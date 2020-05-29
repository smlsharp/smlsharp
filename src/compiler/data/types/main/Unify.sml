(**
 * a kinded unification for ML, an imperative version.
 * @copyright (c) 2006-2010, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 *)
structure Unify =
struct
local
  structure T = Types
  structure TB = TypesBasics
  structure TU = TypesUtils
(*
  structure U = UserLevelPrimitive
*)
  structure DK = DynamicKind
in
  exception Unify
  exception EqRawTy

  fun printTy ty = TyPrinters.printTy ty
  fun raiseUnify id =
      (Bug.printError ("UnifyFail: " ^ Int.toString id ^ "\n");
       raise Unify)

  fun bug s = Bug.Bug ("Unify:" ^ s)

  fun occurres tvarRef ty = 
      let
        val (_, set, _) = TB.EFTV (ty, nil)
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

  fun coerceReify ty = 
      case TB.derefTy ty of
        T.SINGLETONty _ => ()
      | T.BACKENDty _ => ()
      | T.ERRORty => ()
      | T.DUMMYty _ => ()
      | T.EXISTty _ => ()
      | T.TYVARty 
          (r as 
             ref 
             (T.TVAR 
                (tvarRecord 
                   as 
                   {kind = T.KIND (kindRecord
                                     as {properties,...}),
                    utvarOpt = NONE,
                    ...}
                )
             )
          )
        => 
        let
          val properties = T.addProperties T.REIFY properties
          val kindRecord = kindRecord # {properties = properties}
          val tvarRecord = tvarRecord # {kind = T.KIND kindRecord}
        in
          r := T.TVAR tvarRecord
        end
      | T.TYVARty 
          (r as 
             ref 
             (T.TVAR 
                (tvarRecord 
                   as 
                   {kind = T.KIND (kindRecord
                                     as {properties,...}),
                    utvarOpt = SOME x,
                    ...}
                )
             )
          )
        => raiseUnify 9999
      | T.TYVARty _ => ()
      | T.BOUNDVARty _ => ()
      | T.FUNMty (tyList,ty) =>
        (app coerceReify tyList; coerceReify ty)
      | T.RECORDty tyMap => 
        RecordLabel.Map.app coerceReify tyMap
      | T.CONSTRUCTty{tyCon,args} =>
        app coerceReify args        
      | T.POLYty polyTy => ()

  fun isUNIVtvKind
        ({utvarOpt = NONE,
          kind = T.KIND {properties,
                         tvarKind = T.UNIV,
                         dynamicKind = NONE},
          lambdaDepth, id} : T.tvKind) =
      T.equalProperties properties T.emptyProperties
    | isUNIVtvKind _ = false

  fun checkKind 
        ty
        ({utvarOpt,kind as T.KIND {properties,tvarKind, dynamicKind},lambdaDepth,id}: T.tvKind) =
      let
        val _ = case dynamicKind of
                  NONE => ()
                | _ => raise Bug.Bug "checkKind: dynanicKind must not be set"
        val {tag, ...} = DynamicKindUtils.kindOfTy ty
        val _ = case utvarOpt of NONE => () | SOME _ => raiseUnify 3
        val _ = if T.isProperties T.EQ properties then
                  CheckEq.checkEq ty handle CheckEq.Eqcheck => raiseUnify 4
                else ()
        val _ = if T.isProperties T.BOXED properties andalso tag <> DK.TAG DK.BOXED then raiseUnify 1 else ()
        val _ = if T.isProperties T.UNBOXED properties andalso tag <> DK.TAG DK.UNBOXED then raiseUnify 1 else ()
        val _ = if T.isProperties T.REIFY properties then coerceReify ty else ()
        val _ = TB.adjustDepthInTy (ref false) lambdaDepth ty
        val newTyEquations = 
            case tvarKind of
              T.REC kindFields =>
              (case ty of 
                 T.RECORDty tyFields =>
                 RecordLabel.Map.foldri
                   (fn (l, ty, tyEquations) =>
                       (
                        ty, 
                        case RecordLabel.Map.find(tyFields, l) of
                          SOME ty' => ty'
                        | NONE => raiseUnify 6
                       ) :: tyEquations)
                   nil
                   kindFields
               | T.TYVARty _ => raise bug "checkKind"
               | _ => raiseUnify 7)
            | T.OCONSTkind L =>
              (case List.filter
                      (fn x => TypID.eq(tyConId x, tyConId ty)
                               handle TyConId => raiseUnify 8)
                      L 
                of [ty1] => [(ty,ty1)]
                 | _ => raiseUnify 9)
            | T.OPRIMkind {instances, operators} => 
              (case List.filter
                      (fn x => TypID.eq(tyConId x, tyConId ty)
                               handle TyConId => raiseUnify 10)
                      instances
                of [ty1] => [(ty,ty1)]
                 | _ => raiseUnify 11)
            | T.UNIV => nil
      in
        newTyEquations
      end
(*
      handle U.IDNotFound name =>
             raise bug ("userlevel primitive error handling (checkKind):" ^ name)
*)
        
  fun coerceKind 
     {from = {utvarOpt = utvarOpt1,
              kind = T.KIND {tvarKind = tvarKind1,
                             properties = properties1,
                             dynamicKind = dynamicKind1
                            },
              lambdaDepth = lambdaDepth1, 
              id = id1} : T.tvKind,
      to = {utvarOpt = utvarOpt2,
            kind = T.KIND {tvarKind = tvarKind2,
                           properties = properties2,
                           dynamicKind = dynamicKind2
                          },
            lambdaDepth = lambdaDepth2,
            id = id2} : T.tvKind
     } : T.tvKind * (T.ty * T.ty) list =
    let
      val _ = case (dynamicKind1, dynamicKind2) of
                (NONE, NONE) => ()
              | _ => raise Bug.Bug "coerceKind: dynanicKind must not be set"

(*
      (* experimental for ICFP 2020 *)
      val properties2 = if T.isProperties T.REIFY properties1 then
                          T.addProperties T.REIFY properties2
                        else properties2
*)
      val properties = if T.isSubProperties properties1 properties2 then properties2 
                       else raiseUnify 181 
      val lambdaDepth = 
          case Int.compare (lambdaDepth1, lambdaDepth2) of
            LESS => 
            (
             TB.adjustDepthInTvarKind (ref false) lambdaDepth1 tvarKind2;
             lambdaDepth1
            )
          | GREATER =>
            (
             TB.adjustDepthInTvarKind (ref false) lambdaDepth2 tvarKind1;
             lambdaDepth2
            )
          | EQUAL => lambdaDepth1
      val utvarOpt = utvarOpt2
      val (tvarKind, newTyEquations) =
          case (tvarKind1, tvarKind2) of
            (T.REC fl1, T.REC fl2) =>
            let 
              val newTyEquations = 
                  RecordLabel.Map.foldli
                    (fn (label, ty, newTyEquations) =>
                        case RecordLabel.Map.find(fl2, label) of
                          NONE => raiseUnify 21
                        | SOME ty' => (ty, ty')::newTyEquations)
                    nil
                    fl1
            in (T.REC fl2, newTyEquations)
            end
          | (T.UNIV, _) => (tvarKind2, nil)
          | _ => raiseUnify 22
    in
      (
       {
        utvarOpt = utvarOpt,
        kind = T.KIND {properties = properties,
                       tvarKind = tvarKind,
                       dynamicKind = NONE
                      },
        lambdaDepth = lambdaDepth,
        id = id2
       },
       newTyEquations)
    end

  and lubKind  
        (kind1 as
         {utvarOpt = utvarOpt1,
          kind = T.KIND {properties = properties1,
                         tvarKind = tvarKind1,
                         dynamicKind = dynamicKind1
                        },
          lambdaDepth = lambdaDepth1,
          id = id1} : T.tvKind,
         kind2 as
         {utvarOpt = utvarOpt2,
          kind = T.KIND {properties = properties2,
                         tvarKind = tvarKind2,
                         dynamicKind = dynamicKind2
                        },
          lambdaDepth = lambdaDepth2,
          id = id2} : T.tvKind
        ) : T.tvKind * (T.ty * T.ty) list =
      case (utvarOpt1, utvarOpt2) of
        (SOME _, NONE) => coerceKind {from = kind2, to = kind1}
      | (NONE, SOME _) => coerceKind {from = kind1, to = kind2}
      | (SOME _, SOME _) => raiseUnify 23
      | _ =>
      let 
        val _ = case (dynamicKind1, dynamicKind2) of
                  (NONE, NONE) => ()
                | _ => raise Bug.Bug "lubKind: dynanicKind must not be set"

        val utvarOpt = NONE
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
              case tyList of nil => raiseUnify 24
                           | _ => (tyList, newEqs)
            end

        val (tvarKind1, tvarKind2) =
            (if T.isProperties T.EQ properties1 then
              if not (T.isProperties T.EQ properties2) then
                (tvarKind1, TU.coerceTvarKindToProp T.EQ tvarKind2)
              else (tvarKind1,tvarKind2)
            else if T.isProperties T.EQ properties2 then
              (TU.coerceTvarKindToProp T.EQ tvarKind1, tvarKind2)
            else (tvarKind1, tvarKind2))
            handle TU.CoerceTvarKindToProp => raiseUnify 25

        val (tvarKind1, tvarKind2) =
            (if T.isProperties T.BOXED properties1 then
              if not (T.isProperties T.BOXED properties2) then
                (tvarKind1, TU.coerceTvarKindToProp T.BOXED tvarKind2)
              else (tvarKind1,tvarKind2)
            else if T.isProperties T.BOXED properties2 then
              (TU.coerceTvarKindToProp T.BOXED tvarKind1, tvarKind2)
            else (tvarKind1, tvarKind2))
            handle TU.CoerceTvarKindToProp => raiseUnify 25

        val (tvarKind1, tvarKind2) =
            (if T.isProperties T.UNBOXED properties1 then
              if not (T.isProperties T.UNBOXED properties2) then
                (tvarKind1, TU.coerceTvarKindToProp T.UNBOXED tvarKind2)
              else (tvarKind1,tvarKind2)
            else if T.isProperties T.UNBOXED properties2 then
              (TU.coerceTvarKindToProp T.UNBOXED tvarKind1, tvarKind2)
            else (tvarKind1, tvarKind2))
            handle TU.CoerceTvarKindToProp => raiseUnify 25

        val properties = T.unionProperties properties1 properties2
        val lambdaDepth = 
            case Int.compare (lambdaDepth1, lambdaDepth2) of
                LESS => 
                (
                 TB.adjustDepthInTvarKind (ref false) lambdaDepth1 tvarKind2;
                 lambdaDepth1
                )
              | GREATER =>
                (
                 TB.adjustDepthInTvarKind (ref false) lambdaDepth2 tvarKind1;
                 lambdaDepth2
                )
              | EQUAL => lambdaDepth1

        val (newTvarKind, newTyEquations) =
            case (tvarKind1, tvarKind2) of
              (T.REC fl1, T.REC fl2) =>
              let 
                val newTyEquations = 
                    RecordLabel.Map.listItems
                      (RecordLabel.Map.intersectWith (fn x => x) (fl1, fl2))
                val newTyFields = RecordLabel.Map.unionWith #1 (fl1, fl2)
              in (T.REC newTyFields, newTyEquations)
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
                  nil => raiseUnify 27
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
            | _ => raiseUnify 36
        val (newTvarKind, newTyEquations2) =  (newTvarKind, nil)
      in 
        (
         {
          lambdaDepth = lambdaDepth,
          kind = T.KIND {tvarKind = newTvarKind, 
                         properties = properties,
                         dynamicKind = NONE
                        },
          utvarOpt = utvarOpt,
          id = id1
         },
         newTyEquations @ newTyEquations2
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
           (* Special types: SUBSTITUTED, ALIASty, ERRORty,
            * OPAQUEty, SPECty. These cases are all disjoint.
            *)
              (T.TYVARty (ref(T.SUBSTITUTED derefTy1)), _)
              => unifyTy ((derefTy1, ty2) :: tail)
            | (_, T.TYVARty (ref(T.SUBSTITUTED derefTy2)))
              => unifyTy ((ty1, derefTy2) :: tail)
            | (T.ERRORty, _) => unifyTy tail
            | (_, T.ERRORty) => unifyTy tail

            (* these cases for BOUNDVARty are added for EXPORTFUNCTOR check;
               this should not cause any problems in the
               standard monotype unify *)
            (* 2020-5-20 362_functor.sml対応で、以下のケースを追加; 明らかな抜け？ *)
            | (T.BOUNDVARty btv1, T.BOUNDVARty btv2) => 
              if  BoundTypeVarID.eq(btv1, btv2) then unifyTy tail
              else raiseUnify 60
            | (T.TYVARty (tvState as ref (T.TVAR tvKind)), T.BOUNDVARty _) =>
              unifyTy ((ty2, ty1) :: tail)
            | (T.BOUNDVARty _, T.TYVARty (tvState as ref (T.TVAR tvKind))) =>
              if isUNIVtvKind tvKind
              then (tvState := T.SUBSTITUTED ty1; unifyTy tail)
              else raiseUnify 54
            | (T.BOUNDVARty _, _) => raiseUnify 53
            | (_, T.BOUNDVARty _) => raiseUnify 53

            (* these cases for POLYty are added for rank-1 polymorphic type
             * inference. *)
            | (T.TYVARty (tvState as ref (T.TVAR tvKind)), T.POLYty _) =>
              unifyTy ((ty2, ty1) :: tail)
            | (T.POLYty _, T.TYVARty (tvState as ref (T.TVAR tvKind))) =>
              if isUNIVtvKind tvKind
              then (tvState := T.SUBSTITUTED ty1; unifyTy tail)
              else raiseUnify 54
            | (T.POLYty _, _) => raiseUnify 54
            | (_, T.POLYty _) => raiseUnify 54

           (* type variables *)
            | (
               T.TYVARty (tvState1 as (ref(T.TVAR tvKind1))),
               T.TYVARty (tvState2 as (ref(T.TVAR tvKind2)))
              ) => 
              if FreeTypeVarID.eq(#id tvKind1, #id tvKind2) then unifyTy tail
              else if occurres tvState1 ty2 orelse occurres tvState2 ty1 
              then raiseUnify 46
              else 
                let 
                  val (newKind, newTyEquations) = lubKind (tvKind1, tvKind2)
                  val newTy = T.newtyRaw {utvarOpt = #utvarOpt newKind,
                                          lambdaDepth = #lambdaDepth newKind,
                                          kind = #kind newKind}
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
              then raiseUnify 47
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
              then raiseUnify 48
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
              else raiseUnify 49
            | (
               T.CONSTRUCTty {tyCon = {id = id1,...}, args = tyList1},
               T.CONSTRUCTty {tyCon = {id = id2,...}, args = tyList2}
              ) =>
              let
                val omit = calledFromPatternUnify orelse TypID.eq(id1, id2)
              in
                if omit andalso length tyList1 = length tyList2
                then unifyTy  (ListPair.zip (tyList1, tyList2) @ tail)
                else 
                  (
                   raiseUnify 50
                   )
              end
            | (T.RECORDty tyFields1, T.RECORDty tyFields2) =>
              let
                val (newTyEquations, rest) = 
                    RecordLabel.Map.foldri 
                      (fn (label, ty1, (newTyEquations, rest)) =>
                          let val (rest, ty2) = RecordLabel.Map.remove(rest, label)
                          in ((ty1, ty2) :: newTyEquations, rest) end
                          handle LibBase.NotFound => raiseUnify 51)
                      (nil, tyFields2)
                      tyFields1
              in
                if RecordLabel.Map.isEmpty rest 
                then unifyTy (newTyEquations@tail)
                else raiseUnify 52
              end
            | (T.SINGLETONty _, T.SINGLETONty _) =>
              raise bug "unifyTy: SINGLETONty occurs"
            | (T.DUMMYty (n1,k1), T.DUMMYty (n2,k2)) => 
              if n1 = n2 then unifyTy tail else raiseUnify 54 
            | (T.EXISTty (n1,k1), T.EXISTty (n2,k2)) =>
              if n1 = n2 then unifyTy tail else raiseUnify 54
            | (ty1, ty2) => raiseUnify 55
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

(*
  (**
   * type equality 
   *)
  fun tyEq (ty1, ty2) = 
      case (ty1, ty2) of
        (T.TYVARty (ref(T.SUBSTITUTED derefTy1)), _) => tyEq (derefTy1, ty2)
      | (_, T.TYVARty (ref(T.SUBSTITUTED derefTy2))) => tyEq (ty1, derefTy2)
      | (T.DUMMYty n2, T.DUMMYty n1) => n1 = n2
      | (T.TYVARty (ref(T.TVAR tvKind1)), T.TYVARty (ref(T.TVAR tvKind2)))
        => FreeTypeVarID.eq(#id tvKind1, #id tvKind2)
      | (T.FUNMty(domainTyList1, rangeTy1),T.FUNMty(domainTyList2, rangeTy2))
        =>
        length domainTyList1 = length domainTyList2 
        andalso
        List.all 
          tyEq 
          ((rangeTy1, rangeTy2) :: ListPair.zip (domainTyList1, domainTyList2))
      | (
         T.CONSTRUCTty {tyCon = {id = id1,...}, args = tyList1},
         T.CONSTRUCTty {tyCon = {id = id2,...}, args = tyList2}
        ) =>
        TypID.eq(id1, id2) andalso
        length tyList1 = length tyList2 andalso
        List.all 
          tyEq 
          (ListPair.zip (tyList1, tyList2))
      | (T.RECORDty tyFields1, T.RECORDty tyFields2) =>
        let
          val (newTyEquations, rest) = 
              RecordLabel.Map.foldri 
                (fn (label, ty1, (newTyEquations, rest)) =>
                    let val (rest, ty2) = RecordLabel.Map.remove(rest, label)
                    in ((ty1, ty2) :: newTyEquations, rest) end
                    handle LibBase.NotFound => raiseUnify 51)
                (nil, tyFields2)
                tyFields1
        in
          RecordLabel.Map.isEmpty rest  andalso
          List.all tyEq newTyEquations
        end
      | (T.BOUNDVARty id1,T.BOUNDVARty id2) =>
         BoundTypeVarID.eq(id1, id2)
      | _ => false
*)

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
        | (T.POLYty {boundtvars=btv1, constraints = constraints1, body=body1},
           T.POLYty {boundtvars=btv2, constraints = constraints2, body=body2}) =>
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
        | (T.DUMMYty (id1, _), T.DUMMYty (id2, _)) => id1 = id2
        | (T.DUMMYty _, _) => (unify [(ty1, ty2)]; true)
        | (_, T.DUMMYty _) => (unify [(ty1, ty2)]; true)
        | (T.EXISTty (id1, _), T.EXISTty (id2, _)) => id1 = id2
        | (T.EXISTty _, _) => (unify [(ty1, ty2)]; true)
        | (_, T.EXISTty _) => (unify [(ty1, ty2)]; true)
        | (T.TYVARty tv1, _) => (unify [(ty1, ty2)]; true)
        | (_, T.TYVARty tv1) => (unify [(ty1, ty2)]; true)
        | _ => false
      end
      handle Unify => false
  and eqSMap btvEquiv (smap1, smap2) =
      let
        val tyF1 = RecordLabel.Map.listItemsi smap1
        val tyF2 = RecordLabel.Map.listItemsi smap2
      in
        eqTyFields btvEquiv (tyF1, tyF2)
      end
  and eqTyFields btvEquiv (nil, nil) = true
    | eqTyFields btvEquiv ((l1,ty1)::tl1, (l2,ty2)::tl2) = 
      (case RecordLabel.compare(l1,l2) of
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
  and eqTyListOpt btvEquiv (NONE, NONE) = true
    | eqTyListOpt btvEquiv (NONE, SOME _) = false
    | eqTyListOpt btvEquiv (SOME _, NONE) = false
    | eqTyListOpt btvEquiv (SOME l1, SOME l2) = eqTyList btvEquiv (l1, l2)
  and eqSTy btvEquiv (sty1, sty2) =
      case (sty1, sty2) of
      (T.INSTCODEty oprimSelector11,T.INSTCODEty oprimSelector2) =>
      eqOprimSelector btvEquiv (oprimSelector11,oprimSelector2)
    | (T.INDEXty (label1, ty1),T.INDEXty (label2, ty2)) =>
      label1 = label2 andalso eqTy btvEquiv (ty1, ty2)
    | (T.TAGty ty1, T.TAGty ty2) => eqTy btvEquiv (ty1, ty2)
    | (T.SIZEty ty1, T.SIZEty ty2) => eqTy btvEquiv (ty1, ty2)
    | _ => false
  and eqOprimSelector
        btvEquiv 
        ({oprimId=id1,longsymbol=longsymbol1,match=m1},
         {oprimId=id2,longsymbol=longsymbol2,match=m2})
      =
      OPrimID.eq(id1,id2) andalso
      Symbol.eqLongsymbol(longsymbol1, longsymbol2) andalso
      eqOverloadMatch btvEquiv (m1, m2)
  and eqOverloadMatch btvEquiv (match1, match2) =
      case (match1, match2) of
        (T.OVERLOAD_CASE (ty1, matches1), T.OVERLOAD_CASE (ty2, matches2)) =>
        eqTy btvEquiv (ty1, ty2) andalso
        let
          exception NotEqual
        in
          (TypID.Map.app
             (fn (x,y) =>
                 if eqOverloadMatch btvEquiv (x, y) then () else raise NotEqual)
             (TypID.Map.mergeWith
                (fn (NONE, NONE) => NONE
                | (SOME _, NONE) => raise NotEqual
                | (NONE, SOME _) => raise NotEqual
                | (SOME x, SOME y) => SOME (x, y))
                (matches1, matches2));
           true)
          handle NotEqual => false
        end
      | (T.OVERLOAD_CASE _, _) => false
      | (T.OVERLOAD_EXVAR {exVarInfo={path=path1,...}, instTyList=i1},
         T.OVERLOAD_EXVAR {exVarInfo={path=path2,...}, instTyList=i2}) =>
        Symbol.eqLongsymbol (path1, path2) andalso eqTyListOpt btvEquiv (i1, i2)
      | (T.OVERLOAD_EXVAR _, _) => false
      | (T.OVERLOAD_PRIM {primInfo={primitive=p1,...}, instTyList=i1},
         T.OVERLOAD_PRIM {primInfo={primitive=p2,...}, instTyList=i2}) =>
        p1 = p2 andalso eqTyListOpt btvEquiv (i1, i2)
      | (T.OVERLOAD_PRIM _, _) => false
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
  and eqKind btvEquiv (T.KIND {properties = prop1, tvarKind=tvK1, dynamicKind = _},
                       T.KIND {properties = prop2, tvarKind=tvK2, dynamicKind = _}) =
      T.equalProperties prop1 prop2
      andalso
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
        T.POLYty {boundtvars, constraints, body} =>
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


  fun forceRevealTy ty =
      case TB.derefTy ty of
        T.SINGLETONty _ => raise bug "SINGLETONty in revealTy"
      | T.BACKENDty _ => raise bug "BACKENDty in revealTy"
      | T.ERRORty => ty
      | T.DUMMYty _ => ty
      | T.EXISTty _ => ty
      | T.TYVARty _ => ty
      | T.BOUNDVARty _ => ty
      | T.FUNMty (tyList,ty) =>
        T.FUNMty (map forceRevealTy tyList, forceRevealTy ty)
      | T.RECORDty tyMap => T.RECORDty (RecordLabel.Map.map forceRevealTy tyMap)
      | T.CONSTRUCTty
          {tyCon= tyCon as {dtyKind=T.OPAQUE{opaqueRep,revealKey},...},args} =>
        let
          val args = map  forceRevealTy args
        in
          case opaqueRep of
            T.TYCON tyCon =>
            T.CONSTRUCTty{tyCon=tyCon, args= args}
          | T.TFUNDEF {admitsEq, arity, polyTy} =>
            instOfPolyTy(polyTy, args)
        end
      | T.CONSTRUCTty{tyCon,args} =>
        T.CONSTRUCTty{tyCon=tyCon, args= map forceRevealTy args}
      | T.POLYty polyTy => ty (* polyty will not be unified *)


end
end
