(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure CompileDynamicCase =
struct

  exception DynamicCasePatsMustBeGround of TypedCalc.tppat
  exception TypeMismatch

  structure T = Types
  structure TB = TypesBasics
  structure TIU = TypeInferenceUtils
  structure BT = BuiltinTypes
  structure PC = PatternCalc
  structure TC = TypedCalc
  structure UP = UserLevelPrimitive
  (* structure RU = ReifyUtils *)
  structure RTD = ReifiedTyData

  fun printTy ty = print (Bug.prettyPrint (T.format_ty ty))

  fun --> (argTy, retTy) = T.FUNMty ([argTy], retTy)
  fun ** (ty1, ty2) = T.RECORDty (RecordLabel.tupleMap [ty1, ty2])
  infixr 4 -->
  infix 5 **

  fun eqTy arg = Unify.eqTy BoundTypeVarID.Map.empty arg

  fun isDynamicTy loc ty =
      case TB.derefTy ty of
        T.CONSTRUCTty {tyCon, args = [ty]} =>TypID.eq (#id tyCon, #id (UP.REIFY_tyCon_dyn loc))
      | _ => false
  fun dynamicElemTy loc ty =
      case TB.derefTy ty of
        T.CONSTRUCTty {tyCon, args = [ty]} =>
        if TypID.eq (#id tyCon, #id (UP.REIFY_tyCon_dyn loc)) then SOME ty else NONE
      | _ => NONE
  fun Pair loc {exp=exp1, ty=ty1} {exp=exp2, ty=ty2} =
      {exp = TC.TPRECORD
               {fields = RecordLabel.tupleMap [exp1, exp2],
                loc = loc,
                recordTy = RecordLabel.tupleMap [ty1, ty2]},
       ty = ty1 ** ty2}
  fun DynTy loc ty = T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_dyn loc, args = [ty]}
  fun ListTy ty = T.CONSTRUCTty {tyCon = BT.listTyCon, args = [ty]}
  fun Cons loc {hd, tl} =
      let
        val listTy = if eqTy (#ty tl, ListTy (#ty hd)) then #ty tl 
                     else 
                       (print "cons\n";
                        printTy (#ty tl);
                        print "\n";
                        printTy (#ty hd);
                        print "\n";
                       raise TypeMismatch
                       )
        val {exp,ty} = Pair loc hd tl
      in
        {exp=TC.TPDATACONSTRUCT
               {con = BT.consTPConInfo,
                argExpOpt = SOME exp,
                instTyList = SOME [#ty hd],
                loc = loc},
         ty = listTy}
      end
  fun Nil loc instTy = 
      {exp=TC.TPDATACONSTRUCT 
             {argExpOpt = NONE,
              con = BT.nilTPConInfo,
              instTyList = SOME [instTy],
              loc = loc},
       ty=ListTy instTy}
  fun List loc instTy expTyList =
      foldr (fn (hdExp, tlExp) => 
                Cons loc {hd = hdExp, tl = tlExp})
            (Nil loc instTy) 
            expTyList

  fun newVar ty =
      {path = [], ty = ty, id = VarID.generate (), opaque = false} : T.varInfo

  fun NewVar ty =
      {exp = TC.TPVAR {path = [], 
                       ty = ty, 
                       id = VarID.generate (), 
                       opaque = false},
       ty = ty}

  fun Var (varInfo as {ty,path,id,opaque}) =
      {exp = TC.TPVAR varInfo, ty = ty}

  fun Fn loc {expFn, argTy, bodyTy} =
      let
        val v = newVar argTy
      in
        {exp = TC.TPFNM ({argVarList = [v], bodyExp = expFn v, bodyTy = bodyTy, loc = loc}),
         ty = argTy --> bodyTy}
      end

  fun Dynamic loc {exp, ty, elemTy, coerceTy} =
      let
        val exp = 
            TC.TPDYNAMIC {exp = exp,
                          ty = ty,
                          elemTy = elemTy,
                          coerceTy = coerceTy,
                          loc = loc}
      in
        {exp = exp, ty = coerceTy}
      end
  fun DynamicView loc {exp, ty, elemTy, coerceTy} =
      let
        val exp = 
            TC.TPDYNAMICVIEW {exp = exp,
                              ty = ty,
                              elemTy = elemTy,
                              coerceTy = coerceTy,
                              loc = loc}
      in
        {exp = exp, ty = coerceTy}
      end

  fun mapAll f map =
      let exception False
      in
        RecordLabel.Map.foldl 
        (fn (ty, res) => if f ty then res else raise False)
        true
        map
        handle False => false
      end

  fun printRule {arg, body,ty, ...} = 
      let
        val _ = print "\n{arg:" 
        val _ = print (Bug.prettyPrint (TC.format_tppat arg))
        val _ = print "\nty:" 
        val _ = print (Bug.prettyPrint (T.format_ty ty))
        val _ = print "\nbody:" 
        val _ = print (Bug.prettyPrint (TC.format_tpexp body))
        val _ = print "}\n" 
      in
        ()
      end

  fun sortRules ruleList =
      let
        fun compareRule (r1,r2) =
            case CompareTy.compareTy (#keyTy r1, #keyTy r2) of
              EQUAL => Loc.compareLoc
                         (TypedCalc.tppatToLoc (#arg r1), 
                          TypedCalc.tppatToLoc (#arg r2))
            | x => x
      in
        ListSorter.sort compareRule ruleList
      end

  fun coerceGroundTy ty =
      let
        val _ = TIU.instantiateOConstAndRecordTy ty
      in
        case TB.derefTy ty of
          T.FUNMty (tyList, ty) =>
          List.all (fn x => coerceGroundTy x) (ty::tyList)
        | T.RECORDty tyMap => mapAll coerceGroundTy tyMap
        | T.CONSTRUCTty {args, ...} => List.all (fn x => coerceGroundTy x) args
        | T.TYVARty (ref (T.TVAR {utvarOpt = SOME _,...})) => true
        | _ => false
      end

  fun partitionRules nil = nil
    | partitionRules (L as ({keyTy,patTy,existTyvars,existInstTys,...}::rules)) =
      let
(*
        val (firstGroup, restList) = 
            List.partition (fn x => eqTy(#ty x, ty)) L
*)
        val (firstGroup, restList) = 
            List.partition 
              (fn x => case CompareTy.compareTy(#keyTy x, keyTy) of
                         EQUAL => true | _ => false) 
              L
      in
        {keyTy = keyTy,
         patTy = patTy,
         existTyvars = existTyvars,
         existInstTys = existInstTys,
         ruleList = firstGroup}
        :: partitionRules restList
      end

  fun compile {exp = dynamicTerm, ty=dynamicTy, elemTy, ruleList, ruleBodyTy,loc} =
      let
        val _ =
            app (fn r => if coerceGroundTy (#patTy r)
                         then ()
                         else raise DynamicCasePatsMustBeGround (#arg r))
                ruleList
        val ruleList = sortRules ruleList
        val caseGroups = partitionRules ruleList
        val existInstTy =
            T.CONSTRUCTty {tyCon = UP.REIFY_tyCon_existInstMap loc, args = []}
        fun compileGroup {keyTy, patTy, existTyvars, existInstTys, ruleList} =
            let
              val instVar = newVar existInstTy
              val argVar = newVar dynamicTy
              val dynamicExp =
                  TC.TPDYNAMIC
                    {exp = TC.TPVAR argVar,
                     ty = dynamicTy,
                     elemTy = elemTy,
                     coerceTy = patTy,
                     loc = loc}
              val caseExp =
                  TC.TPCASEM
                    {caseKind = PC.MATCH,
                     expList = [dynamicExp],
                     expTyList = [patTy],
                     loc = loc,
                     ruleBodyTy = ruleBodyTy,
                     ruleList = map (fn {arg, body, ...} =>
                                        {args = [arg], body = body})
                                    ruleList}
              val polyExp =
                  if BoundTypeVarID.Map.isEmpty existTyvars
                  then caseExp
                  else TC.TPPOLY
                         {btvEnv = existTyvars,
                          constraints = nil,
                          expTyWithoutTAbs = ruleBodyTy,
                          exp = caseExp,
                          loc = loc}
              val instExp =
                  case existInstTys of
                    nil => polyExp
                  | _::_ =>
                    TC.TPDYNAMICEXISTTAPP
                      {existInstMap = TC.TPVAR instVar,
                       exp = polyExp,
                       expTy = T.POLYty {boundtvars = existTyvars,
                                         constraints = nil,
                                         body = ruleBodyTy},
                       instTyList = existInstTys,
                       loc = loc}
              val funTerm =
                  {exp =
                     TC.TPFNM
                       {argVarList = [argVar],
                        bodyExp = instExp,
                        bodyTy = ruleBodyTy,
                        loc = loc},
                   ty = T.FUNMty ([dynamicTy], ruleBodyTy)}
              val funTerm =
                  {exp =
                     TC.TPFNM
                       {argVarList = [instVar],
                        bodyExp = #exp funTerm,
                        bodyTy = #ty funTerm,
                        loc = loc},
                   ty = T.FUNMty ([existInstTy], #ty funTerm)}
              val tyRepTerm =
                  {exp = TC.TPREIFYTY (keyTy, loc), ty = RTD.TyRepTy loc}
            in
              Pair loc tyRepTerm funTerm
            end
        val RuleTy = RTD.TyRepTy loc ** (existInstTy --> (dynamicTy --> ruleBodyTy))
        val {exp, ty} = List loc RuleTy (map compileGroup caseGroups)
        val term = TC.TPDYNAMICCASE 
                     {
                      groupListTerm = exp, 
                      groupListTy = ty,
                      dynamicTerm = dynamicTerm,
                      dynamicTy = dynamicTy,
                      elemTy=elemTy, 
                      ruleBodyTy = ruleBodyTy,
                      loc=loc
                     }
      in
        (ruleBodyTy, term)
      end
end
