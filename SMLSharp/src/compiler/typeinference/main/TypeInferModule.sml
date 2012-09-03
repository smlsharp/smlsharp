(**
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: TypeInferModule.sml,v 1.96 2008/08/24 03:54:41 ohori Exp $
 *)
structure TypeInferModule =
struct
local 
  structure A = Absyn
  structure C = Control
  structure E = TypeInferenceError
  structure PDT = PredefinedTypes
  structure PT = PatternCalcWithTvars
  structure TC = TypeContext
  structure TIC = TypeInferenceContext
  structure TPU = TypedCalcUtils
  structure U = Unify
  structure TIT = TypeInstantiationTerm
  structure TIU = TypeInferenceUtils
  structure TIFC = TypeInferCore
  structure TCU = TypeContextUtils
  structure TU = TypesUtils
  structure SU = SigUtils
  structure T = Types
  structure TCC = TypedCalc 
  structure NM = NameMap
  structure NPEnv = NameMap.NPEnv
  structure PCF = PatternCalcFlattened
  structure SigCheck = SignatureCheck
in 

  (* 
   * for value description (val x : int and ....) lists in a signature.
   *)
  fun typeinfValdescs (basis : TIC.basis) nil loc = 
      TC.emptyContext
    | typeinfValdescs (basis : TIC.basis) ((namePath, rawTy) :: rem) loc =
      (* rule 79 *)
      let
        fun makeClosureTy rawTy =
          let
            fun tvarsInRawTy rawTy tvarSEnv =
              case rawTy of
                A.TYWILD loc => 
                  raise Control.Bug "A.TYWILD in type infernceModule"
              | A.TYID (tvar as {name, eq}, loc) => 
                  (case SEnv.find (tvarSEnv,name) of
                     NONE => SEnv.insert(tvarSEnv, name, tvar)
                   | _ => tvarSEnv)
              | A.TYRECORD (stringRawtyList, loc) =>
                  foldl
                  (fn ((l, rawTy), tvarSEnv) => tvarsInRawTy rawTy tvarSEnv)
                  tvarSEnv
                  stringRawtyList
              | A.TYCONSTRUCT (rawtyList, longTyCon, loc) =>
                  raise Control.Bug "A.TYCONSTRUCT in type infernceModule"
              | A.TYCONSTRUCT_WITH_NAMEPATH (rawtyList, longTyCon, loc) =>
                  foldl
                  (fn (rawTy, tvarSEnv) => tvarsInRawTy rawTy tvarSEnv)
                  tvarSEnv
                  rawtyList
              | A.TYTUPLE (rawtyList, loc) =>
                  foldl
                  (fn (rawTy, tvarSEnv) => tvarsInRawTy rawTy tvarSEnv)
                  tvarSEnv
                  rawtyList
              | A.TYFUN (rawty1, rawty2, loc) =>
                  let 
                    val tvarSEnv = tvarsInRawTy rawty1 tvarSEnv
                  in 
                    tvarsInRawTy rawty2 tvarSEnv 
                  end
              | A.TYFFI (attributes, _, argTys, retTy, loc) =>
                  foldl
                  (fn (rawTy, tvarSEnv) => tvarsInRawTy rawTy tvarSEnv)
                  (tvarsInRawTy retTy tvarSEnv)
                  argTys
              | A.TYPOLY _ => tvarSEnv
            val tvarSEnv = tvarsInRawTy rawTy SEnv.empty
            val kindedTvarList =
                map (fn tvar => (tvar, A.UNIV)) (SEnv.listItems tvarSEnv)
          in
            case kindedTvarList of
              nil => rawTy
            | _ => A.TYPOLY(kindedTvarList, rawTy, A.getLocTy rawTy)
          end

        val closedRawTy = makeClosureTy rawTy
        val tau = TIFC.evalRawty basis closedRawTy
        val valDesc = {namePath = namePath, ty = tau}
        (*
         Ohori: Need to check.
         This was originally coded below.
          val context1 = 
               TC.bindVarInEmptyContext (vidString, T.VARID varPathInfo)
         Since there should not be any free type variables shared by others,
         it should be a toplevel binding.
         *)
        val context1 = 
            TC.bindVarInEmptyContext
              (T.toplevelDepth, namePath, T.VARID valDesc)
        val context2 =
            typeinfValdescs basis rem loc
      in
          TC.mergeContexts (context1, context2)
      end

(*
  and typeinfSpecKind specKind =
      case specKind of
          A.ATOM => T.ATOMty
        | A.DOUBLE => T.DOUBLEty
        | A.BOXED => T.BOXEDty
        | A.GENERIC => T.GENERICty
*)
 (*
  * for type description ([type] 'a foo and ...) in a signature.
  *)
  and typeinfTypdescs eqKind (basis : TIC.basis) nil loc = 
      TC.emptyContext
    | typeinfTypdescs eqKind (basis : TIC.basis) 
                      ((tyvars : {name:string, eq:Absyn.eq} list, 
                        (tyconName, strpath)) :: rem) loc =
      (* rule 80-for rule 69 *)
      let
        val tyCon =
            {name = tyconName,
             strpath = strpath,
             abstract = false,
             id = Counters.newTyConId (),
             eqKind = ref eqKind,
             tyvars = map
                        (fn {name, eq} =>
                            if eq = Absyn.EQ then T.EQ else T.NONEQ) tyvars,
             constructorHasArgFlagList = nil}
        val context1 =
            TC.bindTyConInEmptyContext ((tyconName, strpath), T.TYSPEC tyCon)
        val context2 = typeinfTypdescs eqKind basis rem loc
      in
          TC.mergeContexts (context1, context2)
      end

  (*
   * exception descriptions ([exception] Ex and ...)  in a signature
   *)
  and typeinfExdescs (basis:TIC.basis) nil loc =
      TC.emptyContext
    | typeinfExdescs (basis:TIC.basis) ((namePath, rawTyOpt) :: rem) loc=
      (*rule 83*)
      let
        val tau =
            case rawTyOpt of
              NONE => NONE
            | SOME rawTy => SOME(TIFC.evalRawty basis rawTy)
        val _ =
            case tau of
              NONE      => ()
            | SOME tau' =>
              if  OTSet.isEmpty (TU.EFTV tau') then () 
              else E.enqueueError
                     (loc,
                      E.FreeTypeVariablesInExceptionType
                        ({exid = NM.namePathToString(namePath)}))
        val exnPathInfo = TIU.makeExnConPath namePath tau
        val context1 = TC.bindVarInEmptyContext
                         (T.toplevelDepth, namePath, T.EXNID exnPathInfo)
        val context2 = typeinfExdescs basis rem loc
      in
          TC.mergeContexts (context1, context2)
      end

  (**
   * for a signature (val valdescs etc)
   * @params currentcontext ptspec
   * @return  an Environment and tpspec
   *)
  and typeinfSpec (basis:TIC.basis) ptspec =
      case ptspec of
        PT.PTSPECVAL (valdescs, loc) => 
        (* rule 68 *) (* generalization operation is moved to rule 79*)
        typeinfValdescs basis valdescs loc
      | PT.PTSPECTYPE(typdescs, loc) =>
        (* rule 69 *)
        typeinfTypdescs T.NONEQ basis typdescs loc
      | PT.PTSPECTYPEEQUATION (tvarListStringRawTy
                                 as (_,tyConNamePath,_) ,loc) =>
        (*
         * sig type t = int end ==> sig include type t end
                                    where type t = int end
         * include sig ptspec end where stringListLongTyConTyList
         *)
        (* appendix A *)
          let
            fun expandManifestTypeDesc (tyvars, tyConNamePath, rawTy) =
                PT.PTSPECSIGWHERE
                    (
                     PT.PTSPECTYPE([(tyvars, tyConNamePath)], loc),
                     [(tyvars, tyConNamePath, rawTy)],
                     loc
                     )
            val newContext as {tyConEnv,...} =
                  typeinfSpec
                    basis
                    (expandManifestTypeDesc tvarListStringRawTy)
            val tyBindInfo = 
                case NPEnv.find(tyConEnv, tyConNamePath) of
                  NONE => 
                    raise
                      Control.BugWithLoc
                        (("unbound tyCon:"^NM.namePathToString(tyConNamePath)),
                         loc)
                | SOME tyFun => tyFun
          in
              newContext
          end
      | PT.PTSPECEQTYPE(typdescs, loc) =>
          (* rule 70 *)
        typeinfTypdescs T.EQ basis typdescs loc
      | PT.PTSPECDATATYPE(prefix, datadescs, loc) => 
          (* rule 71 *)
          let
            (* add op field to constructor list,
             * it has no harm, since it plays no role in 
             * type inference for datatype 
             *)
            val newdatadescs = 
              map
              (fn (tvars, tyConName, constructorlist) =>
               let
                 val newconstructorlist =
                   map (fn (con, tyoption) => (false, con, tyoption))
                       constructorlist
               in
                 (tvars, tyConName, newconstructorlist)
               end)
              datadescs
            (* 
              Ohori: 
                val (newContext, tyCons) = 
                      TIFC.typeinfDatatypeDecl cc newdatadescs loc
            *)
            val (newContext, tyCons) = 
                  TIFC.typeinfDatatypeDecl
                    T.toplevelDepth basis (prefix, newdatadescs) loc
          in
              newContext
          end
      | PT.PTSPECREPLIC((tyConName, tyConStrpath), rightTyNamePath, loc) =>
        (* rule 72 *)
        let 
            val tyBindInfoOpt = TIC.lookupTyConInBasis (basis, rightTyNamePath)
        in
            case tyBindInfoOpt of
                SOME(T.TYCON {tyCon = rightTyCon as
                                      {name, 
                                       strpath, 
                                       abstract, 
                                       tyvars, 
                                       id, 
                                       eqKind, 
                                       constructorHasArgFlagList
                                       },
                                      datacon}) => 
                let
                    val leftDataTyInfo : T.dataTyInfo =
                        {tyCon =
                         {name = tyConName,
                          strpath = tyConStrpath,
                          abstract = abstract,
                          tyvars = tyvars,
                          id = id,
                          eqKind = ref (!eqKind),
                          constructorHasArgFlagList = constructorHasArgFlagList
                         },
                         datacon = SEnv.empty} 
                    val tyConSubst =
                        TyConID.Map.singleton(id, T.TYCON leftDataTyInfo)
                    val newDatacon = 
		        TCU.substTyConInDataConFully tyConSubst datacon
                    val leftDataTyInfo =
                        {tyCon = #tyCon leftDataTyInfo, datacon = newDatacon}
                    val context1 = 
                        TC.bindTyConInEmptyContext
                          ((tyConName, tyConStrpath), T.TYCON leftDataTyInfo)
                    val context2 = 
                        (* do not propagate varEnv of abstype *)
                        if not abstract then
                            let
                              val (newDatacon, _) = 
                                  TIU.setPrefixDataCon
                                    ((#datacon leftDataTyInfo), tyConStrpath)
                            in
                              TC.extendContextWithVarEnv
                                (context1, newDatacon)
                            end
                        else context1
                in
                    context2
                end
            | SOME _ => 
              (
               E.enqueueError
                 (
                  loc,
                  E.TyFunFoundInsteadOfTyCon 
                    {tyFun = NM.namePathToString(rightTyNamePath)}
                 );
               TC.emptyContext
               )
            | _ =>
              (
               E.enqueueError
                 (
                  loc,
                  E.TyConNotFoundInReplicateData
                    ({tyCon = NM.namePathToString(rightTyNamePath)})
                 );
               TC.emptyContext
               )
          end
      | PT.PTSPECEXCEPTION (exdescs, loc) =>
          (* rule 73 *)
        typeinfExdescs basis exdescs loc
      | PT.PTSPECSEQ(ptspec1, ptspec2, loc) => 
        (* rule 77 *)
        let
          val context1 = typeinfSpec basis ptspec1
          val newBasis = TIC.extendBasisWithContext(basis, context1)
          val context2 = typeinfSpec newBasis ptspec2
          val context3 = 
              TC.unionContexts(context2, context1)
              handle TC.exDuplicateElem id => 
                     (
                      E.enqueueError(
                                     loc,
                                     E.DuplicateSpecification{id = id}
                                     );
                      TC.emptyContext
                      )
        in
          context3
        end
      | PT.PTSPECSHARE (ptspec, nil, loc) => typeinfSpec basis ptspec
      | PT.PTSPECSHARE (ptspec, longTyConList, loc) =>
          (* here we just equate id field in tyCon.
             No check is performed.
             At the time of abstraction, we collect the id with its eqkind.
             At the time of realizer computation, we check the equality.
          *)
         (let
              val fromTyConId = Counters.newTyConId ()
              val context1 = typeinfSpec basis ptspec
              val newBasis = TIC.injectContextToBasis context1 
              val (representativeTyConId, hdEqKind) = 
                  let
                    val hdLongTyCon = List.hd longTyConList
                    val (rpTyConId, eqKind) =
                        SU.longTyConIdEqKind newBasis hdLongTyCon
                  in
                 (* ToDo : explanation about this comparation is necessary. *)
                 (*
                   if fromTyConId <= rpTyConId
                 *)
                   if
                     (TyConID.compare(fromTyConId, rpTyConId) <> GREATER)
                   then (rpTyConId, eqKind)
                   else
                     raise E.RigidTypeInSharing 
                             {id = NM.namePathToString(hdLongTyCon)}
                  end
              val (tyConIdEqSubst, othersOverallEqKind) = 
                  List.foldr 
                    (fn (longTyCon, (tyConIdSubst, othersOverallEqKind)) =>
                        let
                          val (tyConId, eqKind) = 
                              SU.longTyConIdEqKind newBasis longTyCon
                        in
                          (* ToDo : explanation about this comparation
                           * is necessary. *)
                            (*
                             if fromTyConId <= tyConId then
                             *)
                          if
                            (TyConID.compare(fromTyConId, tyConId) <> GREATER)
                          then
                            (TyConID.Map.insert
                               (tyConIdSubst, tyConId, representativeTyConId),
                             if eqKind = T.EQ then eqKind
                             else othersOverallEqKind)
                          else
                            raise
                              E.RigidTypeInSharing
                                {id = NM.namePathToString(longTyCon)}
                        end)
                    (TyConID.Map.empty, T.NONEQ)
                    longTyConList
              val newTyConIdEqSubst = 
                  if hdEqKind = T.EQ orelse othersOverallEqKind = T.EQ then
                    TyConID.Map.map (fn newId => (newId, T.EQ)) 
                                    tyConIdEqSubst
                  else 
                    TyConID.Map.map (fn newId => (newId, T.NONEQ)) 
                                    tyConIdEqSubst
              val newContext =
                  SU.equateTyConIdEqInContext newTyConIdEqSubst context1
          in 
            newContext
          end
          handle exn as E.TyConNotFoundInShare _ => 
                 (E.enqueueError (loc, exn);(TC.emptyContext))
               | exn as E.SharingOnTypeFun _ =>
                 (E.enqueueError (loc, exn);(TC.emptyContext))
               | exn as E.RigidTypeInSharing _ =>
                 (E.enqueueError (loc, exn);(TC.emptyContext))
         )
      | PT.PTSPECEMPTY => TC.emptyContext
      | PT.PTSPECPREFIXEDSIGID ((sigName, prefix), loc) =>
        let
          val Env =
              case TIC.lookupSigmaInBasis(basis, sigName) of
                SOME (T.SIGNATURE(tyConIdSet, sigPathInfo as {env,...})) =>
                SigCheck.sigTyNameRename (tyConIdSet, env) 
              | NONE =>
                (E.enqueueError (loc, E.SignatureNotFound{id = sigName});
                 T.emptyE)
          val newEnv = TIU.addStrpathInEnv Env prefix
        in
            TC.injectEnvToContext newEnv
        end
      | PT.PTSPECSIGWHERE (ptspec, stringListLongTyConTyList, loc) => 
        let
          val fromTyConId = Counters.newTyConId ()
          val context1 = typeinfSpec basis ptspec
          val basis1 = TIC.injectContextToBasis context1 
          val (tyConSubst, pathTyFunInfoList) =
              List.foldr
                (fn ((typarams,
                      longTyCon
                        as (name, path), ty),
                     (tyConIdEnv, tyFunInfoList)) =>
                  let
                    val (_, newTyFun) = TIFC.makeTyFun 
                                          T.toplevelDepth 
                                          basis 
                                          (typarams, (name, path), ty)
                    val tyConId =
                        case TIC.lookupTyConInBasis (basis1, longTyCon)
                         of
                          NONE => 
                          raise
                            E.TyConNotFoundInWhereType
                              {tyCon = NM.namePathToString(longTyCon)}
                        | SOME (T.TYCON {tyCon =
                                         {name,id,eqKind,tyvars,...},
                                         ...})=> 
                          if (TyConID.compare(fromTyConId, id) <> LESS)
                          then
                            raise
                              E.RigidTypeInRealisation
                                {id = NM.namePathToString(longTyCon)}
                          else
                            if TU.isTyConOfTyFun(newTyFun) then
                              if (!eqKind = T.EQ) andalso
                                 not (TU.admitEqTyFun newTyFun)
                              then 
                                raise E.EqtypeRequiredInWhereType {
                                      longTyCon = 
                                      NM.namePathToString(longTyCon)
                                      }
                              else
                                if List.length tyvars <>
                                   List.length typarams
                                then
                                  raise
                                    E.ArityMismatchInWhereType 
                                      {
                                       wants = List.length tyvars,
                                       given = List.length typarams,
                                       tyCon =
                                       NM.namePathToString(longTyCon)
                                      }
                                else
                                  id
                            else
                              raise E.DatatypeNotWellFormed {
                                    longTyCon = 
                                    NM.namePathToString(longTyCon)
                                    }
                        | SOME (T.TYFUN tyFun) => 
                          if TU.isTyConOfTyFun(tyFun) 
                          then
                            let
                              val tyCon = TU.tyFunToTyCon tyFun
                            in
                              if (TyConID.compare
                                    (fromTyConId, #id tyCon) <> LESS)
                              then
                                raise
                                  E.RigidTypeInRealisation
                                    {id = NM.namePathToString(longTyCon)}
                              else
                                if (!(#eqKind tyCon) = T.EQ) andalso
                                   not (TU.admitEqTyFun newTyFun)
                                then
                                  raise E.EqtypeRequiredInWhereType {
                                        longTyCon = 
                                        NM.namePathToString(longTyCon)
                                        }
                                else
                                  if List.length (#tyvars tyCon) <>
                                     List.length typarams
                                  then
                                    raise
                                      E.ArityMismatchInWhereType 
                                        {
                                         wants = List.length (#tyvars tyCon),
                                         given = List.length typarams,
                                         tyCon = NM.namePathToString(longTyCon)
                                        }
                                  else (#id tyCon)
                            end
                          else
                            raise
                              E.TyFunWithWhereType
                                {longTyCon = NM.namePathToString(longTyCon)}
                        | SOME (T.TYOPAQUE _) => 
                          raise E.TyFunWithWhereType
                                  {longTyCon = NM.namePathToString(longTyCon)}
                        | SOME(T.TYSPEC
                                 {name, strpath, id, eqKind, tyvars,...}) => 
                          if (!eqKind = T.EQ) andalso
                             not (TU.admitEqTyFun newTyFun)
                          then 
                            raise E.EqtypeRequiredInWhereType {
                                  longTyCon = 
                                  NM.namePathToString(longTyCon)
                                  }
                          else
                            if List.length tyvars <> List.length typarams
                            then
                              raise E.ArityMismatchInWhereType 
                                      {
                                       wants = List.length tyvars,
                                       given = List.length typarams,
                                       tyCon = NM.namePathToString(longTyCon)
                                      }
                            else
                              id
                  in
                    (TyConID.Map.insert(tyConIdEnv, tyConId, T.TYFUN newTyFun),
                     newTyFun :: tyFunInfoList)
                  end
                    handle 
                    exn as E.TyConNotFoundInWhereType _ => 
                    (E.enqueueError (loc, exn);
                     (tyConIdEnv, tyFunInfoList))
                  | exn as E.RigidTypeInRealisation  _ => 
                    (E.enqueueError (loc, exn);
                     (tyConIdEnv, tyFunInfoList))
                  | exn as E.TyFunWithWhereType _ =>
                    (E.enqueueError (loc, exn);
                     (tyConIdEnv, tyFunInfoList))
                  | exn as E.EqtypeRequiredInWhereType _ => 
                    (E.enqueueError (loc, exn);
                     (tyConIdEnv, tyFunInfoList))
                  | exn as E.DatatypeNotWellFormed _ => 
                    (E.enqueueError (loc, exn);
                     (tyConIdEnv, tyFunInfoList))
                  | exn as E.ArityMismatchInWhereType _ => 
                    (E.enqueueError (loc, exn);
                     (tyConIdEnv, tyFunInfoList))
                )
                (TyConID.Map.empty, nil)
                stringListLongTyConTyList
          val context2 = TCU.substTyConInContextPartially tyConSubst context1
        in
          context2
        end
        
 (**
  * infer a type for top-level signature
  * @params currentContext ptsigexp
  * @return  an signature semantic object and tpmstrexp
  *)
  and typeinfSig (basis : TIC.basis) ptspec =
      (*rule 65*)
      let
        val fromTyConId = Counters.newTyConId ()
        val context = typeinfSpec basis ptspec
        val E = TC.getBasicEnvFromContext context
        val T = TIU.tyConIdSetEnv fromTyConId E
      in
        (T, E)
      end

  (*
   * for signature binds (signature A = <signature exp>
   *)
  and typeinfSigbinds basis nil  = (TC.emptyContext, nil)
    | typeinfSigbinds basis ((sigName, (ptsigexp, sigExpForPrint)) :: rem)  =
      (*rule 67*)
      let
        val (tyConIdSet, E) = typeinfSig basis ptsigexp
        val sigBindInfo1 =
            T.SIGNATURE
              (tyConIdSet, {name = sigName, env = E})
        val context1 =
            TC.bindSigInEmptyContext(sigName, sigBindInfo1)
        val (context2, sigspec2) = typeinfSigbinds basis rem 
      in
        (TC.extendContextWithContext
           {newContext=context2, oldContext=context1}, 
         (sigBindInfo1, sigExpForPrint) :: sigspec2)
      end


  (*
   * for functor binds (functor foo = <structure exp>)
   *)
  and typeinfFunbinds (basis:TIC.basis) nil = (TC.emptyContext, nil)
    | typeinfFunbinds
        (basis:TIC.basis)
        (ptfunbind as (funName, 
                       (argSpec, argName, 
                        formalArgNamePathEnv, sigExpForPrint), 
                       (bodyDecs, bodyNameMap, bodySigExpOpt), 
                       loc) :: rem)
      =
     (* rule 86 *)
     let
       val sigma as (T,E) = typeinfSig basis argSpec
       val newBasis = TIC.extendBasisWithBasicEnv (basis, E)
       val fromTyConId = Counters.newTyConId ()
       val (context1, newBodyDecs) = 
           typeinfPtStrDecs newBasis bodyDecs
       val E' = TC.getBasicEnvFromContext context1
       val T' = TIU.tyConIdSetEnv fromTyConId E'
       val exnTagSet = TPU.collectExnTagSetStrDecList newBodyDecs
       val newE = TIU.constructEnvFromNameMap (E, formalArgNamePathEnv) 
       val funBindInfo = 
           {
            funName= funName,
            argName = argName,
            functorSig = {generativeExnTagSet = exnTagSet,
                          argTyConIdSet = T, 
                          argSigEnv = newE, 
                          argStrPrefixedEnv = E,
                          body = (T',E')
                         }
           }
       val context2 = TC.bindFunInEmptyContext (funName,funBindInfo)
       val (context3,tpmfunbinds) = typeinfFunbinds basis rem
     in
       (
        TC.extendContextWithContext
          {newContext = context3, oldContext = context2},
        {funBindInfo = funBindInfo,
         argName = argName,
         argSpec = (sigExpForPrint, formalArgNamePathEnv), 
         bodyDec = (newBodyDecs, bodyNameMap, bodySigExpOpt)} 
        :: tpmfunbinds
       )
     end

  and typeinfPtStrDecs (basis : TIC.basis) plStrDecs =
      let
        val (newBasis, context, newTpStrDecs) =
            foldl (fn (plStrDec, (basis, context, newTpStrDecs)) =>
                      let
                        val (context1, decs) =
                            typeinfPtStrDec basis plStrDec
                      in
                        (
                         TIC.extendBasisWithContext(basis, context1),
                         TC.mergeContexts(context1, context),
                         newTpStrDecs @ decs
                        )
                      end)
                  (basis, TC.emptyContext, nil)
                  plStrDecs
      in
        (context, newTpStrDecs)
      end

  and typeinfPtCoreDecs (basis : TIC.basis) plCoreDecs =
      let
        val (newBasis, context, newTpCoreDecs) =
            foldl
              (fn (plCoreDec, (basis, context, newTpCoreDecs)) =>
                  let
                    val (context1, decs) =
                        TIFC.typeinfTopPtdecl T.toplevelDepth basis plCoreDec
                  in
                    (
                     TIC.extendBasisWithContext(basis, context1),
                     TC.mergeContexts(context1, context),
                     newTpCoreDecs @ decs
                    )
                  end)
              (basis, TC.emptyContext, nil)
              plCoreDecs
      in
        (context, newTpCoreDecs)
      end

  and typeinfPtStrDec (basis : TIC.basis) plStrDec =
      case plStrDec of
        PT.PTANDFLATTENED(newDecUnits, loc) =>
        let
          val (context, newDecUnits) =
              foldl (fn
                     ((*printSigInfo is for printing in printCodeGeneration *)
                      (printSigInfo, decUnit), 
                      (incContext, newDecUnits)) =>
                     let
                       val (context, newDecUnit) =
                           typeinfPtStrDecs basis decUnit
                     in
                       (TC.extendContextWithContext {oldContext = incContext,
                                                     newContext = context},
                        newDecUnits @ 
                        [({strName = #strName printSigInfo,
                           topSigConstraint = #topSigConstraint printSigInfo, 
                           strNameMap = #strNameMap printSigInfo,
                           basicTypeEnv = TC.getBasicEnvFromContext context},
                          newDecUnit)])
                     end)
                    (TC.emptyContext, nil)
                    newDecUnits
        in 
          (context, [TCC.TPANDFLATTENED(newDecUnits, loc)])
        end                          
      | PT.PTTRANCONSTRAINT
          (ptdecs,
           richFlattenedNameMap,
           ptspec,
           strictFlattenedNameMap,
           loc) =>
       (* rule 52 *)
         (* For example, 
          *  structure S =
          *     struct
          *        fun f x = x
          *     end : sig val f : int -> int end
          * Module compiler compiles it into :
          *    ptdecs = [fun $1.S.f x = x]  
          *    ptspec = [val f : int -> int]
          *    richFlattenedNameMap =  {f -> $1.S.f}
          *)
         let
           val (context1, newDecs) = typeinfPtStrDecs basis ptdecs
           val sigmaEnv as (T, E) = typeinfSig basis ptspec
           val richEnv = 
               (* richEnv = {$1.S.f : 'a -> 'a} *)
                 TC.getBasicEnvFromContext context1
           val flattenedSrcRichEnv = 
               (* flattenedSrcRichEnv = {f : 'a -> 'a} *)
                 TIU.constructEnvFromNameMap (richEnv, richFlattenedNameMap) 
           val flattenedSrcStrictEnv = 
               (* flattenedSrcStrictEnv = {f : int -> int} *)
                 SigCheck.transparentSigMatch (flattenedSrcRichEnv, sigmaEnv)
               handle exn => (SU.handleException (exn,loc); T.emptyE)
           val instantiatedDecs =
               TIT.genInstValDecs
                 loc
                 (#2 flattenedSrcRichEnv, #2 flattenedSrcStrictEnv) 
                 (#2 richFlattenedNameMap)
           val flattenedSysStrictEnv = 
               (* flattenedSysStrictEnv = {$1.S.f : int -> int} *)
                 TIU.restoreSysNamePathSigEnv
                 (flattenedSrcStrictEnv, richFlattenedNameMap) loc
           val context3 = TC.injectEnvToContext flattenedSysStrictEnv
         in
           (context3, 
            [TCC.TPCONSTRAINT
               (newDecs @ instantiatedDecs, strictFlattenedNameMap, loc)])
         end
      | PT.PTOPAQCONSTRAINT
          (ptdecs,
           richFlattenedNameMap,
           ptspec,
           strictFlattenedNameMap,
           loc) =>
        (* rule 53 *)
          let
            val (context1, newDecs) = typeinfPtStrDecs basis ptdecs
            val sigmaEnv = typeinfSig basis ptspec
            val richEnv = TC.getBasicEnvFromContext context1
            val flattenedSrcRichEnv = 
                TIU.constructEnvFromNameMap (richEnv, richFlattenedNameMap) 
            val (abstractEnv, enrichedEnv) = 
                (
                 SigCheck.opaqueSigMatch (flattenedSrcRichEnv, sigmaEnv)
                 handle
                 exn => (SU.handleException (exn,loc);(T.emptyE,T.emptyE)))
            val instantiatedDecs =
                TIT.genInstValDecs loc
                                   (#2 flattenedSrcRichEnv, #2 enrichedEnv)
                                   (#2 richFlattenedNameMap)
            val context3 = 
                TC.injectEnvToContext 
                  (TIU.restoreSysNamePathSigEnv
                     (abstractEnv, richFlattenedNameMap) loc)
          in
            (context3, 
             [TCC.TPCONSTRAINT
                (newDecs @ instantiatedDecs, strictFlattenedNameMap, loc)])
          end
      | PT.PTFUNCTORAPP (prefix, 
                         functorName, 
                         (actualArgNamePath, actualFlattenedNamePathEnv), 
                         loc) =>
        (* rule 54 *)
        let
          val funBindInfo as {functorSig, ...}
            = 
            case TIC.lookupFunctorInBasis (basis, functorName) of
              SOME bindinfo => bindinfo
            | NONE =>
              (E.enqueueError (loc, E.FunctorNotFound{id = functorName});
               {
                funName = functorName,
                argName = "X?",
                functorSig = {generativeExnTagSet = ExnTagID.Set.empty,
                              argTyConIdSet = TyConID.Set.empty,
                              argSigEnv = T.emptyE, 
                              argStrPrefixedEnv = T.emptyE, 
                              body = (TyConID.Set.empty,T.emptyE)
                             }
               }
               :T.funBindInfo)
          val Env = 
              TIU.constructActualArgTypeEnvFromNameMap
                actualFlattenedNamePathEnv basis loc
          val (resEnv,
               argMatchedEnv,
               generativeExnTagTable,
               exnTagResolutionTable) =
              let
                val defaultErrorValue = 
                    (T.emptyE,
                     T.emptyE,
                     ExnTagID.Map.empty,
                     ExnTagID.Map.empty
                    )
              in
                ( 
                 SigCheck.functorSigMatch (Env, functorSig)
                 handle
                 exn => (SU.handleException (exn,loc); defaultErrorValue))
              end
          val instTyConSubst = 
              SU.substTyEnvFromEnv (#argSigEnv (#functorSig(funBindInfo)),
                                    argMatchedEnv)
          val context2:TypeContext.context = 
              let
                val newResEnv = TIU.addStrpathInEnv resEnv prefix
              in
                TC.injectEnvToContext newResEnv 
              end
          val instantiatedDecs =
              TIT.genInstValDecs loc
                                 (#2 Env, #2 argMatchedEnv) 
                                 (#2 actualFlattenedNamePathEnv)
        in
          (context2, 
           [TCC.TPSTRLOCAL
              (instantiatedDecs, 
               [TCC.TPFUNCTORAPP 
                  {prefix = prefix,
                   funBindInfo =  funBindInfo,
                   argNameMapInfo =
                     {argNamePath = actualArgNamePath, 
                      env = actualFlattenedNamePathEnv},
                   exnTagResolutionTable = exnTagResolutionTable,
                   refreshedExceptionTagTable = generativeExnTagTable,
                   typeResolutionTable = instTyConSubst,
                   loc = loc}],
               loc
           )]
          )
        end
      | PT.PTSTRLOCAL (ptdecs1, ptdecs2, loc) =>
        (* local structure declarations are also compiled into
         * local core declarations; since it involves constraints 
         * things, we put here to avoid mutual recursive call between
         * core type inference and module type inference
         *)
        let 
          val (newContext1, tpdecs1) =
              typeinfPtStrDecs basis ptdecs1
          val (newContext2, tpdecs2) =
              typeinfPtStrDecs (TIC.extendBasisWithContext(basis, newContext1))
                               ptdecs2
        in
          (newContext2, [TCC.TPSTRLOCAL (tpdecs1, tpdecs2, loc)])
        end
      | PT.PTCOREDEC(ptdecs, loc) =>
        let 
          val (newContext, tpdecs) =
              typeinfPtCoreDecs basis ptdecs
        in
          (newContext, [TCC.TPCOREDEC (tpdecs, loc)])
        end
            
 (**
  * infer a type for top level decs
  * @params currentContext pttopdeclList
  * @return  an Environment and tptopdeclList
  *)
  and typeinfPttopdeclList (basis : TIC.basis) nil = (TC.emptyContext, nil)
    | typeinfPttopdeclList (basis : TIC.basis) (pltopdec :: rest) =
      let
        val _ = T.kindedTyvarList := nil
        val (context1, topbind) =
            case pltopdec of
              PT.PTDECSTR (ptStrDecs, loc) =>
              let
                val (newContext, _, newTpStrDecs) =
                    foldl
                      (fn (ptStrDec, (context, newBasis, ptStrDecs)) =>
                          let
                            val (newContext, newPtStrDecs) =
                                typeinfPtStrDec newBasis ptStrDec
                          in
                            (TC.mergeContexts(newContext, context),
                             TIC.extendBasisWithContext(newBasis, newContext),
                             ptStrDecs @ newPtStrDecs)
                          end)
                      (TC.emptyContext, basis, nil)
                      ptStrDecs
              in
                (newContext, TCC.TPDECSTR (newTpStrDecs, loc))
              end
            | PT.PTDECSIG (ptsigdecs, loc) =>
              (* rule 88 *)
                let
                  val (context1 :TC.context, sigDecs) = 
                      typeinfSigbinds basis ptsigdecs
                in
                  (context1, TCC.TPDECSIG (sigDecs, loc))
                end
            | PT.PTDECFUNCTOR (ptfunbinds,loc) =>
              (* rule 89 *)
                let
                  val (context1, tpfunbinds) = typeinfFunbinds basis ptfunbinds
                in
                  (context1, TCC.TPDECFUN (tpfunbinds, loc))
                end
        val (context1, topbind) =
        if E.isError() then 
          (context1, topbind)
        else
          let
            val tyvars = TypeContextUtils.tyvarsContext context1
            val dummyTyList =
            (foldr
               (fn (r
                      as
                      ref(T.TVAR
                            {recordKind = T.OCONSTkind (h::_), ...}),
                    dummyTyList) => 
                   (r := T.SUBSTITUTED h; dummyTyList)
                 | (r
                    as
                    ref(T.TVAR
                          {recordKind =
                           T.OPRIMkind {instances = (h::_),...},...}),
                    dummyTyList) => 
                   (r := T.SUBSTITUTED h; dummyTyList)
                 | (r as ref (T.TVAR {recordKind=T.UNIV, ...}),
                    dummyTyList) =>
                   let
                     val dummyty = TIU.nextDummyTy ()
                     val _ = r := (T.SUBSTITUTED dummyty)
                   in
                     dummyty :: dummyTyList
                   end
                 | (**** temporary fix of BUG 200 ***)
                     (r as ref (T.TVAR {recordKind=T.REC tySEnvMap, ...}),
                      dummyTyList) =>
                   let
                     val _ = r := (T.SUBSTITUTED (T.RECORDty tySEnvMap))
                   in
                     dummyTyList
                   end
                 | (r as ref (T.SUBSTITUTED _), dummyTyList) => dummyTyList
                 | _ =>
                   raise
                     Control.Bug
                       "non tvar in dummytyvars\
                       \ (typeinference/main/TypeInferCore.sml)"
               )
               nil
               (OTSet.listItems tyvars)
            )
                handle x => raise x
            val _ =
                case dummyTyList of
                  nil => ()
                | _ =>
                  E.enqueueWarning
                    (PT.getLocTopDec pltopdec,
                     E.ValueRestriction {dummyTyList = dummyTyList})
            val _ = TIU.eliminateVacuousTyvars()
(*
           val _ = List.app (fn (ty as T.TYVARty(ref(T.TVAR _)), loc) =>
                                E.enqueueError (loc, E.FFIInvalidTyvar ty)
                              | _ => ())
                            (!ffiApplyTyvars)
*)
          in
            (context1, topbind)
          end
        val newBasis = TIC.extendBasisWithContext(basis, context1)
        val (context2, restTopBinds) = typeinfPttopdeclList newBasis rest
        val context3 = TC.extendContextWithContext 
                         {newContext=context2, 
                          oldContext= context1}
      in
        (context3, topbind :: restTopBinds)
      end
end
end

