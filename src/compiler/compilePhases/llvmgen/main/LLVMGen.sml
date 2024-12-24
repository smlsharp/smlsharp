(**
 * generate llvm ir
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)
structure LLVMGen =
struct

  (* NOTE:
   * For potability, do not write LLVM types immediately in this file.
   * Respect type annotations in MachineCode as many as possible and
   * generate LLVM types from them. This policy will improve modularity
   * of target dependent information such as correspondence between
   * RuntimeTypes and LLVM types.
   *)

  structure M = MachineCode
  structure L = LLVMIR
  structure T = RuntimeTypes
  structure P = BuiltinPrimitive
  structure I = InterfaceName

  val gcname = SOME "smlsharp"

  fun foldli f z l =
      #2 (foldl (fn (x,(i,z)) => (i + 1, f (x,i,z))) (0, z) l)

  fun assertType loc (x, y:L.ty) =
      if x = y
      then ()
      else (*raise Bug.Bug*)
print
                 ("assertType: failed at " ^ loc ^ "\n\
                  \actual: " ^ Bug.prettyPrint (L.format_ty x) ^ "\n\
                  \expect: " ^ Bug.prettyPrint (L.format_ty y))

  val empty = fn x : L.body => x : L.body
  fun insn1 i = fn (body, last) : L.body => (i::body, last) : L.body
  fun insns is = fn (body, last) : L.body => (is @ body, last) : L.body
  fun last l = fn () => (nil, l) : L.body

  fun block (label, args, body) : L.body -> L.body =
      let
        val phis = map L.PHI args
      in
        fn next : L.body =>
           (nil, L.BLOCK {label = label,
                          phis = phis,
                          body = body (),
                          next = next})
      end

  fun label (label, args) =
      let
        val phis = map L.PHI args
      in
        fn body : L.body =>
           fn next : L.body =>
              L.BLOCK {label = label,
                       phis = phis,
                       body = body,
                       next = next}
      end
  fun scope (code : unit -> L.body) =
      fn cont : L.body -> L.last => (nil, cont (code ())) : L.body

  val nullOperand = (L.PTR L.I8, L.CONST L.NULL)

  fun bitcast (operand as (opty, value):L.operand, ty) =
      if opty = ty then (empty, operand) else
      case value of
        L.CONST const =>
        (empty, (ty, L.CONST (L.CONST_BITCAST ((opty, const), ty))))
      | L.VAR var =>
        let
          val var = VarID.generate ()
        in
          (insn1 (L.CONV (var, L.BITCAST, operand, ty)), (ty, L.VAR var))
        end

  val maxSize =
      RuntimeTypes.getSize RuntimeTypes.maxSize

  fun pointerSize () =
      RuntimeTypes.getSize (#size RuntimeTypes.recordTy)

  fun intptrTy () =
      case pointerSize () of
        1 => L.I8
      | 2 => L.I16
      | 4 => L.I32
      | 8 => L.I64
      | _ => raise Bug.Bug "FIXME: intptrTy"

  fun intSize ty =
      case ty of
        L.I1 => SOME 1
      | L.I8 => SOME 8
      | L.I16 => SOME 16
      | L.I32 => SOME 32
      | L.I64 => SOME 64
      | L.PTR _ => NONE
      | L.FLOAT => NONE
      | L.DOUBLE => NONE
      | L.VOID => NONE
      | L.FN _ => NONE
      | L.ARRAY _ => NONE
      | L.STRUCT _ => NONE

  fun isIntTy (L.PTR _) = true
    | isIntTy ty = isSome (intSize ty)

  fun realSize ty =
      case ty of
        L.I1 => NONE
      | L.I8 => NONE
      | L.I16 => NONE
      | L.I32 => NONE
      | L.I64 => NONE
      | L.PTR _ => NONE
      | L.FLOAT => SOME 32
      | L.DOUBLE => SOME 64
      | L.VOID => NONE
      | L.FN _ => NONE
      | L.ARRAY _ => NONE
      | L.STRUCT _ => NONE

  fun compileCallConv cconv =
      case cconv of
        NONE => NONE
      | SOME FFIAttributes.FFI_CDECL => SOME L.CCC
      | SOME FFIAttributes.FFI_STDCALL => SOME L.X86STDCALLCC
      | SOME FFIAttributes.FFI_FASTCC => SOME L.FASTCC

  fun compileRuntimeTy (rty as {tag, size, rep}) =
      case (tag, T.getSize size, rep) of
        (T.UNBOXED, 1, T.INT _) => L.I8
      | (T.UNBOXED, 2, T.INT _) => L.I16
      | (T.UNBOXED, 4, T.INT _) => L.I32
      | (T.UNBOXED, 8, T.INT _) => L.I64
      | (_, _, T.INT _) => raise Bug.Bug "compileRuntimeTy: INT"
      | (T.UNBOXED, 4, T.FLOAT) => L.FLOAT
      | (T.UNBOXED, 8, T.FLOAT) => L.DOUBLE
      | (_, _, T.FLOAT) => raise Bug.Bug "compileRuntimeTy: FLOAT"
      | (_, size, T.PTR) =>
        if size = pointerSize () then L.PTR L.I8
        else raise Bug.Bug "compileRUntimeTy: PTR"
      | (_, size, T.CPTR) =>
        if size = pointerSize () then L.PTR L.I8
        else raise Bug.Bug "compileRuntimeTy: PTR_NULLABLE"
      | (_, size, T.CODEPTR code) =>
        if tag <> T.UNBOXED orelse size <> pointerSize ()
        then raise Bug.Bug "compileRuntimeTy: T.CODEPTR"
        else
          (
            case code of
              T.SOMECODE => L.PTR (L.FN (L.VOID, nil, true))
            | T.FOREIGN {argTys, varArgTys, retTy, attributes} =>
              L.PTR (L.FN (compileRuntimeTyOpt retTy,
                           map compileRuntimeTy argTys,
                           isSome varArgTys))
            | T.FN {haveClsEnv, argTys, retTy} =>
              L.PTR (L.FN (case retTy of
                             {rep = T.DATA T.LAYOUT_SINGLE, ...} => L.VOID
                           | _ => compileRuntimeTy retTy,
                           (if haveClsEnv then [L.PTR L.I8] else nil)
                           @ map compileRuntimeTy argTys,
                           false))
            | T.CALLBACK {haveClsEnv, argTys, retTy, attributes} =>
              L.PTR (L.FN (compileRuntimeTyOpt retTy,
                           (if haveClsEnv then [L.PTR (L.PTR L.I8)] else nil)
                           @ map compileRuntimeTy argTys,
                           false))
          )
      | (T.BOXED, size, T.BINARY) =>
        if size = pointerSize () then L.PTR L.I8
        else raise Bug.Bug "compileRUntimeTy: BINARY"
      | (T.UNBOXED, 1, T.BINARY) => L.I8
      | (T.UNBOXED, 2, T.BINARY) => L.I16
      | (T.UNBOXED, 4, T.BINARY) => L.I32
      | (T.UNBOXED, 8, T.BINARY) => L.I64
      | (_, _, T.BINARY) => raise Bug.Bug "compileRuntimeTy: BINARY"
      | (_, _, T.DATA _) => compileRuntimeTy (rty # {rep = T.BINARY})

  and compileRuntimeTyOpt NONE = L.VOID
    | compileRuntimeTyOpt (SOME ty) = compileRuntimeTy ty

  fun compileTy ((_, rty):M.ty) =
      compileRuntimeTy rty

  fun compileVarInfo ({id, ty}:M.varInfo) =
      (compileTy ty, id)

  fun constToValue (ty:L.ty, const) =
      (ty, L.CONST const)

  (*
   * An object header consists of a 28-bit integer SIZE, a 3-bit integer TYPE
   * and a 1-bit flag S as follows:
   *
   *  (MSB)  31 30  28                                   0  (LSB)
   *        +--+------+-----------------------------------+
   *        |S | TYPE |              SIZE                 |
   *        +--+------+-----------------------------------+
   *
   * SIZE is the size of the object except for its header and bitmap.
   * TYPE indicates the type of the object, which is one of the following:
   *   000   UNBOXED_VECTOR     no pointer,    no bitmap,  content equality
   *   001   BOXED_VECTOR       pointer array, no bitmap,  content equality
   *   010   UNBOXED_ARRAY      no pointer,    no bitmap,  identity equality
   *   011   BOXED_ARRAY        pointer array, no bitmap,  identity equality
   *   100   (unused)
   *   101   RECORD             record with bitmap words,  content equality
   *   110   INTINF             no pointer,    no bitmap,  bignum equality
   *   111   (reserved for forwarding pointers of Cheney's collectors)
   * S indicates that the object is managed by a specific scheme other than GC.
   *
   * See also object.h.
   *)

  val FLAG_OBJTYPE_BOX_SHIFT      = 0w28
  val FLAG_OBJTYPE_UNBOXED        = 0wx00000000 : Word64.word
  val FLAG_OBJTYPE_BOXED          = 0wx10000000 : Word64.word
  val FLAG_OBJTYPE_VECTOR         = 0wx00000000 : Word64.word
  val FLAG_OBJTYPE_ARRAY          = 0wx20000000 : Word64.word
  val FLAG_OBJTYPE_UNBOXED_VECTOR = 0wx00000000 : Word64.word
  val FLAG_OBJTYPE_BOXED_VECTOR   = 0wx10000000 : Word64.word
  val FLAG_OBJTYPE_UNBOXED_ARRAY  = 0wx20000000 : Word64.word
  val FLAG_OBJTYPE_BOXED_ARRAY    = 0wx30000000 : Word64.word
  val FLAG_OBJTYPE_PACK           = 0wx40000000 : Word64.word
  val FLAG_OBJTYPE_RECORD         = 0wx50000000 : Word64.word
  val FLAG_OBJTYPE_INTINF         = 0wx60000000 : Word64.word
  val FLAG_SKIP                   = 0wx80000000 : Word64.word
  val MASK_OBJSIZE                = 0wx0fffffff : Word64.word
  val MASK_OBJTYPE                = 0wx70000000 : Word64.word

  val objHeaderTy = L.I32
  val objHeaderSize = 0w4 : Word32.word

  val recordBitmapWordTy = L.I32
  val recordBitmapWordSize = 0w4 : Word64.word
  val recordBitmapWordBits = 0w32 : Word64.word

  local
    datatype intrinsic =
        R of {name: string,
              tail: L.tail option,
              argTys: L.ty list,
              argAttrs: L.parameter_attribute list list,
              varArg: bool,
              retTy: L.ty,
              retAttrs: L.parameter_attribute list,
              fnAttrs: L.function_attribute list}
    datatype intrinsicVar =
        V of {name: string, ty: L.ty}
  in
  (* "tail" indicates that the function neither access nor reference
   * callees' stack frames.  This implies that functions declared with
   * "tail" never cause garbage collection. *)
  val llvm_memcpy =
      R {name = "llvm.memcpy.p0i8.p0i8.i32",
         tail = NONE,
         argTys = [L.PTR L.I8, L.PTR L.I8, L.I32, L.I32, L.I1],
         argAttrs = [nil, nil, nil, nil, nil],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_memmove =
      R {name = "llvm.memmove.p0i8.p0i8.i32",
         tail = NONE,
         argTys = [L.PTR L.I8, L.PTR L.I8, L.I32, L.I32, L.I1],
         argAttrs = [nil, nil, nil, nil, nil],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_memset =
      R {name = "llvm.memset.p0i8.i32",
         tail = NONE,
         argTys = [L.PTR L.I8, L.I8, L.I32, L.I32, L.I1],
         argAttrs = [nil, nil, nil, nil, nil],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_gcroot =
      R {name = "llvm.gcroot",
         tail = NONE,
         argTys = [L.PTR (L.PTR L.I8), L.PTR L.I8],
         argAttrs = [nil, nil],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_fabs_f32 =
      R {name = "llvm.fabs.f32",
         tail = SOME L.TAIL,
         argTys = [L.FLOAT],
         argAttrs = [nil],
         varArg = false,
         retTy = L.FLOAT,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_fabs_f64 =
      R {name = "llvm.fabs.f64",
         tail = SOME L.TAIL,
         argTys = [L.DOUBLE],
         argAttrs = [nil],
         varArg = false,
         retTy = L.DOUBLE,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_sadd_with_overflow_i8 =
      R {name = "llvm.sadd.with.overflow.i8",
         tail = NONE,
         argTys = [L.I8, L.I8],
         argAttrs = [nil, nil],
         varArg = false,
         retTy = L.STRUCT ([L.I8, L.I1], {packed=false}),
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_sadd_with_overflow_i16 =
      R {name = "llvm.sadd.with.overflow.i16",
         tail = NONE,
         argTys = [L.I16, L.I16],
         argAttrs = [nil, nil],
         varArg = false,
         retTy = L.STRUCT ([L.I16, L.I1], {packed=false}),
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_sadd_with_overflow_i32 =
      R {name = "llvm.sadd.with.overflow.i32",
         tail = NONE,
         argTys = [L.I32, L.I32],
         argAttrs = [nil, nil],
         varArg = false,
         retTy = L.STRUCT ([L.I32, L.I1], {packed=false}),
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_sadd_with_overflow_i64 =
      R {name = "llvm.sadd.with.overflow.i64",
         tail = NONE,
         argTys = [L.I64, L.I64],
         argAttrs = [nil, nil],
         varArg = false,
         retTy = L.STRUCT ([L.I64, L.I1], {packed=false}),
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_ssub_with_overflow_i8 =
      R {name = "llvm.ssub.with.overflow.i8",
         tail = NONE,
         argTys = [L.I8, L.I8],
         argAttrs = [nil, nil],
         varArg = false,
         retTy = L.STRUCT ([L.I8, L.I1], {packed=false}),
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_ssub_with_overflow_i16 =
      R {name = "llvm.ssub.with.overflow.i16",
         tail = NONE,
         argTys = [L.I16, L.I16],
         argAttrs = [nil, nil],
         varArg = false,
         retTy = L.STRUCT ([L.I16, L.I1], {packed=false}),
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_ssub_with_overflow_i32 =
      R {name = "llvm.ssub.with.overflow.i32",
         tail = NONE,
         argTys = [L.I32, L.I32],
         argAttrs = [nil, nil],
         varArg = false,
         retTy = L.STRUCT ([L.I32, L.I1], {packed=false}),
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_ssub_with_overflow_i64 =
      R {name = "llvm.ssub.with.overflow.i64",
         tail = NONE,
         argTys = [L.I64, L.I64],
         argAttrs = [nil, nil],
         varArg = false,
         retTy = L.STRUCT ([L.I64, L.I1], {packed=false}),
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_smul_with_overflow_i8 =
      R {name = "llvm.smul.with.overflow.i8",
         tail = NONE,
         argTys = [L.I8, L.I8],
         argAttrs = [nil, nil],
         varArg = false,
         retTy = L.STRUCT ([L.I8, L.I1], {packed=false}),
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_smul_with_overflow_i16 =
      R {name = "llvm.smul.with.overflow.i16",
         tail = NONE,
         argTys = [L.I16, L.I16],
         argAttrs = [nil, nil],
         varArg = false,
         retTy = L.STRUCT ([L.I16, L.I1], {packed=false}),
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_smul_with_overflow_i32 =
      R {name = "llvm.smul.with.overflow.i32",
         tail = NONE,
         argTys = [L.I32, L.I32],
         argAttrs = [nil, nil],
         varArg = false,
         retTy = L.STRUCT ([L.I32, L.I1], {packed=false}),
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_smul_with_overflow_i64 =
      R {name = "llvm.smul.with.overflow.i64",
         tail = NONE,
         argTys = [L.I64, L.I64],
         argAttrs = [nil, nil],
         varArg = false,
         retTy = L.STRUCT ([L.I64, L.I1], {packed=false}),
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_init_trampoline =
      R {name = "llvm.init.trampoline",
         tail = NONE,
         argTys = [L.PTR L.I8, L.PTR L.I8, L.PTR L.I8],
         argAttrs = [nil, nil, nil],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val llvm_adjust_trampoline =
      R {name = "llvm.adjust.trampoline",
         tail = NONE,
         argTys = [L.PTR L.I8],
         argAttrs = [nil],
         varArg = false,
         retTy = L.PTR L.I8,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val sml_load_intinf =
      R {name = "sml_load_intinf",
         tail = NONE,
         argTys = [L.PTR L.I8],
         argAttrs = [[L.INREG]],
         varArg = false,
         retTy = L.PTR L.I8,
         retAttrs = [L.NOALIAS],
         fnAttrs = [L.NOUNWIND]}
  val sml_gcroot =
      R {name = "sml_gcroot",
         tail = SOME L.TAIL,
         argTys = [L.PTR L.I8, L.PTR (L.FN (L.VOID, nil, false)),
                   L.PTR L.I8, L.PTR L.I8],
         argAttrs = [nil, nil, nil, nil],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
(*
  val sml_gcroot_load =
      R {name = "sml_gcroot_load",
         tail = NONE,
         argTys = [L.PTR L.I8, L.PTR L.I8, L.PTR L.I8],
         argAttrs = [[L.INREG], [L.INREG], [L.INREG]],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val sml_gcroot_unload =
      R {name = "sml_gcroot_unload",
         tail = NONE,
         argTys = [L.PTR L.I8, L.PTR L.I8, L.PTR L.I8],
         argAttrs = [[L.INREG], [L.INREG], [L.INREG]],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
*)
  val sml_start =
      R {name = "sml_start",
         tail = NONE,
         argTys = [L.PTR L.I8],
         argAttrs = [[L.INREG]],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val sml_end =
      R {name = "sml_end",
         tail = NONE,
         argTys = [],
         argAttrs = [],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val sml_leave =
      R {name = "sml_leave",
         tail = NONE,
         argTys = [],
         argAttrs = [],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val sml_enter =
      R {name = "sml_enter",
         tail = NONE,
         argTys = [],
         argAttrs = [],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val sml_save =
      R {name = "sml_save",
         tail = NONE,
         argTys = [],
         argAttrs = [],
         varArg = false,
         retTy = L.PTR L.I8,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val sml_unsave =
      R {name = "sml_unsave",
         tail = NONE,
         argTys = [],
         argAttrs = [],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val sml_check =
      R {name = "sml_check",
         tail = NONE,
         argTys = [L.I32],
         argAttrs = [[L.INREG]],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = []}
  val sml_check_flag =
      V {name = "sml_check_flag",
         ty = L.I32}
  val sml_find_callback =
      R {name = "sml_find_callback",
         tail = NONE,
         argTys = [L.PTR L.I8, L.PTR L.I8],
         argAttrs = [[L.INREG], [L.INREG]],
         varArg = false,
         retTy = L.PTR (L.PTR L.I8),
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val sml_alloc_code =
      R {name = "sml_alloc_code",
         tail = NONE,
         argTys = [],
         argAttrs = [],
         varArg = false,
         retTy = L.PTR L.I8,
         retAttrs = [L.NOALIAS],
         fnAttrs = [L.NOUNWIND]}
  val sml_alloc =
      R {name = "sml_alloc",
         tail = NONE,
         argTys = [L.I32],
         argAttrs = [[L.INREG]],
         varArg = false,
         retTy = L.PTR L.I8,
         retAttrs = [L.NOALIAS],
         fnAttrs = [L.NOUNWIND]}
  val sml_obj_equal =
      R {name = "sml_obj_equal",
         tail = NONE,
         argTys = [L.PTR L.I8, L.PTR L.I8],
         argAttrs = [[L.INREG], [L.INREG]],
         varArg = false,
         retTy = L.I32,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val sml_write =
      R {name = "sml_write",
         tail = NONE,
         argTys = [L.PTR L.I8, L.PTR (L.PTR L.I8), L.PTR L.I8],
         argAttrs = [[L.INREG], [L.INREG], [L.INREG]],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val sml_copyary =
      R {name = "sml_copyary",
         tail = NONE,
         argTys = [L.PTR (L.PTR L.I8), L.I32, L.PTR (L.PTR L.I8),
                   L.I32, L.I32],
         argAttrs = [nil, nil, nil, nil, nil],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val sml_raise =
      R {name = "sml_raise",
         tail = NONE,
         argTys = [L.PTR L.I8],
         argAttrs = [[L.INREG]],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NORETURN]}
  val sml_save_exn =
      R {name = "sml_save_exn",
         tail = NONE,
         argTys = [L.PTR L.I8],
         argAttrs = [[L.INREG]],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val sml_unsave_exn =
      R {name = "sml_unsave_exn",
         tail = NONE,
         argTys = [L.PTR L.I8],
         argAttrs = [[L.INREG]],
         varArg = false,
         retTy = L.PTR L.I8,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val sml_personality =
      R {name = "sml_personality",
         tail = NONE,
         argTys = [],
         argAttrs = [],
         varArg = true,
         retTy = L.I32,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}

  fun intrinsicTy (R {retTy, ...}) = retTy

  local
    val foreignEntries = ref SEnv.empty
  in

  fun initForeignEntries () =
      foreignEntries := SEnv.empty

  fun declareForeignEntries () =
      map #2 (SEnv.listItems (!foreignEntries))

  (* NOTE: a foreign symbol may be _import-ed twice with different type
   * annotations *)
  fun foreignSymbol ((ty, name), newty) =
      if ty = newty
      then (ty, L.SYMBOL name)
      else (newty, L.CONST_BITCAST ((ty, L.SYMBOL name), newty))

  fun registerForeignEntry name ty cconv =
      case SEnv.find (!foreignEntries, name) of
        SOME (oldTy, _) => foreignSymbol ((oldTy, name), ty)
      | NONE =>
        let
          val dec =
              case ty of
                L.PTR (L.FN (retTy, argTys, varArg)) =>
                L.DECLARE {linkage = NONE,
                           cconv = cconv,
                           retAttrs = nil,
                           retTy = retTy,
                           name = name,
                           arguments = map (fn t => (t, nil)) argTys,
                           varArg = varArg,
                           fnAttrs = nil,
                           gcname = NONE}
              | L.PTR ty =>
                L.EXTERN {name = name, ty = ty}
              | _ => raise Bug.Bug "registerForeignEntry"
        in
          foreignEntries := SEnv.insert (!foreignEntries, name, (ty, dec));
          (ty, L.SYMBOL name)
        end

  fun registerIntrinsic (R {name, argTys, argAttrs, retTy, retAttrs, varArg,
                            fnAttrs, ...}) =
      let
        val ty = L.PTR (L.FN (retTy, argTys, varArg))
      in
        case SEnv.find (!foreignEntries, name) of
          SOME (oldTy, _) => foreignSymbol ((ty, name), oldTy)
        | NONE =>
          (foreignEntries :=
             SEnv.insert
               (!foreignEntries, name,
                (ty, L.DECLARE {linkage = NONE,
                                cconv = NONE,
                                retAttrs = retAttrs,
                                retTy = retTy,
                                name = name,
                                arguments = ListPair.zipEq (argTys, argAttrs),
                                varArg = varArg,
                                fnAttrs = fnAttrs,
                                gcname = NONE}));
           (ty, L.SYMBOL name))
      end

  end (* local *)

  fun referIntrinsicVar (V {name, ty}) =
      constToValue (registerForeignEntry name (L.PTR ty) NONE)

  fun intrinsicCallOperands result (r as R {name, tail, fnAttrs, argAttrs,
                                            retTy, ...})
                            args =
      {result = Option.map (fn x => (retTy, x)) result : (L.ty * L.var) option,
       tail = tail,
       cconv = NONE : L.calling_convention option,
       retAttrs = nil : L.parameter_attribute list,
       fnPtr = constToValue (registerIntrinsic r),
       args = ListPair.zipEq (argAttrs, args : L.operand list),
       unwind = NONE : HandlerLabel.id option,
       fnAttrs = fnAttrs}
      handle ListPair.UnequalLengths => raise Bug.Bug ("callIntrinsic " ^ name)

  end (* local *)

  fun funEntryLabelToSymbol id =
      "_SMLL" ^ FunEntryLabel.toString id
  fun callbackEntryLabelToSymbol id =
      "_SMLB" ^ CallbackEntryLabel.toString id
  fun dataLabelToSymbol id =
      "_SMLD" ^ DataLabel.toString id
  fun dataLabelToSymbolAlt id =
      "_SMLM" ^ DataLabel.toString id
  fun extraDataLabelToSymbol id =
      "_SMLE" ^ ExtraDataLabel.toString id
  fun externFunSymbolToSymbol id =
      "_SMLF" ^ ExternFunSymbol.toString id
  fun externSymbolToSymbol id =
      "_SMLZ" ^ ExternSymbol.toString id

  val dataLabelOffset = Word.fromInt maxSize

  type extern_decls =
      {extern:
         {used : bool ref,
          provider : InterfaceName.provider,
          dec : L.topdec option}
           ExternSymbol.Map.map,
       externFun:
         {used : bool ref,
          provider : InterfaceName.provider,
          dec : L.topdec}
           ExternFunSymbol.Map.map}

  val emptyExternDecls : extern_decls =
      {extern = ExternSymbol.Map.empty,
       externFun = ExternFunSymbol.Map.empty}

  fun singletonExtern (id, provider, dec) : extern_decls =
      {extern = ExternSymbol.Map.singleton
                  (id, {used = ref false, provider = provider, dec = dec}),
       externFun = ExternFunSymbol.Map.empty}

  fun singletonExternFun (id, provider, dec) : extern_decls =
      {extern = ExternSymbol.Map.empty,
       externFun =
         ExternFunSymbol.Map.singleton
           (id, {used = ref false, provider = provider, dec = dec})}

  fun unionExternDecls (e1:extern_decls, e2:extern_decls) : extern_decls =
      {extern =
         ExternSymbol.Map.unionWith
           (fn _ => raise Bug.Bug "unionExternDecls extern")
           (#extern e1, #extern e2),
       externFun =
         ExternFunSymbol.Map.unionWith
           (fn _ => raise Bug.Bug "unionExternDecls externFun")
           (#externFun e1, #externFun e2)}

  fun listUsedExternDecls ({extern, externFun}:extern_decls) =
      ExternSymbol.Map.listItems
        (ExternSymbol.Map.mapPartial
           (fn {used = ref false, ...} => NONE
             | {used, provider, dec = NONE} => NONE
             | {used, provider, dec = SOME dec} => SOME (provider, dec))
           extern)
      @ ExternFunSymbol.Map.listItems
          (ExternFunSymbol.Map.mapPartial
             (fn {used = ref false, ...} => NONE
               | {used, provider, dec} => SOME (provider, dec))
             externFun)

  type alias_map =
      {dataMap : L.const DataLabel.Map.map,
       extraDataMap : L.const ExtraDataLabel.Map.map,
       exFunEntryMap : ExternFunSymbol.id list FunEntryLabel.Map.map}

  val emptyAliasMap =
      {dataMap = DataLabel.Map.empty,
       extraDataMap = ExtraDataLabel.Map.empty,
       exFunEntryMap = FunEntryLabel.Map.empty} : alias_map

  fun singletonAlias (id, const) : alias_map =
      {dataMap = DataLabel.Map.singleton (id, const),
       extraDataMap = ExtraDataLabel.Map.empty,
       exFunEntryMap = FunEntryLabel.Map.empty}

  fun singletonAliasExtra (id, const) : alias_map =
      {dataMap = DataLabel.Map.empty,
       extraDataMap = ExtraDataLabel.Map.singleton (id, const),
       exFunEntryMap = FunEntryLabel.Map.empty}

  fun singletonAliasFunEntry (id, id2) : alias_map =
      {dataMap = DataLabel.Map.empty,
       extraDataMap = ExtraDataLabel.Map.empty,
       exFunEntryMap = FunEntryLabel.Map.singleton (id, [id2])}

  fun unionAliasMap (a1:alias_map, a2:alias_map) : alias_map =
      {dataMap =
         DataLabel.Map.unionWith
           (fn _ => raise Bug.Bug "extendAliasMap dataMap")
           (#dataMap a1, #dataMap a2),
       extraDataMap =
         ExtraDataLabel.Map.unionWith
           (fn _ => raise Bug.Bug "extendAliasMap extraDataMap")
           (#extraDataMap a1, #extraDataMap a2),
       exFunEntryMap =
         FunEntryLabel.Map.unionWith
           (op @)
           (#exFunEntryMap a1, #exFunEntryMap a2)}

  fun compileConst (env as {aliasMap:alias_map, externDecls:extern_decls})
                   const =
      case const of
        M.NVINT8 x => L.INTCONST (Word64.fromInt (Int8.toInt x))
      | M.NVINT16 x => L.INTCONST (Word64.fromInt (Int16.toInt x))
      | M.NVINT32 x => L.INTCONST (Word64.fromInt x)
      | M.NVINT64 x => L.INTCONST (Word64.fromLargeInt (Int64.toLarge x))
      | M.NVWORD8 x => L.INTCONST (Word8.toLarge x)
      | M.NVWORD16 x => L.INTCONST (Word16.toLarge x)
      | M.NVWORD32 x => L.INTCONST (Word32.toLarge x)
      | M.NVWORD64 x => L.INTCONST x
      | M.NVCONTAG x => L.INTCONST (Word32.toLarge x)
      | M.NVREAL64 x => L.FLOATCONST x
      | M.NVREAL32 x => L.FLOATCONST (SMLSharp_Builtin.Real32.toReal64 x)
      | M.NVCHAR x => L.INTCONST (Word64.fromInt (ord x))
      | M.NVUNIT => L.INTCONST 0w0
      | M.NVNULLPOINTER => L.NULL
      | M.NVNULLBOXED => L.NULL
      | M.NVTAG {tag, ty} =>
        L.INTCONST (Word64.fromInt (RuntimeTypes.tagValue tag))
      | M.NVSIZE {size, ty} =>
        L.INTCONST (Word64.fromInt (RuntimeTypes.getSize size))
      | M.NVFOREIGNSYMBOL {name, ty} =>
        let
          val cconv =
              case ty of
                (_, {rep = T.CODEPTR (T.FOREIGN {attributes,...}), ...}) =>
                compileCallConv (#callingConvention attributes)
              | _ => NONE
        in
          #2 (registerForeignEntry name (compileTy ty) cconv)
        end
      | M.NVFUNENTRY id =>
        (case FunEntryLabel.Map.find (#exFunEntryMap aliasMap, id) of
           SOME (h::_) => L.SYMBOL (externFunSymbolToSymbol h)
         | _ => L.SYMBOL (funEntryLabelToSymbol id))
      | M.NVEXFUNENTRY id =>
        (case ExternFunSymbol.Map.find (#externFun externDecls, id) of
           SOME {used, ...} => used := true
         | _ => ();
         L.SYMBOL (externFunSymbolToSymbol id))
      | M.NVCALLBACKENTRY id => L.SYMBOL (callbackEntryLabelToSymbol id)
      | M.NVEXTRADATA id =>
        (case ExtraDataLabel.Map.find (#extraDataMap aliasMap, id) of
           SOME x => x
         | NONE => L.SYMBOL (extraDataLabelToSymbol id))
      | M.NVCAST {value, valueTy, targetTy, cast=P.BitCast} =>
        (
          case (compileTy valueTy, compileTy targetTy) of
            (ty1 as L.PTR _, ty2 as L.PTR _) =>
            L.CONST_BITCAST ((ty1, compileConst env value), ty2)
          | (ty1 as L.PTR _, ty2 as L.I32) =>
            L.CONST_PTRTOINT ((ty1, compileConst env value), ty2)
          | (ty1 as L.PTR _, ty2 as L.I64) =>
            L.CONST_PTRTOINT ((ty1, compileConst env value), ty2)
          | (ty1 as L.I32, ty2 as L.PTR _) =>
            L.CONST_INTTOPTR ((ty1, compileConst env value), ty2)
          | (ty1 as L.I64, ty2 as L.PTR _) =>
            L.CONST_INTTOPTR ((ty1, compileConst env value), ty2)
          | (ty1, ty2) =>
            L.CONST_BITCAST ((ty1, compileConst env value), ty2)
        )
      | M.NVCAST {value, valueTy, targetTy, cast} => compileConst env value
      | M.NVTOPDATA id =>
        (case DataLabel.Map.find (#dataMap aliasMap, id) of
           SOME x => x
         | NONE => L.SYMBOL (dataLabelToSymbol id))

  fun compileTopConst env (const, ty) =
      (compileTy ty, compileConst env const)

  fun compileTopConstWord32 (const, ty:M.ty) =
      case compileConst {aliasMap=emptyAliasMap, externDecls=emptyExternDecls}
                        const of
        L.INTCONST w => Word32.fromLarge w
      | _ => raise Bug.Bug "compileTopConstWord32"

  type funTy =
      {
        argTys : (L.ty * L.parameter_attribute list) list,
        varArg : bool,
        retTy : L.ty,
        cconv : L.calling_convention option
      }

  val dummyFunTy =
      {argTys = [], varArg = false, retTy = L.VOID, cconv = NONE} : funTy

  local
    fun congruentTy (L.PTR _, L.PTR _) = true
      | congruentTy (ty1, ty2) = ty1 = ty2
  in
  fun isMustTailAllowed (funTy1:funTy, funTy2:funTy) =
      #varArg funTy1 = #varArg funTy2
      andalso #cconv funTy1 = #cconv funTy2
      andalso ListPair.allEq
                (fn ((ty1, a1), (ty2, a2)) =>
                    congruentTy (ty1, ty2) andalso a1 = a2)
                (#argTys funTy1, #argTys funTy2)
      andalso congruentTy (#retTy funTy1, #retTy funTy2)
  end (* local *)

  type handler_kind =
      {catch : bool, cleanup : bool}

  type env =
      {
        slotAddrMap: L.operand SlotID.Map.map,
        constEnv : {aliasMap : alias_map, externDecls : extern_decls},
        exportMap : {aliaseeTy : L.ty,
                     gvarAddr : L.ty * L.const,
                     gvarArray : L.operand}
                      ExternSymbol.Map.map,
        handlerMap : handler_kind HandlerLabel.Map.map,
        funTy : funTy,
        personality: (L.ty * L.const) option ref option,
        returnInsns : L.operand -> unit -> L.body
      }

  val emptyEnv =
      {
        slotAddrMap = SlotID.Map.empty,
        constEnv = {aliasMap = emptyAliasMap, externDecls = emptyExternDecls},
        exportMap = ExternSymbol.Map.empty,
        handlerMap = HandlerLabel.Map.empty,
        funTy = dummyFunTy,
        personality = NONE,
        returnInsns = fn _ => fn () => (nil, L.UNREACHABLE) (* dummy *)
      } : env

  fun bindHandlerLabel (env as {handlerMap,...}:env) (handlerLabel, kind) =
      env # {
        handlerMap = HandlerLabel.Map.insert (handlerMap, handlerLabel, kind)
      }

  fun getHandlerKind (env as {handlerMap,...}:env) handlerLabel =
      case HandlerLabel.Map.find (handlerMap, handlerLabel) of
        SOME x => x
      | NONE => raise Bug.Bug "getHandlerKind"

  fun compileValue (env as {constEnv, ...}:env) value =
      case value of
      M.ANCONST {const, ty} =>
      (compileTy ty,
       L.CONST (compileConst constEnv const))
    | M.ANVAR {id,ty} =>
      (compileTy ty, L.VAR id)
    | M.ANCAST {exp, expTy, targetTy} =>
      if compileTy expTy = compileTy targetTy
         andalso #tag (#2 expTy) = #tag (#2 targetTy)
      then compileValue env exp
      else raise Bug.Bug ("compileValue: ANCAST: "
                          ^ Bug.prettyPrint (M.format_ty expTy)
                          ^ " -> "
                          ^ Bug.prettyPrint (M.format_ty targetTy))
    | M.ANBOTTOM => raise Bug.Bug "compileValue: ANBOTTOM"

  fun compileAddress (env:env) addr =
      case addr of
        M.MAPTR ptrExp =>
        let
          val ptr = compileValue env ptrExp
        in
          (empty, ptr, ptr)
        end
      | M.MAPACKED base =>
        let
          val ptr = compileValue env base
        in
          (empty, ptr, ptr)
        end
      | M.MAOFFSET {base, offset} =>
        let
          val ptr as (ty, _) = compileValue env base
          val _ = assertType "3" (ty, L.PTR L.I8)
          val offset = compileValue env offset
          val var = VarID.generate ()
        in
          (insn1 (L.GETELEMENTPTR {result = var,
                                   inbounds = true,
                                   ty = L.I8,
                                   ptr = ptr,
                                   indices = [offset]}),
           ptr,
           (ty, L.VAR var))
        end
      | M.MARECORDFIELD {recordExp, fieldIndex} =>
        compileAddress
          env
          (M.MAOFFSET {base = recordExp,
                       offset = fieldIndex})
      | M.MAARRAYELEM {arrayExp, elemSize, elemIndex} =>
        let
          val ptr as (ty, _) = compileValue env arrayExp
          val _ = assertType "4" (ty, L.PTR L.I8)
          val size = compileValue env elemSize
          val index = compileValue env elemIndex
          val _ = assertType "5" (#1 size, #1 index)
          val var1 = VarID.generate ()
          val var2 = VarID.generate ()
        in
          (insns [L.OP2 (var1, L.MUL L.WRAP, size, index),
                  L.GETELEMENTPTR {result = var2,
                                   inbounds = true,
                                   ty = L.I8,
                                   ptr = ptr,
                                   indices = [(#1 size, L.VAR var1)]}],
           ptr,
           (L.PTR L.I8, L.VAR var2))
        end

  fun compileObjTypeTag tag objFlag =
      case tag of
        (ty, L.CONST (L.INTCONST w)) =>
        let
          val shift = FLAG_OBJTYPE_BOX_SHIFT
          val tag = Word64.<< (w, shift)
        in
          (empty, (ty, L.CONST (L.INTCONST (Word64.orb (tag, objFlag)))))
        end
      | tag =>
        let
          val shift = L.INTCONST (Word.toLarge FLAG_OBJTYPE_BOX_SHIFT)
          val v1 = VarID.generate ()
          val v2 = VarID.generate ()
        in
          (insns [L.OP2 (v1, L.SHL, tag, (objHeaderTy, L.CONST shift)),
                  L.OP2 (v2, L.OR, (objHeaderTy, L.VAR v1),
                         (objHeaderTy, L.CONST (L.INTCONST objFlag)))],
           (objHeaderTy, L.VAR v2))
        end

  fun compileObjType env objType =
      case objType of
        M.OBJTYPE_VECTOR tag =>
        compileObjTypeTag (compileValue env tag) FLAG_OBJTYPE_VECTOR
      | M.OBJTYPE_ARRAY tag =>
        compileObjTypeTag (compileValue env tag) FLAG_OBJTYPE_ARRAY
      | M.OBJTYPE_RECORD =>
        (empty, (objHeaderTy, L.CONST (L.INTCONST FLAG_OBJTYPE_RECORD)))
      | M.OBJTYPE_INTINF =>
        (empty, (objHeaderTy, L.CONST (L.INTCONST FLAG_OBJTYPE_INTINF)))
      | M.OBJTYPE_UNBOXED_VECTOR =>
        (empty, (objHeaderTy, L.CONST (L.INTCONST FLAG_OBJTYPE_UNBOXED_VECTOR)))

  fun makeHeaderWord env (objType, allocSize) =
      case (compileObjType env objType, allocSize) of
        ((insns, (_, L.CONST (L.INTCONST w1))), (_, L.CONST (L.INTCONST w2))) =>
        (insns, (objHeaderTy, L.CONST (L.INTCONST (Word64.orb (w1, w2)))))
      | ((insns1, objType), _) =>
        let
          val var = VarID.generate ()
        in
          (insns1 o insn1 (L.OP2 (var, L.OR, allocSize, objType)),
           (objHeaderTy, L.VAR var))
        end

  fun makeHeaderWordStatic (objType, allocSize) =
      case makeHeaderWord
             emptyEnv
             (objType, (objHeaderTy, L.CONST (L.INTCONST allocSize))) of
                (_, (ty, L.CONST (L.INTCONST w))) =>
                (ty, L.INIT_CONST (L.INTCONST (Word64.orb (w, FLAG_SKIP))))
              | _ => raise Bug.Bug "makeHeaderWordStatic"

  fun jumpIfZero value (thenLabel, args) =
      let
        val elseLabel = FunLocalLabel.generate nil
      in
        scope (last (L.SWITCH {value = value,
                               default = (elseLabel, []),
                               branches = [((#1 value, L.INTCONST 0w0),
                                            (thenLabel, args))]}))
        o label (elseLabel, [])
      end

  fun jumpIfNull value (thenLabel, args) =
      let
        val b = VarID.generate ()
        val elseLabel = FunLocalLabel.generate nil
      in
        scope (insn1 (L.ICMP (b, L.EQ, value, nullOperand))
               o last (L.SWITCH {value = (L.I1, L.VAR b),
                                 default = (thenLabel, args),
                                 branches = [((L.I1, L.INTCONST 0w0),
                                              (elseLabel, []))]}))
        o label (elseLabel, [])
      end

  val landingPadTy = L.STRUCT ([L.PTR L.I8, L.PTR L.I8], {packed=false})

  fun resumeInsn (ueVar, exnVar) =
      let
        val r1 = VarID.generate ()
        val r2 = VarID.generate ()
      in
        insns [L.INSERTVALUE (r1, (landingPadTy, L.CONST L.UNDEF),
                              (L.PTR L.I8, L.VAR ueVar), 0),
               L.INSERTVALUE (r2, (landingPadTy, L.VAR r1),
                              (L.PTR L.I8, L.VAR exnVar), 1)]
        o last (L.RESUME (landingPadTy, L.VAR r2))
      end

  fun landingPad (env:env) (handlerId, {catch, cleanup}, ueVar, exnVar,
                            bodyInsn) =
      let
        val _ = case #personality env of
                  NONE => raise Bug.Bug "landingPad without personality"
                | SOME (ref (SOME _)) => ()
                | SOME (r as ref NONE) =>
                  r := SOME (registerIntrinsic sml_personality)
        (*
         * The landingpad instruction returns two pointers {ue, e} where
         * "ue" for a pointer to _Unwind_Exception and "e" for an SML#'s
         * exception object.  "uw" may be NULL if this handler is not a
         * cleanup handler.  "e" may be NULL if current exception is a
         * foreign exception, i.e. not an SML# exception.
         * See also exn.c for details.
         *)
        val lpadVar = VarID.generate ()
        val ue = VarID.generate ()
        val e = VarID.generate ()
        val localLabel = HandlerLabel.asFunLocalLabel handlerId
        val lpadBody =
            insns [L.EXTRACTVALUE (ue, (landingPadTy, L.VAR lpadVar), 0),
                   L.EXTRACTVALUE (e, (landingPadTy, L.VAR lpadVar), 1)]
            o last (L.BR (localLabel, [(L.PTR L.I8, L.VAR ue),
                                       (L.PTR L.I8, L.VAR e)]))
        val r1 = VarID.generate ()
        val r2 = VarID.generate ()
      in
        block (localLabel, [(L.PTR L.I8, ueVar), (L.PTR L.I8, exnVar)],
               bodyInsn o resumeInsn (ueVar, exnVar))
        o (fn next =>
              (nil,
               L.LANDINGPAD
                 {label = handlerId,
                  argVar = (lpadVar, landingPadTy),
                  catch = if catch then [nullOperand] else [],
                  cleanup = cleanup,
                  body = lpadBody (),
                  next = next}))
      end

  fun jumpToLandingPad (handlerLabel, ueVar, exnVar) =
      (HandlerLabel.asFunLocalLabel handlerLabel,
       [(L.PTR L.I8, L.VAR ueVar), (L.PTR L.I8, L.VAR exnVar)])

  fun callInsn {result, tail, cconv, retAttrs, fnPtr, args, unwind, fnAttrs} =
      case unwind of
        NONE =>
        insn1 (L.CALL {result = Option.map #2 result,
                       tail = tail,
                       cconv = cconv,
                       retAttrs = retAttrs,
                       fnPtr = fnPtr,
                       args = args,
                       fnAttrs = fnAttrs})
      | SOME handlerLabel =>
        let
          val toLabel = FunLocalLabel.generate nil
          val tmp = Option.map (fn _ => VarID.generate ()) result
        in
          scope (last (L.INVOKE {result = tmp,
                                 cconv = cconv,
                                 retAttrs = retAttrs,
                                 fnPtr = fnPtr,
                                 args = args,
                                 fnAttrs = fnAttrs,
                                 to = toLabel,
                                 unwind = handlerLabel}))
          o label (toLabel, case result of NONE => nil | SOME var => [var])
        end

  fun callIntrinsic result r args =
      callInsn (intrinsicCallOperands result r args)

  fun invokeIntrinsic result r handler args =
      callInsn (intrinsicCallOperands result r args # {unwind = handler})

  fun objectHeaderAddress (result, obj) =
      let
        val objAddr = VarID.generate ()
      in
        insns
          [L.CONV (objAddr, L.BITCAST, obj, L.PTR objHeaderTy),
           L.GETELEMENTPTR
             {result = result,
              inbounds = true,
              ty = objHeaderTy,
              ptr = (L.PTR objHeaderTy, L.VAR objAddr),
              indices = [(L.I64, L.CONST (L.INTCONST (Word64.~ 0w1)))]}]
      end

  fun objectHeader (result, obj) =
      let
        val headerAddr = VarID.generate ()
      in
        objectHeaderAddress (headerAddr, obj)
        o insn1 (L.LOAD (result, objHeaderTy,
                         (L.PTR objHeaderTy, L.VAR headerAddr)))
      end

  fun objectPayloadSize (result, header) =
      insn1 (L.OP2 (result, L.AND,
                    (objHeaderTy, L.VAR header),
                    (objHeaderTy, L.CONST (L.INTCONST MASK_OBJSIZE))))

  fun recordBitmapSize (result, payloadSize) =
      let
        val ty = objHeaderTy
        val wordBitMask = recordBitmapWordBits - 0w1
        val pointerSize = Word64.fromInt (pointerSize ())
        val numPointers = VarID.generate ()
        val numBitmapBits' = VarID.generate ()
        val numBitmapBits = VarID.generate ()
      in
        insns
          [L.OP2 (numPointers, L.UDIV,
                  payloadSize,
                  (ty, L.CONST (L.INTCONST pointerSize))),
           L.OP2 (numBitmapBits', L.ADD L.NUW,
                  (ty, L.VAR numPointers),
                  (ty, L.CONST (L.INTCONST wordBitMask))),
           L.OP2 (numBitmapBits, L.AND,
                  (ty, L.VAR numBitmapBits'),
                  (ty, L.CONST (L.INTCONST (Word64.notb wordBitMask)))),
           L.OP2 (result, L.LSHR,
                  (ty, L.VAR numBitmapBits),
                  (ty, L.CONST (L.INTCONST 0w3)))]
      end

  fun objectAllocSize (result, obj) =
      let
        val header = VarID.generate ()
        val payloadSize = VarID.generate ()
        val objType = VarID.generate ()
        val cmpResult = VarID.generate ()
        val recordPayloadSize = VarID.generate ()
        val bitmapSize = VarID.generate ()
      in
        objectHeader (header, obj)
        o objectPayloadSize (payloadSize, header)
        o insns
            [L.OP2 (objType, L.AND,
                    (objHeaderTy, L.VAR header),
                    (objHeaderTy, L.CONST (L.INTCONST MASK_OBJTYPE))),
             L.ICMP (cmpResult, L.EQ,
                     (objHeaderTy, L.VAR objType),
                     (objHeaderTy, L.CONST (L.INTCONST FLAG_OBJTYPE_RECORD))),
             L.SELECT (recordPayloadSize,
                       (L.I1, L.VAR cmpResult),
                       (objHeaderTy, L.VAR payloadSize),
                       (objHeaderTy, L.CONST (L.INTCONST 0w0)))]
        o recordBitmapSize
            (bitmapSize, (objHeaderTy, L.VAR recordPayloadSize))
        o insn1 (L.OP2 (result, L.ADD L.NUW,
                        (objHeaderTy, L.VAR payloadSize),
                        (objHeaderTy, L.VAR bitmapSize)))
      end

  local
    fun cmpOp (var, varTy, con, cmp, x : L.operand, y : L.operand) =
        let
          val v = VarID.generate ()
        in
          insns [con (v, cmp, x, y),
                 L.CONV (var, L.ZEXT, (L.I1, L.VAR v), varTy)]
        end
    fun overflowOp (var, varTy, intrinsic, x : L.operand, y : L.operand) =
        let
          val v1 = VarID.generate ()
          val v2 = VarID.generate ()
        in
          callIntrinsic (SOME v1) intrinsic [x, y]
          o insns [L.EXTRACTVALUE (v2, (intrinsicTy intrinsic, L.VAR v1), 1),
                   L.CONV (var, L.ZEXT, (L.I1, L.VAR v2), varTy)]
        end
    fun compareIntTy (ty1, ty2) =
        case (intSize ty1, intSize ty2) of
          (SOME x, SOME y) => SOME (Int.compare (x, y))
        | _ => NONE
    fun compareRealTy (ty1, ty2) =
        case (realSize ty1, realSize ty2) of
          (SOME x, SOME y) => SOME (Int.compare (x, y))
        | _ => NONE
  in

  fun compilePrim env {prim, retTy, argTys, resultTy, result, sizes, args} =
      case (prim, retTy, argTys, args) of
        (P.IdentityEqual, _, _, [x, y]) =>
        (
          if #1 x = #1 y andalso isIntTy (#1 x)
          then () else raise Bug.Bug "compilePrim: IdentityEqual";
          cmpOp (result, resultTy, L.ICMP, L.EQ, x, y)
        )
      | (P.IdentityEqual, _, _, _) =>
        raise Bug.Bug "compilePrim: IdentityEqual"

      | (P.Int_add_unsafe, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.ADD L.NSW, x, y))
      | (P.Int_add_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_add_unsafe"

      | (P.Int_gt, _, _, [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SGT, x, y)
      | (P.Int_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_gt"

      | (P.Int_gteq, _, _, [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SGE, x, y)
      | (P.Int_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_gteq"

      | (P.Int_lt, _, _, [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SLT, x, y)
      | (P.Int_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_lt"

      | (P.Int_lteq, _, _, [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SLE, x, y)
      | (P.Int_lteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_lteq"

      | (P.Int_mul_unsafe, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.MUL L.NSW, x, y))
      | (P.Int_mul_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_mul_unsafe"

      | (P.Int_quot_unsafe, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.SDIV, x, y))
      | (P.Int_quot_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_quot_unsafe"

      | (P.Int_rem_unsafe, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.SREM, x, y))
      | (P.Int_rem_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_rem_unsafe"

      | (P.Int_sub_unsafe, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.SUB L.NSW, x, y))
      | (P.Int_sub_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_sub_unsafe"

      | (P.Int_add_overflowCheck, _, _, [x, y]) =>
        overflowOp
          (result, resultTy,
           case #1 x of
             L.I8 => llvm_sadd_with_overflow_i8
           | L.I16 => llvm_sadd_with_overflow_i16
           | L.I32 => llvm_sadd_with_overflow_i32
           | L.I64 => llvm_sadd_with_overflow_i64
           |  _ => raise Bug.Bug "compilePrim: Int_add_overflowCheck",
           x, y)
      | (P.Int_add_overflowCheck, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_add_overflowCheck"

      | (P.Int_mul_overflowCheck, _, _, [x, y]) =>
        overflowOp
          (result, resultTy,
           case #1 x of
             L.I8 => llvm_smul_with_overflow_i8
           | L.I16 => llvm_smul_with_overflow_i16
           | L.I32 => llvm_smul_with_overflow_i32
           | L.I64 => llvm_smul_with_overflow_i64
           |  _ => raise Bug.Bug "compilePrim: Int_mul_overflowCheck",
           x, y)
      | (P.Int_mul_overflowCheck, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_mul_overflowCheck"

      | (P.Int_sub_overflowCheck, _, _, [x, y]) =>
        overflowOp
          (result, resultTy,
           case #1 x of
             L.I8 => llvm_ssub_with_overflow_i8
           | L.I16 => llvm_ssub_with_overflow_i16
           | L.I32 => llvm_ssub_with_overflow_i32
           | L.I64 => llvm_ssub_with_overflow_i64
           |  _ => raise Bug.Bug "compilePrim: Int_sub_overflowCheck",
           x, y)
      | (P.Int_sub_overflowCheck, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_sub_overflowCheck"

      | (P.ObjectSize, _, _, [x]) =>
        let
          val header = VarID.generate ()
        in
          objectHeader (header, x)
          o objectPayloadSize (result, header)
        end
      | (P.ObjectSize, _, _, _) =>
        raise Bug.Bug "compilePrim: ObjectSize"

      | (P.Ptr_advance, _, _, [ptr as (L.PTR L.I8, _), i]) =>
        let
          val var1 = VarID.generate ()
          val size = case sizes of
                       [x] => x
                     | _ => raise Bug.Bug "compilePrim: Ptr_advance"
        in
          insns [L.OP2 (var1, L.MUL L.WRAP, size, i),
                 L.GETELEMENTPTR {result = result,
                                  inbounds = false,
                                  ty = L.I8,
                                  ptr = ptr,
                                  indices = [(#1 i, L.VAR var1)]}]
        end
      | (P.Ptr_advance, _, _, _) =>
        raise Bug.Bug "compilePrim: Ptr_advance"

      | (P.Ptr_fromWord, _, _, [x]) =>
        insn1 (L.CONV (result, L.INTTOPTR, x, resultTy))
      | (P.Ptr_fromWord, _, _, _) =>
        raise Bug.Bug "compilePrim: Ptr_fromWord"

      | (P.Ptr_toWord, _, _, [x]) =>
        insn1 (L.CONV (result, L.PTRTOINT, x, resultTy))
      | (P.Ptr_toWord, _, _, _) =>
        raise Bug.Bug "compilePrim: Ptr_toWord"

      | (P.Real_abs, _, _, [x]) =>
        callIntrinsic
          (SOME result)
          (case #1 x of
             L.FLOAT => llvm_fabs_f32
           | L.DOUBLE => llvm_fabs_f64
           | _ => raise Bug.Bug "compilePrim: Real_abs")
          [x]
      | (P.Real_abs, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_abs"

      | (P.Real_add, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.FADD, x, y))
      | (P.Real_add, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_add"

      | (P.Real_div, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.FDIV, x, y))
      | (P.Real_div, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_div"

      | (P.Real_equal, _, _, [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OEQ, x, y)
      | (P.Real_equal, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_equal"

      | (P.Real_unorderedOrEqual, _, _, [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_UEQ, x, y)
      | (P.Real_unorderedOrEqual, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_unorderedOrEqual"

      | (P.Real_gt, _, _, [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OGT, x, y)
      | (P.Real_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_gt"

      | (P.Real_gteq, _, _, [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OGE, x, y)
      | (P.Real_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_gteq"

      | (P.Real_isNan, _, _, [x]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_UNO, x, x)
      | (P.Real_isNan, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_isNan"

      | (P.Real_lt, _, _, [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OLT, x, y)
      | (P.Real_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_lt"

      | (P.Real_lteq, _, _, [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OLE, x, y)
      | (P.Real_lteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_lteq"

      | (P.Real_mul, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.FMUL, x, y))
      | (P.Real_mul, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_mul"

      | (P.Real_rem, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.FREM, x, y))
      | (P.Real_rem, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_rem"

      | (P.Real_sub, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.FSUB, x, y))
      | (P.Real_sub, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_sub"

      | (P.Real_trunc_unsafe, _, _, [x]) =>
        insn1 (L.CONV (result, L.FPTOSI, x, resultTy))
      | (P.Real_trunc_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_toInt_unsafe"

      | (P.Real_fptoui, _, _, [x]) =>
        insn1 (L.CONV (result, L.FPTOUI, x, resultTy))
      | (P.Real_fptoui, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_toWord_unsafe"

      | (P.Real_fpext_fptrunc, _, _, [x]) =>
        (case compareRealTy (resultTy, #1 x) of
           SOME GREATER => insn1 (L.CONV (result, L.FPEXT, x, resultTy))
         | SOME EQUAL => insn1 (L.CONV (result, L.BITCAST, x, resultTy))
         | SOME LESS => insn1 (L.CONV (result, L.FPTRUNC, x, resultTy))
         | NONE => raise Bug.Bug "compilePrim: Word_zext_trunc")
      | (P.Real_fpext_fptrunc, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_fpext_fptrunc"

      | (P.Real_fromInt, _, _, [x]) =>
        insn1 (L.CONV (result, L.SITOFP, x, resultTy))
      | (P.Real_fromInt, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_fromInt"

      (* ToDo: RuntimePolyEqual is to be deprecated by equality function
       * compilation *)
      | (P.RuntimePolyEqual, _, [{tag=T.BOXED,...}, {tag=T.BOXED,...}],
         [x as (L.PTR L.I8, _), y as (L.PTR L.I8, _)]) =>
        callIntrinsic (SOME result) sml_obj_equal [x, y]
      | (P.RuntimePolyEqual, _, _, [x, y]) =>
        (
          if #1 x = #1 y andalso isIntTy (#1 x)
          then () else raise Bug.Bug "compilePrim: RuntimePolyEqual";
          cmpOp (result, resultTy, L.ICMP, L.EQ, x, y)
        )
      | (P.RuntimePolyEqual, _, _, _) =>
        raise Bug.Bug "compilePrim: RuntimePolyEqual"

      | (P.Word_add, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.ADD L.WRAP, x, y))
      | (P.Word_add, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_add"

      | (P.Word_andb, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.AND, x, y))
      | (P.Word_andb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_andb"

      | (P.Word_arshift_unsafe, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.ASHR, x, y))
      | (P.Word_arshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_arshift_unsafe"

      | (P.Word_div_unsafe, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.UDIV, x, y))
      | (P.Word_div_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_div"

      | (P.Word_gt, _, _, [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.UGT, x, y)
      | (P.Word_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_gt"

      | (P.Word_gteq, _, _, [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.UGE, x, y)
      | (P.Word_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_gteq"

      | (P.Word_lshift_unsafe, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.SHL, x, y))
      | (P.Word_lshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_lshift_unsafe"

      | (P.Word_lt, _, _, [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.ULT, x, y)
      | (P.Word_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_lt"

      | (P.Word_lteq, _, _, [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.ULE, x, y)
      | (P.Word_lteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_lteq"

      | (P.Word_mod_unsafe, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.UREM, x, y))
      | (P.Word_mod_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_mod"

      | (P.Word_mul, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.MUL L.WRAP, x, y))
      | (P.Word_mul, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_mul"

      | (P.Word_orb, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.OR, x, y))
      | (P.Word_orb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_orb"

      | (P.Word_rshift_unsafe, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.LSHR, x, y))
      | (P.Word_rshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_rshift_unsafe"

      | (P.Word_sub, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.SUB L.WRAP, x, y))
      | (P.Word_sub, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_sub"

      | (P.Word_xorb, _, _, [x, y]) =>
        insn1 (L.OP2 (result, L.XOR, x, y))
      | (P.Word_xorb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_xorb"

      | (P.Word_zext_trunc, _, _, [x]) =>
        (case compareIntTy (resultTy, #1 x) of
           SOME GREATER => insn1 (L.CONV (result, L.ZEXT, x, resultTy))
         | SOME EQUAL => insn1 (L.CONV (result, L.BITCAST, x, resultTy))
         | SOME LESS => insn1 (L.CONV (result, L.TRUNC, x, resultTy))
         | NONE => raise Bug.Bug "compilePrim: Word_zext_trunc")
      | (P.Word_zext_trunc, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_zext_trunc"

      | (P.Word_sext_trunc, _, _, [x]) =>
        (case compareIntTy (resultTy, #1 x) of
           SOME GREATER => insn1 (L.CONV (result, L.SEXT, x, resultTy))
         | SOME EQUAL => insn1 (L.CONV (result, L.BITCAST, x, resultTy))
         | SOME LESS => insn1 (L.CONV (result, L.TRUNC, x, resultTy))
         | NONE => raise Bug.Bug "compilePrim: Word_zext_trunc")
      | (P.Word_sext_trunc, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_sext_trunc"

  end (* local *)

  fun compileMid (env:env) mid =
      case mid of
        M.MCINTINF {resultVar, dataLabel, loc} =>
        let
          val dataPtr = compileConst (#constEnv env) (M.NVEXTRADATA dataLabel)
        in
          callIntrinsic NONE sml_save nil
          o callIntrinsic (SOME (#id resultVar))
                          sml_load_intinf
                          [(L.PTR L.I8, L.CONST dataPtr)]
          o callIntrinsic NONE sml_unsave nil
        end
      | M.MCFOREIGNAPPLY {resultVar, funExp, attributes, argExpList, handler,
                          loc} =>
        let
          val {causeGC, fast, callingConvention, ...} = attributes
          val funPtr = compileValue env funExp
          val argList = map (compileValue env) argExpList
          val cconv = compileCallConv callingConvention
          val (leaveInsn, enterInsnOpt) =
              if not fast
              then (callIntrinsic NONE sml_leave nil,
                    SOME (callIntrinsic NONE sml_enter nil))
              else if causeGC
              then (callIntrinsic NONE sml_save nil,
                    SOME (callIntrinsic NONE sml_unsave nil))
              else (empty, NONE)
          val (lpadLabel, lpadInsn) =
              case (enterInsnOpt, handler) of
                (NONE, NONE) => (NONE, empty)
              | (NONE, SOME handlerLabel) => (SOME handlerLabel, empty)
              | (SOME enterInsn, _) =>
                let
                  val lpadLabel = HandlerLabel.generate nil
                  val ueVar = VarID.generate ()
                  val argVar = VarID.generate ()
                  val arg2Var = VarID.generate ()
                  val unsaveInsn =
                      callIntrinsic (SOME arg2Var) sml_unsave_exn
                                    [(L.PTR L.I8, L.VAR argVar)]
                  val kind =
                      case handler of
                        NONE => {catch=false, cleanup=true}
                      | SOME id => getHandlerKind env id # {cleanup=true}
                  val jumpInsn =
                      case handler of
                        NONE => resumeInsn (ueVar, argVar)
                      | SOME id =>
                        last (L.BR (jumpToLandingPad (id, ueVar, arg2Var)))
                in
                  (SOME lpadLabel,
                   landingPad
                     env
                     (lpadLabel, kind, ueVar, argVar,
                      enterInsn
                      o unsaveInsn
                      o jumpInsn
                      o ignore))
                end
        in
          leaveInsn
          o lpadInsn
          o callInsn {result = Option.map compileVarInfo resultVar,
                      tail = NONE,
                      cconv = cconv,
                      retAttrs = nil,
                      fnPtr = funPtr,
                      args = map (fn x => (nil, x)) argList,
                      unwind = lpadLabel,
                      fnAttrs = nil}
          o (case enterInsnOpt of NONE => empty | SOME x => x)
        end
      | M.MCEXPORTCALLBACK {resultVar, codeExp, closureEnvExp, instTyvars,
                            loc} =>
        let
          val code = compileValue env codeExp
          val closureEnv = compileValue env closureEnvExp
          val funPtr = VarID.generate ()
          val entryPtr = VarID.generate ()
          val trampPtr = VarID.generate ()
          val trampPtr1 = VarID.generate ()
          val trampPtr2 = VarID.generate ()
          val cmpResult = VarID.generate ()
          val nestArg1 = VarID.generate ()
          val nestArg2 = VarID.generate ()
          val resultVar2 = VarID.generate ()
          val isNullLabel = FunLocalLabel.generate nil
          val contLabel = FunLocalLabel.generate nil
        in
          scope
            (insn1 (L.CONV (funPtr, L.BITCAST, code, L.PTR L.I8))
             o callIntrinsic (SOME entryPtr) sml_find_callback
                             [(L.PTR L.I8, L.VAR funPtr), closureEnv]
             o insns [L.LOAD (trampPtr1,
                              L.PTR L.I8,
                              (L.PTR (L.PTR L.I8), L.VAR entryPtr)),
                      L.ICMP (cmpResult, L.EQ,
                              (L.PTR L.I8, L.VAR trampPtr1),
                              nullOperand)]
             o scope
                 (last (L.BR_C ((L.I1, L.VAR cmpResult),
                                (isNullLabel, nil),
                                (contLabel, [(L.PTR L.I8, L.VAR trampPtr1)]))))
             o label (isNullLabel, nil)
             o callIntrinsic (SOME trampPtr2) sml_alloc_code []
             o insns [L.STORE {value = (L.PTR L.I8, L.VAR trampPtr2),
                               dst = (L.PTR (L.PTR L.I8), L.VAR entryPtr)},
                      L.GETELEMENTPTR
                        {result = nestArg1,
                         inbounds = true,
                         ty = L.PTR L.I8,
                         ptr = (L.PTR (L.PTR L.I8), L.VAR entryPtr),
                         indices = [(L.I32, L.CONST (L.INTCONST 0w1))]},
                      L.CONV (nestArg2, L.BITCAST,
                              (L.PTR (L.PTR L.I8), L.VAR nestArg1),
                              L.PTR L.I8)]
             o callIntrinsic NONE llvm_init_trampoline
                             [(L.PTR L.I8, L.VAR trampPtr2),
                              (L.PTR L.I8, L.VAR funPtr),
                              (L.PTR L.I8, L.VAR nestArg2)]
             o last (L.BR (contLabel, [(L.PTR L.I8, L.VAR trampPtr2)])))
          o label (contLabel, [(L.PTR L.I8, trampPtr)])
          o callIntrinsic (SOME resultVar2) llvm_adjust_trampoline
                          [(L.PTR L.I8, L.VAR trampPtr)]
          o insn1 (L.CONV (#id resultVar, L.BITCAST,
                           (L.PTR L.I8, L.VAR resultVar2),
                           compileTy (#ty resultVar)))
        end
      | M.MCEXVAR {resultVar, id, loc} =>
        let
          val ty = compileTy (#ty resultVar)
        in
          case ExternSymbol.Map.find (#exportMap env, id) of
            NONE =>
            (case ExternSymbol.Map.find
                    (#extern (#externDecls (#constEnv env)), id) of
               NONE => raise Bug.Bug "compileMid: MCEXVAR"
             | SOME {used, ...} => used := true;
             insn1 (L.LOAD (#id resultVar,
                            ty,
                            (L.PTR ty,
                             L.CONST (L.SYMBOL (externSymbolToSymbol id))))))
          | SOME {gvarAddr = (_, const), ...} =>
            insn1 (L.LOAD (#id resultVar, ty, (L.PTR ty, L.CONST const)))
        end
      | M.MCMEMCPY_FIELD {dstAddr, srcAddr, copySize, loc} =>
        let
          val (insns1, _, dstAddr) = compileAddress env dstAddr
          val (insns2, _, srcAddr) = compileAddress env srcAddr
          val copySize = compileValue env copySize
        in
          insns1
          o insns2
          o callIntrinsic NONE llvm_memcpy
                          [dstAddr, srcAddr, copySize,
                           (L.I32, L.CONST (L.INTCONST 0w1)),
                           (L.I1, L.CONST (L.INTCONST 0w0))]
        end
      | M.MCMEMMOVE_UNBOXED_ARRAY {dstAddr, srcAddr, numElems, elemSize, loc} =>
        let
          val (insns1, _, dstAddr) = compileAddress env dstAddr
          val (insns2, _, srcAddr) = compileAddress env srcAddr
          val numElems = compileValue env numElems
          val elemSize = compileValue env elemSize
          val size = VarID.generate ()
        in
          insns1
          o insns2
          o insn1 (L.OP2 (size, L.MUL L.NUW, numElems, elemSize))
          o callIntrinsic NONE llvm_memmove
                          [dstAddr, srcAddr,
                           (#1 elemSize, L.VAR size),
                           (L.I32, L.CONST (L.INTCONST 0w1)),
                           (L.I1, L.CONST (L.INTCONST 0w0))]
        end
      | M.MCMEMMOVE_BOXED_ARRAY {dstArray, srcArray, dstIndex, srcIndex,
                                 numElems, loc} =>
        let
          val (insns1, dstArray) =
              bitcast (compileValue env dstArray, L.PTR (L.PTR L.I8))
          val (insns2, srcArray) =
              bitcast (compileValue env srcArray, L.PTR (L.PTR L.I8))
          val dstIndex = compileValue env dstIndex
          val srcIndex = compileValue env srcIndex
          val numElems = compileValue env numElems
        in
          insns1
          o insns2
          (* sml_copyary may call sml_write *)
          o callIntrinsic NONE sml_save nil
          o callIntrinsic NONE sml_copyary
                          [srcArray, srcIndex, dstArray, dstIndex, numElems]
          o callIntrinsic NONE sml_unsave nil
        end
      | M.MCALLOC {resultVar, objType, payloadSize, allocSize, loc} =>
        let
          val allocSize = compileValue env allocSize
          val payloadSize = compileValue env payloadSize
          val (headerInsn, headerWord) =
              makeHeaderWord env (objType, payloadSize)
          val header = VarID.generate ()
        in
          callIntrinsic (SOME (#id resultVar)) sml_alloc [allocSize]
          o headerInsn
          o objectHeaderAddress (header, (L.PTR L.I8, L.VAR (#id resultVar)))
          o insn1 (L.STORE {dst = (L.PTR (#1 headerWord), L.VAR header),
                            value = headerWord})
        end
      | M.MCALLOC_COMPLETED =>
        empty
      | M.MCCHECK {handler} =>
        let
          val check_flag = referIntrinsicVar sml_check_flag
          val onLabel = FunLocalLabel.generate nil
          val offLabel = FunLocalLabel.generate nil
          val flag = VarID.generate ()
          val cmpResult = VarID.generate ()
          val flagValue = (L.I32, L.VAR flag)
        in
          scope
            (insns [L.LOAD_ATOMIC (flag, L.I32, check_flag,
                                   {order = L.UNORDERED, align = 0w4}),
                    L.ICMP (cmpResult, L.EQ, flagValue,
                            (L.I32, L.CONST (L.INTCONST 0w0)))]
             o scope
                 (last (L.BR_C ((L.I1, L.VAR cmpResult),
                                (offLabel, nil),
                                (onLabel, nil))))
             o label (onLabel, nil)
             o invokeIntrinsic NONE sml_check handler [flagValue]
             o last (L.BR (offLabel, nil)))
          o label (offLabel, nil)
        end
      | M.MCRECORDDUP_ALLOC {resultVar, copySizeVar, recordExp, loc} =>
        let
          val recordExp = compileValue env recordExp
        in
          objectAllocSize (#id copySizeVar, recordExp)
          o callIntrinsic (SOME (#id resultVar)) sml_alloc
                          [(L.I32, L.VAR (#id copySizeVar))]
        end
      | M.MCRECORDDUP_COPY {dstRecord, srcRecord, copySize, loc} =>
        let
          val dstRecord = compileValue env dstRecord
          val srcRecord = compileValue env srcRecord
          val copySize = compileValue env copySize
          val srcHeader = VarID.generate ()
          val dstHeader = VarID.generate ()
          val dstHeaderAddr = VarID.generate ()
        in
          objectHeader (srcHeader, srcRecord)
          (* do not copy FLAG_SKIP from srcRecord to dstRecord *)
          o insn1 (L.OP2 (dstHeader, L.AND,
                          (objHeaderTy, L.VAR srcHeader),
                          (objHeaderTy,
                           L.CONST (L.INTCONST (Word64.notb FLAG_SKIP)))))
          o objectHeaderAddress (dstHeaderAddr, dstRecord)
          o insn1 (L.STORE {dst = (L.PTR objHeaderTy, L.VAR dstHeaderAddr),
                            value = (objHeaderTy, L.VAR dstHeader)})
          o callIntrinsic NONE llvm_memcpy
                          [dstRecord,
                           srcRecord,
                           copySize,
                           (L.I32, L.CONST (L.INTCONST 0w1)),
                           (L.I1, L.CONST (L.INTCONST 0w0))]
        end
      | M.MCBZERO {recordExp, recordSize, loc} =>
        let
          val record = compileValue env recordExp
          val size = compileValue env recordSize
        in
          callIntrinsic NONE llvm_memset
                        [record,
                         (L.I8, L.CONST (L.INTCONST 0w0)),
                         size,
                         (L.I32, L.CONST (L.INTCONST 0w1)),
                         (L.I1, L.CONST (L.INTCONST 0w0))]
        end
      | M.MCSAVESLOT {slotId, value, loc} =>
        let
          val dstAddr =
              case SlotID.Map.find (#slotAddrMap env, slotId) of
                NONE => raise Bug.Bug "compileExp: MCSAVESLOT"
              | SOME addr => addr
          val value = compileValue env value
        in
          insn1 (L.STORE {dst = dstAddr, value = value})
        end
      | M.MCLOADSLOT {resultVar, slotId, loc} =>
        let
          val srcAddr =
              case SlotID.Map.find (#slotAddrMap env, slotId) of
                NONE => raise Bug.Bug "compileExp: MCLOADSLOT"
              | SOME addr => addr
        in
          insn1 (L.LOAD (#id resultVar, compileTy (#ty resultVar), srcAddr))
        end
      | M.MCLOAD {resultVar, srcAddr, loc} =>
        let
          val (insns1, _, srcAddr) = compileAddress env srcAddr
          val resultTy = compileTy (#ty resultVar)
          val (insns2, srcAddr) = bitcast (srcAddr, L.PTR resultTy)
        in
          insns1
          o insns2
          o insn1 (L.LOAD (#id resultVar, compileTy (#ty resultVar), srcAddr))
        end
      | M.MCPRIMAPPLY {resultVar, primInfo={primitive,...}, argExpList,
                       argTyList, resultTy, instTyList, instTagList,
                       instSizeList, loc} =>
        let
          val args = map (compileValue env) argExpList
          val sizes = map (compileValue env) instSizeList
          val _ = ListPair.mapEq (assertType "MCPRIMAPPLY2")
                                 (map compileTy argTyList, map #1 args)
        in
          compilePrim env {prim = primitive,
                           retTy = #2 resultTy,
                           argTys = map #2 argTyList,
                           resultTy = compileTy resultTy,
                           result = #id resultVar,
                           sizes = sizes,
                           args = args}
        end
      | M.MCBITCAST {resultVar, exp, expTy, targetTy, loc} =>
        let
          val exp = compileValue env exp
          val targetTy = compileTy targetTy
        in
          case (#1 exp, targetTy) of
            (L.PTR _, L.PTR _) =>
            insn1 (L.CONV (#id resultVar, L.BITCAST, exp, targetTy))
          | (L.PTR _, L.I32) =>
            insn1 (L.CONV (#id resultVar, L.PTRTOINT, exp, targetTy))
          | (L.PTR _, L.I64) =>
            insn1 (L.CONV (#id resultVar, L.PTRTOINT, exp, targetTy))
          | (L.I32, L.PTR _) =>
            insn1 (L.CONV (#id resultVar, L.INTTOPTR, exp, targetTy))
          | (L.I64, L.PTR _) =>
            insn1 (L.CONV (#id resultVar, L.INTTOPTR, exp, targetTy))
          | _ =>
            insn1 (L.CONV (#id resultVar, L.BITCAST, exp, targetTy))
        end
      | M.MCCALL {resultVar, resultTy, codeExp, closureEnvExp, instTyList,
                  argExpList, tail, handler, loc} =>
        let
          val codePtr = compileValue env codeExp
          val clsEnv = Option.map (compileValue env) closureEnvExp
          val argList = map (fn v => ([L.INREG], compileValue env v)) argExpList
          val args =
              case clsEnv of
                NONE => argList
              | SOME v => ([L.INREG], (L.PTR L.I8, #2 v)) :: argList
          val result = Option.map compileVarInfo resultVar
          val funTy =
              {argTys = map (fn (x,(y,z)) => (y,x)) args,
               varArg = false,
               retTy = case resultTy of
                         (_, {rep = T.DATA T.LAYOUT_SINGLE, ...}) => L.VOID
                       | _ => compileTy resultTy,
               cconv = SOME L.FASTCC}
          (*

*)
          val tail =
              if not tail
              (*
               * It is not a good idea to add "tail" annotation to calls
               * not in a tail position because an unnecessary "tail" would
               * yield incorrect code.  The following is an example that
               * causes the incorrectness:
               *
               *  declare void @llvm.gcroot(i8**, i8* )
               *  declare i32 @join(i8* ) gc "smlsharp"
               *  declare i8* @create() gc "smlsharp"
               *  define fastcc i32 @start(i32 %arg) gc "smlsharp" {
               *    %v1 = alloca i8*
               *    call void @llvm.gcroot(i8** %v1, i8* null)
               *    %v3 = icmp slt i32 %arg, 2
               *    br i1 %v3, label %L55, label %L54
               *  L55:
               *    ret i32 0
               *  L54:
               *    %v8 = sub nsw i32 %arg, 1
               *    %v9 = call fastcc i8* @create()
               *    store i8* %v9, i8** %v1      ;;; MANDATORY
               *    %v11 = tail call fastcc i32 @start(i32 %v8)  ;; [*1]
               *    %v12 = load i8*, i8** %v1    ;;; MANDATORY
               *    %v13 = tail call fastcc i32 @join(i8* %v12)
               *    ret i32 %v13
               *  }
               *
               * The "store" and "load" marked MANDATORY are required to
               * maintain the root set for GC.  However, "opt -O1" command
               * eliminates these two operations.  By removing "tail"
               * annotation from [*1] avoids this unexpected elimination.
               *)
              then NONE
              else if !Control.useMustTail
                      andalso isMustTailAllowed (#funTy env, funTy)
              then SOME L.MUSTTAIL
              (*
               * LLVM's tail call optimization changes the size of stack frames
               * due to calling convention requiring that some arguments must
               * be in stack; therefore, it is not always compatible with LLVM's
               * GC support.  To avoid this incompatibility, we turn on the tail
               * call optimization only if both callee and caller does not have
               * any stack arguments.
               *
               * FIXME: We assume that first three arguments are passed
               * in registers.
               *)
              else if length (#argTys funTy) <= 3
                      andalso length (#argTys (#funTy env)) <= 3
              then SOME L.TAIL
              else NONE
        in
          callInsn {result = result,
                    tail = tail,
                    cconv = SOME L.FASTCC,
                    retAttrs = nil,
                    fnPtr = codePtr,
                    args = args,
                    unwind = handler,
                    fnAttrs = nil}
        end
      | M.MCSTORE {srcExp, srcTy, dstAddr, barrier, loc} =>
        let
          val elemTy = compileTy srcTy
          val (insns1, objAddr, dstAddr) = compileAddress env dstAddr
          val src = compileValue env srcExp
          val (insns2, dstAddr) = bitcast (dstAddr, L.PTR elemTy)
          val insns3 =
              if barrier
              then callIntrinsic NONE sml_write [objAddr, dstAddr, src]
              else insn1 (L.STORE {dst = dstAddr, value = src})
        in
          insns1
          o insns2
          o insns3
        end
      | M.MCEXPORTVAR {id, ty, valueExp, loc} =>
        let
          val value = compileValue env valueExp
        in
          case ExternSymbol.Map.find (#exportMap env, id) of
            NONE =>
            insn1 (L.STORE
                     {dst = (L.PTR (compileTy ty),
                             L.CONST (L.SYMBOL (externSymbolToSymbol id))),
                      value = value})
          | SOME {gvarAddr = (dstTy, dst), gvarArray, ...} =>
            case ty of
              (_, {tag = T.BOXED, ...}) =>
              callIntrinsic NONE sml_write
                            [gvarArray, (dstTy, L.CONST dst), value]
            | _ =>
              insn1 (L.STORE {dst = (dstTy, L.CONST dst), value = value})
        end
      | M.MCKEEPALIVE {value, loc} =>
        empty

  fun compileLast (env:env) mcexp_last =
      case mcexp_last of
        M.MCRETURN {value, loc} =>
        #returnInsns env (compileValue env value)
      | M.MCRAISE {argExp, cleanup, loc} =>
        let
          val argExp = compileValue env argExp
        in
          invokeIntrinsic NONE sml_raise cleanup [argExp]
          o last L.UNREACHABLE
        end
      | M.MCHANDLER {nextExp, id, exnVar, handlerExp, cleanup, loc} =>
        let
          val kind = {catch = true, cleanup = isSome cleanup}
          val nextEnv = bindHandlerLabel env (id, kind)
          val ueVar = VarID.generate ()
          val argVar = VarID.generate ()
          val arg2Var = VarID.generate ()
          val jumpInsn =
              case cleanup of
                NONE => empty
              | SOME cleanupLabel =>
                jumpIfNull (L.PTR L.I8, L.VAR argVar)
                           (jumpToLandingPad (cleanupLabel, ueVar, argVar))
        in
          landingPad
            env
            (id, kind, ueVar, argVar,
             jumpInsn
             o insns [L.CONV (arg2Var, L.BITCAST, (L.PTR L.I8, L.VAR argVar),
                              L.PTR (L.PTR L.I8)),
                      L.LOAD (#id exnVar, L.PTR L.I8,
                              (L.PTR (L.PTR L.I8), L.VAR arg2Var))]
             o compileExp env handlerExp
             o ignore)
          o compileExp nextEnv nextExp
        end
      | M.MCSWITCH {switchExp, expTy, branches, default, loc} =>
        let
          val switchValue = compileValue env switchExp
          val _ = if isIntTy (#1 switchValue)
                  then () else raise Bug.Bug "compileExp: MCSWITCH"
          val constTy = compileTy expTy
          val branches =
              map (fn (const, label) =>
                      ((constTy, compileConst (#constEnv env) const),
                       (label, nil)))
                  branches
        in
          last (L.SWITCH {value = switchValue,
                          default = (default, nil),
                          branches = branches})
        end
      | M.MCLOCALCODE {recursive, binds, nextExp, loc} =>
        foldl
          (fn ({id, argVarList, bodyExp}, z) =>
              scope z
              o label (id, map compileVarInfo argVarList)
              o compileExp env bodyExp)
          (compileExp env nextExp)
          binds
      | M.MCGOTO {id, argList, loc} =>
        last (L.BR (id, map (compileValue env) argList))
      | M.MCUNREACHABLE =>
        last L.UNREACHABLE

  and compileExp env ((mids, last):M.mcexp) =
      let
        val mids = map (compileMid env) mids
        val last = compileLast env last
        val body = foldr (fn (f,z) => f z) (last ()) mids
      in
        fn () => body
      end

  fun allocSlots slotMap =
      SlotID.Map.foldli
        (fn (slotId, rty, (allocInsns, gcrootInsns, slotMap)) =>
            let
              val ty = compileRuntimeTy rty
              val varId = VarID.generate ()
            in
              (allocInsns o insn1 (L.ALLOCA (varId, ty, NONE)),
               case rty of
                 {tag = T.BOXED, ...} =>
                 gcrootInsns
                 o callIntrinsic NONE llvm_gcroot
                                 [(L.PTR ty, L.VAR varId),
                                  nullOperand]
               | {tag = T.UNBOXED, ...} =>
                 gcrootInsns,
               SlotID.Map.insert (slotMap, slotId, (L.PTR ty, L.VAR varId)))
            end)
        (empty, empty, SlotID.Map.empty)
        slotMap

  fun compileTop {constEnv, exportMap}
                 {frameSlots, bodyExp, cleanupHandler,
                  argTys, varArg, cconv, retTy} =
      let
        val retLabel = FunLocalLabel.generate nil
        val (retTy, goto, retArgs, return) =
            case retTy of
              NONE =>
              (L.VOID, fn _ => last (L.BR (retLabel, [])), [], L.RET_VOID)
            | SOME (_, {rep = T.DATA T.LAYOUT_SINGLE, ...}) =>
              (L.VOID, fn x => last (L.BR (retLabel, [])), [], L.RET_VOID)
            | SOME ty =>
              let
                val retTy = compileTy ty
                val arg = VarID.generate ()
              in
                (retTy,
                 fn x => last (L.BR (retLabel, [x])),
                 [(retTy, arg)],
                 L.RET (retTy, L.VAR arg))
              end
        val (allocInsns1, gcrootInsns, slotMap) = allocSlots frameSlots
        val personality = ref NONE
        val env = {slotAddrMap = slotMap,
                   constEnv = constEnv,
                   exportMap = exportMap,
                   handlerMap = HandlerLabel.Map.empty,
                   funTy = {argTys = argTys,
                            varArg = varArg,
                            cconv = cconv,
                            retTy = retTy},
                   personality = SOME personality,
                   returnInsns = goto} : env
        val (bodyEnv, cleanupInsn) =
            case cleanupHandler of
              NONE => (env, empty)
            | SOME id =>
              let
                val ueVar = VarID.generate ()
                val argVar = VarID.generate ()
              in
                (bindHandlerLabel env (id, {catch=false, cleanup=true}),
                 landingPad
                   env
                   (id, {catch=false, cleanup=true},
                    ueVar, argVar,
                    callIntrinsic NONE sml_save_exn [(L.PTR L.I8, L.VAR argVar)]
                    o callIntrinsic NONE sml_end []))
              end
        val buf1 = VarID.generate ()
        val buf2 = VarID.generate ()
        val (allocInsns2, prologue, epilogue) =
            case bodyExp of
              (nil, M.MCRETURN _) => (empty, empty, empty)
            | _ =>
              (insn1 (L.ALLOCA (buf1, L.ARRAY (0w3, L.PTR L.I8), NONE)),
               insn1 (L.CONV (buf2, L.BITCAST,
                              (L.PTR (L.ARRAY (0w3, L.PTR L.I8)), L.VAR buf1),
                              L.PTR L.I8))
               o callIntrinsic NONE sml_start
                               [(L.PTR L.I8, L.VAR buf2)]
               o cleanupInsn,
               callIntrinsic NONE sml_end nil)
        val allocInsns =
            allocInsns2
            o allocInsns1
        val body =
            gcrootInsns
            o prologue
            o scope (compileExp bodyEnv bodyExp)
            o label (retLabel, retArgs)
            o epilogue
            o last return
      in
        (allocInsns, body, retTy, !personality)
      end

  fun compileTopdec env topdec =
      case topdec of
        M.MTFUNCTION {id, tyvarKindEnv, tyArgs, argVarList, closureEnvVar,
                      frameSlots, bodyExp, retTy, gcCheck, loc} =>
        let
          val closureEnvArg =
              case closureEnvVar of
                NONE => nil
              | SOME {id, ty} => [(compileTy ty, [L.INREG], id)]
          val (retTy, returnInsns) =
              case retTy of
                (_, {rep = T.DATA T.LAYOUT_SINGLE, ...}) =>
                (L.VOID, fn v => last L.RET_VOID)
              | _ => (compileTy retTy, fn v => last (L.RET v))
          val args = map (fn {id, ty} => (compileTy ty, [L.INREG], id))
                         argVarList
          val params = closureEnvArg @ args
          val (allocInsns, gcrootInsns, slotMap) = allocSlots frameSlots
          val personality = ref NONE
          val env = {slotAddrMap = slotMap,
                     constEnv = #constEnv env,
                     exportMap = #exportMap env,
                     funTy = {argTys = map (fn (x,y,z) => (x,y)) params,
                              varArg = false,
                              retTy = retTy,
                              cconv = SOME L.FASTCC},
                     handlerMap = HandlerLabel.Map.empty,
                     personality = SOME personality,
                     returnInsns = returnInsns}
          val body =
              allocInsns
              o gcrootInsns
              o compileExp env bodyExp
          val (name, linkage, aliases) =
              case FunEntryLabel.Map.find
                     (#exFunEntryMap (#aliasMap (#constEnv env)), id) of
                SOME (h::t) => (externFunSymbolToSymbol h, SOME L.EXTERNAL, t)
              | _ => (funEntryLabelToSymbol id, SOME L.INTERNAL, nil)
        in
          L.DEFINE
            {linkage = linkage,
             cconv = SOME L.FASTCC,
             retAttrs = nil,
             retTy = retTy,
             name = name,
             parameters = params,
             fnAttrs = [L.UWTABLE],
             personality = !personality,
             gcname = gcname,
             body = body ()}
          :: map
               (fn id =>
                   L.ALIAS
                     {name = externFunSymbolToSymbol id,
                      ty = L.FN (retTy, map #1 params, false),
                      linkage = linkage,
                      unnamed_addr = false,
                      aliasee = (L.PTR (L.FN (retTy, map #1 params, false)),
                                 L.SYMBOL name)})
               aliases
        end
      | M.MTCALLBACKFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
                              frameSlots, bodyExp, attributes, retTy,
                              cleanupHandler, loc} =>
        let
          val args = map (fn {id,ty} => (compileTy ty, nil, id)) argVarList
          val (insns1, args) =
              case closureEnvVar of
                NONE => (empty, args)
              | SOME {id, ty} =>
                let
                  val ty = compileTy ty
                  val arg = VarID.generate ()
                in
                  (insn1 (L.LOAD (id, ty, (L.PTR ty, L.VAR arg))),
                   (L.PTR ty, [L.NEST], arg) :: args)
                end
          val cconv = compileCallConv (#callingConvention attributes)
          val (allocInsns, bodyInsns, retTy, personality) =
              compileTop env {frameSlots = frameSlots,
                              bodyExp = bodyExp,
                              cleanupHandler = cleanupHandler,
                              retTy = retTy,
                              argTys = map (fn (x,y,z) => (x,y)) args,
                              varArg = false,
                              cconv = cconv}
        in
          [L.DEFINE
             {linkage = SOME L.INTERNAL,
              cconv = cconv,
              retAttrs = nil,
              retTy = retTy,
              name = callbackEntryLabelToSymbol id,
              parameters = args,
              fnAttrs = [L.UWTABLE],
              personality = personality,
              gcname = gcname,
              body = (allocInsns o insns1 o bodyInsns) ()}]
        end

  fun makeRootArray toplevelName nil = (nil, (L.PTR L.I8, L.NULL))
    | makeRootArray toplevelName roots =
      let
        val intptrTy = intptrTy ()
        val numRoots = length roots
        val gcrootTy = L.ARRAY (Word.fromInt (1 + numRoots), intptrTy)
        val smlrootName = ToplevelSymbol.rootName toplevelName
        val baseAddr = (L.PTR gcrootTy, L.SYMBOL smlrootName)
        val numRoots = Word64.fromInt numRoots
        fun ptrDiff p1 p2 =
            L.CONST_SUB (L.WRAP,
                         (intptrTy, L.CONST_PTRTOINT (p1, intptrTy)),
                         (intptrTy, L.CONST_PTRTOINT (p2, intptrTy)))
        fun offsetOf x =
            (intptrTy, L.INIT_CONST (ptrDiff (L.PTR L.I8, x) baseAddr))
      in
        (* this object is intended to be immutable, but we place it in
         * the same section as mutable objects so that the offset of the
         * mutables can be computed at compile time. *)
        ([L.GLOBALVAR
            {name = smlrootName,
             linkage = SOME L.PRIVATE,
             constant = false, (* must be false to avoid relocation *)
             unnamed_addr = true,
             ty = gcrootTy,
             align = NONE,
             initializer =
               L.INIT_ARRAY
                 ((intptrTy, L.INIT_CONST (L.INTCONST numRoots))
                  :: map offsetOf roots)}],
         baseAddr)
      end

  fun initializeModule isEmptyBody toplevelName depends sml_root =
      let
        val smlmainDepends = map (ToplevelSymbol.mainName o SOME) depends
        val smlloadDepends = map (ToplevelSymbol.loadName o SOME) depends
        val decs1 =
            map (fn name =>
                    L.DECLARE {linkage = NONE,
                               cconv = NONE,
                               retAttrs = nil,
                               retTy = L.VOID,
                               name = name,
                               arguments = nil,
                               varArg = false,
                               fnAttrs = [L.UWTABLE],
                               gcname = gcname})
                smlmainDepends
        val decs2 =
            map (fn name =>
                    L.DECLARE {linkage = NONE,
                               cconv = NONE,
                               retAttrs = nil,
                               retTy = L.VOID,
                               name = name,
                               arguments = [(L.PTR L.I8, nil)],
                               varArg = false,
                               fnAttrs = [],
                               gcname = NONE})
                smlloadDepends
        val smlmainCalls =
            map (fn name =>
                    L.CALL {result = NONE,
                            tail = SOME L.TAIL,
                            cconv = NONE,
                            retAttrs = nil,
                            fnPtr = (L.PTR (L.FN (L.VOID, [], false)),
                                     L.CONST (L.SYMBOL name)),
                            args = nil,
                            fnAttrs = [L.UWTABLE]})
                smlmainDepends
        val initArg = VarID.generate ()
        val smlloadCalls =
            map (fn name =>
                    L.CALL {result = NONE,
                            tail = SOME L.TAIL,
                            cconv = NONE,
                            retAttrs = nil,
                            fnPtr = (L.PTR (L.FN (L.VOID, [L.PTR L.I8], false)),
                                     L.CONST (L.SYMBOL name)),
                            args = [(nil, (L.PTR L.I8, L.VAR initArg))],
                            fnAttrs = []})
                smlloadDepends
        val smlmainName = ToplevelSymbol.mainName toplevelName
        val smlftabName = ToplevelSymbol.ftabName toplevelName
        val smltabbName = ToplevelSymbol.tabbName toplevelName
        val smlloadName = ToplevelSymbol.loadName toplevelName
        val smldoneName = ToplevelSymbol.doneName toplevelName
        val sml_main = (L.PTR (L.FN (L.VOID, [], false)), L.SYMBOL smlmainName)
        val sml_ftab = (L.PTR L.I8, L.SYMBOL smlftabName)
        val sml_tabb = (L.PTR (L.FN (L.VOID, [], false)), L.SYMBOL smltabbName)
        val sml_load = (L.PTR (L.FN (L.VOID, [L.PTR L.I8], false)),
                        L.SYMBOL smlloadName)
        val sml_done = (L.PTR L.I8, L.CONST (L.SYMBOL smldoneName))
        fun toPtr (const as (L.PTR L.I8, _)) = const
          | toPtr const = (L.PTR L.I8, L.CONST_BITCAST (const, L.PTR L.I8))
        fun intConst n = (L.I8, L.CONST (L.INTCONST n))
      in
        (decs1 @ decs2 @
         [L.EXTERN (* generated by smlsharp_gc plugin *)
            {name = smlftabName,
             ty = L.I8},
          L.GLOBALVAR
            {name = smldoneName,
             linkage = SOME L.PRIVATE,
             constant = false,
             unnamed_addr = true,
             ty = L.I8,
             align = NONE,
             initializer = L.ZEROINITIALIZER},
          L.DEFINE
            {linkage = SOME L.PRIVATE,
             cconv = NONE,
             retAttrs = nil,
             retTy = L.VOID,
             name = smltabbName,
             parameters = [],
             fnAttrs = [L.NAKED],
             personality = NONE,
             gcname = NONE,
             body = (nil, L.UNREACHABLE)},
          let
            val v1 = VarID.generate ()
            val thenLabel = FunLocalLabel.generate nil
          in
            L.DEFINE
              {linkage = NONE,
               cconv = NONE,
               retAttrs = nil,
               retTy = L.VOID,
               name = smlloadName,
               parameters = [(L.PTR L.I8, [], initArg)],
               fnAttrs = [L.NOUNWIND],
               personality = NONE,
               gcname = NONE,
               body =
                 (scope
                    (insn1 (L.LOAD (v1, L.I8, sml_done))
                     o jumpIfZero (L.I8, L.VAR v1) (thenLabel, nil)
                     o last L.RET_VOID)
                  o label (thenLabel, [])
                  o insn1 (L.STORE {value = (L.I8, L.CONST (L.INTCONST 0w1)),
                                    dst = sml_done})
                  o insns smlloadCalls
                  o callIntrinsic NONE sml_gcroot
                                  [(L.PTR L.I8, L.VAR initArg),
                                   constToValue sml_tabb,
                                   constToValue sml_ftab,
                                   constToValue (toPtr sml_root)]
                  o last L.RET_VOID)
                   ()}
          end],
         [let
            val v1 = VarID.generate ()
          in
            L.DEFINE
              {linkage = SOME L.WEAK,
               cconv = NONE,
               retAttrs = nil,
               retTy = L.VOID,
               name = "sml_load",
               parameters = [(L.PTR L.I8, [], v1)],
               fnAttrs = nil,
               personality = NONE,
               gcname = NONE,
               body = (insn1 (L.CALL {result = NONE,
                                      tail = SOME L.TAIL,
                                      cconv = NONE,
                                      retAttrs = nil,
                                      fnPtr = constToValue sml_load,
                                      args = [(nil, (L.PTR L.I8, L.VAR v1))],
                                      fnAttrs = [L.UWTABLE, L.NOINLINE]})
                       o last L.RET_VOID)
                        ()}
          end],
         smlmainName,
         sml_main,
         case (isEmptyBody, smlmainCalls) of
           (_, nil) => empty
         | (true, call::nil) => insn1 call
         | _ =>
           let
             val v1 = VarID.generate ()
             val v2 = VarID.generate ()
             val thenLabel = FunLocalLabel.generate nil
           in
             scope
               (insns [L.LOAD (v1, L.I8, sml_done),
                       L.OP2 (v2, L.AND, (L.I8, L.VAR v1),
                              (L.I8, L.CONST (L.INTCONST 0w2)))]
                o jumpIfZero (L.I8, L.VAR v2) (thenLabel, nil)
                o last L.RET_VOID)
             o label (thenLabel, [])
             o insn1 (L.STORE {value = (L.I8, L.CONST (L.INTCONST 0w3)),
                               dst = sml_done})
             o insns smlmainCalls
           end)
      end

  fun compileToplevel env roots {toplevelName, initRequisites}
                      {frameSlots, bodyExp, cleanupHandler} =
      let
        val (rootArrayDecs, sml_root) = makeRootArray toplevelName roots
        val emptyBody =
            case bodyExp of
              (nil, M.MCRETURN _) => true
            | _ => false
        val (allocInsns, bodyInsns, _, personality) =
            compileTop env
                       {frameSlots = frameSlots,
                        bodyExp = bodyExp,
                        cleanupHandler = cleanupHandler,
                        retTy = NONE,
                        argTys = nil,
                        varArg = false,
                        cconv = NONE}
        (* listUsedExternDecls must be performed after compileTop *)
        val (providers, externDecls) =
            ListPair.unzip (listUsedExternDecls (#externDecls (#constEnv env)))
        val needInit =
            foldl
              (fn (I.OTHER {hash, ...}, z) =>
                  SSet.add (z, InterfaceName.hashToString hash)
               | (_, z) => z)
              SSet.empty
              providers
        val depends =
            List.mapPartial
              (fn (I.INIT_ALWAYS, name) => SOME name
                | (I.INIT_IFNEEDED, name as {hash, ...}) =>
                  if SSet.member (needInit, InterfaceName.hashToString hash)
                  then SOME name else NONE)
              initRequisites
        val (loadDecs, weakDecs1, smlmainName, sml_main, initInsns) =
            initializeModule emptyBody toplevelName depends sml_root
        val mainDecs =
            [L.DEFINE
               {linkage = NONE,
                cconv = NONE,
                retAttrs = nil,
                retTy = L.VOID,
                name = smlmainName,
                parameters = [],
                fnAttrs = [L.UWTABLE],
                personality = personality,
                gcname = gcname,
                body = (allocInsns o initInsns o bodyInsns) ()}]
        val weakDecs2 =
            [L.DEFINE
               {linkage = SOME L.WEAK,
                cconv = NONE,
                retAttrs = nil,
                retTy = L.VOID,
                name = "sml_main",
                parameters = [],
                fnAttrs = nil,
                personality = NONE,
                gcname = NONE,
                body = (insn1 (L.CALL {result = NONE,
                                       tail = SOME L.TAIL,
                                       cconv = NONE,
                                       retAttrs = nil,
                                       fnPtr = constToValue sml_main,
                                       args = nil,
                                       fnAttrs = [L.UWTABLE, L.NOINLINE]})
                        o last L.RET_VOID) ()}]
      in
        (externDecls,
         rootArrayDecs @ loadDecs @ mainDecs,
         weakDecs1 @ weakDecs2)
      end

  fun pad (i, j) =
      if i > j then raise Bug.Bug "pad"
      else if i = j then nil
      else [(L.ARRAY (j - i, L.I8), L.ZEROINITIALIZER)]

  fun compileInitConst constEnv const =
      case compileTopConst constEnv const of
        (ty, const) => (ty, L.INIT_CONST const)

  fun allocTopArray toplevelName topdataList =
      let
        val exports =
            List.mapPartial
              (fn M.NTEXPORTVAR {id, weak=false, ty=(_,{tag=T.BOXED,...}),
                                 value=NONE, loc} => SOME id
                | _ => NONE)
              topdataList
      in
        case exports of
          nil => (nil, ExternSymbol.Map.empty, nil)
        | _::_ =>
          let
            val numExports = length exports
            val header =
                makeHeaderWordStatic
                  (M.OBJTYPE_ARRAY
                     (M.ANCONST
                        {const = M.NVTAG {tag=T.BOXED, ty=Types.ERRORty},
                         ty = (Types.ERRORty, T.word32Ty)}),
                   Word64.fromInt (pointerSize () * numExports))
            val exportArrayTy =
                L.ARRAY (Word.fromInt (length exports), L.PTR L.I8)
            val data =
                pad (objHeaderSize, Word.fromInt (pointerSize ()))
                @ [header, (exportArrayTy, L.ZEROINITIALIZER)]
            val dataTy = L.STRUCT (map #1 data, {packed=true})
            val arrayOffset =
                Word64.fromInt (length data - 1)
            val gvarName = ToplevelSymbol.gvarName toplevelName
            fun gvarElem i =
                (L.PTR (L.PTR L.I8),
                 L.CONST_GETELEMENTPTR
                   {inbounds = true,
                    ty = dataTy,
                    ptr = (L.PTR dataTy, L.SYMBOL gvarName),
                    indices = [(L.I32, L.INTCONST 0w0),
                               (L.I32, L.INTCONST arrayOffset),
                               (L.I32, L.INTCONST (Word64.fromInt i))]})
            val gvarObj = L.CONST_BITCAST (gvarElem 0, L.PTR L.I8)
            val gvarObjValue = (L.PTR L.I8, L.CONST gvarObj)
          in
            ([L.GLOBALVAR
                {name = gvarName,
                 linkage = SOME L.PRIVATE,
                 unnamed_addr = false,
                 constant = false,
                 ty = dataTy,
                 initializer = L.INIT_STRUCT (data, {packed=true}),
                 align = SOME (pointerSize ())}],
             foldli (fn (id,i,z) =>
                        ExternSymbol.Map.insert
                          (z, id, {aliaseeTy = L.PTR L.I8,
                                   gvarAddr = gvarElem i,
                                   gvarArray = gvarObjValue}))
                    ExternSymbol.Map.empty
                    exports,
             [gvarObj])
          end
      end

  fun allocTopData {id, payloadSize, mutable, coalescable, objType,
                    includesBoxed, data} =
      let
        val payloadSize = Word32.toLarge payloadSize
        val header = makeHeaderWordStatic (objType, payloadSize)
        val data = pad (0w0, dataLabelOffset - objHeaderSize) @ [header] @ data
        val ty = L.STRUCT (map #1 data, {packed=true})
        val label = dataLabelToSymbol id
        val objptr =
            L.CONST_GETELEMENTPTR
              {inbounds = true,
               ty = L.I8,
               ptr = (L.PTR L.I8,
                      L.CONST_BITCAST ((L.PTR ty, L.SYMBOL label), L.PTR L.I8)),
               indices = [(L.I32, L.INTCONST (Word32.toLarge dataLabelOffset))]}
      in
        ([L.GLOBALVAR {name = label,
                       linkage = SOME L.PRIVATE,
                       unnamed_addr = coalescable,
                       constant = not mutable,
                       ty = ty,
                       initializer = L.INIT_STRUCT (data, {packed=true}),
                       align = SOME maxSize}],
         singletonAlias (id, objptr),
         emptyExternDecls,
         if mutable andalso includesBoxed then [objptr] else nil)
      end

  fun compileTopdata {constEnv, exportMap} topdata =
      case topdata of
        M.NTEXTERNVAR {id, ty, provider, loc} =>
        let
          val dec =
              L.EXTERN
                {name = externSymbolToSymbol id,
                 ty = compileTy ty}
        in
          (nil,
           emptyAliasMap,
           singletonExtern (id, provider, SOME dec),
           nil)
        end
      | M.NTEXPORTVAR {id, weak, ty, value, loc} =>
        (case ExternSymbol.Map.find (exportMap, id) of
           SOME {aliaseeTy, gvarAddr, ...} =>
           [L.ALIAS
              {name = externSymbolToSymbol id,
               ty = aliaseeTy,
               linkage = NONE,
               unnamed_addr = false,
               aliasee = gvarAddr}]
         | NONE =>
           case (ty, value) of
             ((_,{tag=T.BOXED,...}), NONE) => raise Bug.Bug "NTEXPORTVAR"
           | _ =>
             [L.GLOBALVAR
                {name = externSymbolToSymbol id,
                 linkage = if weak then SOME L.WEAK else NONE,
                 unnamed_addr = weak,
                 constant = isSome value,
                 ty = compileTy ty,
                 initializer =
                   case value of
                     SOME v => L.INIT_CONST (#2 (compileTopConst constEnv v))
                   | NONE => L.ZEROINITIALIZER,
                 align = NONE}],
         emptyAliasMap,
         singletonExtern (id, I.SELF, NONE),
         nil)
      | M.NTEXTERNFUN {id, tyvars, argTyList, retTy, provider, loc} =>
        let
          val dec =
              L.DECLARE
                {linkage = NONE,
                 cconv = NONE,
                 retAttrs = nil,
                 retTy = case retTy of
                           (_, {rep = T.DATA T.LAYOUT_SINGLE, ...}) => L.VOID
                         | _ => compileTy retTy,
                 name = externFunSymbolToSymbol id,
                 arguments = map (fn ty => (compileTy ty, [L.INREG])) argTyList,
                 varArg = false,
                 fnAttrs =  [L.UWTABLE],
                 gcname = gcname}
        in
          (nil,
           emptyAliasMap,
           singletonExternFun (id, provider, dec),
           nil)
        end
      | M.NTEXPORTFUN {id, funId, loc} =>
        (nil,
         singletonAliasFunEntry (funId, id),
         emptyExternDecls,
         nil)
      | M.NTSTRING {id, string, loc} =>
        let
          val len = Word32.fromInt (size string + 1)
        in
          allocTopData
            {id = id,
             payloadSize = len,
             mutable = false,
             coalescable = true,
             objType = M.OBJTYPE_UNBOXED_VECTOR,
             includesBoxed = false,
             data = [(L.ARRAY (len, L.I8),
                      L.INIT_STRING (string ^ "\000"))]}
        end
      | M.NTINTINF {id, value, loc} =>
        let
          val src = CharVector.map (fn #"~" => #"-" | x => x)
                                   (IntInf.fmt StringCvt.HEX value)
          val ty = L.ARRAY (Word32.fromInt (size src + 1), L.I8)
          val label = extraDataLabelToSymbol id
        in
          ([L.GLOBALVAR
              {name = label,
               linkage = SOME L.PRIVATE,
               unnamed_addr = true,
               constant = true,
               ty = ty,
               initializer = L.INIT_STRING (src ^ "\000"),
               align = NONE}],
           singletonAliasExtra
             (id, L.CONST_GETELEMENTPTR
                    {inbounds = true,
                     ty = ty,
                     ptr = (L.PTR ty, L.SYMBOL label),
                     indices = [(L.I32, L.INTCONST 0w0),
                                (L.I32, L.INTCONST 0w0)]}),
           emptyExternDecls,
           nil)
        end
      | M.NTRECORD {id, tyvarKindEnv, recordTy=_, fieldList, isMutable,
                    isCoalescable, clearPad, bitmaps, loc} =>
        let
          (* FIXME : optimize bitmap *)
          val includesBoxed =
              List.exists
                (fn {fieldExp=(_,(_,{tag=T.BOXED,...})),...} => true
                  | _ => false)
                fieldList
          val fields =
              map (fn {fieldExp, fieldSize, fieldIndex} =>
                      (compileTopConst constEnv fieldExp,
                       compileTopConstWord32 fieldIndex,
                       compileTopConstWord32 fieldSize))
                  fieldList
          val bitmaps =
              map (fn {bitmapIndex, bitmapExp} =>
                      (compileInitConst constEnv bitmapExp,
                       compileTopConstWord32 bitmapIndex))
                  bitmaps
          val (bitmapIndex, bitmaps) =
              case bitmaps of
                (_,i)::_ => (i, map #1 bitmaps)
              | _ => raise Bug.Bug "compileTopdata: NTRECORD: no bitmap record"
          val fields =
              ListSorter.sort (fn ((_,i,_),(_,j,_)) => Word32.compare (i, j))
                              fields
          fun pack index (((t, c), i, s)::fields) =
              pad (index, i) @ (t, L.INIT_CONST c) :: pack (i + s) fields
            | pack index nil =
              pad (index, bitmapIndex) @ bitmaps
        in
          allocTopData
            {id = id,
             payloadSize = bitmapIndex,
             mutable = isMutable,
             coalescable = isCoalescable,
             objType = M.OBJTYPE_RECORD,
             includesBoxed = includesBoxed,
             data = pack 0w0 fields}
        end
      | M.NTARRAY {id, elemTy, isMutable, isCoalescable, clearPad, numElements,
                   initialElements, elemSizeExp, tagExp, loc} =>
        let
          val includesBoxed =
              case elemTy of (_,{tag=T.BOXED,...}) => true | _ => false
          val initialElements =
              map (compileInitConst constEnv) initialElements
          val numElements = compileTopConstWord32 numElements
          val elemTy = compileTy elemTy
          val elemSize = compileTopConstWord32 elemSizeExp
          val tagExp = M.ANCONST {const = #1 tagExp, ty = #2 tagExp}
          val objType = if isMutable
                        then M.OBJTYPE_ARRAY tagExp
                        else M.OBJTYPE_VECTOR tagExp
          val allocSize = Word32.* (numElements, elemSize)
          val numInitialElements = Word32.fromInt (length initialElements)
          val op > = Word32.>
          val op - = Word32.-
          val filler =
              if numElements > numInitialElements
              then [(L.ARRAY (numElements - numInitialElements, elemTy),
                     L.ZEROINITIALIZER)]
              else nil
        in
          allocTopData
            {id = id,
             payloadSize = allocSize,
             mutable = isMutable,
             coalescable = isCoalescable,
             objType = objType,
             includesBoxed = includesBoxed,
             data = initialElements @ filler}
        end

  fun compileTopdataList env nil = (nil, emptyAliasMap, emptyExternDecls, nil)
    | compileTopdataList env (dec::decs) =
      let
        val (decs1, aliasMap1, externs1, roots1) = compileTopdata env dec
        val (decs2, aliasMap2, externs2, roots2) = compileTopdataList env decs
      in
        (decs1 @ decs2,
         unionAliasMap (aliasMap1, aliasMap2),
         unionExternDecls (externs1, externs2),
         roots1 @ roots2)
      end

  fun compile {targetTriple} (prelude, {topdata, topdecs, toplevel}:M.program) =
      let
        val (topdecs, toplevel) = MachineCodeRename.rename (topdecs, toplevel)
        val _ = initForeignEntries ()
        val (topArrayDecs, exportMap, roots1) =
            allocTopArray (#toplevelName prelude) topdata
        val env = {constEnv = {aliasMap = emptyAliasMap,
                               externDecls = emptyExternDecls},
                   exportMap = exportMap}
        val (_, aliasMap, externDecls, _) = compileTopdataList env topdata
        val env = {constEnv = {aliasMap = aliasMap,
                               externDecls = externDecls},
                   exportMap = exportMap}
        val (topDataDecs, _, _, roots2) = compileTopdataList env topdata
        val topDecDecs = List.concat (map (compileTopdec env) topdecs)
        val (externDecs2, toplevelDecs, weakDecs) =
            compileToplevel env (roots1 @ roots2) prelude toplevel
        val externDecs1 = declareForeignEntries ()
      in
        {
          moduleName = "",
          datalayout = NONE,  (* FIXME *)
          triple = SOME targetTriple,
          topdecs =
            externDecs1 @ externDecs2
            @ topDataDecs  @ topArrayDecs
            @ weakDecs @ toplevelDecs @ topDecDecs
        } : L.program
      end

end
