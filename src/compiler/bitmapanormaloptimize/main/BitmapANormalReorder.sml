(**
 * computation reordering on BitmapANormal.
 *
 * @copyright (c) 2012, Tohoku University.
 * @author UENO Katsuhiro
 *
 * This optimization reorders local variable declarations so that each
 * local variable has least live range. This simultaneously performs
 * the dead-code elimination.
 * It is not recommended to turn off this optimization because it
 * significantly reduces the cost of compilation algorithms of the
 * compiler backend, such as register allocation.
 *
 *)
structure BitmapANormalReorder : sig

  val optimize : BitmapANormal.baexp -> BitmapANormal.baexp

end =
struct

  structure B = BitmapANormal

  local

    fun fvVar bv fv (var as {id, ...}:B.varInfo) =
        if VarID.Set.member (bv, id)
        then fv
        else VarID.Map.insert (fv, id, var)

    fun fvVars bv fv vars =
        foldl (fn (var,fv) => fvVar bv fv var) fv vars

    fun fvValue bv fv value =
        case value of
          B.BACONST _ => fv
        | B.BAVAR var => fvVar bv fv var
        | B.BACAST {exp, expTy, targetTy} => fvValue bv fv exp
        | B.BATAPP {exp, expTy, instTyList} => fvValue bv fv exp

    fun fvValues bv fv values =
        foldl (fn (v,fv) => fvValue bv fv v) fv values

    fun fvPrim bv fv prim =
        case prim of
          B.BAVALUE value => fvValue bv fv value
        | B.BAEXVAR _ => fv
        | B.BAPRIMAPPLY {primInfo, argExpList, instTyList, instTagList,
                         instSizeList} =>
          let
            val fv = fvValues bv fv argExpList
            val fv = fvValues bv fv instTagList
            val fv = fvValues bv fv instSizeList
          in
            fv
          end
        | B.BARECORD {fieldList, recordTy, annotation, isMutable, clearPad,
                      totalSizeExp, bitmapExpList} =>
          let
            val fv =
                foldl
                  (fn ({fieldExp, fieldTy, fieldLabel, fieldSize,
                        fieldIndex}, fv) =>
                      fvValues bv fv [fieldExp, fieldSize, fieldIndex])
                  fv
                  fieldList
            val fv = fvValues bv fv (totalSizeExp :: bitmapExpList)
          in
            fv
          end
        | B.BASELECT {recordExp, indexExp, label, recordTy, resultTy,
                      resultSize} =>
          fvValues bv fv [recordExp, indexExp, resultSize]
        | B.BAMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy,
                      valueTag, valueSize} =>
          fvValues bv fv [recordExp, indexExp, valueExp, valueTag, valueSize]

    fun fvCall bv fv call =
        case call of
          B.BAFOREIGNAPPLY {funExp, foreignFunTy, argExpList} =>
          fvValues bv fv (funExp :: argExpList)
        | B.BAAPPM {funExp, funTy, argExpList} =>
          fvValues bv fv (funExp :: argExpList)

    fun addBv (set, {id,...}:B.varInfo) = VarID.Set.add (set, id)
    fun addBvs (set, vars) = foldl (fn (x,z) => addBv (z,x)) set vars

    fun fvSwitch bv fv ({switchExp, expTy, branches, defaultExp,
                         loc}:B.switch) =
        let
          val fv = fvValue bv fv switchExp
          val fv = foldl (fn ({constant, branchExp}, fv) =>
                             fvExp bv fv branchExp)
                         fv
                         branches
          val fv = fvExp bv fv defaultExp
        in
          fv
        end

    and fvFunction bv fv ({argVarList, funTy, bodyExp, annotation,
                           closureLayout, loc}:B.function) =
        fvExp (addBvs (bv, argVarList)) fv bodyExp

    and fvRecBinds bv fv recbindList =
        let
          val bv =
              foldl (fn ({boundVar,function},bv) => addBv (bv, boundVar))
                    bv
                    recbindList
          val fv =
              foldl (fn ({boundVar,function},fv) => fvFunction bv fv function)
                    fv
                    recbindList
        in
          (bv, fv)
        end

    and fvHandle bv fv (tryExp, exnVar, handlerExp) =
        let
          val fv = fvExp bv fv tryExp
          val fv = fvExp (addBv (bv, exnVar)) fv handlerExp
        in
          fv
        end

    and fvExp bv fv exp =
        case exp of
          B.BAVAL {boundVar, boundExp, nextExp, loc} =>
          fvExp (addBv (bv, boundVar)) (fvPrim bv fv boundExp) nextExp
        | B.BACALL {resultVars, callExp, nextExp, loc} =>
          fvExp (addBvs (bv, resultVars)) (fvCall bv fv callExp) nextExp
        | B.BAEXTERNVAR {exVarInfo, nextExp, loc} =>
          fvExp bv fv nextExp
        | B.BAEXPORTVAR {varInfo, varSize, varTag, nextExp, loc} =>
          let
            val fv = fvVar bv fv varInfo
            val fv = fvValues bv fv [varSize, varTag]
          in
            fvExp bv fv nextExp
          end
        | B.BAFNM {boundVar, btvEnv, function, nextExp} =>
          fvExp (addBv (bv, boundVar)) (fvFunction bv fv function) nextExp
        | B.BACALLBACKFNM {boundVar, function, foreignFunTy, nextExp} =>
          fvExp (addBv (bv, boundVar)) (fvFunction bv fv function) nextExp
        | B.BAVALREC {recbindList, nextExp, loc} =>
          let
            val (bv, fv) = fvRecBinds bv fv recbindList
          in
            fvExp bv fv nextExp
          end
        | B.BAHANDLE {resultVars, tryExp, exnVar, handlerExp, nextExp, loc} =>
          fvExp (addBvs (bv, resultVars))
                (fvHandle bv fv (tryExp, exnVar, handlerExp))
                nextExp
        | B.BASWITCH {resultVars, switch, nextExp} =>
          fvExp (addBvs (bv, resultVars)) (fvSwitch bv fv switch) nextExp
        | B.BATAILSWITCH switch =>
          fvSwitch bv fv switch
        | B.BAPOLY {resultVars, btvEnv, expTyWithoutTAbs, exp, nextExp, loc} =>
          fvExp (addBvs (bv, resultVars)) (fvExp bv fv exp) nextExp
        | B.BAMERGE resultVars =>
          fvVars bv fv resultVars
        | B.BARETURN {resultVars, funTy, loc} =>
          fvVars bv fv resultVars
        | B.BATAILAPPM {funExp, funTy, argExpList, loc} =>
          fvValues bv fv (funExp :: argExpList)
        | B.BARAISE {argExp, loc} =>
          fvValue bv fv argExp

  in

  fun freeVarsValue value =
      VarID.Map.listItems (fvValue VarID.Set.empty VarID.Map.empty value)
  fun freeVarsValueList values =
      VarID.Map.listItems (fvValues VarID.Set.empty VarID.Map.empty values)
  fun freeVarsExp exp =
      VarID.Map.listItems (fvExp VarID.Set.empty VarID.Map.empty exp)
  fun freeVarsSwitch switch =
      VarID.Map.listItems (fvSwitch VarID.Set.empty VarID.Map.empty switch)
  fun freeVarsFunction func =
      VarID.Map.listItems (fvFunction VarID.Set.empty VarID.Map.empty func)
  fun freeVarsRecBind binds =
      VarID.Map.listItems
        (#2 (fvRecBinds VarID.Set.empty VarID.Map.empty binds))
  fun freeVarsPrim prim =
      VarID.Map.listItems (fvPrim VarID.Set.empty VarID.Map.empty prim)
  fun freeVarsCall call =
      VarID.Map.listItems (fvCall VarID.Set.empty VarID.Map.empty call)

  fun freeVarsHandle handleExps =
      VarID.Map.listItems (fvHandle VarID.Set.empty VarID.Map.empty handleExps)

  end (* local *)

  local

    fun alphaVar subst (var as {id, ty, path}:B.varInfo) =
        case VarID.Map.find (subst, id) of
          NONE => raise Control.Bug "alphaVar"
        | SOME id => {id=id, ty=ty, path=path}

    fun alphaValue subst value =
        case value of
          B.BACONST _ => value
        | B.BAVAR var => B.BAVAR (alphaVar subst var)
        | B.BACAST {exp, expTy, targetTy} =>
          B.BACAST {exp = alphaValue subst exp,
                    expTy = expTy,
                    targetTy = targetTy}
        | B.BATAPP {exp, expTy, instTyList} =>
          B.BATAPP {exp = alphaValue subst exp,
                    expTy = expTy,
                    instTyList = instTyList}

    fun alphaPrim subst prim =
        case prim of
          B.BAVALUE value =>
          B.BAVALUE (alphaValue subst value)
        | B.BAEXVAR _ => prim
        | B.BAPRIMAPPLY {primInfo, argExpList, instTyList, instTagList,
                         instSizeList} =>
          B.BAPRIMAPPLY {primInfo = primInfo,
                         argExpList = map (alphaValue subst) argExpList,
                         instTyList = instTyList,
                         instTagList = map (alphaValue subst) instTagList,
                         instSizeList = map (alphaValue subst) instSizeList}
        | B.BARECORD {fieldList, recordTy, annotation, isMutable, clearPad,
                      totalSizeExp, bitmapExpList} =>
          B.BARECORD {fieldList =
                        map (fn {fieldExp, fieldTy, fieldLabel,
                                 fieldSize, fieldIndex} =>
                                {fieldExp = alphaValue subst fieldExp,
                                 fieldTy = fieldTy,
                                 fieldLabel = fieldLabel,
                                 fieldSize = alphaValue subst fieldSize,
                                 fieldIndex = alphaValue subst fieldIndex})
                            fieldList,
                      recordTy = recordTy,
                      annotation = annotation,
                      isMutable = isMutable,
                      clearPad = clearPad,
                      totalSizeExp = alphaValue subst totalSizeExp,
                      bitmapExpList = map (alphaValue subst) bitmapExpList}
        | B.BASELECT {recordExp, indexExp, label, recordTy, resultTy,
                      resultSize} =>
          B.BASELECT {recordExp = alphaValue subst recordExp,
                      indexExp = alphaValue subst indexExp,
                      label = label,
                      recordTy = recordTy,
                      resultTy = resultTy,
                      resultSize = alphaValue subst resultSize}
        | B.BAMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy,
                      valueTag, valueSize} =>
          B.BAMODIFY {recordExp = alphaValue subst recordExp,
                      recordTy = recordTy,
                      indexExp = alphaValue subst indexExp,
                      label = label,
                      valueExp = alphaValue subst valueExp,
                      valueTy = valueTy,
                      valueTag = alphaValue subst valueTag,
                      valueSize = alphaValue subst valueSize}

    fun alphaCall subst call =
        case call of
          B.BAFOREIGNAPPLY {funExp, foreignFunTy, argExpList} =>
          B.BAFOREIGNAPPLY {funExp = alphaValue subst funExp,
                            foreignFunTy = foreignFunTy,
                            argExpList = map (alphaValue subst) argExpList}
        | B.BAAPPM {funExp, funTy, argExpList} =>
          B.BAAPPM {funExp = alphaValue subst funExp,
                    funTy = funTy,
                    argExpList = map (alphaValue subst) argExpList}

    fun addVar subst (var as {id, ty, path}:B.varInfo) =
        case VarID.Map.find (subst, id) of
          NONE => (VarID.Map.insert (subst, id, id), var)
        | SOME _ =>
          let
            val newId = VarID.generate ()
            val subst = VarID.Map.insert (subst, id, newId)
            val var = {id=newId, ty=ty, path=path} : B.varInfo
          in
            (subst, var)
          end

    fun addVars subst nil = (subst, nil)
      | addVars subst (var::vars) =
        let
          val (subst, var) = addVar subst var
          val (subst, vars) = addVars subst vars
        in
          (subst, var::vars)
        end

    fun alphaSwitch subst ({switchExp, expTy, branches, defaultExp,
                            loc}:B.switch) =
        {switchExp = alphaValue subst switchExp,
         expTy = expTy,
         branches = map (fn {constant, branchExp} =>
                            {constant = constant,
                             branchExp = alphaExp subst branchExp})
                        branches,
         defaultExp = alphaExp subst defaultExp,
         loc = loc}
        : B.switch

    and alphaFunction subst ({argVarList, funTy, bodyExp, annotation,
                              closureLayout, loc}:B.function) =
        let
          val (subst, argVarList) = addVars subst argVarList
        in
          {argVarList = argVarList,
           funTy = funTy,
           bodyExp = alphaExp subst bodyExp,
           annotation = annotation,
           closureLayout = closureLayout,
           loc = loc}
          : B.function
        end

    and alphaExp subst exp =
        case exp of
          B.BAVAL {boundVar, boundExp, nextExp, loc} =>
          let
            val (newSubst, boundVar) = addVar subst boundVar
          in
            B.BAVAL {boundVar = boundVar,
                     boundExp = alphaPrim subst boundExp,
                     nextExp = alphaExp newSubst nextExp,
                     loc = loc}
          end
        | B.BACALL {resultVars, callExp, nextExp, loc} =>
          let
            val (newSubst, resultVars) = addVars subst resultVars
          in
            B.BACALL {resultVars = resultVars,
                      callExp = alphaCall subst callExp,
                      nextExp = alphaExp newSubst nextExp,
                      loc = loc}
          end
        | B.BAEXTERNVAR {exVarInfo, nextExp, loc} =>
          B.BAEXTERNVAR {exVarInfo = exVarInfo,
                         nextExp = alphaExp subst nextExp,
                         loc = loc}
        | B.BAEXPORTVAR {varInfo, varSize, varTag, nextExp, loc} =>
          B.BAEXPORTVAR {varInfo = alphaVar subst varInfo,
                         varSize = alphaValue subst varSize,
                         varTag = alphaValue subst varTag,
                         nextExp = alphaExp subst nextExp,
                         loc = loc}
        | B.BAFNM {boundVar, btvEnv, function, nextExp} =>
          let
            val (newSubst, boundVar) = addVar subst boundVar
          in
            B.BAFNM {boundVar = boundVar,
                     btvEnv = btvEnv,
                     function = alphaFunction subst function,
                     nextExp = alphaExp newSubst nextExp}
          end
        | B.BACALLBACKFNM {boundVar, function, foreignFunTy, nextExp} =>
          let
            val (newSubst, boundVar) = addVar subst boundVar
          in
            B.BACALLBACKFNM {boundVar = boundVar,
                             function = alphaFunction subst function,
                             foreignFunTy = foreignFunTy,
                             nextExp = alphaExp newSubst nextExp}
          end
        | B.BAVALREC {recbindList, nextExp, loc} =>
          let
            val (subst, boundVars) = addVars subst (map #boundVar recbindList)
            val recbindList =
                ListPair.mapEq
                  (fn (boundVar, {function, ...}) =>
                      {boundVar = boundVar,
                       function = alphaFunction subst function})
                  (boundVars, recbindList)
          in
            B.BAVALREC {recbindList = recbindList,
                        nextExp = alphaExp subst nextExp,
                        loc = loc}
          end
        | B.BAHANDLE {resultVars, tryExp, exnVar, handlerExp, nextExp, loc} =>
          let
            val (substHandler, exnVar) = addVar subst exnVar
            val (newSubst, resultVars) = addVars subst resultVars
          in
            B.BAHANDLE {resultVars = resultVars,
                        tryExp = alphaExp subst tryExp,
                        exnVar = exnVar,
                        handlerExp = alphaExp substHandler handlerExp,
                        nextExp = alphaExp newSubst nextExp,
                        loc = loc}
          end
        | B.BASWITCH {resultVars, switch, nextExp} =>
          let
            val (newSubst, resultVars) = addVars subst resultVars
          in
            B.BASWITCH {resultVars = resultVars,
                        switch = alphaSwitch subst switch,
                        nextExp = alphaExp newSubst nextExp}
          end
        | B.BATAILSWITCH switch =>
          B.BATAILSWITCH (alphaSwitch subst switch)
        | B.BAPOLY {resultVars, btvEnv, expTyWithoutTAbs, exp, nextExp, loc} =>
          let
            val (newSubst, resultVars) = addVars subst resultVars
          in
            B.BAPOLY {resultVars = resultVars,
                      btvEnv = btvEnv,
                      expTyWithoutTAbs = expTyWithoutTAbs,
                      exp = alphaExp subst exp,
                      nextExp = alphaExp newSubst nextExp,
                      loc = loc}
          end
        | B.BAMERGE resultVars =>
          B.BAMERGE (map (alphaVar subst) resultVars)
        | B.BARETURN {resultVars, funTy, loc} =>
          B.BARETURN {resultVars = map (alphaVar subst) resultVars,
                      funTy = funTy,
                      loc = loc}
        | B.BATAILAPPM {funExp, funTy, argExpList, loc} =>
          B.BATAILAPPM {funExp = alphaValue subst funExp,
                        funTy = funTy,
                        argExpList = map (alphaValue subst) argExpList,
                        loc = loc}
        | B.BARAISE {argExp, loc} =>
          B.BARAISE {argExp = alphaValue subst argExp,
                     loc = loc}

  in

  fun renameVarsExp exp =
      alphaExp VarID.Map.empty exp

  end (* local *)

  fun hasSideEffect prim =
      case prim of
        B.BAVALUE _ => false
      | B.BAEXVAR _ => false
      | B.BAPRIMAPPLY {primInfo={primitive, ty},...} =>
        let
          val {memory, update, read, throw} =
              BuiltinPrimitive.haveSideEffect primitive
        in
          memory orelse update orelse read orelse throw
        end
      | B.BARECORD _ => false
      | B.BASELECT _ => false
      | B.BAMODIFY _ => false

  type expFn = (VarID.Set.set -> B.baexp) -> (VarID.Set.set -> B.baexp)
  type env = expFn VarID.Map.map

  val dummyExp : VarID.Set.set -> B.baexp =
      fn _ => raise Control.Bug "dummyExp"

  fun addBind env ({id,...}:B.varInfo, expFn) =
      VarID.Map.insert (env, id, expFn)
  fun addBinds env (vars, expFn) =
      foldl (fn (v,z) => addBind z (v, expFn)) env vars

  fun addVar (set, {id,...}:B.varInfo) =
      VarID.Set.add (set, id)
  fun addVars (set, vars) =
      foldl (fn (v,z) => addVar (z,v)) set vars

  fun forceVars (env:env) (vars:B.varInfo list) nextExp defined =
      case vars of
        nil => nextExp defined
      | {id,...}::vars =>
        if VarID.Set.member (defined, id)
        then forceVars env vars nextExp defined
        else case VarID.Map.find (env, id) of
               NONE => raise Control.Bug ("forceVars: " ^ VarID.toString id)
             | SOME expFn => expFn (forceVars env vars nextExp) defined

  fun optimizeSwitch env ({switchExp, expTy, branches, defaultExp,
                           loc}:B.switch) defined =
      {switchExp = switchExp,
       expTy = expTy,
       branches = map (fn {constant, branchExp} =>
                          {constant = constant,
                           branchExp = (optimizeExp env branchExp)
                                         dummyExp defined})
                      branches,
       defaultExp = (optimizeExp env defaultExp) dummyExp defined,
       loc = loc}
      : B.switch

  and optimizeFunction env ({argVarList, funTy, bodyExp, annotation,
                             closureLayout, loc}:B.function) defined =
      let
        val defined = addVars (defined, argVarList)
      in
        {argVarList = argVarList,
         funTy = funTy,
         bodyExp = (optimizeExp env bodyExp) dummyExp defined,
         annotation = annotation,
         closureLayout = closureLayout,
         loc = loc}
        : B.function
      end

  and optimizeRecBind (env:env) recbinds defined =
      let
        val defined = addVars (defined, map #boundVar recbinds)
      in
        map (fn {boundVar, function} =>
                {boundVar = boundVar,
                 function = (optimizeFunction env function) defined})
            recbinds
      end

  and optimizeExp env exp : expFn =
      case exp of
        B.BAVAL {boundVar, boundExp, nextExp, loc} =>
        let
          fun expFn nextExp =
              (forceVars env (freeVarsPrim boundExp))
                (fn defined =>
                    B.BAVAL {boundVar = boundVar,
                             boundExp = boundExp,
                             nextExp = nextExp (addVar (defined, boundVar)),
                             loc = loc})
        in
          if hasSideEffect boundExp
          then expFn o optimizeExp env nextExp
          else optimizeExp (addBind env (boundVar, expFn)) nextExp
        end
      | B.BACALL {resultVars, callExp, nextExp, loc} =>
        let
          fun expFn nextExp =
              (forceVars env (freeVarsCall callExp))
                (fn defined =>
                    B.BACALL
                      {resultVars = resultVars,
                       callExp = callExp,
                       nextExp = nextExp (addVars (defined, resultVars)),
                       loc = loc})
        in
          expFn o optimizeExp env nextExp
        end
      | B.BAEXTERNVAR {exVarInfo, nextExp, loc} =>
        let
          fun expFn nextExp =
              (fn defined =>
                  B.BAEXTERNVAR {exVarInfo = exVarInfo,
                                 nextExp = nextExp defined,
                                 loc = loc})
        in
          expFn o optimizeExp env nextExp
        end
      | B.BAEXPORTVAR {varInfo, varSize, varTag, nextExp, loc} =>
        let
          fun expFn nextExp =
              (forceVars env (varInfo :: freeVarsValueList [varSize, varTag]))
                (fn defined =>
                    B.BAEXPORTVAR {varInfo = varInfo,
                                   varSize = varSize,
                                   varTag = varTag,
                                   nextExp = nextExp defined,
                                   loc = loc})
        in
          expFn o optimizeExp env nextExp
        end
      | B.BAFNM {boundVar, btvEnv, function, nextExp} =>
        let
          fun expFn nextExp =
              (forceVars env (freeVarsFunction function))
                (fn defined =>
                    B.BAFNM
                      {boundVar = boundVar,
                       btvEnv = btvEnv,
                       function = (optimizeFunction env function) defined,
                       nextExp = nextExp (addVar (defined, boundVar))})
        in
          optimizeExp (addBind env (boundVar, expFn)) nextExp
        end
      | B.BACALLBACKFNM {boundVar, function, foreignFunTy, nextExp} =>
        let
          fun expFn nextExp =
              (forceVars env (freeVarsFunction function))
                (fn defined =>
                    B.BACALLBACKFNM
                      {boundVar = boundVar,
                       function = (optimizeFunction env function) defined,
                       foreignFunTy = foreignFunTy,
                       nextExp = nextExp (addVar (defined, boundVar))})
        in
          optimizeExp (addBind env (boundVar, expFn)) nextExp
        end
      | B.BAVALREC {recbindList, nextExp, loc} =>
        let
          val boundVars = map #boundVar recbindList
          fun expFn nextExp =
              (forceVars env (freeVarsRecBind recbindList))
                (fn defined =>
                    B.BAVALREC
                      {recbindList = (optimizeRecBind env recbindList) defined,
                       nextExp = nextExp (addVars (defined, boundVars)),
                       loc = loc})
        in
          optimizeExp (addBinds env (boundVars, expFn)) nextExp
        end
      | B.BAHANDLE {resultVars, tryExp, exnVar, handlerExp, nextExp, loc} =>
        let
          fun expFn nextExp =
              (forceVars env (freeVarsHandle (tryExp, exnVar, handlerExp)))
                (fn defined =>
                    B.BAHANDLE
                      {resultVars = resultVars,
                       tryExp = (optimizeExp env tryExp) dummyExp defined,
                       exnVar = exnVar,
                       handlerExp = (optimizeExp env handlerExp)
                                      dummyExp (addVar (defined, exnVar)),
                       nextExp = nextExp (addVars (defined, resultVars)),
                       loc = loc})
        in
          expFn o optimizeExp env nextExp
        end
      | B.BASWITCH {resultVars, switch, nextExp} =>
        let
          fun expFn nextExp =
              (forceVars env (freeVarsSwitch switch))
                (fn defined =>
                    B.BASWITCH
                      {resultVars = resultVars,
                       switch = (optimizeSwitch env switch) defined,
                       nextExp = nextExp (addVars (defined, resultVars))})
        in
          expFn o optimizeExp env nextExp
        end
      | B.BATAILSWITCH switch =>
        (fn _ =>
            (forceVars env (freeVarsSwitch switch))
              (fn defined =>
                  B.BATAILSWITCH ((optimizeSwitch env switch) defined)))
      | B.BAPOLY {resultVars, btvEnv, expTyWithoutTAbs, exp, nextExp, loc} =>
        let
          fun expFn nextExp =
              (forceVars env (freeVarsExp exp))
                (fn defined =>
                    B.BAPOLY
                      {resultVars = resultVars,
                       btvEnv = btvEnv,
                       expTyWithoutTAbs = expTyWithoutTAbs,
                       exp = (optimizeExp env exp) dummyExp defined,
                       nextExp = nextExp (addVars (defined, resultVars)),
                       loc = loc})
        in
          expFn o optimizeExp env nextExp
        end
      | B.BAMERGE resultVars =>
        (fn _ => (forceVars env resultVars) (fn _ => exp))
      | B.BARETURN {resultVars, funTy, loc} =>
        (fn _ => (forceVars env resultVars) (fn _ => exp))
      | B.BATAILAPPM {funExp, funTy, argExpList, loc} =>
        (fn _ =>
            (forceVars env (freeVarsValueList (funExp :: argExpList)))
              (fn _ => exp))
      | B.BARAISE {argExp, loc} =>
        (fn _ => (forceVars env (freeVarsValue argExp)) (fn _ => exp))

  fun optimize exp =
      let
        val exp = renameVarsExp exp
        val expFn = optimizeExp VarID.Map.empty exp
      in
        expFn dummyExp VarID.Set.empty
      end

end
