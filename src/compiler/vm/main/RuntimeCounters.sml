(**
 * Copyright (c) 2006, Tohoku University.
 *
 * counters which records the number of occurrences of events in the runtime.
 * @author YAMATODANI Kiyoshi
 * @version $Id: RuntimeCounters.sml,v 1.2 2006/02/18 04:59:40 ohori Exp $
 *)
structure RuntimeCounters =
struct

  (***************************************************************************)

  local
    structure C = Counter
  in 

  val C.CounterSet VMCounterSet = #addSet C.root ("VM", C.ORDER_OF_ADDITION)
  val C.CounterSet instructionCounterSet =
      #addSet VMCounterSet ("Instruction", C.ORDER_BY_NAME)
  val C.AccumulationCounter totalInstructionsCounter =
      #addAccumulation instructionCounterSet "total"

  end

  (***************************************************************************)

end
