(** symbolic code optimization
 * @copyright (c) 2006, Tohoku University.
 * @author Nguyen Huu-Duc
 * @version $Id: SIOPTIMIZER.sig,v 1.2 2007/04/18 09:09:09 ducnh Exp $
 *)
signature SIOPTIMIZER = sig

  val optimizeInstruction : SIGContext.context -> SymbolicInstructions.instruction -> SymbolicInstructions.instruction

  val deadCodeEliminate : SymbolicInstructions.clusterCode -> SymbolicInstructions.clusterCode

end
