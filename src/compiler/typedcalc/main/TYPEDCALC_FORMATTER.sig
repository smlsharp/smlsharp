(**
 * Pretty printer of the typed pattern calculus.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: TYPEDCALC_FORMATTER.sig,v 1.8 2006/02/28 16:11:07 kiyoshiy Exp $
 *)
signature TYPEDCALC_FORMATTER = 
sig

  val tptopdecToString : Types.btvEnv list -> TypedCalc.tptopdecl -> string
  val tpdecToString : Types.btvEnv list -> TypedCalc.tpdecl -> string
  val tpexpToString : Types.btvEnv list -> TypedCalc.tpexp -> string
  val tpmstrexpToString : Types.btvEnv list -> TypedCalc.tpmstrexp -> string

end
