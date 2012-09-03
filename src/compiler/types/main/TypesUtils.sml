(**
 * utility functions for manupilating types (needs re-writing).
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: TypesUtils.sml,v 1.19.2.1 2007/11/05 12:57:38 ohori Exp $
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
  exception ExIllegalTyFunToTyName of string
  exception CoerceFun 

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
	     | T.CONty {tyCon = {name = "ref",...},...} =>
	       (true,false)
             | T.CONty {tyCon = {name = "array",...},...} =>
	       (true,false)
             | T.CONty {tyCon = {eqKind = ref T.NONEQ, ...}, ...} =>
               raise NotAdmitEq
	     | T.ABSSPECty (specTy,_) => (admitEqTy specTy,false)
             | T.TYVARty (ref(T.TVAR {eqKind = T.NONEQ, ...})) => raise NotAdmitEq
             | _ => (true, true))
         true
         ty)
      handle NotAdmitEq => false
  end

  fun admitEqTyFun {name, tyargs, body} = admitEqTy body

  fun admitEqTyBindInfo tyBindInfo =
      case tyBindInfo of
	T.TYSPEC {spec = {eqKind = T.EQ,...},...} => true
      | T.TYCON {eqKind = ref T.EQ,...} => true
      | T.TYFUN tyFun => admitEqTyFun tyFun
      | _ => false

  (*
   * Returns a new generative type constructor. 
   *)
  fun newTyCon {name, strpath, abstract, tyvars, eqKind, boxedKind, datacon} = 
      let val id = T.newTyConId()
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
        } : T.tyCon
      end

  fun extractAliasTyImpl aliasTy =
      case aliasTy of
	T.ALIASty(_,ty) => extractAliasTyImpl ty
      | ty => ty
      
  fun tyconSpan ({datacon = ref datacon,...}:T.tyCon) = SEnv.numItems datacon

  fun typeOfIdstate idstate =
      case idstate of
        T.CONID conPathInfo => #ty conPathInfo
      | T.OPRIM oprimInfo => #ty oprimInfo
      | T.PRIM primInfo => #ty primInfo
      | T.VARID varPathInfo => #ty varPathInfo
      | T.RECFUNID (varPathInfo, int) => #ty varPathInfo

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
        fun preVisitor (ty, substs as (subst :: _)) =
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
        fun postVisitor (ty, substs as (subst :: _)) =
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
	T.REC fields => T.REC (SEnv.map (substBTvar subst) fields)
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
  fun performSubst (T.TYVARty (r as ref(T.TVAR _)), ty) = r := T.SUBSTITUTED ty
    | performSubst _ = raise Control.Bug "performSubst"

  (**
   * Make a fresh copy of a bound type environment by allocating a new btvid
   * @params  boundEnv
   * @return subst bound type variable substitution
   *)
  fun copyBoundEnv boundEnv = 
      let
        val newSubst =
            IEnv.map
            (fn _  => T.BOUNDVARty (T.nextBTid()))
            boundEnv
	val newBoundEnv =
          IEnv.foldri
          (fn (oldId, {index, recKind, eqKind}, newBoundEnv) =>
           (case IEnv.find(newSubst, oldId) of
              SOME (T.BOUNDVARty newId) =>
                IEnv.insert(newBoundEnv, newId, {index=index, recKind=substBTvarRecKind newSubst recKind, eqKind=eqKind})
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
            (fn x => T.newty 
                         {
                          recKind = T.UNIV,
                          eqKind = T.NONEQ,
                          tyvarName = NONE
                          })
            boundEnv
	val _ =
            IEnv.appi
                (fn (i, T.TYVARty(r as ref (T.TVAR {id, tyvarName, ...}))) => 
		    r := 
		    (case IEnv.find(boundEnv, i) of
		       SOME {index, recKind, eqKind} => 
                       (case recKind of 
                            T.REC _ => T.kindedTyvarList := r :: (!T.kindedTyvarList)
                          | T.OVERLOADED _ => T.kindedTyvarList := r :: (!T.kindedTyvarList)
                          | _ => ();
		       T.TVAR
                           {
                             lambdaDepth = T.infiniteDepth,
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
   * Make a fresh substitution for bound tvars with *named* tyvars.
   * This is used in Sigmatch
   *)
  fun freshRigidSubst boundEnv = 
      let
        val newSubst =
            IEnv.map
            (fn x => T.newty
                         {
                          recKind = T.UNIV,
                          eqKind = T.NONEQ,
                          tyvarName = SOME "RIGID"
                          })
            boundEnv
	val _ =
            IEnv.appi
                (fn (i,T.TYVARty(r as ref (T.TVAR {lambdaDepth, id, tyvarName, ...}))) => 
		    r := 
		    (case IEnv.find(boundEnv, i) of
		       SOME {index, recKind, eqKind} => 
                         (case recKind of 
                            T.REC _ => T.kindedTyvarList := r :: (!T.kindedTyvarList)
                          | T.OVERLOADED _ => T.kindedTyvarList := r :: (!T.kindedTyvarList)
                          | _ => ();		
                              T.TVAR
                              {
                               lambdaDepth = lambdaDepth,
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
                        T.newty
                        {
                         recKind = T.UNIV,
                         eqKind = T.NONEQ,
                         tyvarName = NONE
                         }
                      ))
	        IEnv.empty
	        boundEnv
	val _ =
            IEnv.appi
                (fn (i, T.TYVARty(r as ref (T.TVAR {lambdaDepth, id, tyvarName, ...}))) => 
                   r := 
                     (case IEnv.find(boundEnv, i) of
		       SOME {index, recKind, eqKind} => 
                         (case recKind of 
                            T.REC _ => T.kindedTyvarList := r :: (!T.kindedTyvarList)
                          | T.OVERLOADED _ => T.kindedTyvarList := r :: (!T.kindedTyvarList)
                          | _ => ();
                              T.TVAR
                              {
                               lambdaDepth = lambdaDepth,
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
          (fn (T.TYVARty (ref(T.TVAR {recKind = T.OVERLOADED _,...})), set)  => set
            | (T.TYVARty (tyvarRef as (ref(T.TVAR tvKind))), set)  => 
              let
                fun EFTVKind set =
	            case tvKind of
		      {recKind = T.UNIV, ...} => set
	            | {recKind = T.REC fields, ...} => 
		      SEnv.foldl
                          (fn (ty, set) => OTSet.union(set, EFTV ty))
		          set
		          fields
                    | {recKind = T.OVERLOADED _, ...} => raise Control.Bug "EFTV Overloaded"
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
          T.ERRORty => set
        | T.DUMMYty int => set
        | T.TYVARty (ref(T.TVAR {recKind = T.OVERLOADED _,...})) => set
        | T.TYVARty (ref(T.SUBSTITUTED ty)) => traverseTy (ty,set)
        | T.TYVARty (tyvarRef as (ref(T.TVAR tvKind))) => 
            if OTSet.member(set, tyvarRef) then set
            else traverseTvKind (tvKind, OTSet.add(set, tyvarRef))
        | T.BOUNDVARty int => set
        | T.FUNMty (tyList, ty) => traverseTy (ty, foldl traverseTy set tyList)
        | T.RECORDty tySEnvMap => 
            SEnv.foldl (fn (ty, set) => traverseTy (ty,set)) set tySEnvMap
        | T.CONty {tyCon = tyCon, args = tyList} => foldl traverseTy set tyList
        | T.POLYty {boundtvars = btvKindIEnvMap, body=ty} => traverseTy (ty,set)
        | T.BOXEDty => set
        | T.ATOMty => set
        | T.GENERICty => set
        | T.INDEXty (ty, string) => traverseTy (ty,set)
        | T.BMABSty (tyList, ty) => traverseTy (ty, foldl traverseTy set tyList)
        | T.BITMAPty tyList => foldl traverseTy set tyList
        | T.ALIASty (aliasTy,realTy) => traverseTy (realTy, traverseTy(aliasTy,set))
        | T.BITty int => set
        | T.UNBOXEDty => set
        | T.DBLUNBOXEDty => set
        | T.OFFSETty tyList => foldl traverseTy set tyList
        | T.TAGty int => set
        | T.SIZEty int => set
        | T.DOUBLEty => set
        | T.PADty tyList => foldl traverseTy set tyList
        | T.PADCONDty (tyList, int) => foldl traverseTy set tyList
        | T.FRAMEBITMAPty intList => set
        | T.ABSSPECty (specTy, realTy) => traverseTy(realTy,traverseTy (specTy,set))
        | T.SPECty ty => traverseTy(ty,set)
        | T.ABSTRACTty => set
      and traverseTvKind (kind, set) =
            case kind of
              {recKind = T.UNIV, ...} => set
            | {recKind = T.REC fields, ...} => 
                SEnv.foldl
                (fn (ty, set) => traverseTy (ty,set))
                set
                fields
            | {recKind = T.OVERLOADED _, ...} => raise Control.Bug "EFTV Overloaded"
    in
      traverseTy (ty, OTSet.empty)
    end


  fun EFTVInVarInfo (T.VARID {ty, ...}) = EFTV ty
    | EFTVInVarInfo (T.CONID _) = OTSet.empty (* datacon must be closed *)
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
                                     recKind, 
                                     eqKind, 
                                     tyvarName
                                     }))) =>
         if T.strictlyYoungerDepth(tyvarDepth, contextDepth) then
           tyvarRef := T.TVAR {
                               lambdaDepth=contextDepth, 
                               id = id, 
                               recKind = recKind, 
                               eqKind = eqKind, 
                               tyvarName = tyvarName
                               }
         else ())
      tyset
    end

  fun adjustDepthInRecKind contextDepth kind = 
    case kind of
      T.UNIV => ()
    | T.REC fields => 
        SEnv.app
        (fn ty => adjustDepthInTy contextDepth ty)
        fields
    | T.OVERLOADED _ => ()

  fun adjustEqKindInTy eqKind ty = 
    case eqKind of
      T.NONEQ => ()
    | T.EQ => 
        let
          val tyset = EFTV ty
        in
          OTSet.app
          (fn (tyvarRef as (ref (T.TVAR {
                                         lambdaDepth =lambdaDepth, 
                                         id, 
                                         recKind, 
                                         eqKind, 
                                         tyvarName
                                         })))
              =>
              tyvarRef := T.TVAR {
                                  lambdaDepth = lambdaDepth, 
                                  id = id, 
                                  recKind = recKind, 
                                  eqKind = T.EQ, 
                                  tyvarName = tyvarName
                                  }
            | _ => raise Control.Bug "non TVAR in adjustDepthInTy (TypesUtils.sml)"
          )
          tyset
        end

  fun adjustEqKindInRecKind eqKind kind = 
    case kind of
      T.UNIV => ()
    | T.REC fields => 
        SEnv.app
        (fn ty => adjustEqKindInTy eqKind ty)
        fields
    | T.OVERLOADED _ => ()

  fun adjustDepthInVarPathInfo contextDepth {name, strpath, ty} = 
    adjustDepthInTy contextDepth ty;
  fun adjustDepthInConPathInfo contextDepth {name, strpath, funtyCon,ty,tag,tyCon} = 
    adjustDepthInTy contextDepth ty
  fun adjustDepthInPrimInfo contextDepth {name, ty} = 
    adjustDepthInTy contextDepth ty
  fun adjustDepthInOPrimInfo _ _ = 
      raise (Control.Bug "adjustDepthInOprimInfo should never be called.")
  fun adjustDepthInVarPathInfo contextDepth {name, strpath, ty} =
    adjustDepthInTy contextDepth ty
  fun adjustDepthInIdstate contextDepth idState = 
    case idState of
      T.VARID varPathInfo =>
        adjustDepthInVarPathInfo contextDepth varPathInfo
    | T.CONID conPathInfo =>
        adjustDepthInConPathInfo contextDepth conPathInfo
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
        newTy as T.TYVARty (ref (T.TVAR {lambdaDepth, id, recKind = T.UNIV, eqKind, tyvarName})) => 
          let 
            val tyList = map (fn x => T.newty {recKind = T.UNIV, eqKind=eqKind, tyvarName=tyvarName}) tyList
(*
            val tyList = map (fn x => T.newty T.univKind) tyList
*)
            val ty2 = T.newty T.univKind
            val resTy = T.FUNMty(tyList, ty2)
            val _ = adjustDepthInTy lambdaDepth resTy
            val _ = performSubst (newTy, resTy)
          in
            (tyList, ty2, nil)
          end
      | T.TYVARty (ref(T.SUBSTITUTED ty)) => coerceFunM (ty, tyList)
      | T.FUNMty (tyList, ty2) => (tyList, ty2, nil)
      | T.POLYty {boundtvars, body} =>
        (case derefTy body of
              T.FUNMty(tyList,ty2) =>
                let val subst1 = freshSubst boundtvars
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
      | T.ALIASty(_, ty) => coerceFunM (ty, tyList)
      | T.ERRORty => (map (fn x => T.ERRORty) tyList, T.ERRORty, nil)
      | _ => raise CoerceFun


  fun TEnvClosure (btvEnv : T.btvEnv) ty =
      TypeTransducer.foldTyPreOrder
      (fn (T.BOUNDVARty n, btvEnv) =>
	  (case IEnv.find(btvEnv, n) of
	     SOME btvKind =>
             (
               TEnvClosureOfBTVKind (IEnv.insert (btvEnv, n, btvKind)) btvKind,
               true
             )
	   | NONE => (btvEnv, true))
        | (T.POLYty _, btvEnv) => (btvEnv, false) (* not go inside body *)
        | (_, btvEnv) => (btvEnv, true))
      btvEnv
      ty

  and TEnvClosureOfBTVKind (btvEnv : T.btvEnv) (btvKind : T.btvKind) =
      case btvKind of
        {recKind = T.UNIV, ...} => btvEnv
      | {recKind = T.REC fields, ...} => 
	SEnv.foldr 
	    (fn (ty, set) => IEnv.unionWith #1 (TEnvClosure btvEnv ty, set))
	    btvEnv
	    fields
     | {recKind = T.OVERLOADED _, ...} => raise Control.Bug "OVERLOADED kind given to TEnvClosureOfBTVKind"

(*
  datatype rk = ONE | ZERO | NIL

  fun mergeRank (T.ZERO, _) = T.ZERO
    | mergeRank (_, ZERO) = T.ZERO
    | mergeRank (T.NIL, T.NIL) = T.NIL
    | mergeRank _ = T.ONE
*)

  fun dataTag ({displayName, tyCon = {datacon = ref vEnv, ...}, ...} : T.conInfo) =
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
	 of (T.POLYty{boundtvars,body,...}) =>
	    let 
	      val subst = freshSubst boundtvars
	      val bty = substBTvar subst body
	    in  freshInstTy bty
	    end
	  | T.FUNMty (tyList,ty) => T.FUNMty(tyList, freshInstTy ty)
	  | T.RECORDty fl => T.RECORDty (SEnv.map freshInstTy fl)
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
	    in  freshRigidInstTy bty
	    end
	  | T.FUNMty (tyList,ty) => T.FUNMty(tyList, freshRigidInstTy ty)
	  | T.RECORDty fl => T.RECORDty (SEnv.map freshRigidInstTy fl)
	  | ty => ty

  (**
   *)
  fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")
  fun eliminateVacuousTyvars () =
    let
      fun instanticateTv tv =
        case tv of
          ref(T.TVAR {recKind = T.OVERLOADED (h :: tl), ...}) =>
            tv := T.SUBSTITUTED h
        | ref(T.TVAR {recKind = T.REC tyFields, ...}) => 
            tv := T.SUBSTITUTED (T.RECORDty tyFields)
        | _ => ()
    in
      (
       List.app instanticateTv (!T.kindedTyvarList);
       T.kindedTyvarList := nil
       )
    end


  (**
   * Type generalizer.
   * This must be called top level, i.e. de Bruijn 0
   *)
  fun generalizer (ty, contextLambdaDepth) =
      let 
	val freeTvs = EFTV ty
        val tids = 
            OTSet.foldr 
                (fn (
                      r as
                        ref
                        (T.TVAR(k as {id, recKind = T.OVERLOADED (h :: tl), ...})),
                        tids
                    ) => tids
                  | (r, tids) => OTSet.add(tids, r))
                OTSet.empty
                (OTSet.filter 
                 (fn (ref (T.TVAR {lambdaDepth = tyvarLambdaDepth,...})) => 
                  T.youngerDepth {contextDepth = contextLambdaDepth, tyvarDepth = tyvarLambdaDepth})
                 freeTvs)

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
      in
	if OTSet.isEmpty tids
        then {boundEnv = IEnv.empty, removedTyIds = OTSet.empty}
	else
          let
            val (_, btvs) =
                OTSet.foldl
                    (fn (r as ref(T.TVAR (k as {id, ...})), (next, btvs)) =>
                        let 
                          val btvid = T.nextBTid()
                        in
                          (
                            r := T.SUBSTITUTED (T.BOUNDVARty btvid);
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
     boundtvEnv = #boundEnv(generalizer (ty, T.toplevelDepth)),
     body = ty
     }

(******************************************************************************)
(* boxedKind computation utilities*)

  fun coerceBoxedKind boxedKind =
      case boxedKind of
	T.DOUBLEty => T.BOXEDty
      | _ => boxedKind

  fun boxedKindOfTyCon (tyCon as {name,strpath,id,boxedKind = ref boxedKind ,...}:T.tyCon) =
      if (!Control.enableUnboxedFloat) then
	  boxedKind
      else
	  coerceBoxedKind boxedKind

  (* ToDo : this function can be rewritten by using
   * TypeTransducer.foldTyPreOrder ? *)
  fun computeTy computeFun ty = 
      case derefTy ty of 
        T.TYVARty (ref (T.TVAR {recKind = T.REC _,...})) => computeFun T.BOXEDty
      | T.TYVARty _  => computeFun T.ATOMty  
      | T.BOUNDVARty tid  => computeFun (T.BOUNDVARty tid)
      | T.FUNMty _  => computeFun T.BOXEDty 
      | T.ABSSPECty (_, ty) => computeTy computeFun ty
      | (* imported type specificiation *)
         T.SPECty specTy => computeFun (T.SPECty specTy)
      | T.RECORDty _  => computeFun T.BOXEDty 
      | T.CONty {tyCon as {datacon,...}, args} =>
(* ToDo : 
        if T.isSameTyCon (PT.refTyCon, tyCon) then computeFun T.BOXEDty
        else 
*)
          (
           case boxedKindOfTyCon tyCon of
             T.BOUNDVARty tid =>
             (
              case SEnv.listItems (!datacon) of
                [T.CONID{ty = T.POLYty{boundtvars,body},...}] =>
                let
                  val ty' = T.POLYty{boundtvars = boundtvars,body = T.BOUNDVARty tid}
                in
                  computeTy computeFun (tpappTy (ty',args))
                end
              | _ => raise Control.Bug "tyconSpan <> 1 or CONID is monomorphic"
             )
           | boxedKind => computeFun boxedKind
          )
      | T.POLYty{boundtvars,body}  => 
        (
         case derefTy body of
           T.BOUNDVARty tid =>
           (
            case IEnv.find(boundtvars,tid) of
              SOME _ => computeFun T.BOXEDty   (* \forall{t}.t --> BOXED *)
            | _ => computeFun (T.BOUNDVARty tid)
           )
         | _ => computeTy computeFun body
        )
      | T.DUMMYty _ => computeFun T.ATOMty
      | T.BOXEDty => computeFun T.BOXEDty
      | T.ATOMty => computeFun T.ATOMty
      | T.INDEXty _ => computeFun T.ATOMty
      | T.ALIASty (_,actualTy) => computeTy computeFun actualTy
      | T.BITMAPty _ => computeFun T.ATOMty
      | T.FRAMEBITMAPty _ => computeFun T.ATOMty
      | T.OFFSETty _ => computeFun T.ATOMty
      | T.DOUBLEty => computeFun T.DOUBLEty
      | T.TAGty _ => computeFun T.ATOMty
      | T.SIZEty _ => computeFun T.ATOMty
      | T.PADty _ => computeFun T.ATOMty
      | T.PADCONDty _ => computeFun T.ATOMty
      | T.ERRORty  => computeFun T.ATOMty 
      | _ =>
        raise
          Control.Bug
              ("illegal type in computeTy" ^ TypeFormatter.tyToString ty)

  (* compact a type to one of the following:
   * ATOMty, DOUBLEty, BOXEDty, BOUNDVARty and GENERICty
   *)
  fun compactTy ty = 
      let
          val resultTy = computeTy (fn x => x) ty
      in
          case resultTy of
              T.SPECty specTy => computeTy (fn x => x) specTy
            | T.ATOMty => resultTy
            | T.BOXEDty => resultTy
            | T.DOUBLEty => resultTy
            | T.BOUNDVARty _ => resultTy
            | _ =>
              raise
                Control.Bug
                    ("ilegal result in compactTy:"
                     ^ TypeFormatter.tyToString resultTy)
      end
	     
  fun boxedKindOfType ty = compactTy ty
       
  fun isBoxed boxedKind =
      case boxedKind of
	T.DOUBLEty => if (!Control.enableUnboxedFloat) then false else true
      | T.ATOMty   => false
      | T.BOXEDty  => true
      | _        => raise Control.Bug "illegal value inside boxedKind"

  fun isBoxedType ty = isBoxed (boxedKindOfType ty)

(*
  fun isBoxedType 
	(CONty { tyCon as {boxedKind = ref boxedKind, datacon = ref datacon,...}, ...}) = 
	isBoxedTyCon tyCon
    | isBoxedType (T.POLYty{body, ...}) = isBoxedType body
    | isBoxedType (T.TYVARty(ref (T.SUBSTITUTED ty))) = isBoxedType ty
    | isBoxedType (T.ALIASty(_, actual)) = isBoxedType actual
    | isBoxedType _ = true
*)

  fun boxedKindOfTyBindInfo tyBindInfo =
      case tyBindInfo of
	T.TYFUN{body,...} => boxedKindOfType body
      | T.TYCON tyCon => boxedKindOfTyCon tyCon
      | T.TYSPEC {spec = {boxedKind,...},...} => boxedKind

  fun calcTyConBoxedKind datacon =
   (*
      rcompTy in RecordCompile.sml loop bug
    *
    We supress this optimization 
      case (SEnv.listItems datacon) of
        [T.CONID {name, strpath, funtyCon = true, ty, tag, tyCon}] =>
        (
	 case ty of 
           T.FUNty(ty1,_ ) => compactTy ty1
         | T.POLYty{body = T.FUNty(ty1,_),...} => compactTy ty1
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
			 T.CONID {name, strpath, funtyCon, ty, tag, tyCon} => funtyCon
		       | _ => raise Control.Bug "Not CONID in datacon")
		      orelse S)
		  false
                  (SEnv.listItems datacon)
        in 
	  if isBoxed then T.BOXEDty else T.ATOMty
        end

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

  fun compareBoxedKind (T.GENERICty, T.GENERICty) = true
    | compareBoxedKind (T.ATOMty, T.ATOMty) = true
    | compareBoxedKind (T.BOXEDty, T.BOXEDty) = true
    | compareBoxedKind (T.DOUBLEty, T.DOUBLEty) = true
    | compareBoxedKind ((T.BOUNDVARty tid1), (T.BOUNDVARty tid2)) = tid1 = tid2
    | compareBoxedKind (_,_) = false

  fun boxedKindModifier (tyCon as {boxedKind as ref boxedKindValue,datacon = ref cons,...} : T.tyCon) =
      let
        val newBoxedKind = calcTyConBoxedKind cons
      in
        if compareBoxedKind(newBoxedKind,boxedKindValue)
        then false
        else (boxedKind:=newBoxedKind;true)
      end

  fun updateBoxedKinds tyCons = 
      fixPointUpdateTyCons boxedKindModifier tyCons

(**********************************************************************)

  fun isATOMty ty =
      case ty of
	T.ATOMty => true
      | _      => false

	
  fun isTyNameOfTyFun ({name,tyargs,body} : T.tyFun) = 
      let
	fun isTyName ty = 		
	    case ty of
	      T.CONty {tyCon, args} => true
	    | T.ALIASty (_,ty) => isTyName ty
            | T.SPECty ty => isTyName ty
	    | T.ABSSPECty(ty,_) => isTyName ty
	    | _ => false
      in
	isTyName body
      end

  fun tyFunToTyName ({name,tyargs,body}:T.tyFun) = 
      let
	fun extractCONty ty = 
	    case  ty of
	      T.CONty { tyCon = {name,strpath,abstract,tyvars,
			       id,eqKind,boxedKind,datacon},
		      args = _ } => 
	        {name = name, tyvars = tyvars, id = id, eqKind = eqKind}
	    | T.ALIASty (_,ty) => extractCONty ty
	    | _ => raise ExIllegalTyFunToTyName(name)
      in
	 extractCONty body
      end

  fun strPathOptOfTyBindInfo tyBindInfo =
      case tyBindInfo of
	T.TYSPEC {spec = {strpath,...},...}  =>  strpath
      | T.TYCON  {strpath,...} =>  strpath
      | T.TYFUN  ({body = T.ALIASty(T.CONty{tyCon = {strpath,...},...},_),...}) => strpath
      | T.TYFUN  _ => raise Control.Bug "TYFUN is not well-formed: body = T.ALIASty(T.CONty,_)"

  fun peelTySpec tyBindInfo =
      case tyBindInfo of
	T.TYSPEC {spec,impl = SOME impl} => peelTySpec impl
      |  _   => tyBindInfo

  fun isNotGenericBoxedKind boxedKindValue =
      case boxedKindValue of
          T.GENERICty => false
        | _ => true

  
end
end
