(**
 * Copyright (c) 2006, Tohoku University.
 *
 * Pretty printer of the typed pattern calculus.
 * @author LIU Bochao
 * @version $Id: PRINTTFP.sig,v 1.3 2006/02/18 11:06:34 duchuu Exp $
 *)
signature PRINTTFP = sig
  val tfpdecToString : Types.btvEnv list -> TypedFlatCalc.tfpdecl -> string
end
