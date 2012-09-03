(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

signature RTLCONSTRAINT = sig

  structure Target : sig
    type reg
  end

  (* machine registers. This vector gives each register an unique ID number,
   * which is the index in the vector. *)
  val registers : Target.reg vector

  (* split live ranges in order to make live range of each variable which
   * has some register constraints as short as possible. *)
  val split : RTL.graph -> RTL.graph

  (* add register constraints to interference graph. *)
  val constrain : RTL.graph -> Coloring.graph -> unit

end
