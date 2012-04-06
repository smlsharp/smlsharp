(**
 * Static Analysis
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure StaticAnalysis : sig

  val analyse : TypedLambda.tldecl list -> AnnotatedCalc.acdecl list

end =
struct

  structure T = Types
  structure TU = TypesUtils
  structure AT = AnnotatedTypes
  structure ATU = AnnotatedTypesUtils
  structure TL = TypedLambda
  structure CTX = SAContext
  structure CST = SAConstraint
  structure CT = ConstantTerm
  open AnnotatedCalc
  fun printAtexp atexp = 
      print (AnnotatedCalcFormatter.acexpToString atexp)
      
  fun printTlexp tlexp =
      (
       print (Control.prettyPrint (TL.format_tlexp [] tlexp));
       print "\n"
      )
  fun printATty aty =
      (
       print (Control.prettyPrint (AT.format_ty aty));
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
        TL.TLFOREIGNAPPLY {funExp, foreignFunTy, argExpList, loc} =>
        let
          val (newFunExp, _) = inferExp context funExp
          val (newArgExpList, newArgTyList) = inferExpList context argExpList
          (* arguments/return values, which are passed and received from
           * a foreign function should have global type, e.g. record should 
           * boxed and aligned
           *)
          val _ = List.app CST.globalType newArgTyList
          val bodyTy = CST.convertGlobalType (#resultTy foreignFunTy)
          val newForeignFunTy =
                {
                 argTyList = newArgTyList, 
                 resultTy = bodyTy,
                 attributes = #attributes foreignFunTy
                }
        in
          (
           ACFOREIGNAPPLY
             {
              funExp = newFunExp,
              foreignFunTy = newForeignFunTy,
              argExpList  = newArgExpList,
              loc = loc
             },
           bodyTy
          )
        end

      | TL.TLEXPORTCALLBACK {funExp, foreignFunTy, loc} =>
        let
          val (newFunExp, newFunTy) = inferExp context funExp
          (* export function should have global type*)
          val _ = CST.globalType newFunTy
          val {argTyList, bodyTy, ...} = ATU.expandFunTy newFunTy
        in
          (
           ACEXPORTCALLBACK
               {
                funExp = newFunExp,
                foreignFunTy = {argTyList = argTyList,
                                resultTy = bodyTy,
                                attributes = #attributes foreignFunTy},
                loc = loc
               },
           AT.foreignfunty
          )
        end

      | TL.TLCONSTANT (v as {value, loc}) =>
        (ACCONSTANT v, ATU.constDefaultTy value)
      | TL.TLGLOBALSYMBOL {name,kind,ty,loc} =>
        let
          val newTy = CST.convertGlobalType ty
        in
          (ACGLOBALSYMBOL {name=name, kind=kind, ty=newTy, loc=loc}, newTy)
        end
      | TL.TLTAGOF {ty, loc} =>
        let
          val newTy = CST.convertLocalType ty
        in
          (ACTAGOF {ty = newTy, loc = loc}, AT.SINGLETONty (AT.TAGty newTy))
        end
      | TL.TLSIZEOF {ty, loc} =>
        let
          val newTy = CST.convertLocalType ty
        in
          (ACSIZEOF {ty = newTy, loc = loc}, AT.SINGLETONty (AT.SIZEty newTy))
        end
      | TL.TLINDEXOF {label, recordTy, loc} =>
        let
          val newRecordTy = CST.convertLocalType recordTy
        in
          (ACINDEXOF {label=label, recordTy=newRecordTy, loc=loc},
           AT.SINGLETONty (AT.INDEXty (label, newRecordTy)))
        end
      | TL.TLVAR {varInfo, loc} => 
        (* local variable*)
        let
          val newVarInfo =
              CTX.lookupVariable context varInfo loc
        in
          (ACVAR{varInfo = newVarInfo, loc = loc}, #ty newVarInfo)
        end

      | TL.TLEXVAR {exVarInfo, loc} =>
        (* gloval variable *)
        let
          val newExVarInfo = CTX.lookupExVar context exVarInfo loc
        in
          (ACEXVAR{exVarInfo = newExVarInfo, loc = loc}, #ty newExVarInfo)
        end
        
      | TL.TLPRIMAPPLY
          {primInfo as {primitive,ty},argExpList,instTyList,loc} =>
        let
          val (newArgExpList, newArgTyList) = inferExpList context argExpList
          val primTy = CST.convertGlobalType ty
          (* primitive arguments may be passed to runtime functions
           * implemented in C. *)
          val newInstTyList = map CST.convertGlobalType instTyList
          val instTy = ATU.tpappTy (primTy, newInstTyList)
          val {argTyList=instArgTyList, bodyTy, ...} = ATU.expandFunTy instTy
          val _ = ListPair.app CST.unify (instArgTyList, newArgTyList)
        in
          (
           ACPRIMAPPLY
               {
                primInfo = {primitive = primitive, ty = primTy},
                argExpList = newArgExpList,
                instTyList = newInstTyList,
                loc = loc
               },
           bodyTy
          )
        end

      | TL.TLAPPM {funExp, funTy, argExpList, loc} =>
        let
          val (newFunExp, newFunTy) = inferExp context funExp
          val (newArgExpList, newArgTyList) = inferExpList context argExpList
          val {argTyList, bodyTy, ...} = ATU.expandFunTy newFunTy
              handle (e as Control.Bug _) => 
                    (print "expandFunTy fails\n";
                     print "tlexp:\n";
                     printTlexp tlexp;
                     print "funTy:\n";
                     T.printTy funTy;
                     print "\n";
                     print "funExp:\n";
                     printTlexp funExp;
                     print "newfunExp:\n";
                     printAtexp newFunExp;
                     print "\n";
                     print "newFunTy:\n";
                     printATty newFunTy;
                     print "\n";
                     raise e
                    )
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

      | TL.TLRECORD {fields, recordTy, isMutable, loc} =>
        let
          val (labels, expList) = ListPair.unzip (LabelEnv.listItemsi fields)
          val (newExpList, newExpTyList) = inferExpList context expList
          val newFields =
              ListPair.mapEq
                (fn (label, exp) => {label = label, fieldExp = exp})
                (labels, newExpList)
          val newFlty =
              ListPair.foldl
                  (fn (l,ty,S) => LabelEnv.insert(S,l,ty))
                  (LabelEnv.empty)
                  (labels, newExpTyList)
          val annotationLabel = AnnotationLabelID.generate ()
          (* local record may not need to be boxed and aligned*)
          val annotationRef = 
              ref 
                  {
                   labels =
                   AT.LE_LABELS
                     (AnnotationLabelID.Set.singleton(annotationLabel)),
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
                fields = newFields,
                recordTy = newRecordTy,
                annotation = annotationLabel,
                loc = loc,
                isMutable = isMutable
               },
           newRecordTy
          )
        end

      | TL.TLSELECT {recordExp, indexExp, label, recordTy, resultTy, loc} =>
        let
          val (newRecordExp, newRecordTy) = inferExp context recordExp
          val (newIndexExp, newIndexTy) = inferExp context indexExp
          val indexTy = AT.SINGLETONty (AT.INDEXty (label, newRecordTy))
          val _ = CST.unify (newIndexTy, indexTy)
              handle CST.Unify =>
                     (print "TLSELECT: unification fail\n";
                      print "tlexp\n";
                      printTlexp tlexp;
                      print "recordExp\n";
                      printTlexp recordExp;
                      print "indexExp\n";
                      printTlexp indexExp;
                      print "recordTy\n";
                      T.printTy recordTy;
                      print "\n";
                      print "newRecordTy\n";
                      printATty newRecordTy;
                      print "\n";
                      print "indexTy\n";
                      printATty indexTy;
                      print "\n";
                      print "newIndexTy\n";
                      printATty newIndexTy;
                      print "\n";
                      raise bug "TLSELECT: unification fail")

          val resultTy = CTX.fieldType context (newRecordTy, label)
        in
          (
           ACSELECT
               {
                recordExp = newRecordExp,
                indexExp = newIndexExp,
                label = label,
                recordTy = newRecordTy,
                resultTy = resultTy,
                loc = loc
               },
           resultTy
          )
        end

      | TL.TLMODIFY {recordExp, recordTy, indexExp, label, valueExp, loc} =>
        let
          val (newRecordExp, newRecordTy) = inferExp context recordExp
          (* record expression to be updated can not be multiple values*)
          val _ = CST.singleValueType newRecordTy
          val (newValueExp, newValueTy) = inferExp context valueExp
          (* updated value can not be multiple values *)
          val _ = CST.singleValueType newValueTy
          val (newIndexExp, newIndexTy) = inferExp context indexExp
          val _ = CST.singleValueType newIndexTy
          val indexTy = AT.SINGLETONty (AT.INDEXty (label, newRecordTy))
          val _ = CST.unify (newIndexTy, indexTy)
              handle CST.Unify => raise bug "TLSELECT: unification fail"
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
                indexExp = newIndexExp,
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

      | TL.TLHANDLE {exp, exnVar as {path, ty, id}, handler, loc} =>
        let
          val (newExp, newExpTy) = inferExp context exp
          val newExnVar = 
              {path = path, ty = CST.convertGlobalType ty, id = id}
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
                  (fn {path, ty, id} =>
                      {path = path,
                       ty = CST.convertLocalType ty,
                       id = id}
                  )
                  argVarList
          val newContext = CTX.insertVariables context newArgVarList
          val (newBodyExp, newBodyTy) = inferExp newContext bodyExp
          val annotationLabel = AnnotationLabelID.generate ()
          (* local function may not need to be boxed*)
          val annotationRef = 
              ref 
                  {
                   labels =
                   AT.LE_LABELS
                     (AnnotationLabelID.Set.singleton(annotationLabel)),
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
(*
          val _ = CST.addInstances (tvars, newInstTyList)
*)
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
                val (newExp, newTy) = inferExp context exp
                val _ = CST.unify (newDefaultTy, newTy)
                    handle 
                    CST.Unify =>
                    (print "unification fail(6)\n";
                     print "tlexp\n";
                     printTlexp tlexp;
                     print "exp\n";
                     printTlexp exp;
                     print "defaultExp\n";
                     printTlexp defaultExp;
                     print "\n";
                     raise bug "unification fail(6)"
                    )
              in
                {constant = constant, exp = newExp}
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
        TL.TLVAL {boundVar as {path, ty, id},
                  boundExp, loc} =>
        let
          val (newBoundExp, newBoundTy) = inferExp context boundExp
          val newBoundVar = {path = path, ty = newBoundTy, id = id}
          val newContext = CTX.insertVariable context newBoundVar
        in
          (ACVAL {boundVar = newBoundVar, boundExp = newBoundExp, loc = loc},
           newContext)
        end

      | TL.TLEXPORTVAR (varInfo as {path,...}, loc) =>
        let
          val {id, ty, ...} = CTX.lookupVariable context varInfo loc
          val _ = CST.globalType ty
          val newVar = {path = path, id = id, ty = ty}
        in
          (ACEXPORTVAR {varInfo = newVar, loc = loc}, context)
        end

      | TL.TLEXTERNVAR ({path, ty}, loc) =>
        let
          val newTy = CST.convertGlobalType ty
          val newVar = {path = path, ty = newTy}
          val newContext = CTX.insertExVar context newVar
        in
          (ACEXTERNVAR {exVarInfo = newVar, loc = loc}, newContext)
        end

      | TL.TLVALREC {recbindList, loc} =>
        let
          val newBoundVarList =
              map
                (fn {boundVar={path, ty, id},...} =>
                    {path = path, ty = CST.convertLocalType ty, id = id})
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

  and inferDeclList context ([]) = ([],context)
    | inferDeclList context (decl::rest) =
      let
        val (newDecl, newContext) = inferDecl context decl
        val (newRest, newContext) = inferDeclList newContext rest
      in
        (newDecl::newRest, newContext)
      end

  fun analyse decls =
      let
        val _ = CST.initialize ()
        val (decls, _) = inferDeclList CTX.empty decls
        val _ = CST.solve ()
      in
        decls
      end
end
