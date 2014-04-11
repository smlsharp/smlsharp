(**
 * counter module.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: COUNTER.sig,v 1.9 2007/08/14 04:07:15 ohori Exp $
 *)
signature COUNTER =
sig

  (***************************************************************************)

  datatype counterSetOrder = ORDER_BY_NAME | ORDER_OF_ADDITION | ORDER_BY_TIME

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

  type counterSet
  type counter

  val dump : unit -> string
  val reset : unit -> unit

  (***************************************************************************)
  val root : counterSet
  val TopCounterSet : counterSet
  val ElapsedCounterSet : counterSet
  val parseTimeCounter : elapsedTimeCounter
  val loadFileTimeCounter : elapsedTimeCounter
  val generateMainTimeCounter : elapsedTimeCounter
  val elaborationTimeCounter : elapsedTimeCounter
  val nameEvaluationTimeCounter : elapsedTimeCounter
  val valRecOptimizationTimeCounter : elapsedTimeCounter
  val fundeclElaborationTimeCounter : elapsedTimeCounter
  val typeInferenceTimeCounter : elapsedTimeCounter
  val printerGenerationTimeCounter : elapsedTimeCounter
  val UncurryOptimizationTimeCounter : elapsedTimeCounter
  val TypedCalcOptimizationTimeCounter : elapsedTimeCounter
  val RecordCalcOptimizationTimeCounter : elapsedTimeCounter
  val matchCompilationTimeCounter : elapsedTimeCounter
  val sqlCompilationTimeCounter : elapsedTimeCounter
  val ffiCompilationTimeCounter : elapsedTimeCounter
  val recordCompilationTimeCounter : elapsedTimeCounter
  val datatypeCompilationTimeCounter : elapsedTimeCounter
  val staticAnalysisTimeCounter : elapsedTimeCounter
  val recordUnboxingTimeCounter : elapsedTimeCounter
  val bitmapCompilationTimeCounter : elapsedTimeCounter
  val bitmapANormalizationTimeCounter : elapsedTimeCounter
  val bitmapANormalReorderTimeCounter : elapsedTimeCounter
  val typeCheckBitmapANormalTimeCounter : elapsedTimeCounter
  val closureConversionTimeCounter : elapsedTimeCounter
  val callingConventionCompileTimeCounter : elapsedTimeCounter
  val anormalizeTimeCounter : elapsedTimeCounter
  val machineCodeGenTimeCounter : elapsedTimeCounter
  val insertCheckGCTimeCounter : elapsedTimeCounter
  val stackAllocationTimeCounter : elapsedTimeCounter
  val llvmGenTimeCounter : elapsedTimeCounter
  val llvmEmitTimeCounter : elapsedTimeCounter
  val llvmOutputTimeCounter : elapsedTimeCounter
  val toYAANormalTimeCounter : elapsedTimeCounter
  val anormalOptimizationTimeCounter : elapsedTimeCounter
  val staticAllocationTimeCounter : elapsedTimeCounter
  val aigenerationTimeCounter : elapsedTimeCounter
  val rtlselectTimeCounter : elapsedTimeCounter
  val rtlTypecheckTimeCounter : elapsedTimeCounter
  val rtlstabilizeTimeCounter : elapsedTimeCounter
  val rtlrenameTimeCounter : elapsedTimeCounter
  val rtlcoloringTimeCounter : elapsedTimeCounter
  val rtlframeTimeCounter : elapsedTimeCounter
  val rtlemitTimeCounter : elapsedTimeCounter
  val rtlasmgenTimeCounter : elapsedTimeCounter
  val rtlasmprintTimeCounter : elapsedTimeCounter
  val assembleTimeCounter : elapsedTimeCounter
  val compilationTimeCounter : elapsedTimeCounter
  val parseArgsTimeCounter : elapsedTimeCounter
  val compileArgsTimeCounter : elapsedTimeCounter
  val printHelpTimeCounter : elapsedTimeCounter
  val loadInterfaceTimeCounter : elapsedTimeCounter
  val compileFileTimeCounter : elapsedTimeCounter
  val loadSMITimeCounter : elapsedTimeCounter
  val linkTimeCounter : elapsedTimeCounter
  val generateDependTimeCounter : elapsedTimeCounter

end
