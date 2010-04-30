structure Counters : 
          sig
              type stamps
              val init : stamps -> unit
              val getCountersStamps : unit -> stamps
              val newVarName  : unit -> string
              val nextBTid : unit -> BoundTypeVarID.boundTypeVarID
              val newTyConId : unit -> TyConID.id
              val newExnTagID : unit -> ExnTagID.id
          end
  =
struct

   type stamps = {boundTypeVarIDStamp : int, 
                  freeTypeVarIDStamp : FreeTypeVarID.id, 
                  exnTagIDKeyStamp : ExnTagID.id, 
                  tyConIDKeyStamp : TyConID.id,
                  varNameStamp : VarNameID.id}  

   fun init (stamps : stamps) =
       (
        BoundTypeVarIDGen.init (#boundTypeVarIDStamp stamps);
        FreeTypeVarIDGen.init (#freeTypeVarIDStamp stamps);
        ExnTagIDKeyGen.init (#exnTagIDKeyStamp stamps);
        TyConIDKeyGen.init (#tyConIDKeyStamp stamps);
        VarNameGen.init (#varNameStamp stamps)
       ) 

   fun getCountersStamps () =
     {
      boundTypeVarIDStamp = BoundTypeVarIDGen.reset (),
      freeTypeVarIDStamp = FreeTypeVarIDGen.reset () ,
      exnTagIDKeyStamp = ExnTagIDKeyGen.reset (),
      tyConIDKeyStamp = TyConIDKeyGen.reset (),
      varNameStamp = VarNameGen.reset ()
      }
       
   fun newVarName () = VarNameGen.generate ()

   fun nextBTid () =  BoundTypeVarIDGen.generate ()
                     
   fun newTyConId () = 
       TyConIDKeyGen.generate ()

   fun newExnTagID () = 
       ExnTagIDKeyGen.generate ()

end
