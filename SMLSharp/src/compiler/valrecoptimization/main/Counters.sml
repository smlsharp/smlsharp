(**
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: Counters.sml,v 1.4 2008/08/06 17:23:41 ohori Exp $
 *)
structure Counters 
          : sig
              type stamp
              val init : stamp -> unit
              val getCounterStamp : unit -> stamp
              val newVarName : unit -> string
          end
  =
struct
   type stamp = VarNameID.id

   fun init stamp = VarNameGen.init stamp

   fun getCounterStamp () = VarNameGen.reset ()

   fun newVarName () = VarNameGen.generate ()
end
