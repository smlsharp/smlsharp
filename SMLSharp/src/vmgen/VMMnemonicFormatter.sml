structure VMMnemonicFormatter =
struct

  local
    structure Formatter =
    struct
      structure I = VMMnemonic
      datatype radix = datatype StringCvt.radix

      fun formatVar (I.REG x) = "r" ^ Word.fmt DEC x
        | formatVar (I.VAR x) = "sp(" ^ Word.fmt DEC x ^ ")"
        | formatVar (I.HOLE x) = "<" ^ Int.toString x ^ ">"

      val formatSize = Word.fmt DEC
      val formatLSize = Word32.fmt DEC
      val formatSSize = Int32.fmt DEC
      val formatScale = Word.fmt DEC
      val formatShift = Word.fmt DEC

      fun formatLabel (I.LABELREF x) = x
        | formatLabel (I.LOCALLABELREF x) = "@" ^ Int.toString x
        | formatLabel (I.REL x) = formatSSize x

      fun formatExtern (I.INTERNALREF x) = x
        | formatExtern (I.GLOBALREF x) = x ^ "@GLOBAL"
        | formatExtern (I.EXTCODEREF x) = x ^ "@EXTTEXT"
        | formatExtern (I.EXTDATAREF x) = x ^ "@EXTDATA"
        | formatExtern (I.FFREF x) = x ^ "@FF"
        | formatExtern (I.PRIMREF x) = x ^ "@PRIM"

      fun formatLoc x = "loc " ^ x

      fun formatB x = "0w" ^ Word8.fmt DEC x ^ "b"
      fun formatH x = "0w" ^ Word.fmt DEC x ^ "h"
      fun formatNB x = Int.toString x ^ "b"
      fun formatNH x = Int.toString x ^ "h"
      fun formatW x = "0wx" ^ Word32.fmt HEX x
      fun formatL x = "0w" ^ Word64.fmt DEC x ^ "l"
      fun formatN x = Int32.toString x
      fun formatNL x = Int64.toString x ^ "l"
      fun formatFS x = x ^ "fs"
      fun formatF x = x ^ "f"
      fun formatFL x = x ^ "fl"

      fun formatString x = "\""^String.toString x^"\""
    end

    structure F = VMMnemonicFormatterFn(Formatter)

  in
  open Formatter
  open F
  end

end
