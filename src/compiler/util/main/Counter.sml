(**
 * counter module.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 *)
structure Counter : COUNTER =
struct

  val TitleCOLUMNWIDTH = 23
  val NumCOLUMNWIDTH = 12
  fun titleColumn s = StringCvt.padRight #" " TitleCOLUMNWIDTH s
  fun numColumn s = (StringCvt.padLeft #" " NumCOLUMNWIDTH s ^ " ")

  datatype counterSetOrder = ORDER_BY_NAME | ORDER_OF_ADDITION | ORDER_BY_TIME

  type accumulationCounter =
   {
    name : string,
    toString : counterSetOrder -> string -> string,
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
     toString : counterSetOrder -> string -> string,
     set : int -> unit,
     reset : unit -> unit,
     getMin : unit -> int,
     getMax : unit -> int
     }
  type elapsedTimeCounter =
    {
     name : string,
     toString : counterSetOrder -> string -> string,
     start : unit -> unit,
     stop : unit -> unit,
     reset : unit -> unit,
     getTime : unit -> Time.time
     }

  datatype counterSetInternal =
    CounterSetInternal of      
    {
      name : string,
      addAccumulation : string -> accumulationCounter,
      addMinMax : string -> minMaxCounter,
      addElapsedTime : string -> elapsedTimeCounter,
      addSet : string -> counterSetInternal,
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
      addSet : string -> counterSetInternal,
      listCounters : counterSetOrder -> counterInternal list,
      find : string -> counterInternal option,
      reset : unit -> unit
      }

  type counter =
    {
     counterInternal : counterInternal,
     toString : counterSetOrder -> string -> string,
     reset : unit -> unit
     }

  structure CounterTimeOrd = struct
     type ord_key = counter
     fun compare ({counterInternal=c1, ...}:counter,{counterInternal=c2, ...}:counter) =
         case (c1,c2) of
           (AccumulationCounter {name=n1, getValue=gv1,...},
            AccumulationCounter {name=n2,getValue=gv2,...}) => 
           (case Int.compare(gv1 (), gv2 ()) of 
              EQUAL => String.compare(n1,n2)
            | x => x)
         | (AccumulationCounter _, _) => LESS
         | (MinMaxCounter  {name=n1, getMax=gm1,...},
            MinMaxCounter  {name=n2, getMax=gm2,...}) =>
           (case Int.compare(gm1 (), gm2 ()) of 
              EQUAL => String.compare(n1,n2)
            | x => x)
         | (MinMaxCounter _, AccumulationCounter _) => GREATER
         | (MinMaxCounter _, _) => LESS
         | (ElapsedTimeCounter {name=n1, getTime=gt1,...},
            ElapsedTimeCounter {name=n2, getTime=gt2,...}) =>
           (case Time.compare(gt1 (), gt2 ()) of 
              EQUAL => String.compare(n1,n2)
            | x => x)
         | (ElapsedTimeCounter _, AccumulationCounter _) => GREATER
         | (ElapsedTimeCounter _, MinMaxCounter _) => GREATER
         | (ElapsedTimeCounter _, CounterSet _) => LESS
         | (CounterSet (CounterSetInternal{name=n1, ...}),
            CounterSet (CounterSetInternal{name=n2, ...})) =>
           String.compare(n1, n2)
         | (CounterSet _, _) => GREATER
  end
  structure CounterTimeSet = BinarySetFn(CounterTimeOrd)

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
    fun toString name counter (order:counterSetOrder) indent =
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
    fun toString name {min, max} (order:counterSetOrder) indent =
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
    fun start name ({start, ...} : counterRep) () = 
        (
          if !Control.printTimer
          then print ("start timer " ^ name ^ "\n") else ();
          start := SOME(Time.now ())
        )
    fun stop name ({time, start, ...} : counterRep) () =
        case !start of
          NONE => () (* ignore *)
        | SOME startTime =>
          (
            time := (Time.+(!time, Time.-(Time.now (), startTime)));
            start := NONE;
            if !Control.printTimer
            then print ("stop timer " ^ name ^ " : "
                        ^ Time.toString (!time) ^ " sec\n")
            else ()
          )
          handle Time.Time => () (* ignore error *)
               | General.Overflow => ()
    fun reset ({time, start} : counterRep) () =
        (time := INITIAL_VALUE; start := NONE)
    fun toString name ({time, ...} : counterRep) (order:counterSetOrder) indent =
        let 
          fun toString f = LargeInt.toString(f (!time)) handle _ => "-"
          val name = titleColumn name
          val seconds = numColumn (toString Time.toSeconds)
          val millis = numColumn (toString Time.toMilliseconds)
          val micro = numColumn (toString Time.toMicroseconds)
        in
          indent ^ name ^ " = "
          ^ seconds
          ^ millis
          ^ micro
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
            start = start name counter,
            stop = stop name counter,
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
    fun addCounter1 counters (name, counter) =
        let
          val counterMap = #1 (!counters)
          val indexMap = #2 (!counters)
        in
        counters :=
        (
          SEnv.insert (counterMap, name, counter),
          IEnv.insert (indexMap, IEnv.numItems indexMap, name)
        )
        end
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
        | ORDER_BY_TIME =>
          let
            val counterTimeSet = 
                SEnv.foldr 
                  (fn (counter, counterTimeSet) =>
                      CounterTimeSet.add (counterTimeSet, counter)
                  )
                  CounterTimeSet.empty 
                  counterMap
            val counters = CounterTimeSet.listItems counterTimeSet
            val counters =
                if List.length counters > !Control.profileMaxPhases then
                  List.take(List.rev counters, !Control.profileMaxPhases)
                else List.rev counters
          in
            counters
          end
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
    fun toString name counters (order:counterSetOrder) indent =
        let
          val INDENT_UNIT = "  "
          fun toStr ({toString, counterInternal = CounterSet _, ...} : counter) =
              toString order (indent ^ INDENT_UNIT)
            | toStr {toString, ...} =
              (toString order (indent ^ INDENT_UNIT)) ^ "\n"
          val title =
              case name of 
                "elapsed time" => 
                "              " ^
                numColumn "seconds" ^
                numColumn "millis" ^
                numColumn "micro" 
              | _ => ""
          fun dumpCounter indent counters =
              concat (map toStr (listCounters counters order))
        in
          indent ^ name ^ title ^ "\n" ^ 
          (dumpCounter indent counters)
        end
    fun reset counters () =
        app
            (fn {reset, ...} : counter => reset ())
            (listCounters counters ORDER_OF_ADDITION)
    fun addSet counters name =
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
                toString = toString name newCounters,
                reset = reset newCounters,
                counterInternal = CounterSet newCounterSet
              }
        in 
          addCounter counters (name, newCounterInternal); 
          newCounterSet
        end

    val rootSet = createEmptyCounters ()
  in
    val CounterSetInternal root = addSet rootSet "/"
    fun dump () = 
        #toString (hd(listCounters rootSet ORDER_OF_ADDITION)) ORDER_BY_TIME ""
    val reset = fn () => reset rootSet ()
  end

  val CounterSetInternal TopCounterSet =
      #addSet root "Top"
  val CounterSetInternal ElapsedCounterSet =
      #addSet TopCounterSet "elapsed time"

(* elapsed time counters *)
  val parseTimeCounter =
      #addElapsedTime ElapsedCounterSet "parse"
  val loadFileTimeCounter =
      #addElapsedTime ElapsedCounterSet "loadfile"
  val generateMainTimeCounter =
      #addElapsedTime ElapsedCounterSet "generateMain"
  val elaborationTimeCounter =
      #addElapsedTime ElapsedCounterSet "elaboration"
  val nameEvaluationTimeCounter =
      #addElapsedTime ElapsedCounterSet "name eval"
  val valRecOptimizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "val rec optimize"
  val fundeclElaborationTimeCounter =
      #addElapsedTime ElapsedCounterSet "fundecl optimize"
  val typeInferenceTimeCounter =
      #addElapsedTime ElapsedCounterSet "type inference"
  val printerGenerationTimeCounter =
      #addElapsedTime ElapsedCounterSet "printer generation"
  val UncurryOptimizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "uncurry optimize"
  val TypedCalcOptimizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "typedcalc optimize"
  val matchCompilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "match compilation"
  val RecordCalcOptimizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "recordcalc optimize"
  val sqlCompilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "SQL compilation"
  val ffiCompilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "FFI compilation"
  val recordCompilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "record compilation"
  val datatypeCompilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "datatype compilation"
  val staticAnalysisTimeCounter =
      #addElapsedTime ElapsedCounterSet "static annalysis"
  val recordUnboxingTimeCounter =
      #addElapsedTime ElapsedCounterSet "record unboxing"
(*
  val inliningTimeCounter =
      #addElapsedTime ElapsedCounterSet "inlining"
  val mvOptimizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "multiple value optimization"
*)
  val bitmapCompilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "bitmap compilation"
  val bitmapANormalizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "bitmap A-normlization"
  val bitmapANormalReorderTimeCounter =
      #addElapsedTime ElapsedCounterSet "bitmap A-normal reorder"
  val typeCheckBitmapANormalTimeCounter =
      #addElapsedTime ElapsedCounterSet "typecheck bitmapAN"
  val closureConversionTimeCounter =
      #addElapsedTime ElapsedCounterSet "closure conversion"
  val callingConventionCompileTimeCounter =
      #addElapsedTime ElapsedCounterSet "calling convention compile"
  val anormalizeTimeCounter =
      #addElapsedTime ElapsedCounterSet "a-normalize"
  val machineCodeGenTimeCounter = 
      #addElapsedTime ElapsedCounterSet "machine code gen"
  val insertCheckGCTimeCounter = 
      #addElapsedTime ElapsedCounterSet "insert check gc"
  val stackAllocationTimeCounter = 
      #addElapsedTime ElapsedCounterSet "stack allocation"
  val llvmGenTimeCounter = 
      #addElapsedTime ElapsedCounterSet "llvmgen"
  val llvmEmitTimeCounter = 
      #addElapsedTime ElapsedCounterSet "llvm emit"
  val llvmOutputTimeCounter = 
      #addElapsedTime ElapsedCounterSet "llvm output"
  val toYAANormalTimeCounter =
      #addElapsedTime ElapsedCounterSet "toYAANormal"
(*
  val functionLocalizeTimeCounter =
      #addElapsedTime ElapsedCounterSet "function localization"
*)
  val anormalOptimizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "anormal optimization"
  val staticAllocationTimeCounter =
      #addElapsedTime ElapsedCounterSet "static allocation"
  val aigenerationTimeCounter =
      #addElapsedTime ElapsedCounterSet "aigeneration"
  val rtlselectTimeCounter =
      #addElapsedTime ElapsedCounterSet "rtl select"
  val rtlTypecheckTimeCounter =
      #addElapsedTime ElapsedCounterSet "rtl typecheck"
  val rtlstabilizeTimeCounter =
      #addElapsedTime ElapsedCounterSet "rtl stabilize"
  val rtlrenameTimeCounter =
      #addElapsedTime ElapsedCounterSet "rtl rename"
  val rtlcoloringTimeCounter =
      #addElapsedTime ElapsedCounterSet "rtl coloring"
  val rtlframeTimeCounter =
      #addElapsedTime ElapsedCounterSet "rtl frame"
  val rtlemitTimeCounter =
      #addElapsedTime ElapsedCounterSet "rtl emit"
  val rtlasmgenTimeCounter =
      #addElapsedTime ElapsedCounterSet "rtl asmgen"
  val rtlasmprintTimeCounter =
      #addElapsedTime ElapsedCounterSet "rtl asmprint"
  val assembleTimeCounter =
      #addElapsedTime ElapsedCounterSet "assemble"
  val compilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "compilation"

  (*  main stuff **)
 val parseArgsTimeCounter = 
      #addElapsedTime ElapsedCounterSet "parseArgs"
 val compileArgsTimeCounter = 
      #addElapsedTime ElapsedCounterSet "compileArgs"
 val printHelpTimeCounter = 
      #addElapsedTime ElapsedCounterSet "printHelp"
 val loadInterfaceTimeCounter = 
      #addElapsedTime ElapsedCounterSet "loadInterface"
 val compileFileTimeCounter = 
      #addElapsedTime ElapsedCounterSet "compileFile"
 val loadSMITimeCounter = 
      #addElapsedTime ElapsedCounterSet "loadSMI"
 val linkTimeCounter = 
      #addElapsedTime ElapsedCounterSet "link"
 val generateDependTimeCounter = 
      #addElapsedTime ElapsedCounterSet "generateDepend"

end
