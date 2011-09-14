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
  structure A = Absyn 
  structure BE = BuiltinEnv 
  fun printType ty = print (Control.prettyPrint (T.format_ty nil ty))
  fun printKind kind = print (Control.prettyPrint (T.format_tvarKind nil kind))
in

  fun derefTy (T.TYVARty(ref (T.SUBSTITUTED ty))) = derefTy ty
    | derefTy ty = ty

  (* Substitute bound type variables in a type. *)
  fun substBTvar subst ty =
      case ty of
        T.SINGLETONty singletonTy =>
        T.SINGLETONty (substBTvarSingletonTy subst singletonTy)
      | T.ERRORty => ty
      | T.DUMMYty dummyTyID => ty
      | T.TYVARty (ref (T.SUBSTITUTED ty)) => substBTvar subst ty
      | T.TYVARty (ref (T.TVAR _)) => ty
(* FIXME: The following is wrong. Need to review similar cases.
      | T.TYVARty (tvStateRef as ref tvstate) =>
        ty before tvStateRef := substBTvarTvstate subst tvstate
*)
      | T.BOUNDVARty n =>
        (case BoundTypeVarID.Map.find(subst, n) of SOME ty' => ty' | _ => ty)
      | T.FUNMty (tyList, ty) =>
        T.FUNMty (map (substBTvar subst) tyList, substBTvar subst ty)
      | T.RECORDty tySenvMap =>
        T.RECORDty (SEnv.map (substBTvar subst) tySenvMap)
      | T.CONSTRUCTty {tyCon,args} =>
        T.CONSTRUCTty {tyCon=tyCon,args = map (substBTvar subst) args}
      | T.POLYty {boundtvars, body} =>
        let
          val boundtvars =
              BoundTypeVarID.Map.map 
                (fn {eqKind, tvarKind} =>
                    {eqKind=eqKind, tvarKind=substBTvarTvarKind subst tvarKind}
                )
                boundtvars
        in
          T.POLYty{boundtvars = boundtvars, body = substBTvar subst body}
        end

  and substBTvarSingletonTy subst singletonTy =
      case singletonTy of
        T.INSTCODEty {oprimId, path, keyTyList, match, instMap} => 
        T.INSTCODEty {oprimId = oprimId,
                      path = path,
                      keyTyList = map (substBTvar subst) keyTyList,
                      match = substBTvarOverloadMatch subst match,
                      instMap = instMap}
      | T.INDEXty (label, ty) =>
        T.INDEXty (label, substBTvar subst ty)
      | T.TAGty ty =>
        T.TAGty (substBTvar subst ty)
      | T.SIZEty ty =>
        T.SIZEty (substBTvar subst ty)

(* This is wrong; we should not update the original ref.
  and substBTvarTvstate subst tvstate =
      case tvstate of
        T.TVAR {lambdaDepth,id,tvarKind,eqKind,utvarOpt} => tvstate
      | T.SUBSTITUTED ty => T.SUBSTITUTED (substBTvar subst ty)
*)      

  and substBTvarTvarKind subst tvarKind =
      case tvarKind of
        T.REC fields => T.REC (SEnv.map (substBTvar subst) fields)
      | T.UNIV => T.UNIV
      | T.OCONSTkind l => 
        T.OCONSTkind (map (substBTvar subst) l)
      | T.OPRIMkind {instances, operators} =>
        T.OPRIMkind 
          {instances = map (substBTvar subst) instances,
           operators =
           map (fn {oprimId, path, keyTyList, match, instMap} =>
                   {oprimId = oprimId,
                    path = path,
                    keyTyList = map (substBTvar subst) keyTyList,
                    match = substBTvarOverloadMatch subst match,
                    instMap = instMap})
               operators
          }

  and substBTvarOverloadMatch subst match =
      case match of
        T.OVERLOAD_EXVAR {exVarInfo, instTyList} =>
        T.OVERLOAD_EXVAR {exVarInfo = exVarInfo,
                          instTyList = map (substBTvar subst) instTyList}
      | T.OVERLOAD_PRIM {primInfo, instTyList} =>
        T.OVERLOAD_PRIM {primInfo = primInfo,
                         instTyList = map (substBTvar subst) instTyList}
      | T.OVERLOAD_CASE (ty, matches) =>
        T.OVERLOAD_CASE (substBTvar subst ty,
                         TypID.Map.map (substBTvarOverloadMatch subst) matches)

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
  fun makeFreshSubst utvarOpt boundEnv = 
      let
        val newSubst =
            BoundTypeVarID.Map.map
              (fn x => 
                  let
                    val newTy = 
                        T.newty {
                        tvarKind = T.UNIV,
                        eqKind = A.NONEQ,
                        utvarOpt = utvarOpt
                        }
                  in
                    newTy
                  end)
              boundEnv
        val _ =
            BoundTypeVarID.Map.appi
              (fn (i, T.TYVARty(r as ref (T.TVAR {id, utvarOpt, ...}))) => 
                  r := 
                     (case BoundTypeVarID.Map.find(boundEnv, i) of
                        SOME {tvarKind, eqKind} => 
                        let
                          val uvtarOpt =
                              case utvarOpt of
                                NONE => NONE
                              | SOME{name, id,...} => 
                                SOME{name=name,id=id,eq=eqKind}
                        in
                          T.TVAR
                            {
                             lambdaDepth = T.infiniteDepth,
                             id = id, 
                             tvarKind = substBTvarTvarKind newSubst tvarKind,
                             eqKind = eqKind,
                             utvarOpt = utvarOpt
                            }
                        end
                      | _ => raise Control.Bug "fresh Subst")
                | _ => raise Control.Bug "freshSubst")
              newSubst
      in
        newSubst
      end
  fun freshSubst boundEnv = makeFreshSubst NONE boundEnv
  fun freshRigidSubst boundEnv = 
      let
        val id = TvarID.generate()
        val tvar = {name="RIGID", eq=A.NONEQ,id=id,lifted=false}
        val utvarOpt = SOME tvar
      in
        makeFreshSubst utvarOpt boundEnv
      end

  (**
   * Check whether a type is a mono type or not.
   *)
  fun monoTy ty =
      let
        exception PolyTy
        fun visit ty =
            case ty of
              T.SINGLETONty singletonTy => raise PolyTy
            | T.ERRORty => ()
            | T.DUMMYty dummyTyID => ()
            | T.TYVARty _ => ()
            | T.BOUNDVARty _ => (* raise PolyTy *) ()  (* this should be ok *)
            | T.FUNMty (_, ty) => visit ty
            | T.RECORDty tySenvMap => SEnv.app visit tySenvMap
            | T.CONSTRUCTty _ => ()
            | T.POLYty {boundtvars, body} => raise PolyTy
      in
        (visit ty; true)
        handle PolyTy => false
      end

  fun makeFreshInstTy makeSubst ty =
      if monoTy ty then ty
      else
        case ty of
          T.POLYty{boundtvars,body,...} =>
          let 
            val subst = makeSubst boundtvars
            val bty = substBTvar subst body
          in  
             makeFreshInstTy makeSubst bty
          end
        | T.FUNMty (tyList,ty) =>
          T.FUNMty(tyList, makeFreshInstTy makeSubst ty)
        | T.RECORDty fl => T.RECORDty (SEnv.map (makeFreshInstTy makeSubst) fl)
        | ty => ty

  fun freshInstTy ty = makeFreshInstTy freshSubst ty
  fun freshRigidInstTy ty = makeFreshInstTy freshRigidSubst ty

  exception ExSpecTyCon of string
  exception ExIllegalTyFunToTyCon of string
  exception CoerceFun 
  exception CoerceTvarKindToEQ 

  fun derefSubstTy (T.TYVARty(ref (T.SUBSTITUTED ty))) = derefSubstTy ty
    | derefSubstTy ty = ty

  fun pruneTy ty = 
      case ty of
        T.TYVARty (ref(T.SUBSTITUTED ty)) => pruneTy ty
      | T.POLYty {boundtvars, body = T.TYVARty(ref(T.SUBSTITUTED ty))} =>
        pruneTy (T.POLYty {boundtvars = boundtvars, body = ty})
      | _ => ty

  fun EFTV ty =
    let
      fun traverseTy (ty,set) =
        case ty of
          T.SINGLETONty sty => traverseSingletonTy (sty, set)
        | T.ERRORty => set
        | T.DUMMYty int => set
        | T.TYVARty (ref(T.SUBSTITUTED ty)) => traverseTy (ty,set)
        | T.TYVARty (ref(T.TVAR {tvarKind=T.OCONSTkind _,...})) => set
        | T.TYVARty (tyvarRef as (ref(T.TVAR tvKind))) => 
            if OTSet.member(set, tyvarRef) then set
            else traverseTvKind (tvKind, OTSet.add(set, tyvarRef))
        | T.BOUNDVARty int => set
        | T.FUNMty (tyList, ty) =>
          traverseTy (ty, foldl traverseTy set tyList)
        | T.RECORDty tySEnvMap => 
            SEnv.foldl (fn (ty, set) => traverseTy (ty,set)) set tySEnvMap
        | T.CONSTRUCTty {tyCon, args = tyList} => foldl traverseTy set tyList
        | T.POLYty {boundtvars = btvKindIEnvMap, body=ty} =>
          traverseTy (ty,set)
      and traverseSingletonTy (singletonTy, set) =
          case singletonTy of
            T.INSTCODEty {oprimId, path, keyTyList, match, instMap} =>
            foldl traverseTy set keyTyList
          | T.INDEXty (label, ty) =>
            traverseTy (ty, set)
          | T.TAGty ty =>
            traverseTy (ty, set)
          | T.SIZEty ty =>
            traverseTy (ty, set)
      and traverseTvKind (kind, set) =
            case kind of
              {tvarKind = T.UNIV, ...} => set
            | {tvarKind = T.REC fields, ...} => 
                SEnv.foldl traverseTy set fields
            | {tvarKind = T.OCONSTkind _, ...} =>
              raise Control.Bug "OCONSTkind to travseTvKind"
            | {tvarKind = T.OPRIMkind {instances, operators},...}
              =>
              foldl traverseTy set instances
    in
      traverseTy (ty, OTSet.empty)
    end

  fun adjustDepthInTy contextDepth ty = 
    let
      val tyset = EFTV ty
    in
      OTSet.app
      (fn (tyvarRef as (ref (T.TVAR {
                                     lambdaDepth=tyvarDepth, 
                                     id, 
                                     tvarKind, 
                                     eqKind, 
                                     utvarOpt
                                     }))) =>
         if T.strictlyYoungerDepth {tyvarDepth=tyvarDepth,
                                    contextDepth=contextDepth} then
           tyvarRef := T.TVAR {
                               lambdaDepth=contextDepth, 
                               id = id, 
                               tvarKind = tvarKind, 
                               eqKind = eqKind, 
                               utvarOpt = utvarOpt
                               }
         else ()
       | _ => raise Control.Bug "non TVAR in adjustDepthInTy (TypesUtils.sml)"
      )
      tyset
    end

  fun adjustDepthInTvarKind contextDepth kind = 
    case kind of
      T.UNIV => ()
    | T.REC fields => 
        SEnv.app (adjustDepthInTy contextDepth) fields
    | T.OCONSTkind tyList => 
        List.app (adjustDepthInTy contextDepth) tyList
    | T.OPRIMkind {instances = tyList,...} => 
        List.app (adjustDepthInTy contextDepth) tyList
  (**
   * Type generalizer.
   * This must be called top level, i.e. de Bruijn 0
   *)
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
  fun generalizer (ty, contextLambdaDepth) =
      let 
        val freeTvs = EFTV ty
        val tids = 
            OTSet.filter 
              (fn
                  (ref(T.TVAR{id, tvarKind = T.OCONSTkind _,...}))
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
      in
        if OTSet.isEmpty tids
        then ({boundEnv = BoundTypeVarID.Map.empty, removedTyIds = OTSet.empty})
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
                          BoundTypeVarID.Map.insert
                            (
                             btvs,
                             btvid,
                             {
                              tvarKind = (#tvarKind k),
                              eqKind = (#eqKind k)
                             }
                            )
                         )
                        )
                      end
                    | _ => raise Control.Bug "generalizeTy")
                  BoundTypeVarID.Map.empty
                  tids
          in
            if OTSet.isEmpty tids
            then ({boundEnv = BoundTypeVarID.Map.empty,
                   removedTyIds = OTSet.empty})
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

  (**
   * Perform imperative implace substitutrion.
   *)
  fun performSubst (T.TYVARty (r as ref(T.TVAR _)), ty) = r := T.SUBSTITUTED ty
    | performSubst _ =
      raise Control.Bug "non TVAR in performSubst (types/mainTypesUtils.sml)"
  fun admitEqTy ty =
      let
        exception NonEQ
        fun visit ty = 
            case ty of
              T.SINGLETONty singletonTy => raise NonEQ
            | T.ERRORty => raise NonEQ
            | T.DUMMYty dummyTyID => ()
            | T.TYVARty (ref(T.TVAR {eqKind = A.NONEQ, ...})) => raise NonEQ
            | T.TYVARty (ref(T.TVAR {eqKind = A.EQ, ...})) => ()
            | T.TYVARty (ref(T.SUBSTITUTED ty)) => visit ty
            | T.BOUNDVARty boundTypeVarID => ()
            | T.FUNMty _ => raise NonEQ 
            | T.RECORDty tySenvMap => SEnv.app visit tySenvMap
            | T.CONSTRUCTty {tyCon={id,iseq,...},args} =>
              if TypID.eq(id, #id BE.ARRAYtyCon) then ()
              else if TypID.eq(id, #id (BE.REFtyCon ())) then ()
              else if iseq then List.app visit args
              else raise NonEQ
            | T.POLYty {boundtvars, body} =>
              (BoundTypeVarID.Map.app 
                 (fn {eqKind, tvarKind} => visitTvarKind tvarKind)
                 boundtvars;
               visit body)
        and visitTvarKind tvarKind =
            case tvarKind of
              T.UNIV => ()
          | T.REC tySenvMap => SEnv.app visit tySenvMap
          | T.OCONSTkind tyList => List.app visit tyList
          | T.OPRIMkind {instances, operators} => List.app visit instances
      in
        (visit ty; true)
        handle NonEQ => false
      end

  fun coerceTvarkindToEQ tvarKind = 
      let
        fun adjustEqKindInTy eqKind ty = 
            case eqKind of
              A.NONEQ => ()
            | A.EQ => 
              let
                val tyset = EFTV ty
              in
                OTSet.app
                  (fn (tyvarRef as (ref (T.TVAR
                                           {
                                            lambdaDepth =lambdaDepth, 
                                            id, 
                                            tvarKind, 
                                            eqKind, 
                                            utvarOpt
                                           }
                      )))
                      =>
                      tyvarRef := T.TVAR
                                    {
                                     lambdaDepth = lambdaDepth, 
                                     id = id, 
                                     tvarKind = tvarKind, 
                                     eqKind = A.EQ, 
                                     utvarOpt = utvarOpt
                                    }
                    | _ =>
                      raise
                        Control.Bug
                          "non TVAR in adjustDepthInTy (TypesUtils.sml)"
                  )
                  tyset
              end

        fun adjustEqKindInTvarKind eqKind kind = 
            case kind of
              T.UNIV => ()
            | T.REC fields => 
              SEnv.app (adjustEqKindInTy eqKind) fields
            | T.OCONSTkind tyList =>
              List.app (adjustEqKindInTy eqKind) tyList
            | T.OPRIMkind {instances = tyList,...} =>
              List.app (adjustEqKindInTy eqKind) tyList
      in
        (adjustEqKindInTvarKind A.EQ tvarKind;
         case tvarKind of
           T.UNIV => T.UNIV
         | T.REC fields => T.REC fields
         | T.OCONSTkind L =>  
           let
             val L = List.filter admitEqTy L
           in
             case L of 
               nil => raise CoerceTvarKindToEQ 
             | _ =>  T.OCONSTkind L
           end
         | T.OPRIMkind {instances,operators} =>  
           let
             val instances = List.filter admitEqTy instances
           in
             case instances of 
               nil => raise CoerceTvarKindToEQ 
             | _ =>  T.OPRIMkind {instances = instances, operators =operators} 
           end
        )
      end

  (**
   * Make a fresh copy of a bound type environment by allocating a new btvid
   * @params  boundEnv
   * @return subst bound type variable substitution
   *)
  fun copyBoundEnv boundEnv = 
      let
        val newSubst =
            BoundTypeVarID.Map.map
              (fn _  => 
                  let
                    val newBoundVarId = BoundTypeVarID.generate ()
                  in 
                    T.BOUNDVARty newBoundVarId
                  end)
              boundEnv
        val newBoundEnv =
            BoundTypeVarID.Map.foldri
              (fn (oldId, {tvarKind, eqKind}, newBoundEnv) =>
                  (case BoundTypeVarID.Map.find(newSubst, oldId) of
                     SOME (T.BOUNDVARty newId) =>
                     BoundTypeVarID.Map.insert
                       (newBoundEnv, 
                        newId, 
                        {tvarKind=substBTvarTvarKind newSubst tvarKind, 
                         eqKind=eqKind})
                   | _ => raise Control.Bug "copyBoundEnv"))
              BoundTypeVarID.Map.empty
              boundEnv
      in
        (newSubst, newBoundEnv)
      end

                    
  (*
    exception CoerceFunM
  *)
  fun coerceFunM (ty, tyList) =
      case derefTy ty of
          oldTy as T.TYVARty
                (ref (T.TVAR {lambdaDepth,
                              id,
                              tvarKind = T.UNIV,
                              eqKind,
                              utvarOpt = NONE})) => 
          let 
            val tyList = 
                map (fn x => 
                        let
                          val newTy = 
                              T.newty {tvarKind = T.UNIV,
                                       eqKind=eqKind,
                                       utvarOpt = NONE}
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
        | T.TYVARty (ref (T.TVAR {utvarOpt = SOME _,...})) => 
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
               val argTyList = map (substBTvar subst1) tyList
               val ranTy = substBTvar subst1 ty2
               val btvInstTyList = BoundTypeVarID.Map.listItemsi subst1
               val instTyList = map #2 btvInstTyList
             in
               (argTyList,ranTy,instTyList)
             end
           | T.ERRORty => (map (fn x => T.ERRORty) tyList, T.ERRORty, nil)
           | _ => raise CoerceFun
          )
        | T.ERRORty => (map (fn x => T.ERRORty) tyList, T.ERRORty, nil)
        | _ => raise CoerceFun


  exception RigidCoerceFunM
  fun rigidCoerceFunM (ty, tyList) =
      case derefTy ty of
          oldTy as T.TYVARty
                (ref (T.TVAR {lambdaDepth,
                              id,
                              tvarKind = T.UNIV,
                              eqKind,
                              utvarOpt = NONE})) => 
          let 
            val tyList = 
                map (fn x => 
                        let
                          val newTy = 
                              T.newty {tvarKind = T.UNIV,
                                       eqKind=eqKind,
                                       utvarOpt = NONE}
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
            (tyList, ty2)
          end
        | T.TYVARty (ref (T.TVAR {utvarOpt = SOME _,...})) =>
          raise RigidCoerceFunM
        | T.TYVARty (ref(T.SUBSTITUTED ty)) => rigidCoerceFunM (ty, tyList)
        | T.FUNMty (tyList, ty2) =>  (tyList, ty2)
        | T.POLYty {boundtvars, body} => raise RigidCoerceFunM
        | T.ERRORty => (map (fn x => T.ERRORty) tyList, T.ERRORty)
        | _ => raise RigidCoerceFunM


(******************************************************************************
  (**
   * Substitute bound type variables in a type.
   * only the monomorphic potion of the target contain the bound type
   * variables to be substituted.
   * @params subst type 
   * @param subst substitution. The domain is an integer interval.
   * @return
   *)
  fun applyMatch subst ty =
      if BoundTypeVarID.Map.isEmpty subst
      then ty
      else 
        TypeTransducer.mapTyPreOrder
            (fn (ty as T.BOUNDVARty n) =>
                ((valOf (BoundTypeVarID.Map.find(subst, n)))
                 handle Option => ty, true)
              | (ty as T.POLYty _) => (ty, false)
              | ty => (ty, true))
            ty


  (**
   * Substitute bound type variables in a type Environment
   * this is for boundtyvars in POLYtype only.
   * bound type variables do not occur in a free type variable context.
   *)
  fun substBTvEnv subst tvEnv =
      BoundTypeVarID.Map.map (substBTvarBTKind subst) tvEnv




(*
        val _ =
            BoundTypeVarID.Map.appi
              (fn (i,
                   T.TYVARty
                     (r as ref (T.TVAR {lambdaDepth, id, utvarOpt, ...}))) => 
                  r := 
                 (case BoundTypeVarID.Map.find(boundEnv, i) of
                    SOME {index, tvarKind, eqKind} => 
                    (case tvarKind of 
                       T.REC _ =>
                       T.kindedTyvarList := r :: (!T.kindedTyvarList)
                     | T.OVERLOADED _ =>
                       T.kindedTyvarList := r :: (!T.kindedTyvarList)
                     | _ => ();         
                     T.TVAR
                       {
                        lambdaDepth = lambdaDepth,
                        id = id, 
                        tvarKind = substBTvarTvarKind newSubst tvarKind,
                        eqKind = eqKind,
                        utvarOpt = utvarOpt
                       }
                    )
                  | _ => raise Control.Bug "fresh Subst")
                | _ => raise Control.Bug "freshSubst")
              newSubst
*)


  (**
   * Complement a bound substitution with fresh instances.
   * 
   * @params subst btvenv
   *)
  fun complementBSubst BS boundEnv = 
      let
        val newSubst = 
            BoundTypeVarID.Map.foldli 
              (fn (i, ty, Env) =>
                  if BoundTypeVarID.Map.inDomain(BS, i)
                  then Env
                  else
                    let
                      val newTy =
                          T.newty
                            {
                             tvarKind = T.UNIV,
                             eqKind = A.NONEQ,
                             utvarOpt = NONE
                            }
                    in
                      BoundTypeVarID.Map.insert (Env, i, newTy)
                    end)
              BoundTypeVarID.Map.empty
              boundEnv
        val _ =
            BoundTypeVarID.Map.appi
              (fn (i,
                   T.TYVARty
                     (r as ref (T.TVAR {lambdaDepth, id, utvarOpt, ...}))) => 
                  r := 
                     (case BoundTypeVarID.Map.find(boundEnv, i) of
                        SOME {tvarKind, eqKind} => 
                        T.TVAR
                          {
                           lambdaDepth = lambdaDepth,
                           id = id, 
                           tvarKind = substBTvarTvarKind newSubst tvarKind,
                           eqKind = eqKind,
                           utvarOpt = utvarOpt
                          }
                      | _ => raise Control.Bug "fresh Subst")
                | _ => raise Control.Bug "complementBSubst")
              newSubst
(* 
       val _ =
           BoundTypeVarID.Map.appi
             (fn (i,
                  T.TYVARty
                    (r as ref (T.TVAR{lambdaDepth,id,utvarOpt, ...}))) => 
                 r := 
                    (case BoundTypeVarID.Map.find(boundEnv, i) of
                       SOME {index, tvarKind, eqKind} => 
                       (case tvarKind of 
                          T.REC _ =>
                          T.kindedTyvarList := r :: (!T.kindedTyvarList)
                        | T.OVERLOADED _ =>
                          T.kindedTyvarList := r :: (!T.kindedTyvarList)
                        | _ => ();
                        T.TVAR
                          {
                           lambdaDepth = lambdaDepth,
                           id = id, 
                           tvarKind = substBTvarTvarKind newSubst tvarKind,
                           eqKind = eqKind,
                           utvarOpt = utvarOpt
                       })
                     | _ => raise Control.Bug "fresh Subst")
               | _ => raise Control.Bug "complementBSubst")
             newSubst
*)
      in
        BoundTypeVarID.Map.unionWith
          (fn x => raise Control.Bug "complementBSubstSubst") (BS, newSubst)
      end

  local 
    exception FALSE 
  in

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
        val argsBtyList = BoundTypeVarID.Map.listItemsi tyargs
      in
        if List.length argsBtyList <> List.length tyl then
          raise Control.Bug "betaReduceTy arity mismatch"
        else
          let
            val subst = 
              ListPair.foldr
              (fn ((i, _), ty, S) => BoundTypeVarID.Map.insert(S, i, ty))
              BoundTypeVarID.Map.empty
              (argsBtyList, tyl)
          in 
            substBTvar subst body
          end
      end
*)

  fun tpappTy (ty, nil) = ty
    | tpappTy (T.TYVARty (ref (T.SUBSTITUTED ty)), tyl) =
      tpappTy (ty, tyl)
    | tpappTy (T.POLYty{boundtvars, body, ...}, tyl) = 
      let
        val subst = 
            ListPair.foldr
                (fn ((i, _), ty, S) => BoundTypeVarID.Map.insert(S, i, ty))
                BoundTypeVarID.Map.empty
                (BoundTypeVarID.Map.listItemsi boundtvars, tyl)
      in 
        substBTvar subst body
      end
    | tpappTy (ty1, tyl) =
      raise
        Control.Bug
            ("tpappTy:"
             ^ Control.prettyPrint (Types.format_ty nil ty1)
             ^ ", "
             ^ "{" ^
             concat(map (fn x => Control.prettyPrint (Types.format_ty nil x))
                        tyl)
             ^ "}")

(*
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
      substBTvar (BoundTypeVarID.Map.singleton(srcBTVID, destTy)) ty

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
   * Make a fresh instance of a polytype and a term of that type.
   *)
  (**
   * Make a rigid fresh instance of a polytype and a term of that type.
   *)
  fun freshToplevelRigidInstTy ty =
      case ty of
        (T.POLYty{boundtvars,body,...}) =>
          let 
            val subst = freshRigidSubst boundtvars
          in  
            substBTvar subst body
          end
      | ty => ty


****************************************************************************)
end
end
