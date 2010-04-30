(**
 * @copyright (c) 2006, Tohoku niversity.
 * @author Liu Bochao
 * @version $Id: Counters.sml,v 1.5 2008/08/06 17:23:41 ohori Exp $
 *)
structure Counters :
          sig
              type stamp
              val init : stamp -> unit
              val getCounterStamp : unit -> stamp
              val newLocalId : unit -> LocalVarID.id
          end
  =
struct

   type stamp  = LocalVarID.id

   fun init stamp = LocalVarIDGen.init stamp

   fun getCounterStamp () = LocalVarIDGen.reset ()

   fun newLocalId () = LocalVarIDGen.generate ()

end
