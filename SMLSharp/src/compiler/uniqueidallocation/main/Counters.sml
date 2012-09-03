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
              val newLocalID : unit -> VarID.id
              val newExternalID : unit -> ExternalVarID.id
          end
  =
struct
   type stamps = ExternalVarID.id

   fun init stamps = ExternalVarID.init stamps
       
   fun getCounterStamps () = ExternalVarID.reset ()

   fun newLocalID () = VarID.generate ()

   fun newExternalID () = 
        ExternalVarID.generate ()

end
