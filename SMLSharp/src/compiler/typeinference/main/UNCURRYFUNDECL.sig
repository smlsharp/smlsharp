(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 *)
signature UNCURRYFUNDECL = 
sig
  val optimize : Counters.stamps -> TypedCalc.tptopdecl list -> (Counters.stamps * TypedCalc.tptopdecl list)
end
