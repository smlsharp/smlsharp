(**
 * useless code elimination
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $Id: UselessCodeElimination.sml,v 1.19 2008/02/23 15:49:54 bochao Exp $
 *)
structure UselessCodeElimination (* : USELESSCODEELIMINATION *) = 
struct
  structure T = Types
  open MultipleValueCalc

  fun containEffectInPrimitive (primInfo : MultipleValueCalc.primInfo) =
      BuiltinPrimitiveUtils.hasEffect (#name primInfo) orelse
      (case BuiltinPrimitiveUtils.raisesException (#name primInfo) of
         nil => false | _::_ => true)

  fun containEffectInExp exp =
      case exp of
        MVFOREIGNAPPLY _ => true
      | MVEXPORTCALLBACK _ => true
      | MVTAGOF _ => false
      | MVSIZEOF _ => false
      | MVINDEXOF _ => false
      | MVCONSTANT _ => false
      | MVGLOBALSYMBOL _ => false
      | MVEXCEPTIONTAG _ => false
      | MVVAR _ => false
      | MVGETFIELD _ => false
      | MVSETFIELD _ => true
      | MVSETTAIL _ => true
      | MVARRAY {sizeExp, initialValue, elementTy, isMutable, loc} => containEffectInExpList [sizeExp,initialValue]
      | MVCOPYARRAY _ => true
      | MVPRIMAPPLY {primInfo, argExpList, instTyList, loc} =>
        (containEffectInPrimitive primInfo) orelse (containEffectInExpList argExpList)
      | MVAPPM {funExp, funTy, argExpList, loc} => true (* temporary *)
      | MVLET {localDeclList, mainExp, loc} =>
        (containEffectInDeclList localDeclList) orelse (containEffectInExp mainExp)
      | MVMVALUES {expList, tyList, loc} => containEffectInExpList expList
      | MVRECORD {expList, recordTy, annotation, isMutable, loc} => containEffectInExpList expList
      | MVSELECT {recordExp, indexExp, label, recordTy, resultTy, loc} =>
        (containEffectInExp recordExp) orelse (containEffectInExp indexExp)
      | MVMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy, loc} =>
        containEffectInExpList [recordExp,indexExp,valueExp]
      | MVRAISE {argExp, resultTy, loc} => true
      | MVHANDLE {exp, exnVar, handler, loc} => true (*temporary*)
      | MVFNM {argVarList, funTy, bodyExp, annotation, loc} => false
      | MVPOLY {btvEnv, expTyWithoutTAbs, exp, loc} => containEffectInExp exp
      | MVTAPP {exp, expTy, instTyList, loc} => containEffectInExp exp
      | MVSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        let
          fun containEffectInBranches [] = false
            | containEffectInBranches ({constant,exp}::rest) = 
              (containEffectInExp exp) orelse (containEffectInBranches rest)
        in
          (containEffectInExpList [switchExp,defaultExp]) orelse (containEffectInBranches branches)
        end
      | MVCAST {exp, expTy, targetTy, loc} => containEffectInExp exp

  and containEffectInExpList [] = false
    | containEffectInExpList (exp::rest) =
      (containEffectInExp exp) orelse (containEffectInExpList rest)

  and containEffectInDecl decl =
      case decl of
        MVVAL {boundVars, boundExp,...} => 
        (AnnotatedTypesUtils.isGlobal (hd boundVars)) orelse containEffectInExp boundExp
      | MVVALREC _ => false

  and containEffectInDeclList [] = false
    | containEffectInDeclList (decl::rest) =
      (containEffectInDecl decl) orelse (containEffectInDeclList rest)

  fun eliminateExp vSet exp =
      case exp of
        MVFOREIGNAPPLY {funExp, funTy, argExpList, attributes, loc} =>
        let
          val (newFunExp, newVarIdSet) = eliminateExp vSet funExp
          val (newArgExpList,newVarIdSet) = eliminateExpList newVarIdSet argExpList
        in
          (
           MVFOREIGNAPPLY
               {
                funExp = newFunExp,
                funTy = funTy,
                argExpList = newArgExpList,
                attributes = attributes,
                loc = loc
               },
           newVarIdSet
          )
        end
      | MVEXPORTCALLBACK {funExp, funTy, attributes, loc} =>
        let
          val (newFunExp,newVarIdSet) = eliminateExp vSet funExp
        in
          (
           MVEXPORTCALLBACK
               {
                funExp = newFunExp,
                funTy = funTy,
                attributes = attributes,
                loc = loc
               },
           newVarIdSet
          )
        end
      | MVTAGOF _ => (exp,vSet)
      | MVSIZEOF _ => (exp,vSet)
      | MVINDEXOF _ => (exp,vSet)
      | MVCONSTANT _ => (exp,vSet)
      | MVGLOBALSYMBOL _ => (exp,vSet)
      | MVEXCEPTIONTAG _ => (exp,vSet)
      | MVVAR {varInfo as {varId,...},...} => (exp, VarIdSet.add(vSet,varId))
(*
      | MVGETFIELD {arrayExp, indexExp, elementTy, loc} =>
        let
          val (newArrayExp,newIndexExp,newVarIdSet) = eliminateExp2 vSet (arrayExp,indexExp)
        in
          (
           MVGETFIELD
               {
                arrayExp = newArrayExp,
                indexExp = newIndexExp,
                elementTy = elementTy,
                loc = loc
               },
           newVarIdSet
          )
        end
      | MVSETFIELD {valueExp, arrayExp, indexExp, elementTy, loc} =>
        let
          val (newArrayExp,newVarIdSet) = eliminateExp vSet arrayExp
          val (newIndexExp,newValueExp,newVarIdSet) =
              eliminateExp2 newVarIdSet (indexExp,valueExp)
        in
          (
           MVSETFIELD
               {
                valueExp = newValueExp,
                arrayExp = newArrayExp,
                indexExp = newIndexExp,
                elementTy = elementTy,
                loc = loc
               },
           newVarIdSet
          )
        end
      | MVSETTAIL{consExp, newTailExp, listTy, consRecordTy, tailLabel, loc} =>
        let
          val (newConsExp, newNewTailExp, newVarIdSet) =
              eliminateExp2 vSet (consExp,newTailExp)
        in
          (
           MVSETTAIL
               {
                consExp = newConsExp, 
                newTailExp = newNewTailExp, 
                tailLabel = tailLabel,
                listTy = listTy, 
                consRecordTy = consRecordTy, 
                loc = loc
               },
           newVarIdSet
          )
        end
      | MVARRAY {sizeExp, initialValue, elementTy, isMutable, loc} =>
        let
          val (newSizeExp,newInitialValue,newVarIdSet) = eliminateExp2 vSet (sizeExp,initialValue)
        in
          (
           MVARRAY
               {
                sizeExp = newSizeExp,
                initialValue = newInitialValue,
                elementTy = elementTy,
                isMutable = isMutable,
                loc = loc
               },
           newVarIdSet
          )
        end
      | MVCOPYARRAY
            {srcExp, srcIndexExp, dstExp, dstIndexExp, lengthExp, elementTy, loc} =>
        let
          val (newSrcExp, newSrcIndexExp, newVarIdSet) =
              eliminateExp2 vSet (srcExp, srcIndexExp)
          val (newDstExp, newDstIndexExp, newVarIdSet) =
              eliminateExp2 newVarIdSet (dstExp, dstIndexExp)
          val (newLengthExp, newVarIdSet) = eliminateExp newVarIdSet lengthExp
        in
          (
           MVCOPYARRAY
               {
                srcExp = newSrcExp,
                srcIndexExp = newSrcIndexExp,
                dstExp = newDstExp,
                dstIndexExp = newDstIndexExp,
                lengthExp = newLengthExp,
                elementTy = elementTy,
                loc = loc
               },
           newVarIdSet
          )
        end
*)
      | MVPRIMAPPLY {primInfo as {ty,...}, argExpList, instTyList, loc} =>
        let
          val (newArgExpList,newVarIdSet) = eliminateExpList vSet argExpList
        in
          (
           MVPRIMAPPLY
               {
                primInfo = primInfo,
                argExpList = newArgExpList,
                instTyList = instTyList,
                loc = loc
               },
           newVarIdSet
          )
        end

      | MVAPPM {funExp, funTy, argExpList, loc} =>
        let
          val (newFunExp,newVarIdSet) = eliminateExp vSet funExp
          val (newArgExpList,newVarIdSet) = eliminateExpList newVarIdSet argExpList
        in
          (
           MVAPPM
               {
                funExp = newFunExp,
                funTy = funTy,
                argExpList = newArgExpList,
                loc = loc
               },
           newVarIdSet
          )
        end

      | MVLET {localDeclList, mainExp, loc} =>
        let
          val (newMainExp, newVarIdSet) = eliminateExp vSet mainExp
          val (newLocalDeclList, newVarIdSet) = eliminateDeclList newVarIdSet localDeclList 
        in
          case newLocalDeclList of
            [] => (newMainExp, newVarIdSet)
          | _ => (MVLET {localDeclList = newLocalDeclList, mainExp = newMainExp, loc = loc}, newVarIdSet)
        end
      | MVMVALUES {expList, tyList, loc} =>
        let
          val (newExpList, newVarIdSet) = eliminateExpList vSet expList
        in
          (
           MVMVALUES
               {
                expList = newExpList,
                tyList = tyList,
                loc = loc
               },
           newVarIdSet
          )
        end
      | MVRECORD {expList, recordTy, annotation, isMutable, loc} =>
        let
          val (newExpList, newVarIdSet) = eliminateExpList vSet expList
        in
          (
           MVRECORD
               {
                expList = newExpList,
                recordTy = recordTy,
                annotation = annotation,
                isMutable = isMutable,
                loc = loc
               },
           newVarIdSet
          )
        end
      | MVSELECT {recordExp, indexExp, label, recordTy, resultTy, loc} =>
        let
          val (newRecordExp,newVarIdSet) = eliminateExp vSet recordExp
          val (newIndexExp,newVarIdSet) = eliminateExp newVarIdSet indexExp
        in
          (
           MVSELECT
               {
                recordExp = newRecordExp,
                indexExp = indexExp,
                label = label,
                recordTy = recordTy,
                resultTy = resultTy,
                loc = loc
               },
           newVarIdSet
          )
        end
      | MVMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy, loc} =>
        let
          val (newRecordExp,newValueExp,newVarIdSet) =
              eliminateExp2 vSet (recordExp,valueExp)
          val (newIndexExp,newVarIdSet) = eliminateExp newVarIdSet indexExp
        in
          (
           MVMODIFY
               {
                recordExp = newRecordExp,
                recordTy = recordTy,
                indexExp = newIndexExp,
                label = label,
                valueExp = newValueExp,
                valueTy = valueTy,
                loc = loc
               },
           newVarIdSet
          )
        end
      | MVRAISE {argExp, resultTy, loc} =>
        let
          val (newArgExp,newVarIdSet) = eliminateExp vSet argExp
        in
          (
           MVRAISE
               {
                argExp = newArgExp,
                resultTy = resultTy,
                loc = loc
               },
           newVarIdSet
          )
        end
      | MVHANDLE {exp, exnVar as {varId,...}, handler, loc} =>
        let
          val (newExp,newHandler,newVarIdSet) = eliminateExp2 vSet (exp,handler)
        in
          (
           MVHANDLE
               {
                exp = newExp,
                exnVar = exnVar,
                handler = newHandler,
                loc = loc
               },
           (VarIdSet.delete(newVarIdSet,varId)) handle NotFound => newVarIdSet
          )
        end

      | MVFNM {argVarList, funTy, bodyExp, annotation, loc} =>
        let
          val (newBodyExp,newVarIdSet) = eliminateExp vSet bodyExp
          val newVarIdSet =
              foldl
                  (fn ({varId,...}, S) =>
                      (VarIdSet.delete(S,varId)) handle NotFound => S
                  )
                  newVarIdSet
                  argVarList
        in
          (
           MVFNM
               {
                argVarList = argVarList,
                funTy = funTy,
                bodyExp = newBodyExp,
                annotation = annotation,
                loc = loc
               },
           newVarIdSet
          )
        end

      | MVPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        let
          val (newExp,newVarIdSet) = eliminateExp vSet exp
        in
          (
           MVPOLY
               {
                btvEnv = btvEnv,
                expTyWithoutTAbs = expTyWithoutTAbs,
                exp = newExp,
                loc = loc
               },
           newVarIdSet
          )
        end
      | MVTAPP {exp, expTy, instTyList, loc} =>
        let
          val (newExp,newVarIdSet) = eliminateExp vSet exp
        in
          (
           MVTAPP
               {
                exp = newExp,
                expTy = expTy,
                instTyList = instTyList,
                loc = loc
               },
           newVarIdSet
          )
        end
      | MVSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        let
          val (newSwitchExp,newDefaultExp,newVarIdSet) = eliminateExp2 vSet (switchExp,defaultExp)
          val (newBranches, newVarIdSet) =
              foldr
                  (fn ({constant,exp},(L,S)) => 
                      let
                        val (newExp, newS) = eliminateExp S exp
                      in
                        ({constant = constant, exp = newExp}::L, newS)
                      end
                  )
                  ([],newVarIdSet)
                  branches
        in
          (
           MVSWITCH
               {
                switchExp = newSwitchExp,
                expTy = expTy,
                branches = newBranches,
                defaultExp = newDefaultExp,
                loc = loc
               },
           newVarIdSet
          )
        end
      | MVCAST {exp, expTy, targetTy, loc} =>
        let
          val (newExp,newVarIdSet) = eliminateExp vSet exp
        in
          (
           MVCAST
               {
                exp = newExp,
                expTy = expTy,
                targetTy = targetTy,
                loc = loc
               },
           newVarIdSet
          )
        end

  and eliminateExpList vSet [] = ([],vSet)
    | eliminateExpList vSet (exp::rest) =
      let
        val (newExp, newVarIdSet) = eliminateExp vSet exp
        val (newRest, newVarIdSet) = eliminateExpList newVarIdSet rest
      in
        ((newExp::newRest), newVarIdSet)
      end
  and eliminateExp2 vSet (exp1, exp2) = 
      let
        val (newExp1, newVarIdSet) = eliminateExp vSet exp1
        val (newExp2, newVarIdSet) = eliminateExp newVarIdSet exp2
      in
        (newExp1, newExp2, newVarIdSet)
      end

  and eliminateRecBindList vSet [] = ([], vSet)
    | eliminateRecBindList vSet ({boundVar, boundExp}::rest) =
      let
        val (newBoundExp, newVarIdSet) = eliminateExp vSet boundExp
        val (newRest, newVarIdSet) = eliminateRecBindList newVarIdSet rest
      in
        ({boundVar = boundVar, boundExp = newBoundExp}::newRest, newVarIdSet)
      end

  and eliminateDeclList vSet [] = ([], vSet)
    | eliminateDeclList vSet (decl::declList) =
      let
        val (newDeclList, newVarIdSet) = eliminateDeclList vSet declList
        fun boundVarsInRecBinds recbinds =
            foldl
                (fn ({boundVar, boundExp}, L) => boundVar::L)
                []
                recbinds
        fun globalInVars [] = false
          | globalInVars (({varId = T.EXTERNAL _,...}:varInfo)::rest) = true
          | globalInVars (({varId = T.INTERNAL _,...}:varInfo)::rest) = globalInVars rest
        fun varIdSet boundVarList =
            foldl
                (fn ({varId,...} : varInfo, S) => VarIdSet.add (S,varId))
                VarIdSet.empty
                boundVarList
      in
        case decl of
          MVVAL {boundVars, boundExp, loc} =>
          let
            val boundVarIdSet = 
                foldl (fn ({varId,...},S) => VarIdSet.add(S,varId)) VarIdSet.empty boundVars
            val (newBoundExp, newVarIdSet2) = eliminateExp newVarIdSet boundExp
          in
            if VarIdSet.isEmpty(VarIdSet.intersection(boundVarIdSet,newVarIdSet))
               andalso (not (containEffectInExp newBoundExp))
               andalso (not (AnnotatedTypesUtils.isGlobal (List.hd boundVars)))
            then (newDeclList, newVarIdSet)
            else
              (
               MVVAL{boundVars = boundVars, boundExp = newBoundExp, loc = loc}::newDeclList,
               newVarIdSet2
              )
          end

        | MVVALREC {recbindList, loc} =>
          let
            val boundVars = boundVarsInRecBinds recbindList
            val varIds = varIdSet boundVars
          in
            if (VarIdSet.isEmpty(VarIdSet.intersection(varIds,newVarIdSet)))
               andalso (not (globalInVars boundVars))
            then (newDeclList, newVarIdSet)
            else
              let
                val (newRecBindList, newVarIdSet) = eliminateRecBindList newVarIdSet recbindList
              in
                (
                 MVVALREC {recbindList = newRecBindList, loc = loc}::newDeclList,
                 VarIdSet.difference(newVarIdSet, varIds)
                )
              end
          end

      end
end
