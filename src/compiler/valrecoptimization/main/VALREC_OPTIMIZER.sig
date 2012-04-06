(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: VALREC_OPTIMIZER.sig,v 1.8 2007/12/15 08:30:36 bochao Exp $
 *)
signature VALREC_OPTIMIZER =
sig
  val optimize : IDCalc.icdecl list -> IDCalc.icdecl list
end
