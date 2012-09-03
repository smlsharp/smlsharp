(**
 * counters which records the number of occurrences of events in the runtime.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: RuntimeCounters.sml,v 1.4 2007/08/17 07:01:15 ohori Exp $
 *)
structure RuntimeCounters =
struct

  (***************************************************************************)

  local
    structure C = Counter
  in 

  val C.CounterSetInternal VMCounterSet = #addSet C.root ("VM", C.ORDER_OF_ADDITION)
  val C.CounterSetInternal instructionCounterSet =
      #addSet VMCounterSet ("Instruction", C.ORDER_BY_NAME)
  val totalInstructionsCounter =
      #addAccumulation instructionCounterSet "total"

  end

  (***************************************************************************)

end
