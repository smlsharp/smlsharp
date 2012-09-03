(**
 * x86 instruction selection.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: VMCodeSelection.sml,v 1.12 2008/08/06 17:23:41 ohori Exp $
 *)
structure X86CodeSelection : X86CODESELECTION =
struct
  structure AbstractInstruction = AbstractInstruction2

  structure AI = AbstractInstruction
  structure I = X86Mnemonic
  structure F = FrameLayout

  infix 5 << >>
  infix 2 || && ^^
  val (op ||) = Word32.orb
  val (op &&) = Word32.andb
  val (op ^^) = Word32.xorb
  val (op <<) = Word32.<<
  val (op >>) = Word32.>>
  val notb = Word32.notb
  val toWord = BasicTypes.SInt32ToUInt32

(*
  fun padSize (size, align) =
      let
        val align = toLSZ align
      in
        (align - 0w1) - (size + align - 0w1) mod align : VM.lsz
      end
*)

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
   *  RECORD            0100     mixed structure of arbitrary type values
   *  INTINF            0110     large integer
   *                       ^
   *                    HEAD_BITTAG
   *)
  val HEAD_GC_MASK = 0wx3 << 0w26 : Word32.word
  val HEAP_BITMAP_MASK = 0w1 << 0w28 : Word32.word
  val HEAD_TYPE_MASK = notb 0w0 << 0w28 : Word32.word
  val HEAD_SIZE_MASK = notb (HEAD_TYPE_MASK || HEAD_GC_MASK) : Word32.word

  val HEAD_BITTAG_SHIFT = 28
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

  (* entry label of user program *)
  val smlMainLabel = "smlsharp_main"

  val smlGetPCThunkLabel = "__sml.get_pc_thunk"

  (* __regparm(2) void *sml_heap_alloc(size_t alloc_size, void *fp);
   * Returns new pointer. *)
  val smlHeapAllocFunLabel = "sml_alloc"
  (* __regparm(2) void sml_write_barrier(void *writeaddr, void *objaddr); *)
  val smlWriteBarrierFunLabel = "sml_write_barrier"

  fun localLabel id = "L" ^ LocalVarID.toString id
  fun constLabel id = "C" ^ LocalVarID.toString id
  fun funLabel id = "F" ^ LocalVarID.toString id

  val candidate32 = [I.EAX,I.EDX,I.ECX,I.ESI,I.EDI,I.EBX]
  val candidate8 = [I.EAX,I.EDX,I.ECX,I.EBX]

  fun newReg regs = I.ANY {id = Counters.newLocalId (), candidates = regs}
  fun newReg32 () = newReg candidate32
  fun newReg8 () = newReg candidate8
(*
  fun newReg32 () = I.ANY {id = Counters.newLocalId (), class = I.ANY32}
  fun newSaveReg32 () = I.ANY {id = Counters.newLocalId (), class = I.SAVE32}
*)
  fun newLabel () = localLabel (Counters.newLocalId ())

  fun newVar {size, align} =
      let
        val id = Counters.newLocalId ()
      in
        {id = id, format = {tag = F.UNBOXED, size = size, align = align},
         candidates = nil}
        : I.varInfo
      end

  fun newVar32 regs =
      let
        val id = Counters.newLocalId ()
      in
        {id = id, format = {tag = F.UNBOXED, size = 0w4, align = 0w4},
         candidates = regs}
        : I.varInfo
      end

  fun immAdd (I.INT x, I.INT y) = I.INT (x + y)
    | immAdd (I.WORD x, I.WORD y) = I.WORD (x + y)
    | immAdd (I.INT x, I.WORD y) = I.WORD (toWord x + y)
    | immAdd (I.WORD x, I.INT y) = I.WORD (x + toWord y)
    | immAdd (x, y) = I.CONSTADD (x, y)

  fun immAnd (I.INT x, I.INT y) = I.WORD (toWord x && toWord y)
    | immAnd (I.WORD x, I.WORD y) = I.WORD (x && y)
    | immAnd (I.INT x, I.WORD y) = I.WORD (toWord x && y)
    | immAnd (I.WORD x, I.INT y) = I.WORD (x && toWord y)
    | immAnd (x, y) = I.CONSTAND (x, y)

  fun immOr (I.INT x, I.INT y) = I.WORD (toWord x || toWord y)
    | immOr (I.WORD x, I.WORD y) = I.WORD (x || y)
    | immOr (I.INT x, I.WORD y) = I.WORD (toWord x || y)
    | immOr (I.WORD x, I.INT y) = I.WORD (x || toWord y)
    | immOr (x, y) = raise Control.Bug "immOr"

  fun immShiftL (I.INT x, y) = I.WORD (toWord x << Word.fromInt y)
    | immShiftL (I.WORD x, y) = I.WORD (x << Word.fromInt y)
    | immShiftL (x, y) = raise Control.Bug "immShiftL"

  fun imm8 x = immAnd (x, I.WORD 0wxff)
  fun imm16 x = immAnd (x, I.WORD 0wxffff)

  fun makeInsn insn op2 (I.I_ x, I.I_ y) = (nil, I.I_ (op2 (x, y)))
    | makeInsn insn op2 (x, y) =
      let
        val reg = newReg32 ()
      in
        ([
           I.MOVL (I.R reg, x),
           insn (I.R reg, y)
         ],
         I.R_ reg)
      end

  val addInsn = makeInsn I.ADDL immAdd
  val andInsn = makeInsn I.ANDL immAnd
  val orInsn = makeInsn I.ORL immOr

  fun shiftLInsn (I.I_ x, y) = (nil, I.I_ (immShiftL (x, y)))
    | shiftLInsn (x, y) =
      let
        val reg = newReg32 ()
      in
        ([
           I.MOVL (I.R reg, x),
           I.SHLL (I.R reg, y)
         ],
         I.R_ reg)
      end




(*
  structure AS = Absyn
  structure AI = AbstractInstruction
  structure Target = AbstractInstruction.Target
  structure VM = VMMnemonic
  structure M = MachineLanguage

  (* FIXME: 32bit dependent *)
  infix || && << >> ^^
  val (op ||) = Word32.orb
  val (op &&) = Word32.andb
  val (op ^^) = Word32.xorb
  val (op <<) = Word32.<<
  val (op >>) = Word32.>>
  val notb = Word32.notb

  val wordSize   = 0w4 : word
  val doubleSize = 0w8 : word
  val quadSize   = 0w16 : word
  val realSize   = 0w8 : word
  val genericSize = doubleSize : word    (* FIXME *)
  val maxAlign   = 0w8 : word            (* FIXME *)

(*
  val NullLabel = VM.EXTDATAREF "__NULL__"
  val NowhereLabel = VM.EXTDATAREF "__NOWHERE__"
  val EmptyLabel = VM.EXTDATAREF "__EMPTY__"
*)


  fun WtoSSZ x = Int32.fromLarge (Word32.toLargeInt x)
  fun toSSZ x = Int32.fromLarge (Word.toLargeInt x)
  fun toLSZ x = Word32.fromLargeInt (Word.toLargeInt x)
  fun WtoSZ x = Word.fromInt (Word32.toIntX x)
  val WtoSH = WtoSZ
  fun toW x = Word32.fromLargeWord (Word.toLargeWord x)
  val LSZtoInt = Word32.toIntX

  fun padSize (size, align) =
      let
        val align = toLSZ align
      in
        (align - 0w1) - (size + align - 0w1) mod align : VM.lsz
      end

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
   *  RECORD            0100     mixed structure of arbitrary type values
   *  INTINF            0110     large integer
   *                       ^
   *                    HEAD_BITTAG
   *)
  val HEAD_GC_MASK = 0wx3 << 0w26 : VM.w
  val HEAP_BITMAP_MASK = 0w1 << 0w28 : VM.w
  val HEAD_TYPE_MASK = notb 0w0 << 0w28 : VM.w
  val HEAD_SIZE_MASK = notb (HEAD_TYPE_MASK || HEAD_GC_MASK) : VM.w

  val HEAD_BITTAG_SHIFT = 0w28
  val HEAD_TYPE_UNBOXED = 0w0 << 0w28 : VM.w
  val HEAD_TYPE_BOXED   = 0w1 << 0w28 : VM.w
  val HEAD_TYPE_VECTOR  = 0w0 << 0w29 : VM.w
  val HEAD_TYPE_ARRAY   = 0w1 << 0w29 : VM.w
  val HEAD_TYPE_RECORD  = 0w2 << 0w29 : VM.w
  val HEAD_TYPE_INTINF  = 0w3 << 0w29 : VM.w

  val HEAD_TYPE_BOXED_VECTOR   = HEAD_TYPE_VECTOR || HEAD_TYPE_BOXED
  val HEAD_TYPE_UNBOXED_VECTOR = HEAD_TYPE_VECTOR || HEAD_TYPE_UNBOXED
  val HEAD_TYPE_BOXED_ARRAY    = HEAD_TYPE_ARRAY || HEAD_TYPE_BOXED
  val HEAD_TYPE_UNBOXED_ARRAY  = HEAD_TYPE_ARRAY || HEAD_TYPE_UNBOXED

  fun labelString x = "L" ^ LocalVarID.toString x
  fun constLabelString x = "C" ^ LocalVarID.toString x
  fun LabelRef x = VM.LABELREF (labelString x)
  fun ConstRef x = VM.INTERNALREF (constLabelString x)

  fun newVar ty =
      let
        val id = Counters.newLocalId ()
        val displayName = "$" ^ LocalVarID.toString id
      in
        {id = id, ty = ty, displayName = displayName} : M.varInfo
      end

  (* BOXED, size=4, align=4 *)
  val boxedClassDesc =
      {
        tag = M.BOXED,
        size = wordSize,
        align = wordSize,
        registers = nil,
        interference = WEnv.empty
      } : M.registerClassDesc

  (* UNBOXED, size=4, align=4 *)
  val unboxedSingleClassDesc =
      {
        tag = M.UNBOXED,
        size = wordSize,
        align = wordSize,
        registers =
            [0wx00,0wx01,0wx02,0wx03, 0wx04,0wx05,0wx06,0wx07,
             0wx08,0wx09,0wx0A,0wx0B, 0wx0C,0wx0D,0wx0E,0wx0F,
             0wx10,0wx11,0wx12,0wx13, 0wx14,0wx15,0wx16,0wx17,
             0wx18,0wx19,0wx1A,0wx1B, 0wx1C,0wx1D,0wx1E,0wx1F,
             0wx20,0wx21,0wx22,0wx23, 0wx24,0wx25,0wx26,0wx27,
             0wx28,0wx29,0wx2A,0wx2B, 0wx2C,0wx2D,0wx2E,0wx2F,
             0wx30,0wx31,0wx32,0wx33, 0wx34,0wx35,0wx36,0wx37,
             0wx38,0wx39,0wx3A,0wx3B, 0wx3C,0wx3D,0wx3E,0wx3F],
        interference = WEnv.empty
      } : M.registerClassDesc

  (* UNBOXED, size=8, align=8 *)
  val unboxedDoubleClassDesc =
      let
        val registers =
            [0wx00,      0wx02,       0wx04,      0wx06,
             0wx08,      0wx0A,       0wx0C,      0wx0E,
             0wx10,      0wx12,       0wx14,      0wx16,
             0wx18,      0wx1A,       0wx1C,      0wx1E,
             0wx20,      0wx22,       0wx24,      0wx26,
             0wx28,      0wx2A,       0wx2C,      0wx2E,
             0wx30,      0wx32,       0wx34,      0wx36,
             0wx38,      0wx3A,       0wx3C,      0wx3E      ]
      in
        {
          tag = M.UNBOXED,
          size = doubleSize,
          align = doubleSize,
          registers = registers,
          interference = foldl (fn (x,z) => WEnv.insert (z,x,[x+0w1]))
                               WEnv.empty registers
        } : M.registerClassDesc
      end

  (* UNBOXED, size=16, align=16 *)
  val unboxedQuadClassDesc =
      let
        val registers =
            [0wx00,                   0wx04,
             0wx08,                   0wx0C,
             0wx10,                   0wx14,
             0wx18,                   0wx1C,
             0wx20,                   0wx24,
             0wx28,                   0wx2C,
             0wx30,                   0wx34,
             0wx38,                   0wx3C                  ]
      in
        {
          tag = M.UNBOXED,
          size = quadSize,
          align = quadSize,
          registers = registers,
          interference =
              foldl (fn (x,z) => WEnv.insert (z,x,[x+0w1,x+0w2,x+0w3]))
                    WEnv.empty registers
        } : M.registerClassDesc
      end

  (* GENERIC, size=8, align=4 or 8 *)
  fun genericClassDesc tag size =
      {
        tag = tag,
        size = size,
        align = size,
        registers = nil,
        interference = WEnv.empty
      } : M.registerClassDesc

  val initialRegisterDesc =
      {
        classes =
          [
            boxedClassDesc,             (* 0 *)
            unboxedSingleClassDesc,     (* 1 *)
            unboxedDoubleClassDesc,     (* 2 *)
            unboxedQuadClassDesc        (* 3 *)
            (* followed by generic classes ... *)
          ],
        boxedClass = 0,
        bitmapClass = 1
      } : M.registerDesc

  val boxedClass = 0
  val unboxedSingleClass = 1
  val unboxedDoubleClass = 2
  val unboxedQuadClass = 3

  val pointerClass = unboxedSingleClass
  val pointerClassDesc = unboxedSingleClassDesc

  fun addRegisterClass (desc as {classes, ...}:M.registerDesc) regclass =
      ({
         classes = classes @ [regclass],
         boxedClass = #boxedClass desc,
         bitmapClass = #bitmapClass desc
       } : M.registerDesc,
       length classes)

  val allRegisters =
      map (fn x => M.REGISTER (boxedClass, x))
          (#registers boxedClassDesc)
      @
      map (fn x => M.REGISTER (unboxedDoubleClass, x))
          (#registers unboxedSingleClassDesc)

  (* Application Binary Interface *)

  val calleeSaveRegisterIDs =
      (nil, nil)  (* boxed * unboxed; currently no callee-save registers *)

  fun calleeSaveRegisters () =
      (map (fn r => newVar (M.ALLOCED (M.REGISTER (boxedClass, r))))
           (#1 calleeSaveRegisterIDs),
       map (fn r => newVar (M.ALLOCED (M.REGISTER (unboxedSingleClass, r))))
           (#2 calleeSaveRegisterIDs))

  fun calleeSaveVars () =
      (map (fn _ => newVar (M.VAR boxedClass))
           (#1 calleeSaveRegisterIDs),
       map (fn _ => newVar (M.VAR unboxedSingleClass))
           (#2 calleeSaveRegisterIDs))

  val callerSaveRegisters =
      #registers unboxedSingleClassDesc

  (* every argumentRegister is caller save register *)
  val argumentRegisters =
      List.mapPartial
          (fn x => if x >= 0w8
                   then SOME (M.REGISTER (unboxedQuadClass, x))
                   else NONE)
          (#registers unboxedQuadClassDesc)

  val argumentSize = #size unboxedQuadClassDesc
  val numArgumentRegisters = length argumentRegisters

(*
  val unwindRegNo = 0wx0                         (* unwind register *)
  val unwindReg = M.REGISTER (pointerClass, unwindRegNo)
*)
  val linkRegNo = 0wx1                           (* link register *)
  val linkReg = M.REGISTER (pointerClass, linkRegNo)
  val envReg = M.REGISTER (boxedClass, 0wx2)     (* closure environment *)
  val entryReg = M.REGISTER (pointerClass, 0wx3) (* foreign entry *)

  (* used for passing exception object *)
  val exnRegNo = 0wx4
  val exnReg = M.REGISTER (pointerClass, exnRegNo)
  (* used for holding callee address when tailcall *)
  val tailcallReg = M.REGISTER (pointerClass, 0wx4)

  (*********************************************************************)

  type context =
      {
        registerDesc: M.registerDesc,
        tagArgMap: M.tag LocalVarID.Map.map, (* paramId -> tag *)
        calleeSaveVars: M.varInfo list * M.varInfo list, (* boxed * unboxed *)
        savedUnwindVar: M.varInfo,
        savedLinkVar: M.varInfo,
        savedEnvVar: M.varInfo,
        handlerVar: M.varInfo,
        exnVar: M.varInfo,
        constants: VM.instruction list list,
        currentHandler: AI.handler,
        continue: M.id option,
        jump: M.id list
      }

  fun getRegisterDesc (context as {registerDesc, ...}:context) class =
      List.nth (#classes registerDesc, class)
      handle Subscript => raise Control.Bug "getRegisterDesc"

  fun getRegisterClass (context as {registerDesc, ...}:context) tag size =
      let
        (* FIXME: currently all generic class must have same size. *)
        val size = genericSize

        fun find n (({tag=tag2, size=size2, ...}:M.registerClassDesc)::t) =
            if tag = tag2 andalso size = size2
            then (context, n)
            else find (n + 1) t
          | find n nil =
            let
              val (registerDesc, classId) =
                  addRegisterClass registerDesc (genericClassDesc tag size)
            in
              ({
                 registerDesc = registerDesc,
                 tagArgMap = #tagArgMap context,
                 calleeSaveVars = #calleeSaveVars context,
                 savedUnwindVar = #savedUnwindVar context,
                 savedLinkVar = #savedLinkVar context,
                 savedEnvVar = #savedEnvVar context,
                 handlerVar = #handlerVar context,
                 exnVar = #exnVar context,
                 constants = #constants context,
                 currentHandler = #currentHandler context,
                 continue = #continue context,
                 jump = #jump context
               } : context,
               classId)
            end
      in
        find 0 (#classes registerDesc)
      end

  fun addConst (context as {constants, ...}:context) const =
      {
        registerDesc = #registerDesc context,
        tagArgMap = #tagArgMap context,
        calleeSaveVars = #calleeSaveVars context,
        savedUnwindVar = #savedUnwindVar context,
        savedLinkVar = #savedLinkVar context,
        savedEnvVar = #savedEnvVar context,
        handlerVar = #handlerVar context,
        exnVar = #exnVar context,
        constants = const :: constants,
        currentHandler = #currentHandler context,
        continue = #continue context,
        jump = #jump context
      } : context

  fun startCluster (context:context) tagArgMap =
      {
        registerDesc = initialRegisterDesc,
        tagArgMap = tagArgMap,
        calleeSaveVars = #calleeSaveVars context,
        savedUnwindVar = #savedUnwindVar context,
        savedLinkVar = #savedLinkVar context,
        savedEnvVar = #savedEnvVar context,
        handlerVar = #handlerVar context,
        exnVar = #exnVar context,
        constants = #constants context,
        currentHandler = AI.NoHandler,  (* dummy *)
        continue = NONE,
        jump = nil
      } : context

  fun startBlock (context:context) handler =
      {
        registerDesc = #registerDesc context,
        tagArgMap = #tagArgMap context,
        calleeSaveVars = #calleeSaveVars context,
        savedUnwindVar = #savedUnwindVar context,
        savedLinkVar = #savedLinkVar context,
        savedEnvVar = #savedEnvVar context,
        handlerVar = #handlerVar context,
        exnVar = #exnVar context,
        constants = #constants context,
        currentHandler = handler,
        continue = NONE,
        jump = nil
      } : context

  fun addJump (context as {jump, ...}:context) labels =
      {
        registerDesc = #registerDesc context,
        tagArgMap = #tagArgMap context,
        calleeSaveVars = #calleeSaveVars context,
        savedUnwindVar = #savedUnwindVar context,
        savedLinkVar = #savedLinkVar context,
        savedEnvVar = #savedEnvVar context,
        handlerVar = #handlerVar context,
        exnVar = #exnVar context,
        constants = #constants context,
        currentHandler = #currentHandler context,
        continue = #continue context,
        jump = jump @ labels
      } : context

  fun setContinue (context as {continue, ...}:context) label =
      case continue of
        SOME _ => raise Control.Bug "setContinue: doubly set continue"
      | NONE =>
        {
          registerDesc = #registerDesc context,
          tagArgMap = #tagArgMap context,
          calleeSaveVars = #calleeSaveVars context,
          savedUnwindVar = #savedUnwindVar context,
          savedLinkVar = #savedLinkVar context,
          savedEnvVar = #savedEnvVar context,
          handlerVar = #handlerVar context,
          exnVar = #exnVar context,
          constants = #constants context,
          currentHandler = #currentHandler context,
          continue = SOME label,
          jump = #jump context
        } : context

  fun addFFType context callingConvention (argTys, retTys) =
      let
        fun toFFTy ty =
            case ty of
              AI.UINT => #"i"
            | AI.SINT => #"i"
            | AI.BYTE => #"c"
            | AI.CHAR => #"c"
            | AI.BOXED => #"p"
            | AI.HEAPPOINTER => #"p"
            | AI.CODEPOINTER => #"p"
            | AI.CPOINTER => #"p"
            | AI.ENTRY => #"p"
            | AI.FLOAT => #"f"
            | AI.DOUBLE => #"d"
            | AI.BITMAP => #"i"
            | AI.INDEX => #"i"
            | AI.OFFSET => #"i"
            | AI.SIZE => #"i"
            | AI.TAG => #"i"
            | AI.EXNTAG => #"i"
            | AI.ATOMty => #"i"
            | AI.DOUBLEty => #"d"
            | AI.UNION _ =>
              (print ("WARNING: addFFType: unsupported ffty: "^
                      Control.prettyPrint (AI.format_ty ty)^"\n");
               #"i")

        val argTys = String.implode (map toFFTy argTys)
        val retTys =
            case retTys of
              nil => "-"
            | [ty] => "-" ^ str (toFFTy ty)
            | _ => "-(" ^ String.implode (map toFFTy retTys) ^ "S"

        val convention =
            case callingConvention of
              AS.CC_DEFAULT => ""
            | AS.CC_CDECL => ""
            | AS.CC_STDCALL => ":stdcall:"

        val ffty = convention ^ argTys ^ retTys
        val sz = toLSZ (Word.fromInt (size ffty))
        val pad = padSize (sz + 0w1, maxAlign) + 0w1

        val label = constLabelString (Counters.newLocalId ())
        val const =
            [
              VM.Label label,
              VM.ConstString ffty,
              VM.Const (List.tabulate (LSZtoInt pad, fn _ => VM.CONST_B 0w0))
            ]
      in
        (addConst context const, VM.INTERNALREF label)
      end


  (*********************************************************************)

  datatype vmty =
      TY of VM.ty
    | SIZE of VM.sz

  fun transformTy context ty =
      case ty of
        AI.UINT => (context, TY VM.W, unboxedSingleClass)
      | AI.SINT => (context, TY VM.N, unboxedSingleClass)
      | AI.BYTE => (context, TY VM.W, unboxedSingleClass)
      | AI.CHAR => (context, TY VM.W, unboxedSingleClass)
      | AI.BOXED => (context, TY VM.P, boxedClass)
      | AI.HEAPPOINTER => (context, TY VM.P, pointerClass)
      | AI.CODEPOINTER => (context, TY VM.P, pointerClass)
      | AI.CPOINTER => (context, TY VM.P, pointerClass)
      | AI.ENTRY => (context, TY VM.P, pointerClass)
      | AI.FLOAT => (context, TY VM.FS, unboxedSingleClass)
      | AI.DOUBLE => (context, TY VM.F, unboxedDoubleClass)
      | AI.INDEX => (context, TY VM.W, unboxedSingleClass)
      | AI.BITMAP => (context, TY VM.W, unboxedSingleClass)
      | AI.OFFSET => (context, TY VM.W, unboxedSingleClass)
      | AI.SIZE => (context, TY VM.W, unboxedSingleClass)
      | AI.TAG => (context, TY VM.W, unboxedSingleClass)
      | AI.EXNTAG => (context, TY VM.W, unboxedSingleClass)
      | AI.ATOMty => (context, TY VM.W, unboxedSingleClass)
      | AI.DOUBLEty => (context, TY VM.F, unboxedDoubleClass)
      | AI.UNION {tag, variants} =>
        let
          val tag =
              case tag of
                AI.Boxed => M.BOXED
              | AI.Unboxed => M.UNBOXED
              | AI.IndirectTag {offset, bit} =>
                M.FREEGENERIC {entity = envReg,
                               offset = Target.UIntToWord offset,
                               bit = bit}
              | AI.ParamTag {id, ...} =>
                case LocalVarID.Map.find (#tagArgMap context, id) of
                  SOME tag => tag
                | NONE => raise Control.Bug ("transformTy: ParamTag: "^
                                             LocalVarID.toString id)

          val size =
              foldl (fn (x,z) => Word.max (sizeOf context x, z))
                    0w0 variants

          val (context, class) = getRegisterClass context tag size
        in
          (context, SIZE size, class)
        end

  and sizeOf context ty =
      let
        val (_, _, class) = transformTy context ty
      in
        #size (getRegisterDesc context class)
      end

  fun classOf mty =
      case mty of
        M.VAR x => x
      | M.REG x => x
      | M.STK x => x
      | M.ALLOCED (M.REGISTER (x, _)) => x
      | M.ALLOCED (M.STACK (x, _)) => x
      | M.ALLOCED (M.HANDLER x) => x

  fun transformVarInfo context ({id, displayName, ty}:AI.varInfo) =
      let
        val (context, vmty, class) = transformTy context ty

        (* boxed value must be allocated to stack frame so that
         * GC can find it. *)
        (* FIXME: more efficient way *)
        val mty = if class = boxedClass then M.STK class else M.VAR class

        val newVarInfo =
            {
              id = id,
              displayName = displayName,
              ty = mty
            } : M.varInfo
      in
        (context, newVarInfo, vmty)
      end

  fun transformVarInfoList context (var::varList) =
      let
        val (context, var, vmty) = transformVarInfo context var
        val (context, vars, vmtys) = transformVarInfoList context varList
      in
        (context, var::vars, vmty::vmtys)
      end
    | transformVarInfoList context nil = (context, nil, nil)

  datatype value =
      VAR of M.varInfo
    | IMM of VM.imm
    | LABEL of VM.label

  (* for debug *)
  fun format_value value =
      case value of
        VAR x => "VAR " ^ Control.prettyPrint (M.format_varInfo x)
      | IMM x => "IMM " ^ VMMnemonicFormatter.formatImm x
      | LABEL x => "LABEL " ^ VMMnemonicFormatter.formatLabel x

  fun takeVAR l = foldr (fn (VAR v, z) => v::z | (_, z) => z) nil l

  local
    fun transformConst context imm aity =
        let
          val (context, vmty, class) = transformTy context aity
        in
          (context, imm, vmty, M.VAR class)
        end

    fun transformVar context varInfo =
        let
          val (context, varInfo, vmty) = transformVarInfo context varInfo
        in
          (context, VAR varInfo, vmty, #ty varInfo)
        end

  in

  fun transformValue context value =
      case value of
        AI.UInt n => transformConst context (IMM (VM.CONST_W n)) AI.UINT
      | AI.SInt n => transformConst context (IMM (VM.CONST_N n)) AI.SINT
      | AI.Real n => transformConst context (IMM (VM.CONST_F n)) AI.DOUBLE
      | AI.Float n => transformConst context (IMM (VM.CONST_FS n)) AI.FLOAT
      | AI.Var v => transformVar context v
      | AI.Param v => transformVar context v
      | AI.Exn v => transformVar context v
      | AI.Env =>
        (context, VAR (#savedEnvVar context), TY VM.P, M.VAR boxedClass)
      | AI.Null =>
        (context, IMM (VM.EXTERN NullLabel), TY VM.P, M.VAR pointerClass)
      | AI.Nowhere =>
        (context, IMM (VM.EXTERN NowhereLabel), TY VM.P, M.VAR pointerClass)
      | AI.Empty =>
        (context, IMM (VM.EXTERN EmptyLabel), TY VM.P, M.VAR boxedClass)
      | AI.Entry {clusterId, entry} =>
        (context, LABEL (LabelRef entry), TY VM.P, M.VAR pointerClass)
      | AI.Label label =>
        (context, LABEL (LabelRef label), TY VM.P, M.VAR pointerClass)
      | AI.Init constId =>
        (context, IMM (VM.EXTERN (ConstRef constId)),
         TY VM.P, M.VAR pointerClass)
      | AI.Const constId =>
        (context, IMM (VM.EXTERN (ConstRef constId)), TY VM.P, M.VAR boxedClass)
      | (* FIXME: separate compilation *)
        AI.Extern {label = {label, value=SOME (AI.GLOBAL_TAG t), ...}, ...} =>
        transformConst context (IMM (VM.CONST_W t)) AI.UINT
      | AI.Global {label = {label, ...}, ty} =>
        let
          val (context, vmty, class) = transformTy context ty
        in
          (context, IMM (VM.EXTERN (VM.INTERNALREF label)), vmty, M.VAR class)
        end
      | AI.Extern {label = {label, ...}, ty} =>
        let
          val (context, vmty, class) = transformTy context ty
        in
          (context, IMM (VM.EXTERN (VM.GLOBALREF label)), vmty, M.VAR class)
        end

  end

  fun transformValueList context (value::valueList) =
      let
        val (context, value, vmty, mty) = transformValue context value
        val (context, values, vmtys, mtys) =
            transformValueList context valueList
      in
        (context, value::values, vmty::vmtys, mty::mtys)
      end
    | transformValueList context nil = (context, nil, nil, nil)

  fun copyVars dstList varList vmtyList loc =
      let
        fun gen dstHole srcHole (dst::dsts) (var::vars) (vmty::vmtys) =
            (case vmty of
               TY ty => VM.MOV (ty, VM.HOLE dstHole, VM.HOLE srcHole)
             | SIZE sz => VM.MOVX (sz, VM.HOLE dstHole, VM.HOLE srcHole))
            :: gen (dstHole + 1) (srcHole + 1) dsts vars vmtys
          | gen dstHole srcHole nil nil nil = nil
          | gen dstHole srcHole _ _ _ = raise Control.Bug "copyVars"

        val insns = gen (length varList) 0 dstList varList vmtyList
      in
        case insns of
          nil => nil
        | _ =>
          [
            M.Code {code = insns,
                    use = varList,
                    def = dstList,
                    clob = [],
                    kind = M.MOVE,
                    loc = loc}
          ]
      end

  fun makeMove dst value vmty loc =
      let
        val (use, kind, insn) =
            case (value, vmty) of
              (IMM imm, TY ty) =>
              ([], M.NORMAL, VM.MVI (ty, VM.HOLE 0, imm))
            | (IMM imm, SIZE _) => raise Control.Bug "makeMove: IMM SIZE"
            | (VAR var, TY ty) =>
              ([var], M.MOVE, VM.MOV (ty, VM.HOLE 1, VM.HOLE 0))
            | (VAR var, SIZE n) =>
              ([var], M.MOVE, VM.MOVX (n, VM.HOLE 1, VM.HOLE 0))
            | (LABEL l, TY VM.P) =>
              ([], M.NORMAL, VM.MVFIP (VM.HOLE 0, l))
            | (LABEL l, _) => raise Control.Bug "makeMove: LABEL not P"
      in
        [
          M.Code {code = [insn],
                  use = use,
                  def = [dst],
                  clob = [],
                  kind = kind,
                  loc = loc}
        ]
      end

  fun bindFresh loc ty (context, value, vmty, mty) =
      let
        val var = newVar ty
      in
        (context, makeMove var value vmty loc, var, vmty)
      end

  fun bindValue loc (context:context, value, vmty, mty) =
      case value of
        VAR var => (context, nil, var, vmty)
      | _ =>
        let
          val var = newVar mty
          val code = makeMove var value vmty loc
        in
          (context, code, var, vmty)
        end

  fun bindValueVar loc (context, value, vmty, mty) =
      let
        val (context, code, var, vmty) =
            bindValue loc (context, value, vmty, mty)
      in
        (context, code, VAR var, vmty)
      end

  fun bindValueList loc (context, v::valueList, vmty::vmtyList, mty::mtyList) =
      let
        val (context, code, var, vmty) = bindValue loc (context, v, vmty, mty)
        val (context, codes, vars, vmtys) =
            bindValueList loc (context, valueList, vmtyList, mtyList)
      in
        (context, code @ codes, var::vars, vmty::vmtys)
      end
    | bindValueList loc (context, nil, nil, nil) = (context, nil, nil, nil)
    | bindValueList loc _ = raise Control.Bug "bindValueList"

  fun bindIfLabel loc (context, value, vmty, mty) =
      case value of
        IMM _ => (context, nil, value, vmty)
      | VAR _ => (context, nil, value, vmty)
      | LABEL _ => bindValueVar loc (context, value, vmty, mty)

  fun bindIfLabelList loc
                      (context, v::valueList, vmty::vmtyList, mty::mtyList) =
      let
        val (context, code, value, vmty) =
            bindIfLabel loc (context, v, vmty, mty)
        val (context, codes, values, vmtys) =
            bindIfLabelList loc (context, valueList, vmtyList, mtyList)
      in
        (context, code @ codes, value::values, vmty::vmtys)
      end
    | bindIfLabelList loc (context, nil, nil, nil) = (context, nil, nil, nil)
    | bindIfLabelList loc _ = raise Control.Bug "bindIfLabelList"

  fun bindIfNotLabel loc (context, value, vmty, mty) =
      case value of
        IMM _ => bindValueVar loc (context, value, vmty, mty)
      | VAR _ => (context, nil, value, vmty)
      | LABEL _ => (context, nil, value, vmty)

  fun passArgs varInfoList varTys loc =
      if length varInfoList <= numArgumentRegisters
      then
        (*
         * Pass every arguments by unboxed double-size register
         * regardless of its type.
         *)
        let
          val regs = ListPair.map (fn (_, ent) => newVar (M.ALLOCED ent))
                                  (varInfoList, argumentRegisters)
        in
          (copyVars regs varInfoList varTys loc, regs)
        end
      else
        (*
         * If the number of arguments is exceeded the number of argument
         * registers, create an array for passing argument and pass it
         * by first argument register.
         *)
        let
          val size = argumentSize * Word.fromInt (length varInfoList)
          val dstVar = newVar (M.ALLOCED (List.hd argumentRegisters))
          val dstHole = VM.HOLE (length varInfoList)

          val size = toLSZ size
          val wordSize = toSSZ wordSize

          val header = HEAD_TYPE_UNBOXED_ARRAY || size

          fun store i n (ty::tys) =
              (case ty of
                 TY ty => VM.STM (ty, dstHole, i, VM.HOLE n)
               | SIZE sz => VM.STMX (sz, dstHole, i, VM.HOLE n))
              :: store (i + toSSZ argumentSize) (n + 1) tys
            | store i n nil = nil
        in
          ([
             M.Code
               {code =
                  (* dst = AllocArray(size = numArgs * argumentSize) *)
                  VM.ALLOCX (dstHole, size) ::
                  VM.STI    (VM.W, dstHole, ~wordSize, VM.CONST_W header) ::
                  (* for all args, dst[i] = arg[i] *)
                  store 0 0 varTys,
                use = varInfoList,
                def = [dstVar],
                clob = [],
                kind = M.NORMAL,
                loc = loc}
           ],
           [dstVar])
        end

  fun receiveArgs varInfoList varTys loc =
      if length varInfoList <= numArgumentRegisters
      then
        (*
         * Every arguments are passed by unboxed double-size register
         * regardless of its type. Receiver must be stored boxed
         * arguemnts to root set as soon as possible.
         *)
        let
          val regs = ListPair.map (fn (_, ent) => newVar (M.ALLOCED ent))
                                  (varInfoList, argumentRegisters)
        in
          (copyVars varInfoList regs varTys loc, regs)
        end
      else
        (*
         * If the number of arguments is exceeded the number of argument
         * registers, arguments are packed into one unboxed double-size
         * array and its address is passed by first argument register.
         *)
        let
          val packedVar = newVar (M.ALLOCED (List.hd argumentRegisters))

          fun load i n (ty::tys) =
              (case ty of
                 TY ty => VM.LDM (ty, VM.HOLE n, VM.HOLE 0, i)
               | SIZE sz => VM.LDMX (sz, VM.HOLE n, VM.HOLE 0, i))
              :: load (i + toSSZ argumentSize) (n + 1) tys
            | load i n nil = nil
        in
          ([
             M.Code {code = load 0 1 varTys,
                     use = [packedVar],
                     def = varInfoList,
                     clob = [],
                     kind = M.NORMAL,
                     loc = loc}
           ],
           [packedVar])
        end

  fun makeTagArgMap params =
      if length params < numArgumentRegisters
      then
        (*
         * Every arguments are passed by unboxed double-size register
         * regardless of its type. Receiver must be stored boxed
         * arguemnts to root set as soon as possible.
         *)
        ListPair.foldl
          (fn ({id,...}, ent, map) => LocalVarID.Map.insert (map, id, M.GENERIC ent))
          LocalVarID.Map.empty
          (params, argumentRegisters)
      else
        (*
         * If the number of arguments is exceeded the number of argument
         * registers, arguments are packed into one unboxed double-size
         * array and its address is passed by first argument register.
         *)
        #1 (foldl
             (fn ({id, ...}:AI.paramInfo, (map, i)) =>
                 (LocalVarID.Map.insert (map, id,
                                 M.FREEGENERIC
                                     {entity = List.hd argumentRegisters,
                                      offset = i,
                                      bit = 0w0}),
                  i + argumentSize))
             (LocalVarID.Map.empty, 0w0)
             params)

  fun callerSaveVars use =
      let
        val inUse =
            foldr (fn ({ty, ...}:M.varInfo, inUse) =>
                      case ty of
                        M.ALLOCED (M.REGISTER (class, reg)) =>
                        if class = unboxedDoubleClass
                        then reg :: reg+0w1 :: inUse
                        else reg :: inUse
                      | _ => inUse)
                  nil
                  use
        val saves =
            List.filter (fn x => not (List.exists (fn r => r = x) inUse))
                        callerSaveRegisters

        (* dummy class for caller save registers *)
        val dummyClass = unboxedSingleClass
      in
        map (fn r => M.REGISTER (dummyClass, r)) saves
      end

  fun prologue context params loc =
      let
        (* save link register *)
        val linkVar = newVar (M.ALLOCED linkReg)
        val code1 = copyVars [#savedLinkVar context]
                             [linkVar]
                             [TY VM.P] loc

        (* save env register *)
        val envVar = newVar (M.ALLOCED envReg)
        val code2 = copyVars [#savedEnvVar context]
                             [envVar]
                             [TY VM.P] loc

        (* save callee save registers *)
        val (boxedCalleeSaves, unboxedCalleeSaves) = calleeSaveRegisters ()
        val code3 = copyVars (#1 (#calleeSaveVars context))
                             boxedCalleeSaves
                             (map (fn _ => TY VM.P) boxedCalleeSaves)
                             loc
        val code4 = copyVars (#2 (#calleeSaveVars context))
                             unboxedCalleeSaves
                             (map (fn _ => SIZE wordSize) unboxedCalleeSaves)
                             loc

        (* receive parameters *)
        val (context, params, paramTys) =
            transformVarInfoList context params
        val (code5, argRegs) =
            receiveArgs params paramTys loc

        (* reserved registers for computing bitmaps *)
        val bitmapReg1 = newVar (M.REG unboxedSingleClass)
        val bitmapReg2 = newVar (M.REG unboxedSingleClass)
      in
        (context,
         M.Code {code = [ VM.ENTER 0w0 ],   (* dummy size *)
                 use = [],
                 def = bitmapReg1 :: bitmapReg2 ::
                       linkVar :: envVar :: argRegs @
                       boxedCalleeSaves @ unboxedCalleeSaves,
                 clob = [],
                 kind = M.NORMAL,
                 loc = loc} ::
         code1 @ code2 @ code3 @ code4 @ code5)
      end

  fun epilogue (context:context) loc =
      let
        (* restore link register *)
        val linkVar = newVar (M.ALLOCED linkReg)
        val code1 = copyVars [linkVar]
                             [#savedLinkVar context]
                             [TY VM.P] loc

        (* restore callee save registers *)
        val (boxedCalleeSaves, unboxedCalleeSaves) = calleeSaveRegisters ()
        val code2 = copyVars boxedCalleeSaves
                             (#1 (#calleeSaveVars context))
                             (map (fn _ => TY VM.P) boxedCalleeSaves)
                             loc
        val code3 = copyVars unboxedCalleeSaves
                             (#2 (#calleeSaveVars context))
                             (map (fn _ => SIZE wordSize) unboxedCalleeSaves)
                             loc
      in
        (code1 @ code2 @ code3 @
         [
           M.Code {code = [ VM.LEAVE 0w0 ],   (* dummy size *)
                   use = [],
                   def = [],
                   clob = [],
                   kind = M.NORMAL,
                   loc = loc}
         ],
         (* link regsiter must be first *)
         linkVar :: boxedCalleeSaves @ unboxedCalleeSaves)
      end

  fun getArrayLength blockVar dstVar loc =
      (*
       * Obtain the length of the array from its object header.
       *
       * [head] [data] [data] ... [data]
       *        ^
       *        ptr
       *
       * length = head & HEAD_SIZE_MASK
       *)
      [
        M.Code {code = [
                  VM.LDM  (VM.W, VM.HOLE 1, VM.HOLE 0, ~(toSSZ wordSize)),
                  VM.ANDI (VM.W, VM.HOLE 1, VM.HOLE 1,
                           VM.CONST_W HEAD_SIZE_MASK)
                ],
                use = [blockVar],
                def = [dstVar],
                clob = [],
                kind = M.NORMAL,
                loc = loc}
      ]

  fun callBuiltin context
                  {primName, argVars, argTys, retVars, retTys, loc} =
      let
        val _ =
            if length argVars > numArgumentRegisters
            then raise Control.Bug "callBuiltin: too many arguments" else ()
        val _ =
            if length retVars > numArgumentRegisters
            then raise Control.Bug "callBuiltin: too many returns" else ()

        val (code1, use) = passArgs argVars argTys loc
        val (code2, def) = receiveArgs retVars retTys loc
      in
        (context,
         code1 @
         [
           M.Code {code = [ VM.SYSCALL (VM.PRIMREF primName) ],
                   use = use,
                   def = def,
                   clob = [],
                   kind = M.NORMAL,
                   loc = loc}
         ] @
         code2)
      end

  fun callForeign (context, entry, vmty, mty)
                  {calleeTy, convention, argVars, argTys, retVars, retTys,
                   loc} =
      let
        val (context, ffty) = addFFType context convention calleeTy

        val (retVars, retTys) =
            case (retVars, retTys) of
              (nil, nil) => ([newVar (M.VAR unboxedSingleClass)], [TY VM.W])
            | _ => (retVars, retTys)
      in
        case (entry, argVars, retVars) of
          (IMM (VM.EXTERN entry), [arg1], [ret1]) =>
          (context,
           [
             M.Code {code = [ VM.FFCALL1 (ffty, entry, VM.HOLE 1, VM.HOLE 0) ],
                     use = [arg1],
                     def = [ret1],
                     clob = [],
                     kind = M.NORMAL,
                     loc = loc}
           ])
        | (IMM (VM.EXTERN entry), [arg1, arg2], [ret1]) =>
          (context,
           [
             M.Code {code = [ VM.FFCALL2 (ffty, entry, VM.HOLE 2,
                                          VM.HOLE 0, VM.HOLE 1) ],
                     use = [arg1, arg2],
                     def = [ret1],
                     clob = [],
                     kind = M.NORMAL,
                     loc = loc}
           ])
        | (IMM (VM.EXTERN entry), [arg1, arg2, arg3], [ret1]) =>
          (context,
           [
             M.Code {code = [ VM.FFCALL3 (ffty, entry, VM.HOLE 3,
                                          VM.HOLE 0, VM.HOLE 1, VM.HOLE 2) ],
                     use = [arg1, arg2, arg3],
                     def = [ret1],
                     clob = [],
                     kind = M.NORMAL,
                     loc = loc}
           ])
        | (_, _, [ret1]) =>
          let
            val (code1, use) = passArgs argVars argTys loc
            val (context, code2, entry, _) =
                bindValue loc (context, entry, vmty, mty)
            val retHole = length use + 1
          in
            (context,
             code1 @ code2 @
             [
               M.Code {code = [ VM.FFCALL (ffty, VM.HOLE 0, VM.HOLE retHole) ],
                       use = entry :: use,
                       def = [ret1],
                       clob = [],
                       kind = M.NORMAL,
                       loc = loc}
             ])
          end
        | _ =>
          raise Control.Bug ("callForeign: multiple return value is not \
                             \implemented at"^
                             Control.prettyPrint (Loc.format_loc loc))
      end

  fun callPrim context
               {primName, calleeTy, argVars, argTys, retVars, retTys, loc} =
      callForeign
          (context, IMM (VM.EXTERN (VM.PRIMREF primName)),
           TY VM.P, M.VAR pointerClass)
          {calleeTy = calleeTy,
           convention = AS.CC_DEFAULT,
           argVars = argVars,
           argTys = argTys,
           retVars = retVars,
           retTys = retTys,
           loc = loc}

  fun selectOp1 context (op1 as (_, ty1, ty2))
                (dstVar, dstTy)
                (argVar, argTy)
                loc =
      let
        fun emitPrim primName =
            callPrim context
                     {primName = primName,
                      calleeTy = ([ty1], [ty2]),
                      argVars = [argVar],
                      retVars = [dstVar],
                      argTys = [argTy],
                      retTys = [dstTy],
                      loc = loc}
        fun emit' insn =
            (context,
             [
               M.Code {code = [insn],
                       use = [argVar],
                       def = [dstVar],
                       clob = [],
                       kind = M.NORMAL,
                       loc = loc}
             ])
        fun emit insnCon ty =
            emit' (insnCon (ty, VM.HOLE 1, VM.HOLE 0))
      in
        case op1 of
          (AI.Neg, AI.SINT, AI.SINT) =>
          emit' (VM.SUBR (VM.N, VM.HOLE 1, VM.CONST_N 0, VM.HOLE 0))
        | (AI.Neg, AI.FLOAT, AI.FLOAT) =>
          emit' (VM.SUBR (VM.FS, VM.HOLE 1, VM.CONST_FS "0.0", VM.HOLE 0))
        | (AI.Neg, AI.DOUBLE, AI.DOUBLE) =>
          emit' (VM.SUBR (VM.F, VM.HOLE 1, VM.CONST_F "0.0", VM.HOLE 0))
        | (AI.Abs, AI.SINT, AI.SINT) => emitPrim "absn"
        | (AI.Abs, AI.FLOAT, AI.FLOAT) => emitPrim "absfs"
        | (AI.Abs, AI.DOUBLE, AI.DOUBLE) => emitPrim "absf"
        | (AI.Cast, AI.UINT, AI.FLOAT) => emit VM.CVTW VM.FS
        | (AI.Cast, AI.UINT, AI.DOUBLE) => emit VM.CVTW VM.F
        | (AI.Cast, AI.SINT, AI.FLOAT) => emit VM.CVTN VM.FS
        | (AI.Cast, AI.SINT, AI.DOUBLE) => emit VM.CVTN VM.F
        | (AI.Cast, AI.FLOAT, AI.UINT) => emit VM.CVTFS VM.W
        | (AI.Cast, AI.FLOAT, AI.SINT) => emit VM.CVTFS VM.N
        | (AI.Cast, AI.FLOAT, AI.DOUBLE) => emit VM.CVTFS VM.F
        | (AI.Cast, AI.DOUBLE, AI.UINT) => emit VM.CVTF VM.W
        | (AI.Cast, AI.DOUBLE, AI.SINT) => emit VM.CVTF VM.N
        | (AI.Cast, AI.DOUBLE, AI.FLOAT) => emit VM.CVTF VM.FS
        | (AI.Cast, AI.UINT, AI.SINT) => emit VM.MOV VM.W  (* FIXME *)
        | (AI.Cast, AI.UINT, AI.BYTE) => emit VM.MOV VM.W  (* FIXME *)
        | (AI.Cast, AI.UINT, AI.CHAR) => emit VM.MOV VM.W  (* FIXME *)
        | (AI.Cast, AI.SINT, AI.UINT) => emit VM.MOV VM.N  (* FIXME *)
        | (AI.Cast, AI.SINT, AI.BYTE) => emit VM.MOV VM.N  (* FIXME *)
        | (AI.Cast, AI.SINT, AI.CHAR) => emit VM.MOV VM.N  (* FIXME *)
        | (AI.Cast, AI.CHAR, AI.UINT) => emit VM.MOV VM.W  (* FIXME *)
        | (AI.Cast, AI.CHAR, AI.SINT) => emit VM.EXTB VM.N
        | (AI.Cast, AI.CHAR, AI.BYTE) => emit VM.MOV VM.W  (* FIXME *)
        | (AI.Cast, AI.BYTE, AI.UINT) => emit VM.MOV VM.W  (* FIXME *)
        | (AI.Cast, AI.BYTE, AI.SINT) => emit VM.MOV VM.W  (* FIXME *)
        | (AI.Cast, AI.BYTE, AI.CHAR) => emit VM.MOV VM.W  (* FIXME *)
        | (AI.Notb, AI.UINT, AI.UINT) => emit VM.NOT VM.W
        | (AI.Length, AI.BOXED, AI.UINT) =>
          (context, getArrayLength argVar dstVar loc)
        | (op1, ty1, ty2) =>
          raise Control.Bug
                  ("selectOp1: " ^
                   Control.prettyPrint (AI.format_op1 nil op1)^", "^
                   Control.prettyPrint (AI.format_ty ty1) ^ ", " ^
                   Control.prettyPrint (AI.format_ty ty2))
      end

  fun immToSH (VM.CONST_W x) = WtoSH x
    | immToSH _ = raise Control.Bug "immToSH"

  fun coercePrimTy _ _ AI.CHAR = AI.UINT
    | coercePrimTy _ _ AI.BYTE = AI.UINT
    | coercePrimTy (value1, vmty1, _) (value2, vmty2, _) AI.ATOMty =
      (* FIXME: workaround for ATOMty *)
      let
        fun f (IMM _, TY VM.W) = SOME AI.UINT
          | f (IMM _, TY VM.N) = SOME AI.SINT
          | f (IMM _, TY VM.F) = SOME AI.FLOAT
          | f (IMM _, TY VM.FS) = SOME AI.DOUBLE
          | f _ = NONE
      in
        case f (value1, vmty1) of
          SOME x => x
        | NONE => case f (value2, vmty2) of
                    SOME x => x
                  | NONE => AI.UINT
      end
    | coercePrimTy _ _ AI.DOUBLEty = AI.DOUBLE
    | coercePrimTy _ _ ty = ty

  fun selectOp2 context op2
                (dst as (dstVar, dstTy))
                (arg1 as (value1, vmty1, mty1))
                (arg2 as (value2, vmty2, mty2))
                loc =
      let
        fun bindAndRetry () =
            let
              val (context, code1, value1, _) =
                  bindValue loc (context, value1, vmty1, mty1)
              val (context, code2) =
                  selectOp2 context op2 dst (VAR value1, vmty1, mty1) arg2 loc
            in
              (context, code1 @ code2)
            end

        fun emit (insn, use) =
            (context,
             [
               M.Code {code = [insn],
                       use = use,
                       def = [dstVar],
                       clob = [],
                       kind = M.NORMAL,
                       loc = loc}
             ])

        val coercePrimTy = coercePrimTy arg1 arg2

        val h0 = VM.HOLE 0
        val h1 = VM.HOLE 1
        val h2 = VM.HOLE 2
        val (op2, ty1, ty2, ty3) = op2
        val op2 = (op2, coercePrimTy ty1, coercePrimTy ty2, coercePrimTy ty3)
      in
        case (value1, value2, op2) of
        (* unfolded constant *)
          (IMM _, IMM _, _) => bindAndRetry ()
        (* Add *)
        | (VAR v1, VAR v2, (AI.Add, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.ADD (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Add, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.ADD (VM.N, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Add, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.ADD (VM.FS, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Add, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.ADD (VM.F, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.Add, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.ADDI (VM.W, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Add, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.ADDI (VM.N, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Add, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.ADDI (VM.FS, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Add, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.ADDI (VM.F, h1, h0, i2), [v1])
        | (IMM _,  VAR _,  (AI.Add, t1, t2, t3)) =>
          selectOp2 context (AI.Add, t2, t1, t3) dst arg2 arg1 loc
        (* Sub *)
        | (VAR v1, VAR v2, (AI.Sub, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.SUB (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Sub, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.SUB (VM.N, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Sub, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.SUB (VM.FS, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Sub, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.SUB (VM.F, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.Sub, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.SUBI (VM.W, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Sub, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.SUBI (VM.N, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Sub, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.SUBI (VM.FS, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Sub, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.SUBI (VM.F, h1, h0, i2), [v1])
        | (IMM i1, VAR v2, (AI.Sub, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.SUBR (VM.W, h1, i1, h0), [v2])
        | (IMM i1, VAR v2, (AI.Sub, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.SUBR (VM.N, h1, i1, h0), [v2])
        | (IMM i1, VAR v2, (AI.Sub, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.SUBR (VM.FS, h1, i1, h0), [v2])
        | (IMM i1, VAR v2, (AI.Sub, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.SUBR (VM.F, h1, i1, h0), [v2])
        (* Mul *)
        | (VAR v1, VAR v2, (AI.Mul, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.MUL (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Mul, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.MUL (VM.N, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Mul, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.MUL (VM.FS, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Mul, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.MUL (VM.F, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.Mul, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.MULI (VM.W, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Mul, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.MULI (VM.N, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Mul, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.MULI (VM.FS, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Mul, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.MULI (VM.F, h1, h0, i2), [v1])
        | (IMM _,  VAR _,  (AI.Mul, t1, t2, t3)) =>
          selectOp2 context (AI.Mul, t2, t1, t3) dst arg2 arg1 loc
        (* Div *)
        | (VAR v1, VAR v2, (AI.Div, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.DIV (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Div, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.DIV (VM.N, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Div, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.DIV (VM.FS, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Div, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.DIV (VM.F, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.Div, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.DIVI (VM.W, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Div, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.DIVI (VM.N, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Div, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.DIVI (VM.FS, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Div, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.DIVI (VM.F, h1, h0, i2), [v1])
        | (IMM i1, VAR v2, (AI.Div, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.DIVR (VM.W, h1, i1, h0), [v2])
        | (IMM i1, VAR v2, (AI.Div, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.DIVR (VM.N, h1, i1, h0), [v2])
        | (IMM i1, VAR v2, (AI.Div, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.DIVR (VM.FS, h1, i1, h0), [v2])
        | (IMM i1, VAR v2, (AI.Div, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.DIVR (VM.F, h1, i1, h0), [v2])
        (* Mod *)
        | (VAR v1, VAR v2, (AI.Mod, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.MOD (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Mod, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.MOD (VM.N, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Mod, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.MOD (VM.FS, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Mod, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.MOD (VM.F, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.Mod, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.MODI (VM.W, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Mod, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.MODI (VM.N, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Mod, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.MODI (VM.FS, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Mod, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.MODI (VM.F, h1, h0, i2), [v1])
        | (IMM i1, VAR v2, (AI.Mod, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.MODR (VM.W, h1, i1, h0), [v2])
        | (IMM i1, VAR v2, (AI.Mod, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.MODR (VM.N, h1, i1, h0), [v2])
        | (IMM i1, VAR v2, (AI.Mod, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.MODR (VM.FS, h1, i1, h0), [v2])
        | (IMM i1, VAR v2, (AI.Mod, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.MODR (VM.F, h1, i1, h0), [v2])
        (* Quot *)
        | (VAR v1, VAR v2, (AI.Quot, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.QUOT (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Quot, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.QUOT (VM.N, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Quot, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.QUOT (VM.FS, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Quot, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.QUOT (VM.F, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.Quot, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.QUOTI (VM.W, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Quot, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.QUOTI (VM.N, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Quot, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.QUOTI (VM.FS, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Quot, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.QUOTI (VM.F, h1, h0, i2), [v1])
        | (IMM i1, VAR v2, (AI.Quot, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.QUOTR (VM.W, h1, i1, h0), [v2])
        | (IMM i1, VAR v2, (AI.Quot, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.QUOTR (VM.N, h1, i1, h0), [v2])
        | (IMM i1, VAR v2, (AI.Quot, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.QUOTR (VM.FS, h1, i1, h0), [v2])
        | (IMM i1, VAR v2, (AI.Quot, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.QUOTR (VM.F, h1, i1, h0), [v2])
        (* Rem *)
        | (VAR v1, VAR v2, (AI.Rem, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.REM (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Rem, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.REM (VM.N, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Rem, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.REM (VM.FS, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Rem, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.REM (VM.F, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.Rem, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.REMI (VM.W, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Rem, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.REMI (VM.N, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Rem, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.REMI (VM.FS, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Rem, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.REMI (VM.F, h1, h0, i2), [v1])
        | (IMM i1, VAR v2, (AI.Rem, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.REMR (VM.W, h1, i1, h0), [v2])
        | (IMM i1, VAR v2, (AI.Rem, AI.SINT, AI.SINT, AI.SINT)) =>
          emit (VM.REMR (VM.N, h1, i1, h0), [v2])
        | (IMM i1, VAR v2, (AI.Rem, AI.FLOAT, AI.FLOAT, AI.FLOAT)) =>
          emit (VM.REMR (VM.FS, h1, i1, h0), [v2])
        | (IMM i1, VAR v2, (AI.Rem, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE)) =>
          emit (VM.REMR (VM.F, h1, i1, h0), [v2])
        (* Gt *)
        | (VAR v1, VAR v2, (AI.Gt, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.CPGT (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Gt, AI.SINT, AI.SINT, AI.UINT)) =>
          emit (VM.CPGT (VM.N, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Gt, AI.FLOAT, AI.FLOAT, AI.UINT)) =>
          emit (VM.CPGT (VM.FS, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Gt, AI.DOUBLE, AI.DOUBLE, AI.UINT)) =>
          emit (VM.CPGT (VM.F, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.Gt, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.CPIGT (VM.W, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Gt, AI.SINT, AI.SINT, AI.UINT)) =>
          emit (VM.CPIGT (VM.N, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Gt, AI.FLOAT, AI.FLOAT, AI.UINT)) =>
          emit (VM.CPIGT (VM.FS, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Gt, AI.DOUBLE, AI.DOUBLE, AI.UINT)) =>
          emit (VM.CPIGT (VM.F, h1, h0, i2), [v1])
        | (IMM i1, VAR v2, (AI.Gt, t1, t2, t3)) =>
          selectOp2 context (AI.Lt, t2, t1, t3) dst arg2 arg1 loc
        (* Lt *)
        | (VAR v1, IMM i2, (AI.Lt, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.CPILT (VM.W, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Lt, AI.SINT, AI.SINT, AI.UINT)) =>
          emit (VM.CPILT (VM.N, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Lt, AI.FLOAT, AI.FLOAT, AI.UINT)) =>
          emit (VM.CPILT (VM.FS, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Lt, AI.DOUBLE, AI.DOUBLE, AI.UINT)) =>
          emit (VM.CPILT (VM.F, h1, h0, i2), [v1])
        | (_, _, (AI.Lt, t1, t2, t3)) =>
          selectOp2 context (AI.Gt, t2, t1, t3) dst arg2 arg1 loc
        (* Gteq *)
        | (VAR v1, VAR v2, (AI.Gteq, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.CPGE (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Gteq, AI.SINT, AI.SINT, AI.UINT)) =>
          emit (VM.CPGE (VM.N, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Gteq, AI.FLOAT, AI.FLOAT, AI.UINT)) =>
          emit (VM.CPGE (VM.FS, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.Gteq, AI.DOUBLE, AI.DOUBLE, AI.UINT)) =>
          emit (VM.CPGE (VM.F, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.Gteq, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.CPIGE (VM.W, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Gteq, AI.SINT, AI.SINT, AI.UINT)) =>
          emit (VM.CPIGE (VM.N, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Gteq, AI.FLOAT, AI.FLOAT, AI.UINT)) =>
          emit (VM.CPIGE (VM.FS, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Gteq, AI.DOUBLE, AI.DOUBLE, AI.UINT)) =>
          emit (VM.CPIGE (VM.F, h1, h0, i2), [v1])
        | (IMM i1, VAR v2, (AI.Gteq, t1, t2, t3)) =>
          selectOp2 context (AI.Lteq, t2, t1, t3) dst arg2 arg1 loc
        (* Lteq *)
        | (VAR v1, IMM i2, (AI.Lteq, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.CPILE (VM.W, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Lteq, AI.SINT, AI.SINT, AI.UINT)) =>
          emit (VM.CPILE (VM.N, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Lteq, AI.FLOAT, AI.FLOAT, AI.UINT)) =>
          emit (VM.CPILE (VM.FS, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.Lteq, AI.DOUBLE, AI.DOUBLE, AI.UINT)) =>
          emit (VM.CPILE (VM.F, h1, h0, i2), [v1])
        | (_, _, (AI.Lteq, t1, t2, t3)) =>
          selectOp2 context (AI.Gteq, t2, t1, t3) dst arg2 arg1 loc
        (* Andb *)
        | (VAR v1, VAR v2, (AI.Andb, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.AND (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.Andb, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.ANDI (VM.W, h1, h0, i2), [v1])
        | (IMM _,  VAR _,  (AI.Andb, t1, t2, t3)) =>
          selectOp2 context (AI.Andb, t2, t1, t3) dst arg2 arg1 loc
        (* Orb *)
        | (VAR v1, VAR v2, (AI.Orb, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.OR (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.Orb, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.ORI (VM.W, h1, h0, i2), [v1])
        | (IMM _,  VAR _,  (AI.Orb, t1, t2, t3)) =>
          selectOp2 context (AI.Orb, t2, t1, t3) dst arg2 arg1 loc
        (* Xorb *)
        | (VAR v1, VAR v2, (AI.Xorb, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.XOR (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.Xorb, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.XORI (VM.W, h1, h0, i2), [v1])
        | (IMM _,  VAR _,  (AI.Xorb, t1, t2, t3)) =>
          selectOp2 context (AI.Xorb, t2, t1, t3) dst arg2 arg1 loc
        (* LShift *)
        | (VAR v1, VAR v2, (AI.LShift, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.SHL (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.LShift, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.SHLI (VM.W, h1, h0, immToSH i2), [v1])
        | (IMM _,  VAR _,  (AI.LShift, _, _, _)) =>
          bindAndRetry ()
        (* RShift *)
        | (VAR v1, VAR v2, (AI.RShift, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.SHR (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.RShift, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.SHRI (VM.W, h1, h0, immToSH i2), [v1])
        | (IMM _,  VAR _,  (AI.RShift, _, _, _)) =>
          bindAndRetry ()
        (* ArithRShift *)
        | (VAR v1, VAR v2, (AI.ArithRShift, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.SAR (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.ArithRShift, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.SARI (VM.W, h1, h0, immToSH i2), [v1])
        | (IMM _,  VAR _,  (AI.ArithRShift, _, _, _)) =>
          bindAndRetry ()
        (* MonoEqual *)
        | (VAR v1, VAR v2, (AI.MonoEqual, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.CPEQ (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.MonoEqual, AI.SINT, AI.SINT, AI.UINT)) =>
          emit (VM.CPEQ (VM.N, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.MonoEqual, AI.FLOAT, AI.FLOAT, AI.UINT)) =>
          emit (VM.CPEQ (VM.FS, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.MonoEqual, AI.DOUBLE, AI.DOUBLE, AI.UINT)) =>
          emit (VM.CPEQ (VM.F, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.MonoEqual,
                            AI.HEAPPOINTER, AI.HEAPPOINTER, AI.UINT)) =>
          emit (VM.CPEQ (VM.P, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.MonoEqual,
                            AI.CODEPOINTER, AI.CODEPOINTER, AI.UINT)) =>
          emit (VM.CPEQ (VM.P, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.MonoEqual, AI.CPOINTER, AI.CPOINTER, AI.UINT)) =>
          emit (VM.CPEQ (VM.P, h2, h0, h1), [v1, v2])
        | (VAR v1, VAR v2, (AI.MonoEqual, AI.EXNTAG, AI.EXNTAG, AI.UINT)) =>
          emit (VM.CPEQ (VM.W, h2, h0, h1), [v1, v2])
        | (VAR v1, IMM i2, (AI.MonoEqual, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.CPIEQ (VM.W, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.MonoEqual, AI.SINT, AI.SINT, AI.UINT)) =>
          emit (VM.CPIEQ (VM.N, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.MonoEqual, AI.FLOAT, AI.FLOAT, AI.UINT)) =>
          emit (VM.CPIEQ (VM.FS, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.MonoEqual, AI.DOUBLE, AI.DOUBLE, AI.UINT)) =>
          emit (VM.CPIEQ (VM.F, h1, h0, i2), [v1])
        | (VAR v1, IMM i2, (AI.MonoEqual, AI.EXNTAG, AI.EXNTAG, AI.UINT)) =>
          emit (VM.CPIEQ (VM.W, h1, h0, i2), [v1])
        (* NOTE: comparison with immediate pointer value is never happen. *)
        | (IMM i1, VAR v2, (AI.MonoEqual, t1, t2, t3)) =>
          selectOp2 context (AI.MonoEqual, t2, t1, t3) dst arg2 arg1 loc
        (* error *)
        | (v1, v2, (op2, ty1, ty2, ty3)) =>
          raise Control.Bug
                    ("selectOp2: " ^
                     format_value v1 ^ ", " ^
                     format_value v2 ^ ", " ^
                     Control.prettyPrint (AI.format_op2 (nil, nil) op2) ^ ", " ^
                     Control.prettyPrint (AI.format_ty ty1) ^ ", " ^
                     Control.prettyPrint (AI.format_ty ty2)
                     (*^ ", " ^ Control.prettyPrint (AI.format_ty ty3)*))
      end

  fun selectBranchOp2 context op2
                      (arg1 as (value1, vmty1, mty1))
                      (arg2 as (value2, vmty2, mty2))
                      thenLabel elseLabel
                      loc =
      let
        fun emit (insn, use) =
            (context,
             [
               M.Code {code = [insn],
                       use = use,
                       def = [],
                       clob = [],
                       kind = M.NORMAL,
                       loc = loc}
             ],
             thenLabel,
             elseLabel)

        val coercePrimTy = coercePrimTy arg1 arg2

        val h0 = VM.HOLE 0
        val h1 = VM.HOLE 1
        val (op2, ty1, ty2, ty3) = op2
        val op2 = (op2, coercePrimTy ty1, coercePrimTy ty2, coercePrimTy ty3)
      in
        case (value1, value2, op2) of
        (* Lt *)
          (VAR v1, VAR v2, (AI.Lt, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.BRCLT (VM.W, h0, h1, LabelRef thenLabel), [v1, v2])
        | (VAR v1, VAR v2, (AI.Lt, AI.SINT, AI.SINT, AI.UINT)) =>
          emit (VM.BRCLT (VM.N, h0, h1, LabelRef thenLabel), [v1, v2])
        | (VAR v1, VAR v2, (AI.Lt, AI.FLOAT, AI.FLOAT, AI.UINT)) =>
          emit (VM.BRCLT (VM.FS, h0, h1, LabelRef thenLabel), [v1, v2])
        | (VAR v1, VAR v2, (AI.Lt, AI.DOUBLE, AI.DOUBLE, AI.UINT)) =>
          emit (VM.BRCLT (VM.F, h0, h1, LabelRef thenLabel), [v1, v2])
        | (VAR v1, IMM i2, (AI.Lt, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.BRCILT (VM.W, h0, i2, LabelRef thenLabel), [v1])
        | (VAR v1, IMM i2, (AI.Lt, AI.SINT, AI.SINT, AI.UINT)) =>
          emit (VM.BRCILT (VM.N, h0, i2, LabelRef thenLabel), [v1])
        | (VAR v1, IMM i2, (AI.Lt, AI.FLOAT, AI.FLOAT, AI.UINT)) =>
          emit (VM.BRCILT (VM.FS, h0, i2, LabelRef thenLabel), [v1])
        | (VAR v1, IMM i2, (AI.Lt, AI.DOUBLE, AI.DOUBLE, AI.UINT)) =>
          emit (VM.BRCILT (VM.F, h0, i2, LabelRef thenLabel), [v1])
        | (IMM i1, VAR v2, (AI.Lt, t1, t2, t3)) =>
          selectBranchOp2 context (AI.Gteq, t1, t2, t3)
                          arg1 arg2 elseLabel thenLabel loc
        (* Gt *)
        | (_, _, (AI.Lt, t1, t2, t3)) =>
          selectBranchOp2 context (AI.Lt, t2, t1, t3)
                          arg2 arg1 thenLabel elseLabel loc
        (* Lteq *)
        | (VAR v1, VAR v2, (AI.Lteq, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.BRCLE (VM.W, h0, h1, LabelRef thenLabel), [v1, v2])
        | (VAR v1, VAR v2, (AI.Lteq, AI.SINT, AI.SINT, AI.UINT)) =>
          emit (VM.BRCLE (VM.N, h0, h1, LabelRef thenLabel), [v1, v2])
        | (VAR v1, VAR v2, (AI.Lteq, AI.FLOAT, AI.FLOAT, AI.UINT)) =>
          emit (VM.BRCLE (VM.FS, h0, h1, LabelRef thenLabel), [v1, v2])
        | (VAR v1, VAR v2, (AI.Lteq, AI.DOUBLE, AI.DOUBLE, AI.UINT)) =>
          emit (VM.BRCLE (VM.F, h0, h1, LabelRef thenLabel), [v1, v2])
        | (VAR v1, IMM i2, (AI.Lteq, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.BRCILE (VM.W, h0, i2, LabelRef thenLabel), [v1])
        | (VAR v1, IMM i2, (AI.Lteq, AI.SINT, AI.SINT, AI.UINT)) =>
          emit (VM.BRCILE (VM.N, h0, i2, LabelRef thenLabel), [v1])
        | (VAR v1, IMM i2, (AI.Lteq, AI.FLOAT, AI.FLOAT, AI.UINT)) =>
          emit (VM.BRCILE (VM.FS, h0, i2, LabelRef thenLabel), [v1])
        | (VAR v1, IMM i2, (AI.Lteq, AI.DOUBLE, AI.DOUBLE, AI.UINT)) =>
          emit (VM.BRCILE (VM.F, h0, i2, LabelRef thenLabel), [v1])
        | (IMM i1, VAR v2, (AI.Lteq, t1, t2, t3)) =>
          selectBranchOp2 context (AI.Gt, t1, t2, t3)
                          arg1 arg2 elseLabel thenLabel loc
        (* Gteq *)
        | (_, _, (AI.Lteq, t1, t2, t3)) =>
          selectBranchOp2 context (AI.Lteq, t2, t1, t3)
                          arg2 arg1 thenLabel elseLabel loc
        (* MonoEqual *)
        | (VAR v1, VAR v2, (AI.MonoEqual, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.BRCEQ (VM.W, h0, h1, LabelRef thenLabel), [v1, v2])
        | (VAR v1, VAR v2, (AI.MonoEqual, AI.SINT, AI.SINT, AI.UINT)) =>
          emit (VM.BRCEQ (VM.N, h0, h1, LabelRef thenLabel), [v1, v2])
        | (VAR v1, VAR v2, (AI.MonoEqual, AI.FLOAT, AI.FLOAT, AI.UINT)) =>
          emit (VM.BRCEQ (VM.FS, h0, h1, LabelRef thenLabel), [v1, v2])
        | (VAR v1, VAR v2, (AI.MonoEqual, AI.DOUBLE, AI.DOUBLE, AI.UINT)) =>
          emit (VM.BRCEQ (VM.F, h0, h1, LabelRef thenLabel), [v1, v2])
        | (VAR v1, VAR v2, (AI.MonoEqual,
                            AI.HEAPPOINTER, AI.HEAPPOINTER, AI.UINT)) =>
          emit (VM.BRCEQ (VM.P, h0, h1, LabelRef thenLabel), [v1, v2])
        | (VAR v1, VAR v2, (AI.MonoEqual,
                            AI.CODEPOINTER, AI.CODEPOINTER, AI.UINT)) =>
          emit (VM.BRCEQ (VM.P, h0, h1, LabelRef thenLabel), [v1, v2])
        | (VAR v1, VAR v2, (AI.MonoEqual, AI.CPOINTER, AI.CPOINTER, AI.UINT)) =>
          emit (VM.BRCEQ (VM.P, h0, h1, LabelRef thenLabel), [v1, v2])
        | (VAR v1, IMM i2, (AI.MonoEqual, AI.UINT, AI.UINT, AI.UINT)) =>
          emit (VM.BRCIEQ (VM.W, h0, i2, LabelRef thenLabel), [v1])
        | (VAR v1, IMM i2, (AI.MonoEqual, AI.SINT, AI.SINT, AI.UINT)) =>
          emit (VM.BRCIEQ (VM.N, h0, i2, LabelRef thenLabel), [v1])
        | (VAR v1, IMM i2, (AI.MonoEqual, AI.FLOAT, AI.FLOAT, AI.UINT)) =>
          emit (VM.BRCIEQ (VM.FS, h0, i2, LabelRef thenLabel), [v1])
        | (VAR v1, IMM i2, (AI.MonoEqual, AI.DOUBLE, AI.DOUBLE, AI.UINT)) =>
          emit (VM.BRCIEQ (VM.F, h0, i2, LabelRef thenLabel), [v1])
        (* NOTE: comparison with immediate pointer value is never happen. *)
        | (IMM i1, VAR v2, (AI.MonoEqual, t1, t2, t3)) =>
          selectBranchOp2 context (AI.MonoEqual, t2, t1, t3)
                          arg2 arg1 thenLabel elseLabel loc
        (* otherwise *)
        | (v1, v2, op2) =>
          let
            val vmty1 = TY VM.W
            val mty1 = M.VAR unboxedSingleClass
            val var = newVar mty1

            val (context, code1) =
                selectOp2 context op2 (var, vmty1) arg1 arg2 loc
            val (context, code2, jumpLabel, continueLabel) =
                selectBranchOp2 context
                                (AI.MonoEqual, AI.UINT, AI.UINT, AI.UINT)
                                (VAR var, vmty1, mty1)
                                (IMM (VM.CONST_W 0w0), vmty1, mty1)
                                elseLabel thenLabel
                                loc
          in
            (context, code1 @ code2, jumpLabel, continueLabel)
          end
      end

  datatype offset =
      DISPLACEMENT of VM.ssz
    | INDEXED of M.varInfo * VM.sc

  fun transformOffset offset =
      (* FIXME: use scale *)
      case offset of
        IMM (VM.CONST_N x) => DISPLACEMENT x
      | IMM (VM.CONST_W x) => DISPLACEMENT (WtoSSZ x)
      | IMM _ => raise Control.Bug "transformOffset: IMM"
      | VAR var => INDEXED (var, 0w1)
      | LABEL _ => raise Control.Bug "transformOffset: LABEL"

























  datatype nativeTy =
      B   (* byte : 8 bit *)
    | W   (* word : 16 bit *)
    | L   (* double word : 32 bit *)
    | P   (* pointer : 32 bit *)
    | SS  (* scalar single-precision floating-point : 32 bit *)
    | SD  (* scalar double-precision floating-point : 64 bit *)
    | F   (* extended double-precision floating-point : 80 bit *)
    | UNBOXED_W  (* generic unboxed slot : 16 bit *)
    | UNBOXED_L  (* generic unboxed slot : 32 bit *)
    | UNBOXED_D  (* generic unboxed slot : 64 bit *)
    | UNBOXED_G  (* generic unboxed slot : 128 bit *)
    | GENERIC    (* generic slot : 128 bit *)

  fun max (GENERIC, _) = GENERIC
    | max (_, GENERIC) = GENERIC
    | max (UNBOXED_G, P) = GENERIC
    | max (P, UNBOXED_G) = GENERIC
    | max (UNBOXED_G, _) = UNBOXED_G
    | max (_, UNBOXED_G) = GENERIC
    | max (UNBOXED_D, P) = GENERIC
    | max (P, UNBOXED_D) = GENERIC
    | max (UNBOXED_D, F) = UNBOXED_G
    | max (F, UNBOXED_D) = UNBOXED_G
    | max (UNBOXED_

    | max (UNBOXED_D, _)





  datatype vmty =
      TY of VM.ty
    | SIZE of VM.sz






























  val eax = 0wx1
  val ebx = 0wx2
  val ecx = 0wx3
  val edx = 0wx4
  val esi = 0wx5
  val edi = 0wx6
  val ebp = 0wx7
  val xmm0 = 0wx10
  val xmm1 = 0wx11
  val xmm2 = 0wx12
  val xmm3 = 0wx13
  val xmm4 = 0wx14
  val xmm5 = 0wx15
  val xmm6 = 0wx16
  val xmm7 = 0wx17
  val xmm8 = 0wx18

  val allRegisters =
      [eax, ebx, ecx, edx, esi, edi, ebp,
       xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, xmm7, xmm8]

  val boxedRegisterClass =
      {
        tag = M.BOXED,
        size = 0w4,
        align = 0w4,
        registers = [eax, ebx, ecx, edx, esi, edi, ebp],
        interference = WEnv.empty
      }

  val unboxedLongRegisterClass =
      {
        tag = M.UNBOXED,
        size = 0w4,
        align = 0w4,
        registers = [eax, ebx, ecx, edx, esi, edi, ebp],
        interference = WEnv.empty
      }

  val unboxedSingleFloatRegisterClass =
      {
        tag = M.UNBOXED,
        size = 0w4,
        align = 0w4,
        registers = [xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, xmm7, xmm8],
        interference = WEnv.empty
      }

  val unboxedDoubleFloatRegisterClass =
      {
        tag = M.UNBOXED,
        size = 0w8,
        align = 0w8,
        registers = [xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, xmm7, xmm8],
        interference = WEnv.empty
      }

  fun genericRegisterClass tag size =
      {
        tag = tag,
        size = size,
        align = size,
        registers = nil,
        interference = WEnv.empty
      } : M.registerClassDesc

  val initialRegisterDesc =
      {
        classes =
          [
            boxedClassDesc,          (* 0 *)
            unboxedLongClassDesc,    (* 1 *)
            unboxedFloatClassDesc,   (* 2 *)
            (* followed by generic classes ... *)
          ],
          boxedClass = 0,
          bitmapClass = 1
      } : M.registerDesc

  val boxedClass = 0
  val unboxedLongClass = 1
  val unboxedFloatClass = 2

  val pointerClass = unboxedLongClass
  val pointerClassDesc = unboxedLongClassDesc

  fun addRegisterClass (desc as {classes, ...}:M.registerDesc) regclass =
      ({
         classes = classes @ [regclass],
         boxedClass = #boxedClass desc,
         bitmapClass = #bitmapClass desc
       } : M.registerDesc,
       length classes)

  fun getRegisterClass (context as {registerDesc, ...}:context) tag size =
      let
        (* FIXME: currently all generic class must have same size. *)
        val size = genericSize

        fun find n (({tag=tag2, size=size2, ...}:M.registerClassDesc)::t) =
            if tag = tag2 andalso size = size2
            then (context, n)
            else find (n + 1) t
          | find n nil =
            let
              val (registerDesc, classId) =
                  addRegisterClass registerDesc (genericClassDesc tag size)
            in
              ({
                 registerDesc = registerDesc,
                 tagArgMap = #tagArgMap context,
                 calleeSaveVars = #calleeSaveVars context,
                 savedUnwindVar = #savedUnwindVar context,
                 savedLinkVar = #savedLinkVar context,
                 savedEnvVar = #savedEnvVar context,
                 handlerVar = #handlerVar context,
                 exnVar = #exnVar context,
                 constants = #constants context,
                 currentHandler = #currentHandler context,
                 continue = #continue context,
                 jump = #jump context
               } : context,
               classId)
            end
      in
        find 0 (#classes registerDesc)
      end















  datatype size =
           BYTE          (*   8 bit *)
         | WORD          (*  16 bit *)
         | LONG          (*  32 bit *)
         | DOUBLE        (*  64 bit *)
         | LONGDOUBLE    (*  80 bit *)
         | GENERAL       (* 128 bit *)

  fun max (GENERAL, _) = GENERAL
    | max (_, GENERAL) = GENERAL
    | max (LONGDOUBLE, _) = LONGDOUBLE
    | max (_, LONGDOUBLE) = LONGDOUBLE
    | max (DOUBLE, _) = DOUBLE
    | max (_, DOUBLE) = DOUBLE
    | max (LONG, _) = LONG
    | max (_, LONG) = LONG
    | max (WORD, _) = WORD
    | max (_, WORD) = WORD
    | max (BYTE, _) = BYTE
    | max (_, BYTE) = BYTE

  fun transformTy context ty =
      case ty of
        AI.UINT => (context, unboxedLongClass)
      | AI.SINT => (context, unboxedLongClass)
      | AI.BYTE => (context, unboxedLongClass)
      | AI.CHAR => (context, unboxedLongClass)
      | AI.BOXED => (context, boxedClass)
      | AI.HEAPPOINTER => (context, unboxedLongClass)
      | AI.CODEPOINTER => (context, unboxedLongClass)
      | AI.CPOINTER => (context, unboxedLongClass)
      | AI.ENTRY => (context, unboxedLongClass)
      | AI.FLOAT => (context, unboxedSingleFloatClass)
      | AI.DOUBLE => (context, unboxedDoubleFloatClass)
      | AI.INDEX => (context, unboxedLongClass)
      | AI.BITMAP => (context, unboxedLongClass)
      | AI.OFFSET => (context, unboxedLongClass)
      | AI.SIZE => (context, unboxedLongClass)
      | AI.TAG => (context, unboxedLongClass)
      | AI.EXNTAG => (context, unboxedLongClass)
      | AI.ATOMty => (context, unboxedLongClass)
      | AI.DOUBLEty => (context, unboxedDoubleFloatClass)
      | AI.UNION {tag, variants} =>
        let
          val tag =
              case tag of
                AI.Boxed => M.BOXED
              | AI.Unboxed => M.UNBOXED
              | AI.IndirectTag {offset, bit} =>
                M.FREEGENERIC {entity = envReg,
                               offset = Target.UIntToWord offset,
                               bit = bit}
              | AI.ParamTag {id, ...} =>
                case LocalVarID.Map.find (#tagArgMap context, id) of
                  SOME tag => tag
                | NONE => raise Control.Bug ("transformTy: ParamTag: "^
                                             LocalVarID.toString id)

          val size = foldl (fn (x,z) => max (#1 (transformTy x), z))
                     BYTE variants

          val (context, class) = getRegisterClass context tag size
        in
          (context, size, tag)
        end

  fun transformVarInfo context ({id, displayName, ty}:AI.varInfo) =
      let
        val (context, class) = transformTy context ty

        (* boxed value must be allocated to stack frame so that
         * GC can find it. *)
        (* FIXME: more efficient way *)
        val mty = if class = boxedClass then M.STK class else M.VAR class

        val newVarInfo =
            {
              id = id,
              displayName = displayName,
              ty = mty
            } : M.varInfo
      in
        (context, newVarInfo)
      end















  fun selectInsn context insn =
      case insn of
        AI.Move {dst, ty, value, loc, size} =>
        let
          val dst = transformVar dst
          val src =


        I.MOVL (


        let
          MOV (M.W,

        let
          [
            M.Code {code = [M.MOV (M.W,



  fun makeMove dst value vmty loc =
      let
        val (use, kind, insn) =
            case (value, vmty) of
              (IMM imm, TY ty) =>
              ([], M.NORMAL, VM.MVI (ty, VM.HOLE 0, imm))
            | (IMM imm, SIZE _) => raise Control.Bug "makeMove: IMM SIZE"
            | (VAR var, TY ty) =>
              ([var], M.MOVE, VM.MOV (ty, VM.HOLE 1, VM.HOLE 0))
            | (VAR var, SIZE n) =>
              ([var], M.MOVE, VM.MOVX (n, VM.HOLE 1, VM.HOLE 0))
            | (LABEL l, TY VM.P) =>
              ([], M.NORMAL, VM.MVFIP (VM.HOLE 0, l))
            | (LABEL l, _) => raise Control.Bug "makeMove: LABEL not P"
      in
        [
          M.Code {code = [insn],
                  use = use,
                  def = [dst],
                  clob = [],
                  kind = kind,
                  loc = loc}
        ]
      end



        [
         M.Code {code = [ M.MOV ],
                 use = value,
                 def = [dst],


                 use = use,
                 def = [dst],
                 clob = [],
                 kind = kind,
                 loc = loc}



        let
          val (context, dst, _) = transformVarInfo context dst
          val (context, value, vmty, _) = transformValue context value
        in
          (context, makeMove dst value vmty loc)
        end






















    fun transformConst context imm aity =
        let
          val (context, vmty, class) = transformTy context aity
        in
          (context, imm, vmty, M.VAR class)
        end

  fun transformValue context value =
      case value of
        AI.UInt n => (context, X.CONST_W n)
      | AI.SInt n => (context, X.CONST_W (compliment n))
      | AI.Real n => (context, X.CONST_
      | AI.Float n => transformConst context (IMM (VM.CONST_FS n)) AI.FLOAT
      | AI.Var v => transformVar context v
      | AI.Param v => transformVar context v
      | AI.Exn v => transformVar context v
      | AI.Env =>
        (context, VAR (#savedEnvVar context), TY VM.P, M.VAR boxedClass)
      | AI.Null =>
        (context, IMM (VM.EXTERN NullLabel), TY VM.P, M.VAR pointerClass)
      | AI.Nowhere =>
        (context, IMM (VM.EXTERN NowhereLabel), TY VM.P, M.VAR pointerClass)
      | AI.Empty =>
        (context, IMM (VM.EXTERN EmptyLabel), TY VM.P, M.VAR boxedClass)
      | AI.Entry {clusterId, entry} =>
        (context, LABEL (LabelRef entry), TY VM.P, M.VAR pointerClass)
      | AI.Label label =>
        (context, LABEL (LabelRef label), TY VM.P, M.VAR pointerClass)
      | AI.Init constId =>
        (context, IMM (VM.EXTERN (ConstRef constId)),
         TY VM.P, M.VAR pointerClass)
      | AI.Const constId =>
        (context, IMM (VM.EXTERN (ConstRef constId)), TY VM.P, M.VAR boxedClass)
      | (* FIXME: separate compilation *)
        AI.Extern {label = {label, value=SOME (AI.GLOBAL_TAG t), ...}, ...} =>
        transformConst context (IMM (VM.CONST_W t)) AI.UINT
      | AI.Global {label = {label, ...}, ty} =>
        let
          val (context, vmty, class) = transformTy context ty
        in
          (context, IMM (VM.EXTERN (VM.INTERNALREF label)), vmty, M.VAR class)
        end
      | AI.Extern {label = {label, ...}, ty} =>
        let
          val (context, vmty, class) = transformTy context ty
        in
          (context, IMM (VM.EXTERN (VM.GLOBALREF label)), vmty, M.VAR class)
        end


  case value of
      UInt targetUInt1 =>
    | SInt targetSInt1 =>
    | Real tring1 =>
    | Float tring1 =>
    | Var varInfo1 =>
    | Param paramInfo1 =>
    | Exn paramInfo1 =>
    | Env =>
    | Empty =>
    | Nowhere =>
    | Null =>
    | Const id1 =>
    | Init id1 =>
    | Entry {clusterId, entry} =>
    | Label label1 =>
    | Global {ty, label} =>
    | Extern {ty, label} =>











  fun makeMove dst value vmty loc =
      let
        val (use, kind, insn) =
            case (value, vmty) of
              (IMM imm, TY ty) =>
              ([], M.NORMAL, VM.MVI (ty, VM.HOLE 0, imm))
            | (IMM imm, SIZE _) => raise Control.Bug "makeMove: IMM SIZE"
            | (VAR var, TY ty) =>
              ([var], M.MOVE, VM.MOV (ty, VM.HOLE 1, VM.HOLE 0))
            | (VAR var, SIZE n) =>
              ([var], M.MOVE, VM.MOVX (n, VM.HOLE 1, VM.HOLE 0))
            | (LABEL l, TY VM.P) =>
              ([], M.NORMAL, VM.MVFIP (VM.HOLE 0, l))
            | (LABEL l, _) => raise Control.Bug "makeMove: LABEL not P"
      in
        [
          M.Code {code = [insn],
                  use = use,
                  def = [dst],
                  clob = [],
                  kind = kind,
                  loc = loc}
        ]
      end

























  val nullValue = 0

  datatype rmi =
      VAR of I.varInfo
    | IMM of I.imm

  fun transformValue context value =
      case value of
        AI.UInt n => IMM (I.INT n)  (* BYTE WORD LONG *)
      | AI.SInt n => IMM (I.INT n)  (* BYTE WORD LONG *)
      (* LONG *)
      | AI.Empty => IMM (I.INT nullValue)
      | AI.Nowhere => IMM (I.INT nullValue)
      | AI.Null => IMM (I.INT nullValue)
      | AI.Const id => IMM (I.LABEL ("C" ^ ID.toString id))
      | AI.Init id => IMM (I.LABEL ("C" ^ ID.toString id))
      | AI.Entry {clusterId, entry} => IMM (I.LABEL ("F" ^ ID.toString entry))
      | AI.Label l => IMM (I.LABEL ("L" ^ ID.toString l))
      | AI.Global {ty, label={label,...}} => IMM (I.LABEL ("G" ^ label))
      | AI.Extern {ty, label={label,...}} => IMM (I.LABEL ("G" ^ label))
      (* any type *)
      | AI.Var var => VAR (transformVarInfo context var)

  fun toRM8 (IMM x) = I.I_8 x
    | toRM8 (VAR v) = I.V_8 v


  64bit operation -> 32bit operation




  var = var' : Real



  fldl var
  fldl (mem)
  faddl
  fstlp var
  fldl var









  type context =
       {
         genericTys: AI.genericTyRep IEnv.map
       }

  datatype ty =
           BYTE       (* 8 bit *)
         | WORD       (* 16 bit *)
         | LONG       (* 32 bit *)
         | QUAD       (* 64 bit *)
         | DQUAD      (* 128 bit *)
         | FLOAT      (* 32 bit float *)
         | DOUBLE     (* 64 bit float *)
         | TRIPLE     (* 80 bit float *)

  fun transformTy context ty =
      case ty of
        AI.UINT => LONG
      | AI.SINT => LONG
      | AI.BYTE => BYTE
      | AI.CHAR => BYTE
      | AI.BOXED => LONG
      | AI.HEAPPOINTER => LONG
      | AI.CODEPOINTER => LONG
      | AI.CPOINTER => LONG
      | AI.ENTRY => LONG
      | AI.FLOAT => FLOAT
      | AI.DOUBLE => DOUBLE
      | AI.INDEX => LONG
      | AI.BITMAP => LONG
      | AI.OFFSET => LONG
      | AI.SIZE => LONG
      | AI.TAG => LONG
      | AI.EXNTAG => LONG
      | AI.ATOMty => LONG
      | AI.DOUBLEty => DOUBLE
      | GENERIC tid =>
        case IEnv.find (#genericTys context, tid) of
          SOME {size = 0w1, ...} => BYTE
          SOME {size = 0w2, ...} => WORD
          SOME {size = 0w4, ...} => LONG
          SOME {size = 0w8, ...} => QUAD
          SOME {size = 0w16, align = 0w16, ...} => DQUAD
        | SOME _ => raise Control.Bug "transformTy"
        | NONE => raise Control.Bug "transformTy"

































  fun classOf context ty =
      case ty of
        AI.UINT => longClass
      | AI.SINT => longClass
      | AI.BYTE => longClass
      | AI.CHAR => longClass
      | AI.BOXED => longClass
      | AI.HEAPPOINTER => longClass
      | AI.CODEPOINTER => longClass
      | AI.CPOINTER => longClass
      | AI.ENTRY => longClass
      | AI.FLOAT => floatClass
      | AI.DOUBLE => doubleClass
      | AI.INDEX => longClass
      | AI.BITMAP => longClass
      | AI.OFFSET => longClass
      | AI.SIZE => longClass
      | AI.TAG => longClass
      | AI.EXNTAG => longClass
      | AI.ATOMty => longClass
      | AI.DOUBLEty => doubleClass
      | GENERIC tid =>
        case IEnv.find (#genericTys context, tid) of
          SOME {size = 0w1, ...} => longClass
          SOME {size = 0w2, ...} => longClass
          SOME {size = 0w4, ...} => longClass
          SOME {size = 0w8, ...} => quadClass
          SOME {size = 0w16, align = 0w16, ...} => dquadClass
        | _ => raise Control.Bug "classOf"

*)




































































































































































(*
  val PIC = ref true
  val NonLazyPtr = ref true
*)
  val MMX = ref true
  val SSE = ref true

  val nullValue = I.INT 0
  val currentHandlerListLabel = "sml_currentHandlerList"




  (* struct sml_exn_handler {
   *   struct sml_exn_handler *next;
   *   handler_code *handler_addr;
   *   void *save_esp, *save_ebp;
   * }; *)
  (* __regparm(1) void sml_push_handler(struct sml_exn_handler *handler); *)
  val smlPushHandlerFunLabel = "sml_push_handler"
  (* __regparm(1) struct sml_exn_handler *sml_pop_handler(void); *)
  val smlPopHandlerFunLabel = "sml_pop_handler"

  (* __regparm(1) void sml_save_frame_pointer(void *ebp); *)
  val smlSaveFramePointerFunLabel = "sml_save_frame_pointer"
  (* __regparm(1) void *sml_load_frame_pointer(void); *)
  val smlLoadFramePointerFunLabel = "sml_load_frame_pointer"

(*
  type toplevelContext =
      {
        globalOffsetRoutine: I.instruction list ref
      }
*)

  datatype ossys =
      Darwin
    | Linux
    | Others

  type context =
      {
        calleeSaveRegs: I.varInfo list,
        options: {ossys: ossys, PIC: bool},
        globalOffsetBase: {offsetBaseLabel: I.label,
                           offsetBaseVar: I.varInfo} option ref
      }

  fun formatOf ty =
      case ty of
        AI.GENERIC tid => {tag = F.GENERIC tid, size = 0w8, align = 0w8}
      | AI.UINT => {tag = F.UNBOXED, size = 0w4, align = 0w4}
      | AI.SINT => {tag = F.UNBOXED, size = 0w4, align = 0w4}
      | AI.BYTE => {tag = F.UNBOXED, size = 0w1, align = 0w1}
      | AI.BOXED => {tag = F.BOXED, size = 0w4, align = 0w4}
      | AI.HEAPPOINTER => {tag = F.UNBOXED, size = 0w4, align = 0w4}
      | AI.CODEPOINTER => {tag = F.UNBOXED, size = 0w4, align = 0w4}
      | AI.CPOINTER => {tag = F.UNBOXED, size = 0w4, align = 0w4}
      | AI.ENTRY => {tag = F.UNBOXED, size = 0w4, align = 0w4}
      | AI.FLOAT => {tag = F.UNBOXED, size = 0w4, align = 0w4}
      | AI.DOUBLE => {tag = F.UNBOXED, size = 0w8, align = 0w8}
      | AI.INDEX => {tag = F.UNBOXED, size = 0w4, align = 0w4}
      | AI.BITMAP => {tag = F.UNBOXED, size = 0w4, align = 0w4}
      | AI.OFFSET => {tag = F.UNBOXED, size = 0w4, align = 0w4}
      | AI.SIZE => {tag = F.UNBOXED, size = 0w4, align = 0w4}
      | AI.TAG => {tag = F.UNBOXED, size = 0w4, align = 0w4}
      | AI.ATOMty => {tag = F.UNBOXED, size = 0w4, align = 0w4}
      | AI.DOUBLEty => {tag = F.UNBOXED, size = 0w8, align = 0w8}







(*
  fun fixedSizeOf ty =
      case ty of
        AI.UINT => 4
      | AI.SINT => 4
      | AI.BYTE => 1
      | AI.CHAR => 1
      | AI.BOXED => 4
      | AI.HEAPPOINTER => 4
      | AI.CODEPOINTER => 4
      | AI.CPOINTER => 4
      | AI.ENTRY => 4
      | AI.FLOAT => 4
      | AI.DOUBLE => 8
      | AI.INDEX => 4
      | AI.BITMAP => 4
      | AI.OFFSET => 4
      | AI.SIZE => 4
      | AI.TAG => 4
      | AI.EXNTAG => 4
      | AI.ATOMty => 4
      | AI.DOUBLEty => 8
      | AI.GENERIC _ => raise Control.Bug "fixedSizeOf"

  fun sizeOf (context:context) ty =
      case ty of
        AI.GENERIC tid =>
        (case IEnv.find (#genericTys context, tid) of
           SOME {size = size, ...} => Word.toInt size
         | NONE => raise Control.Bug "sizeOf")
      | _ => fixedSizeOf ty

  fun alignOf (context:context) ty =
      case ty of
        AI.UINT => 0w4
      | AI.SINT => 0w4
      | AI.BYTE => 0w1
      | AI.CHAR => 0w1
      | AI.BOXED => 0w4
      | AI.HEAPPOINTER => 0w4
      | AI.CODEPOINTER => 0w4
      | AI.CPOINTER => 0w4
      | AI.ENTRY => 0w4
      | AI.FLOAT => 0w4
      | AI.DOUBLE => 0w8
      | AI.INDEX => 0w4
      | AI.BITMAP => 0w4
      | AI.OFFSET => 0w4
      | AI.SIZE => 0w4
      | AI.TAG => 0w4
      | AI.EXNTAG => 0w4
      | AI.ATOMty => 0w4
      | AI.DOUBLEty => 0w8
      | AI.GENERIC tid =>
        case IEnv.find (#genericTys context, tid) of
          SOME {align, ...} => align
        | NONE => raise Control.Bug "sizeOf"

  fun formatOf context ty =
      let
        val size = sizeOf context ty
      case ty of
        AI.GENERIC tid => F.Generic tid
      | AI.UINT => F.Unboxed
      | AI.SINT => F.Unboxed
      | AI.BYTE => F.Unboxed
      | AI.CHAR => F.Unboxed
      | AI.BOXED => F.Boxed
      | AI.HEAPPOINTER => F.Unboxed
      | AI.CODEPOINTER => F.Unboxed
      | AI.CPOINTER => F.Unboxed
      | AI.ENTRY => F.Unboxed
      | AI.FLOAT => F.Unboxed
      | AI.DOUBLE => F.Unboxed
      | AI.INDEX => F.Unboxed
      | AI.BITMAP => F.Unboxed
      | AI.OFFSET => F.Unboxed
      | AI.SIZE => F.Unboxed
      | AI.TAG => F.Unboxed
      | AI.EXNTAG => F.Unboxed
      | AI.ATOMty => F.Unboxed
      | AI.DOUBLEty => F.Unboxed
*)

(*
  fun maybeBoxed (context:context) ty =
      case ty of
        AI.UINT => false
      | AI.SINT => false
      | AI.BYTE => false
      | AI.CHAR => false
      | AI.BOXED => true
      | AI.HEAPPOINTER => false
      | AI.CODEPOINTER => false
      | AI.CPOINTER => false
      | AI.ENTRY => false
      | AI.FLOAT => false
      | AI.DOUBLE => false
      | AI.INDEX => false
      | AI.BITMAP => false
      | AI.OFFSET => false
      | AI.SIZE => false
      | AI.TAG => false
      | AI.EXNTAG => false
      | AI.ATOMty => false
      | AI.DOUBLEty => false
      | AI.GENERIC tid =>
        case IEnv.find (#genericTys context, tid) of
          SOME {tag = AI.Unboxed, ...} => false
        | SOME _ => true
        | NONE => raise Control.Bug "isBoxed"
*)

  fun regOrImm (insn, rmi) =
      case rmi of
        I.R_ reg => (insn, rmi)
      | I.I_ imm => (insn, rmi)
      | I.M_ mem =>
        let
          val reg = newReg32 ()
        in
          (insn @ [ I.MOVL (I.R reg, rmi) ], I.R_ reg)
        end

  fun rmiToRm rmi =
      case rmi of
        I.R_ reg => (nil, I.R reg)
      | I.M_ mem => (nil, I.M mem)
      | I.I_ imm =>
        let
          val reg = newReg32 ()
        in
          ([ I.MOVL (I.R reg, rmi) ], I.R reg)
        end

  fun rmToRmi (I.R reg) = I.R_ reg
    | rmToRmi (I.M mem) = I.M_ mem

  fun transformVarInfo ({id, ty, displayName}:AI.varInfo) =
      let
        val format as {size, align, tag} = formatOf ty
        val format = if size >= 0w4 then format
                     else {size = 0w4, align = 0w4, tag = tag}
        val candidates =
            case format of
              {size = 0w4, tag = F.UNBOXED, ...} => candidate32
            | _ => nil
      in
        I.M (I.VAR {id = id, format = format, candidates = candidates})
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
   *   | | 2nd arg       |
   *   | +---------------+ post 32
   *   | | ...           |
   *   | +---------------+ post 16(m-1)
   *   | | Nth arg       |
   *   | +-=-=-=-=-=-=-=-+ post 16m        <------ %esp after call [align 16]
   *   | | 1st ret       |
   *   | +---------------+ post 16(m+1)
   *   | | 2nd ret       |
   *   | +---------------+ post 16(m+2)
   *   | | ...           |
   *   | +---------------+ post 16(m+n-1)
   *   | | Mth ret       |
   *   | +---------------+ post 16(m+n)
   *   | |               | (space for arguments)
   *   | |               |
   *   | +===============+ post 16(m+n+p)  [align 16]
   *   | | Frame         |
   *   | |               |
   *   | |               |
   *   | +---------------+
   *   | |frame header 2 |
   *   | |frame header 1 |
   *   | +===============+ pre 16(m+n+p)+8 <------ my %ebp  [align 8]
   *   | | prev ebp      |
   *   | +---------------+ pre 16(m+n+p)+4
   *   | |               | (space for arguments of tail call)
   *   | |               |
   *   | +---------------+ pre 16(m+n)+4
   *   | | return addr   |
   *   | +-=-=-=-=-=-=-=-+ pre 16(m+n)     <------ caller's %esp [align 16]
   *   | | 1st param     |
   *   | +---------------+ pre 16(m+n-1)
   *   | | 2nd param     |
   *   | +---------------+ pre 16(m+n-2)
   *   | | ...           |
   *   | +---------------+ pre 16(m+1)
   *   | | Nth param     |
   *   | +-=-=-=-=-=-=-=-+ pre 16m         <------ %esp after return [align 16]
   *   | | 1st ret       |
   *   | +---------------+ pre 16(m-1)
   *   | | 2nd ret       |
   *   | +---------------+ pre 16(m-2)
   *   | | ...           |
   *   | +---------------+ pre 16
   *   | | Mth ret       |
   *   | +---------------+ pre 0
   *   v :               :
   *
   * = cdecl
   *
   * addr
   *   | :               :
   *   | +-=-=-=-=-=-=-=-+ post 0       <-------- my %esp [align 16]
   *   | | 1st arg       |
   *   | +---------------+ post sz1
   *   | | 2nd arg       |
   *   | +---------------+ post sz1+sz2
   *   | | ...           |
   *   | +---------------+ post sz1+...+sz(N-1)
   *   | | Nth arg       |
   *   | +---------------+ post sz1+...+szN
   *   | | pad           | (space for arguments)
   *   | | (if needed)   |
   *   | +===============+ post sz1+...+szN+p  [align 16]
   *   | | Frame         |
   *   | |               |
   *   | |               |
   *   | +---------------+
   *   | |frame header 2 |
   *   | |frame header 1 |
   *   | +===============+ pre sz1+...+szN+8+p <------ my %ebp  [align 8]
   *   | | prev ebp      |
   *   | +---------------+ pre sz1+...+szN+4+p   [align 4]
   *   | | pad           | (for alignment)
   *   | | (if needed)   |     (note that tail-call is not available for C)
   *   | +---------------+ pre sz1+...+szN+4
   *   | | return addr   |
   *   | +-=-=-=-=-=-=-=-+ pre sz1+...+szN <------ caller's %esp
   *   | | 1st param     |
   *   | +---------------+ pre sz2+...+szN
   *   | | 2nd param     |
   *   | +---------------+ pre sz3+...+szN
   *   | | ...           |
   *   | +---------------+ pre szN
   *   | | Nth param     |
   *   | +---------------+ pre 0
   *   v :               :
   *)

  fun ccdeclArgs argTys =
      let
        fun mem (off, argTy::argTys) =
            let
              val size = #size (formatOf argTy)
            in
              I.POSTFRAME {offset = Word.toInt off, size = size}
              :: mem (off + size, argTys)
            end
          | mem (off, nil) = nil
      in
        mem (0w0, argTys)
      end

  fun ccdeclParams argTys =
      let
        fun mem (off, argTy::argTys) =
            let
              val (off, args) = mem (off, argTys)
              val size = #size (formatOf argTy)
            in
              (off + size,
               I.PREFRAME {offset = Word.toInt (off + size), size = size}
               :: args)
            end
          | mem (off, nil) = (off, nil)
      in
        #2 (mem (0w0, argTys))
      end

  datatype arg = IARG of I.rm32 | FARG0

  fun transformArgKind argKind =
      case argKind of
        AI.Param {index, argTys, retTys} =>
        IARG (I.M (I.PREFRAME
                       {offset = 16 * (length retTys + length argTys - index),
                        size = 0w16}))
      | AI.Result {index, argTys, retTys} =>
        IARG (I.M (I.PREFRAME {offset = 16 * (length retTys - index),
                               size = 0w16}))
      | AI.Arg {index, argTys, retTys} =>
        IARG (I.M (I.POSTFRAME {offset = 16 * index, size = 0w16}))
      | AI.Ret {index, argTys, retTys} =>
        IARG (I.M (I.POSTFRAME {offset = 16 * (length argTys + index),
                                size = 0w16}))
(*
      | AI.TailArg {index, argTys, retTys} =>
        raise Control.Bug "FIXME"
      | AI.Link {argTys, retTys} =>
        IARG (I.M (I.DISP (I.INT 4, I.BASE I.EBP)))
*)
(*
        IARG (I.M (I.PREFRAME
                       {offset = 16 * (length retTys + length argTys) + 4,
                        size = 0w4}))
*)
      | AI.Env => IARG (I.R I.EAX)
      | AI.Exn => IARG (I.R I.EAX)
      | AI.ExtArg {index, argTys, attributes} =>
        if (case #callingConvention attributes of
              SOME Absyn.FFI_CDECL => true
            | NONE => true
            | _ => false)
        then IARG (I.M (List.nth (ccdeclArgs argTys, index)))
        else raise Control.Bug "FIXME: ExtArg: not implemented convention"
      | AI.ExtRet {index=0, retTys=[ty], attributes} =>
        if (case #callingConvention attributes of
              SOME Absyn.FFI_CDECL => true
            | NONE => true
            | _ => false)
        then
          case ty of
            AI.FLOAT => FARG0
          | AI.DOUBLE => FARG0
          | AI.DOUBLEty => FARG0
          | AI.UINT => IARG (I.R I.EAX)
          | AI.SINT => IARG (I.R I.EAX)
          | AI.BYTE => IARG (I.R I.EAX)
          | AI.BOXED => IARG (I.R I.EAX)
          | AI.HEAPPOINTER => IARG (I.R I.EAX)
          | AI.CODEPOINTER => IARG (I.R I.EAX)
          | AI.CPOINTER => IARG (I.R I.EAX)
          | AI.ENTRY => IARG (I.R I.EAX)
          | AI.INDEX => IARG (I.R I.EAX)
          | AI.BITMAP => IARG (I.R I.EAX)
          | AI.OFFSET => IARG (I.R I.EAX)
          | AI.SIZE => IARG (I.R I.EAX)
          | AI.TAG => IARG (I.R I.EAX)
          | AI.ATOMty => IARG (I.R I.EAX)
          | AI.GENERIC tid => raise Control.Bug "transformArgInfo: ExtRet"
        else raise Control.Bug "FIXME: ExtRet: not implemented convention"
      | AI.ExtRet {index, retTys, attributes} =>
        raise Control.Bug "transformArgInfo: FIXME: not implemented ExtRet"
      | AI.ExtParam {index, argTys, attributes} =>
        raise Control.Bug "transformArgInfo: FIXME: not implemented ExtParam"

  fun transformArgInfo ({id, ty, argKind}:AI.argInfo) =
      transformArgKind argKind

  fun absoluteAddr (context:context) label =
      let
        val (baseLabel, baseVar) =
            case !(#globalOffsetBase context) of
              SOME {offsetBaseLabel, offsetBaseVar} =>
              (offsetBaseLabel, offsetBaseVar)
            | NONE =>
              let
                val baseLabel = newLabel ()
                val baseVar = newVar32 candidate32
              in
                #globalOffsetBase context :=
                SOME {
                       offsetBaseLabel = baseLabel,
                       offsetBaseVar = baseVar
                     };
                (baseLabel, baseVar)
              end

        val reg = newReg32 ()
      in
        ([ I.MOVL (I.R reg, I.M_ (I.VAR baseVar)) ],
         I.DISP (I.CONSTSUB (label, I.LABEL baseLabel), I.BASE reg))
      end

  fun transformLabel context label =
      if #PIC (#options context) then
        let
          val reg = newReg32 ()
          val (insn1, mem) = absoluteAddr context label
        in
          (insn1 @ [ I.LEAL (reg, mem) ], I.R_ reg)
        end
      else
        (nil, I.I_ label)

  fun transformExtVarLabel context label =
      let
        val (code, reg) = transformLabel context label
      in
        if #PIC (#options context) then
          case #ossys (#options context) of
            Darwin =>
            (case reg of
               I.R_ r =>
               let
                 val reg2 = newReg32 ()
               in
                 (code @ [ I.MOVL (I.R reg2, I.M_ (I.BASE r)) ], I.R_ reg2)
               end
             | _ => raise Control.Bug "transformExtVarLabel")
          | _ =>
            raise Control.Bug "unsupported ossys"
        else
          (code, reg)
      end

  fun transformValue context value =
      case value of
        AI.UInt n => (nil, I.I_ (I.WORD (AI.Target.UIntToUInt32 n)))
      | AI.SInt n => (nil, I.I_ (I.INT (AI.Target.SIntToSInt32 n)))
      | AI.Nowhere => (nil, I.I_ nullValue)
      | AI.Null => (nil, I.I_ nullValue)
      | AI.Const id => transformLabel context (I.LABEL (constLabel id))
      | AI.Init id => transformLabel context (I.LABEL (constLabel id))
      | AI.Entry {clusterId, entry} =>
        transformLabel context (I.LABEL (funLabel entry))
      | AI.Global label =>
        transformExtVarLabel context (I.GLOBALLABEL label)
      | AI.Extern label =>
        transformExtVarLabel context (I.EXTERNLABEL label)
      | AI.Label label => transformLabel context (I.LABEL (localLabel label))
      | AI.ExtFunLabel label => (nil, I.I_ (I.EXTERNLABEL label))
      | AI.Var var => (nil, rmToRmi (transformVarInfo var))

  fun transformValueList context (value::valueList) =
      let
        val (insn1, value) = transformValue context value
        val (insn2, values) = transformValueList context valueList
      in
        (insn1 @ insn2, value::values)
      end
    | transformValueList context nil = (nil, nil)

  fun transformJumpTo context value =
      case value of
        AI.Entry {clusterId, entry} => (nil, I.REL (I.LABEL (funLabel entry)))
      | AI.Label label => (nil, I.REL (I.LABEL (localLabel label)))
      | AI.ExtFunLabel label => (nil, I.REL (I.EXTSTUBLABEL label))
      | _ =>
        let
          val (code, rmi) = transformValue context value
        in
          (code, I.ABS rmi)
        end

  fun forceMem rmi =
      case rmi of
        I.M_ mem => (nil, mem)
      | _ =>
        let
          val var = I.VAR (newVar {size = 0w4, align = 0w4})
        in
          ([ I.MOVL (I.M var, rmi) ], var)
        end

  fun forceMem64 rmi =
      let
        val var = I.VAR (newVar {size = 0w8, align = 0w8})
      in
        ([
           I.MOVL (I.M var, rmi),
           I.MOVL (I.M var, I.I_ (I.INT 0))
         ],
         var)
      end

  fun forceMemDst insn rm =
      case rm of
        I.M mem => [ insn mem ]
      | I.R reg =>
        let
          val var = I.VAR (newVar {size = 0w4, align = 0w4})
        in
          [
            insn var,
            I.MOVL (I.R reg, I.M_ var)
          ]
        end

  fun forceMemDst64 insn rm =
      case rm of
        I.M mem => [ insn mem ]
      | I.R reg => raise Control.Bug "forceMemDst64"

  fun transformAddr context (block, offset) =
      let
        val (insn1, block) = regOrImm (transformValue context block)
        val (insn2, offset) = regOrImm (transformValue context offset)
        val mem =
            case (block, offset) of
              (I.R_ base, I.R_ offset) => I.MEM (base, I.S1, offset)
            | (I.R_ base, I.I_ offset) => I.DISP (offset, I.BASE base)
            | (I.I_ base, I.R_ offset) => I.DISP (base, I.BASE offset)
            | (I.I_ base, I.I_ offset) => I.ABSADDR (immAdd (base, offset))
            | _ => raise Control.Bug "transformAddr"
      in
        (insn1 @ insn2, block, mem)
      end

  fun advanceAddr (mem, n) =
      let
        val m = I.INT (Int32.fromInt n)
      in
        case mem of
          I.DISP (n, mem) => I.DISP (immAdd (m,n), mem)
        | _ => I.DISP (m, mem)
      end

  local
    fun sizeOfVar mem =
        case mem of
          I.VAR {format={size,...},...} => SOME size
(*
        | I.VARREL (off, {format={size,...},...}) => SOME (size - off)
*)
        | _ => NONE
  in

  fun moveMemory (dst, src, size) =
      case size of
        I.M_ mem =>
        let
          val reg = newReg32 ()
        in
          I.MOVL (I.R reg, size) ::
          moveMemory (dst, src, I.R_ reg)
        end
      | I.I_ (I.INT x) =>
        moveMemory (dst, src, I.I_ (I.WORD (BasicTypes.SInt32ToUInt32 x)))
      | I.I_ (I.WORD 0w1) =>
        (
          case sizeOfVar dst of
            SOME 0w2 =>
            let
              val reg = newReg32 ()
            in
              [
                I.MOVZBW (I.X reg, I.M8 src),
                I.MOVW   (I.M16 dst, I.R_16 (I.X reg))
              ]
            end
          | SOME 0w4 =>
            let
              val reg = newReg32 ()
            in
              [
                I.MOVZBL (reg, I.M8 src),
                I.MOVL   (I.M dst, I.R_ reg)
              ]
            end
          | SOME 0w1 =>
            let
              val reg = newReg8 ()
            in
              [
                I.MOVB (I.R8 (I.XL reg), I.M_8 src),
                I.MOVB (I.M8 dst, I.R_8 (I.XL reg))
              ]
            end
          | _ => raise Control.Bug "moveMemory size=1"
        )
      | I.I_ (I.WORD 0w2) =>
        (
          case sizeOfVar dst of
            SOME 0w4 =>
            let
              val reg = newReg32 ()
            in
              [
                I.MOVZWL (reg, I.M16 src),
                I.MOVL   (I.M dst, I.R_ reg)
              ]
            end
          | _ =>
            let
              val reg = newReg32 ()
            in
              [
                I.MOVW (I.R16 (I.X reg), I.M_16 src),
                I.MOVW (I.M16 dst, I.R_16 (I.X reg))
              ]
            end
        )
      | I.I_ (I.WORD 0w4) =>
        let
          val reg = newReg32 ()
        in
          [
            I.MOVL (I.R reg, I.M_ src),
            I.MOVL (I.M dst, I.R_ reg)
          ]
        end
      | I.I_ (I.WORD 0w8) =>
(*
        if !SSE then
          let
            val reg = newRegXmm ()
          in
            [
              I.MOVQ_SSE (I.RX reg, I.MX src),
              I.MOVQ_SSE (I.MX dst, I.RX reg)
            ]
          end
        else if !MMX then
          let
            val reg = newRegMmx ()
          in
            [
              I.MOVQ_MMX (I.RM reg, I.MM src),
              I.MOVQ_MMX (I.MM dst, I.RM reg)
            ]
          end
        else
*)
          (* use just one register in order to reduce register pressure *)
          let
            val reg1 = newReg32 ()
            val reg2 = newReg32 ()
          in
            [
              I.MOVL (I.R reg1, I.M_ src),
              I.MOVL (I.M dst, I.R_ reg1),
              I.MOVL (I.R reg2, I.M_ (advanceAddr (src, 4))),
              I.MOVL (I.M (advanceAddr (dst, 4)), I.R_ reg2)
            ]
          end
      | I.I_ (I.WORD 0w12) =>
        let
          val reg1 = newReg32 ()
          val reg2 = newReg32 ()
          val reg3 = newReg32 ()
        in
          [
            I.MOVL (I.R reg1, I.M_ src),
            I.MOVL (I.M dst, I.R_ reg1),
            I.MOVL (I.R reg2, I.M_ (advanceAddr (src, 4))),
            I.MOVL (I.M (advanceAddr (dst, 4)), I.R_ reg2),
            I.MOVL (I.R reg3, I.M_ (advanceAddr (src, 8))),
            I.MOVL (I.M (advanceAddr (dst, 8)), I.R_ reg3)
          ]
        end
      | I.I_ (I.WORD 0w16) =>
(*
        if !SSE then
          let
            val reg = newRegXmm ()
          in
            [
              I.MOVDQA (I.RX reg, I.MX src),
              I.MOVDQA (I.MX dst, I.RX reg)
            ]
          end
        else
*)
          let
            val reg1 = newReg32 ()
            val reg2 = newReg32 ()
            val reg3 = newReg32 ()
            val reg4 = newReg32 ()
          in
            [
              I.MOVL (I.R reg1, I.M_ src),
              I.MOVL (I.M dst, I.R_ reg1),
              I.MOVL (I.R reg2, I.M_ (advanceAddr (src, 4))),
              I.MOVL (I.M (advanceAddr (dst, 4)), I.R_ reg2),
              I.MOVL (I.R reg3, I.M_ (advanceAddr (src, 8))),
              I.MOVL (I.M (advanceAddr (dst, 8)), I.R_ reg3),
              I.MOVL (I.R reg4, I.M_ (advanceAddr (src, 12))),
              I.MOVL (I.M (advanceAddr (dst, 12)), I.R_ reg4)
            ]
          end
      | I.I_ _ =>
        raise Control.Bug "moveMemory: undefined move"
      | I.R_ sz =>
        let
          val reg1 = newReg32 ()
          val reg2 = newReg32 ()
          val l1 = newLabel ()
          val l2 = newLabel ()
          val l3 = newLabel ()
        in
          [
            (* TODO: optimize *)
            I.LEAL (I.ESI, src),
            I.LEAL (I.EDI, dst),
            I.MOVL (I.R I.ECX, I.R_ sz),
            I.CLD,
            I.REP_MOVSB
          ]
        end

  fun moveImmediate (dst, imm, size) =
      case size of
        I.I_ (I.INT x) =>
        moveImmediate (dst, imm, I.I_ (I.WORD (BasicTypes.SInt32ToUInt32 x)))
      | I.I_ (I.WORD 0w1) =>
        (
          case sizeOfVar dst of
            SOME 0w2 => [ I.MOVW (I.M16 dst, I.I_16 (imm8 imm)) ]
          | SOME 0w4 => [ I.MOVL (I.M dst, I.I_ (imm8 imm)) ]
          | _ => [ I.MOVB (I.M8 dst, I.I_8 imm) ]
        )
      | I.I_ (I.WORD 0w2) =>
        (
          case sizeOfVar dst of
            SOME 0w4 => [ I.MOVL (I.M dst, I.I_ (imm16 imm)) ]
          | _ => [ I.MOVB (I.M8 dst, I.I_8 imm) ]
        )
      | I.I_ (I.WORD 0w4) => [ I.MOVL (I.M dst, I.I_ imm) ]
      | _ => raise Control.Bug "moveImmediate"

  end

  fun moveInsn (dst, src, size) =
      case dst of
        I.M dst =>
        (
          case src of
            I.M_ mem => moveMemory (dst, mem, size)
          | I.R_ reg => [ I.MOVL (I.M dst, I.R_ reg) ]
          | I.I_ imm => moveImmediate (dst, imm, size)
        )
      | I.R reg =>
        if (case size of I.I_ (I.INT 4) => true | I.I_ (I.WORD 0w4) => true
                       | _ => false)
        then [ I.MOVL (dst, src) ]
        else raise Control.Bug "moveInsn: I.R: size is not 4"

  fun shiftInsn shl shl_cl (rm, I.I_ (I.INT n)) = [shl (rm, Int32.toInt n)]
    | shiftInsn shl shl_cl (rm, I.I_ (I.WORD n)) = [shl (rm, Word32.toInt n)]
    | shiftInsn shl shl_cl (rm, arg) =
      [
        I.MOVL (I.R I.ECX, arg),
        shl_cl rm
      ]

  fun allocObject (objectType, bitmaps, payloadSize) =
      let
        val (objType, bittag, bitmaps, bitmapSize) =
            case (objectType, bitmaps) of
              (AI.Array, [bitmap]) =>
              (HEAD_TYPE_ARRAY, bitmap, nil, I.INT 0)
            | (AI.Vector, [bitmap]) =>
              (HEAD_TYPE_VECTOR, bitmap, nil, I.INT 0)
            | (AI.Record, _) =>
              (HEAD_TYPE_RECORD, I.I_ (I.INT 0), bitmaps,
               I.INT (Int32.fromInt (length bitmaps) * 4))
            | (AI.Array, bitmaps) =>
              raise Control.Bug "objectHeader: Array: multiple bitmap"
            | (AI.Vector, bitmaps) =>
              raise Control.Bug "objectHeader: Array: multiple bitmap"

        (* align payload size in word *)
        val (insn1, bitmapOffset) = addInsn (payloadSize, I.I_ (I.WORD 0w3))
        val (insn2, bitmapOffset) = andInsn (bitmapOffset,
                                             I.I_ (I.WORD (Word32.notb 0w3)))

        (* allocation size *)
        val (insn3, allocSize) = addInsn (bitmapOffset, I.I_ bitmapSize)

        val (insn4, bitmapOffset) =
            case bitmapOffset of
              I.I_ _ => (nil, bitmapOffset)
            | I.R_ _ =>
              let
                val reg = newReg32 ()
              in
                ([ I.MOVL (I.R reg, bitmapOffset) ], I.R_ reg)
              end
            | I.M_ _ => raise Control.Bug "allocObject: bitmapOffset"

        (* alloc object *)
        val insn5 =
            [
              I.MOVL (I.R I.EAX, allocSize),
              I.MOVL (I.R I.EDX, I.R_ I.EBP),
              I.Use  [I.EAX, I.EDX],
              I.CALL (I.REL (I.EXTSTUBLABEL smlHeapAllocFunLabel)),
              I.Def  [I.EAX, I.ECX, I.EDX],
              I.Use  [I.EAX, I.ECX, I.EDX]
            ]

        (* object type *)
        val (insn6, ty) = shiftLInsn (bittag, HEAD_BITTAG_SHIFT)
        val (insn7, ty) = orInsn (ty, I.I_ (I.WORD objType))

        (* object header *)
        val (insn8, header) = orInsn (ty, bitmapOffset)

        val insn9 =
            [
              I.MOVL (I.M (I.DISP (I.INT ~4, I.BASE I.EAX)), header)
            ]

        (* object bitmaps *)
        fun setBitmap (n, bitmap::bitmaps) =
            (case bitmapOffset of
               I.I_ x =>
               moveInsn (I.M (I.DISP (immAdd (x, I.INT (n * 4)), I.BASE I.EAX)),
                         bitmap,
                         I.I_ (I.INT 4))
             | I.R_ r =>
               moveInsn (I.M (I.DISP (I.INT (n * 4), I.MEM (I.EAX, I.S1, r))),
                         bitmap,
                         I.I_ (I.INT 4))
             | I.M_ _ => raise Control.Bug "allocObject") @
            setBitmap (n + 1, bitmaps)
          | setBitmap (n, nil) = nil

        val insn10 = setBitmap (0, bitmaps)
      in
        {
          insns = insn1 @ insn2 @ insn3 @ insn4 @ insn5 @
                  insn6 @ insn7 @ insn8 @ insn9 @ insn10,
          header = header,
          bitmapOffset = bitmapOffset,
          bitmaps = bitmaps,
          allocSize = allocSize
        }
      end

  fun setFCW insns =
      let
        val fcw1 = I.VAR (newVar {size = 0w2, align = 0w2})
        val fcw2 = I.VAR (newVar {size = 0w2, align = 0w2})
        val rcw = newReg32 ()
      in
        [
          I.FNSTCW  fcw1,
          I.MOVZWL  (rcw, I.M16 fcw1),
          I.ORB     (I.R8 (I.XH rcw), I.I_8 (I.WORD 0wx0f)),
          I.MOVW    (I.M16 fcw2, I.R_16 (I.X rcw)),
          I.FLDCW   fcw2
        ] @
        insns @
        [ I.FLDCW   fcw1 ]
      end

  local
    fun compareFloat op2 fld arg1 arg2 =
        let
          val (insn1, mem1) = forceMem arg1
          val (insn2, mem2) = forceMem arg2
          val (insn3, cc) =
              case op2 of
                AI.Gt =>
                (* 69 = C3|C2|C0 *)
                ([I.TESTB (I.R8 (I.XH I.EAX), I.I_8 (I.INT 69))], I.E)
              | AI.Gteq =>
                (* 5 = C2|C0 *)
                ([I.TESTB (I.R8 (I.XH I.EAX), I.I_8 (I.INT 5))], I.E)
              | AI.MonoEqual =>
                ([
                   (* 69 = C3|C2|C0, 64 = C3 *)
                   I.ANDB (I.R8 (I.XH I.EAX), I.I_8 (I.INT 69)),
                   I.CMPB (I.R8 (I.XH I.EAX), I.I_8 (I.INT 64))
                 ],
                 I.E)
              | _ => raise Control.Bug "compareFloat"
        in
          (insn1 @ insn2 @
           [
             fld mem2,
             fld mem1,
             I.FUCOMPP,
             I.FSTSW_AX
           ] @
           insn3,
           cc)
        end
  in

  fun selectCmpOp context op2 arg1 arg2 =
      case op2 of
        (op2, AI.UINT, AI.UINT, AI.UINT) =>
        let
          val reg = newReg32 ()
          val insn =
              [
                I.MOVL (I.R reg, arg1),
                I.CMPL (I.R reg, arg2)
              ]
          val cc =
              case op2 of
                AI.Gt => I.A
              | AI.Lt => I.B
              | AI.Gteq => I.AE
              | AI.Lteq => I.BE
              | AI.MonoEqual => I.E
              | _ => raise Control.Bug "selectCmpOp: UINT"
        in
          (insn, cc)
        end
      | (op2, AI.SINT, AI.SINT, AI.UINT) =>
        let
          val reg = newReg32 ()
          val insn =
              [
                I.MOVL (I.R reg, arg1),
                I.CMPL (I.R reg, arg2)
              ]
          val cc =
              case op2 of
                AI.Gt => I.G
              | AI.Lt => I.L
              | AI.Gteq => I.GE
              | AI.Lteq => I.LE
              | AI.MonoEqual => I.E
              | _ => raise Control.Bug "selectCmpOp: SINT"
        in
          (insn, cc)
        end
      | (op2, AI.BYTE, AI.BYTE, AI.UINT) =>
        selectCmpOp context (op2, AI.UINT, AI.UINT, AI.UINT) arg1 arg2
      | (op2, AI.ATOMty, AI.ATOMty, AI.UINT) =>
        selectCmpOp context (op2, AI.UINT, AI.UINT, AI.UINT) arg1 arg2
      | (AI.Lt, AI.FLOAT, AI.FLOAT, AI.UINT) =>
        compareFloat AI.Gt I.FLDS arg2 arg1
      | (AI.Lteq, AI.FLOAT, AI.FLOAT, AI.UINT) =>
        compareFloat AI.Gteq I.FLDS arg2 arg1
      | (op2, AI.FLOAT, AI.FLOAT, AI.UINT) =>
        compareFloat op2 I.FLDS arg1 arg2
      | (AI.Lt, AI.DOUBLE, AI.DOUBLE, AI.UINT) =>
        compareFloat AI.Gt I.FLDL arg2 arg1
      | (AI.Lteq, AI.DOUBLE, AI.DOUBLE, AI.UINT) =>
        compareFloat AI.Gteq I.FLDL arg2 arg1
      | (op2, AI.DOUBLE, AI.DOUBLE, AI.UINT) =>
        compareFloat op2 I.FLDL arg1 arg2
      | (AI.MonoEqual, AI.HEAPPOINTER, AI.HEAPPOINTER, AI.UINT) =>
        selectCmpOp context (AI.MonoEqual, AI.UINT, AI.UINT, AI.UINT) arg1 arg2
      | (AI.MonoEqual, AI.CODEPOINTER, AI.CODEPOINTER, AI.UINT) =>
        selectCmpOp context (AI.MonoEqual, AI.UINT, AI.UINT, AI.UINT) arg1 arg2
      | (AI.MonoEqual, AI.CPOINTER, AI.CPOINTER, AI.UINT) =>
        selectCmpOp context (AI.MonoEqual, AI.UINT, AI.UINT, AI.UINT) arg1 arg2
      | (AI.MonoEqual, AI.BOXED, AI.BOXED, AI.UINT) =>
        let
          val reg = newReg32 ()
        in
          ([
             I.MOVL (I.R reg, arg1),
             I.CMPL (I.R reg, arg2)
           ], I.E)
        end
      | (op2, ty1, ty2, ty3) =>
        raise Control.Bug
                ("selectCmpOp: " ^
                 Control.prettyPrint (AI.format_op2 (nil, nil) op2) ^ ": " ^
                 Control.prettyPrint (AI.format_ty ty1) ^ ", " ^
                 Control.prettyPrint (AI.format_ty ty2) ^ " -> " ^
                 Control.prettyPrint (AI.format_ty ty3))
  end

  fun selectInsn context insn =
      case insn of
        AI.Move {dst, ty, value, loc} =>
        let
          val dst = transformVarInfo dst
          val (insn1, value) = transformValue context value
          val valueSize = BasicTypes.WordToUInt32 (#size (formatOf ty))
        in
          insn1 @ moveInsn (dst, value, I.I_ (I.WORD valueSize))
        end

      | AI.Load {dst, ty, block, offset, size, loc} =>
        let
          val dst = transformVarInfo dst
          val (insn1, _, mem) = transformAddr context (block, offset)
          val (insn2, size) = transformValue context size
        in
          insn1 @ insn2 @ moveInsn (dst, I.M_ mem, size)
        end

      | AI.Update {block, offset, ty, size, value, barrier, loc} =>
        let
          val (insn1, obj, dst) = transformAddr context (block, offset)
          val (insn2, size) = transformValue context size
          val (insn3, value) = transformValue context value

          val barrierInsn =
              case barrier of
                AI.NoBarrier => nil
              | AI.WriteBarrier =>
                [
                  I.LEAL (I.EAX, dst),
                  I.MOVL (I.R I.EDX, obj),
                  I.Use  [I.EAX, I.EDX],
                  I.CALL (I.REL (I.EXTSTUBLABEL smlWriteBarrierFunLabel)),
                  I.Def  [I.EAX, I.ECX, I.EDX],
                  I.Use  [I.EAX, I.ECX, I.EDX]
                ]
              | AI.BarrierTag value =>
                let
                  val reg = newReg32 ()
                  val (insn1, value) = transformValue context value
                  val l1 = newLabel ()
                  val l2 = newLabel ()
                in
                  [
                    I.MOVL  (I.R reg, value),
                    I.TESTL (I.R reg, I.R_ reg),
                    I.LEAL  (I.EAX, dst),
                    I.J     (I.E, l2, l1),
                    I.Label l1,
                    I.MOVL  (I.R I.EDX, obj),
                    I.Use   [I.EAX, I.EDX],
                    I.CALL  (I.REL (I.EXTSTUBLABEL smlWriteBarrierFunLabel)),
                    I.Def   [I.EAX, I.ECX, I.EDX],
                    I.Use   [I.EAX, I.ECX, I.EDX],
                    I.Label l2
                  ]
                end
        in
          insn1 @ insn2 @ insn3 @ moveInsn (I.M dst, value, size) @ barrierInsn
        end

      | AI.Get {dst, ty, src, loc} =>
        let
          val arg = transformArgInfo src
          val dst = transformVarInfo dst
          val size = BasicTypes.WordToUInt32 (#size (formatOf ty))
          val size = I.I_ (I.WORD size)
        in
          case arg of
            IARG arg => moveInsn (dst, rmToRmi arg, size)
          | FARG0 =>
            case ty of
              AI.FLOAT => forceMemDst I.FSTPS dst
            | AI.DOUBLE => forceMemDst64 I.FSTPL dst
            | AI.ATOMty => forceMemDst I.FSTPL dst  (* obsolete *)
            | AI.DOUBLEty => forceMemDst64 I.FSTPL dst  (* obsolete *)
            | _ => raise Control.Bug "Get FARG"
        end

      | AI.Set {dst, ty, value, loc} =>
        let
          val arg = transformArgInfo dst
          val (insn1, value) = transformValue context value
          val size = BasicTypes.WordToUInt32 (#size (formatOf ty))
          val size = I.I_ (I.WORD size)
        in
          insn1 @
          (case arg of
             IARG arg => moveInsn (arg, value, size)
           | FARG0 =>
             let
               val (insn2, value) = forceMem value
             in
               insn2 @ [ I.FLDL value ]
             end)
        end

      | AI.Alloc {dst, objectType, bitmaps, payloadSize, loc} =>
        let
          val dst = transformVarInfo dst
          val (insn1, bitmaps) = transformValueList context bitmaps
          val (insn2, payloadSize) = transformValue context payloadSize
          val {insns = insn3, ...} =
              allocObject (objectType, bitmaps, payloadSize)
        in
          insn1 @ insn2 @ insn3 @ [ I.MOVL (dst, I.R_ I.EAX) ]
        end

      | AI.PrimOp1 {dst, op1=(op1, ty1, ty2), arg, loc} =>
        let
          val dst = transformVarInfo dst
          val (insn1, arg) = transformValue context arg
        in
          insn1 @
          (
            case (op1, ty1, ty2) of
              (AI.Neg, AI.SINT, AI.SINT) =>
              let
                val reg = newReg32 ()
              in
                [
                  I.MOVL (I.R reg, arg),
                  I.NEGL (I.R reg),
                  I.MOVL (dst, I.R_ reg)
                ]
              end
            | (AI.Neg, AI.FLOAT, AI.FLOAT) =>
              let
                val (insn1, mem) = forceMem arg
              in
                insn1 @
                [
                  I.FLDS mem,
                  I.FCHS
                ] @
                forceMemDst I.FSTPS dst
              end
            | (AI.Neg, AI.DOUBLE, AI.DOUBLE) =>
              let
                val (insn1, mem) = forceMem arg
              in
                insn1 @
                [
                  I.FLDL mem,
                  I.FCHS
                ] @
                forceMemDst64 I.FSTPL dst
              end
            | (AI.Abs, AI.SINT, AI.SINT) =>
              let
                val l1 = newLabel ()
                val l2 = newLabel ()
                val reg = newReg32 ()
              in
                [
                  I.MOVL  (I.R reg, arg),
                  I.TESTL (I.R reg, I.R_ reg),
                  I.J     (I.S, l2, l1),
                  I.Label l1,
                  I.NEGL  (I.R reg),
                  I.MOVL  (dst, I.R_ reg),
                  I.Label l2
                ]
              end
            | (AI.Abs, AI.FLOAT, AI.FLOAT) =>
              let
                val (insn1, mem) = forceMem arg
              in
                insn1 @
                [
                  I.FLDS mem,
                  I.FABS
                ] @
                forceMemDst I.FSTPS dst
              end
            | (AI.Abs, AI.DOUBLE, AI.DOUBLE) =>
              let
                val (insn1, mem) = forceMem arg
              in
                insn1 @
                [
                  I.FLDL mem,
                  I.FABS
                ] @
                forceMemDst64 I.FSTPL dst
              end
            | (AI.Cast, AI.UINT, AI.FLOAT) =>
              let
                val (insn1, mem) = forceMem64 arg
              in
                insn1 @
                [
                  I.FILDQ mem
                ] @
                forceMemDst I.FSTPS dst
              end
            | (AI.Cast, AI.UINT, AI.DOUBLE) =>
              let
                val (insn1, mem) = forceMem64 arg
              in
                insn1 @
                [
                  I.FILDQ mem
                ] @
                forceMemDst64 I.FSTPL dst
              end
            | (AI.Cast, AI.SINT, AI.FLOAT) =>
              let
                val (insn1, mem) = forceMem arg
              in
                insn1 @
                [
                  I.FILDL mem
                ] @
                forceMemDst I.FSTPS dst
              end
            | (AI.Cast, AI.SINT, AI.DOUBLE) =>
              let
                val (insn1, mem) = forceMem arg
              in
                insn1 @
                [
                  I.FILDL mem
                ] @
                forceMemDst I.FSTPL dst
              end
            | (AI.Cast, AI.FLOAT, AI.UINT) =>
              let
                val var = I.VAR (newVar {size = 0w8, align = 0w8})
                val reg = newReg32 ()
                val (insn1, mem) = forceMem arg
              in
                insn1 @
                [ I.FLDS mem ] @
                setFCW [ I.FISTPQ var ] @
                [
                  I.MOVL (I.R reg, I.M_ var),
                  I.MOVL (dst, I.R_ reg)
                ]
              end
            | (AI.Cast, AI.FLOAT, AI.SINT) =>
              let
                val (insn1, mem) = forceMem arg
              in
                insn1 @
                [ I.FLDS mem ] @
                setFCW (forceMemDst64 I.FISTPL dst)
              end
            | (AI.Cast, AI.FLOAT, AI.DOUBLE) =>
              let
                val (insn1, mem) = forceMem arg
              in
                insn1 @
                [
                  I.FLDS mem
                ] @
                forceMemDst64 I.FSTPL dst
              end
            | (AI.Cast, AI.DOUBLE, AI.UINT) =>
              let
                val (insn1, mem) = forceMem arg
                val var = I.VAR (newVar {size = 0w8, align = 0w8})
                val reg = newReg32 ()
              in
                insn1 @
                [ I.FLDL mem ] @
                setFCW [ I.FISTPQ var ] @
                [
                  I.MOVL (I.R reg, I.M_ var),
                  I.MOVL (dst, I.R_ reg)
                ]
              end
            | (AI.Cast, AI.DOUBLE, AI.SINT) =>
              let
                val (insn1, mem) = forceMem arg
              in
                insn1 @
                [ I.FLDL mem ] @
                setFCW (forceMemDst64 I.FISTPL dst)
              end
            | (AI.Cast, AI.DOUBLE, AI.FLOAT) =>
              let
                val (insn1, mem) = forceMem arg
              in
                insn1 @
                [
                  I.FLDL mem
                ] @
                forceMemDst I.FSTPS dst
              end
            | (AI.Cast, AI.UINT, AI.SINT) =>
              let
                val reg = newReg32 ()
              in
                [
                  I.MOVL (I.R reg, arg),
                  I.MOVL (dst, I.R_ reg)
                ]
              end
            | (AI.Cast, AI.UINT, AI.BYTE) =>
              let
                val reg = newReg32 ()
              in
                [
                  I.MOVL (I.R reg, arg),
                  I.MOVL (dst, I.R_ reg)
                ]
              end
            | (AI.Cast, AI.SINT, AI.UINT) =>
              let
                val reg = newReg32 ()
              in
                [
                  I.MOVL (I.R reg, arg),
                  I.MOVL (dst, I.R_ reg)
                ]
              end
            | (AI.Cast, AI.SINT, AI.BYTE) =>
              let
                val reg = newReg32 ()
              in
                [
                  I.MOVL (I.R reg, arg),
                  I.MOVL (dst, I.R_ reg)
                ]
              end
            | (AI.ZeroExt, AI.BYTE, AI.UINT) =>
              let
                val reg = newReg8 ()
              in
                [
                  I.MOVL (I.R reg, arg),
                  I.MOVZBL (reg, I.R8 (I.XL reg)),
                  I.MOVL (dst, I.R_ reg)
                ]
              end
            | (AI.ZeroExt, AI.BYTE, AI.SINT) =>
              let
                val reg = newReg8 ()
              in
                [
                  I.MOVL (I.R reg, arg),
                  I.MOVZBL (reg, I.R8 (I.XL reg)),
                  I.MOVL (dst, I.R_ reg)
                ]
              end
            | (AI.SignExt, AI.BYTE, AI.SINT) =>
              [
                I.MOVL (I.R I.EAX, arg),
                I.CBW,
                I.CWDE,
                I.MOVL (dst, I.R_ I.EAX)
              ]
            | (AI.Notb, AI.UINT, AI.UINT) =>
              let
                val reg = newReg32 ()
              in
                [
                  I.MOVL (I.R reg, arg),
                  I.NOTL (I.R reg),
                  I.MOVL (dst, I.R_ reg)
                ]
              end
            | (AI.PayloadSize, AI.BOXED, AI.UINT) =>
              let
                val mem = forceMem arg
                val obj = newReg32 ()
                val size = newReg32 ()
              in
                [
                  I.MOVL (I.R obj, arg),
                  I.LEAL (obj, I.DISP (I.INT ~4, I.BASE obj)),
                  I.MOVL (I.R size, I.M_ (I.BASE obj)),
                  I.ANDL (I.R size, I.I_ (I.WORD HEAD_SIZE_MASK)),
                  I.MOVL (dst, I.R_ size)
                ]
              end
            | (op1, ty1, ty2) =>
              raise Control.Bug
                        ("selectOp1: " ^
                         Control.prettyPrint (AI.format_op1 nil op1)^", "^
                         Control.prettyPrint (AI.format_ty ty1) ^ ", " ^
                         Control.prettyPrint (AI.format_ty ty2))
          )
        end

      | AI.PrimOp2 {dst, op2=(op2, ty1, ty2, ty3), arg1, arg2, loc} =>
        let
          val dst = transformVarInfo dst
          val (insn1, arg1) = transformValue context arg1
          val (insn2, arg2) = transformValue context arg2
        in
          case (op2, ty1, ty2, ty3) of
            (AI.Add, AI.UINT, AI.UINT, AI.UINT) =>
            let
              val reg = newReg32 ()
            in
              [
                I.MOVL (I.R reg, arg1),
                I.ADDL (I.R reg, arg2),
                I.MOVL (dst, I.R_ reg)
              ]
            end
          | (AI.Add, AI.SINT, AI.SINT, AI.SINT) =>
            let
              val reg = newReg32 ()
            in
              [
                I.MOVL (I.R reg, arg1),
                I.ADDL (I.R reg, arg2),
                I.MOVL (dst, I.R_ reg)
              ]
            end
          | (AI.Add, AI.FLOAT, AI.FLOAT, AI.FLOAT) =>
            let
              val (insn1, mem1) = forceMem arg1
              val (insn2, mem2) = forceMem arg2
            in
              insn1 @ insn2 @
              [
                I.FLDS  mem1,      (* st0=arg1 *)
                I.FLDS  mem2,      (* st1=arg1, st0=arg2 *)
                I.FADDP (I.ST 1)   (* st0=arg1+arg2 *)
              ] @
              forceMemDst I.FSTPS dst
            end
          | (AI.Add, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE) =>
            let
              val (insn1, mem1) = forceMem arg1
              val (insn2, mem2) = forceMem arg2
            in
              insn1 @ insn2 @
              [
                I.FLDL  mem1,
                I.FLDL  mem2,
                I.FADDP (I.ST 1)
              ] @
              forceMemDst64 I.FSTPL dst
            end
          | (AI.Sub, AI.UINT, AI.UINT, AI.UINT) =>
            let
              val reg = newReg32 ()
            in
              [
                I.MOVL (I.R reg, arg1),
                I.SUBL (I.R reg, arg2),
                I.MOVL (dst, I.R_ reg)
              ]
            end
          | (AI.Sub, AI.SINT, AI.SINT, AI.SINT) =>
            let
              val reg = newReg32 ()
            in
              [
                I.MOVL (I.R reg, arg1),
                I.SUBL (I.R reg, arg2),
                I.MOVL (dst, I.R_ reg)
              ]
            end
          | (AI.Sub, AI.FLOAT, AI.FLOAT, AI.FLOAT) =>
            let
              val (insn1, mem1) = forceMem arg1
              val (insn2, mem2) = forceMem arg2
            in
              insn1 @ insn2 @
              [
                I.FLDS  mem1,      (* st0=arg1 *)
                I.FLDS  mem2,      (* st1=arg1, st0=arg2 *)
                I.FSUBP (I.ST 1)   (* st0=arg1-arg2 *)
              ] @
              forceMemDst I.FSTPS dst
            end
          | (AI.Sub, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE) =>
            let
              val (insn1, mem1) = forceMem arg1
              val (insn2, mem2) = forceMem arg2
            in
              insn1 @ insn2 @
              [
                I.FLDL  mem1,
                I.FLDL  mem2,
                I.FSUBP (I.ST 1)
              ] @
              forceMemDst I.FSTPL dst
            end
          | (AI.Mul, AI.UINT, AI.UINT, AI.UINT) =>
            let
              val (insn1, arg2) = rmiToRm arg2
            in
              insn1 @
              [
                I.MOVL (I.R I.EAX, arg1),
                I.MULL arg2,
                I.Use  [I.EDX],  (* ignore %edx *)
                I.MOVL (dst, I.R_ I.EAX)
              ]
            end
          | (AI.Mul, AI.SINT, AI.SINT, AI.SINT) =>
            let
              val (insn1, arg2) = rmiToRm arg2
            in
              insn1 @
              [
                I.MOVL  (I.R I.EAX, arg1),
                I.IMULL arg2,
                I.Use   [I.EDX],  (* ignore %edx *)
                I.MOVL  (dst, I.R_ I.EAX)
              ]
            end
          | (AI.Mul, AI.FLOAT, AI.FLOAT, AI.FLOAT) =>
            let
              val (insn1, mem1) = forceMem arg1
              val (insn2, mem2) = forceMem arg2
            in
              insn1 @ insn2 @
              [
                I.FLDS  mem1,
                I.FLDS  mem2,
                I.FMULP (I.ST 1)
              ] @
              forceMemDst I.FSTPS dst
            end
          | (AI.Mul, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE) =>
            let
              val (insn1, mem1) = forceMem arg1
              val (insn2, mem2) = forceMem arg2
            in
              insn1 @ insn2 @
              [
                I.FLDL  mem1,
                I.FLDL  mem2,
                I.FMULP (I.ST 1)
              ] @
              forceMemDst64 I.FSTPL dst
            end
          | (AI.Div, AI.SINT, AI.SINT, AI.SINT) =>
            let
              val (insn1, arg2) = rmiToRm arg2
              val tmp = newReg8 ()
            in
              (*
               * NOTE: rounding is towards negative infinity.
               *
               * arg1 / arg2 = q ... r
               * q' = q - ((q < 0 && r != 0) ? 1 : 0)
               * r' = r + ((q < 0 && r != 0) ? arg2 : 0)
               *
               * ((q < 0 && r != 0) ? 1 : 0)
               *   = (q < 0) & (r != 0)
               * ((q < 0 && r != 0) ? arg2 : 0)
               *   = (((q >= 0) | (r == 0)) - 1) & arg2
               *)
              insn1 @
              [
                I.MOVL   (I.R I.EAX, arg1),
                I.CDQ,
                I.IDIVL  arg2,
                I.TESTL  (I.R I.EAX, I.R_ I.EAX),
                I.SET    (I.S, I.R8 (I.XL tmp)),
                I.TESTL  (I.R I.EDX, I.R_ I.EDX),
                I.SET    (I.NE, I.R8 (I.XL I.EDX)),
                I.ANDB   (I.R8 (I.XL tmp), I.R_8 (I.XL I.EDX)),
                I.MOVZBL (tmp, I.R8 (I.XL tmp)),
                I.SUBL   (I.R I.EAX, I.R_ tmp),
                I.MOVL   (dst, I.R_ I.EAX)
              ]
            end
          | (AI.Quot, AI.SINT, AI.SINT, AI.SINT) =>
            let
              val (insn1, arg2) = rmiToRm arg2
            in
              insn1 @
              [
                I.MOVL (I.R I.EAX, arg1),
                I.CDQ,
                I.DIVL arg2,
                I.MOVL (dst, I.R_ I.EAX)
              ]
            end
          | (AI.Div, AI.UINT, AI.UINT, AI.UINT) =>
            let
              val (insn1, arg2) = rmiToRm arg2
            in
              insn1 @
              [
                I.MOVL (I.R I.EAX, arg1),
                I.MOVL (I.R I.EDX, I.I_ (I.INT 0)),
                I.DIVL arg2,
                I.MOVL (dst, I.R_ I.EAX)
              ]
            end
          | (AI.Div, AI.FLOAT, AI.FLOAT, AI.FLOAT) =>
            let
              val (insn1, mem1) = forceMem arg1
              val (insn2, mem2) = forceMem arg2
            in
              insn1 @ insn2 @
              [
                I.FLDS  mem1,      (* %st(1) *)
                I.FLDS  mem2,      (* %st(0) *)
                I.FDIVP (I.ST 1)   (* %st(0) = %st(1) / %st(0) *)
              ] @
              forceMemDst I.FSTPS dst
            end
          | (AI.Div, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE) =>
            let
              val (insn1, mem1) = forceMem arg1
              val (insn2, mem2) = forceMem arg2
            in
              insn1 @ insn2 @
              [
                I.FLDL  mem1,
                I.FLDL  mem2,
                I.FDIVP (I.ST 1)
              ] @
              forceMemDst64 I.FSTPL dst
            end
          | (AI.Mod, AI.SINT, AI.SINT, AI.SINT) =>
            let
              val (insn1, mem2) = forceMem arg2
              val tmp = newReg8 ()
            in
              (* NOTE: rounding is towards negative infinity.
               * see the case for Div. *)
              insn1 @
              [
                I.MOVL   (I.R I.EAX, arg1),
                I.CDQ,
                I.IDIVL  (I.M mem2),
                I.TESTL  (I.R I.EAX, I.R_ I.EAX),
                I.SET    (I.NS, I.R8 (I.XL tmp)),
                I.TESTL  (I.R I.EDX, I.R_ I.EDX),
                I.SET    (I.E, I.R8 (I.XL I.EAX)),
                I.ORB    (I.R8 (I.XL tmp), I.R_8 (I.XL I.EAX)),
                I.MOVZBL (tmp, I.R8 (I.XL tmp)),
                I.SUBL   (I.R tmp, I.I_ (I.INT 1)),
                I.ANDL   (I.R tmp, I.M_ mem2),
                I.ADDL   (I.R I.EDX, I.R_ tmp),
                I.MOVL   (dst, I.R_ I.EDX)
              ]
            end
          | (AI.Rem, AI.SINT, AI.SINT, AI.SINT) =>
            let
              val (insn1, arg2) = rmiToRm arg2
            in
              insn1 @
              [
                I.MOVL  (I.R I.EAX, arg1),
                I.CDQ,
                I.IDIVL arg2,
                I.MOVL  (dst, I.R_ I.EDX)
              ]
            end
          | (AI.Mod, AI.UINT, AI.UINT, AI.UINT) =>
            let
              val (insn1, arg2) = rmiToRm arg2
            in
              insn1 @
              [
                I.MOVL (I.R I.EAX, arg1),
                I.MOVL (I.R I.EDX, I.I_ (I.INT 0)),
                I.DIVL arg2,
                I.MOVL (dst, I.R_ I.EDX)
              ]
            end
          | (AI.Andb, AI.UINT, AI.UINT, AI.UINT) =>
            let
              val reg = newReg32 ()
            in
              [
                I.MOVL (I.R reg, arg1),
                I.ANDL (I.R reg, arg2),
                I.MOVL (dst, I.R_ reg)
              ]
            end
          | (AI.Orb, AI.UINT, AI.UINT, AI.UINT) =>
            let
              val reg = newReg32 ()
            in
              [
                I.MOVL (I.R reg, arg1),
                I.ORL  (I.R reg, arg2),
                I.MOVL (dst, I.R_ reg)
              ]
            end
          | (AI.Xorb, AI.UINT, AI.UINT, AI.UINT) =>
            let
              val reg = newReg32 ()
            in
              [
                I.MOVL (I.R reg, arg1),
                I.XORL (I.R reg, arg2),
                I.MOVL (dst, I.R_ reg)
              ]
            end
          | (AI.LShift, AI.UINT, AI.UINT, AI.UINT) =>
            let
              val reg = newReg32 ()
            in
              I.MOVL (I.R reg, arg1) ::
              shiftInsn I.SHLL I.SHLL_CL (I.R reg, arg2) @
              [ I.MOVL (dst, I.R_ reg) ]
            end
          | (AI.RShift, AI.UINT, AI.UINT, AI.UINT) =>
            let
              val reg = newReg32 ()
            in
              I.MOVL (I.R reg, arg1) ::
              shiftInsn I.SHRL I.SHRL_CL (I.R reg, arg2) @
              [ I.MOVL (dst, I.R_ reg) ]
            end
          | (AI.ArithRShift, AI.UINT, AI.UINT, AI.UINT) =>
            let
              val reg = newReg32 ()
            in
              I.MOVL (I.R reg, arg1) ::
              shiftInsn I.SARL I.SARL_CL (I.R reg, arg2) @
              [ I.MOVL (dst, I.R_ reg) ]
            end
          | op2 =>
            let
              val (insn1, cc) = selectCmpOp context op2 arg1 arg2
              val reg = newReg8 ()
            in
              insn1 @
              [
                I.SET    (cc, I.R8 (I.XL reg)),
                I.MOVZBL (reg, I.R8 (I.XL reg)),
                I.MOVL   (dst, I.R_ reg)
              ]
            end
        end

      | AI.CallExt {dstVarList, entry, attributes, argList, calleeTy, loc} =>
        let
          val (insn1, entry) = transformJumpTo context entry

          val insn2 =
              if not (#noCallback attributes) orelse #allocMLValue attributes
              then
                [
                  I.MOVL (I.R I.EAX, I.R_ I.EBP),
                  I.Use  [I.EAX],
                  I.CALL (I.REL (I.EXTSTUBLABEL smlSaveFramePointerFunLabel)),
                  I.Def  [I.EAX, I.ECX, I.EDX],
                  I.Use  [I.EAX, I.ECX, I.EDX]
                ]
              else nil
        in
          insn1 @ insn2 @
          [
            I.Loc  loc,
            I.CALL entry,
            I.Def  [I.EAX, I.ECX, I.EDX],
            I.Use  [I.EAX, I.ECX, I.EDX]
          ]
        end

      | AI.Call {dstVarList, entry, env, argList,
                 argTyList, resultTyList, loc} =>
        let
          val (insn1, entry) = transformJumpTo context entry
          val argSize = 16 * length argTyList  (* ToDo: 16 is magic number *)
        in
          insn1 @
          [
            I.Loc  loc,
            I.Use  [I.EAX],
            I.CALL entry,
            I.Def  [I.EAX, I.ECX, I.EDX],
            I.Use  [I.EAX, I.ECX, I.EDX],
            I.SUBL (I.R I.ESP, I.I_ (I.INT (Int32.fromInt argSize)))
          ] @
          (if !Control.debugCodeGen then
             let
               val l1 = newLabel ()
               val l2 = newLabel ()
             in
               [
                 I.LEAL (I.ECX, I.POSTFRAME {offset = 0, size = 0w4}),
                 I.CMPL (I.R I.ESP, I.R_ I.ECX),
                 I.J    (I.E, l2, l1),
                 I.Label l1,
                 I.MOVL (I.R I.EAX, I.R_ I.ESP),
                 I.MOVL (I.R I.EDX, I.R_ I.EBP),
                 I.Use  [I.EAX, I.EDX],
                 I.CALL (I.REL (I.EXTSTUBLABEL "sml_stack_corrupted")),
                 I.Def  [I.EAX, I.ECX, I.EDX],
                 I.Use  [I.EAX, I.ECX, I.EDX],
                 I.Label l2,
                 I.MOVL (I.R I.EDI, I.R_ I.ESP),
                 I.MOVL (I.R I.ECX, I.I_ (I.INT (Int32.fromInt argSize div 4))),
                 I.MOVL (I.R I.EAX, I.I_ (I.WORD 0wx55555555)),
                 I.CLD,
                 I.REP_STOSD
               ]
             end
           else nil)
        end

      | AI.TailCall {entry, env, argList, argTyList, resultTyList, loc} =>
        let
          val (insn1, entry) = transformJumpTo context entry
          val argSize = 16 * length argTyList  (* ToDo: 16 is magic number *)
          val retSize = 16 * length resultTyList (* ToDo: magic number *)
          val preSize = retSize + argSize (* ToDo: magic number *)
          val (insn2, entry) =
              case entry of
                I.ABS (dst as I.M_ (I.VAR _)) =>
                let
                  val reg = newReg [I.ECX, I.EDX]
                in
                  ([ I.MOVL (I.R reg, dst) ], I.ABS (I.R_ reg))
                end
              | _ => (nil, entry)
        in
          insn1 @ insn2 @
          [
            I.Loc  loc
          ] @
          map (fn v => I.MOVL (I.R (List.hd (#candidates v)), I.M_ (I.VAR v)))
              (#calleeSaveRegs context) @
          (
            let
              val reg = newReg [I.ECX, I.EDX]
            in
              [I.MOVL (I.R reg, I.M_ (I.DISP (I.INT 4, I.BASE I.EBP))),
               I.MOVL (I.M (I.PREFRAME {offset = preSize, size = 0w4}),
                       I.R_ reg)]
            end
          ) @
          [
            I.Use (I.EAX :: map (List.hd o #candidates)
                                (#calleeSaveRegs context)),
            I.Epilogue {preFrameSize=preSize, instructions=nil},

            I.JMP (entry, nil)
          ]
        end

      | AI.CallbackClosure {dst, entry, env, exportTy, attributes, loc} =>
        raise Control.Bug "FIXME: not implemented"

      | AI.Return {varList, argTyList, retTyList, loc} =>
        let
          val argSize = 16 * length argTyList  (* ToDo: 16 is magic number *)
          val retSize = 16 * length retTyList (* ToDo: magic number *)
          val preSize = retSize + argSize (* ToDo: magic number *)
          val argSize = if argSize = 0
                        then NONE
                        else SOME (I.INT (Int32.fromInt argSize))
        in
          map (fn v => I.MOVL (I.R (List.hd (#candidates v)), I.M_ (I.VAR v)))
              (#calleeSaveRegs context) @
          [
            I.Use (I.EAX :: map (List.hd o #candidates)
                                (#calleeSaveRegs context)),
            I.Epilogue {preFrameSize=preSize, instructions=nil},
            I.RET argSize
          ]
        end

      | AI.ReturnExt _ =>
        raise Control.Bug "FIXME: ReturnExt"

      | AI.If {value1, value2, op2, thenLabel, elseLabel, loc} =>
        let
          val (insn1, arg1) = transformValue context value1
          val (insn2, arg2) = transformValue context value2
          val (insn3, cc) = selectCmpOp context op2 arg1 arg2
          val l = newLabel ()
          val elseLabel = localLabel elseLabel
        in
          insn1 @ insn2 @ insn3 @
          [
            I.J   (cc, localLabel thenLabel, l),
            I.Label l,
            I.JMP (I.REL (I.LABEL elseLabel), [elseLabel])
          ]
        end

      | AI.CheckBoundary {offset, size, objectSize, passLabel, failLabel,
                          loc} =>
        let
          val (insn1, offset) = transformValue context offset
          val (insn2, size) = transformValue context size
          val (insn3, objectSize) = transformValue context objectSize
          val passLabel = localLabel passLabel
          val failLabel = localLabel failLabel
          val reg = newReg32 ()
          val l1 = newLabel ()
          val l2 = newLabel ()
        in
          insn1 @ insn2 @ insn3 @
          [
            I.MOVL (I.R reg, objectSize),  (* objsize <= size *)
            I.SUBL (I.R reg, size),
            I.J    (I.B, failLabel, l1),
            I.Label l1,
            I.CMPL (I.R reg, offset),   (* offset <= objsize - size *)
            I.J    (I.B, failLabel, l2),
            I.Label l2,
            I.JMP  (I.REL (I.LABEL passLabel), [passLabel])
          ]
        end

      | AI.Jump {label, knownDestinations, loc} =>
        (
          case knownDestinations of
            [l] =>
            let
              val label = localLabel l
            in
              [ I.JMP (I.REL (I.LABEL label), [label]) ]
            end
          | _ =>
            let
              val (insn1, entry) = transformJumpTo context label
            in
              insn1 @ [ I.JMP (entry, map localLabel knownDestinations) ]
            end
        )

      | AI.ChangeHandler {change = AI.PushHandler _, previousHandler,
                          newHandler, tryBlock, loc} =>
        let
          val handlerLabel =
              case newHandler of
                AI.StaticHandler l => localLabel l
              | _ => raise Control.Bug "selectInsn: ChangeHandler"
          val tryLabel = localLabel tryBlock
          val (insn1, handlerAddr) = absoluteAddr context (I.LABEL handlerLabel)
          val handlerInfo = I.VAR (newVar {size = 0w16, align = 0w4})
          val reg = newReg32 ()
        in
          insn1 @
          [
            I.LEAL (reg, handlerAddr),
            I.LEAL (I.EAX, handlerInfo),
            I.MOVL (I.M (I.DISP (I.INT 4, I.BASE I.EAX)), I.R_ reg),
            I.MOVL (I.M (I.DISP (I.INT 8, I.BASE I.EAX)), I.R_ I.ESP),
            I.MOVL (I.M (I.DISP (I.INT 12, I.BASE I.EAX)), I.R_ I.EBP),
            I.CALL (I.REL (I.EXTSTUBLABEL smlPushHandlerFunLabel)),
            (* Ensure that all values before changing handler are stored
             * in memory. *)
            I.Def  [I.EAX, I.EBX, I.ECX, I.EDX, I.ESI, I.EDI],
            I.Use  [I.EAX, I.EBX, I.ECX, I.EDX, I.ESI, I.EDI],
            I.JMP  (I.REL (I.LABEL tryLabel), [handlerLabel, tryLabel])
          ]
        end

      | AI.ChangeHandler {change = AI.PopHandler _, previousHandler,
                          newHandler, tryBlock, loc} =>
        let
          val tryLabel = localLabel tryBlock
        in
          [
            I.CALL (I.REL (I.EXTSTUBLABEL smlPopHandlerFunLabel)),
            I.Def  [I.EAX, I.ECX, I.EDX],
            I.Use  [I.EAX, I.ECX, I.EDX],
            I.JMP  (I.REL (I.LABEL tryLabel), [tryLabel])
          ]
        end

      | AI.Raise {exn, loc} =>
        let
          val reg1 = newReg32 ()
          val reg2 = newReg32 ()
        in
          (* ToDo: the case when handled by the same cluster *)
          [
            I.MOVL (I.R reg2, I.R_ I.EAX),   (* FIXME: nasty code *)
            I.Loc  loc
          ] @
          (if !Control.debugCodeGen
           then [I.CALL (I.REL (I.EXTSTUBLABEL "sml_before_raise"))]
           else nil) @
          [
            I.CALL (I.REL (I.EXTSTUBLABEL smlPopHandlerFunLabel)),
            I.Def  [I.EAX, I.ECX, I.EDX],
            I.Use  [I.EAX, I.ECX, I.EDX],
            I.MOVL (I.R reg1, I.M_ (I.DISP (I.INT 4, I.BASE I.EAX))),
            I.MOVL (I.R I.EBP, I.M_ (I.DISP (I.INT 12, I.BASE I.EAX))),
            I.MOVL (I.R I.ESP, I.M_ (I.DISP (I.INT 8, I.BASE I.EAX))),
            I.MOVL (I.R I.EAX, I.R_ reg2),
            I.Use  [I.EAX, I.EBP, I.ESP],
            I.JMP  (I.ABS (I.R_ reg1), nil)
          ]
        end





































































































(*

  fun moveWithSize dst src size =
      case size of
        I.I_ 1 =>
        (
          case dstTy of
            BYTE =>
            let
              val reg = newReg8 ()
            in
              [ I.MOVB (I.R8 reg, I.M_8 src),
                I.MOVB (I.M8 dst, I.R_8 reg) ]
            end
          | WORD =>
            let
              val reg = newReg16 ()
            in
              [ I.XORW (I.R16 reg, I.R_16 reg),
                I.MOVB (I.RWL reg, I.M_8 src),
                I.MOVW (I.M16 dst, I.R_8 reg) ]
            end
          | LONG =>
            let
              val reg = newReg32 ()
            in
              [ I.MOVL (I.R reg, I.I_ (I.INT 0)),
                I.MOVB (I.RL reg, I.M_8 src),
                I.MOVL (I.M dst, I.R_ reg) ]
            end
          | _ => raise Control.Bug ""
        )
      | I.I_ 2 =>
        (
          case dstTy of
            WORD =>
            let
              val reg = newReg16 ()
            in
              [ I.MOVW (I.R16 reg, I.M_16 src),
                I.MOVW (I.M16 dst, I.R_16 reg) ]
            end
          | LONG =>
            let
              val reg = newReg32 ()
            in
              [ I.MOVL (I.R reg, I.I_ (I.INT 0)),
                I.MOVW (I.RW reg, I.M_16 src),
                I.MOVL (I.M dst, I.R_ reg) ]
            end
          | _ => raise Control.Bug ""
        )
      | I.I_ 4 =>
        let
          val reg = newReg32 ()
        in
          [ I.MOVL (I.R reg, I.M_ src),
            I.MOVL (I.M dst, I.R_ reg) ]
        end
      | I.I_ 8 =>
        let
          val reg1 = newReg32 ()
          val reg2 = newReg32 ()
        in
          [ I.MOVL (I.R reg1, src),
            I.MOVL (I.R reg2, I.M_ (advanceAddr (src, 4))),
            I.MOVL (I.M (I.VAR dst), I.R_ reg1),
            I.MOVL (I.M (advanceAddr (dst, 4)), I.R_ reg2) ]
        end
      | I.I_ 12 =>
        let
          val reg1 = newReg32 ()
          val reg2 = newReg32 ()
          val reg3 = newReg32 ()
        in
          [ I.MOVL (I.R reg1, src),
            I.MOVL (I.R reg2, I.M_ (advanceAddr (src, 4))),
            I.MOVL (I.M dst, I.R_ reg1),
            I.MOVL (I.R reg3, I.M_ (advanceAddr (src, 4))),
            I.MOVL (I.M (advanceAddr (dst, 4)), I.R_ reg2) ]
            I.MOVL (I.M (advanceAddr (dst, 4)), I.R_ reg3) ]
        end
      | I.I_ 16 =>
        let
          val reg1 = newReg32 ()
          val reg2 = newReg32 ()
          val reg3 = newReg32 ()
          val reg4 = newReg32 ()
        in
          [ I.MOVL (I.R reg1, I.M_ src),
            I.MOVL (I.R reg2, I.M_ (advanceAddr (src, 4))),
            I.MOVL (I.M dst, I.R_ reg1),
            I.MOVL (I.M (advanceAddr (dst, 4)), I.R_ reg2),
            I.MOVL (I.R reg3, I.M_ (advanceAddr (src, 8))),
            I.MOVL (I.R reg4, I.M_ (advanceAddr (src, 12))),
            I.MOVL (I.M (advanceAddr (dst, 8)), I.R_ reg3),
            I.MOVL (I.M (advanceAddr (dst, 12)), I.R_ reg4) ]
        end
      | I.M_ mem =>
        let
          val reg = newReg32 ()
        in
          I.MOVL (I.R reg, size) :: moveWithSize dst src (I.R_ reg)
        end
      | I.R_ sz =>
        let
          val reg1 = newReg32 ()
          val reg2 = newREg32 ()
        in
          [
            I.CMPL (I.R sz, I.I_ (I.INT 4)),
            I.J (I.B, I.LABELF 2),
            I.MOVL (I.R reg1, I.M_ src),
            I.MOVL (I.M dst, I.R_ reg1),
            I.NUMLABEL 1,
            I.CMPL (I.R sz, I.I_ (I.INT 8)),
            I.J (I.B, I.LABELF 2),
            I.MOVL (I.R reg2, I.M_ (advanceAddr (src, 4))),
            I.MOVL (I.M (advanceAddr (dst, 4)), I.R reg2),
            I.J (I.E, I.LABELF 3),
            I.NUMLABEL 2,
            AI.Call (AI.Extern "loadm"),
          ]
        end

  fun moveImm dst imm =
      case ty of
        BYTE => [ I.MOVB (I.M dst, I.I_8

        (case dstTy



 [ I.MOVB (I.
      | WORD =>
      | LONG =>
      | QUAD => raise Control.Bug "moveImm: QUAD"
      | DQUAD => raise Control.Bug "moveImm: DQUAD"
      | FLOAT => raise Control.Bug "moveImm: FLOAT"
      | DOUBLE => raise Control.Bug "moveImm: DOUBLE"
      | TRIPLE => raise Control.Bug "moveImm: TRIPLE"










  fun selectInsn context insn =
      case insn of
        AI.Move {dst, ty, value, loc, size} =>
        let
          val (ty, dst) = transformVarInfo context dst
          val value = transformValue context value
        in
          case value of
            I.M_ mem => moveWithSize (I.VAR dst, mem, sizeOf ty)
          | I.R_ reg => [ I.MOVL (I.M (I.VAR dst), I.R_ reg) ]
          | I.I_ imm =>
            case ty of
              BYTE => [ I.MOVB (I.M (I.VAR dst), value) ]
            | WORD => [ I.MOVW (I.M (I.VAR dst), value) ]
            | LONG => [ I.MOVL (I.M (I.VAR dst), value) ]
            | QUAD => raise Control.Bug "selectInsn: Move: QUAD"
            | DQUAD => raise Control.Bug "selectInsn: Move: DQUAD"
            | FLOAT => raise Control.Bug "selectInsn: Move: FLOAT"
            | DOUBLE => raise Control.Bug "selectInsn: Move: DOUBLE"
            | TRIPLE => raise Control.Bug "selectInsn: Move: TRIPLE"
        end

      | AI.Load {dst, ty, block, offset, size, loc} =>
        let
          val dst = transformVarInfo context dst
          val size = transformValue32 context size
          val mem = transformAddr context (block, offset)
        in
          moveWithSize (I.VAR dst) mem size
        end

      | AI.Update {block, offset, ty, size, value, barrier, loc} =>
        let
          val value = transformValue context value
          val ty = transformTy context ty
          val dst = transformAddrb context (block, offset)
        in
          case value of
            I.M_ mem => moveWithSize (dst, mem, size)
          | I.R_ reg => [ I.MOVL (I.M mem, I.R_ reg) ]
          | I.I_ imm =>
            case ty of
              BYTE => [ I.MOVB (I.M mem, value) ]
            | WORD => [ I.MOVW (I.M mem, value) ]
            | LONG => [ I.MOVL (I.M mem, value) ]
            | QUAD => raise Control.Bug "selectInsn: Update: QUAD"
            | DQUAD => raise Control.Bug "selectInsn: Update: DQUAD"
            | FLOAT => raise Control.Bug "selectInsn: Update: FLOAT"
            | DOUBLE => raise Control.Bug "selectInsn: Update: DOUBLE"
            | TRIPLE => raise Control.Bug "selectInsn: Update: TRIPLE"
        end

      | AI.Get {dst, ty, src, loc} =>
        let
          val src = transformArgInfo context src
          val dst = transformVarInfo context dst
          val ty = transformTy context ty
        in
          moveWithSize (dst, src, sizeOf ty)
        end

      | AI.Set {dst, ty, value, loc} =>
        let
          val value = transformValue context value
          val dst = transformArgInfo context dst
          val ty = transformTy context ty
        in
          moveWithSize (dst,







    | Alloc {dst, objectType, bitmaps, payloadSize, fieldInfo, loc} =>
    | PrimOp1 {dst, op1=(op11, ty1, ty2), arg, loc} =>
    | PrimOp2 {dst, op2=(op21, ty1, ty2, ty3), arg1, arg2, loc} =>
    | CallExt {dstVarList, callee, argList, calleeTy=(tyList, tyList1), loc} =>
    | Call {dstVarList, entry, env, argList, argTyList, resultTyList, argSizeList, loc} =>
    | TailCall {entry, env, argList, argTyList, resultTyList, argSizeList, loc} =>
    | ExportClosure {dst, entry, env, exportTy=(tyList, tyList1), loc} =>
    | Return {varList, tyList, valueSizeList, loc} =>
    | If {value1, value2, op2=(op21, ty1, ty2, ty3), thenLabel, elseLabel, loc} =>
    | Raise {exn, loc} =>
    | CheckBoundary {block, offset, passLabel, failLabel, loc} =>
    | Jump {label, knownDestinations, loc} =>
    | ChangeHandler {change, previousHandler, newHandler, loc} =>





  fun hi32 (R64 reg) =
    | hi32 (M64 mem) = mem
    | hi32 (I64 imm) = no constant

  fun lo32 (R64 reg) = hoge
    | lo32 (M64 mem) = mem
    | hi32 (I64 imm) =




  fun selectInsn context insn =
      case insn of
        AI.Move {dst, ty, value, loc, size} =>
        let
          val dst = transformVarInfo context dst
          val value = transformValue context value

          fun moveByte () =
              let
                val reg = newReg RegBClass
              in
                [
                  I.MOVB (R8 reg, rmi8 value),
                  I.MOVB (V8 dst, R8 reg)
                ]
              end
          fun moveWord () =
              let
                val reg = newReg RegWClass
              in
                [
                  I.MOVW (R8 reg, rmi8 value),
                  I.MOVW (V8 dst, R8 reg)
                ]
              end
          fun moveLong () =
              let
                val reg = newReg RegLClass
              in
                [
                  I.MOVL (R32 reg, rmi32 value),
                  I.MOVL (V32 dst, R32 reg)
                ]
              end
          fun moveQuad () =
              let
                val reg1 = newReg RegLClass
                val reg2 = newReg RegLClass
              in
                [
                  I.MOVL (R32 reg1, lolong (rmi32 value)),
                  I.MOVL (R32 reg2, hilong (rmi32 value)),
                  I.MOVL (lolong (V32 dst, R32 reg1),
                  I.MOVL (hilong (V32 dst, R32 reg2)
                ]
              end
          fun moveDQuad () =
              let
                val reg = newReg RegXMMClass
              in
                [
                  I.MOVDQA (R128 reg, rm32 value),
                  I.MOVDQA (dst, R128 reg)
                ]
              end








        in
          case #ty dst of
            LONG =>
          | FLOAT =>
            let
              val reg = newReg RegLClass
            in
              [
                I.MOVL


            [


            BYTE => [ I.MOVB (R8 reg, valueL value), I.MOVB (dst, R8 reg) ]
          | WORD => [ I.MOVW (R16 reg, valueL value), I.MOVW (dst, R16 reg) ]
          | LONG => [ I.MOVL (R32 reg, valueL value), I.MOVL (dst, R32 reg) ]
          | QUAD => moveQuad ()
          | DQUAD => moveDQuad ()
          | FLOAT => [ I.MOVL (R32 reg, valueL value), I.MOVL (dst, R32 reg) ]
          | DOUBLE => moveQuad ()
          | TRIPLE => moveDQuad ()




        AI.Move {dst, ty, value, loc, size} =>
        let
          val dst = transformVarInfo context dst
          val value = transformValue context value
          val reg = newReg ()

          fun moveQuad () =
              [ I.MOVL (R32 reg, QH (valueL value)),
                I.MOVL (QH dst, R32 reg),
                I.MOVL (R32 reg, QL (valueL value)),
                I.MOVL (QL dst, R32 reg) ]
        in
          case #ty dst of
            BYTE => [ I.MOVB (R8 reg, valueL value), I.MOVB (dst, R8 reg) ]
          | WORD => [ I.MOVW (R16 reg, valueL value), I.MOVW (dst, R16 reg) ]
          | LONG => [ I.MOVL (R32 reg, valueL value), I.MOVL (dst, R32 reg) ]
          | QUAD => moveQuad ()
          | DQUAD => moveDQuad ()
          | FLOAT => [ I.MOVL (R32 reg, valueL value), I.MOVL (dst, R32 reg) ]
          | DOUBLE => moveQuad ()
          | TRIPLE => moveDQuad ()
        end

      | AI.Load {dst, ty, block, offset, size, loc} =>
        let
          val dst = transformVarInfo context dst
          val block = transformValue context block
          val offset = transformValue context offset

          val addr =
              case (block, offset) of
                (I.VAR block, I.IMM offset) => hoge
              | (I.VAR block, I.VAR offset) =>
              | (I.IMM block, I.IMM offset) =>
              | (I.




        in
          case #ty dst of
            BYTE => [ I.MOVB (R8 reg, I.ARY (block, offset)),
                      I.MOVB (dst, R8 reg) ]
          | LONG => [ I.MOVL (R32 reg, I.ARY (block, offset)




        in
          case


          case ty of
            LONG =>
            [ I.MOVL (reg, value), I.MOVL (dst, reg) ]
          | WORD =>
            [ I.MOVW (reg, value), I.MOVW (dst, reg) ]
          | BYTE =>
            [ I.MOVB (reg, value), I.MOVB (dst, reg) ]
          | FLOAT =>
            [ I.MOVL (reg, value), I.MOVL (dst, reg) ]
          | DOUBLE =>
            [ I.MOVL (reg, value), I.MOVL (dst, reg),
              I.MOVL (reg, value), I.MOVL (dst, reg) ]
          | GENERIC =>
            [ I.MOVL (reg, value), I.MOVL (dst, reg),
              I.MOVL (reg, value), I.MOVL (dst, reg) ]






  fun selectInsn context insn =
      case insn of
        AI.Move {dst, ty, value, loc, size} =>
        let
          val (context, dst, _) = transformVarInfo context dst
          val (context, value, vmty, _) = transformValue context value
        in
          (context, makeMove dst value vmty loc)
        end

      | AI.Load {dst, ty, block, offset, size, loc} =>
        let
          val (context, dst, _) = transformVarInfo context dst
          val (context, vmty, _) = transformTy context ty
          val (context, code1, block, _) =
              bindValue loc (transformValue context block)
          val (context, code2, offset, _) =
              bindIfLabel loc (transformValue context offset)
          val (context, code3, size, _) =
              bindIfLabel loc (transformValue context size)

          val offset = transformOffset offset
          val (use, insn) =
              case (vmty, size, offset) of
                (TY ty, _, DISPLACEMENT dis) =>
                ([block], VM.LDM (ty, VM.HOLE 1, VM.HOLE 0, dis))
              | (TY ty, _, INDEXED (idx,sc)) =>
                ([block,idx], VM.LDMI (ty, VM.HOLE 2, VM.HOLE 0, VM.HOLE 1, sc))
              | (_, IMM (VM.CONST_W sz), DISPLACEMENT dis) =>
                ([block], VM.LDMX (WtoSZ sz, VM.HOLE 1, VM.HOLE 0, dis))
              | (_, IMM (VM.CONST_W sz), INDEXED (idx,sc)) =>
                ([block,idx], VM.LDMXI (WtoSZ sz, VM.HOLE 2,
                                        VM.HOLE 0, VM.HOLE 1, sc))
              | (_, VAR sz, DISPLACEMENT dis) =>
                ([block,sz], VM.LDMV (VM.HOLE 1, VM.HOLE 2, VM.HOLE 0, dis))
              | (_, VAR sz, INDEXED (idx,sc)) =>
                ([block,idx,sz], VM.LDMVI (VM.HOLE 2, VM.HOLE 3,
                                           VM.HOLE 0, VM.HOLE 1, sc))
              | _ => raise Control.Bug "selectInsn: Load: size"
        in
          (context,
           code1 @ code2 @ code3 @
           [
             M.Code {code = [insn],
                     use = use,
                     def = [dst],
                     clob = [],
                     kind = M.NORMAL,
                     loc = loc}
           ])
        end

      | AI.Update {block, offset, ty, size, value, barrier, loc} =>
        let
          val (context, vmty, _) = transformTy context ty
          val (context, code1, block, _) =
              bindValue loc (transformValue context block)
          val (context, code2, offset, _) =
              bindIfLabel loc (transformValue context offset)
          val (context, code3, size, _) =
              bindIfLabel loc (transformValue context size)
          val (context, code4, value, valueTy) =
              bindIfLabel loc (transformValue context value)

          (* FIXME: workaround for ATOMty *)
          val vmty = case ty of AI.ATOMty => valueTy | _ => vmty

          fun WBAR (base, displ) barrier =
              case barrier of
                AI.NoBarrier => (context, nil)
              | AI.WriteBarrier =>
                (context,
                 [
                   M.Code {code = [VM.WBAR (VM.HOLE 0, displ)],
                           use = [base],
                           def = [],
                           clob = [],
                           kind = M.NORMAL,
                           loc = loc}
                 ])
              | AI.BarrierTag value =>
                let
                  val (context, code1, tag, _) =
                      bindValue loc (transformValue context value)
                in
                  (context,
                   code1 @
                   [
                     M.Code {code = [VM.WBARV (VM.HOLE 0, VM.HOLE 1, displ)],
                             use = [tag, base],
                             def = [],
                             clob = [],
                             kind = M.NORMAL,
                             loc = loc}
                   ])
                end

          fun WBARI (base, index, scale) barrier =
              case barrier of
                AI.NoBarrier => (context, nil)
              | AI.WriteBarrier =>
                (context,
                 [
                   M.Code {code = [VM.WBARI (VM.HOLE 0, VM.HOLE 1, scale)],
                           use = [base, index],
                           def = [],
                           clob = [],
                           kind = M.NORMAL,
                           loc = loc}
                 ])
              | AI.BarrierTag value =>
                let
                  val (context, code1, tag, _) =
                      bindValue loc (transformValue context value)
                in
                  (context,
                   code1 @
                   [
                     M.Code {code = [
                               VM.WBARVI (VM.HOLE 0, VM.HOLE 1, VM.HOLE 2,
                                          scale)
                             ],
                             use = [tag, base, index],
                             def = [],
                             clob = [],
                             kind = M.NORMAL,
                             loc = loc}
                   ])
                end

          val offset = transformOffset offset
          val (use, insn, wbar) =
              case (value, vmty, size, offset) of
                (IMM imm, TY ty, _, DISPLACEMENT dis) =>
                ([block],
                 VM.STI (ty, VM.HOLE 0, dis, imm),
                 WBAR (block, dis))
              | (IMM imm, TY ty, _, INDEXED (v,sc)) =>
                ([block,v],
                 VM.STII (ty, VM.HOLE 0, VM.HOLE 1, sc, imm),
                 WBARI (block, v, sc))
              | (IMM _, SIZE _, _, _) =>
                raise Control.Bug "selectInsn: Update: IMM SIZE"
              | (LABEL l, _, _, _) =>
                raise Control.Bug "selectInsn: Update: LABEL"
              | (VAR v, TY ty, _, DISPLACEMENT dis) =>
                ([block,v],
                 VM.STM (ty, VM.HOLE 0, dis, VM.HOLE 1),
                 WBAR (block, dis))
              | (VAR v, TY ty, _, INDEXED (idx,sc)) =>
                ([block,idx,v],
                 VM.STMI (ty, VM.HOLE 0, VM.HOLE 1, sc, VM.HOLE 2),
                 WBARI (block, idx, sc))
              | (VAR v, SIZE _, IMM (VM.CONST_W sz), DISPLACEMENT dis) =>
                ([block,v],
                 VM.STMX (WtoSZ sz, VM.HOLE 0, dis, VM.HOLE 1),
                 WBAR (block, dis))
              | (VAR v, SIZE _, IMM (VM.CONST_W sz), INDEXED (idx,sc)) =>
                ([block,idx,v],
                 VM.STMXI (WtoSZ sz, VM.HOLE 0, VM.HOLE 1, sc, VM.HOLE 2),
                 WBARI (block, idx, sc))
              | (VAR v, SIZE _, VAR sz, DISPLACEMENT dis) =>
                ([block,sz,v],
                 VM.STMV (VM.HOLE 1, VM.HOLE 0, dis, VM.HOLE 2),
                 WBAR (block, dis))
              | (VAR v, SIZE _, VAR sz, INDEXED (idx,sc)) =>
                ([block,idx,sz,v],
                 VM.STMVI (VM.HOLE 2, VM.HOLE 0, VM.HOLE 1, sc, VM.HOLE 3),
                 WBARI (block, idx, sc))
              | _ =>
                raise Control.Bug "selectInsn: Update: size"

          val (context, code5) = wbar barrier
        in
          (context,
           code1 @ code2 @ code3 @ code4 @
           [
             M.Code {code = [insn],
                     use = use,
                     def = [],
                     clob = [],
                     kind = M.NORMAL,
                     loc = loc}
           ] @
           code5)
        end

      | AI.Alloc {dst, objectType, bitmaps, payloadSize, fieldInfo, loc} =>
        let
          val (context, dst, _) = transformVarInfo context dst
          val (context, code1, bitmaps, _) =
              bindIfLabelList loc (transformValueList context bitmaps)
          val (context, code2, payloadSize, _) =
              bindIfLabel loc (transformValue context payloadSize)

          val (objType, bittag, bitmapSize) =
              case (objectType, bitmaps) of
                (AI.Array, [bitmap]) =>
                (HEAD_TYPE_ARRAY, bitmap, 0w0)
              | (AI.Vector, [bitmap]) =>
                (HEAD_TYPE_VECTOR, bitmap, 0w0)
              | (AI.Record, _) =>
                (HEAD_TYPE_RECORD, IMM (VM.CONST_W 0w0),
                 toLSZ (Word.fromInt (length bitmaps) * wordSize))
              | (AI.Array, bitmaps) =>
                raise Control.Bug "selectInsn: Alloc: Array: multiple bitmap"
              | (AI.Vector, bitmaps) =>
                raise Control.Bug "selectInsn: Alloc: Vector: multiple bitmap"

          (*
           * FIXME: make it more general.
           *
           * Construct heap object header, and store the header to
           * specified place of the heap object.
           *
           * tmp1 = payloadSize + 3;        // (1) align payloadSize to word
           * tmp1 = tmp1 & ~3;
           * tmp2 = tmp1 + bitmapSize;      // (2) allocation size
(*
           * tmp2 = tmp1 + 4;               // (3) header size
           * tmp2 = tmp2 + 7;               // align object size to max align
           * tmp2 = tmp2 & ~7;
*)
           * dst = Alloc(tmp2);             // (4) alloc
           * tmp2 = bittag << HEAD_BITTAG_SHIFT;  // (5) construct objtype
           * tmp2 = tmp2 | objType;
           * tmp2 = tmp1 | tmp2;              // (6) construct object header
           * dst[-4] = tmp2;                  // (7) store object header
           * dst[tmp1] = bitmap[0];           // (8) setup bitmaps
           * ..
           * dst[tmp1+4n] = bitmap[n];
           *)

          val (bitmapOffset, code1) =
              case payloadSize of
                IMM (VM.CONST_W size) =>
                let
                  (* (1) align payloadSize to word *)
                  val tmp1 = size + padSize (size, wordSize)
                  (* (2) allocation size *)
                  val tmp2 = tmp1 + bitmapSize
(*
                  (* (3) header size + align object size to max align *)
                  val tmp2 = tmp2 + toLSZ wordSize
                  val tmp2 = tmp2 + padSize (tmp2, maxAlign)
*)
                in
                  (IMM (VM.CONST_W tmp1),
                   [
                     (* (4) alloc *)
                     M.Code {code = [ VM.ALLOCX (VM.HOLE 0, tmp2) ],
                             use = [],
                             def = [dst],
                             clob = [],
                             kind = M.NORMAL,
                             loc = loc}
                   ])
                end
              | VAR payloadSizeVar =>
                let
                  val allocSizeVar = newVar (M.VAR unboxedSingleClass)
                  val bitmapOffsetVar = newVar (M.VAR unboxedSingleClass)
                  val wordSize = toW wordSize
                  val maxAlign = toW maxAlign
                in
                  (VAR bitmapOffsetVar,
                   [
                     M.Code
                       {code = [
                          (* (1) align payloadSize to word *)
                          VM.ADDI  (VM.W, VM.HOLE 1, VM.HOLE 0,
                                    VM.CONST_W (wordSize - 0w1)),
                          VM.ANDI  (VM.W, VM.HOLE 1, VM.HOLE 1,
                                    VM.CONST_W (notb (wordSize - 0w1)))
                        ],
                        use = [payloadSizeVar],
                        def = [bitmapOffsetVar],
                        clob = [],
                        kind = M.NORMAL,
                        loc = loc},
                     M.Code
                       {code = [
                          (* (2) allocation size *)
                          VM.ADDI  (VM.W, VM.HOLE 1, VM.HOLE 0,
                                    VM.CONST_W (bitmapSize
(*
                                                (* (3) header size *)
                                                + wordSize
                                                + (maxAlign - 0w1)
 *)
                                                ))
(*
                          VM.ANDI  (VM.W, VM.HOLE 1, VM.HOLE 1,
                                    VM.CONST_W (notb (maxAlign - 0w1)))
*)
                        ],
                        use = [bitmapOffsetVar],
                        def = [allocSizeVar],
                        clob = [],
                        kind = M.NORMAL,
                        loc = loc},
                      M.Code
                        {code = [
                           (* (4) alloc *)
                           VM.ALLOC (VM.HOLE 1, VM.HOLE 0)
                         ],
                         use = [allocSizeVar],
                         def = [dst],
                         clob = [],
                         kind = M.NORMAL,
                         loc = loc}
                   ])
                end
              | _ => raise Control.Bug "selectInsn: Alloc: payloadSize"

          val (objType, code2) =
              case bittag of
                IMM (VM.CONST_W bit) =>
                let
                  (* (5) construct objtype *)
                  val objType = (bit << HEAD_BITTAG_SHIFT) || objType
                in
                  (IMM (VM.CONST_W objType), nil)
                end
              | VAR bitVar =>
                (VAR bitVar,
                 [
                   (* (5) construct objtype *)
                   M.Code {code = [
                             VM.SHLI (VM.W, VM.HOLE 1, VM.HOLE 0,
                                      HEAD_BITTAG_SHIFT),
                             VM.ORI  (VM.W, VM.HOLE 1, VM.HOLE 1,
                                      VM.CONST_W objType)
                           ],
                           use = [bitVar],
                           def = [bitVar],
                           clob = [],
                           kind = M.NORMAL,
                           loc = loc}
                 ])
              | _ => raise Control.Bug "selectInsn: Alloc: b1"

          val (header, code3) =
              case (bitmapOffset, objType) of
                (IMM (VM.CONST_W offset), IMM (VM.CONST_W ty)) =>
                (* (6) construct object header *)
                (IMM (VM.CONST_W (offset || ty)), nil)
              | (IMM offset, VAR objTypeVar) =>
                (VAR objTypeVar,
                 [
                   M.Code {code = [
                             (* (6) construct object header *)
                             VM.ORI (VM.W, VM.HOLE 1, VM.HOLE 0, offset)
                           ],
                           use = [objTypeVar],
                           def = [objTypeVar],
                           clob = [],
                           kind = M.NORMAL,
                           loc = loc}
                 ])
              | (VAR offsetVar, IMM objType) =>
                let
                  val var = newVar (M.VAR unboxedSingleClass)
                in
                  (VAR var,
                   [
                     M.Code {code = [
                               (* (6) construct object header *)
                               VM.ORI (VM.W, VM.HOLE 1, VM.HOLE 0, objType)
                             ],
                             use = [offsetVar],
                             def = [var],
                             clob = [],
                             kind = M.NORMAL,
                             loc = loc}
                   ])
                end
              | (VAR offsetVar, VAR objTypeVar) =>
                (VAR objTypeVar,
                 [
                   M.Code {code = [
                             (* (6) construct object header *)
                             VM.OR (VM.W, VM.HOLE 2, VM.HOLE 0, VM.HOLE 1)
                           ],
                           use = [offsetVar, objTypeVar],
                           def = [objTypeVar],
                           clob = [],
                           kind = M.NORMAL,
                           loc = loc}
                 ])
              | _ => raise Control.Bug "selectInsn: Alloc: offset * ty"

          val code4 =
              case header of
                IMM head =>
                [
                  M.Code {code = [
                            (* (7) store object header *)
                            VM.STI (VM.W, VM.HOLE 0, ~(toSSZ wordSize), head)
                          ],
                          use = [dst],
                          def = [],
                          clob = [],
                          kind = M.NORMAL,
                          loc = loc}
                ]
              | VAR headVar =>
                [
                  M.Code {code = [
                            (* (7) store object header *)
                            VM.STM (VM.W, VM.HOLE 0, ~(toSSZ wordSize),
                                    VM.HOLE 1)
                          ],
                          use = [dst, headVar],
                          def = [],
                          clob = [],
                          kind = M.NORMAL,
                          loc = loc}
                ]
              | _ => raise Control.Bug "selectInsn: Alloc: header"

          val code5 =
              case objectType of
                AI.Record =>
                let
                  (* (8) setup bitmaps *)
                  val (bitmapBase, offset, leaCode) =
                      case bitmapOffset of
                        VAR offset =>
                        let
                          val v = newVar (M.VAR pointerClass)
                        in
                          (v, 0w0,
                           [M.Code {code = [
                                      VM.LEAI (VM.HOLE 2,
                                               VM.HOLE 0, VM.HOLE 1, 0w1)
                                    ],
                                    use = [dst, offset],
                                    def = [v],
                                    clob = [],
                                    kind = M.NORMAL,
                                    loc = loc}])
                        end
                      | IMM (VM.CONST_W x) => (dst, x, nil)
                      | _ => raise Control.Bug "selectinsn: Alloc: bitmapOffset"

                  val use = bitmapBase :: takeVAR bitmaps

                  fun st i n bitmap =
                      case bitmap of
                        IMM bitmap =>
                        (VM.STI (VM.W, VM.HOLE 0, WtoSSZ (offset+i), bitmap),
                         n)
                      | VAR bitmap =>
                        (VM.STM (VM.W, VM.HOLE 0, WtoSSZ (offset+i), VM.HOLE n),
                         n + 1)
                      | _ => raise Control.Bug "selectInsn: Alloc: st"

                  fun store i n nil = nil
                    | store i n (bitmap::bitmaps) =
                      let
                        val (insn, n) = st i n bitmap
                      in
                        insn :: store (i + toLSZ wordSize) n bitmaps
                      end
                in
                  leaCode @
                  [
                    M.Code {code = store 0w0 1 bitmaps,
                            use = use,
                            def = [],
                            clob = [],
                            kind = M.NORMAL,
                            loc = loc}
                  ]
                end

              | _ => nil
        in
          (context, code1 @ code2 @ code3 @ code4 @ code5)
        end

      | AI.PrimOp1 {dst, op1, arg, loc} =>
        let
          val (context, dst, dstTy) = transformVarInfo context dst
          val (context, code1, arg, argTy) =
              bindValue loc (transformValue context arg)
          val (context, code2) =
              selectOp1 context op1 (dst, dstTy) (arg, argTy) loc
        in
          (context, code1 @ code2)
        end

      | AI.PrimOp2 {dst, op2, arg1, arg2, loc} =>
        let
          val (context, dst, dstTy) = transformVarInfo context dst
          val (context, value1, vmty1, mty1) = transformValue context arg1
          val (context, value2, vmty2, mty2) = transformValue context arg2
          val (context, code1, value1, _) =
              bindIfLabel loc (context, value1, vmty1, mty1)
          val (context, code2, value2, _) =
              bindIfLabel loc (context, value2, vmty2, mty2)

          val (context, code3) =
              selectOp2 context op2 (dst, dstTy)
                        (value1, vmty1, mty1) (value2, vmty2, mty2) loc
        in
          (context, code1 @ code2 @ code3)
        end

      | AI.CallExt {dstVarList, callee, argList, calleeTy, loc} =>
        let
          val (context, dsts, dstTys) = transformVarInfoList context dstVarList
          val (context, code1, args, argTys) =
              bindValueList loc (transformValueList context argList)

          val (context, code2) =
              case callee of
                AI.Foreign {function, convention} =>
                callForeign (transformValue context function)
                            {calleeTy = calleeTy,
                             convention = convention,
                             argVars = args,
                             argTys = argTys,
                             retVars = dsts,
                             retTys = dstTys,
                             loc = loc}
              | AI.Primitive {name, builtin=false, ...} =>
                callPrim context
                         {primName = name,
                          calleeTy = calleeTy,
                          argVars = args,
                          argTys = argTys,
                          retVars = dsts,
                          retTys = dstTys,
                          loc = loc}
              | AI.Primitive {name, builtin=true, ...} =>
                callBuiltin context
                            {primName = name,
                             argVars = args,
                             argTys = argTys,
                             retVars = dsts,
                             retTys = dstTys,
                             loc = loc}
        in
          (context, code1 @ code2)
        end

      | AI.ExportClosure {dst, entry, env, exportTy=(argTy, retTy), loc} =>
        let
          val (context, dst, _) = transformVarInfo context dst
          val (context, code1, entry, _) =
              bindValue loc (transformValue context entry)
          val (context, code2, env, _) =
              bindValue loc (transformValue context env)

          val (context, ffty) =
              addFFType context AS.CC_DEFAULT (argTy, retTy)
        in
          (context,
           code1 @ code2 @
           [
             M.Code
               {code = [ VM.FFEXPORT (ffty, VM.HOLE 2, VM.HOLE 0, VM.HOLE 1) ],
                use = [entry, env],
                def = [dst],
                clob = [],
                kind = M.NORMAL,
                loc = loc}
           ])
        end

      | AI.Call {dstVarList, entry, env, argList, argTyList, argSizeList,
                 resultTyList, loc} =>
        let
          val (context, dsts, dstTys) = transformVarInfoList context dstVarList
          val (context, argList, argTyList, argMTyList) =
              transformValueList context argList
          val (context, code1, argList, argTys) =
              bindValueList loc (context, argList, argTyList, argMTyList)
          val (context, code3, env, _) =
              bindFresh loc (M.ALLOCED envReg) (transformValue context env)
          val (context, code2, entry, _) =
              bindIfNotLabel loc (transformValue context entry)

          val (code4, use) = passArgs argList argTys loc

          val linkVar = newVar (M.ALLOCED linkReg)
          val use = linkVar :: env :: use
          val saves = callerSaveVars use

          val (code5, def) = receiveArgs dsts dstTys loc
        in
          (context,
           code1 @ code2 @ code3 @ code4 @
           [
             M.Code {code = [ VM.MVFIP (VM.HOLE 0, VM.LOCALLABELREF 1) ],
                     use = [],
                     def = [linkVar],
                     clob = [],
                     kind = M.NORMAL,
                     loc = loc},
             case entry of
               LABEL label =>
               M.Code {code = [ VM.BR label, VM.LocalLabel ],
                       use = use,
                       def = def,
                       clob = saves,
                       kind = M.NORMAL,
                       loc = loc}
             | VAR var =>
               M.Code {code = [ VM.BRI (VM.HOLE 0), VM.LocalLabel ],
                       use = var :: use,
                       def = def,
                       clob = saves,
                       kind = M.NORMAL,
                       loc = loc}
             | _ => raise Control.Bug "selectInsn: Call: entry"
           ] @
           code5)
        end

      | AI.TailCall {entry, env, argList, argTyList, argSizeList,
                     resultTyList, loc} =>
        let
          val (context, code1, argList, argTys) =
              bindValueList loc (transformValueList context argList)
          val (context, code3, env, _) =
              bindFresh loc (M.ALLOCED envReg) (transformValue context env)
          val (context, code2, entry, _) =
              bindIfNotLabel loc (transformValue context entry)

          val (code4, use1) = passArgs argList argTys loc
          val (epilogueCode, use2) = epilogue context loc
          val use = use2 @ use1
        in
          (context,
           code1 @ code2 @ code3 @ code4 @
           (case entry of
              LABEL label =>
              epilogueCode @
              [
                M.Code {code = [ VM.BR label ],
                        use = use,
                        def = [],
                        clob = [],
                        kind = M.NORMAL,
                        loc = loc}
              ]
            | VAR var =>
              let
                val entryVar = newVar (M.ALLOCED tailcallReg)
              in
                copyVars [entryVar] [var] [TY VM.P] loc @
                epilogueCode @
                [
                  M.Code {code = [ VM.BRI (VM.HOLE 0) ],
                          use = entryVar :: use,
                          def = [],
                          clob = [],
                          kind = M.NORMAL,
                          loc = loc}
                ]
              end
            | _ => raise Control.Bug "selectInsn: TailCall: entry"))
        end

      | AI.Return {valueList, tyList, valueSizeList, loc} =>
        let
          val (context, code1, valueList, valueTys) =
              bindValueList loc (transformValueList context valueList)

          val (code2, use1) = passArgs valueList valueTys loc
          val (code3, use2) = epilogue context loc
        in
          (context,
           code1 @ code2 @ code3 @
           [
             M.Code {code = [ VM.BRI (VM.HOLE 0) ],
                     use = use2 @ use1,
                     def = [],
                     clob = [],
                     kind = M.NORMAL,
                     loc = loc}
           ])
        end

      | AI.If {value1, value2, op2, thenLabel, elseLabel, loc} =>
        let
          val (context, value1, vmty1, mty1) = transformValue context value1
          val (context, value2, vmty2, mty2) = transformValue context value2
          val (context, code1, value1, _) =
              bindIfLabel loc (context, value1, vmty1, mty1)
          val (context, code2, value2, _) =
              bindIfLabel loc (context, value2, vmty2, mty2)

          val (context, code3, jumpLabel, continueLabel) =
              selectBranchOp2 context op2
                              (value1, vmty1, mty1) (value2, vmty2, mty2)
                              thenLabel elseLabel
                              loc

          val context = setContinue context continueLabel
          val context = addJump context [thenLabel]
        in
          (context, code1 @ code2 @ code3)
        end

      | AI.Raise {exn, loc} =>
      let
        val (context, code1, exnVar, _) =
            bindFresh loc (M.ALLOCED exnReg) (transformValue context exn)
      in
        (context,
         code1 @
         [
           M.Code {code = [ VM.RAISE ],
                   use = [exnVar],
                   def = [],
                   clob = [],
                   kind = M.NORMAL,
                   loc = loc}
         ])
      end
(*
          case #currentHandler context of
            AI.StaticHandler handlerLabel =>
            (setContinue context handlerLabel,
             [
               M.Code {code = [ VM.MOV (VM.P, VM.HOLE 1, VM.HOLE 0) ],
                       use = [exn],
                       def = [#exnVar context],
                       clob = [],
                       kind = M.MOVE,
                       loc = loc},
               M.Code {code = [ VM.BR (LabelRef handlerLabel) ],
                       use = [#exnVar context],
                       def = [],
                       clob = [],
                       kind = M.NORMAL,
                       loc = loc}
             ])

          | AI.DynamicHandler {handlers, outside = false, ...} =>
            (addJump context handlers,
             [
               M.Code {code = [ VM.MOV (VM.P, VM.HOLE 1, VM.HOLE 0) ],
                       use = [exn],
                       def = [#exnVar context],
                       clob = [],
                       kind = M.MOVE,
                       loc = loc},
               M.Code {code = [ VM.BRI (VM.HOLE 0) ],
                       use = [#handlerVar context],
                       def = [],
                       clob = [],
                       kind = M.NORMAL,
                       loc = loc}
             ])

          | handler =>
            let
              val context =
                  case handler of
                    AI.DynamicHandler {handlers, ...} =>
                    addJump context handlers
                  | _ => context
            in
              (context,
               [
                 M.Code {code = [ VM.MOV (VM.P, VM.HOLE 1, VM.HOLE 0) ],
                         use = [exn],
                         def = [#exnVar context],
                         clob = [],
                         kind = M.MOVE,
                         loc = loc},
                 M.Code {code = [ VM.UNWIND,
                                  VM.BRI (VM.HOLE 0) ],
                         use = [#handlerVar context],
                         def = [],
                         clob = [],
                         kind = M.NORMAL,
                         loc = loc}
               ])
            end
*)

      | AI.CheckBoundary {block, offset, passLabel, failLabel, loc} =>
        let
          val (context, code1, block, _) =
              bindValue loc (transformValue context block)
          val (context, code2, offset, _) =
              bindIfLabel loc (transformValue context offset)

          val lenVar = newVar (M.VAR unboxedSingleClass)

          val context = setContinue context passLabel
          val context = addJump context [failLabel]
        in
          (context,
           code1 @ code2 @
           getArrayLength block lenVar loc @
           [case offset of
              IMM imm =>
              M.Code
                {code = [
                   (* if (len <= offset) then ERROR else OK *)
                   VM.BRCILE (VM.W, VM.HOLE 0, imm, LabelRef failLabel)
                 ],
                 use = [lenVar],
                 def = [],
                 clob = [],
                 kind = M.NORMAL,
                 loc = loc}
            | VAR offsetVar =>
              M.Code
                {code = [
                   (* if (len <= offset) then ERROR else OK *)
                   VM.BRCLE (VM.W, VM.HOLE 0, VM.HOLE 1, LabelRef failLabel)
                 ],
                 use = [lenVar, offsetVar],
                 def = [],
                 clob = [],
                 kind = M.NORMAL,
                 loc = loc}
            | _ => raise Control.Bug "selectInsn: CheckBoundary: offset"])
        end

      | AI.Jump {label, knownDestinations = [dest], loc} =>
        (setContinue context dest, nil)

      | AI.Jump {label, knownDestinations, loc} =>
        let
          val (context, code1, dest, _) =
              bindValue loc (transformValue context label)
        in
          (addJump context knownDestinations,
           [
             M.Code {code = [ VM.BRI (VM.HOLE 0) ],
                     use = [dest],
                     def = [],
                     clob = [],
                     kind = M.NORMAL,
                     loc = loc}
           ])
        end

  and selectInsnList context (insn::insnList) =
      let
        val (context, code) = selectInsn context insn
        val (context, codes) = selectInsnList context insnList
      in
        (context, code @ codes)
      end
    | selectInsnList context nil = (context, nil)

(*
  fun setHandlerCode context handler loc =
      case handler of
        AI.NoHandler =>
        (context,
         [
           M.Code {code = [ VM.MVTHR (VM.HOLE 0) ],
                  use = [#savedUnwindVar context],
                  def = [],
                  clob = allRegisters,
                  kind = M.NORMAL,
                  loc = loc}
         ])
      | AI.StaticHandler label =>
        (context,
         [
           M.Code {code = [ VM.MVFIP (VM.HOLE 1, LabelRef label) ],
                   use = [],
                   def = [#handlerVar context],
                   clob = [],
                   kind = M.NORMAL,
                   loc = loc}
         ])
      | AI.DynamicHandler {current, ...} =>
        let
          val (context, currentVar, _) =
              transformVarInfo context current
        in
          (context,
           [
             M.Code {code = [ VM.MOV (VM.P, VM.HOLE 1, VM.HOLE 0) ],
                     use = [currentVar],
                     def = [#handlerVar context],
                     clob = [],
                     kind = M.NORMAL,
                     loc = loc}
           ])
        end
*)






  fun selectBlock context
                  ({label, blockKind, handler, instructionList, loc}
                   :AI.basicBlock) =
      let
        val context = startBlock context handler

        val (context, prologueCode) =
            case blockKind of
              AI.FunEntry params =>
              prologue context params loc

            | AI.Handler exnParam =>
              let
                val (context, exnVar, _) = transformVarInfo context exnParam
              in
                (context,
                 [
                   M.Code {code = [],
                           use = [],
                           def = [#exnVar context],
                           clob = [],
                           kind = M.NORMAL,
                           loc = loc}
                 ] @
                 (* save exception object *)
                 [
                   M.Code {code = [ VM.MOV (VM.P, VM.HOLE 1, VM.HOLE 0) ],
                           use = [#exnVar context],
                           def = [exnVar],
                           clob = [],
                           kind = M.MOVE,
                           loc = loc}
                 ])
              end
(*
              let
                val (context, exnVar, _) = transformVarInfo context exnParam
                val (context, code1) = setHandlerCode context handler loc
              in
                (context,
                 [
                   M.Code {code = [],
                           use = [],
                           def = [#exnVar context],
                           clob = [],
                           kind = M.NORMAL,
                           loc = loc}
                 ] @
                 (* enable current exception handler *)
                 code1 @
                 (* save exception object *)
                 [
                   M.Code {code = [ VM.MOV (VM.P, VM.HOLE 1, VM.HOLE 0) ],
                           use = [#exnVar context],
                           def = [exnVar],
                           clob = [],
                           kind = M.MOVE,
                           loc = loc}
                 ])
              end
*)

            | AI.ChangeHandler {change = SOME (AI.PushHandler _), ...} =>
              let
                val handlerLabel =
                    case handler of
                      AI.StaticHandler label => label
                    | _ => raise Control.Bug "selectBlock: PushHandler"
                val var = newVar (M.VAR pointerClass)
              in
                (addJump context [handlerLabel],
                 (* enable new handler and spill all registers *)
                 [
                   M.Code {code = [ VM.PUSHTRAP (LabelRef handlerLabel) ],
                           use = [],
                           def = [],
                           clob = allRegisters,
                           kind = M.NORMAL,
                           loc = loc}
                 ])
              end
(*
               case handler of
                 AI.NoHandler =>
                 [
                   M.Code {code = [ VM.MVFIP (VM.HOLE 0, LabelRef newHandler),
                                    VM.MVFHR (VM.HOLE 0),
                                    VM.CATCH ],
                           use = [],
                           def = [#handlerVar context,
                                  #savedUnwindVar context],
                           clob = allRegisters,
                           kind = M.NORMAL,
                           loc = loc}
                 ]
               | _ =>
                 [
                   M.Code {code = [ VM.MVFIP (VM.HOLE 0, LabelRef newHandler) ],
                           use = [],
                           def = [#handlerVar context],
                           clob = allRegisters,
                           kind = M.NORMAL,
                           loc = loc}
                 ])
*)

            | AI.ChangeHandler {change = SOME (AI.PopHandler _), ...} =>
              let
                val var = newVar (M.VAR pointerClass)
              in
                (context,
                 [
                   M.Code {code = [ VM.POPTRAP ],
                           use = [],
                           def = [var],
                           clob = [],
                           kind = M.NORMAL,
                           loc = loc}
                 ])
              end
(*
              (* resume previously available handler *)
              setHandlerCode context handler loc
*)

            | _ => (context, nil)

        val (context, bodyCode) = selectInsnList context instructionList
      in
        (context,
         {
           label = label,
           instructionList = prologueCode @ bodyCode,
           continue = #continue context,
           jump = #jump context,
           loc = loc
         } : VM.instruction list M.basicBlock)
      end

  fun selectBlockList context (block::blockList) =
      let
        val (context, block) = selectBlock context block
        val (context, blocks) = selectBlockList context blockList
      in
        (context, block :: blocks)
      end
    | selectBlockList context nil = (context, nil)

  fun selectCluster (context:context) ({name, body, loc}:AI.cluster) =
      let
        val entries =
            foldr
              (fn ({label, blockKind = AI.FunEntry _, ...}, z) => label::z
                | (_, z) => z)
              nil
              body

        val tagArgMap =
            foldl
              (fn ({blockKind = AI.FunEntry params, loc, ...}, map) =>
                  LocalVarID.Map.unionWith
                      (fn _ =>
                          raise Control.Bug "selectCluster: doubled parameter")
                      (map, makeTagArgMap params)
                | (_, z) => z)
              LocalVarID.Map.empty
              body

        val context = startCluster context tagArgMap
        val (context, body) = selectBlockList context body
      in
        (context,
         {
           name = name,
           entries = entries,
           registerDesc = #registerDesc context,
           frameInfo = M.dummyFrameInfo,
           body = body,
           alignment = maxAlign,
           loc = loc
         } : VM.instruction list M.cluster)
      end

  fun selectClusterList context (cluster::clusterList) =
      let
        val (context, cluster) = selectCluster context cluster
        val (context, clusters) = selectClusterList context clusterList
      in
        (context, cluster::clusters)
      end
    | selectClusterList context nil = (context, nil)

  fun makePad padsize =
      List.tabulate (LSZtoInt padsize, fn _ => VM.CONST_B 0w0)

  fun transformConst context const =
      case const of
        AI.ConstString str =>
        let
          (*
           * FIXME: Now this workaround is not needed.
           *
           * |<----------- multiple of words ------------->|
           * [head] [word1] [word2] ... [wordN] [tail] [pad]
           *
           * tail:
           *   c1 c2 c3 c4  -> c1 c2 c3 c4 00 00 00 04
           *   c1 c2 c3 00  -> c1 c2 c3 00 00 00 00 05
           *   c1 c2 00 00  -> c1 c2 00 02
           *   c1 00 00 00  -> c1 00 00 03
           *
           * payloadSize = wordSize * N + tail size
           * object type = VECTOR
           *)
          fun toW8 c = Word8.fromInt (ord c)

          val sz = toLSZ (Word.fromInt (size str))
          val pad = padSize (sz, wordSize)
          val pad = if pad <= 0w1 then pad + toLSZ wordSize else pad
          val payloadSize = sz + pad

          val objpad = padSize (payloadSize + toLSZ wordSize, maxAlign)
          val header = payloadSize || HEAD_TYPE_UNBOXED_VECTOR
        in
          (VM.CONST_W header,
           [
             VM.ConstString str,
             VM.Const
                 (makePad (pad - 0w1) @
                  [ VM.CONST_B (Word8.fromInt (LSZtoInt pad)) ] @
                  makePad objpad)
            ])
        end

      | AI.ConstReal r =>
        let
          (*
           * |<- multiple of maxAlign ->|
           * [head] [word1] [word2] [pad]
           *
           * payloadSize = realSize
           * object type = VECTOR
           *)
          val objpad = padSize (toLSZ (wordSize + realSize), maxAlign)
          val header = toLSZ realSize || HEAD_TYPE_UNBOXED_VECTOR
        in
          (VM.CONST_W header, [ VM.Const (VM.CONST_F r :: makePad objpad) ])
        end

      | AI.ConstIntInf n =>
        (*
         * FIXME: format of IntInf
         *)
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
          transformConst context (AI.ConstString s)
        end

      | AI.ConstObject {objectType, bitmaps, payloadSize, fields} =>
        let
          val (objType, bitmaps) =
              case (objectType, bitmaps) of
                (AI.Array, [0w0]) => (HEAD_TYPE_UNBOXED_ARRAY, nil)
              | (AI.Array, [0w1]) => (HEAD_TYPE_BOXED_ARRAY, nil)
              | (AI.Array, _) => raise Control.Bug "transformConst: Array"
              | (AI.Vector, [0w0]) => (HEAD_TYPE_UNBOXED_VECTOR, nil)
              | (AI.Vector, [0w1]) => (HEAD_TYPE_BOXED_VECTOR, nil)
              | (AI.Vector, _) => raise Control.Bug "transformConst: Vector"
              | (AI.Record, _) => (HEAD_TYPE_RECORD, bitmaps)

          val header = payloadSize || objType
          val bitmapPad = padSize (payloadSize, wordSize)

          val totalSize =
              payloadSize + bitmapPad
              + toLSZ (wordSize * Word.fromInt (length bitmaps))
          val objpad = padSize (totalSize, maxAlign)

          val consts =
              foldr
                (fn ({size, value}, consts) =>
                    let
                      val (_, value, _, mty) = transformValue context value
                      val imm =
                          case value of
                            IMM imm => imm
                          | _ => raise Control.Bug "transformConst: Object"
                      val class = classOf mty
                      val valueSize =
                          toLSZ (#size (getRegisterDesc context class))

                      val _ =
                          if valueSize <= size then ()
                          else
                            raise Control.Bug "transformConst: field too small"
                      val pad = size - valueSize
                    in
                      List.tabulate (LSZtoInt pad, fn _ => VM.CONST_B 0w0) @
                      (imm :: consts)
                    end)
                nil
                fields
        in
          (VM.CONST_W header,
           [VM.Const (consts @
                      makePad bitmapPad @
                      map VM.CONST_W bitmaps @
                      makePad objpad)])
        end

  fun transformConstants context constants =
      let
        val constants =
            LocalVarID.Map.foldli
                (fn (label, const, z) =>
                    let
                      val (header, content) = transformConst context const
                    in
                      VM.Const [header] ::
                      VM.Label (constLabelString label) ::
                      content @ z
                    end)
                nil
                constants
      in
        case constants of
          nil => context
        | _::_ =>
          addConst context
                   (* prepend padding to align constant object pointers *)
                   (VM.Const (makePad (toLSZ (maxAlign - wordSize)))
                    :: constants)
      end

  fun transformGlobals context globals =
      let
        fun align offset alignment ((label, sz)::t) =
            let
              val alignment = Word.max (alignment, sz)
              val pad = Word.fromInt (LSZtoInt (padSize (toLSZ offset, sz)))
              val offset = offset + pad
              val {size, slots, alignment} = align (offset + sz) alignment t
            in
              {size = size,
               slots = {label = label, offset = offset} :: slots,
               alignment = alignment}
            end
          | align offset alignment nil =
            {size = offset, slots = nil, alignment = alignment}

        val (boxed, unboxed) =
            SEnv.foldri
              (fn (label, ty, (boxed, unboxed)) =>
                  case AbstractInstructionUtils.tagOf ty of
                    AI.Boxed   => ((label, sizeOf context ty) :: boxed, unboxed)
                  | AI.Unboxed => (boxed, (label, sizeOf context ty) :: unboxed)
                  | _ => raise Control.Bug "transformGlobals")
              (nil, nil)
              globals
      in
        {
          boxedGlobals = align 0w0 0w1 boxed,
          unboxedGlobals = align 0w0 0w1 unboxed
        }
      end

  fun select stamp ({clusters, constants, globals}:AI.program) =
      let
        val _ = Counters.init stamp

        (* first entry of first cluster is the toplevel entry *)
        val mainEntry =
            labelString
              (List.hd
                 (List.mapPartial
                    (fn {label, blockKind = AI.FunEntry _, ...} => SOME label
                      | _ => NONE)
                    (#body (List.hd clusters))))
            handle Empty => raise Control.Bug "select: mainEntry"

        val context =
            {
              registerDesc = initialRegisterDesc,
              tagArgMap = LocalVarID.Map.empty,
              calleeSaveVars = calleeSaveVars (),
              savedUnwindVar = newVar (M.VAR pointerClass),
              savedLinkVar = newVar (M.VAR pointerClass),
              savedEnvVar = newVar (M.VAR boxedClass),
              handlerVar = newVar (M.ALLOCED (M.HANDLER pointerClass)),
              exnVar = newVar (M.ALLOCED exnReg),
              constants = nil,
              currentHandler = AI.NoHandler,   (* dummy *)
              continue = NONE,
              jump = nil
            } : context

        val context =
            transformConstants context constants

        val (context, clusters) = selectClusterList context clusters

        val {unboxedGlobals, boxedGlobals} =
            transformGlobals context globals

        val program =
            {
              toplevel =
                {
                  code = [[ VM.Const [VM.EXTERN (VM.INTERNALREF mainEntry)] ]],
                  alignment = #align pointerClassDesc
                },
              clusters = clusters,
              constants = {code = #constants context, alignment = maxAlign},
              unboxedGlobals = unboxedGlobals,
              boxedGlobals = boxedGlobals
            } : VM.instruction list M.program
      in
          (Counters.getCounterStamp(), program)
      end
*)

  fun selectBlock (context:context)
                  ({label, blockKind, handler, instructionList, loc}
                   :AI.basicBlock) =
      let
(*
        fun defParams args =
            map (fn x => case transformArgInfo x of
                           IARG rm => rm
                         | _ => raise Control.Bug "selectBlock")
                args

        val prologueCode =
            case blockKind of
              AI.FunEntry params =>
              [
                (* labels following a call should be 16-byte-aligned
                 * when less than 8 bytes away from a 16 byte boundary. *)
                (* ToDo: loop entry labels should be 16-byte-aligned
                 * when less than 8 bytes away from a 16 byte boundary. *)
                (* ToDo: labels following an uncoditional branch should be
                 * 16-byte-aligned when less than 8 bytes away from a
                 * 16-byte boundary. *)
                I.Align {align = 4, filler = 0wx90},
                (* I.EntryLabel (funLabel label), *)
                I.Label (funLabel label),
                I.Def  (defParams params),
                I.Prologue nil,
                I.GlobalOffsetBase
              ]
            | AI.Handler arg =>
              [
                I.Label (localLabel label),
                I.Def  (defParams [arg]),
                (* Since all registers are broken here, we need to
                 * calculate global offset again. *)
                I.GlobalOffsetBase
              ]
            | _ =>
              [
                I.Label (localLabel label)
              ]
*)
        val bodyCode = map (selectInsn context) instructionList
      in
        List.concat bodyCode
(*
        prologueCode :: bodyCode
(*
        {
          label = label,
          instructionList = List.concat (prologueCode :: bodyCode),
          loc = loc
        } : basicBlock
*)
*)
      end

  fun transformFrameBitmap ({source, bits}:AI.frameBitmap) =
      let
        val source =
            case source of
              AI.EnvBitmap (_, offset) =>
              F.MEM (I.DISP (I.WORD (BasicTypes.WordToUInt32 offset),
                             I.BASE I.EAX))
            | AI.BitParam {id, ty, argKind} =>
              case transformArgKind argKind of
                IARG (I.M mem) => F.MEM mem
              | IARG (I.R mem) => F.REG mem
              | _ => raise Control.Bug "transformFrameBitmap"
      in
        {source = source, bits = bits} : I.frameBitmap
      end

  (*
   * How to get current instruction pointer?
   *
   * (1)     call  L1
   *     L1: popl  %eax
   *
   * (2)     call  get_pc_chunk
   *
   *     get_pc_chunk:
   *         movl  (%esp), %ebx
   *         ret
   *
   * (2) is twice faster than (1) on CoreDuo.      (1) 6.4sec  (2) 3.2sec
   * (1) is slightly faster than (2) on Core2Duo.  (1) 2.1sec  (2) 2.5sec
   *)
  (*
   * There must be just one global offset base for each cluster.
   *
   * Currently we put one global offset base for each cluster.
   * We may share the global offset base among clusters in the same
   * compilation unit, but that is one of optimiazations.
   *)
  fun makeGlobalOffsetComputation (context:context) numEntries =
      case !(#globalOffsetBase context) of
        NONE => (nil, nil)
      | SOME {offsetBaseLabel, offsetBaseVar} =>
        let
          val label = newLabel ()
          val reg = newReg32 ()

          val offsetBaseCode =
              [
                I.CALL (I.REL (I.LABEL label)),
                I.Def  [reg],
                I.Use  [reg],
                I.Label offsetBaseLabel
              ]
          val offsetBaseRoutine =
              [
                I.Align {align = 4, filler = 0wx90},
                I.Label label,
                I.MOVL (I.R reg, I.M_ (I.BASE I.ESP)),
                I.MOVL (I.M (I.VAR offsetBaseVar), I.R_ reg),
                I.RET NONE
              ]
        (*
          val (offsetBaseCode, offsetBaseRoutine) =
              ([
                 I.CALL offsetBaseLabel,
                 I.Label offsetBaseLabel,
                 I.POPL (I.R offsetBaseReg)
               ],
               nil)
         *)
        in
          if numEntries = 1
          then (offsetBaseCode, offsetBaseRoutine)
          else
            let
              val label = newLabel ()
              val offsetBaseCode2 =
                  [
                    I.CALL (I.REL (I.LABEL label)),
                    I.Def  [reg],
                    I.Use  [reg]
                  ]
              val offsetBaseRoutine2 =
                  [
                    I.Align {align = 4, filler = 0wx90},
                    I.Label label
                  ] @
                  offsetBaseCode @
                  [
                    I.RET NONE
                  ] @
                  offsetBaseRoutine
            in
              (offsetBaseCode2, offsetBaseRoutine2)
            end
        end


(*
  fun globalOffsetComputation (toplevelContext:toplevelContext)
                              (context:context)
                              numEntries =
      case !(#codeBase context) of
        NONE => NONE
      | SOME {offsetBaseLabel, offsetBaseReg} =>
        let
          val (loadCode, loadRoutine) =
              if numEntries == 1 then
                (* no need to share global offset base label.
                 * we can choose the most efficient one. *)
                ([
                   I.CALL (I.I_ (I.LABEL label)),
                   I.Label label,
                   I.POPL (I.R reg)
                 ],
                 nil)
              else
                (* we need to share global offset base label among
                 * entries. *)
                ([
                   I.CALL (I.I_ (I.LABEL smlGetPCThunkLabel)),
                   I.Def [I.R I.EBX],
                   I.MOVL (I.R offsetBaseReg, I.R_ I.EBX)
                 ],
                 [
                   I.Label smlGetPCThunkLabel,
                   I.MOVL (I.R I.EBX, I.M_ (I.BASE I.ESP)),
                   I.RET NONE
                 ])
        in
          (* load routine is shared among all clusters. *)
          #globalOffsetRoutine toplevelContext := loadRoutine;
          loadCode
        end

  fun selectCluster (toplevelContext:toplevelContext)
                    ({frameBitmap, name, body, loc}:AI.cluster) =
      let
        val clusterContext =
            {
              globalOffsetBase = ref NONE
            } : context

        val bodyCodes =
            map (fn block => (block, selectBlock context block)) body

        val globalOffsetBaseCode =
            globalOffsetComputation toplevelContext context

        fun defParams args =
            map (fn x => case transformArgInfo x of
                           IARG rm => rm
                         | _ => raise Control.Bug "selectBlock")
                args

        val bodyCodes =
            map (fn ({blockKind, label, ...}, blockCode) =>
                    (* labels following a call should be 16-byte-aligned
                     * when less than 8 bytes away from a 16 byte boundary. *)
                    (* loop entry labels should be 16-byte-aligned
                     * when less than 8 bytes away from a 16 byte boundary. *)
                    (* labels following an uncoditional branch should be
                     * 16-byte-aligned when less than 8 bytes away from a
                     * 16-byte boundary. *)
                    case blockKind of
                      AI.FunEntry params =>
                      [
                        I.Align {align = 4, filler = 0wx90},
                        (* I.EntryLabel (funLabel label), *)
                        I.Label (funLabel label),
                        I.Def (defParams params),
                        I.Prologue nil
                      ] @
                      globalOffsetBaseCode @
                      blockCode
                    | AI.Handler arg =>
                      [
                        I.Label (localLabel label),
                        I.Def (defparams [arg])
                      ] @
                      (* Since all registers are broken here, we need to
                       * calculate global offset again. *)
                      globalOffsetBaseCode @
                      blockCode
                    | _ =>
                      [
                        I.Align {align = 4, filler = 0wx90},
                        I.Lavel (localLabel label)
                      ] @
                      blockCode)
            bodyCodes

        val bodyCode = List.concat (List.concat bodyCodes)

        val frameBitmap = map transformFrameBitmap frameBitmap
      in
        {
          frameBitmap = frameBitmap,
          entries = entries,
          body = bodyCode,
          preFrameAligned = true,
          loc = loc
        } : I.cluster
      end



      let


        val bodyCode =
            case !(#codeBase context) of
              NONE => bodyCode
            | SOME (label, reg) =>
              let
                fun count (n, I.LoadGlobalOffset::t) = count (n + 1, t)
                  | count (n, h::t) = count (n, t)
                  | count (n, nil) = n
                val (routine, loadCode) =
                    if count (0, bodyCode) = 1 then
                      (nil,
                       [
                        I.CALL (I.I_ (I.LABEL label)),
                        I.Label label,
                        I.POPL (I.R reg)
                       ])
                    else
                      let
                        val routineLabel = newLabel ()
                      in
                        ([
                           I.Label routineLabel,
                           I.MOVL (I.R reg, I.M_ (I.OFF (I.INT ~4, I.ESP))),
                           I.RET NONE
                         ],
                         [ I.CALL (I.I_ (I.LABEL routineLabel)) ])
                      end

                fun replace (I.LoadGlobalOffset::t) = loadCode @ replace t
                  | replace (h::t) = h :: replace t
                  | replace nil = nil
              in
                I.Align {align = 4, filler = 0wx90} ::
                routine @ replace bodyCode
              end

(*
        val bodyCode = I.Align {align = 4, filler = 0wx90} :: bodyCode
*)

        val frameBitmap = map transformFrameBitmap frameBitmap
      in
        {
          frameBitmap = frameBitmap,
          entries = entries,
          body = bodyCode,
          preFrameAligned = true,
          loc = loc
        } : I.cluster
      end
*)


  fun split insnList =
      let
        fun add (graph, label, rblock, succ) =
            SEnv.insert (graph, label, {body = rev rblock, succ = succ})
        fun body (graph, label, rblock, (insn as I.JMP (_, succs))::insns) =
            begin (add (graph, label, insn::rblock, succs), nil, insns)
          | body (graph, label, rblock, (insn as I.J (_, l, succ))::insns) =
            begin (add (graph, label, insn::rblock, [succ,l]), nil, insns)
          | body (graph, label, rblock, (insn as I.RET _)::insns) =
            begin (add (graph, label, insn::rblock, nil), nil, insns)
          | body (graph, label, rblock, insns as I.Label l::_) =
            begin (add (graph, label, I.JMP (I.REL (I.LABEL l), [l])::rblock,
                        [l]), nil, insns)
          | body (graph, label, rblock, insn::insns) =
            body (graph, label, insn::rblock, insns)
          | body (graph, label, rblock, nil) =
(
 app (fn x => print (Control.prettyPrint (I.debug_instruction x)^"\n")) (rev rblock);
            raise Control.Bug "unexpected block end"
)
        and begin (graph, rblock, (insn as I.Label label) :: insns) =
            body (graph, label, insn::rblock, insns)
          | begin (graph, rblock, (insn as I.Align _) :: insns) =
            begin (graph, insn::rblock, insns)
          | begin (graph, nil, nil) = graph
          | begin (graph, _, insn::insns) =
            raise Control.Bug ("label is not found at beginning of block\n"^
                               Control.prettyPrint (I.debug_instruction insn))
          | begin (graph, _::_, nil) =
            raise Control.Bug "unexpected code end"
      in
        begin (SEnv.empty, nil, insnList)
      end

  fun reversePostorder (graph, entries) =
      let
        fun visit (visited, blocks, label::labels) =
            if SSet.member (visited, label)
            then (visited, blocks)
            else
              let
                val visited = SSet.add (visited, label)
                val block as {body, succ} =
                    case SEnv.find (graph, label) of
                      SOME x => x
                    | NONE => raise Control.Bug ("postorder: "^label)

(*
                val _ = print ("visited "^label^"\n")
                val _ = app (fn x => print (Control.prettyPrint (I.debug_instruction x)^"\n")) body
                val _ = print ("succ "^foldl (fn (l,z) => z^","^l) "" succ^"\n")
                val _ = app (fn (x,_) => print ("l: "^x^"\n")) blocks
                val _ = print "ret\n"
*)
                val (visited, blocks) = visit (visited, blocks, succ)
                val (visited, blocks) = visit (visited, (label,block)::blocks, labels)
              in
                (visited, blocks)
              end
          | visit (visited, blocks, nil) = (visited, blocks)
      in
        #2 (visit (SSet.empty, nil, entries))
      end

  fun concat blocks =
      let
        val insns = foldr (fn ((label,{body,succ}),z) => body @ z) nil blocks
        fun trim ((h as I.JMP (I.REL (I.LABEL l1), _))::
                  (t as I.Align _::I.Label l2::_)) =
            if l1 = l2 then trim t else h :: trim t
          | trim ((h as I.JMP (I.REL (I.LABEL l1), _))::(t as I.Label l2::_)) =
            if l1 = l2 then trim t else h :: trim t
          | trim ((h as I.J (_, _, l1))::(t as I.Label l2::_)) =
            if l1 = l2 then h :: trim t
            else h :: I.JMP (I.REL (I.LABEL l1), [l1]) :: trim t
          | trim (h::t) = h :: trim t
          | trim nil = nil
      in
        trim insns
      end

  fun selectCluster options ({frameBitmap, name, body, loc}:AI.cluster) =
      let
        val calleeSaveRegs =
            [newVar32 [I.ESI], newVar32 [I.EDI], newVar32 [I.EBX]]

        val context =
            {
              calleeSaveRegs = calleeSaveRegs,
              options = options,
              globalOffsetBase = ref NONE
            } : context

        (* context is updated destructively *)
        val blocks =
            map (fn block => (block, selectBlock context block)) body

        val entryLabels =
            List.mapPartial
              (fn {blockKind=AI.FunEntry _,label,...} => SOME (funLabel label)
                | _ => NONE)
              body

        val (offsetBaseCode, offsetBaseRoutine) =
            makeGlobalOffsetComputation context (length entryLabels)

        fun defParams args =
            foldl (fn (x, (defs, pre)) =>
                      case transformArgInfo x of
                        IARG (I.R reg) => (reg::defs, pre)
                      | IARG (I.M (I.PREFRAME {offset,...})) =>
                        (defs, Int.max (pre, offset))
                      | IARG (I.M (I.DISP (_, I.BASE I.EBP))) => (defs, pre)
                      | _ => raise Control.Bug "selectBlock")
                  (nil, 0)
                  args

        (* labels following a call should be 16-byte-aligned
         * when less than 8 bytes away from a 16 byte boundary. *)
        (* loop entry labels should be 16-byte-aligned
         * when less than 8 bytes away from a 16 byte boundary. *)
        (* labels following an uncoditional branch should be
         * 16-byte-aligned when less than 8 bytes away from a
         * 16-byte boundary. *)
        val bodyInsns =
            map (fn ({blockKind, label, loc, ...}, blockCode) =>
                    (case blockKind of
                       AI.FunEntry {argVarList=params,env,...} =>
                       let
                         val params = case env of
                                        SOME v => v::params | NONE => params
                         val (defs, preSize) = defParams params
                       in
                         [
                           I.Align {align = 4, filler = 0wx90},
                           I.Label (funLabel label),
                           I.Loc loc,
                           I.Def (defs
                                  @ map (List.hd o #candidates) calleeSaveRegs),
                           I.Prologue {preFrameSize=preSize, instructions=nil}
                         ] @
                         map (fn v => I.MOVL (I.M (I.VAR v),
                                              I.R_ (List.hd (#candidates v))))
                             (#calleeSaveRegs context) @
                         offsetBaseCode @
                         blockCode
                       end
                     | AI.Handler arg =>
                       [
                         I.Align {align = 4, filler = 0wx90},
                         I.Label (localLabel label),
                         I.Loc loc,
                         I.Def (#1 (defParams [arg]))
                       ] @
                       blockCode
                     | _ =>
                       I.Label (localLabel label) :: I.Loc loc :: blockCode))
            blocks

        val bodyInsns = List.concat bodyInsns
(*
        val _ = app (fn x => print (Control.prettyPrint (I.debug_instruction x)^"\n")) bodyInsns
*)
        val bodyInsns = concat (reversePostorder (split bodyInsns, entryLabels))
                        @ offsetBaseRoutine
(*
        val _ = app (fn x => print (Control.prettyPrint (I.debug_instruction x)^"\n")) bodyInsns
*)

        val frameBitmap = map transformFrameBitmap frameBitmap
      in
        {
          frameBitmap = frameBitmap,
(*
          entries = entries,
*)
          body = bodyInsns,
          preFrameAligned = true,
          loc = loc
        } : I.cluster
      end






  val objectAlign = 16
  val wordSize = 4
  val singleSize = 4
  val doubleSize = 8

  fun padSize (size, align) =
      (align - 1) - (size + align - 1) mod align

(*
  fun makePad padsize =
      List.tabulate (padsize, fn _ => 0w0 : Word8.word)
*)

  fun charToWord8 c = Word8.fromInt (ord c)

  (* FIXME: need to split constants into text and data;
   *        Number constants should be placed in either .literal4 or .literal8.
   *        String constants ended with zero is placed in .cstring.
   *        Any other constant data consisting of only literals is placed in
   *        .const.
   *        Constant data including references to other data is placed in
   *        .const_data.
   *        Mutable data is placed in .data.
   *)

  fun transformPrimData primData =
      case primData of
        AI.SIntData n => (wordSize, I.IntData (AI.Target.SIntToSInt32 n))
      | AI.UIntData n => (wordSize, I.WordData (AI.Target.UIntToUInt32 n))
      | AI.RealData r => (doubleSize, I.DoubleData r)
      | AI.FloatData r => (singleSize, I.SingleData r)
      | AI.EntryData {entry,...} => (wordSize, I.LabelData (funLabel entry))
      | AI.GlobalLabelData label => (wordSize, I.GlobalLabelData label)
      | AI.ExternLabelData label => (wordSize, I.GlobalLabelData label)

  fun transformData data =
      case data of
        AI.PrimData x =>
        let
          (*
           * |<- multiple of maxAlign ->|
           * [head] [    data     ] [pad]
           *
           * payloadSize = data size
           * object type = VECTOR
           *)
          val (size, data) = transformPrimData x
          val header = Word32.fromInt size || HEAD_TYPE_UNBOXED_VECTOR
        in
          (wordSize + size,
           [ I.WordData header ],
           [ data ])
        end

      | AI.StringData str =>
        let
          (*
           * |<-- multiple of words --->|
           * [head] [  string  ] 00 [pad]
           *
           * payloadSize = stringSize + 1
           * object type = VECTOR
           *)
          val size = size str + 1
          val header = Word32.fromInt size || HEAD_TYPE_UNBOXED_VECTOR
        in
          (wordSize + size,
           [ I.WordData header ],
           [ I.AsciiData str, I.BytesData [0w0] ])
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
          transformData (AI.StringData s)
        end

      | AI.ObjectData {objectType, bitmaps, payloadSize, fields} =>
        let
          fun toWordImm x = I.I_ (I.WORD (AI.Target.UIntToUInt32 x))
          fun fromWordImm (I.I_ (I.WORD x)) = x
            | fromWordImm _ = raise Control.Bug "transformData: fromWordImm"

          val bitmaps = map toWordImm bitmaps
          val payloadSize = toWordImm payloadSize

          val {header, bitmapOffset, bitmaps, allocSize, ...} =
              allocObject (objectType, bitmaps, payloadSize)

          val header = fromWordImm header
          val bitmapOffset = Word32.toInt (fromWordImm bitmapOffset)
          val bitmaps = map fromWordImm bitmaps
          val allocSize = Word32.toInt (fromWordImm allocSize)

          fun makePad (size, filled) =
              if size = filled then nil
              else if size < filled then [ I.FillZeroData (filled - size) ]
              else raise Control.Bug "transformData: makePad"

          fun makeData (offset, {value, size}::fields) =
              let
                val size = AI.Target.UIntToInt size
                val (valueSize, data) = transformPrimData value
              in
                data :: makePad (valueSize, size)
                @ makeData (offset + size, fields)
              end
            | makeData (offset, nil) =
              let
                val fill1 = makePad (offset, bitmapOffset)
                val bitmapData = map I.WordData bitmaps
                val offset = offset + wordSize * length bitmaps
                val fill2 = makePad (offset, allocSize)
              in
                fill1 @ bitmapData @ fill2
              end
        in
          (allocSize,
           [ I.WordData header ],
           makeData (0, fields))
        end

  fun transformObjectData labels data =
      let
        val (size, header, body) = transformData data
        val objpad = padSize (size, objectAlign)
        val pad = if objpad > 0
                  then [ I.FillZeroData objpad ]
                  else nil
      in
        (size + objpad,
         I.Data header ::
         labels @
         [ I.Data (body @ pad) ])
      end

  fun appendObjectSectionHeader section nil = nil
    | appendObjectSectionHeader section insns =
      [
        I.Section section,
        I.Align {align = objectAlign, filler = 0w0},
        I.Data [I.FillZeroData (objectAlign - wordSize) ]
      ] @ insns

  fun transformConstant constants =
      let
        val insns =
            LocalVarID.Map.foldri
              (fn (id, const, insns) =>
                  #2 (transformObjectData [I.Label (constLabel id)] const)
                  @ insns)
              nil
              constants
      in
        appendObjectSectionHeader I.ConstSection insns
      end

  fun isMutableData data =
      case data of
        AI.ObjectData {objectType = AI.Array, ...} => true
      | _ => false

  fun transformGlobals globals =
      let
        val aliasMap =
            SEnv.foldli (fn (_, AI.GlobalData _, z) => z
                          | (newName, AI.GlobalAlias origName, z) =>
                            case SEnv.find (z, origName) of
                              SOME l => SEnv.insert (z, origName, newName::l)
                            | NONE => SEnv.insert (z, origName, [newName]))
                        SEnv.empty
                        globals

        val (rodata, data) =
            SEnv.foldri
              (fn (_, AI.GlobalAlias _, z) => z
                | (label, AI.GlobalData data, (rodata, rwdata)) =>
                  let
                    val aliases = case SEnv.find (aliasMap, label) of
                                    SOME x => x | NONE => nil
                    val labels =
                        map I.GlobalDataLabel (label::aliases)
                    val (size, insns) =
                        transformObjectData labels data
                  in
                    if isMutableData data
                    then (rodata, insns @ rwdata)
                    else (insns @ rodata, rwdata)
                  end)
              (nil, nil)
              globals
      in
        appendObjectSectionHeader I.ConstSection rodata @
        appendObjectSectionHeader I.DataSection data
      end



(*
  fun generateEntryCode toplevelContext globals =
      let
        val clusterContext =
            {
              globalOffsetBase = ref NONE
            } : context

        (* toplevel dependency resplution *)
        val initEntryData = {label = toplevelEntryLabel, size = 4, align = 4}
        val initEntryAddr = absoluteAddr context "init_entry"
        val initDoneAddr = absoluteAddr context "init_done"

        val provideLabels =

        val code =
            [
              I.Text,
              I.Label "init_module",
              I.ReauireLabels,


              I.LEAL (I.EAX, absoluteAddr context "init_entry"),
              I.JMP  (I.R_ I.EAX),
              I.Align {align = 4, filler = 0wx90},
              I.Label "init_done",
              I.RET NONE,

              I.Data,
              I.Align {align = 4, filler = 0w0},
              I.Label "init_entry",
              I.Long (I.LABEL "start"),

              I.Text,
              I.Align {align = 4, filler = 0wx90},
              I.Label "start",
              I.CallRequire,
              I.PUSHL (I.R_ I.EBP),
              I.MOVL (I.R I.EBP, I.R_ I.ESP),
              I.ANDL (I.R I.ESP, I.I_ (I.WORD 0wxfffffff0)),
              I.CALL (I.I_ (I.LABEL toplevelEntry)),

              I.LEAL (I.EAX, absoluteAddr context "init_entry"),
              I.LEAL (I.ECX, absoluteAddr context "init_done"),
              I.MOVL (I.M (I.BASE I.EAX), I.R_ I.ECX),
              I.LEAVE,
              I.RET
            ]

*)



  fun select compileUnitCount stamp
             ({toplevel, clusters, constants, globals}:AI.program) =
      let
        val _ = Counters.init stamp

        val {cpu, manufacturer, ossys, options} = Control.targetInfo ()

        (* FIXME: hard coded *)
        val ossys =
            case ossys of
              "darwin" => Darwin
            | "linux" => Linux
            | _ => Others

        val defaultOptions =
            case ossys of
              Darwin => SSet.singleton "PIC"
            | _ => SSet.empty

        val options =
            foldl (fn ((positive, option), set) =>
                      if positive then SSet.add (set, option)
                      else SSet.delete (set, option) handle NotFound => set)
                  defaultOptions
                  options

        val options =
            {
              ossys = ossys,
              PIC = SSet.member (options, "PIC")
            }

        val clusters = map (selectCluster options) clusters
        val constants = transformConstant constants
        val globals = transformGlobals globals

        val (entryLabel, return, nextStubCode) =
            case compileUnitCount of
              NONE => (smlMainLabel, [I.RET NONE], NONE)
            | SOME x =>
              let
                val currentLabel =
                    if x = 0 then smlMainLabel
                    else smlMainLabel ^ "._" ^ Int.toString x
                val nextLabel = smlMainLabel ^ "._" ^ Int.toString (x+1)
                val l1 = newLabel ()
                val l2 = newLabel ()
              in
                (currentLabel,
                 [
                   (* If eax is not null, return immediately. *)
                   I.TESTL (I.R I.EAX, I.R_ I.EAX),
                   I.J     (I.NE, l2, l1),
                   I.Label l1,
                   I.JMP   (I.REL (I.EXTSTUBLABEL nextLabel), nil),
                   I.Label l2,
                   I.RET   NONE
                 ],
                 SOME {label = nextLabel, code = [I.RET NONE]})
              end

        val entryCode =
            case toplevel of
              NONE => nil
            | SOME {entry=toplevelLabel, ...} =>
              [
                I.Align {align = 4, filler = 0wx90},
                I.GlobalCodeLabel entryLabel,
                I.PUSHL (I.R_ I.EBP),      (* -8 *)

                (* save callee-save registers; they may be clobbered due to
                 * exception. *)
                I.PUSHL (I.R_ I.EBX),      (* -12 *)
                I.PUSHL (I.R_ I.ESI),      (* -16 *)
                I.PUSHL (I.R_ I.EDI),      (* -20 *)

                (* allocate memory for exception handler. *)
                I.SUBL  (I.R I.ESP, I.I_ (I.INT 16)),  (* -36 *)
                I.MOVL  (I.R I.EAX, I.R_ I.ESP),

                (* enter toplevel code. *)
                I.CALL  (I.REL (I.LABEL "enter_toplevel_")),
                (* if there is an unhandled exception, eax register holds
                 * the exception object. *)

                I.ADDL  (I.R I.ESP, I.I_ (I.INT 16)),
                I.POPL  (I.R I.EDI),
                I.POPL  (I.R I.ESI),
                I.POPL  (I.R I.EBX),
                I.POPL  (I.R I.EBP)
              ] @
              return @
              [
                I.Label "enter_toplevel_",

                (* terminate frame stack chain. *)
                I.PUSHL (I.I_ (I.INT 0)),   (* -44 *)
                I.MOVL  (I.R I.EBP, I.R_ I.ESP),
                I.PUSHL (I.I_ (I.INT 0)),   (* -48 *)

                (* force align stack pointer. *)
                I.ANDL  (I.R I.ESP, I.I_ (I.WORD 0wxfffffff0)),

                (* setup toplevel exception handler.
                 * handler_addr = return address of the last call.
                 * save_esp = stack pointer before the last call.
                 * save_ebp = ditto (any value is ok actually)
                 *)
                I.MOVL (I.R I.EDX, I.M_ (I.DISP (I.INT ~4, I.BASE I.EAX))),
                I.MOVL (I.M (I.DISP (I.INT 4, I.BASE I.EAX)), I.R_ I.EDX),
                I.MOVL (I.M (I.DISP (I.INT 8, I.BASE I.EAX)), I.R_ I.EAX),
                I.MOVL (I.M (I.DISP (I.INT 12, I.BASE I.EAX)), I.R_ I.EAX),
                I.CALL (I.REL (I.EXTSTUBLABEL smlPushHandlerFunLabel)),

                (* call toplevel cluster. *)
                I.MOVL (I.R I.EAX, (I.I_ (I.INT 0))),
                I.CALL (I.REL (I.LABEL (funLabel toplevelLabel))),

                (* pop toplevel exception handler. *)
                I.CALL (I.REL (I.EXTSTUBLABEL smlPopHandlerFunLabel)),

                (* return NULL *)
                I.MOVL (I.R I.EAX, I.I_ (I.INT 0)),
                I.LEAL (I.ESP, I.DISP (I.INT 4, I.BASE I.EBP)),
                I.RET NONE
              ]

(*
        (* toplevel dependency resplution *)
        val toplevelEntryLabel = newLabel ()
        val globals = {label = toplevelEntryLabel, size = 4, align = 4}
        val toplevelEntryAddr = absoluteAddr context toplevelEntryLabel

        val code =
            [


        val code =
            [
              I.Text,
              I.Label "init_module",
              I.GlobalOffsetBase,
              I.LEAL (I.EAX, absoluteAddr context "init_entry"),
              I.JMP  (I.R_ I.EAX),
              I.Align {align = 4, filler = 0wx90},
              I.Label "init_done",
              I.RET NONE,

              I.Data,
              I.Align {align = 4, filler = 0w0},
              I.Label "init_entry",
              I.Long (I.LABEL "start"),

              I.Text,
              I.Align {align = 4, filler = 0wx90},
              I.Label "start",
              I.CallRequire,
              I.PUSHL (I.R_ I.EBP),
              I.MOVL (I.R I.EBP, I.R_ I.ESP),
              I.ANDL (I.R I.ESP, I.I_ (I.WORD 0wxfffffff0)),
              I.CALL (I.I_ (I.LABEL toplevelEntry)),
              I.GlobalOffsetBase,
              I.LEAL (I.EAX, absoluteAddr context "init_entry"),
              I.LEAL (I.ECX, absoluteAddr context "init_done"),
              I.MOVL (I.M (I.BASE I.EAX), I.R_ I.ECX),
              I.LEAVE,
              I.RET
            ]

*)




        val program =
            {
              entryCode = entryCode,       (* filled after RegisterAllocation *)
(*
              toplevel = toplevelEntry,
*)
              clusters = clusters,
              data = constants @ globals,
              globalReferences = nil,     (* filled by RegisterAllocation *)
              externReferences = nil,     (* filled by RegisterAllocation *)
              externCodeStubs = nil,     (* filled by RegisterAllocation *)
              toplevelStubCode = nextStubCode
            } : I.program
      in
        (Counters.getCounterStamp (), program)
      end

end
