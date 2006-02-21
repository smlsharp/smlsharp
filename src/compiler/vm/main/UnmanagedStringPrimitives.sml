(**
 * Copyright (c) 2006, Tohoku University.
 *
 * implementation of primitives on unmanaged string.
 * @author YAMATODANI Kiyoshi
 * @version $Id: UnmanagedStringPrimitives.sml,v 1.2 2006/02/18 04:59:40 ohori Exp $
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
