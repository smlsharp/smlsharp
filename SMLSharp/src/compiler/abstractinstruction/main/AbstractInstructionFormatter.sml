(**
 * a pretty printer for the abstract instructions.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: AbstractInstructionFormatter.sml,v 1.1 2007/09/24 22:28:39 katsu Exp $
 *)
structure AbstractInstructionFormatter =
struct

  (***************************************************************************)

  fun clusterToString (exp : AbstractInstruction.cluster) =
      Control.prettyPrint
          (AbstractInstruction.format_cluster exp)

  fun programToString (exp : AbstractInstruction.program) =
      Control.prettyPrint
          (AbstractInstruction.format_program exp)

  fun instructionToString (instruction : AbstractInstruction.instruction) =
      Control.prettyPrint 
          (AbstractInstruction.format_instruction instruction)

  (***************************************************************************)

end
