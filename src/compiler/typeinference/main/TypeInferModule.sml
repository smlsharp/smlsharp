(**
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: TypeInferModule.sml,v 1.70.6.5 2007/11/06 01:31:35 bochao Exp $
 *)
structure TypeInferModule =
struct
local 
  structure A = Absyn
  structure C = Control
  structure E = TypeInferenceError
  structure P = Path
  structure PDT = PredefinedTypes
  structure PL = PatternCalc
  structure PT = PatternCalcWithTvars
  structure TB = TypeinfBase
  structure TC = TypeContext
  structure TIC = TypeInferenceContext
  structure TPU = TypedCalcUtils
  structure ITC = InitialTypeContext
  structure U = Unify
  structure UE = UserError 
  structure TIT = TypeInstantiationTerm
  structure TIU = TypeInferenceUtils
  structure SL = StructureLocalization
  structure TIFC = TypeInferCore
  structure TCU = TypeContextUtils
  structure TU = TypesUtils
  structure SU = SigUtils
  structure T = Types
  structure TCC = TypedCalc 
  structure STE = StaticTypeEnv
  val emptyContext = TC.emptyContext

in 

  
  fun computetvarSEnv rawTy =
      let
        fun compImpl rawTy tvarSEnv =
            case rawTy of
              A.TYID ({name=s,ifeq=bool}, loc) => 
              (case SEnv.find (tvarSEnv,s) of
                 NONE => 
                 let
                   val newTyVarRef = 
                       case T.newty
                              {
                               recKind = T.UNIV,
                               eqKind = if bool then T.EQ else T.NONEQ, 
                               tyvarName = NONE
                               } of
                         T.TYVARty newTyVarRef => newTyVarRef
                       | _ => raise Control.Bug "illegal newTy in computevarSEnv"
                 in
                   SEnv.insert(tvarSEnv, s, newTyVarRef)
                 end
               | _ => tvarSEnv)
            | A.TYRECORD (stringRawtyList, loc) =>
              foldl
                (fn ((l, rawTy), tvarSEnv) => compImpl rawTy tvarSEnv)
                tvarSEnv
                stringRawtyList
            | A.TYCONSTRUCT (rawtyList, longTyCon, loc) =>
              foldl
                (fn (rawTy, tvarSEnv) => compImpl rawTy tvarSEnv)
                tvarSEnv
                rawtyList
            | A.TYTUPLE (rawtyList, loc) =>
              foldl
                (fn (rawTy, tvarSEnv) => compImpl rawTy tvarSEnv)
                tvarSEnv
                rawtyList
            | A.TYFUN (rawty1, rawty2, loc) =>
              let val tvarSEnv = compImpl rawty1 tvarSEnv
              in compImpl rawty2 tvarSEnv end
            | A.TYFFI (cconv, argTys, retTy, loc) =>
              foldl
                (fn (rawTy, tvarSEnv) => compImpl rawTy tvarSEnv)
                (compImpl retTy tvarSEnv)
                argTys
      in
        compImpl rawTy SEnv.empty
      end

  fun updateStrpathInEnv (currentStrpath, newStrpath, Env) =
      case currentStrpath of
        P.PStructure _ => 
        TCU.updateStrpathInTopEnv {
                                   newStrpath = newStrpath,
                                   currentStrpath = currentStrpath
                                   }
                                  Env
      | NilPath => Env

  (* Note: specification descriptions duplication is
   * checked in Elaboration phase 
   *)
  (* 
   * for value description (val x : int and ....) lists in a signature.
   *)
  fun typeinfValdescs (cc : TIC.currentContext) nil loc = 
      (TC.emptyContext, nil)
    | typeinfValdescs (cc : TIC.currentContext) ((vidString, rawTy) :: rem) loc =
      (* rule 79 *)
      let
        val tvarSEnv = computetvarSEnv rawTy 
        val newcc = 
            TIC.extendCurrentContextWithUtvarEnv(cc, tvarSEnv)
        val tau = TIFC.evalRawty newcc rawTy
        val newTau = 
            let
              (*
                Ohori:
                tau below should not contain any free type variables shared by
                other.
                *)
              val {boundEnv, removedTyIds} = TIFC.generalizer (tau, T.toplevelDepth)
(*
              val {boundEnv, removedTyIds} = TIFC.generalizer (tau, cc)
*)
            in 
              if IEnv.isEmpty boundEnv
              then tau
              else T.POLYty{boundtvars = boundEnv, body = tau}
            end
        val valDesc = {name = vidString, ty = newTau}
        val varPathInfo = 
            {
             name = vidString, 
             strpath = #strLevel cc, 
             ty = newTau
            }
        (*
         Ohori: Need to check.
         This was originally coded below.
          val context1 = 
               TC.bindVarInEmptyContext (vidString, T.VARID varPathInfo)
         Since there should not be any free type variables shared by others,
         it should be a toplevel binding.
         *)
        val context1 = 
            TC.bindVarInEmptyContext (T.toplevelDepth, vidString, T.VARID varPathInfo)
        val (context2 : TC.context, valDescs) = 
            typeinfValdescs cc rem loc
      in
        (
         TC.mergeContexts (context1, context2),
         valDesc :: valDescs
         )
      end

  and typeinfSpecKind specKind =
      case specKind of
          A.ATOM => T.ATOMty
        | A.DOUBLE => T.DOUBLEty
        | A.BOXED => T.BOXEDty
        | A.GENERIC => T.GENERICty
 (*
  * for type description ([type] 'a foo and ...) in a signature.
  *)
  and typeinfTypdescs eqKind (cc : TIC.currentContext) nil loc = 
      (TC.emptyContext, nil)
    | typeinfTypdescs eqKind 
        (cc : TIC.currentContext) 
        ((tyvars : {name:string, ifeq:bool} list, tyconName, specKind) :: rem) loc =
      (* rule 80-for rule 69 *)
      let
        val spec = {
                    name = tyconName,
                    id = T.newTyConId(),
                    strpath = #strLevel cc,
                    eqKind = eqKind,
                    tyvars = map (fn {name, ifeq} => ifeq) tyvars,
                    boxedKind = typeinfSpecKind specKind
                    }
        val tySpec = {spec = spec, impl = NONE}
        val context1 = TC.bindTyConInEmptyContext (tyconName, T.TYSPEC tySpec)
        val (context2, specs) = typeinfTypdescs eqKind cc rem loc
      in
        (
         TC.mergeContexts (context1, context2),
         spec :: specs
         )
      end

  (*
   * exception descriptions ([exception] Ex and ...)  in a signature
   *)
  and typeinfExdescs (cc:TIC.currentContext) nil loc =
      (TC.emptyContext, nil)
    | typeinfExdescs (cc:TIC.currentContext) ((vidString, rawTyOpt) :: rem) loc=
      (*rule 83*)
      let
        val tau =
            case rawTyOpt of
              NONE => NONE
            | SOME rawTy => SOME(TIFC.evalRawty cc rawTy)
        val _ =
            case tau of
              NONE      => ()
            | SOME tau' =>
              if  OTSet.isEmpty (TU.EFTV tau') then () 
              else E.enqueueError
                     (loc, E.FreeTypeVariablesInExceptionType({exid = vidString}))
        val conPathInfo = PDT.makeExnConPath vidString P.NilPath tau
        (*
         Ohori: Need to check.
         This was originally coded below.
            val context1 = TC.bindVarInEmptyContext (vidString, T.CONID conPathInfo)
         This should be regarded as a toplevel binding with respect to lambdaDepth.
          *)
        val context1 = TC.bindVarInEmptyContext (T.toplevelDepth, vidString, T.CONID conPathInfo)
        val (context2, conPathInfos) = typeinfExdescs cc rem loc
      in
        (
         TC.mergeContexts (context1, context2),
         conPathInfo :: conPathInfos
         )
      end


  (*
   * for structure description ([structure] A : <sig> and ... )
   *)
  and typeinfStrdescs (cc : TIC.currentContext) nil loc = 
      (TC.emptyContext, nil)
    | typeinfStrdescs cc ((strName, ptsigexp) :: rem) loc = 
      (*rule 84*)
      let
        val strID = T.newStructureId ()
        val newcc =
            TIC.updateStrLevel
                (cc, P.appendPath (#strLevel cc, strID, strName))
        val (sigIdPath, context1, specs) = typeinfSigexp newcc ptsigexp
        val E = TC.getStructureEnvFromContext context1
        val E = updateStrpathInEnv (sigIdPath, (#strLevel newcc), E)
        val strPathInfo =
            {id = strID, name = strName, strpath = #strLevel cc, env = E}
        val context1 =
            TC.injectStrEnvToContext
                (T.STRUCTURE (SEnv.singleton(strName, strPathInfo)))
        val (context2, strdescs) = typeinfStrdescs cc rem loc
      in
        (
         TC.mergeContexts (context1, context2),
         (strPathInfo, specs) :: strdescs
         )
      end

  (**
   * for a signature (val valdescs etc)
   * @params currentcontext ptspec
   * @return  an Environment and tpspec
   *)
  and typeinfSpec (cc:TIC.currentContext) ptspec =
      case ptspec of
        PT.PTSPECVAL (valdescs, loc) => 
          (* rule 68 *) (* generalization operation is moved to rule 79*)
          let 
            val (newContext, valspecs) = 
                  typeinfValdescs cc valdescs loc
          in
            (newContext, TCC.TPMSPECVAL valspecs)
          end
      | PT.PTSPECTYPE(typdescs, loc) =>
          (* rule 69 *)
        let
            val (newContext, typespecs) = 
                typeinfTypdescs T.NONEQ cc typdescs loc
        in
            (newContext, TCC.TPMSPECTYPE typespecs)
        end
      | PT.PTSPECTYPEEQUATION (tvarListStringRawTy as (_,tyConName,_) ,loc) =>
          (* appendix A *)
          let
            fun expandManifestTypeDesc (tyvars, tyConName, rawTy) =
                PT.PTSPECINCLUDE
                (
                 PT.PTSIGWHERE
                   (
                    PT.PTSIGEXPBASIC (PT.PTSPECTYPE([(tyvars, tyConName, A.GENERIC)], loc), loc),
                    [(tyvars, [tyConName], rawTy)],
                    loc
                   ),
                 loc
                )
            val (newContext as {tyConEnv,...}, _) =
                  typeinfSpec cc (expandManifestTypeDesc tvarListStringRawTy)
            val tyBindInfo = 
                case SEnv.find(tyConEnv,tyConName) of
                  NONE => 
                    raise Control.BugWithLoc (("tyCon unbounded:"^tyConName),loc)
                | SOME tyFun => tyFun
          in
            (newContext, TCC.TPMTYPEEQUATION tyBindInfo)
          end
      | PT.PTSPECEQTYPE(typdescs, loc) =>
          (* rule 70 *)
          let
            val (newContext, eqtypespecs) = 
                  typeinfTypdescs T.EQ cc typdescs loc
          in
            (newContext, TCC.TPMSPECEQTYPE eqtypespecs)
          end
      | PT.PTSPECDATATYPE(datadescs, loc) => 
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
                  TIFC.typeinfDatatypeDecl T.toplevelDepth cc newdatadescs loc
          in
            (newContext, TCC.TPMSPECDATATYPE tyCons)
          end
      | PT.PTSPECREPLIC(tyConName, longTyCon, loc) =>
          (* rule 72 *)
        let 
            val ((tyConStrPath,tyCon), tyBindInfoOpt) = TIC.lookupLongTyCon (cc, longTyCon)
        in
            case tyBindInfoOpt of
                SOME(T.TYCON rightTyCon) => 
                let
                    val {name, strpath, abstract, tyvars,
                         id,   eqKind,  boxedKind, datacon} : T.tyCon= rightTyCon
                    val leftTyCon : T.tyCon =
                        {
                         name = tyConName,
                         strpath = #strLevel cc,
                         abstract = abstract,
                         tyvars = tyvars,
                         id = id,
                         eqKind = ref (!eqKind),
                         boxedKind = ref (!boxedKind),
                         datacon = ref SEnv.empty 
                         } 
                    val tyConSubst = ID.Map.singleton(id,T.TYCON leftTyCon)
                    val (visited,newDatacon) = 
                        TCU.substTyConInVarEnv ID.Set.empty tyConSubst (!datacon)
                    val _ = (#datacon leftTyCon):= newDatacon
                    val context1 = TC.bindTyConInEmptyContext(tyConName, T.TYCON leftTyCon)
                    val context2 = 
                        (* do not propagate varEnv of abstype *)
                        if not abstract then
                            TC.extendContextWithVarEnv (context1,!(#datacon leftTyCon))
                        else context1
                in
                    (
                     context2,
                     TCC.TPMSPECREPLIC ({left = leftTyCon, 
                                         right = {
                                                  relativePath = (tyConStrPath,tyCon),
                                                  tyCon = rightTyCon
                                                  }
                                         }
                                        )
                     )
                end
            | SOME _ => 
              (
               E.enqueueError(
                              loc,
                              E.TyFunFoundInsteadOfTyCon 
                                  {tyFun = Absyn.longidToString(longTyCon)}
                                  );
               (TC.emptyContext, TCC.TPMSPECERROR)
               )
            | _ =>
              (
               E.enqueueError(
                              loc,
                              E.TyConNotFoundInReplicateData
                                  ({tyCon = Absyn.longidToString(longTyCon)})
                                  );
               (TC.emptyContext, TCC.TPMSPECERROR)
               )
          end
      | PT.PTSPECEXCEPTION (exdescs, loc) =>
          (* rule 73 *)
          let
            val (newContext, exspecs) = 
                  typeinfExdescs cc exdescs loc
          in
            (newContext, TCC.TPMSPECEXCEPTION exspecs)
          end
      | PT.PTSPECSTRUCT(strdescs, loc) =>
          (* rule 74 *)
          let
            val (newContext, strspecs) = typeinfStrdescs cc strdescs loc
          in
            (newContext, TCC.TPMSPECSTRUCT strspecs)
          end
      | PT.PTSPECINCLUDE(ptsigexp, loc) =>
          (* rule 75 *)
        let
          val (sigIdPath, newContext, sigspecs) = typeinfSigexp cc ptsigexp 
          val E = TC.getStructureEnvFromContext newContext
          val newE = updateStrpathInEnv (sigIdPath, #strLevel cc, E)
          val newContext = TC.injectEnvToContext newE
        in
          (newContext, TCC.TPMSPECINCLUDE sigspecs)
        end
      | PT.PTSPECSEQ(ptspec1, ptspec2, loc) => 
        (* rule 77 *)
        let
          val (context1, spec1) = typeinfSpec cc ptspec1
          val newcc = TIC.extendCurrentContextWithContext(cc, context1)
          val (context2, spec2) = typeinfSpec newcc ptspec2
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
          (context3, TCC.TPMSPECSEQ(spec1, spec2))
        end
      | PT.PTSPECSHARE (ptspec, nil, loc) => typeinfSpec cc ptspec
      | PT.PTSPECSHARE (ptspec, longTyConList, loc) =>
          (* here we just equate id field in tyCon.
             No check is performed.
             At the time of abstraction, we collect the id with its eqkind.
             At the time of realizer computation, we check the equality.
          *)
         (let
            val fromTyConId = T.nextTyConId()
            val (context1, tpmspec) = typeinfSpec cc ptspec
            val newCurrentContext = 
                  TIC.injectContextToCurrentContext context1
              val (representativeTyConId, hdEqKind) = 
                let
                  val hdLongTyCon = List.hd longTyConList
                  val (rpTyConId, eqKind) = SU.longTyConIdEqKind newCurrentContext hdLongTyCon
                in
                  (* ToDo : explanation about this comparation is necessary. *)
                  (*
                  if fromTyConId <= rpTyConId
                   *)
                  if
                    (ID.compare(fromTyConId, rpTyConId) <> GREATER)
                  then (rpTyConId, eqKind)
                  else
                    raise E.RigidTypeInSharing 
                            {id = Absyn.longidToString hdLongTyCon}
                end
            val pathList = 
                map (fn longTyCon =>
                        let
                          val ((tyConStrPath,tyCon), _) = 
                              case
                                TIC.lookupLongTyCon
                                  (newCurrentContext, longTyCon) 
                               of
                                (_,NONE) => 
                                  raise E.TyConNotFoundInShare
                                          {tyCon = Absyn.longidToString(longTyCon)}
                              | tyConOption => tyConOption
                        in
                          (tyConStrPath, tyCon)
                        end
                    )
                    longTyConList
            val (tyConIdEqSubst, othersOverallEqKind) = 
                List.foldr (fn (longTyCon, (tyConIdSubst, othersOverallEqKind)) =>
                               let
                                 val (tyConId, eqKind) = 
                                     SU.longTyConIdEqKind newCurrentContext longTyCon
                               in
                                 (* ToDo : explanation about this comparation
                                  * is necessary. *)
                                 (*
                                 if fromTyConId <= tyConId then
                                   *)
                                 if
                                   (ID.compare(fromTyConId, tyConId) <> GREATER)
                                 then
                                     (ID.Map.insert(tyConIdSubst, tyConId, representativeTyConId),
                                      if eqKind = T.EQ then eqKind else othersOverallEqKind)
                                 else
                                   raise E.RigidTypeInSharing {id = Absyn.longidToString longTyCon}
                               end
                              )
                           (ID.Map.empty, T.NONEQ)
                           longTyConList
              val newTyConIdEqSubst = 
                  if hdEqKind = T.EQ orelse othersOverallEqKind = T.EQ then
                      ID.Map.map (fn newId => (newId, T.EQ)) 
                                 tyConIdEqSubst
                  else 
                      ID.Map.map (fn newId => (newId, T.NONEQ)) 
                                 tyConIdEqSubst
          in 
              (SU.equateTyConIdEqInContext newTyConIdEqSubst context1, TCC.TPMSPECSHARE (tpmspec, pathList))
          end
            handle exn as E.TyConNotFoundInShare _ => 
                   (E.enqueueError (loc, exn);(TC.emptyContext, TCC.TPMSPECERROR))
                 | exn as E.SharingOnTypeFun _ =>
                   (E.enqueueError (loc, exn);(TC.emptyContext, TCC.TPMSPECERROR))
                 | exn as E.RigidTypeInSharing _ =>
                   (E.enqueueError (loc, exn);(TC.emptyContext, TCC.TPMSPECERROR))
         )
      | PT.PTSPECSHARESTR(ptspec, longstrids, loc) =>
        (*
         * suppose 
         *  signature A =
         *  sig
         *   structure A : sig type t end  (* tyconId = 1 *)
         *   structure B : sig type t end  (* tyconId = 2 *)
         *   structure C : sig type t end  (* tyconId = 3 *)
         *   sharing A = B = C
         *  end
         * then phi = { 1 -> 3, 2 -> 3}
         *)
        let 
          type idEqSubst = (ID.id * T.eqKind) ID.Map.map
          val fromTyConId = T.nextTyConId()
          val (context1, tpmspec) = typeinfSpec cc ptspec
          val newCurrentContext = TIC.injectContextToCurrentContext context1
          val (Es, strPaths) = 
              foldr
              (fn (longstrid, (Es,strPaths)) =>
                 case TIC.lookupLongStructureEnv (newCurrentContext, longstrid)
                   of (strpath, SOME {env = E, ...}) => 
                      (E :: Es, strpath :: strPaths)
                    | (_, NONE) =>
                       (
                        E.enqueueError
                        (
                         loc,
                         E.StructureNotFound
                         ({id = Absyn.longidToString(longstrid)})
                         );
                        (Es,strPaths))
                       )
              (nil,nil)
              longstrids

          fun share nil phi = phi
            | share (E :: Es) phi =
              let
                val phi' = sharepairwise E Es phi
              in
                share Es phi'
              end

          and sharepairwise E nil (phi) = phi
            | sharepairwise E (E1 :: Es) phi =
              let 
                val newphi = sharePairE E E1 phi
              in 
                sharepairwise E Es newphi
              end

          and sharePairE
                  (E1 as (tyConEnv1, varEnv1, strEnv1:T.strEnv))
                  (E2 as (tyConEnv2, varEnv2, strEnv2:T.strEnv))
                  phi =
                  let 
                    val phi1 = shareTE (tyConEnv1, tyConEnv2) phi
                    val phi2 = shareSE (strEnv1, strEnv2) phi1
                  in 
                    phi2
                  end 

          and shareTE (tyConEnv1, tyConEnv2) (phi:idEqSubst) =
              SEnv.foldli
                (fn (tyConName, tyBindInfo, (phi:idEqSubst)) =>
                    (case SEnv.find(tyConEnv2, tyConName) of 
                       NONE => phi
                     | SOME(tyBindInfo') => 
                       let
                         val (idFrom, eqFrom) = 
                             let
                                 val idFrom = TIU.tyConIdInTyBindInfo tyBindInfo
                                 val eqFrom = TIU.eqKindInTyBindInfo tyBindInfo
                             in
                                 case ID.Map.find(phi, idFrom) of
                                     NONE => (idFrom, eqFrom)
                                   | SOME (newId, newEqKind) =>
                                     if newEqKind = T.EQ orelse eqFrom = T.EQ then
                                         (newId, T.EQ)
                                     else (newId, T.NONEQ)
                             end
                         val (idTo, eqTo) = 
                             let
                                 val idTo = TIU.tyConIdInTyBindInfo tyBindInfo'
                                 val eqTo = TIU.eqKindInTyBindInfo tyBindInfo'
                             in
                                 case ID.Map.find(phi, idTo) of
                                     NONE => (idTo, eqTo)
                                   | SOME (newId, newEqKind) =>
                                     if newEqKind = T.EQ orelse eqTo = T.EQ then
                                         (newId, T.EQ)
                                     else (newId, T.NONEQ)
                             end
                         val eqOverall = if eqFrom = T.EQ orelse eqTo = T.EQ then 
                                             T.EQ 
                                         else T.NONEQ
                       in
                         (* ToDo : explanation about this comparation is
                          * necessary. *)
(*
                         if fromTyConId <= idFrom andalso
                            fromTyConId <= idTo
*)
                         if
                           (ID.compare(fromTyConId, idFrom) <> GREATER)
                           andalso (ID.compare(fromTyConId, idTo) <> GREATER)
                         then
                           if ID.eq(idFrom, idTo) then phi
                           else
                               SU.extendTyConIdEqSubst (ID.Map.singleton(idFrom, (idTo, eqOverall)), phi) 
                         else
                           raise E.RigidTypeInSharing {id = tyConName}
                       end
                         handle exn as E.SharingOnTypeFun _ =>
                                (E.enqueueError (loc,exn);phi)
                              | exn as E.RigidTypeInSharing _ =>
                                (E.enqueueError (loc,exn);phi)
                                )
                    )
                phi
                tyConEnv1

          and shareSE (T.STRUCTURE strEnvCont1, T.STRUCTURE strEnvCont2) phi =
              SEnv.foldli
                (fn (strid, {env = E1, ...}, phi) =>
                    case SEnv.find (strEnvCont2, strid) of
                      NONE => phi
                    | SOME {env = E2, ...} => sharePairE E1 E2 phi)
                phi
                strEnvCont1
          val phi = share Es ID.Map.empty
        in         
          (SU.equateTyConIdEqInContext phi context1, TCC.TPMSPECSHARESTR (tpmspec,strPaths))
        end
(*        let 
          val fromTyConId = SE.nextTyConId()
          val (context1, tpmspec) = typeinfSpec cc ptspec
          val newCurrentContext = TIC.injectContextToCurrentContext context1
          val (Es, strPaths) = 
              foldr
              (fn (longstrid, (Es,strPaths)) =>
                 case TIC.lookupLongStructureEnv (newCurrentContext, longstrid)
                   of (strpath, SOME {env = E, ...}) => 
                      (E :: Es, strpath :: strPaths)
                    | (_, NONE) =>
                       (
                        E.enqueueError
                        (
                         loc,
                         E.StructureNotFound
                         ({id = Absyn.longidToString(longstrid)})
                         );
                        (Es,strPaths))
                       )
              (nil,nil)
              longstrids

          fun share nil phi = phi
            | share (E :: Es) phi =
              let
                val phi' = sharepairwise E Es phi
              in
                share Es phi'
              end

          and sharepairwise E nil phi = phi
            | sharepairwise E (E1 :: Es) phi =
              let 
                val newphi = sharePairE E E1 phi
              in 
                sharepairwise E Es newphi
              end

          and sharePairE
                  (E1 as (tyConEnv1, varEnv1, strEnv1))
                  (E2 as (tyConEnv2, varEnv2, strEnv2))
                  phi =
                  let 
                    val phi1 = shareTE (tyConEnv1, tyConEnv2) phi
                    val phi2 = shareSE (strEnv1, strEnv2) phi1
                  in 
                    phi2
                  end 

          and shareTE (tyConEnv1, tyConEnv2) phi =
              SEnv.foldli
                (fn (tyConName, tyBindInfo, phi) =>
                    (case SEnv.find(tyConEnv2, tyConName) of 
                       NONE => phi
                     | SOME(tyBindInfo') => 
                       let
                         val idFrom = TCU.substTyConIdInId phi (TIU.tyConIdInTyBindInfo tyBindInfo)
                         val idTo = TCU.substTyConIdInId phi (TIU.tyConIdInTyBindInfo tyBindInfo')
                       in
                         (* ToDo : explanation about this comparation is
                          * necessary. *)
(*
                         if fromTyConId <= idFrom andalso
                            fromTyConId <= idTo
*)
                         if
                           (ID.compare(fromTyConId, idFrom) <> GREATER)
                           andalso (ID.compare(fromTyConId, idTo) <> GREATER)
                         then
                           if idFrom = idTo then phi
                           else 
                             SU.extendTyConIdSubst (ID.Map.singleton(idFrom, idTo), phi)
                         else
                           raise E.RigidTypeInSharing {id = tyConName}
                       end
                         handle exn as E.SharingOnTypeFun _ =>
                                (E.enqueueError (loc,exn);phi)
                              | exn as E.RigidTypeInSharing _ =>
                                (E.enqueueError (loc,exn);phi)
                                )
                    )
                phi
                tyConEnv1

          and shareSE (strEnv1, strEnv2) phi =
              SEnv.foldli
                (fn (strid, T.STRUCTURE{env = E1, ...}, phi) =>
                    case SEnv.find (strEnv2, strid) of
                      NONE => phi
                    | SOME(T.STRUCTURE{env = E2, ...}) => sharePairE E1 E2 phi)
                phi
                strEnv1
          val phi = share Es ID.Map.empty
        in         
          (SU.equateTyConIdInContext phi context1, TCC.TPMSPECSHARESTR (tpmspec,strPaths))
        end
*)
      | PT.PTSPECEMPTY => (TC.emptyContext, TCC.TPMSPECEMPTY)

    (*
     * for signatures (sig ... end etc)
     *)
    and typeinfSigexp cc ptsigexp =
        case ptsigexp of
          PT.PTSIGEXPBASIC(ptspec, loc) =>
          (*rule 62*)
          let
            val (newContext, sigspec) = typeinfSpec cc ptspec
          in
            (P.NilPath, newContext, TCC.TPMSIGEXPBASIC sigspec)
          end
        | PT.PTSIGID(sigName, loc) =>
          (*rule 63*)   
          let
            val (sigIdPath, Env) =
                case TIC.lookupSigma(cc, sigName) of
                  SOME (T.SIGNATURE(tyConIdSet, sigPathInfo as {id,name,env,...})) =>
                  (
                   P.PStructure(id,name,P.NilPath),
                   SigCheck.sigTyNameRename (tyConIdSet, env)
                   )
                | NONE =>
                  (
                    E.enqueueError (loc, E.SignatureNotFound{id = sigName});
                    (P.NilPath,T.emptyE)
                  )
          in
            (sigIdPath, TC.injectEnvToContext Env, TCC.TPMSIGID sigName)
          end
        | PT.PTSIGWHERE(ptsigexp, stringListLongTyConTyList, loc) =>
          (*rule 64*)
          let 
            val (sigPath, context1, sigspecs) = typeinfSigexp cc ptsigexp
            val cc1 = TIC.injectContextToCurrentContext context1
            val (tyConSubst, pathTyFunInfoList) =
                List.foldr
                    (fn ((typarams, longTyCon, ty), (tyConIdEnv, pathTyFunInfoList)) =>
                        let
                          val tyFunName = Absyn.getLastIdOfLongid longTyCon
                          val (_, newTyFun) = TIFC.makeTyFun T.toplevelDepth cc (typarams, tyFunName, ty)
                          val (tyConStrPath, tyConId) =
                              case TIC.lookupLongTyCon (cc1, longTyCon) of
                                (_, NONE) => 
                                raise E.TyConNotFoundInWhereType
                                          {tyCon = Absyn.longidToString(longTyCon)}
                              | ((tyConStrPath,_), SOME (T.TYCON {name,id,eqKind,tyvars,...})) => 
                                if  TU.isTyNameOfTyFun(newTyFun) then
                                  if (!eqKind = T.EQ) andalso
                                     not (TU.admitEqTyFun newTyFun)
                                  then 
                                    raise E.EqtypeRequiredInWhereType {
                                                                       longTyCon = 
                                                                       Absyn.longidToString(longTyCon)
                                                                       }
                                  else
                                    if List.length tyvars <> List.length typarams
                                    then
                                      raise E.ArityMismatchInWhereType 
                                              {
                                               wants = List.length tyvars,
                                               given = List.length typarams,
                                               tyCon = Absyn.longidToString(longTyCon)
                                               }
                                    else
                                      (tyConStrPath,id)
                                else
                                  raise E.DatatypeNotWellFormed {
                                                                 longTyCon = 
                                                                 Absyn.longidToString(longTyCon)
                                                                 }
                              | (_, SOME (T.TYFUN tyFun)) => 
                                raise E.DataConWithWhereType 
                                        {longTyCon = Absyn.longidToString(longTyCon)}
                              | ((tyConStrPath,_), 
                                 SOME(T.TYSPEC 
                                        {spec = {name, id, strpath, eqKind, tyvars, boxedKind},
                                         ...}
                                        )
                                 ) => 
                                if TU.isNotGenericBoxedKind boxedKind then
                                    raise E.KindConstranintOnAbstractTypeSpecification
                                              {tyConName = name, kind = boxedKind}
                                else
                                    if (eqKind = T.EQ) andalso
                                       not (TU.admitEqTyFun newTyFun)
                                    then 
                                        raise E.EqtypeRequiredInWhereType {
                                                                           longTyCon = 
                                                                           Absyn.longidToString(longTyCon)
                                                                           }
                                    else
                                        if List.length tyvars <> List.length typarams
                                        then
                                    raise E.ArityMismatchInWhereType 
                                              {
                                               wants = List.length tyvars,
                                               given = List.length typarams,
                                               tyCon = Absyn.longidToString(longTyCon)
                                               }
                                        else
                                            (tyConStrPath,id)
                        in
                          (ID.Map.insert(tyConIdEnv, tyConId, T.TYFUN newTyFun),
                           (tyConStrPath, newTyFun)::pathTyFunInfoList)
                        end
                            handle 
                            exn as E.TyConNotFoundInWhereType _ => 
                            (E.enqueueError (loc, exn);
                             (tyConIdEnv, pathTyFunInfoList))
                          | exn as E.DataConWithWhereType _ =>
                            (E.enqueueError (loc, exn);
                             (tyConIdEnv, pathTyFunInfoList))
                          | exn as E.EqtypeRequiredInWhereType _ => 
                            (E.enqueueError (loc, exn);
                             (tyConIdEnv, pathTyFunInfoList))
                          | exn as E.DatatypeNotWellFormed _ => 
                            (E.enqueueError (loc, exn);
                             (tyConIdEnv, pathTyFunInfoList))
                          | exn as E.ArityMismatchInWhereType _ => 
                            (E.enqueueError (loc, exn);
                             (tyConIdEnv, pathTyFunInfoList))
                          | exn as E.KindConstranintOnAbstractTypeSpecification _ =>
                            (E.enqueueError (loc, exn);
                             (tyConIdEnv, pathTyFunInfoList))
                      )
                    (ID.Map.empty, nil)
                    stringListLongTyConTyList
            val context2 = TCU.substTyConInContext tyConSubst context1
          in 
            (sigPath, context2, TCC.TPMSIGWHERE (sigspecs, pathTyFunInfoList))
          end

    (**
     * infer a type for top-level signature
     * @params currentContext ptsigexp
     * @return  an signature semantic object and tpmstrexp
     *)
    and typeinfSig (cc : TIC.currentContext) ptsigexp =
        (*rule 65*)
        let
          val fromTyConId = T.nextTyConId()
          val (sigIdPath, context : TC.context, sigspec) = 
                typeinfSigexp cc ptsigexp
          val E = TC.getStructureEnvFromContext context
          val T = TIU.tyConIdSetEnv fromTyConId E
        in
          (sigIdPath,(T, E), sigspec)
        end

    (*
     * infer a type for structure exp
       (struct ... end etc)
     * @params currentContext ptstrexp
     * @return strpath: represents the freshly introduced structure identifier,
     *                  it is used to update the strpath field 
     *         constrained context : a (constrained) structure environment 
     *         unconstrained context : unconstrained structure environment.
     *                                 used for functor body instantiation
     *         structure epxression  : tpmstrexp
     *)
    and typeinfStrexp (cc : TIC.currentContext) ptstrexp =
        case ptstrexp of
            PT.PTSTREXPBASIC(ptstrdecs, loc) => 
            (* rule 50 *)
            let
              val (context, tpstrdecs) = 
                  typeinfStrDecs cc ptstrdecs
            in
              (P.NilPath, context, context, TCC.TPMSTRUCT (tpstrdecs,loc))
            end
          | PT.PTSTRID(longStrid, loc) => 
            (* rule 51*)
            let
              val (absolutePath, relativePath, E) = 
                  case TIC.lookupLongStructureEnv  (cc, longStrid) of
                    (path, SOME (strPathInfo as {id,name,strpath,env})) => 
                    (P.appendPath(strpath,id,name), path, env)
                  | (path, NONE) =>
                    (
                     E.enqueueError
                       (loc, E.StructureNotFound({id = Absyn.longidToString(longStrid)}));
                       (P.NilPath, path, T.emptyE)
                    )
              val context1 = TC.injectEnvToContext E
              val {id, name} = 
                  case absolutePath of 
                    P.NilPath => {id = T.dummyStructureId, name = "?X"}
                  | _ => P.getLastElementOfPath absolutePath
            in
              (
               absolutePath,
               context1,
               context1,
               TCC.TPMLONGSTRID ({
                              id = id, 
                              name = name, 
                              strpath = P.getParentPath relativePath, 
                              env = E},
                             loc)
               )
            end
          | PT.PTSTRTRANCONSTRAINT(ptstrexp, ptsigexp, loc) => 
            (* rule 52 *)
            let
              val (stridStrpath, context1, unConstrainedContext, tpmodexp) =
                    typeinfStrexp cc ptstrexp
              val Env = TC.getStructureEnvFromContext context1
              val (sigIdPath, sigma, tpmsigexp) = 
                  typeinfSig cc ptsigexp
                  (* typeinfSig (TIC.updateStrLevel (cc, P.NilPath)) ptsigexp *)
              val strictEnv = 
                    ( 
                     SigCheck.transparentSigMatch (Env, sigma)
                     handle exn => (SU.handleException (exn,loc); T.emptyE)
                    )
              val strictEnv = updateStrpathInEnv (sigIdPath, #strLevel cc, strictEnv)
              val context2 = TC.injectEnvToContext strictEnv
              (* below deal with type instantiated structure *)
              val newTpmodexp =
                  case TIU.stripSignature(tpmodexp) of
                    TCC.TPMSTRUCT (
                                   (
                                    (h as TCC.TPMCOREDEC (
                                                          [TCC.TPOPEN ([{id, name, strpath, env}], loc1)], 
                                                          loc2
                                                          ))
                                    :: tpmstrdecls,
                                    loc
                                    )
                               ) =>
                    let
	                val pathPrefix = Path.appendPath (strpath, id, name)
                        val newTpmstrdecls =
                            TIT.generateInstantiatedStructure (pathPrefix,loc1) (env,strictEnv)
                    in
                      TCC.TPMSTRUCT ((h :: newTpmstrdecls),loc)
                    end
                  | _ => 
                    raise Control.Bug 
                              ("only basic structure expression  " ^
                               "can be constrained by signature")
            in
              (stridStrpath, 
               context2, 
               unConstrainedContext,
               TCC.TPMTRANCONS (newTpmodexp, tpmsigexp, strictEnv, loc))
            end
          
          | PT.PTSTROPAQCONSTRAINT(ptstrexp, ptsigexp, loc) => 
            (* rule 53 *)
            let
              val (stridStrpath, context1, unConstrainedContext, tpmodexp) = 
                  typeinfStrexp cc  ptstrexp
              val Env = TC.getStructureEnvFromContext context1
              val (sigIdPath, sigma, tpmsigexp) =
                  (* typeinfSig (TIC.updateStrLevel (cc, P.NilPath)) ptsigexp *)
                  typeinfSig cc ptsigexp
              val (abstractEnv, enrichedEnv) = 
                  (
                   SigCheck.opaqueSigMatch (Env, sigma)
                   handle exn => (SU.handleException (exn,loc);(T.emptyE,T.emptyE)))
              val abstractEnv  = 
                  updateStrpathInEnv (sigIdPath, #strLevel cc, abstractEnv)
              val context2 = TC.injectEnvToContext abstractEnv
              val newTpmodexp =
                  case TIU.stripSignature(tpmodexp) of
                    TCC.TPMSTRUCT (
                                   (
                                    (h as TCC.TPMCOREDEC (
                                                          [TCC.TPOPEN ([{id, name, strpath, env}], loc1)], 
                                                          loc2
                                                          ))
                                    :: tpmstrdecls,
                                    loc
                                    )
                                   ) =>
                    let
                        val pathPrefix = Path.appendPath (strpath, id, name)
                        val newTpmstrdecls =
                            TIT.generateInstantiatedStructure (pathPrefix,loc1) (env,enrichedEnv)
                    in
                      TCC.TPMSTRUCT ((h :: newTpmstrdecls),loc)
                    end
                  | _ => 
                    raise Control.Bug 
                            ("only basic structure expression  " ^
                             "can be constrained by signature")
            in
              (stridStrpath, 
               context2, 
               unConstrainedContext,
               TCC.TPMOPAQCONS (newTpmodexp, tpmsigexp, abstractEnv, loc)
              )
            end
          | PT.PTFUNCTORAPP (functorName,ptstrexp,loc) =>
            (* rule 54 *)
            let
              val funBindInfo as 
                              { func = {name = functorName, id = functorID},
                                argument = {name = strArgName ,id = strArgID},
                                functorSig 
                                }
                  = 
                  case TIC.lookupFunctor (cc,functorName) of
                    SOME bindinfo => bindinfo
                  | NONE =>
                    (
                     E.enqueueError (loc, E.FunctorNotFound{id = functorName});
                     { func = {name = functorName, id = T.newStructureId()},
                       argument = {name = "X?",id = T.newStructureId()},
                       functorSig = {
                                     exnTagSet = ISet.empty,
                                     tyConIdSet = ID.Set.empty,
                                     func = {
                                             arg = T.emptyE, 
                                             body = {
                                                     constrained = (ID.Set.empty,T.emptyE),
                                                     unConstrained = T.emptyE
                                                     }
                                             }
                                     }
                       }:T.funBindInfo               
                     )
              val (newcc,anonyStrPath) = 
                  if TIU.isAnonymousStrExp ptstrexp then
                    let
                      val anonyStrPath = 
                          P.appendPath(#strLevel cc,
                                       T.newStructureId (),
                                       TIU.NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER
                                       )
                    in
                      (TIC.updateStrLevel (cc, anonyStrPath), anonyStrPath)
                    end
                  else
                    (TIC.updateStrLevel (cc, P.NilPath),P.NilPath)
              val (argStrIdPath, context1, _ , tpmodexp) = 
                  typeinfStrexp newcc ptstrexp
              val Env = TC.getStructureEnvFromContext context1
                        
              val (resEnv, argMatchedEnv, instTyConSubstInBody, exnTagSubst) =
                  let
                    val defaultErrorValue = 
                        (T.emptyE,T.emptyE,ID.Map.empty,IEnv.empty)
                  in
                    ( 
                     SigCheck.functorSigMatch(Env, functorSig)
                     handle exn => (SU.handleException (exn,loc); defaultErrorValue))
                  end
              val instTyConSubst = 
                  ID.Map.unionWith 
                      #1 (SU.substTyEnvFromEnv (#arg (#func(#functorSig(funBindInfo))),
                                                Env),
                          instTyConSubstInBody)
              val context2 = TC.injectEnvToContext resEnv
              (***** below deal with type instantiation environment *****)

              val instantiatedStrExp =
                  let
                      val pathPrefix = 
                          Path.appendPath 
                              (Path.NilPath, 
                               Path.localizedConstrainedStrID, 
                               Path.localizedConstrainedStrName)
                  in
                      TCC.TPMSTRUCT 
                          (
                           (TCC.TPMCOREDEC
                                ([TCC.TPOPEN 
                                      ([{id = Path.localizedConstrainedStrID,
                                         name = Path.localizedConstrainedStrName,
                                         strpath = Path.NilPath, 
                                         env = Env}], 
                                       loc)
                                      ],
                                 loc
                                 )
                                )
                           :: (TIT.generateInstantiatedStructure 
                                   (pathPrefix,loc)
                                   (Env, argMatchedEnv)
                                   ),
                           loc)
                  end
              val strInfo = 
                  {id = Path.localizedConstrainedStrID,
                   name = Path.localizedConstrainedStrName,
                   env = argMatchedEnv}:TCC.strInfo
              val newTpmodexp = 
                  TCC.TPMLET
                    (
                     [TCC.TPMSTRBIND ([(strInfo, tpmodexp)],loc)], 
                     instantiatedStrExp, 
                     loc)
              (*val argInstEnv = TIT.generateInstEnvOnStructure (Env, argMatchedEnv)*)
            in
              (
               P.PStructure(functorID,functorName,P.NilPath),
               context2, 
               context2,
               TCC.TPMFUNCTORAPP(funBindInfo,
                                 {
                                  strArg = newTpmodexp,
                                  env = Env
                                  },
                             exnTagSubst,
                             instTyConSubst,
                             anonyStrPath,
                             loc
                            )
               )
            end
          | PT.PTSTRUCTLET(ptstrdecs, ptletstrexp, loc) => 
            (* rule 55 *)
            let
              val (context1: TC.context, tpmstrdecs) = typeinfStrDecs cc ptstrdecs
              val newcc = TIC.extendCurrentContextWithContext (cc, context1)
              val (stridStrpath, constrainedContext2, unConstrainedContext2, tpmstrexp) = 
                  typeinfStrexp newcc ptletstrexp
            in
              (
               stridStrpath, 
               constrainedContext2,
               unConstrainedContext2,
               TCC.TPMLET(tpmstrdecs, tpmstrexp, loc)
               )
            end


    (*
     * for structure bind (structure A = <structure exp>
     *)
    and typeinfStrbind (cc : TIC.currentContext)  (strName, ptstrexp) =
        let
            val strID = 
                if strName = Path.localizedConstrainedStrName then
                  Path.localizedConstrainedStrID
                else
                  T.newStructureId ()
            val newcc =
                TIC.updateStrLevel
                    (cc, P.appendPath (#strLevel cc, strID, strName))
            val (stridStrpath, context1, _, tpmstrexp) = 
                typeinfStrexp newcc  ptstrexp
            val E = TC.getStructureEnvFromContext context1
            val newE = updateStrpathInEnv(stridStrpath, #strLevel newcc, E)
            val strInfo = {id = strID, name = strName, env = newE}
            val strPathInfo =
                {id = strID, name = strName, strpath = #strLevel cc, env = newE}
            val context2 = TC.bindStrInEmptyContext(strName, strPathInfo)
        in
          (
           context2,
           (strInfo, tpmstrexp)
           )
        end

    and typeinfStrbinds (cc : TIC.currentContext) nil = (TC.emptyContext, nil)
      | typeinfStrbinds  (cc : TIC.currentContext) (ptstrbind :: rest) = 
        (* rule 61 *)
        let
          val (context1 : TC.context, tpstrbind) = typeinfStrbind cc ptstrbind
          val (context2, tpstrbinds) = typeinfStrbinds cc rest
        in
          (TC.extendContextWithContext{newContext = context2, oldContext = context1}, 
           tpstrbind :: tpstrbinds)
        end
    (**
     * infer a type for each component declaration in structure exp
       (val x = 1 etc)
     * @params currentContext toplevelflag ptstrdecl
     * @return  an structure Environment and tpmstrdecl
     *)
    and typeinfStrDec (cc : TIC.currentContext) ptstrdec =
        case ptstrdec of
          PT.PTCOREDEC(pdecl, loc) => 
          (* rule 56 *)
          let
            (*
              Ohori: lambdaDepth parameter is added.
                val (context, tdecl) = TIFC.typeinfTopPtdecl cc pdecl
             *)
            val (context, tdecl) = TIFC.typeinfTopPtdecl T.toplevelDepth cc pdecl
          in
            (context, TCC.TPMCOREDEC(tdecl, loc))
          end
        | PT.PTSTRUCTBIND(ptstrbinds, loc) =>
          (* rule 57 *)
          let
            val (context, tlstrbinds) = typeinfStrbinds cc ptstrbinds
          in
            (context, TCC.TPMSTRBIND(tlstrbinds, loc) )
          end
        | PT.PTSTRUCTLOCAL(ptstrdecs1, ptstrdecs2, loc) =>
          (* rule 58 *)
          let
            val (context1, tlstrdecs1) = typeinfStrDecs cc ptstrdecs1
            val newcc = TIC.extendCurrentContextWithContext(cc,context1)
            val (context2, tlstrdecs2) = typeinfStrDecs newcc ptstrdecs2
          in
            (context2, TCC.TPMLOCALDEC(tlstrdecs1, tlstrdecs2, loc))
          end

    and typeinfStrDecs (cc : TIC.currentContext) nil = (TC.emptyContext, nil)
      | typeinfStrDecs (cc : TIC.currentContext) (ptstrdec :: rest) =
        let
          val (context1, tpstrdec) = typeinfStrDec cc ptstrdec 
          val newcc = TIC.extendCurrentContextWithContext(cc, context1)
          val (context2, tpstrdecs) = typeinfStrDecs newcc rest
        in
          (
           TC.extendContextWithContext {newContext = context2, oldContext = context1},
           tpstrdec :: tpstrdecs
          )
        end

    (*
     * for signature binds (signature A = <signature exp>
     *)
    and typeinfSigbinds cc nil  = (TC.emptyContext, nil)
      | typeinfSigbinds cc ((sigName, ptsigexp) :: rem)  =
        (*rule 67*)
        let
            val sigID = T.newStructureId ()
            val newcc =
                TIC.updateStrLevel
                    (cc, P.appendPath (#strLevel cc, sigID, sigName))
            val (_,(tyConIdSet, E), sigspec1) = typeinfSig newcc ptsigexp
            val sigBindInfo1 =
                T.SIGNATURE
                (
                  tyConIdSet,
                  {name = sigName, id = sigID, strpath = #strLevel cc, env = E}
                )
            val context1 =
                TC.bindSigInEmptyContext(sigName, sigBindInfo1)
            val (context2, sigspec2) = typeinfSigbinds cc rem 
        in
            (TC.extendContextWithContext
                 {newContext=context2, oldContext=context1}, 
             (sigBindInfo1, sigspec1) :: sigspec2)
        end
    (*
     * for functor binds (functor foo = <structure exp>)
     *)
    and typeinfFunbinds cc nil = (TC.emptyContext, nil)
      | typeinfFunbinds cc (ptfunbind as (funName,strName,ptsigexp,ptstrexp,loc) :: rem) =
        (* rule 86 *)
        let
          val functorID = T.newStructureId ()
          val newcc1 = TIC.updateStrLevel
                         (cc, P.appendPath (#strLevel cc, functorID,funName))
          val strID = T.newStructureId ()
          val strPath = P.appendPath (#strLevel newcc1, strID,strName)
          val newcc2 = TIC.updateStrLevel (newcc1, strPath)
          val (sigIdPath, sigma as (T,E), tpsigexp) = typeinfSig newcc2  ptsigexp
          val sigmaE = 
              updateStrpathInEnv (sigIdPath, strPath, E)
          val strPathInfo =
              {id = strID, name = strName, strpath = P.NilPath, env = sigmaE}
          val newcc3 = TIC.bindStrInCurrentContext(newcc1,strName, strPathInfo)
          val newptstrexp = SL.localizeToLetStrexp ptstrexp loc
          val fromTyConId = T.nextTyConId ()
          val fromExnTag = T.nextExnTag ()
          val (_, context1, unConstrainedContext, tpmodexp) = 
              typeinfStrexp newcc3 newptstrexp
          val unConstrainedEnv = TC.getStructureEnvFromContext unConstrainedContext
          val E' = TC.getStructureEnvFromContext context1
          val T' = TIU.tyConIdSetEnv fromTyConId E'
          val exnTagSet = SU.exnTagSetEnv fromExnTag E'
          val funBindInfo = 
              {
               func={id = functorID, name = funName},
               argument = {id = strID, name = strName},
               functorSig = {
                             exnTagSet = exnTagSet,
                             tyConIdSet = T, 
                             func = {arg = sigmaE, 
                                     body = {
                                             constrained = (T',E'),
                                             unConstrained = unConstrainedEnv
                                             }
                                     }
                             }
               }
          val context2 = TC.bindFunInEmptyContext (funName,funBindInfo)
          val (context3,tpmfunbinds) = typeinfFunbinds cc rem
        in
          (
           TC.extendContextWithContext {newContext = context3, oldContext = context2},
           (funBindInfo,strName,tpsigexp,tpmodexp) :: tpmfunbinds
           )
        end
            
    (**
     * infer a type for top level decs
     * @params currentContext pttopdeclList
     * @return  an Environment and tptopdeclList
     *)
    fun typeinfPttopdeclList (cc:TIC.currentContext) nil = (TC.emptyContext, nil)
      | typeinfPttopdeclList (cc : TIC.currentContext) (pltopdec :: rest) =
      let
        val (newContext, topbinds) =
            case pltopdec of
              PT.PTTOPDECSTR(ptstrdec, loc) =>
              (* rule 87 *)
              let
                val newPtstrdec = SL.localizePtstrdec ptstrdec
                val (context1 as {varEnv,...}: TC.context, tlstrdec) = 
                    typeinfStrDec cc newPtstrdec
                val newcc = TIC.extendCurrentContextWithContext(cc, context1)
                val (context2, tptopbinds) = typeinfPttopdeclList newcc rest
                val context3 = TC.extendContextWithContext {newContext=context2, oldContext=context1}
              in
                (context3, (TCC.TPMDECSTR (tlstrdec, loc)) :: tptopbinds)
              end
            | PT.PTTOPDECSIG(ptsigdecs, loc) =>
              (* rule 88 *)
              let
                val (context1 :TC.context, sigspecs) = typeinfSigbinds cc ptsigdecs
                val newcc = TIC.extendCurrentContextWithContext(cc, context1)
                val (context2, tptopbinds) = typeinfPttopdeclList newcc rest
                val context3 = TC.extendContextWithContext {newContext=context2, oldContext= context1}
              in
                (context3, TCC.TPMDECSIG (sigspecs, loc) :: tptopbinds)
              end
            | PT.PTTOPDECFUN(ptfunbinds,loc) =>
              (* rule 89 *)
              let
                val (context1, tpfunbinds) = typeinfFunbinds cc ptfunbinds
                val newcc = TIC.extendCurrentContextWithContext(cc, context1)
                val (context2, tptopbinds) = typeinfPttopdeclList newcc rest
                val context3 = TC.extendContextWithContext {newContext=context2, oldContext= context1}
              in
                (context3, TCC.TPMDECFUN (tpfunbinds, loc) :: tptopbinds)
              end
            | PT.PTTOPDECIMPORT _ => raise Control.Bug "import occurs at separate compilation"
            | PT.PTTOPDECEXPORT _ => raise Control.Bug "export occurs at separate compilation"
            
      in
        (newContext, topbinds)
      end

    fun typeinfPttopdeclListLinkageUnit (cc : TIC.currentContext) pltopdecs =
        let
            fun typeInfPttopdecListImpl cc nil =
                ((ID.Set.empty, STE.emptyImportTypeEnv, STE.emptyExportTypeEnv), nil)
              | typeInfPttopdecListImpl cc (pltopdec :: rest) =
                case pltopdec of
                    PT.PTTOPDECIMPORT(ptspec, loc) =>
                    let
                        val fromTyConId = T.nextTyConId()
                        val (context1, tpImSpecs) = typeinfSpec cc ptspec
                        val importTypeEnv1 = STE.contextToTypeEnv context1
                        val importTyConIdSet1 =
                            TIU.tyConIdSetTypeEnv fromTyConId importTypeEnv1
                        val newcc = TIC.extendCurrentContextWithContext (cc, context1)
                        val ((importTyConIdSet2, importTypeEnv2, exportTypeEnv2), tptopbinds) =
                            typeInfPttopdecListImpl newcc rest
                        val importTypeEnv3 = STE.extendImportTypeEnvWithImportTypeEnv
                                                 { newImportTypeEnv = importTypeEnv2,
                                                   oldImportTypeEnv = importTypeEnv1}
                                                 handle TC.exDuplicateElem id => 
                                                        (E.enqueueError(loc,
                                                                        E.DuplicateSpecification{id = id});
                                                         STE.emptyTypeEnv)
                        val importTyConIdSet3 =
                            ID.Set.union (importTyConIdSet1, importTyConIdSet2)
                    in
                        ( (importTyConIdSet3, importTypeEnv3, exportTypeEnv2),
                          TCC.TPMDECIMPORT(tpImSpecs,TC.extractEnvFromContext context1, loc) 
                          :: tptopbinds
                          )
                    end
                  | _ =>
                    let
                        val (context1, tptopbinds1) = typeinfPttopdeclList cc [pltopdec]
                        val exportTypeEnv1 = 
                            STE.injectContextIntoEmptyExportTypeEnv context1
                        val newcc = TIC.extendCurrentContextWithContext(cc, context1)
                        val ((importTyConIdSet2, importTypeEnv2, exportTypeEnv2), tptopbinds2) =
                            typeInfPttopdecListImpl newcc rest
                        val exportTypeEnv3 = 
                            STE.extendExportTypeEnvWithExportTypeEnv
                                { newExportTypeEnv = exportTypeEnv2,
                                  oldExportTypeEnv = exportTypeEnv1}
                    in
                        ((importTyConIdSet2, importTypeEnv2, exportTypeEnv3), tptopbinds1 @ tptopbinds2)
                    end
            val fromExnTag = T.nextExnTag()
            val ((importTyConIdSet, importTypeEnv, exportTypeEnv), tptopbinds) =
                typeInfPttopdecListImpl cc pltopdecs
            val toExnTag = T.nextExnTag()
            val staticTypeEnv = 
                {importTyConIdSet = importTyConIdSet,
                 importTypeEnv = importTypeEnv,
                 exportTypeEnv = exportTypeEnv,
                 generativeExnTagSet = TIU.computeGenerativeExnTag(fromExnTag, toExnTag, importTypeEnv)}
        in
            (staticTypeEnv:STE.staticTypeEnv, tptopbinds)
        end

    fun typeinfPttopdeclInterface (cc : TIC.currentContext) nil = 
        (ID.Set.empty, StaticTypeEnv.emptyTypeEnv)
      | typeinfPttopdeclInterface (cc : TIC.currentContext) [PT.PTTOPDECEXPORT(ptspec, loc)] = 
        let
            val fromTyConId = T.nextTyConId()
            val (context1, tpImSpecs) = typeinfSpec cc ptspec
            val exportTypeEnv = STE.contextToTypeEnv context1
            val exportTyConIdSet =
                TIU.tyConIdSetTypeEnv fromTyConId exportTypeEnv
        in
            (exportTyConIdSet, exportTypeEnv)
        end
      | typeinfPttopdeclInterface _ _  = raise Control.Bug "export interface contains other constructs"

end
end

