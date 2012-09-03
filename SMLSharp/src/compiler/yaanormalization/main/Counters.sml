(**
 * @copyright (c) 2006, Tohoku niversity.
 * @author Liu Bochao
 * @version $Id: Counters.sml,v 1.5 2008/08/06 17:23:41 ohori Exp $
 *)
structure Counters :
          sig
              val newLocalId : unit -> VarID.id
              val newClusterId : unit -> ClusterID.id
          end
  =
struct

   fun newLocalId () = VarID.generate ()

   fun newClusterId () = ClusterID.generate ()

end
