(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

signature RTLSTABILIZE = sig

  structure Target : sig  (* for consistency check *)
    type reg
  end

  val stabilize : RTL.program -> RTL.program

end
