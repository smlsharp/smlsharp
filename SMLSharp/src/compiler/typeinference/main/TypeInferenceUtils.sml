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
      structure PT = PatternCalcWithTvars
      structure PDT = PredefinedTypes
      structure TIC = TypeInferenceContext
      structure TC = TypeContext
      structure TU = TypesUtils
      structure TCU = TypedCalcUtils
      structure E = TypeInferenceError
      (*    structure STE = StaticTypeEnv *)
      structure NM = NameMap
      structure NPEnv = NameMap.NPEnv
      open Types TypesUtils TypedCalc
  in
  
      val dummyTyId = ref 0
      fun nextDummyTy () = DUMMYty (!dummyTyId) before dummyTyId := !dummyTyId + 1

     fun eliminateVacuousTyvars () =
        let
          fun instanticateTv tv =
            case tv of
              ref(TVAR {recordKind = OVERLOADED (h :: tl), ...}) =>
                tv := SUBSTITUTED h
            | ref(TVAR {recordKind = REC tyFields, ...}) => 
                tv := SUBSTITUTED (RECORDty tyFields)
            | ref(TVAR {recordKind = UNIV, ...}) => 
                tv := SUBSTITUTED (nextDummyTy())
            | _ => ()
        in
          (
           List.app instanticateTv (!kindedTyvarList);
           kindedTyvarList := nil
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

      (**************************************************************************************)

      (*
       * make a fresh instance of ty by instantiating the top-level type

       * abstractions (only)
       *)
      fun freshTopLevelInstTy ty =
          case ty of
              (POLYty{boundtvars, body, ...}) =>
              let 
                  val subst = freshSubst boundtvars
                  val bty = substBTvar subst body
              in  
                  (bty, IEnv.listItems subst)
              end
            | _ => (ty, nil)

      fun etaExpandCon namePath loc idState = 
          case idState of
              CONID (conPathInfo as {namePath = namePath1, funtyCon, ty, tag, tyCon}) =>
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
                          POLYty{boundtvars, body = FUNMty([argTy], resultTy)} =>
                          let
                              val (subst, newBoundEnv) = TU.copyBoundEnv boundtvars
                              val newArgTy = TU.substBTvar subst argTy
                              val newResultTy = TU.substBTvar subst resultTy
                              val newVarPathInfo =
                                  {namePath = (Counters.newVarName (), Path.NilPath), 
                                   ty = newArgTy}
                              val newTy = POLYty{boundtvars=newBoundEnv, body = FUNMty([newArgTy], newResultTy)}
                          in
                              (
                               newTy,
                               TPPOLYFNM
                                   {
                                    btvEnv=newBoundEnv,
                                    argVarList=[newVarPathInfo],
                                    bodyTy=newResultTy,
                                    bodyExp=
                                    TPDATACONSTRUCT
                                        {
                                         con=termconPathInfo,
                                         instTyList=map BOUNDVARty (IEnv.listKeys newBoundEnv),
                                         argExpOpt= SOME (TPVAR (newVarPathInfo, loc)),
                                         loc=loc
                                        },
                                    loc=loc
                                   }
                              )
                          end
                        | POLYty{boundtvars, body = FUNMty(_, ty)} =>
                          raise Control.Bug "Uncurried fun type in OPRIM"
                        | FUNMty([argTy], resultTy) => (* ty should be mono; data constructor has a closed type *)
                          let
                              val newVarPathInfo =
                                  {namePath = (Counters.newVarName (), Path.NilPath), 
                                   ty = argTy}
                          in
                              (
                               ty,
                               TPFNM
                                   {
                                    argVarList=[newVarPathInfo],
                                    bodyTy=resultTy,
                                    bodyExp=
                                    TPDATACONSTRUCT
                                        {
                                         con=termconPathInfo,
                                         instTyList=nil,
                                         argExpOpt=SOME (TPVAR (newVarPathInfo, loc)),
                                         loc=loc
                                        },
                                    loc=loc
                                   }
                              )
                          end
                        | FUNMty(_, ty) => raise Control.Bug "Uncurried fun type in OPRIM"
                        | _ => raise Control.Bug "datacon type"
                  else (ty, TPDATACONSTRUCT{con=termconPathInfo, instTyList=nil, argExpOpt=NONE, loc=loc})
              end
            | EXNID (exnPathInfo as {namePath = namePath1, funtyCon, ty, tag, tyCon}) =>
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
                          POLYty _=>
                          raise Control.Bug "exception type is not generalized"
                        | FUNMty([argTy], resultTy) => 
                          let
                              val newVarPathInfo =
                                  {namePath = (Counters.newVarName (), Path.NilPath), 
                                   ty = argTy}
                          in
                              (
                               ty,
                               TPFNM
                                   {
                                    argVarList=[newVarPathInfo],
                                    bodyTy=resultTy,
                                    bodyExp=
                                    TPEXNCONSTRUCT
                                        {
                                         exn=termconPathInfo,
                                         instTyList=nil,
                                         argExpOpt=SOME (TPVAR (newVarPathInfo, loc)),
                                         loc=loc
                                        },
                                    loc=loc
                                   }
                              )
                          end
                        | FUNMty(_, ty) => raise Control.Bug "Uncurried fun type in OPRIM"
                        | _ => raise Control.Bug "datacon type"
                  else (ty, TPEXNCONSTRUCT{exn=termconPathInfo, instTyList=nil, argExpOpt=NONE, loc=loc})
              end
            | PRIM (primInfo as {name, ty}) =>
              (case ty of
                   POLYty{boundtvars, body = FUNMty([argTy], resultTy)} =>
                   let
                       val (subst, newBoundEnv) = TU.copyBoundEnv boundtvars
                       val newArgTy = TU.substBTvar subst argTy
                       val newResultTy = TU.substBTvar subst resultTy
                       val newVarPathInfo =
                           {namePath = (Counters.newVarName (), Path.NilPath), 
                            ty = newArgTy}
                       val newTy = POLYty{boundtvars=newBoundEnv, body = FUNMty([newArgTy], newResultTy)}
                   in
                       (
                        newTy,
                        TPPOLYFNM
                            {
                             btvEnv=newBoundEnv,
                             argVarList=[newVarPathInfo],
                             bodyTy=newResultTy,
                             bodyExp=
                             TPPRIMAPPLY
                                 {
                                  primOp=primInfo,
                                  instTyList=map BOUNDVARty (IEnv.listKeys newBoundEnv),
                                  argExpOpt=SOME (TPVAR (newVarPathInfo, loc)),
                                  loc=loc
                                 },
                             loc=loc
                            }
                       )
                   end
                 | POLYty{boundtvars, body = FUNMty(_, ty)} =>
                   raise Control.Bug "Uncurried fun type in OPRIM"
                 | FUNMty([argTy], resultTy) =>
                   let
                       val newVarPathInfo =
                           {namePath = (Counters.newVarName (), Path.NilPath), 
                            ty = argTy}
                   in
                       (
                        ty,
                        TPFNM
                            {
                             argVarList=[newVarPathInfo],
                             bodyTy=resultTy,
                             bodyExp=
                             TPPRIMAPPLY
                                 {
                                  primOp=primInfo,
                                  instTyList=nil,
                                  argExpOpt=SOME (TPVAR (newVarPathInfo, loc)),
                                  loc=loc
                                 },
                             loc=loc
                            }
                       )
                   end
                 | FUNMty(_, ty) => raise Control.Bug "Uncurried fun type in OPRIM"
                 | _ =>raise Control.Bug "datacon type"
              )
            | OPRIM (oprimInfo as {name, ty, instances}) =>
              let
                  val (instTy, instTyList) = freshTopLevelInstTy ty
              in
                  case instTy of
                      FUNMty([argTy], resultTy) =>
                      let
                          val newVarPathInfo =
                              {namePath = (Counters.newVarName (), Path.NilPath), 
                               ty = argTy}
                      in
                          (
                           instTy,
                           TPFNM
                               {
                                argVarList=[newVarPathInfo],
                                bodyTy=resultTy,
                                bodyExp=
                                TPOPRIMAPPLY
                                    {
                                     oprimOp=oprimInfo,
                                     instances=instTyList,
                                     argExpOpt=SOME (TPVAR (newVarPathInfo, loc)),
                                     loc=loc
                                    },
                                loc=loc
                               }
                          )
                      end
                    | FUNMty(_, ty) => raise Control.Bug "Uncurried fun type in OPRIM"
                    | _ =>raise Control.Bug "oprim type"
              end
            | RECFUNID _ => raise Control.Bug "recfunid in etaExpandCon"
            | VARID _ => raise Control.Bug "var in etaExpandCon"

      fun tyConIdInTyBindInfo tyBindInfo = 
          case  tyBindInfo of
              TYCON ({tyCon = {id, ...}, ...}) => id
            | TYSPEC {id, ...} => id
            | TYOPAQUE {spec={id, ...}, impl} => id
            | TYFUN {name,...} => raise (E.SharingOnTypeFun {tyConName = name})

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
              (fn (CONID {namePath, funtyCon, ty, tag, tyCon}, tyConIdSet) =>
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
              TYCON {tyCon = {name, strpath, tyvars, id, abstract, eqKind, constructorHasArgFlagList}, datacon} =>
              TYCON {tyCon = {name = name,
                              strpath = Path.joinPath(path, strpath),
                              tyvars = tyvars,
                              id = id,
                              abstract = abstract,
                              eqKind = eqKind,
                              constructorHasArgFlagList = constructorHasArgFlagList},
                     datacon = datacon}
            | TYFUN {name, strpath, tyargs, body} => 
              TYFUN {name = name,
                     strpath = Path.joinPath(path, strpath),
                     tyargs = tyargs,
                     body = body}
            | TYOPAQUE {spec = {name, strpath, id, abstract, eqKind, tyvars, constructorHasArgFlagList}, impl} =>
              TYOPAQUE {spec = {name = name,
                                strpath = Path.joinPath(path, strpath),
                                id = id,
                                abstract = abstract,
                                eqKind = eqKind,
                                tyvars = tyvars,
                                constructorHasArgFlagList = constructorHasArgFlagList},
                        impl = impl}
            | TYSPEC  {name, strpath, id, abstract, eqKind, tyvars, constructorHasArgFlagList} =>
              TYSPEC {name = name,
                      strpath = Path.joinPath(path, strpath),
                      id = id,
                      abstract = abstract,
                      eqKind = eqKind,
                      tyvars = tyvars,
                      constructorHasArgFlagList = constructorHasArgFlagList}
              
      and addPrefixTyEnv (tyEnv, path) =
          NPEnv.foldli (fn (tyNamePath, tyBindInfo, newTyEnv) =>
                           NPEnv.insert(newTyEnv,
                                        (#1 tyNamePath, Path.joinPath(path, #2 tyNamePath)),
                                        addPrefixTyBindInfo (tyBindInfo, path)))
                       NPEnv.empty
                       tyEnv

      and addIdstate (idstate, path) =
          case idstate of
              VARID {namePath, ty} =>
              VARID {namePath = (#1 namePath, Path.joinPath(path, #2 namePath)), ty = ty}
            | CONID {namePath, funtyCon, ty, tag, tyCon} =>
              CONID {namePath = (#1 namePath, Path.joinPath(path, #2 namePath)),
                     funtyCon = funtyCon, 
                     ty = ty,
                     tag = tag, 
                     tyCon = tyCon}
            | EXNID {namePath, funtyCon, ty, tag, tyCon} =>
              EXNID {namePath = (#1 namePath, Path.joinPath(path, #2 namePath)),
                     funtyCon = funtyCon, 
                     ty = ty,
                     tag = tag, 
                     tyCon = tyCon}
            | RECFUNID ({namePath, ty}, int) =>
              RECFUNID
                  ({namePath = (#1 namePath, Path.joinPath(path, #2 namePath)),
                    ty = ty},
                   int)
            | _ => raise Control.Bug "illegal idstate"
                         
      and addPrefixVarEnv (varEnv, path : Path.path) =
          NPEnv.foldli (fn (varNamePath, idstate, (newVarEnv, nameMap)) =>
                           let
                               val newNamePath =  (#1 varNamePath, Path.joinPath(path, #2 varNamePath))
                               val newName = NameMap.namePathToString newNamePath
                               val newIdstate = addIdstate (idstate,  path)
                           in
                               (NPEnv.insert(newVarEnv, newNamePath, newIdstate),
                                SEnv.insert(nameMap, newName, NM.namePathToString(varNamePath)))
                           end)
                       (NPEnv.empty, SEnv.empty)
                       varEnv
      (************************************************************************)
      fun setPrefixEnv ((tyEnv, varEnv), path) =
          let
              val newTyEnv = setPrefixTyEnv (tyEnv, path)
              val (newVarEnv, prefixedNameMap) = setPrefixVarEnv (varEnv, path)
          in
              ((newTyEnv, newVarEnv), prefixedNameMap)
          end

      and setPrefixTyBindInfo (tyBindInfo, path) =
          case tyBindInfo of
              TYCON {tyCon = {name, strpath, tyvars, id, abstract, eqKind, constructorHasArgFlagList}, 
                     datacon} =>
              TYCON {tyCon = {name = name,
                              strpath = path,
                              tyvars = tyvars,
                              id = id,
                              abstract = abstract,
                              eqKind = eqKind,
                              constructorHasArgFlagList = constructorHasArgFlagList},
                     datacon = datacon
                    }
            | TYFUN {name, strpath, tyargs, body} => 
              TYFUN {name = name,
                     strpath = path,
                     tyargs = tyargs,
                     body = body}
            | TYOPAQUE {spec = {name, strpath, id, abstract, eqKind, tyvars, constructorHasArgFlagList}, impl} 
              =>
              TYOPAQUE {spec = {name = name,
                                strpath = path,
                                id = id,
                                abstract = abstract,
                                eqKind = eqKind,
                                tyvars = tyvars,
                                constructorHasArgFlagList = constructorHasArgFlagList},
                        impl = impl}
            | TYSPEC  {name, strpath, id, abstract, eqKind, tyvars, constructorHasArgFlagList} =>
              TYSPEC {name = name,
                      strpath = path,
                      id = id,
                      abstract = abstract,
                      eqKind = eqKind,
                      tyvars = tyvars,
                      constructorHasArgFlagList = constructorHasArgFlagList}
              

      and setPrefixTyEnv (tyEnv, path) =
          NPEnv.foldli (fn (tyNamePath, tyBindInfo, newTyEnv) =>
                           NPEnv.insert(newTyEnv,
                                        (#1 tyNamePath, Path.joinPath(path, #2 tyNamePath)),
                                        setPrefixTyBindInfo (tyBindInfo, path)))
                       NPEnv.empty
                       tyEnv

      and setIdstate (idstate, path) =
          case idstate of
              VARID {namePath, ty} =>
              VARID {namePath = (#1 namePath, path), ty = ty}
            | CONID {namePath, funtyCon, ty, tag, tyCon} =>
              CONID {namePath = (#1 namePath, path),
                     funtyCon = funtyCon, 
                     ty = ty,
                     tag = tag, 
                     tyCon = tyCon}
            | EXNID {namePath, funtyCon, ty, tag, tyCon} =>
              EXNID {namePath = (#1 namePath, path),
                     funtyCon = funtyCon, 
                     ty = ty,
                     tag = tag, 
                     tyCon = tyCon}
            | RECFUNID ({namePath, ty}, int) =>
              RECFUNID
                  ({namePath = (#1 namePath, path),
                    ty = ty},
                   int)
            | _ => raise Control.Bug "illegal idstate"
                         
      and setPrefixVarEnv (varEnv, path : Path.path) =
          NPEnv.foldli (fn (namePath, idstate, (newVarEnv, nameMap)) =>
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
          SEnv.foldli (fn (varName, idstate, (newVarEnv, nameMap)) =>
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

      (********************************************************************************)
      fun constructVarEnvFromVarNameMap (varEnv, varNamePathEnv) =
          NPEnv.foldli(fn (srcNamePath, idstate, newVarEnv) =>
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
          NPEnv.foldli (fn (srcNamePath, tyState, newTyConEnv) =>
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
                       
      fun constructEnvFromNameMap (Env : Types.Env, flattenedNameMap:NM.basicNameNPEnv)  =
          let
              val tyConEnv = 
                  constructTyConEnvFromTyNameMap (#1 Env, #1 flattenedNameMap) 
              val varEnv = 
                  constructVarEnvFromVarNameMap (#2 Env, #2 flattenedNameMap) 
          in
              (tyConEnv, varEnv)
          end

      fun resotreSysNamePathSigVarEnv (sigVarEnv, varNamePathEnv) loc =
          NPEnv.foldli (fn (srcNamePath, idstate, newVarEnv) =>
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
          NPEnv.foldli (fn (srcNamePath, tyBindInfo, newTyConEnv) =>
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
                       
      fun restoreSysNamePathSigEnv (strictEnv:Types.Env, flattenedNameMap:NM.basicNameNPEnv) loc =
          let
              val tyConEnv = 
                  restoreSysNamePathSigTyConEnv (#1 strictEnv, #1 flattenedNameMap) loc
              val varEnv = 
                  resotreSysNamePathSigVarEnv (#2 strictEnv, #2 flattenedNameMap) loc
          in
              (tyConEnv, varEnv)
          end
      (****************************************************************************************)
      fun constructActualArgTypeEnvFromNameMap
              (flattenedNameNPEnv : NM.basicNameNPEnv) basis loc =
          let
              val tyConEnv =
                  NPEnv.foldli (fn (namePath, tyState, newTyConEnv) => 
                                   case TIC.lookupTyConInBasis(basis, NM.getNamePathFromTyState tyState) of
                                       NONE => 
                                       (* error will be captured by functor signature matching *)
                                       newTyConEnv
                                     | SOME tyBindInfo =>
                                       NPEnv.insert(newTyConEnv, namePath, tyBindInfo))
                               NPEnv.empty
                               (#1 flattenedNameNPEnv)

              val varEnv =
                  NPEnv.foldli (fn (namePath, idstate, newVarEnv) => 
                                   case TIC.lookupVarInBasis(basis, NM.getNamePathFromIdstate idstate) of
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


      (**************************************************************************************)
      (* updatedateStrpath manipulation utilities *)         
      fun updateStrpath strpath {current, original} =
          if Path.isPrefix {path = strpath, prefix = original} then
              let val (_, remPath) = Path.removeCommonPrefix (original, strpath)
              in Path.joinPath (current, remPath) end
          else strpath
               
      fun updateStrpathInTyBindInfo  tyBindInfo strPathPair =
          case tyBindInfo of
              TYCON {tyCon, datacon} =>
              let
                  val newTyCon = 
                      updateStrpathInTyCon tyCon strPathPair
                  val (newDatacon) =
                      updateStrpathInDatacon datacon strPathPair
              in
                  (TYCON {tyCon = newTyCon, datacon = newDatacon})
              end
            | TYFUN tyfun => 
              let
                  val newTyFun = 
                      updateStrpathInTyfun tyfun strPathPair
              in
                  (TYFUN newTyFun)
              end
            | TYSPEC tycon =>
              let
                  val (newTyCon) = 
                      updateStrpathInTyCon tycon strPathPair
              in
                  (TYSPEC newTyCon)
              end
            | TYOPAQUE ({spec = {name, id, eqKind, tyvars, strpath, abstract, constructorHasArgFlagList},
                         impl}) =>
              (TYOPAQUE ({spec = {name = name, 
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
                  IEnv.foldli (fn (key, tyarg, (newTyargs)) =>
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
          
      and updateStrpathInBtvKind  {index, recordKind, eqKind} strPathPair =
          let
              val (recordKind) =
                  case recordKind of 
                      UNIV => (UNIV)
                    | REC tySEnvMap => 
                      let
                          val (tySEnvMap) = 
                              (SEnv.foldli
                                   (fn (label, ty, (tySEnvMap)) =>
                                       let
                                           val ty = 
                                               updateStrpathInTy ty strPathPair
                                       in
                                           (SEnv.insert(tySEnvMap, label, ty))
                                       end)
                                   (SEnv.empty)
                                   tySEnvMap)
                      in
                          (REC tySEnvMap)
                      end
                    | OVERLOADED tys =>
                      let
                          val (tys) = 
                              (foldr
                                   (fn (ty, (tys)) =>
                                       let
                                           val (ty) = 
                                               updateStrpathInTy ty strPathPair
                                       in
                                           (ty :: tys)
                                       end)
                                   (nil)
                                   tys)
                      in 
                          (OVERLOADED tys)
                      end
          in
              (
               {
                index=index, 
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
              TYVARty (tvar as ref (TVAR tvKind)) => 
              let
                  val tvKind =
                      updateStrpathInTvKind tvKind strPathPair
                  val _  = tvar := TVAR tvKind
              in
                  ty
              end
            | TYVARty(ref(SUBSTITUTED realTy)) => 
              updateStrpathInTy realTy strPathPair
            | RAWty {tyCon, args} => 
              let
                  val (tyCon) =
                      updateStrpathInTyCon tyCon strPathPair
                  val (newArgs) =
                      updateStrpathInTyList args strPathPair
              in
                  (RAWty {tyCon = tyCon, args = newArgs})
              end
            | OPAQUEty {spec = {tyCon, args}, implTy}=>
              let
                  val (newTyCon) =
                      updateStrpathInTyCon tyCon strPathPair
                  val (newArgs) =
                      updateStrpathInTyList args strPathPair
              in
                  (OPAQUEty {spec = {tyCon = newTyCon, args = newArgs}, implTy = implTy})
              end
            | ALIASty (printTy, actualTy) =>
              let
                  val (newPrintTy) =
                      updateStrpathInTy  printTy strPathPair
              in
                  (ALIASty (newPrintTy, actualTy))
              end
            | POLYty {boundtvars, body} => 
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
                  (POLYty{boundtvars = boundtvars, body = newBody})
              end
            | FUNMty(domainTyList, rangeTy) =>
              let
                  val ( newDomainTyList) =
                      updateStrpathInTyList  domainTyList strPathPair
                  val (newRangeTy) =
                      updateStrpathInTy  rangeTy strPathPair
              in
                  (FUNMty(newDomainTyList, newRangeTy))
              end
            | RECORDty tyFields => 
              let
                  val ( newFields) = 
                      SEnv.foldli (fn (label, ty, ( newFields)) => 
                                      let
                                          val (newTy) =  updateStrpathInTy  ty strPathPair
                                      in ( SEnv.insert(newFields, label, newTy)) end)
                                  ( SEnv.empty)
                                  tyFields
              in (RECORDty newFields) end
            | SPECty {tyCon, args} =>
              let
                  val ( tyCon) =
                      updateStrpathInTyCon  tyCon strPathPair
                  val ( newArgs) =
                      updateStrpathInTyList  args strPathPair
              in
                  (SPECty {tyCon = tyCon, args = newArgs})
              end
            | BOUNDVARty _ => (ty)
            | DUMMYty _ => (ty)
            | ERRORty  => (ty)
                          
      and updateStrpathInTvKind  {lambdaDepth, id, recordKind, eqKind, tyvarName} strPathPair = 
          let
              val ( recordKind) =
                  case recordKind of 
                      UNIV => ( UNIV)
                    | REC tySEnvMap => 
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
                          (REC tySEnvMap)
                      end
                    | OVERLOADED tys =>
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
                          ( OVERLOADED tys)
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
              
              ({name, strpath, abstract, tyvars, id, eqKind, constructorHasArgFlagList}:Types.tyCon)
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
              Types.CONID {namePath, funtyCon, ty, tag, tyCon} =>
              let
                  val (ty) = 
                      updateStrpathInTy  ty strPathPair
                  val ( tyCon) = 
                      updateStrpathInTyCon  tyCon strPathPair
              in
                  (
                   CONID{namePath = (#1 namePath, updateStrpath (#2 namePath) strPathPair), 
                         funtyCon = funtyCon, 
                         ty = ty,
                         tag = tag,
                         tyCon = tyCon}
                  )
              end
            | Types.EXNID {namePath, funtyCon, ty, tag, tyCon} =>
              let
                  val (ty) = 
                      updateStrpathInTy  ty strPathPair
                  val ( tyCon:tyCon) = 
                      updateStrpathInTyCon  tyCon strPathPair
              in
                  (
                   EXNID{namePath = (#1 namePath, updateStrpath (#2 namePath) strPathPair), 
                         funtyCon = funtyCon, 
                         ty = ty,
                         tag = tag,
                         tyCon = tyCon}
                  )
              end
            | VARID {namePath, ty} =>
              let
                  val (ty) = 
                      updateStrpathInTy  ty strPathPair
              in
                  (
                   VARID {namePath = (#1 namePath, updateStrpath (#2 namePath) strPathPair), 
                          ty = ty
                         }
                  )
              end
            | RECFUNID ({namePath, ty}, int) =>
              let
                  val (ty) = 
                      updateStrpathInTy  ty strPathPair
              in
                  (
                   RECFUNID ({namePath = (#1 namePath, updateStrpath (#2 namePath) strPathPair), 
                              ty = ty
                             },
                             int)
                  )
              end
            | PRIM _ => ( idstate)
            | OPRIM _ => ( idstate)
                         
      and updateStrpathInDatacon  dataCon strPathPair = 
          SEnv.foldli (fn (label, idstate, ( dataCon)) =>
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
          NPEnv.map (fn idstate =>
                        let
                            val newIdstate = updateStrpathInIdstate idstate strPathPair
                        in newIdstate end)
                    varEnv

      fun updateStrpathInTyConEnv tyConEnv strPathPair =
          NPEnv.map (fn tyBindInfo =>
                        let
                            val newTyBindInfo = updateStrpathInTyBindInfo tyBindInfo strPathPair
                        in newTyBindInfo end)
                    tyConEnv
                    
      fun updateStrpathInEnv (tyConEnv, varEnv) strPathPair =
          (updateStrpathInTyConEnv tyConEnv strPathPair,
           updateStrpathInVarEnv varEnv strPathPair)


      (*********************************************************************************************)
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
              TYCON {tyCon, datacon} =>
              TYCON {tyCon = addStrpathInTyCon updateCandidateSet strPathPrefix tyCon,
                     datacon = addStrpathInDatacon updateCandidateSet strPathPrefix datacon}
            | TYFUN tyfun => 
              TYFUN (addStrpathInTyfun updateCandidateSet strPathPrefix tyfun)
            | TYOPAQUE ({spec = tyspec as {name, id, eqKind, tyvars, strpath, abstract, constructorHasArgFlagList},
                         impl}) =>
              TYOPAQUE ({spec = {name = name, 
                                 id = id, 
                                 eqKind = eqKind, 
                                 tyvars = tyvars, 
                                 strpath = Path.joinPath(strPathPrefix, strpath), 
                                 abstract = abstract,
                                 constructorHasArgFlagList = constructorHasArgFlagList},
                         impl = impl})
            | TYSPEC {name, id, eqKind, tyvars, strpath, abstract, constructorHasArgFlagList} =>
              TYSPEC {name = name, 
                      id = id, 
                      eqKind = eqKind, 
                      tyvars = tyvars, 
                      strpath = Path.joinPath(strPathPrefix, strpath), 
                      abstract = abstract,
                      constructorHasArgFlagList = constructorHasArgFlagList}
              
      and addStrpathInTyfun updateCandidateSet
                            (strPathPrefix:Path.path) 
                            ({name, strpath, tyargs, body}:tyFun)  =
          let
              val newTyargs = IEnv.map (addStrpathInBtvKind updateCandidateSet strPathPrefix) tyargs
              val newBody = addStrpathInTy updateCandidateSet strPathPrefix body 
          in
              {name = name,
               strpath = Path.joinPath (strPathPrefix, strpath),
               tyargs = newTyargs,
               body = newBody}:tyFun
          end
          
      and addStrpathInBtvKind updateCandidateSet strPath {index, recordKind, eqKind}  =
          let
              val recordKind =
                  case recordKind of 
                      UNIV => UNIV
                    | REC tySEnvMap => 
                      REC (SEnv.map (addStrpathInTy updateCandidateSet strPath) tySEnvMap)
                    | OVERLOADED tys =>
                      OVERLOADED (map (addStrpathInTy updateCandidateSet strPath) tys)
          in
              {
               index=index, 
               recordKind = recordKind,
               eqKind = eqKind
              }
          end
          
      and addStrpathInTyList updateCandidateSet strPath tyList  =           
          map (addStrpathInTy updateCandidateSet strPath) tyList
          
      and addStrpathInTy updateCandidateSet strPath ty  = 
          case ty of
              TYVARty (tvar as ref (TVAR tvKind)) => 
              let
                  val tvKind = addStrpathInTvKind updateCandidateSet strPath tvKind 
                  val _  = tvar := TVAR tvKind
              in
                  ty
              end
            | TYVARty(ref(SUBSTITUTED realTy)) => 
              addStrpathInTy updateCandidateSet strPath realTy 
            | RAWty {tyCon, args} => 
              let
                  val newTyCon = addStrpathInTyCon updateCandidateSet strPath tyCon
                  val newArgs = addStrpathInTyList updateCandidateSet strPath args 
              in
                  (RAWty {tyCon= newTyCon, args = newArgs})
              end
            | OPAQUEty {spec = {tyCon, args}, implTy} =>
              let
                  val newTyCon = addStrpathInTyCon updateCandidateSet strPath tyCon
                  val newArgs = addStrpathInTyList updateCandidateSet strPath args 
              in
                  OPAQUEty {spec = {tyCon = newTyCon, args = newArgs}, implTy = implTy}
              end
            | ALIASty (printTy, actualTy) =>
              let
                  val newPrintTy = 
                      addStrpathInTy updateCandidateSet strPath printTy
              in
                  ALIASty (newPrintTy, actualTy)
              end
            | POLYty {boundtvars, body} => 
              let
                  val boundtvars = 
                      IEnv.map (addStrpathInBtvKind updateCandidateSet strPath)
                               boundtvars
                  val newBody = addStrpathInTy updateCandidateSet strPath body 
              in
                  POLYty{boundtvars = boundtvars, body = newBody}
              end
            | FUNMty(domainTyList, rangeTy) =>
              let
                  val newDomainTyList =
                      addStrpathInTyList updateCandidateSet strPath domainTyList 
                  val newRangeTy =
                      addStrpathInTy updateCandidateSet strPath rangeTy 
              in
                  FUNMty(newDomainTyList, newRangeTy)
              end
            | RECORDty tyFields => 
              RECORDty (SEnv.map (addStrpathInTy updateCandidateSet strPath) tyFields)
            | SPECty {tyCon, args} =>
              let
                  val newTyCon = addStrpathInTyCon updateCandidateSet strPath tyCon
                  val newArgs = addStrpathInTyList updateCandidateSet strPath args 
              in
                  SPECty {tyCon = newTyCon, args = newArgs}
              end
            | BOUNDVARty _ => ty
            | DUMMYty _ => ty
            | ERRORty  => ty
                          
      and addStrpathInTvKind updateCandidateSet strPath {lambdaDepth, id, recordKind, eqKind, tyvarName}  = 
          let
              val recordKind = 
                  case recordKind of 
                      UNIV => UNIV
                    | REC tySEnvMap => 
                      REC (SEnv.map (addStrpathInTy updateCandidateSet strPath) tySEnvMap)
                    | OVERLOADED tys =>
                      OVERLOADED (map (addStrpathInTy updateCandidateSet strPath) tys)
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
              (tyCon:tyCon as {name, strpath, abstract, tyvars, id, eqKind, constructorHasArgFlagList}) 
          
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
              CONID {namePath, funtyCon, ty, tag, tyCon} =>
              CONID{namePath = (#1 namePath, Path.joinPath(strPath, #2 namePath)), 
                    funtyCon = funtyCon, 
                    ty = addStrpathInTy updateCandidateSet strPath ty,
                    tag = tag,
                    tyCon = addStrpathInTyCon updateCandidateSet strPath tyCon}
            | EXNID {namePath, funtyCon, ty, tag, tyCon} =>
              EXNID{namePath = (#1 namePath, Path.joinPath(strPath, #2 namePath)), 
                    funtyCon = funtyCon, 
                    ty = addStrpathInTy updateCandidateSet strPath ty,
                    tag = tag,
                    tyCon = addStrpathInTyCon updateCandidateSet strPath tyCon}
            | VARID {namePath, ty} =>
              VARID {namePath = (#1 namePath, Path.joinPath (strPath, #2 namePath)), 
                     ty = addStrpathInTy updateCandidateSet strPath ty}
            | RECFUNID ({namePath, ty}, int) =>
              RECFUNID ({namePath = (#1 namePath, Path.joinPath (strPath, #2 namePath) ), 
                         ty = addStrpathInTy updateCandidateSet strPath ty},
                        int)
            | PRIM _ => idstate
            | OPRIM _ => idstate
                         
      and addStrpathInDatacon updateCandidateSet strPath dataCon = 
          SEnv.map (fn (CONID {namePath, funtyCon, ty, tag, tyCon}) =>
                       CONID{(*Inside dataCon, constructors use short name *)
                             namePath = namePath, 
                             funtyCon = funtyCon, 
                             ty = addStrpathInTy updateCandidateSet strPath ty,
                             tag = tag,
                             tyCon = tyCon}
                     | _ => raise Control.Bug "non CONID in dataCon(addStrpathInDatacon)")
                   dataCon 

      fun addStrpathInVarEnv updateCandidateSet strPath varEnv =
          NPEnv.foldli (fn (varNamePath, idstate, newVarEnv) =>
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
          NPEnv.foldli (fn (tyNamePath, tyBindInfo, newTyEnv) =>
                           NPEnv.insert(newTyEnv,
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
                              TYSPEC ({id, ...}) =>
                              TyConID.Set.add(updateCandidateSet, id)
                            | TYOPAQUE ({spec = {id, ...}, ...}) =>
                              TyConID.Set.add(updateCandidateSet, id)
                            | TYCON {tyCon = {id,...}, ...} =>
                              TyConID.Set.add(updateCandidateSet, id)
                            | TYFUN {body = ALIASty(RAWty {tyCon = {id,...},...}, _),...} => 
                              TyConID.Set.add(updateCandidateSet, id)
                            | TYFUN _  => raise Control.Bug "illegal tyfun format(addStrpathInEnv)")
                      TyConID.Set.empty
                      tyConEnv
              val updateCandidateSet = updateCandidateInTyConEnv tyConEnv
              val newTyConEnv = addStrpathInTyConEnv updateCandidateSet strPath tyConEnv 
              val newVarEnv = addStrpathInVarEnv updateCandidateSet strPath varEnv
          in
              (newTyConEnv, newVarEnv)
          end

      fun makeExnConPath namePath tyOpt =
          let
              val (ty, funtyCon) =
                  case tyOpt
                   of SOME argty => (Types.FUNMty([argty], PredefinedTypes.exnty), true)
                    | _ => (PredefinedTypes.exnty, false)
          in
              {
               namePath = namePath,
               funtyCon = funtyCon,
               ty = ty,
               tyCon = PredefinedTypes.exnTyCon,
               tag = ExnTagIDKeyGen.generate ()
              }
          end

      (*******************************************************************************************)
(*
      fun restoreExnTagExternalNameVarEnv (topVarEnv : Types.topVarEnv) =
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

      (******************************************************************************************)
      fun exnTagSetVarEnv varEnv =
          NPEnv.foldl
              (fn (Types.EXNID {tag, ...}, exnTagSet) =>
                  ExnTagID.Set.add(exnTagSet, tag)
                | (_, exnTagSet) => exnTagSet
              )
              ExnTagID.Set.empty
              varEnv

      fun exnTagSetEnv (tyConEnv, varEnv) =
          exnTagSetVarEnv varEnv
  end
end
