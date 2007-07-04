(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author YAMATODANI Kiyoshi
 * @version $Id: Top.sml,v 1.173 2007/06/19 22:19:12 ohori Exp $
 *)
structure Top :> TOP =
struct

  (***************************************************************************)

  structure C = Control
  structure CT = Counter
  structure UE = UserError
  structure PU = PathUtility
  structure P = Pickle
  structure LU = LinkerUtils
  structure SU = SignalUtility
  structure T = Types

  (***************************************************************************)

  (* maybe "NonInteractive" will be changed to other name. *)
  datatype interactionMode =
           Interactive
         | NonInteractive of {stopOnError : bool}
         | Prelude

  type context =
       {
         fixEnvRef : Fixity.fixity SEnv.map ref,
	 moduleEnvRef : StaticModuleEnv.moduleEnv ref,
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
  val CT.ElapsedTimeCounter typedLambdaNormalizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "typed lambda normalization"
  val CT.ElapsedTimeCounter staticAnalysisTimeCounter =
      #addElapsedTime ElapsedCounterSet "static annalysis"
  val CT.ElapsedTimeCounter recordUnboxingTimeCounter =
      #addElapsedTime ElapsedCounterSet "record unboxing"
  val CT.ElapsedTimeCounter mvOptimizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "multiple value optimization"
  val CT.ElapsedTimeCounter clusteringTimeCounter =
      #addElapsedTime ElapsedCounterSet "clustering"
  val CT.ElapsedTimeCounter rbuTransformationTimeCounter =
      #addElapsedTime ElapsedCounterSet "rbuTransformation"
  val CT.ElapsedTimeCounter anormalizationTimeCounter =
      #addElapsedTime ElapsedCounterSet "anormalization"
  val CT.ElapsedTimeCounter iltransformationTimeCounter =
      #addElapsedTime ElapsedCounterSet "iltransformation"
  val CT.ElapsedTimeCounter sigenerationTimeCounter =
      #addElapsedTime ElapsedCounterSet "sigeneration"
  
  val CT.ElapsedTimeCounter stackReallocationTimeCounter =
      #addElapsedTime ElapsedCounterSet "stack reallocation"

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
        val _ = Vars.initVars()
        val _ = Types.init()
        val _ = #reset TopCounterSet ()
      in
        {
          session = session,
          standardOutput = standardOutput,
          standardError = standardError,
          loadPathList = loadPathList,
          getVariable = getVariable,
          fixEnvRef = ref Fixity.initialFixEnv,
          topTypeContextRef = ref InitialTypeContext.initialTopTypeContext,
	  moduleEnvRef = ref InitialModuleContext.initialModuleContext
        } : context
      end

  local
    val pickleEnvs =
        P.tuple4
            (
              EnvPickler.SEnv(TypesPickler.fixity),
              TypeContextPickler.topTypeContext,
              ModuleCompilationPickler.moduleEnv,
              TypesPickler.moduleState
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
              T.getModuleState ()
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
        val _ = Vars.initVars()
        val _ = Types.init()

        val _ = #start unpickleEnvsCounter ()
        val (
              fixEnv,
              topTypeContext,
              moduleEnv,
              typesState
            ) =
            P.unpickle pickleEnvs instream
        val _ = #stop unpickleEnvsCounter ()

        val _ = T.restoreModuleState typesState
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


  fun printError (context : context) message = 
      #print (CharacterStreamWrapper.wrapOut (#standardError context)) message

  fun printWarnings (context : context) warnings =
      if ! C.printWarning
      then
        (
          #flush (#standardOutput context) ();
          app
              (fn warning => 
                  (
                    printError
                        context
                        (C.prettyPrint(UE.format_errorInfo warning));
                    printError context "\n"
                  ))
              warnings
        )
      else ()

  fun printIntermediateCodes (context : context) name printer codes =
      (
        printError context (name ^ ":\n");
        app
            (fn code =>
                (
                  printError context (printer code);
                  printError context "\n"
                ))
            codes;
        #flush (#standardError context) ()
      )

  (****************************************)

  fun doSource context decs =
      let
        val _ =
            if !C.printSource andalso !C.switchTrace
            then
              printIntermediateCodes
                  context "Source expr" AbsynFormatter.topdecToString decs
            else ()
      in
        (decs, fn _ => ())
      end

  (* elaborateion *)
  fun doElaboration (context as {fixEnvRef, ...} : context) decs =
      let
        val _ = #start elaborationTimeCounter ()
        val (pldecs, newFixEnv, warnings) =
            Elaborator.elaborate (!fixEnvRef) decs
        val _ = #stop elaborationTimeCounter ()

        fun onFinish _ = fixEnvRef := SEnv.unionWith #1 (newFixEnv, !fixEnvRef)

        val _ = printWarnings context warnings
        val _ =
            if !C.printPL andalso !C.switchTrace
            then
              printIntermediateCodes
                  context
                  "Elaborated"
                  PatternCalcFormatter.pltopdecToString
                  pldecs
            else ()
      in
        (pldecs, onFinish)
      end

  fun doVALRECOptimization
          (context as {topTypeContextRef, ...} : context) pldecs =
      let
        (* VAL REC optimization *)
        val _ = #start valRecOptimizationTimeCounter ()
        val pldecs = VALREC_Optimizer.optimize (!topTypeContextRef) pldecs
        val _ = #stop valRecOptimizationTimeCounter ()
                            
        val _ =
            if !C.printPL andalso !C.switchTrace
            then
              printIntermediateCodes
                  context
                  "VAL REC optimize"
                  PatternCalcFormatter.pltopdecToString
                  pldecs
            else ()
      in
        (pldecs, fn _ => ())
      end

  fun doFundeclElaboration context pldecs =
      let
        (* Uncurrying  optimization *)
        val pldecs = 
            if !C.doUncurryOptimization
            then pldecs
            else TransFundecl.transTopDeclList pldecs
      in
        (pldecs, fn _ => ())
      end

  fun doSetTvars context pldecs =
      let
        (* process user type declaration *)
        val _ = #start setTVarsTimeCounter ()
        val ptdecs = map (SetTVars.settopdec SEnv.empty) pldecs
        val _ = #stop setTVarsTimeCounter ()
                
        val _ =
            if !C.printPL andalso !C.switchTrace
            then
              printIntermediateCodes
                  context
                  "User Tyvar Processed"
                  PatternCalcWithTvarsFormatter.pttopdecToString
                  ptdecs
            else ()
      in
        (ptdecs, fn _ => ())
      end

  fun doTypeInference (context as {topTypeContextRef, ...} : context) ptdecs =
      let
        (* type inference *)
        val _ = #start typeInferenceTimeCounter ()
        val (newContext, tpdecs, warnings) =
            TypeInferencer.infer (!topTypeContextRef) ptdecs
        val _ = #stop typeInferenceTimeCounter ()
                            
        fun onFinish _ =
            let
              val newTopTypeContext = 
                  InitialTypeContext.extendTopTypeContextWithContext
                      (!topTypeContextRef) newContext
            in
              topTypeContextRef := newTopTypeContext
            end

        val _ = printWarnings context warnings
        val _ =
            if !C.printTP andalso !C.switchTrace
            then
              (
                printIntermediateCodes
                    context
                    "Statically evaluated"
                    (TypedCalcFormatter.tptopdecToString [])
                    tpdecs;
                printError context "\nGenerated static bindings:\n";
                printError context (TypeContext.contextToString newContext)
              )
            else ()
      in
        ((tpdecs, newContext), onFinish)
      end
(*
  fun doTypeInferenceLinkageUnit (context : context) ptdecs =
      let
        (* type inference *)
        val (typeEnv, tpdecs, warnings) =
            TypeInferencer.inferLinkageUnit ptdecs

        val _ = printWarnings context warnings
        val _ =
            if !C.printTP andalso !C.switchTrace
            then
              (
                printError context "\nStatically evaluated to:\n";
                app
                    (fn dec =>
                        printError
                            context
                            (TypedCalcFormatter.tptopdecToString [] dec
                             ^ "\n"))
                    tpdecs;
                    printError context "\nGenerated static bindings:\n";
                    printError
                        context
                        (Control.prettyPrint
                             (TypeContext.format_staticTypeEnv nil typeEnv))
               )
            else ()
      in
        (tpdecs, onFinish)
      end
*)
  fun doUncurryOptimization context (tpdecs, newContext) =
      let
        (* Uncurrying  optimization *)
        val _ = #start UncurryOptimizationTimeCounter ()
        val tpdecs = 
            if !C.doUncurryOptimization
            then UncurryFundecl.optimize tpdecs
            else tpdecs
        val _ = #stop UncurryOptimizationTimeCounter ()
        val _ =
            if !C.printUC andalso !C.switchTrace
            then
              printIntermediateCodes
                  context
                  "Uncurying Optimized"
                  (TypedCalcFormatter.tptopdecToString [])
                  tpdecs
            else ()
      in
        ((tpdecs, newContext), fn _ => ())
      end
        
  fun doPrinterGeneration
          (context as {topTypeContextRef, ...} : context)
          (tpdecs, newContext) =
      let
        (* printer generation *)
        val _ = #start printerGenerationTimeCounter ()
        val (newContext, tpdecs) =
            if !C.skipPrinter
            then (newContext, tpdecs)
            else
              PrinterGenerator.generate
                  {
                    context = (!topTypeContextRef),
                    newContext = newContext,
                    printBinds = !C.printBinds,
                    declarations = tpdecs
                  }
        val _ = #stop printerGenerationTimeCounter ()

        fun onFinish _ = ()
(*
            let
              val newTopTypeContext = 
                  InitialTypeContext.extendTopTypeContextWithContext
                      (!topTypeContextRef) newContext
            in
              topTypeContextRef := newTopTypeContext
            end
*)

        val _ =
            if
              !C.printTP
              andalso !C.switchTrace
              andalso false = !C.skipPrinter
            then
              (
                printIntermediateCodes
                    context
                    "Printer code generated"
                    (TypedCalcFormatter.tptopdecToString [])
                    tpdecs;
                printError context "\nGenerated static bindings:\n";
                printError context (TypeContext.contextToString newContext)
              )
            else ()
      in
        (tpdecs, onFinish)
      end

  fun doModuleCompilation (context as {moduleEnvRef, ...} : context) tpdecs =
      let
	(* module compile *)
        val _ = #start moduleCompilationTimeCounter ()
        val (deltaModuleEnv, tpflatdecs) =
            ModuleCompiler.moduleCompile (!moduleEnvRef) tpdecs
        val _ = #stop moduleCompilationTimeCounter ()

        fun onFinish _ =
            let
              val newModuleEnv = 
		  StaticModuleEnv.extendModuleEnvWithDeltaModuleEnv
                      {
                        deltaModuleEnv = deltaModuleEnv,
                        moduleEnv = !moduleEnvRef
                      }
            in
              moduleEnvRef := newModuleEnv
            end

        val _ =
            if !C.printTFP andalso !C.switchTrace
            then
              printIntermediateCodes
                  context
                  "Module Compiled"
                  (PrintTFP.tfpdecToString [])
                  tpflatdecs
            else ()
      in
        (tpflatdecs, onFinish)
      end

  fun doMatchCompilation context tpflatdecs =
      let
        (* match compile *)
        val _ = #start matchCompilationTimeCounter ()
        val (rcdecs, warnings) = MatchCompiler.compile tpflatdecs
        val _ = #stop matchCompilationTimeCounter ()

        val _ = printWarnings context warnings
        val _ =
            if !C.printRC andalso !C.switchTrace
            then
              printIntermediateCodes
                  context
                  "Match Compiled"
                  (RecordCalcFormatter.rcdecToString [])
                  rcdecs
            else ()
      in
        (rcdecs, fn _ => ())
      end

  fun doTypedLambdaNormalization context rcdecs =
      let
        (* record compile *)
        val _ = #start typedLambdaNormalizationTimeCounter ()
        val tldecs = TLNormalization.normalize rcdecs
        val _ = #stop typedLambdaNormalizationTimeCounter ()

        val _ =
            if !C.printTL andalso !C.switchTrace
            then
              printIntermediateCodes
                  context
                  "TypedLambda normalization"
                  (TypedLambdaFormatter.tldecToString [])
                  tldecs
            else ()
      in
        (tldecs, fn _ => ())
      end

  fun doTypeCheck context tldecs =
      let
        (* type check *)
        val _ =
            if !C.checkType
            then
              let
                val diagnoses =
                    TypeCheckTypedLambda.typecheck tldecs
                val _ = 
                  if ! C.printDiagnosis then
                    case diagnoses of
                      nil => ()
                    | _ =>
                        printIntermediateCodes
                        context
                        "Diagnoses"
                        (C.prettyPrint o UE.format_errorInfo)
                        diagnoses
                  else ()
              in
                ()
              end
            else ()
      in
        (tldecs, fn _ => ())
      end

  fun doStaticAnalysis context tldecs =
      let
        (* static analysis *)
        val _ = #start staticAnalysisTimeCounter ()
        val acdecs = StaticAnalysis.analyse tldecs
        val _ = #stop staticAnalysisTimeCounter ()

        val _ =
            if !C.printAC andalso !C.switchTrace
            then
              printIntermediateCodes
                  context
                  "Static analysis"
                  (AnnotatedCalcFormatter.acdeclToString)
                  acdecs
            else ()
      in
        (acdecs, fn _ => ())
      end

  fun doRecordUnboxing context acdecs =
      let
        (* record unboxing *)
        val _ = #start recordUnboxingTimeCounter ()
        val mvdecs = RecordUnboxing.transform acdecs
        val _ = #stop recordUnboxingTimeCounter ()

        val _ =
            if !C.printMV andalso !C.switchTrace
            then
              printIntermediateCodes
                  context
                  "Record unboxing"
                  (MultipleValueCalcFormatter.mvdeclToString)
                  mvdecs
            else ()
      in
        (mvdecs, fn _ => ())
      end

  fun doMultipleValueOptimization context mvdecs =
      if !C.doMultipleValueOptimization
      then
        let
          val _ = #start mvOptimizationTimeCounter ()
          val mvdecs = MVOptimization.optimize mvdecs
          val _ = #stop mvOptimizationTimeCounter ()

          val _ =
              if !C.printMV andalso !C.switchTrace
              then
                printIntermediateCodes
                    context
                    "Multiple value optimization"
                    (MultipleValueCalcFormatter.mvdeclToString)
                    mvdecs
              else ()
        in
          (mvdecs, fn _ => ())
        end
      else (mvdecs, fn _ => ())

  fun doMVTypeCheck context mvdecs =
      let
        (* type check *)
        val _ =
            if !C.checkType
            then
              let
                val diagnoses =
                    MVTypeCheck.typecheck mvdecs
                val _ = 
                  if ! C.printDiagnosis then
                    case diagnoses of
                      nil => ()
                    | _ =>
                        printIntermediateCodes
                        context
                        "Diagnoses"
                        (C.prettyPrint o UE.format_errorInfo)
                        diagnoses
                  else ()
              in
                ()
              end
            else ()
      in
        (mvdecs, fn _ => ())
      end


  fun doClustering context mvdecs =
      let
        val _ = #start clusteringTimeCounter ()
        val ccdecs = Clustering.transform mvdecs
        val _ = #stop clusteringTimeCounter ()
                
        val _ =
            if !C.printCC andalso !C.switchTrace
            then
              printIntermediateCodes
                  context
                  "Clustering"
                  (ClusterCalcFormatter.ccdeclToString)
                  ccdecs
            else ()
      in
        (ccdecs, fn _ => ())
      end

  fun doRBUTransformation context ccdecs =
      let
        val _ = #start rbuTransformationTimeCounter ()
        val rbudecs = RBUTransformation.transform ccdecs
        val _ = #stop rbuTransformationTimeCounter ()
                
        val _ =
            if !C.printRBU andalso !C.switchTrace
            then
              printIntermediateCodes
                  context
                  "RBU transformation"
                  (RBUCalcFormatter.rbudeclToString)
                  rbudecs
            else ()
      in
        (rbudecs, fn _ => ())
      end

  fun doANormalization context rbudecs =
      let
        val _ = #start anormalizationTimeCounter ()
        val andecs = ANormalization.normalize rbudecs
        val _ = #stop anormalizationTimeCounter ()
                
        val _ =
            if !C.printAN andalso !C.switchTrace
            then
              printIntermediateCodes
                  context
                  "ANormalization"
                  (ANormalFormatter.andeclToString)
                  andecs
            else ()
      in
        (andecs, fn _ => ())
      end


  fun doILTransformation context andecls =
      let
        val _ = #start iltransformationTimeCounter ()
        val ilcode = ILTransformation.transform andecls
        val _ = #stop iltransformationTimeCounter ()
                
        val _ =
            if !C.printIL andalso !C.switchTrace
            then
              printIntermediateCodes
                  context
                  "ILTransformation"
                  ILFormatter.moduleCodeToString
                  [ilcode]
            else ()
      in
        (ilcode, fn _ => ())
      end

  fun doSIGeneration context ilcode =
      let
        (* SIGeneration *)
        val _ = #start sigenerationTimeCounter ()
        val symbolicCode = SIGenerator.generate ilcode
        val _ = #stop sigenerationTimeCounter ()

        val _ =
            if !C.printLS andalso !C.switchTrace
            then
              printIntermediateCodes
                  context
                  "SIGeneration"
                  SymbolicInstructionsFormatter.clusterCodeToString
                  symbolicCode
            else ()
      in
        (symbolicCode, fn _ => ())
      end

  fun doStackReallocation context symbolicCode = 
      let
	  (* stack reallocation *)
	  val _ = #start stackReallocationTimeCounter ()
	  val newSymbolicCode = 
	      if !C.doStackReallocation 
	      then map 
		       Reallocater.clusterGraphColoring  symbolicCode
	      else symbolicCode
	  val _ = 
	      if !C.printSR andalso !C.switchTrace
	      then 
		       printIntermediateCodes
		       context
		       "StackReallocation"
		       SymbolicInstructionsFormatter.clusterCodeToString (*clusterCodeToString*) (*livesProgToString*) (*cfgToString*) 
		       (*map Reallocater.printLivenessClusters newSymbolicCode*) 
		       (*map Reallocater.printCFGClusters newSymbolicCode*) 
		       (newSymbolicCode)
	      else
		  ()
	  val _ = #stop stackReallocationTimeCounter ()
		  
      in (newSymbolicCode, fn _ => ())
      end 


  fun doAssemble context symbolicCode =
      let
        (* assemble *)
        val _ = #start assembleTimeCounter ()
        val executable as {instructions, locationTable, ...} =
            Assembler.assemble symbolicCode
        val _ = #stop assembleTimeCounter ()

        val _ =
            if !C.printIS andalso !C.switchTrace
            then
              (
                printIntermediateCodes
                    context
                    "Assembled"
                    Instructions.toString
                    instructions;
                printError
                    context (Executable.locationTableToString locationTable)
              )
            else ()
      in
        (executable, fn _ => ())
      end

  fun doSerialize context executable =
      let
        (* serialize *)
        val _ = #start serializeTimeCounter ()
        val codeBlock = ExecutableSerializer.serialize executable
        val _ = #stop serializeTimeCounter ()
      in
        (codeBlock, fn _ => ())
      end
(*
  fun doMakeObj initialSourceName (context : context) tldecs =
      (* pickling *)
      let
        val objName = 
            let
              val _ = 
                  if OS.Path.ext initialSourceName = SOME "sml"
                  then ()
                  else 
                    raise
                      Control.Bug
                          ("illegal file name ending without .sml:"
                           ^ initialSourceName)
              val objNameWithoutSuffix = OS.Path.base initialSourceName
            in
              objNameWithoutSuffix ^ ".smo"
            end
        val linkageUnit =
            {
              fileName = objName,
              staticTypeEnv = typeEnv,
              staticModuleEnv = (!#moduleEnvRef context),
              tyInstValIndexList = nil,
              code = tldecs
            }
        val outfile = BinIO.openOut objName
        val outstream =
            Pickle.makeOutstream
                (fn byte => BinIO.output1 (outfile, byte)) 
      in
        print "[begin pickle ................";
        P.pickle LinkageUnitPickler.linkageUnit linkageUnit outstream;
        print "done]\n";
        BinIO.closeOut outfile;
        ((), fn _ => ())
      end
*)

  fun doRestoreObject
          (context as {topTypeContextRef, moduleEnvRef, ...} : context)
          object =
      let
        val (newContext, deltaModuleEnv, tldecs) =
            Linker.useObj
                (
                  {
                    topTypeContext = !topTypeContextRef,
                    moduleEnv = !moduleEnvRef
                  },
                  object
                )
        val _ =
            if !C.printTL andalso !C.switchTrace
            then
              printIntermediateCodes
                  context
                  "Restored Object Code"
                  (TypedLambdaFormatter.tldecToString [])
                  tldecs
            else ()

        fun onFinish _ =
            let
              val newTopTypeContext = 
                  InitialTypeContext.extendTopTypeContextWithContext
                      (!topTypeContextRef) newContext
              val newModuleEnv = 
		  StaticModuleEnv.extendModuleEnvWithDeltaModuleEnv
                      {
                        deltaModuleEnv = deltaModuleEnv,
                        moduleEnv = !moduleEnvRef
                      }
            in
              topTypeContextRef := newTopTypeContext;
              moduleEnvRef := newModuleEnv
            end

      in
        (tldecs, onFinish)
      end

  (********************)

  infix ==>
  fun (prev ==> (phase, next)) context code =
      let
        val (code1, onFinish1) = prev context code
        val (code2, onFinish2) = 
          if C.doPhase phase then
            case code1 of
              NONE => (NONE, fn _ => ())
            | SOME code1 => 
              let
                val (code2, onFinish2) = next context code1
              in
                (SOME code2, onFinish2)
              end
          else
            (NONE, fn _ => ())
      in
        (code2, fn _ => (onFinish1 (); onFinish2 ()))
      end
(*
  infix ==>
  fun (prev ==> next) context code =
      let
        val (code1, onFinish1) = prev context code
        val (code2, onFinish2) = next context code1
      in
        (code2, fn _ => (onFinish1 (); onFinish2 ()))
      end
  fun makeObj context initialSourceName decs =
      let
        val phases =
            (fn context => fn (SOME code) => 
            let
              val (code, onFinish) = doSource context code
            in
              (SOME code, onFinish)
            end)
                ==> doElaboration
                ==> doVALRECOptimization
                ==> doFundeclElaboration
                ==> doSetTvars
                ==> doTypeInference
                ==> doUncurryOptimization
                ==> doPrinterGeneration
                ==> doModuleCompilation
                ==> doMatchCompilation
                ==> doRecordCompilation
                ==> doTypeCheck
                ==> doMakeObj initialSourceName
      in
        phases context (SOME decs)
      end
*)
  fun compile context decs =
      let
        val phases =
            (fn context => fn (SOME code) => 
            let
              val (code, onFinish) = doSource context code
            in
              (SOME code, onFinish)
            end)
                ==> (C.Elab, doElaboration)
                ==> (C.FunOpt, doVALRECOptimization)
                ==> (C.FunOpt, doFundeclElaboration)
                ==> (C.TVar, doSetTvars)
                ==> (C.TyInf,doTypeInference)
                ==> (C.LayoutOpt, doUncurryOptimization)
                ==> (C.Print, doPrinterGeneration)
                ==> (C.Module, doModuleCompilation)
                ==> (C.MatchComp, doMatchCompilation)
                ==> (C.Lambda, doTypedLambdaNormalization)
                ==> (C.Lambda, doTypeCheck)
                ==> (C.Static, doStaticAnalysis)
                ==> (C.Unbox, doRecordUnboxing)
                ==> (C.DeadCode,doMultipleValueOptimization)
                ==> (C.DeadCode, doMVTypeCheck)
                ==> (C.Cluster, doClustering)
                ==> (C.RBUComp, doRBUTransformation)
                ==> (C.Anormal,doANormalization)
                ==> (C.SI, doILTransformation)
                ==> (C.SI, doSIGeneration)
		==> (C.SIOpt, doStackReallocation)
                ==> (C.Assem, doAssemble)
                ==> (C.Code, doSerialize)
      in
        phases context (SOME decs)
      end

  fun compileObject context object =
      let
        val phases =
            (fn context => fn (SOME code) => 
            let
              val (code, onFinish) = doRestoreObject context code
            in
              (SOME code, onFinish)
            end)
                ==> (C.Static, doStaticAnalysis)
                ==> (C.Unbox, doRecordUnboxing)
                ==> (C.DeadCode, doMultipleValueOptimization)
                ==> (C.DeadCode, doMVTypeCheck)
                ==> (C.Cluster, doClustering)
                ==> (C.RBUComp, doRBUTransformation)
                ==> (C.Anormal, doANormalization)
                ==> (C.SI, doILTransformation)
                ==> (C.SI, doSIGeneration)
		==> (C.SIOpt, doStackReallocation)
                ==> (C.Assem, doAssemble)
                ==> (C.Code, doSerialize)
      in
        phases context (SOME object)
      end

  (****************************************)

  fun run
      (context
       as {
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

        type parseSource =
              {
                interactionMode : interactionMode,
                getBaseDirectory : unit -> string,
                fileName : string,
                stream : ChannelTypes.InputChannel,
                promptMode : bool,
                printInput : bool,
                (** list of name of files which opened the current source
                 * directly or indirectly.
                 * The direct parent file is at the top of the list.
                 *)
                history : string list
              }

        val promptMode = ref true
        val doFirstLinePrompt = ref true
        val firstLinePrompt = ref "# "
        val secondLinePrompt = ref "> "

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

        (****************************************)

        val onParseError = printError context o Parser.errorToString

        val initialSource =
              {
                interactionMode = interactionMode,
                getBaseDirectory = getBaseDirectory,
                fileName = initialSourceName,
                stream = initialSource,
                promptMode =
                case interactionMode of Interactive => true | _ => false,
                printInput = false,
                history = [initialSourceName]
              } : parseSource

        (* In interactive mode, parser should abort as soon as the first error
         * is detected.
         *)
        val initialParseContext = 
            (Parser.createContext
                 {
                   sourceName = initialSourceName,
                   onError =
                   case interactionMode
                    of Interactive =>
                       ((fn _ => raise Parser.ParseError) o onParseError)
                     | _ => onParseError,
                   getLine = getLine initialSource,
                   isPrelude = interactionMode = Prelude
                 })

        fun useSource (currentSource : parseSource) (fileName, loc) = 
            let
              val currentBaseDirectory = #getBaseDirectory currentSource ()
              val absoluteFilePath =
                  PathResolver.resolve
                      getVariable loadPathList currentBaseDirectory fileName
                  handle exn => raise UE.UserErrors [(loc, UE.Error, exn)]
              val _ =
                  if
                    List.exists
                        (fn parent => parent = absoluteFilePath)
                        (#history currentSource)
                  then
                    raise
                      UE.UserErrors
                          [(
                             loc,
                             UE.Error,
                             Fail
                                 ("detected circular file references: "
                                  ^ absoluteFilePath)
                           )]
                  else ()
              val _ =
                  if !C.switchTrace andalso !C.traceFileLoad
                  then
                    printError context ("source: " ^ absoluteFilePath ^ "\n")
                  else ()

              val baseDirectory = #dir(PU.splitDirFile absoluteFilePath)
              val newSource =
                  {
                    interactionMode = NonInteractive {stopOnError = true},
                    fileName = fileName,
                    getBaseDirectory = fn () => baseDirectory,
                    stream = FileChannel.openIn {fileName = absoluteFilePath},
                    promptMode = false,
                    printInput = false,
                    history = absoluteFilePath :: (#history currentSource)
                  } : parseSource
              val newParseContext =
                  Parser.createContext
                      {
                        sourceName = fileName,
                        onError = onParseError,
                        getLine = getLine newSource,
                        isPrelude = interactionMode = Prelude
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
                            printError context
                                (C.prettyPrint
                                     (UE.format_errorInfo error));
                            printError context "\n"
                          ))
                      errors;
                  printError context "\n"
                )
              | exn as C.Bug message =>
                (
                  printError context ("BUG :" ^ message ^"\n");
                  app
                      (fn line => printError context (line ^ "\n"))
                      (SMLofNJ.exnHistory exn)
                )
              | exn as C.BugWithLoc (message, loc) =>
                (
                  printError context ("BUG :" ^ message ^"\n");
                  printError
                      context
                      ("  at " ^ AbsynFormatter.locToString loc ^ "\n");
                  app
                      (fn line => printError context (line ^ "\n"))
                      (SMLofNJ.exnHistory exn)
                )
              | SessionTypes.Failure cause =>
                printError context ("RuntimeError:" ^ exnMessage cause ^ "\n")
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
                  printError context (message ^ "\n")
                end
              | OS.SysErr(message, _) => printError context (message ^ "\n")
              | _ => raise exn;
              #flush standardError ()
            ) 

        fun useObject (currentSource : parseSource) (fileName, loc) = 
            let
              val _ =
                  if OS.Path.ext fileName = SOME "smo"  
                  then ()
                  else
                    raise
                      Control.BugWithLoc
                          ("object file should ends with .smo", loc)
              val currentBaseDirectory = #getBaseDirectory currentSource ()
              val absoluteFilePath =
                  PathResolver.resolve
                      getVariable loadPathList currentBaseDirectory fileName
                  handle exn => raise UE.UserErrors [(loc, UE.Error, exn)]
              val linkageUnit =
                  let
                      val infile = BinIO.openIn absoluteFilePath
                      val instream =
                          Pickle.makeInstream
                              (fn _ => valOf(BinIO.input1 infile))
                      val _ =
                          if !C.switchTrace andalso !C.traceFileLoad
                          then
                            printError
                                context
                                ("\n[begin unpickle "
                                 ^ absoluteFilePath
                                 ^ ".......")
                          else ()
                      val _ = ID.init ()
                      val linkageUnit : LinkageUnit.linkageUnit = 
                          P.unpickle LinkageUnitPickler.linkageUnit instream
                      val _ = printError context "done]\n"
                      val _ = BinIO.closeIn infile
                  in
                      linkageUnit
                  end
(*              val _ = print "\n ********* unpickle *************** \n"
                val _ = print (Control.prettyPrint (LinkageUnit.format_linkageUnit nil linkageUnit))
                val _ = print "\n ********************************** \n"*)
            in
                linkageUnit
            end handle exn => (errorHandler exn;LinkageUnit.emptyLinkageUnit)

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
            | Prelude => true

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
                      useSource source (fileName, loc)
                in
                  ((if processSource (innerSource, innerParseContext)
                    then true
                    else not(isStopOnError source))
                   handle exn =>
                          (#close (#stream innerSource) (); raise exn))
                  before (#close (#stream innerSource) ())
                end)
             | Absyn.USEOBJ (fileName, loc) => 
               let
                 val _= #start compilationTimeCounter ()
                 val object = useObject source (fileName, loc)
                 val (codeBlock, onFinish) = 
                     compileObject context object
                 val _= #stop compilationTimeCounter ()
                 val _ =
                   if C.doPhase C.Run then
                     case codeBlock of
                       SOME codeBlock =>
                         (#start executeTimeCounter ();
                          #execute session codeBlock;
                          #stop executeTimeCounter ();
                          ())
                       | _ => ()
                   else ()
                 (* update contexts *)
                 val _ = onFinish ()
               in
                 true
               end 
             | Absyn.TOPDECS (topdecs,loc) =>
               let
                 val _= #start compilationTimeCounter ()
                 val (codeBlock, onFinish) = compile context topdecs
                 val _= #stop compilationTimeCounter ()
                 val _ =
                   if C.doPhase C.Run then
                     case codeBlock of
                       SOME codeBlock =>
                         (#start executeTimeCounter ();
                          #execute session codeBlock;
                          #stop executeTimeCounter ();
                          ())
                       | _ => ()
                   else ()
                 (* update contexts *)
                 val _ = onFinish ()
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

                (** raised if user send Ctrl-C before finishing input. *)
                exception Interrupted 

              in
                let
                  val newParseContextOpt =
                      (case
                         SU.doWithInterruption
                             [SU.SIGINT] Parser.parse parseContext
                        of SU.Interrupted _ => raise Interrupted
                         | SU.Completed newParseContext =>
                           SOME newParseContext)
                      handle Parser.EndOfParse => NONE
                           | Interrupted => raise Interrupted
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
                           errorHandler exn;
                           if isStopOnError source
                           then StopByError
                           else Continue(flush newParseContext)
                         end
                       | Interrupted =>
                         (
                           if #promptMode source then print "\n" else ();
                           Continue(flush parseContext)
                         )
                       | exn => raise exn
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
                        then #reset TopCounterSet ()
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

  fun runObject
      (context
       as {
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
        val _= #start compilationTimeCounter ()
        val _ = ID.init ()
        fun reader () =
            case #receive initialSource () of
              SOME byte => byte
            | NONE => raise Fail "unexpected EOF of library"
        val object =
            P.unpickle
                LinkageUnitPickler.linkageUnit
                (Pickle.makeInstream reader)

        val (codeBlock, onFinish) = compileObject context object
        val _= #stop compilationTimeCounter ()
        val _ =
          if C.doPhase C.Run then
            case codeBlock of
              SOME codeBlock =>
                (#start executeTimeCounter ();
                 #execute session codeBlock;
                 #stop executeTimeCounter ();
                 ())
            | _ => ()
          else ()
        (* update contexts *)
        val _ = onFinish ()
      in
        true
      end

  (***************************************************************************)

end
