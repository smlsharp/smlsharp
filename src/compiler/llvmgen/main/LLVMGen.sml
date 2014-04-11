(**
 * generate llvm ir
 *
 * @copyright (c) 2013, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure LLVMGen : sig

  val compile : {moduleName : string}
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

  fun isIntTy ty =
      case ty of
        L.I1 => true
      | L.I8 => true
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
        T.UCHARty => L.I8
      | T.INTty => L.I32
      | T.UINTty => L.I32
      | T.BOXEDty => L.PTR L.I8
      | T.POINTERty => L.PTR L.I8
      | T.MLCODEPTRty {haveClsEnv, argTys, retTy} =>
        L.FPTR (compileRuntimeTyOpt retTy,
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

  val FLAG_OBJTYPE_BOX_SHIFT = 0w28 : Word32.word
  val FLAG_OBJTYPE_UNBOXED = Word32.<< (0w0, FLAG_OBJTYPE_BOX_SHIFT)
  val FLAG_OBJTYPE_BOXED = Word32.<< (0w1, FLAG_OBJTYPE_BOX_SHIFT)
  val FLAG_OBJTYPE_VECTOR = Word32.<< (0w0, 0w29)
  val FLAG_OBJTYPE_ARRAY = Word32.<< (0w1, 0w29)
  val FLAG_OBJTYPE_RECORD =
      Word32.orb (FLAG_OBJTYPE_BOXED, Word32.<< (0w2, 0w29))
  val FLAG_OBJTYPE_INTINF =
      Word32.orb (FLAG_OBJTYPE_UNBOXED, Word32.<< (0w3, 0w29))
  val FLAG_OBJTYPE_UNBOXED_VECTOR =
      Word32.orb (FLAG_OBJTYPE_UNBOXED, FLAG_OBJTYPE_VECTOR)
  val FLAG_OBJTYPE_BOXED_VECTOR =
      Word32.orb (FLAG_OBJTYPE_BOXED, FLAG_OBJTYPE_VECTOR)
  val FLAG_OBJTYPE_UNBOXED_ARRAY =
      Word32.orb (FLAG_OBJTYPE_UNBOXED, FLAG_OBJTYPE_ARRAY)
  val FLAG_OBJTYPE_BOXED_ARRAY =
      Word32.orb (FLAG_OBJTYPE_BOXED, FLAG_OBJTYPE_ARRAY)
  val MASK_OBJSIZE = Word32.<< (0w1, 0w28) - 0w1
  val objHeaderTy = L.I32
  val objHeaderSize = 0w4 : Word32.word
  val headerOffset = (L.I32, L.CONST (L.INTCONST (Word32.fromInt ~1)))

  local
    datatype intrinsic =
        R of {name: string,
              tail: bool,
              argTys: L.ty list,
              argAttrs: L.parameter_attribute list list,
              varArg: bool,
              retTy: L.ty,
              fnAttrs: L.function_attribute list}
    val declares = ref SEnv.empty
  in
  val llvm_memcpy =
      R {name = "llvm.memcpy.p0i8.p0i8.i32",
         tail = false,
         argTys = [L.PTR L.I8, L.PTR L.I8, L.I32, L.I32, L.I1],
         argAttrs = [nil, nil, nil, nil, nil],
         varArg = false,
         retTy = L.VOID,
         fnAttrs = [L.NOUNWIND]}
  val llvm_memmove =
      R {name = "llvm.memmove.p0i8.p0i8.i32",
         tail = false,
         argTys = [L.PTR L.I8, L.PTR L.I8, L.I32, L.I32, L.I1],
         argAttrs = [nil, nil, nil, nil, nil],
         varArg = false,
         retTy = L.VOID,
         fnAttrs = [L.NOUNWIND]}
  val llvm_memset =
      R {name = "llvm.memset.p0i8.i32",
         tail = false,
         argTys = [L.PTR L.I8, L.I8, L.I32, L.I32, L.I1],
         argAttrs = [nil, nil, nil, nil, nil],
         varArg = false,
         retTy = L.VOID,
         fnAttrs = [L.NOUNWIND]}
  val llvm_gcroot =
      R {name = "llvm.gcroot",
         tail = false,
         argTys = [L.PTR (L.PTR L.I8), L.PTR L.I8],
         argAttrs = [nil, nil],
         varArg = false,
         retTy = L.VOID,
         fnAttrs = [L.NOUNWIND]}
  val llvm_fabs_f32 =
      R {name = "llvm.fabs.f32",
         tail = false,
         argTys = [L.FLOAT],
         argAttrs = [nil],
         varArg = false,
         retTy = L.FLOAT,
         fnAttrs = [L.NOUNWIND]}
  val llvm_fabs_f64 =
      R {name = "llvm.fabs.f64",
         tail = false,
         argTys = [L.DOUBLE],
         argAttrs = [nil],
         varArg = false,
         retTy = L.DOUBLE,
         fnAttrs = [L.NOUNWIND]}
  val llvm_init_trampoline =
      R {name = "llvm.init.trampoline",
         tail = false,
         argTys = [L.PTR L.I8, L.PTR L.I8, L.PTR L.I8],
         argAttrs = [nil, nil, nil],
         varArg = false,
         retTy = L.VOID,
         fnAttrs = [L.NOUNWIND]}
  val llvm_adjust_trampoline =
      R {name = "llvm.adjust.trampoline",
         tail = false,
         argTys = [L.PTR L.I8],
         argAttrs = [nil],
         varArg = false,
         retTy = L.PTR L.I8,
         fnAttrs = [L.NOUNWIND]}
  val sml_load_intinf =
      R {name = "sml_load_intinf",
         tail = false,
         argTys = [L.PTR L.I8],
         argAttrs = [[L.INREG]],
         varArg = false,
         retTy = L.PTR L.I8,
         fnAttrs = [L.NOUNWIND]}
  val sml_control_start =
      R {name = "sml_control_start",
         tail = true,
         argTys = [],
         argAttrs = [],
         varArg = false,
         retTy = L.VOID,
         fnAttrs = [L.NOUNWIND]}
  val sml_control_finish =
      R {name = "sml_control_finish",
         tail = true,
         argTys = [],
         argAttrs = [],
         varArg = false,
         retTy = L.VOID,
         fnAttrs = [L.NOUNWIND]}
  val sml_control_suspend =
      R {name = "sml_control_suspend",
         tail = true,
         argTys = [],
         argAttrs = [],
         varArg = false,
         retTy = L.VOID,
         fnAttrs = [L.NOUNWIND]}
  val sml_control_resume =
      R {name = "sml_control_resume",
         tail = true,
         argTys = [],
         argAttrs = [],
         varArg = false,
         retTy = L.VOID,
         fnAttrs = [L.NOUNWIND]}
  val sml_push_fp =
      R {name = "sml_push_fp",
         tail = true,
         argTys = [],
         argAttrs = [],
         varArg = false,
         retTy = L.VOID,
         fnAttrs = [L.NOUNWIND]}
  val sml_pop_fp =
      R {name = "sml_pop_fp",
         tail = true,
         argTys = [],
         argAttrs = [],
         varArg = false,
         retTy = L.VOID,
         fnAttrs = [L.NOUNWIND]}
  val sml_find_callback =
      R {name = "sml_find_callback",
         tail = false,
         argTys = [L.PTR L.I8, L.PTR L.I8],
         argAttrs = [[L.INREG], [L.INREG]],
         varArg = false,
         retTy = L.PTR (L.PTR L.I8),
         fnAttrs = [L.NOUNWIND]}
  val sml_alloc_code =
      R {name = "sml_alloc_code",
         tail = false,
         argTys = [],
         argAttrs = [],
         varArg = false,
         retTy = L.PTR L.I8,
         fnAttrs = [L.NOUNWIND]}
  val sml_alloc =
      R {name = "sml_alloc",
         tail = false,
         argTys = [L.I32],
         argAttrs = [[L.INREG]],
         varArg = false,
         retTy = L.PTR L.I8,
         fnAttrs = [L.NOUNWIND]}
  val sml_obj_dup =
      R {name = "sml_obj_dup",
         tail = false,
         argTys = [L.PTR L.I8],
         argAttrs = [[L.INREG]],
         varArg = false,
         retTy = L.PTR L.I8,
         fnAttrs = [L.NOUNWIND]}
  val sml_obj_equal =
      R {name = "sml_obj_equal",
         tail = true,
         argTys = [L.PTR L.I8, L.PTR L.I8],
         argAttrs = [[L.INREG], [L.INREG]],
         varArg = false,
         retTy = L.I32,
         fnAttrs = [L.NOUNWIND]}
  val sml_write =
      R {name = "sml_write",
         tail = true,
         argTys = [L.PTR L.I8, L.PTR (L.PTR L.I8), L.PTR L.I8],
         argAttrs = [[L.INREG], [L.INREG], [L.INREG]],
         varArg = false,
         retTy = L.VOID,
         fnAttrs = [L.NOUNWIND]}
  val sml_copyary =
      R {name = "sml_copyary",
         tail = true,
         argTys = [L.PTR (L.PTR L.I8), L.I32, L.PTR (L.PTR L.I8),
                   L.I32, L.I32],
         argAttrs = [nil, nil, nil, nil, nil],
         varArg = false,
         retTy = L.VOID,
         fnAttrs = [L.NOUNWIND]}
  val sml_check_gc =
      R {name = "sml_check_gc",
         tail = true,
         argTys = [],
         argAttrs = [],
         varArg = false,
         retTy = L.VOID,
         fnAttrs = [L.NOUNWIND]}
  val sml_raise =
      R {name = "sml_raise",
         tail = true,
         argTys = [L.PTR L.I8],
         argAttrs = [[L.INREG]],
         varArg = false,
         retTy = L.VOID,
         fnAttrs = [L.NORETURN]}
  val sml_personality =
      R {name = "sml_personality",
         tail = true,
         argTys = [],
         argAttrs = [],
         varArg = true,
         retTy = compileRuntimeTy T.INTty,
         fnAttrs = [L.NOUNWIND]}

  fun initIntrinsics () = declares := SEnv.empty

  fun referIntrinsic (r as R {name, argTys, varArg, retTy, ...}) =
      (
        if SEnv.inDomain (!declares, name)
        then ()
        else declares := SEnv.insert (!declares, name, r);
        (L.FPTR (retTy, argTys, varArg), L.CONST (L.SYMBOL name))
      )

  fun callIntrinsic result (r as R {tail, fnAttrs, argAttrs, ...}) args =
      insn1
        (L.CALL
           {result = result,
            tail = tail,
            cconv = NONE,
            retAttrs = nil,
            fnPtr = referIntrinsic r,
            args = ListPair.zipEq (argAttrs, args),
            fnAttrs = fnAttrs})

  fun declareIntrinsics () =
      SEnv.foldri
        (fn (_, R {name, argTys, argAttrs, retTy, varArg, fnAttrs, ...},
             z) =>
            L.DECLARE
              {linkage = NONE,
               cconv = NONE,
               retAttrs = nil,
               retTy = retTy,
               name = name,
               arguments = ListPair.zipEq (argTys, argAttrs),
               varArg = varArg,
               fnAttrs = fnAttrs,
               gcname = NONE}
            :: z)
        nil
        (!declares)

  end (* local *)

  (* FIXME : workaround for GLOBALSYMBOL *)
  local
    val entries = ref SEnv.empty
  in
  fun initForeignEntries () = entries := SEnv.empty
  fun registerForeignEntry symbol ty cconv =
      case SEnv.find (!entries, symbol) of
        NONE =>
        (entries := SEnv.insert (!entries, symbol, (ty, cconv));
         L.SYMBOL symbol)
      | SOME (oldTy, _) =>
        if oldTy = ty
        then L.SYMBOL symbol
        else L.CONST_BITCAST ((oldTy, L.SYMBOL symbol), ty)
  fun declareForeignEntries () =
      SEnv.foldri
        (fn (name, (L.FPTR (retTy, argTys, varArg), cconv), z) =>
            L.DECLARE {linkage = NONE,
                       cconv = cconv,
                       retAttrs = nil,
                       retTy = retTy,
                       name = name,
                       arguments = map (fn ty => (ty, nil)) argTys,
                       varArg = varArg,
                       fnAttrs = nil,
                       gcname = NONE}
            :: z
          | (name, (ty, _), z) =>
            L.EXTERN {name=name, ty=ty} :: z)
        nil
        (!entries)
  end (* local *)

  fun readReal s =
      case Real.fromString s of
        NONE => raise Bug.Bug "realReal"
      | SOME x => x
  fun funEntryLabelToSymbol id =
      "_SML_F" ^ FunEntryLabel.toString id
  fun callbackEntryLabelToSymbol id =
      "_SML_B" ^ CallbackEntryLabel.toString id
  fun dataLabelToSymbol id =
      "_SML_D" ^ DataLabel.toString id
  fun extraDataLabelToSymbol id =
      "_SML_E" ^ ExtraDataLabel.toString id
  fun externSymbolToSymbol id =
      "_SML" ^ ExternSymbol.toString id
  fun toplevelSymbolToSymbol name =
      name

  val dataLabelOffset =
      Word32.fromInt TypeLayout2.maxSize

  exception TopDataNotFound

  fun compileConst topdataMap const =
      case const of
        M.NVINT x => L.INTCONST (Word32.fromLargeInt (Int32.toLarge x))
      | M.NVWORD x => L.INTCONST x
      | M.NVCONTAG x => L.INTCONST x
      | M.NVBYTE x => L.INTCONST (Word32.fromInt (Word8.toInt x))
      | M.NVREAL x => L.FLOATCONST (readReal x)
      | M.NVFLOAT x => L.FLOATCONST (readReal x)
      | M.NVCHAR x => L.INTCONST (Word32.fromInt (ord x))
      | M.NVUNIT => L.INTCONST 0w0
      | M.NVNULLPOINTER => L.NULL
      | M.NVNULLBOXED => L.NULL
      | M.NVTAG {tag, ty} =>
        L.INTCONST (Word32.fromInt (TypeLayout2.tagValue tag))
      | M.NVFOREIGNSYMBOL {name, ty} =>
        let
          val cconv =
              case ty of
                (_, T.FOREIGNCODEPTRty {attributes,...}) =>
                compileCallConv (#callingConvention attributes)
              | _ => NONE
        in
          registerForeignEntry name (compileTy ty) cconv
        end
      | M.NVFUNENTRY id => L.SYMBOL (funEntryLabelToSymbol id)
      | M.NVCALLBACKENTRY id => L.SYMBOL (callbackEntryLabelToSymbol id)
      | M.NVEXTRADATA id => L.SYMBOL (extraDataLabelToSymbol id)
      | M.NVCAST {value, valueTy, targetTy, runtimeTyCast, bitCast=false} =>
        compileConst topdataMap value
      | M.NVCAST {value, valueTy, targetTy, runtimeTyCast, bitCast=true} =>
        L.CONST_BITCAST ((compileTy valueTy, compileConst topdataMap value),
                         compileTy targetTy)
      | M.NVTOPDATA id =>
        case DataLabel.Map.find (topdataMap, id) of
          NONE => raise TopDataNotFound
        | SOME ty =>
          (*
           * The order of bitcast and getelementptr is significant;
           * The following two expressions seems to have different meaning:
           * (1) getelementptr i8* ( bitcast <{[4 x i8], ...}>* @foo to i8* ),
           *                   i32 8
           * (2) bitcast i8* (getelementptr <{[4 x i8], ...}>* @foo,
           *                  i32 0, i32 0, i32 8) to i8*
           *
           * LLVM compiles load instructions on the pointer of (2) into
           * code sequences that always return 0.  This behavior does not 
           * follow of our intension.  (1) seems to work fine as we expect
           * so we choose (1).
           *
           * Since LLVM does not provide some formal semantics of LLVM IR,
           * we cannot determine the rationale of the above difference.
           * I guess that (2) is evaluated to an out-of-bound pointer to 8th
           * element of the first element of type [4 x i8].  Since
           * dereferencing such pointer is illegal, LLVM would choose any
           * value as its result.  In contrast, (1) points the 8th byte of
           * @foo, which is in bound.
           *)
          L.CONST_GETELEMENTPTR
            {inbounds = true,
             ptr = (L.PTR L.I8,
                    L.CONST_BITCAST
                      ((L.PTR ty, L.SYMBOL (dataLabelToSymbol id)),
                       L.PTR L.I8)),
             indices = [(L.I32, L.INTCONST dataLabelOffset)]}

  fun compileTopConst topdataMap (const, ty) =
      let
        val const =
            case topdataMap of
                SOME topdataMap => compileConst topdataMap const
              | NONE => compileConst DataLabel.Map.empty const
                        handle TopDataNotFound => L.NULL (* dummy *)
      in
        (compileTy ty, const)
      end

  fun compileTopConstWord (const, ty:M.ty) =
      case compileConst DataLabel.Map.empty const of
        L.INTCONST w => w
       | _ => raise Bug.Bug "compileTopConstWord"

  type env =
      {
        slotAddrMap: L.operand SlotID.Map.map,
        topdataMap: L.ty DataLabel.Map.map,
        extraDataMap: L.ty ExtraDataLabel.Map.map,
        enableTailcallOpt: bool,
        returnInsns : L.operand -> unit -> L.body
      }

  val emptyEnv =
      {
        slotAddrMap = SlotID.Map.empty,
        topdataMap = DataLabel.Map.empty,
        extraDataMap = ExtraDataLabel.Map.empty,
        enableTailcallOpt = false,
        returnInsns = fn _ => fn () => (nil, L.UNREACHABLE) (* dummy *)
      } : env

  fun compileValue (env as {topdataMap, ...}:env) value =
      case value of
      M.ANCONST {const, ty} =>
      (compileTy ty, L.CONST (compileConst topdataMap const))
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
          val shift = Word.fromInt (Word32.toInt FLAG_OBJTYPE_BOX_SHIFT)
          val tag = Word32.<< (w, shift)
        in
          (empty, (ty, L.CONST (L.INTCONST (Word.orb (tag, objFlag)))))
        end
      | tag =>
        let
          val shift = L.INTCONST FLAG_OBJTYPE_BOX_SHIFT
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
        (insns, (objHeaderTy, L.CONST (L.INTCONST (Word32.orb (w1, w2)))))
      | ((insns1, objType), _) =>
        let
          val var = VarID.generate ()
        in
          (insns1 o insn1 (L.OP2 (var, L.OR, allocSize, objType)),
           (objHeaderTy, L.VAR var))
        end

  datatype landingPadKind =
      CLEANUP
    | CATCH of M.varInfo

  fun landingPad (handlerId, kind, bodyInsn) =
      let
        val lpadVar = VarID.generate ()
        (* see also exn.c. First member is exception header and second one
         * is exception object. *)
        val lpadTy = L.STRUCT ([L.PTR L.I8, L.PTR L.I8], {packed=false})
        val lpadOperand = (lpadTy, L.VAR lpadVar)
        val (extractInsn, catch, cleanup) =
            case kind of
              CLEANUP => (empty, nil, true)
            | CATCH exnVar =>
              (insn1 (L.EXTRACTVALUE (#id exnVar, lpadOperand, 1)),
               [nullOperand], false)
        val resumeInsn = last (L.RESUME lpadOperand)
      in
        fn next =>
           (nil, L.LANDINGPAD
                   {label = handlerId,
                    argVar = (lpadVar, lpadTy),
                    personality = referIntrinsic sml_personality,
                    catch = catch,
                    cleanup = cleanup,
                    body = (extractInsn o bodyInsn o resumeInsn) (),
                    next = next})
      end

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
          val var4 = VarID.generate ()
        in
          insns [L.CONV (var1, L.BITCAST, x, L.PTR objHeaderTy),
                 L.GETELEMENTPTR {result = var2,
                                  inbounds = true,
                                  ptr = (L.PTR objHeaderTy, L.VAR var1),
                                  indices = [headerOffset]},
                 L.LOAD (var3, (L.PTR objHeaderTy, L.VAR var2)),
                 L.OP2 (var4, L.AND, (objHeaderTy, L.VAR var3),
                        (objHeaderTy,
                         L.CONST (L.INTCONST
                                    (Word32.notb FLAG_OBJTYPE_ARRAY)))),
                 L.STORE {dst = (L.PTR objHeaderTy, L.VAR var2),
                          value = (objHeaderTy, L.VAR var4)},
                 L.CONV (result, L.BITCAST, x, resultTy)]
        end
      | (P.Array_turnIntoVector, _, _, _) =>
        raise Bug.Bug "compilePrim: Array_turnIntoVector"

      | (P.Byte_add, T.UCHARty, [T.UCHARty, T.UCHARty], [x, y]) =>
        insn1 (L.OP2 (result, L.ADD L.WRAP, x, y))
      | (P.Byte_add, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_add"

      | (P.Byte_andb, T.UCHARty, [T.UCHARty, T.UCHARty], [x, y]) =>
        insn1 (L.OP2 (result, L.AND, x, y))
      | (P.Byte_andb, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_andb"

      | (P.Byte_arshift_unsafe, T.UCHARty, [T.UCHARty, T.UCHARty], [x, y]) =>
        insn1 (L.OP2 (result, L.ASHR, x, y))
      | (P.Byte_arshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_arshift_unsafe"

      | (P.Byte_div_unsafe, T.UCHARty, [T.UCHARty, T.UCHARty], [x, y]) =>
        insn1 (L.OP2 (result, L.UDIV, x, y))
      | (P.Byte_div_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_div"

      | (P.Byte_fromWord, T.UCHARty, [T.UINTty], [x]) =>
        insn1 (L.CONV (result, L.TRUNC, x, resultTy))
      | (P.Byte_fromWord, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_fromWord"

      | (P.Byte_gt, T.UINTty, [T.UCHARty, T.UCHARty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.UGT, x, y)
      | (P.Byte_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_gt"

      | (P.Byte_gteq, T.UINTty, [T.UCHARty, T.UCHARty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.UGE, x, y)
      | (P.Byte_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_gteq"

      | (P.Byte_lshift_unsafe, T.UCHARty, [T.UCHARty, T.UCHARty], [x, y]) =>
        insn1 (L.OP2 (result, L.SHL, x, y))
      | (P.Byte_lshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_lshift_unsafe"

      | (P.Byte_lt, T.UINTty, [T.UCHARty, T.UCHARty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.ULT, x, y)
      | (P.Byte_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_lt"

      | (P.Byte_lteq, T.UINTty, [T.UCHARty, T.UCHARty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.ULE, x, y)
      | (P.Byte_lteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_lteq"

      | (P.Byte_mod_unsafe, T.UCHARty, [T.UCHARty, T.UCHARty], [x, y]) =>
        insn1 (L.OP2 (result, L.UREM, x, y))
      | (P.Byte_mod_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_mod"

      | (P.Byte_mul, T.UCHARty, [T.UCHARty, T.UCHARty], [x, y]) =>
        insn1 (L.OP2 (result, L.MUL L.WRAP, x, y))
      | (P.Byte_mul, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_mul"

      | (P.Byte_orb, T.UCHARty, [T.UCHARty, T.UCHARty], [x, y]) =>
        insn1 (L.OP2 (result, L.OR, x, y))
      | (P.Byte_orb, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_orb"

      | (P.Byte_rshift_unsafe, T.UCHARty, [T.UCHARty, T.UCHARty], [x, y]) =>
        insn1 (L.OP2 (result, L.LSHR, x, y))
      | (P.Byte_rshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_rshift_unsafe"

      | (P.Byte_sub, T.UCHARty, [T.UCHARty, T.UCHARty], [x, y]) =>
        insn1 (L.OP2 (result, L.SUB L.WRAP, x, y))
      | (P.Byte_sub, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_sub"

      | (P.Byte_xorb, T.UCHARty, [T.UCHARty, T.UCHARty], [x, y]) =>
        insn1 (L.OP2 (result, L.XOR, x, y))
      | (P.Byte_xorb, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_xorb"

      | (P.Byte_toIntX, T.INTty, [T.UCHARty], [x]) =>
        insn1 (L.CONV (result, L.SEXT, x, resultTy))
      | (P.Byte_toIntX, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_toIntX"

      | (P.Byte_toWord, T.UINTty, [T.UCHARty], [x]) =>
        insn1 (L.CONV (result, L.ZEXT, x, resultTy))
      | (P.Byte_toWord, _, _, _) =>
        raise Bug.Bug "compilePrim: Byte_toWord"

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

      | (P.Float_equal, T.UINTty, [T.FLOATty, T.FLOATty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OEQ, x, y)
      | (P.Float_equal, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_equal"

      | (P.Float_unorderedOrEqual, T.UINTty, [T.FLOATty, T.FLOATty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_UEQ, x, y)
      | (P.Float_unorderedOrEqual, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_unorderedOrEqual"

      | (P.Float_fromInt_unsafe, T.FLOATty, [T.INTty], [x]) =>
        insn1 (L.CONV (result, L.SITOFP, x, resultTy))
      | (P.Float_fromInt_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_fromInt_unsafe"

      | (P.Float_fromReal_unsafe, T.FLOATty, [T.DOUBLEty], [x]) =>
        insn1 (L.CONV (result, L.FPTRUNC, x, resultTy))
      | (P.Float_fromReal_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_fromReal_unsafe"

      | (P.Float_gt, T.UINTty, [T.FLOATty, T.FLOATty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OGT, x, y)
      | (P.Float_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_gt"

      | (P.Float_gteq, T.UINTty, [T.FLOATty, T.FLOATty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OGE, x, y)
      | (P.Float_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_gteq"

      | (P.Float_isNan, T.UINTty, [T.FLOATty], [x]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_UNO, x, x)
      | (P.Float_isNan, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_isNan"

      | (P.Float_lt, T.UINTty, [T.FLOATty, T.FLOATty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OLT, x, y)
      | (P.Float_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_lt"

      | (P.Float_lteq, T.UINTty, [T.FLOATty, T.FLOATty], [x, y]) =>
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

      | (P.Float_toReal, T.DOUBLEty, [T.FLOATty], [x]) =>
        insn1 (L.CONV (result, L.FPEXT, x, resultTy))
      | (P.Float_toReal, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_toReal"

      | (P.Float_trunc_unsafe, T.INTty, [T.FLOATty], [x]) =>
        insn1 (L.CONV (result, L.FPTOSI, x, resultTy))
      | (P.Float_trunc_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Float_trunc_unsafe"

      | (P.IdentityEqual, T.UINTty, [ty1, ty2], [x, y]) =>
        (
          if ty1 = ty2 andalso #1 x = #1 y andalso isIntTy (#1 x)
          then () else raise Bug.Bug "compilePrim: IdentityEqual";
          cmpOp (result, resultTy, L.ICMP, L.EQ, x, y)
        )
      | (P.IdentityEqual, _, _, _) =>
        raise Bug.Bug "compilePrim: IdentityEqual"

      | (P.Int_add_unsafe, T.INTty, [T.INTty, T.INTty], [x, y]) =>
        insn1 (L.OP2 (result, L.ADD L.NSW, x, y))
      | (P.Int_add_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_add_unsafe"

      | (P.Int_gt, T.UINTty, [T.INTty, T.INTty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SGT, x, y)
      | (P.Int_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_gt"

      | (P.Int_gteq, T.UINTty, [T.INTty, T.INTty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SGE, x, y)
      | (P.Int_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_gteq"

      | (P.Int_lt, T.UINTty, [T.INTty, T.INTty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SLT, x, y)
      | (P.Int_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_lt"

      | (P.Int_lteq, T.UINTty, [T.INTty, T.INTty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.SLE, x, y)
      | (P.Int_lteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_lteq"

      | (P.Int_mul_unsafe, T.INTty, [T.INTty, T.INTty], [x, y]) =>
        insn1 (L.OP2 (result, L.MUL L.NSW, x, y))
      | (P.Int_mul_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_mul_unsafe"

      | (P.Int_quot_unsafe, T.INTty, [T.INTty, T.INTty], [x, y]) =>
        insn1 (L.OP2 (result, L.SDIV, x, y))
      | (P.Int_quot_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_quot_unsafe"

      | (P.Int_rem_unsafe, T.INTty, [T.INTty, T.INTty], [x, y]) =>
        insn1 (L.OP2 (result, L.SREM, x, y))
      | (P.Int_rem_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_rem_unsafe"

      | (P.Int_sub_unsafe, T.INTty, [T.INTty, T.INTty], [x, y]) =>
        insn1 (L.OP2 (result, L.SUB L.NSW, x, y))
      | (P.Int_sub_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_sub_unsafe"

      | (P.ObjectSize, T.UINTty, [T.BOXEDty], [x]) =>
        let
          val var1 = VarID.generate ()
          val var2 = VarID.generate ()
          val var3 = VarID.generate ()
        in
          insns [L.CONV (var1, L.BITCAST, x, L.PTR objHeaderTy),
                 L.GETELEMENTPTR {result = var2,
                                  inbounds = true,
                                  ptr = (L.PTR objHeaderTy, L.VAR var1),
                                  indices = [headerOffset]},
                 L.LOAD (var3, (L.PTR objHeaderTy, L.VAR var2)),
                 L.OP2 (result, L.AND, (objHeaderTy, L.VAR var3),
                        (objHeaderTy, L.CONST (L.INTCONST MASK_OBJSIZE)))]
        end
      | (P.ObjectSize, _, _, _) =>
        raise Bug.Bug "compilePrim: ObjectSize"

      | (P.Ptr_advance, T.POINTERty, [T.POINTERty, T.INTty],
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

      | (P.Real_equal, T.UINTty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OEQ, x, y)
      | (P.Real_equal, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_equal"

      | (P.Real_unorderedOrEqual, T.UINTty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_UEQ, x, y)
      | (P.Real_unorderedOrEqual, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_unorderedOrEqual"

      | (P.Real_fromInt_unsafe, T.DOUBLEty, [T.INTty], [x]) =>
        insn1 (L.CONV (result, L.SITOFP, x, resultTy))
      | (P.Real_fromInt_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_fromInt_unsafe"

      | (P.Real_gt, T.UINTty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OGT, x, y)
      | (P.Real_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_gt"

      | (P.Real_gteq, T.UINTty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OGE, x, y)
      | (P.Real_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_gteq"

      | (P.Real_isNan, T.UINTty, [T.DOUBLEty], [x]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_UNO, x, x)
      | (P.Real_isNan, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_isNan"

      | (P.Real_lt, T.UINTty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
        cmpOp (result, resultTy, L.FCMP, L.F_OLT, x, y)
      | (P.Real_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_lt"

      | (P.Real_lteq, T.UINTty, [T.DOUBLEty, T.DOUBLEty], [x, y]) =>
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

      | (P.Real_trunc_unsafe, T.INTty, [T.DOUBLEty], [x]) =>
        insn1 (L.CONV (result, L.FPTOSI, x, resultTy))
      | (P.Real_trunc_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_trunc_unsafe"

      (* ToDo: RuntimePolyEqual is to be deprecated by equality function
       * compilation *)
      | (P.RuntimePolyEqual, T.UINTty, [T.BOXEDty, T.BOXEDty],
         [x as (L.PTR L.I8, _), y as (L.PTR L.I8, _)]) =>
        callIntrinsic (SOME result) sml_obj_equal [x, y]
      | (P.RuntimePolyEqual, T.UINTty, [ty1, ty2], [x, y]) =>
        (
          if ty1 = ty2 andalso #1 x = #1 y andalso isIntTy (#1 x)
          then () else raise Bug.Bug "compilePrim: RuntimePolyEqual";
          cmpOp (result, resultTy, L.ICMP, L.EQ, x, y)
        )
      | (P.RuntimePolyEqual, _, _, _) =>
        raise Bug.Bug "compilePrim: RuntimePolyEqual"

      | (P.Word_add, T.UINTty, [T.UINTty, T.UINTty], [x, y]) =>
        insn1 (L.OP2 (result, L.ADD L.WRAP, x, y))
      | (P.Word_add, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_add"

      | (P.Word_andb, T.UINTty, [T.UINTty, T.UINTty], [x, y]) =>
        insn1 (L.OP2 (result, L.AND, x, y))
      | (P.Word_andb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_andb"

      | (P.Word_arshift_unsafe, T.UINTty, [T.UINTty, T.UINTty], [x, y]) =>
        insn1 (L.OP2 (result, L.ASHR, x, y))
      | (P.Word_arshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_arshift"

      | (P.Word_div_unsafe, T.UINTty, [T.UINTty, T.UINTty], [x, y]) =>
        insn1 (L.OP2 (result, L.UDIV, x, y))
      | (P.Word_div_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_div"

      | (P.Word_gt, T.UINTty, [T.UINTty, T.UINTty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.UGT, x, y)
      | (P.Word_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_gt"

      | (P.Word_gteq, T.UINTty, [T.UINTty, T.UINTty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.UGE, x, y)
      | (P.Word_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_gteq"

      | (P.Word_lshift_unsafe, T.UINTty, [T.UINTty, T.UINTty], [x,y]) =>
        insn1 (L.OP2 (result, L.SHL, x, y))
      | (P.Word_lshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_lshift_unsafe"

      | (P.Word_lt, T.UINTty, [T.UINTty, T.UINTty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.ULT, x, y)
      | (P.Word_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_lt"

      | (P.Word_lteq, T.UINTty, [T.UINTty, T.UINTty], [x, y]) =>
        cmpOp (result, resultTy, L.ICMP, L.ULE, x, y)
      | (P.Word_lteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_lteq"

      | (P.Word_mod_unsafe, T.UINTty, [T.UINTty, T.UINTty], [x, y]) =>
        insn1 (L.OP2 (result, L.UREM, x, y))
      | (P.Word_mod_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_mod"

      | (P.Word_mul, T.UINTty, [T.UINTty, T.UINTty], [x, y]) =>
        insn1 (L.OP2 (result, L.MUL L.WRAP, x, y))
      | (P.Word_mul, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_mul"

      | (P.Word_orb, T.UINTty, [T.UINTty, T.UINTty], [x, y]) =>
        insn1 (L.OP2 (result, L.OR, x, y))
      | (P.Word_orb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_orb"

      | (P.Word_rshift_unsafe, T.UINTty, [T.UINTty, T.UINTty], [x, y]) =>
        insn1 (L.OP2 (result, L.LSHR, x, y))
      | (P.Word_rshift_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_rshift_unsafe"

      | (P.Word_sub, T.UINTty, [T.UINTty, T.UINTty], [x, y]) =>
        insn1 (L.OP2 (result, L.SUB L.WRAP, x, y))
      | (P.Word_sub, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_sub"

      | (P.Word_xorb, T.UINTty, [T.UINTty, T.UINTty], [x, y]) =>
        insn1 (L.OP2 (result, L.XOR, x, y))
      | (P.Word_xorb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_xorb"

  end (* local *)

  fun compileMid (env:env) mid =
      case mid of
        M.MCLARGEINT {resultVar, dataLabel, loc} =>
        let
          val dataTy =
              case ExtraDataLabel.Map.find (#extraDataMap env, dataLabel) of
                NONE => raise TopDataNotFound
              | SOME ty => ty
          val dataPtr =
              L.CONST_GETELEMENTPTR
                {inbounds = true,
                 ptr = (dataTy, L.SYMBOL (extraDataLabelToSymbol dataLabel)),
                 indices = [(L.I32, L.INTCONST 0w0),
                            (L.I32, L.INTCONST 0w0)]}
        in
          callIntrinsic NONE sml_push_fp nil
          o callIntrinsic (SOME (#id resultVar))
                          sml_load_intinf
                          [(L.PTR L.I8, L.CONST dataPtr)]
          o callIntrinsic NONE sml_pop_fp nil
        end
      | M.MCFOREIGNAPPLY {resultVar, funExp, attributes, argExpList, handler,
                          loc} =>
        let
          val {isPure, noCallback, allocMLValue, suspendThread,
               callingConvention} = attributes
          val funPtr = compileValue env funExp
          val argList = map (compileValue env) argExpList
          val cconv = compileCallConv callingConvention
          val (insns1, insns2) =
              if allocMLValue
              then (callIntrinsic NONE sml_push_fp nil,
                    callIntrinsic NONE sml_pop_fp nil)
              else if suspendThread orelse not noCallback
              then (callIntrinsic NONE sml_control_suspend nil,
                    callIntrinsic NONE sml_control_resume nil)
              else (empty, empty)
        in
          insns1
          o callInsn {result = Option.map compileVarInfo resultVar,
                      tail = false,
                      cconv = cconv,
                      retAttrs = nil,
                      fnPtr = funPtr,
                      args = map (fn x => (nil, x)) argList,
                      unwind = handler,
                      fnAttrs = nil}
          o insns2
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
          val symbol = externSymbolToSymbol id
        in
          insn1 (L.LOAD (#id resultVar,
                         (L.PTR ty, L.CONST (L.SYMBOL symbol))))
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
          o callIntrinsic NONE sml_push_fp nil
          o callIntrinsic NONE sml_copyary
                          [srcArray, srcIndex, dstArray, dstIndex, numElems]
          o callIntrinsic NONE sml_pop_fp nil
        end
      | M.MCALLOC {resultVar, objType, payloadSize, allocSize, loc} =>
        let
          val allocSize = compileValue env allocSize
          val payloadSize = compileValue env payloadSize
          val (headerInsn, headerWord) =
              makeHeaderWord env (objType, payloadSize)
          val var1 = VarID.generate ()
          val var2 = VarID.generate ()
        in
          callIntrinsic (SOME (#id resultVar)) sml_alloc [allocSize]
          o headerInsn
          o insns
              [L.CONV (var1, L.BITCAST, (L.PTR L.I8, L.VAR (#id resultVar)),
                       L.PTR (#1 headerWord)),
               L.GETELEMENTPTR {result = var2,
                                inbounds = true,
                                ptr = (L.PTR (#1 headerWord), L.VAR var1),
                                indices = [headerOffset]},
               L.STORE {dst = (L.PTR (#1 headerWord), L.VAR var2),
                        value = headerWord}]
        end
      | M.MCDISABLEGC =>
        empty
      | M.MCENABLEGC =>
        empty
      | M.MCCHECKGC =>
        let
          (* FIXME: the type of sml_check_gc_flag *)
          val sml_check_gc_flag =
              (L.PTR L.I32,
               L.CONST (registerForeignEntry "sml_check_gc_flag" L.I32 NONE))
          val onLabel = FunLocalLabel.generate nil
          val offLabel = FunLocalLabel.generate nil
          val flag = VarID.generate ()
          val cmpResult = VarID.generate ()
        in
          scope
            (insns [(* FIXME: load must be volatile *)
                    L.LOAD (flag, sml_check_gc_flag),
                    L.ICMP (cmpResult, L.EQ, (L.I32, L.VAR flag),
                            (L.I32, L.CONST (L.INTCONST 0w0)))]
             o scope
                 (last (L.BR_C ((L.I1, L.VAR cmpResult),
                                (offLabel, nil),
                                (onLabel, nil))))
             o label (onLabel, nil)
             o callIntrinsic NONE sml_check_gc nil
             o last (L.BR (offLabel, nil)))
          o label (offLabel, nil)
        end
      | M.MCRECORDDUP {resultVar, recordExp, loc} =>
        let
          val recordExp = compileValue env recordExp
        in
          callIntrinsic NONE sml_push_fp nil
          o callIntrinsic (SOME (#id resultVar)) sml_obj_dup [recordExp]
          o callIntrinsic NONE sml_pop_fp nil
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
      | M.MCCALL {resultVar, codeExp, closureEnvExp, argExpList, tail,
                  handler, loc} =>
        let
          val codePtr = compileValue env codeExp
          val clsEnv = Option.map (compileValue env) closureEnvExp
          val argList = map (fn v => ([L.INREG], compileValue env v)) argExpList
          val args =
              case clsEnv of
                NONE => argList
              | SOME v => ([L.INREG], (L.PTR L.I8, #2 v)) :: argList
        in
          callInsn {result = SOME (compileVarInfo resultVar),
                    tail = tail
                           andalso #enableTailcallOpt env
                           andalso length args <= 2,
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
          val symbol = externSymbolToSymbol id
          val dst = (L.PTR (compileTy ty), L.CONST (L.SYMBOL symbol))
        in
          case ty of
            (_, T.BOXEDty) =>
            callIntrinsic NONE sml_write [nullOperand, dst, value]
          | _ =>
            insn1 (L.STORE {dst = dst, value = value})
        end

  fun compileLast (env:env) mcexp_last =
      case mcexp_last of
        M.MCRETURN {value, loc} =>
        #returnInsns env (compileValue env value)
      | M.MCRAISE {argExp, loc} =>
        callIntrinsic NONE sml_raise [compileValue env argExp]
        o last L.UNREACHABLE
      | M.MCHANDLER {nextExp, id, exnVar, handlerExp, loc} =>
        landingPad (id, CATCH exnVar, compileExp env handlerExp o ignore)
        o compileExp env nextExp
      | M.MCSWITCH {switchExp, expTy, branches, default, loc} =>
        let
          val switchValue = compileValue env switchExp
          val _ = if isIntTy (#1 switchValue)
                  then () else raise Bug.Bug "compileExp: MCSWITCH"
          val constTy = compileTy expTy
          val branches =
              map (fn (const, label) =>
                      ((constTy, compileConst (#topdataMap env) const),
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

  fun compileTopdec {topdataMap, extraDataMap} topdec =
      case topdec of
        M.MTTOPLEVEL {symbol, frameSlots, bodyExp, loc} =>
        let
          val (insns1, slotMap) = allocSlots frameSlots
          val env =
              {slotAddrMap = slotMap,
               topdataMap = topdataMap,
               extraDataMap = extraDataMap,
               enableTailcallOpt = false,
               returnInsns = fn _ => last L.RET_VOID} : env
          val body =
              insns1
              o compileExp env bodyExp
        in
          [L.DEFINE
             {linkage = SOME L.EXTERNAL,
              cconv = SOME L.FASTCC,
              retAttrs = nil,
              retTy = L.VOID,
              name = toplevelSymbolToSymbol symbol,
              parameters = [],
              fnAttrs = nil,
              gcname = gcname,
              body = body ()}]
        end
      | M.MTFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar, frameSlots,
                      bodyExp, retTy, loc} =>
        let
          val closureEnvArg =
              case closureEnvVar of
                NONE => nil
              | SOME {id, ty} => [(compileTy ty, [L.INREG], id)]
          val retTy = compileTy retTy
          val args = map (fn {id, ty} => (compileTy ty, [L.INREG], id))
                         argVarList
          val params = closureEnvArg @ args
          val (insns1, slotMap) = allocSlots frameSlots
          val env = {slotAddrMap = slotMap,
                     topdataMap = topdataMap,
                     extraDataMap = extraDataMap,
                     enableTailcallOpt = length params <= 2,
                     returnInsns = fn v => last (L.RET v)} : env
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
              gcname = gcname,
              body = body ()}]
        end
      | M.MTCALLBACKFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
                              frameSlots, bodyExp, attributes, retTy,
                              cleanupHandler, loc} =>
        let
          val args = map (fn {id,ty} => (compileTy ty,nil,id)) argVarList
          val retTy = case retTy of NONE => L.VOID
                                  | SOME ty => compileTy ty
          val cconv = compileCallConv (#callingConvention attributes)
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
          val (insns2, slotMap) = allocSlots frameSlots
          val env =
              {slotAddrMap = slotMap,
               topdataMap = topdataMap,
               extraDataMap = extraDataMap,
               enableTailcallOpt = false,
               returnInsns =
                 fn x => callIntrinsic NONE sml_control_finish nil
                         o last (case retTy of
                                   L.VOID => L.RET_VOID
                                 | _ => L.RET x)}
          val header = VarID.generate ()
          val body =
              insns1
              o insn1 (L.ALLOCA (header, L.PTR L.I8))
              o callIntrinsic NONE llvm_gcroot
                              [(L.PTR (L.PTR L.I8), L.VAR header),
                               (L.PTR L.I8,
                                L.CONST
                                  (L.CONST_INTTOPTR ((L.I32, L.INTCONST 0w1),
                                                     L.PTR L.I8)))]
              o insns2
              o callIntrinsic NONE sml_control_start nil
              o landingPad (cleanupHandler, CLEANUP,
                            callIntrinsic NONE sml_control_finish nil)
              o compileExp env bodyExp
        in
          [L.DEFINE
             {linkage = SOME L.INTERNAL,
              cconv = cconv,
              retAttrs = nil,
              retTy = retTy,
              name = callbackEntryLabelToSymbol id,
              parameters = args,
              fnAttrs = [L.UWTABLE],
              gcname = gcname,
              body = body ()}]
        end

  fun pad (i, j) =
      if i > j then raise Bug.Bug "pad"
      else if i = j then nil
      else [(L.ARRAY (j - i, L.I8), L.ZEROINITIALIZER)]

  fun compileInitConst topdataMap const =
      case compileTopConst topdataMap const of
        (ty, const) => (ty, L.INIT_CONST const)

  fun allocTopData {id, payloadSize, mutable, objType, data} =
      let
        val header =
            case makeHeaderWord
                   emptyEnv
                   (objType, (objHeaderTy, L.CONST (L.INTCONST payloadSize))) of
                (_, (ty, L.CONST c)) => (ty, L.INIT_CONST c)
              | _ => raise Bug.Bug "allocTopData"
        val data = pad (0w0, dataLabelOffset - objHeaderSize) @ [header] @ data
        val ty = L.STRUCT (map #1 data, {packed=true})
      in
        ([L.GLOBALVAR {name = dataLabelToSymbol id,
                       linkage = SOME L.INTERNAL,
                       constant = not mutable,
                       ty = ty,
                       initializer = L.INIT_STRUCT (data, {packed=true}),
                       align = SOME TypeLayout2.maxSize}],
         DataLabel.Map.singleton (id, ty),
         ExtraDataLabel.Map.empty)
      end

  fun compileTopdata topdataMap topdata =
      case topdata of
        M.NTEXTERNVAR {id, ty, loc} =>
        ([L.EXTERN
            {name = externSymbolToSymbol id,
             ty = compileTy ty}],
         DataLabel.Map.empty,
         ExtraDataLabel.Map.empty)
      | M.NTEXPORTVAR {id, ty, value, loc} =>
        ([L.GLOBALVAR
            {name = externSymbolToSymbol id,
             linkage = NONE,
             constant = false,
             ty = compileTy ty,
             initializer =
               case value of
                 SOME v => L.INIT_CONST (#2 (compileTopConst topdataMap v))
               | NONE => L.ZEROINITIALIZER,
             align = NONE}],
         DataLabel.Map.empty,
         ExtraDataLabel.Map.empty)
      | M.NTSTRING {id, string, loc} =>
        let
          val len = Word32.fromInt (size string)
          val op + = Word32.+
        in
          allocTopData
            {id = id,
             payloadSize = len + 0w1,
             mutable = false,
             objType = M.OBJTYPE_UNBOXED_VECTOR,
             data = [(L.ARRAY (len + 0w1, L.I8),
                      L.INIT_STRING (string ^ "\000"))]}
        end
      | M.NTLARGEINT {id, value, loc} =>
        let
          val src = CharVector.map (fn #"~" => #"-" | x => x)
                                   (BigInt.fmt StringCvt.HEX value)
          val ty = L.ARRAY (Word32.fromInt (size src + 1), L.I8)
        in
          ([L.GLOBALVAR
              {name = extraDataLabelToSymbol id,
               linkage = SOME L.INTERNAL,
               constant = true,
               ty = ty,
               initializer = L.INIT_STRING (src ^ "\000"),
               align = NONE}],
           DataLabel.Map.empty,
           ExtraDataLabel.Map.singleton (id, ty))
        end
      | M.NTRECORD {id, tyvarKindEnv, recordTy=_, fieldList, isMutable,
                    clearPad, bitmaps, loc} =>
        let
          (* FIXME : optimize bitmap *)
          val fields =
              map (fn {fieldExp, fieldSize, fieldIndex} =>
                      (compileTopConst topdataMap fieldExp,
                       compileTopConstWord fieldIndex,
                       compileTopConstWord fieldSize))
                  fieldList
          val bitmaps =
              map (fn {bitmapIndex, bitmapExp} =>
                      (compileInitConst topdataMap bitmapExp,
                       compileTopConstWord bitmapIndex))
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
             objType = M.OBJTYPE_RECORD,
             data = pack 0w0 fields}
        end
      | M.NTARRAY {id, elemTy, isMutable, clearPad, numElements,
                   initialElements, elemSizeExp, tagExp, loc} =>
        let
          val initialElements =
              map (compileInitConst topdataMap) initialElements
          val numElements = compileTopConstWord numElements
          val elemTy = compileTy elemTy
          val elemSize = compileTopConstWord elemSizeExp
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
             objType = objType,
             data = initialElements @ filler}
        end

  fun compileTopdataList topdataMap nil =
      (nil, DataLabel.Map.empty, ExtraDataLabel.Map.empty)
    | compileTopdataList topdataMap (dec::decs) =
      let
        val (decs1, topdataMap1, extraDataMap1) = compileTopdata topdataMap dec
        val (decs2, topdataMap2, extraDataMap2) =
            compileTopdataList topdataMap decs
      in
        (decs1 @ decs2,
         DataLabel.Map.unionWith
           (fn _ => raise Bug.Bug "compileTopdataList")
           (topdataMap1, topdataMap2),
         ExtraDataLabel.Map.unionWith
           (fn _ => raise Bug.Bug "compileTopdataList")
           (extraDataMap1, extraDataMap2))
      end

  fun compile {moduleName} ({topdata, topdecs}:M.program) =
      let
        val topdecs = MachineCodeRename.rename topdecs
        val _ = initIntrinsics ()
        val _ = initForeignEntries ()
        val (_, topdataMap, _) = compileTopdataList NONE topdata
        val (decs3, topdataMap, extraDataMap) =
            compileTopdataList (SOME topdataMap) topdata
        val env = {topdataMap = topdataMap, extraDataMap = extraDataMap}
        val decs4 = List.concat (map (compileTopdec env) topdecs)
        val decs2 = declareIntrinsics ()
        val decs1 = declareForeignEntries ()
      in
        {
          moduleName = moduleName,
          datalayout = NONE,  (* FIXME *)
          triple = SOME (SMLSharp_Config.TARGET_TRIPLE ()),
          topdecs = decs1 @ decs2 @ decs3 @ decs4
        } : L.program
      end
      handle e as Fail x => (print x; raise e)

end
