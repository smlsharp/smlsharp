(**
 * Copyright (c) 2006, Tohoku University.
 *
 * Pretty printer of the typed pattern calculus.
 * @author Atsushi Ohori 
 * @version $Id: TYPEDCALC_FORMATTER.sig,v 1.7 2006/02/18 04:59:31 ohori Exp $
 *)
signature TYPEDCALC_FORMATTER = 
sig

  val tptopdecToString : Types.btvEnv list -> TypedCalc.tptopdecl -> string
  val tpdecToString : Types.btvEnv list -> TypedCalc.tpdecl -> string
  val tpexpToString : Types.btvEnv list -> TypedCalc.tpexp -> string
  val tpmstrexpToString : Types.btvEnv list -> TypedCalc.tpmstrexp -> string

end
