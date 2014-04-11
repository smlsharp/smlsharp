(**
 * a kinded unification for ML, an imperative version.
 * @copyright (c) 2006-2010, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 *)
structure Unify =
struct
local
  structure A = Absyn
  structure T = Types
  structure TB = TypesBasics
  structure TU = TypesUtils
in
  exception Unify
  exception EqRawTy

  fun bug s = Bug.Bug ("Unify:" ^ s)

  fun occurres tvarRef ty = 
      let
        val (_, set, _) = TB.EFTV ty
      in
        OTSet.member (set, tvarRef)
      end
  fun occurresTyList tvarRef nil = false
    | occurresTyList tvarRef (h::t) = 
      occurres tvarRef h orelse occurresTyList tvarRef t
  fun occurresTyEqList tvarRef nil = false
    | occurresTyEqList tvarRef ((h1,h2)::t) = 
      occurres tvarRef h1
      orelse occurres tvarRef h2
      orelse occurresTyEqList tvarRef t
                                
  exception TyConId
  fun tyConId ty = 
      case TB.derefTy ty of
        T.CONSTRUCTty {tyCon = {id, ...}, args} => id
      | _ => raise TyConId

  fun coerceKind 
        (
         kind1 as
         {
          utvarOpt = utvarOpt1,
          eqKind = eqKind1,
          lambdaDepth = lambdaDepth1,
          tvarKind = tvarKind1,
          occurresIn = occurresIn1,
          id = id1
         } : T.tvKind,
         kind2 as
         {
          utvarOpt = utvarOpt2,
          eqKind = eqKind2,
          lambdaDepth = lambdaDepth2,
          tvarKind = tvarKind2,
          occurresIn = occurresIn2,
          id = id2
         } : T.tvKind
        ) : T.tvKind * (T.ty * T.ty) list =
    let
      val utvarOpt = utvarOpt2
      val eqKind = 
          case (eqKind1, eqKind2) of
            (A.EQ, A.NONEQ) => raise Unify
          | _ => eqKind2
      val lambdaDepth = 
          case Int.compare (lambdaDepth1, lambdaDepth2) of
            LESS => 
            (
             TB.adjustDepthInTvarKind lambdaDepth1 tvarKind2;
             lambdaDepth1
            )
          | GREATER =>
            (
             TB.adjustDepthInTvarKind lambdaDepth2 tvarKind1;
             lambdaDepth2
            )
          | EQUAL => lambdaDepth1
      val (tvarKind, newTyEquations) =
          case (tvarKind1, tvarKind2) of
            (T.REC fl1, T.REC fl2) =>
            let 
              val newTyEquations = 
                  LabelEnv.foldli
                    (fn (label, ty, newTyEquations) =>
                        case LabelEnv.find(fl2, label) of
                          NONE => raise Unify
                        | SOME ty' => (ty, ty')::newTyEquations)
                    nil
                    fl1
            in (T.REC fl2, newTyEquations)
            end
          | (T.UNIV, _) => (tvarKind2, nil)
          | _ => raise Unify
    in
      (
       {
        utvarOpt = utvarOpt,
        eqKind = eqKind,
        lambdaDepth = lambdaDepth,
        tvarKind = tvarKind,
        occurresIn = occurresIn1 @ occurresIn2,
        id = id2
       },
       newTyEquations)
    end
  fun checkKind 
        ty 
        ({utvarOpt,eqKind,lambdaDepth,occurresIn, tvarKind,id}: T.tvKind) =
      let
        val _ = 
            case utvarOpt of NONE => () | SOME _ => raise Unify
        val _ =
            (case eqKind of A.EQ => CheckEq.checkEq ty | _ => ())
            handle CheckEq.Eqcheck => raise Unify
        val _ = TB.adjustDepthInTy lambdaDepth ty
        val newTyEquations = 
            case tvarKind of
              T.REC kindFields =>
              (case ty of 
                 T.RECORDty tyFields =>
                 LabelEnv.foldri
                   (fn (l, ty, tyEquations) =>
                       (
                        ty, 
                        case LabelEnv.find(tyFields, l) of
                          SOME ty' => ty'
                        | NONE => raise Unify
                       ) :: tyEquations)
                   nil
                   kindFields
               | T.TYVARty _ => raise bug "checkKind"
               | _ => raise Unify)
            | T.OCONSTkind L =>
              (case List.filter
                      (fn x => TypID.eq(tyConId x, tyConId ty)
                               handle TyConId => raise Unify
                      )
                      L of
                 [ty1] => [(ty,ty1)]
               | _ => raise Unify)
            | T.OPRIMkind {instances, operators} => 
              (case List.filter
                      (fn x => TypID.eq(tyConId x, tyConId ty)
                               handle TyConId => raise Unify
                      )
                      instances
                of
                 [ty1] => [(ty,ty1)]
               | _ => raise Unify)
            | T.UNIV => nil
            | T.JOIN _ =>  raise Unify
      in
        newTyEquations
      end
        
  and lubKind 
        (
         kind1 as
         {
          utvarOpt = utvarOpt1,
          eqKind = eqKind1,
          lambdaDepth = lambdaDepth1,
          tvarKind = tvarKind1,
          occurresIn = occurresIn1,
          id = id1
         } : T.tvKind,
         kind2 as
         {
          utvarOpt = utvarOpt2,
          eqKind = eqKind2,
          lambdaDepth = lambdaDepth2,
          occurresIn = occurresIn2,
          tvarKind = tvarKind2,
          id = id2
         } : T.tvKind
        ) : T.tvKind * (T.ty * T.ty) list =
      case (utvarOpt1, utvarOpt2) of
        (SOME _, NONE) => coerceKind (kind2, kind1)
      | (NONE, SOME _) => coerceKind (kind1, kind2)
      | (SOME _, SOME _) => raise Unify
      | _ =>
      let 
        fun lubTyList(tyList1, tyList2) = 
            let
              fun find ty nil = NONE
                | find ty (ty'::tyList) = 
                  if TypID.eq(tyConId ty,tyConId ty')
                     handle TyConId => raise bug "non rawty in oprim kind"
                  then
                    SOME ty' 
                  else find ty tyList
              val (tyList, newEqs) =
                  foldr
                  (fn (ty, (tyList,newEqs)) =>
                      case find ty tyList2 of
                        NONE => (tyList,newEqs)
                      | SOME ty' => (ty::tyList,(ty,ty') :: newEqs)
                  )
                  (nil,nil)
                  tyList1
            in
              case tyList of nil => raise Unify
                           | _ => (tyList, newEqs)
            end
        val utvarOpt = NONE
        val (eqKind, tvarKind1, tvarKind2) =
            (case (eqKind1, eqKind2) of
               (A.NONEQ, A.NONEQ) => (A.NONEQ, tvarKind1, tvarKind2)
             | (A.EQ, A.EQ) => (A.EQ, tvarKind1, tvarKind2)
             | (A.NONEQ, A.EQ) =>
               (A.EQ, TU.coerceTvarkindToEQ tvarKind1, tvarKind2)
             | (A.EQ, A.NONEQ) =>
               (A.EQ, tvarKind1, TU.coerceTvarkindToEQ tvarKind2)
            )
            handle TU.CoerceTvarKindToEQ => raise Unify
        val lambdaDepth = 
            case Int.compare (lambdaDepth1, lambdaDepth2) of
                LESS => 
                (
                 TB.adjustDepthInTvarKind lambdaDepth1 tvarKind2;
                 lambdaDepth1
                )
              | GREATER =>
                (
                 TB.adjustDepthInTvarKind lambdaDepth2 tvarKind1;
                 lambdaDepth2
                )
              | EQUAL => lambdaDepth1
        val (newTvarKind, newTyEquations) = 
            case (tvarKind1, tvarKind2) of
              (T.REC fl1, T.REC fl2) =>
              let 
                val newTyEquations = 
                    LabelEnv.listItems
                      (LabelEnv.intersectWith (fn x => x) (fl1, fl2))
                val newTyFields = LabelEnv.unionWith #1 (fl1, fl2)
              in (T.REC newTyFields, newTyEquations)
              end
            | (T.REC fl1, T.JOIN (fl2, ty1, ty2, loc)) =>
              let 
                val newTyEquations = 
                    LabelEnv.listItems
                      (LabelEnv.intersectWith (fn x => x) (fl1, fl2))
                val newTyFields = LabelEnv.unionWith #1 (fl1, fl2)
              in (T.JOIN (newTyFields, ty1, ty2, loc), newTyEquations)
              end
            | (T.JOIN (fl1, ty1, ty2, loc), T.REC fl2) =>
              let 
                val newTyEquations = 
                    LabelEnv.listItems
                      (LabelEnv.intersectWith (fn x => x) (fl1, fl2))
                val newTyFields = LabelEnv.unionWith #1 (fl1, fl2)
              in (T.JOIN (newTyFields, ty1, ty2, loc), newTyEquations)
              end
            | (T.OCONSTkind L1, T.OCONSTkind L2) => 
              let
                val (tyList, newEqs) = lubTyList(L1,L2)
              in
                (T.OCONSTkind tyList, newEqs)
              end
            | (T.OCONSTkind L1,
               T.OPRIMkind {instances, operators}) => 
              let
                val (tyList, newEqs) = lubTyList(L1,instances)
              in
                (T.OCONSTkind tyList, newEqs)
              end
            | (T.OPRIMkind {instances, operators},
               T.OCONSTkind L2) => 
              let
                val (tyList, newEqs) = lubTyList(instances, L2)
              in
                (T.OCONSTkind tyList, newEqs)
              end
            | (
               T.OPRIMkind {instances = I1, operators = O1},
               T.OPRIMkind {instances = I2, operators = O2}
              ) =>
              let
                fun find (op1:T.oprimSelector) (nil:T.oprimSelector list)=NONE
                  | find  op1 (op2::opList) =
                    if OPrimID.eq(#oprimId op1, #oprimId op2) then
                      SOME op2
                    else find op1 opList
                (* we do not and should not generate equations from 
                   (O1,O2) 
                 *)
                val O2 =
                    foldr
                    (fn (op2, O2) =>
                        let
                          val op1Opt = find op2 O1
                        in
                          case op1Opt of
                            SOME _ => O2
                          | NONE => op2::O2
                        end
                    )
                    nil
                    O2
                val (I,newEqs) = lubTyList(I1,I2)
              in
                case I of 
                  nil => raise Unify
                | _ => 
                  (T.OPRIMkind
                     {
                      instances = I,
                      operators = O1@O2
                     },
                   newEqs)
              end
            | (T.UNIV, x) => (x,nil)
            | (x, T.UNIV) => (x,nil)
            | _ => raise Unify
      in 
        (
         {
          lambdaDepth = lambdaDepth,
          tvarKind = newTvarKind, 
          eqKind = eqKind, 
          utvarOpt = utvarOpt,
          occurresIn = occurresIn1 @ occurresIn2,
          id = id1
         },
         newTyEquations
        )
      end

  (**
   * The mysterious control flag "calledFromPatternUnify" should be
   * eiminated in future.
   *)
  and unifyTypeEquations calledFromPatternUnify L =
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
            | (T.ERRORty, _) => unifyTy tail
            | (_, T.ERRORty) => unifyTy tail
            | (T.DUMMYty n2, T.DUMMYty n1) =>
              if n1 = n2 then unifyTy tail else raise Unify
            | (T.DUMMYty _,
               T.TYVARty (ref(T.TVAR
                                {
                                 lambdaDepth,
                                 id,
                                 tvarKind = T.UNIV,
                                 eqKind=A.NONEQ,
                                 occurresIn,
                                 utvarOpt = NONE
                                }
                              ))
              ) => 
              (
               TB.performSubst(ty2, ty1); 
               unifyTy tail
              )
            | (T.TYVARty (ref(T.TVAR
                                {
                                 lambdaDepth,
                                 id,
                                 tvarKind = T.UNIV,
                                 eqKind=Absyn.NONEQ,
                                 occurresIn,
                                 utvarOpt = NONE
                                }
                              )),
               T.DUMMYty _
              ) => 
              (
               TB.performSubst(ty1, ty2); 
               unifyTy tail
              )
            | (T.DUMMYty _, _) => raise Unify
            | (_, T.DUMMYty _) => raise Unify

           (* type variables *)
(*
            | (
               T.TYVARty(tvState1 as ref(T.TVAR {utvarOpt = SOME _,
                                                 eqKind = eqkind1,
                                                 tvarKind= T.UNIV,
                                                 lambdaDepth=depth1,
                                             ...})),
               T.TYVARty(tvState2 as ref(T.TVAR {utvarOpt = NONE,
                                                 eqKind = eqkind2,
                                                 tvarKind= T.UNIV,
                                                 lambdaDepth=depth2,
                                             ...}))
              ) =>
              let
                val _ =
                    case (eqkind1, eqkind2) of
                      (A.NONEQ, A.EQ) => raise Unify
                    | _ => ()
(*
                val _ = 
                    if T.strictlyYoungerDepth
                         {tyvarDepth=depth1, contextDepth=depth2}
                    then () else raise Unify
*)
              in
                (
                 TB.adjustDepthInTy depth1 ty1;
                 TB.performSubst(ty2, ty1); 
                 unifyTy  tail
                )
              end
            | (
               T.TYVARty(tvState1 as ref(T.TVAR {utvarOpt = NONE,
                                                 eqKind = eqkind1,
                                                 tvarKind= T.UNIV,
                                                 lambdaDepth=depth1,
                                                 ...})),
               T.TYVARty(tvState2 as ref(T.TVAR {utvarOpt = SOME _,
                                                 eqKind = eqkind2,
                                                 tvarKind= T.UNIV,
                                                 lambdaDepth=depth2,
                                                 ...}))
              ) =>
              let
                val _ =
                    case (eqkind1, eqkind2) of
                      (A.EQ, A.NONEQ) => raise Unify
                    | _ => ()
(*
                val _ = 
                    if T.strictlyYoungerDepth {tyvarDepth=depth2,
                                               contextDepth=depth1}
                    then () else raise Unify
*)
              in
                (
                 TB.adjustDepthInTy depth1 ty2;
                 TB.performSubst(ty1, ty2); 
                 unifyTy tail
                )
              end
*)
            | (
               T.TYVARty (tvState1 as (ref(T.TVAR tvKind1))),
               T.TYVARty (tvState2 as (ref(T.TVAR tvKind2)))
              ) => 
              if FreeTypeVarID.eq(#id tvKind1, #id tvKind2) then unifyTy tail
              else if occurres tvState1 ty2 orelse occurres tvState2 ty1 
              then raise Unify
              else 
                let 
                  val (newKind, newTyEquations) = lubKind (tvKind1, tvKind2)
                  val newTy = T.newtyRaw {utvarOpt = #utvarOpt newKind,
                                          lambdaDepth = #lambdaDepth newKind,
                                          tvarKind = #tvarKind newKind,
                                          occurresIn = #occurresIn newKind,
                                          eqKind = #eqKind newKind}
                in
                  unifyTy newTyEquations;
                  TB.performSubst(ty1, newTy);
                  TB.performSubst(ty2, newTy);
                  unifyTy tail
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
                  val _ = unifyTy newTyEquations
                in
                  (
                   TB.performSubst(ty1, ty2); 
                   unifyTy tail
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
                  val _ = unifyTy newTyEquations
                in
                  (
                   TB.performSubst(ty2, ty1); 
                   unifyTy tail
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
               T.CONSTRUCTty {tyCon = {id = id1,...}, args = tyList1},
               T.CONSTRUCTty {tyCon = {id = id2,...}, args = tyList2}
              ) =>
              let
                val omit = calledFromPatternUnify orelse TypID.eq(id1, id2)
              in
                if omit andalso length tyList1 = length tyList2
                then unifyTy  (ListPair.zip (tyList1, tyList2) @ tail)
                else raise Unify
              end
            | (T.RECORDty tyFields1, T.RECORDty tyFields2) =>
              let
                val (newTyEquations, rest) = 
                    LabelEnv.foldri 
                      (fn (label, ty1, (newTyEquations, rest)) =>
                          let val (rest, ty2) = LabelEnv.remove(rest, label)
                          in ((ty1, ty2) :: newTyEquations, rest) end
                          handle LibBase.NotFound => raise Unify)
                      (nil, tyFields2)
                      tyFields1
              in
                if LabelEnv.isEmpty rest 
                then unifyTy (newTyEquations@tail)
                else raise Unify
              end
            | (T.SINGLETONty _, T.SINGLETONty _) =>
              raise bug "unifyTy: SINGLETONty occurs"
            (* this case is added for EXPORTFUNCTOR check;
               this should not cause any problems in the 
               standard monotype unify *)
            | (T.BOUNDVARty id1,T.BOUNDVARty id2) =>
              if BoundTypeVarID.eq(id1, id2) then unifyTy tail
              else raise Unify
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

  exception NONEQ
  fun eqTy btvEquiv (ty1, ty2) = 
      let
        val ty1 = TB.derefTy ty1
        val ty2 = TB.derefTy ty2
        fun btvEq (id1, id2) = 
            BoundTypeVarID.eq(id1, id2) orelse 
            (case BoundTypeVarID.Map.find(btvEquiv, id1) of
               SOME id11 => BoundTypeVarID.eq(id11, id2)
             | NONE => 
               (case BoundTypeVarID.Map.find(btvEquiv, id2) of
                  SOME id21 => BoundTypeVarID.eq(id1, id21)
                | NONE => false))
        fun eq (ty1, ty2) = eqTy btvEquiv (ty1, ty2)
        fun eqList (tyL1, tyL2) = eqTyList btvEquiv (tyL1, tyL2)
      in
        case (ty1, ty2) of
          (T.BOUNDVARty bid1, T.BOUNDVARty bid2) => btvEq(bid1, bid2)
        | (T.SINGLETONty sty1, T.SINGLETONty sty2) =>
          eqSTy btvEquiv (sty1, sty2)
        | (T.POLYty {boundtvars=btv1, body=body1},
           T.POLYty {boundtvars=btv2, body=body2}) =>
          (let
             val idkindPairs1 = BoundTypeVarID.Map.listItemsi btv1
             val idkindPairs2 = BoundTypeVarID.Map.listItemsi btv2
             val _= if length idkindPairs1 = length idkindPairs2 
                    then () else raise NONEQ
             val kindPairs = ListPair.zip(idkindPairs1,idkindPairs2)
             val btvMap =
                 foldl
                   (fn (((i1,_),(i2,_)), btvMap) =>
                       BoundTypeVarID.Map.insert(btvMap, i1, i2)
                   )
(*  2012-8-11 ohori
                   BoundTypeVarID.Map.empty
*)
                   btvEquiv
                   kindPairs
             val _ = 
                 app (fn ((_,kind1), (_,kind2)) =>
                         if eqKind btvMap (kind1, kind2) then ()
                         else raise NONEQ)
                     kindPairs
           in
             eqTy btvMap (body1, body2)
           end
           handle NONEQ => false
          )
        | (T.FUNMty (tyList1, ty1),T.FUNMty (tyList2, ty2))  =>
          (eqTyList btvEquiv (tyList1, tyList2) andalso eq(ty1, ty2)
           handle NONEQ => false)
        | (T.RECORDty tyMap1,T.RECORDty tyMap2)  =>
          eqSMap btvEquiv (tyMap1, tyMap2)
        | (T.CONSTRUCTty {tyCon=tyCon1,args=args1},
           T.CONSTRUCTty {tyCon=tyCon2,args=args2}) =>
          TypID.eq(#id tyCon1, #id tyCon2) andalso
          eqTyList btvEquiv (args1, args2)
        | (T.ERRORty, _) => true
        | (_, T.ERRORty) => true
        | (T.DUMMYty _, _) => (unify [(ty1, ty2)]; true)
        | (_, T.DUMMYty _) => (unify [(ty1, ty2)]; true)
        | (T.TYVARty tv1, _) => (unify [(ty1, ty2)]; true)
        | (_, T.TYVARty tv1) => (unify [(ty1, ty2)]; true)
        | _ => false
      end
      handle Unify => false
  and eqSMap btvEquiv (smap1, smap2) =
      let
        val tyF1 = LabelEnv.listItemsi smap1
        val tyF2 = LabelEnv.listItemsi smap2
      in
        eqTyFields btvEquiv (tyF1, tyF2)
      end
  and eqTyFields btvEquiv (nil, nil) = true
    | eqTyFields btvEquiv ((l1,ty1)::tl1, (l2,ty2)::tl2) = 
      (case String.compare(l1,l2) of
         EQUAL => eqTy btvEquiv (ty1, ty2) andalso eqTyFields btvEquiv (tl1, tl2)
       | _ => false)
    | eqTyFields btvEquiv (h1::t1, nil) = false
    | eqTyFields btvEquiv (nil, h2::t2) =  false
  and eqTyList btvEquiv (tyList1, tyList2) = 
      length tyList1 = length tyList2 andalso
      let
        val tyPairs = ListPair.zip(tyList1, tyList2)
      in
        (app 
           (fn (ty1, ty2) =>
               if eqTy btvEquiv (ty1, ty2) then () else raise NONEQ
           )
           tyPairs;
         true
        )
        handle NONEQ => false
      end
  and eqSTy btvEquiv (sty1, sty2) =
      case (sty1, sty2) of
      (T.INSTCODEty oprimSelector11,T.INSTCODEty oprimSelector2) =>
      eqOprimSelector btvEquiv (oprimSelector11,oprimSelector2)
    | (T.INDEXty (string1, ty1),T.INDEXty (string2, ty2)) =>
      string1 = string2 andalso eqTy btvEquiv (ty1, ty2)
    | (T.TAGty ty1, T.TAGty ty2) => eqTy btvEquiv (ty1, ty2)
    | (T.SIZEty ty1, T.SIZEty ty2) => eqTy btvEquiv (ty1, ty2)
    | _ => false
  and eqOprimSelector
        btvEquiv 
        ({oprimId=id1,longsymbol=longsymbol1,keyTyList=ktyL1,match=m1,instMap=IM1},
         {oprimId=id2,longsymbol=longsymbol2,keyTyList=ktyL2,match=m2,instMap=IM2})
      =
      OPrimID.eq(id1,id2) andalso
      Symbol.eqLongsymbol(longsymbol1, longsymbol2) andalso
      eqTyList btvEquiv (ktyL1, ktyL2)
  and eqOprimSelectorList btvEquiv (opList1, opList2) =
      length opList1 = length opList2 andalso
      let
        val opPairs = ListPair.zip (opList1, opList2)
      in
        (app
           (fn x => if eqOprimSelector btvEquiv x then () else raise NONEQ)
           opPairs;
         true)
        handle NONEQ => false
      end
  and eqKind btvEquiv ({eqKind=eqK1, tvarKind=tvK1},
                       {eqKind=eqK2, tvarKind=tvK2}) =
      (case (eqK1, eqK2) of
         (Absyn.EQ, Absyn.EQ) => true
       | (Absyn.NONEQ, Absyn.NONEQ) => true
       | _ => false) andalso
      eqTvarKind btvEquiv (tvK1, tvK2)
  and eqTvarKind btvEquiv (tvK1, tvK2) =
      case (tvK1, tvK2) of
      (T.OCONSTkind tyL1,T.OCONSTkind tyL2) => eqTyList btvEquiv (tyL1, tyL2)
    | (T.OPRIMkind {instances = tyL1, operators = opL1},
       T.OPRIMkind {instances = tyL2, operators = opL2})
       =>
       eqTyList btvEquiv (tyL1, tyL2) andalso
       eqOprimSelectorList btvEquiv (opL1, opL2)
    | (T.UNIV, T.UNIV) => true
    | (T.REC smap1, T.REC smap2) => eqSMap btvEquiv (smap1, smap2)
    | _ => false

  fun instOfPolyTy (polyTy, tyList) =
      case TB.derefTy polyTy of
        T.POLYty {boundtvars, body} =>
        let 
          val subst1 = TB.freshSubst boundtvars
          val body = TB.substBTvar subst1 body
          val instTyList = BoundTypeVarID.Map.listItems subst1
          val tyPairs = 
              if length tyList = length instTyList then 
                ListPair.zip (instTyList, tyList)
              else raise bug "arity mismatch in instOfPoly"
          val _ = unify tyPairs
        in
          body
        end
      | _ => 
        raise bug "nonpolyty in TFUNDEF in instOfPoly"

end
end
