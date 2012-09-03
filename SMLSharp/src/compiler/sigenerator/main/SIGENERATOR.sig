(** symbolic code generator
 * @copyright (c) 2006, Tohoku University.
 * @author Nguyen Huu-Duc
 * @version $Id: SIGENERATOR.sig,v 1.4 2007/12/15 08:30:35 bochao Exp $
 *)
signature SIGENERATOR = sig

  val generate : GlobalIndexEnv.globalIndexEnv * 
                 Counters.stamp * 
                 IntermediateLanguage.moduleCode -> 
                 (GlobalIndexEnv.globalIndexEnv * Counters.stamp * SymbolicInstructions.clusterCode list)

end
