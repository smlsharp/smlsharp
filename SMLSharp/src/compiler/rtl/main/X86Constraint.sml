(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure X86Constraint : RTLCONSTRAINT =
struct

  structure R = RTL
  structure X = X86Asm
  structure Target = X86Asm

  val registers = Vector.fromList [X.EAX, X.EBX, X.ECX, X.EDX, X.EDI, X.ESI]
  val EAX = 1 : Interference.colorId
  val EBX = 2 : Interference.colorId
  val ECX = 3 : Interference.colorId
  val EDX = 4 : Interference.colorId
  val EDI = 5 : Interference.colorId
  val ESI = 6 : Interference.colorId

  val calleeSaveRegs = [EDI, ESI, EBX]
  val callerSaveRegs = [EAX, EDX, ECX]
  val regsOnly32 = [EDI, ESI]

  fun newVar ty =
      let
        val id = VarID.generate ()
      in
        {id = id, ty = ty} : R.var
      end

  fun splitVar (code:RTLEdit.focus) (var as {ty,...}:R.var) =
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
                   (z, [R.MOVE (ty, R.REG tmp, R.REF_ (R.REG orig))]))
             code
             pairs,
       vars)

  fun save (code, pairs, vars) =
      (foldl (fn ({orig as {ty,...}, tmp}, z) =>
                 RTLEdit.insertAfter
                   (z, [R.MOVE (ty, R.REG orig, R.REF_ (R.REG tmp))]))
             code
             pairs,
       vars)

  fun splitDst code (R.REG var) =
      let
        val (code, pairs, var) = splitVar code var
      in
        (code, pairs, R.REG var)
      end
    | splitDst code (R.COUPLE (ty, {hi, lo})) =
      let
        val (code, pairs1, hi) = splitDst code hi
        val (code, pairs2, lo) = splitDst code lo
      in
        (code, pairs1 @ pairs2, R.COUPLE (ty, {hi=hi, lo=lo}))
      end
    | splitDst code (dst as R.MEM _) = (code, nil, dst)

  fun splitOperand code (R.REF (cast, dst)) =
      let
        val (code, dst) = load (splitDst code dst)
      in
        (code, R.REF (cast, dst))
      end
    | splitOperand code (op1 as R.CONST _) = (code, op1)

  fun splitAddr code (ptrTy, R.BASE var) =
      let
        val (code, var) = load (splitVar code var)
      in
        (code, R.BASE var)
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
        R.NOP => (code, insn)
      | R.STABILIZE => (code, insn)
      | R.REQUEST_SLOT slot => (code, insn)
      | R.REQUIRE_SLOT slot => (code, insn)
      | R.USE vars => (code, insn)
      | R.COMPUTE_FRAME {uses, clobs} => (code, insn)
      | R.MOVE (ty1, dst, op1) => (code, insn)
      | R.MOVEADDR (ty, dst, addr) => (code, insn)
      | R.COPY {ty, dst, src, clobs} => (code, insn)
      | R.MLOAD {ty, dst:R.slot, srcAddr, size, defs, clobs} =>
        let
          val (code, srcAddr) = splitAddr code (R.Void, srcAddr)
          val (code, size) = splitOperand code size
          val (code, defs) = save (splitVarList code defs)
        in
          (code, R.MLOAD {ty=ty, dst=dst, srcAddr=srcAddr, size=size,
                          defs=defs, clobs=clobs})
        end
      | R.MSTORE {ty, dstAddr, src:R.slot, size, defs, clobs, global} =>
        let
          val (code, dstAddr) = splitAddr code (R.Void, dstAddr)
          val (code, size) = splitOperand code size
          val (code, defs) = save (splitVarList code defs)
        in
          (code, R.MSTORE {ty=ty, dstAddr=dstAddr, src=src, size=size,
                           defs=defs, clobs=clobs, global=global})
        end
(*
      | R.EXT8TO16 (sign, dst, op1) => (code, insn)
*)
      | R.EXT8TO32 (sign, dst, op1) => (code, insn)
      | R.EXT16TO32 (sign, dst, op1) => (code, insn)
(*
      | R.SIGNEXT8TO16 (sign, dst, op1) =>
        splitPrecolored2 code R.SIGNEXT8TO16 (sign, dst, op1)
      | R.SIGNEXT8TO32 (sign, dst, op1) =>
        splitPrecolored2 code R.SIGNEXT8TO32 (sign, dst, op1)
      | R.SIGNEXT16TO32 (sign, dst, op1) =>
        splitPrecolored2 code R.SIGNEXT16TO32 (sign, dst, op1)
*)
      | R.EXT32TO64 (sign, dst as R.COUPLE _, op1) =>
        splitPrecolored2 code R.EXT32TO64 (sign, dst, op1)
      | R.EXT32TO64 (sign, dst, op1) => (code, insn)
      | R.DOWN32TO8 (sign, dst, op1) => (code, insn)
      | R.DOWN32TO16 (sign, dst, op1) => (code, insn)
(*
      | R.DOWN16TO8 (sign, dst, op1) => (code, insn)
*)
      | R.ADD (ty, dst, op1, op2) =>
        splitCoalesce3 code R.ADD (ty, dst, op1, op2)
      | R.SUB (ty, dst, op1, op2) =>
        splitCoalesce3 code R.SUB (ty, dst, op1, op2)
      | R.MUL ((ty, dst as R.COUPLE _), (ty1, op1), op2) =>
        let
          val (code, dst) = save (splitDst code dst)
          val (code, op1) = splitOperand code op1
        in
          (code, R.MUL ((ty, dst), (ty1, op1), op2))
        end
      | R.MUL ((ty, dst), (ty2, op1), (ty3, op2)) =>
        splitCoalesce3 code
          (fn (_, dst, op1, op2) => R.MUL ((ty, dst), (ty2, op1), (ty3, op2)))
          (ty, dst, op1, op2)
      | R.DIVMOD ({div=(divTy, ddiv), mod=(modTy, dmod)}, (ty1, op1), op2) =>
        let
          val (code, ddiv) = save (splitDst code ddiv)
          val (code, dmod) = save (splitDst code dmod)
          val (code, op1) = splitOperand code op1
        in
          (code, R.DIVMOD ({div=(divTy,ddiv), mod=(modTy,dmod)},
                           (ty1, op1), op2))
        end
      | R.AND (ty, dst, op1, op2) =>
        splitCoalesce3 code R.AND (ty, dst, op1, op2)
      | R.OR (ty, dst, op1, op2) =>
        splitCoalesce3 code R.OR (ty, dst, op1, op2)
      | R.XOR (ty, dst, op1, op2) =>
        splitCoalesce3 code R.XOR (ty, dst, op1, op2)
      | R.LSHIFT (ty, dst, op1, op2) =>
        splitShift code R.LSHIFT (ty, dst, op1, op2)
      | R.RSHIFT (ty, dst, op1, op2) =>
        splitShift code R.RSHIFT (ty, dst, op1, op2)
      | R.ARSHIFT (ty, dst, op1, op2) =>
        splitShift code R.ARSHIFT (ty, dst, op1, op2)
      | R.TEST_SUB (ty, op1, op2) => (code, insn)
      | R.TEST_AND (ty, op1, op2) => (code, insn)
      | R.TEST_LABEL (ty, op1, op2) => (code, insn)
      | R.NOT (ty, dst, op1) => splitCoalesce2 code R.NOT (ty, dst, op1)
      | R.NEG (ty, dst, op1) => splitCoalesce2 code R.NEG (ty, dst, op1)
      | R.SET (cc, ty, dst, {test}) =>
        let
          val (code, test) = splitInsn code test
        in
          (code, R.SET (cc, ty, dst, {test=test}))
        end
      | R.LOAD_FP dst => (code, insn)
      | R.LOAD_SP dst => (code, insn)
      | R.LOAD_PREV_FP dst => (code, insn)
      | R.LOAD_RETADDR dst => (code, insn)
      (* dst must be a register but this is a special case;
       * we don't split its liverange here. *)
      | R.LOADABSADDR {ty, dst, symbol, thunk} => (code, insn)
      | R.X86 (R.X86LEAINT (ty, dst, addr)) => (code, insn)
      | R.X86 (R.X86FLD (ty, op1)) => (code, insn)
      | R.X86 (R.X86FLD_ST x86st1) => (code, insn)
      | R.X86 (R.X86FST (ty, addr)) => (code, insn)
      | R.X86 (R.X86FSTP (ty, dst)) => (code, insn)
      | R.X86 (R.X86FSTP_ST x86st1) => (code, insn)
      | R.X86 (R.X86FADD (ty, op1)) => (code, insn)
      | R.X86 (R.X86FADD_ST (x86st1, x86st2)) => (code, insn)
      | R.X86 (R.X86FADDP x86st1) => (code, insn)
      | R.X86 (R.X86FSUB (ty, op1)) => (code, insn)
      | R.X86 (R.X86FSUB_ST (x86st1, x86st2)) => (code, insn)
      | R.X86 (R.X86FSUBP x86st1) => (code, insn)
      | R.X86 (R.X86FSUBR (ty, op1)) => (code, insn)
      | R.X86 (R.X86FSUBR_ST (x86st1, x86st2)) => (code, insn)
      | R.X86 (R.X86FSUBRP x86st1) => (code, insn)
      | R.X86 (R.X86FMUL (ty, op1)) => (code, insn)
      | R.X86 (R.X86FMUL_ST (x86st1, x86st2)) => (code, insn)
      | R.X86 (R.X86FMULP x86st1) => (code, insn)
      | R.X86 (R.X86FDIV (ty, op1)) => (code, insn)
      | R.X86 (R.X86FDIV_ST (x86st1, x86st2)) => (code, insn)
      | R.X86 (R.X86FDIVP x86st1) => (code, insn)
      | R.X86 (R.X86FDIVR (ty, op1)) => (code, insn)
      | R.X86 (R.X86FDIVR_ST (x86st1, x86st2)) => (code, insn)
      | R.X86 (R.X86FDIVRP x86st1) => (code, insn)
      | R.X86 (R.X86FABS) => (code, insn)
      | R.X86 (R.X86FCHS) => (code, insn)
      | R.X86 (R.X86FFREE st) => (code, insn)
      | R.X86 (R.X86FXCH st) => (code, insn)
      | R.X86 (R.X86FUCOM st) => (code, insn)
      | R.X86 (R.X86FUCOMP st) => (code, insn)
      | R.X86 R.X86FUCOMPP => (code, insn)
      | R.X86 (R.X86FSW_GT {clob}) => (code, insn)
      | R.X86 (R.X86FSW_GE {clob}) => (code, insn)
      | R.X86 (R.X86FSW_EQ {clob}) => (code, insn)
      | R.X86 (R.X86FLDCW op1) => (code, insn)
      | R.X86 (R.X86FNSTCW dst) => (code, insn)
      | R.X86 R.X86FWAIT => (code, insn)
      | R.X86 R.X86FNCLEX => (code, insn)

  fun splitFirst first =
      case first of
        R.ENTER => RTLEdit.singletonFirst first
      | R.BEGIN _ => RTLEdit.singletonFirst first
      | R.CODEENTRY {label, symbol, scope, align, preFrameSize, stubOptions,
                     defs, loc} =>
        let
          val code = RTLEdit.singletonFirst R.ENTER
          val (code, defs) = save (splitVarList code defs)
        in
          RTLEdit.insertFirst
            (code, R.CODEENTRY {label=label, symbol=symbol, scope=scope,
                                align=align, preFrameSize=preFrameSize,
                                stubOptions=stubOptions,
                                defs=defs, loc=loc})
        end
      | R.HANDLERENTRY {label, align, defs, loc} =>
        let
          val code = RTLEdit.singletonFirst R.ENTER
          val (code, defs) = save (splitVarList code defs)
        in
          RTLEdit.insertFirst
            (code, R.HANDLERENTRY {label=label, align=align,
                                   defs=defs, loc=loc})
        end

  fun splitLast last =
      case last of
        R.HANDLE (insn, {nextLabel, handler}) =>
        let
          val code = RTLEdit.singletonLast (RTLEdit.jump nextLabel)
          val (code, insn) = splitInsn code insn
          val (code, _) =
              RTLEdit.insertLastAfter
                (code, fn l => R.HANDLE (insn, {nextLabel=l, handler=handler}))
        in
          code
        end
      | R.CJUMP {test, cc, thenLabel, elseLabel} =>
        let
          val code = RTLEdit.singletonFirst R.ENTER
          val (code, test) = splitInsn code test
        in
          if RTLEdit.atLast code
          then RTLEdit.insertLast
                 (code, R.CJUMP {test=test, cc=cc, thenLabel=thenLabel,
                                 elseLabel=elseLabel})
          else raise Control.Bug "splitLast: CJUMP"
        end
      | R.CALL {callTo, returnTo, handler, defs, uses, needStabilize,
                postFrameAdjust} =>
        let
          val code = RTLEdit.singletonLast (RTLEdit.jump returnTo)
          val (code, defs) = save (splitVarList code defs)
          val (code, uses) = load (splitVarList code uses)
          val (code, _) =
              RTLEdit.insertLastAfter
                (code, fn l => R.CALL {callTo=callTo, returnTo=l,
                                       handler=handler,
                                       defs=defs, uses=uses,
                                       needStabilize=needStabilize,
                                       postFrameAdjust=postFrameAdjust})
        in
          code
        end
      | R.JUMP {jumpTo, destinations} => RTLEdit.singletonLast last
      | R.UNWIND_JUMP {jumpTo, fp, sp, uses, handler} =>
        let
          val code = RTLEdit.singletonFirst R.ENTER
          val (code, uses) = load (splitVarList code uses)
        in
          RTLEdit.insertLast
            (code, R.UNWIND_JUMP {jumpTo=jumpTo, fp=fp, sp=sp,
                                  uses=uses, handler=handler})
        end
      | R.TAILCALL_JUMP {preFrameSize, jumpTo, uses} =>
        let
          val code = RTLEdit.singletonFirst R.ENTER
          val (code, uses) = load (splitVarList code uses)
        in
          RTLEdit.insertLast
            (code, R.TAILCALL_JUMP {preFrameSize=preFrameSize,
                                    jumpTo=jumpTo,
                                    uses=uses})
        end
      | R.RETURN {preFrameSize, stubOptions, uses} =>
        let
          val code = RTLEdit.singletonFirst R.ENTER
          val (code, uses) = load (splitVarList code uses)
        in
          RTLEdit.insertLast
            (code, R.RETURN {preFrameSize=preFrameSize,
                             stubOptions=stubOptions,
                             uses=uses})
        end
      | R.EXIT => RTLEdit.singletonLast R.EXIT

  fun split graph =
      RTLEdit.extend
        (fn RTLEdit.FIRST first => RTLEdit.unfocus (splitFirst first)
          | RTLEdit.MIDDLE insn =>
            let
              val (code, insn) = splitInsn (RTLEdit.singletonFirst R.ENTER) insn
            in
              RTLEdit.unfocus (RTLEdit.insertBefore (code, [insn]))
            end
          | RTLEdit.LAST last => RTLEdit.unfocus (splitLast last))
        graph

  fun precolorVar (interference, {id,...}:R.var, reg) =
      let
        fun colors 0 l = l
          | colors n l = colors (n-1) (if n = reg then l else n::l)
        val maxRegisterId = Vector.length registers
        val interference =
            Interference.interfereWithColors
              (interference, id, colors maxRegisterId nil)
      in
        Interference.disallowSpill (interference, id)
      end

  fun precolorVarList (interference, vars, regs) =
      ListPair.foldl
          (fn (var, color, interference) =>
              precolorVar (interference, var, color))
          interference
          (vars, regs)

  fun precolorVarList8 (interference, vars) =
      foldl
        (fn ({id,...}:R.var, interference) =>
            Interference.interfereWithColors (interference, id, regsOnly32))
        interference
        vars

  fun precolorDst (interference, R.REG var, reg) =
      precolorVar (interference, var, reg)
    | precolorDst (interference, R.MEM _, reg) = interference
    | precolorDst (interference, R.COUPLE _, reg) =
      raise Control.Bug "precolorDst: COUPLE"

  fun precolorOperand (interference, R.REF (_, dst), reg) =
      precolorDst (interference, dst, reg)
    | precolorOperand (interference, R.CONST _, reg) = interference

  fun precolorAddr (interference, R.BASE var, reg) =
      precolorVar (interference, var, reg)
    | precolorAddr (interference, R.ADDRCAST (_, addr), reg) =
      precolorAddr (interference, addr, reg)
    | precolorAddr (interference, R.DISP (_, addr), reg) = 
      precolorAddr (interference, addr, reg)
    | precolorAddr (interference, R.ABSADDR _, reg) = interference
    | precolorAddr (interference, R.ABSINDEX _, reg) = interference
    | precolorAddr (interference, R.BASEINDEX _, reg) = interference
    | precolorAddr (interference, R.POSTFRAME _, reg) = interference
    | precolorAddr (interference, R.PREFRAME _, reg) = interference
    | precolorAddr (interference, R.WORKFRAME _, reg) = interference
    | precolorAddr (interference, R.FRAMEINFO _, reg) = interference

  fun precolorDst8 (interference, R.REG {id,...}) =
      Interference.interfereWithColors (interference, id, regsOnly32)
    | precolorDst8 (interference, R.MEM _) = interference
    | precolorDst8 (interference, R.COUPLE _) =
      raise Control.Bug "precolorDst8: COUPLE"

  fun precolorOperand8 (interference, R.REF (_, dst)) =
      precolorDst8 (interference, dst)
    | precolorOperand8 (interference, R.CONST _) = interference

  fun precolorDstByTy (interference, ty, dst) =
      if (case ty of R.Int8 _ => true | R.Int16 _ => true | _ => false)
      then precolorDst8 (interference, dst)
      else interference

  fun precolorOperandByTy (interference, ty, op1) =
      if (case ty of R.Int8 _ => true | R.Int16 _ => true | _ => false)
      then precolorOperand8 (interference, op1)
      else interference

  fun precolorDst64 (interference, R.COUPLE (_, {hi=hi,lo=lo})) =
      precolorDst (precolorDst (interference, hi, EDX), lo, EAX)
    | precolorDst64 (interference, R.REG _) = interference
    | precolorDst64 (interference, R.MEM _) = interference

  fun precolorOperand64 (interference, R.REF (_, dst)) =
      precolorDst64 (interference, dst)
    | precolorOperand64 (interference, R.CONST _) = interference

  fun coalesceDst (interference, R.REG {id=id1,...}, R.REG {id=id2,...}) =
      Interference.coalesce (interference, id1, id2)
    | coalesceDst (interference, R.COUPLE (_,c1), R.COUPLE (_,c2)) =
      let
        val interference = coalesceDst (interference, #hi c1, #hi c2)
        val interference = coalesceDst (interference, #lo c1, #lo c2)
      in
        interference
      end
    | coalesceDst (interference, _, _) = interference

  fun coalesce (interference, dst, R.REF (_, op1)) =
      coalesceDst (interference, dst, op1)
    | coalesce (interference, dst, R.CONST _) = interference

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
        val interference = precolorOperand (interference, op2, ECX)
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

  fun copyRegs (interference, vars as [_,_,_]) =
      precolorVarList (interference, vars, [EDI, ESI, ECX])
    | copyRegs _ = raise Control.Bug "copyRegs"

  fun addMove (interference, R.REG v1, R.REF (_, R.REG v2)) =
      Interference.addMove (interference, #id v1, #id v2)
    | addMove (interference, _, R.REF _) = interference
    | addMove (interference, _, R.CONST _) = interference

  fun constrainInsn (insn, interference) =
      case insn of
        R.NOP => interference
      | R.STABILIZE => interference
      | R.REQUEST_SLOT slot => interference
      | R.REQUIRE_SLOT slot => interference
      | R.USE vars => interference
      | R.COMPUTE_FRAME {uses, clobs} => interference
      | R.MOVE (ty, dst, op1) =>
        let
          val interference = addMove (interference, dst, op1)
          val interference = precolorDstByTy (interference, ty, dst)
          val interference = precolorOperandByTy (interference, ty, op1)
        in
          interference
        end
      | R.MOVEADDR (ty, dst, R.BASE reg) =>
        addMove (interference, dst, R.REF_ (R.REG reg))
      | R.MOVEADDR (ty, dst, addr) => interference
      | R.COPY {ty, dst, src, clobs} =>
        if #size (X86Emit.formatOf ty) mod 4 = 0
        then interference
        else precolorVarList8 (interference, clobs)
      | R.MLOAD {ty, dst:R.slot, srcAddr, size, defs, clobs} =>
        let
          val interference = precolorAddr (interference, srcAddr, ESI)
          val interference = precolorOperand (interference, size, ECX)
          val interference = copyRegs (interference, defs @ clobs)
        in
          interference
        end
      | R.MSTORE {ty, dstAddr, src:R.slot, size, defs, clobs, global} =>
        let
          val interference = precolorAddr (interference, dstAddr, EDI)
          val interference = precolorOperand (interference, size, ECX)
          val interference = copyRegs (interference, defs @ clobs)
        in
          interference
        end
      | R.EXT8TO32 (sign, dst, op1) => precolorOperand8 (interference, op1)
      | R.EXT16TO32 (sign, dst, op1) => precolorOperand8 (interference, op1)
      | R.EXT32TO64 (sign, dst as R.COUPLE _, op1) =>
        let
          val interference = precolorDst64 (interference, dst)
          val interference = precolorOperand (interference, op1, EAX)
        in
          interference
        end
      | R.EXT32TO64 (sign, dst, op1) => interference
      | R.DOWN32TO8 (sign, dst, op1) =>
        let
          val interference = precolorDst8 (interference, dst)
          val interference = precolorOperand8 (interference, op1)
          val interference = addMove (interference, dst, op1)
        in
          interference
        end
      | R.DOWN32TO16 (sign, dst, op1) =>
        let
          val interference = precolorDst8 (interference, dst)
          val interference = precolorOperand8 (interference, op1)
          val interference = addMove (interference, dst, op1)
        in
          interference
        end
(*
      | R.DOWN16TO8 (sign, dst, op1) =>
        let
          val interference = precolorDst8 (interference, dst)
          val interference = precolorOperand8 (interference, op1)
        in
          interference
        end
*)
      | R.ADD (ty, dst, op1, op2) =>
        precolorArith3 (interference, ty, dst, op1, op2)
      | R.SUB (ty, dst, op1, op2) =>
        precolorArith3 (interference, ty, dst, op1, op2)
      | R.MUL ((_, dst as R.COUPLE _), (_, op1 as R.REF (_, R.COUPLE _)),
               _) =>
        let
          val interference = precolorDst64 (interference, dst)
          val interference = precolorOperand64 (interference, op1)
        in
          interference
        end
      | R.MUL ((ty, dst), (ty2, op1), (ty3, op2)) =>
        (
          case (dst, op1, op2) of
            (R.REG _, R.REF (_, R.REG _), R.REF (_, R.REG _)) =>
            coalesce (interference, dst, op1)
          | (_, _, R.REF (_, R.MEM _)) =>
            coalesce (interference, dst, op1)
          | (_, R.REF (_, R.MEM _), _) =>
            coalesce (interference, dst, op2)
          | _ => interference
        )
      | R.DIVMOD ({div=(ty, ddiv), mod=(ty2, dmod)}, (ty3, op1), (ty4, op2)) =>
        let
          val interference = precolorDst (interference, ddiv, EAX)
          val interference = precolorDst (interference, dmod, EDX)
          val interference = precolorOperand64 (interference, op1)
        in
          interference
        end
      | R.AND (ty, dst, op1, op2) =>
        precolorArith3 (interference, ty, dst, op1, op2)
      | R.OR (ty, dst, op1, op2) =>
        precolorArith3 (interference, ty, dst, op1, op2)
      | R.XOR (ty, dst, op1, op2) =>
        precolorArith3 (interference, ty, dst, op1, op2)
      | R.LSHIFT (ty, dst, op1, op2) =>
        precolorShift (interference, ty, dst, op1, op2)
      | R.RSHIFT (ty, dst, op1, op2) =>
        precolorShift (interference, ty, dst, op1, op2)
      | R.ARSHIFT (ty, dst, op1, op2) =>
        precolorShift (interference, ty, dst, op1, op2)
      | R.TEST_SUB (ty, op1, op2) =>
        precolorTest (interference, ty, op1, op2)
      | R.TEST_AND (ty, op1, op2) =>
        precolorTest (interference, ty, op1, op2)
      | R.TEST_LABEL (ty, op1, label) => interference
      | R.NOT (ty, dst, op1) =>
        precolorArith2 (interference, ty, dst, op1)
      | R.NEG (ty, dst, op1) =>
        precolorArith2 (interference, ty, dst, op1)
      | R.SET (cc, ty, dst, {test}) =>
        let
          val interference = constrainInsn (test, interference)
        in
          precolorDst8 (interference, dst)
        end
      | R.LOAD_FP dst => interference
      | R.LOAD_SP dst => interference
      | R.LOAD_PREV_FP dst => interference
      | R.LOAD_RETADDR dst => interference
      | R.LOADABSADDR {ty, dst, symbol, thunk=SOME _} =>
        precolorDst (interference, dst, EBX)
      | R.LOADABSADDR {ty, dst, symbol, thunk=NONE} => interference
      | R.X86 (R.X86LEAINT (ty, dst, addr)) => interference
      | R.X86 (R.X86FLD (ty, addr)) => interference
      | R.X86 (R.X86FLD_ST x86st1) => interference
      | R.X86 (R.X86FST (ty, addr)) => interference
      | R.X86 (R.X86FSTP (ty, addr)) => interference
      | R.X86 (R.X86FSTP_ST x86st1) => interference
      | R.X86 (R.X86FADD (ty, addr)) => interference
      | R.X86 (R.X86FADD_ST (x86st1, x86st2)) => interference
      | R.X86 (R.X86FADDP x86st1) => interference
      | R.X86 (R.X86FSUB (ty, addr)) => interference
      | R.X86 (R.X86FSUB_ST (x86st1, x86st2)) => interference
      | R.X86 (R.X86FSUBP x86st1) => interference
      | R.X86 (R.X86FSUBR (ty, addr)) => interference
      | R.X86 (R.X86FSUBR_ST (x86st1, x86st2)) => interference
      | R.X86 (R.X86FSUBRP x86st1) => interference
      | R.X86 (R.X86FMUL (ty, addr)) => interference
      | R.X86 (R.X86FMUL_ST (x86st1, x86st2)) => interference
      | R.X86 (R.X86FMULP x86st1) => interference
      | R.X86 (R.X86FDIV (ty, addr)) => interference
      | R.X86 (R.X86FDIV_ST (x86st1, x86st2)) => interference
      | R.X86 (R.X86FDIVP x86st1) => interference
      | R.X86 (R.X86FDIVR (ty, addr)) => interference
      | R.X86 (R.X86FDIVR_ST (x86st1, x86st2)) => interference
      | R.X86 (R.X86FDIVRP x86st1) => interference
      | R.X86 (R.X86FABS) => interference
      | R.X86 (R.X86FCHS) => interference
      | R.X86 (R.X86FFREE st) => interference
      | R.X86 (R.X86FXCH st) => interference
      | R.X86 (R.X86FUCOM st) => interference
      | R.X86 (R.X86FUCOMP st) => interference
      | R.X86 R.X86FUCOMPP => interference
      | R.X86 (R.X86FSW_GT {clob}) => precolorVar (interference, clob, EAX)
      | R.X86 (R.X86FSW_GE {clob}) => precolorVar (interference, clob, EAX)
      | R.X86 (R.X86FSW_EQ {clob}) => precolorVar (interference, clob, EAX)
      | R.X86 (R.X86FLDCW addr) => interference
      | R.X86 (R.X86FNSTCW addr) => interference
      | R.X86 R.X86FWAIT => interference
      | R.X86 R.X86FNCLEX => interference

  fun constrainFirst (first, interference) =
      case first of
        R.BEGIN {label, align, loc} => interference
      | R.CODEENTRY {label, symbol, scope, align, preFrameSize, stubOptions,
                     defs, loc} =>
        precolorVarList (interference, defs, calleeSaveRegs @ callerSaveRegs)
      | R.HANDLERENTRY {label, align, defs, loc} =>
        precolorVarList (interference, defs, callerSaveRegs)
      | R.ENTER => interference

  fun constrainLast (last, interference) =
      case last of
        R.HANDLE (insn, {nextLabel, handler}) =>
        constrainInsn (insn, interference)
      | R.CJUMP {test, cc, thenLabel, elseLabel} =>
        constrainInsn (test, interference)
      | R.CALL {callTo, returnTo, handler, defs, uses, needStabilize,
                postFrameAdjust} =>
        let
          val interference =
              precolorVarList (interference, defs, callerSaveRegs)
          val interference =
              precolorVarList (interference, uses, callerSaveRegs)
        in
          interference
        end
      | R.JUMP {jumpTo, destinations} => interference
      | R.UNWIND_JUMP {jumpTo, uses, fp, sp, handler} =>
        precolorVarList (interference, uses, callerSaveRegs)
      | R.TAILCALL_JUMP {preFrameSize, jumpTo, uses} =>
        precolorVarList (interference, uses, calleeSaveRegs @ callerSaveRegs)
      | R.RETURN {preFrameSize, stubOptions, uses} =>
        precolorVarList (interference, uses, calleeSaveRegs @ callerSaveRegs)
      | R.EXIT => interference

  fun constrain graph interference =
      R.LabelMap.foldli
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
