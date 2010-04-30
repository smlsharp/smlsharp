(**
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: Counters.sml,v 1.1 2008/05/08 09:06:03 katsu Exp $
 *)
structure Counters 
          : sig
              type stamp
              type counter

              val init : stamp -> unit
              val getCounter : unit -> counter
              val getCounterStamp : unit -> stamp
              val newVarName : unit -> string
          end
  =
struct
   type stamp = int
   type counter = VarNameSequence.sequence

   val counterRef = ref NONE : counter option ref

   fun init stamp =
       counterRef := SOME (VarNameSequence.generateSequence stamp)

   fun getCounter () = 
       case !counterRef of
           NONE => raise Control.Bug "counter is not initialized!"
         | SOME counter => counter

   fun newVarName () = Vars.freshNameFromSequence (getCounter())

   fun getCounterStamp () = VarNameSequence.peek (getCounter())
end
