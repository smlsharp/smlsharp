(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author YAMATODANI Kiyoshi
 * @version $Id: Top.sml,v 1.249 2008/11/19 20:04:38 ohori Exp $
 *)
structure Top :> TOP =
struct

(***************************************************************************)
  structure A = Absyn
  structure C = Control
  structure CT = Counter
  structure P = Pickle
  structure PU = PathUtility
  structure SU = SignalUtility
  structure UE = UserError
  structure TB = TopBasis 
(***************************************************************************)

    val xprint = print

    (* maybe "NonInteractive" will be changed to other name. *)
    datatype interactionMode =
             Interactive
           | NonInteractive of {stopOnError : bool}
           | Prelude

    type source = 
         {
          interactionMode : interactionMode,
          initialSourceChannel : ChannelTypes.InputChannel,
          initialSourceName : string,
          getBaseDirectory : unit -> string
         }

    (** source information necessary for parser.
     * This is used internal only.
     *)
    type parseSource =
         {
          interactionMode : interactionMode,
          getBaseDirectory : unit -> string,
          fileName : string,
          stream : ChannelTypes.InputChannel,
          (** list of name of files which opened the current source
           * directly or indirectly.
           * The direct parent file is at the top of the list.
           *)
          history : string list
         }

    type context = TB.context
    type stamps = TB.stamps
    type sysParam = TB.sysParam

    (***************************************************************************)

    val CT.CounterSetInternal TopCounterSet =
        #addSet CT.root ("Top", CT.ORDER_OF_ADDITION)
    val CT.CounterSetInternal ElapsedCounterSet =
        #addSet TopCounterSet ("elapsed time", CT.ORDER_OF_ADDITION)
    val parseTimeCounter =
        #addElapsedTime ElapsedCounterSet "parse"
    val compilationTimeCounter =
        #addElapsedTime ElapsedCounterSet "compilation (after parse)"
    val elaborationTimeCounter =
        #addElapsedTime ElapsedCounterSet "elaboration"
    val moduleCompilationTimeCounter =
        #addElapsedTime ElapsedCounterSet "module compilation"
    val valRecOptimizationTimeCounter =
        #addElapsedTime ElapsedCounterSet "val rec optimize"
    val setTVarsTimeCounter =
        #addElapsedTime ElapsedCounterSet "set tvars"
    val typeInferenceTimeCounter =
        #addElapsedTime ElapsedCounterSet "type inference"
    val UncurryOptimizationTimeCounter =
        #addElapsedTime ElapsedCounterSet "uncurry optimize"
    val printerGenerationTimeCounter =
        #addElapsedTime ElapsedCounterSet "printer generation"
    val UniqueIdAllocationCounter =
        #addElapsedTime ElapsedCounterSet "unique allocation"
    val matchCompilationTimeCounter =
        #addElapsedTime ElapsedCounterSet "match compilation"
    val typedLambdaNormalizationTimeCounter =
        #addElapsedTime ElapsedCounterSet "typed lambda normalization"
    val staticAnalysisTimeCounter =
        #addElapsedTime ElapsedCounterSet "static annalysis"
    val recordUnboxingTimeCounter =
        #addElapsedTime ElapsedCounterSet "record unboxing"
    val inliningTimeCounter =
        #addElapsedTime ElapsedCounterSet "inlining"
    val mvOptimizationTimeCounter =
        #addElapsedTime ElapsedCounterSet "multiple value optimization"
    val functionLocalizeTimeCounter =
        #addElapsedTime ElapsedCounterSet "function localization"
    val functorLinkerTimeCounter =
        #addElapsedTime ElapsedCounterSet "functor linker"
    val clusteringTimeCounter =
        #addElapsedTime ElapsedCounterSet "clustering"
    val rbuTransformationTimeCounter =
        #addElapsedTime ElapsedCounterSet "rbuTransformation"
    val anormalizationTimeCounter =
        #addElapsedTime ElapsedCounterSet "anormalization"
    val iltransformationTimeCounter =
        #addElapsedTime ElapsedCounterSet "iltransformation"
    val sigenerationTimeCounter =
        #addElapsedTime ElapsedCounterSet "sigeneration"
    val anormalOptimizationTimeCounter =
        #addElapsedTime ElapsedCounterSet "anormal optimization"
    val aigenerationTimeCounter =
        #addElapsedTime ElapsedCounterSet "aigeneration"
    val vmcodeselectionTimeCounter =
        #addElapsedTime ElapsedCounterSet "vmcode selection"
    val stackallocationTimeCounter =
        #addElapsedTime ElapsedCounterSet "stack allocation"
    val linearizeTimeCounter =
        #addElapsedTime ElapsedCounterSet "linarization"
    val vmcodeemissionTimeCounter =
        #addElapsedTime ElapsedCounterSet "vmcode emission"
    val vmassembleTimeCounter =
        #addElapsedTime ElapsedCounterSet "vm assemble"
    val yasigenerationTimeCounter =
        #addElapsedTime ElapsedCounterSet "yasigeneration"
    val stackReallocationTimeCounter =
        #addElapsedTime ElapsedCounterSet "stack reallocation"
    val assembleTimeCounter =
        #addElapsedTime ElapsedCounterSet "assemble"
    val serializeTimeCounter =
        #addElapsedTime ElapsedCounterSet "serialize"
    val executeTimeCounter =
        #addElapsedTime ElapsedCounterSet "execute"
    val pickleEnvsCounter =
        #addElapsedTime ElapsedCounterSet "pickle environments"
    val unpickleEnvsCounter =
        #addElapsedTime ElapsedCounterSet "unpickle environments"

    (****************************************)
    local
        val pickleEnvs =
            P.tuple12
                (
                 EnvPickler.SEnv(TypesPickler.fixity),
                 NameMapPickler.topNameMap,
                 TypeContextPickler.topTypeContext,
                 UniqueIdAllocationPickler.topExternalVarIDBasis,
                 GlobalIndexEnv.pu_globalIndexEnv,
                 P.tuple3
                     (
                      ClusterID.pu_ID,
                      EnvPickler.SEnv(P.string),
                      P.int
                     ),
                 TyConID.pu_ID,
                 ExnTagID.pu_ID,
                 BoundTypeVarID.pu_boundTypeVarID,
                 ExternalVarID.pu_ID,
	         InlinePickler.globalInlineEnv,
                 FunctorLinker.pu_functorEnv
                )
    in
    fun pickle (context : TB.context, stamps : TB.stamps) outstream =
        let
            val _ = #start pickleEnvsCounter ()
        in
            P.pickle
                pickleEnvs
                (
                 (#fixEnv context),
                 (#nameMap context),
                 (#topTypeContext context),
                 (#externalVarIDBasis context),
                 (#globalIndexEnv context),
                 (
                   #clusterIDKeyStamp stamps,
                   #globalNameAliasEnv context,
                   #compileUnitStamp stamps
                 ),
                 (#tyConIDKeyStamp stamps),
                 (#exnTagIDKeyStamp stamps),
                 (#boundTypeVarIDStamp stamps),
                 (#externalVarIDKeyStamp stamps),
	         (#inlineEnv context),
                 (*
                  * when functor is compiled into instructions, we 
                  * shall use (#functorEnv context). 
                  * Now functor is not pickled.
                  *)
                 SEnv.empty
                )
                outstream;
            #stop pickleEnvsCounter ()
        end
    
    fun unpickle instream =
        let
            val _ = #start unpickleEnvsCounter ()
            val (
                 fixEnv,
                 nameMap,
                 topTypeContext,
                 externalVarIDBasis,
                 globalIndexEnv,
                 (
                   clusterIDKeyStamp,
                   globalNameAliasEnv,
                   compileUnitStamp
                 ),
                 tyConIDKeyStamp,
                 exnTagIDKeyStamp,
                 boundTypeVarIDStamp,
                 externalVarIDKeyStamp,
	         inlineEnv,
                 functorEnv)
              =
              P.unpickle pickleEnvs instream
            val _ = #stop unpickleEnvsCounter ()
        in
            ({
             fixEnv =  fixEnv,
             topTypeContext =  topTypeContext,
	     externalVarIDBasis =  externalVarIDBasis,
             nameMap = nameMap,
             globalNameAliasEnv = globalNameAliasEnv,
             globalIndexEnv =  globalIndexEnv,
	     inlineEnv = inlineEnv,
             functorEnv  =  functorEnv
             } : TB.context,
             {
              compileUnitStamp = compileUnitStamp,
              tyConIDKeyStamp = tyConIDKeyStamp,
              exnTagIDKeyStamp = exnTagIDKeyStamp,
              boundTypeVarIDStamp = boundTypeVarIDStamp,
              clusterIDKeyStamp = clusterIDKeyStamp,
              externalVarIDKeyStamp = externalVarIDKeyStamp
             } : TB.stamps
            )
        end
    end (* local *)

    fun print (sysParam : sysParam) message = 
        (#print (#standardOutput sysParam) message;
         #flush (#standardOutput sysParam) ())


    fun printError (sysParam : sysParam) message = 
        #print (#standardError sysParam) message

    fun printWarnings (sysParam : sysParam) warnings =
        if ! C.printWarning
        then
            (
             #flush (#standardOutput sysParam) ();
             app
                 (fn warning => 
                     (
                      printError
                          sysParam
                          (C.prettyPrint(UE.format_errorInfo warning));
                      printError sysParam "\n"
                 ))
                 warnings
            )
        else ()

    fun printIntermediateCodes (sysParam : sysParam) name printer codes =
        (
         printError sysParam (name ^ ":\n");
         app
             (fn code =>
                 (
                  printError sysParam (printer code);
                  printError sysParam "\n"
             ))
             codes;
         #flush (#standardError sysParam) ()
        )

    (*********************************************************************)
    (* Each phase returns a triple: 
     * code : the output code,
     * basis : newly extended basis for next phase compilation 
     * contextUpdater : the context extending function attributed to the current phase 
     *)
    fun doSource (basis : TB.basis) decs =
      (*
       () => Absyn
       *)
        let
            val _ =
                if !C.printSource andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "Source expr" 
                        AbsynFormatter.topdecToString 
                        decs
                else ()
        in
            (decs, basis, fn x => x)
        end

(*
val currentSourceFilename = ref ""
*)

    fun doElaboration (basis : TB.basis) decs =
      (*
       Absyn => PatternCalc
       *)
        let
(*
          val exp =
              Absyn.EXPAPP
                  ([
                    Absyn.EXPFFIIMPORT
                      (Absyn.EXPGLOBALSYMBOL("prim_printerr",
                                             Absyn.ForeignCodeSymbol,
                                             Loc.noloc),
                       Absyn.TYFFI
                         (Absyn.defaultFFIAttributes, nil,
                          [Absyn.TYCONSTRUCT([],["string"],Loc.noloc)],
                          Absyn.TYCONSTRUCT([],["unit"],Loc.noloc),
                          Loc.noloc),
                       Loc.noloc),
                    Absyn.EXPCONSTANT
                      (Absyn.STRING (!currentSourceFilename^"\n", Loc.noloc),
                       Loc.noloc)
                   ],
                   Loc.noloc)
          val decs =
              Absyn.TOPDECSTR
                (Absyn.COREDEC
                   (Absyn.DECVAL
                      (nil, [(Absyn.PATWILD Loc.noloc, exp)], Loc.noloc),
                    Loc.noloc),
                   Loc.noloc)
              :: decs
*)

            val _ = #start elaborationTimeCounter ()
            val (pldecs, newFixEnv, varNameStamp, warnings) =
                Elaborator.elaborate (#fixEnv (#context basis))
                                     (#varNameStamp (#localStamps basis))
                                     decs
            val _ = #stop elaborationTimeCounter ()
            (***************************************************)                    
            val contextUpdater = 
             fn context => TB.extendContextFixEnv context newFixEnv
            val newBasis = TB.setBasisLocalStamps 
                               basis 
                               (TB.setLocalStampsVarNameStamp (#localStamps basis)
                                                              varNameStamp)
            (***************************************************)                    
            val _ = printWarnings (#sysParam basis) warnings
            val _ =
                if !C.printPL andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "Elaborated"
                        PatternCalcFormatter.pltopdecToString
                        pldecs
                else ()
        in
            (pldecs, newBasis, contextUpdater)
        end

    fun doModuleCompilation (basis : TB.basis) decs =
      (*
       PatternCalc => PatternCalcFlattened
       *)
        let
            val _ = #start moduleCompilationTimeCounter ()
            val (exportCurrentNameMap, varNameStamp, plfdecs) = 
                ModuleCompiler.compile (#nameMap (#context basis))
                                       (#varNameStamp (#localStamps basis))
                                       decs
            val _ = #stop moduleCompilationTimeCounter ()

            (*************************************************)                    
            val flattenedNamePathEnv = 
                NameMap.basicNameMapToFlattenedNamePathEnv 
                    (#tyNameMap exportCurrentNameMap, 
                     #varNameMap exportCurrentNameMap, 
                     #strNameMap exportCurrentNameMap)
            val contextUpdater = 
                (fn context => 
                    TB.extendContextNameMapWithCurrentNameMap context exportCurrentNameMap)
            val newLocalStamps = 
                TB.setLocalStampsVarNameStamp (#localStamps basis) varNameStamp
            val newLocalContext = 
                TB.setLocalContextFlattenedNamePathEnvOpt (#localContext basis) flattenedNamePathEnv
            val newBasis = 
                TB.setBasisLocalStamps (TB.setBasisLocalContext basis newLocalContext) newLocalStamps
            (*************************************************)
            val _ =
                if !C.printPL andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "Module Compilation"
                        PatternCalcFlattenedFormatter.plftopdecToString
                        plfdecs
                else ()
        in
            (plfdecs, newBasis, contextUpdater)
        end

    fun doVALRECOptimization (basis : TB.basis) plfdecs =
      (*
       PatternCalcFlattened => PatternCalcFlattened
       *)
        let
            (* VAL REC optimization *)
            val _ = #start valRecOptimizationTimeCounter ()
            val (varNameStamp, plfdecs) = 
                VALREC_Optimizer.optimize (#nameMap (#context basis))
                                          (#varNameStamp (#localStamps basis))
                                          plfdecs
            val _ = #stop valRecOptimizationTimeCounter ()

            (*******************************************************)
            val newLocalStamps = 
                TB.setLocalStampsVarNameStamp (#localStamps basis) varNameStamp
            val newBasis = 
                TB.setBasisLocalStamps basis newLocalStamps
            (*******************************************************)
                    
            val _ =
                if !C.printPL andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "VAL REC optimize"
                        PatternCalcFlattenedFormatter.plftopdecToString
                        plfdecs
                else ()
        in
            (plfdecs, newBasis, fn context => context)
        end

    fun doFundeclElaboration basis pldecs =
      (*
       PatternCalcFlattened => PatternCalcFlattened
       *)
        let
            (* Uncurrying  optimization *)
            val pldecs = 
                if !C.doUncurryOptimization
                then pldecs
                else TransFundecl.transTopDeclList pldecs
        in
            (pldecs, basis, fn context => context)
        end

    fun doSetTvars (basis : TB.basis) pldecs =
      (*
       PatternCalcFlattened => PatternCalcWithTvars
       *)
        let
            (* process user type declaration *)
            val _ = #start setTVarsTimeCounter ()
            val ptdecs = map (SetTVars.setTopDec SEnv.empty) pldecs
            val _ = #stop setTVarsTimeCounter ()
                    
            val _ =
                if !C.printPL andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "User Tyvar Processed"
                        PatternCalcWithTvarsFormatter.pttopdecToString
                        ptdecs
                else ()
        in
            (ptdecs, basis, fn context => context)
        end

    fun doTypeInference (basis : TB.basis) ptdecs =
      (*
       PatternCalcWithTvars => TypedCalc
       *)
        let
            (* type inference *)
            val _ = #start typeInferenceTimeCounter ()
            val stamps = 
                {boundTypeVarIDStamp = #boundTypeVarIDStamp (#stamps basis),
                 freeTypeVarIDStamp = #freeTypeVarIDStamp (#localStamps basis),
                 exnTagIDKeyStamp = #exnTagIDKeyStamp (#stamps basis),
                 tyConIDKeyStamp = #tyConIDKeyStamp (#stamps basis),
                 varNameStamp = #varNameStamp (#localStamps basis)}
            val flattenedNamePathEnv = 
                case (#flattenedNamePathEnvOpt (#localContext basis)) of
                    NONE => raise Control.Bug "expect flattenedNamePathEnv for type inferencer"
                  | SOME x => x
            val (exportContext, newStamps, tpdecs, warnings) =
                TypeInferencer.infer (#topTypeContext (#context basis))
                                     stamps
                                     flattenedNamePathEnv
                                     ptdecs
            val _ = #stop typeInferenceTimeCounter ()

            (*******************************************************************************)
            val newGlobalStamps = 
                TB.setStampsTypeConstructorGlobalIDStamp
                    (TB.setStampsExceptionGlobalTagStamp
                         (TB.setStampsBoundTypeVarIDStamp (#stamps basis) (#boundTypeVarIDStamp newStamps))
                         (#exnTagIDKeyStamp newStamps))
                    (#tyConIDKeyStamp newStamps)
            val newLocalContext =
                TB.setLocalContextTypeContextOpt (#localContext basis) exportContext
            val newLocalStamps =
                TB.setLocalStampsVarNameStamp (#localStamps basis) (#varNameStamp newStamps)
            val newBasis = 
                TB.setBasisLocalStamps (TB.setBasisLocalContext (TB.setBasisStamps basis newGlobalStamps)  
                                                                newLocalContext)
                                       newLocalStamps
            val contextUpdater = 
                (fn context => 
                    TB.extendContextTopTypeContextWithCurrentTypeContext context exportContext)
            (*******************************************************************************)
            val _ = printWarnings (#sysParam basis) warnings
            val _ =
                if !C.printTP andalso !C.switchTrace
                then
                    (
                     printIntermediateCodes
                         (#sysParam basis)
                         "Statically evaluated"
                         (TypedCalcFormatter.tptopdecToString [])
                         tpdecs;
                     printError (#sysParam basis) "\nGenerated static bindings:\n";
                     printError (#sysParam basis) (TypeContext.contextToString exportContext)
                    )
                else ()
        in
            (tpdecs, newBasis, contextUpdater)
        end

    fun doUncurryOptimization (basis: TB.basis) tpdecs =
      (*
       TypedCalc => TypedCalc
       *)
        let
            (* Uncurrying  optimization *)
            val _ = #start UncurryOptimizationTimeCounter ()
            val stamps = 
                {boundTypeVarIDStamp = #boundTypeVarIDStamp (#stamps basis),
                 freeTypeVarIDStamp = #freeTypeVarIDStamp (#localStamps basis),
                 exnTagIDKeyStamp = #exnTagIDKeyStamp (#stamps basis),
                 tyConIDKeyStamp = #tyConIDKeyStamp (#stamps basis),
                 varNameStamp = #varNameStamp (#localStamps basis)} 
            val (newStamps, tpdecs) = 
                if !C.doUncurryOptimization
                then UncurryFundecl.optimize stamps tpdecs
                else (stamps, tpdecs)
            val newLocalStamps =
                TB.setLocalStampsVarNameStamp (#localStamps basis) (#varNameStamp newStamps)
            val newBasis = 
                TB.setBasisLocalStamps basis newLocalStamps
            val _ = #stop UncurryOptimizationTimeCounter ()
            val _ =
                if !C.printUC andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "Uncurying Optimized"
                        (TypedCalcFormatter.tptopdecToString [])
                        tpdecs
                else ()
        in
            (tpdecs, newBasis, fn context => context)
        end
        
    fun doPrinterGeneration (basis : TB.basis) tpdecs =
      (*
       TypedCalc => TypedCalc
       *)
        let
            (* printer generation *)
            val _ = #start printerGenerationTimeCounter ()
            val newTypeContext = 
                case (#typeContextOpt (#localContext basis)) of 
                    NONE => raise Control.Bug "\nexpect type context for PrinterCodeGeneration\n"
                  | SOME x => x
            val stamps = 
                {
                 varNameStamp = #varNameStamp (#localStamps basis),
                 boundTypeVarIDStamp = #boundTypeVarIDStamp (#stamps basis),
                 freeTypeVarIDStamp = #freeTypeVarIDStamp (#localStamps basis)
                 }
            val flattenedNamePathEnv = 
                case (#flattenedNamePathEnvOpt (#localContext basis)) of
                    NONE => raise Control.Bug "expect flattenedNamePathEnv for print code generator"
                  | SOME x => x
            val (newContext, newFlattenedNamePathEnv, newStamps, tpdecs) =
                if !C.skipPrinter
                then (newTypeContext, flattenedNamePathEnv, stamps, tpdecs)
                else
                    PrinterGenerator.generate
                        {
                         context = #topTypeContext (#context basis),
                         newContext = newTypeContext,
                         flattenedNamePathEnv = flattenedNamePathEnv, 
                         stamps = stamps,
                         printBinds = !C.printBinds,
                         declarations = tpdecs
                         }
            val _ = #stop printerGenerationTimeCounter ()
                    
            (***************************************************************************)
            val newGlobalStamps = 
                TB.setStampsBoundTypeVarIDStamp (#stamps basis)
                                                (#boundTypeVarIDStamp newStamps)
            val newLocalStamps = 
                TB.setLocalStampsFreeTypeVarIDStamp
                    (TB.setLocalStampsVarNameStamp (#localStamps basis)
                                                   (#varNameStamp newStamps))
                    (#freeTypeVarIDStamp newStamps)
            val newLocalContext = 
                TB.setLocalContextFlattenedNamePathEnvOpt (#localContext basis) newFlattenedNamePathEnv
            val newBasis = 
                TB.setBasisLocalContext
                    (TB.setBasisLocalStamps (TB.setBasisStamps basis newGlobalStamps)
                                            newLocalStamps)
                    newLocalContext
            (***************************************************************************)
            val _ =
                if
                    !C.printTP
                    andalso !C.switchTrace
                    andalso false = !C.skipPrinter
                then
                    (
                     printIntermediateCodes
                         (#sysParam basis)
                         "Printer code generated"
                         (TypedCalcFormatter.tptopdecToString [])
                         tpdecs;
                     printError (#sysParam basis) "\nGenerated static bindings:\n";
                     printError (#sysParam basis) (TypeContext.contextToString newContext)
                    )
                else ()
        in
            (tpdecs, newBasis, fn context => context)
        end

    fun doUniqueIDAllocation (basis : TB.basis) tpdecs  =
      (*
       TypedCalc => TypedFlatCalc
       *)
        let
	    (* unique Id Allocation *)
            val _ = #start UniqueIdAllocationCounter ()
            val stamps = 
                {
                 localVarIDStamp = (#localVarIDStamp (#localStamps basis)),
                 externalVarIDKeyStamp = #externalVarIDKeyStamp (#stamps basis)
                }
            val flattenedNamePathEnv = 
                case (#flattenedNamePathEnvOpt (#localContext basis)) of
                    NONE => raise Control.Bug "expect flattenedNamePathEnv for uniqueIdAllocation"
                  | SOME x => x
            val (deltaBasis, stamps, tpflatdecs) =
                UniqueIDAllocation.allocateID (#externalVarIDBasis (#context basis))
                                              (#2 flattenedNamePathEnv)
                                              stamps
                                              tpdecs
            val _ = #stop UniqueIdAllocationCounter ()

            (**********************************************************************)
            val newBasis = 
                TB.setBasisStamps
                    (TB.setBasisLocalStamps 
                         basis 
                         (TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis)
                                                                      (#localVarIDStamp stamps)))
                    (TB.setStampsExternalVarIDStamp (#stamps basis)
                                                    (#externalVarIDKeyStamp stamps))
            val newLocalContext = 
                TB.setLocalContextNewExternalVarIDBasisOpt (#localContext basis) deltaBasis
            val newBasis = 
                TB.setBasisLocalContext newBasis newLocalContext
            val contextUpdater = 
                (fn context => TB.extendContextWithExternalVarIDBasis context deltaBasis)
            (**********************************************************************)
            val _ =
                if !C.printTFP andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "Unique ID Allocated"
                        PrintTFP.tfpTopBlockToString
                        tpflatdecs
                else () 
        in
          (tpflatdecs, newBasis, contextUpdater)
        end

    fun doMatchCompilation (basis : TB.basis) tpflatdecs =
      (*
       TypedFlatCalc => RecordCalc
       *)
        let
            (* match compile *)
            val stamps = 
                {localVarIDStamp = #localVarIDStamp (#localStamps basis),
                 varNameStamp = #varNameStamp (#localStamps basis)}
            val _ = #start matchCompilationTimeCounter ()
            val (newStamps, rcdecs, warnings) = MatchCompiler.compile stamps tpflatdecs
            val _ = #stop matchCompilationTimeCounter ()

            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsVarNameStamp
                    (TB.setLocalStampsUniqueLocalIdentifierStamp
                         (#localStamps basis)
                         (#localVarIDStamp newStamps))
                    (#varNameStamp newStamps)
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps
            (***************************************************************************************)
            val _ = printWarnings (#sysParam basis) warnings
            val _ =
                if !C.printRC andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "Match Compiled"
                        (RecordCalcFormatter.topGroupToString)
                        rcdecs
                else ()
        in
            (rcdecs, newBasis, fn context => context)
        end

    fun doTypedLambdaNormalization (basis : TB.basis) rcdecs =
      (*
       RecordCalc => TypedLambda
       *)
        let
            (* record compile *)
            val _ = #start typedLambdaNormalizationTimeCounter ()
            val (stamp, tldecs) = 
                TLNormalization.normalize (#localVarIDStamp (#localStamps basis)) rcdecs
            val _ = #stop typedLambdaNormalizationTimeCounter ()

            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) stamp
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps
            (***************************************************************************************)

            val _ =
                if !C.printTL andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "TypedLambda normalization"
                        (TypedLambdaFormatter.topBlockToString)
                        tldecs
                else ()
        in
            (tldecs, newBasis, fn context => context)
        end

    fun doTypeCheck (basis:TB.basis) tldecs =
      (*
       TypedLambda => unit
       *)
      let
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
                        (#sysParam basis)
                        "Diagnoses"
                        (C.prettyPrint o UE.format_errorInfo)
                        diagnoses
                  else ()
              in
                ()
              end
          else ()
      in
        (tldecs, basis, fn context => context)
      end

    fun doStaticAnalysis (basis : TB.basis) tldecs =
      (*
       TypedLambda => AnnotatedCalc
       *)
        let
            (* static analysis *)
            val _ = #start staticAnalysisTimeCounter ()
            val acdecs = StaticAnalysis.analyse tldecs
            val _ = #stop staticAnalysisTimeCounter ()
            val _ =
                if !C.printAC andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "Static analysis"
                        (AnnotatedCalcFormatter.topBlockToString)
                        acdecs
                else ()
        in
            (acdecs, basis, fn context => context)
        end

    fun doRecordUnboxing basis acdecs =
      (*
       AnnotatedCalc => MultipleValueCalc
       *)
        let
            (* record unboxing *)
            val _ = #start recordUnboxingTimeCounter ()
            val (stamp, mvdecs) = 
                RecordUnboxing.transform (#localVarIDStamp (#localStamps basis)) acdecs
            val _ = #stop recordUnboxingTimeCounter ()

            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) stamp
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps
            (***************************************************************************************)
            val _ =
                if !C.printMV andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "Record unboxing"
                        (MultipleValueCalcFormatter.topBlockToString)
                        mvdecs
                else ()
        in
            (mvdecs, newBasis, fn context => context)
        end

    fun doInlining (basis : TB.basis) mvdecs =
      (*
       MultipleValueCalc => MultipleValueCalc
       *)
        if !C.doInlining then
	    let
                val stamps = 
                    {localVarIDStamp = #localVarIDStamp (#localStamps basis),
                     boundTypeVarIDStamp = #boundTypeVarIDStamp (#stamps basis)}
	        val _ = #start inliningTimeCounter()
	        val (globalInlineEnv, newStamps, mvdecs) = 
		    Inline.doInlining (#inlineEnv (#context basis)) stamps mvdecs
	        val _ = #stop inliningTimeCounter()

                (***************************************************************************)
                val newGlobalStamps = 
                    TB.setStampsBoundTypeVarIDStamp (#stamps basis)
                                                    (#boundTypeVarIDStamp newStamps)
                val newLocalStamps = 
                    TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis)
                                                                (#localVarIDStamp newStamps)
                val newBasis = 
                    TB.setBasisLocalStamps (TB.setBasisStamps basis newGlobalStamps)
                                           newLocalStamps
                (* 2008.2.7 liu : to support true separate compilation , inliner must return the incremental
                 * globalInlineEnv instead of an already increased one. The current implementation 
                 * follows the latter strategy. Thus we need to switch it off in true separate
                 * compilation.
                 *)
                val contextUpdater =
                    (fn context => TB.setContextInlineEnv context globalInlineEnv)
                (***************************************************************************)
                val _ =
		    if !C.printMV andalso !C.switchTrace
		    then
		        printIntermediateCodes
                            (#sysParam basis)
			    "Inlining"
			    (MultipleValueCalcFormatter.topBlockToString)
			    mvdecs
		    else ()
	    in
                (mvdecs, newBasis, contextUpdater)
	    end
        else
	    (mvdecs, basis, fn context => context)

    fun doMultipleValueOptimization (basis : TB.basis) mvdecs =
      (*
       MultipleValueCalc => MultipleValueCalc
       *)
        if !C.doMultipleValueOptimization
        then
            let
                val _ = #start mvOptimizationTimeCounter ()
                val (stamp, mvdecs) = 
                    MVOptimization.optimize 
                        (#localVarIDStamp (#localStamps basis)) mvdecs
                val _ = #stop mvOptimizationTimeCounter ()

                (***************************************************************************************)
                val newLocalStamps = 
                    TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) stamp
                val newBasis = TB.setBasisLocalStamps basis newLocalStamps
                (***************************************************************************************)
                val _ =
                    if !C.printMV andalso !C.switchTrace
                    then
                        printIntermediateCodes
                            (#sysParam basis)
                            "Multiple value optimization"
                            (MultipleValueCalcFormatter.topBlockToString)
                            mvdecs
                    else ()
            in
                (mvdecs, newBasis, fn context => context)
            end
        else (mvdecs, basis, fn context => context)
             
    fun doFunctionLocalize (basis : TB.basis) mvdecs =
      (*
       MultipleValueCalc => MultipleValueCalc
       *)
      if !C.doFunctionLocalize
      then
        let
          val _ = #start functionLocalizeTimeCounter ()
          val mvdecs = FunctionLocalize.localize mvdecs
          val _ = #stop  functionLocalizeTimeCounter ()

          val _ =
              if !C.printMV andalso !C.switchTrace
              then
                printIntermediateCodes
                    (#sysParam basis)
                    "Function Localization"
                    (MultipleValueCalcFormatter.topBlockToString)
                    mvdecs
              else ()
        in
            (mvdecs, basis, fn context => context)
        end
      else 
          (mvdecs, basis, fn context => context)

    fun doFunctorLinker (basis : TB.basis)  mvdecs =
      (*
       MultipleValueCalc => MultipleValueCalc
       *)
        let
            val _ = #start functorLinkerTimeCounter ()
            val (newFunctorEnv, stamp, mvdecs) =
                FunctorLinker.link (#functorEnv (#context basis))
                                   (#localVarIDStamp (#localStamps basis)) 
                                   mvdecs
            val _ = #stop functorLinkerTimeCounter ()

            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) stamp
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps
            val contextUpdater = fn context => TB.extendContextFunctorEnv context newFunctorEnv
            (***************************************************************************************)
            val _ =
                if !C.printMV andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "Functor Linker"
                        (MultipleValueCalcFormatter.mvdeclToString)
                        mvdecs
                else ()
        in
            (mvdecs, newBasis, contextUpdater)
        end
        
    fun doMVTypeCheck (basis : TB.basis) mvdecs =
      (*
       MultipleValueCalc => MultipleValueCalc
       *)
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
                                        (#sysParam basis)
                                        "Diagnoses"
                                        (C.prettyPrint o UE.format_errorInfo)
                                        diagnoses
                            else ()
                    in
                        ()
                    end
                else ()
        in
            (mvdecs, basis, fn context => context)
        end

    fun doMVTypeCheckBeforeInline (basis : TB.basis) mvdecs =
      (*
       MultipleValueCalc => MultipleValueCalc
       *)
        let
            (* type check *)
            val _ = print (#sysParam basis) "Typecheking before Inlining ..."
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
                                        (#sysParam basis)
                                        "Diagnoses"
                                        (C.prettyPrint o UE.format_errorInfo)
                                        diagnoses
                            else ()
                    in
                        ()
                    end
                else ()
            val _ = print (#sysParam basis) "done.\n"
        in
            (mvdecs, basis, fn context => context)
        end

    fun doMVTypeCheckAfterInline (basis : TB.basis) mvdecs =
      (*
       MultipleValueCalc => MultipleValueCalc
       *)
        let
            (* type check *)
            val _ = print (#sysParam basis) "Typecheking after Inlining ..."
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
                                        (#sysParam basis)
                                        "Diagnoses"
                                        (C.prettyPrint o UE.format_errorInfo)
                                        diagnoses
                            else ()
                    in
                        ()
                    end
                else ()
            val _ = print (#sysParam basis) "done.\n"
        in
            (mvdecs, basis, fn context => context)
        end

    fun doClustering (basis : TB.basis) mvdecs =
      (*
       MultipleValueCalc => ClusterCalc
       *)
        let
            val _ = #start clusteringTimeCounter ()
            val (stamp, ccdecs) = 
                Clustering.transform (#localVarIDStamp (#localStamps basis))  mvdecs
            val _ = #stop clusteringTimeCounter ()

            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) stamp
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps
            (***************************************************************************************)
            val _ =
                if !C.printCC andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "Clustering"
                        (ClusterCalcFormatter.ccdeclToString)
                        ccdecs
                else ()
        in
            (ccdecs, newBasis, fn context => context)
        end

    fun doRBUTransformation (basis : TB.basis) ccdecs =
      (*
       ClusterCalc => RBUCalc
       *)
        let
            val _ = #start rbuTransformationTimeCounter ()
            val (stamp, rbudecs) = 
                RBUTransformation.transform (#localVarIDStamp (#localStamps basis)) ccdecs
            val _ = #stop rbuTransformationTimeCounter ()

            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) stamp
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps
            (***************************************************************************************)
            val _ =
                if !C.printRBU andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "RBU transformation"
                        (RBUCalcFormatter.rbudeclToString)
                        rbudecs
                else ()
        in
            (rbudecs, newBasis, fn context => context)
        end

    fun doANormalization (basis : TB.basis) rbudecs =
        let
            val _ = #start anormalizationTimeCounter ()
            val (stamp, andecs) = 
                ANormalization.normalize (#localVarIDStamp (#localStamps basis)) rbudecs
            val _ = #stop anormalizationTimeCounter ()

            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) stamp
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps
            (***************************************************************************************)

            val _ =
                if !C.printAN andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "ANormalization"
                        (ANormalFormatter.andeclToString)
                        andecs
                else ()
        in
            (andecs, newBasis, fn context => context)
        end


    fun doILTransformation (basis : TB.basis) andecls =
        let
            val _ = #start iltransformationTimeCounter ()
            val (stamp, ilcode) = 
                ILTransformation.transform (#localVarIDStamp (#localStamps basis)) andecls
            val _ = #stop iltransformationTimeCounter ()
                    
            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) stamp
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps
            (***************************************************************************************)

            val _ =
                if !C.printIL andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "ILTransformation"
                        ILFormatter.moduleCodeToString
                        [ilcode]
                else ()
        in
            (ilcode, newBasis, fn context => context)
        end

    fun doSIGeneration (basis : TB.basis) ilcode =
        let
            (* SIGeneration *)
            val stamps = #localVarIDStamp (#localStamps basis)
            val _ = #start sigenerationTimeCounter ()
            val (newGlobalIndexEnv, stamp, symbolicCode) = 
                SIGenerator.generate (#globalIndexEnv (#context basis), stamps, ilcode)
            val _ = #stop sigenerationTimeCounter ()

            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis)
                                                            stamp
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps
            val contextUpdater = fn context => TB.setContextGlobalIndexEnv context newGlobalIndexEnv
            (***************************************************************************************)

            val _ =
                if !C.printLS andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "SIGeneration"
                        SymbolicInstructionsFormatter.clusterCodeToString
                        symbolicCode
                else ()
        in
            (symbolicCode, newBasis, contextUpdater)
        end

    fun doStackReallocation (basis : TB.basis) symbolicCode = 
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
                        (#sysParam basis)
		        "StackReallocation"
		        SymbolicInstructionsFormatter.clusterCodeToString
                        (*clusterCodeToString*) (*livesProgToString*) (*cfgToString*) 
		        (*map Reallocater.printLivenessClusters newSymbolicCode*) 
		        (*map Reallocater.printCFGClusters newSymbolicCode*) 
		        (newSymbolicCode)
	        else
		    ()
	    val _ = #stop stackReallocationTimeCounter ()
		    
        in
            (newSymbolicCode, basis, fn context => context)
        end 

    fun doYAANormalization (basis : TB.basis) rbudecs =
        let
            val _ = #start anormalizationTimeCounter ()
            val (newCounter, andecs) = 
                YAANormalization.normalize
                    {localVarIDStamp = #localVarIDStamp (#localStamps basis),
                     clusterIDStamp = #clusterIDKeyStamp (#stamps basis)}
                    rbudecs
            val _ = #stop anormalizationTimeCounter ()
                    
            (***************************************************************************************)
            val newGlobalStamps = 
                TB.setStampsClusterGlobalIDStamp (#stamps basis) (#clusterIDStamp newCounter)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) (#localVarIDStamp newCounter)

            val newBasis = TB.setBasisStamps basis newGlobalStamps
            val newBasis = TB.setBasisLocalStamps newBasis newLocalStamps
            (***************************************************************************************)

            val _ =
                if !C.printAN andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "Yet Another ANormalization"
                        (YAANormalFormatter.topdeclToString)
                        andecs
                else ()
        in
            (andecs, newBasis, fn context => context)
        end

    fun doYAANormalOptimization (basis : TB.basis) andecs =
        let
            val _ = #start anormalizationTimeCounter ()
            val newAndecs = YAANormalOptimization.optimize andecs
            val _ = #stop anormalizationTimeCounter ()

            val _ =
                if !C.printAN andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "Yet Another ANormal Optimization"
                        (YAANormalFormatter.topdeclToString)
                        newAndecs
                else ()
        in
            (newAndecs, basis, fn context => context)
        end

    fun doYAANormalTypeCheck (basis : TB.basis) andecs =
        let
            val _ =
                if !C.checkType
                then
                    let
                        val diagnoses = YAANormalTypeCheck.typecheck andecs
                        val _ = 
                            if ! C.printDiagnosis then
                                case diagnoses of
                                    nil => ()
                                  | _ =>
                                    printIntermediateCodes
                                        (#sysParam basis)
                                        "Diagnoses"
                                        (C.prettyPrint o UE.format_errorInfo)
                                        diagnoses
                            else ()
                    in
                        ()
                    end
                else ()
        in
            (andecs, basis, fn context => context)
        end

    fun doDeclarationRecovery (basis : TB.basis) andecs =
        let
          val (newAliasEnv, newAndecs) =
              DeclarationRecovery.recover
                {
                  currentBasis = #externalVarIDBasis (#context basis),
                  newBasis = valOf (#newTopExternalVarIDBasisOpt (#localContext basis)),
                  currentContext = #topTypeContext (#context basis),
                  newContext = valOf (#typeContextOpt (#localContext basis)),
                  aliasEnv = #globalNameAliasEnv (#context basis),
                  separateCompilation = false
                }
                andecs

            val contextUpdater = 
             fn context => TB.setContextGlobalNameAliasEnv context newAliasEnv

            val _ =
                if !C.printAN andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "Declaration Recovery"
                        (YAANormalFormatter.topdeclToString)
                        newAndecs
                else ()
        in
            (newAndecs, basis, contextUpdater)
        end

    fun doAIGeneration useGlobalArray (basis : TB.basis) andecls =
        let
            val globalIndexAllocator =
                if useGlobalArray
                then SOME (GlobalIndexAllocator.new
                               (#globalIndexEnv (#context basis)))
                else NONE

            val (allocator, finish) =
                case globalIndexAllocator of
                  SOME {allocator, finish} => (SOME allocator, SOME finish)
                | NONE => (NONE, NONE)
                     
            val _ = #start aigenerationTimeCounter ()
            val (stamp, aicode) =
                AIGenerator.generate
                    (#localVarIDStamp (#localStamps basis))
                    allocator
                    andecls
            val _ = #stop aigenerationTimeCounter ()

            val (contextUpdater, initGlobalArrays) =
                case finish of
                  NONE => (fn x => x, nil)
                | SOME finish =>
                  let
                    val (newGlobalIndexEnv, initGlobalArrays) = finish ()
                  in
                    (fn context => 
                        TB.setContextGlobalIndexEnv context newGlobalIndexEnv,
                     initGlobalArrays)
                  end
                     
            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) stamp
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps

            (***************************************************************************************)

            val _ =
                if !C.printAI andalso !C.switchTrace
                then
                  printIntermediateCodes
                      (#sysParam basis)
                      "AIGeneration"
                      AbstractInstructionFormatter.programToString
                      [aicode]
                else ()
        in
            ((initGlobalArrays, aicode), newBasis, contextUpdater)
        end

    fun doAIGeneration2 (basis : TB.basis) andecls =
        let
            val _ = #start aigenerationTimeCounter ()
            val (stamp, aicode) =
                AIGenerator2.generate
                    (#localVarIDStamp (#localStamps basis))
                    andecls

            val _ = #stop aigenerationTimeCounter ()

            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) stamp
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps

            (***************************************************************************************)

            val _ =
                if !C.printAI andalso !C.switchTrace
                then
                  printIntermediateCodes
                      (#sysParam basis)
                      "AIGeneration2"
                      AbstractInstruction2Formatter.programToString
                      [aicode]
                else ()
        in
            (aicode, newBasis, fn context => context)
        end

    fun doVMCodeSelection (basis : TB.basis) aicode =
        let
            val _ = #start vmcodeselectionTimeCounter ()
            val (stamp, vmcode) = 
                VMCodeSelection.select
                    (#localVarIDStamp (#localStamps basis))
                    aicode
            val _ = #stop vmcodeselectionTimeCounter ()

            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) stamp
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps
            (***************************************************************************************)

            val _ =
                if !C.printML andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "VMCodeSelection"
                        VMCodeFormatter.programToString
                        [vmcode]
                else ()
        in
            (vmcode, newBasis, fn context => context)
        end

    fun doStackAllocation (basis : TB.basis) mcode =
        let
            val _ = #start stackallocationTimeCounter ()
            val mcode = StackAllocation.allocate mcode
            val _ = #stop stackallocationTimeCounter ()

            val _ =
                if !C.printML andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "StackAllocation"
                        VMCodeFormatter.programToString
                        [mcode]
                else ()
        in
            (mcode, basis, fn context => context)
        end

    fun doLinearize (basis : TB.basis) mcode =
        let
            val _ = #start linearizeTimeCounter ()
            val mcode = Linearize.linearize mcode
            val _ = #stop linearizeTimeCounter ()

            val _ =
                if !C.printML andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "Linearize"
                        VMCodeFormatter.programToString
                        [mcode]
                else ()
        in
            (mcode, basis, fn context => context)
        end

    fun doVMCodeEmission (basis : TB.basis) vmcode =
        let
            val _ = #start vmcodeemissionTimeCounter ()
            val asmcode = VMCodeEmission.emit vmcode
            val _ = #stop vmcodeemissionTimeCounter ()

            val _ =
                if !C.printIS andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "VMCodeEmission"
                        VMAsmCodeFormatter.assemblyCodeToString
                        [asmcode]
                else ()
        in
            (asmcode, basis, fn context => context)
        end

    fun doVMAssemble (basis : TB.basis) asmcode =
        let
            val _ = #start vmcodeemissionTimeCounter ()
            val objfile = Assemble.assemble VMAssembler.assemble asmcode
            val _ = #stop vmcodeemissionTimeCounter ()

            val _ =
                if !C.printOBJ andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis) 
                        "VMAssemble"
                        ObjectFileFormatter.objectFileToString
                        [objfile]
                else ()
        in
            (SessionTypes.OBJECTFILE objfile, basis, fn context => context)
        end

    fun doX86RTLBackend (basis : TB.basis) aicode =
        let
          val _ = #start vmcodeselectionTimeCounter ()
          val (stamp, asmFn) =
              X86RTLBackend.codegen
                  (#localVarIDStamp (#localStamps basis))
                  (SOME (#compileUnitStamp (#stamps basis)))
                  aicode
          val _ = #stop vmcodeselectionTimeCounter ()

          val newLocalStamps = 
              TB.setLocalStampsUniqueLocalIdentifierStamp
                (#localStamps basis) stamp
          val newBasis = TB.setBasisLocalStamps basis newLocalStamps
        in
          (SessionTypes.ASMFILE asmFn, newBasis, fn context => context)
        end

    fun doX86CodeSelection (basis : TB.basis) aicode =
        let
            val _ = #start vmcodeselectionTimeCounter ()
            val (stamp, x86code) = 
                X86CodeSelection.select
                    (SOME (#compileUnitStamp (#stamps basis)))
                    (#localVarIDStamp (#localStamps basis))
                    aicode
            val _ = #stop vmcodeselectionTimeCounter ()

            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) stamp
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps
            (***************************************************************************************)

            val _ =
                if !C.printML andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "X86CodeSelection"
                        X86Formatter.programToString
                        [x86code]
                else ()
        in
            (x86code, newBasis, fn context => context)
        end

    fun doX86RegisterAllocation (basis : TB.basis) x86code =
        let
            val _ = #start vmcodeselectionTimeCounter ()
            val (stamp, x86code) = 
                X86RegisterAllocation.allocate
                    (#localVarIDStamp (#localStamps basis))
                    x86code
            val _ = #stop vmcodeselectionTimeCounter ()

            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) stamp
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps
            (***************************************************************************************)

            val _ =
                if !C.printML andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "X86RegisterAllocation"
                        X86Formatter.programToString
                        [x86code]
                else ()
        in
            (x86code, basis, fn context => context)
        end

    fun doX86CodeGeneration (basis : TB.basis) x86code =
        let
            val _ = #start vmcodeselectionTimeCounter ()
            val asm = X86CodeGeneration.codeGen x86code
            val _ = #stop vmcodeselectionTimeCounter ()
            val asmFn = SessionTypes.ASMFILE (fn f => f asm)
        in
            (asmFn, basis, fn context => context)
        end

    fun doYASIGeneration (basis : TB.basis) (initGlobalArrays, aicode) =
        let
            val _ = #start yasigenerationTimeCounter ()
            val (stamp, sicode) = 
                YASIGenerator.generate
                    (#localVarIDStamp (#localStamps basis))
                    (initGlobalArrays, aicode)
            val _ = #stop yasigenerationTimeCounter ()

            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) stamp
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps
            (***************************************************************************************)

            val _ =
                if !C.printLS andalso !C.switchTrace
                then
                    printIntermediateCodes
                        (#sysParam basis)
                        "Yet Another SIGeneration"
                        SymbolicInstructionsFormatter.clusterCodeToString
                        sicode
                else ()
        in
            (sicode, newBasis, fn context => context)
        end

    fun doAssemble (basis : TB.basis) symbolicCode =
        let
            (* assemble *)
            val _ = #start assembleTimeCounter ()
            val (stamp, executable as {instructions, locationTable, ...}) =
                Assembler.assemble (#localVarIDStamp (#localStamps basis)) symbolicCode
            val _ = #stop assembleTimeCounter ()

            (***************************************************************************************)
            val newLocalStamps = 
                TB.setLocalStampsUniqueLocalIdentifierStamp (#localStamps basis) stamp
            val newBasis = TB.setBasisLocalStamps basis newLocalStamps
            (***************************************************************************************)

            val _ =
                if !C.printIS andalso !C.switchTrace
                then
                    (
                     printIntermediateCodes
                         (#sysParam basis)
                         "Assembled"
                         Instructions.toString
                         instructions;
                     printError
                         (#sysParam basis)
                         (Executable.locationTableToString locationTable)
                    )
                else ()
        in
            (executable, newBasis, fn context => context)
        end

    fun doSerialize basis executable =
        let
            (* serialize *)
            val _ = #start serializeTimeCounter ()
            val codeBlock = ExecutableSerializer.serialize executable
            val _ = #stop serializeTimeCounter ()
        in
          (SessionTypes.CODEBLOCK codeBlock, basis, fn context => context)
        end

    (********************)
    infix ==>
    fun (prev ==> (phasePosition, phase)) (basis: TB.basis) code = 
        let
            val (code1Opt, basis1, contextUpdater1) = prev basis code
        in
            if C.doPhase phasePosition then
                case code1Opt of
                    NONE => (NONE, basis1, contextUpdater1)
                  | SOME code1 => 
                    let
                        val (code2, basis2, contextUpdater2) = phase basis1 code1
                    in
                        (SOME code2, basis2, contextUpdater2 o contextUpdater1)
                    end
            else
                (NONE, basis1, contextUpdater1)
        end

    infix -->
    fun (prev --> next) (basis : TB.basis) code =
        let
            val (code1Opt, basis1, contextUpdater1) = prev basis code
        in
            case code1Opt of
                NONE => (NONE, basis1, contextUpdater1)
              | SOME code1 => 
                let
                    val (code2Opt, basis2, contextUpdater2) = next basis1 code1
                in
                    (code2Opt, basis2, contextUpdater2 o contextUpdater1)
                end
        end

    fun enter (basis : TB.basis) code = (SOME code, basis, fn context => context)


(*
  doUncurryOptimization
  doRecordUnboxing
  doMultipleValueOptimization
  doUselessCodeElimination
*)
    val phasesUpToTypeInferenceCompile =
        enter ==> (0, doSource)
              ==> (C.Elab, doElaboration)
              ==> (C.Elab, doModuleCompilation)
              ==> (C.FunOpt, doVALRECOptimization)
              ==> (C.FunOpt, doFundeclElaboration) (* cannot turn off *)
              ==> (C.TVar, doSetTvars)
              ==> (C.TyInf, doTypeInference)

    (* liu : used for the continuous compilation of the type instantiation declarations
     * generated by require specification matching in separate compilation
     *)
    val phasesFromUnCurryOptimizationCompile =
        enter ==> (C.Print, doPrinterGeneration)
              ==> (C.LayoutOpt, doUncurryOptimization)
              ==> (C.UniqueID, doUniqueIDAllocation)
              ==> (C.MatchComp, doMatchCompilation)
              ==> (C.Lambda, doTypedLambdaNormalization)
              ==> (C.Lambda, doTypeCheck)
              ==> (C.Static, doStaticAnalysis)
              ==> (C.Unbox, doRecordUnboxing) (* cannot turn off *)
	      ==> (C.Inline, doInlining)
              ==> (C.DeadCode, doMultipleValueOptimization) (* cannot turn off *)
              ==> (C.Localize, doFunctionLocalize)
              ==> (C.Localize, doMVTypeCheck)
              ==> (C.Functor, doFunctorLinker)
              ==> (C.Cluster, doClustering)
              ==> (C.RBUComp, doRBUTransformation)
              --> (fn basis => (
              if Control.nativeGen() then
                  enter
                      ==> (C.Anormal, doYAANormalization)
                      ==> (C.Anormal, doYAANormalOptimization)
                      ==> (C.Anormal, doDeclarationRecovery)
(*
                      ==> (C.Anormal, doYAANormalTypeCheck)
*)
                      --> (
                      case #cpu (Control.targetInfo ()) of
                        "x86old" =>
                          enter
                              ==> (C.AI, doAIGeneration2)
                              ==> (C.SI, doX86CodeSelection)
                              ==> (C.SI, doX86RegisterAllocation)
                              ==> (C.SI, doX86CodeGeneration)
                      | "x86" =>
                          enter
                              ==> (C.AI, doAIGeneration2)
                              ==> (C.SI, doX86RTLBackend)
                      | "newvm" =>
                          enter
                              ==> (C.AI, doAIGeneration false)
                              --> (fn b => fn (x, y) => (SOME y, b, fn x => x))
                              ==> (C.SI, doVMCodeSelection)
                              ==> (C.SI, doStackAllocation)
                              ==> (C.SI, doLinearize)
                              ==> (C.SI, doVMCodeEmission)
                              ==> (C.SI, doVMAssemble)
                      | "vm" =>
                          enter
                              ==> (C.AI, doAIGeneration true)
                              ==> (C.SI, doYASIGeneration)
                              ==> (C.Assem, doAssemble)
                              ==> (C.Code, doSerialize)
                      | x =>
                        raise Fail ("unknown target cpu : " ^ x)
                      )
              else
                  enter
                      ==> (C.Anormal, doANormalization)
                      ==> (C.SI, doILTransformation)
                      ==> (C.SI, doSIGeneration)
		      ==> (C.SIOpt, doStackReallocation)
                      ==> (C.Assem, doAssemble)
                      ==> (C.Code, doSerialize)
              ) basis)

    val phasesCompile  = 
        phasesUpToTypeInferenceCompile --> phasesFromUnCurryOptimizationCompile

    fun compile (context, stamps, sysParam) decs =
        let
            val initialBasis = 
                {
                 context = context,
                 stamps = stamps,
                 localContext = TB.initializeLocalContext (),
                 localStamps = TB.initializeLocalStamps(),
                 sysParam = sysParam
                }: TB.basis
            val (codeOpt, newBasis, contextUpdater) = phasesCompile initialBasis  decs
        in
            (
             codeOpt,
             ((contextUpdater (#context newBasis)) : TB.context, TB.incrementCompileUnitStamp (#stamps newBasis) : TB.stamps)
            )
        end
    (****************************************)

    fun onParseError sysParam = printError sysParam o Parser.errorToString

    fun getLine (source : parseSource) n = #getLine (#stream source) ()

    fun printPrompt (sysParam : sysParam) message =
        (print sysParam message; #flush (#standardOutput sysParam) ())

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

    (** obtains a new parse source and a parse context to parse a source
     * file which is specified by a 'use' directive.
     *)
    fun useSource sysParam (currentSource : parseSource) (fileName, loc) = 
        let
          val currentBaseDirectory = #getBaseDirectory currentSource ()
          val absoluteFilePath =
              PathResolver.resolve
                  (#getVariable sysParam)
                  (#loadPathList sysParam)
                  currentBaseDirectory
                  fileName
              handle exn => raise UE.UserErrors [(loc, UE.Error, exn)]
(*
val _ = currentSourceFilename := absoluteFilePath
*)
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
                  then printError sysParam ("source: " ^ absoluteFilePath ^ "\n")
                else ()
            val baseDirectory = #dir(PU.splitDirFile absoluteFilePath)
            val newParseSource =
                {
                 interactionMode =
                 case #interactionMode currentSource
                   of Prelude => Prelude
                    | _ => NonInteractive {stopOnError = true},
                 fileName = fileName,
                 getBaseDirectory = fn () => baseDirectory,
                 stream = FileChannel.openIn {fileName = absoluteFilePath},
                 history = absoluteFilePath :: (#history currentSource)
                } : parseSource
            val newParseContext =
                Parser.createContext
                  {
                   sourceName = fileName,
                   onError = onParseError sysParam,
                   getLine = getLine newParseSource,
                   isPrelude = #interactionMode currentSource = Prelude,
                   withPrompt = false,
                   print = printPrompt sysParam
                  }
        in
          (newParseSource, newParseContext)
        end

    fun useObject (basis : TB.basis) object =
        raise Control.Bug "to be done"

    fun restoreObject (basis : TB.basis) (currentSource : parseSource) (fileName, loc) = 
        raise Control.Bug "to be done"

    fun errorHandler sysParam exn =
      (
       #flush (#standardOutput sysParam) ();
       case exn of
         Parser.ParseError => ()
       | exn as UE.UserErrors errors =>
           (
            app
            (fn error =>
             (
              printError
              sysParam
              (C.prettyPrint (UE.format_errorInfo error));
              printError sysParam "\n"
              ))
            errors;
            printError sysParam "\n"
            )
       | exn as C.Bug message =>
           (
            printError sysParam ("BUG :" ^ message ^"\n");
            app
            (fn line => printError sysParam (line ^ "\n"))
            (SMLofNJ.exnHistory exn)
            )
       | exn as C.BugWithLoc (message, loc) =>
           (
            printError sysParam ("BUG :" ^ message ^"\n");
            printError
            sysParam
            ("  at " ^ AbsynFormatter.locToString loc ^ "\n");
            app
            (fn line => printError sysParam (line ^ "\n"))
            (SMLofNJ.exnHistory exn)
            )
       | SessionTypes.Failure cause =>
           printError sysParam ("RuntimeError:" ^ exnMessage cause ^ "\n")
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
             printError sysParam (message ^ "\n")
           end
       | OS.SysErr(message, _) => printError sysParam (message ^ "\n")
       | _ => raise exn;
           #flush (#standardError sysParam) ()
      ) 

        (** true if process of the current source should be stopped when any
         * error occurs. *)
        fun isStopOnError (source : parseSource) =
            case #interactionMode source of
                Interactive => false
              | NonInteractive {stopOnError, ...} => stopOnError
              | Prelude => true

      (**
       * @return true if the process succeeds. false otherwise.
       *)
      fun processSource (context, stamps, sysParam) (parseSource, parseContext) =
        let
          (* datatype to absorbe the exception raised during the parsing *)
          datatype 'a parseResult = 
            Interrupted | Completed of 'a | Finished | ParseError of exn

          val doProfile = Interactive = #interactionMode parseSource andalso !C.doProfile

          fun loop (context, stamps) parseContext = 
              let
                val _ = if doProfile then #reset TopCounterSet () else ()
                val _ = #start parseTimeCounter ();
                val parseStatus = 
                    (case SU.doWithInterruption [SU.SIGINT] Parser.parse parseContext of
                       SU.Interrupted _ => Interrupted
                     | SU.Completed arg => Completed arg)
                   handle 
                       Parser.EndOfParse => Finished
                     | exn => ParseError exn
                val _ = #stop parseTimeCounter ();
              in
                case parseStatus of
                  Finished => (true, (context, stamps))

                | Interrupted => 
                    (
                     print sysParam "\n"; 
                     loop (context, stamps) (flush parseContext)
                     )

                | ParseError exn =>
                    (
                     errorHandler sysParam exn;
                     if isStopOnError parseSource then 
                       (false, (context, stamps))
                     else 
                       loop (context, stamps) (flush parseContext)
                     )

                | Completed (A.USEOBJ (fileName, loc), newParseContext) => 
                    raise Control.Bug "to be implemented ..."

                | Completed (A.USE(fileName, loc), newParseContext) => 
                    (
                     let
                       val (innerParseSource, innerParseContext) =
                           useSource sysParam parseSource (fileName, loc)
                     in
                       let
                         val (success, updatedContextAndStamps) =
                           processSource
                           (context, stamps, sysParam)
                           (innerParseSource, innerParseContext)
                         val _ = #close (#stream innerParseSource) ()
                       in
                         (
                          if success andalso doProfile
                            then (print sysParam "\n"; 
                                  print sysParam (Counter.dump ()))
                          else ();
                            if success then
                              loop updatedContextAndStamps newParseContext
                            else if isStopOnError parseSource then 
                              (false, (context, stamps))
                            else 
                              loop (context, stamps) (flush newParseContext)
                          )
                       end
                     end
                   handle sourceError => 
                      (
                       errorHandler sysParam sourceError;
                       if isStopOnError parseSource
                         then (false, (context, stamps))
                       else 
                         loop (context, stamps) (flush newParseContext)
                      )
                    )

                | Completed (A.UNIT(topdecs, loc), newParseContext) => 
                    let
                      val _ = #start compilationTimeCounter ()
                      val (codeBlock, updatedContextAndStamps) = compile (context, stamps, sysParam) topdecs
                      val _= #stop compilationTimeCounter ()
                      val _ =
                        if C.doPhase C.Run
                          then
                            case codeBlock of
                              SOME codeBlock =>
                                (
                                 #start executeTimeCounter ();
                                 #execute (#session sysParam) codeBlock;
                                 #stop executeTimeCounter ();
                                 ()
                                 )
                            | _ => ()
                        else ()
                    in
                      if doProfile
                        then (print sysParam "\n"; 
                              print sysParam (Counter.dump ()))
                      else ();
                      loop updatedContextAndStamps newParseContext
                    end
                    handle compilerError => 
                      (
                       errorHandler sysParam compilerError;
                       if isStopOnError parseSource
                         then (false, (context, stamps))
                       else 
                         loop (context, stamps) (flush newParseContext)
                      )
              end
        in
          loop (context, stamps) parseContext
        end


      fun initializeContextAndStamps () =
          (TB.initializeContext (), TopBasis.initializeStamps ())
          
      fun initializeContextAndStampsWithNamespace namespace =
          (TB.initializeContext (), TopBasis.initializeStampsWithNamespace namespace)

    fun run (context : TB.context)
            (stamps : TB.stamps)
            (sysParam : TB.sysParam)
            ({
             interactionMode,
             initialSourceChannel,
             initialSourceName,
             getBaseDirectory
             } : source) =
        let 
            val initialParseSource =
                {
                 interactionMode = interactionMode,
                 getBaseDirectory = getBaseDirectory,
                 fileName = initialSourceName,
                 stream = initialSourceChannel,
                 history = [initialSourceName]
                } : parseSource

            (* In interactive mode, parser should abort as soon as the first error
             * is detected.
             *)
            val initialParseContext = 
                Parser.createContext
                    {
                     sourceName = initialSourceName,
                     onError =
                       if interactionMode = Interactive
                         then (fn _ => raise Parser.ParseError) o onParseError sysParam
                       else onParseError sysParam,
                     getLine = getLine initialParseSource,
                     isPrelude = interactionMode = Prelude,
                     withPrompt = interactionMode = Interactive,
                     print = printPrompt sysParam
                    }
        in
            processSource (context, stamps, sysParam) (initialParseSource, initialParseContext)
        end
end
