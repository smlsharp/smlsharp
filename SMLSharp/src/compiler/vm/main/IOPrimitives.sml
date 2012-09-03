(**
 * implementation of primitives on IO operataions.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: IOPrimitives.sml,v 1.6 2006/02/28 16:11:12 kiyoshiy Exp $
 *)
structure IOPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  fun printString VM heap [address] =
      let
        val (array, length) = SLD.expandStringBlock heap address
        val string = UInt8ArrayToString (array, length)
      in VM.print VM string; [SLD.unitToValue heap ()] end
    | printString _ _ _ = raise RE.UnexpectedPrimitiveArguments "printString"

  val primitives =
      [
        {name = "print", function = printString}
      ]

  (***************************************************************************)

end;
