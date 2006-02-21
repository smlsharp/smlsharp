(**
 * Copyright (c) 2006, Tohoku University.
 *
 * counter module.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Counter.sml,v 1.10 2006/02/18 04:59:38 ohori Exp $
 *)
structure Counter :> COUNTER =
struct

  (***************************************************************************)

  datatype counterSetOrder = ORDER_BY_NAME | ORDER_OF_ADDITION

  datatype counter =
           AccumulationCounter of accumulationCounter
         | MinMaxCounter of minMaxCounter
         | ElapsedTimeCounter of elapsedTimeCounter
         | CounterSet of counterSet

  withtype accumulationCounter =
           {
             name : string,
             inc : unit -> unit,
             dec : unit -> unit,
             add : int -> unit,
             sub : int -> unit,
             reset : unit -> unit,
             getValue : unit -> int
           }
  and minMaxCounter =
      {
        name : string,
        set : int -> unit,
        reset : unit -> unit,
        getMin : unit -> int,
        getMax : unit -> int
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
(*
  datatype counter =
           AccumulationCounter of
           {
             name : string,
             inc : unit -> unit,
             dec : unit -> unit,
             add : int -> unit,
             sub : int -> unit,
             reset : unit -> unit,
             getValue : unit -> int
           }
         | MinMaxCounter of
           {
             name : string,
             set : int -> unit,
             reset : unit -> unit,
             getMin : unit -> int,
             getMax : unit -> int
           }
         | CounterSet of
           {
             name : string,
             addAccumulation : string -> counter,
             addMinMax : string -> counter,
             addSet : string -> counter
           }
*)
  type internal =
       {
         counter : counter,
         toString : string -> string,
         reset : unit -> unit
       }

  (***************************************************************************)

  (*
   * accumulationCounter
   *)
  local
    val INITIAL_VALUE = 0
    fun add value number =
	(value := (!value) + number) handle General.Overflow => ()
    fun sub counter number = add counter (~number)
    fun inc counter () = add counter 1
    fun dec counter () = sub counter 1
    fun reset counter () = counter := INITIAL_VALUE
    fun getValue counter () = !counter
    fun toString name counter indent =
        indent ^ name ^ " = " ^ (Int.toString (!counter))
  in
    fun createAccumulationCounter name =
        let val counter = ref INITIAL_VALUE
        in
          {
            toString = toString name counter,
            reset = reset counter,
            counter = 
            AccumulationCounter
                {
                  name = name,
                  inc = inc counter,
                  dec = dec counter,
                  add = add counter,
                  sub = sub counter,
                  reset = reset counter,
                  getValue = getValue counter
                }
          }
        end
  end

  (*
   * minMaxCounter
   *)
  local
    val INITIAL_VALUE = 0
    fun getMin {min, max} () = !min
    fun getMax {min, max} () = !max
    fun set {min, max} value =
        if value < !min
        then min := value
        else
          if !max < value
          then max := value
          else ()
    fun reset {min, max} () = (min := INITIAL_VALUE; max := INITIAL_VALUE)
    fun toString name {min, max} indent =
        indent ^ name ^ " = "
        ^ "{min = " ^ (Int.toString (!min))
        ^ ", max = " ^ (Int.toString (!max)) ^ "}"
  in
    fun createMinMaxCounter name =
        let
          val minCounter = ref INITIAL_VALUE
          val maxCounter = ref INITIAL_VALUE
          val counter = {min = minCounter, max = maxCounter}
        in
          {
            toString = toString name counter,
            reset = reset counter,
            counter =
            MinMaxCounter
              {
                name = name,
                getMin = getMin counter,
                getMax = getMax counter,
                set = set counter,
                reset = reset counter
              }
          }
        end
  end

  (*
   * elapsedTimeCounter
   *)
  local
    type counterRep = {time : Time.time ref, start : Time.time option ref}
    val INITIAL_VALUE = Time.zeroTime
    fun getTime ({time, ...} : counterRep) () = !time
    fun start ({start, ...} : counterRep) () = 
        start := SOME(Time.now ())
    fun stop ({time, start, ...} : counterRep) () =
        case !start of
          NONE => () (* ignore *)
        | SOME startTime =>
          (
            time := (Time.+(!time, Time.-(Time.now (), startTime)));
            start := NONE
          )
          handle Time.Time => () (* ignore error *)
               | General.Overflow => ()
    fun reset ({time, start} : counterRep) () =
        (time := INITIAL_VALUE; start := NONE)
    fun toString name ({time, ...} : counterRep) indent =
        let fun toString f = LargeInt.toString(f (!time)) handle _ => "-"
        in
          indent ^ name ^ " = "
          ^ "{seconds = " ^ (toString Time.toSeconds)
          ^ ", millis = " ^ (toString Time.toMilliseconds)
          ^ ", micro = " ^ (toString Time.toMicroseconds ) ^ "}"
        end
          handle General.Overflow => "<Overflow>"
  in
    fun createElapsedTimeCounter name =
        let
          val counter =
              {time = ref INITIAL_VALUE, start = ref NONE} : counterRep
        in
          {
            toString = toString name counter,
            reset = reset counter,
            counter =
            ElapsedTimeCounter
              {
                name = name,
                start = start counter,
                stop = stop counter,
                reset = reset counter,
                getTime = getTime counter
              }
          }
        end
  end

  (*
   * counterSet
   *)
  local
    type counterSet = (internal SEnv.map * string IEnv.map) ref

    fun createEmptyCounters () = ref (SEnv.empty, IEnv.empty) : counterSet
    fun addCounter (counters as ref (counterMap, indexMap)) (name, counter) =
        counters :=
        (
          SEnv.insert (counterMap, name, counter),
          IEnv.insert (indexMap, IEnv.numItems indexMap, name)
        )
    fun findCounter (ref (counterMap, _)) name =
        SEnv.find (counterMap, name) : internal option
    fun listCounters (ref (counterMap, indexMap)) order =
        case order of
          ORDER_BY_NAME => SEnv.listItems counterMap
        | ORDER_OF_ADDITION =>
          IEnv.foldr
              (fn (name, counters) =>
                  valOf(SEnv.find (counterMap, name)) :: counters)
              []
              indexMap

    (**********)

    fun addAccumulation counters name =
        let
          val newCounterInternal as {counter = newCounter, ...} =
              createAccumulationCounter name
        in addCounter counters (name, newCounterInternal); newCounter end
    fun addMinMax counters name =
        let
          val newCounterInternal as {counter = newCounter, ...} =
              createMinMaxCounter name
        in addCounter counters (name, newCounterInternal); newCounter end
    fun addElapsedTime counters name =
        let
          val newCounterInternal as {counter = newCounter, ...} =
              createElapsedTimeCounter name
        in addCounter counters (name, newCounterInternal); newCounter end
    fun find counters name = Option.map #counter (findCounter counters name)
    fun toString name counters order indent =
        let
          val INDENT_UNIT = "  "
          fun toStr ({toString, counter = CounterSet _, ...} : internal) =
              toString (indent ^ INDENT_UNIT)
            | toStr {toString, ...} =
              (toString (indent ^ INDENT_UNIT)) ^ "\n"
          fun dumpCounter indent counters =
              concat (map toStr (listCounters counters order))
        in
          indent ^ name ^ "\n" ^ (dumpCounter indent counters)
        end
    fun reset counters () =
        app
            (fn {reset, ...} : internal => reset ())
            (listCounters counters ORDER_BY_NAME)
    fun addSet counters (name, order) =
        let
          val newCounters = createEmptyCounters ()
          val newCounter = 
              CounterSet
                  {
                    name = name,
                    addAccumulation = addAccumulation newCounters,
                    addMinMax = addMinMax newCounters,
                    addElapsedTime = addElapsedTime newCounters,
                    addSet = addSet newCounters,
                    listCounters = (map #counter) o (listCounters newCounters),
                    find = find newCounters,
                    reset = reset newCounters
                  }
          val newCounterInternal =
              {
                toString = toString name newCounters order,
                reset = reset newCounters,
                counter = newCounter
              }
        in addCounter counters (name, newCounterInternal); newCounter end

    val rootSet = createEmptyCounters ()
  in
  val CounterSet root = addSet rootSet ("/", ORDER_OF_ADDITION)
  fun dump () = #toString (hd(listCounters rootSet ORDER_OF_ADDITION)) ""
  end

  (***************************************************************************)

end;

(*
local
  structure C = Counter
in
val C.CounterSet heapCounterSet = #addSet C.root "Heap"
val C.CounterSet VMCounterSet = #addSet C.root "VM"
val C.CounterSet frameStackCounterSet = #addSet VMCounterSet "Frame"
val C.AccumulationCounter allocFrameCounter =
    #addAccumulation frameStackCounterSet "alloc"
val C.CounterSet callCounterSet = #addSet VMCounterSet "Calls"
val C.AccumulationCounter callStaticCounter =
    #addAccumulation callCounterSet "callStatic"
val C.AccumulationCounter applyCounter =
    #addAccumulation callCounterSet "apply"
end

*)
