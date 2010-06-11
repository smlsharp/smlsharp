(**
 * signature check utility for module.
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: SigUtils.sml,v 1.17 2008/08/06 12:59:09 ohori Exp $
 *)
structure SigUtils =
struct 
local
  structure TC = TypeContext
  structure TIC = TypeInferenceContext
  structure TU = TypesUtils
  structure TCU = TypeContextUtils
  structure E = TypeInferenceError
  structure PT = PredefinedTypes
  structure T = Types
  structure P = Path
  structure PT = PredefinedTypes
  structure NPEnv = NameMap.NPEnv
  fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")

  structure strPathOrd:ORD_KEY =
  struct 
  type ord_key = TyConID.id * Path.path
  fun compare ((id1,p1),(id2,p2)) = 
      case TyConID.compare(id1,id2) of
        EQUAL => NameMap.comparePathByName (p1,p2)
      | other => other 
  end

in
  structure strPathEnv = BinaryMapMaker(strPathOrd)

  fun longTyConIdEqKind basis longTyCon = 
      case TIC.lookupTyConInBasis (basis, longTyCon) of
        NONE =>
        raise
          E.TyConNotFoundInShare
            ({tyCon = NameMap.namePathToString(longTyCon)})
      | SOME(T.TYCON {tyCon = {id, eqKind, ...}, ...}) => (id, !eqKind)
      | SOME(T.TYOPAQUE({spec = {id, eqKind, ...}, ...})) => (id, !eqKind)
      | SOME(T.TYSPEC({id, eqKind, ...})) => (id, !eqKind)
      | SOME(T.TYFUN({name,...})) =>
        raise (E.SharingOnTypeFun {tyConName = name})

  fun extendTyConIdSubst (newSubst, oldSubst) =
      let
        val revisedOldSubst =
            TyConID.Map.map (TCU.substTyConIdInId newSubst) oldSubst
      in
        TyConID.Map.unionWith
          (fn x => raise Control.Bug "sigutils.extendTyConIdSubst:Duplicate")
          (newSubst, revisedOldSubst)
      end


  fun equateTyConIdEqInContext
        tyConIdEqSubst
        ({tyConEnv, varEnv, sigEnv, funEnv}:TC.context) =
      {
       tyConEnv = TCU.substTyConIdEqInTyConEnv tyConIdEqSubst tyConEnv,
       varEnv = TCU.substTyConIdEqInVarEnv tyConIdEqSubst varEnv,
       sigEnv = sigEnv,
       funEnv = funEnv
      } : TC.context

 (****************************************************************************)
  fun instVarEnvWithExnAndIdState (enrichedVE:T.varEnv, absVE:T.varEnv) =
      NPEnv.mapi
        (fn (varNamePath, idstate) =>
            case idstate of
              T.VARID{namePath, ty = absTy} =>
              (case NPEnv.find(enrichedVE, varNamePath) of
                 SOME (T.CONID{namePath, funtyCon, ty, tag, tyCon}) =>
                 T.CONID{namePath = namePath, 
                         funtyCon = funtyCon,
                         ty = absTy,  
                         tag = tag, 
                         tyCon = tyCon}
               | SOME (T.EXNID{namePath, funtyCon, ty, tag, tyCon}) =>
                 T.EXNID{namePath = namePath, 
                         funtyCon = funtyCon,
                         ty = absTy,  
                         tag = tag, 
                         tyCon = tyCon}
               | _ => idstate
              )
            | T.CONID {namePath, funtyCon, ty, tag, tyCon = {id,...}} =>
              (case NPEnv.find(enrichedVE, varNamePath) of
                 SOME  (T.CONID {tag, tyCon,...}) => 
                 T.CONID(
                 { 
                  namePath = namePath,
                  funtyCon = funtyCon,
                  ty = ty,
                  tag = tag,
                  tyCon = tyCon
                 }
                 )
               | _ => idstate
              )
            | T.EXNID {namePath, funtyCon, ty, tag, tyCon = {id,...}} =>
              (case NPEnv.find(enrichedVE, varNamePath) of
                 SOME (T.EXNID {tag, tyCon,...}) => 
                 T.EXNID(
                 { 
                  namePath = namePath,
                  funtyCon = funtyCon,
                  ty = ty,
                  tag = tag,
                  tyCon = tyCon
                 }
                 )
               | _ => idstate
              )
            | _ => idstate
        )
        absVE

  (* instantiate the followings:
   * 1. Exception tag.
   * 2. FFID actual argument list.
   *)
  fun instEnvWithExnAndIdState ((_, enrichedVE), (absTE, absVE)) =
      let
        val newAbsVE = instVarEnvWithExnAndIdState(enrichedVE, absVE)
      in
        (absTE, newAbsVE)
      end
 (***************************************************************************)        
 (* 
  * functor F(S: sig exception exn end) = 
  * struct  exception exnNew = S.exn end
  * accumulate the exception tag substitution for functor application
  *)
  fun computeExnTagSubstVarEnv (argVarEnv, actVarEnv) = 
      NPEnv.foldli (
      fn (varId, idstate, subst) =>
         case idstate of
           T.EXNID {tag = oldTag, tyCon,...} =>
           if TyConID.eq(#id tyCon, #id PT.exnTyCon) then
             case NPEnv.find(actVarEnv,varId) of
               NONE => subst (* error captured by sigmatch *)
             | SOME (T.EXNID {tag = argTag,...}) =>
               ExnTagID.Map.insert(subst, oldTag, argTag)
             | _ => subst  (* error captured by sigmatch *)
           else subst
         | _ => subst
      )
                   ExnTagID.Map.empty
                   argVarEnv

  fun computeExnTagSubst (argEnv as (_, argVE), actEnv as (_, actVE)) =
      computeExnTagSubstVarEnv (argVE,actVE)

 (****************************************************************************)
  fun instExnTagBySubstOnVarEnv subst (varEnv:T.varEnv) =
      NPEnv.map
        ( fn idstate:T.idState =>
             case idstate of
               T.EXNID {tag,namePath,funtyCon,ty, tyCon} =>
               (case ExnTagID.Map.find(subst, tag) of
                  NONE => (idstate : T.idState)
                | SOME argTag =>
                  T.EXNID
                    {
                     namePath = namePath,
                     funtyCon = funtyCon,
                     ty = ty,
                     tag = argTag,
                     tyCon = tyCon
                    }
               )
             | _ => idstate
        )
        varEnv

 (* 
  *instantiate tag field of exception with actual one for exception replication
  *)
  fun instExnTagBySubstOnEnv subst (Env as (tyConEnv,varEnv)) =
      let
        val varEnv = instExnTagBySubstOnVarEnv subst varEnv
      in
        (tyConEnv,varEnv)
      end

(** update BoxedKind & strpath field & abstract tyspec for opaque signature **)
  fun instSPECty strPathSubst tyConSubst {tyCon, args} =
      let
        val newTyCon = instSigTyConStrPath strPathSubst tyCon
        val args = map (instSigTy strPathSubst tyConSubst) args
        val newTy = 
            case TyConID.Map.find(tyConSubst, #id tyCon) of
              NONE => T.SPECty {tyCon = newTyCon, args = args}
            | SOME tyBindInfo => 
              case (TU.peelTyOPAQUE tyBindInfo) of
                T.TYFUN tyFun => 
                T.OPAQUEty {spec = {tyCon = newTyCon, args = args},
                            implTy = TU.betaReduceTy (tyFun,args)}
              | T.TYCON dataTyInfo => 
                T.OPAQUEty{spec = {tyCon = newTyCon, args = args},
                           implTy = T.RAWty {tyCon = #tyCon dataTyInfo,
                                             args = args}}
              | T.TYSPEC tyCon => 
                T.OPAQUEty{spec = {tyCon = newTyCon, args = args},
                           implTy = T.RAWty {tyCon = tyCon, args = args}}
              | T.TYOPAQUE _ =>
                raise
                  Control.Bug
                    "TYOPAQUEty occurs after peelTyOPAQUE"
      in
        newTy
      end

  and instOPAQUEty strPathSubst tyConSubst ty =
      case ty of
        T.OPAQUEty {spec = {tyCon, args}, implTy} =>
        let
          val newTyCon =
              instSigTyConStrPath strPathSubst tyCon
          val newArgs =
              instSigTyList strPathSubst tyConSubst args
          val newImplTy =
              instSigTy strPathSubst tyConSubst implTy
        in
          T.OPAQUEty{spec = {tyCon = newTyCon, args = newArgs},
                     implTy = newImplTy}
        end
      | _ =>
        raise
          Control.Bug
            "non ABSSPECty to instABSSPECty (typeinference/main/sigutils.sml)"
                       
  and instSigTyList strPathSubst tyConSubst tyList =           
      map (instSigTy strPathSubst tyConSubst) tyList
              
  and instSigTy strPathSubst tyConSubst ty =
      TypeTransducer.mapTyPreOrder
        (fn ty =>
            case ty of
              T.TYVARty (tvar as ref (T.TVAR tvKind)) => 
              let
                val tvKind =
                    instSigTvKind strPathSubst tyConSubst tvKind
                val _  = tvar := T.TVAR tvKind
              in (ty, true) end
            | T.RAWty {tyCon, args} => 
              (T.RAWty {tyCon = instSigTyConStrPath strPathSubst tyCon,
                        args = args}, 
               true) 
            | T.OPAQUEty {spec = {tyCon, args}, implTy} =>
              (T.OPAQUEty
                 {
                  spec = {tyCon = instSigTyConStrPath strPathSubst tyCon,
                          args = args},
                  implTy = implTy},
               true)
            | T.SPECty spec =>
              (instSPECty strPathSubst tyConSubst spec, false)
            | T.POLYty {boundtvars, body} => 
              let
                val boundtvars = 
                    IEnv.foldli
                      (fn (index, btvKind, boundtvars) =>
                          let
                            val btvKind =
                                instSigBtvKind strPathSubst tyConSubst btvKind
                          in
                            IEnv.insert(boundtvars, index, btvKind)
                          end)
                      IEnv.empty
                      boundtvars
              in
                (T.POLYty{boundtvars = boundtvars, body = body}, true)
              end
            | _ => (ty, true))
        ty
            
  and instSigTvKind
        strPathSubst
        tyConSubst
        {lambdaDepth, id, recordKind, eqKind, tyvarName} = 
      let
        val recordKind =
            case recordKind of 
              T.UNIV => T.UNIV
            | T.REC tySEnvMap => 
              T.REC (SEnv.map (instSigTy strPathSubst tyConSubst) tySEnvMap)
            | T.OVERLOADED tys => 
              T.OVERLOADED (map (instSigTy strPathSubst tyConSubst) tys)
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
        
  and instSigBtvKind strPathSubst tyConSubst {index, recordKind, eqKind} = 
      let
        val recordKind =
            case recordKind of 
              T.UNIV => T.UNIV
            | T.REC tySEnvMap => 
              T.REC (SEnv.map (instSigTy strPathSubst tyConSubst) tySEnvMap)
            | T.OVERLOADED tys => 
              T.OVERLOADED (map (instSigTy strPathSubst tyConSubst) tys)
      in
        (
         {
          index=index, 
          recordKind = recordKind,
          eqKind = eqKind
         }
        )
      end
        
  and instSigTyFun strPathSubst tyConSubst {name,strpath,tyargs,body} =
      let
        val tyargs = IEnv.map (instSigBtvKind strPathSubst tyConSubst) tyargs
        val body = instSigTy strPathSubst tyConSubst body
      in
        {
         name = name, 
         strpath = strpath,
         tyargs = tyargs, 
         body = body
        }
      end
        
  and instSigTyConStrPath
        strPathSubst
        (tyCon
           as
           {name,
            strpath,
            abstract,
            tyvars,
            id,
            eqKind,
            constructorHasArgFlagList}) =
      let 
        val strpath = 
            case strPathEnv.find(strPathSubst,(id,strpath)) of
              NONE => strpath
            | SOME x => x
      in
        {
         name = name, 
         strpath =  strpath, 
         abstract = abstract,
         tyvars = tyvars,
         id = id,
         eqKind = eqKind,
         constructorHasArgFlagList = constructorHasArgFlagList
        }
      end

  and instSigIdstate strPathSubst tyConSubst idstate =
      case idstate of
        T.CONID {namePath, funtyCon, ty, tag, tyCon} =>
        let
          val ty = instSigTy strPathSubst tyConSubst ty
          val tyCon = instSigTyConStrPath strPathSubst tyCon
        in
          T.CONID
            {
             namePath = namePath, 
             funtyCon=funtyCon, 
             ty = ty,
             tag = tag,
             tyCon = tyCon
            }
        end
      | T.EXNID {namePath, funtyCon, ty, tag, tyCon} =>
        let
          val ty = instSigTy strPathSubst tyConSubst ty
          val tyCon = instSigTyConStrPath strPathSubst tyCon
        in
          T.EXNID
            {
             namePath = namePath, 
             funtyCon=funtyCon, 
             ty = ty,
             tag = tag,
             tyCon = tyCon
            }
        end
      | T.VARID {namePath, ty} =>
        T.VARID{namePath = namePath, ty = instSigTy strPathSubst tyConSubst ty}
      | T.RECFUNID ({namePath, ty}, int) => 
        T.RECFUNID
          ({namePath = namePath, ty = instSigTy strPathSubst tyConSubst ty},
           int)
      | T.PRIM x => T.PRIM x
      | T.OPRIM x => T.OPRIM x
                         
  and instSigVarEnv  strPathSubst tyConSubst varEnv = 
      NPEnv.map (instSigIdstate strPathSubst tyConSubst) varEnv
            
  and instSigDataCon  strPathSubst tyConSubst dataCon = 
      SEnv.map (instSigIdstate strPathSubst tyConSubst) dataCon
            
  and instSigTyConEnv strPathSubst tyConSubst tyConEnv =
      NPEnv.map (instSigTyBindInfo strPathSubst tyConSubst) tyConEnv
        
  and instSigTyBindInfo strPathSubst tyConSubst tyBindInfo =
      case tyBindInfo of
        T.TYCON {tyCon, datacon} => 
        T.TYCON {tyCon = instSigTyConStrPath strPathSubst tyCon,
                 datacon = instSigDataCon strPathSubst tyConSubst datacon}
      | T.TYFUN tyFun => T.TYFUN (instSigTyFun strPathSubst tyConSubst tyFun)
      | T.TYOPAQUE {spec = tyCon, impl} => 
        T.TYOPAQUE {spec = instSigTyConStrPath strPathSubst tyCon,
                    impl = instSigTyBindInfo strPathSubst tyConSubst impl}
      | T.TYSPEC (tyCon as {id,...}) => 
        (case TyConID.Map.find (tyConSubst, id) of
           NONE => tyBindInfo
         | SOME implTyBindInfo =>
           T.TYOPAQUE {spec = tyCon, impl = implTyBindInfo})
            
  and instSigEnv strPathSubst tyConSubst (tyConEnv1,varEnv1) =
      let
        val tyConEnv1 = 
            instSigTyConEnv strPathSubst tyConSubst tyConEnv1
        val varEnv1 =
            instSigVarEnv strPathSubst tyConSubst varEnv1
      in
        (tyConEnv1,varEnv1)
      end
        
  and dataTyInfoToAbsTyCon  {tyCon, datacon} : Types.dataTyInfo =
      let
        val newTyCon =
            {
             name = #name tyCon,
             strpath = #strpath tyCon,
             abstract = true,
             tyvars = #tyvars tyCon,
             id = #id tyCon,
             eqKind = #eqKind tyCon,
             constructorHasArgFlagList = #constructorHasArgFlagList tyCon
            }
        val tyConSubst = 
            TyConID.Map.singleton
              (#id tyCon, 
               T.TYCON {tyCon = newTyCon, datacon = datacon})
        val newDatacon = TCU.substTyConInDataConFully tyConSubst datacon
      in
        {tyCon = newTyCon, datacon = newDatacon}
      end
        
 (* 
  * tyConSubst : instantiate tyspec to abstract tycon
  *)
  and instTopSigEnv
        (Env as (tyConEnv2, varEnv2), sigEnv as (tyConEnv1, varEnv1)) = 
      let
        fun substOfTyConEnv tyConEnv1 tyConEnv2 = 
            NPEnv.foldli
              (fn (tyConNamePath,tyBindInfo1, (strPathSubst, tyConSubst)) =>
                  case tyBindInfo1 of
                    T.TYSPEC {id, strpath, ...} =>
                    (case NPEnv.find(tyConEnv2,tyConNamePath) of
                       NONE => 
                       (* error case captured by signature check *)
                         (strPathSubst, tyConSubst)
                     | SOME tyBindInfo => 
                       let
                         val strPathSubst =  
                             strPathEnv.insert
                               (strPathSubst,
                                (id,strpath),
                                TU.strPathOfTyBindInfo tyBindInfo)
                         val tyConSubst = 
                             case tyBindInfo of
                               T.TYCON dataTyInfo => 
                               TyConID.Map.insert
                                 (tyConSubst,
                                  id,
                                  T.TYCON(dataTyInfoToAbsTyCon dataTyInfo))
                             | _ =>
                               TyConID.Map.insert(tyConSubst, id, tyBindInfo) 
                       in
                         (strPathSubst, tyConSubst)
                       end)
                  | T.TYCON {tyCon = {id,strpath,...}, ...} =>
                    (case NPEnv.find(tyConEnv2,tyConNamePath) of
                       NONE => (* error case captured by signature check *)
                                 (strPathSubst, tyConSubst)
                     | SOME tyBindInfo => 
                       let
                         val strPathSubst = 
                             strPathEnv.insert
                               (strPathSubst,
                                (id,strpath),
                                TU.strPathOfTyBindInfo tyBindInfo)
                       in (strPathSubst,tyConSubst) end)
                  | T.TYFUN
                      {name,
                       strpath,
                       tyargs,
                       body = T.ALIASty(T.RAWty {tyCon = {id,...},...},ty)}
                    => 
                    (case NPEnv.find(tyConEnv2, tyConNamePath) of
                       NONE => (* error case captured by signature check *)
                                 (strPathSubst, tyConSubst)
                     | SOME tyBindInfo =>
                       let
                         val strPathSubst = 
                             strPathEnv.insert
                               (strPathSubst,
                                (id,strpath),
                                TU.strPathOfTyBindInfo tyBindInfo)
                       in (strPathSubst,tyConSubst) end)
                  | T.TYOPAQUE {spec = {strpath, id, ...}, impl} => 
                    (case NPEnv.find(tyConEnv2, tyConNamePath) of
                       NONE => (* error case captured by signature check *)
                                 (strPathSubst, tyConSubst)
                     | SOME tyBindInfo =>
                       let
                         val strPathSubst = 
                             strPathEnv.insert
                               (strPathSubst,
                                (id,strpath),
                                TU.strPathOfTyBindInfo tyBindInfo)
                       in (strPathSubst,tyConSubst) end)
                  | T.TYFUN _ => raise Control.Bug "illegal tyFun form"
              )
              (strPathEnv.empty, TyConID.Map.empty)
              tyConEnv1
        val (strPathSubst, tyConSubst) = substOfTyConEnv tyConEnv1 tyConEnv2
        val Env = instSigEnv strPathSubst tyConSubst (tyConEnv1, varEnv1)
      in
        Env
      end

  fun handleException (ex,loc) =
      case ex of
        exn as E.ArityMismatchInSigMatch _ =>
        E.enqueueError(loc, exn)
      | exn as E.EqErrorInSigMatch _ =>
        E.enqueueError(loc, exn)
      | exn as E.RedunantConstructorInSignatureInSigMatch _ =>
        E.enqueueError(loc, exn)
      | exn as E.RedunantConstructorInStructureInSigMatch _ =>
        E.enqueueError(loc, exn)
      | exn as E.TyConMisMatchInSigMatch _ =>
        E.enqueueError(loc, exn)
      | exn as E.SharingTypeMismatchInSigMatch _ =>
        E.enqueueError(loc, exn)
      | exn as E.InstanceCheckInSigMatch _ => 
        E.enqueueError(loc, exn)
      | exn as E.DataConRequiredInSigMatch _ =>
        E.enqueueError(loc, exn)
      | exn as E.DatatypeContainUnboundType _ =>
        E.enqueueError(loc, exn)
      | exn as E.unboundStructureInSigMatch _ =>
        E.enqueueError(loc, exn)
      | exn as E.unboundVarInSigMatch _ =>
        E.enqueueError(loc, exn)
      | exn as E.unboundTyconInSigMatch _ =>
        E.enqueueError(loc, exn)
      | x => raise x

  fun substTyEnvFromTyConEnv (sigTyConEnv, strTyConEnv) =
      NPEnv.foldli
        (
         fn (tyConNamePath,tyBind1,substTyEnv) =>
            case NPEnv.find(strTyConEnv, tyConNamePath) of 
              NONE => substTyEnv
            | SOME tyBind2 => 
              ( case tyBind1 of
                  T.TYSPEC{id,...} => 
                  TyConID.Map.insert(substTyEnv,id , tyBind2)
                  (*
                | T.TYCON {id,...} =>
                  TyConID.Map.insert(substTyEnv,id , tyBind2)
                   *)
                | _ => substTyEnv
              )
	)
        TyConID.Map.empty
        sigTyConEnv

  fun substTyEnvFromEnv ((sigTyConEnv, sigVarEnv), (strTyConEnv, strVarEnv) ) 
    = substTyEnvFromTyConEnv (sigTyConEnv,strTyConEnv)

end
end
