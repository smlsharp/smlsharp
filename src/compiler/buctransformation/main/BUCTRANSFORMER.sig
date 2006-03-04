(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: BUCTRANSFORMER.sig,v 1.5 2006/02/28 16:11:00 kiyoshiy Exp $
 *)
signature BUCTRANSFORMER =
sig

  (***************************************************************************)
  val transform :
      TypedLambda.tldecl list
      -> BUCCalc.bucdecl list
  (***************************************************************************)

end
