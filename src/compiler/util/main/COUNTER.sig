(**
 * Copyright (c) 2006, Tohoku University.
 *
 * counter module.
 * @author YAMATODANI Kiyoshi
 * @version $Id: COUNTER.sig,v 1.6 2006/02/18 04:59:38 ohori Exp $
 *)
signature COUNTER =
sig

  (***************************************************************************)

  datatype counterSetOrder = ORDER_BY_NAME | ORDER_OF_ADDITION

  datatype counter =
           CounterSet of counterSet
         | AccumulationCounter of accumulationCounter
         | MinMaxCounter of minMaxCounter
         | ElapsedTimeCounter of elapsedTimeCounter
  withtype accumulationCounter =
           {
             name : string,
             inc : unit -> unit,
             dec : unit -> unit,
             add : int -> unit,
             sub : int -> unit,
             getValue : unit -> int,
             reset : unit -> unit
           }
  and minMaxCounter =
      {
        name : string,
        getMax : unit -> int,
        getMin : unit -> int,
        set : int -> unit,
        reset : unit -> unit
      }
  and elapsedTimeCounter =
      {
        name : string,
        start : unit -> unit,
        stop : unit -> unit,
        reset : unit -> unit,
        getTime : unit -> Time.time
      }
  and counterSet =
      {
        name : string,
        addAccumulation : string -> counter,
        addMinMax : string -> counter,
        addElapsedTime : string -> counter,
        addSet : string * counterSetOrder -> counter,
        listCounters : counterSetOrder -> counter list,
        find : string -> counter option,
        reset : unit -> unit
      }

  val dump : unit -> string

  val root : counterSet

  (***************************************************************************)

end
