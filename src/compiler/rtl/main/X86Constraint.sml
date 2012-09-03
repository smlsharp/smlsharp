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
  val EAX = 0 : Coloring.regId
  val EBX = 1 : Coloring.regId
  val ECX = 2 : Coloring.regId
  val EDX = 3 : Coloring.regId
  val EDI = 4 : Coloring.regId
  val ESI = 5 : Coloring.regId

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
      | R.X86 R.X86FPREM => (code, insn)
      | R.X86 (R.X86FABS) => (code, insn)
      | R.X86 (R.X86FCHS) => (code, insn)
      | R.X86 (R.X86FINCSTP) => (code, insn)
      | R.X86 (R.X86FFREE st) => (code, insn)
      | R.X86 (R.X86FXCH st) => (code, insn)
      | R.X86 (R.X86FUCOM st) => (code, insn)
      | R.X86 (R.X86FUCOMP st) => (code, insn)
      | R.X86 R.X86FUCOMPP => (code, insn)
      | R.X86 (R.X86FSW_TESTH {clob,mask}) => (code, insn)
      | R.X86 (R.X86FSW_MASKCMPH {clob,mask,compare}) => (code, insn)
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

  fun precolorVar (coloring, var, regId) =
      Coloring.allocReg (coloring, var, regId)

  fun precolorVarList (coloring, vars, regs) =
      ListPair.app
        (fn (var, color) => precolorVar (coloring, var, color))
        (vars, regs)

  fun precolorVarList8 (coloring, vars) =
      app (fn var => Coloring.interfereWithRegs (coloring, var, regsOnly32))
          vars

  fun precolorDst (coloring, R.REG var, reg) =
      precolorVar (coloring, var, reg)
    | precolorDst (coloring, R.MEM _, reg) = ()
    | precolorDst (coloring, R.COUPLE _, reg) =
      raise Control.Bug "precolorDst: COUPLE"

  fun precolorOperand (coloring, R.REF (_, dst), reg) =
      precolorDst (coloring, dst, reg)
    | precolorOperand (coloring, R.CONST _, reg) = ()

  fun precolorAddr (coloring, R.BASE var, reg) =
      precolorVar (coloring, var, reg)
    | precolorAddr (coloring, R.ADDRCAST (_, addr), reg) =
      precolorAddr (coloring, addr, reg)
    | precolorAddr (coloring, R.DISP (_, addr), reg) =
      precolorAddr (coloring, addr, reg)
    | precolorAddr (coloring, R.ABSADDR _, reg) = ()
    | precolorAddr (coloring, R.ABSINDEX _, reg) = ()
    | precolorAddr (coloring, R.BASEINDEX _, reg) = ()
    | precolorAddr (coloring, R.POSTFRAME _, reg) = ()
    | precolorAddr (coloring, R.PREFRAME _, reg) = ()
    | precolorAddr (coloring, R.WORKFRAME _, reg) = ()
    | precolorAddr (coloring, R.FRAMEINFO _, reg) = ()

  fun precolorDst8 (coloring, R.REG var) =
      Coloring.interfereWithRegs (coloring, var, regsOnly32)
    | precolorDst8 (coloring, R.MEM _) = ()
    | precolorDst8 (coloring, R.COUPLE _) =
      raise Control.Bug "precolorDst8: COUPLE"

  fun precolorOperand8 (coloring, R.REF (_, dst)) =
      precolorDst8 (coloring, dst)
    | precolorOperand8 (coloring, R.CONST _) = ()

  fun precolorDstByTy (coloring, ty, dst) =
      if (case ty of R.Int8 _ => true | R.Int16 _ => true | _ => false)
      then precolorDst8 (coloring, dst)
      else ()

  fun precolorOperandByTy (coloring, ty, op1) =
      if (case ty of R.Int8 _ => true | R.Int16 _ => true | _ => false)
      then precolorOperand8 (coloring, op1)
      else ()

  fun precolorDst64 (coloring, R.COUPLE (_, {hi=hi,lo=lo})) =
      (precolorDst (coloring, hi, EDX);
       precolorDst (coloring, lo, EAX))
    | precolorDst64 (coloring, R.REG _) = ()
    | precolorDst64 (coloring, R.MEM _) = ()

  fun precolorOperand64 (coloring, R.REF (_, dst)) =
      precolorDst64 (coloring, dst)
    | precolorOperand64 (coloring, R.CONST _) = ()

  fun coalesceDst (coloring, R.REG var1, R.REG var2) =
      Coloring.sameReg (coloring, var1, var2)
    | coalesceDst (coloring, R.COUPLE (_,c1), R.COUPLE (_,c2)) =
      (coalesceDst (coloring, #hi c1, #hi c2);
       coalesceDst (coloring, #lo c1, #lo c2))
    | coalesceDst (coloring, _, _) = ()

  fun coalesce (coloring, dst, R.REF (_, op1)) =
      coalesceDst (coloring, dst, op1)
    | coalesce (coloring, dst, R.CONST _) = ()

  fun precolorArith2 (coloring, ty, dst, op1) =
      (precolorDstByTy (coloring, ty, dst);
       coalesce (coloring, dst, op1))

  fun precolorArith3 (coloring, ty, dst, op1, op2) =
      (precolorDstByTy (coloring, ty, dst);
       coalesce (coloring, dst, op1);
       precolorOperandByTy (coloring, ty, op2))

  fun precolorShift (coloring, ty, dst, op1, op2) =
      (coalesce (coloring, dst, op1);
       precolorDstByTy (coloring, ty, dst);
       precolorOperand (coloring, op2, ECX))

  fun precolorTest (coloring, ty, op1, op2) =
      (precolorOperandByTy (coloring, ty, op1);
       precolorOperandByTy (coloring, ty, op2))

  fun copyRegs (coloring, vars as [_,_,_]) =
      precolorVarList (coloring, vars, [EDI, ESI, ECX])
    | copyRegs _ = raise Control.Bug "copyRegs"

  fun addMove (coloring, R.REG var1, R.REF (_, R.REG var2)) =
      Coloring.coalescable (coloring, var1, var2)
    | addMove (coloring, _, R.REF _) = ()
    | addMove (coloring, _, R.CONST _) = ()

  fun constrainInsn coloring insn =
      case insn of
        R.NOP => ()
      | R.STABILIZE => ()
      | R.REQUEST_SLOT slot => ()
      | R.REQUIRE_SLOT slot => ()
      | R.USE vars => ()
      | R.COMPUTE_FRAME {uses, clobs} => ()
      | R.MOVE (ty, dst, op1) =>
        (addMove (coloring, dst, op1);
         precolorDstByTy (coloring, ty, dst);
         precolorOperandByTy (coloring, ty, op1))
      | R.MOVEADDR (ty, dst, R.BASE reg) =>
        addMove (coloring, dst, R.REF_ (R.REG reg))
      | R.MOVEADDR (ty, dst, addr) => ()
      | R.COPY {ty, dst, src, clobs} =>
        if #size (X86Emit.formatOf ty) mod 4 = 0
        then ()
        else precolorVarList8 (coloring, clobs)
      | R.MLOAD {ty, dst:R.slot, srcAddr, size, defs, clobs} =>
        (precolorAddr (coloring, srcAddr, ESI);
         precolorOperand (coloring, size, ECX);
         copyRegs (coloring, defs @ clobs))
      | R.MSTORE {ty, dstAddr, src:R.slot, size, defs, clobs, global} =>
        (precolorAddr (coloring, dstAddr, EDI);
         precolorOperand (coloring, size, ECX);
         copyRegs (coloring, defs @ clobs))
      | R.EXT8TO32 (sign, dst, op1) => precolorOperand8 (coloring, op1)
      | R.EXT16TO32 (sign, dst, op1) => precolorOperand8 (coloring, op1)
      | R.EXT32TO64 (sign, dst as R.COUPLE _, op1) =>
        (precolorDst64 (coloring, dst);
         precolorOperand (coloring, op1, EAX))
      | R.EXT32TO64 (sign, dst, op1) => ()
      | R.DOWN32TO8 (sign, dst, op1) =>
        (precolorDst8 (coloring, dst);
         precolorOperand8 (coloring, op1);
         addMove (coloring, dst, op1))
      | R.DOWN32TO16 (sign, dst, op1) =>
        (precolorDst8 (coloring, dst);
         precolorOperand8 (coloring, op1);
         addMove (coloring, dst, op1))
(*
      | R.DOWN16TO8 (sign, dst, op1) =>
        (precolorDst8 (coloring, dst);
         precolorOperand8 (coloring, op1))
*)
      | R.ADD (ty, dst, op1, op2) =>
        precolorArith3 (coloring, ty, dst, op1, op2)
      | R.SUB (ty, dst, op1, op2) =>
        precolorArith3 (coloring, ty, dst, op1, op2)
      | R.MUL ((_, dst as R.COUPLE _), (_, op1 as R.REF (_, R.COUPLE _)), _) =>
        (precolorDst64 (coloring, dst);
         precolorOperand64 (coloring, op1))
      | R.MUL ((ty, dst), (ty2, op1), (ty3, op2)) =>
        (
          case (dst, op1, op2) of
            (R.REG _, R.REF (_, R.REG _), R.REF (_, R.REG _)) =>
            coalesce (coloring, dst, op1)
          | (_, _, R.REF (_, R.MEM _)) =>
            coalesce (coloring, dst, op1)
          | (_, R.REF (_, R.MEM _), _) =>
            coalesce (coloring, dst, op2)
          | _ => ()
        )
      | R.DIVMOD ({div=(ty, ddiv), mod=(ty2, dmod)}, (ty3, op1), (ty4, op2)) =>
        (precolorDst (coloring, ddiv, EAX);
         precolorDst (coloring, dmod, EDX);
         precolorOperand64 (coloring, op1))
      | R.AND (ty, dst, op1, op2) =>
        precolorArith3 (coloring, ty, dst, op1, op2)
      | R.OR (ty, dst, op1, op2) =>
        precolorArith3 (coloring, ty, dst, op1, op2)
      | R.XOR (ty, dst, op1, op2) =>
        precolorArith3 (coloring, ty, dst, op1, op2)
      | R.LSHIFT (ty, dst, op1, op2) =>
        precolorShift (coloring, ty, dst, op1, op2)
      | R.RSHIFT (ty, dst, op1, op2) =>
        precolorShift (coloring, ty, dst, op1, op2)
      | R.ARSHIFT (ty, dst, op1, op2) =>
        precolorShift (coloring, ty, dst, op1, op2)
      | R.TEST_SUB (ty, op1, op2) =>
        precolorTest (coloring, ty, op1, op2)
      | R.TEST_AND (ty, op1, op2) =>
        precolorTest (coloring, ty, op1, op2)
      | R.TEST_LABEL (ty, op1, label) => ()
      | R.NOT (ty, dst, op1) =>
        precolorArith2 (coloring, ty, dst, op1)
      | R.NEG (ty, dst, op1) =>
        precolorArith2 (coloring, ty, dst, op1)
      | R.SET (cc, ty, dst, {test}) =>
        (constrainInsn coloring test;
         precolorDst8 (coloring, dst))
      | R.LOAD_FP dst => ()
      | R.LOAD_SP dst => ()
      | R.LOAD_PREV_FP dst => ()
      | R.LOAD_RETADDR dst => ()
      | R.LOADABSADDR {ty, dst, symbol, thunk=SOME _} =>
        precolorDst (coloring, dst, EBX)
      | R.LOADABSADDR {ty, dst, symbol, thunk=NONE} => ()
      | R.X86 (R.X86LEAINT (ty, dst, addr)) => ()
      | R.X86 (R.X86FLD (ty, addr)) => ()
      | R.X86 (R.X86FLD_ST x86st1) => ()
      | R.X86 (R.X86FST (ty, addr)) => ()
      | R.X86 (R.X86FSTP (ty, addr)) => ()
      | R.X86 (R.X86FSTP_ST x86st1) => ()
      | R.X86 (R.X86FADD (ty, addr)) => ()
      | R.X86 (R.X86FADD_ST (x86st1, x86st2)) => ()
      | R.X86 (R.X86FADDP x86st1) => ()
      | R.X86 (R.X86FSUB (ty, addr)) => ()
      | R.X86 (R.X86FSUB_ST (x86st1, x86st2)) => ()
      | R.X86 (R.X86FSUBP x86st1) => ()
      | R.X86 (R.X86FSUBR (ty, addr)) => ()
      | R.X86 (R.X86FSUBR_ST (x86st1, x86st2)) => ()
      | R.X86 (R.X86FSUBRP x86st1) => ()
      | R.X86 (R.X86FMUL (ty, addr)) => ()
      | R.X86 (R.X86FMUL_ST (x86st1, x86st2)) => ()
      | R.X86 (R.X86FMULP x86st1) => ()
      | R.X86 (R.X86FDIV (ty, addr)) => ()
      | R.X86 (R.X86FDIV_ST (x86st1, x86st2)) => ()
      | R.X86 (R.X86FDIVP x86st1) => ()
      | R.X86 (R.X86FDIVR (ty, addr)) => ()
      | R.X86 (R.X86FDIVR_ST (x86st1, x86st2)) => ()
      | R.X86 (R.X86FDIVRP x86st1) => ()
      | R.X86 R.X86FPREM => ()
      | R.X86 (R.X86FABS) => ()
      | R.X86 (R.X86FCHS) => ()
      | R.X86 (R.X86FINCSTP) => ()
      | R.X86 (R.X86FFREE st) => ()
      | R.X86 (R.X86FXCH st) => ()
      | R.X86 (R.X86FUCOM st) => ()
      | R.X86 (R.X86FUCOMP st) => ()
      | R.X86 R.X86FUCOMPP => ()
      | R.X86 (R.X86FSW_TESTH {clob,mask}) =>
        precolorVar (coloring, clob, EAX)
      | R.X86 (R.X86FSW_MASKCMPH {clob,mask,compare}) =>
        precolorVar (coloring, clob, EAX)
      | R.X86 (R.X86FLDCW addr) => ()
      | R.X86 (R.X86FNSTCW addr) => ()
      | R.X86 R.X86FWAIT => ()
      | R.X86 R.X86FNCLEX => ()

  fun constrainFirst coloring first =
      case first of
        R.BEGIN {label, align, loc} => ()
      | R.CODEENTRY {label, symbol, scope, align, preFrameSize, stubOptions,
                     defs, loc} =>
        precolorVarList (coloring, defs, calleeSaveRegs @ callerSaveRegs)
      | R.HANDLERENTRY {label, align, defs, loc} =>
        precolorVarList (coloring, defs, callerSaveRegs)
      | R.ENTER => ()

  fun constrainLast coloring last =
      case last of
        R.HANDLE (insn, {nextLabel, handler}) =>
        constrainInsn coloring insn
      | R.CJUMP {test, cc, thenLabel, elseLabel} =>
        constrainInsn coloring test
      | R.CALL {callTo, returnTo, handler, defs, uses, needStabilize,
                postFrameAdjust} =>
        (precolorVarList (coloring, defs, callerSaveRegs);
         precolorVarList (coloring, uses, callerSaveRegs))
      | R.JUMP {jumpTo, destinations} => ()
      | R.UNWIND_JUMP {jumpTo, uses, fp, sp, handler} =>
        precolorVarList (coloring, uses, callerSaveRegs)
      | R.TAILCALL_JUMP {preFrameSize, jumpTo, uses} =>
        precolorVarList (coloring, uses, calleeSaveRegs @ callerSaveRegs)
      | R.RETURN {preFrameSize, stubOptions, uses} =>
        precolorVarList (coloring, uses, calleeSaveRegs @ callerSaveRegs)
      | R.EXIT => ()

  fun constrain graph coloring =
      R.LabelMap.foldli
      (fn (label, (first, mid, last), ()) =>
            (constrainFirst coloring first;
             app (constrainInsn coloring) mid;
             constrainLast coloring last))
        ()
        graph

end
