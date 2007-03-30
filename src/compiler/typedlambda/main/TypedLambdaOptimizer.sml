(**
 * THIS IS OBSOLUTE. AN OPTIMIZER IS BEING WRITTEN.
 * Source-to-source optimizer for the typed lambda calculus.
 * This phase also rectifi the bound variables 
 *  so that bound and free variables are all unique.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: TypedLambdaOptimizer.sml,v 1.15 2007/01/21 13:41:33 kiyoshiy Exp $
 *)
structure TypedLambdaOptimizer =
struct

  local
    open TypedLambda TypedLambdaUtils 
    structure T = Types
  in
  fun occursOnce v vset = 
      case VEnv.find(vset, v) of
        SOME n => n <= 1
      | NONE => true
    
  fun notOccurs v vset = 
      case VEnv.find(vset, v) of
        SOME _ => false
      | NONE => true
    
  fun isAtom exp =
      case exp of
	TLVAR v => true
      | TLCONSTANT _ => true
      | _ => false

  fun isValue exp =
      isAtom exp orelse
      case exp of
        TLRECORD (exps, ty, loc) =>  List.all isValue exps
(*
      | TLSELECTINT (exp, i, ty) => isValue exp
      | TLSELECTVAR (exp, v, ty) => isValue exp
*)
      | TLFNM _ => true
      | TLFN _ => true
      | TLPOLY (btvEnv, ty, exp, loc) => isValue exp
      | TLTAPP (exp, ty, tyl, loc)  => isValue exp
      | TLTERMVAR _ => true
      | _ => false

  fun optimizePrim (prim as {name, ty}, tyl, expList, loc) =
      case (name, expList) of
        ("^", [TLCONSTANT(STRING s1, loc1), TLCONSTANT(STRING s2, loc2)]) =>
        TLCONSTANT(STRING (s1 ^ s2), loc)
      (* need to list up all the statically evaluated cases *)
      | _ => TLPRIMAPPLY(prim, tyl, expList, loc)
  
  (**
   * The optimizer main function.
   * A care must be taken not to traverse multiple times to avoid exponential
   * blow up.
   *)
  fun optimizeExp subst exp =
      case exp of
        TLCONSTANT (c, loc) => TLCONSTANT (c, loc) 
      | TLVAR (v, loc) =>
        (case VEnv.find(subst, v) of SOME e => e | NONE => exp)
      | TLGETGLOBAL _ => exp
      | TLGETFIELD (e1, int, ty, loc) =>
        TLGETFIELD (optimizeExp subst e1, int, ty, loc)
      | TLSETFIELD (e1, e2, int, ty, loc) =>
        TLSETFIELD (optimizeExp subst e1, optimizeExp subst e2, int, ty, loc)
      | TLARRAY (e1, e2, ty1, ty2, loc) =>
        TLARRAY (optimizeExp subst e1, optimizeExp subst e2, ty1, ty2, loc)
      | TLPRIMAPPLY (prim, tyl, exl, loc) => 
        optimizePrim (prim, tyl, map (optimizeExp subst) exl, loc)
      | TLAPP (TLFN(v, ty0, e1, loc1), ty, e2, loc) =>
        optimizeExp subst (TLMONOLET([(v, e2)], e1, loc))
      | TLAPP (e1, ty, e2, loc) => 
	let val newe1 = optimizeExp subst e1
	in
	  case newe1 of 
	    TLFN(v, ty0, e1', loc1) =>
            optimizeExp subst (TLMONOLET([(v, e2)], e1', loc1))
	  | _ => TLAPP (newe1, ty, optimizeExp subst e2, loc)
	end
      | TLAPPM (TLFNM(vs, ty0, e1, loc1), ty, el, loc) =>
        optimizeExp subst (TLMONOLET(ListPair.zip(vs, el), e1, loc1))
      | TLAPPM (e1, ty, el, loc) => 
	let val newe1 = optimizeExp subst e1
	in
	  case newe1 of 
	    TLFNM(vs, ty, e1', loc1) =>
            optimizeExp subst (TLMONOLET(ListPair.zip(vs, el), e1', loc1))
	  | _ => TLAPPM (newe1, ty, map (optimizeExp subst) el, loc)
	end
      | TLMONOLET (binds, exp, loc) =>
	let
          val vars = freeVars exp
	  val (newsubst, newbinds) = 
	      foldr
                  (fn ((v, e), (subst, newbinds)) => 
		      let val newExp = optimizeExp subst e
		      in
		        if
                          isAtom newExp orelse
                          isValue newExp andalso
                          occursOnce v vars
                        then (VEnv.insert(subst, v, newExp), newbinds)
		        else
		          let val newv = Vars.newTLVar (T.newVarId(),#ty v)
		          in
			    ((* ToDo : pass correct loc of v. *)
                              VEnv.insert(subst, v, TLVAR (newv, loc)),
                              (newv, newExp) :: newbinds
                            )
		          end
		      end)
	          (subst, nil)
	          binds
	  val newexp = optimizeExp newsubst exp
	in
	  case newbinds of
            nil => newexp | _ => TLMONOLET(newbinds, newexp, loc)
	end
      | TLLET (decls, exps, tyl, loc) =>
	let 
	  val vars = 
	      foldr
                  (fn (e, vset) => 
		      let val vs = freeVars e
		      in VEnv.unionWith (op +) (vs, vset)
		      end)
	          VEnv.empty
	          exps
	  val (exsubst, decls) = optimizeDecs subst decls vars
	  val exps = map (optimizeExp (VEnv.unionWith #1 (exsubst,subst))) exps
	in
          case decls of
	    nil => (case exps of [x] => x | _ => TLSEQ (exps, tyl, loc))
	  | _ => TLLET(decls, exps, tyl, loc)
	end
      | TLRECORD (fields, ty, loc) =>
        TLRECORD ((map (optimizeExp subst) fields), ty, loc)
      | TLSELECT (record, selector, ty, loc) =>
        TLSELECT (optimizeExp subst record, selector, ty, loc) 
      | TLMODIFY (record, recordTy, selector, exp, expTy, loc) =>
        TLMODIFY
            (
              optimizeExp subst record,
              recordTy,
              selector,
              optimizeExp subst exp,
              expTy,
              loc
            )
(*
      | TLSELECTINT (exp1 as TLRECORD (exl, _), i, ty) => 
	optimizeExp subst (List.nth (exl, i))
      | TLSELECTINT (e1, i, ty) => 
	let val newe1 = optimizeExp subst e1
	in
	  case newe1 of
            TLRECORD (exl, _) => List.nth (exl, i)
	  | _ => TLSELECTINT (newe1, i, ty)
	end
      | TLSELECTVAR (e1, v, ty) => 
	(case VEnv.find(subst, v) of 
	   SOME (TLVAR v) => TLSELECTVAR(optimizeExp subst e1, v ,ty)
         | NONE => raise Control.Bug "optimize no var in TLSELECT")
      | TLMODIFYINT (e1, ty1, i, e2, ty2) => 
	TLMODIFYINT (e1, ty1, i, e2, ty2)
      | TLMODIFYVAR (e1, ty1, v, e2, ty2) => 
	TLMODIFYVAR (e1, ty1, v, e2, ty2)
*)
      | TLRAISE (e, ty, loc) => TLRAISE (optimizeExp subst e, ty, loc)
      | TLHANDLE (e1, v, e2, loc) =>
	TLHANDLE(optimizeExp subst e1, v, optimizeExp subst e2, loc)
      | TLFNM (vs, ty, e, loc) => 
	let
	  val (newsubst, newvs) = 
	    foldr
                (fn (v, (newsubst, newvs)) => 
		    let val newv = Vars.newTLVar (T.newVarId(), #ty v)
		    in
                      (
                        VEnv.insert(newsubst, v, TLVAR (newv, loc)),
                        newv :: newvs
                      )
		    end)
	        (subst, nil)
	        vs
	in
	  TLFNM(newvs, ty, optimizeExp newsubst e, loc)
	end
      | TLFN (v, ty, e, loc) => 
	let
          val newv = Vars.newTLVar (T.newVarId(),#ty v)
          val locOfE = getLocOfExp e
          val optimizedE =
              optimizeExp (VEnv.insert(subst, v, TLVAR (newv, locOfE))) e
	in
          TLFN (newv, ty, optimizedE, loc)
	end
      | TLPOLY (tvEnv, ty, e, loc) =>
        TLPOLY(tvEnv, ty, optimizeExp subst e, loc)
      | TLTAPP (TLPOLY (tvEnv, ty, e1, loc1), ty1, tys, loc) => 
	let 
	  val bsubst = 
	      ListPair.foldr
                  (fn ((i, _), ty, S) => IEnv.insert(S, i, ty))
                  IEnv.empty
                  (IEnv.listItemsi tvEnv, tys)
	in 
	  substBTvarExp bsubst (optimizeExp subst e1)
	end
      | TLTAPP (e, ty1, tys, loc) => TLTAPP(optimizeExp subst e, ty1, tys, loc)
      | TLSWITCH (e1, ty, rules, e2, loc) =>
	TLSWITCH
            (
              optimizeExp subst e1,
	      ty,
	      map (fn (c, e) => (c, optimizeExp subst e)) rules,
	      optimizeExp subst e2,
              loc
            )
      | TLLETTERM (vs, e, loc) => raise Control.Bug "letterm not implemented"
      | TLTERMVAR (v, vs, loc) => raise Control.Bug "letterm not implemented"
      | TLSEQ (es, tyl, loc) => TLSEQ(map (optimizeExp subst) es, tyl, loc)
      | TLCAST (e, ty, loc) => TLCAST(optimizeExp subst e, ty, loc)
      | TLOFFSET(recordTy, label, loc) => exp

  and optimizeDec subst dec vars =
      case dec of
        TLVAL (binds, loc) =>
	(* Note: this is a a set of simultaneous defintion. *)
	let 
	  val (extrasubst, newbinds) = 
	      foldr
                  (fn (
                        (Types.VALIDENT (v as {ty, ...}), e),
                        (extrasubst,newbinds)
                      ) => 
		      let 
                        val newExp = optimizeExp subst e
                        val locOfExp = getLocOfExp newExp
                      in
                        if
                          isAtom newExp orelse
                          isValue newExp andalso
                          occursOnce v vars
                        then (VEnv.insert(extrasubst, v, newExp), newbinds)
                        else
                          if notOccurs v vars
                          then
                            (
                              extrasubst,
                              (Types.VALIDENTWILD ty, newExp) :: newbinds
                            )
                          else
                            let val newv = Vars.newTLVar (T.newVarId(),#ty v)
                            in
                              (
                                VEnv.insert
                                    (extrasubst, v, TLVAR (newv, locOfExp)),
                                (Types.VALIDENT newv, newExp) :: newbinds
                              )
                            end
                      end
                    | ((Types.VALIDENTWILD ty, e), (extrasubst, newbinds)) => 
		      let val newExp = optimizeExp subst e
                      in
                        if isValue newExp
                        then (extrasubst, newbinds)
                        else
                          (
                            extrasubst,
                            (Types.VALIDENTWILD ty, newExp) :: newbinds
                          )
                      end)
	          (VEnv.empty, nil)
	          binds
	in
          case newbinds of
            nil => (extrasubst, nil)
          | _ => (extrasubst, [TLVAL (newbinds, loc)])
	end
      | TLVALREC (recbinds, loc) => 
	let
	  val (extrasubst, newrecbind) = 
	      foldr
                  (fn ((v, ty, e), (extrasubst, newrecbind)) =>
		      let
                        val newv = Vars.newTLVar (T.newVarId(),#ty v)
                        val locOfE = getLocOfExp e
		      in
                        (
                          VEnv.insert(extrasubst, v, TLVAR (newv, locOfE)), 
			  (v, newv, ty, e) :: newrecbind
                        )
		      end)
	          (VEnv.empty, nil)
	          recbinds
	in
	  (
            extrasubst,
	    [
              TLVALREC
              (map
               (fn (v, newv, ty, e) => 
		   (
                     newv,
                     ty,
                     optimizeExp (VEnv.unionWith #1 (extrasubst,subst)) e
                   ))
	       newrecbind,
               loc)
            ]
	  )
	end
      | TLVALPOLYREC (btvEnv, recbinds, loc) => 
	let
	  val (extrasubst, newrecbind) = 
	      foldr
                  (fn ((v, ty, e), (extrasubst, newrecbind)) =>
		      let
                        val newv = Vars.newTLVar (T.newVarId(),#ty v)
                        val locOfE = getLocOfExp e
		      in
                        (
                          VEnv.insert(extrasubst, v, TLVAR (newv, locOfE)), 
			  (v, newv, ty, e) :: newrecbind
                        )
		      end)
	          (VEnv.empty, nil)
	          recbinds
	in
	  (
            extrasubst,
	    [
              TLVALPOLYREC
              (
                btvEnv,
		map
                (fn (v, newv, ty, e) => 
		    (
                      newv,
                      ty,
                      optimizeExp (VEnv.unionWith #1 (extrasubst, subst)) e
                    )) 
		newrecbind,
                loc
              )
            ]
	  )
	end
      | TLLOCALDEC (decls1, decls2, loc) =>
	let 
	  val newvars = VEnv.unionWith (op + ) (freeVarsInDecs decls2, vars)
	  val (exsub1, decls1) = optimizeDecs subst decls1 newvars
	  val (exsub2, decls2) =
              optimizeDecs (VEnv.unionWith #1 (exsub1, subst)) decls2 vars
	in
          case decls1 of
	    nil => (exsub2, decls2)
	  | _ => (exsub2, [TLLOCALDEC(decls1, decls2, loc)])
	end
      | TLSETGLOBAL(string,exp,loc) => (VEnv.empty,nil)
      | TLEMPTY loc => (VEnv.empty, nil)

  and optimizeDecs subst nil vars = (VEnv.empty, nil)
    | optimizeDecs subst (h :: t) vars = 
      let 
        (* this is exponential; must be re-write *)
	val newvars = VEnv.unionWith (op +) (freeVarsInDecs t, vars)
	val (exsub1, decls1) = optimizeDec subst h newvars
	val (exsub2, decls2) =
            optimizeDecs (VEnv.unionWith #1 (exsub1, subst)) t vars
      in (VEnv.unionWith #1 (exsub2, exsub1), decls1 @ decls2) end

  fun optimizeTopDec subst dec =
      case dec of
        TLVAL (binds, loc) =>
        TLVAL (map (fn (v, e) => (v, optimizeExp subst e)) binds, loc)
      | TLVALREC (recbinds, loc) =>
        TLVALREC
            (map (fn (v, ty, e) => (v, ty, optimizeExp subst e)) recbinds, loc)
      | TLVALPOLYREC (btvEnv,recbinds,loc) =>
        let
          val newBinds =
              map (fn (v, ty, e) => (v, ty, optimizeExp subst e)) recbinds
        in
          TLVALPOLYREC(btvEnv, newBinds, loc)
        end
      | TLLOCALDEC (decls1, decls2, loc) =>
	let 
	  val vars = freeVarsInDecs decls2
	  val (exsub1, decls1) = optimizeDecs subst decls1 vars
	  val decls2 =
              optimizeTopDecs (VEnv.unionWith #1 (exsub1, subst)) decls2
	in TLLOCALDEC(decls1, decls2, loc)
	end
      | TLSETGLOBAL(string,exp,loc) =>
	TLSETGLOBAL(string,optimizeExp subst exp,loc)
      | TLEMPTY loc => dec

  and optimizeTopDecs subst decs = map (optimizeTopDec subst) decs

  val optimize = optimizeTopDecs

end
end
