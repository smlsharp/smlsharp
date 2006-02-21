(**
 * Copyright (c) 2006, Tohoku University.
 *
TODO:
  1.  ***compTy in RecordCompile.sml loop bug**** the fix is temporary

 * utility functions for manupilating types (needs re-writing).
 * @author Atsushi Ohori 
 * @version $Id: TypesUtils.sml,v 1.3 2006/02/18 04:59:36 ohori Exp $
 *)
structure TypesUtils =
struct

  local 
    open Types StaticEnv
    structure SE = StaticEnv
  in

  exception ExSpecTyCon of string
  exception ExIllegalTyFunToTyName of string
  exception CoerceFun 

  fun derefTy (TYVARty(ref (SUBSTITUTED ty))) = derefTy ty
    | derefTy (ALIASty (ty1, ty2)) = derefTy ty2
    | derefTy ty = ty

  fun pruneTy ty = 
      case ty of
        TYVARty (ref(SUBSTITUTED ty)) => pruneTy ty
      | ALIASty (ty1, ty2) => pruneTy ty2
      | POLYty {boundtvars, body = TYVARty(ref(SUBSTITUTED ty))} =>
        pruneTy (POLYty {boundtvars = boundtvars, body = ty})
      | _ => ty

  fun constTy const =
      case const of
        INT _ => intty
      | WORD _ => wordty
      | REAL _ => realty
      | STRING _ => stringty
      | CHAR _ => charty

  fun tyConId (conInfo:tyCon) = #id conInfo

  fun eqTyCon (conInfo1 : tyCon, conInfo2 : tyCon) =
      (tyConId conInfo1) = (tyConId conInfo2)

  local
    exception NotAdmitEq
  in
  fun admitEqTy ty =
      (TypeTransducer.foldTyPreOrder
         (fn (ty, _) =>
             case ty of
               ALIASty (ty1,ty2) => (admitEqTy ty2,false)
             | FUNMty _ => raise NotAdmitEq
	     | CONty {tyCon = {name = "ref",...},...} =>
	       (true,false)
             | CONty {tyCon = {name = "array",...},...} =>
	       (true,false)
             | CONty {tyCon = {eqKind = ref NONEQ, ...}, ...} =>
               raise NotAdmitEq
	     | ABSSPECty (specTy,_) => (admitEqTy specTy,false)
             | TYVARty (ref(TVAR {eqKind = NONEQ, ...})) => raise NotAdmitEq
             | _ => (true, true))
         true
         ty)
      handle NotAdmitEq => false
  end

  fun admitEqTyFun {name, tyargs, body} = admitEqTy body

  fun admitEqTyBindInfo tyBindInfo =
      case tyBindInfo of
	TYSPEC {spec = {eqKind = EQ,...},...} => true
      | TYCON {eqKind = ref EQ,...} => true
      | TYFUN tyFun => admitEqTyFun tyFun
      | _ => false

  (*
   * Returns a new generative type constructor. 
   *)
  fun newTyCon {name, strpath, abstract, tyvars, eqKind, boxedKind, datacon} = 
      let val id = SE.newTyConId()
      in
        {
          name = name,
	  strpath = strpath,
	  abstract = abstract,
          tyvars = tyvars, 
          eqKind = eqKind,
          datacon = datacon,
	  boxedKind = boxedKind,
          id = id
        } : Types.tyCon
      end

  fun extractAliasTyImpl aliasTy =
      case aliasTy of
	ALIASty(_,ty) => extractAliasTyImpl ty
      | ty => ty
      
  (* 
   * the tagid is the integer position of the datatype declaration starting
   * with 0.
   *)
  fun computeTagId
      {
        name = conName,
        funtyCon,
        ty,
        tag,
        tyCon
      } =  INT tag


  fun tyconSpan ({datacon = ref datacon,...}:tyCon) = SEnv.numItems datacon



  fun typeOfIdstate idstate =
      case idstate of
        VARID varPathInfo => #ty varPathInfo
      | CONID conPathInfo => #ty conPathInfo
      | PRIM primInfo => #ty primInfo
      | OPRIM oprimInfo => #ty oprimInfo


  (**
   * Substitute bound type variables in a type.
   * only the monomorphic potion of the target contain the bound type variables
   * to be substituted.
   * @params subst type 
   * @param subst substitution. The domain is an integer interval.
   * @return
   *)

  fun applyMatch subst ty =
      if IEnv.isEmpty subst
      then ty
      else 
        TypeTransducer.mapTyPreOrder
            (fn (ty as BOUNDVARty n) =>
                ((valOf (IEnv.find(subst, n))) handle Option => ty, true)
              | (ty as POLYty _) => (ty, false)
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
        fun preVisitor (ty, substs as (subst :: _)) =
            case ty of
              POLYty{boundtvars, body} =>
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
                      POLYty{boundtvars = newBoundtvars, body = body},
                      newSubst :: substs,
                      true
                    )
                  end
              end
            | ty => (ty, substs, true)

        (* pop a newSubst pushed by preVisitor from the substs stack. *)
        fun postVisitor (ty, substs as (subst :: _)) =
            case ty of
              POLYty _ => (ty, tl substs)
            | (ty as BOUNDVARty n) =>
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
            val (newTy, [_]) =
                TypeTransducer.transTy preVisitor postVisitor [subst] ty
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
  and substBTvarRecKind subst recKind =
      case recKind of
	REC fields => REC (SEnv.map (substBTvar subst) fields)
      | k => k
  and substBTvarBTKind subst {index, recKind, eqKind} =
      {
        index = index,
        recKind = substBTvarRecKind subst recKind,
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
  fun performSubst (TYVARty (r as ref(TVAR _)), ty) = r := SUBSTITUTED ty
    | performSubst _ = raise Control.Bug "performSubst"

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
            (fn x => newty 
                         {
                          recKind = UNIV,
                          eqKind = NONEQ,
                          tyvarName = NONE
                          })
            boundEnv
	val _ =
            IEnv.appi
                (fn (i,TYVARty(r as ref (TVAR {id, tyvarName, ...}))) => 
		    r := 
		    (case IEnv.find(boundEnv, i) of
		       SOME {index, recKind, eqKind} => 
                       (case recKind of 
                            REC _ => kindedTyvarList := r :: (!kindedTyvarList)
                          | OVERLOADED _ => kindedTyvarList := r :: (!kindedTyvarList)
                          | _ => ();
		       TVAR
                           {
                             id = id, 
			     recKind = substBTvarRecKind newSubst recKind,
			     eqKind = eqKind,
			     tyvarName = tyvarName
                           })
                     | _ => raise Control.Bug "fresh Subst")
                  | _ => raise Control.Bug "freshSubst")
	        newSubst
      in
	newSubst
      end
  (*
    exception CoerceFunM
  *)
  fun coerceFunM (ty, tyList) =
      case derefTy ty of
       newTy as TYVARty (ref (TVAR {id, recKind = UNIV, eqKind, tyvarName})) => 
        let 
          val tyList = map (fn x => newty univKind) tyList
          val ty2 = newty univKind
          val _ = performSubst (newTy, FUNMty(tyList, ty2))
        in
          (tyList, ty2, nil)
        end
      | TYVARty (ref(SUBSTITUTED ty)) => coerceFunM (ty, tyList)
      | FUNMty (tyList, ty2) => (tyList, ty2, nil)
      | POLYty {boundtvars, body} =>
        (case derefTy body of
              FUNMty(tyList,ty2) =>
                let val subst1 = freshSubst boundtvars
                in
                  (
                   map (substBTvar subst1) tyList,
                   substBTvar subst1 ty2,
                   IEnv.listItems subst1
                   )
                end
            | ERRORty => (map (fn x => ERRORty) tyList, ERRORty, nil)
            | ALIASty(_, ty) => coerceFunM (ty, tyList)
            | _ => raise CoerceFun
         )
      | ALIASty(_, ty) => coerceFunM (ty, tyList)
      | ERRORty => (map (fn x => ERRORty) tyList, ERRORty, nil)
      | _ => raise CoerceFun


  (*
   * Make a fresh substitution for bound tvars with *named* tyvars.
   * This is used in Sigmatch
   *)
  fun freshRigidSubst boundEnv = 
      let
        val newSubst =
            IEnv.map
            (fn x => newty
                         {
                          recKind = UNIV,
                          eqKind = NONEQ,
                          tyvarName = SOME "RIGID"
                          })
            boundEnv
	val _ =
            IEnv.appi
                (fn (i,TYVARty(r as ref (TVAR {id, tyvarName, ...}))) => 
		    r := 
		    (case IEnv.find(boundEnv, i) of
		       SOME {index, recKind, eqKind} => 
                         (case recKind of 
                            REC _ => kindedTyvarList := r :: (!kindedTyvarList)
                          | OVERLOADED _ => kindedTyvarList := r :: (!kindedTyvarList)
                          | _ => ();		
                          TVAR
                            {
                             id = id, 
			     recKind = substBTvarRecKind newSubst recKind,
			     eqKind = eqKind,
			     tyvarName = tyvarName
                             }
                          )
                     | _ => raise Control.Bug "fresh Subst")
                  | _ => raise Control.Bug "freshSubst")
	        newSubst
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
                      IEnv.insert
                      (
                        Env,
                        i,
                        newty
                        {
                         recKind = UNIV,
                         eqKind = NONEQ,
                         tyvarName = NONE
                         }
                      ))
	        IEnv.empty
	        boundEnv
	val _ =
            IEnv.appi
                (fn (i, TYVARty(r as ref (TVAR {id, tyvarName, ...}))) => 
                   r := 
                     (case IEnv.find(boundEnv, i) of
		       SOME {index, recKind, eqKind} => 
                         (case recKind of 
                            REC _ => kindedTyvarList := r :: (!kindedTyvarList)
                          | OVERLOADED _ => kindedTyvarList := r :: (!kindedTyvarList)
                          | _ => ();
                         TVAR
                            {
                             id = id, 
			     recKind = substBTvarRecKind newSubst recKind,
			     eqKind = eqKind,
			     tyvarName = tyvarName
                             })
                          | _ => raise Control.Bug "fresh Subst")
                | _ => raise Control.Bug "complementBSubst")
	        newSubst
      in
	IEnv.unionWith 
	    (fn x => raise Control.Bug "complementBSubstSubst")
	    (BS, newSubst)
      end

  local 
    exception FALSE 
  in
  (**
   * Check whether a type is a mono type or not.
   *)
  fun monoTy ty =
      TypeTransducer.foldTyPreOrder
          (fn (POLYty _, _) => raise FALSE
            | (BOUNDVARty _, _) => raise FALSE
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
   *)
  fun EFTV ty =
      TypeTransducer.foldTyPostOrder
          (fn (TYVARty (ref(TVAR {recKind = OVERLOADED _,...})), set)  => set
            | (TYVARty (tyvarRef as (ref(TVAR tvKind))), set)  => 
              let
                fun EFTVKind set =
	            case tvKind of
		      {recKind = UNIV, ...} => set
	            | {recKind = REC fields, ...} => 
		      SEnv.foldl
                          (fn (ty, set) => OTSet.union(set, EFTV ty))
		          set
		          fields
                    | {recKind = OVERLOADED _, ...} => raise Control.Bug "EFTV Overloaded"
              in 
                OTSet.union(set, EFTVKind (OTSet.singleton tyvarRef))
              end
            | (_, set) => set
          )
          OTSet.empty
          ty;

  fun EFTVInVarInfo (VARID {ty, ...}) = EFTV ty
    | EFTVInVarInfo (CONID _) = OTSet.empty (* datacon must be closed *)
    | EFTVInVarInfo (PRIM _) = OTSet.empty (* primitive must be closed *)
    | EFTVInVarInfo (OPRIM _) =
      OTSet.empty (* overloaded primitive must be closed *)
    | EFTVInVarInfo (FFID _) = OTSet.empty (* foreign fun must be closed *)
    | EFTVInVarInfo (RECFUNID ({ty,...}, _)) = EFTV ty

  fun TEnvClosure (btvEnv : btvEnv) ty =
      TypeTransducer.foldTyPreOrder
      (fn (BOUNDVARty n, btvEnv) =>
	  (case IEnv.find(btvEnv, n) of
	     SOME btvKind =>
             (
               TEnvClosureOfBTVKind (IEnv.insert (btvEnv, n, btvKind)) btvKind,
               true
             )
	   | NONE => (btvEnv, true))
        | (POLYty _, btvEnv) => (btvEnv, false) (* not go inside body *)
        | (_, btvEnv) => (btvEnv, true))
      btvEnv
      ty
  and TEnvClosureOfBTVKind (btvEnv : btvEnv) (btvKind : btvKind) =
      case btvKind of
        {recKind = UNIV, ...} => btvEnv
      | {recKind = REC fields, ...} => 
	SEnv.foldr 
	    (fn (ty, set) => IEnv.unionWith #1 (TEnvClosure btvEnv ty, set))
	    btvEnv
	    fields
     | {recKind = OVERLOADED _, ...} => raise Control.Bug "OVERLOADED kind given to TEnvClosureOfBTVKind"

  datatype rk = ONE | ZERO | NIL

  fun mergeRank (ZERO, _) = ZERO
    | mergeRank (_, ZERO) = ZERO
    | mergeRank (NIL, NIL) = NIL
    | mergeRank _ = ONE


  fun dataTag ({displayName, tyCon = {datacon = ref vEnv, ...}, ...} : conInfo) =
      let val idlist = SEnv.listKeys vEnv
      in {id = Basics.findIndex displayName idlist, span = length idlist}
      end
      
  fun betaReduceTy ({name, tyargs, body}, tyl) =
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
    | tpappTy (Types.TYVARty (ref (Types.SUBSTITUTED ty)), tyl) =
      tpappTy (ty, tyl)
    | tpappTy (Types.POLYty{boundtvars, body, ...}, tyl) = 
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

  fun polyBodyTy (Types.POLYty {body, ...}) = body
    | polyBodyTy (Types.TYVARty (ref (Types.SUBSTITUTED ty))) = polyBodyTy ty
    | polyBodyTy ty =
      raise Control.Bug ("polyBodyTy:" ^ TypeFormatter.tyToString ty)

  fun ranTy (Types.FUNMty(_, ty)) = ty
    | ranTy (Types.TYVARty (ref (Types.SUBSTITUTED ty))) = ranTy ty
    | ranTy ty = raise Control.Bug ("ranTy:" ^ TypeFormatter.tyToString ty)
  fun domTy (Types.FUNMty(tyList, _)) = tyList
    | domTy (Types.TYVARty (ref (Types.SUBSTITUTED ty))) = domTy ty
    | domTy ty = raise Control.Bug ("domTy:" ^ TypeFormatter.tyToString ty)
(*
  fun ranTyI (Types.IABSty(ty1, ty2)) = ty2
    | ranTyI (Types.TYVARty (ref (Types.SUBSTITUTED ty))) = ranTyI ty
    | ranTyI ty = raise Control.Bug ("ranTyM:" ^ TypeFormatter.tyToString ty)
  fun domTyI (Types.IABSty(n, ty2)) = n
    | domTyI (Types.TYVARty (ref (Types.SUBSTITUTED ty))) = domTyI ty
    | domTyI ty = raise Control.Bug ("domTyM:" ^ TypeFormatter.tyToString ty)
*)
  (* The following are for printer code generation. *)
  fun substituteBTV (srcBTVID, destTy) ty=
      substBTvar (IEnv.singleton(srcBTVID, destTy)) ty
  fun instantiate {boundtvars : btvEnv, body : ty} =
      let val subst = freshSubst boundtvars
      in (substBTvar subst body, subst) end
(*
fun unify (ty1, ty2) = Unify.unify [(ty1,ty2)]
Unify is imperative; i.e. it performs the unifier by updating the type variables.
So be careful in using this.
*)

  (**
   * Make a fresh instance of a polytype and a term of that type.
   *)
  fun freshInstTy ty =
      if monoTy ty
      then ty
      else
        case ty 
	 of (POLYty{boundtvars,body,...}) =>
	    let 
	      val subst = freshSubst boundtvars
	      val bty = substBTvar subst body
	    in  freshInstTy bty
	    end
	  | FUNMty (tyList,ty) =>FUNMty(tyList, freshInstTy ty)
	  | RECORDty fl => RECORDty (SEnv.map freshInstTy fl)
	  | ty => ty

  (**
   * Make a rigid fresh instance of a polytype and a term of that type.
   *)
  fun freshRigidInstTy ty =
      if monoTy ty
      then ty
      else
        case ty 
	 of (POLYty{boundtvars,body,...}) =>
	    let 
	      val subst = freshRigidSubst boundtvars
	      val bty = substBTvar subst body
	    in  freshRigidInstTy bty
	    end
	  | FUNMty (tyList,ty) =>FUNMty(tyList, freshRigidInstTy ty)
	  | RECORDty fl => RECORDty (SEnv.map freshRigidInstTy fl)
	  | ty => ty

  (**
   *)
  fun eliminateVacuousTyvars () =
    let
      fun instanticateTv tv =
        case tv of
          ref(TVAR {recKind = OVERLOADED (h :: tl), ...}) =>
            tv := SUBSTITUTED h
        | ref(TVAR {recKind = REC tyFields, ...}) => 
            tv := SUBSTITUTED (RECORDty tyFields)
        | _ => ()
    in
      (
       List.app instanticateTv (!kindedTyvarList);
       kindedTyvarList := nil
       )
    end


  (**
   * Type generalizer.
   * This must be called top level, i.e. de Bruijn 0
   *)
  fun generalizer (ty, varEnv, utvarEnv) =
      let 
	val freeTvs = EFTV ty
        val context =
            SEnv.foldr
                (fn (x, set) => OTSet.union (EFTVInVarInfo x, set))
                (SEnv.foldr
                     (fn (tvStateRef, set) => OTSet.add(set, tvStateRef))
                     OTSet.empty
                     utvarEnv)
                varEnv
        val tids = 
            OTSet.foldr 
                (fn (
                      r as
                        ref
                        (TVAR(k as {id, recKind = OVERLOADED (h :: tl), ...})),
                        tids
                    ) => tids
(*
                    (r := SUBSTITUTED h; tids)
*)
                  | (r, tids) => OTSet.add(tids, r))
                OTSet.empty
                (OTSet.difference (freeTvs, context))

	(* fix the bug 187
	 * when typeinference phase does type instantiation for the more polymorphic
	 * type in strucutre with the restricted type in signature, the bound type variables 
	 * of the new generated instantiated type should be in the same order as that specified at the 
	 * type in the signature. Since the type varialbes of a polymorphic val type
	 * in signature only bounded at toplevel, the order of these bounded type variables
	 * decides the order of type instantiation paramaters. When we do freshRigidInstTy 
	 * of a signature type, the rigid type variables are in the same incremental order as 
	 * bound variables. And then we generalize the instantiated structure 
	 * type (see function generateInstTermFunOnStructure in TypeInstantiationTerm.sml) by the 
	 * rigid type variables. Since it is always incremental we generate the orderedTidEnv below.
	 * So in this way we generates the new bounded type variables in the order as that of
	 * original bounded type variables.
	 *)
(*
	val orderedTidEnv =
	    foldl (fn (r as ref(TVAR (k as {id, ...})), orderedTidEnv) =>
			    IEnv.insert(orderedTidEnv,id,r)
			    )
			IEnv.empty
			(OTSet.listItems tids)
*)
      in
	if OTSet.isEmpty tids
        then {boundEnv = IEnv.empty, removedTyIds = OTSet.empty}
	else
          let
            val (_, btvs) =
                OTSet.foldl
                    (fn (r as ref(TVAR (k as {id, ...})), (next, btvs)) =>
                        let 
                          val btvid = nextBTid()
                        in
                          (
                            r := SUBSTITUTED (BOUNDVARty btvid);
                            (
                              next + 1,
                              IEnv.insert
                                  (
                                    btvs,
                                    btvid,
                                    {
                                      index = next,
                                      recKind = (#recKind k),
                                      eqKind = (#eqKind k)
                                    }
                                  )
                            )
                          )
                        end
                      | _ => raise Control.Bug "generalizeTy")
		    (0, IEnv.empty)
		    tids
	  in
	    if OTSet.isEmpty tids
            then {boundEnv = IEnv.empty, removedTyIds = OTSet.empty}
	    else {boundEnv = btvs, removedTyIds = tids}
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
    {
     boundtvEnv = #boundEnv(generalizer (ty, SEnv.empty, SEnv.empty)),
     body = ty
     }

(******************************************************************************)
(* boxedKind computation utilities*)

  fun coerceBoxedKind boxedKind =
      case boxedKind of
	DOUBLEty => BOXEDty
      | _ => boxedKind

  fun boxedKindValueOfTyCon (tyCon as {name,strpath,id,boxedKind = ref boxedKindOpt ,...}:tyCon) =
      case boxedKindOpt of
	NONE => raise ExSpecTyCon ((Path.pathToString(strpath)^"."^name^
				    "("^(ID.toString(id)^") isBoxedDataInSignature")))
      | SOME boxedKind  => 
        if (!Control.enableUnboxedFloat) then
	  boxedKind
        else
	  coerceBoxedKind boxedKind

  fun boxedKindOptOfTyCon (tyCon:tyCon) =
      (SOME (boxedKindValueOfTyCon tyCon)) handle ExSpecTyCon _ => NONE

  (* compact a type 
   * to one of following  ATOMty,DOUBLEty,BOXEDty and BOUNDVARty
   *)
  fun compactTy ty = 
      case derefTy ty of 
        TYVARty (ref (TVAR {recKind = REC _,...})) => BOXEDty
      | TYVARty _  => ATOMty  (* TODO. ????*)
      | BOUNDVARty tid  => BOUNDVARty tid
      | FUNMty _  => BOXEDty 
      | ABSSPECty (_, ty) => compactTy ty
      | SPECty specTy => compactTy specTy
      | RECORDty _  => BOXEDty 
      | CONty {tyCon as {datacon,...}, args} =>
        if isSameTyCon (refTyCon, tyCon) then BOXEDty
        else 
          (
           case boxedKindValueOfTyCon tyCon of
             BOUNDVARty tid =>
             (
              case SEnv.listItems (!datacon) of
                [CONID{ty=POLYty{boundtvars,body},...}] =>
                let
                  val ty' = POLYty{boundtvars=boundtvars,body=BOUNDVARty tid}
                in
                  compactTy (tpappTy (ty',args))
                end
              | _ => raise Control.Bug "tyconSpan <> 1 or CONID is monomorphic"
             )
           | boxedKind => boxedKind
          )
      | POLYty{boundtvars,body}  => 
        (
         case derefTy body of
           BOUNDVARty tid =>
           (
            case IEnv.find(boundtvars,tid) of
              SOME _ => BOXEDty   (* \forall{t}.t --> BOXED *)
            | _ => BOUNDVARty tid
           )
         | _ => compactTy body
        )
      | DUMMYty _ => ATOMty
      | BOXEDty => BOXEDty
      | ATOMty => ATOMty
      | INDEXty _ => ATOMty
      | ALIASty (_,actualTy) => compactTy actualTy
      | BITMAPty _ => ATOMty
      | FRAMEBITMAPty _ => ATOMty
      | OFFSETty _ => ATOMty
      | DOUBLEty => DOUBLEty
      | TAGty _ => ATOMty
      | SIZEty _ => ATOMty
      | PADty _ => ATOMty
      | PADCONDty _ => ATOMty
      | ERRORty  => ATOMty (* ? ok? *)
      | _ => raise Control.Bug "illegal type in compactTy"
	     
  fun boxedKindValueOfType ty = compactTy ty
       
  fun boxedKindOptOfType ty =
      SOME (boxedKindValueOfType ty) handle ExSpecTyCon _ => NONE
	
  fun isBoxed boxedKind =
      case boxedKind of
	DOUBLEty => if (!Control.enableUnboxedFloat) then false else true
      | ATOMty   => false
      | BOXEDty  => true
      | _        => raise Control.Bug "illegal value inside boxedKind"

  fun isBoxedType ty = isBoxed (boxedKindValueOfType ty)

(*
  fun isBoxedType 
	(CONty { tyCon as {boxedKind = ref boxedKind, datacon = ref datacon,...}, ...}) = 
	isBoxedTyCon tyCon
    | isBoxedType (Types.POLYty{body, ...}) = isBoxedType body
    | isBoxedType (Types.TYVARty(ref (Types.SUBSTITUTED ty))) = isBoxedType ty
    | isBoxedType (Types.ALIASty(_, actual)) = isBoxedType actual
    | isBoxedType _ = true
*)

  fun boxedKindOptOfTyBindInfo tyBindInfo =
      case tyBindInfo of
	TYFUN{body,...} => boxedKindOptOfType body
      | TYCON tyCon => boxedKindOptOfTyCon tyCon
      | TYSPEC {spec = {boxedKind,...},...} => boxedKind

  fun calcTyConBoxedKind datacon =
   (***rcompTy in RecordCompile.sml loop bug****
    We supress this optimization 
      case (SEnv.listItems datacon) of
        [CONID {name, strpath, funtyCon = true, ty, tag, tyCon}] =>
        (
	 case ty of 
           FUNty(ty1,_ ) => compactTy ty1
         | POLYty{body = FUNty(ty1,_),...} => compactTy ty1
	 | _ => raise Control.Bug "should be function type of CONID"
	)
      | [CONID {name, strpath, funtyCon = false, ty, tag, tyCon}] => ATOMty
      | conList => 
    *)
        let
	  val isBoxed = 
              foldl
		  (fn (v, S) => 
		      (case v of 
			 CONID {name, strpath, funtyCon, ty, tag, tyCon} => funtyCon
		       | _ => raise Control.Bug "Not CONID in datacon")
		      orelse S)
		  false
                  (SEnv.listItems datacon)
        in 
	  if isBoxed then BOXEDty else ATOMty
        end

  fun calcTyConBoxedKindOpt datacon =
      (SOME (calcTyConBoxedKind datacon))
      handle ExSpecTyCon _ => NONE

  fun fixPointUpdateTyCons modifier tyCons =
      let
        fun update () =
            let 
              val updateFlag =
                  foldl 
                      (fn (tyCon,flag) =>
                          if modifier tyCon then true else flag
                      )
                      false
                      tyCons
            in
              if updateFlag then update () else ()
            end
      in
        update ()
      end

  fun compareBoxedKind (NONE,NONE) = true
    | compareBoxedKind (SOME ATOMty,SOME ATOMty) = true
    | compareBoxedKind (SOME BOXEDty,SOME BOXEDty) = true
    | compareBoxedKind (SOME DOUBLEty,SOME DOUBLEty) = true
    | compareBoxedKind (SOME (BOUNDVARty tid1),SOME (BOUNDVARty tid2)) = tid1 = tid2
    | compareBoxedKind (_,_) = false

  fun boxedKindModifier (tyCon as {boxedKind as ref boxedKindOpt,datacon = ref cons,...} : tyCon) =
      let
        val newBoxedKind = calcTyConBoxedKindOpt cons
      in
        if compareBoxedKind(newBoxedKind,boxedKindOpt)
        then false
        else (boxedKind:=newBoxedKind;true)
      end

  fun updateBoxedKinds tyCons = 
      fixPointUpdateTyCons boxedKindModifier tyCons

(**********************************************************************)

  fun isATOMty ty =
      case ty of
	ATOMty => true
      | _      => false

	
  fun isTyNameOfTyFun ({name,tyargs,body}:tyFun) = 
      let
	fun isTyName ty = 		
	    case ty of
	      CONty {tyCon, args} => true
	    | ALIASty (_,ty) => isTyName ty
            | SPECty ty => isTyName ty
	    | ABSSPECty(ty,_) => isTyName ty
	    | _ => false
      in
	isTyName body
      end

  fun tyFunToTyName ({name,tyargs,body}:tyFun) = 
      let
	fun extractCONty ty = 
	    case  ty of
	      CONty { tyCon = {name,strpath,abstract,tyvars,
			       id,eqKind,boxedKind,datacon},
		      args = _ } => 
	      {name = name, tyvars = tyvars, id = id, eqKind = eqKind}
	    | ALIASty (_,ty) => extractCONty ty
	    | _ => raise ExIllegalTyFunToTyName(name)
      in
	 extractCONty body
      end

  fun strPathOptOfTyBindInfo tyBindInfo =
      case tyBindInfo of
	TYSPEC {spec = {strpath,...},...}  =>  strpath
      | TYCON  {strpath,...} =>  strpath
      | TYFUN  ({body = ALIASty(CONty{tyCon = {strpath,...},...},_),...}) => strpath
      | TYFUN  _ => raise Control.Bug "TYFUN is not well-formed: body = ALIASty(CONty,_)"

  fun peelTySpec tyBindInfo =
      case tyBindInfo of
	TYSPEC {spec,impl = SOME impl} => peelTySpec impl
      |  _   => tyBindInfo

end
end
