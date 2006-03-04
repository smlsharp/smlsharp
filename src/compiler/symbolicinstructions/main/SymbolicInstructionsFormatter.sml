(**
 * a pretty printer for the symbolic instructions.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SymbolicInstructionsFormatter.sml,v 1.4 2006/02/28 16:11:06 kiyoshiy Exp $
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
