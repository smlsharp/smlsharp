(**
 * a kinded unification for ML, an imperative version.
 * @copyright (c) 2006-2010, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 *)
structure Unify : UNIFY =
struct
  structure T = Types
  structure TU = TypesUtils
  structure TB = TypeinfBase

  exception Unify
  exception EqConTy

  fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")

  fun eqConTy (ty1, ty2) =
      case (ty1,ty2) of
        (T.RAWty{tyCon={id=id1, ...}, ...}, T.RAWty{tyCon={id=id2, ...}, ...}) 
          => TyConID.eq(id1, id2)
      | _ => raise EqConTy 

  fun lubKind 
        (
         {
          tyvarName = tyvarName1,
          eqKind = eqKind1,
          lambdaDepth = lambdaDepth1,
          recordKind = recordKind1,
          id = id1
         },
         {
          tyvarName = tyvarName2,
          eqKind = eqKind2,
          lambdaDepth = lambdaDepth2,
          recordKind = recordKind2,
          id = id2
         }
        ) =
      let 
        val tyvarName =
            case (tyvarName1, tyvarName2) of
              (NONE, NONE) => NONE
             | _ =>  raise Unify
        val (eqKind, recordKind1, recordKind2) =
            (case (eqKind1, eqKind2) of
               (T.NONEQ, T.NONEQ) => (T.NONEQ, recordKind1, recordKind2)
             | (T.EQ, T.EQ) => (T.EQ, recordKind1, recordKind2)
             | (T.NONEQ, T.EQ) =>
               (T.EQ, TU.coerceReckindToEQ recordKind1, recordKind2)
             | (T.EQ, T.NONEQ) =>
               (T.EQ, recordKind1, TU.coerceReckindToEQ recordKind2)
            )
            handle TU.CoerceRecKindToEQ => raise Unify
        val lambdaDepth = 
            case Int.compare (lambdaDepth1, lambdaDepth2) of
                LESS => 
                (
                 TU.adjustDepthInRecKind lambdaDepth1 recordKind2;
                 lambdaDepth1
                )
              | GREATER =>
                (
                 TU.adjustDepthInRecKind lambdaDepth2 recordKind1;
                 lambdaDepth2
                )
              | EQUAL => lambdaDepth1
        val (newRecKind, newTyEquations) = 
            case (recordKind1, recordKind2) of
              (T.REC fl1, T.REC fl2) =>
              let 
                val newTyEquations = 
                    SEnv.listItems
                      (SEnv.intersectWith (fn x => x) (fl1, fl2))
                val newTyFields = SEnv.unionWith #1 (fl1, fl2)
              in (T.REC newTyFields, newTyEquations)
              end
            | (T.OVERLOADED L1, T.OVERLOADED L2) => 
              let
                val L = 
                    (foldr
                      (fn (ty,l) =>
                          if List.exists (fn x => eqConTy (ty,x)) L2 then
                            (ty::l) 
                          else l)
                      nil
                      L1
                      )
                    handle EqConTy =>
                           raise Control.Bug "non RAWty to eqConTy"
              in
                case L of nil => raise Unify
                        | _ => (T.OVERLOADED L, nil)
              end
            | (T.UNIV, x) => (x,nil)
            | (x, T.UNIV) => (x,nil)
            | _ => raise Unify
      in 
        (
         {
          lambdaDepth = lambdaDepth,
          recordKind = newRecKind, 
          eqKind = eqKind, 
          tyvarName = tyvarName,
          id = id1
         },
         newTyEquations
        )
      end

  fun checkKind ty 
                {
                 tyvarName,
                 eqKind,
                 lambdaDepth,
                 recordKind,
                 id
                }
                =
      let
        val _ = 
            case tyvarName of NONE => () | SOME _ => raise Unify
        val _ =
            (case eqKind of T.EQ => CheckEq.checkEq ty | _ => ())
            handle CheckEq.Eqcheck => raise Unify
        val _ = TU.adjustDepthInTy lambdaDepth ty
        val newTyEquations = 
            case recordKind of
              T.REC kindFields =>
              (case ty of 
                 T.RECORDty tyFields =>
                 SEnv.foldri
                   (fn (l, ty, tyEquations) =>
                       (
                        ty, 
                        case SEnv.find(tyFields, l) of
                          SOME ty' => ty'
                        | NONE => raise Unify
                       ) :: tyEquations)
                   nil
                   kindFields
               | T.TYVARty _ => raise Control.Bug "checkKind"
               | _ => raise Unify)
            | T.OVERLOADED L => 
              if List.exists 
                    (fn x => eqConTy(x,ty)
                        handle EqConTy => false
                    )
                    L
              then nil
              else raise Unify
            | T.UNIV => nil
      in
        newTyEquations
      end
        
  fun occurres tvarRef ty = OTSet.member (TU.EFTV ty, tvarRef)

  (**
   * The mysterious control flag "calledFromPatternUnify" should be
   * eiminated in future.
   *)
  fun unifyTypeEquations calledFromPatternUnify L =
      let
        fun unifyTy nil = ()
          | unifyTy ((ty1, ty2) :: tail) = 
            case (ty1, ty2) of
           (* Special types: SUBSTITUTED, ALIASty, ERRORty, DUMMYty,
            * OPAQUEty, SPECty. These cases are all disjoint.
            *)
              (T.TYVARty (ref(T.SUBSTITUTED derefTy1)), _)
              => unifyTy ((derefTy1, ty2) :: tail)
            | (_, T.TYVARty (ref(T.SUBSTITUTED derefTy2)))
              => unifyTy ((ty1, derefTy2) :: tail)
            | (T.ALIASty(_, ty1), _) => unifyTy ((ty1, ty2) :: tail)
            | (ty1, T.ALIASty(_, ty2)) => unifyTy ((ty1, ty2) :: tail)
            | (T.ERRORty, _) => unifyTy tail
            | (_, T.ERRORty) => unifyTy tail
            | (T.DUMMYty n2, T.DUMMYty n1) =>
              if n1 = n2 then unifyTy tail else raise Unify
            | (T.DUMMYty _, _) => raise Unify
            | (_, T.DUMMYty _) => raise Unify
            | (T.OPAQUEty {spec={tyCon={id=id1, ...}, args = args1}, ...},
               T.OPAQUEty {spec={tyCon={id=id2, ...}, args = args2}, ...})
              =>
              let
                val omit = calledFromPatternUnify orelse TyConID.eq(id1, id2)
              in
                if omit andalso length args1 = length args2
                then unifyTy (ListPair.zip (args1, args2) @ tail)
                else raise Unify
              end
            | (T.OPAQUEty {spec={tyCon={id = id1,...}, args = args1},...},
               T.RAWty {tyCon = {id = id2,...}, args = args2})
              =>
              let
                val omit = calledFromPatternUnify orelse TyConID.eq(id1, id2)
              in
                if omit andalso length args1 = length args2
                then unifyTy (ListPair.zip (args1, args2) @ tail)
                else raise Unify
              end
            | (T.RAWty {tyCon = {id = id1, ...}, args = args1},
               T.OPAQUEty {spec = {tyCon={id = id2, ...}, args = args2},...})
              =>
              let
                val omit = calledFromPatternUnify orelse TyConID.eq(id1, id2)
              in
                if omit andalso length args1 = length args2
                then unifyTy (ListPair.zip (args1, args2) @ tail)
                else raise Unify
              end
            | (T.SPECty {tyCon = {id = id1, ...}, args = args1},
               T.SPECty {tyCon = {id = id2, ...}, args = args2}) =>
              let
                val omit = calledFromPatternUnify orelse TyConID.eq(id1, id2)
              in
                if omit andalso length args1 = length args2
                then unifyTy (ListPair.zip (args1, args2) @ tail)
                else raise Unify
              end
            | (T.SPECty {tyCon = {id = id1, ...}, args = args1},
               T.RAWty {tyCon = {id = id2, ...}, args = args2}) =>
              let
                val omit = calledFromPatternUnify orelse TyConID.eq(id1, id2)
              in
                if omit andalso length args1 = length args2
                then unifyTy (ListPair.zip (args1, args2) @ tail)
                else raise Unify
              end
            | (T.RAWty {tyCon = {id = id1, ...}, args = args1},
               T.SPECty {tyCon = {id = id2, ...}, args = args2}) =>
              let
                val omit = calledFromPatternUnify orelse TyConID.eq(id1, id2)
              in
                if omit andalso length args1 = length args2
                then unifyTy (ListPair.zip (args1, args2) @ tail)
                else raise Unify
              end
           (* type variables *)
            | (
               T.TYVARty(tvState1 as ref(T.TVAR {tyvarName = SOME _,
                                                 eqKind = eqkind1,
                                                 recordKind= T.UNIV,
                                             ...})),
               T.TYVARty(tvState2 as ref(T.TVAR {lambdaDepth,
                                                 tyvarName = NONE,
                                                 eqKind = eqkind2,
                                                 recordKind= T.UNIV,
                                             ...}))
              ) =>
              let
                val _ =
                    case (eqkind1, eqkind2) of
                      (T.NONEQ, T.EQ) => raise Unify
                    | _ => ()
              in
                (
                 TU.adjustDepthInTy lambdaDepth ty1;
                 TU.performSubst(ty2, ty1); 
                 unifyTy  tail
                )
              end
            | (
               T.TYVARty(tvState1 as ref(T.TVAR {lambdaDepth,
                                                 tyvarName = NONE,
                                                 eqKind = eqkind1,
                                                 recordKind= T.UNIV,
                                                 ...})),
               T.TYVARty(tvState2 as ref(T.TVAR {tyvarName = SOME _,
                                                 eqKind = eqkind2,
                                                 recordKind= T.UNIV,
                                                 ...}))
              ) =>
              let
                val _ =
                    case (eqkind1, eqkind2) of
                      (T.EQ, T.NONEQ) => raise Unify
                    | _ => ()
              in
                (
                 TU.adjustDepthInTy lambdaDepth ty2;
                 TU.performSubst(ty1, ty2); 
                 unifyTy tail
                )
              end
            | (
               T.TYVARty (tvState1 as (ref(T.TVAR tvKind1))),
               T.TYVARty (tvState2 as (ref(T.TVAR tvKind2)))
              ) => 
              if FreeTypeVarID.eq(#id tvKind1, #id tvKind2) then unifyTy tail
              else if occurres tvState1 ty2 orelse occurres tvState2 ty1 
              then raise Unify
              else 
              (* Here we perform imperative udate to the kind 
                 Whithout treating the above two cases specially,
                 this seems to cause the mlyacc benchmark loops.
                 The following one does not show this problem.
                let 
                  val (newKind, newTyEquations) =
                      lubKind (tvKind1, tvKind2)
                  val newTy = T.newtyRaw {tyvarNmae = #tyvarNmae newKind,
                                          id = #id newKind,
                                          lambdaDepth = #lambdaDepth newKind,
                                          recordKind = #recordKind newKind,
                                          eqKind = #eqKind newKind}
                in
                  TU.performSubst(ty1, newTy);
                  TU.performSubst(ty2, newTy);
                  unifyTy (newTyEquations@tail)
                end
               *)
                let 
                  val (newKind, newTyEquations) =
                      lubKind (tvKind1, tvKind2)
                  val _ = tvState1 := T.TVAR newKind
                in
                  TU.performSubst(ty2, ty1);
                  unifyTy (newTyEquations@tail)
                end
            | (
               T.TYVARty (tvState1 as ref(T.TVAR tvKind1)),
               _
              ) =>
              if occurres tvState1 ty2 
              then raise Unify
              else
                let
                  val newTyEquations = checkKind ty2 tvKind1
                in
                  (
                   TU.performSubst(ty1, ty2); 
                   unifyTy (newTyEquations @ tail)
                  )
                end
            | (
               _,
               T.TYVARty (tvState2 as ref(T.TVAR tvKind2))
              ) =>
              if occurres tvState2 ty1
              then raise Unify
              else
                let
                  val newTyEquations = checkKind ty1 tvKind2
                in
                  (
                   TU.performSubst(ty2, ty1); 
                   unifyTy (newTyEquations @ tail)
                  )
                end
           (* constructor types *)
            | (
               T.FUNMty(domainTyList1, rangeTy1),
               T.FUNMty(domainTyList2, rangeTy2)
              ) =>
              if length domainTyList1 = length domainTyList2 then
                unifyTy (ListPair.zip (domainTyList1, domainTyList2)
                         @ ((rangeTy1, rangeTy2) :: tail))
              else raise Unify
            | (
               T.RAWty {tyCon = {id = id1,...}, args = tyList1},
               T.RAWty {tyCon = {id = id2,...}, args = tyList2}
              ) =>
              let
                val omit = calledFromPatternUnify orelse TyConID.eq(id1, id2)
              in
                if omit andalso length tyList1 = length tyList2
                then unifyTy  (ListPair.zip (tyList1, tyList2) @ tail)
                else raise Unify
              end
            | (T.RECORDty tyFields1, T.RECORDty tyFields2) =>
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
   * Perform imperative unification. When it succeeds, the unifier had
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
   * environment. So unification on types fails. But since signature match
   * guarrantees the type correctness, we only need to do patternUnify.
   *)
  fun patternUnify typeEqs = unifyTypeEquations true typeEqs

end
