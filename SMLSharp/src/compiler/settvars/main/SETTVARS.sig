(**
 * resolve the scope of user declaraed type variables.
 * 
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: SETTVARS.sig,v 1.7 2008/08/05 14:44:00 bochao Exp $
 *)
signature SETTVARS = 
sig

  val setTopDec :
      Absyn.eq SEnv.map -> PatternCalcFlattened.plftopdec -> PatternCalcWithTvars.pttopdec
end
