structure Counters : 
          sig
              val newVarName  : unit -> string
              val nextBTid : unit -> BoundTypeVarID.id
              val newTyConId : unit -> TyConID.id
              val newExnTagID : unit -> ExnTagID.id
          end
  =
struct

   fun newVarName () = VarName.generate ()

   fun nextBTid () =  BoundTypeVarID.generate ()
                     
   fun newTyConId () = TyConID.generate ()

   fun newExnTagID () = ExnTagID.generate ()

end
