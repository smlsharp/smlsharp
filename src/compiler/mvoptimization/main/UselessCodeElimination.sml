(**
 * useless code elimination
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure UselessCodeElimination : USELESSCODEELIMINATION = struct
  structure VSet = ID.Set
  open MultipleValueCalc

  fun containEffectInPrimitive {name, ty} = 
      case name of
        ":=" => true
      | "String_update" => true
      | "print" => true
      | "Array_update" => true
      | "GenericOS_getSTDIN" => true
      | "GenericOS_getSTDOUT" => true
      | "GenericOS_getSTDERR" => true
      | "GenericOS_fileOpen" => true
      | "GenericOS_fileClose" => true
      | "GenericOS_fileRead" => true
      | "GenericOS_fileReadBuf" => true
      | "GenericOS_fileWrite" => true
      | "GenericOS_fileSetPosition" => true
      | "GenericOS_fileGetPosition" => true
      | "GenericOS_fileNo" => true
      | "GenericOS_fileSize" => true

      | "GenericOS_poll" => true

      | "GenericOS_system" => true
      | "GenericOS_exit" => true
      | "GenericOS_sleep" => true

      | "GenericOS_openDir" => true
      | "GenericOS_readDir" => true
      | "GenericOS_rewindDir" => true
      | "GenericOS_closeDir" => true
      | "GenericOS_chDir" => true
      | "GenericOS_getDir" => true
      | "GenericOS_mkDir" => true
      | "GenericOS_rmDir" => true
      | "GenericOS_readLink" => true
      | "GenericOS_getFileModTime" => true
      | "GenericOS_setFileTime" => true
      | "GenericOS_getFileSize" => true
      | "GenericOS_remove" => true
      | "GenericOS_rename" => true
      | "GenericOS_tempFileName" => true
      | "GenericOS_getFileID" => true

      | "CommandLine_name" => true
      | "CommandLine_arguments" => true

      | "Date_ascTime" => true
      | "Date_localTime" => true
      | "Date_gmTime" => true
      | "Date_mkTime" => true
      | "Date_strfTime" => true

      | "Timer_getTime" => true

      | "StandardC_errno" => true

      | "UnmanagedMemory_allocate" => true
      | "UnmanagedMemory_release" => true
      | "UnmanagedMemory_sub" => true
      | "UnmanagedMemory_update" => true
      | "UnmanagedMemory_subWord" => true
      | "UnmanagedMemory_updateWord" => true
      | "UnmanagedMemory_subReal" => true
      | "UnmanagedMemory_updateReal" => true
      | "UnmanagedMemory_import" => true
      | "UnmanagedMemory_export" => true
      | "UnmanagedString_size" => true

      | "DynamicLink_dlopen" => true
      | "DynamicLink_dlclose" => true
      | "DynamicLink_dlsym" => true

      | "GC_addFinalizable" => true
      | "GC_doGC" => true
      | "GC_fixedCopy" => true
      | "GC_releaseFLOB" => true
      | _ => false


  fun containEffectInExp exp =
      case exp of
        MVFOREIGNAPPLY _ => true
      | MVEXPORTCALLBACK _ => true
      | MVSIZEOF _ => false
      | MVCONSTANT _ => false
      | MVEXCEPTIONTAG _ => false
      | MVVAR _ => false
      | MVGETGLOBAL _ => false
      | MVSETGLOBAL _ => true
      | MVINITARRAY _ => true
      | MVGETFIELD _ => false
      | MVSETFIELD _ => true
      | MVSETTAIL _ => true
      | MVARRAY {sizeExp, initialValue, elementTy, loc} => containEffectInExpList [sizeExp,initialValue]
      | MVPRIMAPPLY {primInfo, argExpList, loc} =>
        (containEffectInPrimitive primInfo) orelse (containEffectInExpList argExpList)
      | MVAPPM {funExp, funTy, argExpList, loc} => true (* temporary *)
      | MVLET {localDeclList, mainExp, loc} =>
        (containEffectInDeclList localDeclList) orelse (containEffectInExp mainExp)
      | MVMVALUES {expList, tyList, loc} => containEffectInExpList expList
      | MVRECORD {expList, recordTy, annotation, isMutable, loc} => containEffectInExpList expList
      | MVSELECT {recordExp, label, recordTy, loc} => containEffectInExp recordExp
      | MVMODIFY {recordExp, recordTy, label, valueExp, valueTy, loc} =>
        containEffectInExpList [recordExp,valueExp]
      | MVRAISE {argExp, resultTy, loc} => true
      | MVHANDLE {exp, exnVar as {id,...}, handler, loc} => true (*temporary*)
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
        MVVAL {boundExp,...} => containEffectInExp boundExp
      | MVVALREC _ => false
      | MVVALPOLYREC _ => false

  and containEffectInDeclList [] = false
    | containEffectInDeclList (decl::rest) =
      (containEffectInDecl decl) orelse (containEffectInDeclList rest)

  fun eliminateExp vSet exp =
      case exp of
        MVFOREIGNAPPLY {funExp, funTy, argExpList, convention, loc} =>
        let
          val (newFunExp::newArgExpList,newVSet) = eliminateExpList vSet (funExp::argExpList)
        in
          (
           MVFOREIGNAPPLY
               {
                funExp = newFunExp,
                funTy = funTy,
                argExpList = newArgExpList,
                convention = convention,
                loc = loc
               },
           newVSet
          )
        end
      | MVEXPORTCALLBACK {funExp, funTy, loc} =>
        let
          val (newFunExp,newVSet) = eliminateExp vSet funExp
        in
          (
           MVEXPORTCALLBACK
               {
                funExp = newFunExp,
                funTy = funTy,
                loc = loc
               },
           newVSet
          )
        end
      | MVSIZEOF _ => (exp,vSet)
      | MVCONSTANT _ => (exp,vSet)
      | MVEXCEPTIONTAG _ => (exp,vSet)
      | MVVAR {varInfo as {id,...},...} => (exp, VSet.add(vSet,id))
      | MVGETGLOBAL {arrayIndex, valueIndex, valueTy, loc} => (exp,vSet)
      | MVSETGLOBAL {arrayIndex, valueIndex, valueExp, valueTy, loc} =>
        let
          val (newValueExp,newVSet) = eliminateExp vSet valueExp
        in
          (
           MVSETGLOBAL
               {
                arrayIndex = arrayIndex,
                valueIndex = valueIndex,
                valueExp = newValueExp, 
                valueTy = valueTy,
                loc = loc
               },
           newVSet
          )
        end
      | MVINITARRAY {arrayIndex, size, elementTy, loc} => (exp,vSet)
      | MVGETFIELD {arrayExp, indexExp, elementTy, loc} =>
        let
          val ([newArrayExp,newIndexExp],newVSet) = eliminateExpList vSet [arrayExp,indexExp]
        in
          (
           MVGETFIELD
               {
                arrayExp = newArrayExp,
                indexExp = newIndexExp,
                elementTy = elementTy,
                loc = loc
               },
           newVSet
          )
        end
      | MVSETFIELD {valueExp, arrayExp, indexExp, elementTy, loc} =>
        let
          val ([newArrayExp,newIndexExp,newValueExp],newVSet) =
              eliminateExpList vSet [arrayExp,indexExp,valueExp]
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
           newVSet
          )
        end
      | MVSETTAIL{consExp, newTailExp, listTy, consRecordTy, tailLabel, loc} =>
        let
          val ([newConsExp, newNewTailExp],newVSet) =
              eliminateExpList vSet [consExp,newTailExp]
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
           newVSet
          )
        end
      | MVARRAY {sizeExp, initialValue, elementTy, loc} =>
        let
          val ([newSizeExp,newInitialValue],newVSet) = eliminateExpList vSet [sizeExp,initialValue]
        in
          (
           MVARRAY
               {
                sizeExp = newSizeExp,
                initialValue = newInitialValue,
                elementTy = elementTy,
                loc = loc
               },
           newVSet
          )
        end
      | MVPRIMAPPLY {primInfo as {ty,...}, argExpList, loc} =>
        let
          val (newArgExpList,newVSet) = eliminateExpList vSet argExpList
        in
          (
           MVPRIMAPPLY
               {
                primInfo = primInfo,
                argExpList = newArgExpList,
                loc = loc
               },
           newVSet
          )
        end

      | MVAPPM {funExp, funTy, argExpList, loc} =>
        let
          val (newFunExp::newArgExpList,newVSet) =
              eliminateExpList vSet (funExp::argExpList)
        in
          (
           MVAPPM
               {
                funExp = newFunExp,
                funTy = funTy,
                argExpList = newArgExpList,
                loc = loc
               },
           newVSet
          )
        end
      | MVLET {localDeclList, mainExp, loc} =>
        let
          val (newMainExp, newVSet) = eliminateExp vSet mainExp
          val (newLocalDeclList, newVSet) = eliminateDeclList newVSet localDeclList 
        in
          case newLocalDeclList of
            [] => (newMainExp, newVSet)
          | _ => (MVLET {localDeclList = newLocalDeclList, mainExp = newMainExp, loc = loc}, newVSet)
        end
      | MVMVALUES {expList, tyList, loc} =>
        let
          val (newExpList, newVSet) = eliminateExpList vSet expList
        in
          (
           MVMVALUES
               {
                expList = newExpList,
                tyList = tyList,
                loc = loc
               },
           newVSet
          )
        end
      | MVRECORD {expList, recordTy, annotation, isMutable, loc} =>
        let
          val (newExpList, newVSet) = eliminateExpList vSet expList
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
           newVSet
          )
        end
      | MVSELECT {recordExp, label, recordTy, loc} =>
        let
          val (newRecordExp,newVSet) = eliminateExp vSet recordExp
        in
          (
           MVSELECT
               {
                recordExp = newRecordExp,
                label = label,
                recordTy = recordTy,
                loc = loc
               },
           newVSet
          )
        end
      | MVMODIFY {recordExp, recordTy, label, valueExp, valueTy, loc} =>
        let
          val ([newRecordExp,newValueExp],newVSet) =
              eliminateExpList vSet [recordExp,valueExp]
        in
          (
           MVMODIFY
               {
                recordExp = newRecordExp,
                recordTy = recordTy,
                label = label,
                valueExp = newValueExp,
                valueTy = valueTy,
                loc = loc
               },
           newVSet
          )
        end
      | MVRAISE {argExp, resultTy, loc} =>
        let
          val (newArgExp,newVSet) = eliminateExp vSet argExp
        in
          (
           MVRAISE
               {
                argExp = newArgExp,
                resultTy = resultTy,
                loc = loc
               },
           newVSet
          )
        end
      | MVHANDLE {exp, exnVar as {id,...}, handler, loc} =>
        let
          val ([newExp,newHandler],newVSet) = eliminateExpList vSet [exp,handler]
        in
          (
           MVHANDLE
               {
                exp = newExp,
                exnVar = exnVar,
                handler = newHandler,
                loc = loc
               },
           (VSet.delete(newVSet,id)) handle NotFound => newVSet
          )
        end
      | MVFNM {argVarList, funTy, bodyExp, annotation, loc} =>
        let
          val (newBodyExp,newVSet) = eliminateExp vSet bodyExp
          val newVSet =
              foldl
                  (fn ({id,...}, S) =>
                      (VSet.delete(S,id)) handle NotFound => S
                  )
                  newVSet
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
           newVSet
          )
        end
      | MVPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        let
          val (newExp,newVSet) = eliminateExp vSet exp
        in
          (
           MVPOLY
               {
                btvEnv = btvEnv,
                expTyWithoutTAbs = expTyWithoutTAbs,
                exp = newExp,
                loc = loc
               },
           newVSet
          )
        end
      | MVTAPP {exp, expTy, instTyList, loc} =>
        let
          val (newExp,newVSet) = eliminateExp vSet exp
        in
          (
           MVTAPP
               {
                exp = newExp,
                expTy = expTy,
                instTyList = instTyList,
                loc = loc
               },
           newVSet
          )
        end
      | MVSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        let
          val ([newSwitchExp,newDefaultExp],newVSet) = eliminateExpList vSet [switchExp,defaultExp]
          val (newBranches, newVSet) =
              foldr
                  (fn ({constant,exp},(L,S)) => 
                      let
                        val (newExp, newS) = eliminateExp S exp
                      in
                        ({constant = constant, exp = newExp}::L, newS)
                      end
                  )
                  ([],newVSet)
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
           newVSet
          )
        end
      | MVCAST {exp, expTy, targetTy, loc} =>
        let
          val (newExp,newVSet) = eliminateExp vSet exp
        in
          (
           MVCAST
               {
                exp = newExp,
                expTy = expTy,
                targetTy = targetTy,
                loc = loc
               },
           newVSet
          )
        end

  and eliminateExpList vSet [] = ([],vSet)
    | eliminateExpList vSet (exp::rest) =
      let
        val (newExp, newVSet) = eliminateExp vSet exp
        val (newRest, newVSet) = eliminateExpList newVSet rest
      in
        ((newExp::newRest), newVSet)
      end


  and eliminateRecBindList vSet [] = ([], vSet)
    | eliminateRecBindList vSet ({boundVar, boundExp}::rest) =
      let
        val (newBoundExp, newVSet) = eliminateExp vSet boundExp
        val (newRest, newVSet) = eliminateRecBindList newVSet rest
      in
        ({boundVar = boundVar, boundExp = newBoundExp}::newRest, newVSet)
      end

  and eliminateDeclList vSet [] = ([], vSet)
    | eliminateDeclList vSet (decl::declList) =
      let
        val (newDeclList, newVSet) = eliminateDeclList vSet declList
        fun boundVarsInRecBinds recbinds =
            foldl
                (fn ({boundVar as {id,...} : varInfo, boundExp}, S) => VSet.add(S,id))
                VSet.empty
                recbinds
      in
        case decl of
          MVVAL {boundVars, boundExp, loc} =>
          let
            val boundVarSet = 
                foldl
                    (fn ({id,...},S) => VSet.add(S,id))
                    VSet.empty
                    boundVars
            val (newBoundExp, newVSet2) = eliminateExp newVSet boundExp
          in
            if VSet.isEmpty(VSet.intersection(boundVarSet,newVSet))
               andalso (not (containEffectInExp newBoundExp))
            then (newDeclList, newVSet)
            else
              (
               MVVAL{boundVars = boundVars, boundExp = newBoundExp, loc = loc}::newDeclList,
               newVSet2
              )
          end
        | MVVALREC {recbindList, loc} =>
          let
            val boundVars = boundVarsInRecBinds recbindList
          in
            if VSet.isEmpty(VSet.intersection(boundVars,newVSet))
            then (newDeclList, newVSet)
            else
              let
                val (newRecBindList, newVSet) = eliminateRecBindList newVSet recbindList
              in
                (
                 MVVALREC {recbindList = newRecBindList, loc = loc}::newDeclList,
                 VSet.difference(newVSet, boundVars)
                )
              end
          end
        | MVVALPOLYREC {btvEnv, recbindList, loc} =>
          let
            val boundVars = boundVarsInRecBinds recbindList
          in
            if VSet.isEmpty(VSet.intersection(boundVars,newVSet))
            then (newDeclList, newVSet)
            else
              let
                val (newRecBindList, newVSet) = eliminateRecBindList newVSet recbindList
              in
                (
                 MVVALPOLYREC {btvEnv = btvEnv, recbindList = newRecBindList, loc = loc}::newDeclList,
                 VSet.difference(newVSet, boundVars)
                )
              end
          end
      end

  fun optimize declList =
      let
        val (declList, _ ) = eliminateDeclList VSet.empty declList
      in declList end
end
