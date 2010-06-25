(**
 * utility functions for manupilating types (needs re-writing).
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: TypeInferenceUtils.sml,v 1.58 2008/08/05 14:44:00 bochao Exp $
 *)
structure TypeInferenceUtils =
struct
  local 
    structure T = Types
    structure PT = PatternCalcWithTvars
    structure TPC = TypedCalc
    structure PDT = PredefinedTypes
    structure TIC = TypeInferenceContext
    structure TC = TypeContext
    structure TU = TypesUtils
    structure TCU = TypedCalcUtils
    structure E = TypeInferenceError
    (* structure STE = StaticTypeEnv *)
    structure NM = NameMap
    structure NPEnv = NameMap.NPEnv
  in
  
  val dummyTyId = ref 0
  fun nextDummyTy () =
      T.DUMMYty (!dummyTyId) before dummyTyId := !dummyTyId + 1

  fun eliminateVacuousTyvars () =
      let
        fun instanticateTv tv =
            case tv of
              ref(T.TVAR {recordKind = T.OCONSTkind (h::_), ...}) =>
              tv := T.SUBSTITUTED h
            | ref(T.TVAR {recordKind = T.OPRIMkind
                                         {instances = (h::_),...},
                          ...}
                 )
              => tv := T.SUBSTITUTED h
            | ref(T.TVAR {recordKind = T.REC tyFields, ...}) => 
              tv := T.SUBSTITUTED (T.RECORDty tyFields)
            | ref(T.TVAR {recordKind = T.UNIV, ...}) => 
              tv := T.SUBSTITUTED (nextDummyTy())
            | _ => ()
      in
        (
         List.app instanticateTv (!T.kindedTyvarList);
         T.kindedTyvarList := nil
        )
      end

  val NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER = "X?" 
                                            
  fun varInfoToVarPathInfo {name,ty} =
      {name = name, strpath = Path.NilPath, ty = ty}

  fun conInfoToConPathInfo {name, funtyCon, ty, tag, tyCon} =
      {name = name,
       strpath = Path.NilPath,
       ty = ty,
       tag = tag,
       tyCon = tyCon}

  (*
   * make a fresh instance of ty by instantiating the top-level type
   * abstractions (only)
   *)
  fun freshTopLevelInstTy ty =
      case ty of
        (T.POLYty{boundtvars, body, ...}) =>
        let 
          val subst = TU.freshSubst boundtvars
          val bty = TU.substBTvar subst body
        in  
          (bty, IEnv.listItems subst)
        end
      | _ => (ty, nil)
             
  fun etaExpandCon namePath loc idState = 
      case idState of
        T.CONID (conPathInfo
                 as {namePath = namePath1, funtyCon, ty, tag, tyCon}) =>
        let
          val termconPathInfo =
              {
               namePath = namePath,
               funtyCon = funtyCon,
               ty = ty,
               tag = tag,
               tyCon = tyCon
              }
        in
          if funtyCon
          then
            case ty of
              T.POLYty{boundtvars, body = T.FUNMty([argTy], resultTy)} =>
              let
                val (subst, newBoundEnv) = TU.copyBoundEnv boundtvars
                val newArgTy = TU.substBTvar subst argTy
                val newResultTy = TU.substBTvar subst resultTy
                val newVarPathInfo =
                    {namePath = (Counters.newVarName (), Path.NilPath), 
                     ty = newArgTy}
                val newTy =
                    T.POLYty{boundtvars=newBoundEnv,
                           body = T.FUNMty([newArgTy], newResultTy)}
              in
                (
                 newTy,
                 TPC.TPPOLYFNM
                   {
                    btvEnv=newBoundEnv,
                    argVarList=[newVarPathInfo],
                    bodyTy=newResultTy,
                    bodyExp=
                      TPC.TPDATACONSTRUCT
                      {
                       con=termconPathInfo,
                       instTyList=map T.BOUNDVARty (IEnv.listKeys newBoundEnv),
                       argExpOpt= SOME (TPC.TPVAR (newVarPathInfo, loc)),
                       loc=loc
                      },
                    loc=loc
                   }
                )
              end
            | T.POLYty{boundtvars, body = T.FUNMty(_, ty)} =>
              raise Control.Bug "Uncurried fun type in OPRIM"
            | T.FUNMty([argTy], resultTy) =>
              (* ty should be mono; data constructor has a closed type *)
                let
                  val newVarPathInfo =
                      {namePath = (Counters.newVarName (), Path.NilPath), 
                       ty = argTy}
                in
                  (
                   ty,
                   TPC.TPFNM
                     {
                      argVarList=[newVarPathInfo],
                      bodyTy=resultTy,
                      bodyExp=
                        TPC.TPDATACONSTRUCT
                        {
                         con=termconPathInfo,
                         instTyList=nil,
                         argExpOpt=SOME (TPC.TPVAR (newVarPathInfo, loc)),
                         loc=loc
                        },
                      loc=loc
                     }
                  )
                end
            | T.FUNMty(_, ty) =>
              raise Control.Bug "Uncurried fun type in OPRIM"
            | _ => raise Control.Bug "datacon type"
          else (ty,
                TPC.TPDATACONSTRUCT
                  {con=termconPathInfo,
                   instTyList=nil,
                   argExpOpt=NONE,
                   loc=loc})
        end
      | T.EXNID (exnPathInfo
                 as {namePath = namePath1, funtyCon, ty, tag, tyCon}) =>
        let
          val termconPathInfo =
              {
               namePath = namePath,
               funtyCon = funtyCon,
               ty = ty,
               tag = tag,
               tyCon = tyCon
              }
        in
          if funtyCon
          then
            case ty of
              T.POLYty _=>
              raise Control.Bug "exception type is not generalized"
            | T.FUNMty([argTy], resultTy) => 
              let
                val newVarPathInfo =
                    {namePath = (Counters.newVarName (), Path.NilPath), 
                     ty = argTy}
              in
                (
                 ty,
                 TPC.TPFNM
                   {
                    argVarList=[newVarPathInfo],
                    bodyTy=resultTy,
                    bodyExp=
                      TPC.TPEXNCONSTRUCT
                      {
                       exn=termconPathInfo,
                       instTyList=nil,
                       argExpOpt=SOME (TPC.TPVAR (newVarPathInfo, loc)),
                       loc=loc
                      },
                    loc=loc
                   }
                )
              end
            | T.FUNMty(_, ty) =>
              raise Control.Bug "Uncurried fun type in OPRIM"
            | _ => raise Control.Bug "datacon type"
          else
            (ty,
             TPC.TPEXNCONSTRUCT{exn=termconPathInfo,
                                instTyList=nil,
                                argExpOpt=NONE,
                                loc=loc})
        end
      | T.PRIM (primInfo as {ty,...}) =>
        (case ty of
           T.POLYty{boundtvars, body = T.FUNMty([argTy], resultTy)} =>
           let
             val (subst, newBoundEnv) = TU.copyBoundEnv boundtvars
             val newArgTy = TU.substBTvar subst argTy
             val newResultTy = TU.substBTvar subst resultTy
             val newVarPathInfo =
                 {namePath = (Counters.newVarName (), Path.NilPath), 
                  ty = newArgTy}
             val newTy =
                 T.POLYty{boundtvars=newBoundEnv,
                        body = T.FUNMty([newArgTy], newResultTy)}
           in
             (
              newTy,
              TPC.TPPOLYFNM
                {
                 btvEnv=newBoundEnv,
                 argVarList=[newVarPathInfo],
                 bodyTy=newResultTy,
                 bodyExp=
                   TPC.TPPRIMAPPLY
                   {
                    primOp=primInfo,
                    instTyList=map T.BOUNDVARty (IEnv.listKeys newBoundEnv),
                    argExpOpt=SOME (TPC.TPVAR (newVarPathInfo, loc)),
                    loc=loc
                   },
                 loc=loc
                }
             )
           end
         | T.POLYty{boundtvars, body = T.FUNMty(_, ty)} =>
           raise Control.Bug "Uncurried fun type in OPRIM"
         | T.FUNMty([argTy], resultTy) =>
           let
             val newVarPathInfo =
                 {namePath = (Counters.newVarName (), Path.NilPath), 
                  ty = argTy}
           in
             (
              ty,
              TPC.TPFNM
                {
                 argVarList=[newVarPathInfo],
                 bodyTy=resultTy,
                 bodyExp=
                   TPC.TPPRIMAPPLY
                   {
                    primOp=primInfo,
                    instTyList=nil,
                    argExpOpt=SOME (TPC.TPVAR (newVarPathInfo, loc)),
                    loc=loc
                   },
                 loc=loc
                }
             )
           end
         | T.FUNMty(_, ty) => raise Control.Bug "Uncurried fun type in OPRIM"
         | _ =>raise Control.Bug "datacon type"
        )
      | T.OPRIM (oprimInfo as {oprimPolyTy,...}) =>
        let
          val (instTy, instTyList) = freshTopLevelInstTy oprimPolyTy
          val keyTyList = 
              List.filter
              (fn ty =>
                  case TU.derefTy ty of
                    T.TYVARty(ref(T.TVAR{recordKind=T.OPRIMkind _,...}))=>true
                  | _ => false)
              instTyList
        in
          case instTy of
            T.FUNMty([argTy], resultTy) =>
            let
              val newVarPathInfo =
                  {namePath = (Counters.newVarName (), Path.NilPath), 
                   ty = argTy}
            in
              (
               instTy,
               TPC.TPFNM
                 {
                  argVarList=[newVarPathInfo],
                  bodyTy=resultTy,
                  bodyExp=
                    TPC.TPOPRIMAPPLY
                    {
                     oprimOp=oprimInfo,
                     keyTyList = keyTyList,
                     instances = instTyList,
                     argExpOpt=SOME (TPC.TPVAR (newVarPathInfo, loc)),
                     loc=loc
                    },
                  loc=loc
                 }
              )
            end
          | T.FUNMty(_, ty) => raise Control.Bug "Uncurried fun type in OPRIM"
          | _ =>raise Control.Bug "oprim type"
        end
      | T.RECFUNID _ => raise Control.Bug "recfunid in etaExpandCon"
      | T.VARID _ => raise Control.Bug "var in etaExpandCon"

  fun tyConIdInTyBindInfo tyBindInfo = 
      case  tyBindInfo of
        T.TYCON ({tyCon = {id, ...}, ...}) => id
      | T.TYSPEC {id, ...} => id
      | T.TYOPAQUE {spec={id, ...}, impl} => id
      | T.TYFUN {name,...} => raise (E.SharingOnTypeFun {tyConName = name})

  fun tyConIdInTyBindInfoOpt tyBindInfo = 
      SOME(tyConIdInTyBindInfo tyBindInfo)
      handle exn => NONE

  fun tyConIdSetTyConEnv fromTyConId tyConEnv =
      NPEnv.foldl
        (fn (tyBindInfo, tyConIdSet) => 
            let
              val thisTyConIdOpt = tyConIdInTyBindInfoOpt tyBindInfo
            in
              case thisTyConIdOpt of
                SOME (thisTyConId) =>
                (* Assumption : 
                 * 1. new generative tyConId must have the same namespace as 
                 * that of fromTyConId
                 * 2. new generative tyConId must bigger than fromTyConId
                 *) 
                if TyConID.compare (fromTyConId, thisTyConId) <> GREATER
                then
                  TyConID.Set.add(tyConIdSet, thisTyConId)
                else
                  tyConIdSet
              | NONE => tyConIdSet
            end
        )
        TyConID.Set.empty
        tyConEnv

  and tyConIdSetVarEnv fromTyConId varEnv =
      NPEnv.foldl
        (fn (T.CONID {namePath, funtyCon, ty, tag, tyCon}, tyConIdSet) =>
            let 
              val thisTyConId = #id tyCon
            in
            (* Assumption : 
             * new generative tyConId must bigger than fromTyConId
             *) 
            if
              TyConID.compare (fromTyConId, thisTyConId) <> GREATER
            then
              TyConID.Set.add(tyConIdSet, thisTyConId)
            else
              tyConIdSet
            end
          | (_, tyConIdSet) => tyConIdSet
        )
        TyConID.Set.empty
        varEnv

  fun tyConIdSetEnv fromTyConId (tyConEnv, varEnv) =
      let
        val T1 = tyConIdSetTyConEnv fromTyConId tyConEnv
        val T2 = tyConIdSetVarEnv fromTyConId varEnv
      in
        TyConID.Set.union(T1,T2)
      end

  fun addPrefixEnv  ((tyEnv, varEnv), path) =
      let
        val newTyEnv = addPrefixTyEnv (tyEnv, path)
        val (newVarEnv, prefixedNameMap) = addPrefixVarEnv (varEnv, path)
      in
        ((newTyEnv, newVarEnv))
      end

  and addPrefixTyBindInfo (tyBindInfo, path) =
      case tyBindInfo of
        T.TYCON {tyCon =
                 {name,
                  strpath,
                  tyvars,
                  id,
                  abstract,
                  eqKind,
                  constructorHasArgFlagList},
                 datacon} =>
        T.TYCON {tyCon =
                 {name = name,
                  strpath = Path.joinPath(path, strpath),
                  tyvars = tyvars,
                  id = id,
                  abstract = abstract,
                  eqKind = eqKind,
                  constructorHasArgFlagList = constructorHasArgFlagList},
                 datacon = datacon}
      | T.TYFUN {name, strpath, tyargs, body} => 
        T.TYFUN {name = name,
                 strpath = Path.joinPath(path, strpath),
                 tyargs = tyargs,
                 body = body}
      | T.TYOPAQUE
          {spec =
           {name,
            strpath,
            id,
            abstract,
            eqKind,
            tyvars,
            constructorHasArgFlagList},
           impl} =>
        T.TYOPAQUE {spec =
                    {name = name,
                     strpath = Path.joinPath(path, strpath),
                     id = id,
                     abstract = abstract,
                     eqKind = eqKind,
                     tyvars = tyvars,
                     constructorHasArgFlagList = constructorHasArgFlagList},
                    impl = impl}
      | T.TYSPEC {name,
                  strpath,
                  id,
                  abstract,
                  eqKind,
                  tyvars,
                  constructorHasArgFlagList} =>
        T.TYSPEC {name = name,
                  strpath = Path.joinPath(path, strpath),
                  id = id,
                  abstract = abstract,
                  eqKind = eqKind,
                  tyvars = tyvars,
                  constructorHasArgFlagList = constructorHasArgFlagList}
              
  and addPrefixTyEnv (tyEnv, path) =
      NPEnv.foldli
        (fn (tyNamePath, tyBindInfo, newTyEnv) =>
            NPEnv.insert(newTyEnv,
                         (#1 tyNamePath, Path.joinPath(path, #2 tyNamePath)),
                         addPrefixTyBindInfo (tyBindInfo, path)))
        NPEnv.empty
        tyEnv

  and addIdstate (idstate, path) =
      case idstate of
        T.VARID {namePath, ty} =>
        T.VARID {namePath = (#1 namePath, Path.joinPath(path, #2 namePath)),
                 ty = ty}
      | T.CONID {namePath, funtyCon, ty, tag, tyCon} =>
        T.CONID {namePath = (#1 namePath, Path.joinPath(path, #2 namePath)),
                 funtyCon = funtyCon, 
                 ty = ty,
                 tag = tag, 
                 tyCon = tyCon}
      | T.EXNID {namePath, funtyCon, ty, tag, tyCon} =>
        T.EXNID {namePath = (#1 namePath, Path.joinPath(path, #2 namePath)),
                 funtyCon = funtyCon, 
                 ty = ty,
                 tag = tag, 
                 tyCon = tyCon}
      | T.RECFUNID ({namePath, ty}, int) =>
        T.RECFUNID
          ({namePath = (#1 namePath, Path.joinPath(path, #2 namePath)),
            ty = ty},
           int)
      | _ => raise Control.Bug "illegal idstate"
                         
  and addPrefixVarEnv (varEnv, path : Path.path) =
      NPEnv.foldli
        (fn (varNamePath, idstate, (newVarEnv, nameMap)) =>
            let
              val newNamePath =
                  (#1 varNamePath, Path.joinPath(path, #2 varNamePath))
              val newName = NameMap.namePathToString newNamePath
              val newIdstate = addIdstate (idstate,  path)
            in
              (NPEnv.insert(newVarEnv, newNamePath, newIdstate),
               SEnv.insert(nameMap, newName, NM.namePathToString(varNamePath)))
            end)
        (NPEnv.empty, SEnv.empty)
        varEnv

  fun setPrefixEnv ((tyEnv, varEnv), path) =
      let
        val newTyEnv = setPrefixTyEnv (tyEnv, path)
        val (newVarEnv, prefixedNameMap) = setPrefixVarEnv (varEnv, path)
      in
        ((newTyEnv, newVarEnv), prefixedNameMap)
      end

  and setPrefixTyBindInfo (tyBindInfo, path) =
      case tyBindInfo of
        T.TYCON
          {tyCon =
           {name,
            strpath,
            tyvars,
            id,
            abstract,
            eqKind,
            constructorHasArgFlagList}, 
           datacon} =>
        T.TYCON {tyCon = {name = name,
                        strpath = path,
                        tyvars = tyvars,
                        id = id,
                        abstract = abstract,
                        eqKind = eqKind,
                        constructorHasArgFlagList = constructorHasArgFlagList},
               datacon = datacon
              }
      | T.TYFUN {name, strpath, tyargs, body} => 
        T.TYFUN {name = name,
               strpath = path,
               tyargs = tyargs,
               body = body}
      | T.TYOPAQUE
          {spec =
           {name,
            strpath,
            id,
            abstract,
            eqKind,
            tyvars,
            constructorHasArgFlagList},
           impl} 
        =>
        T.TYOPAQUE {spec =
                    {name = name,
                     strpath = path,
                     id = id,
                     abstract = abstract,
                     eqKind = eqKind,
                     tyvars = tyvars,
                     constructorHasArgFlagList = constructorHasArgFlagList},
                    impl = impl}
      | T.TYSPEC
          {name,
           strpath,
           id,
           abstract,
           eqKind,
           tyvars,
           constructorHasArgFlagList} =>
        T.TYSPEC {name = name,
                  strpath = path,
                  id = id,
                  abstract = abstract,
                  eqKind = eqKind,
                  tyvars = tyvars,
                  constructorHasArgFlagList = constructorHasArgFlagList}

  and setPrefixTyEnv (tyEnv, path) =
      NPEnv.foldli
        (fn (tyNamePath, tyBindInfo, newTyEnv) =>
            NPEnv.insert(newTyEnv,
                         (#1 tyNamePath, Path.joinPath(path, #2 tyNamePath)),
                         setPrefixTyBindInfo (tyBindInfo, path)))
        NPEnv.empty
        tyEnv

  and setIdstate (idstate, path) =
      case idstate of
        T.VARID {namePath, ty} =>
        T.VARID {namePath = (#1 namePath, path), ty = ty}
      | T.CONID {namePath, funtyCon, ty, tag, tyCon} =>
        T.CONID {namePath = (#1 namePath, path),
                 funtyCon = funtyCon, 
                 ty = ty,
                 tag = tag, 
                 tyCon = tyCon}
      | T.EXNID {namePath, funtyCon, ty, tag, tyCon} =>
        T.EXNID {namePath = (#1 namePath, path),
                 funtyCon = funtyCon, 
                 ty = ty,
                 tag = tag, 
                 tyCon = tyCon}
      | T.RECFUNID ({namePath, ty}, int) =>
        T.RECFUNID
          ({namePath = (#1 namePath, path),
            ty = ty},
           int)
      | _ => raise Control.Bug "illegal idstate"
                         
  and setPrefixVarEnv (varEnv, path : Path.path) =
      NPEnv.foldli
        (fn (namePath, idstate, (newVarEnv, nameMap)) =>
            let
              val joinedPath = Path.joinPath (path, #2 namePath)
              val newNamePath = (#1 namePath, joinedPath)
              val newName = NameMap.namePathToString newNamePath
              val newIdstate = setIdstate (idstate,  joinedPath)
            in
              (NPEnv.insert(newVarEnv, newNamePath, newIdstate),
               SEnv.insert(nameMap, newName, NM.namePathToString(namePath)))
            end)
        (NPEnv.empty, SEnv.empty)
        varEnv
                       
  and setPrefixDataCon (dataCon, path : Path.path) =
      SEnv.foldli
        (fn (varName, idstate, (newVarEnv, nameMap)) =>
            let
              val newNamePath = (varName, path)
              val newName = NameMap.namePathToString newNamePath
              val newIdstate = setIdstate (idstate,  path)
            in
              (NPEnv.insert(newVarEnv, newNamePath, newIdstate),
               SEnv.insert(nameMap, newName, varName))
            end)
        (NPEnv.empty, SEnv.empty)
        dataCon

  fun constructVarEnvFromVarNameMap (varEnv, varNamePathEnv) =
      NPEnv.foldli
        (fn (srcNamePath, idstate, newVarEnv) =>
            let
              val innerNamePath = 
                  NM.getNamePathFromIdstate idstate
            in
              case NPEnv.find(varEnv, innerNamePath) of
                NONE => newVarEnv
              | SOME x => 
                NPEnv.insert(newVarEnv, srcNamePath, x)
            end)
        NPEnv.empty
        varNamePathEnv

  fun constructTyConEnvFromTyNameMap (tyConEnv, tyNamePathEnv) =
      NPEnv.foldli
        (fn (srcNamePath, tyState, newTyConEnv) =>
            let
              val innerNamePath =
                  NM.getNamePathFromTyState tyState
            in
              case NPEnv.find(tyConEnv, innerNamePath) of
                NONE => newTyConEnv
              | SOME x =>
                NPEnv.insert(newTyConEnv, srcNamePath, x)
            end)
        NPEnv.empty
        tyNamePathEnv
                       
  fun constructEnvFromNameMap
        (Env : T.Env, flattenedNameMap:NM.basicNameNPEnv)  =
      let
        val tyConEnv = 
            constructTyConEnvFromTyNameMap (#1 Env, #1 flattenedNameMap) 
        val varEnv = 
            constructVarEnvFromVarNameMap (#2 Env, #2 flattenedNameMap) 
      in
        (tyConEnv, varEnv)
      end

  fun resotreSysNamePathSigVarEnv (sigVarEnv, varNamePathEnv) loc =
      NPEnv.foldli
        (fn (srcNamePath, idstate, newVarEnv) =>
            case NPEnv.find(varNamePathEnv, srcNamePath) of
              NONE => 
              raise Control.BugWithLoc
                      (("unbound type "^
                        (NM.namePathToString srcNamePath)),
                       loc)
            | SOME varState =>
              NPEnv.insert(newVarEnv, 
                           NM.getNamePathFromIdstate varState,
                           idstate)
        )
        NPEnv.empty
        sigVarEnv

  fun restoreSysNamePathSigTyConEnv (sigTyConEnv, tyNamePathEnv) loc =
      NPEnv.foldli
        (fn (srcNamePath, tyBindInfo, newTyConEnv) =>
            case NPEnv.find(tyNamePathEnv, srcNamePath) of
              NONE => 
              raise Control.BugWithLoc
                      (("unbound type "^
                        (NM.namePathToString srcNamePath)),
                       loc)
            | SOME tyState =>
              NPEnv.insert(newTyConEnv, 
                           NM.getNamePathFromTyState tyState, 
                           tyBindInfo)
        )
        NPEnv.empty
        sigTyConEnv
                       
  fun restoreSysNamePathSigEnv
        (strictEnv:T.Env, flattenedNameMap:NM.basicNameNPEnv) loc =
      let
        val tyConEnv = 
            restoreSysNamePathSigTyConEnv
              (#1 strictEnv, #1 flattenedNameMap) loc
        val varEnv = 
            resotreSysNamePathSigVarEnv (#2 strictEnv, #2 flattenedNameMap) loc
      in
        (tyConEnv, varEnv)
      end

  fun constructActualArgTypeEnvFromNameMap
        (flattenedNameNPEnv : NM.basicNameNPEnv) basis loc =
      let
        val tyConEnv =
            NPEnv.foldli
              (fn (namePath, tyState, newTyConEnv) => 
                  case TIC.lookupTyConInBasis
                         (basis, NM.getNamePathFromTyState tyState) of
                    NONE => 
                     (* error will be captured by functor signature matching *)
                      newTyConEnv
                  | SOME tyBindInfo =>
                    NPEnv.insert(newTyConEnv, namePath, tyBindInfo))
              NPEnv.empty
              (#1 flattenedNameNPEnv)

        val varEnv =
            NPEnv.foldli
              (fn (namePath, idstate, newVarEnv) => 
                  case TIC.lookupVarInBasis
                         (basis, NM.getNamePathFromIdstate idstate) of
                    NONE => 
                    (* error will be captured by functor signature matching *)
                      newVarEnv
                  | SOME idstate => 
                    NPEnv.insert(newVarEnv, namePath, idstate))
              NPEnv.empty
              (#2 flattenedNameNPEnv)
      in
        (tyConEnv, varEnv)
      end


  (* updatedateStrpath manipulation utilities *)         
  fun updateStrpath strpath {current, original} =
      if Path.isPrefix {path = strpath, prefix = original} then
        let val (_, remPath) = Path.removeCommonPrefix (original, strpath)
        in Path.joinPath (current, remPath) end
      else strpath
               
  fun updateStrpathInTyBindInfo  tyBindInfo strPathPair =
      case tyBindInfo of
        T.TYCON {tyCon, datacon} =>
        let
          val newTyCon = 
              updateStrpathInTyCon tyCon strPathPair
          val (newDatacon) =
              updateStrpathInDatacon datacon strPathPair
        in
          (T.TYCON {tyCon = newTyCon, datacon = newDatacon})
        end
      | T.TYFUN tyfun => 
        let
          val newTyFun = 
              updateStrpathInTyfun tyfun strPathPair
        in
          (T.TYFUN newTyFun)
        end
      | T.TYSPEC tycon =>
        let
          val (newTyCon) = 
              updateStrpathInTyCon tycon strPathPair
        in
          (T.TYSPEC newTyCon)
        end
      | T.TYOPAQUE
          ({spec =
            {name,
             id,
             eqKind,
             tyvars,
             strpath,
             abstract,
             constructorHasArgFlagList},
            impl}) =>
        (T.TYOPAQUE ({spec =
                      {name = name, 
                       id = id, 
                       eqKind = eqKind, 
                       abstract = abstract,
                       tyvars = tyvars, 
                       strpath = updateStrpath strpath strPathPair, 
                       constructorHasArgFlagList = constructorHasArgFlagList},
                      impl = impl}))
              
  and updateStrpathInTyfun {name, strpath, tyargs, body} strPathPair =
      let
        val newTyargs = 
            IEnv.foldli
              (fn (key, tyarg, (newTyargs)) =>
                  let
                    val (newTyarg) =
                        updateStrpathInBtvKind tyarg strPathPair
                  in
                    (
                     IEnv.insert(newTyargs, key, newTyarg)
                    )
                  end)
              (IEnv.empty)
              tyargs
        val (newBody) = updateStrpathInTy  body strPathPair
      in
        (
         {name = name,
          strpath = updateStrpath strpath strPathPair,
          tyargs = newTyargs,
          body = newBody}
        )
      end
          
  and updateStrpathInBtvKind  {recordKind, eqKind} strPathPair =
      let
        val recordKind =
            case recordKind of 
              T.UNIV => T.UNIV
            | T.REC tySEnvMap => 
              let
                val tySEnvMap = 
                    SEnv.foldli
                       (fn (label, ty, tySEnvMap) =>
                           let
                             val ty = 
                                 updateStrpathInTy ty strPathPair
                           in
                             SEnv.insert(tySEnvMap, label, ty)
                           end)
                       SEnv.empty
                       tySEnvMap
              in
                T.REC tySEnvMap
              end
            | T.OCONSTkind tys =>
              let
                val tys = 
                    foldr
                      (fn (ty, tys) =>
                          let
                            val ty = updateStrpathInTy ty strPathPair
                          in
                            ty :: tys
                          end)
                       nil
                       tys
              in 
                T.OCONSTkind tys
              end
            | T.OPRIMkind {instances, operators} =>
              let
                val instances = 
                    foldr
                      (fn (ty, tys) =>
                          let
                            val ty = updateStrpathInTy ty strPathPair
                          in
                            ty :: tys
                          end)
                       nil
                       instances
              in 
                T.OPRIMkind {instances = instances, operators = operators}
              end
      in
        (
         {
          recordKind = recordKind,
          eqKind = eqKind
         }
        )
      end
          
  and updateStrpathInTyList tyList strPathPair =           
      foldr (fn (ty, (newTys)) =>
                let
                  val (newTy) = 
                      updateStrpathInTy ty strPathPair 
                in
                  (newTy :: newTys)
                end)
            nil
            tyList
                
  and updateStrpathInTy ty strPathPair = 
      case ty of
        T.INSTCODEty {oprimId,name,oprimPolyTy, keyTyList, instTyList} =>
        T.INSTCODEty 
          {
           oprimId = oprimId,
           name = name,
           oprimPolyTy = updateStrpathInTy oprimPolyTy strPathPair,
           keyTyList = updateStrpathInTyList keyTyList strPathPair,
           instTyList = updateStrpathInTyList instTyList strPathPair
          }
      | T.TYVARty (tvar as ref (T.TVAR tvKind)) => 
        let
          val tvKind =
              updateStrpathInTvKind tvKind strPathPair
          val _  = tvar := T.TVAR tvKind
        in
          ty
        end
      | T.TYVARty(ref(T.SUBSTITUTED realTy)) => 
        updateStrpathInTy realTy strPathPair
      | T.RAWty {tyCon, args} => 
        let
          val (tyCon) =
              updateStrpathInTyCon tyCon strPathPair
          val (newArgs) =
              updateStrpathInTyList args strPathPair
        in
          T.RAWty {tyCon = tyCon, args = newArgs}
        end
      | T.OPAQUEty {spec = {tyCon, args}, implTy}=>
        let
          val (newTyCon) =
              updateStrpathInTyCon tyCon strPathPair
          val (newArgs) =
              updateStrpathInTyList args strPathPair
        in
          T.OPAQUEty
             {spec = {tyCon = newTyCon, args = newArgs},
              implTy = implTy}
        end
      | T.ALIASty (printTy, actualTy) =>
        let
          val (newPrintTy) =
              updateStrpathInTy  printTy strPathPair
        in
          T.ALIASty (newPrintTy, actualTy)
        end
      | T.POLYty {boundtvars, body} => 
        let
          val (boundtvars) = 
              IEnv.foldli
                (fn (index, btvKind, (boundtvars)) =>
                    let
                      val ( btvKind) =
                          updateStrpathInBtvKind
                            btvKind strPathPair
                    in
                      (IEnv.insert(boundtvars, index, btvKind))
                    end)
                (IEnv.empty)
                boundtvars
          val (newBody) =  updateStrpathInTy  body strPathPair
        in
          T.POLYty{boundtvars = boundtvars, body = newBody}
        end
      | T.FUNMty(domainTyList, rangeTy) =>
        let
          val ( newDomainTyList) =
              updateStrpathInTyList  domainTyList strPathPair
          val (newRangeTy) =
              updateStrpathInTy  rangeTy strPathPair
        in
          T.FUNMty(newDomainTyList, newRangeTy)
        end
      | T.RECORDty tyFields => 
        let
          val ( newFields) = 
              SEnv.foldli
                (fn (label, ty, ( newFields)) => 
                    let
                      val (newTy) =  updateStrpathInTy  ty strPathPair
                    in ( SEnv.insert(newFields, label, newTy)) end)
                ( SEnv.empty)
                tyFields
        in 
          T.RECORDty newFields
        end
      | T.SPECty {tyCon, args} =>
        let
          val ( tyCon) =
              updateStrpathInTyCon  tyCon strPathPair
          val ( newArgs) =
              updateStrpathInTyList  args strPathPair
        in
          T.SPECty {tyCon = tyCon, args = newArgs}
        end
      | T.BOUNDVARty _ => ty
      | T.DUMMYty _ => ty
      | T.ERRORty  => ty
                          
  and updateStrpathInTvKind
        {lambdaDepth, id, recordKind, eqKind, tyvarName} strPathPair = 
      let
        val ( recordKind) =
            case recordKind of 
              T.UNIV => T.UNIV
            | T.REC tySEnvMap => 
              let
                val ( tySEnvMap) = 
                    (SEnv.foldli
                       (fn (label, ty, ( tySEnvMap)) =>
                           let
                             val (ty) = 
                                 updateStrpathInTy  ty strPathPair
                           in
                             ( SEnv.insert(tySEnvMap, label, ty))
                           end)
                       ( SEnv.empty)
                       tySEnvMap)
              in 
                (T.REC tySEnvMap)
              end
            | T.OCONSTkind tys =>
              let
                val ( tys) = 
                    (foldr
                       (fn (ty, ( tys)) =>
                           let
                             val (ty) = 
                                 updateStrpathInTy  ty strPathPair
                           in
                             ( ty :: tys)
                           end)
                       ( nil)
                       tys)
              in 
                T.OCONSTkind tys
              end
            | T.OPRIMkind {instances, operators} =>
              let
                val instances = 
                    foldr
                       (fn (ty, ( tys)) =>
                           let
                             val (ty) = 
                                 updateStrpathInTy  ty strPathPair
                           in
                             ( ty :: tys)
                           end)
                       nil
                       instances
              in 
                T.OPRIMkind {instances = instances, 
                             operators = operators}
              end
      in
        (
         {
          lambdaDepth = lambdaDepth,
          id=id, 
          recordKind = recordKind,
          eqKind = eqKind,
          tyvarName = tyvarName
         }
        )
      end
          
  and updateStrpathInTyCon
        ({name,
          strpath,
          abstract,
          tyvars,
          id,
          eqKind,
          constructorHasArgFlagList}:T.tyCon)
        strPathPair
    =
    (
     {
      name = name, 
      strpath = updateStrpath strpath strPathPair,
      abstract = abstract,
      tyvars = tyvars,
      id = id,
      eqKind = eqKind,
      constructorHasArgFlagList = constructorHasArgFlagList
     }
    )
        
  and updateStrpathInIdstate  idstate strPathPair =
      case idstate of
        T.CONID {namePath, funtyCon, ty, tag, tyCon} =>
        let
          val (ty) = 
              updateStrpathInTy  ty strPathPair
          val ( tyCon) = 
              updateStrpathInTyCon  tyCon strPathPair
        in
          (
           T.CONID{namePath =
                  (#1 namePath, updateStrpath (#2 namePath) strPathPair), 
                 funtyCon = funtyCon, 
                 ty = ty,
                 tag = tag,
                 tyCon = tyCon}
          )
        end
      | T.EXNID {namePath, funtyCon, ty, tag, tyCon} =>
        let
          val (ty) = 
              updateStrpathInTy  ty strPathPair
          val tyCon:T.tyCon = 
              updateStrpathInTyCon  tyCon strPathPair
        in
          (
           T.EXNID{namePath =
                   (#1 namePath, updateStrpath (#2 namePath) strPathPair), 
                   funtyCon = funtyCon, 
                   ty = ty,
                   tag = tag,
                   tyCon = tyCon}
          )
        end
      | T.VARID {namePath, ty} =>
        let
          val (ty) = 
              updateStrpathInTy  ty strPathPair
        in
          (
           T.VARID
             {namePath =
              (#1 namePath, updateStrpath (#2 namePath) strPathPair), 
              ty = ty
             }
          )
        end
      | T.RECFUNID ({namePath, ty}, int) =>
        let
          val (ty) = 
              updateStrpathInTy  ty strPathPair
        in
          (
           T.RECFUNID
             ({namePath =
               (#1 namePath, updateStrpath (#2 namePath) strPathPair), 
               ty = ty
              },
              int)
          )
        end
      | T.PRIM _ => idstate
      | T.OPRIM _ => idstate
                         
  and updateStrpathInDatacon  dataCon strPathPair = 
      SEnv.foldli
        (fn (label, idstate, ( dataCon)) =>
            let
              val ( newIdstate) = 
                  updateStrpathInIdstate  idstate strPathPair
            in 
              (
               SEnv.insert (dataCon,
                            label,
                            newIdstate))
            end)
        ( SEnv.empty)
        dataCon

  fun updateStrpathInVarEnv varEnv strPathPair =
      NPEnv.map
        (fn idstate =>
            let
              val newIdstate = updateStrpathInIdstate idstate strPathPair
            in newIdstate end)
        varEnv

  fun updateStrpathInTyConEnv tyConEnv strPathPair =
      NPEnv.map
        (fn tyBindInfo =>
            let
              val newTyBindInfo =
                  updateStrpathInTyBindInfo tyBindInfo strPathPair
            in newTyBindInfo end)
        tyConEnv
                    
  fun updateStrpathInEnv (tyConEnv, varEnv) strPathPair =
      (updateStrpathInTyConEnv tyConEnv strPathPair,
       updateStrpathInVarEnv varEnv strPathPair)


 (* addStrpathXXX Utilities for functor application to adjust the 
  * old prefix of declared datatype in the functor body to be the new
  * prefix (i.e. unique long structure name). For example,
  *
  *  structure A = F(struct ... end) 
  *
  * Old prefix in the top level is always NilPath(i.e. F is not used as 
  * a prefix). Suppose A is injected into $1, then new prefix now is "$1.A".
  *)
  fun addStrpathInTyBindInfo updateCandidateSet strPathPrefix tyBindInfo  =
      case tyBindInfo of
        T.TYCON {tyCon, datacon} =>
        T.TYCON {tyCon =
                 addStrpathInTyCon updateCandidateSet strPathPrefix tyCon,
                 datacon =
                 addStrpathInDatacon updateCandidateSet strPathPrefix datacon}
      | T.TYFUN tyfun => 
        T.TYFUN (addStrpathInTyfun updateCandidateSet strPathPrefix tyfun)
      | T.TYOPAQUE
          ({spec = tyspec
                     as
                     {name,
                      id,
                      eqKind,
                      tyvars,
                      strpath,
                      abstract,
                      constructorHasArgFlagList},
            impl}) =>
        T.TYOPAQUE ({spec =
                     {name = name, 
                      id = id, 
                      eqKind = eqKind, 
                      tyvars = tyvars, 
                      strpath = Path.joinPath(strPathPrefix, strpath), 
                      abstract = abstract,
                      constructorHasArgFlagList = constructorHasArgFlagList},
                     impl = impl})
      | T.TYSPEC
          {name,
           id,
           eqKind,
           tyvars,
           strpath,
           abstract,
           constructorHasArgFlagList} =>
        T.TYSPEC {name = name, 
                  id = id, 
                  eqKind = eqKind, 
                  tyvars = tyvars, 
                  strpath = Path.joinPath(strPathPrefix, strpath), 
                  abstract = abstract,
                  constructorHasArgFlagList = constructorHasArgFlagList}
              
  and addStrpathInTyfun updateCandidateSet
                        (strPathPrefix:Path.path) 
                        ({name, strpath, tyargs, body}:T.tyFun)  =
      let
        val newTyargs =
            IEnv.map
              (addStrpathInBtvKind updateCandidateSet strPathPrefix) tyargs
        val newBody = addStrpathInTy updateCandidateSet strPathPrefix body 
      in
        {name = name,
         strpath = Path.joinPath (strPathPrefix, strpath),
         tyargs = newTyargs,
         body = newBody}:T.tyFun
      end
          
  and addStrpathInBtvKind
        updateCandidateSet strPath {recordKind, eqKind}  =
      let
        val recordKind =
            case recordKind of 
              T.UNIV => T.UNIV
            | T.REC tySEnvMap => 
              T.REC
                (SEnv.map
                   (addStrpathInTy updateCandidateSet strPath) tySEnvMap)
            | T.OCONSTkind tys =>
              T.OCONSTkind
                (map (addStrpathInTy updateCandidateSet strPath) tys)
            | T.OPRIMkind {instances, operators} =>
              T.OPRIMkind
                {instances =
                   map (addStrpathInTy updateCandidateSet strPath) instances,
                 operators = operators}
      in
        {
         recordKind = recordKind,
         eqKind = eqKind
        }
      end
          
  and addStrpathInTyList updateCandidateSet strPath tyList  =           
      map (addStrpathInTy updateCandidateSet strPath) tyList
      
  and addStrpathInTy updateCandidateSet strPath ty  = 
      case ty of
        T.INSTCODEty {oprimId,name,oprimPolyTy, keyTyList, instTyList}  =>
        T.INSTCODEty
         {
          oprimId = oprimId,
          name = name,
          oprimPolyTy = addStrpathInTy updateCandidateSet strPath oprimPolyTy,
          keyTyList = addStrpathInTyList updateCandidateSet strPath keyTyList,
          instTyList = addStrpathInTyList updateCandidateSet strPath instTyList
         }
      | T.TYVARty (tvar as ref (T.TVAR tvKind)) => 
        let
          val tvKind = addStrpathInTvKind updateCandidateSet strPath tvKind 
          val _  = tvar := T.TVAR tvKind
        in
          ty
        end
      | T.TYVARty(ref(T.SUBSTITUTED realTy)) => 
        addStrpathInTy updateCandidateSet strPath realTy 
      | T.RAWty {tyCon, args} => 
        let
          val newTyCon = addStrpathInTyCon updateCandidateSet strPath tyCon
          val newArgs = addStrpathInTyList updateCandidateSet strPath args 
        in
          T.RAWty {tyCon= newTyCon, args = newArgs}
        end
      | T.OPAQUEty {spec = {tyCon, args}, implTy} =>
        let
          val newTyCon = addStrpathInTyCon updateCandidateSet strPath tyCon
          val newArgs = addStrpathInTyList updateCandidateSet strPath args 
        in
          T.OPAQUEty
            {spec = {tyCon = newTyCon, args = newArgs}, implTy = implTy}
        end
      | T.ALIASty (printTy, actualTy) =>
        let
          val newPrintTy = 
              addStrpathInTy updateCandidateSet strPath printTy
        in
          T.ALIASty (newPrintTy, actualTy)
        end
      | T.POLYty {boundtvars, body} => 
        let
          val boundtvars = 
              IEnv.map (addStrpathInBtvKind updateCandidateSet strPath)
                       boundtvars
          val newBody = addStrpathInTy updateCandidateSet strPath body 
        in
          T.POLYty{boundtvars = boundtvars, body = newBody}
        end
      | T.FUNMty(domainTyList, rangeTy) =>
        let
          val newDomainTyList =
              addStrpathInTyList updateCandidateSet strPath domainTyList 
          val newRangeTy =
              addStrpathInTy updateCandidateSet strPath rangeTy 
        in
          T.FUNMty(newDomainTyList, newRangeTy)
        end
      | T.RECORDty tyFields => 
        T.RECORDty
          (SEnv.map (addStrpathInTy updateCandidateSet strPath) tyFields)
      | T.SPECty {tyCon, args} =>
        let
          val newTyCon = addStrpathInTyCon updateCandidateSet strPath tyCon
          val newArgs = addStrpathInTyList updateCandidateSet strPath args 
        in
          T.SPECty {tyCon = newTyCon, args = newArgs}
        end
      | T.BOUNDVARty _ => ty
      | T.DUMMYty _ => ty
      | T.ERRORty  => ty
                          
  and addStrpathInTvKind
        updateCandidateSet
        strPath
        {lambdaDepth, id, recordKind, eqKind, tyvarName}  = 
      let
        val recordKind = 
            case recordKind of 
              T.UNIV => T.UNIV
            | T.REC tySEnvMap => 
              T.REC
                (SEnv.map
                   (addStrpathInTy updateCandidateSet strPath) tySEnvMap)
            | T.OCONSTkind tys =>
              T.OCONSTkind
                (map (addStrpathInTy updateCandidateSet strPath) tys)
            | T.OPRIMkind {instances, operators} =>
              T.OPRIMkind
                {instances =
                   map (addStrpathInTy updateCandidateSet strPath) instances,
                 operators = operators}
      in
        {
         lambdaDepth = lambdaDepth,
         id=id, 
         recordKind = recordKind,
         eqKind = eqKind,
         tyvarName = tyvarName
        }
      end
      
  and addStrpathInTyCon 
        updateCandidateSet 
        strPathPrefix
        (tyCon:T.tyCon
           as
           {name,
            strpath,
            abstract,
            tyvars,
            id,
            eqKind,
            constructorHasArgFlagList}) 
    =
    let
      val newStrpath = if TyConID.Set.member(updateCandidateSet, id) then
                         Path.joinPath (strPathPrefix, strpath)
                       else strpath
    in
      {
       name = name, 
       strpath = newStrpath,
       abstract = abstract,
       tyvars = tyvars,
       id = id,
       eqKind = eqKind,
       constructorHasArgFlagList = constructorHasArgFlagList
      }
    end

  and addStrpathInIdstate updateCandidateSet strPath idstate  =
      case idstate of
        T.CONID {namePath, funtyCon, ty, tag, tyCon} =>
        T.CONID{namePath = (#1 namePath, Path.joinPath(strPath, #2 namePath)), 
              funtyCon = funtyCon, 
              ty = addStrpathInTy updateCandidateSet strPath ty,
              tag = tag,
              tyCon = addStrpathInTyCon updateCandidateSet strPath tyCon}
      | T.EXNID {namePath, funtyCon, ty, tag, tyCon} =>
        T.EXNID{namePath = (#1 namePath, Path.joinPath(strPath, #2 namePath)), 
                funtyCon = funtyCon, 
                ty = addStrpathInTy updateCandidateSet strPath ty,
                tag = tag,
                tyCon = addStrpathInTyCon updateCandidateSet strPath tyCon}
      | T.VARID {namePath, ty} =>
        T.VARID
          {namePath = (#1 namePath, Path.joinPath (strPath, #2 namePath)), 
           ty = addStrpathInTy updateCandidateSet strPath ty}
      | T.RECFUNID ({namePath, ty}, int) =>
        T.RECFUNID
          ({namePath = (#1 namePath, Path.joinPath (strPath, #2 namePath) ), 
            ty = addStrpathInTy updateCandidateSet strPath ty},
           int)
      | T.PRIM _ => idstate
      | T.OPRIM _ => idstate
                         
  and addStrpathInDatacon updateCandidateSet strPath dataCon = 
      SEnv.map (fn (T.CONID {namePath, funtyCon, ty, tag, tyCon}) =>
                   T.CONID{(*Inside dataCon, constructors use short name *)
                             namePath = namePath, 
                           funtyCon = funtyCon, 
                           ty = addStrpathInTy updateCandidateSet strPath ty,
                           tag = tag,
                           tyCon = tyCon}
                 | _ =>
                   raise
                     Control.Bug "non CONID in dataCon(addStrpathInDatacon)")
               dataCon 

  fun addStrpathInVarEnv updateCandidateSet strPath varEnv =
      NPEnv.foldli
        (fn (varNamePath, idstate, newVarEnv) =>
            let
              val newNamePath =  (#1 varNamePath, 
                                  Path.joinPath(strPath, #2 varNamePath))
              val newIdstate = 
                  addStrpathInIdstate updateCandidateSet
                                      strPath
                                      idstate
            in
              NPEnv.insert(newVarEnv, newNamePath, newIdstate)
            end)
        NPEnv.empty
        varEnv

  fun addStrpathInTyConEnv updateCandidateSet strPath tyConEnv  =
      NPEnv.foldli
        (fn (tyNamePath, tyBindInfo, newTyEnv) =>
            NPEnv.insert
              (newTyEnv,
               (#1 tyNamePath, Path.joinPath(strPath, #2 tyNamePath)),
               addStrpathInTyBindInfo updateCandidateSet strPath tyBindInfo))
        NPEnv.empty
        tyConEnv
                       
  fun addStrpathInEnv (tyConEnv, varEnv) strPath =
      let
        fun updateCandidateInTyConEnv tyConEnv = 
            NPEnv.foldli
              (fn (tyCon, tyBindInfo1, updateCandidateSet) =>
                  case tyBindInfo1 of
                    T.TYSPEC ({id, ...}) =>
                    TyConID.Set.add(updateCandidateSet, id)
                  | T.TYOPAQUE ({spec = {id, ...}, ...}) =>
                    TyConID.Set.add(updateCandidateSet, id)
                  | T.TYCON {tyCon = {id,...}, ...} =>
                    TyConID.Set.add(updateCandidateSet, id)
                  | T.TYFUN
                      {body =
                       T.ALIASty(T.RAWty {tyCon = {id,...},...}, _),...} => 
                    TyConID.Set.add(updateCandidateSet, id)
                  | T.TYFUN _  =>
                    raise Control.Bug "illegal tyfun format(addStrpathInEnv)")
              TyConID.Set.empty
              tyConEnv
        val updateCandidateSet = updateCandidateInTyConEnv tyConEnv
        val newTyConEnv =
            addStrpathInTyConEnv updateCandidateSet strPath tyConEnv 
        val newVarEnv = addStrpathInVarEnv updateCandidateSet strPath varEnv
      in
        (newTyConEnv, newVarEnv)
      end

  fun makeExnConPath namePath tyOpt =
      let
        val (ty, funtyCon) =
            case tyOpt of
              SOME argty =>
              (T.FUNMty([argty], PredefinedTypes.exnty), true)
            | _ => (PredefinedTypes.exnty, false)
      in
        {
         namePath = namePath,
         funtyCon = funtyCon,
         ty = ty,
         tyCon = PredefinedTypes.exnTyCon,
         tag = ExnTagID.generate ()
        }
      end

(*
  fun restoreExnTagExternalNameVarEnv (topVarEnv : T.topVarEnv) =
      SEnv.mapi (fn (name, idstate) => 
                   case idstate of
                       EXNID (exn as {tag, ...}) =>
                       let
                           val newTag = Counters.setExnTagID name
                       in
                           EXNID {namePath = #namePath exn, 
                                  funtyCon = #funtyCon exn, 
                                  ty = #ty exn, 
                                  tag = newTag, 
                                  tyCon = #tyCon exn}
                       end
                     | other => other)
               topVarEnv
*)

  fun exnTagSetVarEnv varEnv =
      NPEnv.foldl
        (fn (T.EXNID {tag, ...}, exnTagSet) =>
            ExnTagID.Set.add(exnTagSet, tag)
          | (_, exnTagSet) => exnTagSet
        )
        ExnTagID.Set.empty
        varEnv

  fun exnTagSetEnv (tyConEnv, varEnv) =
      exnTagSetVarEnv varEnv
  end
end
