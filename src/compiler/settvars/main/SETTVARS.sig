(**
 * resolve the scope of user declaraed type variables.
 * 
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: SETTVARS.sig,v 1.3 2006/02/28 16:11:05 kiyoshiy Exp $
 *)
signature SETTVARS = 
sig

  val setDecl :
      bool SEnv.map -> PatternCalc.pdecl -> PatternCalcWithTvars.ptdecl
  val settopdec : bool SEnv.map -> PatternCalc.pltopdec -> PatternCalcWithTvars.pttopdec
end
