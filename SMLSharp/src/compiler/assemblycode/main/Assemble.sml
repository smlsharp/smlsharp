(**
 * General assembler.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: Assemble.sml,v 1.2 2007/12/25 14:25:34 katsu Exp $
 *)
structure Assemble : ASSEMBLE =
struct

  structure A = AssemblyCode
  structure B = ObjectFile
  structure SymbolMap = ObjectFileUtils.SymbolMap

  fun addSymbol symtab name (value:B.symbolValue) =
      case SymbolMap.find (symtab, name) of
        NONE => SymbolMap.insert (symtab, name, value)
      | SOME x =>
        if x = value then symtab
        else raise Control.Bug ("addSymbol "^
                                Control.prettyPrint (B.format_symbolName name))

  fun addLocalSymbols exports symtab valuecon symbols =
      SEnv.foldli
        (fn (label, value, symtab) =>
            case SEnv.find (exports, label) of
              SOME true  => addSymbol symtab (B.GLOBAL label) (valuecon value)
            | SOME false => addSymbol symtab (B.LOCAL label) (valuecon value)
            | NONE => symtab)
        symtab
        symbols

  fun addExternalSymbols symtab relocs =
      foldl
        (fn ({symbolName, relocKind, ...}:A.relocation, symtab) =>
            case relocKind of
              A.UNDEF   => addSymbol symtab (B.GLOBAL symbolName) B.UNDEF
            | A.LOCAL   => symtab)
        symtab
        relocs

  fun linearizeSymtab symtab =
      let
        (* local symbols must precede symbols with any other bindings. *)
        val (i, rsymbols, symmap) =
            SymbolMap.foldli
              (fn (name as B.LOCAL _, value, (i, rsyms, symmap)) =>
                  (i + 0w1,
                   {name = name, value = value}::rsyms,
                   SymbolMap.insert (symmap, name, i))
                | (_, _, z) => z)
              (0w0 : B.offset, nil, SymbolMap.empty)
              symtab

        val (i, rsymbols, symmap) =
            SymbolMap.foldli
              (fn (B.LOCAL _, _, z) => z
                | (name, value, (i, rsyms, symmap)) =>
                  (i + 0w1,
                   {name = name, value = value}::rsyms,
                   SymbolMap.insert (symmap, name, i)))
              (i, rsymbols, symmap)
              symtab
      in
        (rev rsymbols, symmap)
      end

  fun compileReloc symmap reloc =
      map
        (fn ({offset, symbolName, relocKind, relocType}:A.relocation) =>
            let
              val symid =
                  case relocKind of
                    A.UNDEF => SymbolMap.find (symmap, B.GLOBAL symbolName)
                  | A.LOCAL =>
                    case SymbolMap.find (symmap, B.LOCAL symbolName) of
                      NONE => SymbolMap.find (symmap, B.GLOBAL symbolName)
                    | x => x

              val symid =
                  case symid of
                    SOME x => x
                  | NONE => raise Control.Bug ("compileReloc: "^symbolName)
            in
              {
                offset = offset,
                ty = relocType,
                symbolIndex = symid
              } : B.relocation
            end)
        reloc

  fun assemble (assembleSection:'target A.section -> A.assembledSection)
               ({exportLabels, init, text, data, bss, bbss}:'target A.program) =
      let
        val init = assembleSection init
        val text = assembleSection text
        val data = assembleSection data

        val symtab = SymbolMap.empty

        local
          fun error _ = raise Control.Bug "compile: init symbols exist"
        in
        val symtab = addLocalSymbols exportLabels symtab error (#symbols init)
        end
        val symtab = addLocalSymbols exportLabels symtab B.TEXT (#symbols text)
        val symtab = addLocalSymbols exportLabels symtab B.DATA (#symbols data)
        val symtab = addLocalSymbols exportLabels symtab B.BSS (#symbols bss)
        val symtab = addLocalSymbols exportLabels symtab B.BBSS (#symbols bbss)
        val symtab = addExternalSymbols symtab (#relocation init)
        val symtab = addExternalSymbols symtab (#relocation text)
        val symtab = addExternalSymbols symtab (#relocation data)

        val (symbols, symmap) = linearizeSymtab symtab

        val initReloc = compileReloc symmap (#relocation init)
        val textReloc = compileReloc symmap (#relocation text)
        val dataReloc = compileReloc symmap (#relocation data)
      in
        {
          init = {content = [#content init],
                  relocation = initReloc,
                  alignment = #alignment init},
          text = {content = [#content text],
                  relocation = textReloc,
                  alignment = #alignment text},
          data = {content = [#content data],
                  relocation = dataReloc,
                  alignment = #alignment data},
          bss  = {size = #size bss, alignment = #alignment bss},
          bbss = {size = #size bbss, alignment = #alignment bbss},
          symbols = symbols
        } : B.objectFile
      end

end
