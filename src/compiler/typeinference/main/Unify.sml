(**
 * a kinded unification for ML, an imperative version.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: Unify.sml,v 1.4 2006/03/02 20:25:59 ohori Exp $
 *)
structure Unify : UNIFY =
struct

    (* ToDo : eliminate "open". *)
    open Types 
    open TypesUtils 
    open TypeinfBase 
    open StaticEnv
    structure SE = StaticEnv

    exception Unify
    exception KindCheck

    fun eqBaseTy (CONty{tyCon = tyCon1, ...}, CONty{tyCon = tyCon2, ...}) =
             #id tyCon1 = #id tyCon2
      | eqBaseTy _ = false
    fun isMember (ty,nil) = false
      | isMember (ty1, ty2 :: tail) =
        eqBaseTy(ty1, ty2) orelse isMember(ty1, tail)
    fun isEqtype (CONty{tyCon = {id, ...}, ...}) =
        (id = SE.boolTyConid)
        orelse (id = SE.intTyConid)
        orelse (id = SE.wordTyConid)
        orelse (id = charTyConid)
        orelse (id = stringTyConid)
    fun intersection (l1,l2) =
      foldr
      (fn (ty,l) => if List.exists (fn x => eqBaseTy (ty,x)) l2 then
                      (ty::l) 
                    else l)
      nil
      l1

    (* *
     * Force the two kind compatible and compute the union of the two
     *
     * @params tvKind1 * tvKind2 
     * @param tvKind1 type variable kind
     * @param tvKind2 type variable kind
     * @return type variable kind
     *)
    fun lubKind (tvKind1 : tvKind, tvKind2 : tvKind) =
        let 
          val (newRecKind, newTyEquations) = 
              case (#recKind tvKind1, #recKind tvKind2) of
                (UNIV, x) => (x, nil)
              | (x, UNIV) => (x, nil)
              | (REC fl1, REC fl2) =>
                let 
                  val newTyEquations = 
                      SEnv.listItems
                          (SEnv.intersectWith (fn x => x) (fl1, fl2))
                  val newTyFields = SEnv.unionWith #1 (fl1, fl2)
                in (REC newTyFields, newTyEquations)
                end
              | (OVERLOADED L1, OVERLOADED L2) => 
                let val L = intersection(L1, L2)
                in
                  case L of nil => raise Unify
                    | _ => (OVERLOADED L, nil)
                end
              | _ => raise Control.Bug "lubKind: incompatible kind"
          val eqKind = 
              case (#eqKind tvKind1, #eqKind tvKind2) of
                (NONEQ, x) => x
              | (x, NONEQ) => x
              | _ => EQ
          val tyvarName = 
              case (#tyvarName tvKind1, #tyvarName tvKind2) of
                (NONE, x) => x
              | (x, NONE) => x
              | (SOME v1, SOME v2) => SOME v1
        in 
          (
            {recKind = newRecKind, eqKind = eqKind, tyvarName = tyvarName},
            newTyEquations
          )
        end

    (**
     * Generate a set of type equations to force the type to have the kind.
     * the argument type should not be a type varaible.
     * KindCheck is raised if fail.
     *
     * @params ty kind
     * @param tyConEnv tyCon env
     * @param ty type to be coerced
     * @param kind the kind of the type.
     * @return nil
     *)
    fun checkKind ty (kind : tvKind) = 
        let 
          val _ =
              (case #eqKind kind of EQ => CheckEq.checkEq ty | _ => ())
              handle CheckEq.Eqcheck => raise KindCheck
          val newTyEquations = 
              case #recKind kind of
                REC kindFields =>
                (case ty of 
                   RECORDty tyFields =>
                   SEnv.foldri
                       (fn (l, ty, tyEquations) =>
                           (
                             ty, 
                             case SEnv.find(tyFields, l) of
                               SOME ty' => ty'
                             | NONE => raise KindCheck
                           ) :: tyEquations)
                       nil
                       kindFields
                 | TYVARty _ => raise Control.Bug "checkKind"
                 | _ => raise KindCheck)
              | UNIV => nil
              | OVERLOADED _ => nil
        in
          newTyEquations
        end
             
    (**
     * Check that a free type variable occurres in a type
     *
     * @params tvState ty
     * @param tvState a tvstate to identify a free type variable
     * @param ty a type
     * @return bool
     *)
    fun occurres tvarRef ty = OTSet.member (EFTV ty, tvarRef)

 (* for debugging *)
  fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")

  fun printTyPair (ty1, ty2) = 
    (
     print "(";
     print (TypeFormatter.tyToString ty1);
     print ",";
     print (TypeFormatter.tyToString ty2);
     print "); "
     )

  fun unifyTypeEquations calledFromPatternUnify L =
    let
      fun unifyTy nil = ()
        | unifyTy (arg as ((ty1, ty2) :: tail)) = 
          case (ty1, ty2) of
            (TYVARty (ref(SUBSTITUTED derefTy1)), _) => 
              unifyTy ((derefTy1, ty2) :: tail)
          | (_, TYVARty (ref(SUBSTITUTED derefTy2))) => 
              unifyTy ((ty1, derefTy2) :: tail)
          | (ALIASty(_, ty1), _) =>
              unifyTy ((ty1, ty2) :: tail)
          | (ty1, ALIASty(_, ty2)) =>         
              unifyTy ((ty1, ty2) :: tail)
          | (ERRORty, _) => unifyTy tail
          | (_, ERRORty) => unifyTy tail
          | (DUMMYty n2, DUMMYty n1) => if n1 = n2 then unifyTy tail else raise Unify
          | (DUMMYty _, _) => raise Unify
          | (_, DUMMYty _) => raise Unify
          | (
             TYVARty(tvState1 as ref(TVAR {tyvarName = NONE, eqKind = NONEQ, recKind= UNIV, id = id1,...})),
             _
             ) =>
              (case ty2 of
                TYVARty(ref(TVAR{id=id2,...})) =>
                  if id1 = id2 then unifyTy tail
                  else if occurres tvState1 ty2 
                         then raise Unify
                  else (performSubst(ty1, ty2); unifyTy tail)
              | _ => if occurres tvState1 ty2 
                       then raise Unify
                     else (performSubst(ty1, ty2); unifyTy tail)
             )
          | (
             TYVARty(tvState1 as ref(TVAR {tyvarName = NONE, eqKind = EQ, recKind= UNIV, id = id1,...})),
             _
             ) =>
             let 
               val _ = CheckEq.checkEq ty2  handle CheckEq.Eqcheck => raise Unify
             in
               case ty2 of
                TYVARty(ref(TVAR{id=id2,...})) =>
                  if id1 = id2 then unifyTy tail
                  else if occurres tvState1 ty2 
                         then raise Unify
                       else (performSubst(ty1, ty2); unifyTy tail)
              | _ => if occurres tvState1 ty2
                       then raise Unify
                     else (performSubst(ty1, ty2); unifyTy tail)
             end
          | (
             _,
             TYVARty(tvState2 as ref(TVAR {tyvarName = NONE, eqKind = NONEQ, recKind= UNIV, id = id2,...}))
             ) =>
              (case ty1 of
                TYVARty(ref(TVAR{id=id1,...})) =>
                  if id1 = id2 then unifyTy tail
                  else if occurres tvState2 ty1 
                         then raise Unify
                       else (performSubst(ty2, ty1); unifyTy tail)
              | _ => if occurres tvState2 ty1 
                       then raise Unify
                     else (performSubst(ty2, ty1); unifyTy tail)
             )
          | (
             _,
             TYVARty(tvState2 as ref(TVAR {tyvarName = NONE, eqKind = EQ, recKind= UNIV, id = id2,...}))
             ) =>
             let 
               val _ = CheckEq.checkEq ty1 handle CheckEq.Eqcheck => raise Unify
             in
               case ty1 of
                TYVARty(ref(TVAR{id=id1,...})) =>
                  if id1 = id2 then unifyTy tail
                  else if occurres tvState2 ty1 
                         then raise Unify
                       else (performSubst(ty2, ty1); unifyTy tail)
              | _ => if occurres tvState2 ty1 
                       then raise Unify
                     else (performSubst(ty2, ty1); unifyTy tail)
             end
          | (ABSSPECty(ty11, ty12),  ABSSPECty(ty21, ty22)) => 
            unifyTy ((ty11,ty21) :: tail)
          | (ty1, SPECty ty2) => unifyTy ((ty1,ty2) :: tail)
          | (SPECty ty1, ty2) => unifyTy ((ty1,ty2) :: tail)
          | (
              TYVARty(ref(TVAR {tyvarName = SOME _, id = id1, ...})), 
              TYVARty(ref(TVAR {tyvarName = SOME _, id = id2, ...}))
            ) =>
             if id1 = id2 then unifyTy tail else raise Unify
          | (TYVARty (ref(TVAR {tyvarName = SOME _, ...})), _) => raise Unify
          | (_, TYVARty (ref(TVAR {tyvarName = SOME _, ...}))) => raise Unify
          | (
             TYVARty
              (ref(TVAR (tvKind1 as {recKind = OVERLOADED L1, ...}))), 
              TYVARty
              (ref(TVAR (tvKind2 as {recKind = OVERLOADED L2, ...})))
             ) =>
               if #id tvKind1 = #id tvKind2 then unifyTy tail
               else
                 let 
                   val (newTvarInfo, newTyEquations) = lubKind (tvKind1, tvKind2)
                   val newty = newty newTvarInfo
                 in
                   performSubst(ty1, newty);
                   performSubst(ty2, newty);
                   unifyTy (newTyEquations@tail)
                 end
          | (
             TYVARty (ref(TVAR {recKind = OVERLOADED L1, ...})), 
             CONty _
             ) =>
               if isMember (ty2, L1)
                 then (performSubst(ty1, ty2); unifyTy tail)
               else raise Unify
          | (
             CONty _,
             TYVARty (ref(TVAR {recKind = OVERLOADED L1, ...}))
            ) =>
              if isMember (ty1,L1)
                then (performSubst(ty2, ty1); unifyTy tail)
              else raise Unify
          | (
              TYVARty (ref(TVAR {recKind = OVERLOADED L1, ...})), 
              _
            ) => raise Unify
          | (
             _,
             TYVARty (ref(TVAR {recKind = OVERLOADED L1, ...}))
            ) => raise Unify
         | (
            TYVARty (tvState1 as (ref(TVAR tvKind1))),
            TYVARty (tvState2 as (ref(TVAR tvKind2)))
            ) => 
              if #id tvKind1 = #id tvKind2
                then unifyTy tail
              else 
                if occurres tvState1 ty2 orelse occurres tvState2 ty1 
                  then raise Unify
                else 
                  let 
                    val (newTvarInfo, newTyEquations) = lubKind (tvKind1, tvKind2)
                    val newty = newty newTvarInfo
                  in
                    performSubst(ty1, newty);
                    performSubst(ty2, newty);
                    unifyTy (newTyEquations@tail)
                  end
          | (TYVARty (tvState1 as ref(TVAR tvKind1)), ty2) => 
             if occurres tvState1 ty2 
                then raise Unify
              else 
                (let 
                   val newTyEquations = checkKind ty2 tvKind1
                 in 
                   unifyTy newTyEquations;
                   performSubst(ty1, ty2); 
                   unifyTy tail 
                 end
                   handle KindCheck => raise Unify)
          | (ty1, TYVARty (tvState2 as ref(TVAR tvKind2))) => 
             if occurres tvState2 ty1 
               then raise Unify
             else 
               (let 
                  val newTyEquations = checkKind ty1 tvKind2
                in
                  unifyTy newTyEquations;
                  performSubst(ty2,ty1); 
                  unifyTy tail 
                end
                  handle KindCheck => raise Unify)
          | (FUNMty(domainTyList1, rangeTy1), FUNMty(domainTyList2, rangeTy2)) =>
              if length domainTyList1 = length domainTyList2 then
                unifyTy (ListPair.zip (domainTyList1, domainTyList2) @ ((rangeTy1, rangeTy2) :: tail))
              else raise Unify
          | (
              CONty{tyCon = tyCon1, args = tyList1},
              CONty{tyCon = tyCon2, args = tyList2}
             ) =>
              let
                val {name=name1,id=id1,...} = tyCon1
                val {name=name2,id=id2,...} = tyCon2
                val omit= calledFromPatternUnify orelse id1 = id2
              in
                if omit andalso length tyList1 = length tyList2
                  then unifyTy  (ListPair.zip (tyList1, tyList2) @ tail)
                else raise Unify
              end
           | (RECORDty tyFields1, RECORDty tyFields2) =>
              let
                val (newTyEquations, rest) = 
                  SEnv.foldri 
                  (fn (label, ty1, (newTyEquations, rest)) =>
                   let val (rest, ty2) = SEnv.remove(rest, label)
                   in ((ty1, ty2) :: newTyEquations, rest) end
                   handle LibBase.NotFound => raise Unify)
                  (nil, tyFields2)
                  tyFields1
              in
                if SEnv.isEmpty rest 
                  then unifyTy (newTyEquations@tail)
                else raise Unify
              end
           | (ty1, ty2) => raise Unify
    in
      unifyTy L
    end
  (**
   *  Perform imperative unification, When it succeeds, the unifier had
   * already been applied. 
   * 
   * @params typeEqs
   * @return nil 
   *)
  fun unify typeEqs = unifyTypeEquations false typeEqs

  (* Note: only used in type instantiation for signature match.
   * Since signature match guaranttes the type is correct
   * we just need to do patternUnify to avoid a problem causing
   * by the following case :
   * 
   *   structure A = struct ... end :> sig ... end : sig ... end
   *
   * For opaque signature matching, we generate a type instantiation
   * environment based on the actual structure environment and the 
   * type instantiated signature environment (instead of the abstract 
   * signature environment). And then We do transparent signature
   * match, but the instantiated type in transparent signature is 
   * enriched by the opaque signature instead of the original structure
   * environment. So unification on types fails. But since signature match guarrantees 
   * the type correctness, we only need to do patternUnify.
   *)
  fun patternUnify typeEqs = unifyTypeEquations true typeEqs
end
