(**
 * resolve the scope of user declaraed type variables.
 * 
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: SETTVARS.sig,v 1.3.12.1 2007/11/05 12:57:38 ohori Exp $
 *)
signature SETTVARS = 
sig
  val settopdec : bool SEnv.map -> PatternCalc.pltopdec -> PatternCalcWithTvars.pttopdec
end
