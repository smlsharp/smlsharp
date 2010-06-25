(**
 * utility functions for manupilating types (needs re-writing).
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: TypesUtils.sml,v 1.35.6.3 2009/10/10 07:05:41 katsu Exp $
 *)
(*
TODO:
  1.  ***compTy in RecordCompile.sml loop bug**** the fix is temporary
*)
structure TypesUtils =
struct

  local 
    structure T = Types 
  in

  exception ExSpecTyCon of string
  exception ExIllegalTyFunToTyCon of string
  exception CoerceFun 
  exception CoerceRecKindToEQ 

  fun derefSubstTy (T.TYVARty(ref (T.SUBSTITUTED ty))) = derefSubstTy ty
    | derefSubstTy ty = ty

  fun derefTy (T.TYVARty(ref (T.SUBSTITUTED ty))) = derefTy ty
    | derefTy (T.ALIASty (ty1, ty2)) = derefTy ty2
    | derefTy ty = ty

  fun pruneTy ty = 
      case ty of
        T.TYVARty (ref(T.SUBSTITUTED ty)) => pruneTy ty
      | T.ALIASty (ty1, ty2) => pruneTy ty2
      | T.POLYty {boundtvars, body = T.TYVARty(ref(T.SUBSTITUTED ty))} =>
        pruneTy (T.POLYty {boundtvars = boundtvars, body = ty})
      | _ => ty

  local
    exception NotAdmitEq
  in
  fun admitEqTy ty =
      (TypeTransducer.foldTyPreOrder
         (fn (ty, _) =>
             case ty of
               T.ALIASty (ty1,ty2) => (admitEqTy ty2,false)
             | T.FUNMty _ => raise NotAdmitEq
             | T.RAWty {tyCon = {name = "ref",...},...} =>
               (true,false)
             | T.RAWty {tyCon = {name = "array",...},...} =>
               (true,false)
             | T.RAWty {tyCon = {eqKind = ref T.NONEQ, ...}, ...} =>
               raise NotAdmitEq
             | T.OPAQUEty
                 {spec = {tyCon = {eqKind = ref T.NONEQ, ...},...}, ...} => 
               raise NotAdmitEq
             | T.SPECty {tyCon = {eqKind = ref T.NONEQ, ...}, ...} => 
               raise NotAdmitEq
             | T.TYVARty
                 (ref(T.TVAR {eqKind = T.NONEQ, ...})) => raise NotAdmitEq
             | _ => (true, true))
         true
         ty)
      handle NotAdmitEq => false
  end

  fun admitEqTyFun {name, strpath, tyargs, body} = admitEqTy body

  fun admitEqTyBindInfo tyBindInfo =
      case tyBindInfo of
          T.TYSPEC {eqKind = ref T.EQ, ...} => true
        | T.TYCON {tyCon = {eqKind = ref T.EQ,...}, ...} => true
        | T.TYFUN tyFun => admitEqTyFun tyFun
        | T.TYOPAQUE {spec = {eqKind = ref T.EQ,...}, ...}=> true
        | _ => false

  (*
   * Returns a new generative type constructor. 
   *)
  fun newTyCon
        globalID
        {name, strpath, abstract, tyvars, eqKind, constructorHasArgFlagList} = 
      {
       name = name,
       strpath = strpath,
       abstract = abstract,
       tyvars = tyvars, 
       eqKind = eqKind,
       constructorHasArgFlagList = constructorHasArgFlagList,
       id = globalID
       } : T.tyCon


  fun extractAliasTyImpl aliasTy =
      case aliasTy of
        T.ALIASty(_,ty) => extractAliasTyImpl ty
      | ty => ty
      
(*
  fun tyconSpan ({datacon, ...}:T.tyCon) = SEnv.numItems datacon
*)

(*
  fun typeOfIdstate idstate =
      case idstate of
        T.CONID conPathInfo => #ty conPathInfo
      | T.EXNID exnPathInfo => #ty exnPathInfo
      | T.OPRIM oprimInfo => #ty oprimInfo
      | T.PRIM primInfo => #ty primInfo
      | T.VARID varPathInfo => #ty varPathInfo
      | T.RECFUNID (varPathInfo, int) => #ty varPathInfo
*)

  (**
   * Substitute bound type variables in a type.
   * only the monomorphic potion of the target contain the bound type
   * variables to be substituted.
   * @params subst type 
   * @param subst substitution. The domain is an integer interval.
   * @return
   *)
  fun applyMatch subst ty =
      if IEnv.isEmpty subst
      then ty
      else 
        TypeTransducer.mapTyPreOrder
            (fn (ty as T.BOUNDVARty n) =>
                ((valOf (IEnv.find(subst, n))) handle Option => ty, true)
              | (ty as T.POLYty _) => (ty, false)
              | ty => (ty, true))
            ty

  (**
   * Substitute bound type variables in a type.
   *
   * @params subst type
   * @param subst substitution. The domain is an integer interval.
   * @return
   *)
  fun substBTvar subst ty =
      let
        (* traverse the ty with a stack of substitution.
         * The stack is pushed/popped on enter/exit in POLYty.
         *)
  fun preVisitor (ty, nil) = 
      raise Control.Bug 
              "nil stack to preVistor (types/main/TypesUtils.sml)"
    | preVisitor (ty, substs as (subst :: _)) =
      case ty of
        T.POLYty{boundtvars, body} =>
        let
          (* make a new subst by addin boundtvars,
           * and push it on the subst stack. *)
           val newSubst = 
               IEnv.foldli
                 (fn (i, _, s) => #1 (IEnv.remove(s, i))
                     handle LibBase.NotFound => s)
                 subst
                 boundtvars
        in
          if IEnv.isEmpty newSubst
          then
            (* no traverse into the body. *)
              (ty, newSubst :: substs, false)
          else
            let
              val newBoundtvars =
                  IEnv.map (substBTvarBTKind newSubst) boundtvars
            in
              (
               T.POLYty{boundtvars = newBoundtvars, body = body},
               newSubst :: substs,
               true
              )
            end
        end
      | ty => (ty, substs, true)

        (* pop a newSubst pushed by preVisitor from the substs stack. *)
        fun postVisitor (ty, nil) = 
             raise 
               Control.Bug 
               "nil stack to postVistor (types/main/TypesUtils.sml)"
          | postVisitor (ty, substs as (subst :: _)) =
            case ty of
              T.POLYty _ => (ty, tl substs)
            | (ty as T.BOUNDVARty n) =>
              let
                val newTy =
                    case IEnv.find(subst, n) of SOME ty' => ty' | _ => ty
              in (newTy, substs) end
            | _ => (ty, substs)

      in
        if IEnv.isEmpty subst
        then ty
        else
          let
            val newTy =
              case TypeTransducer.transTy preVisitor postVisitor [subst] ty of
                (newTy, [_]) => newTy
              | (_, _) => 
                raise 
                  Control.Bug 
                    "non singleton returned by\
                    \ TypeTransducer.transTy (types/main/TypesUtils.sml)"
(*
val _ = print ("#substs = " ^ (Int.toString(List.length substs)) ^ "\n")
*)
          in
            newTy
          end
      end

  (**
   * Substitute de Bruijn type variables in a Kind.
   *)
  and substBTvarRecKind subst recordKind =
      case recordKind of
        T.REC fields => T.REC (SEnv.map (substBTvar subst) fields)
      | T.UNIV => T.UNIV
      | T.OCONSTkind l => 
        T.OCONSTkind (map (substBTvar subst) l)
      | T.OPRIMkind {instances, operators} =>
        T.OPRIMkind 
          {instances = map (substBTvar subst) instances,
           operators =
           map
              (fn {oprimId, oprimPolyTy, name, keyTyList, instTyList} =>
                  {oprimId = oprimId,
                   oprimPolyTy = oprimPolyTy, (* closed *)
                   name = name,
                   keyTyList = map (substBTvar subst) keyTyList,
                   instTyList = map (substBTvar subst) instTyList}
              )
              operators
          }

  and substBTvarBTKind subst {recordKind, eqKind} =
      {
        recordKind = substBTvarRecKind subst recordKind,
        eqKind = eqKind
      }

  (**
   * Substitute bound type variables in a type Environment
   * this is for boundtyvars in POLYtype only.
   * bound type variables do not occur in a free type variable context.
   *)
  fun substBTvEnv subst tvEnv = IEnv.map (substBTvarBTKind subst) tvEnv

  (**
   * Perform imperative implace substitutrion.
   *)
  fun performSubst (T.TYVARty (r as ref(T.TVAR _)), ty) = r := T.SUBSTITUTED ty
    | performSubst _ =
      raise Control.Bug "non TVAR in performSubst (types/mainTypesUtils.sml)"

  (**
   * Make a fresh copy of a bound type environment by allocating a new btvid
   * @params  boundEnv
   * @return subst bound type variable substitution
   *)
  fun copyBoundEnv boundEnv = 
      let
        val newSubst =
            IEnv.map
              (fn _  => 
                  let
                    val newBoundVarId = BoundTypeVarID.generate ()
                  in 
                    T.BOUNDVARty newBoundVarId
                  end)
              boundEnv
        val newBoundEnv =
            IEnv.foldri
              (fn (oldId, {recordKind, eqKind}, newBoundEnv) =>
                  (case IEnv.find(newSubst, oldId) of
                     SOME (T.BOUNDVARty newId) =>
                     IEnv.insert
                       (newBoundEnv, 
                        newId, 
                        {recordKind=substBTvarRecKind newSubst recordKind, 
                         eqKind=eqKind})
                   | _ => raise Control.Bug "copyBoundEnv"))
              IEnv.empty
              boundEnv
      in
        (newSubst, newBoundEnv)
      end

  (**
   * Make a fresh instance of a bound type Environment.
   *
   * ex: for {U,{a:0}}, it generate [0 <- t1, 1 <- t2] under the global type
   * variable Environment {t1:U,t2:{a:t1}}.
   *
   * @params tvEnv  subst
   * @param tvEnv a set of bound type variables of the form {0:k_0,...,i:k_i}
   * @param subst bound type variable substitution
   * @return
   *)
  fun freshSubst boundEnv = 
      let
        val newSubst =
            IEnv.map
              (fn x => 
                  let
                    val newTy = 
                        T.newty {
                        recordKind = T.UNIV,
                        eqKind = T.NONEQ,
                        tyvarName = NONE
                        }
                  in
                    newTy
                  end)
              boundEnv
        val _ =
            IEnv.appi
              (fn (i, T.TYVARty(r as ref (T.TVAR {id, tyvarName, ...}))) => 
                  r := 
                     (case IEnv.find(boundEnv, i) of
                        SOME {recordKind, eqKind} => 
                        T.TVAR
                          {
                           lambdaDepth = T.infiniteDepth,
                           id = id, 
                           recordKind = substBTvarRecKind newSubst recordKind,
                           eqKind = eqKind,
                           tyvarName = tyvarName
                          }
                      | _ => raise Control.Bug "fresh Subst")
                | _ => raise Control.Bug "freshSubst")
              newSubst
(*
        val _ =
            IEnv.appi
              (fn (i, T.TYVARty(r as ref (T.TVAR {id, tyvarName, ...}))) => 
                  r := 
                     (case IEnv.find(boundEnv, i) of
                        SOME {index, recordKind, eqKind} => 
                        (case recKind of 
                           T.REC _ =>
                           T.kindedTyvarList := r :: (!T.kindedTyvarList)
                         | T.OVERLOADED _ =>
                           T.kindedTyvarList := r :: (!T.kindedTyvarList)
                         | _ => ();
                         T.TVAR
                           {
                            lambdaDepth = T.infiniteDepth,
                            id = id, 
                            recordKind = substBTvarRecKind newSubst recordKind,
                            eqKind = eqKind,
                            tyvarName = tyvarName
                        })
                      | _ => raise Control.Bug "fresh Subst")
                | _ => raise Control.Bug "freshSubst")
              newSubst
*)
      in
        newSubst
      end


  (*
   * Make a fresh substitution for bound tvars with *named* tyvars.
   * This is used in Sigmatch
   *)
  fun freshRigidSubst  boundEnv = 
      let
          val newSubst =
              IEnv.map
                  (fn x => 
                      let
                          val newTy =
                              T.newty {
                                       recordKind = T.UNIV,
                                       eqKind = T.NONEQ,
                                       tyvarName = SOME "RIGID"
                                       } 
                      in
                          newTy 
                      end)
                  boundEnv
        val _ =
            IEnv.appi
              (fn (i,
                   T.TYVARty
                     (r as ref (T.TVAR {lambdaDepth, id, tyvarName, ...}))) => 
                    r := 
                    (case IEnv.find(boundEnv, i) of
                       SOME {recordKind, eqKind} => 
                       T.TVAR
                         {
                          lambdaDepth = lambdaDepth,
                          id = id, 
                          recordKind = substBTvarRecKind newSubst recordKind,
                          eqKind = eqKind,
                          tyvarName = tyvarName
                         }
                     | _ => raise Control.Bug "fresh Subst")
                | _ => raise Control.Bug "freshSubst")
              newSubst
(*
        val _ =
            IEnv.appi
              (fn (i,
                   T.TYVARty
                     (r as ref (T.TVAR {lambdaDepth, id, tyvarName, ...}))) => 
                  r := 
                 (case IEnv.find(boundEnv, i) of
                    SOME {index, recordKind, eqKind} => 
                    (case recKind of 
                       T.REC _ =>
                       T.kindedTyvarList := r :: (!T.kindedTyvarList)
                     | T.OVERLOADED _ =>
                       T.kindedTyvarList := r :: (!T.kindedTyvarList)
                     | _ => ();         
                     T.TVAR
                       {
                        lambdaDepth = lambdaDepth,
                        id = id, 
                        recordKind = substBTvarRecKind newSubst recordKind,
                        eqKind = eqKind,
                        tyvarName = tyvarName
                       }
                    )
                  | _ => raise Control.Bug "fresh Subst")
                | _ => raise Control.Bug "freshSubst")
              newSubst
*)
      in
          newSubst
      end


  (**
   * Complement a bound substitution with fresh instances.
   * 
   * @params subst btvenv
   *)
  fun complementBSubst BS boundEnv = 
      let
        val newSubst = 
            IEnv.foldli 
              (fn (i, ty, Env) =>
                  if IEnv.inDomain(BS, i)
                  then Env
                  else
                    let
                      val newTy =
                          T.newty
                            {
                             recordKind = T.UNIV,
                             eqKind = T.NONEQ,
                             tyvarName = NONE
                            }
                    in
                      IEnv.insert (Env, i, newTy)
                    end)
              IEnv.empty
              boundEnv
        val _ =
            IEnv.appi
              (fn (i,
                   T.TYVARty
                     (r as ref (T.TVAR {lambdaDepth, id, tyvarName, ...}))) => 
                  r := 
                     (case IEnv.find(boundEnv, i) of
                        SOME {recordKind, eqKind} => 
                        T.TVAR
                          {
                           lambdaDepth = lambdaDepth,
                           id = id, 
                           recordKind = substBTvarRecKind newSubst recordKind,
                           eqKind = eqKind,
                           tyvarName = tyvarName
                          }
                      | _ => raise Control.Bug "fresh Subst")
                | _ => raise Control.Bug "complementBSubst")
              newSubst
(* 
       val _ =
           IEnv.appi
             (fn (i,
                  T.TYVARty
                    (r as ref (T.TVAR{lambdaDepth,id,tyvarName, ...}))) => 
                 r := 
                    (case IEnv.find(boundEnv, i) of
                       SOME {index, recordKind, eqKind} => 
                       (case recKind of 
                          T.REC _ =>
                          T.kindedTyvarList := r :: (!T.kindedTyvarList)
                        | T.OVERLOADED _ =>
                          T.kindedTyvarList := r :: (!T.kindedTyvarList)
                        | _ => ();
                        T.TVAR
                          {
                           lambdaDepth = lambdaDepth,
                           id = id, 
                           recordKind = substBTvarRecKind newSubst recordKind,
                           eqKind = eqKind,
                           tyvarName = tyvarName
                       })
                     | _ => raise Control.Bug "fresh Subst")
               | _ => raise Control.Bug "complementBSubst")
             newSubst
*)
      in
        IEnv.unionWith
          (fn x => raise Control.Bug "complementBSubstSubst") (BS, newSubst)
      end

  local 
    exception FALSE 
  in

  (**
   * Check whether a type is a mono type or not.
   *)
  fun monoTy ty =
      TypeTransducer.foldTyPreOrder
          (fn (T.POLYty _, _) => raise FALSE
            | (T.BOUNDVARty _, _) => raise FALSE
            | _ => (true, true))
          true
          ty
          handle FALSE => false
  end

  (**
   * Compute the set of "effectively" free type variables of a type. 
   * See my TOPLAS paper for what "effectively" free means.
   *
   * @params ty 
   * @param ty type
   * @return tvKind ref OTSet.set

  The following is prohibitively inefficient.
  fun EFTV ty =
      TypeTransducer.foldTyPostOrder
        (fn (T.TYVARty (ref(T.TVAR {recordKind = T.OVERLOADED _,...})), set)
            => set
          | (T.TYVARty (tyvarRef as (ref(T.TVAR tvKind))), set)  => 
            let
              fun EFTVKind set =
                  case tvKind of
                    {recordKind = T.UNIV, ...} => set
                  | {recordKind = T.REC fields, ...} => 
                    SEnv.foldl
                      (fn (ty, set) => OTSet.union(set, EFTV ty))
                      set
                      fields
                  | {recordKind = T.OVERLOADED _, ...} =>
                    raise Control.Bug "EFTV Overloaded"
            in 
              OTSet.union(set, EFTVKind (OTSet.singleton tyvarRef))
            end
          | (_, set) => set
        )
        OTSet.empty
        ty;

   *)

  fun EFTV ty =
    let
      fun traverseTy (ty,set) =
        case ty of
          T.INSTCODEty {oprimId, name, oprimPolyTy, keyTyList, instTyList} =>
          foldl traverseTy set instTyList
        | T.ERRORty => set
        | T.DUMMYty int => set
        | T.TYVARty (ref(T.SUBSTITUTED ty)) => traverseTy (ty,set)
        | T.TYVARty (ref(T.TVAR {recordKind=T.OCONSTkind _,...})) => set
        | T.TYVARty (tyvarRef as (ref(T.TVAR tvKind))) => 
            if OTSet.member(set, tyvarRef) then set
            else traverseTvKind (tvKind, OTSet.add(set, tyvarRef))
        | T.BOUNDVARty int => set
        | T.FUNMty (tyList, ty) =>
          traverseTy (ty, foldl traverseTy set tyList)
        | T.RECORDty tySEnvMap => 
            SEnv.foldl (fn (ty, set) => traverseTy (ty,set)) set tySEnvMap
        | T.RAWty {tyCon, args = tyList} => foldl traverseTy set tyList
        | T.POLYty {boundtvars = btvKindIEnvMap, body=ty} =>
          traverseTy (ty,set)
        | T.ALIASty (aliasTy,realTy) =>
          traverseTy (realTy, traverseTy(aliasTy,set))
        | T.OPAQUEty {spec = {tyCon, args}, implTy} =>
          traverseTy(implTy, foldl traverseTy set args)
        | T.SPECty {tyCon, args} => foldl traverseTy set args
      and traverseTvKind (kind, set) =
            case kind of
              {recordKind = T.UNIV, ...} => set
            | {recordKind = T.REC fields, ...} => 
                SEnv.foldl traverseTy set fields
            | {recordKind = T.OCONSTkind _, ...} =>
              raise Control.Bug "OCONSTkind to travseTvKind"
            | {recordKind = T.OPRIMkind {instances, operators},...}
              =>
              foldl traverseTy set instances
    in
      traverseTy (ty, OTSet.empty)
    end

  fun EFTVInVarInfo (T.VARID {ty, ...}) = EFTV ty
    | EFTVInVarInfo (T.CONID _) = OTSet.empty (* datacon must be closed *)
    | EFTVInVarInfo (T.EXNID _) = OTSet.empty (* datacon must be closed *)
    | EFTVInVarInfo (T.PRIM _) = OTSet.empty (* primitive must be closed *)
    | EFTVInVarInfo (T.OPRIM _) =
       OTSet.empty (* overloaded primitive must be closed *)
    | EFTVInVarInfo (T.RECFUNID ({ty,...}, _)) = EFTV ty

  fun adjustDepthInTy contextDepth ty = 
    let
      val tyset = EFTV ty
    in
      OTSet.app
      (fn (tyvarRef as (ref (T.TVAR {
                                     lambdaDepth=tyvarDepth, 
                                     id, 
                                     recordKind, 
                                     eqKind, 
                                     tyvarName
                                     }))) =>
         if T.strictlyYoungerDepth(tyvarDepth, contextDepth) then
           tyvarRef := T.TVAR {
                               lambdaDepth=contextDepth, 
                               id = id, 
                               recordKind = recordKind, 
                               eqKind = eqKind, 
                               tyvarName = tyvarName
                               }
         else ()
       | _ => raise Control.Bug "non TVAR in adjustDepthInTy (TypesUtils.sml)"
      )
      tyset
    end

  fun adjustDepthInRecKind contextDepth kind = 
    case kind of
      T.UNIV => ()
    | T.REC fields => 
        SEnv.app (adjustDepthInTy contextDepth) fields
    | T.OCONSTkind tyList => 
        List.app (adjustDepthInTy contextDepth) tyList
    | T.OPRIMkind {instances = tyList,...} => 
        List.app (adjustDepthInTy contextDepth) tyList


  fun coerceReckindToEQ recKind = 
      let
        fun adjustEqKindInTy eqKind ty = 
            case eqKind of
              T.NONEQ => ()
            | T.EQ => 
              let
                val tyset = EFTV ty
              in
                OTSet.app
                  (fn (tyvarRef as (ref (T.TVAR
                                           {
                                            lambdaDepth =lambdaDepth, 
                                            id, 
                                            recordKind, 
                                            eqKind, 
                                            tyvarName
                                           }
                      )))
                      =>
                      tyvarRef := T.TVAR
                                    {
                                     lambdaDepth = lambdaDepth, 
                                     id = id, 
                                     recordKind = recordKind, 
                                     eqKind = T.EQ, 
                                     tyvarName = tyvarName
                                    }
                    | _ =>
                      raise
                        Control.Bug
                          "non TVAR in adjustDepthInTy (TypesUtils.sml)"
                  )
                  tyset
              end

        fun adjustEqKindInRecKind eqKind kind = 
            case kind of
              T.UNIV => ()
            | T.REC fields => 
              SEnv.app (adjustEqKindInTy eqKind) fields
            | T.OCONSTkind tyList =>
              List.app (adjustEqKindInTy eqKind) tyList
            | T.OPRIMkind {instances = tyList,...} =>
              List.app (adjustEqKindInTy eqKind) tyList
      in
        (adjustEqKindInRecKind T.EQ recKind;
         case recKind of
           T.UNIV => T.UNIV
         | T.REC fields => T.REC fields
         | T.OCONSTkind L =>  
           let
             val L = List.filter admitEqTy L
           in
             case L of 
               nil => raise CoerceRecKindToEQ 
             | _ =>  T.OCONSTkind L
           end
         | T.OPRIMkind {instances,operators} =>  
           let
             val instances = List.filter admitEqTy instances
           in
             case instances of 
               nil => raise CoerceRecKindToEQ 
             | _ =>  T.OPRIMkind {instances = instances, operators =operators} 
           end
        )
      end

  fun adjustDepthInVarPathInfo contextDepth {namePath, ty} = 
    adjustDepthInTy contextDepth ty;
  fun adjustDepthInConPathInfo contextDepth ({ty,...}:T.conPathInfo) = 
    adjustDepthInTy contextDepth ty
  fun adjustDepthInExnPathInfo contextDepth ({ty,...}:T.exnPathInfo) = 
    adjustDepthInTy contextDepth ty
  fun adjustDepthInPrimInfo contextDepth {prim_or_special, ty} = 
    adjustDepthInTy contextDepth ty
  fun adjustDepthInOPrimInfo _ _ = 
      raise (Control.Bug "adjustDepthInOprimInfo should never be called.")
  fun adjustDepthInVarPathInfo contextDepth {namePath, ty} =
    adjustDepthInTy contextDepth ty
  fun adjustDepthInIdstate contextDepth idState = 
    case idState of
      T.VARID varPathInfo =>
        adjustDepthInVarPathInfo contextDepth varPathInfo
    | T.CONID conPathInfo =>
        adjustDepthInConPathInfo contextDepth conPathInfo
    | T.EXNID exnPathInfo =>
        adjustDepthInExnPathInfo contextDepth exnPathInfo
    | T.PRIM primInfo =>
        adjustDepthInPrimInfo contextDepth primInfo
    | T.OPRIM oprimInfo =>
        adjustDepthInOPrimInfo contextDepth oprimInfo
    | T.RECFUNID (varPathInfo,int) =>
        adjustDepthInVarPathInfo contextDepth varPathInfo


  (*
    exception CoerceFunM
  *)
  fun coerceFunM (ty, tyList) =
      case derefTy ty of
          oldTy as T.TYVARty
                (ref (T.TVAR {lambdaDepth,
                              id,
                              recordKind = T.UNIV,
                              eqKind,
                              tyvarName = NONE})) => 
          let 
            val tyList = 
                map (fn x => 
                        let
                          val newTy = 
                              T.newty {recordKind = T.UNIV,
                                       eqKind=eqKind,
                                       tyvarName = NONE}
                          in 
                              newTy
                          end)
                      tyList
              (*
               val tyList = map (fn x => T.newty T.univKind) tyList
               *)
              val ty2 = T.newty T.univKind
              val resTy = T.FUNMty(tyList, ty2)
              val _ = adjustDepthInTy lambdaDepth resTy
              val _ = performSubst (oldTy, resTy)
          in
              (tyList, ty2, nil)
          end
        | T.TYVARty (ref (T.TVAR {tyvarName = SOME _,...})) => 
           raise CoerceFun
        | T.TYVARty (ref(T.SUBSTITUTED ty)) => 
          coerceFunM (ty, tyList)
        | T.FUNMty (tyList, ty2) => 
          (tyList, ty2, nil)
        | T.POLYty {boundtvars, body} =>
          (case derefTy body of
               T.FUNMty(tyList,ty2) =>
               let 
                   val subst1 = freshSubst boundtvars
               in
                   (
                    map (substBTvar subst1) tyList,
                    substBTvar subst1 ty2,
                    IEnv.listItems subst1
                   )
               end
             | T.ERRORty => (map (fn x => T.ERRORty) tyList, T.ERRORty, nil)
             | T.ALIASty(_, ty) => coerceFunM (ty, tyList)
             | _ => raise CoerceFun
          )
        | T.ALIASty(_, ty) => 
          coerceFunM (ty, tyList)
        | T.ERRORty => (map (fn x => T.ERRORty) tyList, T.ERRORty, nil)
        | _ => raise CoerceFun



(*
  datatype rk = ONE | ZERO | NIL

  fun mergeRank (T.ZERO, _) = T.ZERO
    | mergeRank (_, ZERO) = T.ZERO
    | mergeRank (T.NIL, T.NIL) = T.NIL
    | mergeRank _ = T.ONE
*)

(*
  fun dataTag ({displayName, tyCon = {datacon = vEnv, ...}, ...} : T.conInfo) =
      let val idlist = SEnv.listKeys vEnv
      in {id = Basics.findIndex displayName idlist, constructorHasArgFlagList}
      end
*)
      
  fun betaReduceTy ({name, strpath, tyargs, body}:T.tyFun, tyl) =
      let
        val argsBtyList = IEnv.listItemsi tyargs
      in
        if List.length argsBtyList <> List.length tyl then
          raise Control.Bug "betaReduceTy arity mismatch"
        else
          let
            val subst = 
              ListPair.foldr
              (fn ((i, _), ty, S) => IEnv.insert(S, i, ty))
              IEnv.empty
              (argsBtyList, tyl)
          in 
            substBTvar subst body
          end
      end

  fun tpappTy (ty, nil) = ty
    | tpappTy (T.TYVARty (ref (T.SUBSTITUTED ty)), tyl) =
      tpappTy (ty, tyl)
    | tpappTy (T.POLYty{boundtvars, body, ...}, tyl) = 
      let
        val subst = 
            ListPair.foldr
                (fn ((i, _), ty, S) => IEnv.insert(S, i, ty))
                IEnv.empty
                (IEnv.listItemsi boundtvars, tyl)
      in 
        substBTvar subst body
      end
    | tpappTy (ty1, tyl) = 
      raise
        Control.Bug
            ("tpappTy:" ^ TypeFormatter.tyToString ty1 ^ ", " ^
             "{" ^
             concat(map (fn x => (TypeFormatter.tyToString x ^ ",")) tyl) ^
             "|")

  fun polyBodyTy (T.POLYty {body, ...}) = body
    | polyBodyTy (T.TYVARty (ref (T.SUBSTITUTED ty))) = polyBodyTy ty
    | polyBodyTy ty =
      raise Control.Bug ("polyBodyTy:" ^ TypeFormatter.tyToString ty)

  fun ranTy (T.FUNMty(_, ty)) = ty
    | ranTy (T.TYVARty (ref (T.SUBSTITUTED ty))) = ranTy ty
    | ranTy ty = raise Control.Bug ("ranTy:" ^ TypeFormatter.tyToString ty)
  fun domTy (T.FUNMty(tyList, _)) = tyList
    | domTy (T.TYVARty (ref (T.SUBSTITUTED ty))) = domTy ty
    | domTy ty = raise Control.Bug ("domTy:" ^ TypeFormatter.tyToString ty)
(*
  fun ranTyI (T.IABSty(ty1, ty2)) = ty2
    | ranTyI (T.TYVARty (ref (T.SUBSTITUTED ty))) = ranTyI ty
    | ranTyI ty = raise Control.Bug ("ranTyM:" ^ TypeFormatter.tyToString ty)
  fun domTyI (T.IABSty(n, ty2)) = n
    | domTyI (T.TYVARty (ref (T.SUBSTITUTED ty))) = domTyI ty
    | domTyI ty = raise Control.Bug ("domTyM:" ^ TypeFormatter.tyToString ty)
*)
  (* The following are for printer code generation. *)
  fun substituteBTV (srcBTVID, destTy) ty=
      substBTvar (IEnv.singleton(srcBTVID, destTy)) ty

  fun instantiate {boundtvars : T.btvEnv, body : T.ty} =
      let 
          val subst = freshSubst boundtvars
      in 
          (substBTvar subst body, subst) 
      end
(*
fun unify (ty1, ty2) = Unify.unify [(ty1,ty2)]
Unify is imperative; i.e. it performs the unifier by updating the type
variables. So be careful in using this.
*)

  (**
   * Make a fresh instance of a polytype and a term of that type.
   *)
  fun freshInstTy ty =
      if monoTy ty
      then ty
      else
          case ty 
           of (T.POLYty{boundtvars,body,...}) =>
              let 
                  val subst = freshSubst boundtvars
                  val bty = substBTvar subst body
              in  
                  freshInstTy bty
              end
            | T.FUNMty (tyList,ty) => 
              T.FUNMty(tyList, freshInstTy ty)
            | T.RECORDty fl => 
              T.RECORDty (SEnv.map freshInstTy fl)
            | ty => ty

  (**
   * Make a rigid fresh instance of a polytype and a term of that type.
   *)
  fun freshRigidInstTy ty =
      if monoTy ty
      then ty
      else
        case ty 
         of (T.POLYty{boundtvars,body,...}) =>
            let 
              val subst = freshRigidSubst boundtvars
              val bty = substBTvar subst body
            in  
                freshRigidInstTy bty
            end
          | T.FUNMty (tyList,ty) => 
            let
                val newTy = freshRigidInstTy ty
            in
                T.FUNMty(tyList, newTy)
            end
          | T.RECORDty fl => 
            (T.RECORDty  (SEnv.map freshRigidInstTy fl))
          | ty => ty

  (**
   *)
  fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")


  (**
   * Type generalizer.
   * This must be called top level, i.e. de Bruijn 0
   *)
  fun generalizer (ty, contextLambdaDepth) =
      let 
        val freeTvs = EFTV ty
        val tids = 
            OTSet.filter 
              (fn
                  (ref(T.TVAR{id, recordKind = T.OCONSTkind _,...}))
                  => 
                  raise Control.Bug "OCONSTkind ty to generalizer"
                | (ref (T.TVAR {lambdaDepth = tyvarLambdaDepth,...})) => 
                  T.youngerDepth
                    {contextDepth = contextLambdaDepth,
                     tyvarDepth = tyvarLambdaDepth}
                | _ =>
                  raise Control.Bug
                          "non TVAR found in freeTvs in generalizer\
                          \ (types/main/TypesUtils)"
              )
              freeTvs

(* fix the bug 187
 * when typeinference phase does type instantiation for the more
 * polymorphic type in strucutre with the restricted type in signature,
 * the bound type variables of the new generated instantiated type
 * should be in the same order as that specified at the type in the
 * signature. Since the type varialbes of a polymorphic val type in
 * signature only bounded at toplevel, the order of these bounded type
 * variables decides the order of type instantiation paramaters. When we
 * do freshRigidInstTy of a signature type, the rigid type variables are
 * in the same incremental order as bound variables. And then we
 * generalize the instantiated structure type (see function
 * generateInstTermFunOnStructure in TypeInstantiationTerm.sml) by the
 * rigid type variables. Since it is always incremental we generate the
 * orderedTidEnv below.  So in this way we generates the new bounded
 * type variables in the order as that of original bounded type
 * variables.  
*)
      in
        if OTSet.isEmpty tids
        then ({boundEnv = IEnv.empty, removedTyIds = OTSet.empty})
        else
          let
            val btvs =
                OTSet.foldl
                  (fn (r as ref(T.TVAR (k as {id, ...})), btvs) =>
                      let 
                        val btvid = BoundTypeVarID.generate ()
                      in
                        (
                         r := T.SUBSTITUTED (T.BOUNDVARty btvid);
                         (
                          IEnv.insert
                            (
                             btvs,
                             btvid,
                             {
                              recordKind = (#recordKind k),
                              eqKind = (#eqKind k)
                             }
                            )
                         )
                        )
                      end
                    | _ => raise Control.Bug "generalizeTy")
                  IEnv.empty
                  tids
          in
            if OTSet.isEmpty tids
            then ({boundEnv = IEnv.empty, removedTyIds = OTSet.empty})
            else ({boundEnv = btvs, removedTyIds = tids})
          end
      end

  (**
   * Since generalization is done by performing substitution of free type
   * variables, it is imperative.
   *
   * This function should only be used for a fresh instance of a closed
   * polytype.
   *)
  fun generalize ty =
      let
          val boundObject = generalizer (ty, T.toplevelDepth)
      in
          {boundtvEnv = #boundEnv boundObject, body = ty}
      end

(**********************************************************************)

  fun isTyConOfTyFun ({name, strpath, tyargs, body} : T.tyFun) = 
      let
        fun isTyCon ty =                
            case ty of
                T.RAWty _ => true
              | T.ALIASty (_, ty) => isTyCon ty
              | T.SPECty _ => true
              | T.OPAQUEty _ => true
              | _ => false
      in
          isTyCon body
      end

  fun tyFunToTyCon ({name, strpath, tyargs, body}:T.tyFun) = 
      let
        fun extract ty = 
            case  ty of
                T.RAWty {tyCon, args} => tyCon
              | T.ALIASty (_, ty) => extract ty
              | T.SPECty {tyCon, args} => tyCon
              | T.OPAQUEty {spec = {tyCon, args}, ...} => tyCon
              | _ => raise ExIllegalTyFunToTyCon(name)
      in
          extract body
      end

  fun strPathOfTyBindInfo tyBindInfo =
      case tyBindInfo of
        T.TYSPEC {strpath, ...}  =>  strpath
      | T.TYCON {tyCon = {strpath, ...} ,...} =>  strpath
      | T.TYFUN
          ({body = T.ALIASty(T.RAWty{tyCon = {strpath,...},...},_),
            ...}) => strpath
      | T.TYOPAQUE  {spec = {strpath, ...}, ...} => strpath
      | T.TYFUN  _ =>
        raise
          Control.Bug
            "TYFUN is not well-formed: body = T.ALIASty(T.CONty,_)"

  fun peelTyOPAQUE tyBindInfo =
      case tyBindInfo of
        T.TYOPAQUE {spec,impl} => peelTyOPAQUE impl
      |  _   => tyBindInfo

  fun stripSysStrpathRecordKind (recordKind : T.recordKind) =
     case recordKind of
         T.UNIV => recordKind
       | T.REC tys => T.REC (SEnv.map stripSysStrpathTy tys)
       | T.OCONSTkind tys => T.OCONSTkind (map stripSysStrpathTy tys)
       | T.OPRIMkind {instances,operators}
         => T.OPRIMkind {instances = map stripSysStrpathTy instances,
                         operators = operators}
      
  and stripSysStrpathTvKind (tvKind : T.tvKind) =
      {
       lambdaDepth = #lambdaDepth tvKind,
       id = #id tvKind,
       recordKind = stripSysStrpathRecordKind (#recordKind tvKind),
       eqKind = #eqKind tvKind,
       tyvarName = #tyvarName tvKind
      }

  and stripSysStrpathBtvKind (btvKind : T.btvKind) =
      {recordKind = stripSysStrpathRecordKind (#recordKind btvKind), 
       eqKind = #eqKind btvKind}
      
  and stripSysStrpathTy ty =
      case ty of
          T.INSTCODEty {oprimId, name, oprimPolyTy, keyTyList, instTyList} =>
          T.INSTCODEty 
          {
           oprimId = oprimId,
           name = name, 
           oprimPolyTy = oprimPolyTy,
           instTyList = map stripSysStrpathTy instTyList,
           keyTyList = map stripSysStrpathTy keyTyList
          }
        | T.ERRORty => ty
        | T.DUMMYty _ => ty
        | T.TYVARty (tvStateRef as ref (T.TVAR tvKind)) =>
          let
              val _ = tvStateRef := T.TVAR (stripSysStrpathTvKind tvKind)
          in
              T.TYVARty tvStateRef 
          end
        | T.TYVARty (ref (T.SUBSTITUTED ty)) => stripSysStrpathTy ty
        | T.BOUNDVARty _ => ty
        | T.FUNMty (tys, ty) =>
          T.FUNMty (map stripSysStrpathTy tys, stripSysStrpathTy ty)
        | T.RECORDty tys => T.RECORDty (SEnv.map stripSysStrpathTy tys)
        | T.RAWty {tyCon, args} =>
          T.RAWty
            {tyCon = {name = #name tyCon, 
                      strpath = Path.pathToUsrPath (#strpath tyCon), 
                      abstract = #abstract tyCon, 
                      tyvars = #tyvars tyCon, 
                      id = #id tyCon, 
                      eqKind = #eqKind tyCon,
                      constructorHasArgFlagList =
                        #constructorHasArgFlagList tyCon
                     },
                   args = map stripSysStrpathTy args}
        | T.POLYty {boundtvars, body} =>
          T.POLYty {boundtvars = IEnv.map stripSysStrpathBtvKind boundtvars,
                    body = stripSysStrpathTy body}
        | T.ALIASty (ty1, ty2) =>
          T.ALIASty (stripSysStrpathTy ty1, ty2) 
        | T.OPAQUEty {spec = {tyCon, args}, implTy} =>
          T.OPAQUEty
            {spec =
             {tyCon =
              {name = #name tyCon, 
               strpath = Path.pathToUsrPath (#strpath tyCon), 
               abstract = #abstract tyCon, 
               tyvars = #tyvars tyCon, 
               id = #id tyCon, 
               eqKind = #eqKind tyCon,
               constructorHasArgFlagList = #constructorHasArgFlagList tyCon
              },
              args = map stripSysStrpathTy args},
             implTy = implTy}
        | T.SPECty {tyCon, args} =>
          T.SPECty
            {tyCon =
             {name = #name tyCon, 
              strpath = Path.pathToUsrPath (#strpath tyCon), 
              abstract = #abstract tyCon, 
              tyvars = #tyvars tyCon, 
              id = #id tyCon, 
              eqKind = #eqKind tyCon,
              constructorHasArgFlagList = #constructorHasArgFlagList tyCon
             },
             args = map stripSysStrpathTy args}
  end
end
