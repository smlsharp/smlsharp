(**
 * compiler toplevel
 * @copyright (c) 2010, 2011, 2012, 2013, Tohoku University.
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

  val defaultOptions =
      {
        stopAt = NoStop,
        baseFilename = NONE,
        stdPath = nil,
        loadPath = nil,
        loadAllInterfaceFiles = false
      } : options

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

  fun incVersion (context as {version, ...}: toplevelContext) =
      context # {version = case version of
                             NONE => SOME 0
                           | SOME i => SOME (i + 1)}

  val emptyNewContext =
      {
        topEnv = NameEvalEnv.emptyTopEnv,
        fixEnv = SymbolEnv.empty
      } : newContext

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

  fun printWarnings warnings =
      if !Control.printWarning
      then printLines "" userErrorToString warnings
      else ()

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
      printCode [flag] (Bug.prettyPrint o Absyn.format_unitparseresult)
                title [code]

  fun printAbsyn flag title code =
      printCode [flag] (Bug.prettyPrint o AbsynInterface.format_compileUnit)
                title [code]

  fun printPatternCalc flag title code =
      printCode [flag]
                (Bug.prettyPrint o PatternCalcInterface.format_compileUnit)
                title [code]

  fun printPatternCalcInteractive flagList title code =
      printCode flagList
                (Bug.prettyPrint o PatternCalcInterface.format_interactiveUnit)
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
         then Bug.prettyPrint o (TypedCalc.formatWithType_tpdecl nil)
         else Bug.prettyPrint o (TypedCalc.format_tpdecl nil))
        title code

  fun printRecordCalc flagList title code =
      printCode
        flagList
        (if !Control.printWithType
         then Bug.prettyPrint o (RecordCalc.format_rcdecl nil)
         else Bug.prettyPrint o (RecordCalc.formatWithoutType_rcdecl nil))
        title code

  fun printTypedLambda flagList title code =
      printCode
        flagList
        (if !Control.printWithType
         then Bug.prettyPrint o (TypedLambda.formatWithType_tldecl nil)
         else Bug.prettyPrint o (TypedLambda.format_tldecl nil))
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

  fun printLLVMModule flag title module =
      if !flag
      then (printError title; printError ":\n"; flushError ();
            LLVM.LLVMDumpModule module)
      else ()

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

  fun doLoadFile ({baseFilename, stdPath, loadPath, loadAllInterfaceFiles,
                   ...}:options)
                 ({version, ...}: toplevelContext)
                 absyn =
      let
        val _ = #start Counter.loadFileTimeCounter()
        val (dependency, abunit) =
            LoadFile.load
              {baseFilename=baseFilename, stdPath=stdPath, loadPath=loadPath,
               loadAll=loadAllInterfaceFiles}
              absyn
        val _ = #stop Counter.loadFileTimeCounter()
        val _ = printAbsyn Control.printLoadFile "File Loaded" abunit
      in
        (dependency, abunit)
      end

  fun doElaboration fixEnv abunit =
      let
        val _ = #start Counter.elaborationTimeCounter()
        val (newFixEnv, plunit, warnings) = Elaborator.elaborate fixEnv abunit
        val _ =  #stop Counter.elaborationTimeCounter()
        val _ = printWarnings warnings
        val _ = printPatternCalc Control.printElab "Elaborated" plunit
      in
        (newFixEnv, plunit)
      end

  fun doElaborationInteractiveEnv fixEnv interactiveUnit =
      let
        val _ = #start Counter.elaborationTimeCounter()
        val (newFixEnv, plinteractievUnit, warnings) = 
            Elaborator.elaborateInteractiveEnv fixEnv interactiveUnit
        val _ =  #stop Counter.elaborationTimeCounter()
        val _ = printWarnings warnings
        val _ = printPatternCalcInteractive 
                  [Control.printElab, Control.printSystemDecls] 
                  "Elaborated" plinteractievUnit
      in
        (newFixEnv, plinteractievUnit)
      end

  fun doNameEvaluation ({topEnv, version, builtinDecls, ...}:toplevelContext) plunit =
      let
        val _ = #start Counter.nameEvaluationTimeCounter()
        val {requireTopEnv, returnTopEnv, icdecls, warnings} =
            NameEval.nameEval {topEnv=topEnv, version=version,
                               systemDecls=builtinDecls} plunit
        val _ =  #stop Counter.nameEvaluationTimeCounter()
        val _ = printWarnings warnings
        val _ = printIDCalc [Control.printNameEval] "Name Evaluation" icdecls
      in
        (requireTopEnv, returnTopEnv, icdecls)
      end

  fun doNameEvaluationInteractiveEnv topEnv plinteractive =
      let
        val _ = #start Counter.nameEvaluationTimeCounter()
        val (nameevalTopEnv, warnings) =
            NameEval.nameEvalInteractiveEnv topEnv plinteractive
        val _ =  #stop Counter.nameEvaluationTimeCounter()
        val _ = printWarnings warnings
      in
        nameevalTopEnv
      end

  fun doTypeInference icdecls =
      let
        val _ = #start Counter.typeInferenceTimeCounter()
        val (typeinfVarE, tpdecs, warnings) = InferTypes.typeinf icdecls
        val _ =  #stop Counter.typeInferenceTimeCounter()
        val _ = printWarnings warnings
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

  fun doMatchCompilation tpdecs =
      let
        val _ = #start Counter.matchCompilationTimeCounter()
        val (rcdecs, warnings) = MatchCompiler.compile tpdecs
        val _ =  #stop Counter.matchCompilationTimeCounter()
        val _ = printRecordCalc [Control.printMatchCompile]
                                "Match Compiled" rcdecs
        val _ = printWarnings warnings
      in
        rcdecs
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

  fun doFFICompilation nameevalTopEnv rcdecs =
      let
        val _ = #start Counter.ffiCompilationTimeCounter()
        val rcdecs = FFICompilation.compile nameevalTopEnv rcdecs
        val _ =  #stop Counter.ffiCompilationTimeCounter()
        val _ = printRecordCalc [Control.printFFICompile] "FFI Compiled" rcdecs
      in
        rcdecs
      end

  fun doRecordCompilation nameevalTopEnv rcdecs =
      let
       val _ = #start Counter.recordCompilationTimeCounter()
        val rcdecs = RecordCompilation.compile rcdecs
        val _ =  #stop Counter.recordCompilationTimeCounter()
        val _ = printRecordCalc [Control.printRecordCompile]
                                "Record Compiled" rcdecs
      in
       rcdecs
      end

  fun doDatatypeCompilation rcdecs =
      let
        val _ = #start Counter.datatypeCompilationTimeCounter()
        val tldecs = DatatypeCompilation.compile rcdecs
        val _ =  #stop Counter.datatypeCompilationTimeCounter()
        val _ = printTypedLambda [Control.printDatatypeCompile]
                                 "Datatype Compiled" tldecs
      in
        tldecs
      end

  fun doBitmapCompilation2 tldecs =
      let
        val _ = #start Counter.bitmapCompilationTimeCounter()
        val bcdecs = BitmapCompilation2.compile tldecs
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

  fun doMachineCodeGen dependency anprog =
      let
        val _ = #start Counter.machineCodeGenTimeCounter()
        val mcprog = MachineCodeGen.compile dependency anprog
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

  fun doLLVMGen ({triple,...}:LLVMUtils.compile_options) mcprog =
      let
        val _ = #start Counter.llvmGenTimeCounter()
        val llvmprog = LLVMGen.compile {targetTriple = triple} mcprog
        val _ = #stop Counter.llvmGenTimeCounter()
        val _ = printLLVMIR Control.printLLVMGen "LLVM generated" llvmprog
      in
        llvmprog
      end

  fun doLLVMEmit llvmir =
      let
        val _ = #start Counter.llvmEmitTimeCounter()
        val module = LLVMEmit.emit llvmir
        val _ = #stop Counter.llvmEmitTimeCounter()
        val _ = printLLVMModule Control.printLLVMEmit "LLVM Emit" module
      in
        module
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

  exception Return of InterfaceName.dependency * result

  fun compile llvmOptions
              (options as {stopAt,...}:TopData.options)
              (context as {topEnv, fixEnv, version, builtinDecls}) input =
      let
        val _ = #start Counter.compilationTimeCounter()

        val _ = InitPointerSize.init llvmOptions

        val parsed = doParse input
        val (dependency, abunit) = doLoadFile options context parsed

        val (newFixEnv, plunit) = doElaboration fixEnv abunit

        val _ = if stopAt = SyntaxCheck
                then raise Return (dependency, STOPPED)
                else ()

        val (requireTopEnv, nameevalTopEnv, icdecls) =
            doNameEvaluation context plunit
        val externDecls = UserLevelPrimitive.init requireTopEnv
        val icdecls = icdecls @ externDecls
        val icdecls = doTypedElaboration icdecls
        val icdecls = doVALRECOptimization icdecls

        val icdecls = if !Control.doUncurryOptimization
                     then icdecls
                     else doFundeclElaboration icdecls

        val (typeinfVarEnv, tpdecs) = doTypeInference icdecls
            handle exn => raise exn

        val nameevalTopEnv =
            if !Control.interactiveMode
            then NameEvalEnvUtils.mergeTypeEnv (nameevalTopEnv, typeinfVarEnv)
            else nameevalTopEnv

        val nameevalTopEnv = NameEvalEnvUtils.resetInternalId nameevalTopEnv

        val newContext = {topEnv=nameevalTopEnv, fixEnv=newFixEnv}

        val tpdecs = if !Control.doUncurryOptimization
                     then doUncurryOptimization tpdecs
                     else tpdecs

        val tpdecs =
            if stopAt <> ErrorCheck andalso !Control.doTCOptimization
            then doTypedCalcOptimization tpdecs
            else tpdecs

        val rcdecs = doMatchCompilation tpdecs

        val _ = if stopAt = ErrorCheck
                then raise Return (dependency, STOPPED)
                else ()

        val rcdecs =
            if !Control.interactiveMode andalso not (!Control.skipPrinter)
            then rcdecs @ (ReifyTopEnv.reifyTopEnv nameevalTopEnv)
            else rcdecs

        val rcdecs = doFFICompilation nameevalTopEnv rcdecs
        val rcdecs = doRecordCompilation nameevalTopEnv rcdecs

        val rcdecs = if !Control.doRCOptimization
                     then doRecordCalcOptimization rcdecs
                     else rcdecs

        val tldecs = doDatatypeCompilation rcdecs
        val bcdecs = doBitmapCompilation2 tldecs
        val cccalc = doClosureConversion2 bcdecs
        val nccalc = doCallingConventionCompile cccalc
        val ancalc = doANormalize nccalc
        val mccalc = doMachineCodeGen dependency ancalc
        val mccalc = if !Control.insertCheckGC
                     then doInsertCheckGC mccalc
                     else mccalc
        val mccalc = doStackAllocation mccalc
        val llvmir = doLLVMGen llvmOptions mccalc
        val module = doLLVMEmit llvmir

        val _ =  #stop Counter.compilationTimeCounter()
      in
        (dependency, RETURN (newContext, module))
      end
      handle Return return =>
             (#stop Counter.compilationTimeCounter(); return)

  fun loadBuiltin filename =
      let
        val file = Filename.TextIO.openIn filename
        val input = InterfaceParser.setup
                      {read = fn n => TextIO.inputN (file, n),
                       sourceName = Filename.toString filename}
        val itop = InterfaceParser.parse input
        val abunit =
            case itop of
              AbsynInterface.INTERFACE {requires=nil, provide} =>
              {interface = 
               SOME {interfaceDecs = nil,
                     provideInterfaceNameOpt = NONE,
                     provideTopdecs = provide,
                     requiredIds = nil,
                     locallyRequiredIds = nil},
               topdecsInclude = nil,
               topdecsSource = nil}
            | _ => raise Bug.Bug "illeagal builtin file"
        val (fixEnv, plunit, warnings) =
            Elaborator.elaborate SymbolEnv.empty abunit
        val pidecls = 
            case (#interface plunit) of
              SOME {provideTopdecs,...} => provideTopdecs
            | NONE => nil
        val (topEnv, idcalc) = NameEval.evalBuiltin pidecls
        val version = NONE
      in
        {topEnv=topEnv, version=version, fixEnv=fixEnv,
         builtinDecls=idcalc}
        : toplevelContext
      end

  fun loadInteractiveEnv {stopAt, stdPath, loadPath}
                         ({topEnv, fixEnv, ...}:toplevelContext)
                         filename =
      let
        val _ = #start Counter.loadFileTimeCounter()
        val plinteractive =
            LoadFile.loadInteractiveEnv {stdPath=stdPath, loadPath=loadPath,
                                         loadAll=false} filename
        val _ =  #stop Counter.loadFileTimeCounter()
        val (newFixEnv, plinteractive)  = doElaborationInteractiveEnv fixEnv plinteractive
        val newTopEnv = doNameEvaluationInteractiveEnv topEnv plinteractive
      in
        {topEnv=newTopEnv, fixEnv=newFixEnv}
      end

  type load_interface_options =
       {stopAt : stopAt,
        stdPath : Filename.filename list,
        loadPath : Filename.filename list,
        loadAllInterfaceFiles : bool}

  fun loadInterface ({stopAt, stdPath, loadPath,
                      loadAllInterfaceFiles}:load_interface_options)
                    ({topEnv, fixEnv, ...}:toplevelContext)
                    filename =
      let
        val _ = #start Counter.loadFileTimeCounter ()
        val (dependency, abunit) =
            LoadFile.loadInterfaceFile
              {stdPath=stdPath, loadPath=loadPath,
               loadAll=loadAllInterfaceFiles}
              filename
        val _ = #stop Counter.loadFileTimeCounter ()
        val _ = printCode [Control.printLoadFile]
                          (Bug.prettyPrint
                           o AbsynInterface.format_interface_unit)
                          "File Loaded" [abunit]

        val _ = #start Counter.elaborationTimeCounter ()
        val (newFixEnv, plunit, warnings) =
            Elaborator.elaborateInterface fixEnv abunit
        val _ =  #stop Counter.elaborationTimeCounter()
        val _ = printWarnings warnings
        val _ = printCode [Control.printElab, Control.printSystemDecls]
                          (Bug.prettyPrint
                           o PatternCalcInterface.format_interface_unit)
                          "Elaborated" [plunit]
      in
        if stopAt = SyntaxCheck then (dependency, NONE) else
        let
          val _ = #start Counter.nameEvaluationTimeCounter ()
          val (newTopEnv, warnings) = NameEval.nameEvalInterface topEnv plunit
          val _ =  #stop Counter.nameEvaluationTimeCounter ()
          val _ = printWarnings warnings
        in
          (* return newContext for codes requiring this interface *)
          (dependency, SOME {topEnv=newTopEnv, fixEnv=newFixEnv})
        end
      end

end
