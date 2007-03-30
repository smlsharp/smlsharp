(**
 * compilation of linkage unit
 * @author Liu Bochao
 * @version $Id: CompileObj.sml,v 1.20 2007/01/21 13:41:33 kiyoshiy Exp $
 *)
structure CompileObj =
struct

  (***************************************************************************)

  structure C = Control
  structure CT = Counter
  structure UE = UserError
  structure PU = PathUtility
  structure P = Pickle
  structure STE = StaticTypeEnv
  (***************************************************************************)

  type topTypeContext = InitialTypeContext.topTypeContext

  (* maybe "NonInteractive" will be changed to other name. *)
  datatype interactionMode =
           Interactive
         | NonInteractive of {stopOnError : bool}

  type context =
       {
         standardOutput : ChannelTypes.OutputChannel,
         standardError : ChannelTypes.OutputChannel,
         loadPathList : string list,
         getVariable : string -> string option
       }

  type source = 
       {
         interactionMode : interactionMode,
         initialSource : ChannelTypes.InputChannel,
         initialSourceName : string,
         interfaceSourceOpt : ChannelTypes.InputChannel option,
         interfaceSourceName : string,
         getBaseDirectory : unit -> string
       }

  fun initialize 
      {
        standardOutput : ChannelTypes.OutputChannel,
        standardError : ChannelTypes.OutputChannel,
        loadPathList,
        getVariable
      } =
      let
        val _ = Vars.initVars()
        val _ = Types.init()
        val _ = #reset Counter.root ()
      in
        {
          standardOutput = standardOutput,
          standardError = standardError,
          loadPathList = loadPathList,
          getVariable = getVariable
        } : context
      end

  fun fileNameWithoutSuffix fileName = 
      let
          val suffixLength = 
              case (OS.Path.ext fileName) of
                  SOME suffix => size(suffix) + 1
                | NONE => 0
      in
          substring(fileName, 0, size(fileName) - suffixLength)
      end

  fun run
      ({
         standardOutput : ChannelTypes.OutputChannel,
         standardError : ChannelTypes.OutputChannel,
         loadPathList,
         getVariable
       } : context)
      ({
         interactionMode,
         initialSource,
         initialSourceName,
         interfaceSourceOpt,
         interfaceSourceName,
         getBaseDirectory
       } : source) =
      let 

        (*********************************************************************)

        fun print message = 
            #print (CharacterStreamWrapper.wrapOut standardOutput) message

        fun printError message = 
            #print (CharacterStreamWrapper.wrapOut standardError) message

        fun printWarnings warnings =
            if ! C.printWarning
            then
              (
                #flush standardOutput ();
                app
                (fn warning => 
                    (
                      printError(C.prettyPrint(UE.format_errorInfo warning));
                      printError "\n"
                    ))
                warnings
              )
            else ()

        fun printDiagnoses diagnoses =
            if (! C.printDiagnosis)
            then
              (
                #flush standardOutput ();
                app
                (fn diagnosis => 
                    (
                      printError(C.prettyPrint(UE.format_errorInfo diagnosis));
                      printError "\n"
                    ))
                diagnoses
              )
            else ()

        type parseSource =
              {
                interactionMode : interactionMode,
                getBaseDirectory : unit -> string,
                fileName : string,
                stream : ChannelTypes.InputChannel,
                promptMode : bool,
                printInput : bool
              }

        fun getLine (source : parseSource) n = 
            (
              let
                val line =
                    (#getLine (CharacterStreamWrapper.wrapIn (#stream source)))
                        ()
              in
                if #printInput source
                then (print line; #flush standardOutput ())
                else ();

                line
              end
            )

        local
            fun printDecs decFormatter decs =
                app (fn dec => 
                        (printError (decFormatter dec);
                         printError "\n")) 
                    decs

            fun printAbsyn (linkageUnitDecs, interfaceDecsOpt) =
                if !C.printSource andalso !C.switchTrace then
                    (printError "Source expr:\n";
                     printDecs AbsynFormatter.topdecToString linkageUnitDecs;
                     Option.map (printDecs AbsynFormatter.topdecToString)  interfaceDecsOpt;
                     ())
                else ()

            fun elaborate (linkageUnitDecs, interfaceDecsOpt) =
                let
                    val (pldecs, newFixEnv1, warnings1) =
                        Elaborator.elaborate
                            Fixity.initialFixEnv linkageUnitDecs
                    val (plInterfaceDecsOpt, warnings2) =
                        case
                          Option.map
                              (Elaborator.elaborate Fixity.initialFixEnv) 
                              interfaceDecsOpt
                         of
                            NONE => (NONE, nil)
                          | SOME (decs, _, warnings) => (SOME decs, warnings)
                    val _ = printWarnings (warnings1 @ warnings2)
                    val _ =
                        if !C.printPL andalso !C.switchTrace
                        then
                            (
                             printError "\nElaborated to:\n";
                             printDecs PatternCalcFormatter.pltopdecToString pldecs;
                             Option.map (printDecs PatternCalcFormatter.pltopdecToString) 
                                        plInterfaceDecsOpt;
                             ()
                             )
                        else ()
                in
                    (pldecs, plInterfaceDecsOpt)
                end

            fun valRecOptimizer pldecs =
                let
                    val pldecs = 
                        VALREC_Optimizer.optimize InitialTypeContext.initialTopTypeContext  pldecs
                    val _ =
                        if !C.printPL andalso !C.switchTrace
                        then (printError "\nVAL REC optimize to:\n";
                              printDecs PatternCalcFormatter.pltopdecToString pldecs)
                        else ()
                in 
                    pldecs
                end

            fun unCurryOptimizer pldecs =
                if !C.doUncurryOptimization then
                    pldecs
                else
                    TransFundecl.transTopDeclList pldecs

            fun setTVars (pldecs, plInterfaceDecsOpt) =
                let
                    val ptdecs = map (SetTVars.settopdec SEnv.empty) pldecs
                    val ptInterfaceDecsOpt = 
                        Option.map (map (SetTVars.settopdec SEnv.empty)) 
                                   plInterfaceDecsOpt
                    val _ =
                        if !C.printPL andalso !C.switchTrace
                        then (printError "\nUser Tyvar Proceed:\n";
                              printDecs PatternCalcWithTvarsFormatter.pttopdecToString ptdecs;
                              Option.map 
                                  (printDecs PatternCalcWithTvarsFormatter.pttopdecToString)
                                  ptInterfaceDecsOpt;
                              ())
                        else ()
                in
                    (ptdecs, ptInterfaceDecsOpt)
                end

            fun typeInfer (ptdecs, ptInterfaceDecsOpt) =
                let
                    val (staticTypeEnv, tpdecs, warnings1) =
                        TypeInferencer.inferLinkageUnit ptdecs
                    val (exportSigOpt, warnings2) =
                        case
                            Option.map (TypeInferencer.inferInterface
                                            (#importTypeEnv staticTypeEnv))
                                       ptInterfaceDecsOpt
                         of
                            NONE => (NONE, nil)
                          | SOME (exportSig, warnings) => 
                            (SOME exportSig, warnings)
                    val (exportStaticTypeEnv, warnings3, tyInstTopDecs) = 
                        case exportSigOpt of
                            NONE => (staticTypeEnv, nil, nil)
                          | SOME exportSig => 
                            let
                                val loc =
                                    case valOf(ptInterfaceDecsOpt) of
                                        nil => Loc.noloc
                                      | [pttopdec] =>  
                                        PatternCalcWithTvars.getLocTopDec pttopdec
                                      | _ => raise Control.Bug "multiple top level export constructs"
                                val (newExportTypeEnv, warnings) =
                                    TypeInferencer.exportSigCheck
                                        (#exportTypeEnv staticTypeEnv, exportSig, loc)
                                (* below deal with type instantiation declarations *)
                                val tyInstDecs = 
                                    TypeInstantiationTerm.generateInstantiatedStructure 
                                        (Path.NilPath, loc)
                                        (STE.typeEnvToEnv (#exportTypeEnv staticTypeEnv),
                                         STE.typeEnvToEnv newExportTypeEnv)
                            in
                                (STE.injectExportTypeEnvInStaticTypeEnv 
                                     (newExportTypeEnv,  staticTypeEnv),
                                 warnings,
                                 map (fn x => TypedCalc.TPMDECSTR (x, loc)) tyInstDecs)
                            end
                    val _ = printWarnings (warnings1 @ warnings2 @ warnings3)
                    val _ =
                        if !C.printTP andalso !C.switchTrace
                        then
                            (
                             printError "\nStatically evaluated to:\n";
                             printDecs (TypedCalcFormatter.tptopdecToString nil) tpdecs;
                             printError "\nGenerated static bindings:\n";
                             printError (Control.prettyPrint 
                                             (StaticTypeEnv.format_staticTypeEnv nil staticTypeEnv))
                             )
                        else ()
                in
                    (exportStaticTypeEnv, tpdecs @ tyInstTopDecs)
                end

            fun printCodeGeneration (staticTypeEnv, tpdecs) =
                let
                    val (staticTypeEnv, tpdecs) =
                        if !C.skipPrinter
                        then (staticTypeEnv, tpdecs)
                        else
                            PrinterGenerator.generateForSeparateCompile
                                {
                                 newTypeEnv = staticTypeEnv,
                                 printBinds = !C.printBinds,
                                 declarations = tpdecs
                                 }
                    val _ =
                        if !C.printTP andalso !C.switchTrace andalso false = !C.skipPrinter
                        then
                            (printError "\n Print Code Generation:\n";
                             printDecs (TypedCalcFormatter.tptopdecToString nil) tpdecs;
                             printError "\nGenerated static bindings:\n";
                             printError (Control.prettyPrint 
                                             (StaticTypeEnv.format_staticTypeEnv nil staticTypeEnv))
                             )
                    else ()
                in
                    (staticTypeEnv, tpdecs)
                end

            fun moduleCompile (staticTypeEnv, tpdecs) =
                let
                    val (staticModuleEnv, tpflatdecs) =
                        ModuleCompiler.compileLinkageUnit tpdecs
                    val newStaticModuleEnv = 
                        ModuleCompileUtils.filterStaticModuleEnv (staticModuleEnv, staticTypeEnv)
                    val _ =
                        if !C.printTFP andalso !C.switchTrace
                        then (printError "\nModule Compiled to:\n";
                              printDecs (PrintTFP.tfpdecToString nil) tpflatdecs)
                        else ()
                in
                    (newStaticModuleEnv, tpflatdecs)
                end

            fun matchCompile tpflatdecs =
                let
                    val (rcdecs, warnings) = MatchCompiler.compile tpflatdecs
                    val _ = printWarnings warnings
                    val _ =
                        if !C.printRC andalso !C.switchTrace
                        then (printError "\nMatch Compiled to:\n";
                              printDecs (RecordCalcFormatter.rcdecToString nil) rcdecs)
                        else ()
                in
                    rcdecs
                end

            fun recordCompile rcdecs =
                let
                    val tldecs = RecordCompiler.compile rcdecs
                    val _ =
                        if !C.printTL andalso !C.switchTrace
                        then (printError "\nRecord Compiled to:\n";
                              printDecs (TypedLambdaFormatter.tldecToString nil) tldecs)
                        else ()
                in
                    tldecs
                end

            fun typeCheck tldecs =
                if !C.checkType
                then
                    let
                        val diagnoses =
                            TypeCheckTypedLambda.typechekTypedLambda
                                tldecs
                        val _ = printDiagnoses diagnoses
                    in
                        ()
                    end
                else ()
        in
            fun compileTopdecs (linkageUnitDecs, interfaceDecsOpt) =
                let
                    val _ = printAbsyn (linkageUnitDecs, interfaceDecsOpt)
                            
                    (* elaboration *)
                    val (pldecs, plInterfaceDecsOpt) = 
                        elaborate (linkageUnitDecs, interfaceDecsOpt)                       
                        
                    (* VAL REC optimization *)
                    val pldecs = valRecOptimizer pldecs
                                 
                    (* Uncurrying  optimization *)
                    val pldecs = unCurryOptimizer pldecs
                                 
                    (* process user type declaration *)
                    val (ptdecs, ptInterfaceDecsOpt) = setTVars (pldecs, plInterfaceDecsOpt)
                                                       
                    (* type inference *)
                    val (staticTypeEnv, tpdecs) = typeInfer (ptdecs, ptInterfaceDecsOpt)
                                                  
                    (* print code generation *)
                    val (staticTypeEnv, tpdecs) = printCodeGeneration (staticTypeEnv, tpdecs)
                                                  
	            (* module compile *)
                    val (staticModuleEnv, tpflatdecs) = moduleCompile (staticTypeEnv, tpdecs)
                                                  
                    (* match compile *)
                    val rcdecs = matchCompile tpflatdecs
                                 
                    (* record compile *)
                    val tldecs = recordCompile rcdecs                
                                 
                    (* type check *)
                    val _ = typeCheck tldecs
                                      
                    (* pickling *)
                    local 
                        val objName = (fileNameWithoutSuffix initialSourceName) ^ ".smo"
                        val linkageUnit =
                            {fileName = objName,
                             staticTypeEnv = staticTypeEnv,
                             staticModuleEnv = staticModuleEnv,
                             hiddenValIndexList = nil,
                             code = tldecs}
                        val outfile = BinIO.openOut objName
                        val outstream =
                            Pickle.makeOutstream
                                (fn byte => BinIO.output1 (outfile, byte)) 
                    in
                        val _ = print "[begin pickle ................"
                        val _ = P.pickle LinkageUnitPickler.linkageUnit linkageUnit outstream 
                        val _ = print "done]\n"
                        val _ = print "\n[******** compiled object *************]\n"
                        val _ = print 
                                    (Control.prettyPrint 
                                         (LinkageUnit.format_linkageUnit nil linkageUnit))
                        val _ = print "\n[**************************************]\n"
                        val _ = BinIO.closeOut outfile
                    end
                        
                (*
                 (* buc transformation *)
                 val _ = #start bitmapCompilationTimeCounter ()
                 val bucdecls =
                     BUCTransformer.transform optimizedTldecs 
                 val _ = #stop bitmapCompilationTimeCounter ()
                         
                 val _ =
                     if !C.printBUC andalso !C.switchTrace
                     then
                         (
                          printError "\nBUC transform to:\n";
                          app
                              (fn decl =>
                                  printError
                                      (BUCCalcFormatter.bucdeclToString [] decl
                                       ^ "\n"))
                              bucdecls
                              )
                     else ()
                          
                 (* Anormalization *)
                          
                 val _ = #start untypedBitmapCompilationTimeCounter ()
                 val anexp = ANormalTranslator.translate bucdecls
                 val _ = #stop untypedBitmapCompilationTimeCounter ()
                         
                 val _ =
                     if !C.printAN andalso !C.switchTrace
                     then
                         (
                          printError "\nUntyped bitmap compiled to:\n";
                          printError
                              (ANormalFormatter.anexpToString anexp ^ "\n")
                              )
                     else ()
                          
                 (* linearize *)
                 val _ = #start linearizationTimeCounter ()
                 val symbolicCode as {functions, ...} =
                     Linearizer.linearize anexp
                 val _ = #stop linearizationTimeCounter ()
                         
                 val _ =
                     if !C.printLS andalso !C.switchTrace
                     then
                         (
                          printError "\nLinearized to:\n";
                          app
                              (printError
                               o (fn string => string ^ "\n")
                               o SymbolicInstructionsFormatter.functionCodeToString)
                              functions
                              )
                     else ()
                          
                 (* code optimization *)
                 val symbolicCode as {functions, ...} =
                     {
                      mainFunctionName = #mainFunctionName symbolicCode,
                      functions =
                      if !C.doCodeOptimization
                      then
                          map
                              CodeOptimizer.optimize
                              functions
                      else functions
                           }
                     
                 val _ =
                     if !C.printLS andalso !C.switchTrace
                     then
                         (
                          printError "\nCode Optimized to:\n";
                          app
                              (printError
                               o (fn string => string ^ "\n")
                               o SymbolicInstructionsFormatter.functionCodeToString)
                              functions
                              )
                     else ()
                          
                 (* assemble *)
                 val _ = #start assembleTimeCounter ()
                 val executable as {instructions, locationTable, ...} =
                     Assembler.assemble symbolicCode
                 val _ = #stop assembleTimeCounter ()
                         
                 val _ =
                     if !C.printIS andalso !C.switchTrace
                     then
                         (
                          printError "\nAssembled to:\n";
                          app
                              (printError
                               o (fn string => string ^ "\n")
                               o Instructions.toString)
                              instructions;
                              printError
                                  (Executable.locationTableToString locationTable)
                                  )
                     else ()
                          
                 (* serialize *)
                 val _ = #start serializeTimeCounter ()
                 val codeBlock = ExecutableSerializer.serialize executable
                 val _ = #stop serializeTimeCounter ()
                 *)
                in
                    () (* codeBlock *) 
                end
        end
        (****************************************)

        val onParseError = printError o Parser.errorToString

        fun makeParseSourceAndParseContext  (source, sourceName)
          = 
          let
              val parseSource = 
                  {
                   interactionMode = interactionMode,
                   getBaseDirectory = getBaseDirectory,
                   fileName = sourceName,
                   stream = source,
                   promptMode =
                   case interactionMode of Interactive => true | _ => false,
                   printInput = false
                   } : parseSource
          in
              (parseSource,
               (Parser.createContext {
                                      isPrelude = false,
                                      sourceName = sourceName,
                                      onError = onParseError,
                                      getLine = getLine parseSource
                                      }
                )
               )
          end
          
        val (initialSource, initialParseContext) =
            makeParseSourceAndParseContext (initialSource, initialSourceName)
        val (interfaceSourceOpt, interfaceParseContextOpt) =
            case interfaceSourceOpt of
                SOME src => 
                let
                    val (parsrc, parcon) = 
                        makeParseSourceAndParseContext 
                            (src, interfaceSourceName)
                in
                    (SOME parsrc, SOME parcon)
                end 
              | NONE => (NONE, NONE)
                        
        fun useInput (currentSource : parseSource) (fileName, loc) = 
            let
              val currentBaseDirectory = #getBaseDirectory currentSource ()
              val absoluteFilePath =
                  PathResolver.resolve
                      getVariable loadPathList currentBaseDirectory fileName
                  handle exn => raise UE.UserErrors [(loc, UE.Error, exn)]
              val _ =
                  if !C.switchTrace
                  then printError ("loading: " ^ absoluteFilePath ^ "\n")
                  else ()
              val baseDirectory = OS.Path.dir absoluteFilePath
              val newSource =
                  {
                    interactionMode = NonInteractive {stopOnError = true},
                    fileName = fileName,
                    getBaseDirectory = fn () => baseDirectory,
                    stream = FileChannel.openIn {fileName = absoluteFilePath},
                    promptMode = false,
                    printInput = false
                  } : parseSource
              val newParseContext =
                  Parser.createContext
                      {
                       isPrelude = false,
                       sourceName = fileName,
                       onError = onParseError,
                       getLine = getLine newSource
                       }
            in
              (newSource, newParseContext)
            end

        fun flush parseContext = 
           Parser.resumeContext parseContext

        fun errorHandler exn =
            (
              #flush standardOutput ();
              case exn of
                Parser.ParseError => ()
              | exn as UE.UserErrors errors =>
                (
                  app
                      (fn error =>
                          (
                            printError
                                (C.prettyPrint
                                     (UE.format_errorInfo error));
                            printError "\n"
                          ))
                      errors;
                  printError "\n"
                )
              | exn as C.Bug message =>
                (
                  printError ("BUG :" ^ message ^"\n");
                  app
                      (fn line => printError (line ^ "\n"))
                      (SMLofNJ.exnHistory exn)
                )
              | exn as C.BugWithLoc (message, loc) =>
                (
                  printError ("BUG :" ^ message ^"\n");
                  printError ("  at " ^ AbsynFormatter.locToString loc ^ "\n");
                  app
                      (fn line => printError (line ^ "\n"))
                      (SMLofNJ.exnHistory exn)
                )
              | SessionTypes.Error cause =>
                printError ("RuntimeError:" ^ exnMessage cause ^ "\n")
              | IO.Io ioError =>
                let
                  val function = (#function ioError)
                  val name = (#name ioError)
                  val cause = (#cause ioError)
                  val message =
                      case cause of
                        OS.SysErr (_, SOME inner) => 
                        "GenLex error: use clause ignored. " ^
                        OS.errorMsg inner ^ " : " ^ name
                      | _ => "IO error " ^ function ^ " " ^ name
                in
                  printError (message ^ "\n")
                end
              | OS.SysErr(message, _) => printError (message ^ "\n")
              | _ => raise exn;
              #flush standardError ()
            )

        (** indicates the result of compilation of the current
         * compile unit and how to do next. *)
        datatype 'a compileResult =
                 (** The process of the current source has finished. *) Finish
               | (** The process of the current source should be aborted. *)
                 StopByError 
               | (** The process of the current source should continue. *)
                 Continue of 'a


        (** true if process of the current source should be stopped when any
         * error occurs. *)
        fun isStopOnError (source : parseSource) =
            case #interactionMode source of
              Interactive => false
            | NonInteractive {stopOnError, ...} => stopOnError

        (**
         * This function is called by processSource.
         * Any exception raised in this function is handled by the
         * processSource.
         * @return true if the process of the source should continue.
         *)
        fun processParseResult (source, parseResult) =
            case parseResult of
                Absyn.USE (fileName, loc) => 
                (let
                     val (innerSource, innerParseContext) =
                         useInput source (fileName, loc)
                 in
                     ((processSource (innerSource, innerParseContext))
                      handle exn =>
                             (#close (#stream innerSource) (); raise exn))
                     before (#close (#stream innerSource) ())
                 end)
              | Absyn.TOPDECS (topdecs,loc) => topdecs
              | Absyn.USEOBJ (_, loc) => 
                raise UE.UserErrors [(loc, 
                                      UE.Error, 
                                      TopLevelError.UseObjOccurInLinkageUnit)]
        

        and processCompileUnit source parseContext =
            (
             let
                 val newParseContextOpt =
                     SOME(Parser.parse parseContext)
                     handle Parser.EndOfParse => NONE
                          | exn => raise exn
             (* parseTimeCounter is started in the getLine function *)
             in
                 case newParseContextOpt of
                     NONE => (nil, Finish) (* End Of Source *)
                   | SOME(parseResult, newParseContext) =>
                     (processParseResult (source, parseResult), Continue newParseContext)
             end
            )

        (**
         * parse loops 
         * @return abstract syntax tree
         *)
        and processSource (source, parseContext) =
            let
                fun loop parseContext code =
                    let
                        val (topdecs, result) = 
                            processCompileUnit source parseContext
                    in
                        case result of
                            Finish => code
                          | StopByError => code
                          | Continue(newParseContext) =>
                            (* loop again, because the process of the source has
                             * not finished nor aborted. *)
                            loop newParseContext (code @ topdecs)
                  end
            in
              (* begin a loop of parsing compile units. *)
                loop parseContext nil
            end
      in
          let
              val linkageUnitTopdecs = 
                  processSource (initialSource, initialParseContext) 
              val interfaceTopDecsOpt =
                  case (interfaceSourceOpt, interfaceParseContextOpt) of
                      (SOME src, SOME parcon) => SOME (processSource (src, parcon))
                    | _ => NONE
          in
              compileTopdecs (linkageUnitTopdecs, interfaceTopDecsOpt)
          end handle exn => errorHandler exn
      end

  fun compile fileName =
      let
          val useBasis = ref false

          val _ = C.printBinds := true
          val _ = C.switchTrace := true
          val _ = C.doCompileObj := true
                  
          val currentDir = 
              OS.FileSys.fullPath(#dir(PathUtility.splitDirFile "./"))

          val topInitializeParameter = 
              {
               standardOutput =
               TextIOChannel.openOut {outStream = TextIO.stdOut},
               standardError =
               TextIOChannel.openOut {outStream = TextIO.stdErr},
               loadPathList = ["."],
               getVariable = OS.Process.getEnv
               }

          val context = initialize topInitializeParameter

          val sourceFileChannel = FileChannel.openIn {fileName = fileName}
          val interfaceFileName = (fileNameWithoutSuffix fileName)^ ".smi"
          val interfaceFileChannelOpt = 
              SOME (FileChannel.openIn {fileName = interfaceFileName})
              handle IO.Io _ => NONE
                   | ex => raise ex

          val currentSwitchTrace = !C.switchTrace
          val currentPrintBinds = !C.printBinds
      in
          run
              context
              {
               interactionMode = NonInteractive {stopOnError = true},
               initialSource = sourceFileChannel,
               initialSourceName = fileName,
               interfaceSourceOpt = interfaceFileChannelOpt,
               interfaceSourceName = interfaceFileName,
               getBaseDirectory = fn () => currentDir
              }
              handle e =>
                     (
                      #close sourceFileChannel ();
                      C.switchTrace := currentSwitchTrace;
                      C.printBinds := currentPrintBinds;
                      raise e
                            )
      end


  (***************************************************************************)
end
