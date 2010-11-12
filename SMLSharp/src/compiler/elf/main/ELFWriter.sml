(**
 * write a binary object to file in ELF format.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: ELFWriter.sml,v 1.5 2008/01/10 04:43:12 katsu Exp $
 *)
functor ELFWriterFn
(
  val EI_DATA : Word8.word
  structure Dump : sig
    val dumpB : Word8Array.array * int * Word8.word -> unit
    val dumpH : Word8Array.array * int * word -> unit
    val dumpW : Word8Array.array * int * Word32.word -> unit
    val dumpW64 : Word8Array.array * int * Word32.word -> unit
  end
) : sig

  val write
      : (Word8Array.array -> unit)            (* output function *)
        * ObjectFile.objectFile
        * {sectionName: string,               (* extra sections *)
           content: Word8Array.array} list
        -> unit

end =
struct

  open Dump
  open ELFConst
  structure B = ObjectFile

  infix || <<
  val (op ||) = Word32.orb
  val (op <<) = Word32.<<

  fun alignOffset (offset, align) =
      (offset + align - 1) - (offset + align - 1) mod align
  fun padSize (offset, align) =
      (align - 0w1) - (offset + align - 0w1) mod align : Word32.word

  fun dumpList (a, i) l =
      foldl (fn (x, i) => (Word8Array.update (a, i, x); i + 1)) i l

  val dumpString = StringTable.dumpString

  fun arrayListLength arrays =
      foldl (fn (x,z) => Word8Array.length x + z) 0 arrays

  type elffile =
      {
        shstrtab: StringTable.strtab,    (* section string table *)
        shtable: Word8Array.array list,  (* section headers; reverse order *)
        body: Word8Array.array list,     (* file content; reverse order *)
        offset: Word32.word              (* current file offset *)
      }

  val ELFHeaderSize = 0w52 : Word32.word

  fun ELFheader {sectionHeaderOffset, numSections, shstrtabIndex} =
      let
        val a = Word8Array.array (Word32.toInt ELFHeaderSize, 0w0)
      in
        dumpList (a, 0)
          [
            0wx7f, 0wx45, 0wx4c, 0wx46, (* 7f 'E' 'L' 'F' *)
            ELFCLASS32,                 (* EI_CLASS *)
            EI_DATA,                    (* EL_DATA *)
            EV_CURRENT,                 (* EI_VERSION *)
            0wxff,                      (* EI_OSABI *)
            0w0,                        (* EI_ABIVERSION *)
            0wx53, 0wx4d, 0wx4c, 0wx23, (* EI_PAD *)
            0w0, 0w0, 0w0
          ];
        dumpH (a, 16, ET_REL);  (* e_type *)
        dumpH (a, 18, EM_NONE); (* e_machine *)
        dumpW (a, 20, Word32.fromInt (Word8.toInt EV_CURRENT)); (*e_version*)
        dumpW (a, 24, 0w0);     (* e_entry = 0 *)
        dumpW (a, 28, 0w0);     (* e_phoff = 0; no program header table *)
        dumpW (a, 32, sectionHeaderOffset);  (* e_shoff *)
        dumpW (a, 36, 0w0);     (* e_flags = 0; no flags *)
        dumpH (a, 40, Word.fromInt (Word32.toInt ELFHeaderSize)); (*e_ehsize*)
        dumpH (a, 42, 0w0);     (* e_phentsize = 0; no program header table *)
        dumpH (a, 44, 0w0);     (* e_phnum = 0; no program header table *)
        dumpH (a, 46, 0w40);    (* e_shentsize = 40; section header size *)
        dumpH (a, 48, numSections);          (* e_shnum *)
        dumpH (a, 50, shstrtabIndex);        (* e_shstrndx *)
        a
      end

  fun noteSection () =
      let
        val name = "SML#"
        val desc = SMLSharpConfiguration.Version
        val nameLen = size name + 1
        val descLen = size desc + 1
        val nameOffset = 12
        val descOffset = alignOffset (nameOffset + nameLen, 4)
        val size = alignOffset (descOffset + descLen, 4)

        val a = Word8Array.array (size, 0w0)
      in
        dumpW (a, 0, Word32.fromInt nameLen);  (* namesz *)
        dumpW (a, 4, Word32.fromInt descLen);  (* descsz *)
        dumpW (a, 8, 0w0);                     (* type = 0 *)
        dumpString (a, nameOffset, name);
        dumpString (a, descOffset, desc);
        a
      end

  val dummySectionHeader =
      Word8Array.array (40, 0w0)

  fun sectionHeader strtab
                    {name, ty, flags, offset, size, link, info,
                     addralign, entsize} =
      let
        val a = Word8Array.array (40, 0w0)
        val (strtab, nameIndex) = StringTable.intern (strtab, name)
      in
        dumpW (a, 0, nameIndex);            (* sh_name *)
        dumpW (a, 4, ty);                   (* sh_type *)
        dumpW (a, 8, flags);                (* sh_flags *)
        dumpW (a, 12, 0w0);                 (* sh_addr = 0 *)
        dumpW (a, 16, offset);              (* sh_offset *)
        dumpW (a, 20, size);                (* sh_size *)
        dumpW (a, 24, link);                (* sh_link *)
        dumpW (a, 28, info);                (* sh_info *)
        dumpW (a, 32, addralign);           (* sh_addralign *)
        dumpW (a, 36, entsize);             (* sh_entsize *)
        (strtab, a)
      end

  fun addSection ({offset, shstrtab, shtable, body}:elffile)
                 {name, ty, flags, link, info, entsize, alignment, content} =
      let
        val pad = if alignment = 0w0 then 0w0
                  else padSize (offset, alignment)
        val sectionStart = offset + pad
        val size = Word32.fromInt (arrayListLength content)

        val (shstrtab, header) =
            sectionHeader shstrtab
                          {name = name,
                           ty = ty,
                           flags = flags,
                           offset = sectionStart,
                           size = size,
                           link = link,
                           info = info,
                           addralign = alignment,
                           entsize = entsize}

        val sectionIndex = length shtable

        val sectionContent =
            if pad > 0w0
            then rev (Word8Array.array (Word32.toIntX pad, 0w0) :: content)
            else rev content
      in
        ({
           offset = sectionStart + size,
           shstrtab = shstrtab,
           shtable = header :: shtable,   (* reverse order *)
           body = sectionContent @ body   (* reverse order *)
         } : elffile,
         SOME (Word32.fromInt sectionIndex))
      end

  fun addNoBitSection ({offset, shstrtab, shtable, body}:elffile)
                      {name, virtualOffset, flags, size, alignment} =
      let
        val pad = if alignment = 0w0 then 0w0
                  else padSize (virtualOffset, alignment)
        val sectionStart = virtualOffset + pad

        val (shstrtab, header) =
            sectionHeader shstrtab
                          {name = name,
                           ty = SHT_NOBITS,
                           flags = flags,
                           offset = sectionStart,
                           size = size,
                           link = SHN_UNDEF,
                           info = 0w0,
                           addralign = alignment,
                           entsize = 0w0}

        val sectionIndex = length shtable
      in
        ({
           offset = offset,
           shstrtab = shstrtab,
           shtable = header :: shtable,  (* reverse order *)
           body = body
         } : elffile,
         SOME (Word32.fromInt sectionIndex),
         sectionStart + size)
      end

  val relEntrySize = 0w8 : Word32.word

  fun relSection reloc =
      let
        val a = Word8Array.array (length reloc * 8, 0w0)
      in
        foldl
          (fn ({offset, ty, symbolIndex}, i) =>
              let
                (* NOTE: symbol index in ELF format is 1-origin. *)
                val symbol = symbolIndex + 0w1
                val ty = case ty of B.ABS32 => R_32
                val info = (symbol << 0w8) || ty
              in
                dumpW (a, i+0, offset);    (* r_offset *)
                dumpW (a, i+4, info);      (* r_info *)
                i + 8
              end)
          0
          reloc;
          a
      end

  val symtabEntrySize = 0w16 : Word32.word

  fun symtabSection strtab textIndex dataIndex bssIndex bbssIndex symbols =
      let
        (* first symbol must be dummy. *)
        val a = Word8Array.array ((length symbols + 1) * 16, 0w0)

        fun lastLocal i nil = i
          | lastLocal i ({name=B.LOCAL _,...}::t) = lastLocal (i+0w1) t
          | lastLocal i ({name, value}::t) = i

        val maxLocalIndex = lastLocal 0w1 symbols : Word32.word

        val (strtab, _, _) =
            foldl
              (fn ({name, value}, (strtab, symid, i)) =>
                  let
                    val (name, bind) =
                        case name of
                          B.LOCAL x =>
                          (* local symbols must precede any other symbols. *)
                          if symid < maxLocalIndex then (x, STB_LOCAL)
                          else raise Control.Bug "symtabSection: LOCAL"
                        | B.GLOBAL x => (x, STB_GLOBAL)

                    val (strtab, nameIndex) =
                        StringTable.intern (strtab, name)

                    val (value, section) =
                        (case value of
                           B.UNDEF => (0w0, SHN_UNDEF)
                         | B.TEXT x => (x, valOf textIndex)
                         | B.DATA x => (x, valOf dataIndex)
                         | B.BSS x => (x, valOf bssIndex)
                         | B.BBSS x => (x, valOf bbssIndex))
                        handle Option => raise Control.Bug "symtabSection"

                    val info = Word8.orb (Word8.<< (bind, 0w4), STT_NOTYPE)
                    val section = Word.fromInt (Word32.toInt section)
                  in
                    dumpW (a, i+0, nameIndex);  (* st_name *)
                    dumpW (a, i+4, value);      (* st_value *)
                    dumpW (a, i+8, 0w0);        (* st_size = 0 *)
                    dumpB (a, i+12, info);      (* st_info *)
                    dumpB (a, i+13, 0w0);       (* st_other = 0 *)
                    dumpH (a, i+14, section);   (* st_shndx *)
                    (strtab, symid + 0w1, i + 16)
                  end)
              (strtab, 0w1, 16)
              symbols
      in
        (strtab, a, maxLocalIndex)
      end

  (*
   * [ ELF header     ]
   * [ .note          ]
   * [ .init          ] if exist
   * [ .text          ] if exist
   * [ .rodata        ] if exist
   * [ .rel.init      ] if exist
   * [ .rel.text      ] if exist
   * [ .rel.rodata    ] if exist
   * [ .symtab        ] if exist
   * [ .strtab        ] if exist
   * [ extra sections ]
   * [ .shstrtbl      ]
   * [ section header ]
   *)
  fun write (output,
             objfile as {init, text, data, bss, bbss, symbols} : B.objectFile,
             extraSections) =
      let
        val elffile =
            {
              shstrtab = StringTable.initialStrtab,
              shtable = [dummySectionHeader],
              body = nil,
              offset = ELFHeaderSize
            } : elffile

        val (elffile, _) =
            addSection elffile
                       {name = ".note",
                        ty = SHT_NOTE,
                        flags = 0w0,
                        link = SHN_UNDEF,
                        info = 0w0,
                        alignment = 0w0,
                        entsize = 0w0,
                        content = [noteSection ()]}

        fun addCodeSection elffile name flags
                           ({content, alignment, ...}:B.section) =
            if arrayListLength content = 0
            then (elffile, NONE)
            else addSection elffile
                            {name = name,
                             ty = SHT_PROGBITS,
                             flags = flags,
                             link = SHN_UNDEF,
                             info = 0w0,
                             alignment = alignment,
                             entsize = 0w0,
                             content = content}

        val (elffile, initIndex) =
            addCodeSection elffile ".init" SHF_ALLOC init
        val (elffile, textIndex) =
            addCodeSection elffile ".text" (SHF_ALLOC || SHF_EXECINSTR) text
        val (elffile, dataIndex) =
            addCodeSection elffile ".rodata" SHF_ALLOC data

        fun addNoBitsSection elffile name offset
                             ({size, alignment, ...}:B.nobitsSection) =
            if size = 0w0
            then (elffile, NONE, offset)
            else addNoBitSection elffile
                                 {name = name,
                                  virtualOffset = offset,
                                  flags = SHF_ALLOC || SHF_WRITE,
                                  size = size,
                                  alignment = alignment}

        val (elffile, bssIndex, offset) =
            addNoBitsSection elffile ".bss" (#offset elffile) bss
        val (elffile, bbssIndex, offset) =
            addNoBitsSection elffile ".sml#.bbss" offset bbss

        val (elffile, symtabIndex) =
            if null symbols
            then (elffile, NONE)
            else
              let
                val (strtab, symtabContent, maxLocalSymbolIndex) =
                    symtabSection StringTable.initialStrtab
                                  textIndex dataIndex bssIndex bbssIndex
                                  symbols

                val (elffile, strtabIndex) =
                    addSection elffile
                               {name = ".strtab",
                                ty = SHT_STRTAB,
                                flags = 0w0,
                                link = SHN_UNDEF,
                                info = 0w0,
                                alignment = 0w8,
                                entsize = 0w0,
                                content = [StringTable.dump strtab]}
              in
                addSection elffile
                           {name = ".symtab",
                            ty = SHT_SYMTAB,
                            flags = 0w0,
                            link = valOf strtabIndex,
                            info = maxLocalSymbolIndex,
                            alignment = 0w8,
                            entsize = symtabEntrySize,
                            content = [symtabContent]}
              end

        fun addRelSection elffile name sectionIndex
                          ({relocation, ...}:B.section) =
            if null relocation
            then (elffile, NONE)
            else addSection elffile
                            {name = name,
                             ty = SHT_REL,
                             flags = 0w0,
                             link = valOf symtabIndex,
                             info = valOf sectionIndex,
                             alignment = 0w8,
                             entsize = relEntrySize,
                             content = [relSection relocation]}

        val (elffile, relInitIndex) =
            addRelSection elffile ".rel.init" initIndex init
        val (elffile, relTextIndex) =
            addRelSection elffile ".rel.text" textIndex text
        val (elffile, relDataIndex) =
            addRelSection elffile ".rel.data" dataIndex data

        val elffile =
            foldl
              (fn ({sectionName, content}, elffile) =>
                  #1 (addSection elffile
                                 {name = sectionName,
                                  ty = SHT_LOUSER,
                                  flags = 0w0,
                                  link = SHN_UNDEF,
                                  info = 0w0,
                                  alignment = 0w16,
                                  entsize = 0w0,
                                  content = [content]}))
              elffile
              extraSections

        (* ensure ".shstrtab" is in shstrtab. *)
        val elffile =
            {
              shstrtab = StringTable.intern' (#shstrtab elffile, ".shstrtab"),
              shtable = #shtable elffile,
              body = #body elffile,
              offset = #offset elffile
            } : elffile

        val (elffile, shstrtabIndex) =
            addSection elffile
                       {name = ".shstrtab",
                        ty = SHT_STRTAB,
                        flags = 0w0,
                        link = SHN_UNDEF,
                        info = 0w0,
                        alignment = 0w8,
                        entsize = 0w0,
                        content = [StringTable.dump (#shstrtab elffile)]}

        val {shtable, body, offset, ...} = elffile
        val pad = padSize (offset, 0w16)
        val offset = offset + pad
        val body = if pad > 0w0
                   then Word8Array.array (Word32.toIntX pad, 0w0)::body
                   else body

        val header =
            ELFheader {sectionHeaderOffset = offset,
                       numSections = Word.fromInt (length shtable),
                       shstrtabIndex =
                           Word.fromInt (Word32.toInt (valOf shstrtabIndex))}
      in
        output header;
        foldr (fn (x,_) => output x) () body;
        foldr (fn (x,_) => output x) () shtable
      end
      handle Option => raise Control.Bug "ELFWriter"

end

structure ELFWriterLE = ELFWriterFn(val EI_DATA = ELFConst.ELFDATA2LSB
                                    structure Dump = SerializeLE)
structure ELFWriterBE = ELFWriterFn(val EI_DATA = ELFConst.ELFDATA2MSB
                                    structure Dump = SerializeBE)
