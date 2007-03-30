(**
 * Pretty printer of the typed pattern calculus.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: TYPEDCALC_FORMATTER.sig,v 1.9 2006/03/14 01:38:11 bochao Exp $
 *)
signature TYPEDCALC_FORMATTER = 
sig

  val tptopdecToString : Types.btvEnv list -> TypedCalc.tptopdecl -> string
  val tptpmstrdeclToString : Types.btvEnv list -> TypedCalc.tpmstrdecl -> string
  val tpdecToString : Types.btvEnv list -> TypedCalc.tpdecl -> string
  val tpexpToString : Types.btvEnv list -> TypedCalc.tpexp -> string
  val tpmstrexpToString : Types.btvEnv list -> TypedCalc.tpmstrexp -> string
end
