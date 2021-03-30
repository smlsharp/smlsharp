(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
signature UNCURRYFUNDECL = 
sig
  val optimize : TypedCalc.tpdecl list -> TypedCalc.tpdecl list
end
