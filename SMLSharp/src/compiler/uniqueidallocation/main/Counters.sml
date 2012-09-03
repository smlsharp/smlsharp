(**
 * @copyright (c) 2006, Tohoku niversity.
 * @author Liu Bochao
 * @version $Id: Counters.sml,v 1.12 2008/08/06 17:23:41 ohori Exp $
 *)
structure Counters : 
          sig
              type stamps
              val init : stamps -> unit
              val getCounterStamps : unit -> stamps
              val newLocalID : unit -> LocalVarID.id
              val newExternalID : unit -> ExternalVarID.id
          end
  =
struct
   type stamps = 
        {
         localVarIDStamp : LocalVarID.id,
         externalVarIDKeyStamp : ExternalVarID.id
        }

   fun init (stamps : stamps) =
     (
      LocalVarIDGen.init (#localVarIDStamp stamps);
      ExternalVarIDKeyGen.init (#externalVarIDKeyStamp stamps)
     )
       
   fun getCounterStamps () =
        {
         localVarIDStamp = LocalVarIDGen.reset (),
         externalVarIDKeyStamp =  ExternalVarIDKeyGen.reset ()
        }

   fun newLocalID () = LocalVarIDGen.generate ()

   fun newExternalID () = 
        ExternalVarIDKeyGen.generate ()

(*
   fun setExternalID name =
       let
           val newKey = ExternalVarIDKeyGen.peek ()
       in
           ExternalVarID.setExportID name
       end
*)       
end
