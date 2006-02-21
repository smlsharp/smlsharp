(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author NGUYEN Huu-Duc
 * @version $Id: VALREC_OPTIMIZER.sig,v 1.5 2006/02/18 16:04:07 duchuu Exp $
 *)
signature VALREC_OPTIMIZER =
sig
  val optimize : 
      VALREC_Utils.globalContext -> PatternCalc.pltopdec list -> PatternCalc.pltopdec list
end
