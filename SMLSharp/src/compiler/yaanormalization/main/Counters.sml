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
              val newLocalId : unit -> VarID.id
              val newClusterId : unit -> ClusterID.id
          end
  =
struct

   type stamp = ClusterID.id

   fun init clusterIDStamp =
        ClusterID.init clusterIDStamp

   fun getCounterStamp () = ClusterID.reset ()

   fun newLocalId () = VarID.generate ()

   fun newClusterId () = ClusterID.generate ()

end
