(**
 * Pretty printer of the typed pattern calculus.
 * @copyright (c) 2006, Tohoku University.
 * @author LIU Bochao
 * @version $Id: PRINTTFP.sig,v 1.4 2006/02/27 06:31:09 bochao Exp $
 *)
signature PRINTTFP = sig
  val tfpdecToString : Types.btvEnv list -> TypedFlatCalc.tfpdecl -> string
end
