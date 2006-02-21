(**
 * Copyright (c) 2006, Tohoku University.
 *
 * a pretty printer for the symbolic instructions
 * @author YAMATODANI Kiyoshi
 * @version $Id: SymbolicInstructionsFormatter.sml,v 1.3 2006/02/18 04:59:29 ohori Exp $
 *)
structure SymbolicInstructionsFormatter =
struct

  (***************************************************************************)

  fun functionCodeToString (exp : SymbolicInstructions.functionCode) =
      Control.prettyPrint (SymbolicInstructions.format_functionCode exp)

  fun instructionToString (instruction : SymbolicInstructions.instruction) =
      Control.prettyPrint (SymbolicInstructions.format_instruction instruction)

  (***************************************************************************)

end
