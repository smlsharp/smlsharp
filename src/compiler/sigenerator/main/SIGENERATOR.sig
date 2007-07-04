(** symbolic code generator
 * @copyright (c) 2006, Tohoku University.
 * @author Nguyen Huu-Duc
 * @version $Id: SIGENERATOR.sig,v 1.2 2007/04/18 09:09:09 ducnh Exp $
 *)
signature SIGENERATOR = sig

  val generate : IntermediateLanguage.moduleCode -> SymbolicInstructions.clusterCode list

end
