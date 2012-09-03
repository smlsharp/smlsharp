(**
 * implementation of primitives on date values.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: DynamicLinkPrimitives.sml,v 1.1 2006/12/10 01:57:24 kiyoshiy Exp $
 *)
structure DynamicLinkPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  fun DynamicLink_dlopen VM heap [name as Pointer _] =
      raise RE.UnexpectedPrimitiveArguments "DynamicLink_dlopen"

  fun DynamicLink_dlclose VM heap [Word _] =
      raise RE.UnexpectedPrimitiveArguments "DynamicLink_dlclose"

  fun DynamicLink_dlsym VM heap [Word _, Pointer _] =
      raise RE.UnexpectedPrimitiveArguments "DynamicLink_dlsym"

  val primitives =
      [
        {name = "DynamicLink_dlopen", function = DynamicLink_dlopen},
        {name = "DynamicLink_dlclose", function = DynamicLink_dlclose},
        {name = "DynamicLink_dlsym", function = DynamicLink_dlsym}
      ]

  (***************************************************************************)

end;
