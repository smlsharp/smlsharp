(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure X86Subst : RTLSUBST =
struct

  structure I = RTL

  fun newVar ty =
      let
        val id = VarID.generate ()
      in
        {id = id, ty = ty} : I.var
      end

  fun load (code, pairs, var) =
      (foldl
        (fn ((var as {ty,...}, dst), z) =>
            RTLEdit.insertBefore
                (z, [I.MOVE (ty, I.REG var, I.REF_ dst)]))
        code pairs,
       var)

  fun save (code, pairs, var) =
      (foldl
        (fn ((var as {ty,...}, dst), z) =>
            RTLEdit.insertAfter
                (z, [I.MOVE (ty, dst, I.REF_ (I.REG var))]))
        code pairs,
       var)

  fun substVar subst (code:RTLEdit.focus) (var as {id, ty}:I.var) =
      case subst var of
        NONE => (code, nil, var)
      | SOME (I.REG var) => (code, nil, var)
      | SOME dst =>
        let
          val v = newVar ty
        in
          (code, [(v, dst)], v)
        end

  fun substVarList subst code (var::vars) =
      let
        val (_, pairs1, var) = substVar subst code var
        val (_, pairs2, vars) = substVarList subst code vars
      in
        (code, pairs1 @ pairs2, var::vars)
      end
    | substVarList subst code nil = (code, nil, nil)

  fun substClob subst var =
      case subst var of
        NONE => var
      | SOME (I.REG var) => var
      | SOME _ => raise Control.Bug "substClob"

  fun substAddr subst code addr =
      case addr of
        I.ABSADDR _ => (code, addr)
      | I.POSTFRAME _ => (code, addr)
      | I.PREFRAME _ => (code, addr)
      | I.WORKFRAME _ => (code, addr)
      | I.FRAMEINFO _ => (code, addr)
      | I.ADDRCAST (ptrTy, addr) =>
        let
          val (code, addr) = substAddr subst code addr
        in
          (code, I.ADDRCAST (ptrTy, addr))
        end
      | I.DISP (const, addr) =>
        let
          val (code, addr) = substAddr subst code addr
        in
          (code, I.DISP (const, addr))
        end
      | I.BASE var =>
        let
          val (code, var) = load (substVar subst code var)
        in
          (code, I.BASE var)
        end
      | I.BASEINDEX {base, scale, index} =>
        let
          val (code, base) = load (substVar subst code base)
          val (code, index) = load (substVar subst code index)
        in
          (code, I.BASEINDEX {base = base, scale = scale, index = index})
        end
      | I.ABSINDEX {base, scale, index} =>
        let
          val (code, index) = load (substVar subst code index)
        in
          (code, I.ABSINDEX {base = base, scale = scale, index = index})
        end

  fun substAddrR subst code (ptrTy, addr) =
      case substAddr subst code addr of
        (code, addr as I.BASE _) => (code, addr)
      | (code, addr) =>
        let
          val v = newVar (I.Ptr ptrTy)
          val code = RTLEdit.insertBefore
                       (code, [I.MOVEADDR (ptrTy, I.REG v, addr)])
        in
          (code, I.BASE v)
        end

  fun substMem subst code (I.ADDR addr) =
      let
        val (code, addr) = substAddr subst code addr
      in
        (code, I.ADDR addr)
      end
    | substMem subst code (mem as I.SLOT _) = (code, mem)

  fun substDstR subst code (I.REG var) =
      let
        val (code, pairs, var) = substVar subst code var
      in
        (code, pairs, I.REG var)
      end
    | substDstR subst code (I.MEM (ty, mem)) =
      let
        val (code, mem) = substMem subst code mem
        val v = newVar ty
      in
        (code, [(v, I.MEM (ty, mem))], I.REG v)
      end
    | substDstR subst code (I.COUPLE (ty, {hi, lo})) =
      raise Control.Bug "substDstR: COUPLE"

  fun substDstCoupleR subst code (I.COUPLE (ty, {hi, lo})) =
      let
        val (code, pairs1, hi) = substDstR subst code hi
        val (code, pairs2, lo) = substDstR subst code lo
      in
        (code, pairs1 @ pairs2, I.COUPLE (ty, {hi=hi, lo=lo}))
      end
    | substDstCoupleR subst code (I.REG _) =
      raise Control.Bug "substDstCoupleR: REG"
    | substDstCoupleR subst code (I.MEM _) =
      raise Control.Bug "substDstCoupleR: MEM"

  fun substDstRM subst code (I.REG var) =
      (
        case subst var of
          NONE => (code, I.REG var)
        | SOME (I.REG var) => (code, I.REG var)
        | SOME (I.MEM mem) => (code, I.MEM mem)
        | SOME (I.COUPLE _) => raise Control.Bug "substDstRM: COUPLE"
      )
    | substDstRM subst code (I.MEM (ty, mem)) =
      let
        val (code, mem) = substMem subst code mem
      in
        (code, I.MEM (ty, mem))
      end
    | substDstRM subst code (I.COUPLE (ty, {hi, lo})) =
      raise Control.Bug "substDstRM: COUPLE"

  fun substOperandR subst code operand =
      case operand of
        I.CONST c =>
        let
          val ty = RTLUtils.constTy c
          val v = newVar ty
          val code = RTLEdit.insertBefore
                         (code, [I.MOVE (ty, I.REG v, operand)])
        in
          (code, I.REF_ (I.REG v))
        end
      | I.REF (cast, dst) =>
        let
          val (code, var) = load (substDstR subst code dst)
        in
          (code, I.REF (cast, var))
        end

  fun substOperandCoupleR subst code (I.REF (cast, dst)) =
      let
        val (code, dst) = load (substDstCoupleR subst code dst)
      in
        (code, I.REF (cast, dst))
      end
    | substOperandCoupleR subst code (I.CONST _) =
      raise Control.Bug "substOperandCoupleR: CONST"

  fun substOperandRM subst code operand =
      case operand of
        I.CONST _ => substOperandR subst code operand
      | I.REF (cast, dst) =>
        let
          val (code, dst) = substDstRM subst code dst
        in
          (code, I.REF (cast, dst))
        end

  fun substOperandRMI subst code operand =
      case operand of
        I.CONST c => (code, operand)
      | I.REF _ => substOperandRM subst code operand

  fun substOperandRI subst code operand =
      case operand of
        I.CONST c => (code, operand)
      | I.REF _ => substOperandR subst code operand

  fun substOperandListRMI subst code (operand::operands) =
      let
        val (code, operand) = substOperandRMI subst code operand
        val (code, operands) = substOperandListRMI subst code operands
      in
        (code, operand::operands)
      end
    | substOperandListRMI subst code nil = (code, nil)

  fun normalizeRm code (dst, op1) =
      case (dst, op1) of
        (I.REG _, I.REF (_, I.REG _)) => (code, dst, op1)
      | (I.REG _, _) =>
        let
          val ty1 = RTLUtils.operandTy op1
          val v1 = newVar ty1
          val code = RTLEdit.insertBefore
                         (code, [I.MOVE (ty1, I.REG v1, op1)])
        in
          (code, dst, I.REF_ (I.REG v1))
        end
      | _ =>
        if (case (dst, op1) of (I.MEM m, I.REF (_, I.MEM m1)) => m = m1
                             | _ => false)
        then (code, dst, op1)
        else
          let
            val ty = RTLUtils.dstTy dst
            val v = newVar ty
            val code = RTLEdit.insertAfter
                           (code, [I.MOVE (ty, dst, I.REF_ (I.REG v))])
          in
            normalizeRm code (I.REG v, op1)
          end

  fun normalizeRmRmi code (dst, op1) =
      case (dst, op1) of
        (I.MEM m, I.REF (cast, mem as I.MEM (ty1, m1))) =>
        let
          val v1 = newVar ty1
          val code = RTLEdit.insertBefore
                         (code, [I.MOVE (ty1, I.REG v1, I.REF_ mem)])
        in
          (code, I.REF (cast, I.REG v1))
        end
      | _ => (code, op1)

  fun substRm subst code con (ty, dst, op1) =
      let
        val (code, dst) = substDstRM subst code dst
        val (code, op1) = substOperandRM subst code op1
        val (code, dst, op1) = normalizeRm code (dst, op1)
      in
        (code, con (ty, dst, op1))
      end

  fun substRmRmi3 subst code con (ty, dst, op1, op2) =
      let
        val (code, dst) = substDstRM subst code dst
        val (code, op1) = substOperandRM subst code op1
        val (code, op2) = substOperandRMI subst code op2
        val (code, dst, op1) = normalizeRm code (dst, op1)
        val (code, op2) = normalizeRmRmi code (dst, op2)
      in
        (code, con (ty, dst, op1, op2))
      end

  fun substRmRmiTest subst code con (ty, op1, op2) =
      let
        val (code, op1) = substOperandRM subst code op1
        val (code, op2) = substOperandRMI subst code op2
        val (dst, cast) =
            case op1 of I.REF (cast, dst) => (dst, cast)
                      | I.CONST _ => raise Control.Bug "substRmRmiTest"
        val (code, op2) = normalizeRmRmi code (dst, op2)
      in
        (code, con (ty, I.REF (cast, dst), op2))
      end

  fun substRmRi3 subst code con (ty, dst, op1, op2) =
      let
        val (code, dst) = substDstRM subst code dst
        val (code, op1) = substOperandRM subst code op1
        val (code, op2) = substOperandRI subst code op2
        val (code, dst, op1) = normalizeRm code (dst, op1)
      in
        (code, con (ty, dst, op1, op2))
      end

  fun substRRm subst code ty con (sign, dst, op1) =
      let
        val (code, dst) = save (substDstR subst code dst)
        val (code, op1) = substOperandRM subst code op1
      in
        (code, con (sign, dst, op1))
      end

  fun substFP subst code con (ty, mem) =
      let
        val (code, addr) = substMem subst code mem
      in
        (code, I.X86 (con (ty, addr)))
      end

  fun substMove con subst code (ty, dst, op1) =
      let
        val (code, dst) = substDstRM subst code dst
        val (code, op1) = substOperandRMI subst code op1
        val (code, op1) =
            if (case op1 of I.REF (_, dst1) => dst = dst1 | _ => false)
            then (code, op1)
            else normalizeRmRmi code (dst, op1)
      in
        (code, con (ty, dst, op1))
      end
        
  fun substInsn subst code insn =
      case insn of
        I.NOP => (code, insn)
      | I.STABILIZE => (code, insn)
      | I.REQUEST_SLOT slot => (code, insn)
      | I.REQUIRE_SLOT slot => (code, insn)
      | I.USE ops =>
        let
          val (code, ops) = substOperandListRMI subst code ops
        in
          (code, I.USE ops)
        end
      | I.COMPUTE_FRAME {uses, clobs} =>
        let
          val (code, uses) =
              VarID.Map.foldli
                (fn (key, var, (code, uses)) =>
                    let
                      val (code, var) = load (substVar subst code var)
                    in
                      (code, VarID.Map.insert (uses, key, var))
                    end)
                (code, VarID.Map.empty)
                uses
          val clobs = map (substClob subst) clobs
        in
          (code, I.COMPUTE_FRAME {uses=uses, clobs=clobs})
        end
      | I.MOVE (ty, dst, op1) => substMove I.MOVE subst code (ty, dst, op1)
      | I.MOVEADDR (ptrTy, dst, addr) =>
        let
          fun mayMove withDisp addr =
              case addr of
                I.ADDRCAST (_, addr) => mayMove true addr
              | I.ABSADDR _ => true
              | I.DISP (disp, addr) => mayMove true addr
              | I.BASE _ => not withDisp
              | I.ABSINDEX _ => false
              | I.BASEINDEX _ => false
              | I.POSTFRAME _ => false
              | I.PREFRAME _ => false
              | I.WORKFRAME _ => false
              | I.FRAMEINFO _ => false

          val (code, dst) =
              if mayMove false addr
              then substDstRM subst code dst
              else save (substDstR subst code dst)
          val (code, addr) = substAddr subst code addr
        in
          (code, I.MOVEADDR (ptrTy, dst, addr))
        end
      | I.COPY {ty, dst, src, clobs} =>
        let
          val (code, dst) = substDstRM subst code dst
          val (code, src) = substOperandRM subst code src
          val clobs = map (substClob subst) clobs
        in
          (code, I.COPY {ty=ty, dst=dst, src=src, clobs=clobs})
        end
      | I.MLOAD {ty, dst, srcAddr, size, defs, clobs} =>
        let
          val (code, srcAddr) = substAddrR subst code (I.Void, srcAddr)
          val (code, size) = substOperandR subst code size
          val (code, defs) = save (substVarList subst code defs)
          val clobs = map (substClob subst) clobs
        in
          (code, I.MLOAD {ty=ty, dst=dst, srcAddr=srcAddr, size=size,
                          defs=defs, clobs=clobs})
        end
      | I.MSTORE {ty, dstAddr, src, size, defs, clobs, global} =>
        let
          val (code, dstAddr) = substAddrR subst code (I.Void, dstAddr)
          val (code, size) = substOperandR subst code size
          val (code, defs) = save (substVarList subst code defs)
          val clobs = map (substClob subst) clobs
        in
          (code, I.MSTORE {ty=ty, dstAddr=dstAddr, src=src, size=size,
                           defs=defs, clobs=clobs, global=global})
        end
(*
      | I.ZEROEXT8TO16 (sign, dst, op1) =>
        substRRm subst code (I.Int16 sign) I.ZEROEXT8TO16 (sign, dst, op1)
      | I.ZEROEXT8TO32 (sign, dst, op1) =>
        substRRm subst code (I.Int32 sign) I.ZEROEXT8TO32 (sign, dst, op1)
      | I.ZEROEXT16TO32 (sign, dst, op1) =>
        substRRm subst code (I.Int32 sign) I.ZEROEXT16TO32 (sign, dst, op1)
      | I.EXT8TO16 (sign, dst, op1) =>
        substRRm subst code (I.Int16 sign) I.EXT8TO16 (sign, dst, op1)
*)
      | I.EXT8TO32 (sign, dst, op1) =>
        substRRm subst code (I.Int32 sign) I.EXT8TO32 (sign, dst, op1)
      | I.EXT16TO32 (sign, dst, op1) =>
        substRRm subst code (I.Int32 sign) I.EXT16TO32 (sign, dst, op1)
(*
      | I.SIGNEXT8TO16 (sign, dst, op1) =>
        substR subst code (I.Int16 sign) I.SIGNEXT8TO16 (sign, dst, op1)
      | I.SIGNEXT8TO32 (sign, dst, op1) =>
        substR subst code (I.Int32 sign) I.SIGNEXT8TO32 (sign, dst, op1)
      | I.SIGNEXT16TO32 (sign, dst, op1) =>
        substR subst code (I.Int32 sign) I.SIGNEXT16TO32 (sign, dst, op1)
*)
      | I.EXT32TO64 (sign, dst as I.COUPLE _, op1) =>
        let
          val (code, dst) = save (substDstCoupleR subst code dst)
          val (code, op1) = substOperandR subst code op1
        in
          (code, I.EXT32TO64 (sign, dst, op1))
        end
      | I.EXT32TO64 (I.U, I.MEM (ty, mem), op1) =>
        let
          val (code, mem) = substMem subst code mem
          val (code, op1) = substOperandRI subst code op1
        in
          (code, I.EXT32TO64 (I.U, I.MEM (ty, mem), op1))
        end
      | I.EXT32TO64 _ => raise Control.Bug "substInsn: EXT32TO64"
      | I.DOWN32TO8 (sign, dst, op1) =>
        substMove I.DOWN32TO8 subst code (sign, dst, op1)
      | I.DOWN32TO16 (sign, dst, op1) =>
        substMove I.DOWN32TO16 subst code (sign, dst, op1)
      | I.ADD (ty, dst, op1, op2) =>
        substRmRmi3 subst code I.ADD (ty, dst, op1, op2)
      | I.SUB (ty, dst, op1, op2) =>
        substRmRmi3 subst code I.SUB (ty, dst, op1, op2)

      | I.MUL ((ty as I.Int32 _, dst),
               (ty1 as I.Int32 _, op1), (ty2 as I.Int32 _, op2)) =>
        let
          val (code, dst) = save (substDstR subst code dst)
          val (code, op1) = substOperandRMI subst code op1
          val (code, op2) = substOperandRMI subst code op2
          val (code, op1, op2) =
              if (case (op1, op2) of
                    (I.CONST _, I.CONST _) => true
                  | (I.REF (_, I.MEM _), I.REF (_, I.MEM _)) => true
                  | _ => false)
              then
                let
                  val v1 = newVar ty1
                  val code = RTLEdit.insertBefore
                               (code, [I.MOVE (ty1, I.REG v1, op1)])
                in
                  (code, I.REF_ (I.REG v1), op2)
                end
              else
                (code, op1, op2)
        in
          (code,
           case op1 of
             I.REF (_, I.MEM _) => I.MUL ((ty, dst), (ty2, op2), (ty1, op1))
           | _ => I.MUL ((ty, dst), (ty1, op1), (ty2, op2)))
        end
      | I.MUL ((ty as I.Int64 _, dst),
               (op1Ty as I.Int32 _, op1), (op2Ty as I.Int32 _, op2)) =>
        let
          val (code, dst) = save (substDstCoupleR subst code dst)
          val (code, op1) = substOperandR subst code op1
          val (code, op2) = substOperandRM subst code op2
        in
          (code, I.MUL ((ty, dst), (op1Ty, op1), (op2Ty, op2)))
        end
      | I.MUL _ => raise Control.Bug "substInsn: MUL"
      | I.DIVMOD ({div=(divTy as I.Int32 _, ddiv), 
                   mod=(modTy as I.Int32 _, dmod)},
                  (op1Ty as I.Int64 _, op1), (op2Ty as I.Int32 _, op2)) =>
        let
          val (code, ddiv) = save (substDstR subst code ddiv)
          val (code, dmod) = save (substDstR subst code dmod)
          val (code, op1) = substOperandCoupleR subst code op1
          val (code, op2) = substOperandRM subst code op2
        in
          (code, I.DIVMOD ({div=(divTy,ddiv), mod=(modTy,dmod)},
                           (op1Ty,op1), (op2Ty,op2)))
        end
      | I.DIVMOD _ => raise Control.Bug "substInsn: DIVMOD"
      | I.AND (ty, dst, op1, op2) =>
        substRmRmi3 subst code I.AND (ty, dst, op1, op2)
      | I.OR (ty, dst, op1, op2) =>
        substRmRmi3 subst code I.OR (ty, dst, op1, op2)
      | I.XOR (ty, dst, op1, op2) =>
        substRmRmi3 subst code I.XOR (ty, dst, op1, op2)
      | I.LSHIFT (ty, dst, op1, op2) =>
        substRmRi3 subst code I.LSHIFT (ty, dst, op1, op2)
      | I.RSHIFT (ty, dst, op1, op2) =>
        substRmRi3 subst code I.RSHIFT (ty, dst, op1, op2)
      | I.ARSHIFT (ty, dst, op1, op2) =>
        substRmRi3 subst code I.ARSHIFT (ty, dst, op1, op2)
      | I.TEST_SUB (ty, op1, op2) =>
        substRmRmiTest subst code I.TEST_SUB (ty, op1, op2)
      | I.TEST_AND (ty, op1, op2) =>
        substRmRmiTest subst code I.TEST_AND (ty, op1, op2)
      | I.TEST_LABEL (ty, op1, l) =>
        let
          val (code, op1) = substOperandRM subst code op1
        in
          (code, I.TEST_LABEL (ty, op1, l))
        end
      | I.NOT (ty, dst, op1) =>
        substRm subst code I.NOT (ty, dst, op1)
      | I.NEG (ty, dst, op1) =>
        substRm subst code I.NEG (ty, dst, op1)
      | I.SET (cc, ty, dst, {test}) =>
        let
          val (code, test) = substInsn subst code test
          val (code, dst) = save (substDstR subst code dst)
        in
          (code, I.SET (cc, ty, dst, {test=test}))
        end
      | I.LOAD_FP dst =>
        let
          val (code, dst) = substDstRM subst code dst
        in
          (code, I.LOAD_FP dst)
        end
      | I.LOAD_SP dst =>
        let
          val (code, dst) = substDstRM subst code dst
        in
          (code, I.LOAD_SP dst)
        end
      | I.LOAD_PREV_FP dst =>
        let
          val (code, dst) = save (substDstR subst code dst)
        in
          (code, I.LOAD_PREV_FP dst)
        end
      | I.LOAD_RETADDR dst =>
        let
          val (code, dst) = save (substDstR subst code dst)
        in
          (code, I.LOAD_RETADDR dst)
        end
(*
      | I.SAVE_FP op1 =>
        let
          val (code, op1) = substOperandRM subst code op1
        in
          (code, I.SAVE_FP op1)
        end
      | I.SAVE_SP op1 =>
        let
          val (code, op1) = substOperandRM subst code op1
        in
          (code, I.SAVE_SP op1)
        end
*)
      | I.LOADABSADDR {ty, dst, symbol, thunk} =>
        let
          val ty = RTLUtils.labelTy symbol
          val (code, dst) = save (substDstR subst code dst)
        in
          (code, I.LOADABSADDR {ty=ty, dst=dst, symbol=symbol, thunk=thunk})
        end
      | I.X86 (I.X86LEAINT (ty, dst, {base, shift, offset, disp})) =>
        let
          val (code, base) = load (substVar subst code base)
          val (code, offset) = load (substVar subst code base)
          val (code, dst) = save (substDstR subst code dst)
        in
          (code, I.X86 (I.X86LEAINT (ty, dst, {base=base, shift=shift,
                                               offset=offset, disp=disp})))
        end
(*
      | I.X86 (I.X86HI8OF16 (sign, dst, op1)) =>
        let
          val (code, dst) = save (substDstR subst code (I.Int8 sign, dst))
          val (code, op1) = substOperandRM subst code op1
        in
          (code, I.X86 (I.X86HI8OF16 (sign, dst, op1)))
        end
*)
      | I.X86 (I.X86FLD (ty, mem)) =>
        substFP subst code I.X86FLD (ty, mem)
      | I.X86 (I.X86FLD_ST st1) => (code, insn)
      | I.X86 (I.X86FST (ty, mem)) =>
        substFP subst code I.X86FST (ty, mem)
      | I.X86 (I.X86FSTP (ty, mem)) =>
        substFP subst code I.X86FSTP (ty, mem)
      | I.X86 (I.X86FSTP_ST st1) => (code, insn)
      | I.X86 (I.X86FADD (ty, mem)) =>
        substFP subst code I.X86FADD (ty, mem)
      | I.X86 (I.X86FADD_ST (st1, st2)) => (code, insn)
      | I.X86 (I.X86FADDP st1) => (code, insn)
      | I.X86 (I.X86FSUB (ty, mem)) =>
        substFP subst code I.X86FSUB (ty, mem)
      | I.X86 (I.X86FSUB_ST (st1, st2)) => (code, insn)
      | I.X86 (I.X86FSUBP st1) => (code, insn)
      | I.X86 (I.X86FSUBR (ty, mem)) =>
        substFP subst code I.X86FSUBR (ty, mem)
      | I.X86 (I.X86FSUBR_ST (st1, st2)) => (code, insn)
      | I.X86 (I.X86FSUBRP st1) => (code, insn)
      | I.X86 (I.X86FMUL (ty, mem)) =>
        substFP subst code I.X86FMUL (ty, mem)
      | I.X86 (I.X86FMUL_ST (st1, st2)) => (code, insn)
      | I.X86 (I.X86FMULP st1) => (code, insn)
      | I.X86 (I.X86FDIV (ty, mem)) =>
        substFP subst code I.X86FDIV (ty, mem)
      | I.X86 (I.X86FDIV_ST (st1, st2)) => (code, insn)
      | I.X86 (I.X86FDIVP st1) => (code, insn)
      | I.X86 (I.X86FDIVR (ty, mem)) =>
        substFP subst code I.X86FDIVR (ty, mem)
      | I.X86 (I.X86FDIVR_ST (st1, st2)) => (code, insn)
      | I.X86 (I.X86FDIVRP st1) => (code, insn)
      | I.X86 (I.X86FPREM) => (code, insn)
      | I.X86 (I.X86FABS) => (code, insn)
      | I.X86 (I.X86FCHS) => (code, insn)
      | I.X86 I.X86FINCSTP => (code, insn)
      | I.X86 (I.X86FFREE st) => (code, insn)
      | I.X86 (I.X86FXCH st) => (code, insn)
      | I.X86 (I.X86FUCOM st) => (code, insn)
      | I.X86 (I.X86FUCOMP st) => (code, insn)
      | I.X86 I.X86FUCOMPP => (code, insn)
(*
      | I.X86 (I.X86FSTSW (dst, test)) =>
        let
          val (code, test) = substInsn subst code test
          val (code, dst) = substDstRM subst code dst
        in
          (code, I.X86 (I.X86FSTSW (dst, test)))
        end
*)
      | I.X86 (I.X86FSW_TESTH {clob,mask}) =>
        (code, I.X86 (I.X86FSW_TESTH {clob = substClob subst clob,
                                      mask = mask}))
      | I.X86 (I.X86FSW_MASKCMPH {clob,mask,compare}) =>
        (code, I.X86 (I.X86FSW_MASKCMPH {clob = substClob subst clob,
                                         mask = mask, compare = compare}))
      | I.X86 (I.X86FLDCW mem) =>
        let
          val (code, dst) = substMem subst code mem
        in
          (code, I.X86 (I.X86FLDCW mem))
        end
      | I.X86 (I.X86FNSTCW mem) =>
        let
          val (code, dst) = substMem subst code mem
        in
          (code, I.X86 (I.X86FNSTCW mem))
        end
      | I.X86 I.X86FWAIT => (code, insn)
      | I.X86 I.X86FNCLEX => (code, insn)

  fun substLast subst last =
      case last of
        I.HANDLE (insn, {nextLabel, handler}) =>
        let
          val code = RTLEdit.singletonLast (RTLEdit.jump nextLabel)
          val (code, insn) = substInsn subst code insn
          val (code, _) =
              RTLEdit.insertLastAfter
                (code, fn l => I.HANDLE (insn, {nextLabel=l, handler=handler}))
        in
          code
        end
      | I.CJUMP {test, cc, thenLabel, elseLabel} =>
        let
          val code = RTLEdit.singletonFirst I.ENTER
          val (code, test) = substInsn subst code test
        in
          if RTLEdit.atLast code
          then RTLEdit.insertLast
                 (code, I.CJUMP {test=test, cc=cc, thenLabel=thenLabel,
                                 elseLabel=elseLabel})
          else
            let
              val ty = I.Int8 I.U
              val v = newVar ty
              val code = RTLEdit.insertBefore
                           (code, [I.SET (cc, ty, I.REG v, {test=test})])
              val code = RTLEdit.gotoLast code
              val r = I.REF_ (I.REG v)
            in
              RTLEdit.insertLast
                (code, I.CJUMP {test=I.TEST_AND (ty, r, r),
                                cc=I.NOTEQUAL, thenLabel=thenLabel,
                                elseLabel=elseLabel})
            end
        end
      | I.CALL {callTo, returnTo, handler, defs, uses, needStabilize,
                postFrameAdjust} =>
        let
          val code = RTLEdit.singletonLast (RTLEdit.jump returnTo)
          val (code, callTo) = substAddr subst code callTo
          val (code, defs) = save (substVarList subst code defs)
          val (code, uses) = load (substVarList subst code uses)
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
      | I.JUMP {jumpTo, destinations} =>
        let
          val code = RTLEdit.singletonFirst I.ENTER
          val (code, jumpTo) = substAddr subst code jumpTo
        in
          RTLEdit.insertLast
            (code, I.JUMP {jumpTo=jumpTo, destinations=destinations})
        end
      | I.UNWIND_JUMP {jumpTo, fp, sp, uses, handler} =>
        let
          val code = RTLEdit.singletonFirst I.ENTER
          val (code, jumpTo) = substAddr subst code jumpTo
          val (code, fp) = substOperandRM subst code fp
          val (code, sp) = substOperandRM subst code sp
          val (code, uses) = load (substVarList subst code uses)
        in
          RTLEdit.insertLast
            (code, I.UNWIND_JUMP {jumpTo=jumpTo, fp=fp, sp=sp,
                                  uses=uses, handler=handler})
        end
      | I.TAILCALL_JUMP {preFrameSize, jumpTo, uses} =>
        let
          val code = RTLEdit.singletonFirst I.ENTER
          val (code, jumpTo) = substAddr subst code jumpTo
          val (code, uses) = load (substVarList subst code uses)
        in
          RTLEdit.insertLast
            (code, I.TAILCALL_JUMP {preFrameSize=preFrameSize,
                                    jumpTo=jumpTo,
                                    uses=uses})
        end
      | I.RETURN {preFrameSize, stubOptions, uses} =>
        let
          val code = RTLEdit.singletonFirst I.ENTER
          val (code, uses) = load (substVarList subst code uses)
        in
          RTLEdit.insertLast
            (code, I.RETURN {preFrameSize=preFrameSize,
                             stubOptions=stubOptions,
                             uses=uses})
        end
      | I.EXIT => RTLEdit.singletonLast last

  fun substFirst subst first =
      case first of
        I.ENTER => RTLEdit.singletonFirst first
      | I.BEGIN {label, align, loc} => RTLEdit.singletonFirst first
      | I.CODEENTRY {label, symbol, scope, align, preFrameSize, stubOptions,
                     defs, loc} =>
        let
          val code = RTLEdit.singletonFirst I.ENTER
          val (code, defs) = save (substVarList subst code defs)
        in
          RTLEdit.insertFirst
            (code, I.CODEENTRY {label=label, symbol=symbol, scope=scope,
                                align=align,
                                preFrameSize=preFrameSize,
                                stubOptions=stubOptions,
                                defs=defs, loc=loc})
        end
      | I.HANDLERENTRY {label, align, defs, loc} =>
        let
          val code = RTLEdit.singletonFirst I.ENTER
          val (code, defs) = save (substVarList subst code defs)
        in
          RTLEdit.insertFirst
            (code, I.HANDLERENTRY {label=label, align=align,
                                   defs=defs, loc=loc})
        end

  fun substitute subst graph =
      RTLEdit.extend
        (fn RTLEdit.FIRST first =>
            RTLEdit.unfocus (substFirst subst first)
          | RTLEdit.MIDDLE insn =>
            let
              val code = RTLEdit.singletonFirst I.ENTER
              val (code, insn) = substInsn subst code insn
            in
              RTLEdit.unfocus (RTLEdit.insertBefore (code, [insn]))
            end
          | RTLEdit.LAST last =>
            RTLEdit.unfocus (substLast subst last))
        graph

end
