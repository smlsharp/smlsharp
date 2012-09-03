structure RTLTypeCheck : sig

  val check : {checkStability: bool}
              -> RTL.program
              -> RTLTypeCheckError.err list

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

  fun minus (set, vars) =
      RTLUtils.Var.setMinus (set, RTLUtils.Var.fromList vars)

  val errors = ref nil : RTLTypeCheckError.err list ref
  fun ERROR x = errors := x :: !errors
  fun WRAP f =
      let
        val prevErrors = !errors
      in
        errors := nil;
        fn x => (errors := (case !errors of
                              nil => prevErrors
                            | errs => f (rev errs) :: prevErrors);
                 x)
      end

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
        vars: RTL.var VarID.Map.map,
        slots: RTL.slot VarID.Map.map
      }

  type context =
      {
        env: env,
        liveOut: {vars: RTLUtils.Var.set, slots: RTLUtils.Slot.set},
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

  val emptyEnv = 
      {vars = VarID.Map.empty, slots = VarID.Map.empty} : env

  fun envFromList getId elems =
      foldl (fn (i,map) => VarID.Map.insert (map, getId i, i))
            VarID.Map.empty
            elems

  fun varEnv vars =
      {vars = envFromList #id vars, slots = VarID.Map.empty} : env
  fun slotEnv slots =
      {vars = VarID.Map.empty, slots = envFromList #id slots} : env

  fun setToEnv (varSet, slotSet) =
      {vars = RTLUtils.Var.fold
                (fn (var,map) => VarID.Map.insert (map, #id var, var))
                VarID.Map.empty
                varSet,
       slots = RTLUtils.Slot.fold
                 (fn (slot,map) => VarID.Map.insert (map, #id slot, slot))
                 VarID.Map.empty
                 slotSet} : env

  fun extendEnv ({vars=v1,slots=s1}:env, {vars=v2,slots=s2}:env) =
      {vars = VarID.Map.unionWith #2 (v1, v2),
       slots = VarID.Map.unionWith #2 (s1, s2)} : env

  fun unionEnv ({vars=v1,slots=s1}:env, {vars=v2,slots=s2}:env) =
      {
        vars = VarID.Map.unionWith
                 (fn (x,y) => (ERROR (DuplicateVariable (x, y)); y))
                 (v1, v2),
        slots = VarID.Map.unionWith
                  (fn (x,y) => (ERROR (DuplicateSlot (x, y)); y))
                  (s1, s2)
      } : env

  fun dstEnv dst =
      case dst of
        R.REG v => varEnv [v]
      | R.COUPLE (_, {hi, lo}) => unionEnv (dstEnv hi, dstEnv lo)
      | R.MEM (_, R.SLOT slot) => slotEnv [slot]
      | R.MEM (_, R.ADDR _) => emptyEnv

  fun extendContext ({env, liveOut, cluster, symbolEnv, liveness}:context,
                     env2) =
      {env = extendEnv (env, env2),
       liveOut = liveOut,
       cluster = cluster,
       symbolEnv = symbolEnv,
       liveness = liveness} : context


  fun eqTy (tys as {actual:R.ty, require:R.ty}) f =
      if actual = require then () else ERROR (f tys)

  fun checkTid (context:context) tid =
      if List.exists
           (fn {source,bits} =>
               List.exists (fn SOME t => t = tid | NONE => false) bits)
           (#frameBitmap (#cluster context))
      then ()
      else ERROR (UndefinedGenericTid tid)

  fun checkTy (context:context) ty =
      case ty of
        R.Int8 s => ()
      | R.Int16 s => ()
      | R.Int32 s => ()
      | R.Int64 s => ()
      | R.Real32 => ()
      | R.Real64 => ()
      | R.Real80 => ()
      | R.Ptr ptrTy => ()
      | R.PtrDiff _ => ()
      | R.NoType => ()
      | R.Generic tid => checkTid context tid

  fun checkIntTy ty f =
      case ty of
        R.Int8 s => ()
      | R.Int16 s => ()
      | R.Int32 s => ()
      | R.Int64 s => ()
      | R.Real32 => ERROR (f {actual=ty})
      | R.Real64 => ERROR (f {actual=ty})
      | R.Real80 => ERROR (f {actual=ty})
      | R.Ptr _ => ERROR (f {actual=ty})
      | R.PtrDiff _ => ()
      | R.NoType => ERROR (f {actual=ty})
      | R.Generic tid => ERROR (f {actual=ty})

  fun checkPtrTy (tys as {actual:R.ptrTy, require:R.ptrTy}) f =
      if actual = require then nil else [f tys]

  fun checkAnyPtrTy ty f =
      case ty of
        R.Int8 s => (ERROR (f {actual=ty}); R.Void)
      | R.Int16 s => (ERROR (f {actual=ty}); R.Void)
      | R.Int32 s => (ERROR (f {actual=ty}); R.Void)
      | R.Int64 s => (ERROR (f {actual=ty}); R.Void)
      | R.Real32 => (ERROR (f {actual=ty}); R.Void)
      | R.Real64 => (ERROR (f {actual=ty}); R.Void)
      | R.Real80 => (ERROR (f {actual=ty}); R.Void)
      | R.Ptr pty => pty
      | R.PtrDiff _ => (ERROR (f {actual=ty}); R.Void)
      | R.NoType => (ERROR (f {actual=ty}); R.Void)
      | R.Generic tid => (ERROR (f {actual=ty}); R.Void)

  fun checkLabelRef (context:context) label =
      case label of
        R.NULL ptrTy => ptrTy
      | R.CURRENT_POSITION => R.Code
      | R.ELF_GOT => R.Void
      | R.LABELCAST (ptrTy, label) => (checkLabelRef context label; ptrTy)
      | R.LABEL l =>
        (
          case R.LabelMap.find (#body (#cluster context), l) of
            SOME _ => ()
          | NONE => if (case #baseLabel (#cluster context) of
                          NONE => false
                        | SOME baseLabel => VarID.eq (baseLabel, l))
                    then ()
                    else ERROR (UndefinedLabel l);
          R.Code
        )
      | R.SYMBOL (ptrTy, scope, symbol) =>
        (
          case SEnv.find (#symbolEnv context, symbol) of
            NONE => ERROR (UndefinedSymbol symbol)
          | SOME (_, {scope=scope2, ptrTy=ptrTy2, ...}) =>
            (
              if scope = scope2 then ()
              else ERROR (SymbolScopeMismatch
                            (symbol, {actual=scope, require=scope2}));
              if ptrTy = ptrTy2 then ()
              else ERROR (SymbolTypeMismatch2
                            (symbol, {actual=ptrTy,require=ptrTy2}))
            );
          ptrTy
        )
      | R.LINK_ENTRY symbol =>
        (
          case SEnv.find (#symbolEnv context, symbol) of
            NONE => ERROR (UndefinedSymbol symbol)
          | SOME (_, {haveLinkEntry=true,...}) => ()
          | SOME (_, {haveLinkEntry=false,...}) =>
            ERROR (SymbolLinkEntryNotFound label);
          R.Void
        )
      | R.LINK_STUB symbol =>
        (
          case SEnv.find (#symbolEnv context, symbol) of
            NONE => ERROR (UndefinedSymbol symbol)
          | SOME (_, {haveLinkStub=true,...}) => ()
          | SOME (_, {haveLinkStub=false,...}) =>
            ERROR (SymbolLinkStubNotFound label);
          R.Code
        )

  fun checkConst (context:context) const =
      case const of
        R.SYMOFFSET {label, base} =>
        let
          val pty1 = checkLabelRef context label
          val pty2 = checkLabelRef context base
          val _ = if pty1 = pty2 then ()
                  else ERROR (PointerTypeMismatch (const, pty1, pty2))
        in
          R.PtrDiff pty1
        end
(*
      | R.INT64 _ => R.Int64 R.S
      | R.UINT64 _ => R.Int64 R.U
*)
      | R.INT32 _ => R.Int32 R.S
      | R.UINT32 _ => R.Int32 R.U
      | R.INT16 _ => R.Int16 R.S
      | R.UINT16 _ => R.Int16 R.U
      | R.INT8 _ => R.Int8 R.S
      | R.UINT8 _ => R.Int8 R.U
      | R.REAL32 _ => R.Real32
      | R.REAL64 _ => R.Real64
      | R.REAL64HI _ => R.NoType
      | R.REAL64LO _ => R.NoType

  fun checkFormat (context:context) ({size,align,tag}:R.format) =
      case tag of
        R.BOXED => ()
      | R.UNBOXED => ()
      | R.GENERIC tid => checkTid context tid

  fun checkSlot (context:context) (slot as {id,format}:R.slot) =
      (
        checkFormat context format;
        case VarID.Map.find (#slots (#env context), id) of
          NONE => ERROR (UndefinedSlot slot)
        | SOME {format=format2,...} =>
          if format = format2 then ()
          else ERROR (SlotFormatMismatch
                        (slot, {actual=format,require=format2}))
      )

  fun checkVar (context:context) (var as {id, ty}:R.var) =
      (
        checkTy context ty;
        case VarID.Map.find (#vars (#env context), id) of
          NONE => ERROR (UndefinedVariable var)
        | SOME {ty=ty2,...} =>
          eqTy {actual=ty, require=ty2} (VariableTypeMismatch var);
        ty
      )

  fun checkDefs context varList =
      app (fn {ty,...}:R.var => checkTy context ty) varList

  fun checkUses context varList =
      app (ignore o checkVar context) varList

  val checkClobs = checkDefs

  fun checkClobLive {liveIn, liveOut} (var as {id,ty}:R.var) =
      (
        if RTLUtils.Var.inDomain (liveIn, id)
           orelse RTLUtils.Var.inDomain (liveOut, id)
        then ERROR (ClobVariableIsLive var)
        else ()
      )

  fun checkClobsLive live varList =
      app (checkClobLive live) varList

  fun checkAddr (context:context) addr =
      case addr of
        R.ABSADDR label => checkLabelRef context label
      | R.ADDRCAST (ptrTy, addr) => (checkAddr context addr; ptrTy)
      | R.DISP (const, addr2) =>
        let
          val ty1 = checkConst context const
          val _ = checkIntTy ty1 (DisplacementMustBeInt const)
          val pty2 = checkAddr context addr2
          val _ = case ty1 of
                    R.PtrDiff pty =>
                    if pty = pty2 then ()
                    else ERROR (DisplacementTypeMismatch
                                  (addr,{displacement=ty1, addr=pty2}))
                  | _ => ()
        in
          case pty2 of
            R.Void => R.Void
          | R.Data => R.Void  (* middle of heap object *)
          | R.Code => R.Code
        end
      | R.BASE var =>
        let
          val ty1 = checkVar context var
          val pty1 = checkAnyPtrTy ty1 (VarMustBePointer var)
        in
          pty1
        end
      | R.ABSINDEX {base, index, scale} =>
        let
          val pty1 = checkLabelRef context base
          val ty2 = checkVar context index
          val _ = checkIntTy ty2 (IndexMustBeInt index)
          val _ = case ty2 of
                    R.PtrDiff pty =>
                    if pty = pty1 then ()
                    else ERROR (IndexTypeMismatch
                                  (addr,{index=ty2, addr=pty1}))
                  | _ => ()
        in
          case pty1 of
            R.Void => R.Void
          | R.Data => R.Void  (* middle of heap object *)
          | R.Code => R.Code
        end
      | R.BASEINDEX {base, index, scale} =>
        let
          val ty1 = checkVar context base
          val pty1 = checkAnyPtrTy ty1 (VarMustBePointer base)
          val ty2 = checkVar context index
          val _ = checkIntTy ty2 (IndexMustBeInt index)
          val _ = case ty2 of
                    R.PtrDiff pty =>
                    if pty = pty1 then ()
                    else ERROR (IndexTypeMismatch
                                  (addr,{index=ty2, addr=pty1}))
                  | _ => ()
        in
          case pty1 of
            R.Void => R.Void
          | R.Data => R.Void  (* middle of heap object *)
          | R.Code => R.Code
        end
      | R.PREFRAME {offset, size} =>
        let
          val preSize = #preFrameSize (#cluster context)
        in
          if offset < 0 orelse offset > preSize
          then ERROR (PreFrameExceeded {actual=offset, limit=preSize})
          else if size < 0 orelse offset - size < 0
          then ERROR (PreFrameExceeded {actual=offset-size, limit=preSize})
          else ();
          R.Void
        end
      | R.POSTFRAME {offset, size} =>
        let
          val postSize = #postFrameSize (#cluster context)
        in
          if offset < 0 orelse offset > postSize
          then ERROR (PostFrameExceeded {actual=offset, limit=postSize})
          else if size < 0 orelse offset + size > postSize
          then ERROR (PostFrameExceeded {actual=offset+size, limit=postSize})
          else ();
          R.Void
        end
      | R.WORKFRAME slot => (checkSlot context slot; R.Void)
      | R.FRAMEINFO n => R.Void

  fun checkMem (context:context) (ty, mem) =
      (
        checkTy context ty;
        case mem of
          R.SLOT {id,format} => checkFormat context format
        | R.ADDR addr => (checkAddr context addr; ());
        ty
      )

  fun checkDef (context:context) dst =
      case dst of
        R.REG {ty,...} => (checkTy context ty; ty)
      | R.COUPLE (ty, {hi, lo}) =>
        (
          checkTy context ty;
          checkDef context hi;
          checkDef context lo;
          ty
        )
      | R.MEM mem => checkMem context mem

  fun checkRef (context:context) dst =
      case dst of
        R.REG v => checkVar context v
      | R.COUPLE (ty, {hi, lo}) =>
        (
          checkTy context ty;
          checkRef context hi;
          checkRef context lo;
          ty
        )
      | R.MEM mem => checkMem context mem

  fun checkOperand (context:context) op1 =
      case op1 of
        R.CONST const => checkConst context const
      | R.REF (R.N, dst) => checkRef context dst
      | R.REF (R.CAST ty, dst) =>
        (
          checkTy context ty;
          checkRef context dst;
          ty
        )

  fun checkSucc (context:context) label =
      case R.LabelMap.find (#liveness context, label) of
        NONE => ERROR (UndefinedLabel label)
      | SOME {vars={liveIn=liveVars,...}, slots={liveIn=liveSlots,...}} =>
        (
          app
            (fn v as {id, ty} =>
                case VarID.Map.find (#vars (#env context), id) of
                  NONE => ERROR (RequireLiveVarAcrossBlock (v,{succ=label}))
                | SOME {ty=ty2,...} =>
                  eqTy {actual=ty, require=ty2}
                       (fn _ => TypeMismatchAcrossBlock
                                  (v,{succ=label,thisBlock=ty2,succBlock=ty})))
            (varList liveVars);
          app
            (fn s as {id, format} =>
                case VarID.Map.find (#slots (#env context), id) of
                  NONE => ERROR (RequireLiveSlotAcrossBlock (s,{succ=label}))
                | SOME _ => ())
            (slotList liveSlots)
        )

  fun checkHandler (context:context) handler =
      case handler of
        R.NO_HANDLER => ()
      | R.HANDLER {outside, handlers} =>
        app (fn label =>
                case R.LabelMap.find (#body (#cluster context), label) of
                  SOME (R.HANDLERENTRY _, _, _) => checkSucc context label
                | SOME (_, _, _) => ERROR (NotHandlerEntry label)
                | NONE => ERROR (UndefinedLabel label))
            handlers

  fun checkLabelConsist (label, key) =
      if VarID.eq (label, key) then ()
      else ERROR (InconsistLabel (label, {key=key}))

  fun checkFirst (context:context) (key, first) =
      case first of
        R.BEGIN {label, align, loc} =>
        (checkLabelConsist (label, key); emptyEnv)
      | R.CODEENTRY {label, symbol, scope, align, preFrameSize,
                     stubOptions, defs, loc} =>
        let
          val _ = checkLabelConsist (label, key)
          val _ = checkDefs context defs
          val _ =
              if VarID.Map.isEmpty (#vars (#env context))
              then ()
              else VarID.Map.app (fn v => ERROR (UndefinedVariable v))
                                 (#vars (#env context))
          val _ =
              if VarID.Map.isEmpty (#slots (#env context))
              then ()
              else VarID.Map.app (fn v => ERROR (UndefinedSlot v))
                                 (#slots (#env context))
          val preSize = #preFrameSize (#cluster context)
          val _ =
              if preFrameSize <= preSize
              then ()
              else ERROR (PreFrameExceeded {actual=preFrameSize, limit=preSize})
        in
          varEnv defs
        end
      | R.HANDLERENTRY {label, align, defs, loc} =>
        (
          checkLabelConsist (label, key);
          checkDefs context defs;
          varEnv defs
        )
      | R.ENTER => (ERROR EnterFound; emptyEnv)

  fun checkInsn2 (context:context) (ty, dst, op1) =
      let
        val _ = checkTy context ty
        val ty1 = checkDef context dst
        val _ = eqTy {actual=ty1, require=ty} (DstTypeMismatch dst)
        val ty2 = checkOperand context op1
        val _ = eqTy {actual=ty2, require=ty} (OperandTypeMismatch op1)
      in
        dstEnv dst
      end

  fun checkInsn3 (context:context) (ty, dst, op1, op2) =
      let
        val _ = checkTy context ty
        val ty1 = checkDef context dst
        val _ = eqTy {actual=ty1, require=ty} (DstTypeMismatch dst)
        val ty2 = checkOperand context op1
        val _ = eqTy {actual=ty2, require=ty} (OperandTypeMismatch op1)
        val ty3 = checkOperand context op2
        val _ = eqTy {actual=ty3, require=ty} (OperandTypeMismatch op2)
      in
        dstEnv dst
      end

  fun checkCast (context:context) (sign, fromTy, toTy, dst, op1) =
      let
        val ty1 = checkDef context dst
        val _ = eqTy {actual=ty1, require=toTy sign} (DstTypeMismatch dst)
        val ty2 = checkOperand context op1
        val _ = eqTy {actual=ty2, require=fromTy sign} (OperandTypeMismatch op1)
      in
        dstEnv dst
      end

  fun checkShift (context:context) (ty, dst, op1, op2) =
      let
        val _ = checkTy context ty
        val ty1 = checkDef context dst
        val _ = eqTy {actual=ty1, require=ty} (DstTypeMismatch dst)
        val ty2 = checkOperand context op1
        val _ = eqTy {actual=ty2, require=ty} (OperandTypeMismatch op1)
        val ty3 = checkOperand context op2
        val _ = checkIntTy ty3 (OperandMustBeInt op2)
      in
        dstEnv dst
      end

  fun checkTest (context:context) (ty, op1, op2) =
      let
        val _ = checkTy context ty
        val ty1 = checkOperand context op1
        val _ = eqTy {actual=ty1, require=ty} (OperandTypeMismatch op1)
        val ty2 = checkOperand context op2
        val _ = eqTy {actual=ty2, require=ty} (OperandTypeMismatch op2)
      in
        emptyEnv
      end

  fun checkX86FLD (context:context) (ty, mem) =
      (
        checkMem context (ty, mem);
        emptyEnv
      )

  fun checkX86FST (context:context) (ty, mem) =
      (
        checkMem context (ty, mem);
        dstEnv (R.MEM (ty, mem))
      )

  fun checkInsn (context:context) insn =
      case insn of
        R.NOP => emptyEnv
      | R.STABILIZE => emptyEnv  (* stability check is performed later *)
      | R.REQUEST_SLOT slot => slotEnv [slot]
      | R.REQUIRE_SLOT slot => (checkSlot context slot; emptyEnv)
      | R.USE ops =>
        (app (fn x => (checkOperand context x; ())) ops; emptyEnv)
      | R.COMPUTE_FRAME {uses, clobs} =>
        (
          checkUses context (VarID.Map.listItems uses);
          checkClobs context clobs;
          emptyEnv
        )
      | R.MOVE (ty, dst, op1) => checkInsn2 context (ty, dst, op1)
      | R.MOVEADDR (pty, dst, addr) =>
        let
          val ty1 = checkDef context dst
          val _ = eqTy {actual=ty1, require=R.Ptr pty} (DstTypeMismatch dst)
          val pty2 = checkAddr context addr
          val _ = checkPtrTy {actual=pty2, require=pty} (AddrTypeMismatch addr)
        in
          dstEnv dst
        end
      | R.COPY {ty, dst:R.dst, src:R.operand, clobs} =>
        let
          val _ = checkTy context ty
          val env1 = checkInsn2 context (ty, dst, src)
          val _ = checkClobs context clobs
        in
          env1
        end
      | R.MLOAD {ty, dst:R.slot, srcAddr, size, defs, clobs} =>
        let
          val _ = checkTy context ty
          val _ = checkDef context (R.MEM (ty, R.SLOT dst))
          val pty1 = checkAddr context srcAddr
          val ty2 = checkOperand context size
          val _ = checkIntTy ty2 (OperandMustBeInt size)
          val _ = checkDefs context defs
          val _ = checkClobs context clobs
        in
          unionEnv (slotEnv [dst], varEnv defs)
        end
      | R.MSTORE {ty, dstAddr, src:R.slot, size, defs, clobs, global} =>
        let
          val _ = checkTy context ty
          val pty1 = checkAddr context dstAddr
          val _ = checkSlot context src
          val ty2 = checkOperand context size
          val _ = checkIntTy ty2 (OperandMustBeInt size)
          val _ = checkDefs context defs
          val _ = checkClobs context clobs
        in
          varEnv defs
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
          val _ = checkTy context dstTy
          val _ = checkTy context op1Ty
          val _ = checkTy context op2Ty
          val ty1 = checkDef context dst
          val _ = eqTy {actual=ty1,require=dstTy} (DstTypeMismatch dst)
          val ty2 = checkOperand context op1
          val _ = eqTy {actual=ty2,require=op1Ty} (OperandTypeMismatch op1)
          val ty3 = checkOperand context op2
          val _ = eqTy {actual=ty3,require=op2Ty} (OperandTypeMismatch op2)
        in
          dstEnv dst
        end
      | R.DIVMOD ({div=(divTy,ddiv), mod=(modTy,dmod)},
                  (op1Ty,op1), (op2Ty,op2)) =>
        let
          val _ = checkTy context divTy
          val _ = checkTy context modTy
          val _ = checkTy context op1Ty
          val _ = checkTy context op2Ty
          val ty1 = checkDef context ddiv
          val _ = eqTy {actual=ty1,require=divTy} (DstTypeMismatch ddiv)
          val ty2 = checkDef context dmod
          val _ = eqTy {actual=ty2,require=modTy} (DstTypeMismatch dmod)
          val ty3 = checkOperand context op1
          val _ = eqTy {actual=ty3,require=op1Ty} (OperandTypeMismatch op1)
          val ty4 = checkOperand context op2
          val _ = eqTy {actual=ty4,require=op2Ty} (OperandTypeMismatch op2)
        in
          unionEnv (dstEnv ddiv, dstEnv dmod)
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
          val ty1 = checkOperand context op1
          val _ = eqTy {actual=ty1, require=R.Ptr pty} (OperandTypeMismatch op1)
          val pty2 = checkLabelRef context l
          val _ = eqTy {actual=R.Ptr pty2, require=R.Ptr pty}
                       (LabelTypeMismatch l)
        in
          emptyEnv
        end
      | R.NOT (ty, dst, op1) => checkInsn2 context (ty, dst, op1)
      | R.NEG (ty, dst, op1) => checkInsn2 context (ty, dst, op1)
      | R.SET (cc1, ty, dst, {test}) =>
        let
          val env1 = checkInsn context test
          val ty1 = checkDef context dst
          val _ = eqTy {actual=ty1, require=ty} (DstTypeMismatch dst)
        in
          dstEnv dst
        end
      | R.LOAD_FP dst =>
        let
          val ty1 = checkDef context dst
          val _ = eqTy {actual=ty1, require=R.Ptr R.Void} (DstTypeMismatch dst)
        in
          dstEnv dst
        end
      | R.LOAD_SP dst =>
        let
          val ty1 = checkDef context dst
          val _ = eqTy {actual=ty1, require=R.Ptr R.Void} (DstTypeMismatch dst)
        in
          dstEnv dst
        end
      | R.LOAD_PREV_FP dst =>
        let
          val ty1 = checkDef context dst
          val _ = eqTy {actual=ty1, require=R.Ptr R.Void} (DstTypeMismatch dst)
        in
          dstEnv dst
        end
      | R.LOAD_RETADDR dst =>
        let
          val ty1 = checkDef context dst
          val _ = eqTy {actual=ty1, require=R.Ptr R.Code} (DstTypeMismatch dst)
        in
          dstEnv dst
        end
      | R.LOADABSADDR {ty, dst, symbol, thunk} =>
        let
          val ty1 = checkDef context dst
          val _ = eqTy {actual=ty1, require=ty} (DstTypeMismatch dst)
          val pty2 = checkLabelRef context symbol
          val _ = eqTy {actual=R.Ptr pty2, require=ty}
                       (LabelTypeMismatch symbol)
          val _ =
              case thunk of
                NONE => ()
              | SOME thunk =>
                case SEnv.find (#symbolEnv context, thunk) of
                  NONE => ERROR (UndefinedSymbol thunk)
                | SOME (_,{ptrTy=R.Code,...}) => ()
                | SOME (_,{ptrTy,...}) =>
                  ERROR (SymbolTypeMismatch 
                           (thunk, {actual=ptrTy, require=R.Code}))
        in
          dstEnv dst
        end
      | R.X86 (R.X86LEAINT (ty, dst, {base, shift, offset, disp})) =>
        let
          val _ = checkIntTy ty TypeMustBeInt
          val ty1 = checkDef context dst
          val _ = eqTy {actual=ty1, require=ty} (DstTypeMismatch dst)
          val ty2 = checkVar context base
          val _ = eqTy {actual=ty2, require=ty} (VariableTypeMismatch base)
          val ty3 = checkVar context offset
          val _ = eqTy {actual=ty3, require=ty} (VariableTypeMismatch offset)
          val ty4 = checkConst context disp
          val _ = eqTy {actual=ty4, require=ty} (ConstTypeMismatch disp)
        in
          dstEnv dst
        end
      | R.X86 (R.X86FLD (ty, mem)) => checkX86FLD context (ty, mem)
      | R.X86 (R.X86FLD_ST st) => emptyEnv
      | R.X86 (R.X86FST (ty, mem)) => checkX86FST context (ty, mem)
      | R.X86 (R.X86FSTP (ty, mem)) => checkX86FST context (ty, mem)
      | R.X86 (R.X86FSTP_ST st) => emptyEnv
      | R.X86 (R.X86FADD (ty, mem)) => checkX86FLD context (ty, mem)
      | R.X86 (R.X86FADD_ST (st1, st2)) => emptyEnv
      | R.X86 (R.X86FADDP st1) => emptyEnv
      | R.X86 (R.X86FSUB (ty, mem)) => checkX86FLD context (ty, mem)
      | R.X86 (R.X86FSUB_ST (st1, st2)) => emptyEnv
      | R.X86 (R.X86FSUBP st1) => emptyEnv
      | R.X86 (R.X86FSUBR (ty, mem)) => checkX86FLD context (ty, mem)
      | R.X86 (R.X86FSUBR_ST (st1, st2)) => emptyEnv
      | R.X86 (R.X86FSUBRP st1) => emptyEnv
      | R.X86 (R.X86FMUL (ty, mem)) => checkX86FLD context (ty, mem)
      | R.X86 (R.X86FMUL_ST (st1, st2)) => emptyEnv
      | R.X86 (R.X86FMULP st1) => emptyEnv
      | R.X86 (R.X86FDIV (ty, mem)) => checkX86FLD context (ty, mem)
      | R.X86 (R.X86FDIV_ST (st1, st2)) => emptyEnv
      | R.X86 (R.X86FDIVP st1) => emptyEnv
      | R.X86 (R.X86FDIVR (ty, mem)) => checkX86FLD context (ty, mem)
      | R.X86 (R.X86FDIVR_ST (st1, st2)) => emptyEnv
      | R.X86 (R.X86FDIVRP st1) => emptyEnv
      | R.X86 R.X86FPREM => emptyEnv
      | R.X86 (R.X86FABS) => emptyEnv
      | R.X86 (R.X86FCHS) => emptyEnv
      | R.X86 R.X86FINCSTP => emptyEnv
      | R.X86 (R.X86FFREE st) => emptyEnv
      | R.X86 (R.X86FXCH st) => emptyEnv
      | R.X86 (R.X86FUCOM st) => emptyEnv
      | R.X86 (R.X86FUCOMP st) => emptyEnv
      | R.X86 R.X86FUCOMPP => emptyEnv
      | R.X86 (R.X86FSW_TESTH {clob,mask}) =>
        (checkClobs context [clob]; emptyEnv)
      | R.X86 (R.X86FSW_MASKCMPH {clob,mask,compare}) =>
        (checkClobs context [clob]; emptyEnv)
      | R.X86 (R.X86FLDCW mem) =>
        (
          checkMem context (R.Int16 R.U, mem);
          emptyEnv
        )
      | R.X86 (R.X86FNSTCW mem) =>
        (
          checkMem context (R.Int16 R.U, mem);
          dstEnv (R.MEM (R.Int16 R.U, mem))
        )
      | R.X86 R.X86FWAIT => emptyEnv
      | R.X86 R.X86FNCLEX => emptyEnv

  fun checkLast (context:context) last =
      case last of
        R.HANDLE (insn, {nextLabel, handler}) =>
        let
          val env1 = checkInsn context insn
          val context = extendContext (context, env1)
          val _ = checkSucc context nextLabel
          val _ = checkHandler context handler
        in
          context
        end
      | R.CJUMP {test, cc, thenLabel, elseLabel} =>
        let
          val env1 = checkInsn context test
          val context = extendContext (context, env1)
handle e => (print (Control.prettyPrint (RTL.format_last last)^ "\n"); raise e)
          val _ = checkSucc context thenLabel
          val _ = checkSucc context elseLabel
        in
          context
        end
      | R.CALL {callTo, returnTo, handler, defs, uses,
                needStabilize, postFrameAdjust} =>
        let
          val pty1 = checkAddr context callTo
          val _ = checkPtrTy {require=R.Code, actual=pty1}
                             (AddrTypeMismatch callTo)
          val _ = checkDefs context defs
          val _ = checkUses context uses
          val context = extendContext (context, varEnv defs)
          val _ = checkSucc context returnTo
          val _ = checkHandler context handler
        in
          context
        end
      | R.JUMP {jumpTo, destinations} =>
        let
          val pty1 = checkAddr context jumpTo
          val _ = checkPtrTy {require=R.Code, actual=pty1}
                             (AddrTypeMismatch jumpTo)
          val _ = app (checkSucc context) destinations
        in
          context
        end
      | R.UNWIND_JUMP {jumpTo, sp, fp, uses, handler} =>
        let
          val pty1 = checkAddr context jumpTo
          val _ = checkPtrTy {require=R.Code, actual=pty1}
                                (AddrTypeMismatch jumpTo)
          val ty1 = checkOperand context sp
          val _ = eqTy {actual=ty1, require=R.Ptr R.Void}
                       (OperandTypeMismatch sp)
          val ty2 = checkOperand context fp
          val _ = eqTy {actual=ty2, require=R.Ptr R.Void}
                       (OperandTypeMismatch fp)
          val _ = checkUses context uses
          val _ = checkHandler context handler
        in
          context
        end
      | R.TAILCALL_JUMP {preFrameSize, jumpTo, uses} =>
        let
          val pty1 = checkAddr context jumpTo
          val _ = checkPtrTy {require=R.Code, actual=pty1}
                             (AddrTypeMismatch jumpTo)
          val _ = checkUses context uses
          val preSize = #preFrameSize (#cluster context)
          val _ =
              if preFrameSize <= preSize
              then ()
              else ERROR (PreFrameExceeded
                            {actual = preFrameSize, limit = preSize})
        in
          context
        end
      | R.RETURN {preFrameSize, stubOptions, uses} =>
        let
          val _ = checkUses context uses
          val preSize = #preFrameSize (#cluster context)
          val _ =
              if preFrameSize <= preSize
              then ()
              else ERROR (PreFrameExceeded
                            {actual = preFrameSize, limit = preSize})
        in
          context
        end
      | R.EXIT => (ERROR ExitFound; context)

  fun checkPtrStability liveOut =
      let
        val vars = RTLUtils.Var.filter
                     (fn {ty=R.Ptr R.Data,...} => true | _ => false)
                     liveOut
      in
        if RTLUtils.Var.isEmpty vars
        then ()
        else app (fn x => ERROR (NotStabilized x)) (varList vars)
      end

  fun getFirstLabel first =
      case first of
        R.BEGIN {label, align, loc} => SOME label
      | R.CODEENTRY {label, symbol, scope, align, preFrameSize,
                     stubOptions, defs, loc} => SOME label
      | R.HANDLERENTRY {label, align, defs, loc} => SOME label
      | R.ENTER => NONE

  fun checkLivenessFirst {checkStability}
                         ({liveIn, liveOut}:RTLLiveness.liveness) first =
      case first of
        R.BEGIN {label, align, loc} => ()
      | R.CODEENTRY {label, symbol, scope, align, preFrameSize,
                     stubOptions, defs, loc} => ()
      | R.HANDLERENTRY {label, align, defs, loc} =>
        if checkStability
        then if RTLUtils.Var.isEmpty (minus (liveOut, defs))
             then ()
             else app (fn x => ERROR (NotStabilized x)) (varList liveOut)
        else ()
      | R.ENTER => ()

  fun checkLivenessInsn {checkStability}
                        (live as {liveIn, liveOut}:RTLLiveness.liveness)
                        insn =
      case insn of
        R.NOP => ()
      | R.STABILIZE => if checkStability then checkPtrStability liveIn else ()
      | R.COMPUTE_FRAME {uses, clobs} => checkClobsLive live clobs
      | R.REQUEST_SLOT slot => ()
      | R.REQUIRE_SLOT slot => ()
      | R.USE vars => ()
      | R.MOVE (ty, dst, op1) => ()
      | R.MOVEADDR (ptrTy, dst, addr) => ()
      | R.COPY {ty, dst, src, clobs} => checkClobsLive live clobs
      | R.MLOAD {ty, dst, srcAddr, size, defs, clobs} =>
        checkClobsLive live clobs
      | R.MSTORE {ty, dstAddr, src, size, global, defs, clobs} =>
        checkClobsLive live clobs
      | R.EXT8TO32 (sign, dst, op1) => ()
      | R.EXT16TO32 (sign, dst, op1) => ()
      | R.EXT32TO64 (sign, dst, op1) => ()
      | R.DOWN32TO8 (sign, dst, op1) => ()
      | R.DOWN32TO16 (sign, dst, op1) => ()
      | R.ADD (ty, dst, op1, op2) => ()
      | R.SUB (ty, dst, op1, op2) => ()
      | R.MUL ((ty, dst), (ty2, op1), (ty3, op2)) => ()
      | R.DIVMOD ({div, mod}, (ty3, op1), (ty4, op2)) => ()
      | R.AND (ty, dst, op1, op2) => ()
      | R.OR (ty, dst, op1, op2) => ()
      | R.XOR (ty, dst, op1, op2) => ()
      | R.LSHIFT (ty, dst, op1, op2) => ()
      | R.RSHIFT (ty, dst, op1, op2) => ()
      | R.ARSHIFT (ty, dst, op1, op2) => ()
      | R.TEST_SUB (ty, op1, op2) => ()
      | R.TEST_AND (ty, op1, op2) => ()
      | R.TEST_LABEL (ptrTy, op1, label) => ()
      | R.NOT (ty, dst, op1) => ()
      | R.NEG (ty, dst, op1) => ()
      | R.SET (cc1, ty, dst, {test}) => ()
      | R.LOAD_FP dst => ()
      | R.LOAD_SP dst => ()
      | R.LOAD_PREV_FP dst => ()
      | R.LOAD_RETADDR dst => ()
      | R.LOADABSADDR {ty, dst, symbol, thunk} => ()
      | R.X86 (R.X86LEAINT (ty, dst, {base, shift, offset, disp})) => ()
      | R.X86 (R.X86FLD (ty, mem)) => ()
      | R.X86 (R.X86FLD_ST x86st1) => ()
      | R.X86 (R.X86FST (ty, mem)) => ()
      | R.X86 (R.X86FSTP (ty, mem)) => ()
      | R.X86 (R.X86FSTP_ST x86st1) => ()
      | R.X86 (R.X86FADD (ty, mem)) => ()
      | R.X86 (R.X86FADD_ST (x86st1, x86st2)) => ()
      | R.X86 (R.X86FADDP x86st1) => ()
      | R.X86 (R.X86FSUB (ty, mem)) => ()
      | R.X86 (R.X86FSUB_ST (x86st1, x86st2)) => ()
      | R.X86 (R.X86FSUBP x86st1) => ()
      | R.X86 (R.X86FSUBR (ty, mem)) => ()
      | R.X86 (R.X86FSUBR_ST (x86st1, x86st2)) => ()
      | R.X86 (R.X86FSUBRP x86st1) => ()
      | R.X86 (R.X86FMUL (ty, mem)) => ()
      | R.X86 (R.X86FMUL_ST (x86st1, x86st2)) => ()
      | R.X86 (R.X86FMULP x86st1) => ()
      | R.X86 (R.X86FDIV (ty, mem)) => ()
      | R.X86 (R.X86FDIV_ST (x86st1, x86st2)) => ()
      | R.X86 (R.X86FDIVP x86st1) => ()
      | R.X86 (R.X86FDIVR (ty, mem)) => ()
      | R.X86 (R.X86FDIVR_ST (x86st1, x86st2)) => ()
      | R.X86 (R.X86FDIVRP x86st1) => ()
      | R.X86 R.X86FPREM => ()
      | R.X86 R.X86FABS => ()
      | R.X86 R.X86FCHS => ()
      | R.X86 R.X86FINCSTP => ()
      | R.X86 (R.X86FFREE x86st1) => ()
      | R.X86 (R.X86FXCH x86st1) => ()
      | R.X86 (R.X86FUCOM x86st1) => ()
      | R.X86 (R.X86FUCOMP x86st1) => ()
      | R.X86 R.X86FUCOMPP => ()
      | R.X86 (R.X86FSW_TESTH {clob,mask}) => checkClobLive live clob
      | R.X86 (R.X86FSW_MASKCMPH {clob,mask,compare}) => checkClobLive live clob
      | R.X86 (R.X86FLDCW mem) => ()
      | R.X86 (R.X86FNSTCW mem) => ()
      | R.X86 R.X86FWAIT => ()
      | R.X86 R.X86FNCLEX => ()

  fun checkLivenessLast {checkStability}
                        ({liveIn, liveOut}:RTLLiveness.liveness) last =
      case last of
        R.HANDLE (insn, {nextLabel, handler}) => ()
      | R.CJUMP {test, cc, thenLabel, elseLabel} => ()
      | R.CALL {callTo, returnTo, handler, defs, uses, needStabilize,
                postFrameAdjust} =>
        if checkStability
        then checkPtrStability (minus (liveOut, defs))
        else ()
      | R.JUMP {jumpTo, destinations} => ()
      | R.UNWIND_JUMP {jumpTo, sp, fp, uses, handler} => ()
      | R.TAILCALL_JUMP {preFrameSize, jumpTo, uses} => ()
      | R.RETURN {preFrameSize, stubOptions, uses} => ()
      | R.EXIT => ()

  fun checkInsnList (context:context) (insn::insns) =
      let
        val env1 = WRAP (ErrorAtMiddle insn) (checkInsn context insn)
        val context = extendContext (context, env1)
        val context = checkInsnList context insns
      in
        context
      end
    | checkInsnList (context:context) nil = context

  fun checkBlock (context:context) (label, (first, mid, last):R.block) =
      let
        val env = WRAP (ErrorAtFirst first) (checkFirst context (label, first))

        val context = extendContext (context, env)
        val context = checkInsnList context mid

        val context = WRAP (ErrorAtLast last) (checkLast context last)
      in
        app
          (fn v as {id, ty} =>
              case VarID.Map.find (#vars (#env context), id) of
                NONE => ERROR (VarNotFoundInLiveOut v)
              | SOME {ty=ty2,...} =>
                eqTy {actual=ty, require=ty2}
                     (fn _ => TypeMismatchWithLiveOut
                                (v,{actual=ty2,liveOut=ty})))
          (varList (#vars (#liveOut context)));
        app
          (fn v as {id, format} =>
              case VarID.Map.find (#slots (#env context), id) of
                NONE => ERROR (SlotNotFoundInLiveOut v)
              | SOME _ => ())
          (slotList (#slots (#liveOut context)))
      end

  fun checkClusterLiveness options livenessGraph =
      let
        val prevErrors = !errors
        val (err1, err2) =
            RTLLiveness.foldBackward
              (fn (RTLEdit.FIRST first, live, (e1, e2)) =>
                  (errors := nil;
                   checkLivenessFirst options live first;
                   case !errors @ e1 of
                     nil => (nil, e2)
                   | errs =>
                     (nil, ErrorInBlock (getFirstLabel first) errs :: e2))
                | (RTLEdit.MIDDLE insn, live, (e1, e2)) =>
                  (errors := nil;
                   checkLivenessInsn options live insn;
                   (!errors @ e1, e2))
                | (RTLEdit.LAST last, live, (e1, e2)) =>
                  (errors := nil;
                   checkLivenessLast options live last;
                   (!errors @ e1, e2)))
              (nil, nil)
              livenessGraph
      in
        errors := err1 @ rev err2 @ prevErrors
      end

  fun checkCluster {symbolEnv, checkStability}
                   ({clusterId, frameBitmap, baseLabel, body,
                     preFrameSize, postFrameSize, numHeaderWords,
                     loc}:R.cluster) =
      let
        val livenessGraph = RTLLiveness.liveness body
        val _ = checkClusterLiveness {checkStability=checkStability}
                                     livenessGraph

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
      in
        WRAP (ErrorInCluster clusterId)
          (R.LabelMap.appi
             (fn (label, block) =>
                 let
                   val {vars, slots} = R.LabelMap.lookup (liveness, label)
                   val context =
                       {
                         env = setToEnv (#liveIn vars, #liveIn slots),
                         liveOut = {vars = #liveOut vars,
                                    slots = #liveOut slots},
                         cluster = cluster,
                         symbolEnv = symbolEnv,
                         liveness = liveness
                       } : context
                 in
                   WRAP (ErrorInBlock (SOME label))
                        (checkBlock context (label, block))
                 end)
             body)
      end

  fun dummyContext {symbolEnv, checkStability} =
      {
        env = emptyEnv,
        liveOut = {vars = RTLUtils.Var.emptySet,
                   slots = RTLUtils.Slot.emptySet},
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
        R.CONST_DATA const => (checkConst context const; ())
      | R.LABELREF_DATA label => (checkLabelRef context label; ())
      | R.BINARY_DATA wordList => ()
      | R.ASCII_DATA s => ()
      | R.SPACE_DATA {size} => ()

  fun checkDatumList context data =
      app (checkDatum context) data

  fun checkData context ({scope, symbol, aliases, ptrTy, section, prefix,
                          align, data, prefixSize}:R.data) =
      (
        checkDatumList context prefix;
        checkDatumList context data
      )

  fun unifySymbolDef (symbol, (STRONG, _:symbolDef), (STRONG, _:symbolDef)) =
      (ERROR (DoubledSymbol symbol); NONE)
    | unifySymbolDef (symbol, (WEAK, def1), (WEAK, def2)) =
      (ERROR (DoubledSymbol symbol); NONE)
    | unifySymbolDef (symbol, def1 as (WEAK, _), def2 as (STRONG, _)) =
      unifySymbolDef (symbol, def2, def1)
    | unifySymbolDef (symbol, (STRONG, def1), (WEAK, def2)) =
      (
        case #scope def1 of
          R.LOCAL =>
          ERROR (SymbolScopeMismatch
                   (symbol, {actual = #scope def2, require = R.GLOBAL}))
        | R.GLOBAL => ();
        case #scope def2 of
          R.LOCAL =>
          ERROR (SymbolScopeMismatch
                   (symbol, {actual = #scope def2, require = R.GLOBAL}))
        | R.GLOBAL => ();
        if #ptrTy def1 = #ptrTy def2
        then ()
        else ERROR (SymbolTypeMismatch (symbol, {actual = #ptrTy def2,
                                                 require = #ptrTy def1}));
        SOME (STRONG,
              {haveLinkEntry = #haveLinkEntry def1 orelse #haveLinkEntry def2,
               haveLinkStub = #haveLinkStub def1 orelse #haveLinkStub def2,
               scope = #scope def1,
               ptrTy = #ptrTy def1})
      )

  fun unionSymbolEnv (env1:symbolEnv, env2:symbolEnv) =
      SEnv.foldri
        (fn (symbol, def, env1:symbolEnv) =>
            case (SEnv.find (env1, symbol), def) of
              (NONE, _) => SEnv.insert (env1, symbol, def)
            | (SOME def1, def2) =>
              case unifySymbolDef (symbol, def1, def2) of
                NONE => env1
              | SOME def => SEnv.insert (env1, symbol, def))
        env1
        env2

  fun symbolDef topdecl =
      case topdecl of
        R.TOPLEVEL {symbol, toplevelEntry, nextToplevel,
                    smlPushHandlerLabel, smlPopHandlerLabel} =>
        SEnv.singleton (symbol,
                        (STRONG, {haveLinkEntry = false, haveLinkStub = false,
                                  scope = R.GLOBAL, ptrTy = R.Code}))
      | R.CLUSTER {body, ...} =>
        R.LabelMap.foldl
          (fn ((R.CODEENTRY {symbol, scope, ...}, _, _), env) =>
              if SEnv.inDomain (env, symbol)
              then (ERROR (DoubledSymbol symbol); env)
              else SEnv.insert (env, symbol,
                                (STRONG, {haveLinkEntry = false,
                                          haveLinkStub = false,
                                          scope = scope,
                                          ptrTy = R.Code}))
            | (_, z) => z)
          SEnv.empty
          body
      | R.DATA {scope, symbol, ptrTy, ...} =>
        SEnv.singleton (symbol,
                        (STRONG, {haveLinkEntry = false, haveLinkStub = false,
                                  scope = scope, ptrTy = ptrTy}))
      | R.BSS {scope, symbol, size} =>
        SEnv.singleton (symbol,
                        (STRONG, {haveLinkEntry = false, haveLinkStub = false,
                                  scope = scope, ptrTy = R.Void}))
      | R.X86GET_PC_THUNK_BX symbol =>
        SEnv.singleton (symbol,
                        (STRONG, {haveLinkEntry = false, haveLinkStub = false,
                                  scope = R.LOCAL, ptrTy = R.Code}))
      | R.EXTERN {symbol, linkStub, linkEntry, ptrTy} =>
        SEnv.singleton (symbol,
                        (WEAK, {haveLinkEntry = linkEntry,
                                haveLinkStub = linkStub,
                                scope = R.GLOBAL,
                                ptrTy = ptrTy}))

  fun makeSymbolEnv program =
      foldl
        (fn (topdecl, env) =>
            let
              val env1 = symbolDef topdecl
              val env2 = unionSymbolEnv (env, env1)
            in
              env2
            end)
        SEnv.empty
        program

  fun checkTopdecl (context as {symbolEnv, checkStability}) topdecl =
      case topdecl of
        R.TOPLEVEL {symbol, toplevelEntry, nextToplevel,
                    smlPushHandlerLabel, smlPopHandlerLabel} =>
        let
          val context = dummyContext context
          val pty1 = checkLabelRef context smlPushHandlerLabel
          val _ = eqTy {require=R.Ptr R.Code, actual=R.Ptr pty1}
                       (LabelTypeMismatch smlPushHandlerLabel)
          val pty2 = checkLabelRef context smlPopHandlerLabel
          val _ = eqTy {require=R.Ptr R.Code, actual=R.Ptr pty2}
                       (LabelTypeMismatch smlPopHandlerLabel)
        in
          ()
        end
      | R.CLUSTER (cluster as {clusterId,...}) =>
        checkCluster context cluster
      | R.DATA (data as {symbol,...}) =>
        let
          val context = dummyContext context
        in
          WRAP (ErrorInData symbol) (checkData context data)
        end
      | R.BSS _ => ()
      | R.X86GET_PC_THUNK_BX _ => ()
      | R.EXTERN _ => ()

  fun check {checkStability} program =
      let
        val _ = errors := nil
        val symbolEnv = makeSymbolEnv program
        val context = {symbolEnv = symbolEnv, checkStability = checkStability}
        val _ = app (checkTopdecl context) program
      in
        rev (!errors) before errors := nil
      end

end
