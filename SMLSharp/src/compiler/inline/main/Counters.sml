(**
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: Counters.sml,v 1.4 2008/08/06 17:23:39 ohori Exp $
 *)
structure Counters :
          sig
              type stamps
              val init : stamps -> unit
              val newLocalID : unit -> VarID.id
              val getCountersStamps : unit -> stamps 
          end
  =
struct
   type stamps =int

   fun init stamps = BoundTypeVarID.init stamps

   fun newLocalID () = VarID.generate ()

   fun getCountersStamps () = BoundTypeVarID.reset ()
end
