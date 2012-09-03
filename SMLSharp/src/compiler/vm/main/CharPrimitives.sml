(**
 * implementation of primitives on char values.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: CharPrimitives.sml,v 1.6 2006/02/28 16:11:11 kiyoshiy Exp $
 *)
structure CharPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  fun Char_toString VM heap [Word char] =
      [SLD.stringToValue heap (String.str (Char.chr (UInt32ToInt char)))]
    | Char_toString _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Char_toString"

  fun Char_toEscapedString VM heap [Word char] =
      [SLD.stringToValue heap (Char.toString (Char.chr (UInt32ToInt char)))]
    | Char_toEscapedString _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Char_toEscapedString"

  fun Char_ord VM heap [Word char] = [Int(UInt32ToSInt32 char)]
    | Char_ord _ _ _ = raise RE.UnexpectedPrimitiveArguments "Char_ord"

  fun Char_chr VM heap [Int int] = [Word (SInt32ToUInt32 int)]
    | Char_chr _ _ _ = raise RE.UnexpectedPrimitiveArguments "Char_chr"

  val primitives =
      [
        {name = "Char_toString", function = Char_toString},
        {name = "Char_toEscapedString", function = Char_toEscapedString},
        {name = "Char_ord", function = Char_ord},
        {name = "Char_chr", function = Char_chr}
      ]

  (***************************************************************************)

end;
