(**
 * Linker Utilities
 * 
 * @copyright (c) 2006, Tohoku University. 
 * @author Liu Bochao
 * @version $Id: LinkerUtils.sml,v 1.1 2006/03/02 12:46:19 bochao Exp $
 *)
structure LinkerUtils =
struct
  local
    structure T = Types
    structure TC = TypeContext
    structure P = Pickle
    structure TCU = TypeContextUtils
    structure PE = PathEnv
    structure SE = StaticEnv
    structure E = TypeInferenceError
    structure FAU = FunctorApplyUtils
    structure TO = TopObject
    structure SU = SigUtils
    structure C = Control
    structure UE = UserError 
  in
    (*****************************************************************)
    fun getKeyInIndex index = 
        (TO.getPageArrayIndex index, TO.getOffset index)

    structure IndexOrd : ordsig =
      struct 
        type ord_key = (TO.pageArrayIndex * TO.offset)
        fun compare (g1 as (p1,o1),g2 as (p2,o2)) = 
            case UInt32.compare(p1,p2) of
                EQUAL => Int.compare(o1,o2)
              | res => res
      end

    structure IndexEnv = BinaryMapFn(IndexOrd)
    (*****************************************************************)
    (* used to update old abstract index to newer ones *)
    fun constructImplTyConSizeTagEnv (tyConSizeTagEnv, accTyConEnv) =
        SEnv.foldli 
        (fn (tyConName, tyBindInfo, (implTyConEnv, unResolvedTyConSizeTagEnv)) =>
            (case SEnv.find(accTyConEnv, tyConName) of
               SOME tyBindInfo' =>
               (SEnv.insert(implTyConEnv, tyConName, tyBindInfo'),
                unResolvedTyConSizeTagEnv)
             | NONE => 
               (implTyConEnv,
                SEnv.insert(unResolvedTyConSizeTagEnv, tyConName, tyBindInfo))
            )
        )
        (SEnv.empty, SEnv.empty)
        tyConSizeTagEnv

    fun constructImplVarEnv (varEnv, accVarEnv) =
        SEnv.foldli
        (fn (varName, idstate , (implVarEnv, unResolvedVarEnv)) =>
            (case SEnv.find(accVarEnv, varName) of
               SOME idstate' =>
               (SEnv.insert(implVarEnv, varName, idstate'),
                unResolvedVarEnv)
             | NONE => 
               (implVarEnv,
                SEnv.insert(unResolvedVarEnv, varName, idstate))
            )
        )
        (SEnv.empty, SEnv.empty)
        varEnv

    fun constructImplStrSizeTagEnv (strEnv, accStrEnv) =
        SEnv.foldli
          (fn (strName, strBindInfo, (implStrEnv, unResolvedStrSizeTagEnv)) =>
              (case SEnv.find(accStrEnv, strName) of
                 SOME strBindInfo' =>
                 (SEnv.insert(implStrEnv, strName, strBindInfo'),
                  unResolvedStrSizeTagEnv)
               | NONE => 
                 (implStrEnv,
                  SEnv.insert(unResolvedStrSizeTagEnv, strName, strBindInfo))
                 ))
          (SEnv.empty, SEnv.empty)
          accStrEnv

    fun constructImplEnv 
          ({tyConSizeTagEnv, varEnv, strSizeTagEnv},
           accExportTypeContext:TC.exportTypeEnv) =
        let
          val (implTyConSizeTagEnv, unResolvedTyConSizeTagEnv) =
              constructImplTyConSizeTagEnv (tyConSizeTagEnv, #tyConSizeTagEnv accExportTypeContext)
          val (implVarEnv, unResolvedVarEnv) =
              constructImplVarEnv (varEnv, #varEnv accExportTypeContext)
          val (implStrSizeTagEnv, unResolvedStrSizeTagEnv) =
              constructImplStrSizeTagEnv (strSizeTagEnv, #strSizeTagEnv accExportTypeContext)
        in
          (
           {tyConSizeTagEnv = implTyConSizeTagEnv,
            varEnv = implVarEnv, 
            strSizeTagEnv = implStrSizeTagEnv},
           {tyConSizeTagEnv = unResolvedTyConSizeTagEnv, 
            varEnv = unResolvedVarEnv,
            strSizeTagEnv = unResolvedStrSizeTagEnv})
        end

    fun constructImplTyConEnvWithTyConEnv (tyConSizeTagEnv, tyConEnv) =
        SEnv.foldli 
            (fn (tyConName, tyBindInfo, implTyConEnv) =>
                (case SEnv.find(tyConEnv, tyConName) of
                     SOME tyBindInfo' =>
                     SEnv.insert(implTyConEnv, tyConName, tyBindInfo')
                   | NONE => 
                     (* error check postponed to signature check *)
                     implTyConEnv))
            SEnv.empty
            tyConSizeTagEnv        
            
    fun constructImplVarEnvWithVarEnv (varEnv, varEnv1) =
        SEnv.foldli
            (fn (varName, idstate , implVarEnv) =>
                (case SEnv.find(varEnv1, varName) of
                     SOME idstate' =>
                     SEnv.insert(implVarEnv, varName, idstate')
                   | NONE => 
                     (* error check postponed to signature check *)
                     implVarEnv))
            SEnv.empty
            varEnv       
 
    fun constructImplStrEnvWithStrEnv (strSizeTagEnv, strEnv) =
        SEnv.foldli
            (fn (strName, strBindInfo, implStrEnv) =>
                (case SEnv.find(strEnv, strName) of
                     SOME strBindInfo' =>
                     SEnv.insert(implStrEnv, strName, strBindInfo')
                   | NONE => 
                     (* error check postponed to signature check *)
                     implStrEnv))
            SEnv.empty
            strSizeTagEnv
          
    fun constructImplEnvWithTypeContext 
            ({tyConSizeTagEnv, varEnv, strSizeTagEnv},
             {tyConEnv, varEnv = varEnv1, strEnv, sigEnv, funEnv}) 
      =
      let
          val implTyConEnv =
              constructImplTyConEnvWithTyConEnv (tyConSizeTagEnv, tyConEnv)
          val implVarEnv =
              constructImplVarEnvWithVarEnv (varEnv, varEnv1)
          val implStrEnv = 
              constructImplStrEnvWithStrEnv (strSizeTagEnv, strEnv)
      in
          (implTyConEnv, implVarEnv, implStrEnv)
      end

    fun instantiateTyPathVarEnv substTyEnv pathVarEnv =
        SEnv.map (fn PE.TopItem (pathVar, index, ty) =>
                      PE.TopItem (pathVar,
                                  index,
                                  FAU.instantiateTy substTyEnv ty)
                    | PE.CurItem _ => raise Control.Bug "CurItem occurs at linking phase"
                   )
                 pathVarEnv

    fun instantiateTyPathStrEnv substTyEnv pathStrEnv =
        SEnv.map (fn PE.PATHAUX (pathVarEnv,pathStrEnv) =>
                     let
                       val newPathVarEnv = 
                           instantiateTyPathVarEnv substTyEnv pathVarEnv
                       val newPathStrEnv = 
                           instantiateTyPathStrEnv substTyEnv pathStrEnv
                     in
                       PE.PATHAUX (newPathVarEnv, newPathStrEnv)
                     end)
                 pathStrEnv
                 
    fun instantiateTyExportModuleEnv
          substTyEnv (exportModuleEnv as (pathFunEnv, pathEnv as (pathVarEnv, pathStrEnv)))
        =
        (pathFunEnv,
         (instantiateTyPathVarEnv substTyEnv pathVarEnv,
          instantiateTyPathStrEnv substTyEnv pathStrEnv))

    fun stripSizeTagTyConSizeTagEnv tyConSizeTagEnv =
        SEnv.map (fn ({tyBindInfo, sizeInfo, tagInfo}) => tyBindInfo) tyConSizeTagEnv
        
    fun stripSizeTagStrSizeTagEnv strSizeTagEnv =
        SEnv.map (fn T.STRSIZETAG
                       {id, 
                        name, 
                        strpath, 
                        env = (tyConSizeTagEnv, varEnv, strSizeTagEnv)} =>
                       T.STRUCTURE 
                         {id = id, 
                          name = name, 
                          strpath = strpath, 
                          env = (stripSizeTagTyConSizeTagEnv tyConSizeTagEnv,
                                 varEnv,
                                 stripSizeTagStrSizeTagEnv strSizeTagEnv)}
                         )
                 strSizeTagEnv
                 
    fun stripSizeTagTypeEnv
          {tyConSizeTagEnv, varEnv, strSizeTagEnv} =
          let
            val tyConEnv = stripSizeTagTyConSizeTagEnv tyConSizeTagEnv
            val strEnv = stripSizeTagStrSizeTagEnv strSizeTagEnv
          in
            (tyConEnv, varEnv, strEnv)
          end
    (*************************************************************************************)
    fun handleException (exn,loc) =
        case exn of
            exn as E.UnboundImportValueIdentifier _ =>
            E.enqueueError(loc, exn)
          | exn as E.UnboundImportTypeContructor _ =>
            E.enqueueError(loc, exn)
          | exn as E.UnboundImportStructure _ =>
            E.enqueueError(loc, exn)
          | _ => SU.handleException (exn,loc)

    (*************************************************************************************)
    fun substTyConIdEnvTyConIdSet tyConIdSet =
        ID.Set.foldl (fn (tyConId, (substEnv, newTyConIdSet)) =>
                         let
                             val newTyConId = SE.newTyConId()
                         in
                             (ID.Map.insert (substEnv, tyConId, newTyConId),
                              ID.Set.add (newTyConIdSet, newTyConId))
                         end)
                     (ID.Map.empty, ID.Set.empty)
                     tyConIdSet

    (*********************************************************************************)
    type substContext = {tyConIdSubst : ID.id ID.Map.map,
                         substTyEnv : Types.tyBindInfo ID.Map.map,
                         indexSubst : TO.globalIndex IndexEnv.map}
                        
    fun injectSubstTyEnvInSubstContext substTyEnv =
        {
         tyConIdSubst = ID.Map.empty,
         substTyEnv = substTyEnv,
         indexSubst = IndexEnv.empty
         }

    fun substTy (substContext:substContext) ty = 
        let
            val (updatedty, visited) = 
                TCU.substTyConIdInTy ID.Set.empty (#tyConIdSubst substContext) ty
            val updatedty =
                FAU.instantiateTy (#substTyEnv substContext) updatedty
        in
            updatedty
        end
            
    local 
       open TypedLambda
       fun substIndex (substContext:substContext) (arrayIndex, offset) =
           IndexEnv.find (#indexSubst substContext,
                          (arrayIndex, offset)) 
           
       fun substTlexp substContext exp =
           case exp of
               TLFOREIGNAPPLY {funExp, instTyList, argExpList, argTyList, loc} =>
               TLFOREIGNAPPLY {funExp = substTlexp substContext funExp, 
                               instTyList = 
                               map (substTy substContext) instTyList,
                               argExpList = map (substTlexp substContext) argExpList,
                               argTyList = map (substTy substContext) argTyList, 
                               loc = loc}
             | TLCONSTANT _ => exp
             | TLVAR {varInfo, loc} =>
               TLVAR {varInfo = substVarIdInfo substContext varInfo , loc = loc}
             | TLGETGLOBAL (string,ty,loc) =>
               TLGETGLOBAL (string, substTy substContext ty, loc)
             | TLGETGLOBALVALUE {arrayIndex, offset, ty, loc} => 
               let
                   val (arrayIndex, offset) = 
                       case substIndex substContext (arrayIndex, offset) of
                           NONE => (arrayIndex, offset)
                         | SOME newIndex => (TO.getPageArrayIndex newIndex,
                                             TO.getOffset newIndex)
               in
                   TLGETGLOBALVALUE {arrayIndex = arrayIndex, 
                                     offset = offset,
                                     ty = substTy substContext ty, 
                                     loc = loc}
               end
             | TLSETGLOBALVALUE {arrayIndex, offset, valueExp, ty, loc} =>
               let
                   val TLCAST 
                           {exp = TLVAR{varInfo = {id, displayName, ty = varTy},loc = loc1}, 
                            targetTy,
                            loc = loc2} = valueExp
                   val (targetTy, arrayIndex, offset) = 
                       case substIndex substContext (arrayIndex, offset) of
                           NONE => (targetTy, arrayIndex, offset)
                         | SOME newIndex => (TO.pageKindToType(TO.getPageKind newIndex),
                                             TO.getPageArrayIndex newIndex,
                                             TO.getOffset newIndex)
                   val newValueExp = 
                       TLCAST
                           {exp = TLVAR{varInfo = {id = id, 
                                                   displayName = displayName,
                                                   ty = substTy substContext varTy},
                                        loc = loc1},
                            targetTy = targetTy, 
                            loc = loc}
               in
                   TLSETGLOBALVALUE {arrayIndex = arrayIndex, 
                                     offset = offset, 
                                     valueExp = newValueExp,
                                     ty = targetTy,
                                     loc = loc}
               end
             | TLINITARRAY {arrayIndex, size, elemTy, loc} =>
               TLINITARRAY {arrayIndex = arrayIndex, 
                            size = size, 
                            elemTy = substTy substContext elemTy, 
                            loc = loc}
             | TLGETFIELD {arrayExp, indexExp, elementTy, loc} =>
               TLGETFIELD {arrayExp = substTlexp substContext arrayExp, 
                           indexExp = substTlexp substContext indexExp, 
                           elementTy = substTy substContext elementTy, 
                           loc = loc} 
             | TLSETFIELD  {valueExp, arrayExp, indexExp, elementTy, loc} =>
               TLSETFIELD  {valueExp = substTlexp substContext valueExp, 
                            arrayExp = substTlexp substContext arrayExp, 
                            indexExp = substTlexp substContext indexExp,
                            elementTy = substTy substContext elementTy, 
                            loc = loc}
             | TLARRAY {sizeExp, initialValue, elementTy, resultTy, loc} =>
               TLARRAY {sizeExp = substTlexp substContext sizeExp, 
                        initialValue = substTlexp substContext initialValue, 
                        elementTy = substTy substContext elementTy, 
                        resultTy = substTy substContext resultTy, 
                        loc = loc}
             | TLPRIMAPPLY {primOp, instTyList, argExpList, loc} =>
               TLPRIMAPPLY {primOp = substPrimInfo substContext primOp, 
                            instTyList = map (substTy substContext) instTyList,
                            argExpList = map (substTlexp substContext) argExpList,
                            loc = loc}
             | TLAPPM {funExp, funTy, argExpList, loc} =>
               TLAPPM {funExp = substTlexp substContext funExp,
                       funTy = substTy substContext funTy,
                       argExpList = map (substTlexp substContext) argExpList,
                       loc = loc}
             | TLMONOLET {binds, bodyExp, loc} =>
               let
                   val binds = 
                       map (fn (v, e) => 
                               (substVarIdInfo substContext v,
                                substTlexp substContext e)) binds
               in
                   TLMONOLET {binds = binds, 
                              bodyExp = substTlexp substContext bodyExp,
                              loc = loc} 
               end
             | TLLET {localDeclList, mainExpList, mainExpTyList, loc} =>
               TLLET {localDeclList = substTldecs substContext localDeclList,
                      mainExpList = map (substTlexp substContext) mainExpList,
                      mainExpTyList = map (substTy substContext) mainExpTyList, 
                      loc = loc}
             | TLRECORD {expList, internalTy, externalTy, loc} =>
               TLRECORD {expList = map (substTlexp substContext) expList,
                         internalTy = substTy substContext internalTy, 
                         externalTy = 
                         case externalTy of 
                             NONE => NONE 
                           | SOME x => SOME (substTy substContext x),
                         loc = loc}
             | TLSELECT {recordExp, indexExp, recordTy, loc} =>
               TLSELECT {recordExp = substTlexp substContext recordExp,
                         indexExp =  substTlexp substContext indexExp,
                         recordTy = substTy substContext recordTy,
                         loc = loc}
             | TLMODIFY {recordExp, recordTy, indexExp, elementExp, elementTy, loc} =>
               TLMODIFY {recordExp = substTlexp substContext recordExp,
                         recordTy = substTy substContext recordTy,
                         indexExp = substTlexp substContext indexExp,
                         elementExp = substTlexp substContext elementExp,
                         elementTy = substTy substContext elementTy,
                         loc = loc}
             | TLRAISE {argExp, resultTy, loc} =>
               TLRAISE {argExp  = substTlexp substContext argExp,
                        resultTy = substTy substContext resultTy,
                        loc = loc}
             | TLHANDLE {exp, exnVar, handler, loc} =>
               TLHANDLE {exp = substTlexp substContext exp,
                         exnVar = substVarIdInfo substContext exnVar,
                         handler = substTlexp substContext handler,
                         loc = loc}
             | TLFNM {argVarList, bodyTy, bodyExp,loc} =>
               TLFNM {argVarList = map (substVarIdInfo substContext) argVarList,
                      bodyTy = substTy substContext bodyTy,
                      bodyExp = substTlexp substContext bodyExp,
                      loc = loc}
             | TLPOLY{btvEnv, expTyWithoutTAbs, exp, loc} =>
               TLPOLY{btvEnv = substBtvEnv substContext btvEnv,
                      expTyWithoutTAbs = substTy substContext expTyWithoutTAbs, 
                      exp = substTlexp substContext exp,
                      loc = loc}
             | TLTAPP {exp, expTy, instTyList, loc} =>
               TLTAPP {exp = substTlexp substContext exp,
                       expTy = substTy substContext expTy,
                       instTyList = map (substTy substContext) instTyList,
                       loc = loc}
             | TLSWITCH{switchExp, expTy, branches, defaultExp, loc} =>
               TLSWITCH{switchExp = substTlexp substContext switchExp, 
                        expTy = substTy substContext expTy,
                        branches =
                        map (fn (c, e) => (c, substTlexp substContext e)) branches,
                        defaultExp = substTlexp substContext defaultExp,
                        loc = loc}
             | TLSEQ {expList, expTyList, loc} =>
               TLSEQ {expList = map (substTlexp substContext) expList,
                      expTyList = map (substTy substContext) expTyList,
                      loc = loc}
             | TLCAST {exp, targetTy, loc} =>
               TLCAST {exp = substTlexp substContext exp,
                       targetTy = substTy substContext targetTy, 
                       loc = loc}
             | TLOFFSET {recordTy, label, loc} =>
               TLOFFSET {recordTy = substTy substContext recordTy,
                         label = label,
                         loc = loc}
             | TLFFIVAL {funExp, libExp, argTyList, resultTy, funTy,loc}=>
               TLFFIVAL {funExp = substTlexp substContext funExp,
                         libExp = substTlexp substContext libExp,
                         argTyList = map (substTy substContext) argTyList,
                         resultTy = substTy substContext resultTy, 
                         funTy = substTy substContext funTy,
                         loc = loc}
       and substPrimInfo substContext {name, ty} =
           {name = name, ty = substTy substContext ty}

       and substValIdent substContext valIdent =
           case valIdent of
               Types.VALIDENT {id, displayName, ty} =>
               Types.VALIDENT {id = id, 
                               displayName = displayName,
                               ty = substTy substContext ty}
             | Types.VALIDENTWILD ty => Types.VALIDENTWILD (substTy substContext ty)

       and substRecbind substContext {boundVar, boundTy, boundExp} = 
           {boundVar = substVarIdInfo substContext boundVar,
            boundTy = substTy substContext boundTy,
            boundExp = substTlexp substContext boundExp}

       and substVarIdInfo substContext {id, displayName, ty} =
           {id = id,
            displayName = displayName,
            ty = substTy substContext ty}
           
       and substBtvEnv substContext btvEnv =
           IEnv.map (substBtvkind substContext) btvEnv

       and substBtvkind substContext {index, recKind, eqKind} =
           {index = index,
            recKind = substRecKind substContext recKind,
            eqKind = eqKind}

       and substRecKind substContext recKind =
           case recKind of
               Types.UNIV => recKind
             | Types.REC tys => Types.REC (SEnv.map (substTy substContext) tys)
             | Types.OVERLOADED tys => Types.OVERLOADED (map (substTy substContext) tys)

       and substTldec substContext tldec =
           case tldec of
               TLVAL {bindList = binds, loc} =>
               let
                   val binds = 
                       map (fn {boundExp, boundValIdent} =>
                               {boundExp = substTlexp substContext boundExp,
                                boundValIdent = substValIdent substContext boundValIdent})
                           binds
               in
                   TLVAL {bindList = binds, loc = loc} 
               end
             | TLVALREC {recbindList = recbinds, loc} =>
               let
                   val recbinds = 
                       map (substRecbind substContext) recbinds
               in
                   TLVALREC {recbindList = recbinds, loc = loc}
               end
             | TLVALPOLYREC {btvEnv, indexVars, recbindList, loc} =>
               let
                   val btvEnv = substBtvEnv substContext btvEnv
                   val indexVars = map (substVarIdInfo substContext) indexVars
                   val recbinds = map (substRecbind substContext) recbindList
               in
                   TLVALPOLYREC {btvEnv = btvEnv, 
                                 indexVars = indexVars, 
                                 recbindList = recbinds, 
                                 loc = loc}
               end
             | TLLOCALDEC {localDeclList, mainDeclList, loc} =>
               let
                   val localDecList = substTldecs substContext localDeclList
                   val mainDeclList = substTldecs substContext mainDeclList
               in
                   TLLOCALDEC {localDeclList = localDeclList,
                               mainDeclList = mainDeclList, 
                               loc = loc}
               end
             | TLSETGLOBAL (string, tlexp, loc) =>
               TLSETGLOBAL (string, substTlexp substContext tlexp, loc)
             | TLEMPTY _ => tldec 
                   
       and substTldecs substContext tldecs = 
           map (substTldec substContext) tldecs
    in
       fun substTyConIdTldecs tyConIdSubst tldecs =
           let
               val context = {tyConIdSubst = tyConIdSubst,
                              substTyEnv = ID.Map.empty,
                              indexSubst = IndexEnv.empty}
           in
               substTldecs context tldecs
           end

       fun substTyTldecs substTyEnv tldecs =
           let
               val context = {tyConIdSubst = ID.Map.empty,
                              substTyEnv = substTyEnv,
                              indexSubst = IndexEnv.empty}
           in
               substTldecs context tldecs
           end
       fun substIndexTldecs indexEnv tldecs =
           let
               val context = {tyConIdSubst = ID.Map.empty,
                              substTyEnv = ID.Map.empty,
                              indexSubst = indexEnv}
           in
               substTldecs context tldecs
           end
    end (* end local open typedlambda *)

    (***********************************************************************)
    fun substTyConIdPathVarEnv substTyConIdEnv pathVarEnv =
        SEnv.map (fn item => 
                     case item of
                         PE.TopItem (pathVar, index, ty) =>
                         let
                             val (ty, visited) = 
                                 TCU.substTyConIdInTy ID.Set.empty substTyConIdEnv ty
                         in
                             PE.TopItem (pathVar, index, ty)
                         end
                       | PE.CurItem (pathVar, id, ty, loc) =>
                         let
                             val (ty, visited) = 
                                 TCU.substTyConIdInTy ID.Set.empty substTyConIdEnv ty
                         in
                             PE.CurItem (pathVar, id, ty, loc)
                         end)
                 pathVarEnv

    fun substTyConIdPathStrEnv substTyConIdEnv pathStrEnv =
        SEnv.map (fn (PE.PATHAUX Env) =>
                     PE.PATHAUX (substTyConIdPathEnv substTyConIdEnv Env))
                 pathStrEnv

    and substTyConIdPathEnv substTyConIdEnv (pathEnv:PathEnv.pathEnv) =
        let
            val pathVarEnv = substTyConIdPathVarEnv substTyConIdEnv (#1 pathEnv)
            val pathStrEnv = substTyConIdPathStrEnv substTyConIdEnv (#2 pathEnv)
        in
            (pathVarEnv, pathStrEnv)
        end

    fun substTyConIdPathBasis substTyConIdEnv (pathBasis:PathEnv.pathBasis) = 
        let
            (* tobe : how to deal with functor ???*)
            val pathFunEnv = #1 pathBasis
            val pathEnv = substTyConIdPathEnv substTyConIdEnv (#2 pathBasis)
        in
            (pathFunEnv, pathEnv)
        end

    fun substTyConIdStaticModuleEnv 
            substTyConIdEnv (staticModuleEnv:StaticModuleEnv.staticModuleEnv) =
        let
            val importModuleEnv = 
                substTyConIdPathBasis substTyConIdEnv (#importModuleEnv staticModuleEnv)
            val exportModuleEnv =
                substTyConIdPathBasis substTyConIdEnv (#exportModuleEnv staticModuleEnv)
        in
            {importModuleEnv = importModuleEnv,
             exportModuleEnv = exportModuleEnv}
        end

    fun substTyConIdInnerMergedModuleEnv substTyConIdEnv innerMergedModuleEnv =
        substTyConIdPathEnv substTyConIdEnv  innerMergedModuleEnv
   
    fun handleSigCheckFail () =
        let
            fun printError message = 
                #print (CharacterStreamWrapper.wrapOut 
                            (TextIOChannel.openOut {outStream = TextIO.stdErr})) message
        in
            (app (fn error =>
                     (printError (C.prettyPrint
                                      (UE.format_errorInfo error));
                      printError "\n"
                      ))
                 (E.getErrorsAndWarnings ());
                 printError "\n")
        end
    (**************************************************************************************)
    fun unPickle objName ty  = 
        let
            val _ = StaticEnv.init()
            val _ = Vars.initVars()
            val _ = Types.init()
            val infile = BinIO.openIn objName
            val instream =
                Pickle.makeInstream (fn _ => valOf(BinIO.input1 infile))
            val _ = print ("\n[begin unpickle "^ objName ^ ".......")
            val object = 
                P.unpickle ty instream
            val _ = print "done]\n"
            val _ = BinIO.closeIn infile 
        in object end
  end
end