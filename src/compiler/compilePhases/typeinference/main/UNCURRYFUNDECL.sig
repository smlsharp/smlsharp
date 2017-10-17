(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 *)
signature UNCURRYFUNDECL = 
sig
  val optimize : TypedCalc.tpdecl list -> TypedCalc.tpdecl list
end
