(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

signature RTLFRAME =
sig

  structure Emit : sig
    type frameLayout
  end

  val allocate : RTL.program
                 -> RTL.program * Emit.frameLayout ClusterID.Map.map

end
