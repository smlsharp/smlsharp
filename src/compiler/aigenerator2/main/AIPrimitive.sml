(**
 * abstract instruction generator for primitives
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: AIPrimitive.sml,v 1.12 2008/08/06 17:23:39 ohori Exp $
 *)
structure AIPrimitive : sig

  val copyBlockPrimName: string
  val strCmpPrimName: string
  val intInfCmpPrimName: string
  val loadIntInfPrimName: string
  val memcpyPrimName: string
  val objectEqualPrimName: string

  val CopyBlock
      : {dst: AbstractInstruction2.varInfo,
         block: AbstractInstruction2.value,
         loc: AbstractInstruction2.loc}
        -> AbstractInstruction2.instruction list
  val StrCmp
      : {dst: AbstractInstruction2.varInfo,
         arg1: AbstractInstruction2.value,
         arg2: AbstractInstruction2.value,
         loc: AbstractInstruction2.loc}
        -> AbstractInstruction2.instruction list
  val IntInfCmp
      : {dst: AbstractInstruction2.varInfo,
         arg1: AbstractInstruction2.value,
         arg2: AbstractInstruction2.value,
         loc: AbstractInstruction2.loc} 
        -> AbstractInstruction2.instruction list
  val LoadIntInf
      : {dst: AbstractInstruction2.varInfo,
         arg: AbstractInstruction2.value,
         loc: AbstractInstruction2.loc}
        -> AbstractInstruction2.instruction list
  val Memcpy
      : {src: AbstractInstruction2.value,
         srcOffset: AbstractInstruction2.value,
         dst: AbstractInstruction2.value,
         dstOffset: AbstractInstruction2.value,
         length: AbstractInstruction2.value,
         tag: AbstractInstruction2.value,
         loc: AbstractInstruction2.loc}
        -> AbstractInstruction2.instruction list

  val transform
      : {prim: BuiltinPrimitive.primitive,
         dstVarList: AbstractInstruction2.varInfo list,
         dstTyList: AbstractInstruction2.ty list,
         argList: AbstractInstruction2.value list,
         argTyList: AbstractInstruction2.ty list,
         instSizeList: AbstractInstruction2.value list,
         instTagList: AbstractInstruction2.value list,
         loc: AbstractInstruction2.loc}
        -> AbstractInstruction2.instruction list

  val needDivZeroCheck
      : BuiltinPrimitive.primitive -> AbstractInstruction2.ty option

end =
struct
  structure AbstractInstruction = AbstractInstruction2

  structure I = AbstractInstruction
  structure P = BuiltinPrimitive

  fun newVar ty =
      let
        val id = VarID.generate ()
        val displayName = "$" ^ VarID.toString id
      in
        {id = id, ty = ty, displayName = displayName} : I.varInfo
      end

  fun newArg (ty, argKind) =
      let
        val id = VarID.generate  ()
      in
        {id = id, ty = ty, argKind = argKind} : I.argInfo
      end
      
  datatype primop =
      Op1 of I.op1 * I.ty * I.ty
    | Op2 of I.op2 * I.ty * I.ty * I.ty
    | FloatOp of string * primop
    | Special of {dst: I.varInfo,
                  args: I.value list,
                  argTys: I.ty list,
                  instSizes: I.value list,
                  instTags: I.value list,
                  loc: I.loc}
                 -> I.instruction list
    | Ext of {name: string, alloc: bool}

  val copyBlockPrimName = "sml_obj_dup"
  val strCmpPrimName = "prim_String_cmp"
  val intInfCmpPrimName = "prim_IntInf_cmp"
  val loadIntInfPrimName = "prim_IntInf_load"
  val memcpyPrimName = "prim_CopyMemory"
  val objectEqualPrimName = "sml_obj_equal"

  fun CallExt {dstVarList, entry, isPure, allocMLValue, argList,
               calleeTy as (argTys, retTys), loc} =
      let
        val attributes =
            {
              isPure = isPure,
              noCallback = true,
              allocMLValue = allocMLValue,
              suspendThread = false,
              callingConvention = NONE
            } : I.ffiAttributes
        fun genArgs (n, arg::argList, ty::tys) =
            let
              val a = newArg (ty, I.ExtArg {index = n, argTys = argTys,
                                            attributes = attributes})
              val (argVars, insns) = genArgs (n + 1, argList, tys)
            in
              (a :: argVars,
               I.Set {dst = a, ty = ty, value = arg, loc = loc} :: insns)
            end
          | genArgs (n, nil, nil) = (nil, nil)
          | genArgs _ = raise Control.Bug "callext: genArgs"

        fun genRets (n, dst::dstList, ty::tys) =
            let
              val a = newArg (ty, I.ExtRet {index = n, retTys = retTys,
                                            attributes = attributes})
              val (retVars, insns) = genRets (n + 1, dstList, tys)
            in
              (a :: retVars,
               I.Get {dst = dst, ty = ty, src = a, loc = loc} :: insns)
            end
          | genRets (n, nil, nil) = (nil, nil)
          | genRets _ = raise Control.Bug "callext: genRets"

        val (args, sets) = genArgs (0, argList, argTys)
        val (rets, gets) = genRets (0, dstVarList, retTys)
      in
        sets @
        (I.CallExt {dstVarList = rets,
                    entry = I.ExtFunLabel entry,
                    attributes = attributes,
                    argList = args,
                    calleeTy = calleeTy,
                    loc = loc}
         :: gets)
      end

  fun CopyBlock {dst, block, loc} =
      CallExt {dstVarList = [dst],
               entry = copyBlockPrimName,
               isPure = false,
               allocMLValue = true,
               argList = [block],
               calleeTy = ([I.BOXED], [I.BOXED]),
               loc = loc}

  fun StrCmp {dst, arg1, arg2, loc} =
      CallExt {dstVarList = [dst],
               entry = strCmpPrimName,
               isPure = true,
               allocMLValue = false,
               argList = [arg1, arg2],
               calleeTy = ([I.BOXED, I.BOXED], [I.SINT]),
               loc = loc}

  fun IntInfCmp {dst, arg1, arg2, loc} =
      CallExt {dstVarList = [dst],
               entry = intInfCmpPrimName,
               isPure = true,
               allocMLValue = false,
               argList = [arg1, arg2],
               calleeTy = ([I.BOXED, I.BOXED], [I.SINT]),
               loc = loc}

  fun LoadIntInf {dst, arg, loc} =
      CallExt {dstVarList = [dst],
               entry = loadIntInfPrimName,
               isPure = true,
               allocMLValue = true,
               argList = [arg],
               calleeTy = ([I.HEAPPOINTER], [I.BOXED]),
               loc = loc}

  fun Memcpy {src, srcOffset, dst, dstOffset, length, tag, loc} =
      CallExt {dstVarList = nil,
               entry = memcpyPrimName,
               isPure = true,
               allocMLValue = false,
               argList = [dst, dstOffset, src, srcOffset, length, tag],
               calleeTy = ([I.BOXED, I.UINT, I.BOXED, I.UINT,
                            I.UINT, I.UINT], []),
               loc = loc}
      
  fun stringCmp {dst, args=[arg1, arg2], argTys=[ty1, ty2],
                 instSizes=nil, instTags=nil, loc} =
      StrCmp {dst = dst,
              arg1 = arg1,
              arg2 = arg2,
              loc = loc}
    | stringCmp _ =
      raise Control.Bug "invalid arity for comparison"

  fun advancePointer {dst, args=[arg1, arg2], argTys=[ty1, ty2],
                      instSizes=[sz], instTags=[tag], loc} =
      let
        fun shiftAndAdd n =
            let
              val var1 = newVar I.UINT
              val var2 = newVar I.SINT
            in
              [I.PrimOp1 {dst = var1,
                          op1 = (I.Cast, I.SINT, I.UINT),
                          arg = arg2,
                          loc = loc},
               I.PrimOp2 {dst = var1,
                          op2 = (I.LShift, I.UINT, I.UINT, I.UINT),
                          arg1 = I.Var var1,
                          arg2 = I.UInt n,
                          loc = loc},
               I.PrimOp1 {dst = var2,
                          op1 = (I.Cast, I.UINT, I.SINT),
                          arg = I.Var var1,
                          loc = loc},
               I.PrimOp2 {dst = dst,
                          op2 = (I.PointerAdvance,
                                 I.CPOINTER, I.SINT, I.CPOINTER),
                          arg1 = arg1,
                          arg2 = I.Var var2,
                          loc = loc}]
            end
      in
        case sz of
          I.UInt 0w1 =>
          [
            I.PrimOp2 {dst = dst,
                       op2 = (I.PointerAdvance, I.CPOINTER, I.SINT, I.CPOINTER),
                       arg1 = arg1,
                       arg2 = arg2,
                       loc = loc}
          ]
        | I.UInt 0w2 => shiftAndAdd 0w1
        | I.UInt 0w4 => shiftAndAdd 0w2
        | I.UInt 0w8 => shiftAndAdd 0w3
        | I.UInt 0w16 => shiftAndAdd 0w4
        | _ =>
          let
            val var1 = newVar I.UINT
            val var2 = newVar I.SINT
          in
            [I.PrimOp1 {dst = var1,
                        op1 = (I.Cast, I.SINT, I.UINT),
                        arg = arg2,
                        loc = loc},
             I.PrimOp2 {dst = var1,
                        op2 = (I.Mul, I.UINT, I.UINT, I.UINT),
                        arg1 = I.Var var1,
                        arg2 = sz,
                        loc = loc},
             I.PrimOp1 {dst = var2,
                        op1 = (I.Cast, I.UINT, I.SINT),
                        arg = I.Var var1,
                        loc = loc},
             I.PrimOp2 {dst = dst,
                        op2 = (I.PointerAdvance,
                               I.CPOINTER, I.SINT, I.CPOINTER),
                        arg1 = arg1,
                        arg2 = I.Var var2,
                        loc = loc}]
          end
      end
    | advancePointer _ =
      raise Control.Bug "invalid arity for Ptr_advance"

  fun primEqual {dst, args = [arg1, arg2], argTys = [ty1, ty2],
                 instSizes = [sz], instTags = [tag], loc} =
      if ty1 <> ty2
      then raise Control.Bug "primEqual"
      else if (case ty1 of
                 I.UINT => true
               | I.SINT => true
               | I.BYTE => true
               | I.FLOAT => true
               | I.DOUBLE => true
               | I.CODEPOINTER => true
               | I.HEAPPOINTER => true
               | I.CPOINTER => true
               | I.BOXED => false
               | I.ENTRY => true
               | I.GENERIC _ => false)
      then
        (* monomorphic equal *)
        [
          I.PrimOp2 {dst = dst,
                     op2 = (I.MonoEqual, ty1, ty2, I.UINT),
                     arg1 = arg1,
                     arg2 = arg2,
                     loc = loc}
        ]
      else if ty1 = I.BOXED then
        CallExt {dstVarList = [dst],
                 entry = objectEqualPrimName,
                 isPure = true,
                 allocMLValue = false,
                 argList = [arg1, arg2],
                 calleeTy = ([I.BOXED, I.BOXED], [I.UINT]),
                 loc = loc}
      else
        (* polymorphic equal *)
        let
          val v1 = newVar I.BOXED
          val v2 = newVar I.BOXED
        in
          [
            I.Alloc    {dst = v1,
                        objectType = I.Vector,
                        bitmaps = [tag],
                        payloadSize = sz,
                        loc = loc},
            I.Update   {block = I.Var v1,
                        offset = I.UInt 0w0,
                        size = sz,
                        ty = ty1,
                        value = arg1,
                        barrier = I.NoBarrier,
                        loc = loc},
            I.Alloc    {dst = v2,
                        objectType = I.Vector,
                        bitmaps = [tag],
                        payloadSize = sz,
                        loc = loc},
            I.Update   {block = I.Var v2,
                        offset = I.UInt 0w0,
                        size = sz,
                        ty = ty2,
                        value = arg2,
                        barrier = I.NoBarrier,
                        loc = loc}
          ] @
          CallExt {dstVarList = [dst],
                   entry = objectEqualPrimName,
                   isPure = true,
                   allocMLValue = false,
                   argList = [I.Var v1, I.Var v2],
                   calleeTy = ([I.BOXED, I.BOXED], [I.UINT]),
                   loc = loc}
        end
    | primEqual _ =
      raise Control.Bug "invalid arity for equal"

  fun primCast {dst, args = [arg], argTys = [ty], instSizes, instTags, loc} =
      [
        I.Move {dst = dst, ty = ty, value = arg, loc = loc}
      ]
    | primCast _ = raise Control.Bug "primCast"

  fun primArrayLength {dst, args = [arg1], argTys = [ty1],
                       instSizes = [sz], instTags = [tag], loc} =
      let
        val tmp = newVar I.UINT
      in
        I.PrimOp1 {dst = tmp,
                   op1 = (I.PayloadSize, ty1, I.UINT),
                   arg = arg1,
                   loc = loc} ::
        (case sz of
           I.UInt 0w1 => nil
         | I.UInt 0w2 =>
           [I.PrimOp2 {dst = tmp,
                       op2 = (I.RShift, I.UINT, I.UINT, I.UINT),
                       arg1 = I.Var tmp,
                       arg2 = I.UInt 0w1,
                       loc = loc}]
         | I.UInt 0w4 =>
           [I.PrimOp2 {dst = tmp,
                       op2 = (I.RShift, I.UINT, I.UINT, I.UINT),
                       arg1 = I.Var tmp,
                       arg2 = I.UInt 0w2,
                       loc = loc}]
         | I.UInt 0w8 =>
           [I.PrimOp2 {dst = tmp,
                       op2 = (I.RShift, I.UINT, I.UINT, I.UINT),
                       arg1 = I.Var tmp,
                       arg2 = I.UInt 0w3,
                       loc = loc}]
         | I.UInt 0w16 =>
           [I.PrimOp2 {dst = tmp,
                       op2 = (I.RShift, I.UINT, I.UINT, I.UINT),
                       arg1 = I.Var tmp,
                       arg2 = I.UInt 0w4,
                       loc = loc}]
         | _ =>
           [I.PrimOp2 {dst = tmp,
                       op2 = (I.Div, I.UINT, I.UINT, I.UINT),
                       arg1 = I.Var tmp,
                       arg2 = sz,
                       loc = loc}])
        @ [I.PrimOp1 {dst = dst,
                      op1 = (I.Cast, I.UINT, I.SINT),
                      arg = I.Var tmp,
                      loc = loc}]
      end
    | primArrayLength _ =
      raise Control.Bug "invalid arity for Array_length"

  fun convertPrim prim =
      case prim of
        P.Equal => Special primEqual
      | P.Cast => Special primCast
      | P.IdentityEqual => Op2 (I.MonoEqual, I.BOXED, I.BOXED, I.UINT)
      | P.Exn_Name => raise Control.Bug "convertPrim: Exn_Name"
      | P.Array_allocArray => raise Control.Bug "convertPrim: Array_array"
      | P.Array_copy_unsafe =>
        raise Control.Bug "convertPrim: Array_array_unsafe"
      | P.Array_allocVector => raise Control.Bug "convertPrim: Array_vector"
      | P.Array_sub => raise Control.Bug "convertPrim: Array_sub"
      | P.Array_update => raise Control.Bug "convertPrim: Array_update"
      | P.Ref_alloc => raise Control.Bug "convertPrim: Ref_alloc"
      | P.Ref_deref => raise Control.Bug "convertPrim: Ref_deref"
      | P.Ref_assign => raise Control.Bug "convertPrim: Ref_assign"
      | P.Int_add P.NoOverflowCheck => Op2 (I.Add, I.SINT, I.SINT, I.SINT)
      | P.Int_add P.OverflowCheck => raise Control.Bug "Int_add_ov"
      | P.Real_add =>
        FloatOp ("addReal", Op2 (I.Add, I.DOUBLE, I.DOUBLE, I.DOUBLE))
      | P.Float_add => Op2 (I.Add, I.FLOAT, I.FLOAT, I.FLOAT)
      | P.Word_add => Op2 (I.Add, I.UINT, I.UINT, I.UINT)
      | P.Byte_add => Op2 (I.Add, I.BYTE, I.BYTE, I.BYTE)
      | P.Int_sub P.NoOverflowCheck => Op2 (I.Sub, I.SINT, I.SINT, I.SINT)
      | P.Int_sub P.OverflowCheck => raise Control.Bug "Int_sub_ov"
      | P.Real_sub =>
        FloatOp ("subReal", Op2 (I.Sub, I.DOUBLE, I.DOUBLE, I.DOUBLE))
      | P.Float_sub => Op2 (I.Sub, I.FLOAT, I.FLOAT, I.FLOAT)
      | P.Word_sub => Op2 (I.Sub, I.UINT, I.UINT, I.UINT)
      | P.Byte_sub => Op2 (I.Sub, I.BYTE, I.BYTE, I.BYTE)
      | P.Int_mul P.NoOverflowCheck=> Op2 (I.Mul, I.SINT, I.SINT, I.SINT)
      | P.Int_mul P.OverflowCheck => raise Control.Bug "Int_mul_ov"
      | P.Real_mul =>
        FloatOp ("mulReal", Op2 (I.Mul, I.DOUBLE, I.DOUBLE, I.DOUBLE))
      | P.Float_mul => Op2 (I.Mul, I.FLOAT, I.FLOAT, I.FLOAT)
      | P.Word_mul => Op2 (I.Mul, I.UINT, I.UINT, I.UINT)
      | P.Byte_mul => Op2 (I.Mul, I.BYTE, I.BYTE, I.BYTE)
      | P.Int_div P.NoOverflowCheck => Op2 (I.Div, I.SINT, I.SINT, I.SINT)
      | P.Int_div P.OverflowCheck => raise Control.Bug "Int_div_ov"
      | P.Word_div => Op2 (I.Div, I.UINT, I.UINT, I.UINT)
      | P.Byte_div => Op2 (I.Div, I.BYTE, I.BYTE, I.BYTE)
      | P.Real_div =>
        FloatOp ("divReal", Op2 (I.Div, I.DOUBLE, I.DOUBLE, I.DOUBLE))
      | P.Float_div => Op2 (I.Div, I.FLOAT, I.FLOAT, I.FLOAT)
      | P.Int_mod P.NoOverflowCheck => Op2 (I.Mod, I.SINT, I.SINT, I.SINT)
      | P.Int_mod P.OverflowCheck => raise Control.Bug "Int_mod_ov"
      | P.Real_rem => Op2 (I.Rem, I.DOUBLE, I.DOUBLE, I.DOUBLE)
      | P.Float_rem => Op2 (I.Rem, I.FLOAT, I.FLOAT, I.FLOAT)
      | P.Word_mod => Op2 (I.Mod, I.UINT, I.UINT, I.UINT)
      | P.Byte_mod => Op2 (I.Mod, I.BYTE, I.BYTE, I.BYTE)
      | P.Int_quot P.NoOverflowCheck=> Op2 (I.Quot, I.SINT, I.SINT, I.SINT)
      | P.Int_quot P.OverflowCheck => raise Control.Bug "Int_quot_ov"
      | P.Int_rem P.NoOverflowCheck=> Op2 (I.Rem, I.SINT, I.SINT, I.SINT)
      | P.Int_rem P.OverflowCheck => raise Control.Bug "Int_rem_ov"
      | P.Int_neg P.NoOverflowCheck=> Op1 (I.Neg, I.SINT, I.SINT)
      | P.Int_neg P.OverflowCheck => raise Control.Bug "Int_neg_ov"
      | P.Real_neg => FloatOp ("negReal", Op1 (I.Neg, I.DOUBLE, I.DOUBLE))
      | P.Float_neg => Op1 (I.Neg, I.FLOAT, I.FLOAT)
      | P.Int_abs P.NoOverflowCheck => Op1 (I.Abs, I.SINT, I.SINT)
      | P.Int_abs P.OverflowCheck => raise Control.Bug "Int_abs_ov"
      | P.Real_abs => FloatOp ("absReal", Op1 (I.Abs, I.DOUBLE, I.DOUBLE))
      | P.Float_abs => Op1 (I.Neg, I.FLOAT, I.FLOAT)
      | P.Int_lt => Op2 (I.Lt, I.SINT, I.SINT, I.UINT)
      | P.Real_lt => FloatOp ("ltReal", Op2 (I.Lt, I.DOUBLE, I.DOUBLE, I.UINT))
      | P.Float_lt => Op2 (I.Lt, I.FLOAT, I.FLOAT, I.UINT)
      | P.Word_lt => Op2 (I.Lt, I.UINT, I.UINT, I.UINT)
      | P.Byte_lt => Op2 (I.Lt, I.BYTE, I.BYTE, I.UINT)
      | P.Char_lt => Op2 (I.Lt, I.BYTE, I.BYTE, I.UINT)
      | P.Int_gt => Op2 (I.Gt, I.SINT, I.SINT, I.UINT)
      | P.Real_gt => FloatOp ("gtReal", Op2 (I.Gt, I.DOUBLE, I.DOUBLE, I.UINT))
      | P.Float_gt => Op2 (I.Gt, I.FLOAT, I.FLOAT, I.UINT)
      | P.Word_gt => Op2 (I.Gt, I.UINT, I.UINT, I.UINT)
      | P.Byte_gt => Op2 (I.Gt, I.BYTE, I.BYTE, I.UINT)
      | P.Char_gt => Op2 (I.Gt, I.BYTE, I.BYTE, I.UINT)
      | P.Int_lteq => Op2 (I.Lteq, I.SINT, I.SINT, I.UINT)
      | P.Real_lteq =>
        FloatOp ("lteqReal", Op2 (I.Lteq, I.DOUBLE, I.DOUBLE, I.UINT))
      | P.Float_lteq => Op2 (I.Lteq, I.FLOAT, I.FLOAT, I.UINT)
      | P.Word_lteq => Op2 (I.Lteq, I.UINT, I.UINT, I.UINT)
      | P.Byte_lteq => Op2 (I.Lteq, I.BYTE, I.BYTE, I.UINT)
      | P.Char_lteq => Op2 (I.Lteq, I.BYTE, I.BYTE, I.UINT)
      | P.Int_gteq => Op2 (I.Gteq, I.SINT, I.SINT, I.UINT)
      | P.Real_gteq =>
        FloatOp ("gteqReal", Op2 (I.Gteq, I.DOUBLE, I.DOUBLE, I.UINT))
      | P.Float_gteq => Op2 (I.Gteq, I.FLOAT, I.FLOAT, I.UINT)
      | P.Word_gteq => Op2 (I.Gteq, I.UINT, I.UINT, I.UINT)
      | P.Byte_gteq => Op2 (I.Gteq, I.BYTE, I.BYTE, I.UINT)
      | P.Char_gteq => Op2 (I.Gteq, I.BYTE, I.BYTE, I.UINT)
      | P.Byte_toInt => Op1 (I.ZeroExt, I.BYTE, I.SINT)
      | P.Byte_toIntX => Op1 (I.SignExt, I.BYTE, I.SINT)
      | P.Byte_toWord => Op1 (I.ZeroExt, I.BYTE, I.UINT)
      | P.Byte_fromInt => Op1 (I.Cast, I.SINT, I.BYTE)
      | P.Byte_fromWord => Op1 (I.Cast, I.UINT, I.BYTE)
      | P.Word_toIntX => Op1 (I.Cast, I.UINT, I.SINT)
      | P.Word_fromInt => Op1 (I.Cast, I.SINT, I.UINT)
      | P.Word_andb => Op2 (I.Andb, I.UINT, I.UINT, I.UINT)
      | P.Word_orb => Op2 (I.Orb, I.UINT, I.UINT, I.UINT)
      | P.Word_xorb => Op2 (I.Xorb, I.UINT, I.UINT, I.UINT)
      | P.Word_neg => Op1 (I.Neg, I.UINT, I.UINT)
      | P.Word_notb => Op1 (I.Notb, I.UINT, I.UINT)
      | P.Word_lshift => Op2 (I.LShift, I.UINT, I.UINT, I.UINT)
      | P.Word_rshift => Op2 (I.RShift, I.UINT, I.UINT, I.UINT)
      | P.Word_arshift => Op2 (I.ArithRShift, I.UINT, I.UINT, I.UINT)
      | P.Real_fromInt =>
        FloatOp ("Real_fromInt", Op1 (I.Cast, I.SINT, I.DOUBLE))
      | P.Real_equal =>
        FloatOp ("Real_equal", Op2 (I.MonoEqual, I.DOUBLE, I.DOUBLE, I.UINT))
      | P.Float_equal => Op2 (I.MonoEqual, I.FLOAT, I.FLOAT, I.UINT)
      | P.Real_unorderedOrEqual =>
        Op2 (I.UnorderedOrEqual, I.DOUBLE, I.DOUBLE, I.UINT)
      | P.Float_unorderedOrEqual =>
        Op2 (I.UnorderedOrEqual, I.FLOAT, I.FLOAT, I.UINT)
      | P.Float_fromInt => Op1 (I.Cast, I.SINT, I.FLOAT)
      | P.Float_fromReal => Op1 (I.Cast, I.DOUBLE, I.FLOAT)
      | P.Float_toReal => Op1 (I.Cast, I.FLOAT, I.DOUBLE)
      | P.Float_trunc_unsafe P.NoOverflowCheck => Op1 (I.Cast, I.FLOAT, I.SINT)
      | P.Real_trunc_unsafe P.NoOverflowCheck =>
        FloatOp ("Real_trunc", Op1 (I.Cast, I.DOUBLE, I.SINT))
      | P.Float_trunc_unsafe P.OverflowCheck => raise Control.Bug "Float_trunc"
      | P.Real_trunc_unsafe P.OverflowCheck => raise Control.Bug "Real_trunc"
      | P.Char_ord => Op1 (I.ZeroExt, I.BYTE, I.SINT)
      | P.Char_chr_unsafe => Op1 (I.Cast, I.SINT, I.BYTE)
      | P.Array_length => Special primArrayLength

      (* these are not used currently *)
      | P.Byte_equal => raise Control.Bug "Byte_equal"
      | P.Char_equal => raise Control.Bug "Char_equal"
      | P.Int_equal => raise Control.Bug "Int_equal"
      | P.Word_equal => raise Control.Bug "Word_equal"
      | P.String_equal => raise Control.Bug "String_equal"

      (* these are implemented as runtime functions currently *)
      | P.String_allocArray => Ext{name="prim_String_allocateMutableNoInit",
                                   alloc=true}
      | P.String_allocVector => Ext{name="prim_String_allocateImmutableNoInit",
                                    alloc=true}
      | P.String_copy_unsafe => Ext{name="prim_String_copy", alloc=false}
      | P.String_compare => Special stringCmp
      | P.String_size => Ext{name="prim_String_size", alloc=false}
      | P.String_sub => Ext{name="prim_String_sub", alloc=false} (*unsafe*)
      | P.String_update => Ext{name="prim_String_update", alloc=false} (*unsafe*)
      | P.Ptr_advance => Special advancePointer
      | P.Ptr_deref_int => Ext{name="prim_UnmanagedMemory_subInt", alloc=false}
      | P.Ptr_deref_real => Ext{name="prim_UnmanagedMemory_subReal",alloc=false}
      | P.Ptr_deref_real32 => raise Control.Bug "Ptr_deref_float"
      | P.Ptr_deref_word => Ext{name="prim_UnmanagedMemory_subWord",alloc=false}
      | P.Ptr_deref_char => Ext{name="prim_UnmanagedMemory_subByte", alloc=false}
      | P.Ptr_deref_word8 => Ext{name="prim_UnmanagedMemory_subByte", alloc=false}
      | P.Ptr_deref_ptr => Ext{name="prim_UnmanagedMemory_subPtr", alloc=false}
      | P.Ptr_store_int => Ext{name="prim_UnmanagedMemory_updateInt", alloc=false}
      | P.Ptr_store_real => Ext{name="prim_UnmanagedMemory_updateReal",alloc=false}
      | P.Ptr_store_real32 => raise Control.Bug "Ptr_store_real32"
      | P.Ptr_store_word => Ext{name="prim_UnmanagedMemory_updateWord",alloc=false}
      | P.Ptr_store_char => Ext{name="prim_UnmanagedMemory_updateByte", alloc=false}
      | P.Ptr_store_word8 => Ext{name="prim_UnmanagedMemory_updateByte", alloc=false}
      | P.Ptr_store_ptr => Ext{name="prim_UnmanagedMemory_updatePtr", alloc=false}

  fun needDivZeroCheck prim =
      case prim of
        P.Equal => NONE
      | P.Cast => NONE
      | P.Exn_Name => NONE
      | P.IdentityEqual => NONE
      | P.Array_allocArray => NONE
      | P.Array_copy_unsafe => NONE
      | P.Array_allocVector => NONE
      | P.Array_sub => NONE
      | P.Array_update => NONE
      | P.Ref_alloc => NONE
      | P.Ref_deref => NONE
      | P.Ref_assign => NONE
      | P.Int_add P.NoOverflowCheck => NONE
      | P.Int_add P.OverflowCheck => NONE
      | P.Real_add => NONE
      | P.Float_add => NONE
      | P.Word_add => NONE
      | P.Byte_add => NONE
      | P.Int_sub P.NoOverflowCheck => NONE
      | P.Int_sub P.OverflowCheck => NONE
      | P.Real_sub => NONE
      | P.Float_sub => NONE
      | P.Word_sub => NONE
      | P.Byte_sub => NONE
      | P.Int_mul P.NoOverflowCheck => NONE
      | P.Int_mul P.OverflowCheck => NONE
      | P.Real_mul => NONE
      | P.Float_mul => NONE
      | P.Word_mul => NONE
      | P.Byte_mul => NONE
      | P.Int_div P.NoOverflowCheck => SOME I.SINT
      | P.Int_div P.OverflowCheck => SOME I.SINT
      | P.Word_div => SOME I.UINT
      | P.Byte_div => SOME I.BYTE
      | P.Real_div => NONE
      | P.Float_div => NONE
      | P.Int_mod P.NoOverflowCheck => SOME I.SINT
      | P.Int_mod P.OverflowCheck => SOME I.SINT
      | P.Word_mod => SOME I.UINT
      | P.Byte_mod => SOME I.BYTE
      | P.Real_rem => NONE
      | P.Float_rem => NONE
      | P.Int_quot P.NoOverflowCheck => SOME I.SINT
      | P.Int_quot P.OverflowCheck => SOME I.SINT
      | P.Int_rem P.NoOverflowCheck => SOME I.SINT
      | P.Int_rem P.OverflowCheck => SOME I.SINT
      | P.Int_neg P.NoOverflowCheck => NONE
      | P.Int_neg P.OverflowCheck => NONE
      | P.Real_neg => NONE
      | P.Float_neg => NONE
      | P.Int_abs P.NoOverflowCheck => NONE
      | P.Int_abs P.OverflowCheck => NONE
      | P.Real_abs => NONE
      | P.Float_abs => NONE
      | P.Int_lt => NONE
      | P.Real_lt => NONE
      | P.Float_lt => NONE
      | P.Word_lt => NONE
      | P.Byte_lt => NONE
      | P.Char_lt => NONE
      | P.Int_gt => NONE
      | P.Real_gt => NONE
      | P.Float_gt => NONE
      | P.Word_gt => NONE
      | P.Byte_gt => NONE
      | P.Char_gt => NONE
      | P.Int_lteq => NONE
      | P.Real_lteq => NONE
      | P.Float_lteq => NONE
      | P.Word_lteq => NONE
      | P.Byte_lteq => NONE
      | P.Char_lteq => NONE
      | P.Int_gteq => NONE
      | P.Real_gteq => NONE
      | P.Float_gteq => NONE
      | P.Word_gteq => NONE
      | P.Byte_gteq => NONE
      | P.Char_gteq => NONE
      | P.Byte_toInt => NONE
      | P.Byte_toIntX => NONE
      | P.Byte_toWord => NONE
      | P.Byte_fromInt => NONE
      | P.Byte_fromWord => NONE
      | P.Word_toIntX => NONE
      | P.Word_fromInt => NONE
      | P.Word_andb => NONE
      | P.Word_orb => NONE
      | P.Word_xorb => NONE
      | P.Word_neg => NONE
      | P.Word_notb => NONE
      | P.Word_lshift => NONE
      | P.Word_rshift => NONE
      | P.Word_arshift => NONE
      | P.Real_fromInt => NONE
      | P.Real_equal => NONE
      | P.Float_equal => NONE
      | P.Real_unorderedOrEqual => NONE
      | P.Float_unorderedOrEqual => NONE
      | P.Float_fromInt => NONE
      | P.Float_fromReal => NONE
      | P.Float_toReal => NONE
      | P.Float_trunc_unsafe P.NoOverflowCheck => NONE
      | P.Real_trunc_unsafe P.NoOverflowCheck => NONE
      | P.Float_trunc_unsafe P.OverflowCheck => NONE
      | P.Real_trunc_unsafe P.OverflowCheck => NONE
      | P.Char_ord => NONE
      | P.Char_chr_unsafe => NONE
      | P.Array_length => NONE
      | P.Byte_equal => NONE
      | P.Char_equal => NONE
      | P.Int_equal => NONE
      | P.Word_equal => NONE
      | P.String_allocArray => NONE
      | P.String_allocVector => NONE
      | P.String_copy_unsafe => NONE
      | P.String_equal => NONE
      | P.String_compare => NONE
      | P.String_size => NONE
      | P.String_sub => NONE
      | P.String_update => NONE
      | P.Ptr_advance => NONE
      | P.Ptr_deref_int => NONE
      | P.Ptr_deref_real => NONE
      | P.Ptr_deref_real32 => NONE
      | P.Ptr_deref_word => NONE
      | P.Ptr_deref_char => NONE
      | P.Ptr_deref_word8 => NONE
      | P.Ptr_deref_ptr => NONE
      | P.Ptr_store_int => NONE
      | P.Ptr_store_real => NONE
      | P.Ptr_store_real32 => NONE
      | P.Ptr_store_word => NONE
      | P.Ptr_store_char => NONE
      | P.Ptr_store_word8 => NONE
      | P.Ptr_store_ptr => NONE

  fun transform {prim,
                 dstVarList, dstTyList, argList, argTyList,
                 instSizeList, instTagList,
                 loc} =
      let
        fun primInsn x =
            case (x, dstVarList, argList) of
              (Ext {name, alloc}, _, _) =>
              let
                val {memory, update, read, throw} =
                    BuiltinPrimitive.haveSideEffect prim
                val isPure = not memory andalso not update
                             andalso not read andalso not throw
              in
                CallExt {dstVarList = dstVarList,
                         entry = name,
                         isPure = isPure,
                         allocMLValue = alloc,
                         argList = argList,
                         calleeTy = (argTyList, dstTyList),
                         loc = loc}
              end
            | (FloatOp (oldname, x), dsts, args) =>
              primInsn
                (if !Control.enableUnboxedFloat then x
                 else Ext {name = oldname, alloc = true})
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
        primInsn (convertPrim prim)
      end
end
