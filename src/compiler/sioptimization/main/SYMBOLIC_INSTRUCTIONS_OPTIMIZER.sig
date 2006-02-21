(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author NGUYEN Huu-Duc
 * @version $Id: SYMBOLIC_INSTRUCTIONS_OPTIMIZER.sig,v 1.1 2006/02/20 14:48:29 kiyoshiy Exp $
 *)

signature SYMBOLIC_INSTRUCTIONS_OPTIMIZER = sig

  val optimize :  SymbolicInstructions.functionCode -> SymbolicInstructions.functionCode

end
