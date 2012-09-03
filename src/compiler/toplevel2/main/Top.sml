(**
 * compiler toplevel
 * @copyright (c) 2010, Tohoku University.
 * @author Atsushi Ohori
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *)
structure Top : TOP =
struct

  open TopData

  val defaultOptions =
      {
        stopAt = NoStop,
        dstfile = NONE,
        baseName = NONE,
        stdPath = nil,
        loadPath = nil,
        asmFlags = nil
      } : toplevelOptions

  fun extendContext ({topEnv, fixEnv, version, builtinDecls} : toplevelContext,
                     {topEnv=newTopEnv, fixEnv=newFixEnv} : newContext) =
      let
        val topEnv = NameEvalEnv.topEnvWithTopEnv (topEnv, newTopEnv)
      in
        {topEnv = topEnv,
         version = version,
         fixEnv = Elaborator.extendFixEnv (fixEnv, newFixEnv),
         builtinDecls = builtinDecls} : toplevelContext
      end
(*
  fun extendVersionEnv
        ({topEnv, fixEnv, versionEnv, builtinDecls} : toplevelContext,
         {topEnv=newTopEnv, fixEnv=newFixEnv} : newContext) =
      {topEnv = topEnv,
       versionEnv = NameEvalEnv.topEnvWithTopEnv (topEnv, newTopEnv),
       fixEnv = fixEnv,
       builtinDecls = builtinDecls} : toplevelContext
*)
  val emptyNewContext =
      {
        topEnv = NameEvalEnv.emptyTopEnv,
        fixEnv = SEnv.empty
      } : newContext

(*
  val Counter.CounterSetInternal TopCounterSet =
      #addSet Counter.root "Top"
  val Counter.CounterSetInternal ElapsedCounterSet =
      #addSet TopCounterSet "elapsed time"

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
  val matchCompilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "match compilation"
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
  val assembleTimeCounter =
      #addElapsedTime ElapsedCounterSet "assemble"
  val compilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "compilation"
*)
  val errorOutput = TextIO.stdErr
  fun printError msg = TextIO.output (errorOutput, msg)
  fun flushError () = TextIO.flushOut errorOutput

  fun printLines title formatter elems =
      (if title = "" then () else (printError title; printError ":\n");
       app (fn elem => (printError (formatter elem); printError "\n")) elems;
       flushError ())

  fun userErrorToString x =
      Control.prettyPrint (UserError.format_errorInfo x)

  fun printWarnings warnings =
      if !Control.printWarning
      then printLines "" userErrorToString warnings
      else ()

  fun printDiagnosis title diagnoses =
      if !Control.printDiagnosis
      then printLines title userErrorToString diagnoses
      else ()

  fun printPhase title =
      if !Control.debugPrint
      then (printError "start phase: "; printError title; printError "\n")
      else ()

  fun printCode flag formatter title codes =
      if !flag andalso !Control.switchTrace
      then printLines title formatter codes
      else ()

  fun printParseResult title code =
      printCode Control.printSource AbsynFormatter.unitParseResultToString
                title code

  fun printAbsyn title code =
      printCode Control.printSource
                (Control.prettyPrint o AbsynInterface.format_compileUnit)
                title code

  fun printPatternCalc title code =
      printCode Control.printPL
                (Control.prettyPrint o PatternCalcInterface.format_compileUnit)
                title code

  fun printIDCalc title code =
      printCode Control.printNE 
                (if !Control.printWithType 
                 then (Control.prettyPrint o IDCalc.formatWithType_icdecl)
                 else (Control.prettyPrint o IDCalc.format_icdecl)
                )
                title code

  fun printVR title code =
      printCode Control.printVR 
                (Control.prettyPrint o IDCalc.format_icdecl)
                title code

  fun printTypedCalc title code =
      printCode Control.printTP
                (if !Control.printWithType
                 then Control.prettyPrint o (TypedCalc.formatWithType_tpdecl nil)
                 else Control.prettyPrint o (TypedCalc.format_tpdecl nil)
                )
                title code

  fun printRecordCalc title code =
      printCode Control.printRC
                (if !Control.printWithType
                 then RecordCalcFormatter.rcdecToString
                 else RecordCalcFormatter.rcdecToStringWithoutType)
                title code

  fun printTypedLambda title code =
      printCode Control.printTL
                (if !Control.printWithType
                 then TypedLambdaFormatter.tldecToStringWithType
                 else TypedLambdaFormatter.tldecToString)
                title code

  fun printAnnotatedCalc title code =
      printCode Control.printAC
                (if !Control.printWithType
                 then AnnotatedCalcFormatter.acdeclToStringWithType
                 else AnnotatedCalcFormatter.acdeclToString)
                title code

  fun printMultipleValueCalc title code =
      printCode Control.printMV MultipleValueCalcFormatter.mvdeclToString
                title code

  fun printBitmapCalc title code =
      printCode Control.printRBU
                (if !Control.printWithType
                 then Control.prettyPrint o BitmapCalc.formatWithType_bcdecl
                 else Control.prettyPrint o BitmapCalc.format_bcdecl)
                title code

  fun printBitmapANormal title code =
      printCode Control.printRBU
                (if !Control.printWithType
                 then Control.prettyPrint o BitmapANormal.formatWithType_baexp
                 else Control.prettyPrint o BitmapANormal.format_baexp)
                title [code]

  fun printClosureANormal title code =
      printCode Control.printRBU
                (Control.prettyPrint o ClosureANormal.format_catopdec)
                title code

  fun printYAANormal title code =
      printCode Control.printAN
                (Control.prettyPrint o YAANormal.format_topdecl)
                title code

  fun printAbstractInstruction2 title code =
      printCode Control.printAI AbstractInstruction2Formatter.programToString
                title [code]

  fun printRTL title code =
      printCode Control.printML (Control.prettyPrint o RTL.format_program)
                title [code]

  fun doParse input =
      let
        val _ = printPhase "Parse"
        val _ = #start Counter.parseTimeCounter()
        val ret = Parser.parse input
        val _ = #stop Counter.parseTimeCounter()
        val _ = printParseResult "Parsed" [ret]
      in
        case ret of
          Absyn.UNIT unit => unit
        | Absyn.EOF =>
          {interface = Absyn.NOINTERFACE, tops = nil, loc = Loc.noloc}
      end

  fun doLoadFile (baseName, stdPath, loadPath) absyn =
      let
        val _ = printPhase "LoadFile"
        val _ = #start Counter.loadFileTimeCounter()
        val ({loadedFiles}, abunit) =
            LoadFile.load
              {baseName=baseName, stdPath=stdPath, loadPath=loadPath}
              absyn
        val _ = #stop Counter.loadFileTimeCounter()
        val _ = printAbsyn "File Loaded" [abunit]
        val interfaceNames =
            {provide = #interfaceName (#interface abunit),
             requires = map #interfaceName (#decls (#interface abunit)),
             depends = loadedFiles}
            : interfaceNames
      in
        (interfaceNames, abunit)
      end

  fun doElaboration fixEnv abunit =
      let
        val _ = printPhase "Elaboration"
        val _ = #start Counter.elaborationTimeCounter()
        val (newFixEnv, plunit, warnings) = Elaborator.elaborate fixEnv abunit
        val _ = #stop Counter.elaborationTimeCounter()
        val _ = printWarnings warnings
        val _ = printPatternCalc "Elaborated" [plunit]
      in
        (newFixEnv, plunit)
      end

  fun doNameEvaluation (topEnv, version, builtinICDecls) plunit =
      let
        val _ = printPhase "NameEval"
        val _ = #start Counter.nameEvaluationTimeCounter()
        val (nameevalTopEnv, icdecls, warnings) =
            NameEval.nameEval {topEnv=topEnv, version=version,
                               systemDecls=builtinICDecls} plunit
        val _ = #stop Counter.nameEvaluationTimeCounter()
        val _ = printWarnings warnings
        val _ = printIDCalc "Name Evaluation" icdecls
      in
        (nameevalTopEnv, icdecls)
      end

  fun doTypeInference icdecls =
      let
        val _ = printPhase "TypeInference"
        val _ = #start Counter.typeInferenceTimeCounter()
        val (typeinfVarE, tpdecs, warnings) = InferTypes.typeinf icdecls
        val _ = #stop Counter.typeInferenceTimeCounter()
        val _ = printWarnings warnings
        val _ = printTypedCalc "Type Inference" tpdecs
      in
        (typeinfVarE, tpdecs)
      end

  fun doPrinterGeneration (topEnv, tpdecs) =
      let
        val _ = printPhase "PrinterGeneration"
        val _ = #start Counter.printerGenerationTimeCounter()
        val (topEnv, externDecls, printDecls) = PrinterGeneration.generate topEnv
        val _ = #stop Counter.printerGenerationTimeCounter()
        val tpdecs = externDecls @ tpdecs @ printDecls
        val _ = printTypedCalc "Printer Generated" 
      in
        (topEnv, tpdecs)
      end

  fun doUncurryOptimization tpdecs =
      let
        val _ = printPhase "UncurryOptimization"
        val _ = #start Counter.UncurryOptimizationTimeCounter()
        val tpdecs = UncurryFundecl.optimize tpdecs
        val _ = #stop Counter.UncurryOptimizationTimeCounter()
        val _ = printTypedCalc "Uncurrying Optimized" tpdecs
      in
        tpdecs
      end

  fun doVALRECOptimization iddecs =
      let
        val _ = printPhase "VALRECOptimization"
        val _ = #start Counter.valRecOptimizationTimeCounter()
        val iddecs = VALREC_Optimizer.optimize iddecs
        val _ = #stop Counter.valRecOptimizationTimeCounter()
        val _ = printVR "VAL REC optimize" iddecs
      in
        iddecs
      end

  fun doFundeclElaboration iddecs =
      let
        val _ = printPhase "FundeclElaboration"
        val _ = #start Counter.fundeclElaborationTimeCounter()
        val iddecs = TransFundecl.transIcdeclList iddecs
        val _ = #stop Counter.fundeclElaborationTimeCounter()
        val _ = printIDCalc "Fundecl Elaboration" iddecs
      in
        iddecs
      end


  fun doMatchCompilation tpdecs =
      let
        val _ = printPhase "MatchCompilation"
        val _ = #start Counter.matchCompilationTimeCounter()
        val (rcdecs, warnings) = MatchCompiler.compile tpdecs
        val _ = #stop Counter.matchCompilationTimeCounter()
        val _ = printRecordCalc "Match Compiled" rcdecs
        val _ = printWarnings warnings
      in
        rcdecs
      end

  fun doSQLCompilation rcdecs =
      let
        val _ = printPhase "SQLCompilation"
        val _ = #start Counter.sqlCompilationTimeCounter()
        val rcdecs = SQLCompilation.compile rcdecs
        val _ = #stop Counter.sqlCompilationTimeCounter()
        val _ = printRecordCalc "SQL Compiled" rcdecs
      in
        rcdecs
      end

  fun doFFICompilation rcdecs =
      let
        val _ = printPhase "FFICompilation"
        val _ = #start Counter.ffiCompilationTimeCounter()
        val rcdecs = FFICompilation.compile rcdecs
        val _ = #stop Counter.ffiCompilationTimeCounter()
        val _ = printRecordCalc "FFI Compiled" rcdecs
      in
        rcdecs
      end

  fun doRecordCompilation rcdecs =
      let
        val _ = printPhase "RecordCompilation"
        val _ = #start Counter.recordCompilationTimeCounter()
        val rcdecs = RecordCompilation.compile rcdecs
        val _ = #stop Counter.recordCompilationTimeCounter()
        val _ = printRecordCalc "Record Compiled" rcdecs
      in
        rcdecs
      end

  fun doDatatypeCompilation rcdecs =
      let
        val _ = printPhase "DatatypeCompilation"
        val _ = #start Counter.datatypeCompilationTimeCounter()
        val tldecs = DatatypeCompilation.compile rcdecs
        val _ = #stop Counter.datatypeCompilationTimeCounter()
        val _ = printTypedLambda "Datatype Compiled" tldecs
      in
        tldecs
      end

(*
  fun doTLTypeCheck (localContext, rcdecs) =
      let
        val diagnoses = TypeCheckTypedLambda.typecheck rcdecs
        val _ = printDiagnosis "TypedLambda Diagnoses" diagnoses
      in
        ()
      end
*)

  fun doStaticAnalysis tldecs =
      let
        val _ = printPhase "StaticAnalysis"
        val _ = #start Counter.staticAnalysisTimeCounter()
        val acdecs = StaticAnalysis.analyse tldecs
        val _ = #stop Counter.staticAnalysisTimeCounter()
        val _ = printAnnotatedCalc "Static Analysis" acdecs
      in
        acdecs
      end

  fun doRecordUnboxing acdecs =
      let
        val _ = printPhase "RecordUnboxing"
        val _ = #start Counter.recordUnboxingTimeCounter()
        val mvdecs =  RecordUnboxing.transform acdecs
        val _ = #stop Counter.recordUnboxingTimeCounter()
        val _ = printMultipleValueCalc "Record Unboxing" mvdecs
      in
        mvdecs
      end

  fun doBitmapCompilation mvdecs =
      let
        val _ = printPhase "BitmapCompilation"
        val _ = #start Counter.bitmapCompilationTimeCounter()
        val bcdecs = BitmapCompilation.compile mvdecs
        val _ = #stop Counter.bitmapCompilationTimeCounter()
        val _ = printBitmapCalc "Bitmap Compiled" bcdecs
      in
        bcdecs
      end

  fun doBitmapANormalization bcdecs =
      let
        val _ = printPhase "BitmapANormalization"
        val _ = #start Counter.bitmapANormalizationTimeCounter()
        val baexp = BitmapANormalization.normalize bcdecs
        val _ = #stop Counter.bitmapANormalizationTimeCounter()
        val _ = printBitmapANormal "Bitmap ANormalized" baexp
      in
        baexp
      end

  fun doBitmapANormalReorder baexp =
      let
        val _ = printPhase "BitmapANormalReorder"
        val _ = #start Counter.bitmapANormalReorderTimeCounter()
        val baexp = BitmapANormalReorder.optimize baexp
        val _ = #stop Counter.bitmapANormalReorderTimeCounter()
        val _ = printBitmapANormal "BitmapANormal Reordered" baexp
      in
        baexp
      end

  fun doClosureConversion baexp =
      let
        val _ = printPhase "ClosureConversion"
        val _ = #start Counter.closureConversionTimeCounter()
        val cadecs = ClosureConversion.convert baexp
        val _ = #stop Counter.closureConversionTimeCounter()
        val _ = printClosureANormal "Closure Converted" cadecs
      in
        cadecs
      end

  fun toYAANormal cadecs =
      let
        val _ = printPhase "ToYAANormal"
        val _ = #start Counter.toYAANormalTimeCounter()
        val ancalc = ToYAANormal.transform cadecs
        val _ = #stop Counter.toYAANormalTimeCounter()
        val _ = printYAANormal "To YAANormal" ancalc
      in
        ancalc
      end

  fun doYAANormalOptimization andecs =
      let
        val _ = printPhase "YAANormalOptimization"
        val _ = #start Counter.anormalOptimizationTimeCounter()
        val andecs = YAANormalOptimization.optimize andecs
        val _ = #stop Counter.anormalOptimizationTimeCounter()
        val _ = printYAANormal "A-Normal Optimization" andecs
      in
        andecs
      end

  fun doStaticAllocation andecs =
      let
        val _ = printPhase "StaticAllocation"
        val _ = #start Counter.staticAllocationTimeCounter()
        val andecs = StaticAllocation.optimize andecs
        val _ = #stop Counter.staticAllocationTimeCounter()
        val _ = printYAANormal "Static Allocation" andecs
      in
        andecs
      end

(*
  fun doInlining (basis:basis) (localContext, mvdecs) =
      let
	val _ = #start Counter.inliningTimeCounter()
	val (globalInlineEnv, mvdecs) =
	    Inline.doInlining (#inlineEnv basis) mvdecs
	val _ = #stop Counter.inliningTimeCounter()
        val _ = printMultipleValueCalc "Inlining" mvdecs
      in
        (localContext, mvdecs)
      end
*)

(*
  fun doMVOptimization (localContext, mvdecs) =
      let
        val _ = #start Counter.mvOptimizationTimeCounter()
        val mvdecs = MVOptimization.optimize mvdecs
        val _ = #stop Counter.mvOptimizationTimeCounter()
        val _ = printMultipleValueCalc "MutipleValue Optimization" mvdecs
      in
        (localContext, mvdecs)
      end
*)

(*
  fun doFunctionLocalize (localContext, mvdecs) =
      let
        val _ = #start Counter.functionLocalizeTimeCounter()
        val mvdecs = FunctionLocalize.localize mvdecs
        val _ = #stop  Counter.functionLocalizeTimeCounter()
        val _ = printMultipleValueCalc "Function Localization" mvdecs
      in
        (localContext, mvdecs)
      end

  fun doMVTypeCheck (localContext, mvdecs) =
      let
        val diagnoses = MVTypeCheck.typecheck mvdecs
        val _ = printDiagnosis "MultipleValue Diagnoses" diagnoses
      in
        ()
      end

  fun doYAANormalTypeCheck andecs =
      let
        val diagnoses = YAANormalTypeCheck.typecheck andecs
        val _ = printDiagnosis "YAANormal Diagnoses" diagnoses
      in
        ()
      end
*)

  fun doAIGeneration2 andecs =
      let
        val _ = printPhase "AIGeneration"
        val _ = #start Counter.aigenerationTimeCounter()
        val aicode = AIGenerator2.generate andecs
        val _ = #stop Counter.aigenerationTimeCounter()
        val _ = printAbstractInstruction2 "AIGeneration2" aicode
      in
        aicode
      end

  fun doRTLTypeCheck params rtl =
      let
        val _ = printPhase "RTLTypeCheck"
        val _ = #start Counter.rtlTypecheckTimeCounter()
        val res = RTLTypeCheck.check params rtl
        val _ = #stop Counter.rtlTypecheckTimeCounter()
      in
        case res of
          nil => ()
        | err =>
          printLines "RTLTypeCheck"
                     (Control.prettyPrint o RTLTypeCheckError.format_errlist)
                     [err]
      end

  fun doRTLX86Select mainSymbol aicode =
      let
        val _ = printPhase "RTLX86Select"
        val _ = #start Counter.rtlselectTimeCounter()
        val rtl = X86Select.select (mainSymbol, aicode)
        val _ = #stop Counter.rtlselectTimeCounter()
        val _ = printRTL "X86 RTL Select" rtl
      in
        rtl
      end

  fun doRTLX86Stabilize rtl =
      let
        val _ = printPhase "RTLX86Stabilize"
        val _ = #start Counter.rtlstabilizeTimeCounter()
        val rtl = X86Stabilize.stabilize rtl
        val _ = #stop Counter.rtlstabilizeTimeCounter()
        val _ = printRTL "X86 RTL Stabilize" rtl
      in
        rtl
      end

  fun doRTLRename rtl =
      let
        val _ = printPhase "RTLRename"
        val _ = #start Counter.rtlrenameTimeCounter()
        val rtl = RTLRename.rename rtl
        val _ = #stop Counter.rtlrenameTimeCounter()
        val _ = printRTL "X86 RTL Rename" rtl
      in
        rtl
      end

  fun doRTLX86Coloring rtl =
      let
        val _ = printPhase "RTLX86Coloring"
        val _ = #start Counter.rtlcoloringTimeCounter()
        val (rtl, regAlloc) = X86Coloring.regalloc rtl
        val _ = #stop Counter.rtlcoloringTimeCounter()
        val _ = printRTL "X86 RTL Coloring" rtl
      in
        ({regAlloc = regAlloc}, rtl)
      end

  fun doRTLX86Frame ({regAlloc}, rtl) =
      let
        val _ = printPhase "RTLX86Frame"
        val _ = #start Counter.rtlframeTimeCounter()
        val (rtl, layoutMap) = X86Frame.allocate rtl
        val _ = #stop Counter.rtlframeTimeCounter()
        val _ = printRTL "X86 RTL Frame Allocation" rtl
      in
        ({regAlloc = regAlloc, layoutMap = layoutMap}, rtl)
      end

  fun doRTLX86Emit (env, rtl) =
      let
        val _ = printPhase "RTLX86Emit"
        val _ = #start Counter.rtlemitTimeCounter()
        val ret = X86Emit.emit env rtl
        val _ = #stop Counter.rtlemitTimeCounter()
        val _ = printRTL "X86 RTL Frame Allocation" rtl
      in
        ret
      end

  fun doRTLX86AsmGen asmfile code =
      let
        val _ = printPhase "RTLX86AsmGen"
        val _ = #start Counter.rtlasmgenTimeCounter()
        val asmout = X86AsmGen.generate code
        val _ = #stop Counter.rtlasmgenTimeCounter()
        val asmfile =
            case asmfile of
              SOME filename => filename
            | NONE => TempFile.create ("."^SMLSharp_Config.ASMEXT())
        val _ = CoreUtils.makeTextFile' (asmfile, asmout)
      in
        asmfile
      end

  fun doRTLX86Assemble flags objfile asmfile =
      let
        val _ = printPhase "RTLX86Assemble"
        val objfile =
            case objfile of
              NONE => TempFile.create ("."^SMLSharp_Config.OBJEXT())
            | SOME filename => filename
        val _ = #start Counter.assembleTimeCounter()
        val _ = BinUtils.assemble {source=asmfile, flags=flags, object=objfile}
        val _ = #stop Counter.assembleTimeCounter()
      in
        FILE objfile
      end

  exception Return of interfaceNames * result

  fun compile {stopAt,dstfile,baseName,stdPath,loadPath,asmFlags} 
              {topEnv, fixEnv, version, builtinDecls} input =
      let
        val _ = #start Counter.compilationTimeCounter()

        val parsed = doParse input
        val (interfaceNames, abunit) =
            doLoadFile (baseName, stdPath, loadPath) parsed

        val _ = #start Counter.generateMainTimeCounter()
        val mainSymbol = GenerateMain.mainSymbol abunit
        val _ = #stop Counter.generateMainTimeCounter()

        val (newFixEnv, plunit) = doElaboration fixEnv abunit

        val _ = if stopAt = SyntaxCheck
                then raise Return (interfaceNames, STOPPED)
                else ()

        val (nameevalTopEnv, idcalc) = 
            doNameEvaluation (topEnv, version, builtinDecls) plunit
            handle exn => raise exn

        val idcalc = doVALRECOptimization idcalc

        val idcalc = if !Control.doUncurryOptimization
                     then idcalc
                     else doFundeclElaboration idcalc

        val (typeinfVarE, tpcalc) = 
            doTypeInference idcalc handle exn => raise exn

        val nameevalTopEnv = 
            if !Control.interactiveMode
            then NameEvalEnvUtils.mergeTypeEnv (nameevalTopEnv, typeinfVarE)
            else nameevalTopEnv

        val (_, tpcalc) = if !Control.interactiveMode
                     then doPrinterGeneration (nameevalTopEnv, tpcalc)
                     else (nameevalTopEnv, tpcalc)

        val nameevalTopEnv = NameEvalEnvUtils.resetInternalId nameevalTopEnv

        val tpcalc = if !Control.doUncurryOptimization
                     then doUncurryOptimization tpcalc
                     else tpcalc
(*
        val tpcalc = if !Control.skipPrinter
                     then tpcalc
                     else doPrinterGeneration Basis.initialBasis tpcalc
*)
        val rccalc = doMatchCompilation tpcalc

        val _ = if stopAt = ErrorCheck
                then raise Return (interfaceNames, STOPPED)
                else ()
        val rccalc = doSQLCompilation rccalc

        val rccalc = doFFICompilation rccalc

        val rccalc = doRecordCompilation rccalc

        val tlcalc = doDatatypeCompilation rccalc

(*
        val _ = if !Control.checkType then doTLTypeCheck tlcalc else ()
*)
        val accalc = doStaticAnalysis tlcalc

        val mvcalc = doRecordUnboxing accalc

(*
        val mvcalc = if !Control.doInlining
                     then doInlining Basis.initialBasis mvcalc
                     else mvcalc
        val mvcalc = if !Control.doMultipleValueOptimization
                     then doMVOptimization mvcalc
                     else mvcalc
        val mvcalc = if !Control.doFunctionLocalize
                     then doFunctionLocalize mvcalc
                     else mvcalc
        val _ = if !Control.checkType then doMVTypeCheck mvcalc else ()
*)
        val bccalc = doBitmapCompilation mvcalc

        val bacalc = doBitmapANormalization bccalc

        val bacalc = if !Control.doBitmapANormalReorder
                     then doBitmapANormalReorder bacalc
                     else bacalc

        val _ = if !Control.checkType
                then 
                  (
                   #start Counter.typeCheckBitmapANormalTimeCounter();
                   TypeCheckBitmapANormal.typecheck bacalc;
                   #stop Counter.typeCheckBitmapANormalTimeCounter()
                  )
                else ()

        val cacalc = doClosureConversion bacalc

        val ancalc = toYAANormal cacalc

        val ancalc = doYAANormalOptimization ancalc

        val ancalc = doStaticAllocation ancalc

        val aicode = doAIGeneration2 ancalc

        (* case #cpu (Control.targetInfo ()) of "x86" => *)
        val rtl = doRTLX86Select mainSymbol aicode

        val _ = if !Control.checkType
                then doRTLTypeCheck {checkStability=false} rtl
                else ()

        val rtl = doRTLX86Stabilize rtl

        val _ = if !Control.checkType
                then doRTLTypeCheck {checkStability=true} rtl
                else ()

        val rtl = doRTLRename rtl

        val _ = if !Control.checkType
                then doRTLTypeCheck {checkStability=true} rtl
                else ()

        val rtl = doRTLX86Coloring rtl

        val _ = if !Control.checkType
                then doRTLTypeCheck {checkStability=true} (#2 rtl)
                else ()

        val rtl = doRTLX86Frame rtl

        val _ = if !Control.checkType
                then doRTLTypeCheck {checkStability=true} (#2 rtl)
                else ()

        val code = doRTLX86Emit rtl

        val asmfile = if stopAt = Assembly then dstfile else NONE
        val asm = doRTLX86AsmGen asmfile code

        val _ = if stopAt = Assembly
                then raise Return (interfaceNames, STOPPED)
                else ()

        val objcode = doRTLX86Assemble asmFlags dstfile asm

        val _ = #stop Counter.compilationTimeCounter()

      in
        (interfaceNames,
         RETURN ({topEnv=nameevalTopEnv, fixEnv=newFixEnv}, objcode))
      end
      handle Return return => return

  exception Return of interfaceNames * newContext option

  fun loadInterface {stopAt, stdPath, loadPath}
                    ({topEnv, fixEnv, ...}:toplevelContext) filename =
      let
        val sourceName = Filename.toString filename
        val _ = #start Counter.loadFileTimeCounter()
        val ({loadedFiles}, abunit) =
            LoadFile.require 
              {stdPath=stdPath, loadPath=loadPath}
              sourceName
        val _ = #stop Counter.loadFileTimeCounter()
        val _ = printAbsyn "File Loaded" [abunit]

        val interfaceNames =
            {provide = #interfaceName (#interface abunit),
             requires = map #interfaceName (#decls (#interface abunit)),
             depends = List.filter (fn (_,x) => x <> sourceName) loadedFiles}

        val _ = #start Counter.elaborationTimeCounter()
        val (newFixEnv, plunit, warnings) =
            Elaborator.elaborateRequire abunit
        val _ = #stop Counter.elaborationTimeCounter()
        val _ = printWarnings warnings
        val _ = printPatternCalc "Elaborated" [plunit]

        val _ = if stopAt = SyntaxCheck
                then raise Return (interfaceNames, NONE)
                else ()

        val _ = #start Counter.nameEvaluationTimeCounter()
        val (topEnv, icdecls, warnings) =
            NameEval.evalRequire (topEnv, nil) plunit
        val _ = #stop Counter.nameEvaluationTimeCounter()
        val _ = printWarnings warnings
        val _ = printIDCalc "Name Evaluation" icdecls

        val fixEnv = Elaborator.extendFixEnv (fixEnv, newFixEnv)

        (* all topdecs should be eliminated by NameEval. *)
        val _ =
            case icdecls of
              nil => ()
            | _::_ => raise Control.Bug "loadInterface"
      in
        (interfaceNames, SOME {topEnv=topEnv, fixEnv=fixEnv})
      end
      handle Return return => return

end
