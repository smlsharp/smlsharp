(**
 * @copyright (c) 2006, Tohoku niversity.
 * @author Liu Bochao
 * @version $Id: Counters.sml,v 1.12 2008/08/06 17:23:41 ohori Exp $
 *)
structure Counters : 
          sig
              val newLocalID : unit -> VarID.id
              val newExternalID : unit -> ExVarID.id
          end
  =
struct
   fun newLocalID () = VarID.generate ()
   fun newExternalID () = 
        ExVarID.generate ()
end
