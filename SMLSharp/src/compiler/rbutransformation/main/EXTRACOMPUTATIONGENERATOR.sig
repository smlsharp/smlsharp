(**
 * ExtraComputationGenerator.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: EXTRACOMPUTATIONGENERATOR.sig,v 1.3 2007/09/29 08:30:05 ohori Exp $
 *)

signature EXTRACOMPUTATIONGENERATOR = sig

  val generate : RBUContext.context -> Loc.loc -> (RBUCalc.rbudecl list * RBUContext.context)
  val generateWithBtvEnv : RBUContext.context -> AnnotatedTypes.btvEnv -> Loc.loc -> (RBUCalc.rbudecl list * RBUContext.context)

end
