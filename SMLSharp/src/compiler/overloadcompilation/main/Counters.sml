(**
 * @copyright (c) 2006, Tohoku niversity.
 * @author Liu Bochao
 * @version $Id: Counters.sml,v 1.4 2008/08/06 17:23:40 ohori Exp $
 *)
structure Counters : 
sig
  type stamps
  val init : stamps -> unit
  val getCounterStamp : unit -> stamps
end
  =
struct
  type stamps = int

  fun init (stamps:stamps) = BoundTypeVarID.init stamps

  fun getCounterStamp () =  BoundTypeVarID.reset ()

end
