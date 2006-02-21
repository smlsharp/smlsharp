(**
 * Copyright (c) 2006, Tohoku University.
 *
 * resolve the scope of user declaraed type variables
 * 
 * @author Atsushi Ohori 
 * @version $Id: SETTVARS.sig,v 1.2 2006/02/18 04:59:28 ohori Exp $
 *)
signature SETTVARS = 
sig

  val setDecl :
      bool SEnv.map -> PatternCalc.pdecl -> PatternCalcWithTvars.ptdecl
  val settopdec : bool SEnv.map -> PatternCalc.pltopdec -> PatternCalcWithTvars.pttopdec
end
