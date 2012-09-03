(**
 * effect analysis.
 * @copyright (c) 2008, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: EFFECT_ANALYSIS.sig,v 1.4 2008/05/08 09:06:03 katsu Exp $
 *)
signature EFFECT_ANALYSIS = 
sig

  type env

  val analyze :
      Counters.stamp
      -> env
      -> PatternCalcWithTvars.pttopdec list
      -> env
         * Counters.stamp

  val toplevelEnv : env

end
