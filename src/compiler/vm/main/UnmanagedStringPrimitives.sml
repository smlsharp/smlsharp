(**
 * implementation of primitives on unmanaged string.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: UnmanagedStringPrimitives.sml,v 1.3 2006/02/28 16:11:13 kiyoshiy Exp $
 *)
structure UnmanagedStringPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  fun UnmanagedString_size VM heap [Word rawAddress] = [Word 0w0]
    | UnmanagedString_size _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "UnmanagedString_import"

  val primitives =
      [
        {name = "UnmanagedString_size", function = UnmanagedString_size}
      ]

  (***************************************************************************)

end;
