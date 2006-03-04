(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: VALREC_OPTIMIZER.sig,v 1.6 2006/02/28 16:11:11 kiyoshiy Exp $
 *)
signature VALREC_OPTIMIZER =
sig
  val optimize : 
      VALREC_Utils.globalContext -> PatternCalc.pltopdec list -> PatternCalc.pltopdec list
end
