(**
 * abstract instruction generator for primitives
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: AIPrimitive.sml,v 1.12 2008/08/06 17:23:39 ohori Exp $
 *)
structure AIPrimitive : sig

  val copyBlockPrimName: string
  val strCmpPrimName: string
  val intInfCmpPrimName: string
  val loadIntInfPrimName: string
  val memcpyPrimName: string
  val polyEqualPrimName: string

  val CopyBlock
      : {dst: AbstractInstruction.varInfo,
         block: AbstractInstruction.value,
         loc: AbstractInstruction.loc}
        -> AbstractInstruction.instruction
  val StrCmp
      : {dst: AbstractInstruction.varInfo,
         arg1: AbstractInstruction.value,
         arg2: AbstractInstruction.value,
         loc: AbstractInstruction.loc}
        -> AbstractInstruction.instruction
  val IntInfCmp
      : {dst: AbstractInstruction.varInfo,
         arg1: AbstractInstruction.value,
         arg2: AbstractInstruction.value,
         loc: AbstractInstruction.loc}
        -> AbstractInstruction.instruction
  val LoadIntInf
      : {dst: AbstractInstruction.varInfo,
         arg: AbstractInstruction.value,
         loc: AbstractInstruction.loc}
        -> AbstractInstruction.instruction
  val Memcpy
      : {src: AbstractInstruction.value,
         srcOffset: AbstractInstruction.value,
         dst: AbstractInstruction.value,
         dstOffset: AbstractInstruction.value,
         length: AbstractInstruction.value,
         tag: AbstractInstruction.value,
         loc: AbstractInstruction.loc}
        -> AbstractInstruction.instruction

  val transform
      : {prim: BuiltinPrimitive.primitive,
         dstVarList: AbstractInstruction.varInfo list,
         dstTyList: AbstractInstruction.ty list,
         argList: AbstractInstruction.value list,
         argTyList: AbstractInstruction.ty list,
         instSizeList: AbstractInstruction.value list,
         instTagList: AbstractInstruction.value list,
         loc: AbstractInstruction.loc}
        -> AbstractInstruction.instruction list

end =
struct

  structure I = AbstractInstruction
  structure P = BuiltinPrimitive

  fun newVar ty =
      let
        val id = VarID.generate ()
        val displayName = "$" ^ VarID.toString id
      in
        {id = id, ty = ty, displayName = displayName} : I.varInfo
      end

  datatype primop =
      Op1 of I.op1 * I.ty * I.ty
    | Op2 of I.op2 * I.ty * I.ty * I.ty
    | FloatOp of primop
(*
    | Prim of {name: string, hasEffect: bool, builtin: bool}
*)
    | Special of {dst: I.varInfo,
                  args: I.value list,
                  argTys: I.ty list,
                  instSizes: I.value list,
                  instTags: I.value list,
                  loc: I.loc}
                 -> I.instruction list
    | NewOp of primop (* for YASIGenerator *)
    | Ext of string

  val copyBlockPrimName = "sml_obj_dup"
  val strCmpPrimName = "prim_String_cmp"
  val intInfCmpPrimName = "prim_IntInf_cmp"
  val loadIntInfPrimName = "prim_IntInf_load"
  val memcpyPrimName = "prim_CopyMemory"
  val polyEqualPrimName = "builtin_PolyEqual"

  fun CopyBlock {dst, block, loc} =
      I.CallExt {dstVarList = [dst],
                 callee = I.Primitive {oldPrimName = "",
                                       name = copyBlockPrimName,
                                       hasEffect = false,
                                       builtin = false},
                 argList = [block],
                 calleeTy = ([I.BOXED], [I.BOXED]),
                 loc = loc}

  fun StrCmp {dst, arg1, arg2, loc} =
      I.CallExt {dstVarList = [dst],
                 callee = I.Primitive {oldPrimName = "",
                                       name = strCmpPrimName,
                                       hasEffect = false,
                                       builtin = false},
                 argList = [arg1, arg2],
                 calleeTy = ([I.BOXED, I.BOXED], [I.SINT]),
                 loc = loc}

  fun IntInfCmp {dst, arg1, arg2, loc} =
      I.CallExt {dstVarList = [dst],
                 callee = I.Primitive {oldPrimName = "",
                                       name = intInfCmpPrimName,
                                       hasEffect = false,
                                       builtin = false},
                 argList = [arg1, arg2],
                 calleeTy = ([I.BOXED, I.BOXED], [I.SINT]),
                 loc = loc}

  fun LoadIntInf {dst, arg, loc} =
      I.CallExt {dstVarList = [dst],
                 callee = I.Primitive {oldPrimName = "",
                                       name = loadIntInfPrimName,
                                       hasEffect = false,
                                       builtin = false},
                 argList = [arg],
                 calleeTy = ([I.HEAPPOINTER], [I.BOXED]),
                 loc = loc}

  fun Memcpy {src, srcOffset, dst, dstOffset, length, tag, loc} =
      I.CallExt {dstVarList = nil,
                 callee = I.Primitive {oldPrimName = "",
                                       name = memcpyPrimName,
                                       hasEffect = true,
                                       builtin = false},
                 argList = [dst, dstOffset, src, srcOffset, length, tag],
                 calleeTy = ([I.BOXED, I.OFFSET, I.BOXED, I.OFFSET,
                              I.SIZE, I.UINT], []),
                 loc = loc}

  fun useCmp cmpPrim cmpOp {dst, args=[arg1, arg2], argTys=[ty1, ty2],
                            instSizes=nil, instTags=nil, loc} =
      let
        val var = newVar I.SINT
      in
        [
          (* dst = strcmp(arg1, arg2) op 0; *)
          cmpPrim   {dst = var,
                     arg1 = arg1,
                     arg2 = arg2,
                     loc = loc},
          I.PrimOp2 {dst = dst,
                     op2 = (cmpOp, I.SINT, I.SINT, I.UINT),
                     arg1 = I.Var var,
                     arg2 = I.SInt 0,
                     loc = loc}
        ]
      end
    | useCmp cmpPrim cmpOp _ =
      raise Control.Bug "invalid arity for comparison"

  fun primEqual {dst, args = [arg1, arg2], argTys = [ty1, ty2],
                 instSizes = [sz], instTags = [tag], loc} =
      if (case (ty1, ty2) of
            (I.UINT, I.UINT) => true
          | (I.SINT, I.SINT) => true
          | (I.BYTE, I.BYTE) => true
          | (I.CHAR, I.CHAR) => true
          | (I.FLOAT, I.FLOAT) => true
          | (I.DOUBLE, I.DOUBLE) => true
          | (I.ATOMty, I.ATOMty) => true
          | (I.DOUBLEty, I.DOUBLEty) => true
          | (I.CODEPOINTER, I.CODEPOINTER) => true
          | (I.HEAPPOINTER, I.HEAPPOINTER) => true
          | (I.CPOINTER, I.CPOINTER) => true
          | _ => false)
      then
        (* monomorphic equal *)
        [
          I.PrimOp2 {dst = dst,
                     op2 = (I.MonoEqual, ty1, ty2, I.UINT),
                     arg1 = arg1,
                     arg2 = arg2,
                     loc = loc}
        ]
      else
        (* polymorphic equal *)
        [
          I.CallExt {dstVarList = [dst],
                     callee = I.Primitive {oldPrimName = "",
                                           name = polyEqualPrimName,
                                           hasEffect = false,
                                           builtin = true},
                     argList = [arg1, arg2, sz, tag],
                     calleeTy = ([ty1, ty2, I.UINT, I.UINT], [I.UINT]),
                     loc = loc}
        ]
    | primEqual _ =
      raise Control.Bug "invalid arity for equal"

  fun primArrayLength {dst, args = [arg1], argTys = [ty1],
                       instSizes = [sz], instTags = [tag], loc} =
      I.PrimOp1 {dst = dst,
                 op1 = (I.Length, ty1, I.UINT),
                 arg = arg1,
                 loc = loc} ::
      (case sz of
         I.UInt 0w1 => nil
       | I.UInt 0w2 =>
         [I.PrimOp2 {dst = dst,
                     op2 = (I.RShift, I.UINT, I.UINT, I.UINT),
                     arg1 = I.Var dst,
                     arg2 = I.UInt 0w1,
                     loc = loc}]
       | I.UInt 0w4 =>
         [I.PrimOp2 {dst = dst,
                     op2 = (I.RShift, I.UINT, I.UINT, I.UINT),
                     arg1 = I.Var dst,
                     arg2 = I.UInt 0w2,
                     loc = loc}]
       | I.UInt 0w8 =>
         [I.PrimOp2 {dst = dst,
                     op2 = (I.RShift, I.UINT, I.UINT, I.UINT),
                     arg1 = I.Var dst,
                     arg2 = I.UInt 0w3,
                     loc = loc}]
       | I.UInt 0w16 =>
         [I.PrimOp2 {dst = dst,
                     op2 = (I.RShift, I.UINT, I.UINT, I.UINT),
                     arg1 = I.Var dst,
                     arg2 = I.UInt 0w4,
                     loc = loc}]
       | _ =>
         [I.PrimOp2 {dst = dst,
                     op2 = (I.Div, I.UINT, I.UINT, I.UINT),
                     arg1 = I.Var dst,
                     arg2 = sz,
                     loc = loc}])
    | primArrayLength _ =
      raise Control.Bug "invalid arity for Array_length"

  fun convertPrim prim =
      case prim of
        P.PolyEqual => Special primEqual
      | P.Int_add P.NoOverflowCheck => Op2 (I.Add, I.SINT, I.SINT, I.SINT)
      | P.Int_add P.OverflowCheck => raise Control.Bug "Int_add_ov"
      | P.Real_add => FloatOp (Op2 (I.Add, I.DOUBLE, I.DOUBLE, I.DOUBLE))
      | P.Float_add => Op2 (I.Add, I.FLOAT, I.FLOAT, I.FLOAT)
      | P.Word_add => Op2 (I.Add, I.UINT, I.UINT, I.UINT)
      | P.Byte_add => Op2 (I.Add, I.BYTE, I.BYTE, I.BYTE)
      | P.Int_sub P.NoOverflowCheck => Op2 (I.Sub, I.SINT, I.SINT, I.SINT)
      | P.Int_sub P.OverflowCheck => raise Control.Bug "Int_sub_ov"
      | P.Real_sub => FloatOp (Op2 (I.Sub, I.DOUBLE, I.DOUBLE, I.DOUBLE))
      | P.Float_sub => Op2 (I.Sub, I.FLOAT, I.FLOAT, I.FLOAT)
      | P.Word_sub => Op2 (I.Sub, I.UINT, I.UINT, I.UINT)
      | P.Byte_sub => Op2 (I.Sub, I.BYTE, I.BYTE, I.BYTE)
      | P.Int_mul P.NoOverflowCheck=> Op2 (I.Mul, I.SINT, I.SINT, I.SINT)
      | P.Int_mul P.OverflowCheck => raise Control.Bug "Int_mul_ov"
      | P.Real_mul => FloatOp (Op2 (I.Mul, I.DOUBLE, I.DOUBLE, I.DOUBLE))
      | P.Float_mul => Op2 (I.Mul, I.FLOAT, I.FLOAT, I.FLOAT)
      | P.Word_mul => Op2 (I.Mul, I.UINT, I.UINT, I.UINT)
      | P.Byte_mul => Op2 (I.Mul, I.BYTE, I.BYTE, I.BYTE)
      | P.Int_div P.NoOverflowCheck => Op2 (I.Div, I.SINT, I.SINT, I.SINT)
      | P.Int_div P.OverflowCheck => raise Control.Bug "Int_div_ov"
      | P.Word_div => Op2 (I.Div, I.UINT, I.UINT, I.UINT)
      | P.Byte_div => Op2 (I.Div, I.BYTE, I.BYTE, I.BYTE)
      | P.Real_div => FloatOp (Op2 (I.Div, I.DOUBLE, I.DOUBLE, I.DOUBLE))
      | P.Float_div => Op2 (I.Div, I.FLOAT, I.FLOAT, I.FLOAT)
      | P.Int_mod P.NoOverflowCheck => Op2 (I.Mod, I.SINT, I.SINT, I.SINT)
      | P.Int_mod P.OverflowCheck => raise Control.Bug "Int_mod_ov"
      | P.Word_mod => Op2 (I.Mod, I.UINT, I.UINT, I.UINT)
      | P.Byte_mod => Op2 (I.Mod, I.BYTE, I.BYTE, I.BYTE)
      | P.Int_quot P.NoOverflowCheck=> Op2 (I.Quot, I.SINT, I.SINT, I.SINT)
      | P.Int_quot P.OverflowCheck => raise Control.Bug "Int_quot_ov"
      | P.Int_rem P.NoOverflowCheck=> Op2 (I.Rem, I.SINT, I.SINT, I.SINT)
      | P.Int_rem P.OverflowCheck => raise Control.Bug "Int_rem_ov"
      | P.Int_neg P.NoOverflowCheck=> Op1 (I.Neg, I.SINT, I.SINT)
      | P.Int_neg P.OverflowCheck => raise Control.Bug "Int_neg_ov"
      | P.Real_neg => FloatOp (Op1 (I.Neg, I.DOUBLE, I.DOUBLE))
      | P.Float_neg => Op1 (I.Neg, I.FLOAT, I.FLOAT)
      | P.Int_abs P.NoOverflowCheck => Op1 (I.Abs, I.SINT, I.SINT)
      | P.Int_abs P.OverflowCheck => raise Control.Bug "Int_abs_ov"
      | P.Real_abs => FloatOp (Op1 (I.Abs, I.DOUBLE, I.DOUBLE))
      | P.Float_abs => Op1 (I.Neg, I.FLOAT, I.FLOAT)
      | P.Int_lt => Op2 (I.Lt, I.SINT, I.SINT, I.UINT)
      | P.Real_lt => FloatOp (Op2 (I.Lt, I.DOUBLE, I.DOUBLE, I.UINT))
      | P.Float_lt => Op2 (I.Lt, I.FLOAT, I.FLOAT, I.UINT)
      | P.Word_lt => Op2 (I.Lt, I.UINT, I.UINT, I.UINT)
      | P.Byte_lt => Op2 (I.Lt, I.BYTE, I.BYTE, I.UINT)
      | P.Char_lt => Op2 (I.Lt, I.CHAR, I.CHAR, I.UINT)
      | P.Int_gt => Op2 (I.Gt, I.SINT, I.SINT, I.UINT)
      | P.Real_gt => FloatOp (Op2 (I.Gt, I.DOUBLE, I.DOUBLE, I.UINT))
      | P.Float_gt => Op2 (I.Gt, I.FLOAT, I.FLOAT, I.UINT)
      | P.Word_gt => Op2 (I.Gt, I.UINT, I.UINT, I.UINT)
      | P.Byte_gt => Op2 (I.Gt, I.BYTE, I.BYTE, I.UINT)
      | P.Char_gt => Op2 (I.Gt, I.CHAR, I.CHAR, I.UINT)
      | P.Int_lteq => Op2 (I.Lteq, I.SINT, I.SINT, I.UINT)
      | P.Real_lteq => FloatOp (Op2 (I.Lteq, I.DOUBLE, I.DOUBLE, I.UINT))
      | P.Float_lteq => Op2 (I.Lteq, I.FLOAT, I.FLOAT, I.UINT)
      | P.Word_lteq => Op2 (I.Lteq, I.UINT, I.UINT, I.UINT)
      | P.Byte_lteq => Op2 (I.Lteq, I.BYTE, I.BYTE, I.UINT)
      | P.Char_lteq => Op2 (I.Lteq, I.CHAR, I.CHAR, I.UINT)
      | P.Int_gteq => Op2 (I.Gteq, I.SINT, I.SINT, I.UINT)
      | P.Real_gteq => FloatOp (Op2 (I.Gteq, I.DOUBLE, I.DOUBLE, I.UINT))
      | P.Float_gteq => Op2 (I.Gteq, I.FLOAT, I.FLOAT, I.UINT)
      | P.Word_gteq => Op2 (I.Gteq, I.UINT, I.UINT, I.UINT)
      | P.Byte_gteq => Op2 (I.Gteq, I.BYTE, I.BYTE, I.UINT)
      | P.Char_gteq => Op2 (I.Gteq, I.CHAR, I.CHAR, I.UINT)
      | P.Byte_toIntX => Op1 (I.Cast, I.BYTE, I.SINT)
      | P.Byte_fromInt => Op1 (I.Cast, I.SINT, I.BYTE)
      | P.Word_toIntX => Op1 (I.Cast, I.UINT, I.SINT)
      | P.Word_fromInt => Op1 (I.Cast, I.SINT, I.UINT)
      | P.Word_andb => Op2 (I.Andb, I.UINT, I.UINT, I.UINT)
      | P.Word_orb => Op2 (I.Orb, I.UINT, I.UINT, I.UINT)
      | P.Word_xorb => Op2 (I.Xorb, I.UINT, I.UINT, I.UINT)
      | P.Word_notb => Op1 (I.Notb, I.UINT, I.UINT)
      | P.Word_lshift => Op2 (I.LShift, I.UINT, I.UINT, I.UINT)
      | P.Word_rshift => Op2 (I.RShift, I.UINT, I.UINT, I.UINT)
      | P.Word_arshift => Op2 (I.ArithRShift, I.UINT, I.UINT, I.UINT)
      | P.Real_fromInt => FloatOp (Op1 (I.Cast, I.SINT, I.DOUBLE))
      | P.Real_equal => FloatOp (Op2 (I.MonoEqual, I.DOUBLE, I.DOUBLE, I.UINT))
      | P.Float_equal => Op2 (I.MonoEqual, I.FLOAT, I.FLOAT, I.UINT)
      | P.Float_fromInt => Op1 (I.Cast, I.SINT, I.FLOAT)
      | P.Float_fromReal => Op1 (I.Cast, I.DOUBLE, I.FLOAT)
      | P.Float_toReal => Op1 (I.Cast, I.FLOAT, I.DOUBLE)
      | P.Float_trunc_unsafe P.NoOverflowCheck => Op1 (I.Cast, I.FLOAT, I.SINT)
      | P.Real_trunc_unsafe P.NoOverflowCheck =>
        FloatOp (Op1 (I.Cast, I.DOUBLE, I.SINT))
      | P.Float_trunc_unsafe P.OverflowCheck => raise Control.Bug "Float_trunc"
      | P.Real_trunc_unsafe P.OverflowCheck => raise Control.Bug "Real_trunc"
      | P.Char_ord => Op1 (I.Cast, I.CHAR, I.SINT)
      | P.Char_chr_unsafe => Op1 (I.Cast, I.SINT, I.CHAR)
      | P.Array_length => Special primArrayLength

      (* these are not used currently *)
      | P.ObjectEqual => raise Control.Bug "ObjectEqual"
      | P.PointerEqual => raise Control.Bug "PointerEqual"
      | P.Byte_equal => raise Control.Bug "Byte_equal"
      | P.Char_equal => raise Control.Bug "Char_equal"
      | P.Int_equal => raise Control.Bug "Int_equal"
      | P.Word_equal => raise Control.Bug "Word_equal"

      (* these are implemented as runtime functions currently *)
      | P.String_array => Ext "prim_String_allocateMutable"
      | P.String_vector => Ext "prim_String_allocateImmutable"
      | P.String_copy_unsafe => Ext "prim_String_copy"
      | P.String_equal => Special (useCmp StrCmp I.MonoEqual)
      | P.String_gt => Special (useCmp StrCmp I.Gt)
      | P.String_gteq => Special (useCmp StrCmp I.Gteq)
      | P.String_lt => Special (useCmp StrCmp I.Lt)
      | P.String_lteq => Special (useCmp StrCmp I.Lteq)
      | P.String_size => Ext "prim_String_size"
      | P.String_sub_unsafe => Ext "prim_String_sub"
      | P.String_update_unsafe => Ext "prim_String_update"
      | P.IntInf_abs => Ext "prim_IntInf_abs"
      | P.IntInf_add => Ext "prim_IntInf_add"
      | P.IntInf_div => Ext "prim_IntInf_div"
      | P.IntInf_equal => Special (useCmp IntInfCmp I.MonoEqual)
      | P.IntInf_gt => Special (useCmp IntInfCmp I.Gt)
      | P.IntInf_gteq => Special (useCmp IntInfCmp I.Gteq)
      | P.IntInf_lt => Special (useCmp IntInfCmp I.Lt)
      | P.IntInf_lteq => Special (useCmp IntInfCmp I.Lteq)
      | P.IntInf_mod => Ext "prim_IntInf_mod"
      | P.IntInf_mul => Ext "prim_IntInf_mul"
      | P.IntInf_neg => Ext "prim_IntInf_neg"
      | P.IntInf_sub => Ext "prim_IntInf_sub"
      | P.Ptr_deref_int => Ext "prim_UnmanagedMemory_subInt"
      | P.Ptr_deref_real => Ext "prim_UnmanagedMemory_subReal"
      | P.Ptr_deref_float => raise Control.Bug "Ptr_deref_float"
      | P.Ptr_deref_word => Ext "prim_UnmanagedMemory_subWord"
      | P.Ptr_deref_char => Ext "prim_UnmanagedMemory_subByte"
      | P.Ptr_deref_byte => Ext "prim_UnmanagedMemory_subByte"

      (* old primitive; never appear for native backend *)
      | P.RuntimePrim s => raise Control.Bug ("RuntimePrim " ^ s)

  fun transform {prim,
                 dstVarList, dstTyList, argList, argTyList,
                 instSizeList, instTagList,
                 loc} =
      let
        fun primInsn x =
            case (x, dstVarList, argList) of
              (Ext name, _, _) =>
              let
                val hasEffect =
                    case BuiltinPrimitiveUtils.raisesException prim of
                      nil => false | _ => true
                val oldname = BuiltinPrimitiveUtils.oldPrimitiveName prim
              in
                [
                  I.CallExt {dstVarList = dstVarList,
                             callee = I.Primitive {oldPrimName = oldname,
                                                   name = name,
                                                   hasEffect = hasEffect,
                                                   builtin = false},
                             argList = argList,
                             calleeTy = (argTyList, dstTyList),
                             loc = loc}
                ]
              end
(*
            | (Prim prim, _, _) =>
              [
                I.CallExt {dstVarList = dstVarList,
                           callee = I.Primitive prim,
                           argList = argList,
                           calleeTy = (argTyList, dstTyList),
                           loc = loc}
              ]
*)
            | (FloatOp x, dsts, args) =>
              primInsn (if !Control.enableUnboxedFloat then x
                        else Ext (BuiltinPrimitiveUtils.oldPrimitiveName prim))
            | (NewOp x, dsts, args) =>
              primInsn (if Control.nativeGen() then x
                        else Ext (BuiltinPrimitiveUtils.oldPrimitiveName prim))
            | (Special f, [dst], _) =>
              f {dst = dst,
                 args = argList,
                 argTys = argTyList,
                 instSizes = instSizeList,
                 instTags = instTagList,
                 loc = loc}
            | (Op1 op1, [dst], [arg1]) =>
              [
                I.PrimOp1 {dst = dst,
                           op1 = op1,
                           arg = arg1,
                           loc = loc}
              ]
            | (Op2 op2, [dst], [arg1, arg2]) =>
              [
                I.PrimOp2 {dst = dst,
                           op2 = op2,
                           arg1 = arg1,
                           arg2 = arg2,
                           loc = loc}
              ]
            | _ =>
              raise Control.Bug ("AIPrimitive.transform: " ^
                                 Control.prettyPrint
                                   (BuiltinPrimitive.format_primitive prim))
      in
(*
        primInsn prim (*(SEnv.find (primitiveMap, primName))*)
*)
        primInsn (convertPrim prim)
      end

end
