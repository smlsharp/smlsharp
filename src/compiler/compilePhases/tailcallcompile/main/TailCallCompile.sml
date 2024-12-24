(**
 * @copyright (C) 2024 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure TailCallCompile =
struct

  structure R = RecordCalc
  structure T = Types
  datatype arg = datatype CallAnalysis.arg
  datatype abs = datatype CallAnalysis.abs
  datatype pos = datatype CallAnalysis.pos
  datatype caller = datatype CallAnalysis.caller
  datatype call = datatype CallAnalysis.call

  (* for debug *)
  fun posToString CALL = "CALL"
    | posToString TAIL = "TAIL"
  fun callerToString TOPLEVEL = "TOP"
    | callerToString ANON = "ANON"
    | callerToString (FN id) = VarID.toString id
  fun callToString (caller, pos, args) =
      callerToString caller ^ ":" ^ posToString pos
      ^ "(" ^ Int.toString (length args) ^ ")"
  fun pathToString path = String.concatWith "." (map #string path)
  fun resultToString {var, loc, absList, calls} =
      pathToString (#path var)
      ^ "(" ^ Int.toString (length absList) ^ ")"
      ^ "["
      ^ String.concatWith ", " (map callToString calls)
      ^ "]"
  fun printFuncs funcs =
      VarID.Map.appi
        (fn (id, result) =>
            print (VarID.toString id ^ " <- " ^ resultToString result ^ "\n"))
        funcs
  fun printTailcallGraph graph starts =
      VarID.Map.appi
        (fn (id, succs) =>
            print ((if List.exists (fn i => i = id) starts then "*" else "")
                   ^ VarID.toString id
                   ^ " -> "
                   ^ String.concatWith
                       ","
                       (map VarID.toString (VarID.Set.listItems succs))
                   ^ "\n"))
        graph
  fun printOwners owners =
      VarID.Map.appi
        (fn (id, owner) =>
            print (VarID.toString id ^ " -> " ^ VarID.toString owner ^ "\n"))
        owners
  fun printLabels labels =
      VarID.Map.appi
        (fn (id, label) =>
            print (VarID.toString id ^ " -> " ^ FunLocalLabel.toString label
                   ^ "\n"))
        labels
  fun printEta eta =
      VarID.Map.appi
        (fn (id, etaBinds) =>
            IEnv.appi
              (fn (n, bind) =>
                  print (VarID.toString id ^ ":" ^ Int.toString n ^ " -> "
                         ^ Bug.prettyPrint (R.format_rcdecl (R.RCVAL bind))
                         ^ "\n"))
              etaBinds)
        eta

  fun Catch {recursive, rules = nil, tryExp, resultTy, loc} = tryExp
    | Catch arg = R.RCCATCH arg

  fun Let {decls = nil, body, loc} = body
    | Let {decls = decl :: decls, body, loc} =
      R.RCLET {decl = decl,
               body = Let {decls = decls, body = body, loc = loc},
               loc = loc}

  fun varToExp loc var =
      R.RCVALUE (R.RCVAR var, loc)

  fun unionBtvMap btvs =
      foldl (BoundTypeVarID.Map.unionWith (fn _ => raise Bug.Bug "unionBtvMap"))
            BoundTypeVarID.Map.empty
            btvs

  fun instMap (btvEnv : Types.btvEnv) instTyList =
      ListPair.foldlEq
        (fn (tid, ty, z) => BoundTypeVarID.Map.insert (z, tid, ty))
        BoundTypeVarID.Map.empty
        (BoundTypeVarID.Map.listKeys btvEnv, instTyList)
      handle ListPair.UnequalLengths => raise Bug.Bug "instMap"

  fun isMono btvEnv constraints =
      BoundTypeVarID.Map.isEmpty btvEnv andalso null constraints

  fun makeFunTy {btvEnv, constraints, argTyList, bodyTy} =
      if isMono btvEnv constraints
      then T.FUNMty (argTyList, bodyTy)
      else T.POLYty {boundtvars = btvEnv,
                     constraints = constraints,
                     body = T.FUNMty (argTyList, bodyTy)}

  fun funBodyTy ty =
      case TypesBasics.revealTy ty of
        T.FUNMty (_, retTy) => retTy
      | T.POLYty {boundtvars, constraints, body} =>
        (case TypesBasics.revealTy body of
           T.FUNMty (_, retTy) => retTy
         | _ => raise Bug.Bug "funBodyTy")
      | _ => raise Bug.Bug "funBodyTy"

  fun funApplyTy funTy instTyList =
      case TypesBasics.revealTy (TypesBasics.tpappTy (funTy, instTyList)) of
        T.FUNMty (_, retTy) => retTy
       | _ => raise Bug.Bug "funApplyTy"

  fun putAppSpine funExp funTy ((instTyList, argExpList, loc) :: argList) =
      putAppSpine (R.RCAPPM {funExp = funExp,
                             funTy = funTy,
                             instTyList = instTyList,
                             argExpList = argExpList,
                             loc = loc})
                  (funApplyTy funTy instTyList)
                  argList
    | putAppSpine funExp _ nil = funExp

  fun putFnSpine funTy absList loc bodyExp =
      let
        fun expand funTy ((btvEnv, constraints, argVarList) :: absList) =
            let
              val bodyTy = funBodyTy funTy
            in
              R.RCFNM {btvEnv = btvEnv,
                       constraints = constraints,
                       argVarList = argVarList,
                       bodyExp = expand bodyTy absList,
                       bodyTy = bodyTy,
                       loc = loc}
            end
          | expand _ nil = bodyExp
      in
        expand funTy absList
      end

  fun absToArg loc ((btvEnv, constraints, argVarList) : abs) : arg =
      (map T.BOUNDVARty (BoundTypeVarID.Map.listKeys btvEnv),
       map (varToExp loc) argVarList,
       loc)

  fun uncurryFn (absList : abs list) exp expTy =
      let
        val fnLoc = RecordCalcLoc.locExp exp
        fun loop (_ :: absList)
                 (R.RCFNM {btvEnv, constraints, argVarList, bodyTy, bodyExp,
                           loc})
                 {tabs, args, bodyTy = _} =
            loop absList
                 bodyExp
                 {tabs = (btvEnv, constraints) :: tabs,
                  args = argVarList :: args,
                  bodyTy = bodyTy}
          | loop (_ :: _) _ _ = raise Bug.Bug "uncurryFn"
          | loop nil bodyExp {args = nil, bodyTy, ...} =
            {Fn = fn bodyExp => bodyExp,
             fnTy = bodyTy,
             mono = true,
             argVarList = nil,
             bodyExp = bodyExp,
             bodyTy = bodyTy}
          | loop nil bodyExp {tabs, args as _ :: _, bodyTy} =
            let
              val (btvs, cons) = ListPair.unzip (rev tabs)
              val btvEnv = unionBtvMap btvs
              val constraints = List.concat cons
              val argVarList = List.concat (rev args)
            in
              {Fn = fn x => R.RCFNM {btvEnv = btvEnv,
                                     constraints = constraints,
                                     argVarList = argVarList,
                                     bodyTy = bodyTy,
                                     bodyExp = x,
                                     loc = fnLoc},
               fnTy = makeFunTy {btvEnv = btvEnv,
                                 constraints = constraints,
                                 argTyList = map #ty argVarList,
                                 bodyTy = bodyTy},
               mono = isMono btvEnv constraints,
               argVarList = argVarList,
               bodyExp = bodyExp,
               bodyTy = bodyTy}
            end
      in
        loop absList exp {tabs = nil, args = nil, bodyTy = expTy}
      end

  fun uncurryApp funTy funLoc (absList : abs list) argList =
      let
        fun loop ((btvEnv, constraints, argVarList) :: absList)
                 ((instTyList, argExpList, loc) :: argList)
                 funTy
                 {tabs, insts, args, loc = _} =
            loop absList
                 argList
                 (funBodyTy funTy)
                 {tabs = (btvEnv, constraints) :: tabs,
                  insts = instMap btvEnv instTyList :: insts,
                  args = (map #ty argVarList, argExpList) :: args,
                  loc = loc}
          | loop (_ :: _) _ _ _ = raise Bug.Bug "uncurryApp"
          | loop nil argList retTy {args = nil, loc, ...} =
            {App = fn funExp => funExp,
             funTy = retTy,
             appTy = retTy,
             argExpList = nil,
             loc = loc,
             restArgs = argList}
          | loop nil argList retTy {tabs, insts, args, loc} =
            let
              val (btvs, cons) = ListPair.unzip (rev tabs)
              val btvEnv = unionBtvMap btvs
              val constraints = List.concat cons
              val instTys = unionBtvMap insts
              val instTyList = BoundTypeVarID.Map.listItems instTys
              val (argTys, argExps) = ListPair.unzip (rev args)
              val argTyList = List.concat argTys
              val argExpList = List.concat argExps
              val funTy = makeFunTy {btvEnv = btvEnv,
                                     constraints = constraints,
                                     argTyList = argTyList,
                                     bodyTy = retTy}
            in
              {App = fn funExp =>
                        R.RCAPPM {funExp = funExp,
                                  funTy = funTy,
                                  instTyList = instTyList,
                                  argExpList = argExpList,
                                  loc = loc},
               funTy = funTy,
               appTy = funApplyTy funTy instTyList,
               argExpList = argExpList,
               loc = loc,
               restArgs = argList}
            end
      in
        loop absList
             argList
             funTy
             {tabs = nil, insts = nil, args = nil, loc = funLoc}
      end

  type catch_rule =
      {catchLabel : FunLocalLabel.id,
       argVarList : RecordCalc.varInfo list,
       catchExp : RecordCalc.rcexp}

  type inline =
      {argVarList : RecordCalc.varInfo list,
       bodyExp : RecordCalc.rcexp}

  type catches = catch_rule list VarID.Map.map
  type inlines = (catches -> inline) VarID.Map.map
  type env = {catches : catches, inlines : inlines}

  fun addCatch id rule (env as {catches, ...} : env) =
      case VarID.Map.find (catches, id) of
        NONE => env # {catches = VarID.Map.insert (catches, id, [rule])}
      | SOME t => env # {catches = VarID.Map.insert (catches, id, rule :: t)}

  fun catchesOf (catches : catches) id =
      case VarID.Map.find (catches, id) of
        NONE => nil
      | SOME rules => rev rules

  fun addInline id inline (env as {inlines, ...} : env) =
      env # {inlines = VarID.Map.insert (inlines, id, inline)}

  fun findInline ({inlines, catches} : env) id =
      case VarID.Map.find (inlines, id) of
        NONE => NONE
      | SOME inline => SOME (inline catches)

  fun deleteInline (env as {inlines, ...} : env) id =
      if VarID.Map.inDomain (inlines, id)
      then env # {inlines = #1 (VarID.Map.remove (inlines, id))}
      else env

  type bind =
      {var : RecordCalc.varInfo,
       exp : RecordCalc.rcexp,
       loc : RecordCalc.loc}

  type context =
      {funcs : CallAnalysis.result VarID.Map.map,
       owners : VarID.id VarID.Map.map,
       labels : FunLocalLabel.id VarID.Map.map,
       eta : bind IEnv.map VarID.Map.map,
       scope : CallAnalysis.caller,
       isTail : bool,
       env : env}

  fun ownerOf owners id =
      case VarID.Map.find (owners, id) of
        NONE => id
      | SOME owner => owner

  fun splitCalls owners id calls =
      let
        val scope = ownerOf owners id
        fun isJump (FN from, TAIL, _ :: _) = ownerOf owners from = scope
          | isJump _ = false
        fun loop nil {calls, jumps} = {calls = rev calls, jumps = rev jumps}
          | loop (call :: t) {calls, jumps} =
            if isJump call
            then loop t {calls = calls, jumps = call :: jumps}
            else loop t {calls = call :: calls, jumps = jumps}
      in
        loop calls {calls = nil, jumps = nil}
      end

  fun isSingleCall ({owners, ...} : context) id calls =
      case splitCalls owners id calls of
        {calls = [(_, _, _ :: _)], ...} => true
      | _ => false

  fun tail (context : context) = context # {isTail = true}

  fun nontail (context : context) = context # {isTail = false}

  fun anonFn (context : context) = context # {scope = ANON, isTail = true}

  fun emitFunctionBody (context : context) id argVarList bodyExp bodyTy =
      let
        val loc = RecordCalcLoc.locExp bodyExp
        val (rules, bodyExp) =
            case VarID.Map.find (#labels context, id) of
              NONE => (nil, bodyExp)
            | SOME label =>
              ([{catchLabel = label,
                 argVarList = argVarList,
                 catchExp = bodyExp}],
               R.RCTHROW {catchLabel = label,
                          argExpList = map (varToExp loc) argVarList,
                          resultTy = bodyTy,
                          loc = loc})
      in
        fn catches => Catch {recursive = true,
                             rules = catchesOf catches id @ rules,
                             tryExp = bodyExp,
                             resultTy = bodyTy,
                             loc = loc}
      end

  datatype transform_bind =
      ENV of env -> env
    | BIND of {var : RecordCalc.varInfo, exp : RecordCalc.rcexp}
    | FUN of {var : RecordCalc.varInfo,
              Fn : RecordCalc.rcexp -> RecordCalc.rcexp,
              scope : caller,
              bodyExp : catches -> RecordCalc.rcexp}
    | CATCH of catch_rule * Types.ty

  fun transformBind (context : context) {var as {id, ty, ...}, exp, loc} =
      let
        fun emitInlineFunction {argVarList, bodyExp, bodyTy, ...} =
            let
              val bodyExp =
                  emitFunctionBody context id argVarList bodyExp bodyTy
              fun inline catches : inline =
                  {argVarList = argVarList, bodyExp = bodyExp catches}
            in
              ENV (addInline id inline)
            end
        fun emitFunction {Fn, fnTy, argVarList, bodyExp, bodyTy, ...} =
            FUN {var = var # {ty = fnTy},
                 Fn = Fn,
                 scope = FN id,
                 bodyExp =
                   emitFunctionBody context id argVarList bodyExp bodyTy}
      in
        case VarID.Map.find (#funcs context, id) of
          NONE => BIND {var = var, exp = exp} (* not a named function *)
        | SOME {calls = nil, ...} => ENV (fn x => x) (* dead code *)
        | SOME {absList, calls, ...} =>
          let
            val result = uncurryFn absList exp ty
            val owner = ownerOf (#owners context) id
          in
            if owner = id
            then if #mono result andalso isSingleCall context id calls
                 then emitInlineFunction result
                 else emitFunction result
            else case VarID.Map.find (#labels context, id) of
                   NONE => emitInlineFunction result
                 | SOME label =>
                   let
                     val {argVarList, bodyExp, bodyTy, ...} = result
                     val rule = {catchLabel = label,
                                 argVarList = argVarList,
                                 catchExp = bodyExp}
                   in
                     if FN owner = #scope context
                     then CATCH (rule, bodyTy)
                     else ENV (addCatch owner rule)
                   end
          end
      end

  fun transformApp (context : context) (var as {id, ty, ...}) varLoc argList =
      let
        fun inlineExpand id {argVarList, bodyExp} {loc, argExpList, ...} =
            let
              val decls =
                  ListPair.mapEq
                    (fn (var, exp) => R.RCVAL {var = var, exp = exp, loc = loc})
                    (argVarList, argExpList)
                  handle ListPair.UnequalLengths => raise Bug.Bug "inlineExpand"
              val env = deleteInline (#env context) id
              val owner = ownerOf (#owners context) id
              val context = context # {scope = FN owner, env = env}
              val bodyExp = compileExp (tail context) bodyExp
            in
              Let {decls = decls, body = bodyExp, loc = loc}
            end
        fun emitThrow label {argExpList, appTy, loc, ...} =
            R.RCTHROW {catchLabel = label,
                       argExpList = argExpList,
                       resultTy = appTy,
                       loc = loc}
        fun emitApp id {App, funTy, ...} =
            App (varToExp varLoc (var # {id = id, ty = funTy}))
      in
        case VarID.Map.find (#funcs context, id) of
          NONE => putAppSpine (varToExp varLoc var) ty argList
        | SOME {absList, ...} =>
          let
            val absLen = length absList
            val argLen = length argList
            val (id, absList) =
                if argLen >= absLen
                then (id, absList)
                else case VarID.Map.find (#eta context, id) of
                       NONE => raise Bug.Bug "transformApp: eta1"
                     | SOME etaBinds =>
                       case IEnv.find (etaBinds, argLen) of
                         NONE => (id, List.take (absList, argLen))
                       | SOME {var = {id, ...}, ...} =>
                         (id, List.take (absList, argLen))
            val result = uncurryApp ty varLoc absList argList
            val owner = ownerOf (#owners context) id
            val appExp =
                case findInline (#env context) id of
                  SOME inline => inlineExpand id inline result
                | NONE =>
                  case VarID.Map.find (#labels context, id) of
                    NONE => emitApp id result
                  | SOME label =>
                    if #isTail context andalso FN owner = #scope context
                    then emitThrow label result
                    else emitApp id result
          in
            putAppSpine appExp (#appTy result) (#restArgs result)
          end
      end

  and compileArg context ((instTyList, argExpList, loc): arg) : arg =
      (instTyList, map (compileExp (nontail context)) argExpList, loc)

  and compileValue context value =
      case value of
        R.RCCONSTANT _ => value
      | R.RCVAR var =>
        case VarID.Map.find (#eta context, #id var) of
          NONE => value
        | SOME etaBinds =>
          case IEnv.find (etaBinds, 0) of
            NONE => value
          | SOME {var = {id, ...}, ...} => R.RCVAR (var # {id = id})

  and compileExp context exp =
      case exp of
        R.RCVALUE (value, loc) =>
        R.RCVALUE (compileValue context value, loc)
      | R.RCSTRING _ => exp
      | R.RCEXVAR _ => exp
      | R.RCCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
        R.RCCALLBACKFN {attributes = attributes,
                        argVarList = argVarList,
                        bodyExp = compileExp (anonFn context) bodyExp,
                        resultTy = resultTy,
                        loc = loc}
      | R.RCFNM {btvEnv, constraints, argVarList, bodyTy, bodyExp, loc} =>
        R.RCFNM {btvEnv = btvEnv,
                 constraints = constraints,
                 argVarList = argVarList,
                 bodyTy = bodyTy,
                 bodyExp = compileExp (anonFn context) bodyExp,
                 loc = loc}
      | R.RCAPPM _ =>
        (
          case CallAnalysis.getAppSpine exp of
            (_, NONE, _) => raise Bug.Bug "RCAPPM"
          | (R.RCVALUE (R.RCVAR var, varLoc), SOME funTy, argList) =>
            transformApp context var varLoc (map (compileArg context) argList)
          | (funExp, SOME funTy, argList) =>
            putAppSpine (compileExp (nontail context) funExp)
                        funTy
                        (map (compileArg context) argList)
        )
      | R.RCSWITCH {exp, expTy, branches, defaultExp, resultTy, loc} =>
        R.RCSWITCH
          {exp = compileExp (nontail context) exp,
           expTy = expTy,
           branches = map (fn {const, body} =>
                              {const = const,
                               body = compileExp context body})
                          branches,
           defaultExp = compileExp context defaultExp,
           resultTy = resultTy,
           loc = loc}
      | R.RCPRIMAPPLY {primOp, instTyList, instSizeList, instTagList,
                       argExpList, loc} =>
        R.RCPRIMAPPLY
          {primOp = primOp,
           instTyList = instTyList,
           instSizeList = map (compileValue (nontail context)) instSizeList,
           instTagList = map (compileValue (nontail context)) instTagList,
           argExpList = map (compileExp (nontail context)) argExpList,
           loc = loc}
      | R.RCRECORD {fields, loc} =>
        R.RCRECORD
          {fields = RecordLabel.Map.map
                      (fn {exp, ty, size, tag} =>
                          {exp = compileExp (nontail context) exp,
                           ty = ty,
                           size = compileValue (nontail context) size,
                           tag = compileValue (nontail context) tag})
                      fields,
           loc = loc}
      | R.RCSELECT {label, indexExp, recordExp, recordTy, resultTy, resultSize,
                    resultTag, loc} =>
        R.RCSELECT {label = label,
                    indexExp = compileExp (nontail context) indexExp,
                    recordExp = compileExp (nontail context) recordExp,
                    recordTy = recordTy,
                    resultTy = resultTy,
                    resultSize = compileValue (nontail context) resultSize,
                    resultTag = compileValue (nontail context) resultTag,
                    loc = loc}
      | R.RCMODIFY {label, indexExp, recordExp, recordTy, elementExp, elementTy,
                    elementSize, elementTag, loc} =>
        R.RCMODIFY {label = label,
                    indexExp = compileExp (nontail context) indexExp,
                    recordExp = compileExp (nontail context) recordExp,
                    recordTy = recordTy,
                    elementExp = compileExp (nontail context) elementExp,
                    elementTy = elementTy,
                    elementSize = compileValue (nontail context) elementSize,
                    elementTag = compileValue (nontail context) elementTag,
                    loc = loc}
      | R.RCLET {decl, body, loc} =>
        let
          val {decls, catch, env} = compileDecl (nontail context) decl
          val body = compileExp (context # {env = env}) body
          val body = Let {decls = decls, body = body, loc = loc}
        in
          case catch of
            NONE => body
          | SOME {recursive, rules, resultTy} =>
            R.RCCATCH {recursive = recursive,
                       rules = rules,
                       resultTy = resultTy,
                       tryExp = body,
                       loc = loc}
        end
      | R.RCRAISE {exp, resultTy, loc} =>
        R.RCRAISE {exp = compileExp (nontail context) exp,
                   resultTy = resultTy,
                   loc = loc}
      | R.RCHANDLE {exp, exnVar, handler, resultTy, loc} =>
        R.RCHANDLE {exp = compileExp (nontail context) exp,
                    exnVar = exnVar,
                    handler = compileExp context handler,
                    resultTy = resultTy,
                    loc = loc}
      | R.RCTHROW {catchLabel, argExpList, resultTy, loc} =>
        R.RCTHROW {catchLabel = catchLabel,
                   argExpList = map (compileExp (nontail context)) argExpList,
                   resultTy = resultTy,
                   loc = loc}
      | R.RCCATCH {recursive, rules, tryExp, resultTy, loc} =>
        R.RCCATCH {recursive = recursive,
                   rules = map (fn {catchLabel, argVarList, catchExp} =>
                                   {catchLabel = catchLabel,
                                    argVarList = argVarList,
                                    catchExp = compileExp context catchExp})
                               rules,
                   tryExp = compileExp context tryExp,
                   resultTy = resultTy,
                   loc = loc}
      | R.RCFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        R.RCFOREIGNAPPLY
          {funExp = compileExp (nontail context) funExp,
           argExpList = map (compileExp (nontail context)) argExpList,
           attributes = attributes,
           resultTy = resultTy,
           loc = loc}
      | R.RCCAST {exp, expTy, targetTy, cast, loc} =>
        R.RCCAST {exp = compileExp (nontail context) exp,
                  expTy = expTy,
                  targetTy = targetTy,
                  cast = cast,
                  loc = loc}
      | R.RCINDEXOF {fields, label, loc} =>
        R.RCINDEXOF
          {fields = RecordLabel.Map.map
                      (fn {ty, size} =>
                          {ty = ty,
                           size = compileValue (nontail context) size})
                      fields,
           label = label,
           loc = loc}

  and compileBindAsBind context result =
      case result of
        ENV _ => NONE
      | CATCH _ => NONE
      | BIND {var, exp} =>
        SOME {var = var, exp = compileExp (nontail context) exp}
      | FUN {var, Fn, scope, bodyExp} =>
        let
          val bodyExp = bodyExp (#catches (#env context))
          val context = context # {scope = scope, isTail = true}
        in
          SOME {var = var, exp = Fn (compileExp context bodyExp)}
        end

  and compileBindAsCatch context result =
      case result of
        ENV _ => NONE
      | CATCH ({catchLabel, argVarList, catchExp}, resultTy) =>
        SOME ({catchLabel = catchLabel,
               argVarList = argVarList,
               catchExp = compileExp (tail context) catchExp},
              resultTy)
      | BIND _ => NONE
      | FUN _ => NONE

  and compileDecl context decl =
      case decl of
        R.RCVAL {var, exp, loc} =>
        let
          val etaBinds =
              case VarID.Map.find (#eta context, #id var) of
                NONE => nil
              | SOME etaBinds => IEnv.listItems etaBinds
          val binds = {var = var, exp = exp, loc = loc} :: etaBinds
          val results = map (transformBind context) binds
          val env = foldl (fn (ENV f, env) => f env | (_, env) => env)
                          (#env context)
                          results
          val context = context # {env = env}
          val decls =
              map (fn {var, exp} => R.RCVAL {var = var, exp = exp, loc = loc})
                  (List.mapPartial (compileBindAsBind context) results)
          val catches = List.mapPartial (compileBindAsCatch context) results
        in
          {decls = decls,
           catch = case catches of
                     nil => NONE
                   | (_, resultTy) :: _ => SOME {recursive = false,
                                                 rules = map #1 catches,
                                                 resultTy = resultTy},
           env = env}
        end
      | R.RCVALREC (binds, loc) =>
        let
          val binds =
              map (fn {var, exp} => {var = var, exp = exp, loc = loc}) binds
          val etaBinds =
              List.concat
                (map (fn {var = {id, ...}, ...} =>
                         case VarID.Map.find (#eta context, id) of
                           NONE => nil
                         | SOME etaBinds => IEnv.listItems etaBinds)
                     binds)
          val results = map (transformBind context) (binds @ etaBinds)
          val env = foldl (fn (ENV f, env) => f env | (_, env) => env)
                          (#env context)
                          results
          val context = context # {env = env}
          val binds = List.mapPartial (compileBindAsBind context) results
          val catches = List.mapPartial (compileBindAsCatch context) results
        in
          {decls =
             case binds of
               nil => nil
             | binds => [R.RCVALREC (binds, loc)],
           catch =
             case catches of
               nil => NONE
             | (_, resultTy) :: _ => SOME {recursive = true,
                                           rules = map #1 catches,
                                           resultTy = resultTy},
           env = env}
        end
      | R.RCEXPORTVAR {weak, var, exp} =>
        {decls = [R.RCEXPORTVAR {weak = weak,
                                 var = var,
                                 exp = compileExp (nontail context) exp}],
         catch = NONE,
         env = #env context}
      | R.RCEXTERNVAR _ =>
        {decls = [decl], catch = NONE, env = #env context}

  fun compileDecls context nil = nil
    | compileDecls context (decl :: rcdecls) =
      case compileDecl context decl of
        {catch = NONE, decls, env} =>
        decls @ compileDecls (context # {env = env}) rcdecls
      | _ => raise Bug.Bug "compileDecls"

  fun isMonoFn (absList : abs list) =
      List.all (fn (btvEnv, constraints, _) => isMono btvEnv constraints)
               absList

  fun hasCall calls =
      List.exists (fn (FN _, TAIL, _ :: _) => false | _ => true) calls

  fun addEdge to ((_, CALL, _), graph) = graph
    | addEdge to ((_, TAIL, nil), graph) = graph
    | addEdge to ((ANON, TAIL, _), graph) = graph
    | addEdge to ((TOPLEVEL, TAIL, _), graph) =
      (* top-level does not have tail position *)
      raise Bug.Bug "addEdge"
    | addEdge to ((FN from, TAIL, _ :: _), graph) =
      (* tail calls between named functions are added *)
      case VarID.Map.find (graph, from) of
        NONE => VarID.Map.insert (graph, from, VarID.Set.singleton to)
      | SOME succs => VarID.Map.insert (graph, from, VarID.Set.add (succs, to))

  fun getEdge graph id =
      case VarID.Map.find (graph, id) of
        NONE => nil
      | SOME succs => VarID.Set.listItems succs

  fun deleteIncomingEdges graph id =
      VarID.Map.map (fn succs => VarID.Set.subtract (succs, id)) graph

  datatype colorify = OK of VarID.id VarID.Map.map | NG of VarID.id

  fun colorify graph colors colorId =
      let
        fun loop nil colors = OK colors
          | loop (id :: stack) colors =
            case VarID.Map.find (colors, id) of
              SOME color =>
              if color = colorId
              then loop stack colors
              else NG id
            | NONE =>
              loop (getEdge graph id @ stack)
                   (VarID.Map.insert (colors, id, colorId))
      in
        loop [colorId] colors
      end

  fun clustering graph starts =
      let
        fun check graph starts colors nil = colors
          | check graph starts colors (id :: ids) =
            case colorify graph colors id of
              OK colors => check graph starts colors ids
            | NG id =>
              (* if a node has more than one colors, remove its all incoming
               * edges and colorify again *)
              check (deleteIncomingEdges graph id)
                    (id :: starts)
                    VarID.Map.empty
                    (id :: starts)
      in
        check graph starts VarID.Map.empty starts
      end

  fun solve (funcs : CallAnalysis.result VarID.Map.map) =
      let
        (* create tail-call graph *)
        val graph =
            VarID.Map.foldli
              (fn (id, {calls, ...}, graph) => foldl (addEdge id) graph calls)
              VarID.Map.empty
              funcs

        (* poly funcs and non-tail-called funcs must be functions *)
        (* ToDo: poly funcs cannot be turned into blocks *)
        val starts =
            VarID.Map.listKeys
              (VarID.Map.filter
                 (fn {absList, calls, ...} =>
                     not (isMonoFn absList) orelse hasCall calls)
                 funcs)

        (* perform clustering on the tail-call graph *)
        val owners = clustering graph starts

        fun numIncomingEdges id calls =
            case splitCalls owners id calls of
              {calls = nil, jumps} => length jumps
            | {calls = _ :: _, jumps} => length jumps + 1

        (* blocks having multiple incoming edges must have a label *)
        val labels =
            VarID.Map.foldli
              (fn (id, {var, calls, ...}, labels) =>
                  if numIncomingEdges id calls > 1
                  then VarID.Map.insert
                         (labels, id, FunLocalLabel.generate (#path var))
                  else labels)
              VarID.Map.empty
              funcs
      in
        (*
        print "## funcs\n";
        printFuncs funcs;
        print "## tailcall graph\n";
        printTailcallGraph graph starts;
        print "## owners\n";
        printOwners owners;
        print "## labels\n";
        printLabels labels;
        *)
        {owners = owners, labels = labels}
      end

  fun etaExpand id {var, loc, absList, calls} =
      let
        val absLen = length absList
        val calls = map (fn call as (_ , _, args) => (call, length args)) calls
        fun filterByNumArgs n calls =
            List.mapPartial
              (fn (call : call, m) => if m = n then SOME call else NONE)
              calls

        (* generate ids of eta-expanded functions *)
        val etaMap =
            if absLen <= 1
            then IEnv.empty
            else foldl
                   (fn ((_, argLen), etaMap) =>
                       if absLen = argLen orelse IEnv.inDomain (etaMap, argLen)
                       then etaMap
                       else IEnv.insert (etaMap, argLen, VarID.generate ()))
                   IEnv.empty
                   calls
      in
        if IEnv.isEmpty etaMap then (VarID.Map.empty, VarID.Map.empty) else
        let
          val argList = map (absToArg loc) absList

          (* split smaller calls into calls to eta-expanded functions *)
          val etaCalls =
              IEnv.listItems
                (IEnv.mapi (fn (n, id) => (ANON, TAIL, argList)) etaMap)
          val func =
              {var = var,
               loc = loc,
               absList = absList,
               calls = filterByNumArgs absLen calls @ etaCalls}
          val funcs =
              IEnv.foldli
                (fn (n, id, funcs) =>
                    VarID.Map.insert
                      (funcs, id, {var = var # {id = id},
                                   loc = loc,
                                   absList = List.take (absList, n),
                                   calls = filterByNumArgs n calls}))
                (VarID.Map.singleton (id, func))
                etaMap

          (* generate eta-expanded functions *)
          val appExp = putAppSpine (varToExp loc var) (#ty var) argList
          val fnExp = putFnSpine (#ty var) absList loc appExp
          val etaMap =
              IEnv.map
                (fn id => {var = var # {id = id}, exp = fnExp, loc = loc})
                etaMap
        in
          (funcs, VarID.Map.singleton (id, etaMap))
        end
      end

  fun generateEtaExpansions funcs =
      VarID.Map.foldli
        (fn (id, result, {funcs, eta}) =>
            let
              val (funcs2, eta2) = etaExpand id result
            in
              {funcs = VarID.Map.unionWith #2 (funcs, funcs2),
               eta = VarID.Map.unionWith #2 (eta, eta2)}
            end)
        {funcs = funcs, eta = VarID.Map.empty}
        funcs

  fun compile decls =
      let
        val decls = RecordCalcRename.rename decls
        val funcs = CallAnalysis.analyze decls
        val {funcs, eta} = generateEtaExpansions funcs
        (*
        val _ = print "## eta\n"
        val _ = printEta eta
        *)
        val {owners, labels} = solve funcs
        val context = {funcs = funcs,
                       owners = owners,
                       labels = labels,
                       eta = eta,
                       scope = TOPLEVEL,
                       isTail = false,
                       env = {inlines = VarID.Map.empty,
                              catches = VarID.Map.empty}} : context
      in
        compileDecls context decls
      end

end
