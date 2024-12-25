structure TypedLambdaSubst =
struct

  structure L = TypedLambda

  fun bindVar (subst : L.tlexp VarID.Map.map) ({id, ...} : L.varInfo) =
      if VarID.Map.inDomain (subst, id)
      then #1 (VarID.Map.remove (subst, id))
      else subst

  fun bindVars subst vars =
      foldl (fn (v, z) => bindVar z v) subst vars

  fun substExp subst exp =
      case exp of
        L.TLCONSTANT _ => exp
      | L.TLINT _ => exp
      | L.TLSTRING _ => exp
      | L.TLVAR (var, loc) =>
        (
          case VarID.Map.find (subst, #id var) of
            NONE => exp
          | SOME exp => exp
        )
      | L.TLEXVAR _ => exp
      | L.TLFNM {argVarList, bodyTy, bodyExp, loc} =>
        L.TLFNM {argVarList = argVarList,
                 bodyTy = bodyTy,
                 bodyExp = substExp (bindVars subst argVarList) bodyExp,
                 loc = loc}
      | L.TLAPPM {funExp, funTy, argExpList, loc} =>
        L.TLAPPM {funExp = substExp subst funExp,
                  funTy = funTy,
                  argExpList = map (substExp subst) argExpList,
                  loc = loc}
      | L.TLSWITCH {exp, expTy, branches, defaultExp, resultTy, loc} =>
        L.TLSWITCH {exp = substExp subst exp,
                    expTy = expTy,
                    branches = map (fn {const, body} =>
                                       {const = const,
                                        body = substExp subst body})
                                   branches,
                    defaultExp = substExp subst defaultExp,
                    resultTy = resultTy,
                    loc = loc}
      | L.TLDYNAMICEXISTTAPP {existInstMap, exp, expTy, instTyList, loc} =>
        L.TLDYNAMICEXISTTAPP {existInstMap = substExp subst existInstMap,
                              exp = substExp subst exp,
                              expTy = expTy,
                              instTyList = instTyList,
                              loc = loc}
      | L.TLPRIMAPPLY {primOp, instTyList, argExpList, loc} =>
        L.TLPRIMAPPLY {primOp = primOp,
                       instTyList = instTyList,
                       argExpList = map (substExp subst) argExpList,
                       loc = loc}
      | L.TLOPRIMAPPLY {oprimOp, instTyList, argExp, loc} =>
        L.TLOPRIMAPPLY {oprimOp = oprimOp,
                        instTyList = instTyList,
                        argExp = substExp subst argExp,
                        loc = loc}
      | L.TLRECORD {fields, recordTy, loc} =>
        L.TLRECORD {fields = RecordLabel.Map.map (substExp subst) fields,
                    recordTy = recordTy,
                    loc = loc}
      | L.TLSELECT {label, recordExp, recordTy, resultTy, loc} =>
        L.TLSELECT {label = label,
                    recordExp = substExp subst recordExp,
                    recordTy = recordTy,
                    resultTy = resultTy,
                    loc = loc}
      | L.TLMODIFY {label, recordExp, recordTy, elementExp, elementTy, loc} =>
        L.TLMODIFY {label = label,
                    recordExp = substExp subst recordExp,
                    recordTy = recordTy,
                    elementExp = substExp subst elementExp,
                    elementTy = elementTy,
                    loc = loc}
      | L.TLLET {decl, body, loc} =>
        L.TLLET {decl = substDecl subst decl,
                 body = substExp subst body,
                 loc = loc}
      | L.TLRAISE {exp, resultTy, loc} =>
        L.TLRAISE {exp = substExp subst exp,
                   resultTy = resultTy,
                   loc = loc}
      | L.TLHANDLE {exp, exnVar, handler, resultTy, loc} =>
        L.TLHANDLE {exp = substExp subst exp,
                    exnVar = exnVar,
                    handler = substExp (bindVar subst exnVar) handler,
                    resultTy = resultTy,
                    loc = loc}
      | L.TLTHROW {catchLabel, argExpList, resultTy, loc} =>
        L.TLTHROW {catchLabel = catchLabel,
                   argExpList = map (substExp subst) argExpList,
                   resultTy = resultTy,
                   loc = loc}
      | L.TLCATCH {catchLabel, argVarList, catchExp, tryExp, resultTy, loc} =>
        L.TLCATCH {catchLabel = catchLabel,
                   argVarList = argVarList,
                   catchExp = substExp (bindVars subst argVarList) catchExp,
                   tryExp = substExp subst tryExp,
                   resultTy = resultTy,
                   loc = loc}
      | L.TLPOLY {btvEnv, constraints, expTyWithoutTAbs, exp, loc} =>
        L.TLPOLY {btvEnv = btvEnv,
                  constraints = constraints,
                  expTyWithoutTAbs = expTyWithoutTAbs,
                  exp = substExp subst exp,
                  loc = loc}
      | L.TLTAPP {exp, expTy, instTyList, loc} =>
        L.TLTAPP {exp = substExp subst exp,
                  expTy = expTy,
                  instTyList = instTyList,
                  loc = loc}
      | L.TLFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        L.TLFOREIGNAPPLY {funExp = substExp subst funExp,
                          argExpList = map (substExp subst) argExpList,
                          attributes = attributes,
                          resultTy = resultTy,
                          loc = loc}
      | L.TLCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
        L.TLCALLBACKFN {attributes = attributes,
                        argVarList = argVarList,
                        bodyExp = substExp (bindVars subst argVarList) bodyExp,
                        resultTy = resultTy,
                        loc = loc}
      | L.TLCAST {exp, expTy, targetTy, cast, loc} =>
        L.TLCAST {exp = substExp subst exp,
                  expTy = expTy,
                  targetTy = targetTy,
                  cast = cast,
                  loc = loc}
      | L.TLSIZEOF _ => exp
      | L.TLINDEXOF _ => exp
      | L.TLREIFYTY _ => exp

  and substBind subst {var, exp} =
      {var = var, exp = substExp subst exp}

  and substDecl subst decl =
      case decl of
        L.TLVAL {var, exp, loc} =>
        L.TLVAL {var = var,
                 exp = substExp subst exp,
                 loc = loc}
      | L.TLVALREC (binds, loc) =>
        let
          val subst = bindVars subst (map #var binds)
        in
          L.TLVALREC (map (substBind subst) binds, loc)
        end
      | L.TLVALPOLYREC {btvEnv, constraints, recbinds, loc} =>
        let
          val subst = bindVars subst (map #var recbinds)
        in
          L.TLVALPOLYREC {btvEnv = btvEnv,
                          constraints = constraints,
                          recbinds = map (substBind subst) recbinds,
                          loc = loc}
        end
      | L.TLEXPORTVAR {weak, var, exp} =>
        L.TLEXPORTVAR {weak = weak,
                       var = var,
                       exp = substExp subst exp}
      | L.TLEXTERNVAR _ => decl

end
