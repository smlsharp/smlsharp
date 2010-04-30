(**
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: Counters.sml,v 1.4 2008/08/06 17:23:39 ohori Exp $
 *)
structure Counters :
          sig
              type stamps
              val init : stamps -> unit
              val newLocalID : unit -> LocalVarID.id
              val getCountersStamps : unit -> stamps 
          end
  =
struct
   type stamps =
        {
         boundTypeVarIDStamp : int,
         localVarIDStamp : LocalVarID.id
        }

   fun init (stamps:stamps) =
     (
      LocalVarIDGen.init (#localVarIDStamp stamps);
      BoundTypeVarIDGen.init (#boundTypeVarIDStamp stamps)
     )

   fun newLocalID () = LocalVarIDGen.generate ()

   fun getCountersStamps () =
       {
        localVarIDStamp = LocalVarIDGen.reset (),
        boundTypeVarIDStamp =  BoundTypeVarIDGen.reset ()
       }
end
