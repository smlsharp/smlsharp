(**
 * implementation of primitives which access internal of the runtime.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: InternalPrimitives.sml,v 1.3 2006/02/28 16:11:12 kiyoshiy Exp $
 *)
structure InternalPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  fun Internal_IPToString VM heap [Word executableHandle, Word offset] =
      let
        val executable =
            case SLD.getExecutableOfHandle executableHandle of
              NONE =>
              raise
                RE.UnexpectedPrimitiveArguments
                    "Internal_IPToString: invalid executableHandle"
            | SOME executable => executable  
        val codeRef = {executable = executable, offset = offset}
        val locationOpt = LocationTable.getLocationOfCodeRef codeRef
        val string =
            case locationOpt of
              NONE => "???" | SOME loc => AbsynFormatter.locToString loc
      in
        [SLD.stringToValue heap string]
      end
    | Internal_IPToString _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Internal_IPToString"


  val primitives =
      [
        {name = "Internal_IPToString", function = Internal_IPToString}
      ]

  (***************************************************************************)

end;
