(**
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: Counters.sml,v 1.5 2008/08/06 17:23:40 ohori Exp $
 *)
structure Counters :
          sig
              type stamps
              val init : stamps -> unit
              val newLocalId : unit -> LocalVarID.id
              val newVarName : unit -> string
              val getCountersStamps : unit -> stamps
          end
 =
struct
   type stamps = 
        {
         localVarIDStamp : LocalVarID.id,
         varNameStamp : VarNameID.id
        }

   fun init (stamps : stamps) =
     (
      LocalVarIDGen.init (#localVarIDStamp stamps);
      VarNameGen.init (#varNameStamp stamps)
     )

    fun getCountersStamps () =
       {
        localVarIDStamp = LocalVarIDGen.reset (),
        varNameStamp = VarNameGen.reset ()
       }
       
   fun newLocalId () = LocalVarIDGen.generate ()

   fun newVarName () = VarNameGen.generate ()
end
