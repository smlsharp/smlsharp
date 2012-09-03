(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: SYMBOLIC_INSTRUCTIONS_OPTIMIZER.sig,v 1.3 2007/04/19 05:06:52 ducnh Exp $
 *)

signature SYMBOLIC_INSTRUCTIONS_OPTIMIZER = sig

  val optimize :  SymbolicInstructions.clusterCode list -> SymbolicInstructions.clusterCode list

end
