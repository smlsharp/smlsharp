(**
 * implementation of primitives which access garbage collector.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PlatformPrimitives.sml,v 1.1.2.3 2007/03/22 17:32:44 katsu Exp $
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

  fun Platform_getPlatform VM heap [dummy] =
      [SLD.stringToValue heap "emulator-emulator"]

  val primitives =
      [
        {name = "Platform_getPlatform", function = Platform_getPlatform}
      ]

  (***************************************************************************)

end;
