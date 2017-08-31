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
    structure TB = TypesBasics
    structure P = Printers

  fun bug s = Bug.Bug ("TypeInferenceUtils: " ^ s)

in
  
  fun nextDummyTy kind =
      T.DUMMYty (DummyTyID.generate (), kind)

  (*
   * make a fresh instance of ty by instantiating the top-level type
   * abstractions (only)
   *)
  fun freshTopLevelInstTy ty =
      case ty of
        (T.POLYty{boundtvars, body, constraints}) =>
        let 
          val subst = TB.freshSubst boundtvars
          val bty = TB.substBTvar subst body
          val constraints =
              List.map (fn c =>
                           case c of T.JOIN {res, args = (arg1, arg2), loc} =>
                             T.JOIN
                                 {res = TB.substBTvar subst res,
                                  args = (TB.substBTvar subst arg1,
                                          TB.substBTvar subst arg2), loc=loc})
                       constraints
        in  
          (bty, BoundTypeVarID.Map.listItems subst, constraints)
        end
      | _ => (ty, nil, nil)
             
  fun instantiateTv tv =
      case tv of
        ref (T.TVAR {kind as T.KIND {tvarKind, ...}, ...}) =>
        (case tvarKind of
           T.OCONSTkind (h::_) => tv := T.SUBSTITUTED h
         | T.OCONSTkind nil => raise Bug.Bug "instantiateTv OCONSTkind"
         | T.OPRIMkind {instances = (h::_),...} => tv := T.SUBSTITUTED h
         | T.OPRIMkind {instances = nil,...} =>
           raise Bug.Bug "instantiateTv OPRIMkind"
         | T.REC tyFields => tv := T.SUBSTITUTED (nextDummyTy kind)
         | T.BOXED => tv := T.SUBSTITUTED (nextDummyTy kind)
         | T.UNIV => tv := T.SUBSTITUTED (nextDummyTy kind))
      | ref(T.SUBSTITUTED _) => ()

(*
  fun eliminateVacuousTyvars () =
      (
       List.app instanticateTv (!T.kindedTyvarList);
       T.kindedTyvarList := nil
      )
*)
  exception CoerceTy
  fun coerceTy (tpexp, fromTy, toTy, loc) =
      if TB.monoTy (TB.derefTy toTy) then 
        let
          val (fromTy, constraints, tpexp) = TCU.freshInst(fromTy, tpexp)
        in
          (
           U.unify [(fromTy, toTy)] 
           handle U.Unify => raise CoerceTy;
           {tpexp=tpexp, constraints=constraints}
          )
        end
      else
        case (TB.derefTy toTy) of
          T.POLYty{boundtvars,body,constraints} =>
          let 
            (* here we rely on unification with bound tvar
               2013-4-29 With kind constraints in user type spec, this 
               is no longer valid.
               Since rigid instance will not be substituted, we can
               re-generalize in the original order to obtain the same type.
               bug fixed. 257_recordPolyAnnotation.sml
             *)
            val (fromBody, fromConstraints, tpexp) = TCU.freshToplevelInst(fromTy, tpexp)
            (* FIXME: fromConstraintsを捨てている問題の確認 *)
            val subst = TB.freshRigidSubst boundtvars
            val body = TB.substBTvar subst body
            val {tpexp=tpexp, constraints=fromConstraints} = coerceTy (tpexp, fromBody, body, loc)
            val boundtvars =
                BoundTypeVarID.Map.foldl
                  (fn (ty, btvs) =>
                      case TB.derefTy ty of
                        T.TYVARty (r as ref(T.TVAR {id, kind, ...})) =>
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
                      | ty => 
                        (
                         P.print "POLY in coerceTy\n";
                         P.printTy ty;
                         P.print "\n";
                         raise Bug.Bug "POLY in coerceTy"
                        )
                  )
                  BoundTypeVarID.Map.empty
                  subst
          in
            {tpexp=TPC.TPPOLY{btvEnv=boundtvars,
                              expTyWithoutTAbs=body,
                              exp=tpexp,
                              loc=loc},
             constraints=nil}
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
               val argVarList = map (TCU.newTCVarInfo loc) tyList
               val argExpList = map TPC.TPVAR argVarList
               val bodyExp = 
                   TPC.TPAPPM {funExp=tpexp,
                               funTy=T.FUNMty(tyList, fromBodyTy),
                               argExpList=argExpList,
                               loc=loc}
               val {tpexp=bodyExp, constraints} = coerceTy (bodyExp, fromBodyTy, bodyTy, loc)
             in 
               {tpexp=TPC.TPFNM
                          {argVarList = argVarList,
                           bodyTy = bodyTy,
                           bodyExp = bodyExp,
                           loc = loc},
                constraints=constraints}
             end
           | _ => raise CoerceTy
          )
        | T.RECORDty tyFields => 
          (
           case fromTy of
             T.RECORDty fromTyFields =>
             let
               val labels = RecordLabel.Map.listKeys tyFields
               val fromLabels = RecordLabel.Map.listKeys fromTyFields
               val _ = if length labels = length fromLabels then ()
                       else raise CoerceTy
               val _ = List.app
                         (fn (l1,l2) => if l1 = l2 then () else raise CoerceTy)
                         (ListPair.zip (labels, fromLabels))
               val (extraBindsRev, expFields) =
                   case tpexp of
                     TPC.TPRECORD {fields, recordTy=_, loc=loc} => 
                     (nil, fields)
                   | _ => 
                     let
                       val var = TCU.newTCVarInfo loc fromTy
                       val varExp = TPC.TPVAR var
                     in
                       RecordLabel.Map.foldli
                         (fn (label,fieldTy,(extraBindsRev, expFields)) =>
                             let
                               val fieldVar = TCU.newTCVarInfo loc fieldTy
                               val fieldExp = TPC.TPVAR fieldVar
                               val newBind =
                                   (fieldVar,
                                    TPC.TPSELECT
                                      {label=label,
                                       exp=varExp,
                                       expTy=fromTy,
                                       resultTy=fieldTy,
                                       loc=loc}
                                   )
                             in
                               (newBind::extraBindsRev,
                                RecordLabel.Map.insert(expFields,label,fieldExp)
                               )
                             end
                         )
                         ([(var, tpexp)], RecordLabel.Map.empty)
                         fromTyFields
                     end
               fun getItem (map, label) =
                   case RecordLabel.Map.find(map, label) of
                     SOME item => item
                   | NONE => raise bug "impossible"
               val (extraBindsRev, newExpFields, newConstraints) =
                   RecordLabel.Map.foldli
                   (fn (label, exp, (extraBindsRev,newExpFields,constraints)) =>
                       let
                         val fromTy = getItem(fromTyFields, label)
                         val toTy = getItem(tyFields, label)
                         val {tpexp=newExp,constraints=newConstraints} = coerceTy(exp, fromTy, toTy, loc)
                       in
                         if TCU.isAtom newExp then
                           (extraBindsRev, RecordLabel.Map.insert(newExpFields, label, newExp), constraints @ newConstraints)
                         else
                           let
                             val fieldVar = TCU.newTCVarInfo loc toTy
                             val fieldExp = TPC.TPVAR fieldVar
                             val newBind = (fieldVar, newExp)
                           in
                             ((fieldVar, newExp)::extraBindsRev,
                              RecordLabel.Map.insert(newExpFields, label, fieldExp),
                              constraints @ newConstraints
                             )
                           end
                       end
                   )
                   (extraBindsRev, RecordLabel.Map.empty, nil)
                   expFields
               val resultExp =
                   TPC.TPMONOLET
                     {binds = List.rev extraBindsRev,
                      bodyExp = TPC.TPRECORD
                               {fields=newExpFields,
                                recordTy=toTy,
                                loc=loc},
                      loc = loc
                     }
             in
               {tpexp=resultExp, constraints=newConstraints}
             end
           | _ => raise CoerceTy
          )
        | _ => raise CoerceTy
end
end
