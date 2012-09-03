(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc NGUYEN
 * @version $Id: TLNORMALIZATION.sig,v 1.3 2007/04/19 05:06:52 ducnh Exp $
 *)
signature TLNORMALIZATION =
sig

  val normalize : RecordCalc.rcdecl list -> TypedLambda.tldecl list

end
