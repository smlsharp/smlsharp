(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

functor RTLStabilize (structure Emit : RTLEMIT) : RTLSTABILIZE =
struct

  structure R = RTL
  structure Target = Emit.Target

  (* request status of register value *)
  datatype request =
      SAVE   (* value must be saved on memory. *)
    | LOAD   (* value is just on register. *)

  (* actual status of register value *)
  datatype actual =
      SAVED  (* available value is just on memory. *)
    | CACHED (* available value is on both memory and register. *)
    | LOADED (* available value is just on register. *)

  fun mergeRequest (SAVE, SAVE) = SAVE
    | mergeRequest (SAVE, LOAD) = SAVE
    | mergeRequest (LOAD, SAVE) = SAVE
    | mergeRequest (LOAD, LOAD) = LOAD

  fun mergeActual (SAVED, SAVED) = SAVED
    | mergeActual (SAVED, CACHED) = CACHED
    | mergeActual (SAVED, LOADED) = LOADED
    | mergeActual (CACHED, SAVED) = CACHED
    | mergeActual (CACHED, CACHED) = CACHED
    | mergeActual (CACHED, LOADED) = LOADED
    | mergeActual (LOADED, _) = LOADED

  type 'a result = (R.ty * 'a) VarID.Map.map
  type 'a answer = 'a result RTLUtils.answer

  local
    open SMLFormat.BasicFormatters
    open SMLFormat.FormatExpression
    fun s x = [Term (size x, x)]
  in
  fun format_request SAVE = s "SAVE"
    | format_request LOAD = s "LOAD"
  fun format_actual SAVED = s "SAVED"
    | format_actual CACHED = s "CACHED"
    | format_actual LOADED = s "LOADED"
  fun format_result fmt (map:'a result) =
      s "{" @
      format_list
        (fn (l,(x,y)) => R.format_id l @ s ":("
                         @ R.format_ty x @ s "," @ fmt y @ s ")",
         s ",")
        (VarID.Map.listItemsi map) @ s "}"
  fun format_answer fmt (ans:'a answer) =
      RTLUtils.format_answer (format_result fmt) ans
  end

  fun join merge (result1:'a result, result2) =
      VarID.Map.unionWith
        (fn ((ty,x), (_,y)) => (ty, merge (x, y)))
        (result1, result2)

  fun minus (result:'a result, vars) =
      VarID.Map.filteri
        (fn (id, _) => not (RTLUtils.Var.inDomain (vars, id)))
        result

  fun isSubset merge (result1:'a result, result2) =
      VarID.Map.foldli
        (fn (k, (_, s1), z) =>
            z andalso (case VarID.Map.find (result2, k) of
                         NONE => false
                       | SOME (_, s2) => merge (s1, s2) = s2))
        true
        result1

  fun changed merge {old, new} =
      not (isSubset merge (new, old))

  fun singleton ({id, ty}:R.var, status:'a) =
      VarID.Map.singleton (id, (ty, status)) : 'a result

  fun setStatus1 (result:'a result, {id, ty}:R.var, status:'a) =
      VarID.Map.insert (result, id, (ty, status))

  fun setStatus (result:'a result, vars, status:'a) =
      RTLUtils.Var.fold
        (fn ({id, ty}:R.var, z) => VarID.Map.insert (z, id, (ty, status)))
        result
        vars

  fun makeResult (vars, status) =
      setStatus (VarID.Map.empty, vars, status)

  fun requestLoaded (result:request result, vars) =
      RTLUtils.Var.fold
        (fn ({id, ty}:R.var, z) =>
            case VarID.Map.find (z, id) of
              SOME _ => z
            | NONE => VarID.Map.insert (z, id, (ty, LOAD)))
        result
        vars

  fun actuallyLoaded (result:actual result, vars) =
      RTLUtils.Var.fold
        (fn ({id, ty}:R.var, z) =>
            case VarID.Map.find (z, id) of
              SOME (_, LOADED) => z
            | SOME (_, CACHED) => z
            | SOME (ty, SAVED) => VarID.Map.insert (z, id, (ty, CACHED))
            | NONE => VarID.Map.insert (z, id, (ty, LOADED)))
        result
        vars

  fun stabilizeRequestAll (result:request result) =
      VarID.Map.map (fn (ty, _) => (ty, SAVE)) result

  fun stabilizeRequestPtr (result:request result) =
      VarID.Map.map (fn (ty as R.Ptr R.Data, _) => (ty, SAVE)
                           | (ty, v) => (ty, v))
                         result

  fun stabilizeActualAll (result:actual result) =
      VarID.Map.map (fn (ty, _) => (ty, SAVED)) result

  fun stabilizeActualPtr (result:actual result) =
      VarID.Map.map (fn (ty as R.Ptr R.Data, _) => (ty, SAVED)
                           | (ty, v) => (ty, v))
                         result

  fun isStabilizedAll (result:actual result) =
      VarID.Map.foldl (fn ((_,SAVED),z) => z
                             | ((_,CACHED),z) => z
                             | ((_,LOADED),z) => false)
                           true
                           result

  fun isStabilizedPtr (result:actual result) =
      VarID.Map.foldl (fn ((R.Ptr R.Data,SAVED),z) => z
                             | ((R.Ptr R.Data,CACHED),z) => z
                             | ((R.Ptr R.Data,LOADED),z) => false
                             | (_, z) => z)
                           true
                           result

  fun requestFirst (first, result) =
      let
        val {defs, uses} = RTLUtils.Var.defuseFirst first
        val result = minus (result, defs)
        val result = requestLoaded (result, uses)
      in
        case first of
          R.BEGIN {label, align, loc} => result
        | R.CODEENTRY {label, symbol, scope, align, preFrameSize,
                       stubOptions, defs, loc} => result
        | R.HANDLERENTRY {label, align, defs, loc} => stabilizeRequestAll result
        | R.ENTER => result
      end

  fun requestInsn (insn, result) =
      let
        val {defs, uses} = RTLUtils.Var.defuseInsn insn
        val result = minus (result, defs)
        val result = requestLoaded (result, uses)
      in
        case insn of
          R.NOP => result
        | R.STABILIZE => stabilizeRequestPtr result
        | R.COMPUTE_FRAME {uses, clobs} => result
        | R.REQUEST_SLOT slot => result
        | R.REQUIRE_SLOT slot => result
        | R.USE vars => result
        | R.MOVE (ty, dst, op1) => result
        | R.MOVEADDR (ptrTy, dst, addr) => result
        | R.COPY {ty, dst, src, clobs} => result
        | R.MLOAD {ty, dst, srcAddr, size, defs, clobs} => result
        | R.MSTORE {ty, dstAddr, src, size, global, defs, clobs} => result
        | R.EXT8TO32 (sign, dst, op1) => result
        | R.EXT16TO32 (sign, dst, op1) => result
        | R.EXT32TO64 (sign, dst, op1) => result
        | R.DOWN32TO8 (sign, dst, op1) => result
        | R.DOWN32TO16 (sign, dst, op1) => result
        | R.ADD (ty, dst, op1, op2) => result
        | R.SUB (ty, dst, op1, op2) => result
        | R.MUL ((ty, dst), (ty2, op1), (ty3, op2)) => result
        | R.DIVMOD ({div, mod}, (ty3, op1), (ty4, op2)) => result
        | R.AND (ty, dst, op1, op2) => result
        | R.OR (ty, dst, op1, op2) => result
        | R.XOR (ty, dst, op1, op2) => result
        | R.LSHIFT (ty, dst, op1, op2) => result
        | R.RSHIFT (ty, dst, op1, op2) => result
        | R.ARSHIFT (ty, dst, op1, op2) => result
        | R.TEST_SUB (ty, op1, op2) => result
        | R.TEST_AND (ty, op1, op2) => result
        | R.TEST_LABEL (ptrTy, op1, label) => result
        | R.NOT (ty, dst, op1) => result
        | R.NEG (ty, dst, op1) => result
        | R.SET (cc1, ty, dst, {test}) => result
        | R.LOAD_FP dst => result
        | R.LOAD_SP dst => result
        | R.LOAD_PREV_FP dst => result
        | R.LOAD_RETADDR dst => result
        | R.LOADABSADDR {ty, dst, symbol, thunk} => result
        | R.X86 (R.X86LEAINT (ty, dst, {base, shift, offset, disp})) => result
        | R.X86 (R.X86FLD (ty, mem)) => result
        | R.X86 (R.X86FLD_ST x86st1) => result
        | R.X86 (R.X86FST (ty, mem)) => result
        | R.X86 (R.X86FSTP (ty, mem)) => result
        | R.X86 (R.X86FSTP_ST x86st1) => result
        | R.X86 (R.X86FADD (ty, mem)) => result
        | R.X86 (R.X86FADD_ST (x86st1, x86st2)) => result
        | R.X86 (R.X86FADDP x86st1) => result
        | R.X86 (R.X86FSUB (ty, mem)) => result
        | R.X86 (R.X86FSUB_ST (x86st1, x86st2)) => result
        | R.X86 (R.X86FSUBP x86st1) => result
        | R.X86 (R.X86FSUBR (ty, mem)) => result
        | R.X86 (R.X86FSUBR_ST (x86st1, x86st2)) => result
        | R.X86 (R.X86FSUBRP x86st1) => result
        | R.X86 (R.X86FMUL (ty, mem)) => result
        | R.X86 (R.X86FMUL_ST (x86st1, x86st2)) => result
        | R.X86 (R.X86FMULP x86st1) => result
        | R.X86 (R.X86FDIV (ty, mem)) => result
        | R.X86 (R.X86FDIV_ST (x86st1, x86st2)) => result
        | R.X86 (R.X86FDIVP x86st1) => result
        | R.X86 (R.X86FDIVR (ty, mem)) => result
        | R.X86 (R.X86FDIVR_ST (x86st1, x86st2)) => result
        | R.X86 (R.X86FDIVRP x86st1) => result
        | R.X86 R.X86FPREM => result
        | R.X86 R.X86FABS => result
        | R.X86 R.X86FCHS => result
        | R.X86 R.X86FINCSTP => result
        | R.X86 (R.X86FFREE x86st1) => result
        | R.X86 (R.X86FXCH x86st1) => result
        | R.X86 (R.X86FUCOM x86st1) => result
        | R.X86 (R.X86FUCOMP x86st1) => result
        | R.X86 R.X86FUCOMPP => result
        | R.X86 (R.X86FSW_TESTH {clob,mask}) => result
        | R.X86 (R.X86FSW_MASKCMPH {clob,mask,compare}) => result
        | R.X86 (R.X86FLDCW mem) => result
        | R.X86 (R.X86FNSTCW mem) => result
        | R.X86 R.X86FWAIT => result
        | R.X86 R.X86FNCLEX => result
      end

  fun requestLast (last, result) =
      let
        val {defs, uses} = RTLUtils.Var.defuseLast last
        val result = minus (result, defs)
        val result = requestLoaded (result, uses)
      in
        case last of
          R.HANDLE (insn, {nextLabel, handler}) => result
        | R.CJUMP {test, cc, thenLabel, elseLabel} => result
        | R.CALL {callTo, returnTo, handler, defs, uses, needStabilize,
                  postFrameAdjust} => stabilizeRequestPtr result
        | R.JUMP {jumpTo, destinations} => result
        | R.UNWIND_JUMP {jumpTo, sp, fp, uses, handler} => result
        | R.TAILCALL_JUMP {preFrameSize, jumpTo, uses} => result
        | R.RETURN {preFrameSize, stubOptions, uses} => result
        | R.EXIT => result
      end

  fun passRequest (node, result) =
(*
(
Control.ps "----pass";
Control.p RTLEdit.format_node node;
Control.p (format_result format_request) result;
let val x =
*)
      case node of
        RTLEdit.FIRST first => requestFirst (first, result)
      | RTLEdit.LAST last => requestLast (last, result)
      | RTLEdit.MIDDLE insn => requestInsn (insn, result)
(*
in
Control.p (format_result format_request) x;
Control.ps "----";
x
end
)
*)

  fun actualFirst (first, result) =
      case first of
        R.BEGIN {label, align, loc} => result
      | R.CODEENTRY {label, symbol, scope, align, preFrameSize,
                     stubOptions, defs, loc} =>
        actuallyLoaded (result, RTLUtils.Var.fromList defs)
      | R.HANDLERENTRY {label, align, defs, loc} =>
        actuallyLoaded (stabilizeActualAll result, RTLUtils.Var.fromList defs)
      | R.ENTER => result

  fun actualInsn (insn, result) =
      let
        val {defs, uses} = RTLUtils.Var.defuseInsn insn
        val result = actuallyLoaded (result, uses)
        val result = setStatus (result, defs, LOADED)
      in
        case insn of
          R.NOP => result
        | R.STABILIZE => stabilizeActualPtr result
        | R.COMPUTE_FRAME {uses, clobs} => result
        | R.REQUEST_SLOT slot => result
        | R.REQUIRE_SLOT slot => result
        | R.USE vars => result
        | R.MOVE (ty, R.REG v, R.REF (_, R.MEM (_, R.SLOT s))) =>
          if VarID.eq (#id v, #id s)
          then setStatus1 (result, v, CACHED)
          else result
        | R.MOVE (ty, R.MEM (_, R.SLOT s), R.REF (_, R.REG v)) =>
          if VarID.eq (#id v, #id s)
          then setStatus1 (result, v, CACHED)
          else result
        | R.MOVE (ty, dst, op1) => result
        | R.MOVEADDR (ptrTy, dst, addr) => result
        | R.COPY {ty, dst, src, clobs} => result
        | R.MLOAD {ty, dst, srcAddr, size, defs, clobs} => result
        | R.MSTORE {ty, dstAddr, src, size, global, defs, clobs} => result
        | R.EXT8TO32 (sign, dst, op1) => result
        | R.EXT16TO32 (sign, dst, op1) => result
        | R.EXT32TO64 (sign, dst, op1) => result
        | R.DOWN32TO8 (sign, dst, op1) => result
        | R.DOWN32TO16 (sign, dst, op1) => result
        | R.ADD (ty, dst, op1, op2) => result
        | R.SUB (ty, dst, op1, op2) => result
        | R.MUL ((ty, dst), (ty2, op1), (ty3, op2)) => result
        | R.DIVMOD ({div, mod}, (ty3, op1), (ty4, op2)) => result
        | R.AND (ty, dst, op1, op2) => result
        | R.OR (ty, dst, op1, op2) => result
        | R.XOR (ty, dst, op1, op2) => result
        | R.LSHIFT (ty, dst, op1, op2) => result
        | R.RSHIFT (ty, dst, op1, op2) => result
        | R.ARSHIFT (ty, dst, op1, op2) => result
        | R.TEST_SUB (ty, op1, op2) => result
        | R.TEST_AND (ty, op1, op2) => result
        | R.TEST_LABEL (ptrTy, op1, label) => result
        | R.NOT (ty, dst, op1) => result
        | R.NEG (ty, dst, op1) => result
        | R.SET (cc1, ty, dst, {test}) => result
        | R.LOAD_FP dst => result
        | R.LOAD_SP dst => result
        | R.LOAD_PREV_FP dst => result
        | R.LOAD_RETADDR dst => result
        | R.LOADABSADDR {ty, dst, symbol, thunk} => result
        | R.X86 (R.X86LEAINT (ty, dst, {base, shift, offset, disp})) => result
        | R.X86 (R.X86FLD (ty, mem)) => result
        | R.X86 (R.X86FLD_ST x86st1) => result
        | R.X86 (R.X86FST (ty, mem)) => result
        | R.X86 (R.X86FSTP (ty, mem)) => result
        | R.X86 (R.X86FSTP_ST x86st1) => result
        | R.X86 (R.X86FADD (ty, mem)) => result
        | R.X86 (R.X86FADD_ST (x86st1, x86st2)) => result
        | R.X86 (R.X86FADDP x86st1) => result
        | R.X86 (R.X86FSUB (ty, mem)) => result
        | R.X86 (R.X86FSUB_ST (x86st1, x86st2)) => result
        | R.X86 (R.X86FSUBP x86st1) => result
        | R.X86 (R.X86FSUBR (ty, mem)) => result
        | R.X86 (R.X86FSUBR_ST (x86st1, x86st2)) => result
        | R.X86 (R.X86FSUBRP x86st1) => result
        | R.X86 (R.X86FMUL (ty, mem)) => result
        | R.X86 (R.X86FMUL_ST (x86st1, x86st2)) => result
        | R.X86 (R.X86FMULP x86st1) => result
        | R.X86 (R.X86FDIV (ty, mem)) => result
        | R.X86 (R.X86FDIV_ST (x86st1, x86st2)) => result
        | R.X86 (R.X86FDIVP x86st1) => result
        | R.X86 (R.X86FDIVR (ty, mem)) => result
        | R.X86 (R.X86FDIVR_ST (x86st1, x86st2)) => result
        | R.X86 (R.X86FDIVRP x86st1) => result
        | R.X86 R.X86FPREM => result
        | R.X86 R.X86FABS => result
        | R.X86 R.X86FCHS => result
        | R.X86 R.X86FINCSTP => result
        | R.X86 (R.X86FFREE x86st1) => result
        | R.X86 (R.X86FXCH x86st1) => result
        | R.X86 (R.X86FUCOM x86st1) => result
        | R.X86 (R.X86FUCOMP x86st1) => result
        | R.X86 R.X86FUCOMPP => result
        | R.X86 (R.X86FSW_TESTH {clob,mask}) => result
        | R.X86 (R.X86FSW_MASKCMPH {clob,mask,compare}) => result
        | R.X86 (R.X86FLDCW mem) => result
        | R.X86 (R.X86FNSTCW mem) => result
        | R.X86 R.X86FWAIT => result
        | R.X86 R.X86FNCLEX => result
      end

  fun actualLast (last, result) =
      let
        val {defs, uses} = RTLUtils.Var.defuseLast last
        val result = actuallyLoaded (result, uses)
        val result = setStatus (result, defs, LOADED)
      in
        case last of
          R.HANDLE (insn, {nextLabel, handler}) => result
        | R.CJUMP {test, cc, thenLabel, elseLabel} => result
        | R.CALL {callTo, returnTo, handler, defs=_, uses, needStabilize,
                  postFrameAdjust} =>
          setStatus (stabilizeActualPtr result, defs, LOADED)
        | R.JUMP {jumpTo, destinations} => result
        | R.UNWIND_JUMP {jumpTo, sp, fp, uses, handler} => result
        | R.TAILCALL_JUMP {preFrameSize, jumpTo, uses} => result
        | R.RETURN {preFrameSize, stubOptions, uses} => result
        | R.EXIT => result
      end

  fun passActual (node, result) =
      case node of
        RTLEdit.FIRST first => actualFirst (first, result)
      | RTLEdit.MIDDLE insn => actualInsn (insn, result)
      | RTLEdit.LAST last => actualLast (last, result)






  local
    fun makeSlot ({id,ty}:R.var) =
        R.MEM (ty, R.SLOT {id = id, format = Emit.formatOf ty})

    fun makeSave vars =
        RTLUtils.Var.fold
          (fn (var as {ty,...}, z) =>
              R.MOVE (ty, makeSlot var, R.REF_ (R.REG var)) :: z)
          nil
          vars

    fun makeLoad vars =
        RTLUtils.Var.fold
          (fn (var as {ty,...}, z) =>
              R.MOVE (ty, R.REG var, R.REF_ (makeSlot var)) :: z)
          nil
          vars

    fun insertLastWithFollower (focus, last, nil) =
        RTLEdit.insertLast (focus, last)
      | insertLastWithFollower (focus, last, insns) =
        case last of
          R.HANDLE (insn, {nextLabel, handler}) =>
          let
            val focus = RTLEdit.insertLast (focus, RTLEdit.jump nextLabel)
            val focus = RTLEdit.insertAfter (focus, insns)
            val (focus, _) =
                RTLEdit.insertLastAfter
                  (focus, fn l => R.HANDLE (insn, {nextLabel=l,
                                                   handler=handler}))
          in
            focus
          end
        | R.CALL {callTo, returnTo, handler, defs, uses, needStabilize,
                  postFrameAdjust} =>
          let
            val focus = RTLEdit.insertLast (focus, RTLEdit.jump returnTo)
            val focus = RTLEdit.insertAfter (focus, insns)
            val (focus, _) =
                RTLEdit.insertLastAfter
                  (focus, fn l => R.CALL {callTo=callTo, returnTo=l,
                                          handler=handler,
                                          defs=defs, uses=uses,
                                          needStabilize=needStabilize,
                                          postFrameAdjust=postFrameAdjust})
          in
            focus
          end
        | R.CJUMP {test, cc, thenLabel, elseLabel} =>
          RTLEdit.insertLast (RTLEdit.insertBefore (focus, insns), last)
        | R.JUMP {jumpTo, destinations} =>
          RTLEdit.insertLast (RTLEdit.insertBefore (focus, insns), last)
        | R.UNWIND_JUMP {jumpTo, sp, fp, uses, handler} =>
          RTLEdit.insertLast (RTLEdit.insertBefore (focus, insns), last)
        | R.TAILCALL_JUMP {preFrameSize, jumpTo, uses} =>
          RTLEdit.insertLast (RTLEdit.insertBefore (focus, insns), last)
        | R.RETURN {preFrameSize, stubOptions, uses} =>
          RTLEdit.insertLast (RTLEdit.insertBefore (focus, insns), last)
        | R.EXIT =>
          RTLEdit.insertLast (RTLEdit.insertBefore (focus, insns), last)
  in

  fun insertSaveAfter (node, vars) =
      case node of
        RTLEdit.FIRST first =>
        let
          val focus = RTLEdit.singletonFirst first
          val focus = RTLEdit.insertAfter (focus, makeSave vars)
        in
          focus
        end
      | RTLEdit.MIDDLE insn =>
        let
          val focus = RTLEdit.singletonFirst R.ENTER
          val focus = RTLEdit.insertBefore (focus, [insn])
          val focus = RTLEdit.insertAfter (focus, makeSave vars)
        in
          focus
        end
      | RTLEdit.LAST last =>
        let
          val focus = RTLEdit.singletonFirst R.ENTER
        in
          insertLastWithFollower (focus, last, makeSave vars)
        end

  fun insertLoadBefore (node, vars) =
      case node of
        RTLEdit.FIRST first => RTLEdit.singletonFirst first
      | RTLEdit.MIDDLE insn =>
        let
          val focus = RTLEdit.singletonFirst R.ENTER
          val focus = RTLEdit.insertBefore (focus, makeLoad vars)
          val focus = RTLEdit.insertAfter (focus, [insn])
        in
          focus
        end
      | RTLEdit.LAST last =>
        let
          val focus = RTLEdit.singletonFirst R.ENTER
          val focus = RTLEdit.insertBefore (focus, makeLoad vars)
          val focus = RTLEdit.insertLast (focus, last)
        in
          focus
        end

  fun insertLastWithLoad (focus, last, answerOut, graph) =
      let
        val succ =
            foldl
              (fn (label, succ) =>
                  let
                    val x = RTLEdit.focusBlock (graph, label)
                    val a = RTLEdit.annotation x : actual answer
                  in
                    join mergeActual (succ, #answerIn a)
                  end)
              VarID.Map.empty
              (RTLUtils.successors last)
(*
val _ = Control.ps "----last+load"
val _ = Control.p (format_result format_actual) answerOut
val _ = Control.p (format_result format_actual) succ
*)
        val vars =
            VarID.Map.foldli
              (fn (id, (ty, s1), vars) =>
                  let
                    val s2 = case VarID.Map.find (succ, id) of
                               SOME (_, s) => s
                             | NONE => raise Control.Bug ("insertLoadWithLoad "^Control.prettyPrint (R.format_id id))
                  in
                    case (s1, s2) of
                      (LOADED, LOADED) => vars
                    | (CACHED, CACHED) => vars
                    | (CACHED, LOADED) => vars
                    | (SAVED, CACHED) => {id=id,ty=ty}::vars
                    | (SAVED, LOADED) => {id=id,ty=ty}::vars
                    | (SAVED, SAVED) => vars
                    | _ => raise Control.Bug ("insertLoadWithLoad "^Control.prettyPrint (format_actual s1)^" -> "^Control.prettyPrint (format_actual s2))
                  end)
              nil
              answerOut
        val vars = RTLUtils.Var.fromList vars
      in
        insertLastWithFollower (focus, last, makeLoad vars)
      end

  end (* local *)

  fun select f (result:'a result, varSet) =
      RTLUtils.Var.filter
        (fn {id,...}:R.var =>
            case VarID.Map.find (result, id) of
              SOME (_, x) => f x
            | NONE => false)
        varSet

  fun insertSave graph =
      RTLEdit.rewrite
        (RTLEdit.rewriteBackward
           (fn (node, {answerOut, answerIn, succs, preds}) =>
               let
(*
val _ = Control.ps "----rewrite"
val _ = Control.p RTLEdit.format_node node
val _ = Control.p (format_result format_request) answerOut
*)
                 val {defs, ...} = RTLUtils.Var.defuse node
                 val vars = select (fn x => x = SAVE) (answerOut, defs)
                 val g = RTLEdit.unfocus (insertSaveAfter (node, vars))
(*
val _ = Control.p R.format_graph g
val _ = Control.ps "----"
*)
               in
                 (g, {answerOut = passRequest (node, answerOut),
                      answerIn = answerIn,
                      succs = succs,
                      preds = preds})
               end))
        graph

  fun insertLoad graph =
      RTLEdit.rewrite
        (RTLEdit.rewriteForward
           (fn (node, {answerOut, answerIn, succs, preds}) =>
               let
                 val {uses, ...} = RTLUtils.Var.defuse node
                 val vars = select (fn x => x = SAVED) (answerIn, uses)
                 val focus = insertLoadBefore (node, vars)
                 val focus =
                     case node of
                       RTLEdit.FIRST _ => focus
                     | RTLEdit.MIDDLE _ => focus
                     | RTLEdit.LAST last =>
                       insertLastWithLoad (focus, last, answerOut, graph)
                 val g = RTLEdit.unfocus focus
               in
                 (g, {answerOut = answerOut,
                      answerIn = passActual (node, answerIn),
                      succs = succs,
                      preds = preds})
               end))
        graph

  fun stabilizeGraph graph =
      let
        val request = RTLUtils.analyzeFlowBackward
                        {init = VarID.Map.empty,
                         join = join mergeRequest,
                         pass = passRequest,
                         filterIn = fn (_,x) => x,
                         filterOut = fn (_,x) => x,
                         changed = changed mergeRequest}
                        graph
        val graph = insertSave request

        val liveness = RTLEdit.annotations request

        fun filterIn (label, map) =
            case R.LabelMap.find (liveness, label) of
              NONE => map
            | SOME {answerIn=live,...} =>
              VarID.Map.filteri
                (fn (i,_) => VarID.Map.inDomain (live, i))
                map

        fun filterOut (label, map) =
            case R.LabelMap.find (liveness, label) of
              NONE => map
            | SOME {answerOut=live,...} =>
              VarID.Map.filteri
                (fn (i,_) => VarID.Map.inDomain (live, i))
                map

        val actual = RTLUtils.analyzeFlowForward
                       {init = VarID.Map.empty,
                        join = join mergeActual,
                        pass = passActual,
                        filterIn = filterIn,
                        filterOut = filterOut,
                        changed = changed mergeActual}
                       graph

        val graph = insertLoad actual
      in
        graph
      end


  fun stabilize program =
      RTLUtils.mapCluster stabilizeGraph program

end
