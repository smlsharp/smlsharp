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
  structure U = UserLevelPrimitive
in
  exception Unify
  exception EqRawTy

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
                                
  fun isBoxedTy ty =
      case TypeLayout2.runtimeTy BoundTypeVarID.Map.empty ty of
        SOME RuntimeTypes.BOXEDty => true
      | SOME _ => false
      | NONE => raise bug "isBoxedTy"

  exception TyConId
  fun tyConId ty = 
      case TB.derefTy ty of
        T.CONSTRUCTty {tyCon = {id, ...}, args} => id
      | _ => raise TyConId

  fun newtySubkind subkind =
      T.newty {utvarOpt = NONE,
               kind = T.KIND {tvarKind = T.UNIV,
                              dynKind = false,
                              reifyKind = false,
                              subkind = subkind,
                              eqKind = T.NONEQ}}

  fun checkSubkind ty subkind =
      case subkind of
        T.ANY => nil
      | T.UNBOXED => if isBoxedTy ty then raiseUnify 2 else nil
      | T.JSON_ATOMIC =>
        (case TB.derefTy ty of
           T.CONSTRUCTty {tyCon = {id, ...}, args=[]} =>
           if id = #id BuiltinTypes.intTyCon
              orelse id = #id BuiltinTypes.realTyCon
              orelse id = #id BuiltinTypes.stringTyCon
              orelse id = #id BuiltinTypes.boolTyCon
           then nil
           else raiseUnify 12
         | T.TYVARty _ =>
           [(ty, newtySubkind subkind)]
         | _ => raiseUnify 12
        )
      | T.JSON =>
        (case TB.derefTy ty of
           T.CONSTRUCTty {tyCon = {id, ...}, args=[]} =>
           if id = #id BuiltinTypes.intTyCon
              orelse id = #id BuiltinTypes.realTyCon
              orelse id = #id BuiltinTypes.stringTyCon
              orelse id = #id BuiltinTypes.boolTyCon
              orelse id = #id (U.JSON_void_tyCon ())
           then nil
           else raiseUnify 14
         | T.CONSTRUCTty {tyCon = {id, ...}, args=[argTy]} =>
           if id = #id BuiltinTypes.listTyCon
           then [(argTy, newtySubkind subkind)]
           else if id = #id BuiltinTypes.optionTyCon
           then [(argTy, newtySubkind subkind)]
           else if id = #id (U.JSON_dyn_tyCon ())
           then [(argTy, newtySubkind subkind)]
(*
                   case TB.derefTy argTy of
                     T.RECORDty fields =>
                     [(argTy, T.newtyRaw {utvarOpt = utvarOpt,
                                          lambdaDepth = lambdaDepth,
                                          tvarKind = tvarKind,
                                          dynKind = dynKind,
                                          reifyKind = reifyKind,
                                          boxedKind = boxedKind,
                                          eqKind = eqKind})]
                   | T.CONSTRUCTty {tyCon = {dtyKind, id, ...}, args} =>
                     if id = #id BuiltinTypes.intTyCon
                        orelse id = #id BuiltinTypes.realTyCon
                        orelse id = #id BuiltinTypes.stringTyCon
                        orelse id = #id BuiltinTypes.boolTyCon
                        orelse id = #id BuiltinTypes.unitTyCon
                        orelse id = #id (U.JSON_void_tyCon ()) then nil
                     else raiseUnify 15
                   | _ => raiseUnify 16
*)
           else raiseUnify 17
         | T.RECORDty fields =>
           RecordLabel.Map.foldr
             (fn (x,z) => (x, newtySubkind subkind) :: z)
             nil
             fields
         | T.TYVARty _ =>
           [(ty, newtySubkind subkind)]
         | _ => raiseUnify 18)

  fun checkKind 
        ty
        ({utvarOpt,kind as T.KIND {eqKind,dynKind,reifyKind,subkind,tvarKind},lambdaDepth,id}: T.tvKind) =
      let
        val _ = case utvarOpt of NONE => () | SOME _ => raiseUnify 3
        val _ = (case eqKind of T.EQ => CheckEq.checkEq ty | _ => ())
                 handle CheckEq.Eqcheck => raiseUnify 4
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
            | T.BOXED => if isBoxedTy ty then nil else raiseUnify 1
            | T.UNIV => nil
      in
        newTyEquations @ checkSubkind ty subkind
      end
      handle U.IDNotFound name =>
             raise bug ("userlevel primitive error handling (checkKind):" ^ name)
        
  fun coerceKind 
     {from = {utvarOpt = utvarOpt1,
              kind = T.KIND {eqKind = eqKind1,
                             dynKind = dynKind1,
                             reifyKind = reifyKind1,
                             subkind = subkind1,
                             tvarKind = tvarKind1},
              lambdaDepth = lambdaDepth1, 
              id = id1} : T.tvKind,
      to = {utvarOpt = utvarOpt2,
            kind = T.KIND {eqKind = eqKind2,
                           dynKind = dynKind2,
                           reifyKind = reifyKind2,
                           subkind = subkind2,
                           tvarKind = tvarKind2},
            lambdaDepth = lambdaDepth2,
            id = id2} : T.tvKind
     } : T.tvKind * (T.ty * T.ty) list =
    let
      val reifyKind = 
          case (reifyKind1, reifyKind2) of
            (true, false) => raiseUnify 181
          | _ => reifyKind2
      val dynKind = 
          case (dynKind1, dynKind2) of
            (true, false) => raiseUnify 182
          | _ => dynKind2
      val subkind =
          case (subkind1, subkind2) of
            (T.ANY, _) => subkind2
          | (_, T.ANY) => raiseUnify 190
          | (T.JSON, T.JSON) => subkind2
          | (T.JSON, T.JSON_ATOMIC) => subkind2
          | (T.JSON, T.UNBOXED) => raiseUnify 191
          | (T.JSON_ATOMIC, T.JSON) => raiseUnify 192
          | (T.JSON_ATOMIC, T.JSON_ATOMIC) => subkind2
          | (T.JSON_ATOMIC, T.UNBOXED) => raiseUnify 193
          | (T.UNBOXED, T.JSON) => raiseUnify 194
          | (T.UNBOXED, T.JSON_ATOMIC) => subkind2
          | (T.UNBOXED, T.UNBOXED) => subkind2
      val utvarOpt = utvarOpt2
      val eqKind = 
          case (eqKind1, eqKind2) of
            (T.EQ, T.NONEQ) => raiseUnify 20
          | _ => eqKind2
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
          | (T.BOXED, T.BOXED) => (tvarKind2, nil)
          | _ => raiseUnify 22
    in
      (
       {
        utvarOpt = utvarOpt,
        kind = T.KIND {eqKind = eqKind,
                       dynKind = dynKind,
                       reifyKind = reifyKind,
                       subkind = subkind,
                       tvarKind = tvarKind},
        lambdaDepth = lambdaDepth,
        id = id2
       },
       newTyEquations)
    end

  and lubKind 
        (kind1 as
         {utvarOpt = utvarOpt1,
          kind = T.KIND {eqKind = eqKind1,
                         dynKind = dynKind1,
                         reifyKind = reifyKind1,
                         subkind = subkind1,
                         tvarKind = tvarKind1},
          lambdaDepth = lambdaDepth1,
          id = id1} : T.tvKind,
         kind2 as
         {utvarOpt = utvarOpt2,
          kind = T.KIND {eqKind = eqKind2,
                         dynKind = dynKind2,
                         reifyKind = reifyKind2,
                         subkind = subkind2,
                         tvarKind = tvarKind2},
          lambdaDepth = lambdaDepth2,
          id = id2} : T.tvKind
        ) : T.tvKind * (T.ty * T.ty) list =
      case (utvarOpt1, utvarOpt2) of
        (SOME _, NONE) => coerceKind {from = kind2, to = kind1}
      | (NONE, SOME _) => coerceKind {from = kind1, to = kind2}
      | (SOME _, SOME _) => raiseUnify 23
      | _ =>
      let 
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
        val (eqKind, tvarKind1, tvarKind2) =
            (case (eqKind1, eqKind2) of
               (T.NONEQ, T.NONEQ) => (T.NONEQ, tvarKind1, tvarKind2)
             | (T.EQ, T.EQ) => (T.EQ, tvarKind1, tvarKind2)
             | (T.NONEQ, T.EQ) =>
               (T.EQ, TU.coerceTvarKindToEQ tvarKind1, tvarKind2)
             | (T.EQ, T.NONEQ) =>
               (T.EQ, tvarKind1, TU.coerceTvarKindToEQ tvarKind2)
            )
            handle TU.CoerceTvarKindToEQ => raiseUnify 25
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
        val subkind =
            case (subkind1, subkind2) of
              (T.ANY, _) => subkind2
            | (_, T.ANY) => subkind1
            | (T.JSON, T.JSON) => subkind2
            | (T.JSON, T.JSON_ATOMIC) => subkind2
            | (T.JSON, T.UNBOXED) => T.JSON_ATOMIC
            | (T.JSON_ATOMIC, T.JSON) => subkind1
            | (T.JSON_ATOMIC, T.JSON_ATOMIC) => subkind2
            | (T.JSON_ATOMIC, T.UNBOXED) => subkind1
            | (T.UNBOXED, T.JSON) => T.JSON_ATOMIC
            | (T.UNBOXED, T.JSON_ATOMIC) => subkind2
            | (T.UNBOXED, T.UNBOXED) => subkind2
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
            | (T.BOXED, T.BOXED) => (T.BOXED, nil)
            | (T.BOXED, T.OCONSTkind tys) =>
              (T.OCONSTkind (List.filter isBoxedTy tys), nil)
            | (T.BOXED, T.OPRIMkind {instances, operators}) =>
              (T.OPRIMkind {instances = List.filter isBoxedTy instances,
                            operators = operators},
               nil)
            | (T.BOXED, T.REC _) => (tvarKind2, nil)
            | (T.OCONSTkind tys, T.BOXED) =>
              (T.OCONSTkind (List.filter isBoxedTy tys), nil)
            | (T.OPRIMkind {instances, operators}, T.BOXED) =>
              (T.OPRIMkind {instances = List.filter isBoxedTy instances,
                            operators = operators},
               nil)
            | (T.REC _, T.BOXED) => (tvarKind2, nil)
            | (T.UNIV, x) => (x,nil)
            | (x, T.UNIV) => (x,nil)
            | _ => raiseUnify 36
        val (newTvarKind, newTyEquations2) =
            case (subkind, newTvarKind) of
              (T.ANY, _) => (newTvarKind, nil)
            | (T.UNBOXED, T.OCONSTkind tys) =>
              (T.OCONSTkind (List.filter (not o isBoxedTy) tys), nil)
            | (T.UNBOXED, T.OPRIMkind {instances, operators}) =>
              (T.OPRIMkind {instances = List.filter (not o isBoxedTy) instances,
                            operators = operators},
               nil)
            | (T.UNBOXED, T.REC _) => raiseUnify 381
            | (T.UNBOXED, T.BOXED) => raiseUnify 382
            | (T.UNBOXED, T.UNIV) => (T.UNIV, nil)
            | (_, T.OCONSTkind tys) =>
              (case ListPair.unzip
                      (List.mapPartial
                         (fn ty => SOME (ty, checkSubkind ty subkind)
                                   handle Unify => NONE)
                         tys) of
                 (nil, nil) => raiseUnify 383
               | (tys, eqs) => (T.OCONSTkind tys, List.concat eqs))
            | (_, T.OPRIMkind {instances, operators}) =>
              (case ListPair.unzip
                      (List.mapPartial
                         (fn ty => SOME (ty, checkSubkind ty subkind)
                                   handle Unify => NONE)
                         instances) of
                 (nil, nil) => raiseUnify 384
               | (tys, eqs) => (T.OPRIMkind {instances = tys,
                                             operators = operators},
                                List.concat eqs))
            | (_, T.REC fields) =>
              (T.REC fields,
               List.concat (map (fn ty => checkSubkind ty subkind)
                                (RecordLabel.Map.listItems fields)))
            | (T.JSON, T.BOXED) => (T.BOXED, nil)
            | (T.JSON, T.UNIV) => (T.UNIV, nil)
            | (T.JSON_ATOMIC, T.BOXED) => raiseUnify 387
            | (T.JSON_ATOMIC, T.UNIV) => (T.UNIV, nil)
      in 
        (
         {
          lambdaDepth = lambdaDepth,
          kind = T.KIND {tvarKind = newTvarKind, 
                         eqKind = eqKind, 
                         dynKind = dynKind1 orelse dynKind2,
                         reifyKind = reifyKind1 orelse reifyKind2,
                         subkind = subkind},
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
           (* Special types: SUBSTITUTED, ALIASty, ERRORty, DUMMYty,
            * OPAQUEty, SPECty. These cases are all disjoint.
            *)
              (T.TYVARty (ref(T.SUBSTITUTED derefTy1)), _)
              => unifyTy ((derefTy1, ty2) :: tail)
            | (_, T.TYVARty (ref(T.SUBSTITUTED derefTy2)))
              => unifyTy ((ty1, derefTy2) :: tail)
            | (T.ERRORty, _) => unifyTy tail
            | (_, T.ERRORty) => unifyTy tail
            | (T.DUMMYty _,
               T.TYVARty (ref(T.TVAR
                                {
                                 lambdaDepth,
                                 id,
                                 kind = T.KIND {tvarKind = T.UNIV,
                                                eqKind=T.NONEQ,
                                                dynKind,
                                                reifyKind,
                                                subkind = T.ANY},
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
                                 kind = T.KIND {tvarKind = T.UNIV,
                                                eqKind=T.NONEQ,
                                                dynKind = dynKind,
                                                reifyKind = reifyKind,
                                                subkind = T.ANY},
                                 utvarOpt = NONE
                                }
                              )),
               T.DUMMYty _
              ) => 
              (
               TB.performSubst(ty1, ty2); 
               unifyTy tail
              )
            | (T.DUMMYty _, _) => raiseUnify 40
            | (_, T.DUMMYty _) => raiseUnify 41

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
                      (A.NONEQ, T.EQ) => raiseUnify 42
                    | _ => ()
(*
                val _ = 
                    if T.strictlyYoungerDepth
                         {tyvarDepth=depth1, contextDepth=depth2}
                    then () else raiseUnify 43
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
                      (T.EQ, A.NONEQ) => raiseUnify 44
                    | _ => ()
(*
                val _ = 
                    if T.strictlyYoungerDepth {tyvarDepth=depth2,
                                               contextDepth=depth1}
                    then () else raiseUnify 45
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
                else raiseUnify 50
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
            (* this case is added for EXPORTFUNCTOR check;
               this should not cause any problems in the 
               standard monotype unify *)
            | (T.BOUNDVARty id1,T.BOUNDVARty id2) =>
              if BoundTypeVarID.eq(id1, id2) then unifyTy tail
              else raiseUnify 53
            | (ty1, ty2) => raiseUnify 54
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
  and eqKind btvEquiv (T.KIND {eqKind=eqK1, dynKind=dynKind1, reifyKind=reifyKind1, subkind=subkind1, tvarKind=tvK1},
                       T.KIND {eqKind=eqK2, dynKind=dynKind2, reifyKind=reifyKind2, subkind=subkind2, tvarKind=tvK2}) =
      (case (eqK1, eqK2) of
         (T.EQ, T.EQ) => true
       | (T.NONEQ, T.NONEQ) => true
       | _ => false) andalso
      (dynKind1 = dynKind2)
      andalso
      (reifyKind1 = reifyKind2)
      andalso
      (subkind1 = subkind2)
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
    | (T.BOXED, T.BOXED) => true
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

end
end
