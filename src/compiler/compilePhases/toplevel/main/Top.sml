(**
 * compiler toplevel
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 * @author YAMATODANI Kiyoshi
 *)
(*
 : TOP
*)
structure Top =
struct

  fun bug s = Bug.Bug ("Top: " ^ s)

  open TopData

  fun extendContext ({topEnv, fixEnv, version, builtinDecls} : toplevelContext,
                     {topEnv=newTopEnv, fixEnv=newFixEnv} : newContext) =
      let
        val topEnv = NameEvalEnvPrims.topEnvWithTopEnv (topEnv, newTopEnv)
      in
        {topEnv = topEnv,
         version = version,
         fixEnv = Elaborator.extendFixEnv (fixEnv, newFixEnv),
         builtinDecls = builtinDecls} : toplevelContext
      end

  val emptyNewContext =
      {
        topEnv = NameEvalEnv.emptyTopEnv,
        fixEnv = SymbolEnv.empty
      } : newContext

  fun printDebug msg = Bug.printError msg
  val errorOutput = TextIO.stdErr
  fun printError msg = TextIO.output (errorOutput, msg)
  fun flushError () = TextIO.flushOut errorOutput

  fun printLines title formatter elems =
      (if title = "" then () else (printError title; printError ":\n");
       app (fn elem =>
               let
                 val s = formatter elem
               in
                 if s <> "" then
                   (printError s; printError "\n")
                 else ()
               end
           ) elems;
       flushError ())

  fun userErrorToString x =
      Bug.prettyPrint (UserError.format_errorInfo x)

  fun printErrors errors =
      printLines "" userErrorToString errors

  fun printDiagnosis title diagnoses =
      if !Control.printDiagnosis
      then printLines title userErrorToString diagnoses
      else ()

  fun printCode flagList formatter title codes =
      if List.all (fn x => !x) flagList
      then 
        (printError "\n";
         printLines title formatter codes
        )
      else ()

  fun printParseResult flag title code =
      printCode [flag] (Bug.prettyPrint o AbsynFormatter.format_unitparseresult)
                title [code]

  fun printAbsyn flag title code =
      printCode [flag] (Bug.prettyPrint o AbsynInterface.format_compile_unit)
                title [code]

  fun printAbsynInterface flags title code =
      printCode flags (Bug.prettyPrint o AbsynInterface.format_interface_unit)
                title [code]

  fun printFileDependency flags title code =
      printCode flags (Bug.prettyPrint o InterfaceName.format_file_dependency)
                title [code]

  fun printPatternCalc flag title code =
      printCode [flag]
                (Bug.prettyPrint o PatternCalcInterface.format_compile_unit)
                title [code]

  fun printPatternCalcInterface flags title code =
      printCode flags
                (Bug.prettyPrint o PatternCalcInterface.format_interface_unit)
                title [code]

  fun printIDCalc flagList title code =
      printCode
        flagList
        (if !Control.printWithType
         then (Bug.prettyPrint o IDCalc.formatWithType_icdecl)
         else (Bug.prettyPrint o IDCalc.format_icdecl))
        title code

  fun printTypedCalc flagList title code =
      printCode
        flagList
        (if !Control.printWithType
         then Bug.prettyPrint o TypedCalc.formatWithType_tpdecl
         else Bug.prettyPrint o TypedCalc.format_tpdecl)
        title code

  fun printRecordCalc flagList title code =
      printCode
        flagList
        (if !Control.printWithType
         then Bug.prettyPrint o RecordCalc.formatWithType_rcdecl
         else Bug.prettyPrint o RecordCalc.format_rcdecl)
        title code

  fun printTypedLambda flagList title code =
      printCode
        flagList
        (if !Control.printWithType
         then Bug.prettyPrint o TypedLambda.formatWithType_tldecl
         else Bug.prettyPrint o TypedLambda.format_tldecl)
        title code

  fun printBitmapCalc2 flag title code =
      printCode [flag]
                (if !Control.printWithType
                 then Bug.prettyPrint o BitmapCalc2.formatWithType_bcdecl
                 else Bug.prettyPrint o BitmapCalc2.format_bcdecl)
                title code

  fun printClosureCalc flagList title code =
      printCode flagList
                (if !Control.printWithType
                 then Bug.prettyPrint o ClosureCalc.formatWithType_program
                 else Bug.prettyPrint o ClosureCalc.format_program)
                title [code]

  fun printRuntimeCalc flag title code =
      printCode [flag]
                (if !Control.printWithType
                 then Bug.prettyPrint o RuntimeCalc.formatWithType_program
                 else Bug.prettyPrint o RuntimeCalc.format_program)
                title [code]

  fun printANormal flag title code =
      printCode [flag]
                (if !Control.printWithType
                 then Bug.prettyPrint o ANormal.formatWithType_program
                 else Bug.prettyPrint o ANormal.format_program)
                title [code]

  fun printMachineCode flag title code =
      printCode [flag]
                (Bug.prettyPrint o MachineCode.format_program)
                title [code]

  fun printLLVMIR flag title code =
      printCode [flag]
                (Bug.prettyPrint o LLVMIR.format_program)
                title [code]

  fun printFile flag title file =
      if !flag
      then (printError title; printError ":\n"; flushError ();
            printError (CoreUtils.readTextFile file))
      else ()

  fun initPointerSize llvmOptions =
      let
        val {alignment, ...} = LLVMUtils.getDataLayout llvmOptions
        val ptrsize =
            case List.find (fn {ty, ...} => ty = LLVMUtils.Pointer 0) alignment
            of NONE => raise Bug.Bug "initPointerSize"
             | SOME {size, ...} => size
      in
        if ptrsize = 32 orelse ptrsize = 64
        then RuntimeTypes.init {pointerSize = ptrsize div 8}
        else raise UserError.UserErrors
                   [(Loc.noloc, UserError.Error,
                     UnsupportedPointerSize ptrsize)]
      end

  fun doParse input =
      let
        val _ = #start Counter.parseTimeCounter()
        val ret = Parser.parse input
        val _ =  #stop Counter.parseTimeCounter()
        val _ = printParseResult Control.printParse "Parsed" ret
      in
        case ret of
          Absyn.UNIT unit => unit
        | Absyn.EOF =>
          {interface = Absyn.NOINTERFACE, tops = nil, loc = Loc.noloc}
      end

  fun doLoadFile ({baseFilename, loadPath, loadMode, defaultInterface,
                   ...}:options)
                 ({version, ...}: toplevelContext)
                 absyn =
      let
        val _ = #start Counter.loadFileTimeCounter()
        val (dependency, prelude, abunit) =
            LoadFile.load
              {baseFilename = baseFilename,
               loadPath = loadPath,
               loadMode = loadMode,
               defaultInterface = defaultInterface}
              absyn
        val _ = #stop Counter.loadFileTimeCounter()
        val _ = printAbsyn Control.printLoadFile "File Loaded" abunit
        val _ = printFileDependency [Control.printDependency] "File dependency"
                                    dependency
      in
        (dependency, prelude, abunit)
      end

  fun doLoadInterface {loadPath, loadMode, ...} sources =
      let
        val _ = #start Counter.loadFileTimeCounter ()
        val (dependency, abunit) =
            LoadFile.loadInterfaceFiles
              {loadPath=loadPath, loadMode=loadMode}
              sources
        val _ = #stop Counter.loadFileTimeCounter ()
        val _ = printAbsynInterface
                  [Control.printLoadFile, Control.printSystemDecls]
                  "File Loaded"
                  abunit
        val _ = printFileDependency
                  [Control.printDependency, Control.printSystemDecls]
                  "File dependency"
                  dependency
      in
        (dependency, abunit)
      end

  fun doElaboration outputWarnings fixEnv abunit =
      let
        val _ = #start Counter.elaborationTimeCounter()
        val (newFixEnv, plunit, warnings) = Elaborator.elaborate fixEnv abunit
        val _ =  #stop Counter.elaborationTimeCounter()
        val _ = outputWarnings warnings
        val _ = printPatternCalc Control.printElab "Elaborated" plunit
      in
        (newFixEnv, plunit)
      end

  fun doElabInterface {outputWarnings, ...} {fixEnv, ...} abunit =
      let
        val _ = #start Counter.elaborationTimeCounter ()
        val (newFixEnv, plunit, warnings) =
            Elaborator.elaborateInterface fixEnv abunit
        val _ =  #stop Counter.elaborationTimeCounter()
        val _ = case warnings of nil => () | l => outputWarnings l
        val _ = printPatternCalcInterface
                  [Control.printElab, Control.printSystemDecls]
                  "Elaborate"
                  plunit
      in
        (newFixEnv, plunit)
      end

  fun doNameEvaluation source 
                       outputWarnings
                       ({topEnv, version, builtinDecls, ...}:toplevelContext)
                       plunit =
      let
        val _ = #start Counter.nameEvaluationTimeCounter()
        val {requireTopEnv, returnTopEnv, icdecls, warnings} =
            NameEval.nameEval source
                              {topEnv=topEnv, version=version,
                               systemDecls=builtinDecls} plunit
        val _ =  #stop Counter.nameEvaluationTimeCounter()
        val _ = outputWarnings warnings
        val _ = printIDCalc [Control.printNameEval] "Name Evaluation" icdecls
      in
        (requireTopEnv, returnTopEnv, icdecls)
      end

  fun doNameEvalInterface {outputWarnings, ...} {topEnv, ...} plunit =
      let
        val _ = #start Counter.nameEvaluationTimeCounter()
        val (newTopEnv, warnings) = NameEval.nameEvalInterface topEnv plunit
        val _ =  #stop Counter.nameEvaluationTimeCounter()
        val _ = case warnings of nil => () | l => outputWarnings l
      in
        newTopEnv
      end

  fun doTypeInference env outputWarnings icdecls =
      let
        val _ = #start Counter.typeInferenceTimeCounter()
        val (typeinfVarE, tpdecs, warnings) = InferTypes.typeinf env icdecls
        val _ =  #stop Counter.typeInferenceTimeCounter()
        val _ = outputWarnings warnings
        val _ = printTypedCalc [Control.printTypeInf] "Type Inference" tpdecs
      in
        (typeinfVarE, tpdecs)
      end

  fun doUncurryOptimization tpdecs =
      let
        val _ = #start Counter.UncurryOptimizationTimeCounter()
        val tpdecs = UncurryFundecl.optimize tpdecs
        val _ =  #stop Counter.UncurryOptimizationTimeCounter()
        val _ = printTypedCalc [Control.printUncurryOpt]
                               "Uncurrying Optimized" tpdecs
      in
       tpdecs
      end

  fun doPolyTyElimination tpdecs =
      let
        val _ = #start Counter.polyTyEliminationCounter()
        val tpdecs = PolyTyElimination.compile tpdecs
        val _ =  #stop Counter.polyTyEliminationCounter()
        val _ = printTypedCalc [Control.printPolyTyElim]
                               "PolyTy Eliminated" tpdecs
      in
       tpdecs
      end

  fun doTypedCalcOptimization tpdecs =
      let
        val _ = #start Counter.TypedCalcOptimizationTimeCounter()
        val tpdecs = TPOptimize.optimize tpdecs
        val _ =  #stop Counter.TypedCalcOptimizationTimeCounter()
        val _ = printTypedCalc [Control.printTCOpt]
                               "TypedCalc Optimized" tpdecs
      in
        tpdecs
      end

(*
  fun doRecordCalcOptimization rcdecs =
      let
        val _ = #start Counter.RecordCalcOptimizationTimeCounter()
        val rcdecs = RCOptimize.optimize rcdecs
        val _ =  #stop Counter.RecordCalcOptimizationTimeCounter()
        val _ = printRecordCalc [Control.printRCOpt]
                                "RecordCalc Optimized" rcdecs
      in
        rcdecs
      end
*)

  fun doVALRECOptimization icdecls =
      let
        val _ = #start Counter.valRecOptimizationTimeCounter()
        val icdecls = VALREC_Optimizer.optimize icdecls
        val _ =  #stop Counter.valRecOptimizationTimeCounter()
        val _ = printIDCalc [Control.printVALRECOpt] "VAL REC optimize" icdecls
      in
        icdecls
      end

  fun doFundeclElaboration icdecls =
      let
        val _ = #start Counter.fundeclElaborationTimeCounter()
        val icdecls = TransFundecl.transIcdeclList icdecls
        val _ =  #stop Counter.fundeclElaborationTimeCounter()
        val _ = printIDCalc [Control.printFundeclElab]
                            "Fundecl Elaboration" icdecls
      in
       icdecls
      end

  fun doMatchCompilation outputWarnings tpdecs =
      let
        val _ = #start Counter.matchCompilationTimeCounter()
        val (tpdecs, warnings) = MatchCompiler.compile tpdecs
        val _ =  #stop Counter.matchCompilationTimeCounter()
        val _ = printTypedCalc [Control.printMatchCompile]
                               "Match Compiled" tpdecs
        val _ = outputWarnings warnings
      in
        tpdecs
      end

  fun doTypedElaboration icdecls =
      let
        val _ = #start Counter.typedElaborationTimeCounter()
        val icdecls = TypedElaboration.elaborate icdecls
        val _ =  #stop Counter.typedElaborationTimeCounter()
        val _ = printIDCalc [Control.printTypedElaboration] "TypedElaborated" icdecls
      in
        icdecls
      end

  fun doReifyTopEnv env version tpdecls =
      let
        val _ = #start Counter.reifyTopEnvTimeCounter()
        val {env, decls} = ReifyTopEnv.topEnvBind env version
        val _ =  #stop Counter.reifyTopEnvTimeCounter()
        val tpdecls = tpdecls @ decls
        val _ = printTypedCalc [Control.printReifyTopEnv] "ReifyTopEnv" tpdecls
      in
        (env, tpdecls)
      end

  fun doFFICompilation tpdecs =
      let
        val _ = #start Counter.ffiCompilationTimeCounter()
        val tpdecs = FFICompilation.compile tpdecs
        val _ =  #stop Counter.ffiCompilationTimeCounter()
        val _ = printTypedCalc [Control.printFFICompile] "FFI Compiled" tpdecs
      in
        tpdecs
      end

  fun doRecordCompilation tpdecs =
      let
       val _ = #start Counter.recordCompilationTimeCounter()
        val rcdecs = RecordCompilation.compile tpdecs
        val _ =  #stop Counter.recordCompilationTimeCounter()
        val _ = printRecordCalc [Control.printRecordCompile]
                                "Record Compiled" rcdecs
      in
       rcdecs
      end

  fun doDatatypeCompilation tpdecs =
      let
        val _ = #start Counter.datatypeCompilationTimeCounter()
        val tldecs = DatatypeCompilation.compile tpdecs
        val _ =  #stop Counter.datatypeCompilationTimeCounter()
        val _ = printTypedLambda [Control.printDatatypeCompile]
                                 "Datatype Compiled" tldecs
      in
        tldecs
      end

  fun doBitmapCompilation rcdecs =
      let
        val _ = #start Counter.bitmapCompilationTimeCounter()
        val bcdecs = BitmapCompilation.compile rcdecs
        val _ =  #stop Counter.bitmapCompilationTimeCounter()
        val _ = printBitmapCalc2 Control.printBitmapCompile
                                 "Bitmap Compiled" bcdecs
      in
        bcdecs
      end

  fun doClosureConversion2 bcdecs =
      let
        val _ = #start Counter.closureConversionTimeCounter()
        val cccalc = ClosureConversion2.convert bcdecs
        val _ = #stop Counter.closureConversionTimeCounter()
        val _ = printClosureCalc [Control.printClosureConversion]
                                 "Closure Converted" cccalc
      in
        cccalc
      end

  fun doCallingConventionCompile ccprog =
      let
        val _ = #start Counter.callingConventionCompileTimeCounter()
        val ncprog = CallingConventionCompile.compile ccprog
        val _ = #stop Counter.callingConventionCompileTimeCounter()
        val _ = printRuntimeCalc Control.printCConvCompile
                                 "Calling Convention Compiled" ncprog
      in
        ncprog
      end

  fun doANormalize ncprog =
      let
        val _ = #start Counter.anormalizeTimeCounter()
        val anprog = ANormalize.compile ncprog
        val _ = #stop Counter.anormalizeTimeCounter()
        val _ = printANormal Control.printANormal "A-normalized" anprog
        val _ = if !Control.checkType then ANormalTypeCheck.check anprog else ()
      in
        anprog
      end

  fun doMachineCodeGen anprog =
      let
        val _ = #start Counter.machineCodeGenTimeCounter()
        val mcprog = MachineCodeGen.compile anprog
        val _ = #stop Counter.machineCodeGenTimeCounter()
        val _ = printMachineCode Control.printMachineCodeGen
                                 "MachineCodeGen" mcprog
      in
        mcprog
      end

  fun doInsertCheckGC mcprog =
      let
        val _ = #start Counter.insertCheckGCTimeCounter()
        val mcprog = ConcurrencySupport.insertCheckGC mcprog
        val _ = #stop Counter.insertCheckGCTimeCounter()
        val _ = printMachineCode Control.printInsertCheckGC
                                 "Insert Check GC" mcprog
      in
        mcprog
      end

  fun doStackAllocation mcprog =
      let
        val _ = #start Counter.stackAllocationTimeCounter()
        val mcprog = StackAllocation.compile mcprog
        val _ = #stop Counter.stackAllocationTimeCounter()
        val _ = printMachineCode Control.printStackAllocation
                                 "Stack Allocation" mcprog
      in
        mcprog
      end

  fun doLLVMGen ({triple,...}:LLVMUtils.compile_options)
                (prelude, mcprog) =
      let
        val _ = #start Counter.llvmGenTimeCounter()
        val llvmprog = LLVMGen.compile
                         {targetTriple = triple}
                         (prelude, mcprog)
        val _ = #stop Counter.llvmGenTimeCounter()
        val _ = printLLVMIR Control.printLLVMGen "LLVM generated" llvmprog
      in
        llvmprog
      end

  fun doLLVMEmit llvmir =
      let
        val _ = #start Counter.llvmEmitTimeCounter()
        val llfile = LLVMEmit.emit llvmir
        val _ = #stop Counter.llvmEmitTimeCounter()
        val _ = printFile Control.printLLVMEmit "LLVM emit" llfile
      in
        if !Control.dumpLLVMEmit = ""
        then ()
        else CoreUtils.cp llfile (Filename.fromString (!Control.dumpLLVMEmit));
        llfile
      end

  fun doAssemble llfile =
      let
        val _ = #start Counter.assembleTimeCounter()
        val bcfile = LLVMUtils.assemble llfile
        val _ = #stop Counter.assembleTimeCounter()
      in
        bcfile
      end

(*
  fun writeLLVMIR (dstfile, module) =
      (#start Counter.llvmOutputTimeCounter();
       LLVM.LLVMPrintModuleToFile (module, Filename.toString dstfile);
       #stop Counter.llvmOutputTimeCounter())

  fun writeLLVMBitcode (dstfile, module) =
      (#start Counter.llvmOutputTimeCounter();
       LLVM.LLVMWriteBitcodeToFile (module, Filename.toString dstfile);
       #stop Counter.llvmOutputTimeCounter())

  type write_native_options =
       {optLevel: LLVM.CodeGenOptLevel,
        relocModel: LLVM.RelocModel,
        codeModel: LLVM.CodeModel,
        arch: string option}

  local
    fun emitToFile ({optLevel, relocModel, codeModel, arch}
                    :write_native_options)
                   (dstfile, module) filetype =
        (
          #start Counter.llvmOutputTimeCounter();
          LLVM.compile {module = module,
                        arch = case arch of SOME x => x | NONE => "",
                        cpu = "",
                        optLevel = optLevel,
                        relocModel = relocModel,
                        codeModel = codeModel,
                        fileType = filetype,
                        outputFilename = Filename.toString dstfile};
          #stop Counter.llvmOutputTimeCounter()
        )
  in

  fun writeNativeAssembly options module =
      emitToFile options module LLVM.CGFT_AssemblyFile

  fun writeNativeObject options module =
      emitToFile options module LLVM.CGFT_ObjectFile

  end (* local *)
*)

  exception Return of InterfaceName.file_dependency * result

  fun compile llvmOptions
              (options as {stopAt, outputWarnings, ...}:TopData.options)
              (context as {topEnv, fixEnv, version, builtinDecls})
              input =
      let
        val outputWarnings = fn nil => () | l => outputWarnings l

        val _ = #start Counter.compilationTimeCounter()

        val _ = UserLevelPrimitive.initAnalyze
                  {analyzeIdRef = Analyzers.analyzeIdRefForUP,
                   analyzeTstrRef = Analyzers.analyzeTstrRefForUP
                  }

        val _ = initPointerSize llvmOptions

        val parsed = doParse input
        val (dependency, prelude, abunit) = doLoadFile options context parsed

        val (newFixEnv, plunit) = doElaboration outputWarnings fixEnv abunit

        val _ = if stopAt = SyntaxCheck
                then raise Return (dependency, STOPPED)
                else ()

        val source = Parser.sourceOfInput input 
        val (requireTopEnv, nameevalTopEnv, icdecls) =
            doNameEvaluation source outputWarnings context plunit

(*
        val _ = if stopAt = NameRef
                then raise Return (dependency, STOPPED)
                else ()
*)
        val _ = UserLevelPrimitive.init {env = requireTopEnv}

                                                   
        val icdecls = doTypedElaboration icdecls

        val icdecls = doVALRECOptimization icdecls

        val icdecls = if !Control.doUncurryOptimization
                     then icdecls
                     else doFundeclElaboration icdecls

        val _ = TopEnvUtils.setCurrentEnv 
                  (NameEvalEnvPrims.topEnvWithTopEnv (requireTopEnv,nameevalTopEnv))

        val (typeinfVarEnv, tpdecs) = 
            doTypeInference 
              (NameEvalEnvPrims.topEnvWithTopEnv (requireTopEnv,nameevalTopEnv))
              outputWarnings icdecls
            handle exn => raise exn

        val nameevalTopEnv =
            if !Control.interactiveMode
            then NameEvalEnvUtils.mergeTypeEnv (nameevalTopEnv, typeinfVarEnv)
            else nameevalTopEnv

        val nameevalTopEnv = NameEvalEnvUtils.resetInternalId nameevalTopEnv

        val tpdecs = if !Control.doUncurryOptimization
                     then doUncurryOptimization tpdecs
                     else tpdecs

        val (nameevalTopEnv, tpdecs) =
            if !Control.interactiveMode andalso not (!Control.skipPrinter)
            then doReifyTopEnv {sessionTopEnv=nameevalTopEnv,
                                requireTopEnv=topEnv}
                               version
                               tpdecs
            else (nameevalTopEnv, tpdecs)
        val newContext = {topEnv=nameevalTopEnv, fixEnv=newFixEnv}



        val tpdecs = doFFICompilation tpdecs

        val externalDecls = 
            map TypedCalc.TPEXTERNVAR
                (UserLevelPrimitive.getExternDecls())
        val tpdecs = externalDecls @ tpdecs

        val tpdecs = doMatchCompilation outputWarnings tpdecs

        val tpdecs =
            if stopAt <> ErrorCheck andalso !Control.doPolyTyElimination
            then doPolyTyElimination tpdecs
            else tpdecs

        val tpdecs =
            if stopAt <> ErrorCheck andalso !Control.doTCOptimization
            then doTypedCalcOptimization tpdecs
            else tpdecs

        val tldecs = doDatatypeCompilation tpdecs

        val _ = if stopAt = ErrorCheck
                then raise Return (dependency, STOPPED)
                else ()

        val rcdecs = doRecordCompilation tldecs

        val _ = if stopAt = NameRef
                then raise Return (dependency, STOPPED)
                else ()

        val externalDecls = 
            RecordCompilation.makeUerlelvelPrimitiveExternDecls
              (UserLevelPrimitive.getExternDecls())
        val rcdecs = externalDecls @ rcdecs

(*
        val rcdecs = if !Control.doRCOptimization
                     then doRecordCalcOptimization rcdecs
                     else rcdecs
*)

        val bcdecs = doBitmapCompilation rcdecs

        val cccalc = doClosureConversion2 bcdecs
        val nccalc = doCallingConventionCompile cccalc
        val ancalc = doANormalize nccalc
        val mccalc = doMachineCodeGen ancalc
        val mccalc = if !Control.insertCheckGC
                     then doInsertCheckGC mccalc
                     else mccalc
        val mccalc = doStackAllocation mccalc
        val llvmir = doLLVMGen llvmOptions (prelude, mccalc)
        val llfile = doLLVMEmit llvmir
        val bcfile = doAssemble llfile
        val _ =  #stop Counter.compilationTimeCounter()
        val _ = RuntimeTypes.uninit ()
      in
        (dependency, RETURN (newContext, bcfile))
      end
      handle Return return =>
             (#stop Counter.compilationTimeCounter();
              RuntimeTypes.uninit ();
              return)
           | e => (RuntimeTypes.uninit (); raise e)

  exception Return of InterfaceName.file_dependency

  fun loadInterfaces (options as {stopAt, ...}) context sources =
      let
        val (dependency, abunit) = doLoadInterface options sources
        val (newFixEnv, plunit) = doElabInterface options context abunit
        val _ = if stopAt = SyntaxCheck then raise Return dependency else ()
        val newTopEnv = doNameEvalInterface options context plunit
      in
        (dependency, {topEnv=newTopEnv, fixEnv=newFixEnv})
      end
      handle Return x => (x, emptyNewContext)

  fun loadBuiltin source =
      let 
        val options =
            {loadPath = nil,
             loadMode = InterfaceName.ALL,
             outputWarnings = fn l => raise UserError.UserErrors l}
        val context =
            {fixEnv = SymbolEnv.empty,
             topEnv = NameEvalEnv.emptyTopEnv}
        val (dependency, abunit) = doLoadInterface options [source]
        val (newFixEnv, plunit) = doElabInterface options context abunit
        val topdecs =
            case plunit of
              {interfaceDecs = [{requiredIds = nil, provideTopdecs, ...}],
               requiredIds = [_], topdecsInclude = nil} => provideTopdecs
            | _ =>
              raise UserError.UserErrors
                      [(Loc.noloc, UserError.Error, IllegalBuiltin (#2 source))]
        val (newTopEnv, idcalc) = NameEval.evalBuiltin topdecs
      in
        {topEnv=newTopEnv,
         version=InterfaceName.SELF,
         fixEnv=newFixEnv,
         builtinDecls=idcalc}
        : toplevelContext
      end

end
