(**
 * implementation of primitives common for Standard C libraries.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: StandardCPrimitives.sml,v 1.1 2006/11/13 13:14:53 kiyoshiy Exp $
 *)
structure StandardCPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  fun StandardC_errno VM heap [_] = [Int 0]
    | StandardC_errno _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "StandardC_errno"

  val primitives =
      [
        {name = "StandardC_errno", function = StandardC_errno}
      ]

  (***************************************************************************)

end;
