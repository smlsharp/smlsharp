(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: SYMBOLIC_INSTRUCTIONS_OPTIMIZER.sig,v 1.2 2006/02/28 16:11:06 kiyoshiy Exp $
 *)

signature SYMBOLIC_INSTRUCTIONS_OPTIMIZER = sig

  val optimize :  SymbolicInstructions.functionCode -> SymbolicInstructions.functionCode

end
