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
              val newClusterId : unit -> ClusterID.id
          end
  =
struct

   type stamp =
       {localVarIDStamp: LocalVarID.id,
        clusterIDStamp: ClusterID.id}

   fun init {localVarIDStamp, clusterIDStamp} =
       (LocalVarIDGen.init localVarIDStamp;
        ClusterIDGen.init clusterIDStamp)

   fun getCounterStamp () =
       {localVarIDStamp = LocalVarIDGen.reset (),
        clusterIDStamp = ClusterIDGen.reset ()}

   fun newLocalId () = LocalVarIDGen.generate ()

   fun newClusterId () = ClusterIDGen.generate ()

end
