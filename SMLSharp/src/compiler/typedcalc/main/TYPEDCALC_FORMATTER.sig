(**
 * Pretty printer of the typed pattern calculus.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: TYPEDCALC_FORMATTER.sig,v 1.12 2008/08/05 14:44:00 bochao Exp $
 *)
signature TYPEDCALC_FORMATTER = 
sig

  val tpdecToString : Types.btvEnv list -> TypedCalc.tpdecl -> string
  val tpexpToString : Types.btvEnv list -> TypedCalc.tpexp -> string
  val tptopdecToString : Types.btvEnv list -> TypedCalc.tptopdecl -> string
end
