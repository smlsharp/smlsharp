(**
 * replace every variable ID with unique ID of def-use connected component.
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure RTLRename : sig

  val rename : RTL.program -> RTL.program

end =
struct

  structure R = RTL

  datatype liveRange = RANGE of VarID.id option | SAME of liveRangeVar
  withtype liveRangeVar = liveRange ref
  type env = liveRangeVar VarID.Map.map

  fun newLiveRangeVar () =
      ref (RANGE NONE) : liveRangeVar

  fun selectSOME (NONE, y) = y
    | selectSOME (x, y) = x

  fun unify (r1 as ref (RANGE s1), r2 as ref (RANGE s2) : liveRangeVar) =
      if r1 = r2 then r1
      else (r1 := RANGE (selectSOME (s1, s2)); r2 := SAME r1; r1)
    | unify (r1, r2 as ref (SAME v)) =
      let val r = unify (r1, v) in r2 := SAME r; r end
    | unify (r1 as ref (SAME v), r2) =
      let val r = unify (v, r2) in r1 := SAME r; r end

  fun assign (ref (SAME r) : liveRangeVar) = assign r
    | assign (ref (RANGE (SOME id))) = id
    | assign (r as ref (RANGE NONE)) =
      let val id = VarID.generate () in r := RANGE (SOME id); id end

  fun unifyEnv (env1:env, env2:env) =
      VarID.Map.unionWith unify (env1, env2) : env

  fun newEnv vars =
      RTLUtils.Var.fold
        (fn ({id,...}, env) => VarID.Map.insert (env, id, newLiveRangeVar ()))
        VarID.Map.empty
        vars

  fun isSubset (env1, env2:env) =
      VarID.Map.foldli
        (fn (id, r1, z) => z andalso VarID.Map.inDomain (env2, id))
        true
        env1

  fun minus (env:env, vars) =
      RTLUtils.Var.fold
        (fn ({id,...}, env) =>
            #1 (VarID.Map.remove (env, id)) handle _ => env)
        env
        vars

  local

    val init = [VarID.Map.empty] : env list

    fun join (env1::_, env2::_) = [unifyEnv (env1, env2)]
      | join _ = raise Control.Bug "join"

    fun pass (node, nil) = raise Control.Bug "pass"
      | pass (node, envs as outEnv::_) =
        let
          val {defs, uses} = RTLUtils.Var.defuse node
          val useEnv = newEnv uses
          val inEnv = unifyEnv (minus (outEnv, defs), useEnv)
        in
          inEnv::envs
        end

    fun filterOut (_:RTL.label, env::_) = [env] : env list
      | filterOut _ = raise Control.Bug "filterOut"

    fun changed {old=oldEnv::_, new=newEnv::_} =
        (unifyEnv (newEnv, oldEnv); not (isSubset (newEnv, oldEnv)))
      | changed _ = raise Control.Bug "changed"

  in

  fun analyze graph =
      let
        val result =
            RTLUtils.analyzeFlowBackward
              {init = init,
               join = join,
               pass = pass,
               filterIn = fn (_,x) => x,
               filterOut = filterOut,
               changed = changed}
              graph


        val liveness = RTLLiveness.liveness graph
        val _ =
            RTLEdit.fold
              (fn (focus, ()) =>
                  let
                    val label = RTLEdit.blockLabel focus
                    val {liveIn, liveOut, ...} = RTLEdit.annotation focus
                    val {answerIn, answerOut, ...} =
                        RTLEdit.annotation (RTLEdit.focusBlock (result, label))

                    fun domain map =
                        VarID.Map.foldli (fn (i,_,z) => VarID.Set.add (z,i))
                                         VarID.Set.empty map
                    fun equal (set1, set2) =
                        VarID.Set.isSubset (set1, set2)
                        andalso VarID.Set.isSubset (set2, set1)

                    val liveIn = RTLUtils.Var.toVarIDSet liveIn
                    val liveOut = RTLUtils.Var.toVarIDSet liveOut
                    val answerIn = domain (hd answerIn)
                    val answerOut = domain (hd answerOut)
                  in
                    if equal (liveIn, answerIn) andalso
                       equal (liveOut, answerOut) then ()
                    else raise Control.Bug "analyze"
                  end)
              ()
              liveness
      in
        RTLEdit.map #answerIn result
      end

  end (* local *)

  fun substClob ({id,ty}:R.var) =
      {id = VarID.generate (), ty = ty} : R.var

  fun substVar subst ({id, ty}:R.var) =
      case VarID.Map.find (subst, id) of
        SOME v => {id = assign v, ty = ty} : R.var
      | NONE => {id = VarID.generate (), ty = ty}  (* dead code *)

  fun substAddr subst addr =
      case addr of
        R.ADDRCAST (ty, addr) =>
        R.ADDRCAST (ty, substAddr subst addr)
      | R.ABSADDR (label:R.labelReference) => addr
      | R.DISP (const, addr) =>
        R.DISP (const:R.const, substAddr subst addr)
      | R.BASE var =>
        R.BASE (substVar subst var)
      | R.ABSINDEX {base, scale, index} =>
        R.ABSINDEX {base = base:R.labelReference, scale = scale:int,
                    index = substVar subst index}
      | R.BASEINDEX {base, scale, index} =>
        R.BASEINDEX {base = substVar subst base, scale = scale:int,
                     index = substVar subst index}
      | R.POSTFRAME {offset:int, size:int} => addr
      | R.PREFRAME {offset:int, size:int} => addr
      | R.WORKFRAME (slot:R.slot) => addr
      | R.FRAMEINFO (offset:int) => addr

  fun substMem subst (R.ADDR addr) = R.ADDR (substAddr subst addr)
    | substMem subst (slot as R.SLOT (_:R.slot)) = slot

  fun substDst {sDef, sUse} (R.REG var) =
      R.REG (substVar sDef var)
    | substDst subst (R.COUPLE (ty, {hi,lo})) =
      R.COUPLE (ty, {hi = substDst subst hi, lo = substDst subst lo})
    | substDst {sDef, sUse} (R.MEM (ty, mem)) =
      R.MEM (ty, substMem sUse mem)

  fun substOp subst (const as R.CONST (_:R.const)) = const
    | substOp subst (R.REF (cast, dst)) =
      R.REF (cast, substDst {sDef=subst, sUse=subst} dst)

  fun substInsn (subst as {sDef, sUse}) insn =
      case insn of
        R.NOP => insn
      | R.STABILIZE => insn
      | R.REQUEST_SLOT (slot:R.slot) => insn
      | R.REQUIRE_SLOT (slot:R.slot) => insn
      | R.USE ops => R.USE (map (substOp sUse) ops)
      | R.COMPUTE_FRAME {uses, clobs} =>
        R.COMPUTE_FRAME {uses = VarID.Map.map (substVar sUse) uses,
                         clobs = map substClob clobs}
      | R.MOVE (ty, dst, op1) =>
        R.MOVE (ty, substDst subst dst, substOp sUse op1)
      | R.MOVEADDR (ty, dst, addr) =>
        R.MOVEADDR (ty, substDst subst dst, substAddr sUse addr)
      | R.COPY {ty, dst, src, clobs} =>
        R.COPY {ty = ty, dst = substDst subst dst, src = substOp sUse src,
                clobs = map substClob clobs}
      | R.MLOAD {ty, dst, srcAddr, size, defs, clobs} =>
        R.MLOAD {ty = ty, dst = dst:R.slot, srcAddr = substAddr sUse srcAddr,
                 size = substOp sUse size, defs = map (substVar sDef) defs,
                 clobs = map substClob clobs}
      | R.MSTORE {ty, dstAddr, src, size, defs, clobs, global} =>
        R.MSTORE {ty = ty, dstAddr = substAddr sUse dstAddr,
                  src = src:R.slot, size = substOp sUse size,
                  defs = map (substVar sDef) defs, clobs = map substClob clobs,
                  global = global:bool}
      | R.EXT8TO32 (s, dst, op1) =>
        R.EXT8TO32 (s, substDst subst dst, substOp sUse op1)
      | R.EXT16TO32 (s, dst, op1) =>
        R.EXT16TO32 (s, substDst subst dst, substOp sUse op1)
      | R.EXT32TO64 (s, dst, op1) =>
        R.EXT32TO64 (s, substDst subst dst, substOp sUse op1)
      | R.DOWN32TO8 (s, dst, op1) =>
        R.DOWN32TO8 (s, substDst subst dst, substOp sUse op1)
      | R.DOWN32TO16 (s, dst, op1) =>
        R.DOWN32TO16 (s, substDst subst dst, substOp sUse op1)
      | R.ADD (ty, dst, op1, op2) =>
        R.ADD (ty, substDst subst dst, substOp sUse op1, substOp sUse op2)
      | R.SUB (ty, dst, op1, op2) =>
        R.SUB (ty, substDst subst dst, substOp sUse op1, substOp sUse op2)
      | R.MUL ((ty0,dst), (ty1,op1), (ty2,op2)) =>
        R.MUL ((ty0, substDst subst dst), (ty1, substOp sUse op1),
               (ty2, substOp sUse op2))
      | R.DIVMOD ({div=(tydiv,ddiv), mod=(tymod,dmod)}, (ty1,op1), (ty2,op2)) =>
        R.DIVMOD ({div=(tydiv, substDst subst ddiv),
                   mod=(tymod, substDst subst dmod)},
                  (ty1, substOp sUse op1), (ty2, substOp sUse op2))
      | R.AND (ty, dst, op1, op2) =>
        R.AND (ty, substDst subst dst, substOp sUse op1, substOp sUse op2)
      | R.OR (ty, dst, op1, op2) =>
        R.OR (ty, substDst subst dst, substOp sUse op1, substOp sUse op2)
      | R.XOR (ty, dst, op1, op2) =>
        R.XOR (ty, substDst subst dst, substOp sUse op1, substOp sUse op2)
      | R.LSHIFT (ty, dst, op1, op2) =>
        R.LSHIFT (ty, substDst subst dst, substOp sUse op1, substOp sUse op2)
      | R.RSHIFT (ty, dst, op1, op2) =>
        R.RSHIFT (ty, substDst subst dst, substOp sUse op1, substOp sUse op2)
      | R.ARSHIFT (ty, dst, op1, op2) =>
        R.ARSHIFT (ty, substDst subst dst, substOp sUse op1, substOp sUse op2)
      | R.TEST_SUB (ty, op1, op2) =>
        R.TEST_SUB (ty, substOp sUse op1, substOp sUse op2)
      | R.TEST_AND (ty, op1, op2) =>
        R.TEST_AND (ty, substOp sUse op1, substOp sUse op2)
      | R.TEST_LABEL (ty, op1, l) =>
        R.TEST_LABEL (ty, substOp sUse op1, l:R.labelReference)
      | R.NOT (ty, dst, op1) =>
        R.NOT (ty, substDst subst dst, substOp sUse op1)
      | R.NEG (ty, dst, op1) =>
        R.NEG (ty, substDst subst dst, substOp sUse op1)
      | R.SET (cc, ty, dst, {test}) =>
        R.SET (cc, ty, substDst subst dst, {test = substInsn subst test})
      | R.LOAD_FP dst =>
        R.LOAD_FP (substDst subst dst)
      | R.LOAD_SP dst =>
        R.LOAD_SP (substDst subst dst)
      | R.LOAD_PREV_FP dst =>
        R.LOAD_PREV_FP (substDst subst dst)
      | R.LOAD_RETADDR dst =>
        R.LOAD_RETADDR (substDst subst dst)
      | R.LOADABSADDR {ty, dst, symbol, thunk} =>
        R.LOADABSADDR {ty = ty, dst = substDst subst dst,
                       symbol = symbol:R.labelReference,
                       thunk = thunk:R.symbol option}
      | R.X86 (R.X86LEAINT (ty, dst, {base, shift, offset, disp})) =>
        R.X86 (R.X86LEAINT (ty, substDst subst dst,
                            {base = substVar sUse base,
                             shift = shift:int,
                             offset = substVar sUse offset,
                             disp = disp:R.const}))
      | R.X86 (R.X86FLD (ty, mem)) =>
        R.X86 (R.X86FLD (ty, substMem sUse mem))
      | R.X86 (R.X86FLD_ST (st:R.x86st)) => insn
      | R.X86 (R.X86FST (ty, mem)) =>
        R.X86 (R.X86FST (ty, substMem sUse mem))
      | R.X86 (R.X86FSTP (ty, mem)) =>
        R.X86 (R.X86FSTP (ty, substMem sUse mem))
      | R.X86 (R.X86FSTP_ST (st:R.x86st)) => insn
      | R.X86 (R.X86FADD (ty, mem)) =>
        R.X86 (R.X86FADD (ty, substMem sUse mem))
      | R.X86 (R.X86FADD_ST (st1:R.x86st, st2:R.x86st)) => insn
      | R.X86 (R.X86FADDP (st1:R.x86st)) => insn
      | R.X86 (R.X86FSUB (ty, mem)) =>
        R.X86 (R.X86FSUB (ty, substMem sUse mem))
      | R.X86 (R.X86FSUB_ST (st1:R.x86st, st2:R.x86st)) =>
        R.X86 (R.X86FSUB_ST (st1:R.x86st, st2:R.x86st))
      | R.X86 (R.X86FSUBP (st1:R.x86st)) => insn
      | R.X86 (R.X86FSUBR (ty, mem)) =>
        R.X86 (R.X86FSUBR (ty, substMem sUse mem))
      | R.X86 (R.X86FSUBR_ST (st1:R.x86st, st2:R.x86st)) =>
        R.X86 (R.X86FSUBR_ST (st1:R.x86st, st2:R.x86st))
      | R.X86 (R.X86FSUBRP (st1:R.x86st)) => insn
      | R.X86 (R.X86FMUL (ty, mem)) =>
        R.X86 (R.X86FMUL (ty, substMem sUse mem))
      | R.X86 (R.X86FMUL_ST (st1:R.x86st, st2:R.x86st)) => insn
      | R.X86 (R.X86FMULP (st1:R.x86st)) => insn
      | R.X86 (R.X86FDIV (ty, mem)) =>
        R.X86 (R.X86FDIV (ty, substMem sUse mem))
      | R.X86 (R.X86FDIV_ST (st1:R.x86st, st2:R.x86st)) => insn
      | R.X86 (R.X86FDIVP (st1:R.x86st)) => insn
      | R.X86 (R.X86FDIVR (ty, mem)) =>
        R.X86 (R.X86FDIVR (ty, substMem sUse mem))
      | R.X86 (R.X86FDIVR_ST (st1:R.x86st, st2:R.x86st)) => insn
      | R.X86 (R.X86FDIVRP (st1:R.x86st)) => insn
      | R.X86 R.X86FPREM => insn
      | R.X86 (R.X86FABS) => insn
      | R.X86 (R.X86FCHS) => insn
      | R.X86 (R.X86FINCSTP) => insn
      | R.X86 (R.X86FFREE (st:R.x86st)) => insn
      | R.X86 (R.X86FXCH (st:R.x86st)) => insn
      | R.X86 (R.X86FUCOM (st:R.x86st)) => insn
      | R.X86 (R.X86FUCOMP (st:R.x86st)) => insn
      | R.X86 R.X86FUCOMPP => insn
      | R.X86 (R.X86FSW_TESTH {clob,mask}) =>
        R.X86 (R.X86FSW_TESTH {clob = substClob clob, mask = mask})
      | R.X86 (R.X86FSW_MASKCMPH {clob,mask,compare}) =>
        R.X86 (R.X86FSW_MASKCMPH {clob = substClob clob, mask = mask,
                                  compare = compare})
      | R.X86 (R.X86FLDCW mem) =>
        R.X86 (R.X86FLDCW (substMem sUse mem))
      | R.X86 (R.X86FNSTCW mem) =>
        R.X86 (R.X86FNSTCW (substMem sUse mem))
      | R.X86 R.X86FWAIT => insn
      | R.X86 R.X86FNCLEX => insn

  fun substLast (subst as {sDef, sUse}) last =
      case last of
        R.HANDLE (insn, args) =>
        R.HANDLE (substInsn subst insn, args)
      | R.CJUMP {test, cc, thenLabel, elseLabel} =>
        R.CJUMP {test = substInsn subst test, cc = cc,
                 thenLabel = thenLabel:R.label, elseLabel = elseLabel:R.label}
      | R.CALL {callTo, returnTo, handler, defs, uses,
                needStabilize, postFrameAdjust} =>
        R.CALL {callTo = substAddr sUse callTo, returnTo = returnTo:R.label,
                handler = handler:R.handler, defs = map (substVar sDef) defs,
                uses = map (substVar sUse) uses,
                needStabilize = needStabilize:bool,
                postFrameAdjust = postFrameAdjust:int}
      | R.JUMP {jumpTo, destinations} =>
        R.JUMP {jumpTo = substAddr sUse jumpTo,
                destinations = destinations:R.label list}
      | R.UNWIND_JUMP {jumpTo, sp, fp, uses, handler} =>
        R.UNWIND_JUMP {jumpTo = substAddr sUse jumpTo,
                       sp = substOp sUse sp, fp = substOp sUse fp,
                       uses = map (substVar sUse) uses,
                       handler = handler:R.handler}
      | R.TAILCALL_JUMP {preFrameSize, jumpTo, uses} =>
        R.TAILCALL_JUMP {preFrameSize = preFrameSize:int,
                         jumpTo = substAddr sUse jumpTo,
                         uses = map (substVar sUse) uses}
      | R.RETURN {preFrameSize, stubOptions, uses} =>
        R.RETURN {preFrameSize = preFrameSize:int,
                  stubOptions = stubOptions,
                  uses = map (substVar sUse) uses}
      | R.EXIT => last

  fun substFirst (subst as {sDef, sUse}) first =
      case first of
        R.BEGIN {label, align, loc} => first
      | R.CODEENTRY {label, symbol, scope, align, preFrameSize,
                     stubOptions, defs, loc} =>
        R.CODEENTRY {label = label, symbol = symbol, scope = scope,
                     align = align, preFrameSize = preFrameSize,
                     stubOptions = stubOptions,
                     defs = map (substVar sDef) defs, loc = loc}
      | R.HANDLERENTRY {label, align, defs, loc} =>
        R.HANDLERENTRY {label = label, align = align,
                        defs = map (substVar sDef) defs, loc = loc}
      | R.ENTER => first

  fun substNode subst node =
      case node of
        RTLEdit.FIRST first =>
        RTLEdit.unfocus (RTLEdit.singletonFirst (substFirst subst first))
      | RTLEdit.MIDDLE insn =>
        RTLEdit.unfocus (RTLEdit.singleton (substInsn subst insn))
      | RTLEdit.LAST last =>
        RTLEdit.unfocus (RTLEdit.singletonLast (substLast subst last))

  fun substGraph graph =
      RTLEdit.rewrite
        (RTLEdit.rewriteForward
           (fn (node, inEnv::(envs as outEnv::_)) =>
                 (substNode {sDef=outEnv, sUse=inEnv} node, envs)
             | _ => raise Control.Bug "renameGraph"))
        graph

  fun renameGraph graph =
      substGraph (analyze graph)

  fun rename program =
      RTLUtils.mapCluster renameGraph program

end
