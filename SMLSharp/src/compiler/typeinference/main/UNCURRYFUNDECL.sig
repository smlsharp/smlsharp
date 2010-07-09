(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 *)
signature UNCURRYFUNDECL = 
sig
  val optimize : TypedCalc.tptopdecl list -> TypedCalc.tptopdecl list
end
