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
   type stamps = int

   fun init (stamps:stamps) =
       BoundTypeVarID.init stamps

   fun getCounterStamps () = BoundTypeVarID.reset ()

   fun newVarName () = VarName.generate () 
end
