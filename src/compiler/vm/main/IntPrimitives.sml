(**
 * implementation of primitives on int values.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: IntPrimitives.sml,v 1.6 2006/02/28 16:11:12 kiyoshiy Exp $
 *)
structure IntPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  fun Int_toString VM heap [Int int] =
      [SLD.stringToValue heap (SInt32.toString int)]
    | Int_toString _ _ _ = raise RE.UnexpectedPrimitiveArguments "Int_toString"

  val primitives =
      [
        {name = "Int_toString", function = Int_toString}
      ]

  (***************************************************************************)

end;
