(**
 * utility functions for manupilating types (needs re-writing).
 * @copyright (C) 2021 SML# Development Team.
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
  type ty = T.ty
  type varInfo = T.varInfo

  fun bug s = Bug.Bug ("TypesUtils: " ^ s)
  fun printType ty = print (Bug.prettyPrint (T.format_ty ty))
  fun printKind kind = print (Bug.prettyPrint (T.format_tvarKind kind))
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
        T.BACKENDty (substBTvarBackendTy tyidEnv subst backendTy)
      | T.ERRORty => ty
      | T.DUMMYty (dummyTyID, kind) =>
        T.DUMMYty (dummyTyID, substBTvarKind tyidEnv subst kind)
      | T.EXISTty (existTyID, kind) =>
        T.EXISTty (existTyID, substBTvarKind tyidEnv subst kind)
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
        T.RECORDty (RecordLabel.Map.map (substBTvar tyidEnv subst) tySenvMap)
      | T.CONSTRUCTty {tyCon,args} =>
        T.CONSTRUCTty {tyCon=substBTvarTyCon tyidEnv subst tyCon,
                       args = map (substBTvar tyidEnv subst) args}
      | T.POLYty {boundtvars, constraints, body} =>
        let
          val (subst, boundtvars) = substBTvarBtvEnv tyidEnv subst boundtvars
          val constraints = 
              List.map
                  (fn c =>
                      case c of T.JOIN {res, args = (arg1, arg2), loc} =>
                        T.JOIN
                            {res = substBTvar tyidEnv subst res,
                             args = (substBTvar tyidEnv subst arg1,
                                     substBTvar tyidEnv subst arg2),
                             loc = loc})
                  constraints
          val newTy = T.POLYty{boundtvars = boundtvars, 
                               constraints = constraints,
                               body = substBTvar tyidEnv subst body}
        in
          newTy
        end
  and substBTvarBtvEnv tyidEnv subst btvEnv =
      let
        val subst =
            BoundTypeVarID.Map.filteri
              (fn (id, _) =>
                  not (BoundTypeVarID.Map.inDomain (btvEnv, id)))
              subst
        val btvEnv =
            BoundTypeVarID.Map.map
              (substBTvarKind tyidEnv subst)
              btvEnv
      in
        (subst, btvEnv)
      end
  and substBTvarSingletonTy tyidEnv subst singletonTy =
      case singletonTy of
        T.INSTCODEty {oprimId, longsymbol, match} =>
        T.INSTCODEty {oprimId = oprimId,
                      longsymbol = longsymbol,
                      match = substBTvarOverloadMatch tyidEnv subst match}
      | T.INDEXty (label, ty) =>
        T.INDEXty (label, substBTvar tyidEnv subst ty)
      | T.TAGty ty =>
        T.TAGty (substBTvar tyidEnv subst ty)
      | T.SIZEty ty =>
        T.SIZEty (substBTvar tyidEnv subst ty)
      | T.REIFYty ty =>
        T.REIFYty (substBTvar tyidEnv subst ty)
  and substBTvarBackendTy tyidEnv subst backendTy =
      case backendTy of
        T.RECORDSIZEty ty =>
        T.RECORDSIZEty (substBTvar tyidEnv subst ty)
      | T.RECORDBITMAPty (i, ty) =>
        T.RECORDBITMAPty (i, substBTvar tyidEnv subst ty)
      | T.RECORDBITMAPINDEXty (i, ty) =>
        T.RECORDBITMAPINDEXty (i, substBTvar tyidEnv subst ty)
      | T.CCONVTAGty {tyvars, tyArgs, haveClsEnv, argTyList, retTy} =>
        let
          val (subst, tyvars) = substBTvarBtvEnv tyidEnv subst tyvars
        in
          T.CCONVTAGty
            {tyvars = tyvars,
             tyArgs = tyArgs,
             haveClsEnv = haveClsEnv,
             argTyList = map (substBTvar tyidEnv subst) argTyList,
             retTy = substBTvar tyidEnv subst retTy}
        end
      | T.FUNENTRYty {tyvars, tyArgs, haveClsEnv, argTyList, retTy} =>
        let
          val (subst, tyvars) = substBTvarBtvEnv tyidEnv subst tyvars
        in
          T.FUNENTRYty
            {tyvars = tyvars,
             tyArgs = tyArgs,
             haveClsEnv = haveClsEnv,
             argTyList = map (substBTvar tyidEnv subst) argTyList,
             retTy = substBTvar tyidEnv subst retTy}
        end
      | T.CALLBACKENTRYty {tyvars, haveClsEnv, argTyList, retTy, attributes} =>
        let
          val (subst, tyvars) = substBTvarBtvEnv tyidEnv subst tyvars
        in
          T.CALLBACKENTRYty
            {tyvars = tyvars,
             haveClsEnv = haveClsEnv,
             argTyList = map (substBTvar tyidEnv subst) argTyList,
             retTy = Option.map (substBTvar tyidEnv subst) retTy,
             attributes = attributes}
        end
      | T.SOME_FUNENTRYty => T.SOME_FUNENTRYty
      | T.SOME_FUNWRAPPERty => T.SOME_FUNWRAPPERty
      | T.SOME_CLOSUREENVty => T.SOME_CLOSUREENVty
      | T.SOME_CCONVTAGty => T.SOME_CCONVTAGty
      | T.FOREIGNFUNPTRty {argTyList, varArgTyList, resultTy, attributes} =>
        T.FOREIGNFUNPTRty
          {argTyList = map (substBTvar tyidEnv subst) argTyList,
           varArgTyList =
             Option.map (map (substBTvar tyidEnv subst)) varArgTyList,
           resultTy = Option.map (substBTvar tyidEnv subst) resultTy,
           attributes = attributes}
  and substBTvarTyCon tyidEnv subst ({id, longsymbol,admitsEq,arity,conSet, conIDSet, extraArgs,dtyKind}) =
      {id=id, longsymbol=longsymbol, admitsEq=admitsEq, arity=arity, conSet=conSet,
       conIDSet=conIDSet,
       extraArgs = map (substBTvar tyidEnv subst) extraArgs,
       dtyKind=(substBTvarDtyKind tyidEnv subst dtyKind)} 
  and substBTvarDtyKind tyidEnv subst dtyKind =
      case dtyKind of
        T.DTY _ => dtyKind
      | T.OPAQUE {opaqueRep, revealKey} =>
        T.OPAQUE {opaqueRep = substBTvarOpaqueRep tyidEnv subst opaqueRep, revealKey=revealKey}
      | T.INTERFACE opaqueRep =>
        T.INTERFACE (substBTvarOpaqueRep tyidEnv subst opaqueRep)
  and substBTvarOpaqueRep tyidEnv subst opaqueRep =
      case opaqueRep of
        T.TYCON tyCon  => T.TYCON (substBTvarTyCon tyidEnv subst tyCon)
      | T.TFUNDEF {admitsEq, arity, polyTy} =>
        T.TFUNDEF {admitsEq=admitsEq, arity=arity, polyTy=substBTvar tyidEnv subst polyTy}

(* This is wrong; we should not update the original ref.
  and substBTvarTvstate subst tvstate =
      case tvstate of
        T.TVAR {lambdaDepth,id,tvarKind,eqKind,utvarOpt} => tvstate
      | T.SUBSTITUTED ty => T.SUBSTITUTED (substBTvar subst ty)

   Ohori: 2012-4-14.
   Updating type variables for TVAR seem to be OK. 
   Updating T.SUBSTITUTED causes probem. I do not know why.
*)      
  and substBTvarKind tyidEnv subst (T.KIND (kind as {tvarKind, properties, dynamicKind})) =
      T.KIND {tvarKind = substBTvarTvarKind tyidEnv subst tvarKind,
              properties = properties,
              dynamicKind = dynamicKind}

  and substBTvarTvarKind tyidEnv subst tvarKind =
      case tvarKind of
        T.REC fields => T.REC (RecordLabel.Map.map (substBTvar tyidEnv subst) fields)
      | T.UNIV => T.UNIV
      | T.OCONSTkind l => 
        T.OCONSTkind (map (substBTvar tyidEnv subst) l)
      | T.OPRIMkind {instances, operators} =>
        T.OPRIMkind 
          {instances = map (substBTvar tyidEnv subst) instances,
           operators =
           map (fn {oprimId, longsymbol, match} =>
                   {oprimId = oprimId,
                    longsymbol = longsymbol,
                    match = substBTvarOverloadMatch tyidEnv subst match})
               operators
          }

  and substBTvarOverloadMatch tyidEnv subst match =
      case match of
        T.OVERLOAD_EXVAR {exVarInfo, instTyList} =>
        T.OVERLOAD_EXVAR {exVarInfo = exVarInfo,
                          instTyList = Option.map (map (substBTvar tyidEnv subst)) instTyList}
      | T.OVERLOAD_PRIM {primInfo, instTyList} =>
        T.OVERLOAD_PRIM {primInfo = primInfo,
                         instTyList = Option.map (map (substBTvar tyidEnv subst)) instTyList}
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
  val substBTvarKind = fn subst => fn kind =>
      substBTvarKind emptyVisitEnv subst kind
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
  fun makeFreshSubst lambdaDepth utvarOpt boundEnv =
      let
        val subst =
            BoundTypeVarID.Map.map
              (fn k => 
                  let
                    val newTy = 
                        T.newtyRaw {
                        lambdaDepth = lambdaDepth,
                        kind = #kind T.univKind,
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
                     SOME (kind as T.KIND {properties, ...}) =>
                     let
                       val uvtarOpt =
                           case utvarOpt of
                             NONE => NONE
                           | SOME{symbol, id,...} => 
                             SOME{symbol=symbol,id=id,eq=T.isProperties T.EQ properties}
                     in
                       (ty, utvarOpt, substBTvarKind subst kind)
                     end
                   | _ => raise Bug.Bug "fresh Subst")
              )
              subst
        val _ =
            BoundTypeVarID.Map.appi
              (fn (i, (ty as T.TYVARty(r as ref (T.TVAR {id,...})), utvarOpt, kind)) =>
                  r := 
                   T.TVAR
                     {
                      lambdaDepth = T.infiniteDepth,
                      id = id,
                      kind = kind,
                      utvarOpt = utvarOpt
                     }
                | _ => raise Bug.Bug "fresh Subst")
              newSubst
      in
        subst
      end
  fun freshSubst boundEnv = makeFreshSubst T.infiniteDepth NONE boundEnv

  fun freshRigidSubst boundEnv = 
      let
        val id = TvarID.generate()
        val symbol = Symbol.mkSymbol "RIGID" Loc.noloc
        val tvar = {symbol=symbol, isEq=false, id=id, lifted=false}
        val utvarOpt = SOME tvar
      in
        makeFreshSubst T.infiniteDepth utvarOpt boundEnv
      end

  fun freshSubstWithLambdaDepth lambdaDepth boundEnv = makeFreshSubst lambdaDepth NONE boundEnv

  fun freshRigidSubstWithLambdaDepth lambdaDepth boundEnv =
      let
        val id = TvarID.generate()
        val symbol = Symbol.mkSymbol "RIGID" Loc.noloc
        val tvar = {symbol=symbol, isEq=false, id=id, lifted=false}
        val utvarOpt = SOME tvar
      in
        makeFreshSubst lambdaDepth utvarOpt boundEnv
      end

  (**
   * Check whether a type is a mono type or not.
   *)
  fun monoTy ty =
      let
        exception PolyTy
        fun visit ty =
(* 2024-12-06 Ohori: Obviously, we need to derefTy here.
            case ty of  
*)
            case derefTy ty of
              T.SINGLETONty _ => raise Bug.Bug "monoTy: SINGLETONty"
            | T.BACKENDty backendTy => raise Bug.Bug "monoTy: BACKENDty"
            | T.ERRORty => ()
            | T.DUMMYty _ => ()
            | T.EXISTty _ => ()
            | T.TYVARty _ => ()
            | T.BOUNDVARty _ => (* raise PolyTy *) ()  (* this should be ok *)
            | T.FUNMty (_, ty) => visit ty
            | T.RECORDty tySenvMap => RecordLabel.Map.app visit tySenvMap
            | T.CONSTRUCTty _ => ()
            | T.POLYty {boundtvars, constraints, body} => raise PolyTy
      in
        (visit ty; true)
        handle PolyTy => false
      end

  val emptyBTVSubst = BoundTypeVarID.Map.empty

  fun makeTopLevelFreshInstTy makeSubst ty =
      (* 2016-06-16 sasaki: constraitsを返すように変更 *)
      if monoTy ty then (ty, nil, emptyBTVSubst)
      else
        case ty of
          T.POLYty{boundtvars,body,constraints} =>
          let
            val subst = makeSubst boundtvars
            val bty = substBTvar subst body
            val constraints =
                List.map (fn c =>
                             case c of T.JOIN {res, args = (arg1, arg2), loc} =>
                               T.JOIN
                                   {res = substBTvar subst res,
                                    args = (substBTvar subst arg1,
                                            substBTvar subst arg2),
                                    loc = loc})
                         constraints
          in
            (bty, constraints, subst)
          end
        | ty => (ty, nil, emptyBTVSubst)

  fun makeFreshInstTy makeSubst ty =
      (* 2016-06-16 sasaki: constraitsを返すように変更 *)
      if monoTy ty then (ty, nil, emptyBTVSubst)
      else
        case ty of
          T.POLYty{boundtvars,body,constraints} =>
          let 
            val subst = makeSubst boundtvars
            val bty = substBTvar subst body
            val bconstraints = 
                List.map (fn c =>
                             case c of T.JOIN {res, args = (arg1, arg2), loc} =>
                               T.JOIN
                                   {res = substBTvar subst res,
                                    args = (substBTvar subst arg1,
                                            substBTvar subst arg2),
                                    loc = loc})
                         constraints
            val (freshty, freshconstraints, _) =
                makeFreshInstTy makeSubst bty
          in  
            (freshty, freshconstraints @ bconstraints, subst)
          end
        | T.FUNMty (tyList,ty) =>
          let
            val (freshty, constraints, _) = makeFreshInstTy makeSubst ty
          in
            (T.FUNMty(tyList, freshty), constraints, emptyBTVSubst)
          end
        | T.RECORDty fl => 
          let
            val (fl, constraints) =
                RecordLabel.Map.foldli
                    (fn (key, ty, (map, constraints)) =>
                        let val (freshty, freshconstraints, _) =
                                makeFreshInstTy makeSubst ty
                        in (RecordLabel.Map.insert (map, key, freshty),
                            freshconstraints @ constraints)
                        end)
                    (RecordLabel.Map.empty, nil)
                    fl
          in 
            (T.RECORDty fl, constraints, emptyBTVSubst)
          end
        | ty => (ty, nil, emptyBTVSubst)

  fun freshInstTy ty = 
      let
        val (ty, constraints, subst) = makeFreshInstTy freshSubst ty
      in
        (ty, constraints)
      end
  fun freshRigidInstTy ty = 
      let
        val (ty, constraints, subst) = makeFreshInstTy freshRigidSubst ty
        val addedUtvars = 
            BoundTypeVarID.Map.foldl
              (fn (ty, addedUtvars) =>
                  let
                    val ty = derefTy ty
                  in
                    case ty of
                      T.TYVARty (r as ref (tvState as  (T.TVAR  {id, utvarOpt = SOME utvar,...})))
                      => TvarMap.insert(addedUtvars, utvar, r)
                    | _ => addedUtvars
                  end
              )
            TvarMap.empty
            subst
      in
        (ty, constraints, addedUtvars)
      end

  fun freshTopLevelRigidInstTy ty =
      let
        val (ty, const, subst) = makeTopLevelFreshInstTy freshRigidSubst ty
      in
        (ty, const, BoundTypeVarID.Map.listItems subst)
      end

  exception ExSpecTyCon of string
  exception ExIllegalTyFunToTyCon of string
  exception CoerceFun 
  exception CoerceTvarKindToEQ 

  (* 2013-4-12 Ohori
     This returns the maxmum index, tvstate ref set, and an index map.
     The index map represent the occurrecen order of each type variable.
   *)
  (* 2013-7-26 Ohori
     EFTV should not traverse operators in OPRIMkind.
   *)
 local
   fun traverseTy (ty, env as (tvset as (i, set, indexMap), btvset)) =
       case ty of
         T.SINGLETONty sty => raise Bug.Bug "SINGLETONty to EFTV"
       | T.BACKENDty bty => raise Bug.Bug "BACKENDty to EFTV"
       | T.ERRORty => env
       | T.DUMMYty (id, kind) => traverseKind (kind, env)
       | T.EXISTty (id, kind) => traverseKind (kind, env)
       | T.TYVARty (ref(T.SUBSTITUTED ty)) => traverseTy (ty,env)
       | T.TYVARty (ref(T.TVAR {kind = T.KIND {tvarKind=T.OCONSTkind _,...},...})) => env
       | T.TYVARty (tyvarRef as (ref(T.TVAR tvKind))) =>
         if OTSet.member(set, tyvarRef) then env
         else 
            traverseTvKind
              (tvKind,
               ((i+1,
                 OTSet.add(set, tyvarRef),
                 IEnv.insert(indexMap, i, tyvarRef)),
                btvset)
              )
       | T.BOUNDVARty int =>
         (tvset, BoundTypeVarID.Set.add (btvset, int))
       | T.FUNMty (tyList, ty) =>
         traverseTy (ty, foldl traverseTy env tyList)
       | T.RECORDty tyLabelEnvMap => 
         RecordLabel.Map.foldl traverseTy env tyLabelEnvMap
       | T.CONSTRUCTty {tyCon, args = tyList} => foldl traverseTy env tyList
       | T.POLYty {boundtvars, constraints=conPoly, body=ty} =>
         let
           val (tvset, btvset) =
               traverseTy
                 (ty,
                  BoundTypeVarID.Map.foldl
                    traverseKind
                    env
                    boundtvars)
         in
           (tvset,
            BoundTypeVarID.Set.filter
              (fn x => not (BoundTypeVarID.Map.inDomain (boundtvars, x)))
              btvset)
         end
   and traverseTvKind ({lambdaDepth, id, kind, utvarOpt}, env) = 
       traverseKind (kind, env) 
   and traverseKind (T.KIND {tvarKind, properties, dynamicKind}, env) =
       case tvarKind of
         T.UNIV=> env
       | T.REC fields => 
         RecordLabel.Map.foldl traverseTy env fields
       | T.OCONSTkind _ =>
         raise Bug.Bug "OCONSTkind to travseTvKind"
       | T.OPRIMkind {instances, operators} =>
(* 2013-7-26 ohori bug 264_invalidDbi *)
(* 2020-1-21 以下を復活 *)
         foldl traverseOprimSelector
               (foldl traverseTy env instances)
               operators
   and traverseOprimSelector ({oprimId, longsymbol, match}
                              : T.oprimSelector, env) =
       traverseOverloadMatch (match, env)
   and traverseOverloadMatch (match, env) =
       case match of
         T.OVERLOAD_EXVAR {exVarInfo, instTyList = NONE} => env
       | T.OVERLOAD_EXVAR {exVarInfo, instTyList = SOME instTyList} =>
         foldl traverseTy env instTyList
       | T.OVERLOAD_PRIM {primInfo, instTyList = NONE} => env
       | T.OVERLOAD_PRIM {primInfo, instTyList = SOME instTyList} =>
         foldl traverseTy env instTyList
       | T.OVERLOAD_CASE (ty, map) =>
         TypID.Map.foldl traverseOverloadMatch (traverseTy (ty, env)) map

   (* traverseはstableになるまで実行する必要がある．*)
     fun traverseConstraints (env as (_, tyset, _)) constraints = 
         let
           fun traverseTy' (ty, env) =
               #1 (traverseTy (ty, (env, BoundTypeVarID.Set.empty)))
           fun traverse env nil  = env
             | traverse (env as (_, tyset, _)) (T.JOIN {res, args = (arg1, arg2), loc} :: tail) = 
               let
                 val (_, newTyset1, _) = traverseTy' (arg1, (0, OTSet.empty, IEnv.empty))
                 val (_, newTyset2, _) = traverseTy' (arg2, (0, OTSet.empty, IEnv.empty))
                 val (_, newTyset3, _) = traverseTy' (res, (0, OTSet.empty, IEnv.empty))
                 val env = 
                     if not (OTSet.isEmpty (OTSet.intersection (tyset, newTyset1)))
                        orelse  not (OTSet.isEmpty (OTSet.intersection (tyset, newTyset2)))
                        orelse  not (OTSet.isEmpty (OTSet.intersection (tyset, newTyset3)))
                     then 
                        traverseTy' (arg1, traverseTy' (arg2, traverseTy' (res, env)))
                     else env
               in
                 traverse env tail
               end
           val (env as (_, newTyset, _)) = traverse env constraints
         in
           if OTSet.isEmpty (OTSet.difference(newTyset, tyset)) then env
           else traverseConstraints env constraints
         end
     val empty = ((0, OTSet.empty, IEnv.empty), BoundTypeVarID.Set.empty)
 in
   fun EFTV (ty, constraints) =
       traverseConstraints (#1 (traverseTy (ty, empty))) constraints
   fun EFTVTy ty = #1 (traverseTy (ty, empty))
   fun EFBTV ty = #2 (traverseTy (ty, empty))
 end      

  fun adjustDepthInTy changed contextDepth ty = 
    let
      val (_, tyset,_) = EFTV (ty, nil)
    in
      OTSet.app
      (fn (tyvarRef as 
          (ref (T.TVAR (tvKind as {lambdaDepth=tyvarDepth,...})))) =>
         if T.strictlyYoungerDepth 
              {tyvarDepth=tyvarDepth, contextDepth=contextDepth} 
         then
           (changed := true;
            tyvarRef := T.TVAR (tvKind # {lambdaDepth=contextDepth})
           )
         else ()
       | _ => raise Bug.Bug "non TVAR in adjustDepthInTy (TypesUtils.sml)"
      )
      tyset
    end

  fun adjustDepthInTvarKind changed contextDepth tvarKind = 
    case tvarKind of
      T.UNIV => ()
    | T.REC fields => 
        RecordLabel.Map.app (adjustDepthInTy changed contextDepth) fields
    | T.OCONSTkind tyList => 
        List.app (adjustDepthInTy changed contextDepth) tyList
    | T.OPRIMkind {instances = tyList,...} => 
        List.app (adjustDepthInTy changed contextDepth) tyList
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
  fun generalizer (ty, constraints, contextLambdaDepth) =
      let 
        val (i, freeTvs, indexMap) = EFTV (ty, constraints)
        fun isFree (ref(T.TVAR{id, kind = T.KIND {tvarKind = T.OCONSTkind _, ...}, ...})) =
            raise Bug.Bug "OCONSTkind ty to generalizer"
          | isFree (ref (T.TVAR {lambdaDepth = tyvarLambdaDepth,...})) =
            T.youngerDepth
              {contextDepth = contextLambdaDepth,
               tyvarDepth = tyvarLambdaDepth}
          | isFree _ = 
            raise Bug.Bug "non TVAR found in freeTvs in generalizer"
        val newFreeTvs = OTSet.filter isFree freeTvs
        val newIndexMap = IEnv.filter (fn tvref => OTSet.member(newFreeTvs, tvref)) indexMap
      in
        if OTSet.isEmpty newFreeTvs
        then ({boundEnv = BoundTypeVarID.Map.empty, removedTyIds = OTSet.empty, boundConstraints = nil})
        else
          let
            fun toBeBound (T.JOIN {res, args = (ty1, ty2), loc}) =
                let
                  val (_, tvarSet1, _) =  EFTVTy res
                  val (_, tvarSet2, _) =  EFTVTy ty1
                  val (_, tvarSet3, _) =  EFTVTy ty2
                  val tvarSet = OTSet.union(tvarSet1, OTSet.union(tvarSet2, tvarSet2))
                in
                  OTSet.isSubset(tvarSet, newFreeTvs)
                end
            val bcs = List.filter toBeBound constraints
            val btvs =
                IEnv.foldl
                  (fn (r as ref(T.TVAR (k as {id, kind, ...})), btvs) =>
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
                             kind
                            )
                         )
                        )
                      end
                    | _ => raise Bug.Bug "generalizeTy")
                  BoundTypeVarID.Map.empty
                  newIndexMap
          in
            ({boundEnv = btvs, removedTyIds = newFreeTvs, boundConstraints = bcs})
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
              (fn (oldId, kind, newBoundEnv) =>
                  (case BoundTypeVarID.Map.find(newSubst, oldId) of
                     SOME (T.BOUNDVARty newId) =>
                     BoundTypeVarID.Map.insert
                       (newBoundEnv, 
                        newId, 
                        substBTvarKind newSubst kind)
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
                              kind = T.KIND {tvarKind = T.UNIV,
                                             properties,
                                             dynamicKind},
                              utvarOpt = NONE})) => 
          let 
            (* 2012-7-27 ohori. eqKind must be NONEQ *)
            val _ = if T.isProperties T.EQ properties then raise CoerceFun else ()
            val _ = if T.isProperties T.UNBOXED properties then raise CoerceFun else ()
            val tyList = map (fn x => T.newty T.univKind) tyList
            val ty2 = T.newty T.univKind
            val resTy = T.FUNMty(tyList, ty2)
            val _ = adjustDepthInTy (ref false) lambdaDepth resTy
            val _ = performSubst (oldTy, resTy)
          in
            (tyList, ty2, NONE, nil)
          end
        | T.TYVARty (ref (T.TVAR {utvarOpt = SOME _,...})) => 
           raise CoerceFun
        | T.TYVARty (ref(T.SUBSTITUTED ty)) => 
          coerceFunM (ty, tyList)
        | T.FUNMty (tyList, ty2) => 
          (tyList, ty2, NONE, nil)
        | T.POLYty {boundtvars, constraints, body} =>
          (case derefTy body of
             T.FUNMty(tyList,ty2) =>
             let 
               val subst1 = freshSubst boundtvars
               val argTyList = map (substBTvar subst1) tyList
               val ranTy = substBTvar subst1 ty2
               val btvInstTyList = BoundTypeVarID.Map.listItemsi subst1
               val instTyList = map #2 btvInstTyList
               val constraints =
                   List.map (fn c =>
                                case c of T.JOIN {res, args = (arg1, arg2), loc} =>
                                  T.JOIN
                                      {res = substBTvar subst1 res,
                                       args = (substBTvar subst1 arg1,
                                               substBTvar subst1 arg2),
                                       loc = loc})
                            constraints
             in
               (argTyList,ranTy,SOME instTyList,constraints)
             end
           | T.ERRORty => (map (fn x => T.ERRORty) tyList, T.ERRORty, NONE, nil)
           | _ => raise CoerceFun
          )
        | T.ERRORty => (map (fn x => T.ERRORty) tyList, T.ERRORty, NONE, nil)
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
              val _ = adjustDepthInTy changed lambdaDepth resTy
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

  fun tpappTy (T.TYVARty (ref (T.SUBSTITUTED ty)), tyl) =
      tpappTy (ty, tyl)
    | tpappTy (T.POLYty{boundtvars, body, ...}, tyl) = 
      let
        val subst = 
            ListPair.foldrEq
                (fn ((i, _), ty, S) => BoundTypeVarID.Map.insert(S, i, ty))
                BoundTypeVarID.Map.empty
                (BoundTypeVarID.Map.listItemsi boundtvars, tyl)
            handle ListPair.UnequalLengths =>
                   raise Bug.Bug "tpappTy: arity mismatch"
      in 
        substBTvar subst body
      end
    | tpappTy (ty, nil) = ty
    | tpappTy (ty1, tyl) =
      raise
        Bug.Bug
            ("tpappTy:"
             ^ Bug.prettyPrint (Types.format_ty ty1)
             ^ ", "
             ^ "{" ^
             concat(map (fn x => Bug.prettyPrint (Types.format_ty x))
                        tyl)
             ^ "}")

  fun revealTy ty =
      case ty of
        T.TYVARty (ref (T.SUBSTITUTED ty)) => revealTy ty
      | T.CONSTRUCTty {tyCon, args} =>
        (case #dtyKind tyCon of
           T.DTY _ => ty
         | T.OPAQUE {opaqueRep = T.TYCON tyCon, ...} =>
           revealTy (T.CONSTRUCTty {tyCon = tyCon, args = args})
         | T.OPAQUE {opaqueRep = T.TFUNDEF {polyTy, ...}, ...} =>
           revealTy (tpappTy (polyTy, args))
         | T.INTERFACE (T.TYCON tyCon) =>
           revealTy (T.CONSTRUCTty {tyCon = tyCon, args = args})
         | T.INTERFACE (T.TFUNDEF {polyTy, ...}) =>
           revealTy (tpappTy (polyTy, args)))
      | ty => ty

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
      T.RECORDty (RecordLabel.tupleMap tys)

end
end
