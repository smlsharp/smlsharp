(**
 * ExtraComputationGenerator.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: EXTRACOMPUTATIONGENERATOR.sig,v 1.2 2007/04/18 09:07:04 ducnh Exp $
 *)

signature EXTRACOMPUTATIONGENERATOR = sig

  val generate : RBUContext.context -> Loc.loc -> (RBUCalc.rbudecl list * RBUContext.context)

end
