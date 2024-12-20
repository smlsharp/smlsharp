(**
 * @copyright (C) 2024 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure RecordCalcFv =
struct

  structure R = RecordCalc

  fun deleteVars fv (vars : RecordCalc.varInfo list) =
      foldl (fn ({id, ...}, fv) =>
                if VarID.Map.inDomain (fv, id)
                then #1 (VarID.Map.remove (fv, id))
                else fv)
            fv
            vars

  fun merge (fvs : int VarID.Map.map list) =
      foldl (VarID.Map.unionWith (op +)) VarID.Map.empty fvs

  fun fvValue value =
      case value of
        R.RCCONSTANT _ => VarID.Map.empty
      | R.RCVAR {id, ...} => VarID.Map.singleton (id, 1)

  fun fvExp exp =
      case exp of
        R.RCVALUE (value, loc) => fvValue value
      | R.RCSTRING _ => VarID.Map.empty
      | R.RCEXVAR _ => VarID.Map.empty
      | R.RCFNM {btvEnv, constraints, argVarList, bodyExp, bodyTy, loc} =>
        deleteVars (fvExp bodyExp) argVarList
      | R.RCAPPM {funExp, funTy, instTyList, argExpList, loc} =>
        merge (fvExp funExp :: map fvExp argExpList)
      | R.RCSWITCH {exp, expTy, branches, defaultExp, resultTy, loc} =>
        merge (fvExp exp
               :: fvExp defaultExp
               :: map (fvExp o #body) branches)
      | R.RCPRIMAPPLY {primOp, instTyList, instSizeList, instTagList,
                       argExpList, loc} =>
        merge [merge (map fvValue instSizeList),
               merge (map fvValue instTagList),
               fvExpList argExpList]
      | R.RCRECORD {fields, loc} =>
        merge (map (fn {exp, ty, size, tag} =>
                     merge [fvExp exp, fvValue size, fvValue tag])
                   (RecordLabel.Map.listItems fields))
      | R.RCSELECT {label, indexExp, recordExp, recordTy, resultSize, resultTag,
                    resultTy, loc} =>
        merge [fvExp indexExp, fvExp recordExp, fvValue resultSize,
               fvValue resultTag]
      | R.RCMODIFY {label, indexExp, recordExp, recordTy, elementExp, elementTy,
                    elementSize, elementTag, loc} =>
        merge [fvExp indexExp, fvExp recordExp, fvExp elementExp,
               fvValue elementSize, fvValue elementTag]
      | R.RCLET {decl, body, loc} =>
        let
          val (fv, vars) = fvDecl decl
        in
          merge [fv, deleteVars (fvExp body) vars]
        end
      | R.RCRAISE {exp, resultTy, loc} =>
        fvExp exp
      | R.RCHANDLE {exp, exnVar, handler, resultTy, loc} =>
        merge [fvExp exp, deleteVars (fvExp handler) [exnVar]]
      | R.RCTHROW {catchLabel, argExpList, resultTy, loc} =>
        fvExpList argExpList
      | R.RCCATCH {recursive, rules, tryExp, resultTy, loc} =>
        merge (fvExp tryExp :: map (fn rule => fvExp (#catchExp rule)) rules)
      | R.RCFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        merge (fvExp funExp :: map fvExp argExpList)
      | R.RCCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
        deleteVars (fvExp bodyExp) argVarList
      | R.RCCAST {exp, expTy, targetTy, cast, loc} =>
        fvExp exp
      | R.RCINDEXOF {fields, label, loc} =>
        merge (map (fn {ty, size} => fvValue size)
                   (RecordLabel.Map.listItems fields))

  and fvExpList exps =
      merge (map fvExp exps)

  and fvDecl decl =
      case decl of
        R.RCVAL {var, exp, loc} =>
        (fvExp exp, [var])
      | R.RCVALREC (binds, loc) =>
        let
          val vars = map #var binds
        in
          (deleteVars (merge (map (fvExp o #exp) binds)) vars, vars)
        end
      | R.RCEXPORTVAR {weak, var, exp = SOME exp} => (fvExp exp, nil)
      | R.RCEXPORTVAR {weak, var, exp = NONE} => (VarID.Map.empty, nil)
      | R.RCEXTERNVAR _ => (VarID.Map.empty, nil)

end
