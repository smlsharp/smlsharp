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

  val allRegisters : Target.reg list

  (* split live ranges to make live ranges of variables which has register
   * constraint as short as possible. *)
  val split : RTL.graph -> RTL.graph

  (* add register constraint to coloring graph *)
  val constrain : RTL.graph -> Target.reg Interference.graph
                  -> Target.reg Interference.graph

end
