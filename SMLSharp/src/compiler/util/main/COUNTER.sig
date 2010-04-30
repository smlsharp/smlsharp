(**
 * counter module.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: COUNTER.sig,v 1.9 2007/08/14 04:07:15 ohori Exp $
 *)
signature COUNTER =
sig

  (***************************************************************************)

  datatype counterSetOrder = ORDER_BY_NAME | ORDER_OF_ADDITION

  type accumulationCounter
  type minMaxCounter
  type elapsedTimeCounter
  datatype counterSetInternal =
    CounterSetInternal of
     {
      name : string,
      addAccumulation : string -> accumulationCounter,
      addMinMax : string -> minMaxCounter,
      addElapsedTime : string -> elapsedTimeCounter,
      addSet : string * counterSetOrder -> counterSetInternal,
      listCounters : counterSetOrder -> counterInternal list,
      find : string -> counterInternal option,
      reset : unit -> unit
      }
  and counterInternal =
      AccumulationCounter of accumulationCounter
    | MinMaxCounter of minMaxCounter
    | ElapsedTimeCounter of elapsedTimeCounter
    | CounterSet of counterSetInternal

  type counterSet
  type counter

  val dump : unit -> string

  val root : counterSet

  (***************************************************************************)

end
