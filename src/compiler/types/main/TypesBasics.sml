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
structure TypesBasics =
struct
local 
  structure T = Types 
  structure A = Absyn 
  type ty = T.ty
  type varInfo = T.varInfo

  fun bug s = Bug.Bug ("TypesUtils: " ^ s)
  fun printType ty = print (Bug.prettyPrint (T.format_ty nil ty))
  fun printKind kind = print (Bug.prettyPrint (T.format_tvarKind nil kind))
  fun printSubst subst =
      BoundTypeVarID.Map.mapi 
        (fn (i,ty) => (print (BoundTypeVarID.toString i);
                       print "=";
                       printType ty;
                       print "\n"))
        subst
in


  fun derefTy (T.TYVARty(ref (T.SUBSTITUTED ty))) = derefTy ty
    | derefTy ty = ty

  (* Substitute bound type variables in a type. *)
local
  val emptyVisitEnv = FreeTypeVarID.Set.empty
  fun visited tyidEnv id = FreeTypeVarID.Set.member(tyidEnv, id)
  fun visit tyidEnv id = FreeTypeVarID.Set.add(tyidEnv, id)
  fun substBTvar tyidEnv subst ty =
      case derefTy ty of
        T.SINGLETONty singletonTy =>
        T.SINGLETONty (substBTvarSingletonTy tyidEnv subst singletonTy)
      | T.BACKENDty backendTy =>
        raise Bug.Bug "substBTvar: BACKENDty"
      | T.ERRORty => ty
      | T.DUMMYty dummyTyID => ty
      | T.TYVARty (r as ref (T.SUBSTITUTED ty)) => raise Bug.Bug "SUBSTITUTED in substBTvar" 
      | T.TYVARty (ref (T.TVAR _)) => ty
(*
   Ohori: 2012-4-14.
   Updating type variables seem to be OK and necessary. 
   I do not remember the case where this caused a probelm before.
   Ohori: 2012-4-15.
   The cause is probably the infinite loop by visiting the same tyvar again.
   This is avoided by maintaining visited set.
   Ohori: 2012-4-16.
   It should not be necessary to substitute the kind in tvar. If 'a#{l:ty} 
   and ty is 'b then 'b must be the same level as 'a, otherwise there is
   some context where 'a is free    while 'b is not, which is impossible
   by the definition of EFTV (toplas 95).
      | T.TYVARty (tvStateRef as ref (T.TVAR {lambdaDepth,id,tvarKind,eqKind,utvarOpt})) =>
        if visited tyidEnv id then ty 
        else
          let
            val tyidEnv = visit tyidEnv id
            val _ = 
                tvStateRef :=
                T.TVAR {lambdaDepth=lambdaDepth,
                        id=id,
                        tvarKind=substBTvarTvarKind tyidEnv subst tvarKind,
                        eqKind=eqKind,
                        utvarOpt=utvarOpt}
          in
            ty
          end
*)
      | T.BOUNDVARty n =>
        (case BoundTypeVarID.Map.find(subst, n) of SOME ty' => ty' | _ => ty)
      | T.FUNMty (tyList, ty) =>
        T.FUNMty (map (substBTvar tyidEnv subst) tyList, substBTvar tyidEnv subst ty)
      | T.RECORDty tySenvMap =>
        T.RECORDty (LabelEnv.map (substBTvar tyidEnv subst) tySenvMap)
      | T.CONSTRUCTty {tyCon,args} =>
        T.CONSTRUCTty {tyCon=substBTvarTyCon tyidEnv subst tyCon,
                       args = map (substBTvar tyidEnv subst) args}
      | T.POLYty {boundtvars, body} =>
        let
          val boundtvars =
              BoundTypeVarID.Map.map
                (fn {eqKind, tvarKind} =>
                    {eqKind=eqKind, tvarKind=substBTvarTvarKind tyidEnv subst tvarKind}
                )
                boundtvars
          val newTy = T.POLYty{boundtvars = boundtvars, body = substBTvar tyidEnv subst body}
        in
          newTy
        end
  and substBTvarSingletonTy tyidEnv subst singletonTy =
      case singletonTy of
        T.INSTCODEty {oprimId, longsymbol, keyTyList, match, instMap} => 
        T.INSTCODEty {oprimId = oprimId,
                      longsymbol = longsymbol,
                      keyTyList = map (substBTvar tyidEnv subst) keyTyList,
                      match = substBTvarOverloadMatch tyidEnv subst match,
                      instMap = instMap}
      | T.INDEXty (label, ty) =>
        T.INDEXty (label, substBTvar tyidEnv subst ty)
      | T.TAGty ty =>
        T.TAGty (substBTvar tyidEnv subst ty)
      | T.SIZEty ty =>
        T.SIZEty (substBTvar tyidEnv subst ty)
(*
  and substBTvarBackendTy tyidEnv subst backendTy =
      case backendTy of
        T.RECORDSIZEty ty =>
        T.RECORDSIZEty (substBTvar tyidEnv subst ty)
      | T.RECORDBITMAPINDEXty ty =>
        T.RECORDBITMAPINDEXty (substBTvar tyidEnv subst ty)
      | T.RECORDBITMAPty (i,ty) => 
        T.RECORDBITMAPty (i, substBTvar tyidEnv subst ty)
      | T.CCONVTAGty ty =>
        T.CCONVTAGty (substBTvar tyidEnv subst ty)
      | T.SOME_CLOSUREENVty => backendTy
      | T.SOME_CCONVTAGty => backendTy
      | T.SOME_FUNENTRYty => backendTy
      | T.FUNENTRYty ty => T.FUNENTRYty (substBTvar tyidEnv subst ty)
      | T.CALLBACKENTRYty {haveClsEnv, argTys, retTy} =>
        T.CALLBACKENTRYty {haveClsEnv = haveClsEnv,
                           argTys = map (substBTvar tyidEnv subst) argTys,
                           retTy = substBTvar tyidEnv subst retTy}
*)
  and substBTvarTyCon tyidEnv subst ({id, longsymbol,iseq,arity,runtimeTy,conSet, conIDSet, extraArgs,dtyKind}) = 
      {id=id, longsymbol=longsymbol, iseq=iseq, arity=arity, runtimeTy=runtimeTy, conSet=conSet,
       conIDSet=conIDSet,
       extraArgs = map (substBTvar tyidEnv subst) extraArgs,
       dtyKind=(substBTvarDtyKind tyidEnv subst dtyKind)} 
  and substBTvarDtyKind tyidEnv subst dtyKind =
      case dtyKind of
        T.DTY => T.DTY
      | T.OPAQUE {opaqueRep, revealKey} =>
        T.OPAQUE {opaqueRep = substBTvarOpaqueRep tyidEnv subst opaqueRep, revealKey=revealKey}
      | T.BUILTIN _ => dtyKind
  and substBTvarOpaqueRep tyidEnv subst opaqueRep =
      case opaqueRep of
        T.TYCON tyCon  => T.TYCON (substBTvarTyCon tyidEnv subst tyCon)
      | T.TFUNDEF {iseq, arity, polyTy} => 
        T.TFUNDEF {iseq=iseq, arity=arity, polyTy=substBTvar tyidEnv subst polyTy}

(* This is wrong; we should not update the original ref.
  and substBTvarTvstate subst tvstate =
      case tvstate of
        T.TVAR {lambdaDepth,id,tvarKind,eqKind,utvarOpt} => tvstate
      | T.SUBSTITUTED ty => T.SUBSTITUTED (substBTvar subst ty)

   Ohori: 2012-4-14.
   Updating type variables for TVAR seem to be OK. 
   Updating T.SUBSTITUTED causes probem. I do not know why.
*)      

  and substBTvarTvarKind tyidEnv subst tvarKind =
      case tvarKind of
        T.REC fields => T.REC (LabelEnv.map (substBTvar tyidEnv subst) fields)
      | T.JOIN (fields, ty1, ty2, loc) => 
        T.JOIN (LabelEnv.map (substBTvar tyidEnv subst) fields, 
                substBTvar tyidEnv subst ty1,
                substBTvar tyidEnv subst ty2,
                loc
               )
      | T.UNIV => T.UNIV
      | T.OCONSTkind l => 
        T.OCONSTkind (map (substBTvar tyidEnv subst) l)
      | T.OPRIMkind {instances, operators} =>
        T.OPRIMkind 
          {instances = map (substBTvar tyidEnv subst) instances,
           operators =
           map (fn {oprimId, longsymbol, keyTyList, match, instMap} =>
                   {oprimId = oprimId,
                    longsymbol = longsymbol,
                    keyTyList = map (substBTvar tyidEnv subst) keyTyList,
                    match = substBTvarOverloadMatch tyidEnv subst match,
                    instMap = instMap})
               operators
          }

  and substBTvarOverloadMatch tyidEnv subst match =
      case match of
        T.OVERLOAD_EXVAR {exVarInfo, instTyList} =>
        T.OVERLOAD_EXVAR {exVarInfo = exVarInfo,
                          instTyList = map (substBTvar tyidEnv subst) instTyList}
      | T.OVERLOAD_PRIM {primInfo, instTyList} =>
        T.OVERLOAD_PRIM {primInfo = primInfo,
                         instTyList = map (substBTvar tyidEnv subst) instTyList}
      | T.OVERLOAD_CASE (ty, matches) =>
        T.OVERLOAD_CASE (substBTvar tyidEnv subst ty,
                         TypID.Map.map (substBTvarOverloadMatch tyidEnv subst) matches)
in
  val substBTvar = fn subst => fn ty =>
      substBTvar emptyVisitEnv subst ty
  val substBTvarSingletonTy = fn  subst => fn singletonTy =>
      substBTvarSingletonTy emptyVisitEnv subst singletonTy
  val substBTvarTyCon = fn  subst => fn arg =>
      substBTvarTyCon emptyVisitEnv subst arg
  val substBTvarDtyKind = fn subst =>  fn dtyKind =>
      substBTvarDtyKind emptyVisitEnv subst dtyKind
  val substBTvarOpaqueRep = fn subst => fn opaqueRep =>
      substBTvarOpaqueRep emptyVisitEnv subst opaqueRep
  val substBTvarTvarKind = fn subst => fn tvarKind =>
      substBTvarTvarKind emptyVisitEnv subst tvarKind
  val substBTvarOverloadMatch = fn subst => fn match =>
      substBTvarOverloadMatch emptyVisitEnv subst match
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
  fun makeFreshSubst utvarOpt boundEnv = 
      let
        val subst =
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
        val newSubst = 
            BoundTypeVarID.Map.mapi
              (fn (i, ty) => 
                  (case BoundTypeVarID.Map.find(boundEnv, i) of
                     SOME {tvarKind, eqKind} => 
                     let
                       val uvtarOpt =
                           case utvarOpt of
                             NONE => NONE
                           | SOME{symbol, id,...} => 
                             SOME{symbol=symbol,id=id,eq=eqKind}
                     in
                       (ty, utvarOpt, eqKind, substBTvarTvarKind subst tvarKind)
                     end
                   | _ => raise Bug.Bug "fresh Subst")
              )
              subst
        val _ =
            BoundTypeVarID.Map.appi
              (fn (i, (ty as T.TYVARty(r as ref (T.TVAR {id,occurresIn,...})), utvarOpt, eqKind, tvarKind)) =>
                  r := 
                   T.TVAR
                     {
                      lambdaDepth = T.infiniteDepth,
                      id = id,
                      tvarKind = tvarKind,
                      eqKind = eqKind,
                      occurresIn = occurresIn,
                      utvarOpt = utvarOpt
                     }
                | _ => raise Bug.Bug "fresh Subst")
              newSubst
      in
        subst
      end
  fun freshSubst boundEnv = makeFreshSubst NONE boundEnv

  fun freshRigidSubst boundEnv = 
      let
        val id = TvarID.generate()
        val symbol = Symbol.mkSymbol "RIGID" Loc.noloc
        val tvar = {symbol=symbol, eq=A.NONEQ,id=id,lifted=false}
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
            | T.BACKENDty backendTy => raise PolyTy
            | T.ERRORty => ()
            | T.DUMMYty dummyTyID => ()
            | T.TYVARty _ => ()
            | T.BOUNDVARty _ => (* raise PolyTy *) ()  (* this should be ok *)
            | T.FUNMty (_, ty) => visit ty
            | T.RECORDty tySenvMap => LabelEnv.app visit tySenvMap
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
        | T.RECORDty fl => T.RECORDty (LabelEnv.map (makeFreshInstTy makeSubst) fl)
        | ty => ty

  fun freshInstTy ty = makeFreshInstTy freshSubst ty
  fun freshRigidInstTy ty = makeFreshInstTy freshRigidSubst ty

  exception ExSpecTyCon of string
  exception ExIllegalTyFunToTyCon of string
  exception CoerceFun 
  exception CoerceTvarKindToEQ 

  fun derefSubstTy (T.TYVARty(ref (T.SUBSTITUTED ty))) = derefSubstTy ty
    | derefSubstTy ty = ty

(*
  fun pruneTy ty = 
      case ty of
        T.TYVARty (ref(T.SUBSTITUTED ty)) => pruneTy ty
      | T.POLYty {boundtvars, body = T.TYVARty(ref(T.SUBSTITUTED ty))} =>
        pruneTy (T.POLYty {boundtvars = boundtvars, body = ty})
      | _ => ty
*)
  (* 2013-4-12 Ohori
     This returns the maxmum index, tvstate ref set, and an index map.
     The index map represent the occurrecen order of each type variable.
   *)
  (* 2013-7-26 Ohori
     EFTV should not traverse operators in OPRIMkind.
   *)
  fun EFTV ty =
    let
      fun traverseTy (ty, env as (i, set, indexMap)) =
        case ty of
          T.SINGLETONty sty => raise Bug.Bug "SINGLETONty to EFTV"
(* 2013-7-26 ohori
          T.SINGLETONty sty => traverseSingletonTy (sty, env)
 *)
        | T.BACKENDty bty => raise Bug.Bug "BACKENDty to EFTV"
(* 2013-7-26 ohori
        | T.BACKENDty bty => traverseBackEnvTy (bty, env)
 *)
        | T.ERRORty => env
        | T.DUMMYty int => env
        | T.TYVARty (ref(T.SUBSTITUTED ty)) => traverseTy (ty,env)
        | T.TYVARty (ref(T.TVAR {tvarKind=T.OCONSTkind _,...})) => env
        | T.TYVARty (tyvarRef as (ref(T.TVAR tvKind))) =>
            if OTSet.member(set, tyvarRef) then env
            else traverseTvKind
                 (tvKind,
                  (i+1,
                   OTSet.add(set, tyvarRef),
                   IEnv.insert(indexMap, i, tyvarRef))
                 )
        | T.BOUNDVARty int => env
        | T.FUNMty (tyList, ty) =>
          traverseTy (ty, foldl traverseTy env tyList)
        | T.RECORDty tyLabelEnvMap => 
          LabelEnv.foldl traverseTy env tyLabelEnvMap
        | T.CONSTRUCTty {tyCon, args = tyList} => foldl traverseTy env tyList
        | T.POLYty {boundtvars, body=ty} =>
          traverseTy
            (ty, 
             BoundTypeVarID.Map.foldl
               (fn ({eqKind, tvarKind}, env) =>
                   traverseTvarKind (tvarKind, env)
               )
               env
               boundtvars
            )
(* 2013-7-26 ohori 
   These should never occures and they do not make sense;
      and traverseSingletonTy (singletonTy, env) =
          case singletonTy of
            T.INSTCODEty selector =>
            traverseOprimSelector (selector, env)
          | T.INDEXty (label, ty) =>
            traverseTy (ty, env)
          | T.TAGty ty =>
            traverseTy (ty, env)
          | T.SIZEty ty =>
            traverseTy (ty, env)
      and traverseBackendTy (backendTy, env) =
          case backendTy of
            T.RECORDSIZEty ty => traverseTy (ty, env)
          | T.RECORDBITMAPINDEXty ty => traverseTy (ty, env)
          | T.RECORDBITMAPty (i,ty) => traverseTy (ty, env) 
          | T.CCONVTAGty ty => traverseTy (ty, env)
          | T.SOME_CLOSUREENVty => env
          | T.SOME_CCONVTAGty => env
          | T.SOME_FUNENTRYty => env
          | T.FUNENTRYty ty => traverseTy (ty, env)
          | T.CALLBACKENTRYty {haveClsEnv, argTys, retTy} =>
            traverseTy (retTy, foldl traverseTy env argTys)
*)
      and traverseTvKind ({lambdaDepth, id, occurresIn, tvarKind, eqKind, utvarOpt}, env) = 
          traverseTvarKind (tvarKind, env) 
      and traverseTvarKind (tvarKind, env) =
            case tvarKind of
              T.UNIV=> env
            | T.REC fields => 
              LabelEnv.foldl traverseTy env fields
            | T.JOIN (fields, ty1, ty2, loc) =>
              LabelEnv.foldl 
                traverseTy 
                (traverseTy (ty1, traverseTy (ty2, env)))
                fields
            | T.OCONSTkind _ =>
              raise Bug.Bug "OCONSTkind to travseTvKind"
            | T.OPRIMkind {instances, operators} =>
              foldl traverseTy env instances
(* 2013-7-26 ohori bug 264_invalidDbi
              foldl traverseOprimSelector
                    (foldl traverseTy env instances)
                    operators
      and traverseOprimSelector ({oprimId, path, keyTyList, match, instMap}
                                 : T.oprimSelector, env) =
            traverseOverloadMatch (match, foldl traverseTy env keyTyList)
      and traverseOverloadMatch (match, env) =
          case match of
            T.OVERLOAD_EXVAR {exVarInfo, instTyList} =>
            foldl traverseTy env instTyList
          | T.OVERLOAD_PRIM {primInfo, instTyList} =>
            foldl traverseTy env instTyList
          | T.OVERLOAD_CASE (ty, map) =>
            TypID.Map.foldl traverseOverloadMatch (traverseTy (ty, env)) map
*)
    in
      traverseTy (ty, (0, OTSet.empty, IEnv.empty))
    end

  fun adjustDepthInTy contextDepth ty = 
    let
      val (_, tyset,_) = EFTV ty
    in
      OTSet.app
      (fn (tyvarRef as (ref (T.TVAR {
                                     lambdaDepth=tyvarDepth, 
                                     id, 
                                     tvarKind, 
                                     occurresIn,
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
                               occurresIn = occurresIn,
                               utvarOpt = utvarOpt
                               }
         else ()
       | _ => raise Bug.Bug "non TVAR in adjustDepthInTy (TypesUtils.sml)"
      )
      tyset
    end

  fun adjustDepthInTvarKind contextDepth kind = 
    case kind of
      T.UNIV => ()
    | T.REC fields => 
        LabelEnv.app (adjustDepthInTy contextDepth) fields
    | T.JOIN (fields, ty1, ty2, loc) => 
      (adjustDepthInTy contextDepth ty1;
       adjustDepthInTy contextDepth ty2;
       LabelEnv.app (adjustDepthInTy contextDepth) fields
      )
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
        val (i, freeTvs, indexMap) = EFTV ty
        val tids = 
            OTSet.filter 
              (fn
                  (ref(T.TVAR{id, tvarKind = T.OCONSTkind _,...}))
                  => 
                  raise Bug.Bug "OCONSTkind ty to generalizer"
                | (ref (T.TVAR {lambdaDepth = tyvarLambdaDepth,...})) => 
                  T.youngerDepth
                    {contextDepth = contextLambdaDepth,
                     tyvarDepth = tyvarLambdaDepth}
                | _ =>
                  raise Bug.Bug
                          "non TVAR found in freeTvs in generalizer\
                          \ (types/main/TypesUtils)"
              )
              freeTvs
        val newIndexMap = 
            IEnv.filter 
              (fn
                  (ref(T.TVAR{id, tvarKind = T.OCONSTkind _,...}))
                  => 
                  raise Bug.Bug "OCONSTkind ty to generalizer"
                | (ref (T.TVAR {lambdaDepth = tyvarLambdaDepth,...})) => 
                  T.youngerDepth
                    {contextDepth = contextLambdaDepth,
                     tyvarDepth = tyvarLambdaDepth}
                | _ =>
                  raise Bug.Bug
                          "non TVAR found in freeTvs in generalizer\
                          \ (types/main/TypesUtils)"
              )
              indexMap
      in
        if OTSet.isEmpty tids
        then ({boundEnv = BoundTypeVarID.Map.empty, removedTyIds = OTSet.empty})
        else
          let
            val btvs =
                IEnv.foldl
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
                    | _ => raise Bug.Bug "generalizeTy")
                  BoundTypeVarID.Map.empty
                  newIndexMap
          in
            ({boundEnv = btvs, removedTyIds = tids})
          end
      end

  (**
   * Perform imperative implace substitutrion.
   *)
  fun performSubst (T.TYVARty (r as ref(T.TVAR _)), ty) = r := T.SUBSTITUTED ty
    | performSubst _ =
      raise Bug.Bug "non TVAR in performSubst (types/mainTypesUtils.sml)"

  (**
   * Make a fresh copy of a bound type environment by allocating a new btvid
   * @params  boundEnv
   * @return subst bound type variable substitution
   *)
  fun copyBoundEnv (boundEnv:T.btvEnv) : T.ty BoundTypeVarID.Map.map * T.btvEnv = 
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
                   | _ => raise Bug.Bug "copyBoundEnv"))
              BoundTypeVarID.Map.empty
              boundEnv
      in
        (newSubst, newBoundEnv)
      end

  fun coerceFunM (ty, tyList) =
      case derefTy ty of
          oldTy as T.TYVARty
                (ref (T.TVAR {lambdaDepth,
                              id,
                              tvarKind = T.UNIV,
                              eqKind,
                              occurresIn,
                              utvarOpt = NONE})) => 
          let 
            (* 2012-7-27 ohori. eqKind must be NONEQ *)
            val _ = case eqKind of A.EQ => raise CoerceFun | _ => ()
(* 2012-7-27 ohori. The following does not make sense:
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
*)
              val tyList = map (fn x => T.newty T.univKind) tyList
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


(*
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
*)

  fun tpappPrimTy ({boundtvars, argTyList, resultTy}, tyl) =
      let
        val subst =
            ListPair.foldr
              (fn (i,ty,subst) => BoundTypeVarID.Map.insert (subst, i, ty))
              BoundTypeVarID.Map.empty
              (BoundTypeVarID.Map.listKeys boundtvars, tyl)
      in
        {argTyList = map (substBTvar subst) argTyList,
         resultTy = substBTvar subst resultTy}
      end

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
        Bug.Bug
            ("tpappTy:"
             ^ Bug.prettyPrint (Types.format_ty nil ty1)
             ^ ", "
             ^ "{" ^
             concat(map (fn x => Bug.prettyPrint (Types.format_ty nil x))
                        tyl)
             ^ "}")

  fun tyConFromConTy ty =
      case derefTy ty of
        T.POLYty{body,...} =>
        (case derefTy body of
           T.FUNMty(_, ty) =>
           (case derefTy ty of
              T.CONSTRUCTty{tyCon,...} => tyCon
            | _ => raise bug "tyConFromConTy:non con ty"
           )
         | ty =>
           (case derefTy ty of
              T.CONSTRUCTty{tyCon,...} => tyCon
            | _ => raise bug "tyConFromConTy:non con ty"
           )
        )
      | T.FUNMty(_,ty) =>
        (case derefTy ty of
           T.CONSTRUCTty {tyCon,...} => tyCon
         | _ => raise bug "tyConFromConTy:non con ty"
        )
      | T.CONSTRUCTty{tyCon,...} => tyCon
      | _ => raise bug "tyConFromConTy:non con ty"

  fun tupleTy tys =
      T.RECORDty
        (#2 (List.foldl
               (fn (ty,(i,z)) => (i+1, LabelEnv.insert (z, Int.toString i, ty)))
               (1, LabelEnv.empty)
               tys))

end
end
