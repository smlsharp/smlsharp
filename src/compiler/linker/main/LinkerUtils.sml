(**
 * Linker Utilities
 * 
 * @copyright (c) 2006, Tohoku University. 
 * @author Liu Bochao
 * @version $Id: LinkerUtils.sml,v 1.26 2007/02/28 15:31:25 katsu Exp $
 *)
structure LinkerUtils =
struct
  local
    structure T = Types
    structure TC = TypeContext
    structure P = Pickle
    structure TCU = TypeContextUtils
    structure PE = PathEnv
    structure PT = PredefinedTypes
    structure E = TypeInferenceError
    structure FAU = FunctorApplyUtils
    structure TO = TopObject
    structure C = Control
    structure UE = UserError 
    structure SC = SigCheck
    structure AU = AntiUnifier
    structure TIT = TypeInstantiationTerm
    structure SME = StaticModuleEnv 
    structure STE = StaticTypeEnv
    structure STEU = StaticTypeEnvUtils
    structure TCalc = TypedCalc
    structure TU = TypesUtils
    structure LE = LinkError
    structure SU = SigUtils
    fun printTy ty = print (TypeFormatter.tyToString ty ^ "\n")
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
    structure IndexSet = BinarySetFn(IndexOrd)

    (*****************************************************************)
    fun constructImplAndUnResolvedTyConEnv (tyConEnv, accTyConEnv) =
        SEnv.foldli 
        (fn (tyConName, tyBindInfo, (implTyConEnv, unResolvedTyConEnv)) =>
            (case SEnv.find(accTyConEnv, tyConName) of
               SOME tyBindInfo' =>
               (SEnv.insert(implTyConEnv, tyConName, tyBindInfo'),
                unResolvedTyConEnv)
             | NONE => 
               (implTyConEnv,
                SEnv.insert(unResolvedTyConEnv, tyConName, tyBindInfo))
            )
        )
        (SEnv.empty, SEnv.empty)
        tyConEnv

    fun constructImplAndUnResolvedVarEnv (varEnv, accVarEnv) =
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

    fun constructImplAndUnResolvedStrEnv (T.STRUCTURE strEnvCont, T.STRUCTURE  accStrEnvCont) =
      let
        val (implStrEnvCont, unResolvedStrEnvCont) =
          SEnv.foldli
          (fn (strName, strBindInfo, (implStrEnvCont, unResolvedStrEnvCont)) =>
           (case SEnv.find(accStrEnvCont, strName) of
              SOME strBindInfo' =>
                (SEnv.insert(implStrEnvCont, strName, strBindInfo'),
                 unResolvedStrEnvCont)
            | NONE => 
                (implStrEnvCont,
                 SEnv.insert(unResolvedStrEnvCont, strName, strBindInfo))
                ))
          (SEnv.empty, SEnv.empty)
          strEnvCont
      in
        (T.STRUCTURE implStrEnvCont, T.STRUCTURE unResolvedStrEnvCont)
      end

    (*
     * param : Env1, Env2
     * return : (Env3,Env4)
     * Env3 : contains all the maps in Env2 whose domain is 
     *        the intersection of dom(Env1) \cap dom(Env2) 
     * Env4 : contains all the maps in Env1 whose domain is 
     *        the minus of dom(Env1) \minus dom(Env2)
     *)
    fun constructImplAndUnResolvedEnv
          ({tyConEnv, varEnv, strEnv},
           accTypeEnv:STE.typeEnv) =
        let
          val (implTyConEnv, unResolvedTyConEnv) =
              constructImplAndUnResolvedTyConEnv (tyConEnv, #tyConEnv accTypeEnv)
          val (implVarEnv, unResolvedVarEnv) =
              constructImplAndUnResolvedVarEnv (varEnv, #varEnv accTypeEnv)
          val (implStrEnv, unResolvedStrEnv) =
              constructImplAndUnResolvedStrEnv (strEnv, #strEnv accTypeEnv)
        in
          (
           {tyConEnv = implTyConEnv,
            varEnv = implVarEnv, 
            strEnv = implStrEnv},
           {tyConEnv = unResolvedTyConEnv, 
            varEnv = unResolvedVarEnv,
            strEnv = unResolvedStrEnv})
        end

    fun constructImplTyConEnvWithTyConEnv (tyConEnv1, tyConEnv2) =
        SEnv.foldli 
            (fn (tyConName, tyBindInfo, implTyConEnv) =>
                (case SEnv.find(tyConEnv2, tyConName) of
                     SOME tyBindInfo' =>
                     SEnv.insert(implTyConEnv, tyConName, tyBindInfo')
                   | NONE => 
                     (* error check postponed to signature check *)
                     implTyConEnv))
            SEnv.empty
            tyConEnv1
            
    fun constructImplVarEnvWithVarEnv (varEnv1, varEnv2) =
        SEnv.foldli
            (fn (varName, idstate , implVarEnv) =>
                (case SEnv.find(varEnv2, varName) of
                     SOME idstate' =>
                     SEnv.insert(implVarEnv, varName, idstate')
                   | NONE => 
                     (* error check postponed to signature check *)
                     implVarEnv))
            SEnv.empty
            varEnv1
 
    fun constructImplStrEnvWithStrEnv (T.STRUCTURE strEnvCont1, T.STRUCTURE strEnvCont2) =
      let
        val newStrEnv =
          SEnv.foldli
          (fn (strName, strBindInfo, implStrEnv) =>
           (case SEnv.find(strEnvCont2, strName) of
              SOME strBindInfo' =>
                SEnv.insert(implStrEnv, strName, strBindInfo')
            | NONE => 
                (* error check postponed to signature check *)
                implStrEnv))
          SEnv.empty
          strEnvCont1
      in
        T.STRUCTURE newStrEnv
      end
          
    fun constructImplEnvWithTypeContext 
            ({
              tyConEnv = tyConEnv1, 
              varEnv = varEnv1, 
              strEnv = strEnv1
              },
             {tyConEnv = tyConEnv2,
              varEnv = varEnv2, 
              strEnv = strEnv2, 
              sigEnv, 
              funEnv}) 
      =
      let
          val implTyConEnv =
              constructImplTyConEnvWithTyConEnv (tyConEnv1, tyConEnv2)
          val implVarEnv =
              constructImplVarEnvWithVarEnv (varEnv1, varEnv2)
          val implStrEnv = 
              constructImplStrEnvWithStrEnv (strEnv1, strEnv2)
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


    (*************************************************************************************)
    fun substTyConIdEnvTyConIdSet tyConIdSet =
        ID.Set.foldl (fn (tyConId, (substEnv, newTyConIdSet)) =>
                         let
                             val newTyConId = T.newTyConId()
                         in
                             (ID.Map.insert (substEnv, tyConId, newTyConId),
                              ID.Set.add (newTyConIdSet, newTyConId))
                         end)
                     (ID.Map.empty, ID.Set.empty)
                     tyConIdSet

    (*********************************************************************************)
    type substContext = {tyConIdSubst : ID.id ID.Map.map,
                         substTyEnv : Types.tyBindInfo ID.Map.map,
                         indexSubst : TO.globalIndex IndexEnv.map,
                         exnTagSubst : int IEnv.map}
                        
    fun injectSubstTyEnvInSubstContext substTyEnv =
        {
         tyConIdSubst = ID.Map.empty,
         substTyEnv = substTyEnv,
         indexSubst = IndexEnv.empty,
         exnTagSubst = IEnv.empty
         }

    fun substTy (substContext:substContext) ty = 
        let
            val (ty1, visited) = 
                TCU.substTyConIdInTy ID.Set.empty (#tyConIdSubst substContext) ty
            val (ty2, visited) = 
                TCU.substTyConInTy ID.Set.empty (#substTyEnv substContext) ty1
        in
            ty2
        end
            
    fun substExnTag (substContext:substContext) tag =
        case IEnv.find(#exnTagSubst substContext, tag) of
            NONE => tag
          | SOME newTag => newTag

    local 
       open TypedLambda
    in
       fun substIndex (substContext:substContext) (arrayIndex, offset) =
           IndexEnv.find (#indexSubst substContext,
                          (arrayIndex, offset)) 
           
       fun substTlexp substContext exp =
           case exp of
               TLFOREIGNAPPLY {funExp, funTy, instTyList, argExpList, argTyList, convention, loc} =>
               TLFOREIGNAPPLY {funExp = substTlexp substContext funExp, 
                               funTy = substTy substContext funTy,
                               instTyList = 
                               map (substTy substContext) instTyList,
                               argExpList = map (substTlexp substContext) argExpList,
                               argTyList = map (substTy substContext) argTyList,
                               convention = convention,
                               loc = loc}
             | TLEXPORTCALLBACK {funExp, instTyList, argTyList, resultTy, loc} =>
               TLEXPORTCALLBACK {funExp = substTlexp substContext funExp,
                               instTyList = 
                               map (substTy substContext) instTyList,
                               argTyList = map (substTy substContext) argTyList, 
                               resultTy = substTy substContext resultTy,
                               loc = loc}
             | TLSIZEOF _ => exp
             | TLCONSTANT _ => exp
             | TLEXCEPTIONTAG {tagValue, loc} =>
               TLEXCEPTIONTAG {tagValue = substExnTag substContext tagValue,
                               loc = loc}
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
                        map (fn {constant,exp} => {constant = substTlexp substContext constant,
                                                   exp = substTlexp substContext exp}) branches,
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
   
       fun substTyConIdTldecs tyConIdSubst tldecs =
           let
               val context = {tyConIdSubst = tyConIdSubst,
                              substTyEnv = ID.Map.empty,
                              indexSubst = IndexEnv.empty,
                              exnTagSubst = IEnv.empty}
           in
               substTldecs context tldecs
           end

       fun substTyTldecs substTyEnv tldecs =
           let
               val context = {tyConIdSubst = ID.Map.empty,
                              substTyEnv = substTyEnv,
                              indexSubst = IndexEnv.empty,
                              exnTagSubst = IEnv.empty}
           in
               substTldecs context tldecs
           end
       fun substIndexTldecs indexEnv tldecs =
           let
               val context = {tyConIdSubst = ID.Map.empty,
                              substTyEnv = ID.Map.empty,
                              indexSubst = indexEnv,
                              exnTagSubst = IEnv.empty}
           in
               substTldecs context tldecs
           end
    end (* end local open typedlambda *)

    (**************************************************************************************)

    fun unPickle objName ty  = 
        let
            val _ = Vars.initVars()
            val _ = Types.init()
            val infile = BinIO.openIn objName
            val instream =
                Pickle.makeInstream (fn _ => valOf(BinIO.input1 infile))
            val _ = print ("\n[begin unpickle "^ objName ^ ".......")
            val object = P.unpickle ty instream
            val _ = print "done]\n"
            val _ = BinIO.closeIn infile 
        in object end 

    (**************************************************************************************)
    (* subEquivalence Relation  *)
    fun computeTyBindInfoEquationsTyConEnv
            (leftTyConEnv, rightTyConEnv) tyBindInfoEquations =
        SEnv.foldli
            (fn (tyConName, leftTyBindInfo, tyBindInfoEquations) =>
                case SEnv.find(rightTyConEnv, tyConName) of
                    SOME rightTyBindInfo => 
                    (leftTyBindInfo, rightTyBindInfo) :: tyBindInfoEquations
                  | _ => tyBindInfoEquations)
            tyBindInfoEquations 
            leftTyConEnv
            
    fun computeTyBindInfoEquationsStrEnv
            (T.STRUCTURE leftStrEnvCont, T.STRUCTURE  rightStrEnvCont) tyBindInfoEquations =
        SEnv.foldli 
            (fn (strName,
                 {env = (subLeftTyConEnv, _, subLeftStrEnv), ...},
                 tyBindInfoEquations) =>
                case SEnv.find(rightStrEnvCont, strName) of
                    SOME {env = (subRightTyConEnv, _, subRightStrEnv), ...} 
                    =>
                    computeTyBindInfoEquationsStrEnv
                        (subLeftStrEnv, subRightStrEnv)
                        (computeTyBindInfoEquationsTyConEnv
                             (subLeftTyConEnv, subRightTyConEnv) 
                             tyBindInfoEquations)
                  | _ => tyBindInfoEquations)
            tyBindInfoEquations
            leftStrEnvCont
            
    fun computeTyBindInfoEquationsEnv
            ({tyConEnv = leftTyConEnv, 
              varEnv = leftVarEnv, 
              strEnv = leftStrEnv}, 
             {tyConEnv = rightTyConEnv,
              varEnv = rightVarEnv, 
              strEnv = rightStrEnv})
      =
      computeTyBindInfoEquationsStrEnv
          (leftStrEnv, rightStrEnv)
          (computeTyBindInfoEquationsTyConEnv
               (leftTyConEnv, rightTyConEnv) 
               nil)
                                       
    fun boundTyConIdSetTyConEnv tyConEnv =
        SEnv.foldl (fn (tyBindInfo, tyConIdSet) =>
                       case tyBindInfo of
                           T.TYSPEC {spec = {id,...}, impl = NONE} => ID.Set.add(tyConIdSet, id)
                         | T.TYCON {id,...} => ID.Set.add(tyConIdSet, id)
                         | _ => tyConIdSet)
                   ID.Set.empty
                   tyConEnv

    fun boundTyConIdSetStrEnv (T.STRUCTURE strEnvCont) =
        SEnv.foldl (fn 
                     ({
                         env = (subTyConEnv, 
                                subVarEnv,
                                subStrEnv),...
                        },
                      tyConIdSet
                      ) =>
                       let
                           val tyConIdSet1 = boundTyConIdSetTyConEnv subTyConEnv
                           val tyConIdSet2 = boundTyConIdSetStrEnv subStrEnv
                       in
                           ID.Set.union
                               (ID.Set.union (tyConIdSet1, tyConIdSet),
                                tyConIdSet2)
                       end)
                   ID.Set.empty
                   strEnvCont
                   
    fun boundTyConIdSetEnv (Env as {tyConEnv, varEnv, strEnv}) =
        ID.Set.union (boundTyConIdSetTyConEnv tyConEnv,
                      boundTyConIdSetStrEnv strEnv)

    fun checkEquivalenceTyBindInfoEqs nil = ()
      | checkEquivalenceTyBindInfoEqs ((leftTyBindInfo, rightTyBindInfo) :: tail) =
        case (leftTyBindInfo, rightTyBindInfo) of
            (T.TYSPEC {spec ={name, id = id1, tyvars = tyvars1, eqKind = eqKind1,...},...},
             T.TYSPEC {spec ={id = id2, tyvars = tyvars2, eqKind = eqKind2,...},...}) =>
            if not (ID.eq(id1, id2)) 
            then raise Control.Bug "id not equal(1)"
            else
                if List.length tyvars2 <> List.length tyvars1 
                then raise E.ArityMismatchInSigMatch {tyConName = name}
                else if eqKind1 = T.EQ andalso eqKind2 = T.NONEQ 
                then raise E.EqErrorInSigMatch {tyConName=name}
                else checkEquivalenceTyBindInfoEqs tail
          | (T.TYCON {name = name, tyvars = tyvars1, id = id1, eqKind = ref eqKind1, ...}, 
             T.TYCON {tyvars = tyvars2, id = id2, eqKind = ref eqKind2, ...}) =>
            if not (ID.eq(id1, id2))
            then raise Control.Bug "id not equal(2)"
            else
                if List.length tyvars2 <> List.length tyvars1 
                then raise E.ArityMismatchInSigMatch {tyConName=name}
                else if eqKind1 = T.EQ andalso eqKind2 = T.NONEQ 
                then raise E.EqErrorInSigMatch {tyConName=name}
                else checkEquivalenceTyBindInfoEqs tail
          | (T.TYFUN  ( {name = name1, tyargs = tyargs1 , body = body1}),
             T.TYFUN  ( {name = name2, tyargs = tyargs2 , body = body2}))
            =>
            if IEnv.numItems(tyargs1) <> IEnv.numItems(tyargs2) then
                raise E.ArityMismatchInSigMatch {tyConName = name1 ^ " " ^ name2}
            else
                if SC.equivTyFcn (tyargs1, body1) (tyargs2,body2) 
                then checkEquivalenceTyBindInfoEqs tail
                else raise E.SharingTypeMismatchInSigMatch{tyConName1 = name1, 
                                                           tyConName2 = name2}
          | (T.TYCON {name = name1, tyvars = tyvars1, id = id1, eqKind = ref eqKind1, 
                      datacon = ref varEnv1, ...}, 
             T.TYFUN {name = name2, tyargs = tyargs2 , body = body2}) 
            =>
            (case (TU.extractAliasTyImpl body2) of
                 T.CONty({tyCon = {name = name3,
                                   tyvars = tyvars3, 
                                   id = id3, eqKind = ref eqKind3,
                                   datacon = ref varEnv3,...},...})
                 => 
                 if List.length tyvars1 <> List.length tyvars3 then
                     raise E.ArityMismatchInSigMatch {tyConName=name2}
                 else if eqKind1 = T.EQ andalso eqKind3 = T.NONEQ then
                     raise E.EqErrorInSigMatch {tyConName=name2}
                 else if not (ID.eq(id1, id3)) then
                     raise E.TyConMisMatchInSigMatch {tyConName=name2}
                 else if not (SC.equivVarEnv (varEnv1, varEnv3)) then
                     raise E.TyConMisMatchInSigMatch {tyConName=name2}
                 else checkEquivalenceTyBindInfoEqs tail
               | _ => 
                 raise E.TyConMisMatchInSigMatch {tyConName = name2})
          | (T.TYFUN  ( {name = name1, tyargs = tyargs1 , body = body1}),
             T.TYCON {name = name2, tyvars=tyvars2, id = id2, eqKind = ref eqKind2, 
                      datacon = datacon2 as ref varEnv2, ...})
            => 
            (case (TU.extractAliasTyImpl body1) of
                 T.CONty({tyCon = {name = name3, tyvars = tyvars3,
                                   id = id3, eqKind = ref eqKind3,
                                   datacon = ref varEnv3,...},...})
                 => 
                 if List.length tyvars2 <> List.length tyvars2 then
                     raise E.ArityMismatchInSigMatch {tyConName=name2}
                 else if eqKind2 = T.EQ andalso eqKind3 = T.NONEQ then
                     raise E.EqErrorInSigMatch {tyConName=name2}
                 else if not (ID.eq(id2, id3)) then
                     raise E.TyConMisMatchInSigMatch {tyConName=name2}
                 else if not (SC.equivVarEnv (varEnv2, varEnv3)) then
                     raise E.TyConMisMatchInSigMatch {tyConName=name2}
                 else checkEquivalenceTyBindInfoEqs tail
               | _ => raise E.TyConMisMatchInSigMatch {tyConName = name2})
          | _ => raise Control.Bug "illegal tyBindInfo equation"

    (***********************************************************************************)
    (* 
     * construct least general type of unitVarEnv 
     *)
    fun computeLeastGeneralTypeSchemeVarEnv (unitVarEnv, commonVarEnv) =
        SEnv.mapi
        (fn (varName, idstate) =>
            case idstate of
                T.VARID {name, strpath = commonstrpath, ty = commonTy} =>
                (case SEnv.find (unitVarEnv, varName) of
                     NONE => idstate
                   | SOME (T.VARID {name, strpath = unitstrpath, ty = unitTy}) => 
                     let
                         val lgt = AU.antiUnifier (unitTy, commonTy)
                     in
                         T.VARID{name = name, strpath = commonstrpath, ty = lgt}
                     end
                   | SOME _ => idstate (* ??? *)
                         )
              | _ => idstate)
        commonVarEnv

    (* 
     * construct least general type of unitStrEnv 
     *)
    fun computeLeastGeneralTypeSchemeStrEnv 
         (T.STRUCTURE unitStrEnvCont, T.STRUCTURE commonStrEnvCont) =
        let
          val newStrEnvCont = 
            SEnv.mapi
            (fn (
                 strName, 
                 strBindInfo as {env = (subUnitTyConEnv, 
                                        subUnitVarEnv, 
                                        subUnitStrEnv),
                                 id, name, strpath}
                 ) 
             =>
             case SEnv.find(commonStrEnvCont, strName) of
               NONE => strBindInfo
              | SOME {env = (subCommonTyConEnv, 
                             subCommonVarEnv, 
                             subCommonStrEnv), ...}
                 =>
                 let
                   val newSubUnitVarEnv = 
                     computeLeastGeneralTypeSchemeVarEnv (subUnitVarEnv, subCommonVarEnv)
                   val newSubUnitStrEnv =
                     computeLeastGeneralTypeSchemeStrEnv (subUnitStrEnv, subCommonStrEnv)
                 in
                   {env = (subUnitTyConEnv,
                           newSubUnitVarEnv,
                           newSubUnitStrEnv),
                    id = id, 
                    name = name,
                    strpath = strpath}
                 end)
            unitStrEnvCont
        in
          T.STRUCTURE newStrEnvCont
        end

                               
    (* 
     * construct least general type of unitTypeEnv
     *)
    fun computeLeastGeneralTypeSchemeEnv (unitTypeEnv:STE.typeEnv, commonTypeEnv:STE.typeEnv) =
        let
            val varEnv = 
                computeLeastGeneralTypeSchemeVarEnv ((#varEnv unitTypeEnv),
                                                     (#varEnv commonTypeEnv))
            val strEnv =
                computeLeastGeneralTypeSchemeStrEnv ((#strEnv unitTypeEnv),
                                                            (#strEnv commonTypeEnv))
        in
            {tyConEnv = #tyConEnv commonTypeEnv,
             varEnv = varEnv,
             strEnv = strEnv}
        end
             
    fun unifyCommonTypeEnv ((unitImportTyConIdSet, unitImportEnv), 
                            commonImportEnv:StaticTypeEnv.typeEnv) =
        let
            (******************************************************)
            (* linkage unit import Env construction *)
            val unitTyConEqs = 
                computeTyBindInfoEquationsEnv (unitImportEnv, commonImportEnv)
            val unitTyConIdSubst = 
                SC.unifyTyConId unitImportTyConIdSet unitTyConEqs ID.Map.empty
            val unitTyConEqs = 
                SC.substTyConIdInTyBindInfoEqsDomain unitTyConIdSubst unitTyConEqs
            val unitTyConSubst =
                SC.unifyTySpec unitTyConEqs ID.Map.empty 

            (* instantiate unit with tyConId and tyCon
             * in accumulated unResolvedImportEnv 
             *)
            val unitImportEnv = 
                STE.substTyConInTypeEnv 
                    unitTyConSubst
                    (STE.substTyConIdInTypeEnv unitTyConIdSubst unitImportEnv)
            (******************************************************)
            (* accmulated import Env common part construction *)
            val commonTyConEqs = 
                computeTyBindInfoEquationsEnv (commonImportEnv, unitImportEnv)
            val commonTyConSubst =
                SC.unifyTySpec commonTyConEqs ID.Map.empty 
            val commonImportEnv =
                STE.substTyConInTypeEnv commonTyConSubst commonImportEnv
            (******************************************************)
            (* common type parts satisfys compatibility *)

            val _ = 
                let
                    val tyBindInfoEqs = 
                        computeTyBindInfoEquationsEnv (commonImportEnv, unitImportEnv)
                in
                    checkEquivalenceTyBindInfoEqs tyBindInfoEqs
                end
            (******************************************************)
            (* compute least generalization type scheme *)
            val generalizedUnitImportEnv = 
                computeLeastGeneralTypeSchemeEnv (unitImportEnv, commonImportEnv)
        in
            (generalizedUnitImportEnv, 
             unitTyConIdSubst, 
             unitTyConSubst,
             commonTyConSubst)
        end

    fun compatibiltyUnify (commonImportEnv, unitImportEnv) =
        let
            val _ = 
                let
                    val tyBindInfoEqs = 
                        computeTyBindInfoEquationsEnv (commonImportEnv, unitImportEnv)
                in
                    checkEquivalenceTyBindInfoEqs tyBindInfoEqs
                end
        in
            computeLeastGeneralTypeSchemeEnv (unitImportEnv, commonImportEnv)
        end

    fun unifyCommonTypeEnv ((unitImportTyConIdSet, unitImportEnv), 
                            commonImportEnv:StaticTypeEnv.typeEnv) =
        let
            (******************************************************)
            (* linkage unit import Env construction *)
            val unitTyConEqs = 
                computeTyBindInfoEquationsEnv (unitImportEnv, commonImportEnv)
            val unitTyConIdSubst = 
                SC.unifyTyConId unitImportTyConIdSet unitTyConEqs ID.Map.empty
            val unitTyConEqs = 
                SC.substTyConIdInTyBindInfoEqsDomain unitTyConIdSubst unitTyConEqs
            val unitTyConSubst =
                SC.unifyTySpec unitTyConEqs ID.Map.empty 

            (* instantiate unit with tyConId and tyCon
             * in accumulated unResolvedImportEnv 
             *)
            val unitImportEnv = 
                STE.substTyConInTypeEnv 
                    unitTyConSubst
                    (STE.substTyConIdInTypeEnv unitTyConIdSubst unitImportEnv)
            (******************************************************)
            (* accmulated import Env common part construction *)
            val commonTyConEqs = 
                computeTyBindInfoEquationsEnv (commonImportEnv, unitImportEnv)
            val commonTyConSubst =
                SC.unifyTySpec commonTyConEqs ID.Map.empty 
            val commonImportEnv =
                STE.substTyConInTypeEnv commonTyConSubst commonImportEnv
        in
            (unitTyConIdSubst, 
             unitTyConSubst,
             commonTyConSubst)
        end
            
    (********************************************************************************)
    fun flattenPathVarEnvToList pathVarEnv =
        SEnv.foldl (fn (itemInfo, tyInstValIndices) =>
                       case itemInfo of
                           PE.TopItem topItem =>
                           tyInstValIndices @ [topItem]
                         | PE.CurItem curItem => 
                           raise Control.Bug "illegal CurItem in pathBasis"
                           )
                   nil
                   pathVarEnv
    fun flattenPathStrEnvToList pathStrEnv =
        SEnv.foldl (fn (PE.PATHAUX (subPathVarEnv, subPathStrEnv), tyInstValIndices) =>
                       tyInstValIndices @
                       (flattenPathVarEnvToList subPathVarEnv) @ 
                       (flattenPathStrEnvToList subPathStrEnv))
                   nil
                   pathStrEnv
                       
    fun flattenPathEnvToList (pathEnv:PE.pathEnv) =
        flattenPathVarEnvToList (#1 pathEnv) @
        flattenPathStrEnvToList (#2 pathEnv)

    fun flattenPathBasisToList (pathBasis:PE.pathBasis) =
        let
            val list1 = flattenPathEnvToList (#2 pathBasis)
        in
            list1
        end
                                           
    fun compileTpdecsToTldecs tpstrdecs accModuleEnv =
        let
            fun printDiagnoses diagnoses =
                app (fn diagnosis => 
                        (print(C.prettyPrint(UE.format_errorInfo diagnosis));
                         print "\n"))
                    diagnoses
            (* initial unique id allocation *)
            val _ = ID.init()
            (* module compile*)
            val (deltaModuleEnv, tpflatdecs) =
                ModuleCompiler.moduleCompileCodeFragmentWithPathBasis accModuleEnv tpstrdecs
            (* match compile *)
            val (rcdecs, warnings) = MatchCompiler.compile tpflatdecs
            (* record compile *)
            val tldecs = RecordCompiler.compile rcdecs
            val _ =
                if !C.checkType
                then
                    let
                        val diagnoses =
                            TypeCheckTypedLambda.typechekTypedLambda tldecs
                    in
                        printDiagnoses diagnoses
                    end
                else ()
        in
            (tldecs, deltaModuleEnv)
        end

    fun genTyInstantiationCode (richEnv, strictEnv) (accModuleEnv:SME.deltaModuleEnv) loc =
        let
            val tpstrdecs =
                TIT.generateInstantiatedStructure (Path.NilPath, loc) (richEnv, strictEnv)
(*            val _ = print "\n type instantiation code \n"
            val _ =  app
                         (fn dec =>
                             print
                                 (TypedCalcFormatter.tptpmstrdeclToString [] dec ^ "\n"))
                         tpstrdecs
            val _ = print "\n ***************************** \n"*)
            val (tldecs, deltaModuleEnv) = 
                compileTpdecsToTldecs tpstrdecs accModuleEnv
        in 
            (tldecs, deltaModuleEnv)
        end

    fun pruneUnGeneralizedInLinkageUnitImportVarEnv
            (commonVarEnv, linkageUnitVarEnv) =
            SEnv.foldli
            (fn (varName, commonIdstate, newLinkageUnitVarEnv) =>
                case SEnv.find(linkageUnitVarEnv, varName) of
                    NONE => 
                    raise Control.Bug 
                              ("common variable name should be contained in linkageUnit"
                               ^varName)
                  | SOME linkageIdstate =>
                    SEnv.insert(newLinkageUnitVarEnv, varName, linkageIdstate))
            SEnv.empty
            commonVarEnv

    fun pruneUnGeneralizedInLinkageUnitImportStrEnv 
        (T.STRUCTURE commonStrEnvCont, T.STRUCTURE linkageUnitStrEnvCont) =
        let
          val newLinkageUnitStrEnv =
            SEnv.foldli
            (fn (strName, 
                 {env = (_, subCommonVarEnv, subCommonStrEnv),...}, 
                 newLinkageUnitStrEnv) =>
                case SEnv.find(linkageUnitStrEnvCont, strName) of
                    NONE => 
                    raise Control.Bug ("common structure should be contained in linkageUnit:"^strName)
                  | SOME {env = (subUnitTyConEnv, 
                                 subUnitVarEnv, 
                                 subUnitStrEnv),
                          id, 
                          strpath,
                          name} =>
                    let
                        val newSubUnitVarEnv = 
                            pruneUnGeneralizedInLinkageUnitImportVarEnv
                                (subCommonVarEnv, subUnitVarEnv)
                        val newSubUnitStrEnv =
                            pruneUnGeneralizedInLinkageUnitImportStrEnv 
                                (subCommonStrEnv, subUnitStrEnv)
                    in
                        SEnv.insert(
                                    newLinkageUnitStrEnv,
                                    strName,
                                    {
                                      env = (subUnitTyConEnv, 
                                             newSubUnitVarEnv, 
                                             newSubUnitStrEnv),
                                      id = id, 
                                      strpath = strpath,
                                      name = name
                                     }
                                    )
                    end)
            SEnv.empty
            commonStrEnvCont
        in
          T.STRUCTURE newLinkageUnitStrEnv
        end
                        
    fun pruneUnGeneralizedInLinkageUnitImportTypeEnv 
            (commonImportTypeEnv : STE.typeEnv, linkageUnitTypeEnv : STE.typeEnv) =
            let
                val varEnv = pruneUnGeneralizedInLinkageUnitImportVarEnv
                                 (#varEnv commonImportTypeEnv,
                                  #varEnv linkageUnitTypeEnv)
                val strEnv = pruneUnGeneralizedInLinkageUnitImportStrEnv
                                        (#strEnv commonImportTypeEnv,
                                         #strEnv linkageUnitTypeEnv)
            in
                {tyConEnv = #tyConEnv linkageUnitTypeEnv,
                 varEnv = varEnv,
                 strEnv = strEnv}
            end
    (*************************************************************************
     * substitute global index with type instantiated val identifier 
     *) 
    fun updateAccPathBasisWithInstDeltaPathBasis 
            (accPathBasis :PE.pathBasis, instDeltaPathBasis:PE.pathBasis) 
      =
      let
          val (accPathFunEnv, accPathEnv) = accPathBasis
          val (instDeltaPathFunEnv, instDeltaPathEnv) = instDeltaPathBasis
          val newPathEnv = 
              PE.extendPathEnvWithPathEnv {newPathEnv = instDeltaPathEnv,
                                           oldPathEnv = accPathEnv}
      in
          (accPathFunEnv, newPathEnv)
      end

    fun updateAccModuleEnvWithInstDeltaModuleEnv 
            (accTopModuleEnv:SME.moduleEnv, instDeltaModuleEnv:SME.deltaModuleEnv) 
      =
      let
          val accPathBasis = 
              PE.projectPathBasisInTop (#topPathBasis accTopModuleEnv)
          val newPathBasis = 
              updateAccPathBasisWithInstDeltaPathBasis
                  (accPathBasis, #pathBasis instDeltaModuleEnv)
          val newTopPathBasis =
              PE.extendTopPathBasisWithPathBasis
                  {topPathBasis = PE.emptyTopPathBasis, pathBasis = newPathBasis}
      in
          {freeGlobalArrayIndex = #freeGlobalArrayIndex instDeltaModuleEnv,
           freeEntryPointer = #freeEntryPointer instDeltaModuleEnv,
           topPathBasis = newTopPathBasis}
      end

    (*************************************************************************)
    fun constructAlreadyImportValIndexEnvInPathVarEnv
            (updatedCommonPathVarEnv:PE.pathVarEnv, accPathVarEnv:PE.pathVarEnv) 
      =
      SEnv.foldli 
      (fn (varName, PE.TopItem (pathVar,newGlobalIndex,ty), indexEnv) =>
          case SEnv.find(accPathVarEnv, varName) of
              NONE => raise Control.Bug "common value identifier should in accPathVarEnv"
            | SOME (PE.TopItem (pathVar, oldGlobalIndex ,ty)) =>
              IndexEnv.insert(indexEnv, (getKeyInIndex oldGlobalIndex), newGlobalIndex)
            | SOME (PE.CurItem _) => raise Control.Bug "CurItem should not occurs in pathBasis")
      IndexEnv.empty
      updatedCommonPathVarEnv

    fun constructAlreadyImportValIndexEnvInPathStrEnv
            (updatedCommonPathStrEnv, accPathStrEnv)
      =
      SEnv.foldli
      (fn (strName, 
           PE.PATHAUX (subCommonPathVarEnv, subCommonPathStrEnv),
           indexEnv) =>
          case SEnv.find(accPathStrEnv, strName) of
              NONE => raise Control.Bug "common structure should in accPathStrEnv"
            | SOME (PE.PATHAUX (subAccPathVarEnv, subAccPathStrEnv)) =>
              let
                  val indexEnv1 = 
                      constructAlreadyImportValIndexEnvInPathVarEnv
                          (subCommonPathVarEnv,  subAccPathVarEnv)
                  val indexEnv2 =
                      constructAlreadyImportValIndexEnvInPathStrEnv
                          (subCommonPathStrEnv,  subAccPathStrEnv)
              in
                  (IndexEnv.unionWith
                       (fn _ => raise Control.Bug "duplicate element")
                       (indexEnv,
                        (IndexEnv.unionWith
                             (fn _ => raise Control.Bug "duplicate element")
                             (indexEnv1, indexEnv2))))
              end)
      IndexEnv.empty
      updatedCommonPathStrEnv
                          
    fun constructAlreadyImportValIndexEnvInPathBasis
            (updatedCommonModuleEnv:PE.pathBasis, accImportME:PE.pathBasis) 
      = 
      let
          val indexEnv1 = 
              constructAlreadyImportValIndexEnvInPathVarEnv
                  (#1 (#2 updatedCommonModuleEnv), #1 (#2 accImportME))
          val indexEnv2 =
              constructAlreadyImportValIndexEnvInPathStrEnv
                  (#2 (#2 updatedCommonModuleEnv), #2 (#2 accImportME))
      in
          IndexEnv.unionWith (fn _ => raise Control.Bug "duplicate element")
                             (indexEnv1, indexEnv2)
      end
        
    (***************************************************************************
     * convert common generalized imported type env into pathBasis
     *)
    fun varEnvToAbstractPathVarEnv varEnv freeEntryPointer =
        SEnv.foldli 
        (fn (varName, idstate, (absPathVarEnv, freeEntryPointer)) =>
            case idstate of
                T.VARID {name, strpath, ty} =>
                let
                    val (newFreeEntryPointer, newGlobalIndex) =
                        IndexAllocator.allocateAbstractIndex freeEntryPointer
                in
                    (SEnv.insert(absPathVarEnv, 
                                 varName,
                                 PE.TopItem ((strpath,name), newGlobalIndex, ty)) : PE.pathVarEnv,
                     newFreeEntryPointer)
                end
              | _ => (absPathVarEnv, freeEntryPointer))
        (SEnv.empty, freeEntryPointer)
        varEnv

    fun strEnvToAbstractPathStrEnv (T.STRUCTURE strEnvCont) freeEntryPointer =
      SEnv.foldli 
      (fn (strName, 
           {env = (_, subVarEnv, subStrEnv),...},
           (absPathStrEnv, freeEntryPointer)) =>
       let
         val (newSubVarEnv:PE.pathVarEnv, freeEntryPointer1) = 
           varEnvToAbstractPathVarEnv subVarEnv freeEntryPointer
         val (newSubStrEnv, freeEntryPointer2) =
           strEnvToAbstractPathStrEnv subStrEnv freeEntryPointer1
       in
         (SEnv.insert(absPathStrEnv, 
                      strName, 
                      PE.PATHAUX (newSubVarEnv, newSubStrEnv)),
          freeEntryPointer2)
       end)
      (SEnv.empty, freeEntryPointer)
      strEnvCont
                
    fun typeEnvToAbstractPathBasis (typeEnv:STE.typeEnv) freeEntryPointer =
        let
            val (abstractPathVarEnv, freeEntryPointer1) = 
                varEnvToAbstractPathVarEnv (#varEnv typeEnv) freeEntryPointer
            val (abstractPathStrEnv, freeEntryPointer2) =
                strEnvToAbstractPathStrEnv (#strEnv typeEnv) freeEntryPointer1
        in
            ((SEnv.empty, (abstractPathVarEnv, abstractPathStrEnv)),
             freeEntryPointer2)
        end
                
    (******************************************************************************)
    local 
        exception NotClosed
    in
        fun recursiveCheckImportTyConEnvInAccTyConEnv
                (importTyConEnv, accTyConEnv) 
          =
          SEnv.mapi
              (fn (tyConName, _ ) =>
                  case SEnv.find(accTyConEnv, tyConName) of
                      NONE => raise NotClosed
                    | SOME _ => ())
              importTyConEnv
              
        fun recursiveCheckImportVarEnvInAccVarEnv (importVarEnv, accVarEnv) 
          =
          SEnv.mapi
              (fn (varName, _ ) =>
                  case SEnv.find(accVarEnv, varName) of
                      NONE => raise NotClosed
                    | SOME _ => ())
              importVarEnv

        fun recursiveCheckImportStrEnvInAccStrEnv 
                (T.STRUCTURE importStrEnvCont, T.STRUCTURE accStrEnvCont) 
          = 
          SEnv.mapi
              (fn (strName, {env = (subImportTyConEnv,
                                    subImportVarEnv,
                                    subStrEnv),...}) =>
                  case SEnv.find(accStrEnvCont, strName) of
                      NONE => raise NotClosed
                    | SOME {env = (subAccTyConEnv,
                                   subAccVarEnv,
                                   subAccStrEnv),...} =>
                      let
                          val _ = 
                              recursiveCheckImportTyConEnvInAccTyConEnv
                                  (subImportTyConEnv, subAccTyConEnv)
                          val _ = 
                              recursiveCheckImportVarEnvInAccVarEnv
                                  (subImportVarEnv, subAccVarEnv)
                          val _ = 
                              recursiveCheckImportStrEnvInAccStrEnv
                                  (subStrEnv, subAccStrEnv)
                      in () end)
              importStrEnvCont
          
        fun recursiveCheckImportTypeEnvInAccTypeEnv 
                (importTypeEnv:STE.typeEnv, accTypeEnv:STE.typeEnv) =
            let
                val _ = 
                    recursiveCheckImportTyConEnvInAccTyConEnv
                    (#tyConEnv importTypeEnv,
                     #tyConEnv accTypeEnv)
                val _ = 
                    recursiveCheckImportVarEnvInAccVarEnv
                    (#varEnv importTypeEnv,
                     #varEnv accTypeEnv)
                val _ = 
                    recursiveCheckImportStrEnvInAccStrEnv
                    (#strEnv importTypeEnv,
                     #strEnv accTypeEnv)
            in () end

        fun checkClosed linkageUnits = 
            let
                exception NotClosed
            in
                ((foldl 
                      (fn (linkageUnit:LinkageUnit.linkageUnit, accTypeEnv) =>
                          let
                              val {importTypeEnv, exportTypeEnv,...} = 
                                  # staticTypeEnv linkageUnit
                              val _ = recursiveCheckImportTypeEnvInAccTypeEnv
                                          (importTypeEnv, accTypeEnv)
                          in
                              STE.extendTypeEnvWithTypeEnv
                                  {newTypeEnv = exportTypeEnv,
                                   oldTypeEnv = accTypeEnv}
                          end)
                      STE.emptyTypeEnv
                      linkageUnits);
                 true)
            end
                handle NotClosed => false
    end (* end local check closed *)

    (*****************************************************************************)
    fun checkObjectFileNames fileNames =
        app (fn fileName => 
                if OS.Path.ext fileName = SOME "smo"  
                then ()
                else raise LE.IllegalObjectFileSuffix {fileName = fileName})
            fileNames

    (*****************************************************************************)
    fun calcValIndexListPathVarEnv pathVarEnv =
        SEnv.foldl
            (fn (item, indexList) =>
                case item of
                PE.TopItem itemInfo => itemInfo :: indexList
              | _ => raise Control.Bug "CurItem occurs")
            nil
            pathVarEnv
        
    fun calcValIndexListPathStrEnv pathStrEnv =
        SEnv.foldl
            (fn (PE.PATHAUX(subPathVarEnv, subPathStrEnv), indexList) =>
                let
                    val indexList1 = calcValIndexListPathVarEnv subPathVarEnv
                    val indexList2 = calcValIndexListPathStrEnv subPathStrEnv
                in
                    indexList @ indexList1 @ indexList2
                end)
            nil
            pathStrEnv
    (******************************************************************************)
    fun pruneOverridenSetGlobalTldec tldecs IndexSet =
        foldr (fn (tldec, newTldecs) =>
                  case tldec of
                      TypedLambda.TLVAL
                          {bindList =
                           [{boundExp = 
                             TypedLambda.TLSETGLOBALVALUE {arrayIndex,offset,...},...}
                            ],...} 
                          => 
                          if IndexSet.member(IndexSet,(arrayIndex, offset)) then 
                              newTldecs
                          else tldec :: newTldecs
                    | _ => tldec :: newTldecs)
              nil
              tldecs
  (******************************************************************************)

    fun exnTagSubstMergeList nil subst = subst
      | exnTagSubstMergeList (h :: t) subst = 
        exnTagSubstMergeList t (IEnv.unionWith #1 (h, subst))

    fun freshExnTagSetSubst exnTagSet =
        ISet.foldl
        (fn (oldExnTag, (subst, set)) =>
            let
                val newExnTag = T.newExnTag()
            in
                (IEnv.insert(subst, oldExnTag, newExnTag),
                 ISet.add(set, newExnTag))
            end)
        (IEnv.empty, ISet.empty)
        exnTagSet

    fun freshExnTagVarEnv varEnv =
        SEnv.foldli
            (fn (varName, idstate, (varEnv, subst)) =>
                case idstate of
                    T.CONID {tag,name,strpath,funtyCon,ty,tyCon} =>
                    if ID.eq(#id tyCon, PT.exnTyConid) then
                        let
                            val newTag = T.nextExnTag ()
                        in
                            (SEnv.insert(varEnv,
                                         varName,
                                         T.CONID {name = name,
                                                  strpath = strpath,
                                                  funtyCon = funtyCon,
                                                  ty = ty,
                                                  tag = newTag,
                                                  tyCon = tyCon}),
                             IEnv.insert(subst, tag, newTag))
                        end
                    else (SEnv.insert(varEnv, varName, idstate),
                          subst)
                  | idstate => 
                    (SEnv.insert(varEnv, varName, idstate), subst))
            (SEnv.empty, IEnv.empty)
            varEnv

    fun freshExnTagStrEnv (T.STRUCTURE  strEnvCont) =
      let
        val (strEnvCont, subst) =
          SEnv.foldli
            (fn (strName,
                 {
                   id, 
                   name, 
                   strpath, 
                   env = (subTyConEnv, subVarEnv, subStrEnv)
                  },
                 (strEnvCont, subst))=>
                let
                    val (newSubVarEnv, subst1) = freshExnTagVarEnv subVarEnv
                    val (newSubStrEnv, subst2) = freshExnTagStrEnv subStrEnv
                in
                    (SEnv.insert(strEnvCont,
                                 strName,
                                 {
                                   id = id, 
                                   name = name, 
                                   strpath = strpath, 
                                   env = (subTyConEnv,
                                          newSubVarEnv,
                                          newSubStrEnv)
                                  }
                                 ),
                     exnTagSubstMergeList [subst, subst1, subst2] IEnv.empty)
                end)
            (SEnv.empty, IEnv.empty)
            strEnvCont
      in
        (T.STRUCTURE strEnvCont, subst)
      end


    fun freshExnTagTypeEnv (typeEnv:STE.typeEnv) =
        let
            val (varEnv, exnTagSubst1) = 
                freshExnTagVarEnv (#varEnv typeEnv)
            val (strEnv, exnTagSubst2) =
                freshExnTagStrEnv (#strEnv typeEnv)
        in
            ({tyConEnv = #tyConEnv typeEnv,
              varEnv = varEnv,
              strEnv = strEnv},
             IEnv.unionWith #1 (exnTagSubst1, exnTagSubst2))
        end
            
    fun substExnTagStrEnv exnTagSubst (T.STRUCTURE strEnvCont) =
      T.STRUCTURE
      (
        SEnv.map (fn {
                      id, 
                      name, 
                      strpath, 
                      env = (tyConEnv, varEnv, strEnv)
                      } =>
                  {id = id, 
                   name = name, 
                   strpath = strpath, 
                   env = (tyConEnv,
                          SU.instExnTagBySubstOnVarEnv exnTagSubst varEnv,
                          substExnTagStrEnv exnTagSubst strEnv)}
                  )
                 strEnvCont
      )
                 
    fun substExnTagTypeEnv exnTagSubst (typeEnv:STE.typeEnv) =
        let
            val varEnv = 
                SU.instExnTagBySubstOnVarEnv exnTagSubst (#varEnv typeEnv)
            val strEnv =
                substExnTagStrEnv exnTagSubst (#strEnv typeEnv)
        in
            {tyConEnv = #tyConEnv typeEnv,
             varEnv = varEnv,
             strEnv = strEnv}
        end

    fun typeEnvToEnv (typeEnv:STE.typeEnv) =
        (#tyConEnv typeEnv, #varEnv typeEnv, #strEnv typeEnv)
            

    (*****************************************************************************
     * sizeTag substitution computation
     *)
    fun sizeTagSubstTyConEnv (abstractTyConEnv, implTyConEnv) = 
        SEnv.foldli 
        (fn (tyConName, T.TYSPEC {spec = {id,...}, ...}, sizeTagSubst) =>
            (case SEnv.find(implTyConEnv, tyConName) of
                 NONE => sizeTagSubst
               | SOME tyBindInfo =>
                 let
                     val sizeTagExp = STE.sizeTagTyBindInfo tyBindInfo
                 in
                     ID.Map.insert(sizeTagSubst, id, sizeTagExp)
                 end)
          | (tyConName, _, sizeTagSubst) => sizeTagSubst)
        ID.Map.empty
        abstractTyConEnv

    fun sizeTagSubstStrEnv (T.STRUCTURE abstractStrEnvCont, T.STRUCTURE implStrEnvCont) =
        SEnv.foldli
        (fn (strName, 
             {env = (subAbstractTyConEnv, _, subAbstractStrEnv),...},
             sizeTagSubst) =>
            case SEnv.find(implStrEnvCont, strName) of
                NONE => sizeTagSubst
              | SOME {env=(subImplTyConEnv, _, subImplStrEnv),...} =>
                let
                    val sizeTagSubst1 = 
                        sizeTagSubstTyConEnv (subAbstractTyConEnv, subImplTyConEnv)
                    val sizeTagSubst2 =
                        sizeTagSubstStrEnv(subAbstractStrEnv, subImplStrEnv)
                in
                    ID.Map.unionWith 
                        #1
                        (sizeTagSubst,
                         (ID.Map.unionWith 
                              #1 
                              (sizeTagSubst1, sizeTagSubst2))
                         )
                end)
        ID.Map.empty
        abstractStrEnvCont

    fun sizeTagSubstEnv (abstractEnv:T.Env, implEnv:T.Env) =
        let
            val sizeTagSubst1 = sizeTagSubstTyConEnv (#1 abstractEnv, #1 implEnv)
            val sizeTagSubst2 = sizeTagSubstStrEnv(#3 abstractEnv, #3 implEnv)
        in
            ID.Map.unionWith #1 (sizeTagSubst1, sizeTagSubst2)
        end

    fun sizeTagSubstTyConSubst tyConSubst =
        ID.Map.map 
            (fn tyBindInfo => STE.sizeTagTyBindInfo tyBindInfo) 
            tyConSubst

  (**************************************************************************)
    fun domainIDMap IDMap =
        ID.Map.foldli 
        (fn (id, _, domSet) =>
            ID.Set.add(domSet, id))
        ID.Set.empty
        IDMap

  (**************************************************************************)
    fun substEffectKeepingMerge (newSubstTyConEnv, oldSubstTyConEnv) =
        let
            val instantiatedOldSubstTyConEnv =
                ID.Map.map 
                    (fn tyBindInfo => 
                        let
                            val (visited, newTyBindInfo) =
                                TCU.substTyConInTyBindInfo ID.Set.empty 
                                                           newSubstTyConEnv
                                                           tyBindInfo
                        in
                            newTyBindInfo
                        end)
                    oldSubstTyConEnv
            val mergedSubstTyConEnv =
                ID.Map.unionWith #1 (newSubstTyConEnv, instantiatedOldSubstTyConEnv)
        in
            mergedSubstTyConEnv
        end
  end (* end local *)
end (* end structure *)
