(**
 * calling compilation compile
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)
structure ANormalize : sig

  val compile : RuntimeCalc.program -> ANormal.program

end =
struct

  structure N = RuntimeCalc
  structure A = ANormal
  (* structure T = Types *)
  structure R = RuntimeTypes

  (* reuse var ids as many as possible *)
  val usedVarIds = ref VarID.Set.empty

  fun freshVarId id =
      if VarID.Set.member (!usedVarIds, id)
      then VarID.generate ()
      else (usedVarIds := VarID.Set.add (!usedVarIds, id); id)

  fun initUsedIds () =
      usedVarIds := VarID.Set.empty

  fun newVar ty =
      {id = VarID.generate (), ty = ty} : A.varInfo

  fun refreshVar ({id, ty}:A.varInfo) =
      {id = freshVarId id, ty = ty} : A.varInfo

  val emptyProc = fn x:A.anexp => x

  datatype context = TAIL | NONTAIL | BIND of A.varInfo

  val unitTy = (BuiltinTypes.unitTy, RuntimeTypes.unitTy)
  val unitValue =
      A.ANCONST {const = A.NVUNIT, ty = unitTy}

  val intInfTy = (BuiltinTypes.intInfTy, RuntimeTypes.recordTy)

  fun toConst (A.ANCONST x) = SOME x
    | toConst (A.ANVAR _) = NONE
    | toConst A.ANBOTTOM = NONE
    | toConst (A.ANCAST {exp, expTy, targetTy}) =
      case toConst exp of
        NONE => NONE
      | SOME {const, ty} =>
        SOME {const = A.NVCAST {value = const,
                                valueTy = ty,
                                targetTy = targetTy,
                                cast = BuiltinPrimitive.TypeCast},
              ty = targetTy}

  datatype handler =
      NO_HANDLER
    | HANDLER of {handlerLabel : HandlerLabel.id, localLabel : FunLocalLabel.id}
    | CLEANUP of HandlerLabel.id option ref

  type env =
       {funId : FunEntryLabel.id option,
        loopLabel : FunLocalLabel.id option ref,
        handler : handler,
        varEnv : A.anvalue VarID.Map.map}

  fun getHandlerLabel ({handler,...}:env) =
      case handler of
        NO_HANDLER => NONE
      | HANDLER {handlerLabel, ...} => SOME handlerLabel
      | CLEANUP (ref (x as SOME _)) => x
      | CLEANUP (r as ref NONE) =>
        let val x = SOME (HandlerLabel.generate nil) in r := x; x end

  fun getCleanupLabel env =
      case #handler env of
        CLEANUP _ => getHandlerLabel env
      | _ => NONE

  fun bindVar (env:env, {id,...}:A.varInfo, value) =
      env # {varEnv = VarID.Map.insert (#varEnv env, id, value)}

  fun addBoundVar (env, v as {id,...}:A.varInfo) =
      let
        val v2 = refreshVar v
      in
        (bindVar (env, v, A.ANVAR v2), v2)
      end

  fun addBoundVars (env, nil) = (env, nil)
    | addBoundVars (env, var::vars) =
      let
        val (env, var) = addBoundVar (env, var)
        val (env, vars) = addBoundVars (env, vars)
      in
        (env, var::vars)
      end

  fun addBoundVarOpt (env, NONE) = (env, NONE)
    | addBoundVarOpt (env, SOME var) =
      let
        val (env, var) = addBoundVar (env, var)
      in
        (env, SOME var)
      end

  fun touchLoopLabel ({loopLabel, ...}:env) =
      case !loopLabel of
        SOME id => id
      | NONE =>
        let
          val id = FunLocalLabel.generate nil
        in
          loopLabel := SOME id;
          id
        end

  fun isSelfRecTailCall ({funId,...}:env) context anconst =
      case (funId, context, anconst) of
        (SOME funId,
         TAIL,
         A.ANCONST {ty = _, const = A.NVFUNENTRY id}) =>
        FunEntryLabel.eq (funId, id)
      | _ => false

  fun last anexp =
      (fn _:A.anexp => anexp, A.ANBOTTOM)

  fun bind context (expFn, expTy, loc) =
      case context of
        BIND var =>
        let
          val var = refreshVar var
        in
          (expFn var, A.ANVAR var)
        end
      | NONTAIL =>
        let
          val var = newVar expTy
        in
          (expFn var, A.ANVAR var)
        end
      | TAIL =>
        let
          val var = newVar expTy
          val (proc, ret) =
              last (A.ANRETURN {value = A.ANVAR var, ty = expTy, loc = loc})
        in
          (expFn var o proc, ret)
        end

  fun return context (value, ty, loc) =
      case context of
        BIND _ => (emptyProc, value)
      | NONTAIL => (emptyProc, value)
      | TAIL =>
        last (A.ANRETURN {value = value, ty = ty, loc = loc})

  fun compileVarInfo (env:env) ({id, ty}:N.varInfo) =
      case VarID.Map.find (#varEnv env, id) of
        SOME value => (value, ty)
      | NONE => raise Bug.Bug ("compileVarInfo " ^ VarID.toString id)

  fun compileExp env context ncexp =
      case ncexp of
        N.NCFOREIGNAPPLY {funExp, attributes, argExpList, resultTy, loc} =>
        let
          val (proc1, funExp) = compileExp env NONTAIL funExp
          val (proc2, argExpList) = compileExpList env argExpList
          val (proc3, ret) =
              case resultTy of
                SOME retTy =>
                bind context
                     (fn v => fn K =>
                         A.ANFOREIGNAPPLY {resultVar = SOME v,
                                           funExp = funExp,
                                           argExpList = argExpList,
                                           attributes = attributes,
                                           handler = getHandlerLabel env,
                                           nextExp = K,
                                           loc = loc},
                      retTy, loc)
              | NONE =>
                let
                  val (proc4, ret) = return context (unitValue, unitTy, loc)
                in
                  (fn K => A.ANFOREIGNAPPLY {resultVar = NONE,
                                             funExp = funExp,
                                             argExpList = argExpList,
                                             attributes = attributes,
                                             handler = getHandlerLabel env,
                                             nextExp = proc4 K,
                                             loc = loc},
                   ret)
                end
        in
          (proc1 o proc2 o proc3, ret)
        end
      | N.NCEXPORTCALLBACK {codeExp, closureEnvExp, instTyvars, resultTy,
                            loc} =>
        let
          val (proc1, codeExp) = compileExp env NONTAIL codeExp
          val (proc2, closureEnvExp) = compileExp env NONTAIL closureEnvExp
          val (proc3, ret) =
              bind context
                   (fn v => fn K =>
                       A.ANEXPORTCALLBACK {resultVar = v,
                                           codeExp = codeExp,
                                           closureEnvExp = closureEnvExp,
                                           instTyvars = instTyvars,
                                           nextExp = K,
                                           loc = loc},
                    resultTy, loc)
        in
          (proc1 o proc2 o proc3, ret)
        end
      | N.NCCONST {const, ty, loc} =>
        return context (A.ANCONST {const = const, ty = ty}, ty, loc)
      | N.NCINTINF {srcLabel, loc} =>
        bind context (fn v => fn K =>
                         A.ANINTINF {resultVar = v,
                                     dataLabel = srcLabel,
                                     nextExp = K,
                                     loc = loc},
                      intInfTy, loc)
      | N.NCVAR {varInfo, loc} =>
        let
          val (value, ty) = compileVarInfo env varInfo
        in
          return context (value, ty, loc)
        end
      | N.NCEXVAR {id, ty, loc} =>
        bind context (fn v => fn K =>
                         A.ANEXVAR {resultVar = v,
                                    id = id,
                                    nextExp = K,
                                    loc = loc},
                      ty, loc)
      | N.NCPACK {exp, expTy, loc} =>
        let
          val (proc1, exp) = compileExp env NONTAIL exp
          val (proc2, ret) =
              bind context
                   (fn v => fn K =>
                       A.ANPACK {resultVar = v,
                                 exp = exp,
                                 expTy = expTy,
                                 nextExp = K,
                                 loc = loc},
                    (#1 expTy, R.recordTy), loc)
        in
          (proc1 o proc2, ret)
        end
      | N.NCUNPACK {exp, resultTy, loc} =>
        let
          val (proc1, exp) = compileExp env NONTAIL exp
          val (proc2, ret) =
              bind context
                   (fn v => fn K =>
                       A.ANUNPACK {resultVar = v,
                                   exp = exp,
                                   nextExp = K,
                                   loc = loc},
                    resultTy, loc)
        in
          (proc1 o proc2, ret)
        end
      | N.NCDUP {srcAddr, resultTy, valueSize, loc} =>
        let
          val (proc1, srcAddr) = compileAddress env srcAddr
          val (proc2, valueSize) = compileExp env NONTAIL valueSize
          val (proc3, ret) =
              bind context
                   (fn v => fn K =>
                       A.ANDUP {resultVar = v,
                                srcAddr = srcAddr,
                                valueSize = valueSize,
                                nextExp = K,
                                loc = loc},
                    resultTy, loc)
        in
          (proc1 o proc2 o proc3, ret)
        end
      | N.NCLOAD {srcAddr, resultTy, loc} =>
        let
          val (proc1, srcAddr) = compileAddress env srcAddr
          val (proc2, ret) =
              bind context
                   (fn v => fn K =>
                       A.ANLOAD {resultVar = v,
                                 srcAddr = srcAddr,
                                 nextExp = K,
                                 loc = loc},
                    resultTy, loc)
        in
          (proc1 o proc2, ret)
        end
      | N.NCCOPY {srcExp, dstAddr, valueSize, loc} =>
        let
          val (proc1, srcExp) = compileExp env NONTAIL srcExp
          val (proc2, dstAddr) = compileAddress env dstAddr
          val (proc3, valueSize) = compileExp env NONTAIL valueSize
          val proc4 =
              fn nextExp =>
                 A.ANCOPY {srcExp = srcExp,
                           dstAddr = dstAddr,
                           valueSize = valueSize,
                           nextExp = nextExp,
                           loc = loc}
          val (proc5, ret) = return context (unitValue, unitTy, loc)
        in
          (proc1 o proc2 o proc3 o proc4 o proc5, ret)
        end
      | N.NCSTORE {srcExp, srcTy, dstAddr, loc} =>
        let
          val (proc1, srcExp) = compileExp env NONTAIL srcExp
          val (proc2, dstAddr) = compileAddress env dstAddr
          val proc3 =
              fn nextExp =>
                 A.ANSTORE {srcExp = srcExp,
                            srcTy = srcTy,
                            dstAddr = dstAddr,
                            nextExp = nextExp,
                            loc = loc}
          val (proc4, ret) = return context (unitValue, unitTy, loc)
        in
          (proc1 o proc2 o proc3 o proc4, ret)
        end
      | N.NCPRIMAPPLY {primInfo, argExpList, argTyList, resultTy, instTyList,
                       instTagList, instSizeList, loc} =>
        let
          val (proc1, argExpList) = compileExpList env argExpList
          val (proc2, instTagList) = compileExpList env instTagList
          val (proc3, instSizeList) = compileExpList env instSizeList
          val (proc4, ret) =
              bind context
                   (fn v => fn K =>
                       A.ANPRIMAPPLY {resultVar = v,
                                      primInfo = primInfo,
                                      argExpList = argExpList,
                                      argTyList = argTyList,
                                      resultTy = resultTy,
                                      instTyList = instTyList,
                                      instTagList = instTagList,
                                      instSizeList = instSizeList,
                                      nextExp = K,
                                      loc = loc},
                    resultTy, loc)
        in
          (proc1 o proc2 o proc3 o proc4, ret)
        end
      | N.NCCALL {codeExp, closureEnvExp, argExpList, resultTy, loc} =>
        let
          val (proc1, codeExp) = compileExp env NONTAIL codeExp
          val (proc2, closureEnvExp) = compileExpOption env closureEnvExp
          val (proc3, argExpList) = compileExpList env argExpList
          val (proc4, ret) =
              if isSelfRecTailCall env context codeExp
              then last (A.ANGOTO {id = touchLoopLabel env,
                                   argList = argExpList,
                                   loc = loc})
              else
                case context of
                  TAIL =>
                  last (A.ANTAILCALL {resultTy = resultTy,
                                      codeExp = codeExp,
                                      closureEnvExp = closureEnvExp,
                                      argExpList = argExpList,
                                      loc = loc})
                | _ =>
                  bind context
                       (fn v => fn K =>
                           A.ANCALL {resultVar = v,
                                     codeExp = codeExp,
                                     closureEnvExp = closureEnvExp,
                                     argExpList = argExpList,
                                     handler = getHandlerLabel env,
                                     nextExp = K,
                                     loc = loc},
                        resultTy, loc)
        in
          (proc1 o proc2 o proc3 o proc4, ret)
        end
      | N.NCLET {boundVar, boundExp, mainExp, loc} =>
        let
          val (proc1, v) = compileExp env (BIND boundVar) boundExp
          val env = bindVar (env, boundVar, v)
          val (proc2, ret) = compileExp env context mainExp
        in
          (proc1 o proc2, ret)
        end
      | N.NCRECORD {fieldList, recordTy, isMutable, clearPad, allocSizeExp,
                    bitmaps, loc} =>
        let
          val (proc1, fieldList) = compileFieldList env fieldList
          val (proc2, allocSizeExp) = compileExp env NONTAIL allocSizeExp
          val (proc3, bitmaps) = compileBitmapList env bitmaps
          val (proc4, ret) =
              bind context
                   (fn v => fn K =>
                       A.ANRECORD {resultVar = v,
                                   fieldList = fieldList,
                                   isMutable = isMutable,
                                   clearPad = clearPad,
                                   allocSizeExp = allocSizeExp,
                                   bitmaps = bitmaps,
                                   nextExp = K,
                                   loc = loc},
                    recordTy, loc)
        in
          (proc1 o proc2 o proc3 o proc4, ret)
        end
      | N.NCMODIFY {recordExp, recordTy, indexExp, valueExp, valueTy, loc} =>
        let
          val (proc1, recordExp) = compileExp env NONTAIL recordExp
          val (proc2, indexExp) = compileExp env NONTAIL indexExp
          val valueExp = compileInitField env valueExp
          val (proc3, ret) =
              bind context
                   (fn v => fn K =>
                       A.ANMODIFY {resultVar = v,
                                   recordExp = recordExp,
                                   indexExp = indexExp,
                                   valueExp = valueExp,
                                   valueTy = valueTy,
                                   nextExp = K,
                                   loc = loc},
                    recordTy, loc)
        in
          (proc1 o proc2 o proc3, ret)
        end
      | N.NCCAST {exp, expTy, targetTy, cast=BuiltinPrimitive.BitCast, loc} =>
        let
          val (proc1, exp) = compileExp env NONTAIL exp
          val (proc2, ret) =
              case toConst exp of
                SOME {const, ty} =>
                return context
                       (A.ANCONST
                          {const = A.NVCAST {value = const,
                                             valueTy = ty,
                                             targetTy = targetTy,
                                             cast = BuiltinPrimitive.BitCast},
                           ty = targetTy},
                        targetTy, loc)
              | NONE => bind context
                             (fn v => fn K =>
                                 A.ANBITCAST {resultVar = v,
                                              exp = exp,
                                              expTy = expTy,
                                              targetTy = targetTy,
                                              nextExp = K,
                                              loc = loc},
                              targetTy, loc)
        in
          (proc1 o proc2, ret)
        end
      | N.NCCAST {exp, expTy, targetTy, cast, loc} =>
        let
          val _ =
              case cast of
                BuiltinPrimitive.TypeCast => ()
              | BuiltinPrimitive.BitCast => raise Bug.Bug "compileExp: NCCAST"
          val (proc1, exp) = compileExp env NONTAIL exp
          val (proc2, ret) =
              return context (A.ANCAST {exp = exp,
                                        expTy = expTy,
                                        targetTy = targetTy},
                              targetTy, loc)
        in
          (proc1 o proc2, ret)
        end
      | N.NCEXPORTVAR {id, ty, valueExp, loc} =>
        let
          val (proc1, valueExp) = compileExp env NONTAIL valueExp
          val proc2 =
              fn nextExp =>
                 A.ANEXPORTVAR {id = id,
                                ty = ty,
                                valueExp = valueExp,
                                nextExp = nextExp,
                                loc = loc}
          val (proc3, ret) = return context (unitValue, unitTy, loc)
        in
          (proc1 o proc2 o proc3, ret)
        end
      | N.NCRAISE {argExp, resultTy, loc} =>
        let
          val (proc1, argExp) = compileExp env NONTAIL argExp
          val (proc2, ret) =
              case #handler env of
                HANDLER {localLabel, ...} =>
                last (A.ANGOTO {id = localLabel,
                                argList = [argExp],
                                loc = loc})
              | _ =>
                last (A.ANRAISE {argExp = argExp,
                                 cleanup = getCleanupLabel env,
                                 loc = loc})
        in
          (proc1 o proc2, ret)
        end
      | N.NCHANDLE {tryExp, exnVar, handlerExp, resultTy, loc} =>
        let
          val resultVar = newVar resultTy
          val mergeLabel = FunLocalLabel.generate nil
          val handlerLabel = HandlerLabel.generate nil
          val localHandlerLabel = FunLocalLabel.generate nil
          val tryEnv = env # {handler = HANDLER {handlerLabel = handlerLabel,
                                                 localLabel = localHandlerLabel}}
          val tryExp = compileBranchExp tryEnv NONTAIL mergeLabel tryExp
          val (env2, exnVar) = addBoundVar (env, exnVar)
          val handlerExp = compileBranchExp env2 context mergeLabel handlerExp
          val proc1 =
              fn nextExp =>
                 (* NOTE: this local code may be dead code if all branches are
                  * terminated by RAISE  *)
                 A.ANLOCALCODE
                   {recursive = false,
                    binds = [{id = mergeLabel,
                              argVarList = [resultVar],
                              bodyExp = nextExp}],
                    nextExp =
                      A.ANLOCALCODE
                        {recursive = false,
                         binds = [{id = localHandlerLabel,
                                   argVarList = [exnVar],
                                   bodyExp = handlerExp}],
                         nextExp =
                           A.ANHANDLER
                             {nextExp = tryExp,
                              exnVar = exnVar,
                              id = handlerLabel,
                              handlerExp =
                                A.ANGOTO {id = localHandlerLabel,
                                          argList = [A.ANVAR exnVar],
                                          loc = loc},
                              cleanup = getCleanupLabel env,
                              loc = loc},
                         loc = loc},
                    loc = loc}
          val (proc2, ret) = return context (A.ANVAR resultVar, resultTy, loc)
        in
          (proc1 o proc2, ret)
        end
      | N.NCSWITCH {switchExp, expTy, branches, defaultExp, resultTy, loc} =>
        let
          val (proc1, switchExp) = compileExp env NONTAIL switchExp
          val mergeVar =
              case context of
                TAIL => NONE
              | NONTAIL => SOME (newVar resultTy)
              | BIND var => SOME (refreshVar var)
          val mergeLabel = FunLocalLabel.generate nil
          val branches =
              map (fn {constant, branchExp} =>
                      (constant,
                       (FunLocalLabel.generate nil,
                        compileBranchExp env context mergeLabel branchExp)))
                  branches
          val defaultBranch =
              (FunLocalLabel.generate nil,
               compileBranchExp env context mergeLabel defaultExp)
          val switchProc =
              A.ANLOCALCODE
                {recursive = false,
                 binds =
                   map (fn (id, exp) =>
                           {id = id, argVarList = nil, bodyExp = exp})
                       (defaultBranch :: rev (map #2 branches)),
                 loc = loc,
                 nextExp =
                   proc1
                     (A.ANSWITCH
                        {switchExp = switchExp,
                         expTy = expTy,
                         branches = map (fn (c, (l, _)) => (c, l)) branches,
                         default = #1 defaultBranch,
                         loc = loc})}
        in
          case mergeVar of
              NONE => (fn _ => switchProc, A.ANBOTTOM)
            | SOME var =>
              let
                val proc1 =
                    fn nextExp =>
                       A.ANLOCALCODE
                         {recursive = false,
                          binds = [{id = mergeLabel,
                                    argVarList = [var],
                                    bodyExp = nextExp}],
                          nextExp = switchProc,
                          loc = loc}
                val (proc2, ret) = return context (A.ANVAR var, resultTy, loc)
              in
                (proc1 o proc2, ret)
              end
        end
      | N.NCCATCH {recursive, rules, tryExp, resultTy, loc} =>
        let
          val mergeVar =
              case context of
                TAIL => NONE
              | NONTAIL => SOME (newVar resultTy)
              | BIND var => SOME (refreshVar var)
          val mergeLabel = FunLocalLabel.generate nil
          val mainExp = compileBranchExp env context mergeLabel tryExp
          val binds =
              map (fn {catchLabel, argVarList, catchExp} =>
                      let
                        val (env2, argVarList) = addBoundVars (env, argVarList)
                      in
                        {id = catchLabel,
                         argVarList = argVarList,
                         bodyExp =
                           compileBranchExp env2 context mergeLabel catchExp}
                      end)
                  rules
          val localCodeExp =
              A.ANLOCALCODE {recursive = recursive,
                             binds = binds,
                             nextExp = mainExp,
                             loc = loc}
        in
          case mergeVar of
            NONE => (fn _ => localCodeExp, A.ANBOTTOM)
          | SOME var =>
            let
              val proc1 =
                  fn nextExp =>
                     (* NOTE: this local code may be dead code if all branches
                      * are terminated by RAISE  *)
                     A.ANLOCALCODE {recursive = false,
                                    binds = [{id = mergeLabel,
                                              argVarList = [var],
                                              bodyExp = nextExp}],
                                    nextExp = localCodeExp,
                                    loc = loc}
              val (proc2, ret) = return context (A.ANVAR var, resultTy, loc)
            in
              (proc1 o proc2, ret)
            end
        end
      | N.NCTHROW {catchLabel, argExpList, resultTy, loc} =>
        let
          val (proc1, argExpList) = compileExpList env argExpList
          val (proc2, ret) =
              last (A.ANGOTO {id=catchLabel, argList=argExpList, loc=loc})
        in
          (proc1 o proc2, ret)
        end

  and compileExpList env (exp::exps) =
      let
        val (proc1, value) = compileExp env NONTAIL exp
        val (proc2, values) = compileExpList env exps
      in
        (proc1 o proc2, value :: values)
      end
    | compileExpList env nil = (emptyProc, nil)

  and compileExpOption env NONE = (fn x => x, NONE)
    | compileExpOption env (SOME exp) =
      let
        val (proc1, value) = compileExp env NONTAIL exp
      in
        (proc1, SOME value)
      end

  and compileAddress env address =
      case address of
        N.NAPTR ptrExp =>
        let
          val (proc1, ptrExp) = compileExp env NONTAIL ptrExp
        in
          (proc1,
           A.AAPTR ptrExp)
        end
      | N.NARECORDFIELD {recordExp, fieldIndex} =>
        let
          val (proc1, recordExp) = compileExp env NONTAIL recordExp
          val (proc2, fieldIndex) = compileExp env NONTAIL fieldIndex
        in
          (proc1 o proc2,
           A.AARECORDFIELD {recordExp = recordExp,
                            fieldIndex = fieldIndex})
        end
      | N.NAARRAYELEM {arrayExp, elemSize, elemIndex} =>
        let
          val (proc1, arrayExp) = compileExp env NONTAIL arrayExp
          val (proc2, elemSize) = compileExp env NONTAIL elemSize
          val (proc3, elemIndex) = compileExp env NONTAIL elemIndex
        in
          (proc1 o proc2 o proc3,
           A.AAARRAYELEM {arrayExp = arrayExp,
                          elemSize = elemSize,
                          elemIndex = elemIndex})
        end

  and compileInitField env initField =
      case initField of
        N.INIT_CONST (const, ty) =>
        A.INIT_VALUE (A.ANCONST {const = const, ty = ty})
      | N.INIT_VALUE var =>
        A.INIT_VALUE (#1 (compileVarInfo env var))
      | N.INIT_COPY {srcExp, fieldSize} =>
        A.INIT_COPY {srcExp = #1 (compileVarInfo env srcExp),
                     fieldSize = #1 (compileVarInfo env fieldSize)}
      | N.INIT_IF {tagExp, tagOfTy, ifBoxed, ifUnboxed} =>
        A.INIT_IF {tagExp = #1 (compileVarInfo env tagExp),
                   tagOfTy = tagOfTy,
                   ifBoxed = compileInitField env ifBoxed,
                   ifUnboxed = compileInitField env ifUnboxed}

  and compileFieldList env ({fieldExp, fieldTy, fieldIndex}::fields) =
      let
        val fieldExp = compileInitField env fieldExp
        val (proc1, fieldIndex) = compileExp env NONTAIL fieldIndex
        val (proc2, fields) = compileFieldList env fields
      in
        (proc1 o proc2,
         {fieldExp = fieldExp,
          fieldTy = fieldTy,
          fieldIndex = fieldIndex}
         :: fields)
      end
    | compileFieldList env nil = (emptyProc, nil)

  and compileBitmapList env ({bitmapIndex, bitmapExp}::bitmaps) =
      let
        val (proc1, bitmapIndex) = compileExp env NONTAIL bitmapIndex
        val (proc2, bitmapExp) = compileExp env NONTAIL bitmapExp
        val (proc3, bitmaps) = compileBitmapList env bitmaps
      in
        (proc1 o proc2 o proc3,
         {bitmapIndex = bitmapIndex, bitmapExp = bitmapExp} :: bitmaps)
      end
    | compileBitmapList env nil = (emptyProc, nil)

  and compileBranchExp env context mergeLabel exp =
      let
        val (proc, ret) = compileExp env context exp
      in
        proc (A.ANGOTO {id=mergeLabel, argList=[ret], loc=Loc.noloc})
      end

  fun compileFunBody (funId, closureEnvVar, argVarList, bodyExp,
                      handler, loc) =
      let
        val loopLabel = ref NONE
        val env = {funId = funId,
                   loopLabel = loopLabel,
                   handler = handler,
                   varEnv = VarID.Map.empty} : env
        val (env, closureEnvVar) = addBoundVarOpt (env, closureEnvVar)
        val (env, argVarList) = addBoundVars (env, argVarList)
        val (proc, _) = compileExp env TAIL bodyExp
        val bodyExp = proc A.ANUNREACHABLE
      in
        case !loopLabel of
          NONE => (closureEnvVar, argVarList, bodyExp)
        | SOME label =>
          (closureEnvVar,
           argVarList,
           A.ANLOCALCODE
             {recursive = true,
              binds = [{id = label,
                        argVarList = argVarList,
                        bodyExp = bodyExp}],
              nextExp = A.ANGOTO {id = label,
                                  argList = map A.ANVAR argVarList,
                                  loc = loc},
              loc = loc})
      end

  fun compileTopdec topdec =
      case topdec of
        N.NTFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar, bodyExp,
                      retTy, gcCheck, loc} =>
        let
          val (closureEnvVar, argVarList, bodyExp) =
              compileFunBody (SOME id, closureEnvVar, argVarList, bodyExp,
                              NO_HANDLER, loc)
        in
          A.ATFUNCTION
            {id = id,
             tyvarKindEnv = tyvarKindEnv,
             argVarList = argVarList,
             closureEnvVar = closureEnvVar,
             bodyExp = bodyExp,
             retTy = retTy,
             gcCheck = gcCheck,
             loc = loc}
        end
      | N.NTCALLBACKFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
                              bodyExp, attributes, retTy, loc} =>
        let
          val cleanupHandler = ref NONE
          val (closureEnvVar, argVarList, bodyExp) =
              compileFunBody (NONE, closureEnvVar, argVarList, bodyExp,
                              CLEANUP cleanupHandler, loc)
        in
          A.ATCALLBACKFUNCTION
            {id = id,
             tyvarKindEnv = tyvarKindEnv,
             argVarList = argVarList,
             closureEnvVar = closureEnvVar,
             bodyExp = bodyExp,
             attributes = attributes,
             retTy = retTy,
             cleanupHandler = !cleanupHandler,
             loc = loc}
        end

  fun compile ({topdata, topdecs, topExp}:N.program) =
      let
        val _ = initUsedIds ()
        val topdecs = map compileTopdec topdecs
        val cleanupHandler = ref NONE
        val topEnv = {funId = NONE,
                      loopLabel = ref NONE,
                      handler = CLEANUP cleanupHandler,
                      varEnv = VarID.Map.empty} : env
        val (proc, ret) = compileExp topEnv NONTAIL topExp
        val _ =
            case (#loopLabel topEnv, ret) of
              (ref NONE, A.ANCONST {const=A.NVUNIT,...}) => ()
             | _ => raise Bug.Bug "compile: assertion failed"
        val topExp =
            proc (A.ANRETURN {value=ret, ty=unitTy, loc=Loc.noloc})
      in
        {topdata = topdata,
         topdecs = topdecs,
         topExp = topExp,
         topCleanupHandler = !cleanupHandler} : A.program
      end

end
