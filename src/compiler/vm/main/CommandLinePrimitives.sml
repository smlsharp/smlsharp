(**
 * Copyright (c) 2006, Tohoku University.
 *
 * implementation of primitives for CommandLine structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: CommandLinePrimitives.sml,v 1.2 2006/02/18 04:59:39 ohori Exp $
 *)
structure CommandLinePrimitives : PRIMITIVE_IMPLEMENTATIONS =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure H = Heap

  (***************************************************************************)

  fun CommandLine_name VM heap [dummy] =
      let val name = VM.getName VM
      in [SLD.stringToValue heap name]
      end
    | CommandLine_name _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "CommandLine_name"

  fun CommandLine_arguments VM heap [dummy] =
      let
        val arguments = VM.getArguments VM
        val argumentsValue =
            SLD.listToValue heap (SLD.stringToValue heap) arguments
      in [argumentsValue]
      end
    | CommandLine_arguments _ _ _ = 
      raise RE.UnexpectedPrimitiveArguments "CommandLine_arguments"

  val primitives =
      [
        {name = "CommandLine_name", function = CommandLine_name},
        {name = "CommandLine_arguments", function = CommandLine_arguments}
      ]

  (***************************************************************************)

end;
