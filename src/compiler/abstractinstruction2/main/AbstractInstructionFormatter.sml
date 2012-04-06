(**
 * a pretty printer for the abstract instructions version 2.
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: AbstractInstructionFormatter.sml,v 1.1 2007/09/24 22:28:39 katsu Exp $
 *)
structure AbstractInstruction2Formatter =
struct
  structure AbstractInstruction = AbstractInstruction2

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
