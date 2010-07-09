(**
 * VM instruction selection.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: VMCodeSelection.sml,v 1.13 2010/01/18 10:44:41 katsu Exp $
 *)
structure VMCodeSelection : VMCODESELECTION =
struct

  structure AS = Absyn
  structure AI = AbstractInstruction
  structure Target = AbstractInstruction.Target
  structure VM = VMMnemonic
  structure M = MachineLanguage

  fun newLocalId () = VarID.generate ()

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

  val NullLabel = VM.EXTDATAREF "__NULL__"
  val NowhereLabel = VM.EXTDATAREF "__NOWHERE__"
  val EmptyLabel = VM.EXTDATAREF "__EMPTY__"

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

  fun labelString x = "L" ^ VarID.toString x
  fun constLabelString x = "C" ^ VarID.toString x
  fun LabelRef x = VM.LABELREF (labelString x)
  fun ConstRef x = VM.INTERNALREF (constLabelString x)

  fun newVar ty =
      let
        val id = newLocalId ()
        val displayName = "$" ^ VarID.toString id
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
        tagArgMap: M.tag VarID.Map.map, (* paramId -> tag *)
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

  fun addFFType context (attributes:AS.ffiAttributes) (argTys, retTys) =
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
            case #callingConvention attributes of
              NONE => ""
            | SOME AS.FFI_CDECL => ""
            | SOME AS.FFI_STDCALL => ":stdcall:"

        val ffty = convention ^ argTys ^ retTys
        val sz = toLSZ (Word.fromInt (size ffty))
        val pad = padSize (sz + 0w1, maxAlign) + 0w1

        val label = constLabelString (newLocalId ())
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
                case VarID.Map.find (#tagArgMap context, id) of
                  SOME tag => tag
                | NONE => raise Control.Bug ("transformTy: ParamTag: "^
                                             VarID.toString id)

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
      | AI.Extern {ty = AI.CPOINTER, label = {label = name, value = NONE}} =>
        (context, IMM (VM.EXTERN (VM.FFREF name)), TY VM.P, M.VAR pointerClass)
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
          (fn ({id,...}, ent, map) => VarID.Map.insert (map, id, M.GENERIC ent))
          VarID.Map.empty
          (params, argumentRegisters)
      else
        (*
         * If the number of arguments is exceeded the number of argument
         * registers, arguments are packed into one unboxed double-size
         * array and its address is passed by first argument register.
         *)
        #1 (foldl
             (fn ({id, ...}:AI.paramInfo, (map, i)) =>
                 (VarID.Map.insert (map, id,
                                 M.FREEGENERIC
                                     {entity = List.hd argumentRegisters,
                                      offset = i,
                                      bit = 0w0}),
                  i + argumentSize))
             (VarID.Map.empty, 0w0)
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
                  {calleeTy, attributes, argVars, argTys, retVars, retTys,
                   loc} =
      let
        val (context, ffty) = addFFType context attributes calleeTy

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
           attributes = AS.defaultFFIAttributes,
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
                AI.Foreign {function, attributes} =>
                callForeign (transformValue context function)
                            {calleeTy = calleeTy,
                             attributes = attributes,
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
              addFFType context Absyn.defaultFFIAttributes (argTy, retTy)
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
          val (context, code4, env, _) =
              bindFresh loc (M.ALLOCED envReg) (transformValue context env)
          val (context, code2, entry, _) =
              bindIfNotLabel loc (transformValue context entry)

          val (code3, use) = passArgs argList argTys loc

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
          val (context, code4, env, _) =
              bindFresh loc (M.ALLOCED envReg) (transformValue context env)
          val (context, code2, entry, _) =
              bindIfNotLabel loc (transformValue context entry)

          val (code3, use1) = passArgs argList argTys loc
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
                  VarID.Map.unionWith
                      (fn _ =>
                          raise Control.Bug "selectCluster: doubled parameter")
                      (map, makeTagArgMap params)
                | (_, z) => z)
              VarID.Map.empty
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
          val s = BigInt.toCString n
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
            VarID.Map.foldli
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

  fun transformGlobals context globals aliases =
      let
        fun align offset alignment ((label, sz)::t) =
            let
              val alignment = Word.max (alignment, sz)
              val pad = Word.fromInt (LSZtoInt (padSize (toLSZ offset, sz)))
              val offset = offset + pad
              val {size, slots, alignment} = align (offset + sz) alignment t
              val aliases = case SEnv.find (aliases, label) of
                              SOME x => x | NONE => nil
              val slots2 =
                  map (fn l => {label = l, offset = offset}) (label::aliases)
            in
              {size = size, slots = slots2 @ slots, alignment = alignment}
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

  fun select ({toplevel, clusters, constants, globals,
                     aliases}:AI.program) =
      let

        val mainEntry =
            case toplevel of
              SOME {clusterId, funLabel} => labelString funLabel
            | NONE => raise Control.Bug "select: mainEntry"

        val context =
            {
              registerDesc = initialRegisterDesc,
              tagArgMap = VarID.Map.empty,
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
            transformGlobals context globals aliases

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
          program
      end
      handle exn => raise exn

end
