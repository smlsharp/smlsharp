(**
 * @copyright (c) 2006, Tohoku niversity.
 * @author Liu Bochao
 * @version $Id: Counters.sml,v 1.4 2008/08/06 17:23:39 ohori Exp $
 *)
structure Counters : 
          sig
              type stamp
(*
              type counter
*)                   
              val init : stamp -> unit
              val getCounterStamp : unit -> stamp
              val newLocalId : unit -> LocalVarID.id
          end
  =
struct
   type stamp  = LocalVarID.id

(*
   type counter = LocalVarIDSequence.sequence

   val counterRef = ref NONE : counter option ref

   fun init stamp =
       counterRef := SOME (LocalVarIDSequence.generateSequence stamp)

   fun getCounter () = 
       case !counterRef of
           NONE => raise Control.Bug "counter is not initilized"
         | SOME counter => counter

   fun getCounterStamp () =
       LocalVarIDSequence.peek (getCounter())

   fun newLocalId () = 
       LocalVarIDSequence.generate (getCounter())
*)

   fun init stamp = LocalVarIDGen.init stamp

   fun getCounterStamp () = LocalVarIDGen.reset ()

   fun newLocalId () = LocalVarIDGen.generate ()
end
