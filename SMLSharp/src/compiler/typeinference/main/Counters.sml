structure Counters : 
          sig
              type stamps
              val init : stamps -> unit
              val getCountersStamps : unit -> stamps
              val newVarName  : unit -> string
              val nextBTid : unit -> BoundTypeVarID.id
              val newTyConId : unit -> TyConID.id
              val newExnTagID : unit -> ExnTagID.id
          end
  =
struct

   type stamps =
        {
         boundTypeVarIDStamp : int, 
         exnTagIDKeyStamp : ExnTagID.id, 
         tyConIDKeyStamp : TyConID.id
        }

   fun init (stamps : stamps) =
       (
        BoundTypeVarID.init (#boundTypeVarIDStamp stamps);
        ExnTagID.init (#exnTagIDKeyStamp stamps);
        TyConID.init (#tyConIDKeyStamp stamps)
       ) 

   fun getCountersStamps () =
     {
      boundTypeVarIDStamp = BoundTypeVarID.reset (),
      exnTagIDKeyStamp = ExnTagID.reset (),
      tyConIDKeyStamp = TyConID.reset ()
      }
       
   fun newVarName () = VarName.generate ()

   fun nextBTid () =  BoundTypeVarID.generate ()
                     
   fun newTyConId () = 
       TyConID.generate ()

   fun newExnTagID () = 
       ExnTagID.generate ()

end
