structure RTLTypeCheck : sig

  type err
  type symbolEnv
  val check : {checkStability: bool} -> RTL.program -> symbolEnv * err list

  val checkCluster : {symbolEnv: symbolEnv, checkStability: bool}
                     -> RTL.cluster -> err list

end =
struct

  structure R = RTL
  open RTLTypeCheckError

  fun DisplacementMustBeInt x y = RTLTypeCheckError.DisplacementMustBeInt (x, y)
  fun IndexMustBeInt x y = RTLTypeCheckError.IndexMustBeInt (x, y)
  fun OperandMustBeInt x y = RTLTypeCheckError.OperandMustBeInt (x, y)
  fun VarMustBePointer x y = RTLTypeCheckError.VarMustBePointer (x, y)
  fun AddrTypeMismatch x y = RTLTypeCheckError.AddrTypeMismatch (x, y)
  fun VariableTypeMismatch x y = RTLTypeCheckError.VariableTypeMismatch (x, y)
  fun LabelTypeMismatch x y = RTLTypeCheckError.LabelTypeMismatch (x, y)
  fun TypeAnnotationMismatch x y =
      RTLTypeCheckError.TypeAnnotationMismatch (x, y)
  fun DstTypeMismatch x y = RTLTypeCheckError.DstTypeMismatch (x, y)
  fun OperandTypeMismatch x y = RTLTypeCheckError.OperandTypeMismatch (x, y)
  fun ConstTypeMismatch x y = RTLTypeCheckError.ConstTypeMismatch (x, y)
  fun MemTypeMismatch x y = RTLTypeCheckError.MemTypeMismatch (x, y)
  fun ErrorAtFirst x y = RTLTypeCheckError.ErrorAtFirst (x, y)
  fun ErrorAtMiddle x y = RTLTypeCheckError.ErrorAtMiddle (x, y)
  fun ErrorAtLast x y = RTLTypeCheckError.ErrorAtLast (x, y)
  fun ErrorInBlock x y = RTLTypeCheckError.ErrorInBlock (x, y)
  fun ErrorInCluster x y = RTLTypeCheckError.ErrorInCluster (x, y)
  fun ErrorInData x y = RTLTypeCheckError.ErrorInData (x, y)

  fun ifcons nil f = nil
    | ifcons (l as (_::_)) f = [f l]

  fun minus (set, vars) =
      RTLUtils.Var.setMinus (set, RTLUtils.Var.fromList vars)

  datatype symbolDefStrength =
           STRONG   (* defined in this compile unit *)
         | WEAK     (* defined in another compile unit *)

  type symbolDef =
       {
         haveLinkEntry: bool,
         haveLinkStub: bool,
         scope: R.symbolScope,
         ptrTy: R.ptrTy
       }

  type symbolEnv =
       (symbolDefStrength * symbolDef) SEnv.map

  type env =
      {
        vars: RTLUtils.Var.set,
        slots: RTLUtils.Slot.set
      }

  type context =
      {
        env: env,
        liveOut: env,
        cluster:
          {
            frameBitmap: R.frameBitmap list,
            body: R.graph,
            baseLabel: R.label option,
            preFrameSize: int,
            postFrameSize: int
          },
        symbolEnv: symbolEnv,
        liveness: {vars:RTLLiveness.liveness, slots:RTLLiveness.livenessSlot}
                    R.LabelMap.map
      }

  fun varList varSet = RTLUtils.Var.fold (op ::) nil varSet
  fun slotList slotSet = RTLUtils.Slot.fold (op ::) nil slotSet

  val emptyEnv = {vars = RTLUtils.Var.emptySet, slots = RTLUtils.Slot.emptySet}
  fun varEnv vars =
      {vars = RTLUtils.Var.fromList vars, slots = RTLUtils.Slot.emptySet}
  fun slotEnv slots =
      {vars = RTLUtils.Var.emptySet, slots = RTLUtils.Slot.fromList slots}

  fun unionEnv ({vars=v1,slots=s1}, {vars=v2,slots=s2}) =
      {vars = RTLUtils.Var.setUnion (v1, v2),
       slots = RTLUtils.Slot.setUnion (s1, s2)}

  fun dstEnv dst =
      case dst of
        R.REG v => varEnv [v]
      | R.COUPLE (_, {hi, lo}) => unionEnv (dstEnv hi, dstEnv lo)
      | R.MEM (_, R.SLOT slot) => slotEnv [slot]
      | R.MEM (_, R.ADDR _) => emptyEnv

  fun extendContext ({env, liveOut, cluster, symbolEnv, liveness}:context,
                     env2) =
      {env = unionEnv (env, env2),
       liveOut = liveOut,
       cluster = cluster,
       symbolEnv = symbolEnv,
       liveness = liveness} : context

  fun eqTy (tys as {actual:R.ty, require:R.ty}) f =
      if actual = require then nil else [f tys]

  fun checkTid (context:context) tid =
      if List.exists
           (fn {source,bits} =>
               List.exists (fn SOME t => t = tid | NONE => false) bits)
           (#frameBitmap (#cluster context))
      then nil
      else [UndefinedGenericTid tid]

  fun checkTy (context:context) ty =
      case ty of
        R.Int8 s => nil
      | R.Int16 s => nil
      | R.Int32 s => nil
      | R.Int64 s => nil
      | R.Real32 => nil
      | R.Real64 => nil
      | R.Real80 => nil
      | R.Ptr ptrTy => nil
      | R.PtrDiff _ => nil
      | R.NoType => nil
      | R.Generic tid => checkTid context tid
      | R.Atom => nil

  fun checkIntTy ty f =
      case ty of
        R.Int8 s => nil
      | R.Int16 s => nil
      | R.Int32 s => nil
      | R.Int64 s => nil
      | R.Real32 => [f {actual=ty}]
      | R.Real64 => [f {actual=ty}]
      | R.Real80 => [f {actual=ty}]
      | R.Ptr _ => [f {actual=ty}]
      | R.PtrDiff _ => nil
      | R.NoType => [f {actual=ty}]
      | R.Generic tid => [f {actual=ty}]
      | R.Atom => nil

  fun checkPtrTy (tys as {actual:R.ptrTy, require:R.ptrTy}) f =
      if actual = require then nil else [f tys]

  fun checkAnyPtrTy ty f =
      case ty of
        R.Int8 s => ([f {actual=ty}], R.Void)
      | R.Int16 s => ([f {actual=ty}], R.Void)
      | R.Int32 s => ([f {actual=ty}], R.Void)
      | R.Int64 s => ([f {actual=ty}], R.Void)
      | R.Real32 => ([f {actual=ty}], R.Void)
      | R.Real64 => ([f {actual=ty}], R.Void)
      | R.Real80 => ([f {actual=ty}], R.Void)
      | R.Ptr pty => (nil, pty)
      | R.PtrDiff _ => ([f {actual=ty}], R.Void)
      | R.NoType => ([f {actual=ty}], R.Void)
      | R.Generic tid => ([f {actual=ty}], R.Void)
      | R.Atom => (nil, R.Void)

  fun checkLabelRef (context:context) label =
      case label of
        R.NULL ptrTy => (nil, ptrTy)
      | R.CURRENT_POSITION => (nil, R.Code)
      | R.ELF_GOT => (nil, R.Void)
      | R.LABELCAST (ptrTy, label) => (#1 (checkLabelRef context label), ptrTy)
      | R.LABEL l =>
        (
          case R.LabelMap.find (#body (#cluster context), l) of
            SOME _ => nil
          | NONE => if (case #baseLabel (#cluster context) of
                          NONE => false
                        | SOME baseLabel => LocalVarID.eq (baseLabel, l))
                    then nil
                    else [UndefinedLabel l],
          R.Code
        )
      | R.SYMBOL (ptrTy, scope, symbol) =>
        (
          case SEnv.find (#symbolEnv context, symbol) of
            NONE => [UndefinedSymbol symbol]
          | SOME (_, {scope=scope2, ptrTy=ptrTy2, ...}) =>
            (
              if scope = scope2 then nil
              else [SymbolScopeMismatch (symbol,
                                         {actual=scope, require=scope2})]
            ) @
            (
              if ptrTy = ptrTy2 then nil
              else [SymbolTypeMismatch (symbol, {actual=ptrTy,require=ptrTy2})]
            ),
          ptrTy
        )
      | R.LINK_ENTRY symbol =>
        (
          case SEnv.find (#symbolEnv context, symbol) of
            NONE => [UndefinedSymbol symbol]
          | SOME (_, {haveLinkEntry=true,...}) => nil
          | SOME (_, {haveLinkEntry=false,...}) =>
            [SymbolLinkEntryNotFound label],
          R.Void
        )
      | R.LINK_STUB symbol =>
        (
          case SEnv.find (#symbolEnv context, symbol) of
            NONE => [UndefinedSymbol symbol]
          | SOME (_, {haveLinkStub=true,...}) => nil
          | SOME (_, {haveLinkStub=false,...}) =>
            [SymbolLinkStubNotFound label],
          R.Code
        )

  fun checkConst (context:context) const =
      case const of
        R.SYMOFFSET {label, base} =>
        let
          val (err1, pty1) = checkLabelRef context label
          val (err2, pty2) = checkLabelRef context base
          val err3 = if pty1 = pty2 then nil
                     else [PointerTypeMismatch (const, pty1, pty2)]
        in
          (err1 @ err2 @ err3, R.PtrDiff pty1)
        end
      | R.INT64 _ => (nil, R.Int64 R.S)
      | R.UINT64 _ => (nil, R.Int64 R.U)
      | R.INT32 _ => (nil, R.Int32 R.S)
      | R.UINT32 _ => (nil, R.Int32 R.U)
      | R.INT16 _ => (nil, R.Int16 R.S)
      | R.UINT16 _ => (nil, R.Int16 R.U)
      | R.INT8 _ => (nil, R.Int8 R.S)
      | R.UINT8 _ => (nil, R.Int8 R.U)
      | R.REAL32 _ => (nil, R.Real32)
      | R.REAL64 _ => (nil, R.Real64)
      | R.REAL64HI _ => (nil, R.NoType)
      | R.REAL64LO _ => (nil, R.NoType)

  fun checkFormat (context:context) ({size,align,tag}:R.format) =
      case tag of
        R.BOXED => nil
      | R.UNBOXED => nil
      | R.GENERIC tid => checkTid context tid

  fun checkSlot (context:context) (slot as {id,format}:R.slot) =
      let
        val err1 = checkFormat context format
        val err2 =
            case RTLUtils.Slot.find (#slots (#env context), id) of
              NONE => [UndefinedSlot slot]
            | SOME {format=format2,...} =>
              if format = format2 then nil
              else [SlotFormatMismatch (slot, {actual=format,require=format2})]
      in
        err1 @ err2
      end

  fun checkVar (context:context) (var as {id, ty}:R.var) =
      let
        val err1 = checkTy context ty
        val err2 =
            case RTLUtils.Var.find (#vars (#env context), id) of
              NONE => [UndefinedVariable var]
            | SOME {ty=ty2,...} =>
              eqTy {actual=ty, require=ty2} (VariableTypeMismatch var)
      in
        (err1 @ err2, ty)
      end

  fun checkVarTy (context:context) ({id, ty}:R.var) =
      (checkTy context ty, ty)

  fun checkDefs context varList =
      foldr (fn (x,z) => #1 (checkVarTy context x) @ z) nil varList

  fun checkUses context varList =
      foldr (fn (x,z) => #1 (checkVar context x) @ z) nil varList

  fun checkClob context (var as {id,ty}:R.var) =
      let
        val err1 = checkTy context ty
        val err2 = if RTLUtils.Var.inDomain (#vars (#env context), id)
                   then [ClobVariableUsed var]
                   else nil
      in
        err1 @ err2
      end

  fun checkClobs context varList =
      foldr (fn (x,z) => checkClob context x @ z) nil varList

  fun checkAddr (context:context) addr =
      case addr of
        R.ABSADDR label => checkLabelRef context label
      | R.ADDRCAST (ptrTy, addr) => (#1 (checkAddr context addr), ptrTy)
      | R.DISP (const, addr2) =>
        let
          val (err1, ty1) = checkConst context const
          val err2 = checkIntTy ty1 (DisplacementMustBeInt const)
          val (err3, pty2) = checkAddr context addr2
          val err4 = case ty1 of
                       R.PtrDiff pty =>
                       if pty = pty2 then nil
                       else [DisplacementTypeMismatch
                               (addr,{displacement=ty1, addr=pty2})]
                     | _ => nil
          val pty = case pty2 of
                      R.Void => R.Void
                    | R.Data => R.Void  (* middle of heap object *)
                    | R.Code => R.Code
        in
          (err1 @ err2 @ err3 @ err4, pty)
        end
      | R.BASE var =>
        let
          val (err1, ty1) = checkVar context var
          val (err2, pty1) = checkAnyPtrTy ty1 (VarMustBePointer var)
        in
          (err1 @ err2, pty1)
        end
      | R.ABSINDEX {base, index, scale} =>
        let
          val (err1, pty1) = checkLabelRef context base
          val (err2, ty2) = checkVar context index
          val err3 = checkIntTy ty2 (IndexMustBeInt index)
          val err4 = case ty2 of
                       R.PtrDiff pty =>
                       if pty = pty1 then nil
                       else [IndexTypeMismatch (addr,{index=ty2, addr=pty1})]
                     | _ => nil
          val pty = case pty1 of
                      R.Void => R.Void
                    | R.Data => R.Void  (* middle of heap object *)
                    | R.Code => R.Code
        in
          (err1 @ err2 @ err3 @ err4, pty)
        end
      | R.BASEINDEX {base, index, scale} =>
        let
          val (err1, ty1) = checkVar context base
          val (err2, pty1) = checkAnyPtrTy ty1 (VarMustBePointer base)
          val (err3, ty2) = checkVar context index
          val err4 = checkIntTy ty2 (IndexMustBeInt index)
          val err5 = case ty2 of
                       R.PtrDiff pty =>
                       if pty = pty1 then nil
                       else [IndexTypeMismatch (addr,{index=ty2, addr=pty1})]
                     | _ => nil
          val pty = case pty1 of
                      R.Void => R.Void
                    | R.Data => R.Void  (* middle of heap object *)
                    | R.Code => R.Code
        in
          (err1 @ err2 @ err3 @ err4 @ err5, pty)
        end
      | R.PREFRAME {offset, size} =>
        let
          val preSize = #preFrameSize (#cluster context)
        in
          (
            if offset < 0 orelse  offset > preSize
            then [PreFrameExceeded {actual=offset, limit=preSize}]
            else if size < 0 orelse offset - size < 0
            then [PreFrameExceeded {actual=offset-size, limit=preSize}]
            else nil,
            R.Void
          )
        end
      | R.POSTFRAME {offset, size} =>
        let
          val postSize = #postFrameSize (#cluster context)
        in
          (
            if offset < 0 orelse offset > postSize
            then [PostFrameExceeded {actual=offset, limit=postSize}]
            else if size < 0 orelse offset + size > postSize
            then [PostFrameExceeded {actual=offset+size, limit=postSize}]
            else nil,
            R.Void
          )
        end
      | R.WORKFRAME slot => (checkSlot context slot, R.Void)
      | R.FRAMEINFO n => (nil, R.Void)

  fun checkMem (context:context) (ty, mem) =
      let
        val err1 = checkTy context ty
        val err2 =
            case mem of
              R.SLOT {id,format} => checkFormat context format
            | R.ADDR addr => #1 (checkAddr context addr)
      in
        (err1 @ err2, ty)
      end

  fun checkDef (context:context) dst =
      case dst of
        R.REG v =>
        let
          val (err1, ty1) = checkVarTy context v
        in
          (err1, ty1)
        end
      | R.COUPLE (ty, {hi, lo}) =>
        let
          val err1 = checkTy context ty
          val (err2, ty1) = checkDef context hi
          val (err3, ty2) = checkDef context lo
        in
          (err1 @ err2 @ err3, ty)
        end
      | R.MEM mem => checkMem context mem

  fun checkRef (context:context) dst =
      case dst of
        R.REG v => checkVar context v
      | R.COUPLE (ty, {hi, lo}) =>
        let
          val err1 = checkTy context ty
          val (err2, ty1) = checkRef context hi
          val (err3, ty2) = checkRef context lo
        in
          (err1 @ err2 @ err3, ty)
        end
      | R.MEM mem => checkMem context mem

  fun checkOperand (context:context) op1 =
      case op1 of
        R.CONST const => checkConst context const
      | R.REF (R.N, dst) => checkRef context dst
      | R.REF (R.CAST ty, dst) =>
        let
          val err1 = checkTy context ty
          val (err2, _) = checkRef context dst
        in
          (err1 @ err2, ty)
        end

  fun checkSucc (context:context) label =
      case R.LabelMap.find (#liveness context, label) of
        NONE => [UndefinedLabel label]
      | SOME {vars={liveIn=liveVars,...}, slots={liveIn=liveSlots,...}} =>
        let
          val err1 =
              RTLUtils.Var.fold
                (fn (v as {id, ty}, z) =>
                    case RTLUtils.Var.find (#vars (#env context), id) of
                      NONE => RequireLiveVarAcrossBlock (v,{succ=label}) :: z
                    | SOME {ty=ty2,...} =>
                      eqTy {actual=ty, require=ty2}
                           (fn _ =>
                               TypeMismatchAcrossBlock
                                 (v,{succ=label,thisBlock=ty2,succBlock=ty}))
                      @ z)
                nil
                liveVars

          val err2 =
              RTLUtils.Slot.fold
                (fn (s as {id, format}, z) =>
                    case RTLUtils.Slot.find (#slots (#env context), id) of
                      NONE => RequireLiveSlotAcrossBlock (s,{succ=label}) :: z
                    | SOME _ => nil)
                nil
                liveSlots
        in
          err1 @ err2
        end

  fun checkHandler (context:context) handler =
      case handler of
        R.NO_HANDLER => nil
      | R.HANDLER {outside, handlers} =>
        foldr
          (fn (label, z) =>
              case R.LabelMap.find (#body (#cluster context), label) of
                SOME (R.HANDLERENTRY _, _, _) =>
                checkSucc context label @ z
              | SOME (_, _, _) => NotHandlerEntry label :: z
              | NONE => UndefinedLabel label :: z)
          nil
          handlers

  fun checkLabelConsist (label, key) =
      if LocalVarID.eq (label, key) then nil
      else [InconsistLabel (label, {key=key})]

  fun checkFirst (context:context) (key, first) =
      case first of
        R.BEGIN {label, align, loc} =>
        (checkLabelConsist (label, key), emptyEnv)
      | R.CODEENTRY {label, symbol, scope, align, preFrameSize,
                     stubOptions, defs, loc} =>
        let
          val err1 = checkLabelConsist (label, key)
          val err2 = checkDefs context defs
          val err3 =
              if RTLUtils.Var.isEmpty (#vars (#env context))
              then nil
              else map UndefinedVariable (varList (#vars (#env context)))
          val err4 =
              if RTLUtils.Slot.isEmpty (#slots (#env context))
              then nil
              else map UndefinedSlot (slotList (#slots (#env context)))
          val preSize = #preFrameSize (#cluster context)
          val err5 =
              if preFrameSize <= preSize
              then nil
              else [PreFrameExceeded {actual=preFrameSize, limit=preSize}]
        in
          (err1 @ err2 @ err3 @ err4 @ err5, varEnv defs)
        end
      | R.HANDLERENTRY {label, align, defs, loc} =>
        let
          val err1 = checkLabelConsist (label, key)
          val err2 = checkDefs context defs
        in
          (err1 @ err2, varEnv defs)
        end
      | R.ENTER => ([EnterFound], emptyEnv)

  fun checkInsn2 (context:context) (ty, dst, op1) =
      let
        val err1 = checkTy context ty
        val (err2, ty1) = checkDef context dst
        val err3 = eqTy {actual=ty1, require=ty} (DstTypeMismatch dst)
        val (err4, ty2) = checkOperand context op1
        val err5 = eqTy {actual=ty2, require=ty} (OperandTypeMismatch op1)
      in
        (err1 @ err2 @ err3 @ err4 @ err5, dstEnv dst)
      end

  fun checkInsn3 (context:context) (ty, dst, op1, op2) =
      let
        val err1 = checkTy context ty
        val (err2, ty1) = checkDef context dst
        val err3 = eqTy {actual=ty1, require=ty} (DstTypeMismatch dst)
        val (err4, ty2) = checkOperand context op1
        val err5 = eqTy {actual=ty2, require=ty} (OperandTypeMismatch op1)
        val (err6, ty3) = checkOperand context op2
        val err7 = eqTy {actual=ty3, require=ty} (OperandTypeMismatch op2)
      in
        (err1 @ err2 @ err3 @ err4 @ err5 @ err6 @ err7, dstEnv dst)
      end

  fun checkCast (context:context) (sign, fromTy, toTy, dst, op1) =
      let
        val (err1, ty1) = checkDef context dst
        val err2 = eqTy {actual=ty1, require=toTy sign} (DstTypeMismatch dst)
        val (err3, ty2) = checkOperand context op1
        val err4 = eqTy {actual=ty2, require=fromTy sign}
                        (OperandTypeMismatch op1)
      in
        (err1 @ err2 @ err3 @ err4, dstEnv dst)
      end

  fun checkShift (context:context) (ty, dst, op1, op2) =
      let
        val err1 = checkTy context ty
        val (err2, ty1) = checkDef context dst
        val err3 = eqTy {actual=ty1, require=ty} (DstTypeMismatch dst)
        val (err4, ty2) = checkOperand context op1
        val err5 = eqTy {actual=ty2, require=ty} (OperandTypeMismatch op1)
        val (err6, ty3) = checkOperand context op2
        val err7 = checkIntTy ty3 (OperandMustBeInt op2)
      in
        (err1 @ err2 @ err3 @ err4 @ err5 @ err6 @ err7, dstEnv dst)
      end

  fun checkTest (context:context) (ty, op1, op2) =
      let
        val err1 = checkTy context ty
        val (err2, ty1) = checkOperand context op1
        val err3 = eqTy {actual=ty1, require=ty} (OperandTypeMismatch op1)
        val (err4, ty2) = checkOperand context op2
        val err5 = eqTy {actual=ty2, require=ty} (OperandTypeMismatch op2)
      in
        (err1 @ err2 @ err3 @ err4 @ err5, emptyEnv)
      end

  fun checkX86FLD (context:context) (ty, mem) =
      let
        val (err1, _) = checkMem context (ty, mem)
      in
        (err1, emptyEnv)
      end

  fun checkX86FST (context:context) (ty, mem) =
      let
        val (err1, _) = checkMem context (ty, mem)
      in
        (err1, dstEnv (R.MEM (ty, mem)))
      end

  fun checkInsn (context:context) insn =
      case insn of
        R.NOP => (nil, emptyEnv)
      | R.STABILIZE => (nil, emptyEnv)  (* stability check is performed later *)
      | R.REQUEST_SLOT slot => (nil, slotEnv [slot])
      | R.REQUIRE_SLOT slot => (checkSlot context slot, emptyEnv)
      | R.USE ops =>
        (foldr (fn (x,z) => #1 (checkOperand context x) @ z) nil ops, emptyEnv)
      | R.COMPUTE_FRAME {uses, clobs} =>
        (checkUses context (LocalVarID.Map.listItems uses) @
         checkClobs context clobs,
         emptyEnv)
      | R.MOVE (ty, dst, op1) => checkInsn2 context (ty, dst, op1)
      | R.MOVEADDR (pty, dst, addr) =>
        let
          val (err1, ty1) = checkDef context dst
          val err2 = eqTy {actual=ty1, require=R.Ptr pty} (DstTypeMismatch dst)
          val (err3, pty2) = checkAddr context addr
          val err4 = checkPtrTy {actual=pty2, require=pty}
                                (AddrTypeMismatch addr)
        in
          (err1 @ err2 @ err3 @ err4, dstEnv dst)
        end
      | R.COPY {ty, dst:R.dst, src:R.operand, clobs} =>
        let
          val err1 = checkTy context ty
          val (err2, env1) = checkInsn2 context (ty, dst, src)
          val err3 = checkClobs context clobs
        in
          (err1 @ err2 @ err3, env1)
        end
      | R.MLOAD {ty, dst:R.slot, srcAddr, size, defs, clobs} =>
        let
          val err1 = checkTy context ty
          val (err2, _) = checkDef context (R.MEM (ty, R.SLOT dst))
          val (err3, pty1) = checkAddr context srcAddr
          val (err4, ty2) = checkOperand context size
          val err5 = checkIntTy ty2 (OperandMustBeInt size)
          val err6 = checkDefs context defs
          val err7 = checkClobs context clobs
        in
          (err1 @ err2 @ err3 @ err4 @ err5 @ err6 @ err7,
           unionEnv (slotEnv [dst], varEnv defs))
        end
      | R.MSTORE {ty, dstAddr, src:R.slot, size, defs, clobs, global} =>
        let
          val err1 = checkTy context ty
          val (err2, pty1) = checkAddr context dstAddr
          val err3 = checkSlot context src
          val (err4, ty2) = checkOperand context size
          val err5 = checkIntTy ty2 (OperandMustBeInt size)
          val err6 = checkDefs context defs
          val err7 = checkClobs context clobs
        in
          (err1 @ err2 @ err3 @ err4 @ err5 @ err6 @ err7, varEnv defs)
        end
      | R.EXT8TO32 (sign, dst, op1) =>
        checkCast context (sign, R.Int8, R.Int32, dst, op1)
      | R.EXT16TO32 (sign, dst, op1) =>
        checkCast context (sign, R.Int16, R.Int32, dst, op1)
      | R.EXT32TO64 (sign, dst, op1) =>
        checkCast context (sign, R.Int32, R.Int64, dst, op1)
      | R.DOWN32TO8 (sign, dst, op1) =>
        checkCast context (sign, R.Int32, R.Int8, dst, op1)
      | R.DOWN32TO16 (sign, dst, op1) =>
        checkCast context (sign, R.Int32, R.Int16, dst, op1)
      | R.ADD (ty, dst, op1, op2) => checkInsn3 context (ty, dst, op1, op2)
      | R.SUB (ty, dst, op1, op2) => checkInsn3 context (ty, dst, op1, op2)
      | R.MUL ((dstTy, dst), (op1Ty, op1), (op2Ty, op2)) =>
        let
          val err1 = checkTy context dstTy
          val err2 = checkTy context op1Ty
          val err3 = checkTy context op2Ty
          val (err4, ty1) = checkDef context dst
          val err5 = eqTy {actual=ty1,require=dstTy} (DstTypeMismatch dst)
          val (err6, ty2) = checkOperand context op1
          val err7 = eqTy {actual=ty2,require=op1Ty} (OperandTypeMismatch op1)
          val (err8, ty3) = checkOperand context op2
          val err9 = eqTy {actual=ty3,require=op2Ty} (OperandTypeMismatch op2)
        in
          (err1 @ err2 @ err3 @ err4 @ err5 @ err6 @ err7 @ err8 @ err9,
           dstEnv dst)
        end
      | R.DIVMOD ({div=(divTy,ddiv), mod=(modTy,dmod)},
                  (op1Ty,op1), (op2Ty,op2)) =>
        let
          val err1 = checkTy context divTy
          val err2 = checkTy context modTy
          val err3 = checkTy context op1Ty
          val err4 = checkTy context op2Ty
          val (err5, ty1) = checkDef context ddiv
          val err6 = eqTy {actual=ty1,require=divTy} (DstTypeMismatch ddiv)
          val (err7, ty2) = checkDef context dmod
          val err8 = eqTy {actual=ty2,require=modTy} (DstTypeMismatch dmod)
          val (err9, ty3) = checkOperand context op1
          val err10 = eqTy {actual=ty3,require=op1Ty} (OperandTypeMismatch op1)
          val (err11, ty4) = checkOperand context op2
          val err12 = eqTy {actual=ty4,require=op2Ty} (OperandTypeMismatch op2)
        in
          (err1 @ err2 @ err3 @ err4 @ err5 @ err6 @ err7 @ err8 @ err9
           @ err10 @ err11 @ err12,
           unionEnv (dstEnv ddiv, dstEnv dmod))
        end
      | R.AND (ty, dst, op1, op2) => checkInsn3 context (ty, dst, op1, op2)
      | R.OR (ty, dst, op1, op2) => checkInsn3 context (ty, dst, op1, op2)
      | R.XOR (ty, dst, op1, op2) => checkInsn3 context (ty, dst, op1, op2)
      | R.LSHIFT (ty, dst, op1, op2) => checkShift context (ty, dst, op1, op2)
      | R.RSHIFT (ty, dst, op1, op2) => checkShift context (ty, dst, op1, op2)
      | R.ARSHIFT (ty, dst, op1, op2) => checkShift context (ty, dst, op1, op2)
      | R.TEST_SUB (ty, op1, op2) => checkTest context (ty, op1, op2)
      | R.TEST_AND (ty, op1, op2) => checkTest context (ty, op1, op2)
      | R.TEST_LABEL (pty, op1, l) =>
        let
          val (err1, ty1) = checkOperand context op1
          val err2 = eqTy {actual=ty1, require=R.Ptr pty}
                          (OperandTypeMismatch op1)
          val (err3, pty2) = checkLabelRef context l
          val err4 = eqTy {actual=R.Ptr pty2, require=R.Ptr pty}
                          (LabelTypeMismatch l)
        in
          (err1 @ err2 @ err3 @ err4, emptyEnv)
        end
      | R.NOT (ty, dst, op1) => checkInsn2 context (ty, dst, op1)
      | R.NEG (ty, dst, op1) => checkInsn2 context (ty, dst, op1)
      | R.SET (cc1, ty, dst, {test}) =>
        let
          val (err1, env1) = checkInsn context test
          val (err2, ty1) = checkDef context dst
          val err3 = eqTy {actual=ty1, require=ty} (DstTypeMismatch dst)
        in
          (err1 @ err2 @ err3, dstEnv dst)
        end
      | R.LOAD_FP dst =>
        let
          val (err1, ty1) = checkDef context dst
          val err2 = eqTy {actual=ty1, require=R.Ptr R.Void}
                          (DstTypeMismatch dst)
        in
          (err1 @ err2, dstEnv dst)
        end
      | R.LOAD_SP dst =>
        let
          val (err1, ty1) = checkDef context dst
          val err2 = eqTy {actual=ty1, require=R.Ptr R.Void}
                          (DstTypeMismatch dst)
        in
          (err1 @ err2, dstEnv dst)
        end
      | R.LOAD_PREV_FP dst =>
        let
          val (err1, ty1) = checkDef context dst
          val err2 = eqTy {actual=ty1, require=R.Ptr R.Void}
                          (DstTypeMismatch dst)
        in
          (err1 @ err2, dstEnv dst)
        end
      | R.LOAD_RETADDR dst =>
        let
          val (err1, ty1) = checkDef context dst
          val err2 = eqTy {actual=ty1, require=R.Ptr R.Code}
                          (DstTypeMismatch dst)
        in
          (err1 @ err2, dstEnv dst)
        end
      | R.LOADABSADDR {ty, dst, symbol, thunk} =>
        let
          val (err1, ty1) = checkDef context dst
          val err2 = eqTy {actual=ty1, require=ty} (DstTypeMismatch dst)
          val (err3, pty2) = checkLabelRef context symbol
          val err4 = eqTy {actual=R.Ptr pty2, require=ty}
                          (LabelTypeMismatch symbol)
          val err5 =
              case thunk of
                NONE => nil
              | SOME thunk =>
                case SEnv.find (#symbolEnv context, thunk) of
                  NONE => [UndefinedSymbol thunk]
                | SOME (_,{ptrTy=R.Code,...}) => nil
                | SOME (_,{ptrTy,...}) => [SymbolTypeMismatch
                                             (thunk, {actual=ptrTy,
                                                      require=R.Code})]
        in
          (err1 @ err2 @ err3 @ err4 @ err5, dstEnv dst)
        end
      | R.X86 (R.X86LEAINT (ty, dst, {base, shift, offset, disp})) =>
        let
          val err1 = checkIntTy ty TypeMustBeInt
          val (err2, ty1) = checkDef context dst
          val err3 = eqTy {actual=ty1, require=ty} (DstTypeMismatch dst)
          val (err4, ty2) = checkVar context base
          val err5 = eqTy {actual=ty2, require=ty} (VariableTypeMismatch base)
          val (err6, ty3) = checkVar context offset
          val err7 = eqTy {actual=ty3, require=ty} (VariableTypeMismatch offset)
          val (err8, ty4) = checkConst context disp
          val err9 = eqTy {actual=ty4, require=ty} (ConstTypeMismatch disp)
        in
          (err1 @ err2 @ err3 @ err4 @ err5 @ err6 @ err7 @ err8 @ err9,
           dstEnv dst)
        end
      | R.X86 (R.X86FLD (ty, mem)) => checkX86FLD context (ty, mem)
      | R.X86 (R.X86FLD_ST st) => (nil, emptyEnv)
      | R.X86 (R.X86FST (ty, mem)) => checkX86FST context (ty, mem)
      | R.X86 (R.X86FSTP (ty, mem)) => checkX86FST context (ty, mem)
      | R.X86 (R.X86FSTP_ST st) => (nil, emptyEnv)
      | R.X86 (R.X86FADD (ty, mem)) => checkX86FLD context (ty, mem)
      | R.X86 (R.X86FADD_ST (st1, st2)) => (nil, emptyEnv)
      | R.X86 (R.X86FADDP st1) => (nil, emptyEnv)
      | R.X86 (R.X86FSUB (ty, mem)) => checkX86FLD context (ty, mem)
      | R.X86 (R.X86FSUB_ST (st1, st2)) => (nil, emptyEnv)
      | R.X86 (R.X86FSUBP st1) => (nil, emptyEnv)
      | R.X86 (R.X86FSUBR (ty, mem)) => checkX86FLD context (ty, mem)
      | R.X86 (R.X86FSUBR_ST (st1, st2)) => (nil, emptyEnv)
      | R.X86 (R.X86FSUBRP st1) => (nil, emptyEnv)
      | R.X86 (R.X86FMUL (ty, mem)) => checkX86FLD context (ty, mem)
      | R.X86 (R.X86FMUL_ST (st1, st2)) => (nil, emptyEnv)
      | R.X86 (R.X86FMULP st1) => (nil, emptyEnv)
      | R.X86 (R.X86FDIV (ty, mem)) => checkX86FLD context (ty, mem)
      | R.X86 (R.X86FDIV_ST (st1, st2)) => (nil, emptyEnv)
      | R.X86 (R.X86FDIVP st1) => (nil, emptyEnv)
      | R.X86 (R.X86FDIVR (ty, mem)) => checkX86FLD context (ty, mem)
      | R.X86 (R.X86FDIVR_ST (st1, st2)) => (nil, emptyEnv)
      | R.X86 (R.X86FDIVRP st1) => (nil, emptyEnv)
      | R.X86 (R.X86FABS) => (nil, emptyEnv)
      | R.X86 (R.X86FCHS) => (nil, emptyEnv)
      | R.X86 (R.X86FFREE st) => (nil, emptyEnv)
      | R.X86 (R.X86FXCH st) => (nil, emptyEnv)
      | R.X86 (R.X86FUCOM st) => (nil, emptyEnv)
      | R.X86 (R.X86FUCOMP st) => (nil, emptyEnv)
      | R.X86 R.X86FUCOMPP => (nil, emptyEnv)
      | R.X86 (R.X86FSW_GT {clob}) => (checkClob context clob, emptyEnv)
      | R.X86 (R.X86FSW_GE {clob}) => (checkClob context clob, emptyEnv)
      | R.X86 (R.X86FSW_EQ {clob}) => (checkClob context clob, emptyEnv)
      | R.X86 (R.X86FLDCW mem) =>
        let
          val (err1, _) = checkMem context (R.Int16 R.U, mem)
        in
          (err1, emptyEnv)
        end
      | R.X86 (R.X86FNSTCW mem) =>
        let
          val (err1, _) = checkMem context (R.Int16 R.U, mem)
        in
          (err1, dstEnv (R.MEM (R.Int16 R.U, mem)))
        end
      | R.X86 R.X86FWAIT => (nil, emptyEnv)
      | R.X86 R.X86FNCLEX => (nil, emptyEnv)

  fun checkLast (context:context) last =
      case last of
        R.HANDLE (insn, {nextLabel, handler}) =>
        let
          val (err1, env1) = checkInsn context insn
          val context = extendContext (context, env1)
          val err2 = checkSucc context nextLabel
          val err3 = checkHandler context handler
        in
          (err1 @ err2 @ err3, context)
        end
      | R.CJUMP {test, cc, thenLabel, elseLabel} =>
        let
          val (err1, env1) = checkInsn context test
          val context = extendContext (context, env1)
          val err2 = checkSucc context thenLabel
          val err3 = checkSucc context elseLabel
        in
          (err1 @ err2 @ err3, context)
        end
      | R.CALL {callTo, returnTo, handler, defs, uses,
                needStabilize, postFrameAdjust} =>
        let
          val (err1, pty1) = checkAddr context callTo
          val err2 = checkPtrTy {require=R.Code, actual=pty1}
                                (AddrTypeMismatch callTo)
          val err3 = checkDefs context defs
          val err4 = checkUses context uses
          val context = extendContext (context, varEnv defs)
          val err5 = checkSucc context returnTo
          val err6 = checkHandler context handler
        in
          (err1 @ err2 @ err3 @ err4 @ err5 @ err6, context)
        end
      | R.JUMP {jumpTo, destinations} =>
        let
          val (err1, pty1) = checkAddr context jumpTo
          val err2 = checkPtrTy {require=R.Code, actual=pty1}
                                (AddrTypeMismatch jumpTo)
          val err3 = foldr (fn (l,z) => checkSucc context l @ z)
                           nil destinations
        in
          (err1 @ err2 @ err3, context)
        end
      | R.UNWIND_JUMP {jumpTo, sp, fp, uses, handler} =>
        let
          val (err1, pty1) = checkAddr context jumpTo
          val err2 = checkPtrTy {require=R.Code, actual=pty1}
                                (AddrTypeMismatch jumpTo)
          val (err3, ty1) = checkOperand context sp
          val err4 = eqTy {actual=ty1, require=R.Ptr R.Void}
                          (OperandTypeMismatch sp)
          val (err5, ty2) = checkOperand context fp
          val err6 = eqTy {actual=ty2, require=R.Ptr R.Void}
                          (OperandTypeMismatch fp)
          val err7 = checkUses context uses
          val err8 = checkHandler context handler
        in
          (err1 @ err2 @ err3 @ err4 @ err5 @ err6 @ err7 @ err8, context)
        end
      | R.TAILCALL_JUMP {preFrameSize, jumpTo, uses} =>
        let
          val (err1, pty1) = checkAddr context jumpTo
          val err2 = checkPtrTy {require=R.Code, actual=pty1}
                                (AddrTypeMismatch jumpTo)
          val err3 = checkUses context uses
          val preSize = #preFrameSize (#cluster context)
          val err4 =
              if preFrameSize <= preSize
              then nil
              else [PreFrameExceeded {actual = preFrameSize, limit = preSize}]
        in
          (err1 @ err2 @ err3 @ err4, context)
        end
      | R.RETURN {preFrameSize, stubOptions, uses} =>
        let
          val err1 = checkUses context uses
          val preSize = #preFrameSize (#cluster context)
          val err2 =
              if preFrameSize <= preSize
              then nil
              else [PreFrameExceeded {actual = preFrameSize, limit = preSize}]
        in
          (err1 @ err2, context)
        end
      | R.EXIT => ([ExitFound], context)

  fun checkPtrStability liveOut =
      let
        val vars = RTLUtils.Var.filter
                     (fn {ty=R.Ptr R.Data,...} => true | _ => false)
                     liveOut
      in
        if RTLUtils.Var.isEmpty vars
        then nil
        else map NotStabilized (varList vars)
      end

  fun wrapErrorsInBlock first errs =
      let
        val label =
            case first of
              R.BEGIN {label, align, loc} => SOME label
            | R.CODEENTRY {label, symbol, scope, align, preFrameSize,
                           stubOptions, defs, loc} => SOME label
            | R.HANDLERENTRY {label, align, defs, loc} => SOME label
            | R.ENTER => NONE
      in
        case label of
          NONE => errs
        | SOME l => ifcons errs (ErrorInBlock l)
      end

  fun checkStabilityFirst ({liveIn, liveOut}:RTLLiveness.liveness) first =
      case first of
        R.BEGIN {label, align, loc} => nil
      | R.CODEENTRY {label, symbol, scope, align, preFrameSize,
                     stubOptions, defs, loc} => nil
      | R.HANDLERENTRY {label, align, defs, loc} =>
        if RTLUtils.Var.isEmpty (minus (liveOut, defs))
        then nil
        else map NotStabilized (varList liveOut)
      | R.ENTER => nil

  fun checkStabilityInsn ({liveIn, liveOut}:RTLLiveness.liveness) insn =
      case insn of
        R.NOP => nil
      | R.STABILIZE => checkPtrStability liveIn
      | R.COMPUTE_FRAME {uses, clobs} => nil
      | R.REQUEST_SLOT slot => nil
      | R.REQUIRE_SLOT slot => nil
      | R.USE vars => nil
      | R.MOVE (ty, dst, op1) => nil
      | R.MOVEADDR (ptrTy, dst, addr) => nil
      | R.COPY {ty, dst, src, clobs} => nil
      | R.MLOAD {ty, dst, srcAddr, size, defs, clobs} => nil
      | R.MSTORE {ty, dstAddr, src, size, global, defs, clobs} => nil
      | R.EXT8TO32 (sign, dst, op1) => nil
      | R.EXT16TO32 (sign, dst, op1) => nil
      | R.EXT32TO64 (sign, dst, op1) => nil
      | R.DOWN32TO8 (sign, dst, op1) => nil
      | R.DOWN32TO16 (sign, dst, op1) => nil
      | R.ADD (ty, dst, op1, op2) => nil
      | R.SUB (ty, dst, op1, op2) => nil
      | R.MUL ((ty, dst), (ty2, op1), (ty3, op2)) => nil
      | R.DIVMOD ({div, mod}, (ty3, op1), (ty4, op2)) => nil
      | R.AND (ty, dst, op1, op2) => nil
      | R.OR (ty, dst, op1, op2) => nil
      | R.XOR (ty, dst, op1, op2) => nil
      | R.LSHIFT (ty, dst, op1, op2) => nil
      | R.RSHIFT (ty, dst, op1, op2) => nil
      | R.ARSHIFT (ty, dst, op1, op2) => nil
      | R.TEST_SUB (ty, op1, op2) => nil
      | R.TEST_AND (ty, op1, op2) => nil
      | R.TEST_LABEL (ptrTy, op1, label) => nil
      | R.NOT (ty, dst, op1) => nil
      | R.NEG (ty, dst, op1) => nil
      | R.SET (cc1, ty, dst, {test}) => nil
      | R.LOAD_FP dst => nil
      | R.LOAD_SP dst => nil
      | R.LOAD_PREV_FP dst => nil
      | R.LOAD_RETADDR dst => nil
      | R.LOADABSADDR {ty, dst, symbol, thunk} => nil
      | R.X86 (R.X86LEAINT (ty, dst, {base, shift, offset, disp})) => nil
      | R.X86 (R.X86FLD (ty, mem)) => nil
      | R.X86 (R.X86FLD_ST x86st1) => nil
      | R.X86 (R.X86FST (ty, mem)) => nil
      | R.X86 (R.X86FSTP (ty, mem)) => nil
      | R.X86 (R.X86FSTP_ST x86st1) => nil
      | R.X86 (R.X86FADD (ty, mem)) => nil
      | R.X86 (R.X86FADD_ST (x86st1, x86st2)) => nil
      | R.X86 (R.X86FADDP x86st1) => nil
      | R.X86 (R.X86FSUB (ty, mem)) => nil
      | R.X86 (R.X86FSUB_ST (x86st1, x86st2)) => nil
      | R.X86 (R.X86FSUBP x86st1) => nil
      | R.X86 (R.X86FSUBR (ty, mem)) => nil
      | R.X86 (R.X86FSUBR_ST (x86st1, x86st2)) => nil
      | R.X86 (R.X86FSUBRP x86st1) => nil
      | R.X86 (R.X86FMUL (ty, mem)) => nil
      | R.X86 (R.X86FMUL_ST (x86st1, x86st2)) => nil
      | R.X86 (R.X86FMULP x86st1) => nil
      | R.X86 (R.X86FDIV (ty, mem)) => nil
      | R.X86 (R.X86FDIV_ST (x86st1, x86st2)) => nil
      | R.X86 (R.X86FDIVP x86st1) => nil
      | R.X86 (R.X86FDIVR (ty, mem)) => nil
      | R.X86 (R.X86FDIVR_ST (x86st1, x86st2)) => nil
      | R.X86 (R.X86FDIVRP x86st1) => nil
      | R.X86 R.X86FABS => nil
      | R.X86 R.X86FCHS => nil
      | R.X86 (R.X86FFREE x86st1) => nil
      | R.X86 (R.X86FXCH x86st1) => nil
      | R.X86 (R.X86FUCOM x86st1) => nil
      | R.X86 (R.X86FUCOMP x86st1) => nil
      | R.X86 R.X86FUCOMPP => nil
      | R.X86 (R.X86FSW_GT {clob}) => nil
      | R.X86 (R.X86FSW_GE {clob}) => nil
      | R.X86 (R.X86FSW_EQ {clob}) => nil
      | R.X86 (R.X86FLDCW mem) => nil
      | R.X86 (R.X86FNSTCW mem) => nil
      | R.X86 R.X86FWAIT => nil
      | R.X86 R.X86FNCLEX => nil

  fun checkStabilityLast ({liveIn, liveOut}:RTLLiveness.liveness) last =
      case last of
        R.HANDLE (insn, {nextLabel, handler}) => nil
      | R.CJUMP {test, cc, thenLabel, elseLabel} => nil
      | R.CALL {callTo, returnTo, handler, defs, uses, needStabilize,
                postFrameAdjust} =>
        checkPtrStability (minus (liveOut, defs))
      | R.JUMP {jumpTo, destinations} => nil
      | R.UNWIND_JUMP {jumpTo, sp, fp, uses, handler} => nil
      | R.TAILCALL_JUMP {preFrameSize, jumpTo, uses} => nil
      | R.RETURN {preFrameSize, stubOptions, uses} => nil
      | R.EXIT => nil

  fun checkInsnList (context:context) (insn::insns) =
      let
        val (err, env1) = checkInsn context insn
        val err1 = ifcons err (ErrorAtMiddle insn)
        val context = extendContext (context, env1)
        val (err2, context) = checkInsnList context insns
      in
        (err1 @ err2, context)
      end
    | checkInsnList (context:context) nil = (nil, context)

  fun checkBlock (context:context) (label, (first, mid, last):R.block) =
      let
        val (err, env) = checkFirst context (label, first)
        val err1 = ifcons err (ErrorAtFirst first)
        val context = extendContext (context, env)

        val (err2, context) = checkInsnList context mid

        val (err, context) = checkLast context last
        val err3 = ifcons err (ErrorAtLast last)

        val err4 =
            RTLUtils.Var.fold
              (fn (v as {id, ty}, z) =>
                  case RTLUtils.Var.find (#vars (#env context), id) of
                    NONE => VarNotFoundInLiveOut v :: z
                  | SOME {ty=ty2,...} =>
                    eqTy {actual=ty, require=ty2}
                         (fn _ => TypeMismatchWithLiveOut
                                    (v,{actual=ty2,liveOut=ty})) @ z)
              nil
              (#vars (#liveOut context))

        val err5 =
            RTLUtils.Slot.fold
              (fn (v as {id, format}, z) =>
                  case RTLUtils.Slot.find (#slots (#env context), id) of
                    NONE => SlotNotFoundInLiveOut v :: z
                  | SOME _ => nil)
              nil
              (#slots (#liveOut context))



      in
        err1 @ err2 @ err3 @ err4
      end

  fun checkCluster {symbolEnv, checkStability}
                   ({clusterId, frameBitmap, baseLabel, body,
                     preFrameSize, postFrameSize, loc}:R.cluster) =
      let
        val livenessGraph = RTLLiveness.liveness body
        val err1 =
            if checkStability
            then (op @)
                   (RTLLiveness.foldBackward
                      (fn (RTLEdit.FIRST first, live, (e1, e2)) =>
                          let
                            val errs = checkStabilityFirst live first
                          in
                            (nil, wrapErrorsInBlock first (errs @ e1) @ e2)
                          end
                        | (RTLEdit.MIDDLE insn, live, (e1, e2)) =>
                          (checkStabilityInsn live insn @ e1, e2)
                        | (RTLEdit.LAST last, live, (e1, e2)) =>
                          (checkStabilityLast live last @ e1, e2))
                      (nil, nil)
                      livenessGraph)
            else nil

        val liveness = RTLEdit.annotations livenessGraph
        val livenessSlot = RTLLiveness.livenessSlot body

        val liveness =
            R.LabelMap.mapi
              (fn (label, liveVars) =>
                  let
                    val focus = RTLEdit.focusBlock (livenessSlot, label)
                  in
                    {vars = liveVars, slots = RTLEdit.annotation focus}
                  end)
              liveness

        val cluster =
            {
              frameBitmap = frameBitmap,
              body = body,
              baseLabel = baseLabel,
              preFrameSize = preFrameSize,
              postFrameSize = postFrameSize
            }

        val err2 =
            R.LabelMap.foldri
              (fn (label, block, z) =>
                  let
                    val {vars, slots} = R.LabelMap.lookup (liveness, label)
                    val context =
                        {
                          env = {vars = #liveIn vars, slots = #liveIn slots},
                          liveOut = {vars = #liveOut vars,
                                     slots = #liveOut slots},
                          cluster = cluster,
                          symbolEnv = symbolEnv,
                          liveness = liveness
                        } : context
                    val err = checkBlock context (label, block)
                  in
                    ifcons err (ErrorInBlock label) @ z
                  end)
              nil
              body

        val err = err1 @ err2
      in
        ifcons err (ErrorInCluster clusterId)
      end

  fun dummyContext {symbolEnv, checkStability} =
      {
        env = emptyEnv,
        liveOut = emptyEnv,
        cluster = {frameBitmap = nil,
                   body = R.emptyGraph,
                   baseLabel = NONE,
                   preFrameSize = 0,
                   postFrameSize = 0},
        symbolEnv = symbolEnv,
        liveness = R.LabelMap.empty
      } : context

  fun checkDatum context datum =
      case datum of
        R.CONST_DATA const => #1 (checkConst context const)
      | R.LABELREF_DATA label => #1 (checkLabelRef context label)
      | R.BINARY_DATA wordList => nil
      | R.ASCII_DATA s => nil
      | R.SPACE_DATA {size} => nil

  fun checkDatumList context data =
      foldr (fn (x,z) => checkDatum context x @ z) nil data

  fun checkData context ({scope, symbol, aliases, ptrTy, section, prefix,
                          align, data, prefixSize, dataSize}:R.data) =
      let
        val err1 = checkDatumList context prefix
        val err2 = checkDatumList context data
      in
        err1 @ err2
      end

  fun unifySymbolDef (symbol, (STRONG, _:symbolDef), (STRONG, _:symbolDef)) =
      ([DoubledSymbol symbol], NONE)
    | unifySymbolDef (symbol, (WEAK, def1), (WEAK, def2)) =
      ([DoubledSymbol symbol], NONE)
    | unifySymbolDef (symbol, def1 as (WEAK, _), def2 as (STRONG, _)) =
      unifySymbolDef (symbol, def2, def1)
    | unifySymbolDef (symbol, (STRONG, def1), (WEAK, def2)) =
      let
        val err1 =
            case #scope def1 of
              R.LOCAL => [SymbolScopeMismatch (symbol, {actual = #scope def2,
                                                        require = R.GLOBAL})]
            | R.GLOBAL => nil
        val err2 =
            case #scope def2 of
              R.LOCAL => [SymbolScopeMismatch (symbol, {actual = #scope def2,
                                                        require = R.GLOBAL})]
            | R.GLOBAL => nil
        val err3 =
            if #ptrTy def1 = #ptrTy def2
            then [SymbolTypeMismatch (symbol, {actual = #ptrTy def2,
                                               require = #ptrTy def1})]
            else nil
      in
        (err1 @ err2 @ err3,
         SOME (STRONG,
               {haveLinkEntry = #haveLinkEntry def1 orelse #haveLinkEntry def2,
                haveLinkStub = #haveLinkStub def1 orelse #haveLinkStub def2,
                scope = #scope def1,
                ptrTy = #ptrTy def1}))
      end

  fun unionSymbolEnv (env1:symbolEnv, env2:symbolEnv) =
      SEnv.foldri
        (fn (symbol, def, (err, env1:symbolEnv)) =>
            case (SEnv.find (env1, symbol), def) of
              (NONE, _) => (nil, SEnv.insert (env1, symbol, def))
            | (SOME def1, def2) =>
              case unifySymbolDef (symbol, def1, def2) of
                (err2, NONE) => (err2 @ err, env1)
              | (err2, SOME def) =>
                (err2 @ err, SEnv.insert (env1, symbol, def)))
        (nil, env1)
        env2

  fun symbolDef topdecl =
      case topdecl of
        R.TOPLEVEL {symbol, toplevelEntry, nextToplevel,
                    smlPushHandlerLabel, smlPopHandlerLabel} =>
        (nil,
         SEnv.singleton (symbol,
                         (STRONG, {haveLinkEntry = false, haveLinkStub = false,
                                   scope = R.GLOBAL, ptrTy = R.Code})))
      | R.CLUSTER {body, ...} =>
        R.LabelMap.foldl
          (fn ((R.CODEENTRY {symbol, scope, ...}, _, _), (err, env)) =>
              if SEnv.inDomain (env, symbol)
              then (DoubledSymbol symbol :: err, env)
              else (err, SEnv.insert (env, symbol,
                                      (STRONG, {haveLinkEntry = false,
                                                haveLinkStub = false,
                                                scope = scope,
                                                ptrTy = R.Code})))
            | (_, z) => z)
          (nil, SEnv.empty)
          body
      | R.DATA {scope, symbol, ptrTy, ...} =>
        (nil,
         SEnv.singleton (symbol,
                         (STRONG, {haveLinkEntry = false, haveLinkStub = false,
                                   scope = scope, ptrTy = ptrTy})))
      | R.BSS {scope, symbol, align, size} =>
        (nil,
         SEnv.singleton (symbol,
                         (STRONG, {haveLinkEntry = false, haveLinkStub = false,
                                   scope = scope, ptrTy = R.Void})))
      | R.X86GET_PC_THUNK_BX symbol =>
        (nil,
         SEnv.singleton (symbol,
                         (STRONG, {haveLinkEntry = false, haveLinkStub = false,
                                   scope = R.LOCAL, ptrTy = R.Code})))
      | R.EXTERN {symbol, linkStub, linkEntry, ptrTy} =>
        (nil,
         SEnv.singleton (symbol,
                         (WEAK, {haveLinkEntry = linkEntry,
                                 haveLinkStub = linkStub,
                                 scope = R.GLOBAL,
                                 ptrTy = ptrTy})))

  fun makeSymbolEnv program =
      foldl
        (fn (topdecl, (err, env)) =>
            let
              val (err1, env1) = symbolDef topdecl
              val (err2, env2) = unionSymbolEnv (env, env1)
            in
              (err1 @ err2 @ err, env2)
            end)
        (nil, SEnv.empty)
        program

  fun checkTopdecl (context as {symbolEnv, checkStability}) topdecl =
      case topdecl of
        R.TOPLEVEL {symbol, toplevelEntry, nextToplevel,
                    smlPushHandlerLabel, smlPopHandlerLabel} =>
        let
          val context = dummyContext context
          val (err1, pty1) = checkLabelRef context smlPushHandlerLabel
          val err2 = eqTy {require=R.Ptr R.Code, actual=R.Ptr pty1}
                          (LabelTypeMismatch smlPushHandlerLabel)
          val (err3, pty2) = checkLabelRef context smlPopHandlerLabel
          val err4 = eqTy {require=R.Ptr R.Code, actual=R.Ptr pty2}
                          (LabelTypeMismatch smlPopHandlerLabel)
        in
          err1 @ err2 @ err3 @ err4
        end
      | R.CLUSTER (cluster as {clusterId,...}) =>
        checkCluster context cluster
      | R.DATA (data as {symbol,...}) =>
        let
          val context = dummyContext context
        in
          ifcons (checkData context data) (ErrorInData symbol)
        end
      | R.BSS _ => nil
      | R.X86GET_PC_THUNK_BX _ => nil
      | R.EXTERN _ => nil

  fun check {checkStability} program =
      let
        val (err1, symbolEnv) = makeSymbolEnv program
        val context = {symbolEnv = symbolEnv, checkStability = checkStability}
      in
        (symbolEnv, foldr (fn (x,z) => checkTopdecl context x @ z) nil program)
      end

end
