(**
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: Counters.sml,v 1.4 2008/08/06 17:23:40 ohori Exp $
 *)
structure Counters : 
          sig
              type stamps
              val init : stamps -> unit
              val newVarName : unit -> string
              val getCounterStamps : unit -> stamps
          end
  =
struct
   type stamps = 
        {
         boundTypeVarIDStamp : int,
         freeTypeVarIDStamp : FreeTypeVarID.id,
         varNameStamp : VarNameID.id
        }
   fun init (stamps:stamps) =
     (
       VarNameGen.init (#varNameStamp stamps);
       BoundTypeVarIDGen.init (#boundTypeVarIDStamp stamps);
       FreeTypeVarIDGen.init (#freeTypeVarIDStamp stamps)
     )
   fun getCounterStamps () =
       {
        boundTypeVarIDStamp = BoundTypeVarIDGen.reset (),
        freeTypeVarIDStamp = FreeTypeVarIDGen.reset (),
        varNameStamp = VarNameGen.reset ()
       }
   fun newVarName () = VarNameGen.generate () 
end
