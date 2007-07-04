(**
 * implementation of primitives which access garbage collector.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PlatformPrimitives.sml,v 1.1 2007/03/22 01:32:24 kiyoshiy Exp $
 *)
structure PlatformPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  fun Platform_getArch VM heap [dummy] = [Int 1]
    | Platform_getArch _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Platform_getArch"

  fun Platform_getOS VM heap [dummy] = [Int 1]
    | Platform_getOS _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Platform_getOS"

  val primitives =
      [
        {name = "Platform_getArch", function = Platform_getArch},
        {name = "Platform_getOS", function = Platform_getOS}
      ]

  (***************************************************************************)

end;
