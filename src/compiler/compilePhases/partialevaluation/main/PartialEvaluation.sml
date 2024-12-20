(**
 * @copyright (C) 2024 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure PartialEvaluation =
struct

  structure R = RecordCalc
  structure T = Types
  structure RT = RuntimeTypes

  val INLINE_THRESHOLD = 20

  (* whether or not the given exp contains some side effects *)
  fun isExpansive exp =
      case exp of
        R.RCVALUE _ => false
      | R.RCSTRING _ => false
      | R.RCEXVAR _ => false
      | R.RCAPPM _ => true
      | R.RCPRIMAPPLY _ => true
      | R.RCFOREIGNAPPLY _ => true
      | R.RCFNM _ => false
      | R.RCCALLBACKFN _ => false
      | R.RCSWITCH {exp, expTy, branches, defaultExp, resultTy, loc} =>
        isExpansive exp
        orelse isExpansive defaultExp
        orelse List.exists (fn x => isExpansive (#body x)) branches
      | R.RCRECORD {fields, loc} =>
        List.exists (isExpansive o #exp) (RecordLabel.Map.listItems fields)
      | R.RCMODIFY {label, indexExp, recordExp, recordTy, elementExp,
                    elementTy, elementSize, elementTag, loc} =>
        isExpansive recordExp
        orelse isExpansive indexExp
        orelse isExpansive elementExp
      | R.RCSELECT {label, indexExp, recordExp, recordTy, resultSize, resultTag,
                    resultTy, loc} =>
        isExpansive recordExp
        orelse isExpansive indexExp
      | R.RCLET {decl, body, loc} =>
        isExpansiveDecl decl orelse isExpansive body
      | R.RCRAISE _ => true
      | R.RCHANDLE {exp, exnVar, handler, resultTy, loc} =>
        isExpansive exp orelse isExpansive handler
      | R.RCTHROW {catchLabel, argExpList, resultTy, loc} =>
        List.exists isExpansive argExpList
      | R.RCCATCH {recursive, rules, tryExp, resultTy, loc} =>
        isExpansive tryExp
        orelse List.exists (fn x => isExpansive (#catchExp x)) rules
      | R.RCCAST {exp, expTy, targetTy, cast, loc} =>
        isExpansive exp
      | R.RCINDEXOF _ => false

  and isExpansiveDecl decl =
      case decl of
        R.RCVAL {var, exp, loc} => isExpansive exp
      | R.RCVALREC (binds, loc) =>
        List.exists (fn x => isExpansive (#exp x)) binds
      | R.RCEXPORTVAR _ => true
      | R.RCEXTERNVAR _ => true

  (* count the number of applications and memory accesses *)
  fun sizeExp exp =
      case exp of
        R.RCVALUE _ => 0
      | R.RCSTRING _ => 0
      | R.RCEXVAR _ => 0
      | R.RCAPPM {funExp, funTy, instTyList, argExpList, loc} =>
        sizeExpList (funExp :: argExpList) + 1
      | R.RCPRIMAPPLY {primOp, instTyList, instSizeList, instTagList,
                       argExpList, loc} =>
        sizeExpList argExpList + 1
      | R.RCFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        sizeExpList (funExp :: argExpList) + 1
      | R.RCFNM {btvEnv, constraints, argVarList, bodyExp, bodyTy, loc} =>
        sizeExp bodyExp + 1
      | R.RCCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
        sizeExp bodyExp + 1
      | R.RCSWITCH {exp, expTy, branches, defaultExp, resultTy, loc} =>
        sizeExp exp + sizeExpList (map #body branches) + sizeExp defaultExp
      | R.RCRECORD {fields, loc} =>
        sizeExpList (map #exp (RecordLabel.Map.listItems fields)) + 1
      | R.RCMODIFY {label, indexExp, recordExp, recordTy, elementExp,
                    elementTy, elementSize, elementTag, loc} =>
        sizeExp recordExp + sizeExp indexExp + sizeExp elementExp + 1
      | R.RCSELECT {label, indexExp, recordExp, recordTy, resultSize, resultTag,
                    resultTy, loc} =>
        sizeExp recordExp + sizeExp indexExp + 1
      | R.RCLET {decl, body, loc} =>
        sizeDecl decl + sizeExp body
      | R.RCRAISE {exp, resultTy, loc} =>
        sizeExp exp + 1
      | R.RCHANDLE {exp, exnVar, handler, resultTy, loc} =>
        sizeExp exp + sizeExp handler
      | R.RCTHROW {catchLabel, argExpList, resultTy, loc} =>
        sizeExpList argExpList
      | R.RCCATCH {recursive, rules, tryExp, resultTy, loc} =>
        sizeExp tryExp + sizeExpList (map #catchExp rules)
      | R.RCCAST {exp, expTy, targetTy, cast, loc} =>
        sizeExp exp
      | R.RCINDEXOF _ => 0

  and sizeExpList exps =
      foldl (fn (x, z) => sizeExp x + z) 0 exps

  and sizeDecl decl =
      case decl of
        R.RCVAL {var, exp, loc} => sizeExp exp
      | R.RCVALREC (binds, loc) => sizeExpList (map #exp binds)
      | R.RCEXPORTVAR {weak, var, exp = SOME exp} => sizeExp exp
      | R.RCEXPORTVAR {weak, var, exp = NONE} => 0
      | R.RCEXTERNVAR _ => 0

  (* visit variables in reverse evaluation order and substitute them *)
  fun visitExp visit exp =
      case exp of
        R.RCVALUE (R.RCCONSTANT _, _) => exp
      | R.RCVALUE (R.RCVAR var, loc) =>
        (
          case visit var of
            NONE => exp
          | SOME exp => visitExp visit exp
        )
      | R.RCSTRING _ => exp
      | R.RCEXVAR _ => exp
      | R.RCFNM _ => exp
      | R.RCAPPM {funExp, funTy, instTyList, argExpList, loc} =>
        R.RCAPPM
          {argExpList = visitExpList visit argExpList, (*2*)
           funExp = visitExp visit funExp, (*1*)
           funTy = funTy,
           instTyList = instTyList,
           loc = loc}
      | R.RCSWITCH {exp, expTy, branches, defaultExp, resultTy, loc} =>
        R.RCSWITCH
          {exp = visitExp visit exp, (*1*)
           expTy = expTy,
           branches = branches,
           defaultExp = defaultExp,
           resultTy = resultTy,
           loc = loc}
      | R.RCPRIMAPPLY {primOp, instTyList, instSizeList, instTagList,
                       argExpList, loc} =>
        R.RCPRIMAPPLY
          {argExpList = visitExpList visit argExpList, (*1*)
           primOp = primOp,
           instTyList = instTyList,
           instSizeList = instSizeList,
           instTagList = instTagList,
           loc = loc}
      | R.RCRECORD {fields, loc} =>
        let
          val fields =
              RecordLabel.Map.foldri
                (fn (id, {exp, ty, size, tag}, z) =>
                    RecordLabel.Map.insert (z, id, {exp = visitExp visit exp,
                                                    ty = ty,
                                                    size = size,
                                                    tag = tag}))
                RecordLabel.Map.empty
                fields
        in
          R.RCRECORD {fields = fields, loc = loc}
        end
      | R.RCSELECT {label, indexExp, recordExp, recordTy, resultSize, resultTag,
                    resultTy, loc} =>
        R.RCSELECT {indexExp = visitExp visit indexExp, (*2*)
                    recordExp = visitExp visit recordExp, (*1*)
                    label = label,
                    recordTy = recordTy,
                    resultSize = resultSize,
                    resultTag = resultTag,
                    resultTy = resultTy,
                    loc = loc}
      | R.RCMODIFY {label, indexExp, recordExp, recordTy, elementExp,
                    elementTy, elementSize, elementTag, loc} =>
        R.RCMODIFY {elementExp = visitExp visit elementExp, (*3*)
                    indexExp = visitExp visit indexExp, (*2*)
                    recordExp = visitExp visit recordExp, (*1*)
                    label = label,
                    recordTy = recordTy,
                    elementSize = elementSize,
                    elementTag = elementTag,
                    elementTy = elementTy,
                    loc = loc}
      | R.RCLET _ => exp
      | R.RCRAISE {exp, resultTy, loc} =>
        R.RCRAISE {exp = visitExp visit exp, (*1*)
                   resultTy = resultTy,
                   loc = loc}
      | R.RCHANDLE _ => exp
      | R.RCTHROW {catchLabel, argExpList, resultTy, loc} =>
        R.RCTHROW {argExpList = visitExpList visit argExpList, (*1*)
                   catchLabel = catchLabel,
                   resultTy = resultTy,
                   loc = loc}
      | R.RCCATCH _ => exp
      | R.RCFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        R.RCFOREIGNAPPLY
          {argExpList = visitExpList visit argExpList, (*2*)
           funExp = visitExp visit funExp, (*1*)
           attributes = attributes,
           resultTy = resultTy,
           loc = loc}
      | R.RCCALLBACKFN _ => exp
      | R.RCCAST {exp, expTy, targetTy, cast, loc} =>
        R.RCCAST {exp = visitExp visit exp, (*1*)
                  expTy = expTy,
                  targetTy = targetTy,
                  cast = cast,
                  loc = loc}
      | R.RCINDEXOF _ => exp

  and visitExpList visit exps =
      let
        fun loop nil r = r
          | loop (exp :: exps) r = loop exps (visitExp visit exp :: r)
      in
        loop (rev exps) nil
      end

  (* embed decl sequence into the given exp to form a nested expression *)
  fun fillExp counts trace exp =
      let
        val next = ref trace
        fun fill ({id, ...} : RecordCalc.varInfo) =
            case !next of
              R.RCVAL {var = {id = id2, path = nil, ...}, exp, ...} :: t =>
              if id = id2
              then case VarID.Map.find (counts, id2) of
                     SOME 1 => (next := t; SOME exp)
                   | _ => NONE
              else NONE
            | _ => NONE
        val exp = visitExp fill exp
      in
        (!next, exp)
      end

  fun fillDecls counts trace =
      let
        fun loop (R.RCVAL {var, exp, loc} :: trace) decls =
            let
              val (trace, exp) = fillExp counts trace exp
              val decl = R.RCVAL {var = var, exp = exp, loc = loc}
            in
              loop trace (decl :: decls)
            end
          | loop (R.RCEXPORTVAR {weak, var, exp = SOME exp} :: trace) decls =
            let
              val (trace, exp) = fillExp counts trace exp
              val decl = R.RCEXPORTVAR {weak = weak, var = var, exp = SOME exp}
            in
              loop trace (decl :: decls)
            end
          | loop ((decl as R.RCEXPORTVAR {exp = NONE, ...}) :: trace) decls =
            loop trace (decl :: decls)
          | loop ((decl as R.RCVALREC _) :: trace) decls =
            loop trace (decl :: decls)
          | loop ((decl as R.RCEXTERNVAR _) :: trace) decls =
            loop trace (decl :: decls)
          | loop nil decls = decls
      in
        loop trace nil
      end

  fun eliminateDeadDecl counts decls =
      let
        fun getCount ({id, ...} : RecordCalc.varInfo) =
            case VarID.Map.find (counts, id) of
              NONE => 0
            | SOME n => n
      in
        List.mapPartial
          (fn decl =>
              if isExpansiveDecl decl then SOME decl else
              case decl of
                R.RCVAL {var, ...} =>
                if getCount var = 0 then NONE else SOME decl
              | R.RCVALREC (binds, loc) =>
                (case List.filter (fn x => getCount (#var x) > 0) binds of
                   nil => NONE
                 | binds => SOME (R.RCVALREC (binds, loc)))
              | _ => SOME decl)
          decls
      end

  fun declToExpList (R.RCVAL {exp, ...}) = [exp]
    | declToExpList (R.RCVALREC (binds, _)) = map #exp binds
    | declToExpList (R.RCEXPORTVAR {exp = SOME exp, ...}) = [exp]
    | declToExpList (R.RCEXPORTVAR {exp = NONE, ...}) = []
    | declToExpList (R.RCEXTERNVAR _) = []

  fun declsToExpList decls =
      foldl (fn (decl, exps) => declToExpList decl @ exps) nil decls

  fun reconstructDecls trace =
      let
        val counts = RecordCalcFv.fvExpList (declsToExpList trace)
        val trace = eliminateDeadDecl counts trace
      in
        fillDecls counts trace
      end

  fun reconstructExp trace exp =
      let
        val counts = RecordCalcFv.fvExpList (exp :: declsToExpList trace)
        val trace = eliminateDeadDecl counts trace
        val (trace, exp) = fillExp counts trace exp
        val decls = fillDecls counts trace
        fun Let (decl, body) =
            R.RCLET {decl = decl,
                     body = body,
                     loc = RecordCalcLoc.locDecl decl}
      in
        foldr Let exp decls
      end

  fun upperCast (_, R.BitCast) = R.BitCast
    | upperCast (R.BitCast, _) = R.BitCast
    | upperCast (R.TypeCast, R.TypeCast) = R.TypeCast

  datatype 'a result =
      RET of 'a
    | ABORT of RecordCalc.rcexp

  datatype object =
      OBJ of RecordCalc.rcexp
    | ANY

  type trace =
      {trace : RecordCalc.rcdecl list, (* reverse order *)
       heap : object VarID.Map.map}

  type env =
      {varEnv : RecordCalc.rcexp VarID.Map.map,
       btvEnv : Types.btvEnv,
       derefMask : VarID.Set.set}

  fun mask (env as {derefMask, ...} : env) ({id, ...} : RecordCalc.varInfo) =
      env # {derefMask = VarID.Set.add (derefMask, id)}

  fun bindVar (env as {varEnv, ...} : env) (var : RecordCalc.varInfo) valueExp =
      env # {varEnv = VarID.Map.insert (varEnv, #id var, valueExp)}

  fun bindVars env nil nil = env
    | bindVars env (var :: vars) (valueExp :: valueExps) =
      bindVars (bindVar env var valueExp) vars valueExps
    | bindVars _ _ _ = raise Bug.Bug "bindVars"

  fun addBtvEnv (env : env) btvEnv =
      env # {btvEnv = BoundTypeVarID.Map.unionWith #2 (#btvEnv env, btvEnv)}

  fun instMap (btvEnv : Types.btvEnv) (instTyList : Types.ty list) =
      ListPair.foldlEq
        (fn (tid, ty, z) => BoundTypeVarID.Map.insert (z, tid, ty))
        BoundTypeVarID.Map.empty
        (BoundTypeVarID.Map.listKeys btvEnv, instTyList)
      handle ListPair.UnequalLengths => raise Bug.Bug "instMap"

  fun emitExp ({trace, heap} : trace) path exp object =
      let
        val ty = RecordCalcType.typeOfExp exp
        val var = {id = VarID.generate (), path = path, ty = ty}
        val loc = RecordCalcLoc.locExp exp
        val decl = R.RCVAL {var = var, exp = exp, loc = loc}
        val heap = VarID.Map.insert (heap, #id var, object)
      in
        ({trace = decl :: trace, heap = heap}, R.RCVALUE (R.RCVAR var, loc))
      end

  fun emitResult t path exp object =
      let
        val (t, valueExp) = emitExp t path exp object
      in
        (t, RET valueExp)
      end

  fun removeCast (R.RCCAST {exp, ...}) = removeCast exp
    | removeCast exp = exp

  fun copyCast (R.RCCAST {exp, expTy, targetTy, cast, loc}) to =
      R.RCCAST {exp = copyCast exp to,
                expTy = expTy,
                targetTy = targetTy,
                cast = cast,
                loc = loc}
    | copyCast _ to = to

  fun eqTy ty1 ty2 =
      Unify.eqTy BoundTypeVarID.Map.empty (ty1, ty2)

  fun deref (trace : trace) (env : env) valueExp valueTy =
      case valueExp of
        R.RCCAST {exp, ...} => deref trace env exp valueTy
      | R.RCVALUE (R.RCVAR var, _) =>
        (case VarID.Map.find (#heap trace, #id var) of
           NONE => raise Bug.Bug ("deref " ^ VarID.toString (#id var))
         | SOME ANY => (env, ANY)
         | SOME (OBJ objExp) =>
           if eqTy valueTy (RecordCalcType.typeOfExp objExp)
           then (mask env var,
                 if VarID.Set.member (#derefMask env, #id var)
                 then ANY
                 else OBJ objExp)
           else (env, ANY))
      | _ => (env, ANY)

  fun addBoundVar loc (trace : trace) (env as {varEnv, ...}) var =
      let
        val newId = VarID.generate ()
        val ty = TyRevealTy.revealTy (#ty var)
        val newVar = var # {id = newId, ty = ty} : RecordCalc.varInfo
        val valueExp = R.RCVALUE (R.RCVAR newVar, loc)
        val heap = VarID.Map.insert (#heap trace, newId, ANY)
      in
        ({trace = #trace trace, heap = heap},
         env # {varEnv = VarID.Map.insert (varEnv, #id var, valueExp)},
         newVar)
      end

  fun addBoundVars loc t env nil = (t, env, nil)
    | addBoundVars loc t env (var :: vars) =
      let
        val (t, env, var) = addBoundVar loc t env var
        val (t, env, vars) = addBoundVars loc t env vars
      in
        (t, env, var :: vars)
      end

  fun evalValue t env value =
      case value of
        R.RCCONSTANT _ => (t, value)
      | R.RCVAR var =>
        case VarID.Map.find (#varEnv env, #id var) of
          NONE =>
          if VarID.Map.inDomain (#heap t, #id var)
          then (t, value)
          else raise Bug.Bug "evalValue"
        | SOME (R.RCVALUE (value, _)) => (t, value)
        | SOME exp =>
          case emitExp t nil exp ANY of
            (t, R.RCVALUE (value, _)) => (t, value)
          | _ => raise Bug.Bug "evalValue"

  fun evalValueList t env nil = (t, nil)
    | evalValueList t env (value :: values) =
      let
        val (t, value) = evalValue t env value
        val (t, values) = evalValueList t env values
      in
        (t, value :: values)
      end

  fun checkSolidRecordTy ({btvEnv, ...} : env) recordTy =
      case TypesBasics.revealTy recordTy of
        T.RECORDty fields =>
        let
          exception NotSolid
        in
          SOME (RecordLabel.Map.map
                  (fn ty =>
                      case TypeLayout2.propertyOf btvEnv ty of
                        NONE => raise Bug.Bug "tagOf"
                      | SOME {tag = RT.ANYTAG, ...} => raise NotSolid
                      | SOME {size = RT.ANYSIZE, ...} => raise NotSolid
                      | SOME {tag = RT.TAG tag, size = RT.SIZE size, ...} =>
                        {ty = ty,
                         tag = R.RCCONSTANT (R.TAG (tag, ty)),
                         size = R.RCCONSTANT (R.SIZE (size, ty))})
                  fields)
          handle NotSolid => NONE
        end
      | _ => NONE

  fun emitModify t env path {label, indexExp, recordExp, recordTy, elementExp,
                             elementTy, elementSize, elementTag, loc} =
      case deref t env recordExp recordTy of
        (env, OBJ (R.RCRECORD {fields, loc = _})) =>
        let
          val field = {exp = elementExp,
                       ty = elementTy,
                       size = elementSize,
                       tag = elementTag}
          val fields = RecordLabel.Map.insert (fields, label, field)
          val resultExp = R.RCRECORD {fields = fields, loc = loc}
          val (t, valueExp) = emitExp t path resultExp (OBJ resultExp)
        in
          (t, RET (copyCast recordExp valueExp))
        end
      | _ =>
        case checkSolidRecordTy env recordTy of
          NONE =>
          let
            val resultTy = R.RCMODIFY {label = label,
                                       indexExp = indexExp,
                                       recordExp = recordExp,
                                       recordTy = recordTy,
                                       elementExp = elementExp,
                                       elementTy = elementTy,
                                       elementSize = elementSize,
                                       elementTag = elementTag,
                                       loc = loc}
          in
            emitResult t path resultTy ANY
          end
        | SOME fields =>
          let
            val indexofFields =
                RecordLabel.Map.map
                  (fn {ty, size, ...} => {ty = ty, size = size})
                  fields
            val elementField =
                {exp = elementExp,
                 ty = elementTy,
                 size = elementSize,
                 tag = elementTag}
            fun selectExp label {ty, size, tag} =
                R.RCSELECT {label = label,
                            indexExp = R.RCINDEXOF {label = label,
                                                    fields = indexofFields,
                                                    loc = loc},
                            recordExp = recordExp,
                            recordTy = recordTy,
                            resultTy = ty,
                            resultSize = size,
                            resultTag = tag,
                            loc = loc}
            val (t, recordFields) =
                RecordLabel.Map.foldli
                  (fn (label2, field as {ty, size, tag}, (t, z)) =>
                      if label = label2
                      then (t, RecordLabel.Map.insert (z, label2, elementField))
                      else
                        let
                          val exp = selectExp label2 field
                          val (t, v) = emitExp t nil exp ANY
                          val field = {ty = ty, size = size, tag = tag, exp = v}
                        in
                          (t, RecordLabel.Map.insert (z, label2, field))
                        end)
                  (t, RecordLabel.Map.empty)
                  fields
            val resultExp = R.RCRECORD {fields = recordFields, loc = loc}
          in
            emitResult t path resultExp (OBJ resultExp)
          end

  fun evalBody t env exp expTy =
      let
        val (t, exp) = evalExp (t # {trace = nil}) env nil exp
        val exp =
            case exp of
              RET exp => exp
            | ABORT (R.RCRAISE {exp, resultTy, loc}) =>
              R.RCRAISE {exp = exp, resultTy = expTy, loc = loc}
            | ABORT exp => exp
      in
        reconstructExp (#trace t) exp
      end

  and evalExp t env path exp =
      case exp of
        R.RCVALUE (R.RCCONSTANT _, _) => (t, RET exp)
      | R.RCVALUE (R.RCVAR var, loc) =>
        (
          case VarID.Map.find (#varEnv env, #id var) of
            SOME valueExp => (t, RET valueExp)
          | NONE =>
            if VarID.Map.inDomain (#heap t, #id var)
            then (t, RET exp)
            else raise Bug.Bug ("evalExp: RCVAR " ^ VarID.toString (#id var))
        )
      | R.RCSTRING _ => (t, RET exp)
      | R.RCEXVAR _ => (t, RET exp)
      | R.RCFNM {btvEnv, constraints, argVarList, bodyTy, bodyExp, loc} =>
        let
          val env2 = addBtvEnv env btvEnv
          val (t2, env2, argVarList) = addBoundVars loc t env2 argVarList
          val bodyExp = evalBody t2 env2 bodyExp bodyTy
          val resultExp = R.RCFNM {btvEnv = btvEnv,
                                   constraints = constraints,
                                   argVarList = argVarList,
                                   bodyTy = bodyTy,
                                   bodyExp = bodyExp,
                                   loc = loc}
          val object =
              if sizeExp bodyExp <= INLINE_THRESHOLD
              then OBJ resultExp
              else ANY
        in
          emitResult t path resultExp object
        end
      | R.RCAPPM {funExp = R.RCFNM {btvEnv, argVarList, bodyExp, ...},
                  funTy, instTyList, argExpList, loc} =>
        (
          case evalExpList t env argExpList of
            (t, ABORT a) => (t, ABORT a)
          | (t, RET argExpList) =>
            let
              val subst = instMap btvEnv instTyList
              val bodyExp = if BoundTypeVarID.Map.isEmpty subst
                            then bodyExp
                            else RecordCalcType.instantiateExp subst bodyExp
              val env = bindVars env argVarList argExpList
            in
              evalExp t env path bodyExp
            end
        )
      | R.RCAPPM {funExp, funTy, instTyList, argExpList, loc} =>
        (
          case evalExp t env nil funExp of
            (t, ABORT a) => (t, ABORT a)
          | (t, RET funExp) =>
            case evalExpList t env argExpList of
              (t, ABORT a) => (t, ABORT a)
            | (t, RET argExpList) =>
              case deref t env funExp funTy of
                (env, OBJ (R.RCFNM {btvEnv, argVarList, bodyExp, ...})) =>
                let
                  val subst = instMap btvEnv instTyList
                  val bodyExp = if BoundTypeVarID.Map.isEmpty subst
                                then bodyExp
                                else RecordCalcType.instantiateExp subst bodyExp
                  val env = env # {varEnv = VarID.Map.empty}
                  val env = bindVars env argVarList argExpList
                in
                  evalExp t env path bodyExp
                end
              | _ =>
                let
                  val resultExp = R.RCAPPM {funExp = funExp,
                                            funTy = funTy,
                                            instTyList = instTyList,
                                            argExpList = argExpList,
                                            loc = loc}
                in
                  emitResult t path resultExp ANY
                end
        )
      | R.RCSWITCH {exp, expTy, branches, defaultExp, resultTy, loc} =>
        (
          case evalExp t env nil exp of
            (t, ABORT a) => (t, ABORT a)
          | (t, RET exp) =>
            case removeCast exp of
              R.RCVALUE (R.RCCONSTANT (R.INT int), _) =>
              (case List.find (fn b => #const b = int) branches of
                 SOME {body, ...} => evalExp t env path body
               | NONE => evalExp t env path defaultExp)
            | _ =>
              let
                val branches = map (fn {const, body} =>
                                       {const = const,
                                        body = evalBody t env body resultTy})
                                   branches
                val defaultExp = evalBody t env defaultExp resultTy
                val resultExp = R.RCSWITCH {exp = exp,
                                            expTy = expTy,
                                            branches = branches,
                                            defaultExp = defaultExp,
                                            resultTy = resultTy,
                                            loc = loc}
              in
                emitResult t path resultExp ANY
              end
        )
      | R.RCPRIMAPPLY {primOp, instTyList, instSizeList, instTagList,
                       argExpList, loc} =>
        (
          case evalExpList t env argExpList of
            (t, ABORT a) => (t, ABORT a)
          | (t, RET argExpList) =>
            let
              val (t, instSizeList) = evalValueList t env instSizeList
              val (t, instTagList) = evalValueList t env instTagList
            in
              case PartialEvaluatePrimitive.eval primOp argExpList loc of
                SOME valueExp => (t, RET valueExp)
              | NONE =>
                let
                  val resultExp = R.RCPRIMAPPLY {primOp = primOp,
                                                 instTyList = instTyList,
                                                 instSizeList = instSizeList,
                                                 instTagList = instTagList,
                                                 argExpList = argExpList,
                                                 loc = loc}
                in
                  emitResult t path resultExp ANY
                end
            end
        )
      | R.RCRECORD {fields, loc} =>
        (
          case evalRecordFields t env fields of
            (t, ABORT a) => (t, ABORT a)
          | (t, RET fields) =>
            let
              val resultExp = R.RCRECORD {fields = fields, loc = loc}
            in
              emitResult t path resultExp (OBJ resultExp)
            end
        )
      | R.RCSELECT {label, indexExp, recordExp, recordTy, resultTy, resultSize,
                    resultTag, loc} =>
        (
          case evalExp t env nil recordExp of
            (t, ABORT a) => (t, ABORT a)
          | (t, RET recordExp) =>
            case evalExp t env nil indexExp of
              (t, ABORT a) => (t, ABORT a)
            | (t, RET indexExp) =>
              let
                val (t, resultSize) = evalValue t env resultSize
                val (t, resultTag) = evalValue t env resultTag
              in
                case deref t env recordExp recordTy of
                  (env, OBJ (objExp as R.RCRECORD {fields, loc})) =>
                  (
                    case RecordLabel.Map.find (fields, label) of
                      NONE => raise Bug.Bug "evalExp: RCSELECT"
                    | SOME {exp, ...} => (t, RET exp)
                  )
                | _ =>
                  let
                    val resultExp = R.RCSELECT {label = label,
                                                indexExp = indexExp,
                                                recordExp = recordExp,
                                                recordTy = recordTy,
                                                resultTy = resultTy,
                                                resultSize = resultSize,
                                                resultTag = resultTag,
                                                loc = loc}
                  in
                    emitResult t path resultExp ANY
                  end
              end
        )
      | R.RCMODIFY {label, indexExp, recordExp, recordTy, elementExp, elementTy,
                    elementSize, elementTag, loc} =>
        (
          case evalExp t env nil recordExp of
            (t, ABORT a) => (t, ABORT a)
          | (t, RET recordExp) =>
            case evalExp t env nil indexExp of
              (t, ABORT a) => (t, ABORT a)
            | (t, RET indexExp) =>
              case evalExp t env nil elementExp of
                (t, ABORT a) => (t, ABORT a)
              | (t, RET elementExp) =>
                let
                  val (t, elementSize) = evalValue t env elementSize
                  val (t, elementTag) = evalValue t env elementTag
                in
                  emitModify t env path {label = label,
                                         indexExp = indexExp,
                                         recordExp = recordExp,
                                         recordTy = recordTy,
                                         elementExp = elementExp,
                                         elementTy = elementTy,
                                         elementSize = elementSize,
                                         elementTag = elementTag,
                                         loc = loc}
                end
        )
      | R.RCLET {decl, body, loc} =>
        (
          case evalDecl t env decl of
            (t, ABORT a) => (t, ABORT a)
          | (t, RET env) => evalExp t env path body
        )
      | R.RCRAISE {exp, resultTy, loc} =>
        (
          case evalExp t env nil exp of
            (t, ABORT a) => (t, ABORT a)
          | (t, RET exp) =>
            (t, ABORT (R.RCRAISE {exp = exp,
                                  resultTy = resultTy,
                                  loc = loc}))
        )
      | R.RCHANDLE {exp, exnVar, handler, resultTy, loc} =>
        let
          val exp = evalBody t env exp resultTy
          val (t2, env2, exnVar) = addBoundVar loc t env exnVar
          val handler = evalBody t2 env2 handler resultTy
          val resultExp = R.RCHANDLE {exp = exp,
                                      exnVar = exnVar,
                                      handler = handler,
                                      resultTy = resultTy,
                                      loc = loc}
        in
          emitResult t path resultExp ANY
        end
      | R.RCTHROW {catchLabel, argExpList, resultTy, loc} =>
        (
          case evalExpList t env argExpList of
            (t, ABORT a) => (t, ABORT a)
          | (t, RET argExpList) =>
            (t, ABORT (R.RCTHROW {catchLabel = catchLabel,
                                  argExpList = argExpList,
                                  resultTy = resultTy,
                                  loc = loc}))
        )
      | R.RCCATCH {recursive, rules, tryExp, resultTy, loc} =>
        let
          val tryExp = evalBody t env tryExp resultTy
          val rules =
              map (fn {catchLabel, argVarList, catchExp} =>
                      let
                        val (t, env, argVarList) =
                            addBoundVars loc t env argVarList
                      in
                        {catchLabel = catchLabel,
                         argVarList = argVarList,
                         catchExp = evalBody t env catchExp resultTy}
                      end)
                  rules
          val resultExp = R.RCCATCH {recursive = recursive,
                                     rules = rules,
                                     tryExp = tryExp,
                                     resultTy = resultTy,
                                     loc = loc}
        in
          emitResult t path resultExp ANY
        end
      | R.RCFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        (
          case evalExp t env nil funExp of
            (t, ABORT a) => (t, ABORT a)
          | (t, RET funExp) =>
            case evalExpList t env argExpList of
              (t, ABORT a) => (t, ABORT a)
            | (t, RET argExpList) =>
              let
                val resultExp = R.RCFOREIGNAPPLY {funExp = funExp,
                                                  argExpList = argExpList,
                                                  attributes = attributes,
                                                  resultTy = resultTy,
                                                  loc = loc}
              in
                emitResult t path resultExp ANY
              end
        )
      | R.RCCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
        let
          val (t2, env2, argVarList) = addBoundVars loc t env argVarList
          val bodyTy = case resultTy of
                         NONE => BuiltinTypes.unitTy
                       | SOME ty => ty
          val bodyExp = evalBody t2 env2 bodyExp bodyTy
          val resultExp = R.RCCALLBACKFN {attributes = attributes,
                                          argVarList = argVarList,
                                          bodyExp = bodyExp,
                                          resultTy = resultTy,
                                          loc = loc}
        in
          emitResult t path resultExp ANY
        end
      | R.RCCAST {exp, expTy, targetTy, cast, loc} =>
        (
          case evalExp t env nil exp of
            (t, ABORT a) => (t, ABORT a)
          | (t, RET (R.RCCAST c)) =>
            (t, RET (R.RCCAST {exp = #exp c,
                               expTy = #expTy c,
                               targetTy = targetTy,
                               cast = upperCast (cast, #cast c),
                               loc = loc}))
          | (t, RET exp) =>
            (t, RET (R.RCCAST {exp = exp,
                               expTy = expTy,
                               targetTy = targetTy,
                               cast = cast,
                               loc = loc}))
        )
      | R.RCINDEXOF {fields, label, loc} =>
        let
          val (t, fields) = evalIndexofFields t env fields
          val resultExp = R.RCINDEXOF {fields = fields,
                                      label = label,
                                      loc = loc}
        in
          emitResult t path resultExp ANY
        end

  and evalExpList t env nil = (t, RET nil)
    | evalExpList t env (exp :: exps) =
      case evalExp t env nil exp of
        (t, ABORT a) => (t, ABORT a)
      | (t, RET exp) =>
        case evalExpList t env exps of
          (t, ABORT a) => (t, ABORT a)
        | (t, RET exps) => (t, RET (exp :: exps))

  and evalRecordFields t env fields =
      let
        fun eval t env nil = (t, RET RecordLabel.Map.empty)
          | eval t env ((label, {exp, ty, size, tag}) :: fields) =
            case evalExp t env nil exp of
              (t, ABORT a) => (t, ABORT a)
            | (t, RET exp) =>
              let
                val (t, size) = evalValue t env size
                val (t, tag) = evalValue t env tag
              in
                case eval t env fields of
                  (t, ABORT a) => (t, ABORT a)
                | (t, RET fields) =>
                  let
                    val field = {exp = exp, ty = ty, size = size, tag = tag}
                  in
                    (t, RET (RecordLabel.Map.insert (fields, label, field)))
                  end
              end
      in
        eval t env (RecordLabel.Map.listItemsi fields)
      end

  and evalIndexofFields t env fields =
      let
        fun eval t env nil = (t, RecordLabel.Map.empty)
          | eval t env ((label, {ty, size}) :: fields) =
            let
              val (t, size) = evalValue t env size
              val (t, fields) = eval t env fields
              val field = {ty = ty, size = size}
            in
              (t, RecordLabel.Map.insert (fields, label, field))
            end
      in
        eval t env (RecordLabel.Map.listItemsi fields)
      end

  and evalDecl t env decl =
      case decl of
        R.RCVAL {var, exp, loc} =>
        (
          case evalExp t env (#path var) exp of
            (t, ABORT a) => (t, ABORT a)
          | (t, RET exp) =>
            let
              val varEnv = VarID.Map.insert (#varEnv env, #id var, exp)
            in
              (t, RET (env # {varEnv = varEnv}))
            end
        )
      | R.RCVALREC (binds, loc) =>
        let
          fun updateHeap ({var, exp}, heap) =
              if (case exp of
                    R.RCFNM {bodyExp, ...} =>
                    sizeExp bodyExp <= INLINE_THRESHOLD
                  | _ => false)
              then VarID.Map.insert (heap, #id var, OBJ exp)
              else heap

          (* evaluate each expressions at first *)
          val (t, env, vars) = addBoundVars loc t env (map #var binds)
          val exps = map (fn {var, exp} => evalBody t env exp (#ty var)) binds
          val binds2 = ListPair.mapEq
                         (fn (var, exp) => {var = var, exp = exp})
                         (vars, exps)

          (* evaluate again for inlining recursive functions *)
          val t2 = t # {heap = foldl updateHeap (#heap t) binds2}
          val env2 = env # {varEnv = VarID.Map.empty}
          val binds2 =
              map (fn {var, exp} =>
                      {var = var,
                       exp = evalBody t2 (mask env2 var) exp (#ty var)})
                  binds2

          (* allow further inlining only of non-recursive functions *)
          val decls = RecordCalcValRec.decompose (binds2, loc)
          val heap =
              foldl (fn (R.RCVAL {var, exp, ...}, heap) =>
                        updateHeap ({var = var, exp = exp}, heap)
                      | (_, heap) => heap)
                    (#heap t)
                    decls
        in
          ({trace = List.revAppend (decls, #trace t), heap = heap}, RET env)
        end
      | R.RCEXPORTVAR {weak, var, exp = SOME exp} =>
        (
          case evalExp t env nil exp of
            (t, ABORT a) => (t, ABORT a)
          | (t, RET exp) =>
            let
              val decl = R.RCEXPORTVAR {weak = weak, var = var, exp = SOME exp}
            in
              (t # {trace = decl :: #trace t}, RET env)
            end
        )
      | R.RCEXPORTVAR {exp = NONE, ...} =>
        (t # {trace = decl :: #trace t}, RET env)
      | R.RCEXTERNVAR _ =>
        (t # {trace = decl :: #trace t}, RET env)

  fun evalDecls t env nil = t
    | evalDecls t env (decl :: decls) =
      case evalDecl t env decl of
        (t, RET env) => evalDecls t env decls
      | (t, ABORT a) =>
        let
          val (t, _) = emitExp t nil a ANY
          val exports =
              List.mapPartial
                (fn R.RCEXPORTVAR {weak, var, exp} =>
                    SOME (R.RCEXPORTVAR {weak = weak, var = var, exp = NONE})
                  | _ => NONE)
                decls
        in
          t # {trace = List.revAppend (exports, #trace t)}
        end

  fun compile decls =
      let
        val t = {trace = nil, heap = VarID.Map.empty} : trace
        val env = {varEnv = VarID.Map.empty,
                   btvEnv = BoundTypeVarID.Map.empty,
                   derefMask = VarID.Set.empty} : env
        val {trace, ...} = evalDecls t env decls
      in
        reconstructDecls trace
      end

end
