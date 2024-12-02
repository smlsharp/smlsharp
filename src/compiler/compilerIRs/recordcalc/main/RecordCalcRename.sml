(**
 * @copyright (C) 2024 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure RecordCalcRename =
struct

  structure R = RecordCalc

  type subst =
      {usedVarIds : VarID.Set.set ref,
       usedBtvIds : BoundTypeVarID.Set.set ref,
       substVar : VarID.id VarID.Map.map,
       substBtv : BoundTypeVarID.id BoundTypeVarID.Map.map}

  fun freshVarId ({usedVarIds, ...} : subst) id =
      if VarID.Set.member (!usedVarIds, id)
      then VarID.generate ()
      else (usedVarIds := VarID.Set.add (!usedVarIds, id); id)

  fun freshBtvId ({usedBtvIds, ...} : subst) id =
      if BoundTypeVarID.Set.member (!usedBtvIds, id)
      then BoundTypeVarID.generate ()
      else (usedBtvIds := BoundTypeVarID.Set.add (!usedBtvIds, id); id)

  fun renameTy ({substBtv, ...} : subst) ty =
      if BoundTypeVarID.Map.isEmpty substBtv
      then ty
      else TyAlphaRename.copyTy substBtv ty

  fun renameConstraints ({substBtv, ...} : subst) constraints =
      if BoundTypeVarID.Map.isEmpty substBtv
      then constraints
      else map (TyAlphaRename.copyConstraint substBtv) constraints

  fun renameVar subst ({path, id, ty} : RecordCalc.varInfo) =
      case VarID.Map.find (#substVar subst, id) of
        NONE => raise Bug.Bug ("RCVAR " ^ VarID.toString id)
      | SOME id => {path = path, id = id, ty = renameTy subst ty}

  fun renameExVar subst ({path, ty} : RecordCalc.exVarInfo) =
      {path = path, ty = renameTy subst ty}

  fun bindVar subst ({path, id, ty} : RecordCalc.varInfo) =
      let
        val newId = freshVarId subst id
      in
        (subst # {substVar = VarID.Map.insert (#substVar subst, id, newId)},
         {path = path, id = newId, ty = renameTy subst ty})
      end

  fun bindBtv subst tid =
      let
        val newId = freshBtvId subst tid
      in
        if tid = newId then (subst, newId) else
        let
          val substBtv = BoundTypeVarID.Map.insert (#substBtv subst, tid, newId)
        in
          (subst # {substBtv = substBtv}, newId)
        end
      end

  fun bindVarList subst nil = (subst, nil)
    | bindVarList subst (var :: vars) =
      let
        val (subst, var) = bindVar subst var
        val (subst, vars) = bindVarList subst vars
      in
        (subst, var :: vars)
      end

  fun bindBtvList subst nil = (subst, nil)
    | bindBtvList subst (tid :: tids) =
      let
        val (subst, tid) = bindBtv subst tid
        val (subst, tids) = bindBtvList subst tids
      in
        (subst, tid :: tids)
      end

  fun renameBtvEnv subst btvEnv =
      let
        val tids = BoundTypeVarID.Map.listKeys btvEnv
        val (subst as {substBtv, ...}, tids) = bindBtvList subst tids
      in
        if BoundTypeVarID.Map.isEmpty substBtv then (subst, btvEnv) else
        let
          val kinds = BoundTypeVarID.Map.listItems btvEnv
          val kinds = map (TyAlphaRename.copyKind (#substBtv subst)) kinds
        in
          (subst,
           ListPair.foldlEq
             (fn (tid, kind, z) => BoundTypeVarID.Map.insert (z, tid, kind))
             BoundTypeVarID.Map.empty
             (tids, kinds))
        end
      end

  fun renameConst subst const =
      case const of
        R.INT _ => const
      | R.CONST (R.REAL64 _) => const
      | R.CONST (R.REAL32 _) => const
      | R.CONST R.UNIT => const
      | R.CONST R.NULLPOINTER => const
      | R.CONST R.NULLBOXED => const
      | R.CONST (R.FOREIGNSYMBOL {name, ty}) =>
        R.CONST (R.FOREIGNSYMBOL {name = name, ty = renameTy subst ty})
      | R.SIZE (size, ty) => R.SIZE (size, renameTy subst ty)
      | R.TAG (tag, ty) => R.TAG (tag, renameTy subst ty)

  fun renameValue subst value =
      case value of
        R.RCCONSTANT const => R.RCCONSTANT (renameConst subst const)
      | R.RCVAR var => R.RCVAR (renameVar subst var)

  fun renameExp subst exp =
      case exp of
        R.RCVALUE (value, loc) =>
        R.RCVALUE (renameValue subst value, loc)
      | R.RCSTRING _ => exp
      | R.RCEXVAR (var, loc) =>
        R.RCEXVAR (renameExVar subst var, loc)
      | R.RCFNM {argVarList, bodyTy, bodyExp, loc} =>
        let
          val (subst, argVarList) = bindVarList subst argVarList
        in
          R.RCFNM {argVarList = argVarList,
                   bodyTy = renameTy subst bodyTy,
                   bodyExp = renameExp subst bodyExp,
                   loc = loc}
        end
      | R.RCPOLY {btvEnv, constraints, expTyWithoutTAbs, exp, loc} =>
        let
          val (subst, btvEnv) = renameBtvEnv subst btvEnv
        in
          R.RCPOLY {btvEnv = btvEnv,
                    constraints = renameConstraints subst constraints,
                    expTyWithoutTAbs = renameTy subst expTyWithoutTAbs,
                    exp = renameExp subst exp,
                    loc = loc}
        end
      | R.RCAPPM {funExp, funTy, argExpList, loc} =>
        R.RCAPPM {funExp = renameExp subst funExp,
                  funTy = renameTy subst funTy,
                  argExpList = map (renameExp subst) argExpList,
                  loc = loc}
      | R.RCTAPP {exp, expTy, instTyList, loc} =>
        R.RCTAPP {exp = renameExp subst exp,
                  expTy = renameTy subst expTy,
                  instTyList = map (renameTy subst) instTyList,
                  loc = loc}
      | R.RCSWITCH {exp, expTy, branches, defaultExp, resultTy, loc} =>
        R.RCSWITCH
          {exp = renameExp subst exp,
           expTy = renameTy subst expTy,
           branches = map (fn {const, body} =>
                              {const = const,
                               body = renameExp subst body})
                          branches,
           defaultExp = renameExp subst defaultExp,
           resultTy = renameTy subst resultTy,
           loc = loc}
      | R.RCPRIMAPPLY {primOp, instTyList, instSizeList, instTagList,
                       argExpList, loc} =>
        R.RCPRIMAPPLY {primOp = primOp,
                       instTyList = map (renameTy subst) instTyList,
                       instSizeList = map (renameValue subst) instSizeList,
                       instTagList = map (renameValue subst) instTagList,
                       argExpList = map (renameExp subst) argExpList,
                       loc = loc}
      | R.RCRECORD {fields, loc} =>
        R.RCRECORD
          {fields = RecordLabel.Map.map
                      (fn {exp, ty, size, tag} =>
                          {exp = renameExp subst exp,
                           ty = renameTy subst ty,
                           size = renameValue subst size,
                           tag = renameValue subst tag})
                      fields,
           loc = loc}
      | R.RCSELECT {label, indexExp, recordExp, recordTy, resultTy, resultSize,
                    resultTag, loc} =>
        R.RCSELECT {label = label,
                    indexExp = renameExp subst indexExp,
                    recordExp = renameExp subst recordExp,
                    recordTy = renameTy subst recordTy,
                    resultTy = renameTy subst resultTy,
                    resultSize = renameValue subst resultSize,
                    resultTag = renameValue subst resultTag,
                    loc = loc}
      | R.RCMODIFY {label, indexExp, recordExp, recordTy, elementExp, elementTy,
                    elementSize, elementTag, loc} =>
        R.RCMODIFY {label = label,
                    indexExp = renameExp subst indexExp,
                    recordExp = renameExp subst recordExp,
                    recordTy = renameTy subst recordTy,
                    elementExp = renameExp subst elementExp,
                    elementSize = renameValue subst elementSize,
                    elementTag = renameValue subst elementTag,
                    elementTy = renameTy subst elementTy,
                    loc = loc}
      | R.RCLET {decl, body, loc} =>
        let
          val (subst, decl) = renameDecl subst decl
        in
          R.RCLET {decl = decl,
                   body = renameExp subst body,
                   loc = loc}
        end
      | R.RCRAISE {exp, resultTy, loc} =>
        R.RCRAISE {exp = renameExp subst exp,
                   resultTy = renameTy subst resultTy,
                   loc = loc}
      | R.RCHANDLE {exp, exnVar, handler, resultTy, loc} =>
        let
          val (subst2, exnVar) = bindVar subst exnVar
        in
          R.RCHANDLE {exp = renameExp subst exp,
                      exnVar = exnVar,
                      handler = renameExp subst2 handler,
                      resultTy = renameTy subst resultTy,
                      loc = loc}
        end
      | R.RCTHROW {catchLabel, argExpList, resultTy, loc} =>
        R.RCTHROW {catchLabel = catchLabel,
                   argExpList = map (renameExp subst) argExpList,
                   resultTy = renameTy subst resultTy,
                   loc = loc}
      | R.RCCATCH {recursive, rules, tryExp, resultTy, loc} =>
        R.RCCATCH
          {recursive = recursive,
           rules = map (fn {catchLabel, argVarList, catchExp} =>
                           let
                             val (subst2, argVarList) =
                                 bindVarList subst argVarList
                           in
                             {catchLabel = catchLabel,
                              argVarList = argVarList,
                              catchExp = renameExp subst2 catchExp}
                           end)
                       rules,
           tryExp = renameExp subst tryExp,
           resultTy = renameTy subst resultTy,
           loc = loc}
      | R.RCFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        R.RCFOREIGNAPPLY {funExp = renameExp subst funExp,
                          argExpList = map (renameExp subst) argExpList,
                          attributes = attributes,
                          resultTy = Option.map (renameTy subst) resultTy,
                          loc = loc}
      | R.RCCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
        let
          val (subst, argVarList) = bindVarList subst argVarList
        in
          R.RCCALLBACKFN {attributes = attributes,
                          argVarList = argVarList,
                          bodyExp = renameExp subst bodyExp,
                          resultTy = Option.map (renameTy subst) resultTy,
                          loc = loc}
        end
      | R.RCCAST {exp, expTy, targetTy, cast, loc} =>
        R.RCCAST {exp = renameExp subst exp,
                  expTy = renameTy subst expTy,
                  targetTy = renameTy subst targetTy,
                  cast = cast,
                  loc = loc}
      | R.RCINDEXOF {fields, label, loc} =>
        R.RCINDEXOF
          {fields = RecordLabel.Map.map
                      (fn {ty, size} =>
                          {ty = renameTy subst ty,
                           size = renameValue subst size})
                      fields,
           label = label,
           loc = loc}

  and renameDecl subst decl =
      case decl of
        R.RCVAL {var, exp, loc} =>
        let
          val (subst2, var) = bindVar subst var
        in
          (subst2,
           R.RCVAL {var = var,
                    exp = renameExp subst exp,
                    loc = loc})
        end
      | R.RCVALREC (binds, loc) =>
        let
          val (subst, vars) = bindVarList subst (map #var binds)
          val exps = map (renameExp subst o #exp) binds
          val binds = ListPair.mapEq
                        (fn (var, exp) => {var = var, exp = exp})
                        (vars, exps)
        in
          (subst, R.RCVALREC (binds, loc))
        end
      | R.RCEXPORTVAR {weak, var, exp} =>
        (subst,
         R.RCEXPORTVAR {weak = weak,
                        var = renameExVar subst var,
                        exp = renameExp subst exp})
      | R.RCEXTERNVAR (var, provider) =>
        (subst,
         R.RCEXTERNVAR (renameExVar subst var, provider))

  fun renameDeclList subst nil = nil
    | renameDeclList subst (decl :: decls) =
      let
        val (subst, decl) = renameDecl subst decl
      in
        decl :: renameDeclList subst decls
      end

  fun rename decls =
      renameDeclList
        {usedVarIds = ref VarID.Set.empty,
         usedBtvIds = ref BoundTypeVarID.Set.empty,
         substVar = VarID.Map.empty,
         substBtv = BoundTypeVarID.Map.empty}
        decls

end
