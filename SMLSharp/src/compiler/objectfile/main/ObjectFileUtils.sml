(**
 * Utilities for object files.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: ObjectFileUtils.sml,v 1.3 2007/12/17 12:11:15 katsu Exp $
 *)
structure ObjectFileUtils =
struct

  local
    structure B = ObjectFile

    structure SymbolNameOrd =
    struct
      type ord_key = B.symbolName

      fun compare (B.GLOBAL s1, B.GLOBAL s2) = String.compare (s1, s2)
        | compare (B.GLOBAL _, B.LOCAL _) = GREATER
        | compare (B.LOCAL s1, B.LOCAL s2) = String.compare (s1, s2)
        | compare (B.LOCAL s1, B.GLOBAL _) = LESS
    end
  in

  structure SymbolMap = BinaryMapFn(SymbolNameOrd)

(*
  (* FIXME: for backward compatibility *)
  fun fromCodeBlock codeBlock =
      let
        val code =
            Word8Array.tabulate
                (Word8Vector.length codeBlock,
                 fn i => Word8Vector.sub (codeBlock, i))
      in
        {
          init = {content = nil, relocation = nil, alignment = 0w0},
          text = {content = nil, relocation = nil, alignment = 0w0},
          data = {content = [code], relocation = nil, alignment = 0w0},
          bss = {size = 0w0, alignment = 0w0},
          bbss = {size = 0w0, alignment = 0w0},
          symbols = [{name = B.GLOBAL "smlsharp_bytecode", value = B.DATA 0w0}]
        } : B.objectFile
      end

  (* FIXME: for backward compatibility *)
  fun toCodeBlock ({data={content, ...}, ...}:B.objectFile) =
      Word8Vector.concat (map Word8Array.vector content)
*)

  end
end
