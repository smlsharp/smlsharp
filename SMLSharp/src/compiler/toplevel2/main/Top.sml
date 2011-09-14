(**
 * compiler toplevel
 * @copyright (c) 2010, Tohoku University.
 * @author Atsushi Ohori
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *)
structure Top : sig

  datatype stopAt =
      SyntaxCheck                   (* run until syntax check is completed. *)
    | ErrorCheck                    (* run until error check is completed. *)
    | Assembly                      (* generate assembly file and return. *)
    | Object                        (* generate object file and return. *)
    | NoStop

  datatype code =
      FILE of Filename.filename     (* compile result is in a file. *)

  type interfaceNames =
      {
        provide: AbsynInterface.interfaceName option,
        requires: AbsynInterface.interfaceName list,
        depends: string list
      }

  datatype result =
      STOPPED of interfaceNames            (* aborted due to stopAt. *)
    | RETURN of code * interfaceNames      (* compile successfully finished *)

  type toplevelOptions =
      {
        stopAt: stopAt,                      (* compile will stop here. *)
        dstfile: Filename.filename option,   (* preferred output file name *)
        baseName: Filename.filename option,  (* base name for file search *)
        loadPath: Filename.filename list,    (* path for file search *)
        asmFlags: string list                (* flags for assembler *)
      }

  val defaultOptions : toplevelOptions

  val initBuiltin : unit -> unit

  (** read one compile unit from input and compile it. *)
  val compile : toplevelOptions -> Parser.input -> result

  val loadInterface : {baseName: Filename.filename option,
                       loadPath: Filename.filename list}
                      -> Filename.filename -> interfaceNames

end =
struct

  datatype stopAt =
      SyntaxCheck
    | ErrorCheck
    | Assembly
    | Object
    | NoStop

  datatype code =
      FILE of Filename.filename

  type interfaceNames =
      {
        provide: AbsynInterface.interfaceName option,
        requires: AbsynInterface.interfaceName list,
        depends: string list
      }

  datatype result =
      STOPPED of interfaceNames
    | RETURN of code * interfaceNames

  type toplevelOptions =
      {
        stopAt: stopAt,
        dstfile: Filename.filename option,
        baseName: Filename.filename option,
        loadPath: Filename.filename list,
        asmFlags: string list
      }

  val defaultOptions =
      {
        stopAt = NoStop,
        dstfile = NONE,
        baseName = NONE,
        loadPath = nil,
        asmFlags = nil
      } : toplevelOptions

  val Counter.CounterSetInternal TopCounterSet =
      #addSet Counter.root ("Top", Counter.ORDER_OF_ADDITION)
  val Counter.CounterSetInternal ElapsedCounterSet =
      #addSet TopCounterSet ("elapsed time", Counter.ORDER_OF_ADDITION)

  val compilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "compilation (after parse)"
  val parseTimeCounter =
      #addElapsedTime ElapsedCounterSet "parse"
  val loadFileTimeCounter =
      #addElapsedTime ElapsedCounterSet "loadfile"
  val elaborationTimeCounter =
      #addElapsedTime ElapsedCounterSet "elaboration"
  val moduleCompilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "module compilation"
  val valRecOptimizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "val rec optimize"
  val fundeclElaborationTimeCounter =
      #addElapsedTime ElapsedCounterSet "fundecl elaboration"
  val setTVarsTimeCounter =
      #addElapsedTime ElapsedCounterSet "set tvars"
  val typeInferenceTimeCounter =
      #addElapsedTime ElapsedCounterSet "type inference"
(*
  val printerGenerationTimeCounter =
      #addElapsedTime ElapsedCounterSet "printer generation"
*)
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
  val closureConversionTimeCounter =
      #addElapsedTime ElapsedCounterSet "closure conversion"
(*
  val functionLocalizeTimeCounter =
      #addElapsedTime ElapsedCounterSet "function localization"
*)
  val anormalOptimizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "anormal optimization"
  val aigenerationTimeCounter =
      #addElapsedTime ElapsedCounterSet "aigeneration"
  val assembleTimeCounter =
      #addElapsedTime ElapsedCounterSet "assemble"
  val rtlselectTimeCounter =
      #addElapsedTime ElapsedCounterSet "rtl select"
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
                (Control.prettyPrint o IDCalc.format_icdecl)
                title code

  fun printTypedCalc title code =
      printCode Control.printTP
                (Control.prettyPrint o (TypedCalc.format_tpdecl nil))
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
        val _ = #start parseTimeCounter ()
        val ret = Parser.parse input
        val _ = #stop parseTimeCounter ()
        val _ = printParseResult "Parsed" [ret]
      in
        case ret of
          Absyn.UNIT unit => unit
        | Absyn.EOF =>
          {interface = Absyn.NOINTERFACE, tops = nil, loc = Loc.noloc}
      end

  fun doLoadFile (baseName, loadPath) absyn =
      let
        val _ = #start loadFileTimeCounter ()
        val ({loadedFiles}, abunit) =
            LoadFile.load {baseName=baseName, loadPath=loadPath} absyn
        val _ = #stop loadFileTimeCounter ()
        val _ = printAbsyn "File Loaded" [abunit]
        val interfaceNames =
            {provide = #interfaceName (#interface abunit),
             requires = map #interfaceName (#decls (#interface abunit)),
             depends = loadedFiles}
            : interfaceNames
      in
        (interfaceNames, abunit)
      end

  fun doElaboration absyn =
      let
        val _ = #start elaborationTimeCounter ()
        val (plunit, warnings) = Elaborator.elaborate absyn
        val _ = #stop elaborationTimeCounter ()
        val _ = printWarnings warnings
        val _ = printPatternCalc "Elaborated" [plunit]
      in
        plunit
      end

  val builtinICDecls = ref nil : IDCalc.icdecl list ref
  val builtinNameEvalEnv = ref NameEvalEnv.emptyTopEnv : NameEvalEnv.topEnv ref

  fun doNameEvaluation plunit =
      let
        val _ = #start moduleCompilationTimeCounter ()
        val (icdecls, warnings) =
            NameEval.nameEval (!builtinNameEvalEnv) plunit
        val _ = #stop moduleCompilationTimeCounter ()
        val icdecls = !builtinICDecls @ icdecls
        val _ = printWarnings warnings
        val _ = printIDCalc "Name Evaluation" icdecls
      in
        icdecls
      end

  fun doTypeInference icdecls =
      let
(*
        val oldDebugPrint = !Control.debugPrint
        val _ = Control.debugPrint := true
*)
        val _ = #start typeInferenceTimeCounter ()
        val (tpdecs, warnings) = InferTypes.typeinf icdecls
        val _ = #stop typeInferenceTimeCounter ()
        val _ = printWarnings warnings
        val _ = printTypedCalc "Type Inference" tpdecs
(*
        val _ = Control.debugPrint := oldDebugPrint
*)
      in
        tpdecs
      end

  fun doUncurryOptimization tpdecs =
      let
        val _ = #start UncurryOptimizationTimeCounter ()
        val tpdecs = UncurryFundecl.optimize tpdecs
        val _ = #stop UncurryOptimizationTimeCounter ()
        val _ = printTypedCalc "Uncurrying Optimized" tpdecs
      in
        tpdecs
      end

  fun doVALRECOptimization iddecs =
      let
        val _ = #start valRecOptimizationTimeCounter ()
        val iddecs = VALREC_Optimizer.optimize iddecs
        val _ = #stop valRecOptimizationTimeCounter ()
        val _ = printIDCalc "VAL REC optimize" iddecs
      in
        iddecs
      end

  fun doFundeclElaboration iddecs =
      let
        val _ = #start fundeclElaborationTimeCounter ()
        val iddecs = TransFundecl.transIcdeclList iddecs
        val _ = #stop fundeclElaborationTimeCounter ()
        val _ = printIDCalc "Fundecl Elaboration" iddecs
      in
        iddecs
      end

(*
  fun doPrinterGeneration (basis:basis) (localContext, tpdecs) =
      let
        val _ = BoundTypeVarID.start ()
        val {flattenedNamePathEnv, newTypeContext} = localContext

        val _ = #start printerGenerationTimeCounter ()
        val (newContext, newFlattenedNamePathEnv, tpdecs) =
            PrinterGenerator.generate
              {context = #topTypeContext basis,
               newContext = newTypeContext,
               flattenedNamePathEnv = flattenedNamePathEnv,
               printBinds = !Control.printBinds,
               declarations = tpdecs}
        val _ = #stop printerGenerationTimeCounter ()
        val _ = printTypedCalc "Printer code generated" tpdecs
        val _ = printTypeContext "Generated static bindings" newContext

        val localContext =
            {flattenedNamePathEnv = newFlattenedNamePathEnv,
             newTypeContext = newTypeContext}
      in
        GlobalCounters.stop ();
        (localContext, tpdecs)
      end
      handle e => (GlobalCounters.stop (); raise e)
*)

  fun doMatchCompilation tpdecs =
      let
        val _ = #start matchCompilationTimeCounter ()
        val (rcdecs, warnings) = MatchCompiler.compile tpdecs
        val _ = #stop matchCompilationTimeCounter ()
        val _ = printRecordCalc "Match Compiled" rcdecs
        val _ = printWarnings warnings
      in
        rcdecs
      end

  fun doSQLCompilation rcdecs =
      let
        val _ = #start sqlCompilationTimeCounter ()
        val rcdecs = SQLCompilation.compile rcdecs
        val _ = #stop sqlCompilationTimeCounter ()
        val _ = printRecordCalc "SQL Compiled" rcdecs
      in
        rcdecs
      end

  fun doFFICompilation rcdecs =
      let
        val _ = #start ffiCompilationTimeCounter ()
        val rcdecs = FFICompilation.compile rcdecs
        val _ = #stop ffiCompilationTimeCounter ()
        val _ = printRecordCalc "FFI Compiled" rcdecs
      in
        rcdecs
      end

  fun doRecordCompilation rcdecs =
      let
        val _ = #start recordCompilationTimeCounter ()
        val rcdecs = RecordCompilation.compile rcdecs
        val _ = #stop recordCompilationTimeCounter ()
        val _ = printRecordCalc "Record Compiled" rcdecs
      in
        rcdecs
      end

  fun doDatatypeCompilation rcdecs =
      let
        val _ = #start datatypeCompilationTimeCounter ()
        val tldecs = DatatypeCompilation.compile rcdecs
        val _ = #stop datatypeCompilationTimeCounter ()
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
        val _ = #start staticAnalysisTimeCounter ()
        val acdecs = StaticAnalysis.analyse tldecs
        val _ = #stop staticAnalysisTimeCounter ()
        val _ = printAnnotatedCalc "Static Analysis" acdecs
      in
        acdecs
      end

  fun doRecordUnboxing acdecs =
      let
        val _ = #start recordUnboxingTimeCounter ()
        val mvdecs =  RecordUnboxing.transform acdecs
        val _ = #stop recordUnboxingTimeCounter ()
        val _ = printMultipleValueCalc "Record Unboxing" mvdecs
      in
        mvdecs
      end

  fun doBitmapCompilation mvdecs =
      let
        val _ = #start bitmapCompilationTimeCounter ()
        val bcdecs = BitmapCompilation.compile mvdecs
        val _ = #stop bitmapCompilationTimeCounter ()
        val _ = printBitmapCalc "Bitmap Compiled" bcdecs
      in
        bcdecs
      end

  fun doBitmapANormalization bcdecs =
      let
        val _ = #start bitmapANormalizationTimeCounter ()
        val baexp = BitmapANormalization.normalize bcdecs
        val _ = #stop bitmapANormalizationTimeCounter ()
        val _ = printBitmapANormal "Bitmap ANormalized" baexp
      in
        baexp
      end

  fun doClosureConversion baexp =
      let
        val _ = #start closureConversionTimeCounter ()
        val cadecs = ClosureConversion.convert baexp
        val _ = #stop closureConversionTimeCounter ()
        val _ = printClosureANormal "Closure Converted" cadecs
      in
        cadecs
      end

  fun toYAANormal cadecs =
      let
        val _ = #start closureConversionTimeCounter ()
        val ancalc = ToYAANormal.transform cadecs
        val _ = #stop closureConversionTimeCounter ()
        val _ = printYAANormal "To YAANormal" ancalc
      in
        ancalc
      end

  fun doYAANormalOptimization andecs =
      let
        val _ = #start anormalOptimizationTimeCounter ()
        val andecs = YAANormalOptimization.optimize andecs
        val _ = #stop anormalOptimizationTimeCounter ()
        val _ = printYAANormal "A-Normal Optimization" andecs
      in
        andecs
      end

  fun doStaticAllocation andecs =
      let
        val _ = #start anormalOptimizationTimeCounter ()
        val andecs = StaticAllocation.optimize andecs
        val _ = #stop anormalOptimizationTimeCounter ()
        val _ = printYAANormal "Static Allocation" andecs
      in
        andecs
      end

(*
  fun doInlining (basis:basis) (localContext, mvdecs) =
      let
	val _ = #start inliningTimeCounter()
	val (globalInlineEnv, mvdecs) =
	    Inline.doInlining (#inlineEnv basis) mvdecs
	val _ = #stop inliningTimeCounter()
        val _ = printMultipleValueCalc "Inlining" mvdecs
      in
        (localContext, mvdecs)
      end

  fun doMVOptimization (localContext, mvdecs) =
      let
        val _ = #start mvOptimizationTimeCounter ()
        val mvdecs = MVOptimization.optimize mvdecs
        val _ = #stop mvOptimizationTimeCounter ()
        val _ = printMultipleValueCalc "MutipleValue Optimization" mvdecs
      in
        (localContext, mvdecs)
      end

  fun doFunctionLocalize (localContext, mvdecs) =
      let
        val _ = #start functionLocalizeTimeCounter ()
        val mvdecs = FunctionLocalize.localize mvdecs
        val _ = #stop  functionLocalizeTimeCounter ()
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
        val _ = #start aigenerationTimeCounter ()
        val aicode = AIGenerator2.generate andecs
        val _ = #stop aigenerationTimeCounter ()
        val _ = printAbstractInstruction2 "AIGeneration2" aicode
      in
        aicode
      end

  fun doRTLTypeCheck params rtl =
      case RTLTypeCheck.check params rtl of
        nil => ()
      | err =>
        printLines "RTLTypeCheck"
                   (Control.prettyPrint o RTLTypeCheckError.format_errlist)
                   [err]

  fun doRTLX86Select mainSymbol aicode =
      let
        val _ = #start rtlselectTimeCounter ()
        val rtl = X86Select.select (mainSymbol, aicode)
        val _ = #stop rtlselectTimeCounter ()
        val _ = printRTL "X86 RTL Select" rtl
      in
        rtl
      end

  fun doRTLX86Stabilize rtl =
      let
        val _ = #start rtlstabilizeTimeCounter ()
        val rtl = X86Stabilize.stabilize rtl
        val _ = #stop rtlstabilizeTimeCounter ()
        val _ = printRTL "X86 RTL Stabilize" rtl
      in
        rtl
      end

  fun doRTLRename rtl =
      let
        val _ = #start rtlrenameTimeCounter ()
        val rtl = RTLRename.rename rtl
        val _ = #stop rtlrenameTimeCounter ()
        val _ = printRTL "X86 RTL Rename" rtl
      in
        rtl
      end

  fun doRTLX86Coloring rtl =
      let
        val _ = #start rtlcoloringTimeCounter ()
        val (rtl, regAlloc) = X86Coloring.regalloc rtl
        val _ = #stop rtlcoloringTimeCounter ()
        val _ = printRTL "X86 RTL Coloring" rtl
      in
        ({regAlloc = regAlloc}, rtl)
      end

  fun doRTLX86Frame ({regAlloc}, rtl) =
      let
        val _ = #start rtlcoloringTimeCounter ()
        val (rtl, layoutMap) = X86Frame.allocate rtl
        val _ = #stop rtlcoloringTimeCounter ()
        val _ = printRTL "X86 RTL Frame Allocation" rtl
      in
        ({regAlloc = regAlloc, layoutMap = layoutMap}, rtl)
      end

  fun doRTLX86Emit (env, rtl) =
      let
        val _ = #start rtlemitTimeCounter ()
        val ret = X86Emit.emit env rtl
        val _ = #stop rtlemitTimeCounter ()
        val _ = printRTL "X86 RTL Frame Allocation" rtl
      in
        ret
      end

  fun doRTLX86AsmGen asmfile code =
      let
        val _ = #start rtlasmgenTimeCounter ()
        val asmout = X86AsmGen.generate code
        val _ = #stop rtlasmgenTimeCounter ()
        val asmfile =
            case asmfile of
              SOME filename => filename
            | NONE => TempFile.create ("."^BinUtils.ASMEXT)
        val _ = CoreUtils.makeTextFile' (asmfile, asmout)
      in
        asmfile
      end

  fun doRTLX86Assemble flags objfile asmfile =
      let
        val objfile =
            case objfile of
              NONE => TempFile.create ("."^BinUtils.OBJEXT)
            | SOME filename => filename
        val _ = #start assembleTimeCounter ()
        val _ = BinUtils.assemble {source=asmfile, flags=flags, object=objfile}
        val _ = #stop assembleTimeCounter ()
      in
        FILE objfile
      end

  fun parseBuiltin {name, body} =
      let
        val src = TextIO.openString body
        val input = InterfaceParser.setup
                      {read = fn n => TextIO.inputN (src, n),
                       sourceName = name}
        val absyn = InterfaceParser.parse input
      in
        case absyn of
          AbsynInterface.INTERFACE {requires=nil, topdecs} => topdecs
        | _ => raise Control.Bug "parseBuiltin"
      end

  fun initBuiltin () =
      let
        val absyns = map parseBuiltin BuiltinContextSources.sources
        val topdecs = List.concat absyns
        val absyn =
            {interface =
             {decls=nil,
              interfaceName=NONE,
              requires=nil,
              topdecs=topdecs},
             topdecs = nil} : AbsynInterface.compileUnit
        val ({interface={decls, requires, topdecs, ...}, ...}, warnings) =
            Elaborator.elaborate absyn
        val (topEnv, builtinEnv, idcalc) = NameEval.evalBuiltin topdecs
      in
        BuiltinEnv.init builtinEnv;
        builtinICDecls := idcalc;
        builtinNameEvalEnv := topEnv
      end

  exception Return of result

  fun compile {stopAt, dstfile, baseName, loadPath, asmFlags} input =
      let
        val parsed = doParse input
        val (interfaceNames, absyn) = doLoadFile (baseName, loadPath) parsed
            handle exn => raise exn
        val mainSymbol = GenerateMain.mainSymbol absyn
        val plcalc = doElaboration absyn handle exn => raise exn
        val _ = if stopAt = SyntaxCheck
                then raise Return (STOPPED interfaceNames)
                else ()
        val idcalc = doNameEvaluation plcalc handle exn => raise exn
        val idcalc = doVALRECOptimization idcalc
        val idcalc = if !Control.doUncurryOptimization
                     then idcalc
                     else doFundeclElaboration idcalc
        val tpcalc = doTypeInference idcalc handle exn => raise exn
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
                then raise Return (STOPPED interfaceNames)
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
        val _ = if !Control.checkType
                then TypeCheckBitmapANormal.typecheck bacalc
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
                then raise Return (STOPPED interfaceNames)
                else ()
        val objcode = doRTLX86Assemble asmFlags dstfile asm
        val _ = if stopAt = Object
                then raise Return (STOPPED interfaceNames)
                else ()
      in
        RETURN (objcode, interfaceNames)
      end
      handle Return result => result

  fun loadInterface {baseName, loadPath} filename =
      let
        val sourceName = Filename.toString filename
        val absyn =
            {interface = Absyn.INTERFACE {name = sourceName, loc = Loc.noloc},
             tops = nil,
             loc = Loc.noloc} : Absyn.unit
        val ({requires, provide, depends}, {interface,...}) =
            doLoadFile (baseName, loadPath) absyn
        val interfaceNames =
            {requires = requires,
             provide = provide,
             depends = List.filter (fn x => x <> sourceName) depends}

        (* error check *)
        val topInterfaceDec =
            {
              interfaceId = InterfaceID.generate (),
              interfaceName = case #interfaceName interface of
                                SOME name => name
                              | NONE => raise Control.Bug "loadInterfaces",
              requires = #requires interface,
              topdecs = #topdecs interface
            } : AbsynInterface.interfaceDec
        val absyn =
            {
              interface = {decls = #decls interface @ [topInterfaceDec],
                           interfaceName = NONE,
                           requires = [{id = #interfaceId topInterfaceDec,
                                        loc = Loc.noloc}],
                           topdecs = nil},
              topdecs = nil
            } : AbsynInterface.compileUnit
        val (plunit, _) = Elaborator.elaborate absyn
        val _ = NameEval.nameEval (!builtinNameEvalEnv) plunit
      in
        interfaceNames
      end

end
