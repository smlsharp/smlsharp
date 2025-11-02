(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure Analyzers =
struct
  val ignore2 = fn _ => ignore

  type symbol = Symbol.symbol
  type longsymbol = Symbol.longsymbol
  type idstatus = IDCalc.idstatus

  val startNameRefTracing = ref ignore
  val stopNameRefTracing = ref ignore
  val stopBindTracing = ref ignore
  val pushInterfaceTracer = ref ignore
  val popInterfaceTracer = ref ignore
  val analyzeFunRef = ref ignore
  val analyzeIdRef = ref ignore
  val analyzeIdRefForUP = ref ignore
  val analyzeSigRef = ref ignore
  val analyzeStrRef = ref ignore
  val analyzeTstrRef = ref ignore
  val analyzeTstrRefForUP = ref ignore
  val insertUPRefMap = ref ignore
  val provideCon = ref ignore
  val provideFun = ref ignore
  val provideId = ref ignore
  val provideStr = ref ignore
  val provideTstr = ref ignore
  val rebindFun = ref ignore2
  val rebindId = ref ignore2
  val rebindSig = ref ignore2
  val rebindStr = ref ignore2
  val rebindTstr = ref ignore2
end
