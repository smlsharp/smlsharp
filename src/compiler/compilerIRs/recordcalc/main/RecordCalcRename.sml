(**
 * @copyright (C) 2024 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure RecordCalcRename =
struct

  structure R = RecordCalc
  structure T = Types

  type subst =
      {usedVarIds : VarID.Set.set ref,
       usedBtvIds : BoundTypeVarID.Set.set ref,
       substVar : (VarID.id * Types.ty) VarID.Map.map,
       substBtv : Types.ty BoundTypeVarID.Map.map}

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
      else TypesBasics.substBTvar substBtv ty

  fun renameVar subst (var as {id, ...} : RecordCalc.varInfo) =
      case VarID.Map.find (#substVar subst, id) of
        NONE => raise Bug.Bug ("RCVAR " ^ VarID.toString id)
      | SOME (id, ty) => var # {id = id, ty = ty}

  fun bindVar subst (var as {id, ty, ...} : RecordCalc.varInfo) =
      let
        val newId = freshVarId subst id
        val ty = renameTy subst ty
        val substVar = VarID.Map.insert (#substVar subst, id, (newId, ty))
      in
        (subst # {substVar = substVar}, var # {id = newId, ty = ty})
      end

  fun bindVarList subst nil = (subst, nil)
    | bindVarList subst (var :: vars) =
      let
        val (subst, var) = bindVar subst var
        val (subst, vars) = bindVarList subst vars
      in
        (subst, var :: vars)
      end

  fun bindBtv subst tid =
      let
        val newId = freshBtvId subst tid
      in
        if tid = newId then (subst, newId) else
        let
          val substBtv = BoundTypeVarID.Map.insert
                           (#substBtv subst, tid, T.BOUNDVARty newId)
        in
          (subst # {substBtv = substBtv}, newId)
        end
      end

  fun bindBtvList subst nil = (subst, nil)
    | bindBtvList subst (tid :: tids) =
      let
        val (subst, tid) = bindBtv subst tid
        val (subst, tids) = bindBtvList subst tids
      in
        (subst, tid :: tids)
      end

  fun renameBtvEnv subst btvEnv constraints =
      let
        val tids = BoundTypeVarID.Map.listKeys btvEnv
        val (subst as {substBtv, ...}, tids) = bindBtvList subst tids
      in
        if BoundTypeVarID.Map.isEmpty substBtv
        then (subst, btvEnv, constraints)
        else
          let
            val newBtvEnv =
                ListPair.foldlEq
                  (fn (id, kind, z) => BoundTypeVarID.Map.insert (z, id, kind))
                  BoundTypeVarID.Map.empty
                  (tids, BoundTypeVarID.Map.listItems btvEnv)
            val polyTy = T.POLYty {boundtvars = newBtvEnv,
                                   constraints = constraints,
                                   body = T.ERRORty}
            val polyTy = TypesBasics.substBTvar substBtv polyTy
            val {boundtvars = newBtvEnv, constraints, ...} =
                case TypesBasics.derefTy polyTy of
                  T.POLYty poly => poly
                | _ => raise Bug.Bug "renameBtvEnv"
          in
            (subst, newBtvEnv, constraints)
          end
      end

  fun renameTlconst subst const =
      case const of
        R.REAL64 _ => const
      | R.REAL32 _ => const
      | R.UNIT => const
      | R.NULLPOINTER => const
      | R.NULLBOXED => const
      | R.FOREIGNSYMBOL {name, ty} =>
        R.FOREIGNSYMBOL {name = name, ty = renameTy subst ty}

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
      | R.RCEXVAR _ => exp
      | R.RCFNM {btvEnv, constraints, argVarList, bodyTy, bodyExp, loc} =>
        let
          val (subst, btvEnv, constraints) =
              renameBtvEnv subst btvEnv constraints
          val (subst, argVarList) = bindVarList subst argVarList
          val bodyExp = renameExp subst bodyExp
        in
          R.RCFNM {btvEnv = btvEnv,
                   constraints = constraints,
                   argVarList = argVarList,
                   bodyExp = bodyExp,
                   bodyTy = RecordCalcType.typeOfExp bodyExp,
                   loc = loc}
        end
      | R.RCAPPM {funExp, funTy, instTyList, argExpList, loc} =>
        let
          val funExp = renameExp subst funExp
        in
          R.RCAPPM {funExp = funExp,
                    funTy = RecordCalcType.typeOfExp funExp,
                    instTyList = map (renameTy subst) instTyList,
                    argExpList = map (renameExp subst) argExpList,
                    loc = loc}
        end
      | R.RCSWITCH {exp, expTy, branches, defaultExp, resultTy, loc} =>
        let
          val exp = renameExp subst exp
          val defaultExp = renameExp subst defaultExp
        in
          R.RCSWITCH
            {exp = exp,
             expTy = RecordCalcType.typeOfExp exp,
             branches = map (fn {const, body} =>
                                {const = const,
                                 body = renameExp subst body})
                            branches,
             defaultExp = defaultExp,
             resultTy = RecordCalcType.typeOfExp defaultExp,
             loc = loc}
        end
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
                          let
                            val exp = renameExp subst exp
                          in
                            {exp = exp,
                             ty = RecordCalcType.typeOfExp exp,
                             size = renameValue subst size,
                             tag = renameValue subst tag}
                          end)
                      fields,
           loc = loc}
      | R.RCSELECT {label, indexExp, recordExp, recordTy, resultTy, resultSize,
                    resultTag, loc} =>
        let
          val recordExp = renameExp subst recordExp
        in
          R.RCSELECT {label = label,
                      indexExp = renameExp subst indexExp,
                      recordExp = recordExp,
                      recordTy = RecordCalcType.typeOfExp recordExp,
                      resultTy = renameTy subst resultTy,
                      resultSize = renameValue subst resultSize,
                      resultTag = renameValue subst resultTag,
                      loc = loc}
        end
      | R.RCMODIFY {label, indexExp, recordExp, recordTy, elementExp, elementTy,
                    elementSize, elementTag, loc} =>
        let
          val recordExp = renameExp subst recordExp
          val elementExp = renameExp subst elementExp
        in
          R.RCMODIFY {label = label,
                      indexExp = renameExp subst indexExp,
                      recordExp = recordExp,
                      recordTy = RecordCalcType.typeOfExp recordExp,
                      elementExp = elementExp,
                      elementSize = renameValue subst elementSize,
                      elementTag = renameValue subst elementTag,
                      elementTy = RecordCalcType.typeOfExp elementExp,
                      loc = loc}
        end
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
          val exp = renameExp subst exp
        in
          R.RCHANDLE {exp = exp,
                      exnVar = exnVar,
                      handler = renameExp subst2 handler,
                      resultTy = RecordCalcType.typeOfExp exp,
                      loc = loc}
        end
      | R.RCTHROW {catchLabel, argExpList, resultTy, loc} =>
        R.RCTHROW {catchLabel = catchLabel,
                   argExpList = map (renameExp subst) argExpList,
                   resultTy = renameTy subst resultTy,
                   loc = loc}
      | R.RCCATCH {recursive, rules, tryExp, resultTy, loc} =>
        let
          val tryExp = renameExp subst tryExp
        in
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
             tryExp = tryExp,
             resultTy = RecordCalcType.typeOfExp tryExp,
             loc = loc}
        end
      | R.RCFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        R.RCFOREIGNAPPLY {funExp = renameExp subst funExp,
                          argExpList = map (renameExp subst) argExpList,
                          attributes = attributes,
                          resultTy = Option.map (renameTy subst) resultTy,
                          loc = loc}
      | R.RCCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
        let
          val (subst, argVarList) = bindVarList subst argVarList
          val bodyExp = renameExp subst bodyExp
          val resultTy = case resultTy of
                           NONE => NONE
                         | SOME _ => SOME (RecordCalcType.typeOfExp bodyExp)
        in
          R.RCCALLBACKFN {attributes = attributes,
                          argVarList = argVarList,
                          bodyExp = bodyExp,
                          resultTy = resultTy,
                          loc = loc}
        end
      | R.RCCAST {exp, expTy, targetTy, cast, loc} =>
        let
          val exp = renameExp subst exp
        in
          R.RCCAST {exp = exp,
                    expTy = RecordCalcType.typeOfExp exp,
                    targetTy = renameTy subst targetTy,
                    cast = cast,
                    loc = loc}
        end
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
        R.RCVAL {var as {id, ...}, exp, loc} =>
        let
          val exp = renameExp subst exp
          val newId = freshVarId subst id
          val ty = RecordCalcType.typeOfExp exp
          val substVar = VarID.Map.insert (#substVar subst, id, (newId, ty))
        in
          (subst # {substVar = substVar},
           R.RCVAL {var = var # {id = newId, ty = ty},
                    exp = exp,
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
        let
          val exp = renameExp subst exp
        in
          (subst,
           R.RCEXPORTVAR {weak = weak,
                          var = var # {ty = RecordCalcType.typeOfExp exp},
                          exp = exp})
        end
      | R.RCEXTERNVAR _ => (subst, decl)

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
