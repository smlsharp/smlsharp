(**
 * Copyright (c) 2006, Tohoku University.
 *
 * implementation of primitives on int values.
 * @author YAMATODANI Kiyoshi
 * @version $Id: IntPrimitives.sml,v 1.5 2006/02/18 04:59:39 ohori Exp $
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
