(**
 * counter module.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: COUNTER.sig,v 1.8 2006/11/03 11:02:50 kiyoshiy Exp $
 *)
signature COUNTER =
sig

  (***************************************************************************)

  datatype counterSetOrder = ORDER_BY_NAME | ORDER_OF_ADDITION

  type accumulationCounter
  type minMaxCounter
  type elapsedTimeCounter
  type counterSet
  datatype counter =
           CounterSet of counterSet
         | AccumulationCounter of accumulationCounter
         | MinMaxCounter of minMaxCounter
         | ElapsedTimeCounter of elapsedTimeCounter

  val dump : unit -> string

  val root : counterSet

  (***************************************************************************)

end
