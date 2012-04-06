(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure X86Select : RTLSELECT =
struct

  structure AI = AbstractInstruction2
  structure R = RTL

  infix 5 << >>
  infix 2 || && ^^
  val (op ||) = Word32.orb
  val (op &&) = Word32.andb
  val (op ^^) = Word32.xorb
  val (op <<) = Word32.<<
  val (op >>) = Word32.>>
  val notb = Word32.notb
  val toWord = BasicTypes.SInt32ToUInt32

  val BYTE_BITS = 8

  (*
   * Heap object header:
   *
   * MSB                                           LSB
   * +--------+------+-------------------------------+
   * |  type  |  gc  |           size                |
   * +--------+------+-------------------------------+
   *  31    28 27  26 25                            0
   *
   * type:
   *  UNBOXED_VECTOR    0000     arbitrary binary data (String and Vector)
   *  BOXED_VECTOR      0001     vector of heap object pointers
   *  UNBOXED_ARRAY     0010     array of arbitrary binary data
   *  BOXED_ARRAY       0011     array of heap object pointers
   *  RECORD            0101     mixed structure of arbitrary type values
   *  INTINF            0110     large integer
   *                       ^
   *                    HEAD_BITTAG
   *)
  val HEAD_GC_MASK = 0wx3 << 0w26 : Word32.word
  val HEAP_BITMAP_MASK = 0w1 << 0w28 : Word32.word
  val HEAD_TYPE_MASK = notb 0w0 << 0w28 : Word32.word
  val HEAD_SIZE_MASK = notb (HEAD_TYPE_MASK || HEAD_GC_MASK) : Word32.word
  val HEAD_BITTAG_SHIFT = 0w28 : Word32.word
  val HEAD_TYPE_UNBOXED = 0w0 << 0w28 : Word32.word
  val HEAD_TYPE_BOXED   = 0w1 << 0w28 : Word32.word
  val HEAD_TYPE_VECTOR  = 0w0 << 0w29 : Word32.word
  val HEAD_TYPE_ARRAY   = 0w1 << 0w29 : Word32.word
  val HEAD_TYPE_RECORD  = 0w2 << 0w29 : Word32.word
  val HEAD_TYPE_INTINF  = 0w3 << 0w29 : Word32.word
  val HEAD_TYPE_BOXED_VECTOR   = HEAD_TYPE_VECTOR || HEAD_TYPE_BOXED
  val HEAD_TYPE_UNBOXED_VECTOR = HEAD_TYPE_VECTOR || HEAD_TYPE_UNBOXED
  val HEAD_TYPE_BOXED_ARRAY    = HEAD_TYPE_ARRAY || HEAD_TYPE_BOXED
  val HEAD_TYPE_UNBOXED_ARRAY  = HEAD_TYPE_ARRAY || HEAD_TYPE_UNBOXED
  val HEAD_TYPE_RECORD  = HEAD_TYPE_RECORD || HEAD_TYPE_BOXED
  val HEAD_TYPE_INTINF  = HEAD_TYPE_INTINF || HEAD_TYPE_UNBOXED

  val FRAME_FLAG_VISITED = 0wx1 : Word32.word
  val FRAME_FLAG_SKIP = 0wx2 : Word32.word

  datatype arch =
      ELF
    | MachO
    | COFF

  type options =
      {
        positionIndependent: arch option,
        globalSymbolStartsWithUnderscore: bool
      }

  fun entrySymbolName {clusterId, entry} =
      "FF" ^ ClusterID.toString clusterId ^ "_" ^ VarID.toString entry
  fun constSymbolName id =
      "LC" ^ VarID.toString id
  fun globalSymbolName (options:options) label =
      if #globalSymbolStartsWithUnderscore options
      then "_" ^ label
      else label

  fun newDst ty =
      let
        val id = VarID.generate ()
      in
        case ty of
          R.Int8 s => R.REG {id=id, ty=ty}
        | R.Int16 s => R.REG {id=id, ty=ty}
        | R.Int32 _ => R.REG {id=id, ty=ty}
        | R.Ptr _ => R.REG {id=id, ty=ty}
        | R.PtrDiff _ => R.REG {id=id, ty=ty}
        | R.NoType => R.REG {id=id, ty=ty}
        | R.Real32 => R.MEM (ty, R.SLOT {id=id, format=X86Emit.formatOf ty})
        | R.Real64 => R.MEM (ty, R.SLOT {id=id, format=X86Emit.formatOf ty})
        | R.Real80 => R.MEM (ty, R.SLOT {id=id, format=X86Emit.formatOf ty})
        | R.Int64 _ => raise Control.Bug "transformVarInfo: Int64"
        | R.Generic _ =>
          R.MEM (ty, R.SLOT {id=id, format=X86Emit.formatOf ty})
      end

  fun newVar ty =
      case newDst ty of
        R.REG v => v
      | _ => raise Control.Bug "newVar"

  fun newSlot fmt =
      {id = VarID.generate (), format = fmt} : R.slot

  datatype value =
      OPRD of R.operand
    | ADDR of R.addr

  fun format_value (OPRD x) = R.format_operand x
    | format_value (ADDR x) = R.format_addr x

  fun valueTy (OPRD op1) = RTLUtils.operandTy op1
    | valueTy (ADDR addr) = R.Ptr (RTLUtils.addrTy addr)

  type context =
      {
        options: options,
        handler: R.handler,
        calleeSaves: R.var list
      }

  type code =
      {
        globalOffsetBase: (R.labelReference * R.var) option,
        externSymbols: {linkStub:bool, linkEntry:bool, ptrTy:R.ptrTy} SEnv.map,
        handlerSlots: R.slot R.LabelMap.map,  (* handlerLabel -> slot *)
        preFrameSize: int,
        postFrameSize: int,
        focus: RTLEdit.focus
      }

  fun updateFocus ({globalOffsetBase, externSymbols, handlerSlots,
                    preFrameSize, postFrameSize, focus=_}:code)
                  focus =
      {globalOffsetBase = globalOffsetBase,
       externSymbols = externSymbols,
       handlerSlots = handlerSlots,
       preFrameSize = preFrameSize,
       postFrameSize = postFrameSize,
       focus = focus} : code

  fun updateGlobalOffsetBase ({globalOffsetBase=_, externSymbols, handlerSlots,
                               preFrameSize, postFrameSize, focus}:code)
                             globalOffsetBase =
      {globalOffsetBase = globalOffsetBase,
       externSymbols = externSymbols,
       handlerSlots = handlerSlots,
       preFrameSize = preFrameSize,
       postFrameSize = postFrameSize,
       focus = focus} : code

  fun updateExternSymbols ({globalOffsetBase, externSymbols=_, handlerSlots,
                            preFrameSize, postFrameSize, focus}:code,
                           (externSymbols, x)) =
      ({globalOffsetBase = globalOffsetBase,
        externSymbols = externSymbols,
        handlerSlots = handlerSlots,
        preFrameSize = preFrameSize,
        postFrameSize = postFrameSize,
        focus = focus} : code,
       x)

  fun requirePreFrame ({globalOffsetBase, externSymbols, handlerSlots,
                        preFrameSize, postFrameSize, focus}:code,
                       size) =
      {globalOffsetBase = globalOffsetBase,
       externSymbols = externSymbols,
       handlerSlots = handlerSlots,
       preFrameSize = Int.max (preFrameSize, size),
       postFrameSize = postFrameSize,
       focus = focus} : code

  fun requirePostFrame ({globalOffsetBase, externSymbols, handlerSlots,
                         preFrameSize, postFrameSize, focus}:code,
                        size) =
      {globalOffsetBase = globalOffsetBase,
       externSymbols = externSymbols,
       handlerSlots = handlerSlots,
       preFrameSize = preFrameSize,
       postFrameSize = Int.max (postFrameSize, size),
       focus = focus} : code

  (*
   * struct handlerSlot {
   *     void *reserved;     /* for runtime */
   *     void *handlerAddr;
   *     void *stackPointer;
   *     void *framePointer;
   * }
   *)
  fun handlerSlot (code as {globalOffsetBase, externSymbols, handlerSlots,
                            preFrameSize, postFrameSize, focus}:code, label) =
      case R.LabelMap.find (handlerSlots, label) of
        SOME slot => (code, slot)
      | NONE =>
        let
          val slot = newSlot {size=16, align=4, tag=R.UNBOXED}
          val handlerSlots = R.LabelMap.insert (handlerSlots, label, slot)
        in
          ({globalOffsetBase = globalOffsetBase,
            externSymbols = externSymbols,
            handlerSlots = handlerSlots,
            preFrameSize = preFrameSize,
            postFrameSize = postFrameSize,
            focus = focus} : code,
           slot)
        end

  fun insert (code, insn) =
      updateFocus code (RTLEdit.insertBefore (#focus code, insn))

  fun insertLast (code, last) =
      updateFocus code (RTLEdit.insertLast (#focus code, last))

  fun insertLastBefore (code, lastFn) =
      updateFocus code (#1 (RTLEdit.insertLastBefore (#focus code, lastFn)))

  fun insertJump (code, label) =
      insertLast (code, R.JUMP {jumpTo = R.ABSADDR (R.LABEL label),
                                destinations = [label]})

  fun makeLabelAfter code =
      let
        val (focus, label) = RTLEdit.makeLabelAfter (#focus code)
      in
        (updateFocus code focus, label)
      end

  fun makeLabelBefore code =
      let
        val (focus, label) = RTLEdit.makeLabelBefore (#focus code)
      in
        (updateFocus code focus, label)
      end

  fun focusFirst (code, label) =
      let
        val graph = RTLEdit.unfocus (#focus code)
      in
        updateFocus code (RTLEdit.focusFirst (graph, label))
      end

  fun transformTy ty =
      case ty of
        AI.GENERIC tid => R.Generic tid
      | AI.UINT => R.Int32 R.U
      | AI.SINT => R.Int32 R.S
      | AI.BYTE => R.Int8 R.U
      | AI.BOXED => R.Ptr R.Data
      | AI.HEAPPOINTER => R.Ptr R.Void
      | AI.CODEPOINTER => R.Ptr R.Code
      | AI.CPOINTER => R.Ptr R.Void
      | AI.ENTRY => R.Ptr R.Code
      | AI.FLOAT => R.Real32
      | AI.DOUBLE => R.Real64

  fun sizeof ty =
      #size (X86Emit.formatOf ty)
  fun genericSize () =
      #size X86Emit.formatOfGeneric

  fun transformVarInfo ({id, ty, displayName}:AI.varInfo) =
      let
        val ty = transformTy ty
      in
        case ty of
          R.Int8 s => R.REG {id=id, ty=R.Int8 s}
        | R.Int16 s => R.REG {id=id, ty=R.Int16 s}
        | R.Int32 _ => R.REG {id=id, ty=ty}
        | R.Ptr _ => R.REG {id=id, ty=ty}
        | R.PtrDiff _ => R.REG {id=id, ty=ty}
        | R.NoType => R.REG {id=id, ty=ty}
          (* floating point variables are allocated in frame. *)
        | R.Real32 => R.MEM (ty, R.SLOT {id=id, format=X86Emit.formatOf ty})
        | R.Real64 => R.MEM (ty, R.SLOT {id=id, format=X86Emit.formatOf ty})
        | R.Real80 => R.MEM (ty, R.SLOT {id=id, format=X86Emit.formatOf ty})
        | R.Int64 _ => raise Control.Bug "transformVarInfo: Int64"
          (* generic variables are allocated in frame. *)
        | R.Generic _ =>
          R.MEM (ty, R.SLOT {id=id, format=X86Emit.formatOf ty})
      end

  fun transformArgInfo ({id, ty, ...}:AI.argInfo) =
      transformVarInfo {id=id, ty=ty, displayName=""}

  fun makeCastOperand (op1 as R.REF (R.N, dst), ty) =
      if RTLUtils.dstTy dst = ty then op1
      else R.REF (R.CAST ty, dst)
    | makeCastOperand (op1 as R.REF (R.CAST ty1, dst), ty2) =
      if ty1 = ty2 then op1
      else R.REF (R.CAST ty2, dst)
    | makeCastOperand (op1 as R.CONST const, ty) =
      case (const, ty) of
        (R.UINT32 n, R.Int8 R.U) =>
        R.CONST (R.UINT8 (Word8.fromInt (Word32.toInt n)))
      | (R.UINT32 n, R.Int8 R.S) =>
        R.CONST (R.INT8 (Word32.toInt n))
      | (R.UINT32 n, R.Int16 R.U) =>
        R.CONST (R.UINT16 (Word.fromInt (Word32.toInt n)))
      | (R.UINT32 n, R.Int16 R.S) =>
        R.CONST (R.INT16 (Word32.toInt n))
      | (R.UINT32 n, R.Int32 R.S) =>
        R.CONST (R.INT32 (Int32.fromLarge (Word32.toLargeInt n)))
      | (R.UINT32 n, R.Int32 R.U) => op1
      | (R.INT32 n, R.Int8 R.U) =>
        R.CONST (R.UINT8 (Word8.fromInt (Int32.toInt n)))
      | (R.INT32 n, R.Int8 R.S) =>
        R.CONST (R.INT8 (Int32.toInt n))
      | (R.INT32 n, R.Int16 R.U) =>
        R.CONST (R.UINT16 (Word.fromInt (Int32.toInt n)))
      | (R.INT32 n, R.Int16 R.S) =>
        R.CONST (R.INT16 (Int32.toInt n))
      | (R.INT32 n, R.Int32 R.U) =>
        R.CONST (R.UINT32 (Word32.fromLargeInt (Int32.toLarge n)))
      | (R.INT32 n, R.Int32 R.S) => op1
      | (R.UINT8 n, R.Int32 R.U) =>
        R.CONST (R.UINT32 (Word32.fromInt (Word8.toInt n)))
      | (R.UINT8 n, R.Int32 R.S) =>
        R.CONST (R.INT32 (Int32.fromInt (Word8.toInt n)))
      | (R.UINT8 n, R.Int16 R.U) =>
        R.CONST (R.UINT16 (Word.fromInt (Word8.toInt n)))
      | (R.UINT8 n, R.Int16 R.S) =>
        R.CONST (R.INT16 (Word8.toInt n))
      | (R.UINT8 n, R.Int8 R.S) =>
        R.CONST (R.INT8 (Word8.toInt n))
      | (R.UINT8 n, R.Int8 R.U) => op1
      | (R.INT8 n, R.Int32 R.U) =>
        R.CONST (R.UINT32 (Word32.fromInt n))
      | (R.INT8 n, R.Int32 R.S) =>
        R.CONST (R.INT32 (Int32.fromInt n))
      | (R.INT8 n, R.Int16 R.U) =>
        R.CONST (R.UINT16 (Word.fromInt n))
      | (R.INT8 n, R.Int16 R.S) =>
        R.CONST (R.INT16 n)
      | (R.INT8 n, R.Int8 R.S) => op1
      | (R.INT8 n, R.Int8 R.U) =>
        R.CONST (R.UINT8 (Word8.fromInt n))
      | (R.REAL64 s, R.Real32) => R.CONST (R.REAL32 s)
      | (R.REAL32 s, R.Real64) => R.CONST (R.REAL64 s)
      | _ => raise Control.Bug
                     ("makeCast: CONST " ^
                      Control.prettyPrint (R.format_const const) ^ " " ^
                      Control.prettyPrint (R.format_ty ty))

  fun makeCast (ADDR addr, R.Ptr ptrTy) =
      if RTLUtils.addrTy addr = ptrTy then ADDR addr
      else ADDR (R.ADDRCAST (ptrTy, addr))
    | makeCast (ADDR addr, _) = raise Control.Bug "makeCast: ADDR"
    | makeCast (OPRD op1, ty) = OPRD (makeCastOperand (op1, ty))

  fun promoteIntTy ty =
      case ty of
        (* extend under-32 bits variables to 32 bits. *)
        R.Int8 s => R.Int32 s
      | R.Int16 s => R.Int32 s
      | R.Int32 _ => ty
      | R.Ptr _ => ty
      | R.PtrDiff _ => ty
      | R.NoType => ty
      | R.Real32 => ty
      | R.Real64 => ty
      | R.Real80 => ty
      | R.Int64 _ => ty
      | R.Generic _ => ty

  fun promoteInt (code, op1) =
      case op1 of
        R.CONST (R.UINT8 n) =>
        (code, R.CONST (R.UINT32 (Word32.fromInt (Word8.toIntX n))))
      | R.CONST (R.UINT16 n) =>
        (code, R.CONST (R.UINT32 (Word32.fromInt (Word.toIntX n))))
      | R.CONST (R.INT8 n) =>
        (code, R.CONST (R.INT32 (Int32.fromInt n)))
      | R.CONST (R.INT16 n) =>
        (code, R.CONST (R.INT32 (Int32.fromInt n)))
      | R.CONST _ => (code, op1)
      | R.REF _ =>
        (
          case RTLUtils.operandTy op1 of
            R.Int8 s =>
            let
              val v = newDst (R.Int32 s)
            in
              (insert (code, [R.EXT8TO32 (s, v, op1)]), R.REF_ v)
            end
          | R.Int16 s =>
            let
              val v = newDst (R.Int32 s)
            in
              (insert (code, [R.EXT16TO32 (s, v, op1)]), R.REF_ v)
            end
          | _ => (code, op1)
        )

  fun promoteIntDst dst =
      case RTLUtils.dstTy dst of
        R.Int8 s =>
        let
          val v = newDst (R.Int32 s)
        in
          (fn code => insert (code, [R.DOWN32TO8 (s, dst, R.REF_ v)]), v)
        end
      | R.Int16 s =>
        let
          val v = newDst (R.Int16 s)
        in
          (fn code => insert (code, [R.DOWN32TO16 (s, dst, R.REF_ v)]), v)
        end
      | _ =>
        (fn code => code, dst)

  fun selectHandler handler =
      case handler of
        AI.NoHandler => R.NO_HANDLER
      | AI.StaticHandler label => R.HANDLER {outside=false, handlers=[label]}
      | AI.DynamicHandler {outside, handlers} =>
        R.HANDLER {outside=outside, handlers=handlers}

  fun entrySymbol ent =
      R.SYMBOL (R.Code, R.LOCAL, entrySymbolName ent)
  fun dataSymbol (ptrTy, scope, symbol) =
      R.SYMBOL (ptrTy, scope, symbol)
  fun constSymbol id =
      R.SYMBOL (R.Data, R.LOCAL, constSymbolName id)

  local
    fun find (externSymbols, ptrTy, symbol) =
        case SEnv.find (externSymbols, symbol) of
          SOME x => x
        | NONE => {linkEntry = false, linkStub = false, ptrTy = ptrTy}
  in

  fun externSymbol (externSymbols, ptrTy, symbol) =
      let
        val v = find (externSymbols, ptrTy, symbol)
        val externSymbols = SEnv.insert (externSymbols, symbol, v)
      in
        (externSymbols, R.SYMBOL (ptrTy, R.GLOBAL, symbol))
      end

  fun linkEntrySymbol (externSymbols, ptrTy, symbol) =
      let
        val {linkEntry, linkStub, ptrTy} = find (externSymbols, ptrTy, symbol)
        val v = {linkEntry=true, linkStub=linkStub, ptrTy=ptrTy}
        val externSymbols = SEnv.insert (externSymbols, symbol, v)
      in
        (externSymbols, R.LINK_ENTRY symbol)
      end

  fun linkStubSymbol (externSymbols, symbol) =
      let
        val {linkEntry, linkStub, ptrTy} = find (externSymbols, R.Code, symbol)
        val v = {linkEntry=linkEntry, linkStub=true, ptrTy=ptrTy}
        val externSymbols = SEnv.insert (externSymbols, symbol, v)
      in
        (externSymbols, R.LINK_STUB symbol)
      end

  fun externSymbolInCode (code as {externSymbols,...}:code, ptrTy, symbol) =
      updateExternSymbols (code, externSymbol (externSymbols, ptrTy, symbol))
  fun linkEntrySymbolInCode (code as {externSymbols,...}:code, ptrTy, symbol) =
      updateExternSymbols (code, linkEntrySymbol (externSymbols, ptrTy, symbol))
  fun linkStubSymbolInCode (code as {externSymbols,...}:code, symbol) =
      updateExternSymbols (code, linkStubSymbol (externSymbols, symbol))

  end (* local *)

  fun globalOffsetBase (context:context) code =
      case #globalOffsetBase code of
        SOME (baseLabel, baseReg) => (code, baseLabel, baseReg)
      | NONE =>
        let
          val baseLabel =
              case #positionIndependent (#options context) of
                NONE => raise Control.Bug "globalOffsetBase"
              | SOME ELF => R.ELF_GOT
              | SOME MachO => R.LABEL (VarID.generate ())
              | SOME COFF => raise Control.Bug "globalOffsetBase: COFF"
          val baseReg = newVar (R.Ptr R.Code)
          val code = updateGlobalOffsetBase code (SOME (baseLabel, baseReg))
        in
          (code, baseLabel, baseReg)
        end

  fun calcAddressByBase context code label =
      let
        val (code, baseLabel, baseReg) = globalOffsetBase context code
        val ptrTy = RTLUtils.labelPtrTy label
      in
        (code,
         R.ADDRCAST (ptrTy,
                     R.DISP (R.SYMOFFSET {base=baseLabel,
                                          label=R.LABELCAST (R.Code, label)},
                             R.BASE baseReg)))
      end

  fun loadAddressOfSymbol context code (ptrTy, symbol) =
      let
        val (code, label) = linkEntrySymbolInCode (code, ptrTy, symbol)
        val (code, addr) = calcAddressByBase context code label
        val var = newVar (R.Ptr ptrTy)
        val code = insert (code, [R.MOVE (R.Ptr ptrTy, R.REG var,
                                          R.REF_ (R.MEM (R.Ptr ptrTy,
                                                         R.ADDR addr)))])
      in
        (code, R.BASE var)
      end

  fun absoluteAddr (context:context) (code, label) =
      case #positionIndependent (#options context) of
        NONE => (code, R.ABSADDR label)
      | SOME _ =>
        let
          fun address label =
              case label of
                R.LABEL _ =>
                calcAddressByBase context code label
              | R.SYMBOL (ptrTy, R.LOCAL, sym) =>
                calcAddressByBase context code label
              | R.SYMBOL (ptrTy, R.GLOBAL, sym) =>
                loadAddressOfSymbol context code (ptrTy, sym)
              | R.CURRENT_POSITION =>
                raise Control.Bug "absoluteAddr: CURRENT_POSITION"
              | R.LINK_ENTRY _ =>
                raise Control.Bug "absoluteAddr: LINK_ENTRY"
              | R.LINK_STUB _ =>
                raise Control.Bug "absoluteAddr: LINK_STUB"
              | R.ELF_GOT => (code, R.ABSADDR label)
              | R.NULL _ => (code, R.ABSADDR label)
              | R.LABELCAST (ptrTy, l) =>
                let
                  val (code, addr) = address l
                in
                  (code, R.ADDRCAST (ptrTy, addr))
                end
        in
          address label
        end

  fun dstToValue (R.REG (var as {ty=R.Ptr _,...})) = ADDR (R.BASE var)
    | dstToValue dst = OPRD (R.REF_ dst)

  fun argInfoToValue arg =
      dstToValue (transformArgInfo arg)

  exception NotOperand
  exception NotAddr
  exception NotJump

  fun transformOperand value =
      case value of
        AI.UInt n => R.CONST (R.UINT32 n)
      | AI.SInt n => R.CONST (R.INT32 n)
      | AI.Byte n => R.CONST (R.UINT8 (Word8.fromInt (AI.Target.UIntToInt n)))
      | AI.Var var =>
        let
          val dst = transformVarInfo var
        in
          case RTLUtils.dstTy dst of
            R.Ptr _ => raise NotOperand
          | _ => R.REF_ dst
        end
      | AI.Nowhere => raise NotOperand
      | AI.Null => raise NotOperand
      | AI.Empty => raise NotOperand
      | AI.Const id => raise NotOperand
      | AI.Init id => raise NotOperand
      | AI.Entry entry => raise NotOperand
      | AI.Global label => raise NotOperand
      | AI.Extern label => raise NotOperand
      | AI.Label label => raise NotOperand
      | AI.ExtFunLabel label => raise NotOperand

  fun transformAddr context code value =
      case value of
        AI.UInt n => raise NotAddr
      | AI.SInt n => raise NotAddr
      | AI.Byte n => raise NotAddr
      | AI.Var var =>
        (
          case transformVarInfo var of
            R.REG (v as {ty=R.Ptr _,...}) => (code, R.BASE v)
          | _ => raise NotAddr
        )
      | AI.Nowhere => (code, R.ABSADDR (R.NULL R.Code))
      | AI.Null => (code, R.ABSADDR (R.NULL R.Void))
      | AI.Empty => (code, R.ABSADDR (R.NULL R.Data))
      | AI.Const id =>
        absoluteAddr context (code, dataSymbol (R.Data, R.LOCAL,
                                                constSymbolName id))
      | AI.Init id =>
        absoluteAddr context (code, dataSymbol (R.Void, R.LOCAL,
                                                constSymbolName id))
      | AI.Entry entry =>
        absoluteAddr context (code, entrySymbol entry)
      | AI.Global (label, ty) =>
        (
          case transformTy ty of
            R.Ptr ptrTy =>
            absoluteAddr context
              (code, dataSymbol (ptrTy, R.GLOBAL,
                                 globalSymbolName (#options context) label))
          | _ => raise Control.Bug "transformAddr: AI.Global: not a ptrTy"
        )
      | AI.Extern (label, ty) =>
        (
          case transformTy ty of
            R.Ptr ptrTy =>
            absoluteAddr context
              (externSymbolInCode
                 (code, ptrTy, globalSymbolName (#options context) label))
          | _ => raise Control.Bug "transformAddr: AI.Extern: not a ptrTy"
        )
      | AI.Label label =>
        absoluteAddr context (code, R.LABEL label)
      | AI.ExtFunLabel label =>
        absoluteAddr context (externSymbolInCode (code, R.Code,
                                                  globalSymbolName
                                                    (#options context) label))

  fun transformExtFunLabel (options:options) code label =
      case #positionIndependent options of
        NONE => externSymbolInCode (code, R.Code,
                                    globalSymbolName options label)
      | SOME _ => linkStubSymbolInCode (code, globalSymbolName options label)

  fun transformJumpTo (context:context) code value =
      case value of
        AI.UInt _ => raise NotJump
      | AI.SInt _ => raise NotJump
      | AI.Byte _ => raise NotJump
      | AI.Var var =>
        (
          case transformVarInfo var of
            R.REG (v as {ty=R.Ptr _,...}) => (code, R.BASE v)
          | _ => raise NotJump
        )
      | AI.Nowhere => raise NotJump
      | AI.Null => raise NotJump
      | AI.Empty => raise NotJump
      | AI.Const id => raise NotJump
      | AI.Init id => raise NotJump
      | AI.Entry entry => (code, R.ABSADDR (entrySymbol entry))
      | AI.Global _ => raise NotJump
      | AI.Extern _ => raise NotJump
      | AI.Label label => (code, R.ABSADDR (R.LABEL label))
      | AI.ExtFunLabel label =>
        let
          val (code, label) = transformExtFunLabel (#options context) code label
        in
          (code, R.ABSADDR label)
        end

  fun transformValue context code value =
      (code, OPRD (transformOperand value))
      handle NotOperand =>
             let
               val (code, addr) = transformAddr context code value
             in
               (code, ADDR addr)
             end

  fun transformValueList context code (value::values) =
      let
        val (code, value) = transformValue context code value
        val (code, values) = transformValueList context code values
      in
        (code, value::values)
      end
    | transformValueList context code nil = (code, nil)

  fun newVarList n =
      if n < 0 then raise Control.Bug "newVarList"
      else List.tabulate (n, fn _ => newVar R.NoType)

  local
    fun to8 (R.CONST (R.UINT32 n)) =
        R.CONST (R.UINT8 (Word8.fromInt (Word32.toInt n)))
      | to8 (R.CONST (R.INT32 n)) = R.CONST (R.INT8 (Int32.toInt n))
      | to8 x = x
    fun to16 (R.CONST (R.UINT32 n)) =
        R.CONST (R.UINT16 (Word.fromInt (Word32.toInt n)))
      | to16 (R.CONST (R.INT32 n)) = R.CONST (R.INT16 (Int32.toInt n))
      | to16 x = x
    fun copy code (ty, dst, op1) =
        insert (code,
                [R.COPY {ty=ty, dst=dst, src=op1, clobs=newVarList 1}])
  in

  fun selectMove code (dst, value, size) =
      let
        val dstTy = RTLUtils.dstTy dst
        val srcTy = valueTy value

        val code =
            case (srcTy, dstTy, value, dst) of
              (R.Int8 _, R.Int8 _, OPRD op1, _) =>
              insert (code, [R.MOVE (dstTy, dst, to8 op1)])
            (*
            | (R.Int8 _, R.Int16 s, OPRD op1) =>
              insert (code, [R.EXT8TO16 (s, dst, op1)])
             *)
            | (R.Int8 _, R.Int32 s, OPRD op1, _) =>
              insert (code, [R.EXT8TO32
                               (s, dst, makeCastOperand (op1, R.Int8 s))])
            | (R.Int8 _, _, _, _) => raise Control.Bug "selectMove: Int8"
            (*
            | (R.Int16 _, R.Int8 s, _, OPRD op1) =>
              insert (code, [R.DOWN16TO8 (s, dst, op1)])
            *)
            | (R.Int16 _, R.Int16 _, OPRD op1, _) =>
              insert (code, [R.MOVE (dstTy, dst, to16 op1)])
            (*
            | (R.Int16 _, R.Int32 s, OPRD op1, _) =>
              insert (code, [R.EXT16TO32
                               (s, dst, makeCastOperand (op1, R.Int16 s))])
             *)
            | (R.Int16 _, _, _, _) => raise Control.Bug "selectMove: Int16"
            | (R.Int32 _, R.Int8 s, OPRD op1, _) =>
              insert (code, [R.DOWN32TO8 (s, dst, op1)])
            (*
            | (R.Int32 _, R.Int16 s, OPRD op1, _) =>
              insert (code, [R.DOWN32TO16 (s, dst, op1)])
             *)
            | (R.Int32 s1, R.Int32 s2, OPRD op1, _) =>
              insert (code, [R.MOVE (dstTy, dst, op1)])
            | (R.Int32 _, _, _, _) => raise Control.Bug "selectMove: Int32"
            | (R.Int64 _, _, _, _) => raise Control.Bug "selectMove: Int64"
            | (R.PtrDiff _, R.PtrDiff _, OPRD op1, _) =>
              insert (code, [R.MOVE (dstTy, dst, op1)])
            | (R.PtrDiff _, _, _, _) => raise Control.Bug "selectMove: PtrDiff"
            | (R.Ptr ptrTy, R.Ptr _, ADDR addr, _) =>
              insert (code, [R.MOVEADDR (ptrTy, dst, addr)])
            | (R.Ptr ptrTy, R.Ptr _, OPRD op1, _) =>
              insert (code, [R.MOVE (dstTy, dst, op1)])
            | (R.Ptr _, _, _, _) => raise Control.Bug "selectMove: Ptr"
            | (R.NoType, R.NoType, OPRD op1, _) =>
              insert (code, [R.MOVE (dstTy, dst, op1)])
            | (R.NoType, _, _, _) => raise Control.Bug "selectMove: NoType"
            | (R.Real32, R.Real32, OPRD op1, _) =>
              insert (code, [R.MOVE (R.Real32, dst, op1)])
            | (R.Real32, _, _, _) => raise Control.Bug "selectMove: Real32"
            | (R.Real64, R.Real64, OPRD op1, _) =>
              copy code (dstTy, dst, op1)
            | (R.Real64, _, _, _) => raise Control.Bug "selectMove: Real64"
            | (R.Real80, R.Real80, OPRD op1, _) =>
              copy code (dstTy, dst, op1)
            | (R.Real80, _, _, _) => raise Control.Bug "selectMove: Real80"
              (* load memory to slot *)
            | (R.Generic _, R.Generic _,
               OPRD (op1 as R.REF (_, R.MEM (_, R.ADDR addr))),
               R.MEM (_, R.SLOT slot)) =>
              (
                case size of
                  SOME size =>
                  insert (code, [R.MLOAD
                                   {ty = dstTy,
                                    dst = slot,
                                    srcAddr = addr,      (* esi *)
                                    size = size,         (* ecx *)
                                    defs = newVarList 3, (* edi, esi, ecx *)
                                    clobs = nil}])
                | NONE =>
                  if (case addr of R.PREFRAME _ => true
                                 | R.POSTFRAME _ => true
                                 | _ => false)
                  then copy code (dstTy, dst, op1)
                  else raise Control.Bug "selectMove: Generic load"
              )
            | (R.Generic _, R.Generic _,
               OPRD (op1 as R.REF (_, R.MEM (_, R.SLOT slot))),
               R.MEM (_, R.ADDR addr)) =>
              (
                case size of
                  SOME size =>
                  insert (code, [R.MSTORE
                                   {ty = dstTy,
                                    dstAddr = addr,     (* edi *)
                                    src = slot,
                                    size = size,        (* ecx *)
                                    global = true,
                                    defs = newVarList 3, (* edi, esi, ecx *)
                                    clobs = nil}])
                | NONE =>
                  if (case addr of R.PREFRAME _ => true
                                 | R.POSTFRAME _ => true
                                 | _ => false)
                  then copy code (dstTy, dst, op1)
                  else raise Control.Bug "selectMove: Generic store"
              )
            | (R.Generic _, R.Generic _,
               OPRD (op1 as R.REF (_, R.MEM (_, R.SLOT _))),
               R.MEM (_, R.SLOT _)) =>
              copy code (dstTy, dst, op1)
            | (R.Generic _, _, _, _) =>
              raise Control.Bug "selectMove: Generic"
      in
        code
      end

  end (* local *)

  fun selectMoveList code (dst::dsts, value::values, sizes) =
      let
        val (size, sizes) = case sizes of h::t => (h, t)
                                        | nil => (NONE, nil)
        val code = selectMove code (dst, value, size)
      in
        selectMoveList code (dsts, values, sizes)
      end
    | selectMoveList code (nil, nil, nil) = code
    | selectMoveList code _ = raise Control.Bug "selectMoveList"

  fun coerceToVar code value =
      case value of
        OPRD (R.REF (R.N, R.REG v)) => (code, v)
      | ADDR (R.BASE v) => (code, v)
      | _ =>
        let
          val ty = valueTy value
          val v = newVar ty
          val code = selectMove code (R.REG v, value, NONE)
        in
          (code, v)
        end

  fun coerceToMem code (OPRD (R.REF (R.N, R.MEM (ty, mem)))) =
      (code, ty, mem)
    | coerceToMem code (OPRD (R.REF (R.CAST ty, R.MEM (_, mem)))) =
      (code, ty, mem)
    | coerceToMem code value =
      let
        val ty = valueTy value
        val mem = R.SLOT (newSlot (X86Emit.formatOf ty))
        val code = selectMove code (R.MEM (ty, mem), value, NONE)
      in
        (code, ty, mem)
      end

  fun coerceDstToVar (R.REG v) = (fn code => code, v)
    | coerceDstToVar dst =
      let
        val ty = RTLUtils.dstTy dst
        val v = newVar ty
      in
        (fn code => selectMove code (dst, OPRD (R.REF_ (R.REG v)), NONE), v)
      end

  fun coerceDstToMem (R.MEM (ty, mem)) = (fn code => code, ty, mem)
    | coerceDstToMem dst =
      let
        val ty = RTLUtils.dstTy dst
        val mem = R.SLOT (newSlot (X86Emit.formatOf ty))
      in
        (fn code =>
            selectMove code (dst, OPRD (R.REF_ (R.MEM (ty, mem))), NONE),
         ty, mem)
      end

  (*
   * Structure of stack frame and calling convension:
   *
   * = ML functions
   *
   * addr
   *   | :               :
   *   | +-=-=-=-=-=-=-=-+ post 0          <------ my %esp [align 16]
   *   | | 1st arg       |
   *   | +---------------+ post 16
   *   | | ...           |
   *   | +---------------+ post 16(m-1)
   *   | | Nth arg       |
   *   | +-=-=-=-=-=-=-=-+ post 16m        <------ %esp after call [align 16]
   *   | | 1st ret       |
   *   | +---------------+ post 16(m+1)
   *   | | ...           |
   *   | +---------------+ post 16(m+n-1)
   *   | | Mth ret       |
   *   | +---------------+ post 16(m+n)
   *   | |               | (space for arguments)
   *   | +===============+ post 16(m+n+p)  [align 16]
   *   | | Frame         |
   *   | |               |
   *   | +---------------+
   *   | | headaddr      |
   *   | +===============+ pre 16(m+n+p)+8 <------ my %ebp  [align 8]
   *   | | prev ebp      |
   *   | +---------------+ pre 16(m+n+p)+4
   *   | |               | (padding if needed)
   *   | +---------------+ pre 16(m+n)+4
   *   | | return addr   |
   *   | +-=-=-=-=-=-=-=-+ pre 16(m+n)     <------ caller's %esp [align 16]
   *   | | 1st param     |
   *   | +---------------+ pre 16(m+n-1)
   *   | | ...           |
   *   | +---------------+ pre 16(m+1)
   *   | | Nth param     |
   *   | +-=-=-=-=-=-=-=-+ pre 16m         <------ %esp after return [align 16]
   *   | | 1st ret       |
   *   | +---------------+ pre 16(m-1)
   *   | | ...           |
   *   | +---------------+ pre 16
   *   | | Mth ret       |
   *   | +---------------+ pre 0
   *   v :               :
   *)

  local
    fun postFrameOffset (off, ty::tys) =
        R.MEM (promoteIntTy ty,
         R.ADDR (R.POSTFRAME {offset = off, size = genericSize ()}))
        :: postFrameOffset (off + genericSize (), tys)
      | postFrameOffset (off, nil) = nil

    fun preFrameOffset (off, ty::tys) =
        let
          val (off, addrs) = preFrameOffset (off, tys)
        in
          (off + genericSize (),
           R.MEM (promoteIntTy ty,
            R.ADDR (R.PREFRAME {offset = off + genericSize (),
                                size = genericSize ()}))
           :: addrs)
        end
      | preFrameOffset (off, nil) = (off, nil)

    fun mlArgs (argTys:R.ty list, retTys:R.ty list) =
        postFrameOffset (0, argTys)
    fun mlRets (argTys:R.ty list, retTys:R.ty list) =
        postFrameOffset (length argTys * genericSize (), retTys)
    fun mlParams (argTys:R.ty list, retTys:R.ty list) =
        #2 (preFrameOffset (length retTys * genericSize (), argTys))
    fun mlResults (argTys:R.ty list, retTys:R.ty list) =
        #2 (preFrameOffset (0, retTys))
  in

  val mlParams = mlParams
  fun mlPreFrameSize (argTys:R.ty list, retTys:R.ty list) =
      genericSize () * (length retTys + length argTys)
  fun mlPreFrameRetSize (retTys:R.ty list) =
      genericSize () * length retTys
  fun mlPostFrameSize (argTys:R.ty list, retTys:R.ty list) =
      genericSize () * (length retTys + length argTys)
  fun adjustMLPostFrame (argTys, retTys) =
      genericSize () * length argTys

  fun setMLArgs code (argTys, retTys) (env, argValues) =
      let
        val code = selectMoveList code (mlArgs (argTys, retTys), argValues, nil)
        val (code, envVar) = coerceToVar code (OPRD (R.REF_ env))
        val code = requirePostFrame (code, mlPostFrameSize (argTys, retTys))
      in
        (code, [envVar])
      end

  fun getMLRets (argTys, retTys) dsts =
      let
        val srcs = map (fn dst => OPRD (R.REF_ dst)) (mlRets (argTys, retTys))
      in
        (fn code =>
            let
              val code =
                  requirePostFrame (code, mlPostFrameSize (argTys, retTys))
            in
              selectMoveList code (dsts, srcs, nil)
            end,
          nil)
      end

  fun getMLArgs (argTys, retTys) (env, dsts) =
      let
        val (set, defs) =
            case env of
              NONE => (fn code => code, nil)
            | SOME v =>
              let
                val (sets, v) = coerceDstToVar v
              in
                (sets, [v])
              end

        val srcs = map (fn dst => OPRD (R.REF_ dst)) (mlParams (argTys, retTys))
      in
        (fn code =>
            let
              val code = requirePreFrame (code, mlPreFrameSize (argTys, retTys))
              val code = selectMoveList code (dsts, srcs, nil)
            in
              set code
            end,
         defs)
      end

  fun setMLRets code (argTys, retTys) retValues =
      let
        val dsts = mlResults (argTys, retTys)
        val code = selectMoveList code (dsts, retValues, nil)
        val code = requirePreFrame (code, mlPreFrameSize (argTys, retTys))
      in
        (code, nil)
      end

  fun setMLTailCallArgs code (argTys, retTys) (env, argValues) =
      let
        val dsts = mlParams (argTys, retTys)
        val code = selectMoveList code (dsts, argValues, nil)
        val code = requirePreFrame (code, mlPreFrameSize (argTys, retTys))
        val (code, envVar) = coerceToVar code (OPRD (R.REF_ env))
      in
        (code, [envVar])
      end

  end (* local *)

  (*
   * = cdecl and stdcall
   *
   * addr
   *   | :               :
   *   | +-=-=-=-=-=-=-=-+ post 0       <-------- my %esp [align 16]
   *   | | 1st arg       |
   *   | +---------------+ post sz1
   *   | | ...           |
   *   | +---------------+ post sz1+...+sz(N-1)
   *   | | Nth arg       |
   *   | +---------------+ post sz1+...+szN
   *   | | pad           | (space for arguments)
   *   | | (if needed)   |
   *   | +===============+ post sz1+...+szN+p  [align 16]
   *   | | Frame         |
   *   | |               |
   *   | +---------------+
   *   | | headaddr      |
   *   | +===============+ pre sz1+...+szN+8+p <------ my %ebp  [align 8]
   *   | | prev ebp      |
   *   | +---------------+ pre sz1+...+szN+4+p   [align 4]
   *   | |               | (for alignment; tail-call is not available for C)
   *   | +---------------+ pre sz1+...+szN+4
   *   | | return addr   |
   *   | +-=-=-=-=-=-=-=-+ pre sz1+...+szN <------ caller's %esp
   *   | | 1st param     |
   *   | +---------------+ pre sz2+...+sz(N-1)
   *   | | ...           |
   *   | +---------------+ pre szN
   *   | | Nth param     |
   *   | +---------------+ pre 0
   *   v :               :
   *)

  local
    fun postFrameOffset (off, ty::tys) =
        let
          val ty = promoteIntTy ty
          val size = sizeof ty
        in
          R.MEM (ty, R.ADDR (R.POSTFRAME {offset = off, size = size}))
          :: postFrameOffset (off + size, tys)
        end
      | postFrameOffset (off, nil) = nil
    fun preFrameOffset base (off, ty::tys) =
        let
          val ty = promoteIntTy ty
          val size = sizeof ty
          val (off, addrs) = preFrameOffset base (off, tys)
        in
          (off + size,
           R.MEM (ty, R.ADDR (base {offset = off + size, size = size}))
           :: addrs)
        end
      | preFrameOffset base (off, nil) = (off, nil)

    fun cdeclArgs argTys =
        postFrameOffset (0, argTys)
    fun cdeclParams base argTys =
        #2 (preFrameOffset base (0, argTys))

    fun cdeclPreFrameSize (argTys, retTys) =
        if length retTys <= 1
        then foldl (fn (ty, z) => sizeof (promoteIntTy ty) + z)
                   0
                   argTys
        else raise Control.Bug "FIXME: cdeclPreFrameSize > 1"
    fun cdeclPostFrameSize (argTys, retTys) =
        if length retTys <= 1
        then foldl (fn (ty, z) => sizeof (promoteIntTy ty) + z) 0 argTys
        else raise Control.Bug "FIXME: cdeclPreFrameSize > 1"

  in

  fun setCArgs code (NONE, argTys, retTys) argValues =
      setCArgs code (SOME Absyn.FFI_CDECL, argTys, retTys) argValues
    | setCArgs code (SOME Absyn.FFI_STDCALL, argTys, retTys) argValues =
      setCArgs code (SOME Absyn.FFI_CDECL, argTys, retTys) argValues
    | setCArgs code (SOME Absyn.FFI_CDECL, argTys, retTys) argValues =
      let
        val code = selectMoveList code (cdeclArgs argTys, argValues, nil)
        val code = requirePostFrame (code, cdeclPostFrameSize (argTys, retTys))
      in
        (code, nil)
      end

  fun getCRets (NONE, argTys, retTys) dsts =
      getCRets (SOME Absyn.FFI_CDECL, argTys, retTys) dsts
    | getCRets (SOME Absyn.FFI_STDCALL, argTys, retTys) dsts =
      getCRets (SOME Absyn.FFI_CDECL, argTys, retTys) dsts
    | getCRets (SOME Absyn.FFI_CDECL, argTys, [retTy]) [dst] =
      (
        case (promoteIntTy retTy, dst) of
          (R.Int8 _, _) => raise Control.Bug "getCRets: Int8"
        | (R.Int16 _, _) => raise Control.Bug "getCRets: Int16"
        | (R.Int32 _, R.REG var) => (fn code => code, [var])
        | (R.Int32 _, _) => raise Control.Bug "getCRets: Int32"
        | (R.Int64 _, _) => raise Control.Bug "getCRets: Int64"
        | (R.Real32, R.MEM (_, mem)) =>
          (fn code => insert (code, [R.X86 (R.X86FSTP (R.Real32, mem))]), nil)
        | (R.Real32, _) => raise Control.Bug "getCRets: Real32"
        | (R.Real64, R.MEM (_, mem)) =>
          (fn code => insert (code, [R.X86 (R.X86FSTP (R.Real64, mem))]), nil)
        | (R.Real64, _) => raise Control.Bug "getCRets: Real64"
        | (R.Real80, R.MEM (_, mem)) =>
          (fn code => insert (code, [R.X86 (R.X86FSTP (R.Real80, mem))]), nil)
        | (R.Real80, _) => raise Control.Bug "getCRets: Real80"
        | (R.Ptr _, R.REG var) => (fn code => code, [var])
        | (R.Ptr _, _) => raise Control.Bug "getCRets: Ptr"
        | (R.PtrDiff _, _) => raise Control.Bug "getCRets: PtrDiff"
        | (R.Generic _, _) => raise Control.Bug "getCRets: Generic"
        | (R.NoType, _) => raise Control.Bug "getCRets: NoType"
      )
    | getCRets (SOME Absyn.FFI_CDECL, argTys, nil) nil =
      (fn code => code, nil)
    | getCRets (SOME Absyn.FFI_CDECL, argTys, retTys) dsts =
      raise Control.Bug "getCRets: FIXME: multiple return values"

  fun adjustCPostFrame (NONE, argTys, retTys) =
      adjustCPostFrame (SOME Absyn.FFI_CDECL, argTys, retTys)
    | adjustCPostFrame (SOME Absyn.FFI_CDECL, argTys, retTys) = 0
    | adjustCPostFrame (SOME Absyn.FFI_STDCALL, argTys, retTys) =
      cdeclPostFrameSize (argTys, retTys)

  fun getCArgs (NONE, argTys, retTys) base dsts =
      getCArgs (SOME Absyn.FFI_CDECL, argTys, retTys) base dsts
    | getCArgs (SOME Absyn.FFI_STDCALL, argTys, retTys) base dsts =
      getCArgs (SOME Absyn.FFI_CDECL, argTys, retTys) base dsts
    | getCArgs (SOME Absyn.FFI_CDECL, argTys, retTys) base dsts =
      if length retTys > 1
      then raise Control.Bug "FIXME: # of retTys of getCArgs > 1"
      else
        let
          val baseFn =
              case base of
                NONE => R.PREFRAME
              | SOME baseVar =>
                let
                  val preFrameSize = cdeclPreFrameSize (argTys, retTys)
                in
                  fn {offset, size} =>
                     R.DISP (R.INT32
                               (Int32.fromInt (preFrameSize + 8 - offset)),
                             R.BASE baseVar)
                end
          val srcs = map (fn dst => OPRD (R.REF_ dst))
                         (cdeclParams baseFn argTys)
        in
          (fn code => selectMoveList code (dsts, srcs, nil), nil)
        end

  fun setCRets code (NONE, argTys, retTys) retValues =
      setCRets code (SOME Absyn.FFI_CDECL, argTys, retTys) retValues
    | setCRets code (SOME Absyn.FFI_STDCALL, argTys, retTys) retValues =
      setCRets code (SOME Absyn.FFI_CDECL, argTys, retTys) retValues
    | setCRets code (SOME Absyn.FFI_CDECL, argTys, [retTy]) [value] =
      let
        fun returnEAX () =
            let
              val (code, v) = coerceToVar code value
            in
              (code, [v])
            end
        fun returnST0 ty =
            let
              val (code, _, mem) = coerceToMem code value
              val code = insert (code, [R.X86 (R.X86FLD (ty, mem))])
            in
              (code, nil)
            end
      in
        case promoteIntTy retTy of
          R.Int8 _ => raise Control.Bug "setCRets: Int8"
        | R.Int16 _ => raise Control.Bug "setCRets: Int16"
        | R.Int32 _ => returnEAX ()
        | R.Int64 _ => raise Control.Bug "setCRets: Int64"
        | R.Real32 => returnST0 R.Real32
        | R.Real64 => returnST0 R.Real64
        | R.Real80 => returnST0 R.Real80
        | R.Ptr _ => returnEAX ()
        | R.PtrDiff _ => raise Control.Bug "setCRets: PtrDiff"
        | R.Generic _ => raise Control.Bug "setCRets: Generic"
        | R.NoType => raise Control.Bug "setCRets: NoType"
      end
    | setCRets code (SOME Absyn.FFI_CDECL, argTys, nil) nil = (code, nil)
    | setCRets code (SOME Absyn.FFI_CDECL, argTys, retTys) retValues =
      raise Control.Bug "setCRets: FIXME: multiple return values"

  fun cPreFrameRetSize (aligned, NONE, argTys, retTys) =
      cPreFrameRetSize (aligned, SOME Absyn.FFI_CDECL, argTys, retTys)
    | cPreFrameRetSize (false, SOME Absyn.FFI_CDECL, argTys, retTys) = 0
    | cPreFrameRetSize (true, SOME Absyn.FFI_CDECL, argTys, retTys) =
      cdeclPreFrameSize (argTys, retTys)
    | cPreFrameRetSize (aligned, SOME Absyn.FFI_STDCALL, argTys, retTys) = 0

  fun cPreFrameSize (aligned, NONE, argTys, retTys) =
      cPreFrameSize (aligned, SOME Absyn.FFI_CDECL, argTys, retTys)
    | cPreFrameSize (false, SOME Absyn.FFI_CDECL, argTys, retTys) = 0
    | cPreFrameSize (true, SOME Absyn.FFI_CDECL, argTys, retTys) =
      cdeclPreFrameSize (argTys, retTys)
    | cPreFrameSize (false, SOME Absyn.FFI_STDCALL, argTys, retTys) = 0
    | cPreFrameSize (true, SOME Absyn.FFI_STDCALL, argTys, retTys) =
      cdeclPreFrameSize (argTys, retTys)

  end (* local *)

  fun selectAddr context code (block, offset) =
      let
        val (code, block) = transformAddr context code block
        val offset= transformOperand offset
        fun add (block, R.CONST (R.UINT32 0w0)) = block
          | add (block, R.CONST const) = R.DISP (const, block)
          | add (R.ABSADDR label, R.REF (R.N, R.REG var)) =
            R.ABSINDEX {base=label, scale=1, index=var}
          | add (R.DISP (c, addr), op1) = R.DISP (c, add (addr, op1))
          | add (R.BASE base, R.REF (R.N, R.REG index)) =
            R.BASEINDEX {base=base, index=index, scale=1}
          | add _ = raise Control.Bug "selectAddr"
      in
        (code, block, add (block, offset))
      end

  fun selectCall (context:context) code
                 {callTo, retRegs, argRegs, needStabilize, returnTo,
                  postFrameAdjust} =
      let
        val defs = retRegs @ newVarList (3 - length retRegs)
        fun call l =
            R.CALL {callTo = callTo,
                    returnTo = l,
                    handler = #handler context,
                    defs = defs,                 (* precolor: eax, edx, ecx *)
                    uses = argRegs,              (* precolor: eax, edx, ecx *)
                    needStabilize = needStabilize,
                    postFrameAdjust = postFrameAdjust}
      in
        case returnTo of
          NONE => insertLastBefore (code, call)
        | SOME l =>
          let
            val focus = RTLEdit.insertLast (#focus code, call l)
            val code = updateFocus code focus
          in
            focusFirst (code, l)
          end
      end

  fun selectPrimCall context code
                     {callTo, retRegs, argRegs, needStabilize, returnTo} =
      let
        val (code, callTo) =
            transformJumpTo context code (AI.ExtFunLabel callTo)
      in
        selectCall context code
                   {callTo = callTo,
                    retRegs = retRegs,
                    argRegs = argRegs,
                    needStabilize = needStabilize,
                    returnTo = returnTo,
                    postFrameAdjust = 0}
      end

  fun pushHandler context code handlerLabel loc =
      let
        val (code, handlerAddr) =
            absoluteAddr context (code, R.LABEL handlerLabel)
        val (code, v) = coerceToVar code (ADDR handlerAddr)
        val (code, slot) = handlerSlot (code, handlerLabel)
        val v = newVar (R.Ptr R.Void)
        fun handlerInfo ptrTy disp =
            R.MEM (R.Ptr ptrTy, R.ADDR (R.DISP (R.INT32 disp, R.BASE v)))
        val code =
            insert (code, [R.REQUEST_SLOT slot,
                           R.MOVEADDR (R.Void, R.REG v, R.WORKFRAME slot),
                           R.MOVEADDR (R.Code, handlerInfo R.Code 4,
                                       handlerAddr),
                           R.LOAD_SP (handlerInfo R.Void 8),
                           R.LOAD_FP (handlerInfo R.Void 12)])
      in
        selectPrimCall context code
                       {callTo = "sml_push_handler",
                        retRegs = nil,
                        argRegs = [v],
                        needStabilize = false,
                        returnTo = NONE}
      end

  fun popHandler context code handlerLabel loc =
      let
        val code =
            selectPrimCall context code
                           {callTo = "sml_pop_handler",
                            argRegs = nil,
                            retRegs = nil,
                            needStabilize = false,
                            returnTo = NONE}
        val (code, slot) = handlerSlot (code, handlerLabel)
      in
        insert (code, [R.REQUIRE_SLOT slot])
      end

  fun selectRaise (context:context) code exnVar infoVar =
      let
        fun handlerInfo ptrTy disp =
            R.MEM (R.Ptr ptrTy, R.ADDR (R.DISP (R.INT32 disp, R.BASE infoVar)))
        val v2 = newVar (R.Ptr R.Code)
        val code =
            insert (code, [R.MOVE (R.Ptr R.Code, R.REG v2,
                                   R.REF_ (handlerInfo R.Code 4))])
      in
        insertLast
          (code, R.UNWIND_JUMP {jumpTo = R.BASE v2,
                                sp = R.REF_ (handlerInfo R.Void 8),
                                fp = R.REF_ (handlerInfo R.Void 12),
                                uses = [exnVar],  (* precolor: eax *)
                                handler = #handler context})
      end

  fun startThread context code =
      let
        val fp = newVar (R.Ptr R.Void)
        val code = insert (code, [R.LOAD_FP (R.REG fp)])
        val code = selectPrimCall context code
                                  {callTo = "sml_control_start",
                                   retRegs = [],
                                   argRegs = [fp],
                                   needStabilize = false,
                                   returnTo = NONE}
      in
        code
      end

  fun saveFramePointer context code =
      let
        val v = newVar (R.Ptr R.Void)
        val code = insert (code, [R.LOAD_FP (R.REG v)])
      in
        selectPrimCall context code
                       {callTo = "sml_save_frame_pointer",
                        retRegs = nil,
                        argRegs = [v],
                        needStabilize = false,
                        returnTo = NONE}
      end

  fun checkGC context code =
      if !Control.insertCheckGC then
      let
        val addr = AI.Extern ("sml_check_gc_flag", AI.CPOINTER)
        val (code, addr) = transformAddr context code addr
        val (code, endLabel) = makeLabelAfter code
        val test =
            R.TEST_SUB (R.Int32 R.U, R.REF_ (R.MEM (R.Int32 R.U, R.ADDR addr)),
                        R.CONST (R.UINT32 0w0))
        val code = insertLastBefore
                     (code, fn l => R.CJUMP {test = test,
                                             cc = R.EQUAL,
                                             thenLabel = endLabel,
                                             elseLabel = l})
        val fp = newVar (R.Ptr R.Void)
        val code = insert (code, [R.LOAD_FP (R.REG fp)])
        val code =
            selectPrimCall context code
                           {callTo = "sml_check_gc",
                            retRegs = nil,
                            argRegs = [fp],
                            needStabilize = true,
                            returnTo = SOME endLabel}
      in
        code
      end
      else code

  local
    fun opInsn (insn, oper) code (R.CONST (R.UINT32 x), R.CONST (R.UINT32 y)) =
        (code, R.CONST (R.UINT32 (oper (x, y))))
      | opInsn (insn, oper) code (op1, op2) =
        let
          val v = newDst (R.Int32 R.U)
          val code = insert (code, [insn (R.Int32 R.U, v, op1, op2)])
        in
          (code, R.REF_ v)
        end
    fun lshift (x,y) = x << Word.fromInt (Word32.toIntX y)

    fun addInsn code x = opInsn (R.ADD, Word32.+) code x
    fun orInsn code x = opInsn (R.OR, Word32.orb) code x
    fun andInsn code x = opInsn (R.AND, Word32.andb) code x
    fun lshiftInsn code x = opInsn (R.LSHIFT, lshift) code x

  in

  fun selectAlloc allocFunc context code
                  (dst, objectType, bitmaps, payloadSize) =
      let
        val wordSize = Word32.fromInt (sizeof (R.Int32 R.U))

        val dstVar =
            case dst of
              R.REG v => v
            | _ => raise Control.Bug "selectAlloc"

        val {objType, bittag, bitmaps, bitmapSize} =
            case (objectType, bitmaps) of
              (AI.Array, [bitmap]) =>
              {objType = R.UINT32 HEAD_TYPE_ARRAY,
               bittag = bitmap,
               bitmaps = nil,
               bitmapSize = R.UINT32 0w0}
            | (AI.Array, _) => raise Control.Bug "selectAlloc: Array"
            | (AI.Vector, [bitmap]) =>
              {objType = R.UINT32 HEAD_TYPE_VECTOR,
               bittag = bitmap,
               bitmaps = nil,
               bitmapSize = R.UINT32 0w0}
            | (AI.Vector, _) => raise Control.Bug "selectAlloc: Vector"
            | (AI.Record _, _) =>
              {objType = R.UINT32 HEAD_TYPE_RECORD,
               bittag = R.CONST (R.UINT32 0w0),
               bitmaps = bitmaps,
               bitmapSize =
                 R.UINT32 (wordSize * Word32.fromInt (length bitmaps))}

        val (code, bitmapOffset, allocSize) =
            case bitmapSize of
              R.UINT32 0w0 =>
              (code, payloadSize, payloadSize)
            | _ =>
              let
                (* align payload size in word *)
                val (code, bitmapOffset) =
                    addInsn code (payloadSize, R.CONST (R.UINT32 0w3))
                val (code, bitmapOffset) =
                    andInsn code (bitmapOffset,
                                  R.CONST (R.UINT32 (Word32.notb 0w3)))
                val (code, allocSize) =
                    addInsn code (bitmapOffset, R.CONST bitmapSize)
              in
                (code, bitmapOffset, allocSize)
              end

        (* alloc object *)
        val (code, allocSizeVar) = coerceToVar code (OPRD allocSize)
        val code = allocFunc (context, code, allocSizeVar, dstVar)

        (* store header *)
        val (code, header) =
            lshiftInsn code (bittag, R.CONST (R.UINT32 HEAD_BITTAG_SHIFT))
        val (code, header) = orInsn code (header, R.CONST objType)
        val (code, header) = orInsn code (header, payloadSize)
        val headerAddr = R.DISP (R.INT32 ~4, R.BASE dstVar)
        val code =
            insert (code, [R.MOVE (R.Int32 R.U,
                                   R.MEM (R.Int32 R.U, R.ADDR headerAddr),
                                   header)])

        (* store bitmaps *)
        val bitmapAddr =
            case bitmapOffset of
              R.CONST c => R.DISP (c, R.BASE dstVar)
            | R.REF (R.N, R.REG v) =>
              R.BASEINDEX {base=dstVar, index=v, scale=1}
            | R.REF _ => raise Control.Bug "selectAlloc: bitmapAddr REF"

        fun disp (R.UINT32 0w0, addr) = addr
          | disp (off, addr) = R.DISP (off, addr)

        fun storeBitmap code (off, bitmap::bitmaps) =
            storeBitmap
              (selectMove code
                          (R.MEM (R.Int32 R.U,
                                  R.ADDR (disp (R.UINT32 off, bitmapAddr))),
                           OPRD bitmap, NONE))
              (off + wordSize, bitmaps)
          | storeBitmap code (off, nil) = code

        val code = storeBitmap code (0w0, bitmaps)
      in
        {
          code = code,
          header = header,
          bitmapOffset = bitmapOffset,
          bitmaps = bitmaps,
          allocSize = allocSize
        }
      end

  fun callAlloc (context, code, sizeVar, dstVar) =
      let
        val fp = newVar (R.Ptr R.Void)
        val code = insert (code, [R.LOAD_FP (R.REG fp)])
        val code = selectPrimCall context code
                                  {callTo = "sml_alloc",
                                   retRegs = [dstVar],
                                   argRegs = [sizeVar, fp],
                                   needStabilize = true,
                                   returnTo = NONE}
      in
        code
      end

  fun callAllocCallback codeAddrVar envVar (context, code, sizeVar, dstVar) =
      let
        val code = saveFramePointer context code
        val code = selectPrimCall context code
                                  {callTo = "sml_alloc_callback",
                                   retRegs = [dstVar],
                                   argRegs = [sizeVar, codeAddrVar, envVar],
                                   needStabilize = true,
                                   returnTo = NONE}
      in
        code
      end

  end (* local *)

  local
    fun cmpFloat code (oper, value1, value2) =
        let
          val (code, ty1, mem1) = coerceToMem code value1
          val (code, ty2, mem2) = coerceToMem code value2
          (*
           * v1 > v2              --> st(0)=v1, st(1)=v2, st(0) > st(1)
           * v1 >= v2             --> st(0)=v1, st(1)=v2, st(0) >= st(1)
           * v1 = v2              --> st(0)=v1, st(1)=v2, st(0) = st(1)
           * v1 < v2  == v2 > v1  --> st(0)=v2, st(1)=v1, st(0) > st(1)
           * v1 <= v2 == v2 >= v1 --> st(0)=v2, st(1)=v1, st(0) >= st(1)
           *
           *            C3:14 C2:10 C0:8
           * st0 > src    0     0     0
           * st0 < src    0     0     1
           * st0 = src    1     0     0
           * unordered    1     1     1
           *
           * >   : hi & 0b01000101 == 0
           * >=  : hi & 0b00000101 == 0
           * ==  : hi & 0b01000101 == 0b01000000
           * ?=  : hi & 0b01000000 == 0
           *)
          val clob = newVar (R.Int16 R.U)  (* ax *)
          val (cmp, st0, st1) =
              case oper of
                AI.Gt =>
                (R.X86FSW_TESTH {clob=clob, mask=R.UINT8 0wx45},
                 (ty1, mem1), (ty2, mem2))
              | AI.Gteq =>
                (R.X86FSW_TESTH {clob=clob, mask=R.UINT8 0wx5},
                 (ty1, mem1), (ty2, mem2))
              | AI.Lt =>
                (R.X86FSW_TESTH {clob=clob, mask=R.UINT8 0wx45},
                 (ty2, mem2), (ty1, mem1))
              | AI.Lteq =>
                (R.X86FSW_TESTH {clob=clob, mask=R.UINT8 0wx5},
                 (ty2, mem2), (ty1, mem1))
              | AI.MonoEqual =>
                (R.X86FSW_MASKCMPH {clob=clob, mask=R.UINT8 0wx45,
                                    compare=R.UINT8 0wx40},
                 (ty1, mem1), (ty2, mem2))
              | AI.UnorderedOrEqual =>
                (R.X86FSW_TESTH {clob=clob, mask=R.UINT8 0wx40},
                 (ty1, mem1), (ty2, mem2))
              | _ => raise Control.Bug "selectCompare: cmpFloat"
          val code = insert (code, [R.X86 (R.X86FLD st1),
                                    R.X86 (R.X86FLD st0),
                                    R.X86 R.X86FUCOMPP])
        in
          (code, R.X86 cmp, R.EQUAL)
        end
  in

  fun selectCompare code (operator, ty1, ty2, _) (arg1, arg2) =
      let
        val ty1 = valueTy arg1
        val ty2 = valueTy arg2
      in
        case (operator, promoteIntTy ty1, promoteIntTy ty2, arg1, arg2) of
          (AI.Gt, R.Int32 R.S, R.Int32 R.S, OPRD op1, OPRD op2) =>
          (code, R.TEST_SUB (ty1, op1, op2), R.GREATER)
        | (AI.Lt, R.Int32 R.S, R.Int32 R.S, OPRD op1, OPRD op2) =>
          (code, R.TEST_SUB (ty1, op1, op2), R.LESS)
        | (AI.Gteq, R.Int32 R.S, R.Int32 R.S, OPRD op1, OPRD op2) =>
          (code, R.TEST_SUB (ty1, op1, op2), R.GREATEREQUAL)
        | (AI.Lteq, R.Int32 R.S, R.Int32 R.S, OPRD op1, OPRD op2) =>
          (code, R.TEST_SUB (ty1, op1, op2), R.LESSEQUAL)
        | (AI.Gt, R.Int32 R.U, R.Int32 R.U, OPRD op1, OPRD op2) =>
          (code, R.TEST_SUB (ty1, op1, op2), R.ABOVE)
        | (AI.Lt, R.Int32 R.U, R.Int32 R.U, OPRD op1, OPRD op2) =>
          (code, R.TEST_SUB (ty1, op1, op2), R.BELOW)
        | (AI.Gteq, R.Int32 R.U, R.Int32 R.U, OPRD op1, OPRD op2) =>
          (code, R.TEST_SUB (ty1, op1, op2), R.ABOVEEQUAL)
        | (AI.Lteq, R.Int32 R.U, R.Int32 R.U, OPRD op1, OPRD op2) =>
          (code, R.TEST_SUB (ty1, op1, op2), R.BELOWEQUAL)
        | (AI.MonoEqual, R.Int32 _, R.Int32 _, OPRD op1, OPRD op2) =>
          (code, R.TEST_SUB (ty1, op1, op2), R.EQUAL)
        | (oper, R.Real32, R.Real32, _, _) => cmpFloat code (oper, arg1, arg2)
        | (oper, R.Real64, R.Real64, _, _) => cmpFloat code (oper, arg1, arg2)
        | (oper, R.Real80, R.Real80, _, _) => cmpFloat code (oper, arg1, arg2)
        | (AI.MonoEqual, R.Ptr ptrTy, R.Ptr _, ADDR a1, ADDR a2) =>
          (
            case (a1, a2) of
              (R.BASE v1, R.BASE v2) =>
              (code,
               R.TEST_SUB (ty1, R.REF_ (R.REG v1), R.REF_ (R.REG v2)),
               R.EQUAL)
            | (R.BASE v1, R.ABSADDR l) =>
              (code, R.TEST_LABEL (ptrTy, R.REF_ (R.REG v1), l), R.EQUAL)
            | _ =>
              let
                val (code, v1) = coerceToVar code arg1
                val (code, v2) = coerceToVar code arg2
              in
                (code,
                 R.TEST_SUB (ty1, R.REF_ (R.REG v1), R.REF_ (R.REG v2)),
                 R.EQUAL)
              end
          )
        | (op2, ty1, ty2, _, _) =>
          raise Control.Bug
                  ("selectCompare: " ^
                   Control.prettyPrint (AI.format_op2 (R.format_ty ty1,
                                                       R.format_ty ty2) op2))
      end

  end (* local *)

  fun insertWithHandle (context:context) code insn =
      case #handler context of
        R.NO_HANDLER => insert (code, [insn])
      | h as R.HANDLER _ =>
        insertLastBefore
          (code, fn l => R.HANDLE (insn, {nextLabel = l, handler = h}))

  fun quotremUInt context code (ddiv, dmod, op1, op2) =
      let
        val (code, hi) = coerceToVar code (OPRD (R.CONST (R.UINT32 0w0)))
        val (code, lo) = coerceToVar code (OPRD op1)
        val arg1 = R.COUPLE (R.Int64 R.U, {hi=R.REG hi, lo=R.REG lo})
      in
        insertWithHandle context code
                         (R.DIVMOD ({div=(R.Int32 R.U, ddiv),
                                     mod=(R.Int32 R.U, dmod)},
                                    (R.Int64 R.U, R.REF_ arg1),
                                    (R.Int32 R.U, op2)))
      end

  fun quotrem context code (ddiv, dmod, op1, op2) =
      let
        val hi = newDst R.NoType
        val lo = newDst R.NoType
        val arg1 = R.COUPLE (R.Int64 R.S, {hi=hi, lo=lo})
        val code = insert (code, [R.EXT32TO64 (R.S, arg1, op1)])
      in
        insertWithHandle context code
                         (R.DIVMOD ({div=(R.Int32 R.S, ddiv),
                                     mod=(R.Int32 R.S, dmod)},
                                    (R.Int64 R.S, R.REF_ arg1),
                                    (R.Int32 R.S, op2)))
      end

  fun divmod context code (ddiv, dmod, op1, op2) =
      (*
       * rounding is towards negative infinity.
       *
       * arg1 / arg2 = q ... r
       * q' = q + ((q < 0 && r != 0) ? -1 : 0)
       * r' = r + ((q < 0 && r != 0) ? arg2 : 0)
       *
       * ((q < 0 && r != 0) ? -1 : 0)
       *     = neg ((q < 0) | (r != 0))
       * ((q < 0 && r != 0) ? arg2 : 0)
       *     = neg ((q < 0) | (r != 0)) & arg2
       *
       * movl    arg1, %eax
       * cltd
       * idivl   arg2
       * testl   %eax, %eax
       * setns   tmp1              ; q >= 0
       * testl   %edx, %edx
       * sete    tmp2              ; r == 0
       * orb     tmp1, tmp2
       * movzbl  tmp2, cond        ; (q >= 0 || r == 0) == ~(q < 0 && r != 0)
       * subl    $1, cond          ; n = if cond then 0 else -1
       * addl    cond, %eax        ; q = q + n
       * andl    arg2, cond        ; m = if n == 0 then 0 else arg2
       * addl    cond, %edx        ; r = r + m
       *)
      let
        val q = newDst (R.Int32 R.S)
        val r = newDst (R.Int32 R.S)
        val notminus = newDst (R.Int8 R.U)
        val divisible = newDst (R.Int8 R.U)
        val cond = newDst (R.Int8 R.U)
        val cond32 = newDst (R.Int32 R.U)
        val roundq = newDst (R.Int32 R.U)
        val roundr = newDst (R.Int32 R.S)
        val code = quotrem context code (q, r, op1, op2)
      in
        insert (code,
                [
                  R.SET (R.NOTSIGN, R.Int8 R.U, notminus,
                         {test = R.TEST_AND (R.Int32 R.S, R.REF_ q, R.REF_ q)}),
                  R.SET (R.EQUAL, R.Int8 R.U, divisible,
                         {test = R.TEST_AND (R.Int32 R.S, R.REF_ r, R.REF_ r)}),
                  R.OR (R.Int8 R.U, cond, R.REF_ notminus, R.REF_ divisible),
                  R.EXT8TO32 (R.U, cond32, R.REF_ cond),
                  R.SUB (R.Int32 R.U, roundq, R.REF_ cond32,
                         R.CONST (R.UINT32 0w1)),
                  R.ADD (R.Int32 R.S, ddiv,
                         R.REF_ q, R.REF (R.CAST (R.Int32 R.S), roundq)),
                  R.AND (R.Int32 R.S, roundr,
                         R.REF (R.CAST (R.Int32 R.S), roundq), op2),
                  R.ADD (R.Int32 R.S, dmod, R.REF_ r, R.REF_ roundr)
                ])
      end

  fun shiftInsn code (con, ty, dst, op1, op2 as R.CONST (R.UINT32 c)) =
      if c < 0w32
      then insert (code, [con (ty, dst, op1, op2)])
      else insert (code, [R.MOVE (ty, dst, R.CONST (R.UINT32 0w0))])
    | shiftInsn code (con, ty, dst, op1, op2) =
      let
        (*
         * dst = (op2 < 32) ? 0 : (op1 >> op2);
         *
         * cond = (op2 >= 32) - 1;   // cond = if (op2 < 32) then -1 else 0
         * dst = op1 >> op2;
         * dst = dst & cond;
         *)
        val limit = R.CONST (R.UINT32 (Word32.fromInt (sizeof ty * BYTE_BITS)))
        val cond = newDst (R.Int8 R.U)
        val cond32 = newDst ty
        val ext =
            case ty of
              R.Int8 R.U => (fn (s,d,o1) => R.MOVE (R.Int8 s, d, o1))
            | R.Int32 R.U => R.EXT8TO32
            | _ => raise Control.Bug "shiftInsn"
        val mask = newDst ty
        val tmp = newDst ty
      in
        insert (code, [R.SET (R.ABOVEEQUAL, R.Int8 R.U, cond,
                              {test=R.TEST_SUB (R.Int32 R.U, op2, limit)}),
                       ext (R.U, cond32, R.REF_ cond),
                       R.SUB (ty, mask, R.REF_ cond32, R.CONST (R.UINT32 0w1)),
                       con (ty, tmp, op1, op2),
                       R.AND (ty, dst, R.REF_ tmp, R.REF_ mask)])
      end

  fun selectInsn context code insn =
      case insn of
        AI.Move {dst, ty, value, loc} =>
        let
          val dst = transformVarInfo dst
          val (code, value) = transformValue context code value
          val code = selectMove code (dst, value, NONE)
        in
          code
        end

      | AI.Load {dst, ty, block, offset, size, loc} =>
        let
          val srcTy = transformTy ty
          val dst = transformVarInfo dst
          val (code, block, addr) = selectAddr context code (block, offset)
          val value = OPRD (R.REF_ (R.MEM (srcTy, R.ADDR addr)))
          val size = transformOperand size
          val code = selectMove code (dst, value, SOME size)
        in
          code
        end

      | AI.Update {block, offset, ty, size, value, barrier, loc} =>
        let
          val dstTy = transformTy ty
          val (code, block, addr) = selectAddr context code (block, offset)
          val (code, value) = transformValue context code value
          val size = transformOperand size
          fun update code =
              selectMove code (R.MEM (dstTy, R.ADDR addr), value, SOME size)
          fun updateWithBarrier (code, valueVar) returnTo =
              let
                val (code, v1) = coerceToVar code (ADDR block)
                val (code, v2) = coerceToVar code (ADDR addr)
              in
                selectPrimCall context code
                               {callTo = "sml_write",
                                retRegs = nil,
                                argRegs = [v1, v2, valueVar],
                                needStabilize = false,
                                returnTo = returnTo}
              end
        in
          case barrier of
            AI.NoBarrier => update code
          | AI.WriteBarrier =>
            updateWithBarrier (coerceToVar code value) NONE
          | AI.GlobalWriteBarrier =>
            updateWithBarrier (coerceToVar code value) NONE
          | AI.BarrierTag tag =>
            let
              val tag = transformOperand tag
              val test = R.TEST_AND (R.Int32 R.U, tag, tag)
              val (code, endLabel) = makeLabelAfter code
              val (code, noBarrierLabel) = makeLabelAfter code
              val code = insertLastBefore
                           (code, fn l => R.CJUMP {test = test,
                                                   cc = R.EQUAL,
                                                   thenLabel = noBarrierLabel,
                                                   elseLabel = l})
              val (code, _, mem) = coerceToMem code value
              val var = newVar (R.Ptr R.Void)
              val code =
                  insert (code, [R.MOVE (R.Ptr R.Void, R.REG var,
                                         R.REF_ (R.MEM (R.Ptr R.Void, mem)))])
              val code = updateWithBarrier (code, var) (SOME endLabel)
              val code = focusFirst (code, noBarrierLabel)
              val code = update code
              val code = focusFirst (code, endLabel)
            in
              code
            end
        end

      | AI.Get {dst, ty, src, loc} =>
        let
          val ty = transformTy ty
          val dst = transformVarInfo dst
          val var = transformArgInfo src
        in
          selectMove code (dst, OPRD (R.REF_ var), NONE)
        end

      | AI.Set {dst, ty, value, loc} =>
        let
          val dst = transformArgInfo dst
          val (code, op1) = transformValue context code value
        in
          selectMove code (dst, op1, NONE)
        end

      | AI.Alloc {dst, objectType, bitmaps, payloadSize, loc} =>
        let
          val dst = transformVarInfo dst
          val payloadSize = transformOperand payloadSize
        in
          if (case objectType of AI.Vector => true
                               | AI.Record _ => true
                               | AI.Array => false)
             andalso payloadSize = R.CONST (R.UINT32 0w0)
          then
            let
              val (sets, dst) = coerceDstToVar dst
              val code = selectPrimCall context code
                                        {callTo = "sml_obj_empty",
                                         retRegs = [dst],
                                         argRegs = nil,
                                         needStabilize = false,
                                         returnTo = NONE}
            in
              sets code
            end
          else
            let
              val bitmaps = map transformOperand bitmaps
            in
              #code (selectAlloc callAlloc context code
                                 (dst, objectType, bitmaps, payloadSize))
            end
        end

      | AI.PrimOp1 {dst, op1=oper as (operator,ty1,ty2), arg, loc} =>
        let
          val dst = transformVarInfo dst
          val (code, arg) = transformValue context code arg
          val dstTy = RTLUtils.dstTy dst
          val ty1 = valueTy arg

          fun float (dst, op1, insns) =
              let
                val (code, srcTy, src) = coerceToMem code op1
                val (save, dstTy, dst) = coerceDstToMem dst
                val code = insert (code, [R.X86 (R.X86FLD (srcTy, src))])
                val code = insert (code, insns)
                val code = insert (code, [R.X86 (R.X86FSTP (dstTy, dst))])
              in
                save code
              end

          fun negReal (dst, op1) =
              float (dst, op1, [R.X86 R.X86FCHS])
          fun absReal (dst, op1) =
              float (dst, op1, [R.X86 R.X86FABS])
          fun castReal (dst, op1) =
              float (dst, op1, nil)
          fun intToReal (dst, op1) =
              float (dst, op1, nil)
          fun realToInt (dst, op1) =
              let
                val (sets, dst) = promoteIntDst dst
                val (code, op1) = promoteInt (code, op1)
                val (code, srcTy, src) = coerceToMem code (OPRD op1)
                val (save, dstTy, dst) = coerceDstToMem dst
                val fcw1 = R.SLOT (newSlot (X86Emit.formatOf (R.Int16 R.U)))
                val fcw2 = R.SLOT (newSlot (X86Emit.formatOf (R.Int16 R.U)))
                val rcw = newVar (R.Int16 R.U)
                val code =
                    insert
                      (code,
                       [
                         R.X86 (R.X86FLD (srcTy, src)),
                         R.X86 R.X86FWAIT,
                         R.X86 R.X86FNCLEX,
                         R.X86 (R.X86FNSTCW fcw1),
                         (* bit 10:11 (rounding control) = truncate to zero *)
                         R.OR (R.Int16 R.U, R.REG rcw,
                               R.REF_ (R.MEM (R.Int16 R.U, fcw1)),
                               R.CONST (R.UINT16 0wxc00)),
                         (*
                          (* bit 0 (invalid exception mask) = unmasked *)
                          R.AND (R.Int16 R.U, R.REG rcw,
                                 R.REF_ (R.REG rcw), R.CONST (R.UINT32 0xfffffffe)),
                          *)
                         R.MOVE (R.Int16 R.U, R.MEM (R.Int16 R.U, fcw2),
                                 R.REF_ (R.REG rcw)),
                         R.X86 (R.X86FLDCW fcw2),
                         R.X86 (R.X86FSTP (dstTy, dst)),
                         R.X86 (R.X86FNSTCW fcw1)
                       ])
              in
                sets (save code)
              end

          fun abs (ty, dst, op1) =
              let
                (* abs(x) = (x + (x >> 31)) ^ (x >> 31) *)
                val shift = Word32.fromInt (sizeof ty * BYTE_BITS - 1)
                val y = newDst ty
                val z = newDst ty
              in
                insert (code,
                        [R.ARSHIFT (ty, y, op1, R.CONST (R.UINT32 shift)),
                         R.ADD (ty, z, R.REF_ y, op1),
                         R.XOR (ty, dst, R.REF_  y, R.REF_ z)])
              end

          val code =
              case (operator, dstTy, ty1, arg) of
                (AI.Notb, R.Int8 _, R.Int8 _, OPRD op1) =>
                insert (code, [R.NOT (dstTy, dst, op1)])
              | (AI.Notb, R.Int16 _, R.Int16 _, OPRD op1) =>
                insert (code, [R.NOT (dstTy, dst, op1)])
              | (AI.Notb, R.Int32 _, R.Int32 _, OPRD op1) =>
                insert (code, [R.NOT (dstTy, dst, op1)])
              | (AI.Neg, R.Int8 _, R.Int8 _, OPRD op1) =>
                insert (code, [R.NEG (dstTy, dst, op1)])
              | (AI.Neg, R.Int16 _, R.Int16 _, OPRD op1) =>
                insert (code, [R.NEG (dstTy, dst, op1)])
              | (AI.Neg, R.Int32 _, R.Int32 _, OPRD op1) =>
                insert (code, [R.NEG (dstTy, dst, op1)])
              | (AI.Neg, R.Real32, R.Real32, op1) => negReal (dst, op1)
              | (AI.Neg, R.Real64, R.Real64, op1) => negReal (dst, op1)
              | (AI.Neg, R.Real80, R.Real80, op1) => negReal (dst, op1)
              | (AI.Abs, R.Int8 _, R.Int8 _, OPRD op1) =>
                abs (dstTy, dst, op1)
              | (AI.Abs, R.Int16 _, R.Int16 _, OPRD op1) =>
                abs (dstTy, dst, op1)
              | (AI.Abs, R.Int32 _, R.Int32 _, OPRD op1) =>
                abs (dstTy, dst, op1)
              | (AI.Abs, R.Real32, R.Real32, op1) => absReal (dst, op1)
              | (AI.Abs, R.Real64, R.Real64, op1) => absReal (dst, op1)
              | (AI.Abs, R.Real80, R.Real80, op1) => absReal (dst, op1)
              | (AI.Cast, R.Real32, R.Int32 R.S, op1) => intToReal (dst, op1)
              | (AI.Cast, R.Real64, R.Int32 R.S, op1) => intToReal (dst, op1)
              | (AI.Cast, R.Real80, R.Int32 R.S, op1) => intToReal (dst, op1)
              | (AI.Cast, R.Int32 R.S, R.Real32, OPRD op1) => realToInt (dst, op1)
              | (AI.Cast, R.Int32 R.S, R.Real64, OPRD op1) => realToInt (dst, op1)
              | (AI.Cast, R.Int32 R.S, R.Real80, OPRD op1) => realToInt (dst, op1)
              | (AI.Cast, R.Real32, R.Real64, op1) => castReal (dst, op1)
              | (AI.Cast, R.Real32, R.Real80, op1) => castReal (dst, op1)
              | (AI.Cast, R.Real64, R.Real32, op1) => castReal (dst, op1)
              | (AI.Cast, R.Real64, R.Real80, op1) => castReal (dst, op1)
              | (AI.Cast, R.Real80, R.Real32, op1) => castReal (dst, op1)
              | (AI.Cast, R.Real80, R.Real64, op1) => castReal (dst, op1)
              | (AI.Cast, R.Int32 R.S, R.Int32 R.U, OPRD op1) =>
                selectMove code (dst, makeCast (arg, dstTy), NONE)
              | (AI.Cast, R.Int32 R.U, R.Int32 R.S, OPRD op1) =>
                selectMove code (dst, makeCast (arg, dstTy), NONE)
              | (AI.Cast, R.Int8 s, R.Int32 _, OPRD op1) =>
                insert (code, [R.DOWN32TO8 (s, dst,
                                            makeCastOperand (op1, R.Int32 s))])
              | (AI.ZeroExt, R.Int32 _, R.Int8 _, OPRD op1) =>
                let
                  val v = newVar (R.Int32 R.U)
                  val op1 = makeCastOperand (op1, R.Int8 R.U)
                in
                  insert (code, [R.EXT8TO32 (R.U, R.REG v, op1),
                                 R.MOVE (dstTy, dst,
                                         R.REF (R.CAST dstTy, R.REG v))])
                end
              | (AI.SignExt, R.Int32 s, R.Int8 _, OPRD op1) =>
                let
                  val v = newVar (R.Int32 R.S)
                  val op1 = makeCastOperand (op1, R.Int8 R.S)
                in
                  insert (code, [R.EXT8TO32 (R.S, R.REG v, op1),
                                 R.MOVE (dstTy, dst,
                                         R.REF (R.CAST dstTy, R.REG v))])
                end
              | (AI.PayloadSize, R.Int32 _, R.Ptr R.Data, ADDR addr) =>
                let
                  val header = R.ADDR (R.DISP (R.INT32 ~4, addr))
                  val headerMask = R.CONST (R.UINT32 HEAD_SIZE_MASK)
                in
                  insert (code, [R.AND (dstTy, dst,
                                        R.REF_ (R.MEM (dstTy, header)),
                                        headerMask)])
                end
              | _ => raise Control.Bug "SelectInsn: PrimOp1"
        in
          code
        end

      | AI.PrimOp2 {dst, op2 as (operator,ty1,ty2,ty3), arg1, arg2, loc} =>
        let
          val dst = transformVarInfo dst
          val (code, arg1) = transformValue context code arg1
          val (code, arg2) = transformValue context code arg2
          val dstTy = RTLUtils.dstTy dst
          val ty1 = valueTy arg1
          val ty2 = valueTy arg2

          (* st(0)=arg2, st(1)=arg1, dst = st(1) op st(0) *)
          fun float (dst, arg1, arg2, insns) =
              let
                val (code, ty1, src1) = coerceToMem code arg1
                val (code, ty2, src2) = coerceToMem code arg2
                val (save, dstTy, dst) = coerceDstToMem dst
                val st1 = (ty1, src1)
                val st0 = (ty2, src2)
                val code = insert (code, [R.X86 (R.X86FLD st1),
                                          R.X86 (R.X86FLD st0)])
                val code = insert (code, insns)
                val code = insert (code, [R.X86 (R.X86FSTP (dstTy, dst))])
              in
                save code
              end

          (* st(0)=arg1, st(1)=arg2, dst = st(1) rem st(0) *)
          fun floatRem (dst, arg1, arg2) =
              let
                val (code, ty1, src1) = coerceToMem code arg1
                val (code, ty2, src2) = coerceToMem code arg2
                val (save, dstTy, dst) = coerceDstToMem dst
                val st1 = (ty2, src2)
                val st0 = (ty1, src1)
                val code = insert (code, [R.X86 (R.X86FLD st1),
                                          R.X86 (R.X86FLD st0)])
                val (code, loopLabel) = makeLabelBefore code
                val code = insert (code, [R.X86 R.X86FPREM])
                val clob = newVar (R.Int16 R.U)  (* ax *)
                val test = R.X86 (R.X86FSW_TESTH {clob=clob,
                                                  mask=R.UINT8 0wx4})
                val code =
                    insertLastBefore
                      (code, fn l => R.CJUMP {test = test,
                                              cc = R.NOTEQUAL,
                                              thenLabel = loopLabel,
                                              elseLabel = l})
                val code = insert (code, [R.X86 (R.X86FSTP (dstTy, dst)),
                                          R.X86 (R.X86FFREE (R.X86ST 0)),
                                          R.X86 R.X86FINCSTP])
              in
                code
              end

          val code =
              case (operator,
                    promoteIntTy dstTy, promoteIntTy ty1, promoteIntTy ty2,
                    arg1, arg2) of
                (AI.Add, R.Int32 _, R.Int32 _, R.Int32 _, OPRD op1, OPRD op2) =>
                insert (code, [R.ADD (dstTy, dst, op1, op2)])
              | (AI.Add, R.Real32, R.Real32, R.Real32, _, _) =>
                float (dst, arg1, arg2, [R.X86 (R.X86FADDP (R.X86ST 1))])
              | (AI.Add, R.Real64, R.Real64, R.Real64, _, _) =>
                float (dst, arg1, arg2, [R.X86 (R.X86FADDP (R.X86ST 1))])
              | (AI.Add, R.Real80, R.Real80, R.Real80, _, _) =>
                float (dst, arg1, arg2, [R.X86 (R.X86FADDP (R.X86ST 1))])
              | (AI.Sub, R.Int32 _, R.Int32 _, R.Int32 _, OPRD op1, OPRD op2) =>
                insert (code, [R.SUB (dstTy, dst, op1, op2)])
              | (AI.Sub, R.Real32, R.Real32, R.Real32, _, _) =>
                float (dst, arg1, arg2, [R.X86 (R.X86FSUBP (R.X86ST 1))])
              | (AI.Sub, R.Real64, R.Real64, R.Real64, _, _) =>
                float (dst, arg1, arg2, [R.X86 (R.X86FSUBP (R.X86ST 1))])
              | (AI.Sub, R.Real80, R.Real80, R.Real80, _, _) =>
                float (dst, arg1, arg2, [R.X86 (R.X86FSUBP (R.X86ST 1))])
              | (AI.Mul, R.Int32 s1, R.Int32 s2, R.Int32 s3,
                 OPRD op1, OPRD op2) =>
                let
                  val (code, op1) = promoteInt (code, op1)
                  val (code, op2) = promoteInt (code, op2)
                  val (sets, dst) = promoteIntDst dst
                  val code = insert (code, [R.MUL ((R.Int32 s1, dst),
                                                   (R.Int32 s2, op1),
                                                   (R.Int32 s3, op2))])
                in
                  sets code
                end
              | (AI.Mul, R.Real32, R.Real32, R.Real32, _, _) =>
                float (dst, arg1, arg2, [R.X86 (R.X86FMULP (R.X86ST 1))])
              | (AI.Mul, R.Real64, R.Real64, R.Real64, _, _) =>
                float (dst, arg1, arg2, [R.X86 (R.X86FMULP (R.X86ST 1))])
              | (AI.Mul, R.Real80, R.Real80, R.Real80, _, _) =>
                float (dst, arg1, arg2, [R.X86 (R.X86FMULP (R.X86ST 1))])
              | (AI.Div, R.Int32 R.S, R.Int32 R.S, R.Int32 R.S,
                 OPRD op1, OPRD op2) =>
                let
                  val (code, op1) = promoteInt (code, op1)
                  val (code, op2) = promoteInt (code, op2)
                  val (sets, dst) = promoteIntDst dst
                  val dmod = newDst (R.Int32 R.S)
                  val code = divmod context code (dst, dmod, op1, op2)
                in
                  sets code
                end
              | (AI.Quot, R.Int32 R.S, R.Int32 R.S, R.Int32 R.S,
                 OPRD op1, OPRD op2) =>
                let
                  val (code, op1) = promoteInt (code, op1)
                  val (code, op2) = promoteInt (code, op2)
                  val (sets, dst) = promoteIntDst dst
                  val dmod = newDst (R.Int32 R.S)
                  val code = quotrem context code (dst, dmod, op1, op2)
                in
                  sets code
                end
              | (AI.Div, R.Int32 R.U, R.Int32 R.U, R.Int32 R.U,
                 OPRD op1, OPRD op2) =>
                let
                  val (code, op1) = promoteInt (code, op1)
                  val (code, op2) = promoteInt (code, op2)
                  val (sets, dst) = promoteIntDst dst
                  val dmod = newDst (R.Int32 R.U)
                  val code = quotremUInt context code (dst, dmod, op1, op2)
                in
                  sets code
                end
              | (AI.Div, R.Real32, R.Real32, R.Real32, _, _) =>
                float (dst, arg1, arg2, [R.X86 (R.X86FDIVP (R.X86ST 1))])
              | (AI.Div, R.Real64, R.Real64, R.Real64, _, _) =>
                float (dst, arg1, arg2, [R.X86 (R.X86FDIVP (R.X86ST 1))])
              | (AI.Div, R.Real80, R.Real80, R.Real80, _, _) =>
                float (dst, arg1, arg2, [R.X86 (R.X86FDIVP (R.X86ST 1))])
              | (AI.Rem, R.Real32, R.Real32, R.Real32, _, _) =>
                floatRem (dst, arg1, arg2)
              | (AI.Rem, R.Real64, R.Real64, R.Real64, _, _) =>
                floatRem (dst, arg1, arg2)
              | (AI.Rem, R.Real80, R.Real80, R.Real80, _, _) =>
                floatRem (dst, arg1, arg2)
              | (AI.Mod, R.Int32 R.S, R.Int32 R.S, R.Int32 R.S,
                 OPRD op1, OPRD op2) =>
                let
                  val (code, op1) = promoteInt (code, op1)
                  val (code, op2) = promoteInt (code, op2)
                  val (sets, dst) = promoteIntDst dst
                  val ddiv = newDst (R.Int32 R.S)
                  val code = divmod context code (ddiv, dst, op1, op2)
                in
                  sets code
                end
              | (AI.Rem, R.Int32 R.S, R.Int32 R.S, R.Int32 R.S,
                 OPRD op1, OPRD op2) =>
                let
                  val (code, op1) = promoteInt (code, op1)
                  val (code, op2) = promoteInt (code, op2)
                  val (sets, dst) = promoteIntDst dst
                  val ddiv = newDst (R.Int32 R.S)
                  val code = quotrem context code (ddiv, dst, op1, op2)
                in
                  sets code
                end
              | (AI.Mod, R.Int32 R.U, R.Int32 R.U, R.Int32 R.U,
                 OPRD op1, OPRD op2) =>
                let
                  val (code, op1) = promoteInt (code, op1)
                  val (code, op2) = promoteInt (code, op2)
                  val (sets, dst) = promoteIntDst dst
                  val ddiv = newDst (R.Int32 R.U)
                  val code = quotremUInt context code (ddiv, dst, op1, op2)
                in
                  sets code
                end
              | (AI.Andb, R.Int32 _, R.Int32 _, R.Int32 _,
                 OPRD op1, OPRD op2) =>
                insert (code, [R.AND (dstTy, dst, op1, op2)])
              | (AI.Orb, R.Int32 _, R.Int32 _, R.Int32 _,
                 OPRD op1, OPRD op2) =>
                insert (code, [R.OR (dstTy, dst, op1, op2)])
              | (AI.Xorb, R.Int32 _, R.Int32 _, R.Int32 _,
                 OPRD op1, OPRD op2) =>
                insert (code, [R.XOR (dstTy, dst, op1, op2)])
              | (AI.LShift, R.Int32 _, R.Int32 _, R.Int32 _,
                 OPRD op1, OPRD op2) =>
                shiftInsn code (R.LSHIFT, dstTy, dst, op1, op2)
              | (AI.RShift, R.Int32 _, R.Int32 _, R.Int32 _,
                 OPRD op1, OPRD op2) =>
                shiftInsn code (R.RSHIFT, dstTy, dst, op1, op2)
              | (AI.ArithRShift, R.Int32 _, R.Int32 _, R.Int32 _,
                 OPRD op1, OPRD op2) =>
                shiftInsn code (R.ARSHIFT, dstTy, dst, op1, op2)
              | (AI.PointerAdvance, R.Ptr ptrTy, R.Ptr _, R.Int32 _, _, _) =>
                let
                  val (code, v) = coerceToVar code arg1
                  val insn =
                      case arg2 of
                        (OPRD (R.CONST c)) =>
                        R.MOVEADDR (ptrTy, dst, R.DISP (c, R.BASE v))
                      | _ =>
                        let
                          val (code, v2) = coerceToVar code arg2
                        in
                          R.MOVEADDR (ptrTy, dst,
                                      R.BASEINDEX {base=v, index=v2, scale=1})
                        end
                in
                  insert (code, [insn])
                end
              | (_, R.Int32 R.U, _, _, _, _) =>
                let
                  val v = newDst (R.Int8 R.U)
                  val (code, test, cc) = selectCompare code op2 (arg1, arg2)
                in
                  insert (code, [R.SET (cc, R.Int8 R.U, v, {test=test}),
                                 R.EXT8TO32 (R.U, dst, R.REF_ v)])
                end
              | (op2, ty3, ty1, ty2, _, _) =>
                raise Control.Bug
                        ("selectInsn: PrimOp2: " ^
                         Control.prettyPrint (AI.format_op2 (R.format_ty ty1,
                                                             R.format_ty ty2)
                                                            op2)
                         ^ " -> " ^ Control.prettyPrint (R.format_ty ty3))
        in
          code
        end

      | AI.CallExt {dstVarList, entry,
                    attributes={callingConvention, isPure, noCallback,
                                suspendThread, allocMLValue},
                    argList, calleeTy=(argTys, retTys), loc} =>
        let
          val argTys = map transformTy argTys
          val retTys = map transformTy retTys
          val argSrcs = map transformArgInfo argList
          val args = map dstToValue argSrcs
          val dsts = map transformArgInfo dstVarList

          val (code, entry) = transformJumpTo context code entry
          val code =
              if not noCallback orelse allocMLValue orelse suspendThread
              then saveFramePointer context code
              else code
          val code =
              if suspendThread then
                selectPrimCall context code
                               {callTo = "sml_state_suspend",
                                retRegs = nil,
                                argRegs = nil,
                                needStabilize = false,
                                returnTo = NONE}
              else code

          val (code, uses) =
              setCArgs code (callingConvention, argTys, retTys) args
          val (gets, defs) =
              getCRets (callingConvention, argTys, retTys) dsts
          val postFrameAdjust =
              adjustCPostFrame (callingConvention, argTys, retTys)
          val code = selectCall context code
                                {callTo = entry,
                                 retRegs = defs,
                                 argRegs = uses,
                                 needStabilize = allocMLValue,
                                 returnTo = NONE,
                                 postFrameAdjust = postFrameAdjust}

          (* make sure that all args are live during executing callbacks. *)
          val code =
              if noCallback then code
              else insert (code, [R.USE (map R.REF_ argSrcs)])

          val code =
              if suspendThread then
                selectPrimCall context code
                               {callTo = "sml_state_running",
                                retRegs = nil,
                                argRegs = nil,
                                needStabilize = false,
                                returnTo = NONE}
              else code

          val code = gets code
        in
          code
        end

      | AI.Call {dstVarList, entry, env, argList, argTyList, resultTyList,
                 loc} =>
        let
          val argTys = map transformTy argTyList
          val retTys = map transformTy resultTyList
          val env = transformArgInfo env
          val args = map argInfoToValue argList
          val dsts = map transformArgInfo dstVarList
          val (code, entry) = transformJumpTo context code entry
          val (code, uses) = setMLArgs code (argTys, retTys) (env, args)
          val (gets, defs) = getMLRets (argTys, retTys) dsts
          val postFrameAdjust = adjustMLPostFrame (argTys, retTys)
          val code = selectCall context code
                                {callTo = entry,
                                 retRegs = defs,
                                 argRegs = uses,
                                 needStabilize = true,
                                 returnTo = NONE,
                                 postFrameAdjust = postFrameAdjust}
          val code = gets code
        in
          code
        end

      | AI.TailCall {entry, env, argList, argTyList, resultTyList, loc} =>
        let
          val argTys = map transformTy argTyList
          val retTys = map transformTy resultTyList
          val env = transformArgInfo env
          val args = map argInfoToValue argList
          val (code, entry) = transformJumpTo context code entry
          val (code, uses) =
              setMLTailCallArgs code (argTys, retTys) (env, args)
          val uses = #calleeSaves context @ uses
        in
          insertLast
            (code, R.TAILCALL_JUMP
                     {jumpTo = entry,
                      preFrameSize = mlPreFrameSize (argTys, retTys),
                      uses = uses (* precolor: edi, esi, ebx, eax *) })
        end

      | AI.CallbackClosure {dst, entry, env, exportTy=(argTys, retTys),
                            attributes as {callingConvention,...}, loc} =>
        let
          val dst = transformVarInfo dst
          val dstTy = RTLUtils.dstTy dst
          val (sets1, dstVar) = coerceDstToVar dst
          val (code, entry) = transformAddr context code entry
          val (code, env) = transformAddr context code env
          val (code, entryVar) = coerceToVar code (ADDR entry)
          val (code, envVar) = coerceToVar code (ADDR env)
          val code = #code (selectAlloc (callAllocCallback entryVar envVar)
                                        context code
                                        (dst, AI.Record {mutable=false},
                                         [R.CONST (R.UINT32 0wx10)],
                                         R.CONST (R.UINT32 0w20)))

          (* TODO: make more efficient *)
          val (code, entryVar) = coerceToVar code (ADDR entry)

          fun closureField 0 = R.ADDR (R.BASE dstVar)
            | closureField n = R.ADDR (R.DISP (R.INT32 n, R.BASE dstVar))
          val offset1 = newVar (R.Int32 R.S)
          val offset2 = newVar (R.Ptr R.Code)

          val argTys = map transformTy argTys
          val retTys = map transformTy retTys
          val preFrameSize =
              cPreFrameSize (true, callingConvention, argTys, retTys)
          val preFrameRetSize =
              cPreFrameRetSize (true, callingConvention, argTys, retTys)

          (*
           * 0000  55                pushl   %ebp
           * 0001  8d 2c 24          leal    (%esp), %ebp
           * 0004  8d 64 24 fc       leal    -4(%esp), %esp
           * 0008  83 e4 f0          andl    $-16, %esp
           * 000b  e8 xx xx xx xx    call    entry
           * 0010  89 ec             movl    %ebp, %esp
           * 0000  5d                popl    %ebp
           * 0000  c2 nn nn          ret     $4
           *)
          (*
           * 0000  c8 04 00 00       enter   $4, $0
           * 0004  83 e4 f0          andl    $-16, %esp
           * 0007  e8 xx xx xx xx    call    entry
           * 000c  c9                leave
           * 000d  c2 nn nn          ret     n
           *
           * [0x000004c8, 0xe8f0e483, 0xxxxxxxxx, 0x0xnnnnc2c9]
           * where xxxxxxxx = codeEntry - closureAddr - 12
           *)
          val retArg =
              Word32.fromInt (preFrameSize - preFrameRetSize) << 0w16
          val retWord =
              if retArg = 0w0 then 0wxc3c9 else retArg || 0wxc2c9
          val code =
              insert
                (code,
                 [
                   R.MOVE (R.Int32 R.U, R.MEM (R.Int32 R.U, closureField 0),
                           R.CONST (R.UINT32 0wx000004c8)),
                   R.MOVE (R.Int32 R.U, R.MEM (R.Int32 R.U, closureField 4),
                           R.CONST (R.UINT32 0wxe8f0e483)),
                   R.MOVE (R.Int32 R.U, R.MEM (R.Int32 R.U, closureField 12),
                           R.CONST (R.UINT32 retWord)),
                   R.MOVEADDR (R.Data,
                               R.MEM (R.Ptr R.Data, closureField 16), env),
                   R.NEG  (R.Int32 R.S, R.REG offset1,
                           R.REF (R.CAST (R.Int32 R.S), R.REG dstVar)),
                   R.MOVEADDR (R.Code, R.REG offset2,
                               R.DISP (R.INT32 ~12,
                                       R.BASEINDEX {base = entryVar,
                                                    index = offset1,
                                                    scale = 1})),
                   R.MOVE (R.Ptr R.Code, R.MEM (R.Ptr R.Code, closureField 8),
                           R.REF_ (R.REG offset2))
                 ])
        in
          sets1 code
        end

      | AI.Return {varList, argTyList, retTyList, loc} =>
        let
          val argTys = map transformTy argTyList
          val retTys = map transformTy retTyList
          val rets = map argInfoToValue varList
          val (code, uses) = setMLRets code (argTys, retTys) rets
          val uses = #calleeSaves context @ uses
        in
          insertLast
            (code,
             (* RETURN assumes that return address is stored at 4(%ebp). *)
             R.RETURN {preFrameSize = mlPreFrameRetSize retTys,
                       stubOptions = NONE,
                       uses = uses (* precolor: edi, esi, ebx *) })
        end

      | AI.ReturnExt {varList, argTyList, retTyList,
                      attributes as {callingConvention, ...}, loc} =>
        let
          val argTys = map transformTy argTyList
          val retTys = map transformTy retTyList

          val fp = newVar (R.Ptr R.Void)
          val code = insert (code, [R.LOAD_FP (R.REG fp)])
          val code = selectPrimCall context code
                                    {callTo = "sml_control_finish",
                                     retRegs = [],
                                     argRegs = [fp],
                                     needStabilize = false,
                                     returnTo = NONE}

          val rets = map argInfoToValue varList
          val (code, uses) =
              setCRets code (callingConvention, argTys, retTys) rets
          val uses = #calleeSaves context @ uses
        in
          insertLast
            (code,
             (* RETURN assumes that return address is stored at 4(%ebp). *)
             R.RETURN {preFrameSize = cPreFrameRetSize
                                        (false, callingConvention,
                                         argTys, retTys),
                       stubOptions = SOME {forceFrameAlign = true},
                       uses = uses (* precolor: edi, esi, ebx, eax *) })
        end

      | AI.If {value1, value2, op2, thenLabel, elseLabel, loc} =>
        let
          val (code, arg1) = transformValue context code value1
          val (code, arg2) = transformValue context code value2
          val (code, test, cc) = selectCompare code op2 (arg1, arg2)
        in
          insertLast
            (code, R.CJUMP {test = test, cc = cc,
                            thenLabel = thenLabel, elseLabel = elseLabel})
        end

      | AI.CheckBoundary {offset, size, objectSize, passLabel, failLabel,
                          loc} =>
        let
          val offset = transformOperand offset
          val size = transformOperand size
          val objectSize = transformOperand objectSize
          val v = newDst (R.Int32 R.U)
          val subInsn = R.SUB (R.Int32 R.U, v, objectSize, size)
          (* if (size <= objectSize && offset <= objectSize - size) then OK *)
          val code = insertLastBefore
                       (code, fn l => R.CJUMP {test = subInsn,
                                               cc = R.BELOW,
                                               thenLabel = failLabel,
                                               elseLabel = l})
        in
          insertLast
            (code, R.CJUMP {test = R.TEST_SUB (R.Int32 R.U, R.REF_ v, offset),
                            cc = R.BELOW,
                            thenLabel = failLabel,
                            elseLabel = passLabel})
        end

      | AI.Jump {label, knownDestinations, loc} =>
        let
          val (code, op1) = transformJumpTo context code label
        in
          insertLast (code, R.JUMP {jumpTo = op1,
                                    destinations = knownDestinations})
        end

      | AI.Raise {exn, loc} =>
        let
          val exn = transformArgInfo exn
          val (code, exnVar) = coerceToVar code (OPRD (R.REF_ exn))
(*
          val code =
              if !Control.debugCodeGen
              then selectPrimCall context code
                                  {callTo = "sml_check_handler",
                                   retRegs = nil,
                                   argRegs = [exnVar],
                                   needStabilize = false,
                                   returnTo = NONE}
              else code
*)
          val v1 = newVar (R.Ptr R.Void)
          val code =
              selectPrimCall context code
                             {callTo = "sml_pop_handler",
                              retRegs = [v1],
                              argRegs = [exnVar],
                              needStabilize = false,
                              returnTo = NONE}
        in
          selectRaise context code exnVar v1
        end

      | AI.RaiseExt {exn, attributes, loc} =>
        let
          val exn = transformArgInfo exn
          val (code, exnVar) = coerceToVar code (OPRD (R.REF_ exn))
          val v1 = newVar (R.Ptr R.Void)
          val code =
              selectPrimCall context code
                             {callTo = "sml_pop_handler",
                              retRegs = [v1],
                              argRegs = [exnVar],
                              needStabilize = false,
                              returnTo = NONE}
          val fp = newVar (R.Ptr R.Void)
          val code = insert (code, [R.LOAD_FP (R.REG fp)])
          val code = selectPrimCall context code
                                    {callTo = "sml_control_finish",
                                     retRegs = [],
                                     argRegs = [fp],
                                     needStabilize = false,
                                     returnTo = NONE}
        in
          selectRaise context code exnVar v1
        end

      | AI.ChangeHandler {change = AI.PushHandler _, previousHandler,
                          newHandler as AI.StaticHandler handler,
                          tryBlock, loc} =>
        let
          val code = pushHandler context code handler loc
        in
          insertJump (code, tryBlock)
        end

      | AI.ChangeHandler {change = AI.PopHandler _,
                          previousHandler as AI.StaticHandler handler,
                          newHandler, tryBlock, loc} =>
        let
          val code = popHandler context code handler loc
        in
          insertJump (code, tryBlock)
        end

      | AI.ChangeHandler {change, previousHandler, newHandler, tryBlock, loc} =>
        raise Control.Bug "selectInsn: ChangeHandler"

  fun selectBlock {code = {globalOffsetBase, externSymbols, handlerSlots,
                           preFrameSize, postFrameSize, graph},
                   numHeaderWords, options, clusterId, calleeSaves}
                  ({label, blockKind, handler, instructionList, loc}
                   :AI.basicBlock) =
      let
        val context =
            {options = options,
             handler = selectHandler handler,
             calleeSaves = calleeSaves} : context

        (* labels following a call should be 16-byte-aligned
         * when less than 8 bytes away from a 16 byte boundary. *)
        (* loop entry labels should be 16-byte-aligned
         * when less than 8 bytes away from a 16 byte boundary. *)
        (* labels following an uncoditional branch should be
         * 16-byte-aligned when less than 8 bytes away from a
         * 16-byte boundary. *)
        val (first, sets, newNumHeaderWords) =
            case blockKind of
              AI.FunEntry {argTyList, resultTyList, env, argVarList} =>
              let
                val symbol = entrySymbolName {clusterId=clusterId, entry=label}
                val argTys = map transformTy argTyList
                val retTys = map transformTy resultTyList
                val env =
                    case env of
                      SOME v => SOME (transformArgInfo v)
                    | NONE => NONE
                val dsts = map transformArgInfo argVarList
                val (sets, defs) = getMLArgs (argTys, retTys) (env, dsts)
                val defs = calleeSaves @ defs
              in
                (R.CODEENTRY {label = label,
                              symbol = symbol,
                              scope = R.LOCAL,
                              align = 4,
                              preFrameSize = mlPreFrameSize (argTys, retTys),
                              stubOptions = NONE,
                              (* precolor: esi, edi, ebx, eax, ecx, edx *)
                              defs = defs,
                              loc = loc},
                 fn code =>
                    let
                      val code = sets code
                      val code = checkGC context code
                    in
                      code
                    end,
                 1)
              end
            | AI.ExtFunEntry {argTyList, resultTyList, env, argVarList,
                              attributes as {callingConvention, ...}} =>
              let
                val symbol = entrySymbolName {clusterId=clusterId, entry=label}
                val argTys = map transformTy argTyList
                val retTys = map transformTy resultTyList

                val env =
                    case env of
                      SOME v => SOME (transformArgInfo v)
                    | NONE => NONE
                val dsts = map transformArgInfo argVarList

                val stubFrameVar = newVar (R.Ptr R.Void)
                val closFrameVar = newVar (R.Ptr R.Void)
                val insn1 =
                    [
                      R.LOAD_PREV_FP (R.REG stubFrameVar),
                      R.MOVE (R.Ptr R.Void,
                              R.REG closFrameVar,
                              R.REF_ (R.MEM (R.Ptr R.Void,
                                             R.ADDR (R.BASE stubFrameVar))))
                    ]
                val insn2 =
                    case env of
                      NONE => nil
                    | SOME envVar =>
                      let
                        val closAddr = newVar (R.Ptr R.Code)
                      in
                        [
                          R.MOVE (R.Ptr R.Code,
                                  R.REG closAddr,
                                  R.REF_
                                    (R.MEM (R.Ptr R.Code,
                                            R.ADDR
                                              (R.DISP (R.INT32 4,
                                                       R.BASE stubFrameVar))))),
                          R.MOVE (R.Ptr R.Data,
                                  envVar,
                                  R.REF_
                                    (R.MEM (R.Ptr R.Data,
                                            R.ADDR
                                              (R.DISP (R.INT32 4,
                                                       R.BASE closAddr)))))
                        ]
                      end

                val (sets, defs) =
                    getCArgs (callingConvention, argTys, retTys)
                             (SOME closFrameVar) dsts
                val defs = calleeSaves @ defs
              in
                (R.CODEENTRY {label = label,
                              symbol = symbol,
                              scope = R.LOCAL,
                              align = 4,
                              preFrameSize = cPreFrameSize (false,
                                                            callingConvention,
                                                            argTys, retTys),
                              stubOptions = SOME {forceFrameAlign = true},
                              (* precolor: esi, edi, ebx, eax, ecx, edx *)
                              defs = defs,
                              loc = loc},
                 fn code =>
                    let
                      val code = startThread context code
                      val code = insert (code, insn1)
                      val code = sets code
                      val code = insert (code, insn2)
                    in
                      code
                    end,
                 2)
              end
            | AI.Handler exn =>
              let
                val exn = transformArgInfo exn
                val (sets, exn) = coerceDstToVar exn
              in
                (R.HANDLERENTRY {label = label,
                                 align = 4,
                                 defs = [exn],  (* precolor: eax *)
                                 loc = loc},
                 sets, 0)
              end
            | _ =>
              (R.BEGIN {label = label, align = 1, loc = loc}, fn x => x, 0)

        val focus = RTLEdit.singletonFirst first
        val code =
            {globalOffsetBase = globalOffsetBase,
             externSymbols = externSymbols,
             handlerSlots = handlerSlots,
             preFrameSize = preFrameSize,
             postFrameSize = postFrameSize,
             focus = focus} : code
        val code = sets code
        val code = foldl (fn (insn, code) => selectInsn context code insn)
                         code
                         instructionList

        val graph = RTLEdit.mergeGraph (graph, RTLEdit.unfocus (#focus code))
      in
        ({globalOffsetBase = #globalOffsetBase code,
          externSymbols = #externSymbols code,
          handlerSlots = #handlerSlots code,
          preFrameSize = #preFrameSize code,
          postFrameSize = #postFrameSize code,
          graph = graph},
         Int.max (numHeaderWords, newNumHeaderWords))
      end

  fun selectFrameBitmap ({source, bits}:AI.frameBitmap) =
      let
        fun toInt32 w = Int32.fromInt (Word.toIntX w)
        val (source, uses) =
            case source of
              AI.BitParam {argKind = AI.Param {argTys, retTys, index},...} =>
              (List.nth (mlParams (map transformTy argTys,
                                   map transformTy retTys), index),
               VarID.Map.empty)
            | AI.BitParam _ =>
              raise Control.Bug "selectFrameBitmap: BitParam"
            | AI.EnvBitmap (arg, offset) =>
              case transformArgInfo arg of
                R.REG var =>
                (R.MEM (R.Int32 R.U, R.ADDR (R.DISP (R.INT32 (toInt32 offset),
                                                     R.BASE var))),
                 VarID.Map.singleton (#id var, var))
              | _ => raise Control.Bug "selectFrameBitmap: EnvBitmap"
      in
        ({source = R.REF_ source, bits = bits} : R.frameBitmap, uses)
      end

  fun selectFrameBitmapList (bitmap::bitmaps) =
      let
        val (bitmap, uses1) = selectFrameBitmap bitmap
        val (bitmaps, uses) = selectFrameBitmapList bitmaps
      in
        (bitmap::bitmaps, VarID.Map.unionWith #1 (uses, uses1))
      end
    | selectFrameBitmapList nil = (nil, VarID.Map.empty)

  fun selectCluster options {externSymbols, thunkSymbol}
                    ({frameBitmap, name, body, loc}:AI.cluster) =
      let
        (* three registers are callee-save. precolor : edi, esi, ebx *)
        val calleeSaves = newVarList 3

        val code =
            {globalOffsetBase = NONE,
             externSymbols = externSymbols,
             handlerSlots = R.LabelMap.empty,
             preFrameSize = 0,
             postFrameSize = 0,
             graph = R.LabelMap.empty}

        val (result, numHeaderWords) =
            foldl (fn (block, (code, numHeaderWords)) =>
                      selectBlock {code = code,
                                   numHeaderWords = numHeaderWords,
                                   options = options,
                                   clusterId = name,
                                   calleeSaves = calleeSaves}
                                  block)
                  (code, 1)
                  body

        val blockKindMap =
            foldl (fn ({label, blockKind, ...}, z) =>
                      VarID.Map.insert (z, label, blockKind))
                  VarID.Map.empty
                  body

        val {globalOffsetBase, externSymbols, handlerSlots,
             preFrameSize, postFrameSize, graph} =
            if !Control.insertCheckGC then
              (* insert GC checks to loop heads *)
              let
                val heads = RTLDominate.loopHeaders (#graph result)
                val heads =
                    List.filter
                      (fn label =>
                          case VarID.Map.find (blockKindMap, label) of
                            SOME AI.Loop => false | _ => true)
                      heads
              in
                foldl
                  (fn (headLabel, {globalOffsetBase, externSymbols,
                                   handlerSlots, preFrameSize, postFrameSize,
                                   graph}) =>
                      let
                        val focus = RTLEdit.focusFirst (graph, headLabel)
                        val (focus, label) = RTLEdit.makeLabelAfter focus
                        val code = {globalOffsetBase = globalOffsetBase,
                                    externSymbols = externSymbols,
                                    handlerSlots = handlerSlots,
                                    preFrameSize = preFrameSize,
                                    postFrameSize = postFrameSize,
                                    focus = focus}
                        val context =
                            {options = options,
                             handler = R.NO_HANDLER, (* dummy *)
                             calleeSaves = calleeSaves} : context
                        val code = checkGC context code
                      in
                        {globalOffsetBase = globalOffsetBase,
                         externSymbols = externSymbols,
                         handlerSlots = handlerSlots,
                         preFrameSize = preFrameSize,
                         postFrameSize = postFrameSize,
                         graph = RTLEdit.unfocus (#focus code)}
                      end)
                  result
                  heads
              end
            else result

        (* insert computation of global offset base *)
        val (baseLabel, thunkSymbol, graph) =
            case globalOffsetBase of
              NONE => (NONE, thunkSymbol, graph)
            | SOME (baseLabel, baseReg) =>
              let
                val thunkSymbol =
                    case thunkSymbol of
                      NONE =>
                      SOME (globalSymbolName options "_i686.get_pc_thunk.bx")
                    | SOME _ => thunkSymbol
                val graph =
                    R.LabelMap.map
                      (fn block as (first, insns, last) =>
                          if (case first of
                                R.CODEENTRY _ => true
                              | R.HANDLERENTRY _ => true
                              | R.BEGIN _ => false
                              | R.ENTER => false)
                          then
                            (first,
                             R.LOADABSADDR {ty = R.Ptr R.Code,
                                            dst = R.REG baseReg,
                                            symbol = baseLabel,
                                            thunk = thunkSymbol} :: insns,
                             last)
                          else block)
                      graph
                val baseLabel =
                    case baseLabel of
                      R.LABEL label => SOME label
                    | _ => NONE
              in
                (baseLabel, thunkSymbol, graph)
              end

        val (frameBitmap, computeFrameUses) =
            selectFrameBitmapList frameBitmap

        (* insert frame bitmap computation. *)
        val graph =
            R.LabelMap.map
              (fn block as (first, insns, last) =>
                  case first of
                    R.CODEENTRY {preFrameSize=entryPreFrameSize, ...} =>
                    (first,
                     R.COMPUTE_FRAME {uses = computeFrameUses,
                                      clobs = [newVar (R.Int32 R.U),
                                               newVar (R.Int32 R.U)]} ::
                     insns,
                     last)
                  | _ => block)
              graph

        (* normalize RTL for X86 *)
        val graph =
            X86Subst.substitute (fn _ => NONE) graph

        val topdecl =
            R.CLUSTER {clusterId = name,
                       frameBitmap = frameBitmap,
                       baseLabel = baseLabel,
                       body = graph,
                       preFrameSize = preFrameSize,
                       postFrameSize = postFrameSize,
                       numHeaderWords = numHeaderWords,
                       loc = loc}
      in
        ({externSymbols=externSymbols, thunkSymbol=thunkSymbol}, topdecl)
      end

  fun selectPrimData options externSymbols primData =
      case primData of
        AI.SIntData n =>
        (externSymbols, R.Int32 R.S,
         R.CONST_DATA (R.INT32 (AI.Target.SIntToSInt32 n)))
      | AI.UIntData n =>
        (externSymbols, R.Int32 R.U,
         R.CONST_DATA (R.UINT32 (AI.Target.UIntToUInt32 n)))
      | AI.ByteData n =>
        (externSymbols, R.Int8 R.U,
         R.CONST_DATA (R.UINT8 (Word8.fromInt (AI.Target.UIntToInt n))))
      | AI.RealData r =>
        (externSymbols, R.Real64, R.CONST_DATA (R.REAL64 r))
      | AI.FloatData r =>
        (externSymbols, R.Real32, R.CONST_DATA (R.REAL32 r))
      | AI.EntryData entry =>
        (externSymbols, R.Ptr R.Code, R.LABELREF_DATA (entrySymbol entry))
      | AI.GlobalLabelData label =>
        (externSymbols, R.Ptr R.Data,
         R.LABELREF_DATA (dataSymbol (R.Data, R.GLOBAL,
                                      globalSymbolName options label)))
      | AI.ExternLabelData label =>
        let
          val (externSymbols, symbol) =
              externSymbol (externSymbols, R.Data,
                            globalSymbolName options label)
        in
          (externSymbols, R.Ptr R.Data, R.LABELREF_DATA symbol)
        end
      | AI.ConstData id =>
        (externSymbols, R.Ptr R.Data, R.LABELREF_DATA (constSymbol id))
      | AI.NullPointerData =>
        (externSymbols, R.Ptr R.Void, R.LABELREF_DATA (R.NULL R.Void))
      | AI.NullBoxedData =>
        (externSymbols, R.Ptr R.Data, R.LABELREF_DATA (R.NULL R.Data))

  fun sectionOf ty =
      let
        val {align, size, ...} = X86Emit.formatOf ty
      in
        case ty of
          R.Ptr _ => (align, size, R.RODATA_SECTION)
        | _ =>
          case size of
            4 => (align, size, R.LITERAL32_SECTION)
          | 8 => (align, size, R.LITERAL64_SECTION)
          | _ => (align, size, R.RODATA_SECTION)
      end

  fun makePad (filled, size) =
      if filled = size then nil
      else if size > filled then [R.SPACE_DATA {size = size - filled}]
      else raise Control.Bug "makePad"

  fun selectData options externSymbols {scope, symbol, aliases} data =
      case data of
        AI.PrimData x =>
        let
          val (externSymbols, ty, data) = selectPrimData options externSymbols x
          val (align, size, section) = sectionOf ty
        in
          (externSymbols,
           R.DATA {scope = scope, symbol = symbol, aliases = aliases,
                   ptrTy = R.Void, section = section,
                   prefix = [], align = 1, data = [data],
                   prefixSize = 0})
        end

      | AI.StringData string =>
        let
          (*
           *   |<-- multiple of words --->|
           *   [head] [  string  ] 00 [pad]
           *          ^
           *      wordAlign
           *
           * payloadSize = stringSize + 1
           * object type = VECTOR
           *)
          val size = size string + 1
          val header = Word32.fromInt size || HEAD_TYPE_UNBOXED_VECTOR
          val align = #align (X86Emit.formatOf (R.Int32 R.U))
        in
          (externSymbols,
           R.DATA {scope = scope, symbol = symbol, aliases = aliases,
                   ptrTy = R.Data, section = R.RODATA_SECTION,
                   prefix = [R.CONST_DATA (R.UINT32 header)],
                   align = align,
                   data = [R.ASCII_DATA (string ^ "\000")],
                   prefixSize = sizeof (R.Int32 R.U)})
        end

      | AI.IntInfData n =>
        (* FIXME: format of IntInf *)
        (* candidate:
         * mpz_import (z, size,
         *             -1,        (* least significant word first *)
         *             wordSize,  (* word size *)
         *             1,         (* always bigendian *)
         *             0,         (* no nail *)
         *             p)
         *)
        let
          val s = BigInt.fmt (StringCvt.DEC) n
          val s = String.translate (fn #"~" => "-" | c => str c) s
        in
          (externSymbols,
           R.DATA {scope = scope, symbol = symbol, aliases = aliases,
                   ptrTy = R.Void, section = R.CSTRING_SECTION,
                   prefix = [], align = 1,
                   data = [R.ASCII_DATA (s ^ "\000")],
                   prefixSize = 0})
        end

      | AI.ObjectData {objectType, bitmaps, payloadSize, fields} =>
        let
          fun toConstWord x = R.CONST (R.UINT32 x)
          fun toInt (R.CONST (R.UINT32 x)) = Word32.toIntX x
            | toInt _ = raise Control.Bug "selectData: ObjectData: toInt"
          fun constData (R.CONST c) = R.CONST_DATA c
            | constData _ = raise Control.Bug "selectData: ObjectData"

          val section =
              case objectType of
                AI.Array => R.DATA_SECTION
              | AI.Vector => R.RODATA_SECTION
              | AI.Record {mutable=false} => R.RODATA_SECTION
              | AI.Record {mutable=true} => R.DATA_SECTION

          val bitmaps =
              map (fn x => toConstWord (AI.Target.UIntToUInt32 x)) bitmaps
          val payloadSize =
              toConstWord (AI.Target.UIntToUInt32 payloadSize)

          (* dummy context, code, and dst *)
          val context = {options = {positionIndependent = NONE,
                                    globalSymbolStartsWithUnderscore = false},
                         handler = R.NO_HANDLER,
                         calleeSaves = nil} : context
          val code = {globalOffsetBase = NONE,
                      externSymbols = externSymbols,
                      handlerSlots = R.LabelMap.empty,
                      preFrameSize = 0,
                      postFrameSize = 0,
                      focus = RTLEdit.singletonFirst R.ENTER} : code
          val dst = R.REG {id=VarID.generate (), ty=R.Ptr R.Data} (* dummy *)

          val {header, bitmapOffset, bitmaps, allocSize, ...} =
              selectAlloc #2 context code
                          (dst, objectType, bitmaps, payloadSize)

          val header = constData header
          val bitmapOffset = toInt bitmapOffset
          val bitmaps = map constData bitmaps
          val allocSize = toInt allocSize

          fun makeData (externSymbols, offset, {value, size}::fields) =
              let
                val size = AI.Target.UIntToInt size
                val (externSymbols, totalSize, data) =
                    makeData (externSymbols, offset + size, fields)
                val (externSymbols, ty, field) =
                    selectPrimData options externSymbols value
                val valueSize = sizeof ty
              in
                (externSymbols, totalSize,
                 field :: makePad (valueSize, size) @ data)
              end
            | makeData (externSymbols, offset, nil) =
              (externSymbols, offset, nil)

          val (externSymbols, offset, data) =
              makeData (externSymbols, 0, fields)

          val (offset, data) =
              case bitmaps of
                nil => (offset, data)
              | _::_ => (offset + length bitmaps * sizeof (R.Int32 R.U),
                         data @ makePad (offset, bitmapOffset) @ bitmaps)

          val data = data @ makePad (offset, allocSize)
        in
          (externSymbols,
           R.DATA {scope = scope, symbol = symbol, aliases = aliases,
                   ptrTy = R.Data, section = section,
                   prefix = [header],
                   align = #align X86Emit.formatOfGeneric,
                   data = data,
                   prefixSize = sizeof (R.Int32 R.U)})
        end

      | AI.VarSlot {size, value} =>
        let
          val size = AI.Target.UIntToInt size
        in
          case (value, aliases) of
            (NONE, nil) =>
            (externSymbols,
             R.BSS {scope = scope, symbol = symbol, size = size})
          | _ =>
            let
              val (externSymbols, align, data) =
                  case value of
                    NONE => (externSymbols, size, [R.SPACE_DATA {size=size}])
                  | SOME v =>
                    let
                      val (externSymbols, ty, field) =
                          selectPrimData options externSymbols v
                      val valueSize = sizeof ty
                      val align = #align (X86Emit.formatOf ty)
                    in
                      (externSymbols, align, field :: makePad (valueSize, size))
                    end
            in
              (externSymbols,
               R.DATA {scope = scope, symbol = symbol, aliases = aliases,
                       ptrTy = R.Void, section = R.DATA_SECTION,
                       prefix = nil, align = align, data = data,
                       prefixSize = 0})
            end
        end

  fun selectConstants options externSymbols constants =
      VarID.Map.foldri
        (fn (constId, data, (externSymbols, topdecls)) =>
            let
              val symbol = constSymbolName constId
              val (externSymbols, topdecl) =
                  selectData options externSymbols
                             {scope=R.LOCAL, symbol=symbol, aliases=nil}
                             data
            in
              (externSymbols, topdecl :: topdecls)
            end)
        (externSymbols, nil)
        constants

  fun selectGlobals options externSymbols globals =
      let
        val aliasesMap =
            SEnv.foldli
              (fn (label, AI.GlobalData _, aliases) => aliases
                | (label, AI.GlobalAlias origLabel, aliases) =>
                  case SEnv.find (aliases, origLabel) of
                    SOME l => SEnv.insert (aliases, origLabel, label::l)
                  | NONE => SEnv.insert (aliases, origLabel, [label]))
              SEnv.empty
              globals
      in
        SEnv.foldri
          (fn (label, AI.GlobalAlias _, z) => z
            | (label, AI.GlobalData data, (externSymbols, topdecls)) =>
              let
                val symbol = globalSymbolName options label
                val aliases = case SEnv.find (aliasesMap, label) of
                                SOME l => map (globalSymbolName options) l
                              | NONE => nil
                val (externSymbols, topdecl) =
                    selectData options externSymbols
                               {scope=R.GLOBAL, symbol=symbol, aliases=aliases}
                               data
              in
                (externSymbols, topdecl :: topdecls)
              end)
          (externSymbols, nil)
          globals
      end

  fun selectClusters options externSymbols clusters =
      let
        val ({externSymbols, thunkSymbol}, topdecls) =
            foldr (fn (cluster, (env, topdecls)) =>
                      let
                        val (env, topdecl) = selectCluster options env cluster
                      in
                        (env, topdecl :: topdecls)
                      end)
                  ({externSymbols = externSymbols, thunkSymbol = NONE}, nil)
                  clusters

        val thunkDecls =
            case thunkSymbol of
              NONE => nil
            | SOME symbol => [R.X86GET_PC_THUNK_BX symbol]
      in
        (externSymbols, topdecls, thunkDecls)
      end

  fun nextToplevelSymbol sym =
      case RTLBackendContext.suffixNumber sym of
        NONE => raise Control.Bug "nextToplevelSymbol: format error"
      | SOME (prefix,x) => prefix ^ "." ^ Int.toString (x + 1)

  fun selectToplevel options externSymbols mainSymbol NONE =
      (externSymbols, nil)
    | selectToplevel options externSymbols mainSymbol (SOME entry) =
      let
        (* dummy code *)
        val code = {globalOffsetBase = NONE,
                    externSymbols = externSymbols,
                    handlerSlots = R.LabelMap.empty,
                    preFrameSize = 0,
                    postFrameSize = 0,
                    focus = RTLEdit.singletonFirst R.ENTER} : code

        val (code, smlPushHandlerLabel) =
            transformExtFunLabel options code "sml_push_handler"
        val (code, smlPopHandlerLabel) =
            transformExtFunLabel options code "sml_pop_handler"

        val (symbol, nextToplevelSymbol) =
            (globalSymbolName options mainSymbol, NONE)
(*
            case toplevelLabel of
              RTLBackendContext.TOP_MAIN =>
              (globalSymbolName options "smlsharp_main",
               RTLBackendContext.TOP_MAIN, NONE)
            | RTLBackendContext.TOP_NONE =>
              let
                val cur = globalSymbolName options "smlsharp_main"
                val next = globalSymbolName options "smlsharp_main.1"
              in
                (cur, RTLBackendContext.TOP_SEQ {from=cur, next=next},
                 SOME next)
              end
            | RTLBackendContext.TOP_SEQ {from,next} =>
              let
                val newNext = nextToplevelSymbol next
              in
                (next, RTLBackendContext.TOP_SEQ {from=next, next=newNext},
                 SOME newNext)
              end
*)

      in
        (#externSymbols code,
         [
           R.TOPLEVEL {symbol = symbol,
                       toplevelEntry = entrySymbolName entry,
                       nextToplevel = nextToplevelSymbol,
                       smlPushHandlerLabel = smlPushHandlerLabel,
                       smlPopHandlerLabel = smlPopHandlerLabel}
         ])
      end

  fun select ({mainSymbol},
              {toplevel, clusters, constants, globals}:AI.program) =
      let
        (* FIXME: hard coded *)
        val {cpu, manufacturer, ossys, options} = Control.targetInfo ()
        val arch =
            case ossys of
              "darwin" => SOME MachO
            | "linux" => SOME ELF
            | "mingw" => SOME COFF
            | "cygwin" => SOME COFF
            | _ => NONE
        val defaultOptions =
            case ossys of
              "darwin" => SSet.singleton "PIC"
            | _ => SSet.empty
        val options =
            foldl (fn ((positive, option), set) =>
                      if positive then SSet.add (set, option)
                      else SSet.delete (set, option) handle NotFound => set)
                  defaultOptions
                  options
        val options =
            {
              positionIndependent =
                if SSet.member (options, "PIC") then arch else NONE,
              globalSymbolStartsWithUnderscore =
                case ossys of
                  "darwin" => true
                | "linux" => false
                | "mingw" => true
                | "cygwin" => true
                | _ => false
            } : options

        val externSymbols = SEnv.empty
        val (externSymbols, toplevelDecls) =
            selectToplevel options externSymbols mainSymbol toplevel
        val (externSymbols, clusterDecls, thunkDecls) =
            selectClusters options externSymbols clusters
        val (externSymbols, constDecls) =
            selectConstants options externSymbols constants
        val (externSymbols, globalDecls) =
            selectGlobals options externSymbols globals

        val externDecls =
            SEnv.foldri
              (fn (symbol, {linkStub, linkEntry, ptrTy}, z) =>
                  R.EXTERN {symbol = symbol,
                            linkStub = linkStub,
                            linkEntry = linkEntry,
                            ptrTy = ptrTy} :: z)
              nil
              externSymbols
      in
        (toplevelDecls @ clusterDecls @ constDecls @ globalDecls
         @ externDecls @ thunkDecls)
      end

end
