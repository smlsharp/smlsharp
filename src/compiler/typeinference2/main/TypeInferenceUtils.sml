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
  
  val dummyTyId = ref 0
  fun nextDummyTy () =
      T.DUMMYty (!dummyTyId) before dummyTyId := !dummyTyId + 1

  (*
   * make a fresh instance of ty by instantiating the top-level type
   * abstractions (only)
   *)
  fun freshTopLevelInstTy ty =
      case ty of
        (T.POLYty{boundtvars, body, ...}) =>
        let 
          val subst = TB.freshSubst boundtvars
          val bty = TB.substBTvar subst body
        in  
          (bty, BoundTypeVarID.Map.listItems subst)
        end
      | _ => (ty, nil)
             
  fun instantiateTv tv =
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
      | ref(T.TVAR {tvarKind = T.JOIN (tyFields,_,_, _), ...}) => 
        tv := T.SUBSTITUTED (T.RECORDty tyFields)
      | ref(T.TVAR {tvarKind = T.UNIV, ...}) => 
        tv := T.SUBSTITUTED (nextDummyTy())
      | _ => ()

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
          val (fromTy, tpexp) = TCU.freshInst(fromTy, tpexp)
        in
          (
           U.unify [(fromTy, toTy)] 
           handle U.Unify => raise CoerceTy;
           tpexp
          )
        end
      else
        case (TB.derefTy toTy) of
          T.POLYty{boundtvars,body,...} =>
          let 
            (* here we rely on unification with bound tvar
               2013-4-29 With kind constraints in user type spec, this 
               is no longer valid.
               Since rigid instance will not be substituted, we can
               re-generalize in the original order to obtain the same type.
               bug fixed. 257_recordPolyAnnotation.sml
             *)
            val (fromBody, tpexp) = TCU.freshToplevelInst(fromTy, tpexp)
            val subst = TB.freshRigidSubst boundtvars
            val body = TB.substBTvar subst body
            val tpexp = coerceTy (tpexp, fromBody, body, loc)
            val boundtvars =
                BoundTypeVarID.Map.foldl
                  (fn (ty, btvs) =>
                      case TB.derefTy ty of
                        T.TYVARty (r as ref(T.TVAR (k as {id, ...}))) =>
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
                               {
                                tvarKind = (#tvarKind k),
                                eqKind = (#eqKind k)
                               }
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
               val argVarList = map (TCU.newTCVarInfo loc) tyList
               val argExpList = map TPC.TPVAR argVarList
               val bodyExp = 
                   TPC.TPAPPM {funExp=tpexp,
                               funTy=T.FUNMty(tyList, fromBodyTy),
                               argExpList=argExpList,
                               loc=loc}
               val bodyExp = coerceTy (bodyExp, fromBodyTy, bodyTy, loc)
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
               val (extraBindsRev, expFields) =
                   case tpexp of
                     TPC.TPRECORD {fields, recordTy=_, loc=loc} => 
                     (nil, fields)
                   | _ => 
                     let
                       val var = TCU.newTCVarInfo loc fromTy
                       val varExp = TPC.TPVAR var
                     in
                       LabelEnv.foldli
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
                                LabelEnv.insert(expFields,label,fieldExp)
                               )
                             end
                         )
                         ([(var, tpexp)], LabelEnv.empty)
                         fromTyFields
                     end
               fun getItem (map, label) =
                   case LabelEnv.find(map, label) of
                     SOME item => item
                   | NONE => raise bug "impossible"
               val (extraBindsRev, newExpFields) =
                   LabelEnv.foldli
                   (fn (label, exp, (extraBindsRev,newExpFields)) =>
                       let
                         val fromTy = getItem(fromTyFields, label)
                         val toTy = getItem(tyFields, label)
                         val newExp = coerceTy(exp, fromTy, toTy, loc)
                       in
                         if TCU.isAtom newExp then
                           (extraBindsRev, LabelEnv.insert(newExpFields, label, newExp))
                         else
                           let
                             val fieldVar = TCU.newTCVarInfo loc toTy
                             val fieldExp = TPC.TPVAR fieldVar
                             val newBind = (fieldVar, newExp)
                           in
                             ((fieldVar, newExp)::extraBindsRev,
                              LabelEnv.insert(newExpFields, label, fieldExp)
                             )
                           end
                       end
                   )
                   (extraBindsRev, LabelEnv.empty)
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
               resultExp
             end
           | _ => raise CoerceTy
          )
        | _ => raise CoerceTy
end
end
