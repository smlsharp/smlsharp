(**
 * signature check utility for module.
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: sigutils.sml,v 1.60 2006/03/02 12:53:26 bochao Exp $
 *)
structure SigUtils =
struct 
local
  structure TC = TypeContext
  structure TIC = TypeInferenceContext
  structure TU = TypesUtils
  structure TCU = TypeContextUtils
  structure E = TypeInferenceError
  structure SE = StaticEnv
  structure T = Types
  structure P = Path
in
  fun longTyConId currentContext longTyCon = 
    case TIC.lookupLongTyCon (currentContext, longTyCon) of
      (_,NONE) => raise E.TyConNotFoundInShare ({tyCon = Absyn.longidToString(longTyCon)})
    | (_,SOME(T.TYCON(tyCon))) => TU.tyConId tyCon
    | (_,SOME(T.TYSPEC({spec = {id,...},impl}))) => id
    | (_,SOME(T.TYFUN({name,...}))) => raise (E.SharingOnTypeFun {tyConName = name})


  fun extendTyConIdSubst (newSubst, oldSubst) =
      let
        val revisedOldSubst = ID.Map.map (TCU.substTyConIdInId newSubst) oldSubst
      in
        ID.Map.unionWith (fn x => raise Control.Bug "sigutils.extendTyConIdSubst:Duplicate")
                       (newSubst, revisedOldSubst)
      end

  fun equateTyConIdInContext 
        tyConIdSubst {tyConEnv, varEnv, strEnv, sigEnv, funEnv}
    =
    {tyConEnv = #2 (TCU.substTyConIdInTyConEnv ID.Set.empty tyConIdSubst tyConEnv),
     varEnv = #2 (TCU.substTyConIdInVarEnv ID.Set.empty tyConIdSubst varEnv),
     strEnv = #2 (TCU.substTyConIdInStrEnv ID.Set.empty tyConIdSubst strEnv),
     sigEnv = sigEnv,
     funEnv = funEnv
     } : TC.context


  fun exnTagSetVarEnv fromExnTag varEnv =
      SEnv.foldl
        (
         fn (T.CONID {tag, tyCon,...}, exnTagSet) =>
            if SE.exnTyConid = #id tyCon andalso tag >= fromExnTag then
              ISet.add(exnTagSet, tag)
            else
              exnTagSet
          | (_, exnTagSet) => exnTagSet
        )
        ISet.empty
        varEnv

  fun exnTagSetStrEnv fromExnTag strEnv =
      SEnv.foldl
        (fn (T.STRUCTURE {env = (tyConEnv, varEnv, strEnv), ...}, exnTagSet) =>
            let
              val exnTagSet1 = exnTagSetVarEnv fromExnTag varEnv
              val exnTagSet2 = exnTagSetStrEnv fromExnTag strEnv
            in
              ISet.union ((ISet.union(exnTagSet1,exnTagSet2)),exnTagSet)
            end)
        ISet.empty
        strEnv

  fun exnTagSetEnv fromExnTag (tyConEnv, varEnv, strEnv) =
      let
        val exnTagSet1 = exnTagSetVarEnv fromExnTag varEnv
        val exnTagSet2 = exnTagSetStrEnv fromExnTag strEnv
      in
        ISet.union(exnTagSet1, exnTagSet2)
      end

  (**********************************************************************************)
  fun instVarEnvWithExnAndIdState (enrichedVE, absVE) =
      SEnv.mapi
        (fn (varName, idstate) =>
            case idstate of
              T.VARID{name, strpath = absStrpath, ty = absTy} =>
              (case SEnv.find(enrichedVE, varName) of
                 SOME (T.FFID{name,strpath,ty,argTys}) =>
                 T.FFID{name = name, strpath = absStrpath, ty = absTy, argTys = argTys}
               | SOME (T.CONID{name, strpath, funtyCon, ty, tag, tyCon}) =>
                 T.CONID{name = name, strpath =  absStrpath, funtyCon = funtyCon,
                       ty = absTy,  tag = tag, tyCon = tyCon}
               | _ => idstate
              )
            | T.CONID {name,strpath,funtyCon,ty,tag,tyCon = {id,...}} =>
              if id = SE.exnTyConid then
                (case SEnv.find(enrichedVE, varName) of
                   SOME  (T.CONID {tag,tyCon,...}) => 
                   T.CONID({ 
                            name = name,
                            strpath = strpath,
                            funtyCon = funtyCon,
                            ty = ty,
                            tag = tag,
                            tyCon = tyCon
                            }
                           )
                 | _ => idstate
                )
              else idstate
            | _ => idstate
       )
        absVE

  fun instStrEnvWithExnAndIdState (enrichedSE, absSE) =
      SEnv.mapi
        (fn (strName, str2 as T.STRUCTURE{env = (absSubTE, absSubVE, absSubSE),id,name,strpath})=> 
            (case SEnv.find(enrichedSE, strName) of
               SOME (T.STRUCTURE{env = (_, enrichedSubVE, enrichedSubSE), ...}) => 
               let
                 val newAbsSubVE = instVarEnvWithExnAndIdState (enrichedSubVE, absSubVE)
                 val newAbsSubSE = instStrEnvWithExnAndIdState (enrichedSubSE, absSubSE)
               in
                 T.STRUCTURE {
                              env = (absSubTE, newAbsSubVE, newAbsSubSE),
                              id = id,
                              name = name,
                              strpath = strpath
                              }
               end
             | NONE => str2
            )
        )
        absSE
 
  (* instantiate the followings:
   * 1. Exception tag.
   * 2. FFID actual argument list.
   *)
  fun instEnvWithExnAndIdState ((_, enrichedVE, enrichedSE), (absTE, absVE, absSE)) =
      let
        val newAbsVE = instVarEnvWithExnAndIdState(enrichedVE, absVE)
        val newAbsSE = instStrEnvWithExnAndIdState(enrichedSE, absSE)
      in
        (absTE, newAbsVE, newAbsSE)
      end
  (***************************************************************************************)        
  (* 
   * functor F(S: sig exception exn end) = 
   * struct  exception exnNew = S.exn end
   * accumulate the exception tag substitution for functor application
   *)
  fun computeExnTagSubstVarEnv (argVarEnv:T.idState SEnv.map, actVarEnv:T.idState SEnv.map) = 
      SEnv.foldli (
                   fn (varId, idstate, subst) =>
                      case idstate of
                        T.CONID {tag = oldTag,tyCon,...} =>
                        if (#id tyCon) = SE.exnTyConid then
                          case SEnv.find(actVarEnv,varId) of
                            NONE => subst (* error captured by sigmatch *)
                          | SOME (T.CONID {tag = argTag,...}) =>
                            IEnv.insert(subst, oldTag, argTag)
                          | _ => raise Control.Bug "computeExnTagSubstVarEnv:should be CONID"
                        else subst
                      | _ => subst
                  )
                  IEnv.empty
                  argVarEnv
  fun computeExnTagSubstStrEnv (argStrEnv, actStrEnv) =
      SEnv.foldli (
                   fn (strId, T.STRUCTURE{env = (_, argSubVarEnv, argSubStrEnv),...}, subst) =>
                      case SEnv.find(actStrEnv, strId) of
                        NONE => subst (* error captured by sigmatch *)
                      | SOME (T.STRUCTURE{env = (_, actSubVarEnv, actSubStrEnv),...}) =>
                        let
                          val subst1 = computeExnTagSubstVarEnv (argSubVarEnv,actSubVarEnv)
                          val subst2 = computeExnTagSubstStrEnv (argSubStrEnv,actSubStrEnv)
                        in
                          IEnv.unionWith #1 (subst,
                                             IEnv.unionWith #1 (subst2,subst1))
                        end
                   )
                  IEnv.empty
                  argStrEnv
  fun computeExnTagSubst (argEnv as (_, argVE, argSE), 
                          actEnv as (_, actVE, actSE)) =
      let
        val subst1 = computeExnTagSubstVarEnv (argVE,actVE)
        val subst2 = computeExnTagSubstStrEnv (argSE,actSE)
      in
        IEnv.unionWith #1 (subst2,subst1)
      end

  (************************************************************************************)
  fun instExnTagBySubstOnVarEnv subst (varEnv:T.idState SEnv.map) =
      SEnv.map ( fn idstate:T.idState =>
                    case idstate of
                      T.CONID {tag,name,strpath,funtyCon,ty,tyCon} =>
                      if (#id tyCon) = SE.exnTyConid then
                        case IEnv.find(subst, tag) of
                          NONE => (idstate : T.idState)
                        | SOME argTag =>
                          T.CONID {
                                 name = name,
                                 strpath = strpath,
                                 funtyCon = funtyCon,
                                 ty = ty,
                                 tag = argTag,
                                 tyCon = tyCon
                                 }
                      else idstate
                    | _ => idstate
                )
               varEnv

  fun instExnTagBySubstOnStrEnv subst strEnv =
      SEnv.map ( fn (T.STRUCTURE{ env = (subTyConEnv, subVarEnv, subStrEnv),id,name,strpath}) =>
                    let
                      val subVarEnv = instExnTagBySubstOnVarEnv subst subVarEnv
                      val subStrEnv = instExnTagBySubstOnStrEnv subst subStrEnv
                    in
                      T.STRUCTURE{
                                  env = (subTyConEnv, subVarEnv, subStrEnv),
                                  id = id,
                                  name = name,
                                  strpath = strpath}
                    end
               )
               strEnv
                          
  (* 
   * instantiate tag field of exception with actual one for exception replication
   *)
  fun instExnTagBySubstOnEnv subst (Env as (tyConEnv,varEnv,strEnv)) =
      let
        val varEnv = instExnTagBySubstOnVarEnv subst varEnv
        val strEnv = instExnTagBySubstOnStrEnv subst strEnv
      in
        (tyConEnv,varEnv,strEnv)
      end

  (*********** update BoxedKind & strpath field & abstract tyspec for opaque signature *********)
  local 
    structure strPathOrd:ordsig =
      struct 
           local 
             open Path
           in
             type ord_key = ID.id * path
             fun comparePath (p1,p2) = 
                 case (p1,p2) of
                   (NilPath,NilPath) => EQUAL
                 | (PStructure _ ,NilPath) => GREATER
                 | (NilPath,PStructure _ ) => LESS
                 | (PStructure(id1,name1,p1),PStructure(id2,name2,p2)) =>
                   case String.compare(name1,name2) of
                     EQUAL => comparePath (p1,p2)
                   | other => other
             fun compare ((id1,p1),(id2,p2)) = 
                 case ID.compare(id1,id2) of
                   EQUAL => comparePath (p1,p2)
                 | other => other 
           end
        end
  in
     structure strPathEnv = BinaryMapFn(strPathOrd)
     type strPathMap = P.path strPathEnv.map

     fun instSPECty visited boxedKindSubst strPathSubst tyConSubst ty =
         case ty of
           T.CONty {tyCon,args} =>
           let
             val (specTy, visited) =
                 instSigTy visited boxedKindSubst strPathSubst ID.Map.empty ty
             val newTy = 
                 case ID.Map.find(tyConSubst, #id tyCon) of
                   NONE => T.SPECty specTy
                 | SOME tyBindInfo => 
                   case (TU.peelTySpec tyBindInfo) of
                      T.TYFUN tyFun => 
                      T.ABSSPECty(specTy, TU.betaReduceTy (tyFun,args))
                    | T.TYCON tyCon => 
                      T.ABSSPECty(specTy, T.CONty {tyCon = tyCon, args = args})
                    | T.TYSPEC _ => 
                      raise Control.Bug "after peelTySpec there should be no TYSPEC"
           in
             (visited, newTy)
           end
         | _ => raise Control.Bug "SPECty ill-formed: SPECty(CONty _)"

     and instABSSPECty visited boxedKindSubst strPathSubst tyConSubst ty =
         case ty of
           T.ABSSPECty (specTy as T.CONty {tyCon, args}, implTy) =>
           let
             val tyBindInfo =
                 case ID.Map.find(tyConSubst, #id tyCon) of
                   NONE => NONE
                 | SOME tyBindInfo => SOME (TU.peelTySpec tyBindInfo)
             val (specTy', visited) = 
                 instSigTy visited boxedKindSubst strPathSubst ID.Map.empty specTy
           in
             case tyBindInfo of
               NONE => 
               let
                 val (implTy',visited) = 
                     let
                       val (newImplTy,visited) =
                           instSigTy visited boxedKindSubst strPathSubst tyConSubst implTy
                     in
                       (newImplTy, visited)
                     end
               in
                 (visited, T.ABSSPECty(specTy',implTy'))
               end
             | SOME (T.TYFUN tyFun) =>
               let
                 val implTy = TU.betaReduceTy (tyFun,args)
               in
                 (visited, T.ABSSPECty(specTy', implTy))
               end
             | SOME (T.TYCON tyCon) => 
               (visited, T.ABSSPECty(specTy', (T.CONty {tyCon = tyCon, args = args})))
             | SOME (T.TYSPEC _ ) => 
               raise Control.Bug "after peelTySpec there should be no TYSPEC"
           end          
         | _ => raise Control.Bug "ill-formed ABSSPECty"
           
     and instSigTy visited boxedKindSubst strPathSubst tyConSubst ty =
         TypeTransducer.transTyPreOrder
           (fn (ty, visited) =>
               case ty of
                 T.TYVARty (tvar as ref (T.TVAR tvKind)) => 
                 let
                   val (visited, tvKind) =
                       instSigTvKind visited boxedKindSubst strPathSubst tyConSubst tvKind
                   val _  = tvar := T.TVAR tvKind
                 in
                   (ty, visited, true)
                 end
               | T.CONty {tyCon, args} => 
                 let
                   val (visited, tyCon) =
                       instSigTyCon visited boxedKindSubst strPathSubst tyConSubst tyCon
                 in 
                   (T.CONty {tyCon=tyCon, args = args}, visited, true)
                 end
               | T.ABSSPECty (specTy, actTy) =>
                 let
                   val (visited,newTy) = 
                       instABSSPECty
                         visited boxedKindSubst strPathSubst tyConSubst ty
                 in
                   (newTy, visited, false)
                 end
               | T.SPECty ty =>
                 let
                   val (vsisited, newTy) =
                       instSPECty
                         visited boxedKindSubst strPathSubst tyConSubst ty
                 in
                   (newTy, visited, false)
                 end
               | T.POLYty {boundtvars, body} => 
                 let
                   val (visited, boundtvars) = 
                       IEnv.foldli
                         (fn (index, btvKind, (visited, boundtvars)) =>
                             let
                               val (visited, btvKind) =
                                   instSigBtvKind
                                     visited boxedKindSubst strPathSubst tyConSubst btvKind
                             in
                               (visited, IEnv.insert(boundtvars, index, btvKind))
                             end)
                         (visited, IEnv.empty)
                         boundtvars
                 in
                   (T.POLYty{boundtvars = boundtvars, body = body}, visited, true)
                 end
               | _ => (ty, visited, true))
           visited
           ty
           
     and instSigTvKind visited boxedKindSubst strPathSubst tyConSubst {id, recKind, eqKind, tyvarName} = 
         let
           val (visited, recKind) =
               case recKind of 
                 T.UNIV => (visited, T.UNIV)
               | T.REC tySEnvMap => 
                 let
                   val (visited,tySEnvMap) = 
                       (SEnv.foldli
                          (fn (label, ty, (visited, tySEnvMap)) =>
                              let
                                val (ty, visited) = 
                                    instSigTy visited boxedKindSubst strPathSubst tyConSubst ty
                              in
                                (visited, SEnv.insert(tySEnvMap, label, ty))
                              end)
                          (visited, SEnv.empty)
                          tySEnvMap)
                 in 
                   (visited, T.REC tySEnvMap)
                 end
               | T.OVERLOADED tys => 
                 let
                   val (visited,tys) = 
                       (foldr
                          (fn (ty, (visited, tys)) =>
                              let
                                val (ty, visited) = 
                                    instSigTy visited boxedKindSubst strPathSubst tyConSubst ty
                              in
                                (visited, ty :: tys)
                              end)
                          (visited, nil)
                          tys
                          )
                 in 
                   (visited, T.OVERLOADED tys)
                 end
         in
           (
            visited,
            {id=id, 
             recKind = recKind,
             eqKind = eqKind,
             tyvarName = tyvarName}
            )
         end
           
     and instSigBtvKind visited boxedKindSubst strPathSubst tyConSubst {index, recKind, eqKind} = 
         let
           val (visited, recKind) =
               case recKind of 
                 T.UNIV => (visited, T.UNIV)
               | T.REC tySEnvMap => 
                 let
                   val (visited,tySEnvMap) = 
                       (SEnv.foldli
                          (fn (label, ty, (visited, tySEnvMap)) =>
                              let
                                val (ty, visited) = 
                                    instSigTy visited boxedKindSubst strPathSubst tyConSubst ty
                              in
                                (visited, SEnv.insert(tySEnvMap, label, ty))
                              end)
                          (visited, SEnv.empty)
                          tySEnvMap)
                 in
                   (visited, T.REC tySEnvMap)
                 end
               | T.OVERLOADED tys => 
                 let
                   val (visited,tys) = 
                       (foldr
                          (fn (ty, (visited, tys)) =>
                              let
                                val (ty, visited) = 
                                    instSigTy visited boxedKindSubst strPathSubst tyConSubst ty
                              in
                                (visited, ty :: tys)
                              end)
                          (visited, nil)
                          tys)
                 in
                   (visited, T.OVERLOADED tys)
                 end
         in
           (
            visited,
            {
             index=index, 
             recKind = recKind,
             eqKind = eqKind
             }
            )
         end
           
     and instSigTyFun visited boxedKindSubst strPathSubst tyConSubst {name,tyargs,body} =
         let
           val (visited, tyargs) =
               IEnv.foldri
                 (fn (index, btvKind, (visited, tyargs)) =>
                     let
                       val (visited, btvKind) = 
                           instSigBtvKind visited boxedKindSubst strPathSubst tyConSubst btvKind
                     in
                       (visited, IEnv.insert(tyargs, index, btvKind))
                     end)
                 (visited, IEnv.empty)
                 tyargs
           val (body, visited) = 
               instSigTy visited boxedKindSubst strPathSubst tyConSubst body
         in
           (visited,
            {
             name = name, 
             tyargs = tyargs, 
             body = body
             }
            )
         end
           
     and instSigTyCon visited 
                      boxedKindSubst
                      strPathSubst
                      (tyConSubst :T.tyBindInfo ID.Map.map)
                      (tyCon as {name, strpath, abstract, tyvars, id, eqKind, boxedKind, datacon}) 
       =
       let
         val tyBindInfo = 
             case ID.Map.find(tyConSubst,id) of
               NONE => NONE
             | SOME (T.TYSPEC tyspec) => SOME (TU.peelTySpec (T.TYSPEC tyspec))
             | SOME tyBindInfo => SOME tyBindInfo
       in
         case  tyBindInfo of
           SOME (T.TYCON tyCon) => (visited, tyCon)
         | SOME (T.TYSPEC _) => 
           raise Control.Bug
                   "instSigTyCon:after peelTySpec there should be no TYSPEC"
         | SOME (T.TYFUN {body,...}) => 
           (
            case (TU.extractAliasTyImpl body) of
              T.CONty({tyCon,...}) => (visited, tyCon)
            | _ => 
              raise Control.Bug "instSigTyCon: instiantiate with non typeName tyfun"
           )
         | _ =>
           let 
             val _ = 
                 case ID.Map.find(boxedKindSubst,id) of
                   NONE => ()
                 | SOME bkvalue => boxedKind := bkvalue
             val strpath = 
                 case strPathEnv.find(strPathSubst,(id,strpath)) of
                   NONE => strpath
                 | SOME x => x
             val visited = 
                 if ID.Set.member(visited, id) then
                   visited
                 else
                   let 
                     val visited = ID.Set.add(visited,id)
                     val (visited, varEnv) = 
                         instSigVarEnv visited boxedKindSubst strPathSubst tyConSubst (!datacon)
                   in
                     (datacon := varEnv;
                      visited)
                   end
           in
             (visited,
              {
               name = name, 
               strpath = strpath,
               abstract = abstract,
               tyvars = tyvars,
               id = id,
               eqKind = eqKind,
               boxedKind = boxedKind,
               datacon = datacon
               }
              )
           end
       end
     and instSigIdstate visited boxedKindSubst strPathSubst tyConSubst idstate =
         case idstate of
           T.CONID {name, strpath, funtyCon, ty, tag, tyCon} =>
           let
             val (ty, visited) = 
                 instSigTy visited boxedKindSubst strPathSubst tyConSubst ty
             val (visited, tyCon) = 
                 instSigTyCon visited boxedKindSubst strPathSubst tyConSubst tyCon
           in
             (visited,
              T.CONID{
                      name=name, 
                      strpath=strpath, 
                      funtyCon=funtyCon, 
                      ty = ty,
                      tag = tag,
                      tyCon = tyCon
                      }
              )
           end
         | T.VARID {name,ty,strpath} =>
           let
             val (ty, visited) = 
                 instSigTy visited boxedKindSubst strPathSubst tyConSubst ty
           in
             (
              visited,
              T.VARID{name=name,
                      strpath=strpath,
                      ty=ty}
              )
           end
         | x => (visited, x)
                
     and instSigVarEnv  visited boxedKindSubst strPathSubst tyConSubst varEnv = 
         SEnv.foldli
           (fn (label, idstate, (visited, varEnv)) => 
               let
                 val (visited,idstate) = 
                     instSigIdstate visited boxedKindSubst strPathSubst tyConSubst idstate
               in
                 (visited,SEnv.insert(varEnv,label,idstate))
               end
                 )
           (visited, SEnv.empty)
           varEnv
           
     and instSigStrEnv 
           visited boxedKindSubst strPathSubstOfTyCon tyConSubst strEnv =
         SEnv.foldri
           (fn
            (label, T.STRUCTURE {id, name, strpath, env = Env, ...}, (visited, strEnv))
            =>
            let
              val (visited, Env) = 
                  instSigEnv
                    visited boxedKindSubst strPathSubstOfTyCon tyConSubst Env
              val strPathInfo = {id = id, name = name, strpath = strpath, env = Env}
            in
              (visited, SEnv.insert(strEnv, label, T.STRUCTURE strPathInfo))
            end
              )
           (visited, SEnv.empty)
           strEnv
           
     and instSigTyConEnv visited boxedKindSubst strPathSubst tyConSubst tyConEnv =
         let
           val (visited, tyConEnv) =
               SEnv.foldli
                 (fn (label, tyBindInfo, (visited, tyConEnv)) =>
                     let
                       val (visited, tyBindInfo) = 
                           instSigTyBindInfo visited boxedKindSubst strPathSubst tyConSubst tyBindInfo
                     in
                       (visited, SEnv.insert(tyConEnv, label, tyBindInfo))
                     end)
                 (visited, SEnv.empty)
                 tyConEnv
         in
           (visited, tyConEnv)
         end
           
     and instSigTyBindInfo
           visited boxedKindSubst strPathSubst tyConSubst tyBindInfo =
         case tyBindInfo of
           T.TYCON (tyCon as {name,...})  => 
           let
             val (visited, tyCon) = 
                 instSigTyCon visited boxedKindSubst strPathSubst tyConSubst tyCon
           in
             (visited, T.TYCON tyCon)
           end
         | T.TYFUN tyFun => 
           let
             val (visited, tyFun) = 
                 instSigTyFun visited boxedKindSubst strPathSubst tyConSubst tyFun
           in
             (visited, T.TYFUN tyFun)
           end
         | T.TYSPEC {spec = {name, id, strpath, eqKind, tyvars, boxedKind},impl} => 
           let
             val bk = 
                 case ID.Map.find(boxedKindSubst,id) of
                   NONE => boxedKind
                 | SOME x => x
             val strpath = 
                 case strPathEnv.find(strPathSubst,(id,strpath)) of
                   NONE => strpath
                 | SOME x => x
             val impl =
                 case ID.Map.find(tyConSubst,id) of 
                   SOME tyBindInfo => SOME tyBindInfo
                 | NONE => 
                   case impl of
                     NONE => NONE
                   | SOME impl => 
                     let
                       val (_,tyBindInfo) =  (instSigTyBindInfo ID.Set.empty
                                                                boxedKindSubst
                                                                strPathSubst
                                                                ID.Map.empty
                                                                impl)
                     in SOME tyBindInfo end
           in
             (visited, 
              T.TYSPEC {spec = {
                                name=name, 
                                id=id, 
                                strpath = strpath, 
                                eqKind = eqKind, 
                                tyvars = tyvars,
                                boxedKind = bk
                                },
                        impl = impl}
              )
           end
             
     and instSigEnv 
           visited 
           boxedKindSubst
           strPathSubstOfTyCon
           tyConSubst
           (tyConEnv1,varEnv1,strEnv1) =
           let
             val (visited,tyConEnv1) = 
                 instSigTyConEnv 
                   visited boxedKindSubst strPathSubstOfTyCon tyConSubst tyConEnv1
             val (visited,varEnv1) = 
                 instSigVarEnv
                   visited boxedKindSubst strPathSubstOfTyCon tyConSubst varEnv1
             val (visited,strEnv1) = 
                 instSigStrEnv 
                   visited boxedKindSubst strPathSubstOfTyCon tyConSubst strEnv1
           in
             (visited,(tyConEnv1,varEnv1,strEnv1))
           end
             
     and tySpecToAbsTyCon (tyspec,
                           {name, strpath, abstract, tyvars, id, eqKind,boxedKind, datacon}
                           )
         = 
         let
           val newTyCon =  {
                            name = name,
                            strpath = strpath,
                            abstract = true, 
                            tyvars = tyvars,
                            id = id,
                            eqKind = eqKind,
                            boxedKind = boxedKind,
                            datacon = ref SEnv.empty
                            }
           val tyConSubst = ID.Map.singleton(id, T.TYCON newTyCon)
           val (visited,newDatacon) = TCU.substTyConInVarEnv ID.Set.empty tyConSubst (!datacon)
           val _ = (#datacon newTyCon):= newDatacon
         in 
           newTyCon
         end
           
     (* 
      * instantiate strpath field of STRUCTURE
      *)
     and instStrpathOfStructureInEnv (Env as (TE,VE,SE), sigEnv as (sigTE,sigVE,sigSE)) = 
         let
           val newSigSE = instStrpathOfStructureInStrEnv (SE,sigSE)
         in
           (sigTE,sigVE,newSigSE)
         end
           
     and instStrpathOfStructureInStrEnv (strEnv, sigStrEnv) =
         SEnv.foldli (fn (strName,
                          (T.STRUCTURE { env = (subSigTE,subSigVE,subSigSE),
                                       id ,
                                       name,
                                       strpath}),
                          newStrEnv
                          )
                         =>
                         let
                           val (newSigStrPath,newSubSigSE) =
                               case SEnv.find(strEnv,strName) of
                                 (* error case captured by sigmatching*)
                                 NONE => (strpath,subSigSE)
                               | SOME (T.STRUCTURE {env = (_,_,subSE),strpath,...}) => 
                                 (
                                  strpath,
                                  instStrpathOfStructureInStrEnv (subSE,subSigSE)
                                  )
                         in
                           SEnv.insert(newStrEnv,
                                       strName,
                                       T.STRUCTURE {env = (subSigTE, subSigVE, newSubSigSE),
                                                  id = id,
                                                  strpath = newSigStrPath,
                                                  name = name})
                         end)
                     SEnv.empty
                     sigStrEnv
                     
     (* boxedKinsSubst : instantiate boxedKind field 
      * strPathSubst : insantiate strPath field of tyCon
      * tyConSubst : instantiate tyspec to abstract tycon
      *)
     and instTopSigEnv (Env, sigEnv) = 
         let
           val (tyConEnv1, varEnv1, strEnv1) = instStrpathOfStructureInEnv (Env, sigEnv)
           val (tyConEnv2, varEnv2, strEnv2) = Env
           fun substOfTyConEnv tyConEnv1 tyConEnv2 = 
               SEnv.foldli
                 (
                  fn (tyCon,tyBindInfo1,
                      (boxedKindSubst,strPathSubst,tyConSubst)
                      ) =>
                     case tyBindInfo1 of
                       T.TYSPEC ({spec = tyspec as {id,strpath,...},impl = NONE}) =>
                       (case SEnv.find(tyConEnv2,tyCon) of
                          NONE => 
                          (* error case captured by signature check *)
                          (boxedKindSubst, strPathSubst, tyConSubst)
                        | SOME tyBindInfo => 
                          let
                            val boxedKindOpt = TU.boxedKindOptOfTyBindInfo tyBindInfo
                            val strPathSubst =  
                                strPathEnv.insert(
                                                  strPathSubst, 
                                                  (id,strpath),
                                                  TU.strPathOptOfTyBindInfo tyBindInfo
                                                  )
                            (* the following tyConSubst is used to 
                             * fill in the impl field of tySpec 
                             *)
                            val tyConSubst = 
                                case tyBindInfo of
                                  T.TYCON tyCon => 
                                  ID.Map.insert(tyConSubst, 
                                                id, 
                                                T.TYCON (tySpecToAbsTyCon ({spec = tyspec,
                                                                            impl = NONE},
                                                                           tyCon))
                                                )
                                | T.TYFUN _ =>
                                  ID.Map.insert(tyConSubst, id, tyBindInfo)
                                | T.TYSPEC _ =>
                                  (* opaque constrained again *)
                                  ID.Map.insert(tyConSubst, id, tyBindInfo) 
                          in
                            (
                             ID.Map.insert(boxedKindSubst, id, boxedKindOpt),
                             strPathSubst,
                             tyConSubst
                             )
                          end
                            )
                     | T.TYCON {boxedKind = ref boxedKindValue,id,strpath,...} =>
                       (
                        case SEnv.find(tyConEnv2,tyCon) of
                          NONE => 
                          (* error case captured by signature check *)
                          (boxedKindSubst, strPathSubst, tyConSubst)
                        | SOME tyBindInfo => 
                          ( case boxedKindValue of
                              NONE =>
                              let
                                val boxedKindOpt = TU.boxedKindOptOfTyBindInfo tyBindInfo
                                val boxedKindSubst = 
                                    case boxedKindOpt of
                                      NONE => boxedKindSubst
                                    | SOME _ => 
                                      ID.Map.insert(boxedKindSubst, id, boxedKindOpt)
                                val strPathSubst =  
                                    strPathEnv.insert(strPathSubst, 
                                                      (id,strpath),
                                                      TU.strPathOptOfTyBindInfo tyBindInfo)
                              in
                                (
                                 boxedKindSubst,
                                 strPathSubst,
                                 tyConSubst
                                 )
                              end
                            | SOME _ =>
                              let
                                val strPathSubst = 
                                    strPathEnv.insert(strPathSubst, 
                                                      (id,strpath), 
                                                      TU.strPathOptOfTyBindInfo tyBindInfo)
                              in
                                (boxedKindSubst,strPathSubst,tyConSubst)
                              end
                                )
                          )
                     | T.TYFUN {name, 
                                tyargs, 
                                body = T.ALIASty(T.CONty {tyCon = {id,strpath,...},...},ty)
                                       } => 
                       (
                        case SEnv.find(tyConEnv2,tyCon) of
                          NONE => 
                          (* error case captured by signature check *)
                          (boxedKindSubst, strPathSubst, tyConSubst)
                        | SOME tyBindInfo =>
                          let
                            val strPathSubst = 
                                strPathEnv.insert(strPathSubst, 
                                                  (id,strpath),
                                                  TU.strPathOptOfTyBindInfo tyBindInfo
                                                  )
                          in
                            (boxedKindSubst,strPathSubst,tyConSubst)
                          end
                       )
                     | _ => (boxedKindSubst,strPathSubst,tyConSubst)
                            )
                 (ID.Map.empty, strPathEnv.empty, ID.Map.empty)
                 tyConEnv1

           fun substOfStrEnv strEnv1 strEnv2 = 
               SEnv.foldli (
                            fn (strName, T.STRUCTURE {env = (tyConEnv1,_,strEnv1),id,...},
                                (boxedKindSubst,strPathSubstOfTyCon,tyConSubst)) 
                               =>
                               case SEnv.find(strEnv2,strName) of
                                 NONE =>
                                 (boxedKindSubst, strPathSubstOfTyCon, tyConSubst)
                               | SOME (T.STRUCTURE {env = (tyConEnv2,_,strEnv2),strpath,...}) =>
                                 let
                                   val subst1 = substOfTyConEnv tyConEnv1 tyConEnv2
                                   val subst2 = substOfStrEnv strEnv1 strEnv2
                                 in
                                   (
                                    ID.Map.unionWith #1 (boxedKindSubst,
                                                       ID.Map.unionWith #1 (#1 subst1, 
                                                                          #1 subst2)
                                                       ),
                                    strPathEnv.unionWith #1 (strPathSubstOfTyCon,
                                                             strPathEnv.unionWith #1 (#2 subst1, 
                                                                                      #2 subst2)
                                                             ),
                                    ID.Map.unionWith #1 (tyConSubst,
                                                       ID.Map.unionWith #1 (#3 subst1, 
                                                                          #3 subst2)
                                                       )
                                    )
                                 end
                                   )
                           (ID.Map.empty, strPathEnv.empty, ID.Map.empty)
                           strEnv1
           val subst1 = substOfTyConEnv tyConEnv1 tyConEnv2
           val subst2 = substOfStrEnv strEnv1 strEnv2
           val (boxedKindSubst, strPathSubstOfTyCon, tyConSubst) = 
               (
                ID.Map.unionWith #1 (#1 subst2, #1 subst1),
                strPathEnv.unionWith #1 (#2 subst2, #2 subst1),
                ID.Map.unionWith #1 (#3 subst2, #3 subst1)
                )
           val (visited,Env) = 
               instSigEnv ID.Set.empty
                          boxedKindSubst 
                          strPathSubstOfTyCon
                          tyConSubst
                          (tyConEnv1,varEnv1,strEnv1)
         in
           Env
         end
  end (* end local for inst signature *)

  (* **************fresh ref field for Environment,sigma **************************)
  fun freshRefAddressInTy visited tyConSubst ty = 
      TypeTransducer.transTyPreOrder
        (fn (ty,visited) =>
            case ty of
              T.TYVARty (tvar as ref (T.TVAR tvKind)) => 
              let
                val (visited, tvKind) =
                    freshRefAddressInTvKind visited tyConSubst tvKind
                val _  = tvar := T.TVAR tvKind
              in
                (ty, visited, true)
              end
            | T.CONty {tyCon, args} => 
              let
                val (visited, tyCon) =
                    freshRefAddressInTyCon visited tyConSubst tyCon
              in 
                (T.CONty {tyCon=tyCon, args = args}, visited, true)
              end
            | T.POLYty {boundtvars, body} => 
              let
                val (visited,boundtvars) = 
                    IEnv.foldli
                      (fn (index, btvKind, (visited,boundtvars)) =>
                          let
                            val (visited,btvKind) =
                                freshRefAddressInBtvKind
                                  visited tyConSubst btvKind
                          in
                            (
                             visited,
                             IEnv.insert(boundtvars, index, btvKind)
                             )
                          end)
                      (visited,IEnv.empty)
                      boundtvars
              in
                (T.POLYty{boundtvars = boundtvars, body = body}, visited, true)
              end
          | _ => (ty, visited, true))
        visited
        ty

  and freshRefAddressInTvKind visited tyConSubst {id, recKind, eqKind, tyvarName}  =
      let
        val (visited, recKind) =
            case recKind of 
              T.UNIV => (visited, T.UNIV)
            | T.REC tySEnvMap => 
              let
                val (visited, tySEnvMap) = 
                    (SEnv.foldli
                       (fn (label, ty, (visited, tySEnvMap)) =>
                           let
                             val (ty, visited) = freshRefAddressInTy visited tyConSubst ty
                           in
                             ( visited, SEnv.insert(tySEnvMap, label, ty))
                           end)
                       (visited, SEnv.empty)
                       tySEnvMap)
              in 
                (visited, T.REC tySEnvMap)
              end
            | T.OVERLOADED tys => 
              let
                val (visited, tys) = 
                    (foldr
                       (fn (ty, (visited, tys)) =>
                           let
                             val (ty, visited) = freshRefAddressInTy visited tyConSubst ty
                           in
                             (visited, ty :: tys)
                           end)
                       (visited, nil)
                       tys)
              in 
                (visited, T.OVERLOADED tys)
              end
      in
        (visited,
         {id=id, 
          recKind = recKind,
          eqKind = eqKind,
          tyvarName = tyvarName}
         )
      end
            
  and freshRefAddressInBtvKind visited tyConSubst {index, recKind, eqKind} = 
      let
        val (visited, recKind) =
            case recKind of 
              T.UNIV => (visited, T.UNIV)
            | T.REC tySEnvMap => 
              let
                val (visited,tySEnvMap) = 
                    (SEnv.foldli
                       (fn (label, ty, (visited, tySEnvMap)) =>
                           let
                             val (ty, visited) = freshRefAddressInTy visited tyConSubst ty
                           in
                             (
                              visited,
                              SEnv.insert(tySEnvMap, label, ty)
                              )
                           end)
                       (
                        visited,
                        SEnv.empty
                        )
                       tySEnvMap
                       )
              in
                (visited, T.REC tySEnvMap)
              end
            | T.OVERLOADED tys => 
              let
                val (visited, tys) = 
                    (foldr
                       (fn (ty, (visited,tys)) =>
                           let
                             val (ty, visited) = freshRefAddressInTy visited tyConSubst ty
                           in
                             (visited, ty :: tys)
                           end)
                       (visited, nil)
                       tys)
              in
                (visited, T.OVERLOADED tys)
              end
      in
        (
         visited,
         {
          index=index, 
          recKind = recKind,
          eqKind = eqKind
          }
         )
      end

  and freshRefAddressInTyCon visited tyConSubst  (tyCon as {id,...} :T.tyCon) 
    =
    case (ID.Map.find(tyConSubst,id)) of
      NONE => (visited,tyCon)
    | SOME (newTyCon 
              as 
              { name, strpath, abstract, tyvars, id , eqKind, boxedKind, datacon} :T.tyCon) =>
      if ID.Set.member(visited, id) then
        (visited,newTyCon)
      else
        let
          val visited = ID.Set.add(visited,id)
          val (visited,newData) =  freshRefAddressInVarEnv visited tyConSubst (!datacon)
          val _ = datacon := newData
        in
          (visited,newTyCon)
        end

  and freshRefAddressInTyFun visited tyConSubst {name, tyargs, body} =
    let
      val (visited,tyargs) =
           IEnv.foldri
           (fn (index, btvKind, (visited,tyargs)) =>
               let
                 val (visited, btvKind) = 
                     freshRefAddressInBtvKind visited tyConSubst btvKind
               in
                 (
                  visited,
                  IEnv.insert(tyargs, index, btvKind)
                  )
               end)
           (visited, IEnv.empty)
           tyargs
      val (body, visited) = freshRefAddressInTy visited tyConSubst body
    in
      (
       visited,
       {
        name = name, 
        tyargs = tyargs, 
        body = body
        }
       )
    end 
      
  and freshRefAddressInTyBindInfo visited tyConSubst tyBindInfo =
    case tyBindInfo of
      T.TYCON (tyCon) => 
      let
        val (visited,tyCon) = freshRefAddressInTyCon visited tyConSubst tyCon
      in 
        (visited, T.TYCON (tyCon))
      end
    | T.TYFUN tyFun => 
      let
        val (visited,tyFun:T.tyFun) = freshRefAddressInTyFun visited tyConSubst tyFun
      in 
        (visited, T.TYFUN tyFun)
      end
    | T.TYSPEC {spec,impl = implOpt} => 
      case implOpt of
        NONE => (visited, tyBindInfo)
      | SOME impl => 
        let
          val (visited,newImpl) = freshRefAddressInTyBindInfo visited tyConSubst impl
        in
          (visited, T.TYSPEC {spec = spec,impl = SOME newImpl})
        end
      

  and freshRefAddressInTyConEnv visited tyConSubst tyConEnv =
      SEnv.foldli (fn (tycon,tyBindInfo,(visited,newTyConEnv)) =>
                      let
                        val (visited,tyBindInfo) = 
                            freshRefAddressInTyBindInfo visited tyConSubst tyBindInfo
                      in
                        (
                         visited,
                         SEnv.insert(newTyConEnv,
                                     tycon,
                                     tyBindInfo)
                         )
                      end
                  )
                  (visited,SEnv.empty)
                  tyConEnv

  and freshRefAddressInVarEnv visited tyConSubst varEnv =
      SEnv.foldli
        (fn (label, idstate,  (visited,varEnv)) =>
          case idstate of
            T.CONID {name, strpath, funtyCon, ty, tag, tyCon} =>
              let
                val (ty,visited) = freshRefAddressInTy visited tyConSubst ty
                val (visited,tyCon) = freshRefAddressInTyCon visited tyConSubst tyCon
              in
                (
                 visited,
                 SEnv.insert(
                             varEnv,
                             label,
                             T.CONID{name=name, 
                                     strpath=strpath, 
                                     funtyCon=funtyCon, 
                                     ty = ty,
                                     tag = tag,
                                     tyCon = tyCon}
                             )
                 )
              end
          | T.VARID {name,ty,strpath} =>
            let
              val (ty, visited) = freshRefAddressInTy visited tyConSubst ty
            in
              (
               visited,
               SEnv.insert(
                           varEnv,
                           label,
                           T.VARID{name=name,
                                   strpath=strpath,
                                   ty=ty}
                           )
               )
            end
          | x => 
            (visited,SEnv.insert(varEnv,label,x))
      )
      (visited,SEnv.empty)
      varEnv

  and freshRefAddressInStrEnv visited tyConSubst strEnv =
        SEnv.foldri
          (fn
           (label, T.STRUCTURE {id, name, strpath, env = Env, ...}, (visited,strEnv))
           =>
           let
             val (visited,Env) = freshRefAddressInEnv visited tyConSubst Env
             val strPathInfo = {id = id, name = name, strpath = strpath, env = Env}
           in
             (
              visited,
              SEnv.insert(strEnv, label, T.STRUCTURE strPathInfo)
              )
           end
             )
          (visited,SEnv.empty)
          strEnv

  and freshRefAddressInEnv visited tyConSubst  (tyConEnv, varEnv, strEnv) =
      let
        val (visited,tyConEnv) = freshRefAddressInTyConEnv visited tyConSubst tyConEnv
        val (visited,varEnv) = freshRefAddressInVarEnv  visited tyConSubst varEnv
        val (visited,strEnv) = freshRefAddressInStrEnv  visited tyConSubst strEnv
      in
        (visited,(tyConEnv,varEnv,strEnv))
      end

  fun freshRefAddressOfTyConInEnv (E as (TE,VE,SE)) =
      let
        fun tyConSubstOfTE TE =
            SEnv.foldli (fn (tyConName,tyBindInfo,tyConSubst) =>
                            case tyBindInfo of
                              T.TYCON {name,strpath,abstract,tyvars,id,
                                       eqKind = ref eqKind,
                                       boxedKind = ref boxedKind,
                                       datacon = ref data}
                              =>
                              let
                                (* partially copy of orginally tyCon
                                 * updation of data will be done in
                                 * freshRefAddressInTyCon
                                 *)
                                val newTyCon = 
                                    { 
                                     name = name,
                                     strpath = strpath,
                                     abstract = abstract,
                                     tyvars = tyvars,
                                     id = id,
                                     eqKind = ref eqKind,
                                     boxedKind = ref boxedKind,
                                     datacon = ref data (* partial fresh copy *) 
                                     }
                              in
                                ID.Map.insert(tyConSubst,id, newTyCon)
                              end
                            | T.TYFUN({name, tyargs, body = T.ALIASty(aliasTy,actTy)}) =>
                              let
                                val (id,newTyCon) = 
                                    case aliasTy of
                                      T.CONty{tyCon= {name,strpath,abstract,tyvars,id,
                                                      eqKind = ref eqKind,
                                                      boxedKind = ref boxedKind,
                                                      datacon = ref data
                                                      },
                                              ...} 
                                      => 
                                      let
                                        val newTyCon = 
                                            { 
                                             name = name,
                                             strpath = strpath,
                                             abstract = abstract,
                                             tyvars = tyvars,
                                             id = id,
                                             eqKind = ref eqKind,
                                             boxedKind = ref boxedKind,
                                             datacon = ref data
                                             }
                                      in
                                        (id,newTyCon)
                                      end
                                    | _ => raise Control.Bug "illegal ALIASty"
                              in
                                ID.Map.insert(tyConSubst, id, newTyCon)
                              end
                            | _ => tyConSubst)
                        ID.Map.empty
                        TE
        fun tyConSubstOfSE SE =
            SEnv.foldli (fn (str,T.STRUCTURE {env = (TE,VE,SE),...},tyConSubst) =>
                            let
                              val tyConSubst1 = tyConSubstOfTE TE
                              val tyConSubst2 = tyConSubstOfSE SE
                            in
                              ID.Map.unionWith 
                                #1 
                                (
                                 ID.Map.unionWith #1 (tyConSubst1,tyConSubst2),
                                 tyConSubst
                                 )
                            end
                        )
                        ID.Map.empty
                        SE
        val tyConSubst = ID.Map.unionWith #1 (tyConSubstOfTE TE,tyConSubstOfSE SE)
        val (visited, E) = freshRefAddressInEnv ID.Set.empty tyConSubst E
      in
        E
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
        | exn as E.IdNotFoundInSigMatch _ => 
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
        | _ => raise Control.Bug "unmatched signature match check"
end
end
