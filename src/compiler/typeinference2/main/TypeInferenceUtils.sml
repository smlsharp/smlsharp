(**
 * utility functions for manupilating types (needs re-writing).
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: TypeInferenceUtils.sml,v 1.58 2008/08/05 14:44:00 bochao Exp $
 *)
structure TypeInferenceUtils =
struct
local 
    structure U = Unify
    structure T = Types
    structure TPC = TypedCalc
    structure TCU = TypedCalcUtils
    structure TIC = TypeInferenceContext
    structure TU = TypesUtils
    structure E = TypeInferenceError
  fun bug s = Control.Bug ("TypeInferenceUtils: " ^ s)

in
  
  val dummyTyId = ref 0
  fun nextDummyTy () =
      T.DUMMYty (!dummyTyId) before dummyTyId := !dummyTyId + 1

  fun instOfPolyTy (polyTy, tyList) =
      case TU.derefTy polyTy of
        T.POLYty {boundtvars, body} =>
        let 
          val subst1 = TU.freshSubst boundtvars
          val body = TU.substBTvar subst1 body
          val instTyList = BoundTypeVarID.Map.listItems subst1
          val tyPairs = 
              if length tyList = length instTyList then 
                ListPair.zip (instTyList, tyList)
              else raise bug "arity mismatch in instOfPoly"
          val _ = U.unify tyPairs
        in
          body
        end
      | _ => 
        raise bug "nonpolyty in TFUNDEF in instOfPoly"


  (*
   * make a fresh instance of ty by instantiating the top-level type
   * abstractions (only)
   *)
  fun freshTopLevelInstTy ty =
      case ty of
        (T.POLYty{boundtvars, body, ...}) =>
        let 
          val subst = TU.freshSubst boundtvars
          val bty = TU.substBTvar subst body
        in  
          (bty, BoundTypeVarID.Map.listItems subst)
        end
      | _ => (ty, nil)
             
  fun eliminateVacuousTyvars () =
      let
        fun instanticateTv tv =
            case tv of
              ref(T.TVAR {tvarKind = T.OCONSTkind (h::_), ...}) =>
              tv := T.SUBSTITUTED h
            | ref(T.TVAR {tvarKind = T.OPRIMkind
                                         {instances = (h::_),...},
                          ...}
                 )
              => tv := T.SUBSTITUTED h
            | ref(T.TVAR {tvarKind = T.REC tyFields, ...}) => 
              tv := T.SUBSTITUTED (T.RECORDty tyFields)
            | ref(T.TVAR {tvarKind = T.UNIV, ...}) => 
              tv := T.SUBSTITUTED (nextDummyTy())
            | _ => ()
      in
        (
         List.app instanticateTv (!T.kindedTyvarList);
         T.kindedTyvarList := nil
        )
      end

(*
  exception NONEQ
  fun eqTy btvEquiv (ty1, ty2) = 
      let
        val ty1 = TU.derefTy ty1
        val ty2 = TU.derefTy ty2
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
             val _ = 
                 app (fn ((_,kind1), (_,kind2)) =>
                         if eqKind btvEquiv (kind1, kind2) then ()
                         else raise NONEQ)
                     kindPairs
             val btvMap =
                 foldl
                   (fn (((i1,_),(i2,_)), btvMap) =>
                       BoundTypeVarID.Map.insert(btvMap, i1, i2)
                   )
                   BoundTypeVarID.Map.empty
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
        | (T.DUMMYty _, _) => (U.unify [(ty1, ty2)]; true)
        | (_, T.DUMMYty _) => (U.unify [(ty1, ty2)]; true)
        | (T.TYVARty tv1, _) => (U.unify [(ty1, ty2)]; true)
        | (_, T.TYVARty tv1) => (U.unify [(ty1, ty2)]; true)
        | _ => false
      end
      handle U.Unify => false
  and eqSMap btvEquiv (smap1, smap2) =
      let
        val tyL1 = LabelEnv.listItems smap1
        val tyL2 = LabelEnv.listItems smap2
      in
        eqTyList btvEquiv (tyL1, tyL2)
      end
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
        ({oprimId=id1,path=path1,keyTyList=ktyL1,match=m1,instMap=IM1},
         {oprimId=id2,path=path2,keyTyList=ktyL2,match=m2,instMap=IM2})
      =
      OPrimID.eq(id1,id2) andalso
      String.concat path1 = String.concat path2 andalso
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
*)

  exception CoerceTy
  fun coerceTy (tpexp, fromTy, toTy, loc) =
      if TU.monoTy toTy then 
        let
          val (fromTy, tpexp) = TCU.freshInst(fromTy, tpexp)
        in
          (
           U.unify [(fromTy, toTy)] handle U.Unify => raise CoerceTy;
           tpexp
          )
        end
      else
        case toTy of
          T.POLYty{boundtvars,body,...} =>
          let 
            (* here we rely on unification to with bound tvar *)
            val (fromBody, tpexp) = TCU.freshToplevelInst(fromTy, tpexp)
            val tpexp = coerceTy (tpexp, fromBody, body, loc)
          in
            TPC.TPPOLY{btvEnv=boundtvars,
                       expTyWithoutTAbs=body,
                       exp=tpexp,
                       loc=loc}
          end
        | T.FUNMty (tyList, bodyTy) =>
          (
           case fromTy of
             T.FUNMty(fromTyList, fromBodyTy) =>
             let
               val _ = if length tyList = length fromTyList then ()
                       else raise CoerceTy
               val tyPairs = ListPair.zip (tyList, fromTyList)
               val _ = U.unify tyPairs handle U.Unify => raise CoerceTy
               val argVarList = map TCU.newTCVarInfo tyList
               val argExpList = map (fn x => TPC.TPVAR (x,loc)) argVarList
               val bodyExp = 
                   TPC.TPAPPM{funExp=tpexp,
                             funTy=T.FUNMty(tyList, fromBodyTy),
                             argExpList=argExpList,
                             loc=loc}
               val bodyEvp = coerceTy (bodyExp, fromBodyTy, bodyTy, loc)
             in 
               TPC.TPFNM
                 {argVarList = argVarList,
                  bodyTy = bodyTy,
                  bodyExp = bodyExp,
                  loc = loc}
             end
           | _ => raise CoerceTy
          )
        | T.RECORDty tyFields => 
          (
           case fromTy of
             T.RECORDty fromTyFields =>
             let
               val labels = LabelEnv.listKeys tyFields
               val fromLabels = LabelEnv.listKeys fromTyFields
               val _ = if length labels = length fromLabels then ()
                       else raise CoerceTy
               val _ = List.app
                         (fn (l1,l2) => if l1 = l2 then () else raise CoerceTy)
                         (ListPair.zip (labels, fromLabels))
               val (makeRecord, expFields) =
                   case tpexp of
                     TPC.TPRECORD {fields, recordTy=_, loc=loc} => 
                     (fn (fields, ty) => TPC.TPRECORD{fields=fields,
                                                      recordTy=ty,
                                                      loc=loc},
                      fields)
                   | _ => 
                     let
                       val var = TCU.newTCVarInfo fromTy
                       val varExp = TPC.TPVAR (var, loc)
                       val expFields = 
                           LabelEnv.foldri 
                             (fn (label,fieldTy,expFields) =>
                                 let
                                   val litem =
                                       TPC.TPSELECT
                                         {label=label,
                                          exp=varExp,
                                          expTy=fromTy,
                                          resultTy=fieldTy,
                                          loc=loc}
                                 in
                                   LabelEnv.insert(expFields,label,litem)
                                 end
                             )
                             LabelEnv.empty
                             fromTyFields
                       fun makeRecord (expFields, recordTy) =
                           TPC.TPLET
                             {decls = [TPC.TPVAL ([(var, tpexp)], loc)],
                              body = [TPC.TPRECORD
                                        {fields=expFields,
                                         recordTy=recordTy,
                                         loc=loc}],
                              tys = [recordTy],
                              loc = loc
                             }
                     in
                       (makeRecord, expFields)
                     end
               fun getItem (map, label) =
                   case LabelEnv.find(map, label) of
                     SOME item => item
                   | NONE => raise bug "impossible"
               val newExpFields =
                   LabelEnv.mapi
                   (fn (label, exp) =>
                       let
                         val fromTy = getItem(fromTyFields, label)
                         val toTy = getItem(tyFields, label)
                         val newExp = coerceTy(exp, fromTy, toTy, loc)
                       in
                        newExp
                       end
                   )
                   expFields
               val newExp = makeRecord (newExpFields, toTy)
             in
               newExp
             end
           | _ => raise CoerceTy
          )
        | _ => raise CoerceTy
end
end
