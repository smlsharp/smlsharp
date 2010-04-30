(**
 * counter module.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Counter.sml,v 1.16 2008/08/06 07:59:47 ohori Exp $
 *)
structure Counter : COUNTER =
struct

  (***************************************************************************)

 type accumulationCounter =
   {
    name : string,
    toString : string -> string,
    inc : unit -> unit,
    dec : unit -> unit,
    add : int -> unit,
    sub : int -> unit,
    reset : unit -> unit,
    getValue : unit -> int
    }
  type minMaxCounter =
    {
     name : string,
     toString : string -> string,
     set : int -> unit,
     reset : unit -> unit,
     getMin : unit -> int,
     getMax : unit -> int
     }
  type elapsedTimeCounter =
    {
     name : string,
     toString : string -> string,
     start : unit -> unit,
     stop : unit -> unit,
     reset : unit -> unit,
     getTime : unit -> Time.time
     }

  datatype counterSetOrder = ORDER_BY_NAME | ORDER_OF_ADDITION

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

  type counterSet = 
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

  type counter =
    {
     counterInternal : counterInternal,
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
           name = name,
           toString = toString name counter,
           inc = inc counter,
           dec = dec counter,
           add = add counter,
           sub = sub counter,
           reset = reset counter,
           getValue = getValue counter
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
            name = name,
            getMin = getMin counter,
            getMax = getMax counter,
            set = set counter,
            reset = reset counter
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
            name = name,
            start = start counter,
            stop = stop counter,
            reset = reset counter,
            getTime = getTime counter
          }
        end
  end

  (*
   * counterSet
   *)
  local
    type counterSetRep = (counter SEnv.map * string IEnv.map) ref
    fun createEmptyCounters () = ref (SEnv.empty, IEnv.empty) : counterSetRep
    fun addCounter (counters as ref (counterMap, indexMap)) (name, counter) =
        counters :=
        (
          SEnv.insert (counterMap, name, counter),
          IEnv.insert (indexMap, IEnv.numItems indexMap, name)
        )
    fun findCounter (ref (counterMap, _)) name =
        SEnv.find (counterMap, name) : counter option
    fun listCounters (ref (counterMap, indexMap)) order =
        case order of
          ORDER_BY_NAME => SEnv.listItems counterMap
        | ORDER_OF_ADDITION =>
          IEnv.foldr
              (fn (name, counters) =>
                  (
                   case (SEnv.find (counterMap, name)) of
                      SOME counter => counter
                    | _ =>
                      raise
                        Fail
                            "Bug:indexMap and counterMap mismatch \
                            \: (util/main/Counter.sml)"
                  )  
                  :: counters)
              []
              indexMap

    (**********)

    fun addAccumulation counters name =
        let
          val newAccumulationCounter as {toString, reset,...} = createAccumulationCounter name
          val counter =
            {
             counterInternal = AccumulationCounter newAccumulationCounter,
             toString = toString,
             reset = reset
             }
        in 
          addCounter counters (name, counter); 
          newAccumulationCounter
        end
    fun addMinMax counters name =
        let
          val newMinMaxCounter as {toString, reset,...} = createMinMaxCounter name
          val counter =
            {
             counterInternal = MinMaxCounter newMinMaxCounter,
             toString = toString,
             reset = reset
             }
        in 
          addCounter counters (name, counter); 
          newMinMaxCounter
        end
    fun addElapsedTime counters name =
        let
          val newElapsedTimeCounter as {toString, reset,...}   = createElapsedTimeCounter name
          val counter =
            {
             counterInternal = ElapsedTimeCounter newElapsedTimeCounter,
             toString = toString,
             reset = reset
             }
        in 
          addCounter counters (name, counter); 
          newElapsedTimeCounter
        end
    fun find counters name = Option.map #counterInternal (findCounter counters name)
    fun toString name counters order indent =
        let
          val INDENT_UNIT = "  "
          fun toStr ({toString, counterInternal = CounterSet _, ...} : counter) =
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
            (fn {reset, ...} : counter => reset ())
            (listCounters counters ORDER_BY_NAME)
    fun addSet counters (name, order) =
        let
          val newCounters = createEmptyCounters ()
          val newCounterSet = 
            CounterSetInternal
            {
             name = name,
             addAccumulation = addAccumulation newCounters,
             addMinMax = addMinMax newCounters,
             addElapsedTime = addElapsedTime newCounters,
             addSet = addSet newCounters,
             listCounters = (map #counterInternal) o (listCounters newCounters),
             find = find newCounters,
             reset = reset newCounters
             }
          val newCounterInternal =
              {
                toString = toString name newCounters order,
                reset = reset newCounters,
                counterInternal = CounterSet newCounterSet
              }
        in 
          addCounter counters (name, newCounterInternal); 
          newCounterSet
        end

    val rootSet = createEmptyCounters ()
  in
    val CounterSetInternal root = addSet rootSet ("/", ORDER_OF_ADDITION) 
    fun dump () = #toString (hd(listCounters rootSet ORDER_OF_ADDITION)) ""
  end

  (***************************************************************************)

end;

