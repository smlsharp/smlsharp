(**
 * Copyright (c) 2006, Tohoku University.
 *
 * implementation of primitives on word values.
 * @author YAMATODANI Kiyoshi
 * @version $Id: WordPrimitives.sml,v 1.6 2006/02/18 04:59:41 ohori Exp $
 *)
structure WordPrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  fun Word_toString VM heap [Word word] =
      [SLD.stringToValue heap (UInt32.fmt StringCvt.HEX word)]
    | Word_toString _ _ _ =
      raise RE.UnexpectedPrimitiveArguments "Word_toString"

  val primitives =
      [
        {name = "Word_toString", function = Word_toString}
      ]

  (***************************************************************************)

end;
