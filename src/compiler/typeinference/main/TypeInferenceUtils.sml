(**
 * utility functions for manupilating types (needs re-writing).
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: TypeInferenceUtils.sml,v 1.36 2007/06/08 21:58:15 ohori Exp $
 *)
structure TypeInferenceUtils =
struct
  local 
    structure PT = PatternCalcWithTvars
    structure PDT = PredefinedTypes
    structure TIC = TypeInferenceContext
    structure TC = TypeContext
    structure TU = TypesUtils
    structure E = TypeInferenceError
    structure STE = StaticTypeEnv
    open Types TypesUtils TypedCalc
  in
  
  val dummyTyId = ref 0
  fun nextDummyTy () = DUMMYty (!dummyTyId) before dummyTyId := !dummyTyId + 1

  val NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER = "X?" 

  fun stripSignature tpmstrexp =
      case tpmstrexp of
        TPMOPAQCONS (tpmstrexp, tpmsigexp, sigenv, loc) => stripSignature tpmstrexp
      | TPMTRANCONS (tpmstrexp, tpmsigexp, sigenv, loc) => stripSignature tpmstrexp
      | _ => tpmstrexp

  fun isAnonymousStrExp ptstrexp =
      case ptstrexp of
        PT.PTSTREXPBASIC _ => true
      | PT.PTSTRID _ => false
      | PT.PTSTRTRANCONSTRAINT (ptstrexp,_,_) => isAnonymousStrExp ptstrexp
      | PT.PTSTROPAQCONSTRAINT (ptstrexp,_,_) => isAnonymousStrExp ptstrexp
      | PT.PTFUNCTORAPP _ => true
      | PT.PTSTRUCTLET (_, ptstrexp, _) => isAnonymousStrExp ptstrexp

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

  fun etaExpandCon (varStrPath,vid) loc idState = 
      case idState of
        CONID (conPathInfo as {name, strpath, funtyCon, ty, tag, tyCon}) =>
        let
          val termconPathInfo =
              {
                name = vid,
                strpath = varStrPath,
                funtyCon = funtyCon,
                ty = ty,
                tyCon = tyCon,
                tag = tag
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
                  {name = Vars.newTPVarName(), strpath = NilPath, ty = newArgTy}
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
                          TPCONSTRUCT
                           {
                            con=termconPathInfo,
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
            | FUNMty([argTy], resultTy) => (* ty should be mono; data constructor has a closed type *)
              let
                val newVarPathInfo =
                  {name = Vars.newTPVarName(), strpath = NilPath, ty = argTy}
              in
                (
                  ty,
                  TPFNM
                  {
                   argVarList=[newVarPathInfo],
                   bodyTy=resultTy,
                   bodyExp=
                     TPCONSTRUCT
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
          else (ty, TPCONSTRUCT{con=termconPathInfo, instTyList=nil, argExpOpt=NONE, loc=loc})
        end
      | PRIM (primInfo as {name, ty}) =>
        (case ty of
           POLYty{boundtvars, body = FUNMty([argTy], resultTy)} =>
           let
                val (subst, newBoundEnv) = TU.copyBoundEnv boundtvars
                val newArgTy = TU.substBTvar subst argTy
                val newResultTy = TU.substBTvar subst resultTy
                val newVarPathInfo =
                  {name = Vars.newTPVarName(), strpath = NilPath, ty = newArgTy}
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
                 {name = Vars.newTPVarName(), strpath = NilPath, ty = argTy}
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
                    {name = Vars.newTPVarName(), strpath = NilPath, ty = argTy}
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
      TYCON({id, ...}) => id
    | TYSPEC {spec={id, ...},impl} => id
    | TYFUN {name,...} => raise (E.SharingOnTypeFun {tyConName = name})

  fun tyConIdInTyBindInfoOpt tyBindInfo = 
    case  tyBindInfo of
      TYCON({id, ...}) => SOME id
    | TYSPEC {spec = {id, ...},impl} => SOME id
    | TYFUN {name,...} => NONE

  fun tyConIdSetTyConEnv fromTyConId tyConEnv =
      SEnv.foldl
        (fn (tyBindInfo, tyConIdSet) => 
            let
              val thisTyConIdOpt = tyConIdInTyBindInfoOpt tyBindInfo
            in
              case thisTyConIdOpt of
                SOME thisTyConId =>
                (* ToDo: Explanation is required for this comparation. *)
                (*
                  if fromTyConId <= thisTyConId 
                 *)
                if ID.compare (fromTyConId, thisTyConId) <> GREATER
                    then
                      ID.Set.add(tyConIdSet, thisTyConId)
                  else
                    tyConIdSet
              | NONE => tyConIdSet
            end
          )
        ID.Set.empty
        tyConEnv

  and tyConIdSetVarEnv fromTyConId varEnv =
      SEnv.foldl
        (fn (CONID {name, strpath, funtyCon, ty, tag, tyCon}, tyConIdSet) =>
            let 
              val thisTyConId = #id tyCon
            in
              (* ToDo : Some explanation is required for this compararation. *)
              (*
              if fromTyConId <= thisTyConId 
               *)
              if ID.compare (fromTyConId, thisTyConId) <> GREATER
              then
                ID.Set.add(tyConIdSet, thisTyConId)
              else
                tyConIdSet
            end
          | (_, tyConIdSet) => tyConIdSet
                              )
        ID.Set.empty
        varEnv

  and tyConIdSetStrEnv fromTyConId (STRUCTURE strEnvCont) =
      SEnv.foldl
        (fn ({env = (tyConEnv, varEnv, strEnv), ...}, tyConIdSet) =>
            let
              val T1 = tyConIdSetTyConEnv fromTyConId tyConEnv
              val T2 = tyConIdSetVarEnv fromTyConId varEnv
              val T3 = tyConIdSetStrEnv fromTyConId strEnv
            in
              ID.Set.union (ID.Set.union(T1, ID.Set.union(T2,T3)),tyConIdSet)
            end)
        ID.Set.empty
        strEnvCont

  fun tyConIdSetEnv fromTyConId (tyConEnv, varEnv, strEnv) =
      let
        val T1 = tyConIdSetTyConEnv fromTyConId tyConEnv
        val T2 = tyConIdSetVarEnv fromTyConId varEnv
        val T3 = tyConIdSetStrEnv fromTyConId strEnv
      in
        ID.Set.union(T1,ID.Set.union(T2,T3))
      end
(*
  fun tyConIdSetTyConSizeTagEnv fromTyConId tyConSizeTagEnv =
      SEnv.foldl
        (fn ({tyBindInfo,sizeInfo,tagInfo}, tyConIdSet) => 
            let
              val thisTyConIdOpt = tyConIdInTyBindInfoOpt tyBindInfo
            in
              case thisTyConIdOpt of
                SOME thisTyConId =>
                (* ToDo: Explanation is required for this comparation. *)
                (*
                  if fromTyConId <= thisTyConId 
                 *)
                if ID.compare (fromTyConId, thisTyConId) <> GREATER
                    then
                      ID.Set.add(tyConIdSet, thisTyConId)
                  else
                    tyConIdSet
              | NONE => tyConIdSet
            end
          )
        ID.Set.empty
        tyConSizeTagEnv

  fun tyConIdSetStrSizeTagEnv fromTyConId strSizeTagEnv =
      SEnv.foldl
        (fn (STRSIZETAG {env = (tyConSizeTagEnv, varEnv, strSizeTagEnv), ...}, tyConIdSet) =>
            let
              val T1 = tyConIdSetTyConSizeTagEnv fromTyConId tyConSizeTagEnv
              val T2 = tyConIdSetVarEnv fromTyConId varEnv
              val T3 = tyConIdSetStrSizeTagEnv fromTyConId strSizeTagEnv
            in
              ID.Set.union (ID.Set.union(T1, ID.Set.union(T2,T3)),tyConIdSet)
            end)
        ID.Set.empty
        strSizeTagEnv
*)
  fun tyConIdSetTypeEnv fromTyConId (TypeEnv:StaticTypeEnv.typeEnv)  =
      ID.Set.union (tyConIdSetStrEnv fromTyConId (#strEnv TypeEnv),
                    ID.Set.union (tyConIdSetTyConEnv fromTyConId (#tyConEnv TypeEnv),
                                  tyConIdSetVarEnv fromTyConId (#varEnv TypeEnv)))

  fun tyConIdSetImExTypeEnv fromTyConId (importTypeEnv, exportTypeEnv)  =
      ID.Set.union (tyConIdSetTypeEnv fromTyConId importTypeEnv ,
                    tyConIdSetTypeEnv fromTyConId exportTypeEnv )


  fun computeGenerativeExnTag(fromExnTag, toExnTag, importTypeEnv) =
      let
          fun collectExnTagVarEnv varEnv =
              SEnv.foldl
              (fn (CONID {name, strpath, funtyCon, ty, tag, tyCon}, exnTagSet) =>
                   if Types.eqTyCon(PDT.exnTyCon, tyCon) 
                   then ISet.add(exnTagSet, tag)
                   else exnTagSet
                | (_, exnTagSet) => exnTagSet)
              ISet.empty
              varEnv

          fun collectExnTagStrEnv (STRUCTURE strEnvCont) =
              SEnv.foldl
              (fn ({env = (_, subVarEnv, subStrEnv),...}, exnTagSet) =>
                  ISet.union
                      ((ISet.union (collectExnTagVarEnv subVarEnv,
                                    collectExnTagStrEnv subStrEnv)),
                       exnTagSet))
              ISet.empty
              strEnvCont
              
          fun genExnTagSetByInterval (fromExnTag, toExnTag) =
              let
                  fun impl currentExnTag exnTagSet =
                      if currentExnTag < toExnTag 
                      then impl (currentExnTag + 1) (ISet.add(exnTagSet, currentExnTag))
                      else exnTagSet
              in impl fromExnTag ISet.empty end

          fun collectExnTagTypeEnv (importTypeEnv:STE.importTypeEnv) =
              ISet.union (collectExnTagVarEnv (#varEnv importTypeEnv),
                          collectExnTagStrEnv (#strEnv importTypeEnv))

          val allExnTagSet = genExnTagSetByInterval (fromExnTag, toExnTag)
          val importExnTagSet = collectExnTagTypeEnv importTypeEnv
      in
          ISet.difference (allExnTagSet, importExnTagSet)
      end
end
end
