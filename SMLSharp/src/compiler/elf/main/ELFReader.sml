(**
 * read a SML# ELF file.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: ELFReader.sml,v 1.2 2008/01/10 04:43:12 katsu Exp $
 *)
structure ELFReader : sig

  datatype error =
      Header
    | Note
    | Version
    | SectionHeader
    | SectionDoubled
    | Rel
    | Symtab

  exception Format of error

  val read
      : Word8Array.array
        -> {objectFile: ObjectFile.objectFile,
            extraSections: Word8ArraySlice.slice SEnv.map}

end =
struct

  structure B = ObjectFile

  open ELFConst
  infix && || << >>
  val (op &&) = Word32.andb
  val (op ||) = Word32.orb
  val (op <<) = Word32.<<
  val (op >>) = Word32.>>

  fun W8toW32 x = Word32.fromInt (Word8.toInt x)
  fun WtoW32 x = Word32.fromLarge (Word.toLarge x)
  fun chrW8 x = chr (Word8.toInt x)

  fun alignOffset (offset, align) =
      (offset + align - 1) - (offset + align - 1) mod align

  fun repeat f i step max =
      if i >= max then nil else f i :: repeat f (i + step) step max

  fun sliceToArray s =
      Word8Array.tabulate (Word8ArraySlice.length s,
                           fn i => Word8ArraySlice.sub (s, i))

  fun readH_LE sub (a, i) =
      (W8toW32 (sub (a, i+0))) ||
      (W8toW32 (sub (a, i+1)) << 0w8)

  fun readW_LE sub (a, i) =
      (W8toW32 (sub (a, i+0))) ||
      (W8toW32 (sub (a, i+1)) << 0w8) ||
      (W8toW32 (sub (a, i+2)) << 0w16) ||
      (W8toW32 (sub (a, i+3)) << 0w24)

  fun readH_BE sub (a, i) =
      (W8toW32 (sub (a, i+0)) << 0w8) ||
      (W8toW32 (sub (a, i+1)))

  fun readW_BE sub (a, i) =
      (W8toW32 (sub (a, i+0)) << 0w24) ||
      (W8toW32 (sub (a, i+1)) << 0w16) ||
      (W8toW32 (sub (a, i+2)) << 0w8) ||
      (W8toW32 (sub (a, i+3)))

  val readB = Word8Array.sub

  fun readString sub (a, i, n) =
      CharVector.tabulate (n, fn x => chrW8 (sub (a, i + x)))

  fun readStrtab sub (a, i) =
      let
        fun getstr i =
            let
              val x = sub (a, i)
            in
              if x = 0w0 then nil else chrW8 x :: getstr (i + 1)
            end
      in
        String.implode (getstr i)
      end

  datatype error =
      Header
    | Note
    | Version
    | SectionHeader
    | SectionDoubled
    | Rel
    | Symtab

  exception Format of error    (* invalid ELF header *)

  val ELFHeaderSize = 52
  val SHEntrySize = 40

  fun readHeader buf =
      let
        fun checkB i x = if readB (buf, i) = x then () else raise Format Header

        val _ = checkB 0 0wx7f   (* 7f 'E' 'L' 'F' *)
        val _ = checkB 1 0wx45
        val _ = checkB 2 0wx4c
        val _ = checkB 3 0wx46
        val _ = checkB 4 ELFCLASS32  (* EI_CLASS *)
        val _ = checkB 6 EV_CURRENT  (* EI_VERSION *)

        val ei_data = readB (buf, 5)
        val (readH, readW, readH_slice, readW_slice) =
            if ei_data = ELFDATA2LSB then
              (readH_LE Word8Array.sub, readW_LE Word8Array.sub,
               readH_LE Word8ArraySlice.sub, readW_LE Word8ArraySlice.sub)
            else if ei_data = ELFDATA2MSB then
              (readH_BE Word8Array.sub, readW_BE Word8Array.sub,
               readH_BE Word8ArraySlice.sub, readW_BE Word8ArraySlice.sub)
            else raise Format Header

        fun checkH i x = if readH (buf, i) = x then () else raise Format Header
        fun checkW i x = if readW (buf, i) = x then () else raise Format Header

        val _ = checkH 16 (WtoW32 ET_REL)                 (* e_type *)
        val _ = checkH 18 (WtoW32 EM_NONE)                (* e_machine *)
        val _ = checkW 20 (W8toW32 EV_CURRENT)            (* e_version *)
        val _ = checkW 24 0w0                             (* e_entry *)
        val _ = checkW 28 0w0                             (* e_phoff *)
        val sectionHeaderOffset = readW (buf, 32)         (* e_shoff *)
        (* 36: e_flags: ignore *)
        val _ = checkH 40 (Word32.fromInt ELFHeaderSize)  (* e_ehsize *)
        val _ = checkH 42 0w0                             (* e_phentsize *)
        val _ = checkH 44 0w0                             (* e_phnum *)
        val _ = checkH 46 (Word32.fromInt SHEntrySize)    (* e_shentsize *)
        val numSections = readH (buf, 48)                 (* e_shnum *)
        val shstrtabIndex = readH (buf, 50)               (* e_shstrndx *)
      in
        {
          readArray = {readH = readH, readW = readW},
          readSlice = {readH = readH_slice, readW = readW_slice},
          sectionHeaderOffset = Word32.toIntX sectionHeaderOffset,
          numSections = Word32.toIntX numSections,
          shstrtabIndex = Word32.toIntX shstrtabIndex
        }
      end
      handle Subscript => raise Format Header
           | Overflow => raise Format Header

    fun readNoteSection {readH, readW} buf =
        let
          val readString = readString Word8ArraySlice.sub

          val namesz = Word32.toIntX (readW (buf, 0))
          val descsz = Word32.toIntX (readW (buf, 4))
          val ty = readW (buf, 8)
          val nameOffset = 12
          val descOffset = alignOffset (nameOffset + namesz, 4)
          val name = readString (buf, nameOffset, namesz)
          val desc = readString (buf, descOffset, descsz)
        in
          if name = "SML#\000" then () else raise Format Note;
          if desc = SMLSharpConfiguration.Version^"\000"
          then () else raise Format Version
        end
        handle Subscript => raise Format Note
             | Overflow => raise Format Header

    datatype content =
        CONT of Word8ArraySlice.slice
      | NOBITS of {offset: Word32.word, size: Word32.word}

    fun readSectionHeader {readArray={readW, readH}, readSlice,
                           sectionHeaderOffset, numSections, shstrtabIndex}
                          buf =
        let
          val sectionHeaderSize = SHEntrySize * numSections
          val sectionHeaderEnd = sectionHeaderOffset + sectionHeaderSize

          fun readEntries (buf, i) =
              if i >= sectionHeaderEnd then nil
              else
                let
                  val sh_name = readW (buf, i+0)
                  val sh_type = readW (buf, i+4)
                  (* 8: sh_flags: ignore *)
                  (* 12: sh_addr: ignore *)
                  val offset = readW (buf, i+16)
                  val size = readW (buf, i+20)
                  val content =
                      if sh_type = SHT_NOBITS
                      then NOBITS {offset = offset, size = size}
                      else CONT (Word8ArraySlice.slice
                                     (buf, Word32.toIntX offset,
                                      SOME (Word32.toIntX size)))
                  val link = readW (buf, i+24)
                  val info = readW (buf, i+28)
                  val addralign = readW (buf, i+32)
                  val entsize = readW (buf, i+36)
                in
                  {
                    sh_name = sh_name,
                    sh_type = sh_type,
                    content = content,
                    link = link,
                    info = info,
                    addralign = addralign,
                    entsize = entsize
                  }
                  :: readEntries (buf, i + SHEntrySize)
                end

          val entries = readEntries (buf, sectionHeaderOffset)

          val {content=shstrtab, ...} = List.nth (entries, shstrtabIndex)

          val readStrtab = readStrtab Word8ArraySlice.sub

          fun add (map, k, v) =
              case SEnv.find (map, k) of
                NONE => SEnv.insert (map, k, v)
              | SOME x => raise Format SectionDoubled

          val (_, sectionMap) =
              foldl
                (fn ({sh_name, sh_type, content, link, info,
                      addralign, entsize}, (i, map)) =>
                    if sh_name = SHN_UNDEF then (i + 0w1, map)
                    else
                      let
                        val name =
                            case shstrtab of
                              CONT x => readStrtab (x, Word32.toIntX sh_name)
                            | NOBITS _ => raise Format SectionHeader
                        val section =
                            {
                              index = i,
                              name = name,
                              sh_type = sh_type,
                              content = content,
                              link = link,
                              info = info,
                              addralign = addralign,
                              entsize = entsize
                            }
                      in
                        (i + 0w1, add (map, name, section))
                      end)
                (0w0 : Word32.word, SEnv.empty)
                entries
        in
          sectionMap
        end
        handle Subscript => raise Format SectionHeader
             | Overflow => raise Format SectionHeader

    fun readRelSection {readW, readH} buf (entsize:Word32.word) =
        let
          val _ = if entsize = 0w8 then () else raise Format Rel
          val len = Word8ArraySlice.length buf
        in
          repeat
            (fn i =>
                let
                  val offset = readW (buf, i)
                  val info = readW (buf, i+4)
                  val symbol = info >> 0w8
                  val ty = info && 0w7
                  val ty = if ty = R_32 then B.ABS32
                           else raise Format Rel
                in
                  (* NOTE: symbol index in ELF format is 1-origin. *)
                  {
                    offset = offset,
                    ty = ty,
                    symbolIndex = symbol - 0w1
                  } : B.relocation
                end)
            0 8 len
        end
        handle Subscript => raise Format Rel

    fun readSymtabSection {readW, readH} strtab
                          textIndex dataIndex bssIndex bbssIndex
                          buf (entsize:Word32.word) =
        let
          val readStrtab = readStrtab Word8ArraySlice.sub
          val readB = Word8ArraySlice.sub

          val _ = if entsize = 0w16 then () else raise Format Symtab
          val len = Word8ArraySlice.length buf
        in
          (* NOTE: first symbol is dummy symbol. *)
          repeat
            (fn i =>
                let
                  val st_name = Word32.toIntX (readW (buf, i+0))
                  val st_value = readW (buf, i+4)
                  (* 8: st_size: ignore *)
                  val st_info = readB (buf, i+12)
                  (* 12: st_other: ignore *)
                  val st_shndx = readH (buf, i+14)

                  val bind = Word8.>> (st_info, 0w4)  (* ignore type *)

                  val namestr = readStrtab (strtab, st_name)
                  val name =
                      if bind = STB_LOCAL then B.LOCAL namestr
                      else if bind = STB_GLOBAL then B.GLOBAL namestr
                      else raise Format Symtab

                  val value =
                      if st_shndx = SHN_UNDEF then B.UNDEF
                      else if SOME st_shndx = textIndex then B.TEXT st_value
                      else if SOME st_shndx = dataIndex then B.DATA st_value
                      else if SOME st_shndx = bssIndex then B.BSS st_value
                      else if SOME st_shndx = bbssIndex then B.BBSS st_value
                      else raise Format Symtab
                in
                  {name = name, value = value} : B.symbol
                end)
            16 16 len
        end
        handle Subscript => raise Format Symtab
             | Overflow => raise Format Symtab

    val reservedSections =
        [ ".note", ".text", ".init", ".rodata", ".bss", ".sml#.bbss",
          ".symtab", ".strtab", ".shstrtab",
          ".rel.text", ".rel.init", ".rel.rodata" ]

    fun read buf =
        let
          val header = readHeader buf
          val sections = readSectionHeader header buf

          (* check .note section *)
          val _ =
              case SEnv.find (sections, ".note") of
                SOME {content = CONT content, ...} =>
                readNoteSection (#readSlice header) content
              | _ => raise Format Note

          (* read .text, .init, .data section *)
          fun getCodeSection sectionName =
              case SEnv.find (sections, sectionName) of
                NONE => (nil, NONE, 0w0)
              | SOME {name, index, sh_type, content = CONT content,
                      link, info, addralign, entsize} =>
                if sh_type = SHT_PROGBITS then
                  ([sliceToArray content], SOME index, addralign)
                else raise Format SectionHeader
              | _ => raise Format SectionHeader

          val (textContent, textIndex, textAlign) = getCodeSection ".text"
          val (initContent, initIndex, initAlign) = getCodeSection ".init"
          val (dataContent, dataIndex, dataAlign) = getCodeSection ".rodata"

          (* read .bss, .bbss section *)
          fun getNoBitsSection sectionName =
              case SEnv.find (sections, sectionName) of
                NONE => (0w0, 0w0, NONE)
              | SOME {name, index, sh_type, content = NOBITS {offset, size},
                      link, info, addralign, entsize} =>
                (size, addralign, SOME index)
              | _ => raise Format SectionHeader

          val (bssSize, bssAlign, bssIndex) = getNoBitsSection ".bss"
          val (bbssSize, bbssAlign, bbssIndex) = getNoBitsSection ".sml#.bbss"

          (* read symbol table *)
          val symtabSection = SEnv.find (sections, ".symtab")
          val strtabSection = SEnv.find (sections, ".strtab")

          val (symbols, symtabIndex) =
              case (symtabSection, strtabSection) of
                (NONE, NONE) => (nil, NONE)
              | (SOME (symtab as {content = CONT symtabContent, entsize, ...}),
                 SOME (strtab as {content = CONT strtabContent, ...})) =>
                let
                  val _ = if #link symtab = #index strtab then ()
                          else raise Format Symtab
                in
                  (readSymtabSection (#readSlice header) strtabContent
                                     textIndex dataIndex bssIndex bbssIndex
                                     symtabContent entsize,
                   SOME (#index symtab))
                end
              | _ => raise Format Symtab

          (* read relocation section *)
          fun getRelSection codeIndex sectionName =
              case SEnv.find (sections, sectionName) of
                NONE => nil
              | SOME {name, index, sh_type, content = CONT content,
                      link, info, addralign, entsize} =>
                if SOME link = symtabIndex andalso SOME info = codeIndex
                then readRelSection (#readSlice header) content entsize
                else raise Format Rel
              | _ => raise Format Rel

          val initReloc = getRelSection initIndex ".rel.init"
          val textReloc = getRelSection textIndex ".rel.text"
          val dataReloc = getRelSection dataIndex ".rel.rodata"

          (* extra sections *)
          val extraSections =
              SEnv.mapPartial
                (fn {name, content = CONT content, ...} =>
                    if List.exists (fn x => name = x) reservedSections
                    then NONE
                    else SOME content
                  | _ => NONE)
                sections
        in
          {
            objectFile =
              {
                init = {content = initContent,
                        relocation = initReloc,
                        alignment = initAlign},
                text = {content = textContent,
                        relocation = textReloc,
                        alignment = textAlign},
                data = {content = dataContent,
                        relocation = dataReloc,
                        alignment = dataAlign},
                bss  = {size = bssSize, alignment = bssAlign},
                bbss = {size = bbssSize, alignment = bbssAlign},
                symbols = symbols
              } : B.objectFile,
            extraSections = extraSections
          }
        end

end
