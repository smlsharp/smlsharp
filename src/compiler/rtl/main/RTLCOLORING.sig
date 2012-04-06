(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

signature RTLCOLORING =
sig

  structure Target : sig
    type reg
  end

  val regalloc : RTL.program -> RTL.program * Target.reg VarID.Map.map

end
