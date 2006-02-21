(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author Atsushi Ohori 
 * @author YAMATODANI Kiyoshi
 * @version $Id: Top.sml,v 1.139 2006/02/18 04:59:30 ohori Exp $
 *)
structure Top : TOP =
struct

  (***************************************************************************)

  structure C = Control
  structure CT = Counter
  structure UE = UserError
  structure SE = StaticEnv
  structure PU = PathUtility
  structure P = Pickle

  (***************************************************************************)

  (* maybe "NonInteractive" will be changed to other name. *)
  datatype interactionMode =
           Interactive
         | NonInteractive of {stopOnError : bool}

  type context =
       {
         fixEnvRef : SE.fixity SEnv.map ref,
	 moduleEnvRef : ModuleCompiler.moduleEnv ref,
         session : SessionTypes.Session,
         standardOutput : ChannelTypes.OutputChannel,
         standardError : ChannelTypes.OutputChannel,
         loadPathList : string list,
         getVariable : string -> string option,
         topTypeContextRef : InitialTypeContext.topTypeContext ref
       }

  type contextParameter =
      {
        session : SessionTypes.Session,
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
         getBaseDirectory : unit -> string
       }

  (***************************************************************************)

  val CT.CounterSet TopCounterSet =
      #addSet CT.root ("Top", CT.ORDER_OF_ADDITION)
  val CT.CounterSet ElapsedCounterSet =
      #addSet TopCounterSet ("elapsed time", CT.ORDER_OF_ADDITION)
  val CT.ElapsedTimeCounter parseTimeCounter =
      #addElapsedTime ElapsedCounterSet "parse"
  val CT.ElapsedTimeCounter compilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "compilation (after parse)"
  val CT.ElapsedTimeCounter elaborationTimeCounter =
      #addElapsedTime ElapsedCounterSet "elaboration"
  val CT.ElapsedTimeCounter valRecOptimizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "val rec optimize"
  val CT.ElapsedTimeCounter setTVarsTimeCounter =
      #addElapsedTime ElapsedCounterSet "set tvars"
  val CT.ElapsedTimeCounter typeInferenceTimeCounter =
      #addElapsedTime ElapsedCounterSet "type inference"
  val CT.ElapsedTimeCounter UncurryOptimizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "uncurry optimize"
  val CT.ElapsedTimeCounter printerGenerationTimeCounter =
      #addElapsedTime ElapsedCounterSet "printer generation"
  val CT.ElapsedTimeCounter moduleCompilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "module compilation"
  val CT.ElapsedTimeCounter matchCompilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "match compilation"
  val CT.ElapsedTimeCounter recordCompilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "record compilation"
  val CT.ElapsedTimeCounter lambdaOptimizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "lambda optimization"
  val CT.ElapsedTimeCounter bitmapCompilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "bitmap compilation"
  val CT.ElapsedTimeCounter untypedBitmapCompilationTimeCounter =
      #addElapsedTime ElapsedCounterSet "untyped bitmap compilation"
  val CT.ElapsedTimeCounter linearizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "linearize"
  val CT.ElapsedTimeCounter assembleTimeCounter =
      #addElapsedTime ElapsedCounterSet "assemble"
  val CT.ElapsedTimeCounter serializeTimeCounter =
      #addElapsedTime ElapsedCounterSet "serialize"
  val CT.ElapsedTimeCounter executeTimeCounter =
      #addElapsedTime ElapsedCounterSet "execute"
  val CT.ElapsedTimeCounter pickleEnvsCounter =
      #addElapsedTime ElapsedCounterSet "pickle environments"
  val CT.ElapsedTimeCounter unpickleEnvsCounter =
      #addElapsedTime ElapsedCounterSet "unpickle environments"

  (****************************************)

  fun initialize 
      {
        session : SessionTypes.Session,
        standardOutput : ChannelTypes.OutputChannel,
        standardError : ChannelTypes.OutputChannel,
        loadPathList,
        getVariable
      } =
      let
        val _ = StaticEnv.init()
        val _ = Vars.initVars()
        val _ = Types.init()
        val _ = #reset Counter.root ()
      in
        {
          session = session,
          standardOutput = standardOutput,
          standardError = standardError,
          loadPathList = loadPathList,
          getVariable = getVariable,
          fixEnvRef = ref SE.initialFixEnv,
          topTypeContextRef = ref InitialTypeContext.initialTopTypeContext,
	  moduleEnvRef = ref InitialModuleContext.initialModuleContext
        } : context
      end

  (* ToDo :
   * StaticEnv.exnConIdSequenceRef is pickled, because it contains
   * global information to generate global unique exception tag.
   * But this seems ad-hoc.
   * 
   *)
  local
    val pickleEnvs =
        P.tuple4
            (
              EnvPickler.SEnv(TypesPickler.fixity),
              TypeContextPickler.topTypeContext,
              ModuleCompilationPickler.moduleEnv,
              NamePickler.sequence
            )
  in
  fun pickle (context : context) outstream =
      let
        val _ = #start pickleEnvsCounter ()
      in
        P.pickle
            pickleEnvs
            (
              !(#fixEnvRef context),
              !(#topTypeContextRef context),
              !(#moduleEnvRef context),
              !(SE.exnConIdSequenceRef)
            )
            outstream;
        #stop pickleEnvsCounter ()
      end
  fun unpickle 
      {
        session : SessionTypes.Session,
        standardOutput : ChannelTypes.OutputChannel,
        standardError : ChannelTypes.OutputChannel,
        loadPathList,
        getVariable
      }
      instream =
      let
        val _ = StaticEnv.init()
        val _ = Vars.initVars()
        val _ = Types.init()

        val _ = #start unpickleEnvsCounter ()
        val (
              fixEnv,
              topTypeContext,
              moduleEnv,
              exnConIdSequence
            ) =
            P.unpickle pickleEnvs instream
        val _ = #stop unpickleEnvsCounter ()

        val _ = SE.exnConIdSequenceRef := exnConIdSequence
      in
        {
          session = session,
          standardOutput = standardOutput,
          standardError = standardError,
          loadPathList = loadPathList,
          getVariable = getVariable,
          fixEnvRef = ref fixEnv,
          topTypeContextRef = ref topTypeContext,
	  moduleEnvRef = ref moduleEnv
        } : context
      end
  end (* local *)

  fun run
      ({
         session : SessionTypes.Session,
         standardOutput : ChannelTypes.OutputChannel,
         standardError : ChannelTypes.OutputChannel,
         loadPathList,
         getVariable,
         fixEnvRef,
         topTypeContextRef,
	 moduleEnvRef
       } : context)
      ({
         interactionMode,
         initialSource,
         initialSourceName,
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

        val promptMode = ref true
        val doFirstLinePrompt = ref true
        val firstLinePrompt = ref "->"
        val secondLinePrompt = ref ">>"

        local
          fun printPrompt promptMode =
              if promptMode then 
                if !doFirstLinePrompt
                then
                  (
                    doFirstLinePrompt := false;
                    print (!firstLinePrompt);
                    #flush standardOutput ()
                  )
                else
                  (print (!secondLinePrompt); #flush standardOutput ())
              else ()
        in

        fun getLine (source : parseSource) n = 
            (
              printPrompt (#promptMode source); 
              let
                val line =
                    (#getLine (CharacterStreamWrapper.wrapIn (#stream source)))
                        ()
              in
                if #printInput source
                then (print line; #flush standardOutput ())
                else ();

                (* parseTimeCounter is stopped after Parser.parse returns. *)
                #start parseTimeCounter ();

                line
              end
            )
        end

        fun compile (fixEnv, topTypeContext, moduleEnv, decs) =
            let
              val _ =
                  if !C.printSource andalso !C.switchTrace then
                    (
                      printError "Source expr:\n";
                      app
                          (fn dec =>
                              (
                                printError (AbsynFormatter.topdecToString dec);
                                printError "\n"
                              ))
                          decs
                    )
                  else ()

              (* elaborateion *)
              val _ = #start elaborationTimeCounter ()
              val (pldecs, newFixEnv, warnings) =
                  Elaborator.elaborate fixEnv decs
              val _ = #stop elaborationTimeCounter ()

              val _ = printWarnings warnings
              val _ =
                  if !C.printPL andalso !C.switchTrace
                  then
                    (
                      printError "\nElaborated to:\n";
                      app
                      (fn dec =>
                          printError
                          ((PatternCalcFormatter.pltopdecToString dec) ^ "\n"))
                      pldecs
                    )
                  else ()
                       
             (* VAL REC optimization *)
              val _ = #start valRecOptimizationTimeCounter ()
              val pldecs = VALREC_Optimizer.optimize topTypeContext pldecs
              val _ = #stop valRecOptimizationTimeCounter ()

              val _ =
                  if !C.printPL andalso !C.switchTrace
                  then
                    (
                      printError "\nVAL REC optimize to:\n";
                      app
                      (fn dec =>
                          printError
                          ((PatternCalcFormatter.pltopdecToString dec) ^ "\n"))
                      pldecs
                    )
                  else ()

             (* Uncurrying  optimization *)
              val pldecs = 
                if !C.doUncurryOptimization then
                  pldecs
                else
                  TransFundecl.transTopDeclList pldecs

              (* process user type declaration *)
              val _ = #start setTVarsTimeCounter ()
              val ptdecs = map (SetTVars.settopdec SEnv.empty) pldecs
              val _ = #stop setTVarsTimeCounter ()

              val _ =
                  if !C.printPL andalso !C.switchTrace
                  then
                    (
                      printError "\nUser Tyvar Proceed:\n";
                      app
                      (fn dec =>
                          printError
                          ((PatternCalcWithTvarsFormatter.pttopdecToString dec)
                           ^ "\n"))
                      ptdecs
                    )
                  else ()

              (* type inference *)
              val _ = #start typeInferenceTimeCounter ()
              val (newContext, tpdecs, warnings) =
                  TypeInferencer.infer topTypeContext ptdecs
              val _ = #stop typeInferenceTimeCounter ()

              val _ = printWarnings warnings
              val _ =
                  if !C.printTP andalso !C.switchTrace
                  then
                    (
                      printError "\nStatically evaluated to:\n";
                      app
                      (fn dec =>
                          printError
                          (TypedCalcFormatter.tptopdecToString [] dec ^ "\n"))
                      tpdecs;
                      printError "\nGenerated static bindings:\n";
                      printError (TypeContext.contextToString newContext)
                    )
                  else ()


             (* Uncurrying  optimization *)
              val _ = #start UncurryOptimizationTimeCounter ()
              val tpdecs = 
                if !C.doUncurryOptimization then
                  UncurryFundecl.optimize tpdecs
                else tpdecs
              val _ = #stop UncurryOptimizationTimeCounter ()
              val _ =
                  if !C.printUC andalso !C.switchTrace
                  then
                    (
                      printError "\nUncurying Optimized to:\n";
                      app
                      (fn dec =>
                          printError
                          (TypedCalcFormatter.tptopdecToString [] dec ^ "\n"))
                      tpdecs;
                      printError "\nGenerated static bindings:\n";
                      printError (TypeContext.contextToString newContext)
                    )
                  else ()


              (* printer generation *)
              val _ = #start printerGenerationTimeCounter ()
              val (newContext, tpdecs) =
                  if !C.skipPrinter
                  then (newContext, tpdecs)
                  else
                    PrinterGenerator.generate
                    {
                      context = topTypeContext,
                      newContext = newContext,
                      printBinds = !C.printBinds,
                      declarations = tpdecs
                    }
              val _ = #stop printerGenerationTimeCounter ()

              val _ =
                  if
                    !C.printTP
                    andalso !C.switchTrace
                    andalso false = !C.skipPrinter
                  then
                    (
                      printError "\nPrinter code is generated:\n";
                      app
                      (fn dec =>
                          printError
                          (TypedCalcFormatter.tptopdecToString [] dec ^ "\n"))
                      tpdecs;
                      printError "\nGenerated static bindings:\n";
                      printError (TypeContext.contextToString newContext)
                    )
                  else ()

	      (* module compile *)
              val _ = #start moduleCompilationTimeCounter ()
              val (deltaModuleEnv, tpflatdecs) =
                  ModuleCompiler.modulecompile moduleEnv tpdecs
              val _ = #stop moduleCompilationTimeCounter ()

              val _ =
                  if !C.printTFP andalso !C.switchTrace
                  then
                    (
                      printError "\nModule Compiled to:\n";
                      app
                      (fn dec =>
                          printError(PrintTFP.tfpdecToString nil dec ^ "\n"))
                      tpflatdecs
                    )
                  else ()
              (* match compile *)

              val _ = #start matchCompilationTimeCounter ()
              val (rcdecs, warnings) = MatchCompiler.compile tpflatdecs
              val _ = #stop matchCompilationTimeCounter ()

              val _ = printWarnings warnings
              val _ =
                  if !C.printRC andalso !C.switchTrace
                  then
                    (
                      printError "\nMatch Compiled to:\n";
                      app
                      (fn dec =>
                          printError
                          (RecordCalcFormatter.rcdecToString nil dec ^ "\n"))
                      rcdecs
                    )
                  else ()
              (* record compile *)

              val _ = #start recordCompilationTimeCounter ()
              val tldecs = RecordCompiler.compile rcdecs
              val _ = #stop recordCompilationTimeCounter ()

              val _ =
                  if !C.printTL andalso !C.switchTrace
                  then
                    (
                      printError "\nRecord Compiled to:\n";
                      app
                      (fn dec =>
                          printError
                          (TypedLambdaFormatter.tldecToString [] dec ^ "\n"))
                      tldecs
                    )
                  else ()

              val optimizedTldecs = tldecs

              (* type check *)
              val _ =
                  if !C.checkType
                  then
                    let
                      val diagnoses =
                          TypeCheckTypedLambda.typechekTypedLambda
                              optimizedTldecs
                      val _ = printDiagnoses diagnoses
                    in
                      ()
                    end
                  else ()

(*
The current optimizer is obsolute.

              (* optimize *)
              val _ = #start lambdaOptimizationTimeCounter ()
              val optimizedTldecs =
                  if !C.doOptimize
                  then TypedLambdaOptimizer.optimize VEnv.empty tldecs
                  else tldecs
              val _ = #stop lambdaOptimizationTimeCounter ()

              val _ =
                  if
                    !C.doOptimize andalso
                    !C.printTL andalso
                    !C.switchTrace
                  then
                    (
                      printError "\nOptimized to:\n";
                      app
                      (fn dec =>
                          printError
                          (TypedLambdaFormatter.tldecToString [] dec ^ "\n"))
                      optimizedTldecs
                    )
                  else ()
*)

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


              (* Anormal optimization*)

              val anexp = ANormalOptimizer.optimize anexp

              val _ =
                  if !C.printAN andalso !C.switchTrace
                  then
                    (
                      printError "\nAnormal optimized to:\n";
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

              (* symbolic instructions optimization *)
              val symbolicCode as {functions, ...} =
                  {
                    mainFunctionName = #mainFunctionName symbolicCode,
                    functions =
                    if !C.doSymbolicInstructionsOptimization
                    then
                      map
                          SymbolicInstructionsOptimizer.optimize
                          functions
                    else functions
                  }

              val _ =
                  if !C.printLS andalso !C.switchTrace
                  then
                    (
                      printError "\nSymbolicInstructions Optimized to:\n";
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
            in
              ( (* ToDo : define a merge function in Elaborator *)
                SEnv.unionWith #1 (newFixEnv,fixEnv),
		InitialTypeContext.extendTopTypeContextWithContext
                    topTypeContext newContext,
		ModuleCompiler.extendModuleEnvWithDeltaModuleEnv
                    {deltaModuleEnv = deltaModuleEnv,
                     moduleEnv = moduleEnv},
                codeBlock
              )
            end

        (****************************************)

        val onParseError = printError o Parser.errorToString

        val initialSource =
              {
                interactionMode = interactionMode,
                getBaseDirectory = getBaseDirectory,
                fileName = initialSourceName,
                stream = initialSource,
                promptMode =
                case interactionMode of Interactive => true | _ => false,
                printInput = false
              } : parseSource

        val initialParseContext = 
            (Parser.createContext
                 {
                   sourceName = initialSourceName,
                   onError = onParseError,
                   getLine = getLine initialSource
                 })

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
                        sourceName = fileName,
                        onError = onParseError,
                        getLine = getLine newSource
                      }
            in
              (newSource, newParseContext)
            end

        fun flush parseContext = 
(*
            if (#fileName (!currentSource)) = "stdIn"
            then
              case TextIO.canInput(TextIO.stdIn, 4096) of
                NONE =>
                currentLexer:=
                CoreMLParser.makeLexer (getLine (!currentSource)) (!currentSource)
              | (SOME 0) =>
                currentLexer:=
                CoreMLParser.makeLexer (getLine (!currentSource)) (!currentSource)
              | (SOME _) =>
                (ignore (TextIO.input TextIO.stdIn); flush())
            else
*)
           Parser.resumeContext parseContext

        fun errorHandler (currentSource : parseSource) parseContext exn =
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
            (case parseResult of
               Absyn.USE (fileName, loc) => 
               (let
                  val (innerSource, innerParseContext) =
                      useInput source (fileName, loc)
                in
                  ((if processSource (innerSource, innerParseContext)
                    then true
                    else not(isStopOnError source))
                   handle exn =>
                          (#close (#stream innerSource) (); raise exn))
                  before (#close (#stream innerSource) ())
                end)
             | Absyn.TOPDECS (topdecs,loc) =>
               let
                 val _= #start compilationTimeCounter ();
                 val
                 (
                   newFixEnv,
                   newTopContext,
                   newModuleEnv,
                   codeBlock
                 ) =
                 compile
                     (
                       !fixEnvRef,
                       !topTypeContextRef,
		       !moduleEnvRef,
                       topdecs
                     )
                 val _= #stop compilationTimeCounter ();

                 val _ = #start executeTimeCounter ()
                 val _ = #execute session codeBlock
                 val _ = #stop executeTimeCounter ()

                 (* update contexts *)
                 (* ToDo : change to parameter passing style *)
                 val _ = fixEnvRef := newFixEnv
                 val _ = topTypeContextRef := newTopContext
		 val _ = moduleEnvRef := newModuleEnv

               in
                 true (* SUCCESS *)
               end)

        and processCompileUnit source parseContext =
            (
              doFirstLinePrompt := true;
              let
                (* An exception that is raised if any error occurs in
                 * the CURRENT source.
                 * Errors which occur in other sources "use"d by this
                 * source are handled in the process of that source and
                 * are not propagated to here.
                 *)
                exception CompileError of exn * Parser.context option

              in
                let
                  val newParseContextOpt =
                      SOME(Parser.parse parseContext)
                      handle Parser.EndOfParse => NONE
                           | exn =>
                             (
                               #stop parseTimeCounter ();
                               raise CompileError(exn, NONE)
                             )
                  (* parseTimeCounter is started in the getLine function *)
                  val _ = #stop parseTimeCounter ()
                in
                  case newParseContextOpt of
                    NONE => Finish (* End Of Source *)
                  | SOME(parseResult, newParseContext) =>
                    (if processParseResult (source, parseResult)
                     then Continue newParseContext
                     else StopByError)
                    handle exn =>
                           raise CompileError (exn, SOME newParseContext)
                end
                  handle CompileError (exn, newParseContextOpt) =>
                         let
                           val newParseContext =
                               case newParseContextOpt of
                                 NONE =>
                                 (* error raised in parse. *) parseContext
                               | SOME context =>
                                 (* error raised after parse. *) context
                         in
                           errorHandler source newParseContext exn;
                           if isStopOnError source
                           then StopByError
                           else Continue(flush newParseContext)
                         end
              end
            )

        (**
         * parse, compile and execute a source.
         * @return true if the process succeeds. false otherwise.
         *)
        and processSource (source, parseContext) =
            let
              fun loop parseContext =
                  let
                    val doCount =
                        Interactive = #interactionMode source
                        andalso !C.doProfile
                    val _ =
                        if doCount
                        then #reset Counter.root ()
                        else ()

                    val result = processCompileUnit source parseContext
                  in
                    if doCount
                    then (print "\n"; print (Counter.dump ()))
                    else ();

                    case result of
                      Finish => true
                    | StopByError => false
                    | Continue(newParseContext) =>
                      (* loop again, because the process of the source has
                       * not finished nor aborted. *)
                      loop newParseContext
                  end
            in
              (* begin a loop of processing compile units. *)
              loop parseContext
            end
      in
        processSource (initialSource, initialParseContext)
      end

  (***************************************************************************)

end
