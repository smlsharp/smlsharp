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

  fun eqTy ty1 ty2 =
      Unify.eqTy BoundTypeVarID.Map.empty (ty1, ty2)

  structure Subst :> sig
    type subst
    val identity : subst
    val fromTyMap : Types.ty BoundTypeVarID.Map.map -> subst
    val toTyMap : subst -> Types.ty BoundTypeVarID.Map.map
    val compose : subst * subst -> subst
    val apply : subst -> Types.ty -> Types.ty
    val applyToExp : subst -> RecordCalc.rcexp -> RecordCalc.rcexp
    val applyToVar : subst -> RecordCalc.varInfo -> RecordCalc.varInfo
    val applyToSubst : subst -> subst -> subst
    val equal : subst * subst -> bool
    val toString : subst -> string (* for debug *)
  end = struct
    type subst = Types.ty BoundTypeVarID.Map.map
    val identity = BoundTypeVarID.Map.empty

    fun toTyMap (subst : subst) = subst

    fun fromTyMap btvMap =
        BoundTypeVarID.Map.mapPartiali
          (fn (id, ty) =>
              case TypesBasics.revealTy ty of
                ty as T.BOUNDVARty id2 => if id = id2 then NONE else SOME ty
              | ty => SOME (TyRevealTy.revealTy ty))
          btvMap

    fun apply subst ty =
        if BoundTypeVarID.Map.isEmpty subst
        then ty
        else TypesBasics.substBTvar subst ty

    fun applyToExp subst exp =
        if BoundTypeVarID.Map.isEmpty subst
        then exp
        else RecordCalcType.instantiateExp subst exp

    fun applyToVar subst var =
        if BoundTypeVarID.Map.isEmpty subst
        then var
        else RecordCalcType.instantiateVar subst var

    fun applyToSubst subst1 subst2 =
        if BoundTypeVarID.Map.isEmpty subst1
        then subst2
        else fromTyMap
               (BoundTypeVarID.Map.map (TypesBasics.substBTvar subst1) subst2)

    fun compose (subst1, subst2) =
        BoundTypeVarID.Map.unionWith #2 (subst1, applyToSubst subst1 subst2)

    fun equal (subst1, subst2) =
        let
          fun loop ((tid1, ty1) :: t1) ((tid2, ty2) :: t2) =
              BoundTypeVarID.eq (tid1, tid2)
              andalso eqTy ty1 ty2
              andalso loop t1 t2
            | loop nil nil = true
            | loop _ _ = false
        in
          loop (BoundTypeVarID.Map.listItemsi subst1)
               (BoundTypeVarID.Map.listItemsi subst2)
        end

    (* for debug *)
    fun toString subst =
        "["
        ^ String.concatWith
            ", "
            (map (fn (id, ty) =>
                     BoundTypeVarID.toString id
                     ^ ":"
                     ^ Bug.prettyPrint (T.format_ty ty))
                 (BoundTypeVarID.Map.listItemsi subst))
        ^ "]"
  end

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
  fun colorToString {owner, subst} =
      VarID.toString owner ^ Subst.toString subst
  fun printCallees callees entries =
      VarID.Map.appi
        (fn (id, edges) =>
            print ((if List.exists (fn i => i = id) entries then "*" else "")
                   ^ VarID.toString id
                   ^ " -> "
                   ^ String.concatWith
                       ","
                       (map (fn (to, subst) =>
                                colorToString {owner = to, subst = subst})
                            edges)
                   ^ "\n"))
        callees
  fun printColors colors =
      VarID.Map.appi
        (fn (id, color) =>
            print (VarID.toString id
                   ^ " -> "
                   ^ colorToString color
                   ^ "\n"))
        colors
  fun printLabels labels =
      VarID.Map.appi
        (fn (id, label) =>
            print (VarID.toString id ^ " -> " ^ FunLocalLabel.toString label
                   ^ "\n"))
        labels
  fun printVarSubst varSubst =
      VarID.Map.appi
        (fn (id, value) =>
            print (VarID.toString id
                   ^ " -> "
                   ^ (case value of
                        NONE => "NONE"
                      | SOME value => Bug.prettyPrint (R.format_rcvalue value))
                   ^ "\n"))
        varSubst
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
  fun printNumCalls numCalls =
      VarID.Map.appi
        (fn (id, {vars, calls, jumps}) =>
            print (VarID.toString id
                   ^ " -> vars="
                   ^ Int.toString vars
                   ^ ", calls="
                   ^ Int.toString calls
                   ^ ", jumps="
                   ^ Int.toString jumps
                   ^ "\n"))
        numCalls

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

  fun instMap (btvEnv : Types.btvEnv) (instTyList : Types.ty list) =
      ListPair.foldlEq
        (fn (tid, ty, z) => BoundTypeVarID.Map.insert (z, tid, ty))
        BoundTypeVarID.Map.empty
        (BoundTypeVarID.Map.listKeys btvEnv, instTyList)
      handle ListPair.UnequalLengths => raise Bug.Bug "instMap"

  fun makeFunTy {btvEnv, constraints, argTyList, bodyTy} =
      if BoundTypeVarID.Map.isEmpty btvEnv andalso null constraints
      then T.FUNMty (argTyList, bodyTy)
      else T.POLYty {boundtvars = btvEnv,
                     constraints = constraints,
                     body = T.FUNMty (argTyList, bodyTy)}

  fun funApplyTy funTy instTyList =
      case TypesBasics.revealTy (TypesBasics.tpappTy (funTy, instTyList)) of
        T.FUNMty (_, retTy) => retTy
       | _ => raise Bug.Bug "funApplyTy"

  fun putAppSpine funExp funTy ({instTyList, argExpList, loc} :: argList) =
      putAppSpine (R.RCAPPM {funExp = funExp,
                             funTy = funTy,
                             instTyList = instTyList,
                             argExpList = argExpList,
                             loc = loc})
                  (funApplyTy funTy instTyList)
                  argList
    | putAppSpine funExp _ nil = funExp

  fun putFnSpine absList loc bodyExp =
      let
        fun expand ({btvEnv, constraints, argVarList, bodyTy} :: absList) =
            R.RCFNM {btvEnv = btvEnv,
                     constraints = constraints,
                     argVarList = argVarList,
                     bodyExp = expand absList,
                     bodyTy = bodyTy,
                     loc = loc}
          | expand nil = bodyExp
      in
        expand absList
      end

  fun absToArg loc ({btvEnv, constraints, argVarList, ...} : abs) : arg =
      {instTyList = map T.BOUNDVARty (BoundTypeVarID.Map.listKeys btvEnv),
       argExpList = map (varToExp loc) argVarList,
       loc = loc}

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
             btvEnv = BoundTypeVarID.Map.empty,
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
               btvEnv = btvEnv,
               argVarList = argVarList,
               bodyExp = bodyExp,
               bodyTy = bodyTy}
            end
      in
        loop absList exp {tabs = nil, args = nil, bodyTy = expTy}
      end

  fun uncurryApp funTy funLoc (absList : abs list) argList =
      let
        (* due to limitation of RecordCalcRename in polymorphic recursion,
         * polytypes occurring in funTy may have unrenamed bound type
         * variables.  as such, use absList rather than funTy *)
        fun loop ({btvEnv, constraints, argVarList, bodyTy} :: absList)
                 ({instTyList, argExpList, loc} :: argList)
                 {tabs, insts, args, bodyTy = _, loc = _} =
            loop absList
                 argList
                 {tabs = (btvEnv, constraints) :: tabs,
                  insts = instMap btvEnv instTyList :: insts,
                  args = (argVarList, argExpList) :: args,
                  bodyTy = bodyTy,
                  loc = loc}
          | loop (_ :: _) _ _ = raise Bug.Bug "uncurryApp"
          | loop nil argList {args = nil, bodyTy, loc, ...} =
            {App = fn funExp => funExp,
             funTy = bodyTy,
             appTy = bodyTy,
             subst = Subst.identity,
             argVarList = nil,
             argExpList = nil,
             loc = loc,
             restArgs = argList}
          | loop nil argList {tabs, insts, args, bodyTy, loc} =
            let
              val (btvs, cons) = ListPair.unzip (rev tabs)
              val btvEnv = unionBtvMap btvs
              val constraints = List.concat cons
              val instTys = unionBtvMap insts
              val instTyList = BoundTypeVarID.Map.listItems instTys
              val (argVars, argExps) = ListPair.unzip (rev args)
              val argVarList = List.concat argVars
              val argTyList = map #ty argVarList
              val argExpList = List.concat argExps
              val funTy = makeFunTy {btvEnv = btvEnv,
                                     constraints = constraints,
                                     argTyList = argTyList,
                                     bodyTy = bodyTy}
            in
              {App = fn funExp =>
                        R.RCAPPM {funExp = funExp,
                                  funTy = funTy,
                                  instTyList = instTyList,
                                  argExpList = argExpList,
                                  loc = loc},
               funTy = funTy,
               appTy = funApplyTy funTy instTyList,
               subst = Subst.fromTyMap instTys,
               argVarList = argVarList,
               argExpList = argExpList,
               loc = loc,
               restArgs = argList}
            end
      in
        loop absList
             argList
             {tabs = nil, insts = nil, args = nil, bodyTy = funTy, loc = funLoc}
      end

  type catch_rule =
      {subst : Subst.subst,
       catchLabel : FunLocalLabel.id,
       argVarList : RecordCalc.varInfo list,
       catchExp : RecordCalc.rcexp}

  type function =
      {context : {scope : caller, tySubst : Subst.subst},
       subst : Subst.subst,
       loopLabel : FunLocalLabel.id option,
       argVarList : RecordCalc.varInfo list,
       catchRules : catch_rule list,
       bodyExp : RecordCalc.rcexp,
       resultTy : Types.ty,
       loc : RecordCalc.loc}

  type catches = catch_rule list VarID.Map.map
  type inlines = (catches -> function) VarID.Map.map
  type env = {catches : catches, inlines : inlines}

  fun addCatch id rule (env as {catches, ...} : env) =
      case VarID.Map.find (catches, id) of
        NONE => env # {catches = VarID.Map.insert (catches, id, [rule])}
      | SOME t => env # {catches = VarID.Map.insert (catches, id, rule :: t)}

  fun findCatches (catches : catches) id =
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

  type color = {owner : VarID.id, subst : Subst.subst}

  type bind =
      {var : RecordCalc.varInfo,
       exp : RecordCalc.rcexp,
       loc : RecordCalc.loc}

  type context =
      {funcs : CallAnalysis.result VarID.Map.map,
       colors : color VarID.Map.map,
       labels : FunLocalLabel.id VarID.Map.map,
       numCalls : {vars : int, calls : int, jumps : int} VarID.Map.map,
       eta : bind IEnv.map VarID.Map.map,
       argSubst : RecordCalc.rcvalue option VarID.Map.map,
       tySubst : Subst.subst,
       scope : caller,
       isTail : bool,
       env : env}

  fun colorOf colors id =
      case VarID.Map.find (colors, id) of
        NONE => {owner = id, subst = Subst.identity}
      | SOME color => color

  fun instantiateBind subst ({var, exp, loc} : bind) =
      {var = Subst.applyToVar subst var,
       exp = Subst.applyToExp subst exp,
       loc = loc}

  fun findEta ({eta, ...} : context) ({id, ...} : RecordCalc.varInfo) =
      case VarID.Map.find (eta, id) of
        NONE => IEnv.empty
      | SOME etaBinds => etaBinds

  fun addTySubst (context as {tySubst, ...} : context) subst =
      context # {tySubst = Subst.compose (subst, tySubst)}

  fun dropArgVarList ({argSubst, ...} : context) argVarList =
      List.filter
        (fn {id, ...} : RecordCalc.varInfo =>
            not (VarID.Map.inDomain (argSubst, id)))
        argVarList

  fun dropArgExpList ({argSubst, ...} : context) argVarList argExpList =
      List.mapPartial
        (fn ({id, ...} : RecordCalc.varInfo, exp) =>
            if VarID.Map.inDomain (argSubst, id)
            then NONE
            else SOME exp)
        (ListPair.zipEq (argVarList, argExpList)
         handle ListPair.UnequalLengths => raise Bug.Bug "dropArgExpList")

  fun makeVarSubst argVarList argExpList loc =
      ListPair.foldrEq
        (fn (var, R.RCVALUE (value, _), (varSubst, decls)) =>
            (VarID.Map.insert (varSubst, #id var, value), decls)
          | (var, exp, (varSubst, decls)) =>
            (varSubst, R.RCVAL {var = var, exp = exp, loc = loc} :: decls))
        (VarID.Map.empty, nil)
        (argVarList, argExpList)
      handle ListPair.UnequalLengths => raise Bug.Bug "makeVarSubst"

  fun substValue ({argSubst, ...} : context) value =
      case value of
        R.RCCONSTANT _ => value
      | R.RCVAR var =>
        case VarID.Map.find (argSubst, #id var) of
          SOME (SOME value) => value
        | SOME NONE => raise Bug.Bug "substValue"
        | NONE => value

  fun tail (context : context) = context # {isTail = true}

  fun nontail (context : context) = context # {isTail = false}

  fun anonFn (context : context) = context # {scope = ANON, isTail = true}

  fun makeFunction (context : context)
                   id
                   {subst, scope}
                   {argVarList, bodyExp, bodyTy, ...} =
      let
        val loc = RecordCalcLoc.locExp bodyExp
        val label = VarID.Map.find (#labels context, id)
        val {tySubst, ...} = context
      in
        fn catches =>
           {context = {tySubst = tySubst, scope = scope},
            subst = subst,
            loopLabel = label,
            argVarList = argVarList,
            catchRules = findCatches catches id,
            bodyExp = bodyExp,
            resultTy = bodyTy,
            loc = loc}
      end

  datatype transform_bind =
      ENV of env -> env
    | BIND of {var : RecordCalc.varInfo, exp : RecordCalc.rcexp}
    | FUN of {var : RecordCalc.varInfo,
              Fn : RecordCalc.rcexp -> RecordCalc.rcexp,
              function : catches -> function}
    | CATCH of catch_rule * Types.ty

  fun transformBind (context : context) {var as {id, ty, ...}, exp, loc} =
      let
        fun emitInlineFunction info result =
            ENV (addInline id (makeFunction context id info result))
        fun emitFunction (result as {Fn, fnTy, ...}) =
            let
              val info = {subst = Subst.identity, scope = FN id}
              val function = makeFunction context id info result
            in
              FUN {var = var # {ty = fnTy}, Fn = Fn, function = function}
            end
      in
        case VarID.Map.find (#funcs context, id) of
          NONE => BIND {var = var, exp = exp} (* not a named function *)
        | SOME {calls = nil, ...} => ENV (fn x => x) (* dead code *)
        | SOME {absList, ...} =>
          let
            val result = uncurryFn absList exp ty
            val {owner, subst} = colorOf (#colors context) id
          in
            if owner = id
            then case VarID.Map.find (#numCalls context, id) of
                   SOME {vars = 0, calls = 1, ...} =>
                   emitInlineFunction {subst = Subst.identity, scope = FN owner}
                                      result
                 | _ => emitFunction result
            else case VarID.Map.find (#labels context, id) of
                   NONE => emitInlineFunction {subst = subst, scope = FN owner}
                                              result
                 | SOME label =>
                   let
                     val {argVarList, bodyExp, bodyTy, ...} = result
                     val rule = {subst = subst,
                                 catchLabel = label,
                                 argVarList = dropArgVarList context argVarList,
                                 catchExp = bodyExp}
                   in
                     if FN owner = #scope context
                     then CATCH (rule, bodyTy)
                     else ENV (addCatch owner rule)
                   end
          end
      end

  fun transformApp (context : context) funVar funVarLoc argList =
      let
        fun inlineExpand id function {loc, subst, argExpList, ...} =
            let
              (* avoid infinite loop *)
              val context = context # {env = deleteInline (#env context) id}
              val bodyExp = compileFunction context function
              val {argVarList, ...} = function
              val argVarList = map (Subst.applyToVar subst) argVarList
              val (varSubst, decls) = makeVarSubst argVarList argExpList loc
              val subst = {tySubst = Subst.toTyMap subst, varSubst = varSubst}
              val bodyExp =
                  if BoundTypeVarID.Map.isEmpty (#tySubst subst)
                     andalso VarID.Map.isEmpty (#varSubst subst)
                  then bodyExp
                  else RecordCalcType.substExp subst bodyExp
            in
              Let {decls = decls, body = bodyExp, loc = loc}
            end
        fun emitThrow label {argVarList, argExpList, appTy, loc, ...} =
            R.RCTHROW
              {catchLabel = label,
               argExpList = dropArgExpList context argVarList argExpList,
               resultTy = appTy,
               loc = loc}
        fun emitApp id {App, funTy, ...} =
            App (varToExp funVarLoc (funVar # {id = id, ty = funTy}))
      in
        case VarID.Map.find (#funcs context, #id funVar) of
          NONE => putAppSpine (varToExp funVarLoc funVar) (#ty funVar) argList
        | SOME {absList, ...} =>
          let
            val absLen = length absList
            val argLen = length argList
            val (id, ty, absList) =
                if argLen >= absLen
                then (#id funVar, #ty funVar, absList)
                else case IEnv.find (findEta context funVar, argLen) of
                       NONE => raise Bug.Bug "transformApp: eta1"
                     | SOME {var = {id, ty, ...}, ...} =>
                       case VarID.Map.find (#funcs context, id) of
                         NONE => raise Bug.Bug "transformApp: eta2"
                       | SOME {absList, ...} => (id, ty, absList)
            val result = uncurryApp ty funVarLoc absList argList
            val {owner, subst} = colorOf (#colors context) id
            val appExp =
                case findInline (#env context) id of
                  SOME inline => inlineExpand id inline result
                | NONE =>
                  case VarID.Map.find (#labels context, id) of
                    NONE => emitApp id result
                  | SOME label =>
                    if #isTail context
                       andalso FN owner = #scope context
                       andalso Subst.equal
                                 (subst,
                                  Subst.applyToSubst (#tySubst context)
                                                     (#subst result))
                    then emitThrow label result
                    else emitApp id result
          in
            putAppSpine appExp (#appTy result) (#restArgs result)
          end
      end

  and compileFunction context {context = {tySubst, scope}, subst,
                               loopLabel, argVarList,
                               catchRules, bodyExp, resultTy, loc} =
      let
        val context = context # {scope = scope, tySubst = tySubst}
        val context = addTySubst context subst
        val bodyExp =
            Catch {recursive = true,
                   rules = map (compileCatchRule context) catchRules,
                   tryExp = compileExp (tail context) bodyExp,
                   resultTy = resultTy,
                   loc = loc}
        val bodyExp = Subst.applyToExp subst bodyExp
      in
        case loopLabel of
          NONE => bodyExp
        | SOME label =>
          let
            val argVarList = dropArgVarList context argVarList
            val argVarList = map (Subst.applyToVar subst) argVarList
            val resultTy = Subst.apply subst resultTy
          in
            R.RCCATCH
              {recursive = true,
               rules = [{catchLabel = label,
                         argVarList = argVarList,
                         catchExp = bodyExp}],
               tryExp = R.RCTHROW
                          {catchLabel = label,
                           argExpList = map (varToExp loc) argVarList,
                           resultTy = resultTy,
                           loc = loc},
               resultTy = resultTy,
               loc = loc}
          end
      end

  and compileCatchRule context {subst, catchLabel, argVarList, catchExp} =
      let
        val context = addTySubst context subst
        val catchExp = compileExp (tail context) catchExp
      in
        {catchLabel = catchLabel,
         argVarList = map (Subst.applyToVar subst) argVarList,
         catchExp = Subst.applyToExp subst catchExp}
      end

  and compileArg context ({instTyList, argExpList, loc}: arg) : arg =
      {instTyList = instTyList,
       argExpList = map (compileExp (nontail context)) argExpList,
       loc = loc}

  and compileValue context value =
      case substValue context value of
        value as R.RCCONSTANT _ => value
      | value as R.RCVAR var =>
        case IEnv.find (findEta context var, 0) of
          NONE => value
        | SOME {var, ...} => R.RCVAR var

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
          | (funExp, SOME funTy, argList) =>
            let
              val argList = map (compileArg context) argList
              val funExp =
                  case funExp of
                    R.RCVALUE (value, loc) =>
                    R.RCVALUE (substValue context value, loc)
                  | _ => funExp
            in
              case funExp of
                R.RCVALUE (R.RCVAR var, varLoc) =>
                transformApp context var varLoc argList
              | _ =>
                putAppSpine (compileExp (nontail context) funExp) funTy argList
            end
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
        R.RCCATCH
          {recursive = recursive,
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
      | FUN {var, Fn, function} =>
        let
          val function = function (#catches (#env context))
          val bodyExp = compileFunction context function
        in
          SOME {var = var, exp = Fn bodyExp}
        end

  and compileBindAsCatch context result =
      case result of
        ENV _ => NONE
      | CATCH (catchRule, resultTy) =>
        SOME (compileCatchRule context catchRule, resultTy)
      | BIND _ => NONE
      | FUN _ => NONE

  and compileDecl context decl =
      case decl of
        R.RCVAL (bind as {var, loc, ...}) =>
        let
          val binds = bind :: IEnv.listItems (findEta context var)
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
                (map (fn {var, ...} => IEnv.listItems (findEta context var))
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
        {decls = [R.RCEXPORTVAR
                    {weak = weak,
                     var = var,
                     exp = Option.map (compileExp (nontail context)) exp}],
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

  datatype caller_edge =
      ENTRY of bool | JUMP of VarID.id * Subst.subst * arg list
  type callee_edge = VarID.id * Subst.subst

  fun isEntry edges =
      List.exists (fn ENTRY _ => true | JUMP _ => false) edges

  fun argListToSubst (btvEnvList : Types.btvEnv list) (argList : arg list) =
      Subst.fromTyMap
        (unionBtvMap
           (ListPair.mapEq
              (fn (btvEnv, {instTyList, ...}) => instMap btvEnv instTyList)
              (btvEnvList, argList)
              handle ListPair.UnequalLengths => raise Bug.Bug "argListToSubst"))

  fun callsToCallerEdges btvEnvList (calls : call list) =
      map
        (fn (_, _, nil) => ENTRY false
          | (_, CALL, _ :: _) => ENTRY true
          | (ANON, TAIL, _ :: _) => ENTRY true
          | (TOPLEVEL, TAIL, _ :: _) => raise Bug.Bug "callsToCallerEdges"
          | (FN from, TAIL, argList as _ :: _) =>
            JUMP (from, argListToSubst btvEnvList argList, argList))
        calls

  fun funcsToCallers (funcs : CallAnalysis.result VarID.Map.map) =
      VarID.Map.map
        (fn {absList, calls, ...} =>
            callsToCallerEdges (map #btvEnv absList) calls)
        funcs

  fun addCallee to (ENTRY _, callees) = callees
    | addCallee to (JUMP (from, subst, _), callees) =
      case VarID.Map.find (callees, from) of
        NONE => VarID.Map.insert (callees, from, [(to, subst)])
      | SOME edges => VarID.Map.insert (callees, from, (to, subst) :: edges)

  fun callersToCallees callers =
      VarID.Map.foldli
        (fn (to, edges, callees) => foldl (addCallee to) callees edges)
        VarID.Map.empty
        callers

  fun applySubstToCallees fromSubst (callees : callee_edge list) =
      map (fn (to, subst) => (to, Subst.applyToSubst fromSubst subst)) callees

  fun getCallees callees from fromSubst =
      case VarID.Map.find (callees, from) of
        NONE => nil
      | SOME edges => applySubstToCallees fromSubst edges

  fun deleteIncomingEdges (callees : callee_edge list VarID.Map.map) id =
      VarID.Map.map (List.filter (fn (to, _) => to <> id)) callees

  datatype colorify = OK of color VarID.Map.map | NG of VarID.id

  fun colorify graph colors owner =
      let
        fun loop nil colors = OK colors
          | loop ((id, subst) :: stack) colors =
            case VarID.Map.find (colors, id) of
              SOME color =>
              if #owner color = owner andalso Subst.equal (#subst color, subst)
              then loop stack colors
              else NG id
            | NONE =>
              loop (getCallees graph id subst @ stack)
                   (VarID.Map.insert
                      (colors, id, {owner = owner, subst = subst}))
      in
        loop [(owner, Subst.identity)] colors
      end

  fun clustering graph entries =
      let
        fun check graph entries colors nil = colors
          | check graph entries colors (id :: ids) =
            case colorify graph colors id of
              OK colors => check graph entries colors ids
            | NG id =>
              (* if a node has more than one colors, disable its all incoming
               * edges and colorify again. Note that this possibly remove
               * self-recursive edges, which can be always translated into
               * jumps. This is why rebuildCallers is needed *)
              check (deleteIncomingEdges graph id)
                    (id :: entries)
                    VarID.Map.empty
                    (id :: entries)
      in
        check graph entries VarID.Map.empty entries
      end

  fun rebuildCaller colors color (edge as ENTRY _) = edge
    | rebuildCaller colors color (edge as JUMP (from, subst, _)) =
      let
        val {owner, subst = baseSubst} = colorOf colors from
      in
        if owner = #owner color
           andalso Subst.equal (#subst color,
                                Subst.applyToSubst baseSubst subst)
        then edge
        else ENTRY true
      end

  fun rebuildCallers colors callers =
      VarID.Map.mapi
        (fn (id, edges) => map (rebuildCaller colors (colorOf colors id)) edges)
        callers

  fun countEdges edges =
      let
        fun loop nil r = r
          | loop (ENTRY false :: t) {vars, calls, jumps} =
            loop t {vars = vars + 1, calls = calls + 1, jumps = jumps}
          | loop (ENTRY true :: t) {vars, calls, jumps} =
            loop t {vars = vars, calls = calls + 1, jumps = jumps}
          | loop (JUMP (_, _, argList) :: t) {vars, calls, jumps} =
            loop t {vars = vars, calls = calls, jumps = jumps + 1}
      in
        loop edges {vars = 0, calls = 0, jumps = 0}
      end

  fun eqTlconst (R.REAL64 r1, R.REAL64 r2) = Real64.== (r1, r2)
    | eqTlconst (R.REAL64 _, _) = false
    | eqTlconst (R.REAL32 r1, R.REAL32 r2) = Real32.== (r1, r2)
    | eqTlconst (R.REAL32 _, _) = false
    | eqTlconst (R.UNIT, R.UNIT) = true
    | eqTlconst (R.UNIT, _) = false
    | eqTlconst (R.NULLPOINTER, R.NULLPOINTER) = true
    | eqTlconst (R.NULLPOINTER, _) = false
    | eqTlconst (R.NULLBOXED, R.NULLBOXED) = true
    | eqTlconst (R.NULLBOXED, _) = false
    | eqTlconst (R.FOREIGNSYMBOL {name=name1, ty=ty1},
                 R.FOREIGNSYMBOL {name=name2, ty=ty2}) =
      name1 = name2 andalso eqTy ty1 ty2
    | eqTlconst (R.FOREIGNSYMBOL _, _) = false

  fun eqConst (R.INT n1, R.INT n2) = n1 = n2
    | eqConst (R.INT _, _) = false
    | eqConst (R.CONST c1, R.CONST c2) = eqTlconst (c1, c2)
    | eqConst (R.CONST _, _) = false
    | eqConst (R.SIZE (s1, ty1), R.SIZE (s2, ty2)) =
      s1 = s2 andalso eqTy ty1 ty2
    | eqConst (R.SIZE _, _) = false
    | eqConst (R.TAG (s1, ty1), R.TAG (s2, ty2)) =
      s1 = s2 andalso eqTy ty1 ty2
    | eqConst (R.TAG _, _) = false

  fun eqValue (R.RCCONSTANT c1, R.RCCONSTANT c2) = eqConst (c1, c2)
    | eqValue (R.RCCONSTANT _, _) = false
    | eqValue (R.RCVAR {id = id1, ...}, R.RCVAR {id = id2, ...}) = id1 = id2
    | eqValue (R.RCVAR _, _) = false

  datatype arg_value = BOT | VAL of RecordCalc.rcvalue | TOP
  datatype term = NODE of arg_value UnionFind.node | VALUE of arg_value

  (* for debug *)
  fun argValueToString BOT = "BOT"
    | argValueToString TOP = "TOP"
    | argValueToString (VAL value) = Bug.prettyPrint (R.format_rcvalue value)
  fun termToString varNodes (VALUE value) = argValueToString value
    | termToString varNodes (NODE n) =
      case List.find (fn (_, x) => UnionFind.equal (x, n))
                     (VarID.Map.listItemsi varNodes) of
        SOME (id, _) => "[" ^ VarID.toString id ^ "]"
      | NONE => "[]"

  fun equateValue (BOT, v) = v
    | equateValue (v, BOT) = v
    | equateValue (v as TOP, _) = v
    | equateValue (_, v as TOP) = v
    | equateValue (v as VAL v1, VAL v2) = if eqValue (v1, v2) then v else TOP

  fun equate (n, VALUE v) = UnionFind.update equateValue (n, v)
    | equate (n, NODE n2) = ignore (UnionFind.union equateValue (n, n2))

  fun expToTerm varNodes exp =
      case exp of
        R.RCVALUE (value as R.RCCONSTANT _, _) => VALUE (VAL value)
      | R.RCVALUE (R.RCVAR {id, ...}, _) =>
        (case VarID.Map.find (varNodes, id) of
           NONE => VALUE TOP
         | SOME node => NODE node)
      | _ => VALUE TOP

  fun argListToTerms varNodes (argList : arg list) =
      map (expToTerm varNodes) (List.concat (map #argExpList argList))

  fun equateWithCaller varNodes argVarList (ENTRY _) =
      app (fn (var, node) =>
              (*
              print ("entry "
                     ^ VarID.toString (#id var)
                     ^ " "
                     ^ Bug.prettyPrint (R.format_rcvalue (R.RCVAR var))
                     ^ "\n")
              *)
              UnionFind.update equateValue (node, VAL (R.RCVAR var)))
          argVarList
    | equateWithCaller varNodes argVarList (JUMP (_, _, argList)) =
      ListPair.appEq
        (fn ((var, node), term) =>
            (*
            print ("equate "
                   ^ VarID.toString (#id var)
                   ^ " "
                   ^ termToString varNodes term
                   ^ "\n")
            *)
            equate (node, term))
        (argVarList, argListToTerms varNodes argList)
      handle ListPair.UnequalLengths => raise Bug.Bug "equateWithCaller"

  fun propagateArgs funcs =
      let
        (* create a union-find node for each function parameter *)
        val funcs =
            VarID.Map.map
              (fn {absList : abs list, edges} =>
                  let
                    val argVarList = List.concat (map #argVarList absList)
                    val argVarList = map (fn var => (var, UnionFind.new BOT))
                                         argVarList
                  in
                    {argVarList = argVarList, edges = edges}
                  end)
              funcs

        (* create a map from parameter variables to union-find nodes *)
        val varNodes =
            VarID.Map.foldl
              (fn ({argVarList, ...}, vars) =>
                  foldl (fn (({id, ...}, node), vars) =>
                            VarID.Map.insert (vars, id, node))
                        vars
                        argVarList)
              VarID.Map.empty
              funcs

        (* solve the system of equations between variables and values *)
        val () =
            VarID.Map.app
              (fn {argVarList, edges} =>
                  app (equateWithCaller varNodes argVarList) edges)
              funcs
      in
        VarID.Map.mapPartial
          (fn node =>
              case UnionFind.find node of
                TOP => NONE
              | BOT => SOME NONE
              | VAL value => SOME (SOME value))
          varNodes
      end

  fun solve (funcs : CallAnalysis.result VarID.Map.map) =
      let
        val callers = funcsToCallers funcs
        val entries = VarID.Map.listKeys (VarID.Map.filter isEntry callers)
        val callees = callersToCallees callers
        val colors = clustering callees entries
        val callers = rebuildCallers colors callers
        val numCalls = VarID.Map.map countEdges callers

        (* blocks having multiple incoming edges must have a label *)
        val labels =
            VarID.Map.mergeWith
              (fn (SOME _, NONE) => NONE
                | (NONE, _) => raise Bug.Bug "solve"
                | (SOME {var, ...}, SOME {calls, jumps, ...}) =>
                  if (if calls > 0 then 1 else 0) + jumps > 1
                  then SOME (FunLocalLabel.generate (#path var))
                  else NONE)
              (funcs, numCalls)

        (* propagate arguments between jumps.
         * This is needed for not only optimization but bitmap compilation *)
        val varSubst =
            propagateArgs
              (VarID.Map.mergeWith
                 (fn (SOME _, NONE) => NONE
                   | (NONE, _) => raise Bug.Bug "solve"
                   | (SOME {absList, ...}, SOME edges) =>
                     SOME {absList = absList, edges = edges})
                 (funcs, callers))
      in
        (*
        print "## funcs\n";
        printFuncs funcs;
        print "## callees\n";
        printCallees callees entries;
        print "## colors\n";
        printColors colors;
        print "## labels\n";
        printLabels labels;
        print "## numCalls\n";
        printNumCalls numCalls;
        print "## varSubst\n";
        printVarSubst varSubst;
        *)
        (colors, labels, numCalls, varSubst)
      end

  fun renameVar btvMap ({id, ty, path} : RecordCalc.varInfo) =
      {id = VarID.generate (),
       ty = TyAlphaRename.copyTy btvMap ty,
       path = path}

  fun renameAbsList absList funTy =
      let
        fun rename ({btvEnv, constraints, argVarList, bodyTy} :: absList)
                   _
                   btvMap =
            let
              val (btvMap, btvEnv) = TyAlphaRename.newBtvEnv btvMap btvEnv
              val constraints =
                  map (TyAlphaRename.copyConstraint btvMap) constraints
              val argVarList = map (renameVar btvMap) argVarList
              val (bodyTy, absList) = rename absList bodyTy btvMap
              val abs = {btvEnv = btvEnv,
                         constraints = constraints,
                         argVarList = argVarList,
                         bodyTy = bodyTy}
              val funTy = makeFunTy {btvEnv = btvEnv,
                                     constraints = constraints,
                                     argTyList = map #ty argVarList,
                                     bodyTy = bodyTy}
            in
              (funTy, abs :: absList)
            end
          | rename nil bodyTy btvMap =
            (TyAlphaRename.copyTy btvMap bodyTy, nil)
      in
        rename absList funTy BoundTypeVarID.Map.empty
      end

  fun etaExpand id (func as {var, loc, absList, calls}) =
      let
        val absLen = length absList
        val calls = map (fn call as (_ , _, args) => (call, length args)) calls
        fun filterByNumArgs n calls =
            List.mapPartial
              (fn (call : call, m : int) => if m = n then SOME call else NONE)
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
          (* generate fresh abs list for each eta-expanded functions *)
          val etaMap =
              IEnv.map
                (fn id =>
                    let
                      val (funTy, absList) = renameAbsList absList (#ty var)
                      val var = var # {id = id, ty = funTy}
                      val argList = map (absToArg loc) absList
                    in
                      {var = var, absList = absList, argList = argList}
                    end)
                etaMap

          (* separate smaller calls into calls to eta-expanded functions *)
          val etaCalls =
              IEnv.listItems
                (IEnv.map (fn {argList, ...} => (ANON, TAIL, argList)) etaMap)
          val func = func # {calls = filterByNumArgs absLen calls @ etaCalls}
          val funcs =
              IEnv.foldli
                (fn (argLen, {var = {id, ...}, absList, ...}, funcs) =>
                    VarID.Map.insert
                      (funcs, id, {var = var # {id = id},
                                   loc = loc,
                                   absList = List.take (absList, argLen),
                                   calls = filterByNumArgs argLen calls}))
                (VarID.Map.singleton (id, func))
                etaMap

          (* generate eta-expanded function definitions *)
          val funExp = varToExp loc var
          val funTy = #ty var
          val etaMap =
              IEnv.map
                (fn {var, absList, argList} =>
                    let
                      val appExp = putAppSpine funExp funTy argList
                      val fnExp = putFnSpine absList loc appExp
                    in
                      {var = var, exp = fnExp, loc = loc}
                    end)
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
        (*
        val _ = print "## funcs\n"
        val _ = printFuncs funcs
        *)
        val {funcs, eta} = generateEtaExpansions funcs
        (*
        val _ = print "## eta\n"
        val _ = printEta eta
        *)
        val (colors, labels, numCalls, argSubst) = solve funcs
        val context = {funcs = funcs,
                       colors = colors,
                       labels = labels,
                       numCalls = numCalls,
                       eta = eta,
                       argSubst = argSubst,
                       tySubst = Subst.identity,
                       scope = TOPLEVEL,
                       isTail = false,
                       env = {inlines = VarID.Map.empty,
                              catches = VarID.Map.empty}} : context
      in
        compileDecls context decls
      end

end
