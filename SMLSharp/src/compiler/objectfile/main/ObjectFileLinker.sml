(**
 * Perform partial linking with two symbolic object file.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: ObjectFileLinker.sml,v 1.4 2008/02/28 03:27:59 katsu Exp $
 *)
structure ObjectFileLinker : sig

  exception MultipleDefinition of ObjectFile.symbolName

  (* FIXME: how to deal with init section? *)
  val link
      : ObjectFile.objectFile * ObjectFile.objectFile
        -> ObjectFile.objectFile

end =
struct

  structure B = ObjectFile
  structure SymbolMap = ObjectFileUtils.SymbolMap

  exception MultipleDefinition of B.symbolName

  val toOffset = Word32.fromInt
  val fromOffset = Word32.toInt

  fun sectionLength arrays =
      toOffset (foldl (fn (x,z) => Word8Array.length x + z) 0 arrays)

  fun padSize (offset, align) =
      (align - 0w1) - (offset + align - 0w1) mod align : B.offset

  (*
   * Resolve UNDEF symbols with defined symbols.
   *
   * symtab1: GLOBAL Global_0_0 : BBSS 0w12
   * symtab2: GLOBAL Global_0_0 : UNDEF
   * --> destination: GLOBAL Global_0_0 : BBSS 0w12
   *
   * Integrate same symbols into one symbol.
   *
   * symtabA: GLOBAL Global_0_0 : UNDEF
   * symtabB: GLOBAL Global_0_0 : UNDEF
   * --> destination: GLOBAL Global_0_0 : UNDEF
   *
   * If same non-local symbol is defined twice but their values are
   * different, linker raises an error.
   *
   * symtabA: GLOBAL Global_0_0 : BBSS 0x0
   * symtabB: GLOBAL Global_0_0 : BBSS 0x1
   * --> raise MultipleDefinition "Global_0_0"
   *
   * All local symbols are kept in the destination object file.
   * Local symbol names in destination object file may conflict
   * since each local symbol is identified by symbol ID, not by
   * symbol name.
   *
   * symtabA: LOCAL L39 : TEXT 0w12
   * symtabB: LOCAL L39 : TEXT 0w34
   * --> destination: LOCAL L39 : TEXT 0w12, LOCAL L39 : TEXT 0w34
   *
   * All symbols with LOCAL binding must precede the symbols with
   * any other bindings.
   *)
  fun mergeSymbols symtab1 symtab2 =
      let
        fun splitLocal symtab =
            foldl (fn (sym as {name, value}, (i, locals, globals)) =>
                      case name of
                        B.LOCAL _ => (i+1, (i, sym)::locals, globals)
                      | _ => (i+1, locals, (i, sym)::globals))
                  (0, nil, nil)
                  symtab

        val (_, local1, global1) = splitLocal symtab1
        val (_, local2, global2) = splitLocal symtab2

        fun resolve env symtab =
            foldl
              (fn ((_, {name, value}), env) =>
                  case SymbolMap.find (env, name) of
                    NONE => SymbolMap.insert (env, name, value)
                  | SOME value2 =>
                    case (value, value2) of
                      (B.UNDEF, _) => SymbolMap.insert (env, name, value2)
                    | (_, B.UNDEF) => SymbolMap.insert (env, name, value)
                    | _ => if value = value2 then env
                           else raise MultipleDefinition name)
              env
              symtab

        val env = SymbolMap.empty
        val env = resolve env global1
        val env = resolve env global2

        fun find map key =
            case SymbolMap.find (map, key) of
              SOME x => x : B.symbolValue
            | NONE => raise Control.Bug "mergeSymbols"

        fun addLocal z symbols =
            foldr (fn ((i, sym), (map, (n, rsyms))) =>
                      (IEnv.insert (map, i, n), (n+0w1, sym::rsyms)))
                  z symbols

        fun addGlobal z symbols =
            foldl (fn ((i, {name, value}), (map, (n, rsyms), visited)) =>
                      case SymbolMap.find (visited, name) of
                        SOME x =>
                        (IEnv.insert (map, i, x), (n, rsyms), visited)
                      | NONE =>
                        (IEnv.insert (map, i, n),
                         (n + 0w1, {name = name, value = find env name}::rsyms),
                         SymbolMap.insert (visited, name, n)))
                  z symbols

        val rsyms = (0w0:B.offset, nil)
        val (map1, rsyms) = addLocal (IEnv.empty, rsyms) local1
        val (map2, rsyms) = addLocal (IEnv.empty, rsyms) local2
        val visited = SymbolMap.empty
        val (map1, rsyms, visited) = addGlobal (map1, rsyms, visited) global1
        val (map2, rsyms, visited) = addGlobal (map2, rsyms, visited) global2
        val (_, rsymbols) = rsyms
      in
        (rev rsymbols, map1, map2)
      end

  fun shiftSymbols {textShift, dataShift, bssShift, bbssShift} symbols =
      map
        (fn {name, value} =>
            case value of
              B.UNDEF => {name = name, value = value}
            | B.TEXT x => {name = name, value = B.TEXT (textShift + x)}
            | B.DATA x => {name = name, value = B.DATA (dataShift + x)}
            | B.BSS x => {name = name, value = B.BSS (bssShift + x)}
            | B.BBSS x => {name = name, value = B.BBSS (bbssShift + x)})
        symbols

  fun shiftReloc symmap shift reloc =
      map
        (fn {offset, ty, symbolIndex} =>
            {
              offset = offset + shift,
              ty = ty,
              symbolIndex =
                  case IEnv.find (symmap, Word32.toIntX symbolIndex) of
                    SOME x => x
                  | NONE => raise Control.Bug "shiftReloc"
            } : B.relocation)
        reloc

  fun concatContent (sec1:B.section, sec2:B.section) =
      let
        val sec1sz = sectionLength (#content sec1)
        val sec2sz = sectionLength (#content sec2)

        val padsz =
            if sec1sz = 0w0 orelse sec2sz = 0w0 then 0w0
            else padSize (sec1sz, #alignment sec2)
                 handle Div => raise Control.Bug "concatContent: align is zero"

        val sec2start = sec1sz + padsz
        val pad =
            if padsz > 0w0 andalso sec2sz > 0w0
            then [Word8Array.array (fromOffset padsz, 0w0)]
            else nil
        val alignment =
            if sec1sz + padsz > 0w0
            then #alignment sec1 else #alignment sec2
      in
        {
          content = #content sec1 @ pad @ #content sec2,
          alignment = alignment,
          reloc1 = #relocation sec1,
          reloc2 = #relocation sec2,
          shift = sec2start
        }
      end

  fun concatNobits (sec1:B.nobitsSection, sec2:B.nobitsSection) =
      let
        val padsz =
            if #size sec1 = 0w0 orelse #size sec2 = 0w0 then 0w0
            else padSize (#size sec1, #alignment sec2)
                 handle Div => raise Control.Bug "concatNobits: align is zero"

        val sec2start = #size sec1 + padsz
        val pad =
            if padsz > 0w0 andalso #size sec2 > 0w0
            then padsz else 0w0
        val alignment =
            if #size sec1 + pad > 0w0
            then #alignment sec1 else #alignment sec2
      in
        ({
           size = #size sec1 + pad + #size sec2,
           alignment = alignment
         } : B.nobitsSection,
         sec2start)
      end

  fun makeReloc symmap1 symmap2 {content, alignment, reloc1, reloc2, shift} =
      let
        val reloc1 = shiftReloc symmap1 0w0 reloc1
        val reloc2 = shiftReloc symmap2 shift reloc2
      in
        {
          content = content,
          alignment = alignment,
          relocation = reloc1 @ reloc2
        } : B.section
      end

  fun link (obj1:B.objectFile, obj2:B.objectFile) =
      let
        val init = concatContent (#init obj1, #init obj2)
        val text = concatContent (#text obj1, #text obj2)
        val data = concatContent (#data obj1, #data obj2)
        val (bss, bssShift) = concatNobits (#bss obj1, #bss obj2)
        val (bbss, bbssShift) = concatNobits (#bbss obj1, #bbss obj2)

        val shift = {textShift = #shift text,
                     dataShift = #shift data,
                     bssShift  = bssShift,
                     bbssShift = bbssShift}

        val symbols2 = shiftSymbols shift (#symbols obj2)
        val (symbols, map1, map2) = mergeSymbols (#symbols obj1) symbols2

        val init = makeReloc map1 map2 init
        val text = makeReloc map1 map2 text
        val data = makeReloc map1 map2 data
      in
        {
          init = init,
          text = text,
          data = data,
          bss  = bss,
          bbss = bbss,
          symbols = symbols
        } : B.objectFile
      end

end
