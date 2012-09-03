(**
 * Static Analysis
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure StaticAnalysis : STATICANALYSIS = struct

  structure T = Types
  structure TU = TypesUtils
  structure AT = AnnotatedTypes
  structure ATU = AnnotatedTypesUtils
  structure TL = TypedLambda
  structure CTX = SAContext
  structure CST = SAConstraint
  structure CT = ConstantTerm
  open AnnotatedCalc

  fun printTlexp tlexp =
      (
       print (Control.prettyPrint (TL.format_tlexp [] tlexp));
       print "\n"
      )
  fun printTldecl tldecl =
      (
       print (Control.prettyPrint (TL.format_tldecl [] tldecl));
       print "\n"
      )
  fun bug s =
      Control.Bug ("StaticAnalysis:" ^ s)

  fun rootExp (TL.TLCAST {exp,...}) = rootExp exp
    | rootExp exp = exp

  fun inferExp context tlexp =
      case tlexp of
        TL.TLFOREIGNAPPLY {funExp, funTy, argExpList, attributes, loc} =>
        let
          val (newFunExp, _) = inferExp context funExp
          val (newArgExpList, newArgTyList) = inferExpList context argExpList
          (* arguments/return values, which are passed and received from
           * a foreign function should have global type, e.g. record should 
           * boxed and aligned
           *)
          val _ = List.app CST.globalType newArgTyList
          val bodyTy =
              case funTy of
                T.FUNMty (argTyList, bodyTy) => CST.convertGlobalType bodyTy
              | _ => raise Control.Bug "invalid foreign function type"
          val newFunTy =
              AT.FUNMty 
                {
                 argTyList = newArgTyList, 
                 bodyTy = bodyTy, 
                 funStatus = ATU.newClosureFunStatus(),
                 annotation = ref {labels = AT.LE_GENERIC, boxed = true}
                }
        in
          (
           ACFOREIGNAPPLY
             {
              funExp = newFunExp,
              funTy = newFunTy,
              argExpList  = newArgExpList,
              attributes = attributes,
              loc = loc
             },
           bodyTy
          )
        end

      | TL.TLEXPORTCALLBACK {funExp, funTy, attributes, loc} =>
        let
          val (newFunExp, newFunTy) = inferExp context funExp
          (* export function should have global type*)
          val _ = CST.globalType newFunTy
        in
          (
           ACEXPORTCALLBACK
               {
                funExp = newFunExp,
                funTy = newFunTy,
                attributes = attributes,
                loc = loc
               },
           AT.foreignfunty
          )
        end

      | TL.TLEXCEPTIONTAG (v as {tagValue, displayName, loc}) =>
        (ACEXCEPTIONTAG v, AT.exntagty)
      | TL.TLCONSTANT (v as {value, loc}) =>
        (ACCONSTANT v, ATU.constDefaultTy value)
      | TL.TLGLOBALSYMBOL {name,kind,ty,loc} =>
        let
          val newTy = CST.convertGlobalType ty
        in
          (ACGLOBALSYMBOL {name=name, kind=kind, ty=newTy, loc=loc}, newTy)
        end
      | TL.TLSIZEOF {ty, loc} =>
        let
          (* SIZEOF may appear only as an argument of FOREIGNAPPLY.
           * Since ty have a type of an exported value, ty should have
           * global type. *)
          val newTy = CST.convertGlobalType ty
        in
          (ACSIZEOF {ty = newTy, loc = loc}, AT.intty)
        end
      | TL.TLVAR {varInfo as {varId = T.INTERNAL id,...}, loc} => 
        (* local variable*)
        let
          val newVarInfo =
              CTX.lookupVariable context id (#displayName varInfo, loc)
        in
          (ACVAR{varInfo = newVarInfo, loc = loc}, #ty newVarInfo)
        end

      | TL.TLVAR {varInfo as {displayName, ty, varId as T.EXTERNAL _}, loc} => 
        (* gloval variable *)
        let
          val newTy = CST.convertGlobalType ty
          val newVarInfo =
              {displayName = displayName, ty = newTy, varId = varId}
        in
          (ACVAR{varInfo = newVarInfo, loc = loc}, newTy)
        end
        
      | TL.TLGETFIELD {arrayExp, indexExp, elementTy, loc} =>
        let
          val (newArrayExp, arrayTy) = inferExp context arrayExp
          val newElementTy = ATU.arrayElementTy arrayTy 
          val (newIndexExp, _) = inferExp context indexExp
        in
          (
           ACGETFIELD
               {
                arrayExp = newArrayExp,
                indexExp = newIndexExp,
                elementTy = newElementTy,
                loc = loc
               },
           newElementTy
          )
        end

      | TL.TLSETFIELD {valueExp, arrayExp, indexExp, elementTy, loc} =>
        let
          val (newArrayExp, arrayTy) = inferExp context arrayExp
          val newElementTy = ATU.arrayElementTy arrayTy
          val (newIndexExp, _) = inferExp context indexExp
          val (newValueExp, newValueTy) = inferExp context valueExp
          val _ = CST.unify (newValueTy, newElementTy)
              handle CST.Unify =>
              (printTlexp tlexp;
               raise bug "unification fail (1)")
        in
          (
           ACSETFIELD
               {
                valueExp = newValueExp,
                arrayExp = newArrayExp,
                indexExp = newIndexExp,
                elementTy = newElementTy,
                loc = loc
               },
           AT.unitty
          )
        end

      | TL.TLSETTAIL {consExp,newTailExp,listTy,consRecordTy,tailLabel,loc} =>
        let
          val (newConsExp, newConsExpTy) = inferExp context consExp
          val _ = CST.globalType newConsExpTy
          val (newNewTailExp, newNewTailExpTy) = inferExp context newTailExp
          val _ = CST.globalType newNewTailExpTy
          val newConsRecordTy = CST.convertGlobalType consRecordTy
          val newListTy = CST.convertGlobalType listTy
        in
          (
           ACSETTAIL
               {
                consExp = newConsExp,
                newTailExp = newNewTailExp,
                listTy = newListTy,
                consRecordTy = newConsRecordTy,
                tailLabel = tailLabel,
                loc = loc
               },
           AT.unitty
          )
        end

      | TL.TLARRAY {sizeExp, initialValue, elementTy, isMutable, loc} =>
        let
          val (newSizeExp, _) = inferExp context sizeExp
          val (newInitialValue, newInitialValueTy) =
              inferExp context initialValue
          (* array's elements should be single value, their outermost type
           * constructer should be boxed (if this is record or function)
           *)
          val _ = CST.singleValueType newInitialValueTy
          val newArrayTy = AT.arrayty newInitialValueTy
        in
          (
           ACARRAY
               {
                sizeExp = newSizeExp,
                initialValue = newInitialValue,
                elementTy = newInitialValueTy,
                isMutable = isMutable,
                loc = loc
               },
           newArrayTy
          )
        end

      | TL.TLCOPYARRAY
        {srcExp, srcIndexExp, dstExp,
         dstIndexExp, lengthExp, elementTy, loc} =>
        let
          val (newSrcExp, srcTy) = inferExp context srcExp
          val newSrcElementTy = ATU.arrayElementTy srcTy
          val (newSrcIndexExp, _) = inferExp context srcIndexExp
          val (newDstExp, dstTy) = inferExp context dstExp
          val newDstElementTy = ATU.arrayElementTy dstTy
          val (newDstIndexExp, _) = inferExp context dstIndexExp
          val _ = CST.unify (newSrcElementTy, newDstElementTy)
              handle CST.Unify =>
              (printTlexp tlexp;
               raise bug "unification fail(2)")
          (* ToDo : Should we unify elementTy and newSrcElementTy ? *)
          val (newLengthExp, _) = inferExp context lengthExp
        in
          (
           ACCOPYARRAY
               {
                 srcExp = newSrcExp,
                 srcIndexExp = newSrcIndexExp, 
                 dstExp = newDstExp,
                 dstIndexExp = newDstIndexExp,
                 lengthExp = newLengthExp,
                 elementTy = newSrcElementTy,
                 loc = loc
               },
           AT.unitty
          )
        end

      | TL.TLPRIMAPPLY {primInfo as {name, ty}, argExpList, instTyList, loc} =>
        let
          val (newArgExpList, newArgTyList) = inferExpList context argExpList
          val _ = List.app CST.globalType newArgTyList
          val resultTy =
              case ty of 
                T.FUNMty (_, bodyTy) => CST.convertGlobalType bodyTy
              | _ => raise Control.Bug "function type is expected"
          val newPrimInfo =
              {
               name = name, 
               ty = AT.FUNMty
                      {
                       argTyList = newArgTyList, 
                       bodyTy = resultTy, 
                       funStatus = ATU.newClosureFunStatus(),
                       annotation = ref {labels = AT.LE_GENERIC, boxed = true}
                      }
              }
          val newInstTyList = map CST.convertSingleValueType instTyList
        in
          (
           ACPRIMAPPLY
               {
                primInfo = newPrimInfo,
                argExpList = newArgExpList,
                instTyList = newInstTyList,
                loc = loc
               },
           resultTy
          )
        end

      | TL.TLAPPM {funExp, funTy, argExpList, loc} =>
        let
          val (newFunExp, newFunTy) = inferExp context funExp
          val (newArgExpList, newArgTyList) = inferExpList context argExpList
          val {argTyList, bodyTy, ...} = ATU.expandFunTy newFunTy
          val _ = (ListPair.app CST.unify (argTyList, newArgTyList) )
              handle CST.Unify =>
                       (printTlexp tlexp;
                        raise bug "unification fail(3)")
        in
          (
           ACAPPM
               {
                funExp = newFunExp,
                funTy = newFunTy,
                argExpList = newArgExpList,
                loc = loc
               },
           bodyTy
          )
        end

      | TL.TLLET {localDeclList, mainExp, loc} =>
        let
          val (newLocalDeclList, newContext) =
              inferDeclList context localDeclList
          val (newMainExp, newMainExpTy) = inferExp newContext mainExp
        in
          (
           ACLET
               {
                localDeclList = newLocalDeclList,
                mainExp = newMainExp,
                loc = loc
               },
           newMainExpTy
          )
        end

      | TL.TLRECORD {expList, recordTy, isMutable, loc} =>
        let
          val (newExpList, newExpTyList) = inferExpList context expList
          val flty = case TU.derefTy recordTy of
                       T.RECORDty flty => flty
                     | _ => raise Control.Bug "record type is expected"
          val newFlty =
              ListPair.foldl
                  (fn (l,ty,S) => SEnv.insert(S,l,ty))
                  (SEnv.empty)
                  (SEnv.listKeys flty, newExpTyList)
          val annotationLabel = ATU.freshAnnotationLabel ()
          (* local record may not need to be boxed and aligned*)
          val annotationRef = 
              ref 
                  {
                   labels = AT.LE_LABELS (ISet.singleton(annotationLabel)),
                   boxed = false,
                   align = false
                  }
          val newRecordTy = 
              AT.RECORDty
                  {
                   fieldTypes = newFlty,
                   annotation = annotationRef
                  }
        in
          (
           ACRECORD
               {
                expList = newExpList,
                recordTy = newRecordTy,
                annotation = annotationLabel,
                loc = loc,
                isMutable = isMutable
               },
           newRecordTy
          )
        end

      | TL.TLSELECT {recordExp, label, recordTy, resultTy, loc} =>
        let
          val (newRecordExp, newRecordTy) = inferExp context recordExp
          val resultTy = CTX.fieldType context (newRecordTy, label)
        in
          (
           ACSELECT
               {
                recordExp = newRecordExp,
                label = label,
                recordTy = newRecordTy,
                resultTy = resultTy,
                loc = loc
               },
           resultTy
          )
        end

      | TL.TLMODIFY {recordExp, recordTy, label, valueExp, loc} =>
        let
          val (newRecordExp, newRecordTy) = inferExp context recordExp
          (* record expression to be updated can not be multiple values*)
          val _ = CST.singleValueType newRecordTy
          val (newValueExp, newValueTy) = inferExp context valueExp
          (* updated value can not be multiple values *)
          val _ = CST.singleValueType newValueTy
          val newFieldTy = CTX.fieldType context (newRecordTy, label)
          val _ = CST.unify (newValueTy, newFieldTy)
              handle CST.Unify =>
                       (printTlexp tlexp;
                        raise bug "unification fail(4)")

        in
          (
           ACMODIFY
               {
                recordExp = newRecordExp,
                recordTy = newRecordTy,
                label = label,
                valueExp = newValueExp,
                valueTy = newValueTy,
                loc = loc
               },
           newRecordTy
          )
        end

      | TL.TLRAISE {argExp, resultTy, loc} =>
        let
          val (newArgExp, expTy) = inferExp context argExp
          (* exception argument should have global type*)
          val _ = CST.globalType expTy   (*???*)
          val newResultTy = CST.convertLocalType resultTy
        in
          (
           ACRAISE
               {
                argExp = newArgExp,
                resultTy = newResultTy,
                loc = loc
               },
           newResultTy
          )
        end

      | TL.TLHANDLE {exp, exnVar as {displayName, ty, varId}, handler, loc} =>
        let
          val (newExp, newExpTy) = inferExp context exp
          val newExnVar = 
              {displayName = displayName, ty = CST.convertGlobalType ty,
               varId = varId}
          val newContext = CTX.insertVariable context newExnVar
          val (newHandler, newHandlerTy) = inferExp newContext handler
          val _ = CST.unify(newExpTy, newHandlerTy)
              handle CST.Unify =>
                       (printTlexp tlexp;
                        raise bug "unification fail(5)")

        in
          (
           ACHANDLE
               {
                exp = newExp,
                exnVar = newExnVar,
                handler = newHandler,
                loc = loc
               },
           newExpTy
          )
        end

      | TL.TLFNM {argVarList, bodyTy, bodyExp, loc} =>
        let
          val newArgVarList =
              map 
                  (fn {displayName, ty, varId} =>
                      {displayName = displayName,
                       ty = CST.convertLocalType ty,
                       varId = varId}
                  )
                  argVarList
          val newContext = CTX.insertVariables context newArgVarList
          val (newBodyExp, newBodyTy) = inferExp newContext bodyExp
          val annotationLabel = ATU.freshAnnotationLabel ()
          (* local function may not need to be boxed*)
          val annotationRef = 
              ref 
                  {
                   labels = AT.LE_LABELS (ISet.singleton(annotationLabel)),
                   boxed = false
                  }
          val newFunTy = AT.FUNMty
                             {
                              argTyList = map #ty newArgVarList,
                              bodyTy = newBodyTy,
                              funStatus = ATU.newClosureFunStatus(),
                              annotation = annotationRef
                             }
        in
          (
           ACFNM
               {
                argVarList = newArgVarList,
                funTy = newFunTy,
                bodyExp = newBodyExp,
                annotation = annotationLabel,
                loc = loc
               },
           newFunTy
          )
        end

      | TL.TLPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        let
          val newBtvEnv = CST.convertLocalBtvEnv btvEnv
          val newContext = CTX.insertBtvEnv context newBtvEnv
          val (newExp, newTy) = inferExp newContext exp
          val resultTy = AT.POLYty{boundtvars = newBtvEnv, body = newTy}
        in
          (
           ACPOLY
               {
                btvEnv = newBtvEnv,
                expTyWithoutTAbs = newTy,
                exp = newExp, 
                loc = loc
               },
           resultTy
          )
        end

      | TL.TLTAPP {exp, expTy, instTyList, loc} =>
        let
          val (newExp, newExpTy) = inferExp context exp
          (* type variables are single value types, their instances should
           * also be single value types
           *)
          val newInstTyList = map CST.convertSingleValueType instTyList
          val tvars = case newExpTy of
                        AT.POLYty {boundtvars,...} => boundtvars
                      | _ => raise Control.Bug "polytype is expected"
          val _ = CST.addInstances (tvars, newInstTyList)
          val resultTy = ATU.tpappTy(newExpTy, newInstTyList)
        in
          (
           ACTAPP
               {
                exp = newExp,
                expTy = newExpTy,
                instTyList = newInstTyList,
                loc = loc
               },
           resultTy
          )
        end

      | TL.TLSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        let
          val (newSwitchExp, newSwitchTy) = inferExp context switchExp
          val (newDefaultExp, newDefaultTy) = inferExp context defaultExp
          fun proceedBranch {constant, exp} =
              let
                val (newConst, _) = inferExp context constant 
                val (newExp, newTy) = inferExp context exp
                val _ = CST.unify (newDefaultTy, newTy)
                    handle CST.Unify =>
                           (printTlexp tlexp;
                            raise bug "unification fail(6)")
              in
                {constant = newConst, exp = newExp}
              end
        in
          (
           ACSWITCH
               {
                switchExp = newSwitchExp,
                expTy = newSwitchTy,
                branches = map proceedBranch branches,
                defaultExp = newDefaultExp,
                loc = loc
               },
           newDefaultTy
          )
        end

      (* generic cast: both source type and target type should be global type*)
      | TL.TLCAST {exp, targetTy, loc} => 
        let
          val (newExp, newExpTy) = inferExp context exp
          val _ = CST.globalType newExpTy
          val newTargetTy = CST.convertGlobalType targetTy
        in
          (
           ACCAST
               {
                exp = newExp,
                expTy = newExpTy,
                targetTy = newTargetTy,
                loc = loc
               },
           newTargetTy
          )
        end

  and inferExpList context expList =
      ListPair.unzip (map (inferExp context) expList)
                                       
  and inferDecl context tldecl =
      case tldecl of
        TL.TLVAL {boundVar as {displayName, ty, varId as T.INTERNAL _},
                  boundExp, loc} =>
        let
          val (newBoundExp, newBoundTy) = inferExp context boundExp
          val newBoundVar = {displayName = displayName,
                             ty = newBoundTy, varId = varId}
          val newContext = CTX.insertVariable context newBoundVar
        in
          (ACVAL {boundVar = newBoundVar, boundExp = newBoundExp, loc = loc},
           newContext)
        end

      | TL.TLVAL {boundVar as {displayName, ty, varId as T.EXTERNAL _},
                  boundExp, loc} =>
        let
          val (newBoundExp, newBoundTy) = inferExp context boundExp
          val _ = CST.globalType newBoundTy
          val newBoundVar = {displayName = displayName,
                             ty = newBoundTy, varId = varId}
          val newContext = CTX.insertVariable context newBoundVar
        in
          (ACVAL {boundVar = newBoundVar, boundExp = newBoundExp, loc = loc},
           newContext)
        end

      | TL.TLVALREC {recbindList, loc} =>
        let
          val newBoundVarList =
              map
                (fn {boundVar
                       as {displayName, ty, varId as T.INTERNAL _},...} =>
                    {displayName = displayName, ty = CST.convertLocalType ty,
                     varId = varId}
                  | {boundVar
                       as {displayName, ty, varId as T.EXTERNAL _},...} =>
                    {displayName = displayName, ty = CST.convertGlobalType ty,
                     varId = varId}
                  )
                  recbindList
          val newContext = CTX.insertVariables context newBoundVarList
          fun inferBind ({boundVar, boundExp}, newBoundVar : varInfo) =
              let
                val (newBoundExp, newBoundTy) = inferExp newContext boundExp
                val _ = CST.unify (newBoundTy, #ty newBoundVar)
                    handle CST.Unify =>
                           (printTldecl tldecl;
                            raise bug "unification fail(7)")

              in
                {boundVar = newBoundVar, boundExp = newBoundExp}
              end
        in
          (
           ACVALREC
             {
              recbindList = ListPair.map
                              inferBind (recbindList, newBoundVarList),
                loc = loc
               },
           newContext
          )
        end

      | TL.TLVALPOLYREC {btvEnv, recbindList, loc} =>
        let
          val newBtvEnv = CST.convertLocalBtvEnv btvEnv
          val newBoundVarList =
              map 
                (fn {boundVar as {displayName, ty, varId},...} =>
                    {displayName = displayName, ty = CST.convertLocalType ty,
                     varId = varId}
                  )
                  recbindList
          val newContext =
              CTX.insertVariables
                (CTX.insertBtvEnv context newBtvEnv)
                newBoundVarList
          fun inferBind ({boundExp,boundVar}, newBoundVar : varInfo) =
              let
                val (newBoundExp, newBoundTy) = inferExp newContext boundExp
                val _ = CST.unify (newBoundTy, #ty newBoundVar)
                    handle CST.Unify =>
                           (printTlexp boundExp;
                            raise bug "unification fail(8)")

              in
                {boundVar = newBoundVar, boundExp = newBoundExp}
              end
          val recbindList =
              ListPair.map inferBind (recbindList, newBoundVarList)
          val newBoundVarList = 
              map
                (fn {displayName, ty, varId} =>
                    let
                      val ty = AT.POLYty {boundtvars = newBtvEnv, body = ty}
                      val _ = 
                          case varId of 
                            T.EXTERNAL _ => CST.globalType ty
                          | _ => ()
                    in
                      {
                       displayName = displayName,
                       ty = ty,
                       varId = varId
                      }
                    end
                )
                newBoundVarList
          val newContext = CTX.insertVariables context newBoundVarList
        in
          (
           ACVALPOLYREC
             {
              btvEnv = newBtvEnv,
              recbindList = recbindList,
              loc = loc
             },
           newContext
          )
        end

  and inferDeclList context ([]) = ([],context)
    | inferDeclList context (decl::rest) =
      let
        val (newDecl, newContext) = inferDecl context decl
        val (newRest, newContext) = inferDeclList newContext rest
      in
        (newDecl::newRest, newContext)
      end

  fun inferBasicBlock context basicBlock =
      case basicBlock of
          TL.TLVALBLOCK {code, exnIDSet} =>
          let
              val (newCode, newContext) = inferDeclList context code
          in
              (ACVALBLOCK {code = newCode, exnIDSet = exnIDSet},
               newContext)
          end
        | TL.TLLINKFUNCTORBLOCK
            {name, actualArgName,
             typeResolutionTable,
             exnTagResolutionTable, 
             externalVarIDResolutionTable,
             refreshedExceptionTagTable, 
             refreshedExternalVarIDTable, loc} => 
          (ACLINKFUNCTORBLOCK
             {name = name,
              actualArgName = actualArgName, 
              typeResolutionTable = 
                TyConID.Map.map (CST.convertTyBindInfo) typeResolutionTable, 
              exnTagResolutionTable = exnTagResolutionTable, 
              externalVarIDResolutionTable = externalVarIDResolutionTable, 
              refreshedExceptionTagTable = refreshedExceptionTagTable, 
              refreshedExternalVarIDTable = refreshedExternalVarIDTable, 
              loc = loc},
           context)

  fun inferTopBlock context topBlock =
      case topBlock of
        TL.TLBASICBLOCK basicBlock => 
        let
          val (basicBlock, context) = inferBasicBlock context basicBlock
        in
          (ACBASICBLOCK basicBlock, context)
        end
      | TL.TLFUNCTORBLOCK
          {name, formalAbstractTypeIDSet, formalVarIDSet, formalExnIDSet, 
           generativeExnIDSet,generativeVarIDSet, bodyCode} => 
        let
          val originalMode =  !Control.doFunctorCompile
          val _ = Control.doFunctorCompile := true
          val (newBodyCode, newContext) = inferBasicBlockList context bodyCode
          val _ = Control.doFunctorCompile := originalMode
        in
          (ACFUNCTORBLOCK{name = name, 
                          formalAbstractTypeIDSet = formalAbstractTypeIDSet, 
                          formalVarIDSet = formalVarIDSet,
                          formalExnIDSet = formalExnIDSet, 
                          generativeExnIDSet = generativeExnIDSet,
                          generativeVarIDSet = generativeVarIDSet,
                          bodyCode = newBodyCode}, 
           newContext)
          end

  and inferBasicBlockList context ([]) = ([], context)
    | inferBasicBlockList context (basicBlock::rest) =
      let
        val (newBasicBlock, newContext) = inferBasicBlock context basicBlock
        val (newRest, newContext) = inferBasicBlockList newContext rest
      in
        (newBasicBlock :: newRest, newContext)
      end

  fun inferTopBlockList context ([]) = ([], context)
    | inferTopBlockList context (topBlock::rest) =
      let
        val (newTopBlock, newContext) = inferTopBlock context topBlock
        val (newRest, newContext) = inferTopBlockList newContext rest
      in
        (newTopBlock :: newRest, newContext)
      end

  fun analyse groupList =
      let
        val _ = ATU.initialize ()
        val _ = CST.initialize ()
        val (newTopBlockList, _ ) = inferTopBlockList CTX.empty groupList
        val _ = CST.solve ()
      in
          newTopBlockList
      end
      handle exn => raise exn

end
