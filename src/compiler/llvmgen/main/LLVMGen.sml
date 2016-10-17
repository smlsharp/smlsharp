(**
 * generate llvm ir
 *
 * @copyright (c) 2013, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure LLVMGen : sig

  val compile : {targetTriple : string}
                -> MachineCode.program
                -> LLVMIR.program

end =
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

  val gcname = SOME "smlsharp"

  fun foldli f z l =
      #2 (foldl (fn (x,(i,z)) => (i + 1, f (x,i,z))) (0, z) l)

  fun assertType loc (x, y:L.ty) =
      if x = y
      then ()
      else raise Bug.Bug
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

  fun intptrTy () =
      case TypeLayout2.sizeOf T.BOXEDty of
        4 => L.I32
      | 8 => L.I64
      | _ => raise Bug.Bug "FIXME: intptrTy"

  fun isIntTy ty =
      case ty of
        L.I1 => true
      | L.I8 => true
      | L.I16 => true
      | L.I32 => true
      | L.I64 => true
      | L.PTR _ => true
      | L.FLOAT => false
      | L.DOUBLE => false
      | L.VOID => false
      | L.FPTR _ => true
      | L.ARRAY _ => false
      | L.STRUCT _ => false

  fun compileCallConv cconv =
      case cconv of
        NONE => NONE
      | SOME FFIAttributes.FFI_CDECL => SOME L.CCC
      | SOME FFIAttributes.FFI_STDCALL => SOME L.X86STDCALLCC
      | SOME FFIAttributes.FFI_FASTCC => SOME L.FASTCC

  fun compileRuntimeTy rty =
      case rty of
        T.UNITty => L.PTR L.I8
      | T.UINT8ty => L.I8
      | T.INT32ty => L.I32
      | T.INT64ty => L.I64
      | T.UINT32ty => L.I32
      | T.UINT64ty => L.I64
      | T.BOXEDty => L.PTR L.I8
      | T.POINTERty => L.PTR L.I8
      | T.MLCODEPTRty {haveClsEnv, argTys, retTy} =>
        L.FPTR (case retTy of
                  SOME T.UNITty => L.VOID
                | _ => compileRuntimeTyOpt retTy,
                (if haveClsEnv then [L.PTR L.I8] else nil)
                @ map compileRuntimeTy argTys,
                false)
      | T.SOME_CODEPTRty => L.FPTR (L.VOID, nil, true)
      | T.FOREIGNCODEPTRty {argTys, varArgTys, retTy, attributes} =>
        L.FPTR (compileRuntimeTyOpt retTy,
                map compileRuntimeTy argTys,
                isSome varArgTys)
      | T.CALLBACKCODEPTRty {haveClsEnv, argTys, retTy, attributes} =>
        L.FPTR (compileRuntimeTyOpt retTy,
                (if haveClsEnv then [L.PTR L.I8] else nil)
                @ map compileRuntimeTy argTys,
                false)
      | T.DOUBLEty => L.DOUBLE
      | T.FLOATty => L.FLOAT
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
  val sml_register_top =
      R {name = "sml_register_top",
         tail = SOME L.TAIL,
         argTys = [L.PTR L.I8, L.PTR L.I8, L.PTR L.I8, L.PTR L.I8],
         argAttrs = [nil, nil, nil, nil],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
  val sml_start =
      R {name = "sml_start",
         tail = NONE,
         argTys = [L.PTR (L.PTR L.I8)],
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
         retTy = L.VOID,
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
         argTys = [],
         argAttrs = [],
         varArg = false,
         retTy = L.VOID,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}
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
         retTy = compileRuntimeTy T.INT32ty,
         retAttrs = [],
         fnAttrs = [L.NOUNWIND]}

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
                L.FPTR (retTy, argTys, varArg) =>
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
        val ty = L.FPTR (retTy, argTys, varArg)
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

  fun readReal s =
      case Real.fromString s of
        NONE => raise Bug.Bug "realReal"
      | SOME x => x

  fun funEntryLabelToSymbol id =
      "_SMLF" ^ FunEntryLabel.toString id
  fun callbackEntryLabelToSymbol id =
      "_SMLB" ^ CallbackEntryLabel.toString id
  fun dataLabelToSymbol id =
      "_SMLD" ^ DataLabel.toString id
  fun dataLabelToSymbolAlt id =
      "_SMLM" ^ DataLabel.toString id
  fun extraDataLabelToSymbol id =
      "_SMLE" ^ ExtraDataLabel.toString id
  fun externSymbolToSymbol id =
      "_SMLZ" ^ ExternSymbol.toString id

  val dataLabelOffset =
      Word32.fromInt TypeLayout2.maxSize

  type alias_map =
      {dataMap : L.const DataLabel.Map.map,
       extraDataMap : L.const ExtraDataLabel.Map.map}

  val emptyAliasMap =
      {dataMap = DataLabel.Map.empty,
       extraDataMap = ExtraDataLabel.Map.empty} : alias_map

  fun singletonAlias (id, const) : alias_map =
      {dataMap = DataLabel.Map.singleton (id, const),
       extraDataMap = ExtraDataLabel.Map.empty}

  fun singletonAliasExtra (id, const) : alias_map =
      {dataMap = DataLabel.Map.empty,
       extraDataMap = ExtraDataLabel.Map.singleton (id, const)}

  fun unionAliasMap (a1:alias_map, a2:alias_map) : alias_map =
      {dataMap =
         DataLabel.Map.unionWith
           (fn _ => raise Bug.Bug "extendAliasMap dataMap")
           (#dataMap a1, #dataMap a2),
       extraDataMap =
         ExtraDataLabel.Map.unionWith
           (fn _ => raise Bug.Bug "extendAliasMap extraDataMap")
           (#extraDataMap a1, #extraDataMap a2)}

  fun compileConst (aliasMap as {dataMap, extraDataMap}:alias_map) const =
      case const of
        M.NVINT32 x => L.INTCONST (Word64.fromInt x)
      | M.NVWORD32 x => L.INTCONST (Word32.toLarge x)
      | M.NVINT64 x => L.INTCONST (Word64.fromLargeInt (Int64.toLarge x))
      | M.NVWORD64 x => L.INTCONST x
      | M.NVCONTAG x => L.INTCONST (Word32.toLarge x)
      | M.NVWORD8 x => L.INTCONST (Word8.toLarge x)
      | M.NVREAL x => L.FLOATCONST (readReal x)
      | M.NVFLOAT x => L.FLOATCONST (readReal x)
      | M.NVCHAR x => L.INTCONST (Word64.fromInt (ord x))
      | M.NVUNIT => L.NULL
      | M.NVNULLPOINTER => L.NULL
      | M.NVNULLBOXED => L.NULL
      | M.NVTAG {tag, ty} =>
        L.INTCONST (Word64.fromInt (TypeLayout2.tagValue tag))
      | M.NVFOREIGNSYMBOL {name, ty} =>
        let
          val cconv =
              case ty of
                (_, T.FOREIGNCODEPTRty {attributes,...}) =>
                compileCallConv (#callingConvention attributes)
              | _ => NONE
        in
          #2 (registerForeignEntry name (compileTy ty) cconv)
        end
      | M.NVFUNENTRY id => L.SYMBOL (funEntryLabelToSymbol id)
      | M.NVCALLBACKENTRY id => L.SYMBOL (callbackEntryLabelToSymbol id)
      | M.NVEXTRADATA id =>
        (case ExtraDataLabel.Map.find (extraDataMap, id) of
           SOME x => x
         | NONE => L.SYMBOL (extraDataLabelToSymbol id))
      | M.NVCAST {value, valueTy, targetTy, cast=P.BitCast} =>
        L.CONST_BITCAST ((compileTy valueTy, compileConst aliasMap value),
                         compileTy targetTy)
      | M.NVCAST {value, valueTy, targetTy, cast} => compileConst aliasMap value
      | M.NVTOPDATA id =>
        (case DataLabel.Map.find (dataMap, id) of
           SOME x => x
         | NONE => L.SYMBOL (dataLabelToSymbol id))

  fun compileTopConst aliasMap (const, ty) =
      (compileTy ty, compileConst aliasMap const)

  fun compileTopConstWord32 (const, ty:M.ty) =
      case compileConst emptyAliasMap const of
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
      | congruentTy (L.FPTR _, L.PTR _) = true
      | congruentTy (L.PTR _, L.FPTR _) = true
      | congruentTy (L.FPTR _, L.FPTR _) = true
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
        aliasMap : alias_map,
        exportMap : ((L.ty * L.const) * {gvr : L.ty * L.value})
                      ExternSymbol.Map.map,
        handlerMap : handler_kind HandlerLabel.Map.map,
        funTy : funTy,
        personality: (L.ty * L.const) option ref option,
        returnInsns : L.operand -> unit -> L.body
      }

  val emptyEnv =
      {
        slotAddrMap = SlotID.Map.empty,
        aliasMap = emptyAliasMap,
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

  fun compileValue (env as {aliasMap, ...}:env) value =
      case value of
      M.ANCONST {const, ty} =>
      (compileTy ty, L.CONST (compileConst aliasMap const))
    | M.ANVAR {id,ty} =>
      (compileTy ty, L.VAR id)
    | M.ANCAST {exp, expTy, targetTy, runtimeTyCast} => compileValue env exp
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
        in
          scope (last (L.INVOKE {cconv = cconv,
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
              ptr = (L.PTR objHeaderTy, L.VAR objAddr),
              indices = [(L.I64, L.CONST (L.INTCONST (Word64.~ 0w1)))]}]
      end

  fun objectHeader (result, obj) =
      let
        val headerAddr = VarID.generate ()
      in
        objectHeaderAddress (headerAddr, obj)
        o insn1 (L.LOAD (result, (L.PTR objHeaderTy, L.VAR headerAddr)))
      end

  fun objectPayloadSize (result, header) =
      insn1 (L.OP2 (result, L.AND,
                    (objHeaderTy, L.VAR header),
                    (objHeaderTy, L.CONST (L.INTCONST MASK_OBJSIZE))))

  fun recordBitmapSize (result, payloadSize) =
      let
        val ty = objHeaderTy
        val wordBitMask = recordBitmapWordBits - 0w1
        val pointerSize = Word64.fromInt (TypeLayout2.sizeOf T.BOXEDty)
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

  fun objectTotalSize (result, allocSize) =
      insn1 (L.OP2 (result, L.ADD L.NUW,
                    allocSize,
                    (objHeaderTy,
                     L.CONST (L.INTCONST (Word32.toLarge objHeaderSize)))))

  local
    fun cmpOp (var, varTy, con, cmp, x : L.operand, y : L.operand) =
        let
          val v = VarID.generate ()
        in
          insns [con (v, cmp, x, y),
                 L.CONV (var, L.ZEXT, (L.I1, L.VAR v), varTy)]
        end
  in

  fun compilePrim env {prim, retTy, argTys, resultTy, result, sizes, args} =
      case (prim, retTy, argTys, args) of
        (P.Array_turnIntoVector, T.BOXEDty, [T.BOXEDty], [x]) =>
        let
          val var1 = VarID.generate ()
          val var2 = VarID.generate ()
          val var3 = VarID.generate ()
        in
          objectHeaderAddress (var1, x)
          o insns [L.LOAD (var2, (L.PTR objHeaderTy, L.VAR var1)),
                   L.OP2 (var3, L.AND, (objHeaderTy, L.VAR var2),
                          (objHeaderTy,
                           L.CONST (L.INTCONST
                                      (Word64.notb FLAG_OBJTYPE_ARRAY)))),
                   L.STORE {dst = (L.PTR objHeaderTy, L.VAR var1),
                            value = (objHeaderTy, L.VAR var3)},
                   L.CONV (result, L.BITCAST, x, resultTy)]
        end
      | (P.Array_turnIntoVector, _, _, _) =>
        raise Bug.Bug "compilePrim: Array_turnIntoVector"

      | (P.Float_abs, T.FLOATty, [T.FLOATty], [x]) =>
        callIntrinsic (SOME result) llvm_fabs_f32 [x]
      | (P.Float_abs, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_abs"

      | (P.Float_add, T.FLOATty, [T.FLOATty, T.FLOATty], [x, y]) =>
        insn1 (L.OP2 (result, L.FADD, x, y))
      | (P.Float_add, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_add"

      | (P.Float_div, T.FLOATty, [T.FLOATty, T.FLOATty], [x, y]) =>
        insn1 (L.OP2 (result, L.FDIV, x, y))
      | (P.Float_div, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_div"

      | (P.Float_equal, T.UINT32ty, [T.FLOATty, T.FLOATty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OEQ, x, y)
      | (P.Float_equal, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_equal"

      | (P.Float_unorderedOrEqual, T.UINT32ty, [T.FLOATty, T.FLOATty], [x,y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_UEQ, x, y)
      | (P.Float_unorderedOrEqual, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_unorderedOrEqual"

      | (P.Float_gt, T.UINT32ty, [T.FLOATty, T.FLOATty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OGT, x, y)
      | (P.Float_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_gt"

      | (P.Float_gteq, T.UINT32ty, [T.FLOATty, T.FLOATty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OGE, x, y)
      | (P.Float_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_gteq"

      | (P.Float_isNan, T.UINT32ty, [T.FLOATty], [x]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_UNO, x, x)
      | (P.Float_isNan, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_isNan"

      | (P.Float_lt, T.UINT32ty, [T.FLOATty, T.FLOATty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OLT, x, y)
      | (P.Float_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_lt"

      | (P.Float_lteq, T.UINT32ty, [T.FLOATty, T.FLOATty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OLE, x, y)
      | (P.Float_lteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_lteq"

      | (P.Float_mul, T.FLOATty, [T.FLOATty, T.FLOATty], [x, y]) =>
        insn1 (L.OP2 (result, L.FMUL, x, y))
      | (P.Float_mul, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_mul"

      | (P.Float_rem, T.FLOATty, [T.FLOATty, T.FLOATty], [x, y]) =>
        insn1 (L.OP2 (result, L.FREM, x, y))
      | (P.Float_rem, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_rem"

      | (P.Float_sub, T.FLOATty, [T.FLOATty, T.FLOATty], [x, y]) =>
        insn1 (L.OP2 (result, L.FSUB, x, y))
      | (P.Float_sub, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_sub"

      | (P.Float_toInt32_unsafe, T.INT32ty, [T.FLOATty], [x]) =>
        insn1 (L.CONV (result, L.FPTOSI, x, resultTy))
      | (P.Float_toInt32_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_toInt32_unsafe"

      | (P.Float_toInt64_unsafe, T.INT64ty, [T.FLOATty], [x]) =>
        insn1 (L.CONV (result, L.FPTOSI, x, resultTy))
      | (P.Float_toInt64_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_toInt64_unsafe"

      | (P.Float_toWord32_unsafe, T.UINT32ty, [T.FLOATty], [x]) =>
        insn1 (L.CONV (result, L.FPTOUI, x, resultTy))
      | (P.Float_toWord32_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_toWord32_unsafe"

      | (P.Float_toWord64_unsafe, T.UINT64ty, [T.FLOATty], [x]) =>
        insn1 (L.CONV (result, L.FPTOUI, x, resultTy))
      | (P.Float_toWord64_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_toWord64_unsafe"

      | (P.Float_toReal, T.DOUBLEty, [T.FLOATty], [x]) =>
        insn1 (L.CONV (result, L.FPEXT, x, resultTy))
      | (P.Float_toReal, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_toReal"

      | (P.IdentityEqual, T.UINT32ty, [ty1, ty2], [x, y]) =>
        (
          if ty1 = ty2 andalso #1 x = #1 y andalso isIntTy (#1 x)
          then () else raise Bug.Bug "compilePrim: IdentityEqual";
          cmpOp (result, resultTy, L.ICMP, L.EQ, x, y)
        )
      | (P.IdentityEqual, _, _, _) =>
        raise Bug.Bug "compilePrim: IdentityEqual"

      | (P.Int32_add_unsafe, T.INT32ty, [T.INT32ty, T.INT32ty], [x, y]) =>
        insn1 (L.OP2 (result, L.ADD L.NSW, x, y))
      | (P.Int32_add_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int32_add_unsafe"

      | (P.Int32_gt, T.UINT32ty, [T.INT32ty, T.INT32ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SGT, x, y)
      | (P.Int32_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Int32_gt"

      | (P.Int32_gteq, T.UINT32ty, [T.INT32ty, T.INT32ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SGE, x, y)
      | (P.Int32_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Int32_gteq"

      | (P.Int32_lt, T.UINT32ty, [T.INT32ty, T.INT32ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SLT, x, y)
      | (P.Int32_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Int32_lt"

      | (P.Int32_lteq, T.UINT32ty, [T.INT32ty, T.INT32ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SLE, x, y)
      | (P.Int32_lteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Int32_lteq"

      | (P.Int32_mul_unsafe, T.INT32ty, [T.INT32ty, T.INT32ty], [x, y]) =>
        insn1 (L.OP2 (result, L.MUL L.NSW, x, y))
      | (P.Int32_mul_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int32_mul_unsafe"

      | (P.Int32_quot_unsafe, T.INT32ty, [T.INT32ty, T.INT32ty], [x, y]) =>
        insn1 (L.OP2 (result, L.SDIV, x, y))
      | (P.Int32_quot_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int32_quot_unsafe"

      | (P.Int32_rem_unsafe, T.INT32ty, [T.INT32ty, T.INT32ty], [x, y]) =>
        insn1 (L.OP2 (result, L.SREM, x, y))
      | (P.Int32_rem_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int32_rem_unsafe"

      | (P.Int32_sub_unsafe, T.INT32ty, [T.INT32ty, T.INT32ty], [x, y]) =>
        insn1 (L.OP2 (result, L.SUB L.NSW, x, y))
      | (P.Int32_sub_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int32_sub_unsafe"

      | (P.Int32_toReal, T.DOUBLEty, [T.INT32ty], [x]) =>
        insn1 (L.CONV (result, L.SITOFP, x, resultTy))
      | (P.Int32_toReal, _, _, _) =>
        raise Bug.Bug "compilePrim: Int32_toReal"

      | (P.Int32_toFloat_unsafe, T.FLOATty, [T.INT32ty], [x]) =>
        insn1 (L.CONV (result, L.SITOFP, x, resultTy))
      | (P.Int32_toFloat_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int32_toFloat_unsafe"

      | (P.Int64_add_unsafe, T.INT64ty, [T.INT64ty, T.INT64ty], [x, y]) =>
        insn1 (L.OP2 (result, L.ADD L.NSW, x, y))
      | (P.Int64_add_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int64_add_unsafe"

      | (P.Int64_gt, T.UINT32ty, [T.INT64ty, T.INT64ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SGT, x, y)
      | (P.Int64_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Int64_gt"

      | (P.Int64_gteq, T.UINT32ty, [T.INT64ty, T.INT64ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SGE, x, y)
      | (P.Int64_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Int64_gteq"

      | (P.Int64_lt, T.UINT32ty, [T.INT64ty, T.INT64ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SLT, x, y)
      | (P.Int64_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Int64_lt"

      | (P.Int64_lteq, T.UINT32ty, [T.INT64ty, T.INT64ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SLE, x, y)
      | (P.Int64_lteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Int64_lteq"

      | (P.Int64_mul_unsafe, T.INT64ty, [T.INT64ty, T.INT64ty], [x, y]) =>
        insn1 (L.OP2 (result, L.MUL L.NSW, x, y))
      | (P.Int64_mul_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int64_mul_unsafe"

      | (P.Int64_quot_unsafe, T.INT64ty, [T.INT64ty, T.INT64ty], [x, y]) =>
        insn1 (L.OP2 (result, L.SDIV, x, y))
      | (P.Int64_quot_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int64_quot_unsafe"

      | (P.Int64_rem_unsafe, T.INT64ty, [T.INT64ty, T.INT64ty], [x, y]) =>
        insn1 (L.OP2 (result, L.SREM, x, y))
      | (P.Int64_rem_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int64_rem_unsafe"

      | (P.Int64_sub_unsafe, T.INT64ty, [T.INT64ty, T.INT64ty], [x, y]) =>
        insn1 (L.OP2 (result, L.SUB L.NSW, x, y))
      | (P.Int64_sub_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int64_sub_unsafe"

      | (P.Int64_toReal_unsafe, T.DOUBLEty, [T.INT64ty], [x]) =>
        insn1 (L.CONV (result, L.SITOFP, x, resultTy))
      | (P.Int64_toReal_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int32_toReal"

      | (P.Int64_toFloat_unsafe, T.FLOATty, [T.INT64ty], [x]) =>
        insn1 (L.CONV (result, L.SITOFP, x, resultTy))
      | (P.Int64_toFloat_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int32_toFloat_unsafe"

      | (P.ObjectSize, T.UINT32ty, [T.BOXEDty], [x]) =>
        let
          val header = VarID.generate ()
        in
          objectHeader (header, x)
          o objectPayloadSize (result, header)
        end
      | (P.ObjectSize, _, _, _) =>
        raise Bug.Bug "compilePrim: ObjectSize"

      | (P.Ptr_advance, T.POINTERty, [T.POINTERty, T.INT32ty],
         [ptr as (L.PTR L.I8, _), i]) =>
        let
          val var1 = VarID.generate ()
          val size = case sizes of
                       [x] => x
                     | _ => raise Bug.Bug "compilePrim: Ptr_advance"
        in
          insns [L.OP2 (var1, L.MUL L.WRAP, size, i),
                 L.GETELEMENTPTR {result = result,
                                  inbounds = false,
                                  ptr = ptr,
                                  indices = [(#1 i, L.VAR var1)]}]
        end
      | (P.Ptr_advance, _, _, _) =>
        raise Bug.Bug "compilePrim: Ptr_advance"

      | (P.Ptr_toWord64, T.UINT64ty, [T.POINTERty], [x]) =>
        insn1 (L.CONV (result, L.PTRTOINT, x, resultTy))
      | (P.Ptr_toWord64, _, _, _) =>
        raise Bug.Bug "compilePrim: Ptr_toWord64"

      | (P.Real_abs, T.DOUBLEty, [T.DOUBLEty], [x]) =>
        callIntrinsic (SOME result) llvm_fabs_f64 [x]
      | (P.Real_abs, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_abs"

      | (P.Real_add, T.DOUBLEty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
        insn1 (L.OP2 (result, L.FADD, x, y))
      | (P.Real_add, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_add"

      | (P.Real_div, T.DOUBLEty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
        insn1 (L.OP2 (result, L.FDIV, x, y))
      | (P.Real_div, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_div"

      | (P.Real_equal, T.UINT32ty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OEQ, x, y)
      | (P.Real_equal, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_equal"

      | (P.Real_unorderedOrEqual, T.UINT32ty, [T.DOUBLEty, T.DOUBLEty],
         [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_UEQ, x, y)
      | (P.Real_unorderedOrEqual, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_unorderedOrEqual"

      | (P.Real_gt, T.UINT32ty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OGT, x, y)
      | (P.Real_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_gt"

      | (P.Real_gteq, T.UINT32ty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OGE, x, y)
      | (P.Real_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_gteq"

      | (P.Real_isNan, T.UINT32ty, [T.DOUBLEty], [x]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_UNO, x, x)
      | (P.Real_isNan, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_isNan"

      | (P.Real_lt, T.UINT32ty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OLT, x, y)
      | (P.Real_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_lt"

      | (P.Real_lteq, T.UINT32ty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OLE, x, y)
      | (P.Real_lteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_lteq"

      | (P.Real_mul, T.DOUBLEty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
        insn1 (L.OP2 (result, L.FMUL, x, y))
      | (P.Real_mul, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_mul"

      | (P.Real_rem, T.DOUBLEty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
        insn1 (L.OP2 (result, L.FREM, x, y))
      | (P.Real_rem, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_rem"

      | (P.Real_sub, T.DOUBLEty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
        insn1 (L.OP2 (result, L.FSUB, x, y))
      | (P.Real_sub, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_sub"

      | (P.Real_toInt32_unsafe, T.INT32ty, [T.DOUBLEty], [x]) =>
        insn1 (L.CONV (result, L.FPTOSI, x, resultTy))
      | (P.Real_toInt32_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_toInt32_unsafe"

      | (P.Real_toInt64_unsafe, T.INT64ty, [T.DOUBLEty], [x]) =>
        insn1 (L.CONV (result, L.FPTOSI, x, resultTy))
      | (P.Real_toInt64_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_toInt64_unsafe"

      | (P.Real_toWord32_unsafe, T.UINT32ty, [T.DOUBLEty], [x]) =>
        insn1 (L.CONV (result, L.FPTOUI, x, resultTy))
      | (P.Real_toWord32_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_toWord32_unsafe"

      | (P.Real_toWord64_unsafe, T.UINT64ty, [T.DOUBLEty], [x]) =>
        insn1 (L.CONV (result, L.FPTOUI, x, resultTy))
      | (P.Real_toWord64_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_toWord32_unsafe"

      | (P.Real_toFloat_unsafe, T.FLOATty, [T.DOUBLEty], [x]) =>
        insn1 (L.CONV (result, L.FPTRUNC, x, resultTy))
      | (P.Real_toFloat_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_toFloat_unsafe"

      (* ToDo: RuntimePolyEqual is to be deprecated by equality function
       * compilation *)
      | (P.RuntimePolyEqual, T.UINT32ty, [T.BOXEDty, T.BOXEDty],
         [x as (L.PTR L.I8, _), y as (L.PTR L.I8, _)]) =>
        callIntrinsic (SOME result) sml_obj_equal [x, y]
      | (P.RuntimePolyEqual, T.UINT32ty, [ty1, ty2], [x, y]) =>
        (
          if ty1 = ty2 andalso #1 x = #1 y andalso isIntTy (#1 x)
          then () else raise Bug.Bug "compilePrim: RuntimePolyEqual";
          cmpOp (result, resultTy, L.ICMP, L.EQ, x, y)
        )
      | (P.RuntimePolyEqual, _, _, _) =>
        raise Bug.Bug "compilePrim: RuntimePolyEqual"

      | (P.Word8_add, T.UINT8ty, [T.UINT8ty, T.UINT8ty], [x, y]) =>
        insn1 (L.OP2 (result, L.ADD L.WRAP, x, y))
      | (P.Word8_add, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_add"

      | (P.Word8_andb, T.UINT8ty, [T.UINT8ty, T.UINT8ty], [x, y]) =>
        insn1 (L.OP2 (result, L.AND, x, y))
      | (P.Word8_andb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_andb"

      | (P.Word8_arshift_unsafe, T.UINT8ty, [T.UINT8ty, T.UINT8ty], [x, y]) =>
        insn1 (L.OP2 (result, L.ASHR, x, y))
      | (P.Word8_arshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_arshift_unsafe"

      | (P.Word8_div_unsafe, T.UINT8ty, [T.UINT8ty, T.UINT8ty], [x, y]) =>
        insn1 (L.OP2 (result, L.UDIV, x, y))
      | (P.Word8_div_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_div"

      | (P.Word8_gt, T.UINT32ty, [T.UINT8ty, T.UINT8ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.UGT, x, y)
      | (P.Word8_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_gt"

      | (P.Word8_gteq, T.UINT32ty, [T.UINT8ty, T.UINT8ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.UGE, x, y)
      | (P.Word8_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_gteq"

      | (P.Word8_lshift_unsafe, T.UINT8ty, [T.UINT8ty, T.UINT8ty], [x, y]) =>
        insn1 (L.OP2 (result, L.SHL, x, y))
      | (P.Word8_lshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_lshift_unsafe"

      | (P.Word8_lt, T.UINT32ty, [T.UINT8ty, T.UINT8ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.ULT, x, y)
      | (P.Word8_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_lt"

      | (P.Word8_lteq, T.UINT32ty, [T.UINT8ty, T.UINT8ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.ULE, x, y)
      | (P.Word8_lteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_lteq"

      | (P.Word8_mod_unsafe, T.UINT8ty, [T.UINT8ty, T.UINT8ty], [x, y]) =>
        insn1 (L.OP2 (result, L.UREM, x, y))
      | (P.Word8_mod_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_mod"

      | (P.Word8_mul, T.UINT8ty, [T.UINT8ty, T.UINT8ty], [x, y]) =>
        insn1 (L.OP2 (result, L.MUL L.WRAP, x, y))
      | (P.Word8_mul, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_mul"

      | (P.Word8_orb, T.UINT8ty, [T.UINT8ty, T.UINT8ty], [x, y]) =>
        insn1 (L.OP2 (result, L.OR, x, y))
      | (P.Word8_orb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_orb"

      | (P.Word8_rshift_unsafe, T.UINT8ty, [T.UINT8ty, T.UINT8ty], [x, y]) =>
        insn1 (L.OP2 (result, L.LSHR, x, y))
      | (P.Word8_rshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_rshift_unsafe"

      | (P.Word8_sub, T.UINT8ty, [T.UINT8ty, T.UINT8ty], [x, y]) =>
        insn1 (L.OP2 (result, L.SUB L.WRAP, x, y))
      | (P.Word8_sub, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_sub"

      | (P.Word8_toWord32, T.UINT32ty, [T.UINT8ty], [x]) =>
        insn1 (L.CONV (result, L.ZEXT, x, resultTy))
      | (P.Word8_toWord32, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_toWord32"

      | (P.Word8_toWord32X, T.UINT32ty, [T.UINT8ty], [x]) =>
        insn1 (L.CONV (result, L.SEXT, x, resultTy))
      | (P.Word8_toWord32X, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_toWord32X"

      | (P.Word8_toWord64, T.UINT64ty, [T.UINT8ty], [x]) =>
        insn1 (L.CONV (result, L.ZEXT, x, resultTy))
      | (P.Word8_toWord64, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_toWord64"

      | (P.Word8_toWord64X, T.UINT64ty, [T.UINT8ty], [x]) =>
        insn1 (L.CONV (result, L.SEXT, x, resultTy))
      | (P.Word8_toWord64X, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_toWord64X"

      | (P.Word8_xorb, T.UINT8ty, [T.UINT8ty, T.UINT8ty], [x, y]) =>
        insn1 (L.OP2 (result, L.XOR, x, y))
      | (P.Word8_xorb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word8_xorb"

      | (P.Word32_add, T.UINT32ty, [T.UINT32ty, T.UINT32ty], [x, y]) =>
        insn1 (L.OP2 (result, L.ADD L.WRAP, x, y))
      | (P.Word32_add, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_add"

      | (P.Word32_andb, T.UINT32ty, [T.UINT32ty, T.UINT32ty], [x, y]) =>
        insn1 (L.OP2 (result, L.AND, x, y))
      | (P.Word32_andb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_andb"

      | (P.Word32_arshift_unsafe, T.UINT32ty, [T.UINT32ty, T.UINT32ty],
         [x, y]) =>
        insn1 (L.OP2 (result, L.ASHR, x, y))
      | (P.Word32_arshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_arshift"

      | (P.Word32_div_unsafe, T.UINT32ty, [T.UINT32ty, T.UINT32ty], [x, y]) =>
        insn1 (L.OP2 (result, L.UDIV, x, y))
      | (P.Word32_div_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_div"

      | (P.Word32_gt, T.UINT32ty, [T.UINT32ty, T.UINT32ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.UGT, x, y)
      | (P.Word32_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_gt"

      | (P.Word32_gteq, T.UINT32ty, [T.UINT32ty, T.UINT32ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.UGE, x, y)
      | (P.Word32_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_gteq"

      | (P.Word32_lshift_unsafe, T.UINT32ty, [T.UINT32ty, T.UINT32ty], [x,y]) =>
        insn1 (L.OP2 (result, L.SHL, x, y))
      | (P.Word32_lshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_lshift_unsafe"

      | (P.Word32_lt, T.UINT32ty, [T.UINT32ty, T.UINT32ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.ULT, x, y)
      | (P.Word32_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_lt"

      | (P.Word32_lteq, T.UINT32ty, [T.UINT32ty, T.UINT32ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.ULE, x, y)
      | (P.Word32_lteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_lteq"

      | (P.Word32_mod_unsafe, T.UINT32ty, [T.UINT32ty, T.UINT32ty], [x, y]) =>
        insn1 (L.OP2 (result, L.UREM, x, y))
      | (P.Word32_mod_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_mod"

      | (P.Word32_mul, T.UINT32ty, [T.UINT32ty, T.UINT32ty], [x, y]) =>
        insn1 (L.OP2 (result, L.MUL L.WRAP, x, y))
      | (P.Word32_mul, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_mul"

      | (P.Word32_orb, T.UINT32ty, [T.UINT32ty, T.UINT32ty], [x, y]) =>
        insn1 (L.OP2 (result, L.OR, x, y))
      | (P.Word32_orb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_orb"

      | (P.Word32_rshift_unsafe, T.UINT32ty, [T.UINT32ty, T.UINT32ty], [x,y]) =>
        insn1 (L.OP2 (result, L.LSHR, x, y))
      | (P.Word32_rshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_rshift_unsafe"

      | (P.Word32_sub, T.UINT32ty, [T.UINT32ty, T.UINT32ty], [x, y]) =>
        insn1 (L.OP2 (result, L.SUB L.WRAP, x, y))
      | (P.Word32_sub, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_sub"

      | (P.Word32_toWord8, T.UINT8ty, [T.UINT32ty], [x]) =>
        insn1 (L.CONV (result, L.TRUNC, x, resultTy))
      | (P.Word32_toWord8, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_toWord8"

      | (P.Word32_toWord64, T.UINT64ty, [T.UINT32ty], [x]) =>
        insn1 (L.CONV (result, L.ZEXT, x, resultTy))
      | (P.Word32_toWord64, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_toWord64"

      | (P.Word32_toWord64X, T.UINT64ty, [T.UINT32ty], [x]) =>
        insn1 (L.CONV (result, L.SEXT, x, resultTy))
      | (P.Word32_toWord64X, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_toWord64X"

      | (P.Word32_xorb, T.UINT32ty, [T.UINT32ty, T.UINT32ty], [x, y]) =>
        insn1 (L.OP2 (result, L.XOR, x, y))
      | (P.Word32_xorb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word32_xorb"

      | (P.Word64_add, T.UINT64ty, [T.UINT64ty, T.UINT64ty], [x, y]) =>
        insn1 (L.OP2 (result, L.ADD L.WRAP, x, y))
      | (P.Word64_add, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_add"

      | (P.Word64_andb, T.UINT64ty, [T.UINT64ty, T.UINT64ty], [x, y]) =>
        insn1 (L.OP2 (result, L.AND, x, y))
      | (P.Word64_andb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_andb"

      | (P.Word64_arshift_unsafe, T.UINT64ty, [T.UINT64ty, T.UINT64ty],
         [x, y]) =>
        insn1 (L.OP2 (result, L.ASHR, x, y))
      | (P.Word64_arshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_arshift"

      | (P.Word64_div_unsafe, T.UINT64ty, [T.UINT64ty, T.UINT64ty], [x, y]) =>
        insn1 (L.OP2 (result, L.UDIV, x, y))
      | (P.Word64_div_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_div"

      | (P.Word64_gt, T.UINT32ty, [T.UINT64ty, T.UINT64ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.UGT, x, y)
      | (P.Word64_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_gt"

      | (P.Word64_gteq, T.UINT32ty, [T.UINT64ty, T.UINT64ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.UGE, x, y)
      | (P.Word64_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_gteq"

      | (P.Word64_lshift_unsafe, T.UINT64ty, [T.UINT64ty, T.UINT64ty], [x,y]) =>
        insn1 (L.OP2 (result, L.SHL, x, y))
      | (P.Word64_lshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_lshift_unsafe"

      | (P.Word64_lt, T.UINT32ty, [T.UINT64ty, T.UINT64ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.ULT, x, y)
      | (P.Word64_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_lt"

      | (P.Word64_lteq, T.UINT32ty, [T.UINT64ty, T.UINT64ty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.ULE, x, y)
      | (P.Word64_lteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_lteq"

      | (P.Word64_mod_unsafe, T.UINT64ty, [T.UINT64ty, T.UINT64ty], [x, y]) =>
        insn1 (L.OP2 (result, L.UREM, x, y))
      | (P.Word64_mod_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_mod"

      | (P.Word64_mul, T.UINT64ty, [T.UINT64ty, T.UINT64ty], [x, y]) =>
        insn1 (L.OP2 (result, L.MUL L.WRAP, x, y))
      | (P.Word64_mul, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_mul"

      | (P.Word64_orb, T.UINT64ty, [T.UINT64ty, T.UINT64ty], [x, y]) =>
        insn1 (L.OP2 (result, L.OR, x, y))
      | (P.Word64_orb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_orb"

      | (P.Word64_rshift_unsafe, T.UINT64ty, [T.UINT64ty, T.UINT64ty], [x,y]) =>
        insn1 (L.OP2 (result, L.LSHR, x, y))
      | (P.Word64_rshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_rshift_unsafe"

      | (P.Word64_sub, T.UINT64ty, [T.UINT64ty, T.UINT64ty], [x, y]) =>
        insn1 (L.OP2 (result, L.SUB L.WRAP, x, y))
      | (P.Word64_sub, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_sub"

      | (P.Word64_toWord8, T.UINT8ty, [T.UINT64ty], [x]) =>
        insn1 (L.CONV (result, L.TRUNC, x, resultTy))
      | (P.Word64_toWord8, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_toWord8"

      | (P.Word64_toWord32, T.UINT32ty, [T.UINT64ty], [x]) =>
        insn1 (L.CONV (result, L.TRUNC, x, resultTy))
      | (P.Word64_toWord32, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_toWord32"

      | (P.Word64_xorb, T.UINT64ty, [T.UINT64ty, T.UINT64ty], [x, y]) =>
        insn1 (L.OP2 (result, L.XOR, x, y))
      | (P.Word64_xorb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word64_xorb"

  end (* local *)

  fun compileMid (env:env) mid =
      case mid of
        M.MCINTINF {resultVar, dataLabel, loc} =>
        let
          val dataPtr = compileConst (#aliasMap env) (M.NVEXTRADATA dataLabel)
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
                  val exnVar = VarID.generate ()
                  val exn2Var = VarID.generate ()
                  val unsaveInsn =
                      callIntrinsic (SOME exn2Var) sml_unsave_exn
                                    [(L.PTR L.I8, L.VAR ueVar)]
                  val kind =
                      case handler of
                        NONE => {catch=false, cleanup=true}
                      | SOME id => getHandlerKind env id # {cleanup=true}
                  val jumpInsn =
                      case handler of
                        NONE => resumeInsn (ueVar, exn2Var)
                      | SOME id =>
                        last (L.BR (jumpToLandingPad (id, ueVar, exn2Var)))
                in
                  (SOME lpadLabel,
                   landingPad
                     env
                     (lpadLabel, kind, ueVar, exnVar,
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
            insn1 (L.LOAD (#id resultVar,
                           (L.PTR ty,
                            L.CONST (L.SYMBOL (externSymbolToSymbol id)))))
          | SOME ((_, const), _) =>
            insn1 (L.LOAD (#id resultVar, (L.PTR ty, L.CONST const)))
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
      | M.MCCHECK =>
        let
          val check_flag = referIntrinsicVar sml_check_flag
          val onLabel = FunLocalLabel.generate nil
          val offLabel = FunLocalLabel.generate nil
          val flag = VarID.generate ()
          val cmpResult = VarID.generate ()
        in
          scope
            (insns [L.LOAD_ATOMIC (flag, check_flag, {order = L.UNORDERED,
                                                      align = 0w4}),
                    L.ICMP (cmpResult, L.EQ, (L.I32, L.VAR flag),
                            (L.I32, L.CONST (L.INTCONST 0w0)))]
             o scope
                 (last (L.BR_C ((L.I1, L.VAR cmpResult),
                                (offLabel, nil),
                                (onLabel, nil))))
             o label (onLabel, nil)
             o callIntrinsic NONE sml_check nil
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
          val dst' = VarID.generate ()
          val src' = VarID.generate ()
          val dst = VarID.generate ()
          val src = VarID.generate ()
          val totalSize = VarID.generate ()
        in
          objectHeaderAddress (dst', dstRecord)
          o objectHeaderAddress (src', srcRecord)
          o objectTotalSize (totalSize, copySize)
          o insns [L.CONV (dst, L.BITCAST, (L.PTR objHeaderTy, L.VAR dst'),
                           L.PTR L.I8),
                   L.CONV (src, L.BITCAST, (L.PTR objHeaderTy, L.VAR src'),
                           L.PTR L.I8)]
          o callIntrinsic NONE llvm_memcpy
                          [(L.PTR L.I8, L.VAR dst),
                           (L.PTR L.I8, L.VAR src),
                           (L.I32, L.VAR totalSize),
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
          insn1 (L.LOAD (#id resultVar, srcAddr))
        end
      | M.MCLOAD {resultVar, srcAddr, loc} =>
        let
          val (insns1, _, srcAddr) = compileAddress env srcAddr
          val resultTy = compileTy (#ty resultVar)
          val (insns2, srcAddr) = bitcast (srcAddr, L.PTR resultTy)
        in
          insns1
          o insns2
          o insn1 (L.LOAD (#id resultVar, srcAddr))
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
          insn1 (L.CONV (#id resultVar, L.BITCAST, exp, targetTy))
        end
      | M.MCCALL {resultVar, resultTy, codeExp, closureEnvExp, argExpList, tail,
                  handler, loc} =>
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
                         (_, T.UNITty) => L.VOID
                       | _ => compileTy resultTy,
               cconv = SOME L.FASTCC}
          (*
           * LLVM's tail call optimization changes the size of stack frames
           * due to calling convention requiring that some arguments must
           * be in stack; therefore, it is not always compatible with LLVM's
           * GC support.  To avoid this incompatibility, we turn on the tail
           * call optimization only if both callee and caller does not have
           * any stack arguments.
           *)
          val tail =
              if not tail
              then NONE
              else if !Control.useMustTail
                      andalso isMustTailAllowed (#funTy env, funTy)
              then SOME L.MUSTTAIL
              (* FIXME: We assume that first three arguments are passed
               * in registers. *)
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
          | SOME ((dstTy, dst), {gvr}) =>
            case ty of
              (_, T.BOXEDty) =>
              callIntrinsic NONE sml_write [gvr, (dstTy, L.CONST dst), value]
            | _ =>
              insn1 (L.STORE {dst = (dstTy, L.CONST dst), value = value})
        end

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
          val jumpInsn =
              case cleanup of
                NONE => empty
              | SOME cleanupLabel =>
                jumpIfNull (compileValue env (M.ANVAR exnVar))
                           (jumpToLandingPad (cleanupLabel, ueVar, #id exnVar))
        in
          landingPad env (id, kind, ueVar, #id exnVar,
                          jumpInsn
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
                      ((constTy, compileConst (#aliasMap env) const),
                       (label, nil)))
                  branches
        in
          last (L.SWITCH {value = switchValue,
                          default = (default, nil),
                          branches = branches})
        end
      | M.MCLOCALCODE {id, recursive, argVarList, bodyExp, nextExp, loc} =>
        scope (compileExp env nextExp)
        o label (id, map compileVarInfo argVarList)
        o compileExp env bodyExp
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
        (fn (slotId, T.BOXEDty, z as (insns1, slotMap)) =>
            let
              val varId = VarID.generate ()
            in
              (insns1
               o insn1 (L.ALLOCA (varId, L.PTR L.I8))
               o callIntrinsic NONE llvm_gcroot
                               [(L.PTR (L.PTR L.I8), L.VAR varId),
                                nullOperand],
               SlotID.Map.insert (slotMap, slotId,
                                  (L.PTR (L.PTR L.I8), L.VAR varId)))
            end
          | _ => raise Bug.Bug "allocSlots: FIXME: not implemented")
        (empty, SlotID.Map.empty)
        slotMap

  fun compileTop {aliasMap, exportMap}
                 {frameSlots, bodyExp, cleanupHandler,
                  argTys, varArg, cconv, retTy} =
      let
        val retLabel = FunLocalLabel.generate nil
        val (retTy, goto, retArgs, return) =
            case retTy of
              NONE =>
              (L.VOID, fn _ => last (L.BR (retLabel, [])), [], L.RET_VOID)
            | SOME (_, T.UNITty) =>
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
        val (allocInsns, slotMap) = allocSlots frameSlots
        val personality = ref NONE
        val env = {slotAddrMap = slotMap,
                   aliasMap = aliasMap,
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
                val exnVar = VarID.generate ()
              in
                (bindHandlerLabel env (id, {catch=false, cleanup=true}),
                 landingPad
                   env
                   (id, {catch=false, cleanup=true},
                    ueVar, exnVar,
                    callIntrinsic NONE sml_save_exn [(L.PTR L.I8, L.VAR ueVar)]
                    o callIntrinsic NONE sml_end []))
              end
        val buf1 = VarID.generate ()
        val buf2 = VarID.generate ()
        val body =
            allocInsns
            o insn1 (L.ALLOCA (buf1, L.ARRAY (0w3, L.PTR L.I8)))
            o insn1 (L.CONV (buf2, L.BITCAST,
                             (L.ARRAY (0w3, L.PTR L.I8), L.VAR buf1),
                             L.PTR (L.PTR L.I8)))
            o callIntrinsic NONE sml_start
                            [(L.PTR (L.PTR L.I8), L.VAR buf2)]
            o cleanupInsn
            o scope (compileExp bodyEnv bodyExp)
            o label (retLabel, retArgs)
            o callIntrinsic NONE sml_end nil
            o last return
      in
        (body, retTy, !personality)
      end

  fun compileTopdec env topdec =
      case topdec of
        M.MTFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar, frameSlots,
                      bodyExp, retTy, loc} =>
        let
          val closureEnvArg =
              case closureEnvVar of
                NONE => nil
              | SOME {id, ty} => [(compileTy ty, [L.INREG], id)]
          val (retTy, returnInsns) =
              case retTy of
                (_, T.UNITty) => (L.VOID, fn v => last L.RET_VOID)
              | _ => (compileTy retTy, fn v => last (L.RET v))
          val args = map (fn {id, ty} => (compileTy ty, [L.INREG], id))
                         argVarList
          val params = closureEnvArg @ args
          val (insns1, slotMap) = allocSlots frameSlots
          val personality = ref NONE
          val env = {slotAddrMap = slotMap,
                     aliasMap = #aliasMap env,
                     exportMap = #exportMap env,
                     funTy = {argTys = map (fn (x,y,z) => (x,y)) params,
                              varArg = false,
                              retTy = retTy,
                              cconv = SOME L.FASTCC},
                     handlerMap = HandlerLabel.Map.empty,
                     personality = SOME personality,
                     returnInsns = returnInsns}
          val body =
              insns1
              o compileExp env bodyExp
        in
          [L.DEFINE
             {linkage = SOME L.INTERNAL,
              cconv = SOME L.FASTCC,
              retAttrs = nil,
              retTy = retTy,
              name = funEntryLabelToSymbol id,
              parameters = params,
              fnAttrs = [L.UWTABLE],
              personality = !personality,
              gcname = gcname,
              body = body ()}]
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
                  (insn1 (L.LOAD (id, (L.PTR ty, L.VAR arg))),
                   (L.PTR ty, [L.NEST], arg) :: args)
                end
          val cconv = compileCallConv (#callingConvention attributes)
          val (body, retTy, personality) =
              compileTop env {frameSlots = frameSlots,
                              bodyExp = bodyExp,
                              cleanupHandler = cleanupHandler,
                              retTy = retTy,
                              argTys = map (fn (x,y,z) => (x,y)) args,
                              varArg = false,
                              cconv = cconv}
          val body =
              insns1
              o body
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
              body = body ()}]
        end

  fun ptrDiff intptrTy p1 p2 =
      L.CONST_SUB (L.WRAP, (intptrTy, L.CONST_PTRTOINT (p1, intptrTy)),
                           (intptrTy, L.CONST_PTRTOINT (p2, intptrTy)))

  fun makeRootsetArray roots =
      case roots of
        nil => (nil, (L.PTR L.I8, L.CONST L.NULL))
      | _::_ =>
        let
          val intptrTy = intptrTy ()
          val numRoots = length roots
          val arrayTy = L.ARRAY (Word.fromInt (1 + numRoots), intptrTy)
          val baseAddr = (L.PTR arrayTy, L.SYMBOL "_SML_rts")
        in
          ([L.GLOBALVAR
              {name = "_SML_rts",
               linkage = SOME L.PRIVATE,
               constant = true,
               unnamed_addr = true,
               ty = arrayTy,
               align = NONE,
               initializer =
                 L.INIT_ARRAY
                   ((intptrTy,
                     L.INIT_CONST (L.INTCONST (Word64.fromInt numRoots)))
                    :: map (fn x => (intptrTy,
                                     L.INIT_CONST (ptrDiff intptrTy
                                                           (L.PTR L.I8, x)
                                                           baseAddr)))
                           roots)}],
           (L.PTR L.I8, L.CONST (L.CONST_BITCAST (baseAddr, L.PTR L.I8))))
        end

  fun makeDepArray dependency =
      let
        val (hash, name) =
            case #interfaceNameOpt dependency of
              NONE => (InterfaceHash.emptyHash (), "")
            | SOME {hash, source=(_,name)} =>
              (hash, Filename.toString (Filename.basename name))
        val depends =
            InterfaceName.hashToWord64 hash
            :: Word64.fromInt (length (#link dependency))
            :: ListSorter.sort
                 Word64.compare
                 (map (fn {hash,...} => InterfaceName.hashToWord64 hash)
                      (#link dependency))
        val depArrayTy = L.ARRAY (Word.fromInt (length depends), L.I64)
        val nameArrayTy = L.ARRAY (Word.fromInt (size name + 1), L.I8)
      in
        ([L.GLOBALVAR
            {name = "_SML_dep",
             linkage = SOME L.PRIVATE,
             constant = true,
             unnamed_addr = true,
             ty = L.STRUCT ([depArrayTy, nameArrayTy], {packed=true}),
             align = NONE,
             initializer =
               L.INIT_STRUCT
                 ([(depArrayTy,
                    L.INIT_ARRAY
                      (map (fn x => (L.I64, L.INIT_CONST (L.INTCONST x)))
                           depends)),
                   (nameArrayTy, L.INIT_STRING (name ^ "\000"))],
                  {packed=true})}],
         (L.PTR L.I8,
          L.CONST
            (L.CONST_BITCAST
               ((L.PTR L.I64,
                 L.CONST_GETELEMENTPTR
                   {inbounds = true,
                    ptr = (L.PTR depArrayTy, L.SYMBOL "_SML_dep"),
                    indices = [(L.I32, L.INTCONST 0w0),
                               (L.I32, L.INTCONST 0w0),
                               (L.I32, L.INTCONST 0w0)]}),
                L.PTR L.I8))))
      end

  fun makeCtors {top, dep, mut} =
      let
        val ctorFunTy = L.FPTR (L.VOID, [], false)
        val ctorsElemTy = L.STRUCT ([L.I32, ctorFunTy], {packed=false})
      in
        [L.EXTERN {name = "_SML_ftab", ty = L.I8},
         L.DEFINE
           {linkage = SOME L.INTERNAL,
            cconv = NONE,
            retAttrs = nil,
            retTy = L.VOID,
            name = "_SML_ctor",
            parameters = [],
            fnAttrs = [L.NOUNWIND],
            personality = NONE,
            gcname = NONE,
            body =
              (callIntrinsic
                 NONE
                 sml_register_top
                 [top,
                  dep,
                  (L.PTR L.I8, L.CONST (L.SYMBOL "_SML_ftab")),
                  mut]
               o last L.RET_VOID)
                ()},
         L.GLOBALVAR
           {name = "llvm.global_ctors",
            linkage = SOME L.APPENDING,
            unnamed_addr = false,
            constant = false,
            ty = L.ARRAY (0w1, ctorsElemTy),
            align = NONE,
            initializer =
              L.INIT_ARRAY
                [(ctorsElemTy,
                  L.INIT_STRUCT
                    ([(L.I32, L.INIT_CONST (L.INTCONST 0w65535)),
                      (ctorFunTy, L.INIT_CONST (L.SYMBOL "_SML_ctor"))],
                     {packed=false}))]}]
      end

  fun compileToplevel aliasMap roots
                      {dependency, frameSlots, bodyExp, cleanupHandler} =
      let
        val (body, _, personality) =
            compileTop aliasMap
                       {frameSlots = frameSlots,
                        bodyExp = bodyExp,
                        cleanupHandler = cleanupHandler,
                        retTy = NONE,
                        argTys = nil,
                        varArg = false,
                        cconv = NONE}
        val (decs1, sml_top) =
            ([L.DEFINE
                {linkage = SOME L.INTERNAL,
                 cconv = NONE,
                 retAttrs = nil,
                 retTy = L.VOID,
                 name = "_SML_top",
                 parameters = [],
                 fnAttrs = [L.UWTABLE],
                 personality = personality,
                 gcname = gcname,
                 body = body ()}],
             (L.PTR L.I8,
              L.CONST (L.CONST_BITCAST ((L.FPTR (L.VOID, nil, false),
                                         L.SYMBOL "_SML_top"),
                                        L.PTR L.I8))))
        val (decs2, sml_dep) = makeDepArray dependency
        val (decs3, sml_mut) = makeRootsetArray roots
        val decs4 = makeCtors {top = sml_top, dep = sml_dep, mut = sml_mut}
      in
        decs1 @ decs2 @ decs3 @ decs4
      end

  fun pad (i, j) =
      if i > j then raise Bug.Bug "pad"
      else if i = j then nil
      else [(L.ARRAY (j - i, L.I8), L.ZEROINITIALIZER)]

  fun compileInitConst aliasMap const =
      case compileTopConst aliasMap const of
        (ty, const) => (ty, L.INIT_CONST const)

  fun allocTopArray topdataList =
      let
        val exports =
            List.mapPartial
              (fn M.NTEXPORTVAR {id, weak=false, ty=(_,T.BOXEDty),
                                 value=NONE, loc} => SOME id
                | _ => NONE)
              topdataList
      in
        case exports of
          nil => (nil, ExternSymbol.Map.empty, nil)
        | _::_ =>
          let
            val pointerSize = TypeLayout2.sizeOf T.BOXEDty
            val numExports = length exports
            val header =
                makeHeaderWordStatic
                  (M.OBJTYPE_ARRAY
                     (M.ANCONST
                        {const = M.NVTAG {tag=T.TAG_BOXED, ty=Types.ERRORty},
                         ty = (Types.ERRORty, T.INT32ty)}),
                   Word64.fromInt (pointerSize * numExports))
            val exportArrayTy =
                L.ARRAY (Word.fromInt (length exports), L.PTR L.I8)
            val data =
                pad (objHeaderSize, Word.fromInt pointerSize)
                @ [header, (exportArrayTy, L.ZEROINITIALIZER)]
            val dataTy = L.STRUCT (map #1 data, {packed=true})
            val arrayOffset =
                Word64.fromInt (length data - 1)
            fun gvrElem i =
                (L.PTR (L.PTR L.I8),
                 L.CONST_GETELEMENTPTR
                   {inbounds = true,
                    ptr = (L.PTR dataTy, L.SYMBOL "_SML_gvr"),
                    indices = [(L.I64, L.INTCONST 0w0),
                               (L.I32, L.INTCONST arrayOffset),
                               (L.I64, L.INTCONST (Word64.fromInt i))]})
            val gvrObj = L.CONST_BITCAST (gvrElem 0, L.PTR L.I8)
            val gvrObjValue = (L.PTR L.I8, L.CONST gvrObj)
          in
            ([L.GLOBALVAR
                {name = "_SML_gvr",
                 linkage = SOME L.PRIVATE,
                 unnamed_addr = false,
                 constant = false,
                 ty = dataTy,
                 initializer = L.INIT_STRUCT (data, {packed=true}),
                 align = SOME pointerSize}],
             foldli (fn (id,i,z) =>
                        ExternSymbol.Map.insert
                          (z, id, (gvrElem i, {gvr = gvrObjValue})))
                    ExternSymbol.Map.empty
                    exports,
             [gvrObj])
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
                       align = SOME TypeLayout2.maxSize}],
         singletonAlias (id, objptr),
         if mutable andalso includesBoxed then [objptr] else nil)
      end

  fun compileTopdata {aliasMap, exportMap} topdata =
      case topdata of
        M.NTEXTERNVAR {id, ty, loc} =>
        ([L.EXTERN
            {name = externSymbolToSymbol id,
             ty = compileTy ty}],
         emptyAliasMap,
         nil)
      | M.NTEXPORTVAR {id, weak, ty, value, loc} =>
        (case ExternSymbol.Map.find (exportMap, id) of
           SOME (const, _) =>
           [L.ALIAS
              {name = externSymbolToSymbol id,
               linkage = NONE,
               unnamed_addr = false,
               aliasee = const}]
         | NONE =>
           case (ty, value) of
             ((_,T.BOXEDty), NONE) => raise Bug.Bug "NTEXPORTVAR"
           | _ =>
             [L.GLOBALVAR
                {name = externSymbolToSymbol id,
                 linkage = if weak then SOME L.WEAK else NONE,
                 unnamed_addr = weak,
                 constant = isSome value,
                 ty = compileTy ty,
                 initializer =
                   case value of
                     SOME v => L.INIT_CONST (#2 (compileTopConst aliasMap v))
                   | NONE => L.ZEROINITIALIZER,
                 align = NONE}],
        emptyAliasMap,
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
                     ptr = (L.PTR ty, L.SYMBOL label),
                     indices = [(L.I32, L.INTCONST 0w0),
                                (L.I32, L.INTCONST 0w0)]}),
           nil)
        end
      | M.NTRECORD {id, tyvarKindEnv, recordTy=_, fieldList, isMutable,
                    isCoalescable, clearPad, bitmaps, loc} =>
        let
          (* FIXME : optimize bitmap *)
          val includesBoxed =
              List.exists
                (fn {fieldExp=(_,(_,T.BOXEDty)),...} => true | _ => false)
                fieldList
          val fields =
              map (fn {fieldExp, fieldSize, fieldIndex} =>
                      (compileTopConst aliasMap fieldExp,
                       compileTopConstWord32 fieldIndex,
                       compileTopConstWord32 fieldSize))
                  fieldList
          val bitmaps =
              map (fn {bitmapIndex, bitmapExp} =>
                      (compileInitConst aliasMap bitmapExp,
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
          val includesBoxed = case elemTy of (_,T.BOXEDty) => true | _ => false
          val initialElements =
              map (compileInitConst aliasMap) initialElements
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
      | M.NTDUMP {id, dump, ty=_, loc} =>
        let
          val {immutables, mutables, first, mutableObjects} =
              HeapDump.image dump
          val immutablesLabel = dataLabelToSymbol id
          val immutablesArrayTy =
              L.ARRAY (Word32.fromInt (Vector.length immutables), L.PTR L.I8)
          val mutablesLabel = dataLabelToSymbolAlt id
          val mutablesArrayTy =
              L.ARRAY (Word32.fromInt (Vector.length mutables), L.PTR L.I8)
          fun pointerConst' (HeapDump.MUTABLE p) =
              L.CONST_GETELEMENTPTR
                {inbounds = true,
                 ptr = (L.PTR mutablesArrayTy, L.SYMBOL mutablesLabel),
                 indices = [(L.I64, L.INTCONST 0w0),
                            (L.I64, L.INTCONST p)]}
            | pointerConst' (HeapDump.IMMUTABLE p) =
              L.CONST_GETELEMENTPTR
                {inbounds = true,
                 ptr = (L.PTR immutablesArrayTy, L.SYMBOL immutablesLabel),
                 indices = [(L.I64, L.INTCONST 0w0),
                            (L.I64, L.INTCONST p)]}
          fun pointerConst p =
              L.CONST_BITCAST ((L.PTR (L.PTR L.I8), pointerConst' p),
                               L.PTR L.I8)
          fun elemsInit elems =
              Vector.foldr
                (fn (HeapDump.VALUE v, z) =>
                    (L.PTR L.I8,
                     L.INIT_CONST (L.CONST_INTTOPTR ((L.I64, L.INTCONST v),
                                                     L.PTR L.I8)))
                    :: z
                  | (HeapDump.POINTER v, z) =>
                    (L.PTR L.I8, L.INIT_CONST (pointerConst v))
                    :: z)
                nil
                elems
          val immutablesElems = elemsInit immutables
          val mutablesElems = elemsInit mutables
        in
          ((case immutablesElems of
              nil => nil
            | _::_ => 
              [L.GLOBALVAR
                 {name = immutablesLabel,
                  linkage = SOME L.PRIVATE,
                  unnamed_addr = false,
                  constant = true,
                  ty = immutablesArrayTy,
                  initializer = L.INIT_ARRAY immutablesElems,
                  align = SOME TypeLayout2.maxSize}])
           @ (case mutablesElems of
                nil => nil
              | _::_ =>
                [L.GLOBALVAR
                   {name = mutablesLabel,
                    linkage = SOME L.PRIVATE,
                    unnamed_addr = false,
                    constant = false,
                    ty = mutablesArrayTy,
                    initializer = L.INIT_ARRAY mutablesElems,
                    align = SOME TypeLayout2.maxSize}]),
           singletonAlias (id, pointerConst first),
           map pointerConst mutableObjects)
        end

  fun compileTopdataList env nil = (nil, emptyAliasMap, nil)
    | compileTopdataList env (dec::decs) =
      let
        val (decs1, aliasMap1, roots1) = compileTopdata env dec
        val (decs2, aliasMap2, roots2) = compileTopdataList env decs
      in
        (decs1 @ decs2, unionAliasMap (aliasMap1, aliasMap2), roots1 @ roots2)
      end

  fun compile {targetTriple} ({topdata, topdecs, toplevel}:M.program) =
      let
        val (topdecs, toplevel) = MachineCodeRename.rename (topdecs, toplevel)
        val _ = initForeignEntries ()
        val (decs2, exportMap, roots1) = allocTopArray topdata
        val env = {aliasMap = emptyAliasMap, exportMap = exportMap}
        val (_, aliasMap, _) = compileTopdataList env topdata
        val env = {aliasMap = aliasMap, exportMap = exportMap}
        val (decs3, _, roots2) = compileTopdataList env topdata
        val decs4 = List.concat (map (compileTopdec env) topdecs)
        val decs5 = compileToplevel env (roots1 @ roots2) toplevel
        val decs1 = declareForeignEntries ()
      in
        {
          moduleName = "",
          datalayout = NONE,  (* FIXME *)
          triple = SOME targetTriple,
          topdecs = decs1 @ decs2 @ decs3 @ decs4 @ decs5
        } : L.program
      end

end
