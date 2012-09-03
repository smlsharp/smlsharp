(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure X86Constraint : RTLCONSTRAINT =
struct

  structure I = RTL
  structure X = X86Asm
  structure Target = X86Asm

  fun newVar ty =
      let
        val id = Counters.newLocalId ()
      in
        {id = id, ty = ty} : I.var
      end

  fun splitVar (code:RTLEdit.focus) (var as {ty,...}:I.var) =
      let
        val var2 = newVar ty
      in
        (code, [{orig=var, tmp=var2}], var2)
      end

  fun splitVarList code (var::vars) =
      let
        val (code, pairs1, var) = splitVar code var
        val (code, pairs2, vars) = splitVarList code vars
      in
        (code, pairs1 @ pairs2, var::vars)
      end
    | splitVarList code nil = (code, nil, nil)

  fun load (code, pairs, vars) =
      (foldl (fn ({orig as {ty,...}, tmp}, z) =>
                 RTLEdit.insertBefore
                   (z, [I.MOVE (ty, I.REG tmp, I.REF_ (I.REG orig))]))
             code
             pairs,
       vars)

  fun save (code, pairs, vars) =
      (foldl (fn ({orig as {ty,...}, tmp}, z) =>
                 RTLEdit.insertAfter
                   (z, [I.MOVE (ty, I.REG orig, I.REF_ (I.REG tmp))]))
             code
             pairs,
       vars)

  fun splitDst code (I.REG var) =
      let
        val (code, pairs, var) = splitVar code var
      in
        (code, pairs, I.REG var)
      end
    | splitDst code (I.COUPLE (ty, {hi, lo})) =
      let
        val (code, pairs1, hi) = splitDst code hi
        val (code, pairs2, lo) = splitDst code lo
      in
        (code, pairs1 @ pairs2, I.COUPLE (ty, {hi=hi, lo=lo}))
      end
    | splitDst code (dst as I.MEM _) = (code, nil, dst)

  fun splitOperand code (I.REF (cast, dst)) =
      let
        val (code, dst) = load (splitDst code dst)
      in
        (code, I.REF (cast, dst))
      end
    | splitOperand code (op1 as I.CONST _) = (code, op1)

  fun splitAddr code (ptrTy, I.BASE var) =
      let
        val (code, var) = load (splitVar code var)
      in
        (code, I.BASE var)
      end
    | splitAddr code (ptrTy, addr) = (code, addr)

  fun splitPrecolored2 code con (sign, dst, op1) =
      let
        val (code, dst) = save (splitDst code dst)
        val (code, op1) = splitOperand code op1
      in
        (code, con (sign, dst, op1))
      end

  fun splitCoalesce3 code con (ty, dst, op1, op2) =
      let
        val (code, op1) = splitOperand code op1
      in
        (code, con (ty, dst, op1, op2))
      end

  fun splitCoalesce2 code con (ty, dst, op1) =
      let
        val (code, op1) = splitOperand code op1
      in
        (code, con (ty, dst, op1))
      end

  fun splitShift code con (ty, dst, op1, op2) =
      let
        val (code, op1) = splitOperand code op1
        val (code, op2) = splitOperand code op2
      in
        (code, con (ty, dst, op1, op2))
      end

  fun splitInsn code insn =
      case insn of
        I.NOP => (code, insn)
      | I.STABILIZE => (code, insn)
      | I.REQUEST_SLOT slot => (code, insn)
      | I.REQUIRE_SLOT slot => (code, insn)
      | I.USE vars => (code, insn)
      | I.COMPUTE_FRAME {uses, clobs} => (code, insn)
      | I.MOVE (ty1, dst, op1) => (code, insn)
      | I.MOVEADDR (ty, dst, addr) => (code, insn)
      | I.COPY {ty, dst, src, clobs} => (code, insn)
      | I.MLOAD {ty, dst:I.slot, srcAddr, size, defs, clobs} =>
        let
          val (code, srcAddr) = splitAddr code (I.Void, srcAddr)
          val (code, size) = splitOperand code size
          val (code, defs) = save (splitVarList code defs)
        in
          (code, I.MLOAD {ty=ty, dst=dst, srcAddr=srcAddr, size=size,
                          defs=defs, clobs=clobs})
        end
      | I.MSTORE {ty, dstAddr, src:I.slot, size, defs, clobs, global} =>
        let
          val (code, dstAddr) = splitAddr code (I.Void, dstAddr)
          val (code, size) = splitOperand code size
          val (code, defs) = save (splitVarList code defs)
        in
          (code, I.MSTORE {ty=ty, dstAddr=dstAddr, src=src, size=size,
                           defs=defs, clobs=clobs, global=global})
        end
(*
      | I.EXT8TO16 (sign, dst, op1) => (code, insn)
*)
      | I.EXT8TO32 (sign, dst, op1) => (code, insn)
      | I.EXT16TO32 (sign, dst, op1) => (code, insn)
(*
      | I.SIGNEXT8TO16 (sign, dst, op1) =>
        splitPrecolored2 code I.SIGNEXT8TO16 (sign, dst, op1)
      | I.SIGNEXT8TO32 (sign, dst, op1) =>
        splitPrecolored2 code I.SIGNEXT8TO32 (sign, dst, op1)
      | I.SIGNEXT16TO32 (sign, dst, op1) =>
        splitPrecolored2 code I.SIGNEXT16TO32 (sign, dst, op1)
*)
      | I.EXT32TO64 (sign, dst as I.COUPLE _, op1) =>
        splitPrecolored2 code I.EXT32TO64 (sign, dst, op1)
      | I.EXT32TO64 (sign, dst, op1) => (code, insn)
      | I.DOWN32TO8 (sign, dst, op1) => (code, insn)
      | I.DOWN32TO16 (sign, dst, op1) => (code, insn)
(*
      | I.DOWN16TO8 (sign, dst, op1) => (code, insn)
*)
      | I.ADD (ty, dst, op1, op2) =>
        splitCoalesce3 code I.ADD (ty, dst, op1, op2)
      | I.SUB (ty, dst, op1, op2) =>
        splitCoalesce3 code I.SUB (ty, dst, op1, op2)
      | I.MUL ((ty, dst as I.COUPLE _), (ty1, op1), op2) =>
        let
          val (code, dst) = save (splitDst code dst)
          val (code, op1) = splitOperand code op1
        in
          (code, I.MUL ((ty, dst), (ty1, op1), op2))
        end
      | I.MUL ((ty, dst), (ty2, op1), (ty3, op2)) =>
        splitCoalesce3 code
          (fn (_, dst, op1, op2) => I.MUL ((ty, dst), (ty2, op1), (ty3, op2)))
          (ty, dst, op1, op2)
      | I.DIVMOD ({div=(divTy, ddiv), mod=(modTy, dmod)}, (ty1, op1), op2) =>
        let
          val (code, ddiv) = save (splitDst code ddiv)
          val (code, dmod) = save (splitDst code dmod)
          val (code, op1) = splitOperand code op1
        in
          (code, I.DIVMOD ({div=(divTy,ddiv), mod=(modTy,dmod)},
                           (ty1, op1), op2))
        end
      | I.AND (ty, dst, op1, op2) =>
        splitCoalesce3 code I.AND (ty, dst, op1, op2)
      | I.OR (ty, dst, op1, op2) =>
        splitCoalesce3 code I.OR (ty, dst, op1, op2)
      | I.XOR (ty, dst, op1, op2) =>
        splitCoalesce3 code I.XOR (ty, dst, op1, op2)
      | I.LSHIFT (ty, dst, op1, op2) =>
        splitShift code I.LSHIFT (ty, dst, op1, op2)
      | I.RSHIFT (ty, dst, op1, op2) =>
        splitShift code I.RSHIFT (ty, dst, op1, op2)
      | I.ARSHIFT (ty, dst, op1, op2) =>
        splitShift code I.ARSHIFT (ty, dst, op1, op2)
      | I.TEST_SUB (ty, op1, op2) => (code, insn)
      | I.TEST_AND (ty, op1, op2) => (code, insn)
      | I.TEST_LABEL (ty, op1, op2) => (code, insn)
      | I.NOT (ty, dst, op1) => splitCoalesce2 code I.NOT (ty, dst, op1)
      | I.NEG (ty, dst, op1) => splitCoalesce2 code I.NEG (ty, dst, op1)
      | I.SET (cc, ty, dst, {test}) =>
        let
          val (code, test) = splitInsn code test
        in
          (code, I.SET (cc, ty, dst, {test=test}))
        end
      | I.LOAD_FP dst => (code, insn)
      | I.LOAD_SP dst => (code, insn)
      | I.LOAD_PREV_FP dst => (code, insn)
      | I.LOAD_RETADDR dst => (code, insn)
      (* dst must be a register but this is a special case;
       * we don't split its liverange here. *)
      | I.LOADABSADDR {ty, dst, symbol, thunk} => (code, insn)
      | I.X86 (I.X86LEAINT (ty, dst, addr)) => (code, insn)
      | I.X86 (I.X86FLD (ty, op1)) => (code, insn)
      | I.X86 (I.X86FLD_ST x86st1) => (code, insn)
      | I.X86 (I.X86FST (ty, addr)) => (code, insn)
      | I.X86 (I.X86FSTP (ty, dst)) => (code, insn)
      | I.X86 (I.X86FSTP_ST x86st1) => (code, insn)
      | I.X86 (I.X86FADD (ty, op1)) => (code, insn)
      | I.X86 (I.X86FADD_ST (x86st1, x86st2)) => (code, insn)
      | I.X86 (I.X86FADDP x86st1) => (code, insn)
      | I.X86 (I.X86FSUB (ty, op1)) => (code, insn)
      | I.X86 (I.X86FSUB_ST (x86st1, x86st2)) => (code, insn)
      | I.X86 (I.X86FSUBP x86st1) => (code, insn)
      | I.X86 (I.X86FSUBR (ty, op1)) => (code, insn)
      | I.X86 (I.X86FSUBR_ST (x86st1, x86st2)) => (code, insn)
      | I.X86 (I.X86FSUBRP x86st1) => (code, insn)
      | I.X86 (I.X86FMUL (ty, op1)) => (code, insn)
      | I.X86 (I.X86FMUL_ST (x86st1, x86st2)) => (code, insn)
      | I.X86 (I.X86FMULP x86st1) => (code, insn)
      | I.X86 (I.X86FDIV (ty, op1)) => (code, insn)
      | I.X86 (I.X86FDIV_ST (x86st1, x86st2)) => (code, insn)
      | I.X86 (I.X86FDIVP x86st1) => (code, insn)
      | I.X86 (I.X86FDIVR (ty, op1)) => (code, insn)
      | I.X86 (I.X86FDIVR_ST (x86st1, x86st2)) => (code, insn)
      | I.X86 (I.X86FDIVRP x86st1) => (code, insn)
      | I.X86 (I.X86FABS) => (code, insn)
      | I.X86 (I.X86FCHS) => (code, insn)
      | I.X86 (I.X86FFREE st) => (code, insn)
      | I.X86 (I.X86FXCH st) => (code, insn)
(*
      | I.X86 (I.X86FUCOMPP_FSTSW dst) =>
        let
          val (code, dst) = save (splitDst code dst)
        in
          (code, I.X86 (I.X86FUCOMPP_FSTSW dst))
        end
*)
      | I.X86 (I.X86FUCOM st) => (code, insn)
      | I.X86 (I.X86FUCOMP st) => (code, insn)
      | I.X86 I.X86FUCOMPP => (code, insn)
      | I.X86 (I.X86FSW_GT {clob}) => (code, insn)
      | I.X86 (I.X86FSW_GE {clob}) => (code, insn)
      | I.X86 (I.X86FSW_EQ {clob}) => (code, insn)
      | I.X86 (I.X86FLDCW op1) => (code, insn)
      | I.X86 (I.X86FNSTCW dst) => (code, insn)
      | I.X86 I.X86FWAIT => (code, insn)
      | I.X86 I.X86FNCLEX => (code, insn)

  fun splitFirst first =
      case first of
        I.ENTER => RTLEdit.singletonFirst first
      | I.BEGIN _ => RTLEdit.singletonFirst first
      | I.CODEENTRY {label, symbol, scope, align, preFrameSize, preFrameAligned,
                     defs, loc} =>
        let
          val code = RTLEdit.singletonFirst I.ENTER
          val (code, defs) = save (splitVarList code defs)
        in
          RTLEdit.insertFirst
            (code, I.CODEENTRY {label=label, symbol=symbol, scope=scope,
                                align=align, preFrameSize=preFrameSize,
                                preFrameAligned = preFrameAligned,
                                defs=defs, loc=loc})
        end
      | I.HANDLERENTRY {label, align, defs, loc} =>
        let
          val code = RTLEdit.singletonFirst I.ENTER
          val (code, defs) = save (splitVarList code defs)
        in
          RTLEdit.insertFirst
            (code, I.HANDLERENTRY {label=label, align=align,
                                   defs=defs, loc=loc})
        end

  fun splitLast last =
      case last of
        I.HANDLE (insn, {nextLabel, handler}) =>
        let
          val code = RTLEdit.singletonLast (RTLEdit.jump nextLabel)
          val (code, insn) = splitInsn code insn
          val (code, _) =
              RTLEdit.insertLastAfter
                (code, fn l => I.HANDLE (insn, {nextLabel=l, handler=handler}))
        in
          code
        end
      | I.CJUMP {test, cc, thenLabel, elseLabel} =>
        let
          val code = RTLEdit.singletonFirst I.ENTER
          val (code, test) = splitInsn code test
        in
          if RTLEdit.atLast code
          then RTLEdit.insertLast
                 (code, I.CJUMP {test=test, cc=cc, thenLabel=thenLabel,
                                 elseLabel=elseLabel})
          else raise Control.Bug "splitLast: CJUMP"
        end
      | I.CALL {callTo, returnTo, handler, defs, uses, needStabilize,
                postFrameAdjust} =>
        let
          val code = RTLEdit.singletonLast (RTLEdit.jump returnTo)
          val (code, defs) = save (splitVarList code defs)
          val (code, uses) = load (splitVarList code uses)
          val (code, _) =
              RTLEdit.insertLastAfter
                (code, fn l => I.CALL {callTo=callTo, returnTo=l,
                                       handler=handler,
                                       defs=defs, uses=uses,
                                       needStabilize=needStabilize,
                                       postFrameAdjust=postFrameAdjust})
        in
          code
        end
      | I.JUMP {jumpTo, destinations} => RTLEdit.singletonLast last
      | I.UNWIND_JUMP {jumpTo, fp, sp, uses, handler} =>
        let
          val code = RTLEdit.singletonFirst I.ENTER
          val (code, uses) = load (splitVarList code uses)
        in
          RTLEdit.insertLast
            (code, I.UNWIND_JUMP {jumpTo=jumpTo, fp=fp, sp=sp,
                                  uses=uses, handler=handler})
        end
      | I.TAILCALL_JUMP {preFrameSize, jumpTo, uses} =>
        let
          val code = RTLEdit.singletonFirst I.ENTER
          val (code, uses) = load (splitVarList code uses)
        in
          RTLEdit.insertLast
            (code, I.TAILCALL_JUMP {preFrameSize=preFrameSize,
                                    jumpTo=jumpTo,
                                    uses=uses})
        end
      | I.RETURN {preFrameSize, preFrameAligned, uses} =>
        let
          val code = RTLEdit.singletonFirst I.ENTER
          val (code, uses) = load (splitVarList code uses)
        in
          RTLEdit.insertLast
            (code, I.RETURN {preFrameSize=preFrameSize,
                             preFrameAligned=preFrameAligned,
                             uses=uses})
        end
      | I.EXIT => RTLEdit.singletonLast I.EXIT

  fun split graph =
      RTLEdit.extend
(*
(fn x =>
(Control.ps "--";
Control.p RTLEdit.format_node x;
let val x =
*)
        (fn RTLEdit.FIRST first => RTLEdit.unfocus (splitFirst first)
          | RTLEdit.MIDDLE insn =>
            let
              val (code, insn) = splitInsn (RTLEdit.singletonFirst I.ENTER) insn
            in
              RTLEdit.unfocus (RTLEdit.insertBefore (code, [insn]))
            end
          | RTLEdit.LAST last => RTLEdit.unfocus (splitLast last))
(*
x
in
Control.p I.format_graph x;
x
end))*)
        graph

  val allRegisters = [X.EAX, X.EBX, X.ECX, X.EDX, X.EDI, X.ESI]
  val calleeSaveRegs = [X.EDI, X.ESI, X.EBX]
  val callerSaveRegs = [X.EAX, X.EDX, X.ECX]
  val regsOnly32 = [X.EDI, X.ESI]

  fun precolorVar (interference, var, reg) =
      let
        val interference =
            Interference.interfereWithColors
              (interference, var, List.filter (fn r => r <> reg) allRegisters)
      in
        Interference.disallowSpill (interference, var)
      end

  fun precolorVarList (interference, vars, regs) =
      ListPair.foldl
          (fn (var, color, interference) =>
              precolorVar (interference, var, color))
          interference
          (vars, regs)

  fun precolorVarList8 (interference, vars) =
      foldl
        (fn (var, interference) =>
            Interference.interfereWithColors (interference, var, regsOnly32))
        interference
        vars

  fun precolorDst (interference, I.REG var, reg) =
      precolorVar (interference, var, reg)
    | precolorDst (interference, I.MEM _, reg) = interference
    | precolorDst (interference, I.COUPLE _, reg) =
      raise Control.Bug "precolorDst: COUPLE"

  fun precolorOperand (interference, I.REF (_, dst), reg) =
      precolorDst (interference, dst, reg)
    | precolorOperand (interference, I.CONST _, reg) = interference

  fun precolorAddr (interference, I.BASE var, reg) =
      precolorVar (interference, var, reg)
    | precolorAddr (interference, I.ADDRCAST (_, addr), reg) =
      precolorAddr (interference, addr, reg)
    | precolorAddr (interference, I.DISP (_, addr), reg) = 
      precolorAddr (interference, addr, reg)
    | precolorAddr (interference, I.ABSADDR _, reg) = interference
    | precolorAddr (interference, I.ABSINDEX _, reg) = interference
    | precolorAddr (interference, I.BASEINDEX _, reg) = interference
    | precolorAddr (interference, I.POSTFRAME _, reg) = interference
    | precolorAddr (interference, I.PREFRAME _, reg) = interference
    | precolorAddr (interference, I.WORKFRAME _, reg) = interference
    | precolorAddr (interference, I.FRAMEINFO _, reg) = interference

  fun precolorDst8 (interference, I.REG var) =
      Interference.interfereWithColors (interference, var, regsOnly32)
    | precolorDst8 (interference, I.MEM _) = interference
    | precolorDst8 (interference, I.COUPLE _) =
      raise Control.Bug "precolorDst8: COUPLE"

  fun precolorOperand8 (interference, I.REF (_, dst)) =
      precolorDst8 (interference, dst)
    | precolorOperand8 (interference, I.CONST _) = interference

  fun precolorDstByTy (interference, ty, dst) =
      if (case ty of I.Int8 _ => true | I.Int16 _ => true | _ => false)
      then precolorDst8 (interference, dst)
      else interference

  fun precolorOperandByTy (interference, ty, op1) =
      if (case ty of I.Int8 _ => true | I.Int16 _ => true | _ => false)
      then precolorOperand8 (interference, op1)
      else interference

  fun precolorDst64 (interference, I.COUPLE (_, {hi=hi,lo=lo})) =
      precolorDst (precolorDst (interference, hi, X.EDX), lo, X.EAX)
    | precolorDst64 (interference, I.REG _) = interference
    | precolorDst64 (interference, I.MEM _) = interference

  fun precolorOperand64 (interference, I.REF (_, dst)) =
      precolorDst64 (interference, dst)
    | precolorOperand64 (interference, I.CONST _) = interference

  fun coalesceDst (interference, I.REG var1, I.REG var2) =
      Interference.coalesce (interference, var1, var2)
    | coalesceDst (interference, I.COUPLE (_,c1), I.COUPLE (_,c2)) =
      let
        val interference = coalesceDst (interference, #hi c1, #hi c2)
        val interference = coalesceDst (interference, #lo c1, #lo c2)
      in
        interference
      end
    | coalesceDst (interference, _, _) = interference

  fun coalesce (interference, dst, I.REF (_, op1)) =
      coalesceDst (interference, dst, op1)
    | coalesce (interference, dst, I.CONST _) = interference

  fun precolorArith2 (interference, ty, dst, op1) =
      let
        val interference = precolorDstByTy (interference, ty, dst)
        val interference = coalesce (interference, dst, op1)
      in
        interference
      end

  fun precolorArith3 (interference, ty, dst, op1, op2) =
      let
        val interference = precolorDstByTy (interference, ty, dst)
        val interference = coalesce (interference, dst, op1)
        val interference = precolorOperandByTy (interference, ty, op2)
      in
        interference
      end

  fun precolorShift (interference, ty, dst, op1, op2) =
      let
        val interference = coalesce (interference, dst, op1)
        val interference = precolorDstByTy (interference, ty, dst)
        val interference = precolorOperand (interference, op2, X.ECX)
      in
        interference
      end

  fun precolorTest (interference, ty, op1, op2) =
      let
        val interference = precolorOperandByTy (interference, ty, op1)
        val interference = precolorOperandByTy (interference, ty, op2)
      in
        interference
      end

(*
  fun passArgs (interference, vars) =
      precolorVarList (interference, vars, [X.EAX, X.EDX, X.ECX])

  fun callerSave (interference, vars as [_, _, _]) =
      passArgs (interference, vars)
    | callerSave _ = raise Control.Bug "callerSave"

  fun calleeSave (interference, vars as [var1, var2, var3]) =
      precolorVarList (interference, vars, [X.ESI, X.EDI, X.EBX])
    | calleeSave _ = raise Control.Bug "calleeSave"
*)

  fun copyRegs (interference, vars as [_,_,_]) =
      precolorVarList (interference, vars, [X.EDI, X.ESI, X.ECX])
    | copyRegs _ = raise Control.Bug "copyRegs"

  fun moveRelated (interference, I.REG v1, I.REF (_, I.REG v2)) =
      Interference.requestCoalesce (interference, v1, v2)
    | moveRelated (interference, _, I.REF _) = interference
    | moveRelated (interference, _, I.CONST _) = interference

  fun constrainInsn (insn, interference) =
      case insn of
        I.NOP => interference
      | I.STABILIZE => interference
      | I.REQUEST_SLOT slot => interference
      | I.REQUIRE_SLOT slot => interference
      | I.USE vars => interference
      | I.COMPUTE_FRAME {uses, clobs} => interference
      | I.MOVE (ty, dst, op1) =>
        let
          val interference = moveRelated (interference, dst, op1)
          val interference = precolorDstByTy (interference, ty, dst)
          val interference = precolorOperandByTy (interference, ty, op1)
        in
          interference
        end
      | I.MOVEADDR (ty, dst, I.BASE reg) =>
        moveRelated (interference, dst, I.REF_ (I.REG reg))
      | I.MOVEADDR (ty, dst, addr) => interference
      | I.COPY {ty, dst, src, clobs} =>
        if #size (X86Emit.formatOf ty) mod 4 = 0
        then interference
        else precolorVarList8 (interference, clobs)
      | I.MLOAD {ty, dst:I.slot, srcAddr, size, defs, clobs} =>
        let
          val interference = precolorAddr (interference, srcAddr, X.ESI)
          val interference = precolorOperand (interference, size, X.ECX)
          val interference = copyRegs (interference, defs @ clobs)
        in
          interference
        end
      | I.MSTORE {ty, dstAddr, src:I.slot, size, defs, clobs, global} =>
        let
          val interference = precolorAddr (interference, dstAddr, X.EDI)
          val interference = precolorOperand (interference, size, X.ECX)
          val interference = copyRegs (interference, defs @ clobs)
        in
          interference
        end
(*
      | I.ZEROEXT8TO16 (sign, dst, op1) => precolorOperand8 (interference, op1)
      | I.ZEROEXT8TO32 (sign, dst, op1) => precolorOperand8 (interference, op1)
      | I.ZEROEXT16TO32 (sign, dst, op1) => precolorOperand8 (interference, op1)
      | I.EXT8TO16 (sign, dst, op1) => precolorOperand8 (interference, op1)
*)
      | I.EXT8TO32 (sign, dst, op1) => precolorOperand8 (interference, op1)
      | I.EXT16TO32 (sign, dst, op1) => precolorOperand8 (interference, op1)
(*
      | I.SIGNEXT8TO16 (sign, dst, op1) =>
        let
          val interference = precolorDst (interference, dst, X.EAX)
          val interference = precolorOperand (interference, op1, X.EAX)
        in
          interference
        end
      | I.SIGNEXT8TO32 (sign, dst, op1) =>
        let
          val interference = precolorDst (interference, dst, X.EAX)
          val interference = precolorOperand (interference, op1, X.EAX)
        in
          interference
        end
      | I.SIGNEXT16TO32 (sign, dst, op1) =>
        let
          val interference = precolorDst (interference, dst, X.EAX)
          val interference = precolorOperand (interference, op1, X.EAX)
        in
          interference
        end
*)
      | I.EXT32TO64 (sign, dst as I.COUPLE _, op1) =>
        let
          val interference = precolorDst64 (interference, dst)
          val interference = precolorOperand (interference, op1, X.EAX)
        in
          interference
        end
      | I.EXT32TO64 (sign, dst, op1) => interference
      | I.DOWN32TO8 (sign, dst, op1) =>
        let
          val interference = precolorDst8 (interference, dst)
          val interference = precolorOperand8 (interference, op1)
          val interference = moveRelated (interference, dst, op1)
        in
          interference
        end
      | I.DOWN32TO16 (sign, dst, op1) =>
        let
          val interference = precolorDst8 (interference, dst)
          val interference = precolorOperand8 (interference, op1)
          val interference = moveRelated (interference, dst, op1)
        in
          interference
        end
(*
      | I.DOWN16TO8 (sign, dst, op1) =>
        let
          val interference = precolorDst8 (interference, dst)
          val interference = precolorOperand8 (interference, op1)
        in
          interference
        end
*)
      | I.ADD (ty, dst, op1, op2) =>
        precolorArith3 (interference, ty, dst, op1, op2)
      | I.SUB (ty, dst, op1, op2) =>
        precolorArith3 (interference, ty, dst, op1, op2)
      | I.MUL ((_, dst as I.COUPLE _), (_, op1 as I.REF (_, I.COUPLE _)),
               _) =>
        let
          val interference = precolorDst64 (interference, dst)
          val interference = precolorOperand64 (interference, op1)
        in
          interference
        end
      | I.MUL ((ty, dst), (ty2, op1), (ty3, op2)) =>
        (
          case (dst, op1, op2) of
            (I.REG _, I.REF (_, I.REG _), I.REF (_, I.REG _)) =>
            coalesce (interference, dst, op1)
          | (_, _, I.REF (_, I.MEM _)) =>
            coalesce (interference, dst, op1)
          | (_, I.REF (_, I.MEM _), _) =>
            coalesce (interference, dst, op2)
          | _ => interference
        )
      | I.DIVMOD ({div=(ty, ddiv), mod=(ty2, dmod)}, (ty3, op1), (ty4, op2)) =>
        let
          val interference = precolorDst (interference, ddiv, X.EAX)
          val interference = precolorDst (interference, dmod, X.EDX)
          val interference = precolorOperand64 (interference, op1)
        in
          interference
        end
      | I.AND (ty, dst, op1, op2) =>
        precolorArith3 (interference, ty, dst, op1, op2)
      | I.OR (ty, dst, op1, op2) =>
        precolorArith3 (interference, ty, dst, op1, op2)
      | I.XOR (ty, dst, op1, op2) =>
        precolorArith3 (interference, ty, dst, op1, op2)
      | I.LSHIFT (ty, dst, op1, op2) =>
        precolorShift (interference, ty, dst, op1, op2)
      | I.RSHIFT (ty, dst, op1, op2) =>
        precolorShift (interference, ty, dst, op1, op2)
      | I.ARSHIFT (ty, dst, op1, op2) =>
        precolorShift (interference, ty, dst, op1, op2)
      | I.TEST_SUB (ty, op1, op2) =>
        precolorTest (interference, ty, op1, op2)
      | I.TEST_AND (ty, op1, op2) =>
        precolorTest (interference, ty, op1, op2)
      | I.TEST_LABEL (ty, op1, label) => interference
      | I.NOT (ty, dst, op1) =>
        precolorArith2 (interference, ty, dst, op1)
      | I.NEG (ty, dst, op1) =>
        precolorArith2 (interference, ty, dst, op1)
      | I.SET (cc, ty, dst, {test}) =>
        let
          val interference = constrainInsn (test, interference)
        in
          precolorDst8 (interference, dst)
        end
      | I.LOAD_FP dst => interference
      | I.LOAD_SP dst => interference
      | I.LOAD_PREV_FP dst => interference
      | I.LOAD_RETADDR dst => interference
      | I.LOADABSADDR {ty, dst, symbol, thunk=SOME _} =>
        precolorDst (interference, dst, X.EBX)
      | I.LOADABSADDR {ty, dst, symbol, thunk=NONE} => interference
      | I.X86 (I.X86LEAINT (ty, dst, addr)) => interference
      | I.X86 (I.X86FLD (ty, addr)) => interference
      | I.X86 (I.X86FLD_ST x86st1) => interference
      | I.X86 (I.X86FST (ty, addr)) => interference
      | I.X86 (I.X86FSTP (ty, addr)) => interference
      | I.X86 (I.X86FSTP_ST x86st1) => interference
      | I.X86 (I.X86FADD (ty, addr)) => interference
      | I.X86 (I.X86FADD_ST (x86st1, x86st2)) => interference
      | I.X86 (I.X86FADDP x86st1) => interference
      | I.X86 (I.X86FSUB (ty, addr)) => interference
      | I.X86 (I.X86FSUB_ST (x86st1, x86st2)) => interference
      | I.X86 (I.X86FSUBP x86st1) => interference
      | I.X86 (I.X86FSUBR (ty, addr)) => interference
      | I.X86 (I.X86FSUBR_ST (x86st1, x86st2)) => interference
      | I.X86 (I.X86FSUBRP x86st1) => interference
      | I.X86 (I.X86FMUL (ty, addr)) => interference
      | I.X86 (I.X86FMUL_ST (x86st1, x86st2)) => interference
      | I.X86 (I.X86FMULP x86st1) => interference
      | I.X86 (I.X86FDIV (ty, addr)) => interference
      | I.X86 (I.X86FDIV_ST (x86st1, x86st2)) => interference
      | I.X86 (I.X86FDIVP x86st1) => interference
      | I.X86 (I.X86FDIVR (ty, addr)) => interference
      | I.X86 (I.X86FDIVR_ST (x86st1, x86st2)) => interference
      | I.X86 (I.X86FDIVRP x86st1) => interference
      | I.X86 (I.X86FABS) => interference
      | I.X86 (I.X86FCHS) => interference
      | I.X86 (I.X86FFREE st) => interference
      | I.X86 (I.X86FXCH st) => interference
(*
      | I.X86 (I.X86FUCOMPP_FSTSW dst) => precolorDst (interference, dst, X.EAX)
*)
      | I.X86 (I.X86FUCOM st) => interference
      | I.X86 (I.X86FUCOMP st) => interference
      | I.X86 I.X86FUCOMPP => interference
      | I.X86 (I.X86FSW_GT {clob}) => precolorVar (interference, clob, X.EAX)
      | I.X86 (I.X86FSW_GE {clob}) => precolorVar (interference, clob, X.EAX)
      | I.X86 (I.X86FSW_EQ {clob}) => precolorVar (interference, clob, X.EAX)
      | I.X86 (I.X86FLDCW addr) => interference
      | I.X86 (I.X86FNSTCW addr) => interference
      | I.X86 I.X86FWAIT => interference
      | I.X86 I.X86FNCLEX => interference

  fun constrainFirst (first, interference) =
      case first of
        I.BEGIN {label, align, loc} => interference
      | I.CODEENTRY {label, symbol, scope, align, preFrameSize, preFrameAligned,
                     defs, loc} =>
        precolorVarList (interference, defs, calleeSaveRegs @ callerSaveRegs)
      | I.HANDLERENTRY {label, align, defs, loc} =>
        precolorVarList (interference, defs, callerSaveRegs)
      | I.ENTER => interference

  fun constrainLast (last, interference) =
      case last of
        I.HANDLE (insn, {nextLabel, handler}) =>
        constrainInsn (insn, interference)
      | I.CJUMP {test, cc, thenLabel, elseLabel} =>
        constrainInsn (test, interference)
      | I.CALL {callTo, returnTo, handler, defs, uses, needStabilize,
                postFrameAdjust} =>
        let
          val interference =
              precolorVarList (interference, defs, callerSaveRegs)
          val interference =
              precolorVarList (interference, uses, callerSaveRegs)
        in
          interference
        end
      | I.JUMP {jumpTo, destinations} => interference
      | I.UNWIND_JUMP {jumpTo, uses, fp, sp, handler} =>
        precolorVarList (interference, uses, calleeSaveRegs)
      | I.TAILCALL_JUMP {preFrameSize, jumpTo, uses} =>
        precolorVarList (interference, uses, calleeSaveRegs @ callerSaveRegs)
      | I.RETURN {preFrameSize, preFrameAligned, uses} =>
        precolorVarList (interference, uses, calleeSaveRegs @ callerSaveRegs)
      | I.EXIT => interference

  fun constrain graph interference =
      I.LabelMap.foldli
        (fn (label, (first, mid, last), interference) =>
            let
              val interference = constrainFirst (first, interference)
              val interference = foldl constrainInsn interference mid
              val interference = constrainLast (last, interference)
            in
              interference
            end)
        interference
        graph

end
