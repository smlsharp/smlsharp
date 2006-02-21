(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author NGUYEN Huu-Duc
 * @version $Id: BUCTRANSFORMER.sig,v 1.4 2006/02/18 16:04:05 duchuu Exp $
 *)
signature BUCTRANSFORMER =
sig

  (***************************************************************************)
  val transform :
      TypedLambda.tldecl list
      -> BUCCalc.bucdecl list
  (***************************************************************************)

end
