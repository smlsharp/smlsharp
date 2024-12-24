(**
 * @copyright (C) 2024 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure CallAnalysis =
struct

  structure R = RecordCalc

  type arg = Types.ty list * RecordCalc.rcexp list * RecordCalc.loc
  type abs = Types.btvEnv * Types.constraint list * RecordCalc.varInfo list

  fun getAppSpine exp =
      let
        fun loop (R.RCAPPM {funExp, funTy, instTyList, argExpList, loc}) _ t =
            loop funExp (SOME funTy) ((instTyList, argExpList, loc) :: t)
          | loop exp expTy spine =
            (exp, expTy, spine)
      in
        loop exp NONE nil
      end

  fun getFnSpine exp =
      let
        fun loop (R.RCFNM {btvEnv, constraints, argVarList, bodyTy, bodyExp,
                           loc})
                 spine =
            loop bodyExp ((btvEnv, constraints, argVarList) :: spine)
          | loop exp spine =
            (rev spine, exp)
      in
        loop exp nil
      end

  datatype caller = FN of VarID.id | ANON | TOPLEVEL
  datatype pos = CALL | TAIL
  type call = caller * pos * arg list
  type call_graph = call list VarID.Map.map
  type result = {var : RecordCalc.varInfo,
                 loc : RecordCalc.loc,
                 absList : abs list,
                 calls : call list}
  type funcs = (RecordCalc.varInfo * RecordCalc.loc * abs list) VarID.Map.map
  type context = {funcs: funcs ref, caller : caller, isTail : bool}

  fun call ({caller, isTail, ...} : context) args : call =
      (caller, if isTail then TAIL else CALL, args)

  fun nontail (context : context) = context # {isTail = false}

  fun merge nil = VarID.Map.empty
    | merge (h :: t) =
      let
        fun loop g nil : call_graph = g
          | loop g (h :: t) = loop (VarID.Map.unionWith (op @) (g, h)) t
      in
        loop h t
      end

  fun analyzeValue (context : context) value : call_graph =
      case value of
        R.RCCONSTANT _ => VarID.Map.empty
      | R.RCVAR var => VarID.Map.singleton (#id var, [call context nil])

  fun analyzeValueList context values =
      merge (map (analyzeValue context) values)

  and analyzeArg context ((instTyList, argExpList, loc) : arg) =
      analyzeExpList (nontail context) argExpList

  and analyzeArgList context args =
      merge (map (analyzeArg context) args)

  and analyzeExp context exp =
      case exp of
        R.RCVALUE (value, _) => analyzeValue context value
      | R.RCSTRING _ => VarID.Map.empty
      | R.RCEXVAR _ => VarID.Map.empty
      | R.RCCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
        analyzeExp (context # {caller = ANON, isTail = true}) bodyExp
      | R.RCFNM {btvEnv, constraints, argVarList, bodyTy, bodyExp, loc} =>
        analyzeExp (context # {caller = ANON, isTail = true}) bodyExp
      | R.RCAPPM _ =>
        (
          case getAppSpine exp of
            (R.RCVALUE (R.RCVAR var, _), _, args) =>
            merge [VarID.Map.singleton (#id var, [call context args]),
                   analyzeArgList (nontail context) args]
          | (exp, _, args) =>
            merge [analyzeExp (nontail context) exp,
                   analyzeArgList (nontail context) args]
        )
      | R.RCSWITCH {exp, expTy, branches, defaultExp, resultTy, loc} =>
        merge [analyzeExp (nontail context) exp,
               analyzeExpList context (map #body branches),
               analyzeExp context defaultExp]
      | R.RCPRIMAPPLY {primOp, instTyList, instSizeList, instTagList,
                       argExpList, loc} =>
        merge [analyzeValueList (nontail context) instSizeList,
               analyzeValueList (nontail context) instTagList,
               analyzeExpList (nontail context) argExpList]
      | R.RCRECORD {fields, loc} =>
        let
          val fields = RecordLabel.Map.listItems fields
        in
          merge [analyzeExpList (nontail context) (map #exp fields),
                 analyzeValueList (nontail context) (map #size fields),
                 analyzeValueList (nontail context) (map #tag fields)]
        end
      | R.RCSELECT {label, indexExp, recordExp, recordTy, resultTy, resultSize,
                    resultTag, loc} =>
        merge [analyzeExp (nontail context) indexExp,
               analyzeExp (nontail context) recordExp,
               analyzeValue (nontail context) resultSize,
               analyzeValue (nontail context) resultTag]
      | R.RCMODIFY {label, indexExp, recordExp, recordTy, elementExp, elementTy,
                    elementSize, elementTag, loc} =>
        merge [analyzeExp (nontail context) indexExp,
               analyzeExp (nontail context) recordExp,
               analyzeExp (nontail context) elementExp,
               analyzeValue (nontail context) elementSize,
               analyzeValue (nontail context) elementTag]
      | R.RCLET {decl, body, loc} =>
        merge [analyzeDecl (nontail context) decl,
               analyzeExp context body]
      | R.RCRAISE {exp, resultTy, loc} =>
        analyzeExp (nontail context) exp
      | R.RCHANDLE {exp, exnVar, handler, resultTy, loc} =>
        merge [analyzeExp (nontail context) exp,
               analyzeExp context handler]
      | R.RCTHROW {catchLabel, argExpList, resultTy, loc} =>
        merge [analyzeExpList (nontail context) argExpList]
      | R.RCCATCH {recursive, rules, tryExp, resultTy, loc} =>
        merge [analyzeExpList context (map #catchExp rules),
               analyzeExp context tryExp]
      | R.RCFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        merge [analyzeExp (nontail context) funExp,
               analyzeExpList (nontail context) argExpList]
      | R.RCCAST {exp, expTy, targetTy, cast, loc} =>
        analyzeExp (nontail context) exp
      | R.RCINDEXOF {fields, label, loc} =>
        analyzeValueList (nontail context)
                         (map #size (RecordLabel.Map.listItems fields))

  and analyzeExpList context exps =
      merge (map (analyzeExp context) exps)

  and analyzeBind context loc {var, exp} =
      case getFnSpine exp of
        (nil, bodyExp) => analyzeExp (nontail context) exp
      | (args, bodyExp) =>
        let
          val {funcs, ...} = context
          val {id, ...} = var
        in
          funcs := VarID.Map.insert (!funcs, id, (var, loc, args));
          analyzeExp (context # {caller = FN id, isTail = true}) bodyExp
        end

  and analyzeDecl context decl : call_graph =
      case decl of
        R.RCVAL {var, exp, loc} =>
        analyzeBind context loc {var = var, exp = exp}
      | R.RCVALREC (binds, loc) =>
        merge (map (analyzeBind context loc) binds)
      | R.RCEXPORTVAR {weak, var, exp} =>
        analyzeExp (nontail context) exp
      | R.RCEXTERNVAR _ => VarID.Map.empty

  fun eliminateDeadCode (calls : call_graph) =
      let
        fun isAlive alive ((TOPLEVEL, _, _) : call) = true
          | isAlive alive (ANON, _, _) = true
          | isAlive alive (FN from, _, _) = VarID.Set.member (alive, from)
        fun loop alive =
            let
              val newAlive =
                  VarID.Map.foldli
                    (fn (id, calls, newAlive) =>
                        if List.exists (isAlive alive) calls
                        then VarID.Set.add (newAlive, id)
                        else newAlive)
                    VarID.Set.empty
                    calls
            in
              if VarID.Set.isSubset (newAlive, alive)
              then alive
              else loop (VarID.Set.union (newAlive, alive))
            end
        val alive = loop VarID.Set.empty
      in
        VarID.Map.mapPartiali
          (fn (id, calls) =>
              if VarID.Set.member (alive, id)
              then SOME (List.filter (isAlive alive) calls)
              else NONE)
          calls
      end

  fun computeMaxArgs (calls : call list) =
      foldl (fn ((_, _, args), z) => Int.max (length args, z)) 0 calls

  fun limitArgs numArgs (call : call) =
      case call of
        (caller, CALL, args) =>
        if length args <= numArgs
        then call
        else (caller, CALL, List.take (args, numArgs))
      | (caller, TAIL, args) =>
        case Int.compare (length args, numArgs) of
          EQUAL => call
        | GREATER => (caller, CALL, List.take (args, numArgs))
        | LESS => (caller, CALL, args)

  fun anonymizeCaller callers (call : call) =
      case call of
        (TOPLEVEL, _, _) => call
      | (ANON, _, _) => call
      | (FN id, pos, args) =>
        if VarID.Set.member (callers, id) then (ANON, pos, args) else call

  fun analyze decls =
      let
        val funcs = ref VarID.Map.empty
        val context = {funcs = funcs, caller = TOPLEVEL, isTail = false}
        val calls = merge (map (analyzeDecl context) decls)
        val calls = eliminateDeadCode calls

        val funcs =
            VarID.Map.mergeWith
              (fn (NONE, NONE) => NONE
                | (SOME _, NONE) => NONE
                | (NONE, SOME (var, loc, absList)) =>
                  SOME (var, loc, absList, nil)
                | (SOME calls, SOME (var, loc, absList)) =>
                  SOME (var, loc, absList, calls))
              (calls, !funcs)

        (* adjustment for uncurrying *)
        val (results, anon) =
            VarID.Map.foldli
              (fn (id, (var, loc, absList, calls), (results, anon)) =>
                  let
                    val numArgs = Int.min (length absList, computeMaxArgs calls)
                    val newAbsList = List.take (absList, numArgs)
                    val restAbsList = List.drop (absList, numArgs)
                    val calls = map (limitArgs numArgs) calls
                    val results =
                        VarID.Map.insert (results, id, {var = var,
                                                        loc = loc,
                                                        absList = newAbsList,
                                                        calls = calls})
                  in
                    case restAbsList of
                      nil => (results, anon)
                    | _ :: _ => (results, VarID.Set.add (anon, id))
                  end)
              (VarID.Map.empty, VarID.Set.empty)
              funcs
      in
        VarID.Map.map
          (fn result as {calls, ...} =>
              result # {calls = map (anonymizeCaller anon) calls})
          results
      end

end
