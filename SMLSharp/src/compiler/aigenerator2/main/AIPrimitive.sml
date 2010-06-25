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
    | FloatOp of primop
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
               calleeTy = ([I.BOXED, I.OFFSET, I.BOXED, I.OFFSET,
                            I.SIZE, I.UINT], []),
               loc = loc}
      
  fun useCmp cmpPrim cmpOp {dst, args=[arg1, arg2], argTys=[ty1, ty2],
                            instSizes=nil, instTags=nil, loc} =
      let
        val var = newVar I.SINT
      in
        (* dst = strcmp(arg1, arg2) op 0; *)
        cmpPrim {dst = var,
                 arg1 = arg1,
                 arg2 = arg2,
                 loc = loc} @
        [
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
      if ty1 <> ty2
      then raise Control.Bug "primEqual"
      else if (case ty1 of
                 I.UINT => true
               | I.SINT => true
               | I.BYTE => true
               | I.FLOAT => true
               | I.DOUBLE => true
               | I.ATOMty => true
               | I.DOUBLEty => true
               | I.CODEPOINTER => true
               | I.HEAPPOINTER => true
               | I.CPOINTER => true
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

  fun primArrayLength {dst, args = [arg1], argTys = [ty1],
                       instSizes = [sz], instTags = [tag], loc} =
      I.PrimOp1 {dst = dst,
                 op1 = (I.PayloadSize, ty1, I.UINT),
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

(*
  fun convertPrim ({bindName, instruction, ...} : Primitives.primitive) =
      case (instruction, bindName) of
        (Internal2 _, "=") => Special primEqual
      | (Internal2 _, "addInt") => Op2 (I.Add, I.SINT, I.SINT, I.SINT)
      | (Internal2 _, "addReal") =>
        FloatOp (Op2 (I.Add, I.DOUBLE, I.DOUBLE, I.DOUBLE))
      | (Internal2 _, "addFloat") => Op2 (I.Add, I.FLOAT, I.FLOAT, I.FLOAT)
      | (Internal2 _, "addWord") => Op2 (I.Add, I.UINT, I.UINT, I.UINT)
      | (Internal2 _, "addByte") => Op2 (I.Add, I.BYTE, I.BYTE, I.BYTE)
      | (Internal2 _, "addLargeInt") => Ext
      | (Internal2 _, "subInt") => Op2 (I.Sub, I.SINT, I.SINT, I.SINT)
      | (Internal2 _, "subReal") =>
        FloatOp (Op2 (I.Sub, I.DOUBLE, I.DOUBLE, I.DOUBLE))
      | (Internal2 _, "subFloat") => Op2 (I.Sub, I.FLOAT, I.FLOAT, I.FLOAT)
      | (Internal2 _, "subWord") => Op2 (I.Sub, I.UINT, I.UINT, I.UINT)
      | (Internal2 _, "subByte") => Op2 (I.Sub, I.BYTE, I.BYTE, I.BYTE)
      | (Internal2 _, "subLargeInt") => Ext
      | (Internal2 _, "mulInt") => Op2 (I.Mul, I.SINT, I.SINT, I.SINT)
      | (Internal2 _, "mulReal") =>
        FloatOp (Op2 (I.Mul, I.DOUBLE, I.DOUBLE, I.DOUBLE))
      | (Internal2 _, "mulFloat") => Op2 (I.Mul, I.FLOAT, I.FLOAT, I.FLOAT)
      | (Internal2 _, "mulWord") => Op2 (I.Mul, I.UINT, I.UINT, I.UINT)
      | (Internal2 _, "mulByte") => Op2 (I.Mul, I.BYTE, I.BYTE, I.BYTE)
      | (Internal2 _, "mulLargeInt") => Ext
      | (Internal2 _, "divInt") => Op2 (I.Div, I.SINT, I.SINT, I.SINT)
      | (Internal2 _, "divWord") => Op2 (I.Div, I.UINT, I.UINT, I.UINT)
      | (Internal2 _, "divByte") => Op2 (I.Div, I.BYTE, I.BYTE, I.BYTE)
      | (Internal2 _, "divLargeInt") => Ext
      | (Internal2 _, "/") =>
        FloatOp (Op2 (I.Div, I.DOUBLE, I.DOUBLE, I.DOUBLE))
      | (Internal2 _, "divFloat") => Op2 (I.Div, I.FLOAT, I.FLOAT, I.FLOAT)
      | (Internal2 _, "modInt") => Op2 (I.Mod, I.SINT, I.SINT, I.SINT)
      | (Internal2 _, "modWord") => Op2 (I.Mod, I.UINT, I.UINT, I.UINT)
      | (Internal2 _, "modByte") => Op2 (I.Mod, I.BYTE, I.BYTE, I.BYTE)
      | (Internal2 _, "modLargeInt") => Ext
      | (Internal2 _, "quotInt") => Op2 (I.Quot, I.SINT, I.SINT, I.SINT)
      | (Internal2 _, "quotLargeInt") => Ext
      | (Internal2 _, "remInt") => Op2 (I.Rem, I.SINT, I.SINT, I.SINT)
      | (Internal2 _, "remLargeInt") => Ext
      | (Internal1 _, "negInt") => Op1 (I.Neg, I.SINT, I.SINT)
      | (Internal1 _, "negLargeInt") => Ext
      | (Internal1 _, "negReal") =>
        FloatOp (Op1 (I.Neg, I.DOUBLE, I.DOUBLE))
      | (Internal1 _, "negFloat") => Op1 (I.Neg, I.FLOAT, I.FLOAT)
      | (Internal1 _, "absInt") => Op1 (I.Abs, I.SINT, I.SINT)
      | (Internal1 _, "absLargeInt") => Ext
      | (Internal1 _, "absReal") =>
        FloatOp (Op1 (I.Abs, I.DOUBLE, I.DOUBLE))
      | (Internal1 _, "absFloat") => Op1 (I.Neg, I.FLOAT, I.FLOAT)
      | (Internal2 _, "ltInt") => Op2 (I.Lt, I.SINT, I.SINT, I.UINT)
      | (Internal2 _, "ltReal") =>
        FloatOp (Op2 (I.Lt, I.DOUBLE, I.DOUBLE, I.UINT))
      | (Internal2 _, "ltFloat") => Op2 (I.Lt, I.FLOAT, I.FLOAT, I.UINT)
      | (Internal2 _, "ltWord") => Op2 (I.Lt, I.UINT, I.UINT, I.UINT)
      | (Internal2 _, "ltByte") => Op2 (I.Lt, I.BYTE, I.BYTE, I.UINT)
      | (Internal2 _, "ltChar") => Op2 (I.Lt, I.CHAR, I.CHAR, I.UINT)
      | (Internal2 _, "ltString") => Special (useCmp StrCmp I.Lt)
      | (Internal2 _, "ltLargeInt") => Special (useCmp IntInfCmp I.Lt)
      | (Internal2 _, "gtInt") => Op2 (I.Gt, I.SINT, I.SINT, I.UINT)
      | (Internal2 _, "gtReal") =>
        FloatOp (Op2 (I.Gt, I.DOUBLE, I.DOUBLE, I.UINT))
      | (Internal2 _, "gtFloat") => Op2 (I.Gt, I.FLOAT, I.FLOAT, I.UINT)
      | (Internal2 _, "gtWord") => Op2 (I.Gt, I.UINT, I.UINT, I.UINT)
      | (Internal2 _, "gtByte") => Op2 (I.Gt, I.BYTE, I.BYTE, I.UINT)
      | (Internal2 _, "gtChar") => Op2 (I.Gt, I.CHAR, I.CHAR, I.UINT)
      | (Internal2 _, "gtString") => Special (useCmp StrCmp I.Gt)
      | (Internal2 _, "gtLargeInt") => Special (useCmp IntInfCmp I.Gt)
      | (Internal2 _, "lteqInt") => Op2 (I.Lteq, I.SINT, I.SINT, I.UINT)
      | (Internal2 _, "lteqReal") =>
        FloatOp (Op2 (I.Lteq, I.DOUBLE, I.DOUBLE, I.UINT))
      | (Internal2 _, "lteqFloat") => Op2 (I.Lteq, I.FLOAT, I.FLOAT, I.UINT)
      | (Internal2 _, "lteqWord") => Op2 (I.Lteq, I.UINT, I.UINT, I.UINT)
      | (Internal2 _, "lteqByte") => Op2 (I.Lteq, I.BYTE, I.BYTE, I.UINT)
      | (Internal2 _, "lteqChar") => Op2 (I.Lteq, I.CHAR, I.CHAR, I.UINT)
      | (Internal2 _, "lteqString") => Special (useCmp StrCmp I.Lteq)
      | (Internal2 _, "lteqLargeInt") => Special (useCmp IntInfCmp I.Lteq)
      | (Internal2 _, "gteqInt") => Op2 (I.Gteq, I.SINT, I.SINT, I.UINT)
      | (Internal2 _, "gteqReal") =>
        FloatOp (Op2 (I.Gteq, I.DOUBLE, I.DOUBLE, I.UINT))
      | (Internal2 _, "gteqFloat") => Op2 (I.Gteq, I.FLOAT, I.FLOAT, I.UINT)
      | (Internal2 _, "gteqWord") => Op2 (I.Gteq, I.UINT, I.UINT, I.UINT)
      | (Internal2 _, "gteqByte") => Op2 (I.Gteq, I.BYTE, I.BYTE, I.UINT)
      | (Internal2 _, "gteqChar") => Op2 (I.Gteq, I.CHAR, I.CHAR, I.UINT)
      | (Internal2 _, "gteqString") => Special (useCmp StrCmp I.Gteq)
      | (Internal2 _, "gteqLargeInt") => Special (useCmp IntInfCmp I.Gteq)
      | (Internal1 _, "Word_toIntX") => Op1 (I.Cast, I.UINT, I.SINT)
      | (Internal1 _, "Word_fromInt") => Op1 (I.Cast, I.SINT, I.UINT)
      | (Internal2 _, "Word_andb") => Op2 (I.Andb, I.UINT, I.UINT, I.UINT)
      | (Internal2 _, "Word_orb") => Op2 (I.Orb, I.UINT, I.UINT, I.UINT)
      | (Internal2 _, "Word_xorb") => Op2 (I.Xorb, I.UINT, I.UINT, I.UINT)
      | (Internal1 _, "Word_notb") => Op1 (I.Notb, I.UINT, I.UINT)
      | (Internal2 _, "Word_leftShift") =>
        Op2 (I.LShift, I.UINT, I.UINT, I.UINT)
      | (Internal2 _, "Word_logicalRightShift") =>
        Op2 (I.RShift, I.UINT, I.UINT, I.UINT)
      | (Internal2 _, "Word_arithmeticRightShift") =>
        Op2 (I.ArithRShift, I.UINT, I.UINT, I.UINT)
      | (Internal1 _, "Array_length") =>
        (* for YASIGenerator;
         * In symbolic instruction, Array_length primitives returns the
         * number of elements, not in bytes. *)
        NewOp (Special primArrayLength)
      | (Internal1 _, "Internal_getCurrentIP") => Ext
      | (Internal1 _, "Internal_getStackTrace") => Ext
      | (External _, "Real_fromInt") =>
        FloatOp (Op1 (I.Cast, I.SINT, I.DOUBLE))
      | (External _, "Real_equal") =>
        FloatOp (Op2 (I.MonoEqual, I.DOUBLE, I.DOUBLE, I.UINT))
      | (External _, "Real_toFloat") =>
        FloatOp (Op1 (I.Cast, I.DOUBLE, I.FLOAT))
      | (External _, "Real_fromFloat") =>
        FloatOp (Op1 (I.Cast, I.FLOAT, I.DOUBLE))
      | (External _, "Char_ord") => Op1 (I.Cast, I.CHAR, I.SINT)
      | (External _, "Char_chr") => Op1 (I.Cast, I.SINT, I.CHAR)
      | (External _, "GC_fixedCopy") =>
        Prim {name = bindName, isPure = false}
      | (External _, "GC_copyBlock") =>
        Prim {name = bindName, isPure = false}
      | (External _, _) => Ext
      | (None, _) => Ext
      | _ =>
        (print ("NOTICE: ignore primitive "^bindName^"\n"); Ext)

  val primitiveMap =
      foldl (fn (prim as {bindName, ...}, primMap) =>
                case convertPrim prim of
                  Ext => primMap
                | x => SEnv.insert (primMap, bindName, x))
            SEnv.empty
            Primitives.allPrimitives
*)

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
      | P.Char_lt => Op2 (I.Lt, I.BYTE, I.BYTE, I.UINT)
      | P.Int_gt => Op2 (I.Gt, I.SINT, I.SINT, I.UINT)
      | P.Real_gt => FloatOp (Op2 (I.Gt, I.DOUBLE, I.DOUBLE, I.UINT))
      | P.Float_gt => Op2 (I.Gt, I.FLOAT, I.FLOAT, I.UINT)
      | P.Word_gt => Op2 (I.Gt, I.UINT, I.UINT, I.UINT)
      | P.Byte_gt => Op2 (I.Gt, I.BYTE, I.BYTE, I.UINT)
      | P.Char_gt => Op2 (I.Gt, I.BYTE, I.BYTE, I.UINT)
      | P.Int_lteq => Op2 (I.Lteq, I.SINT, I.SINT, I.UINT)
      | P.Real_lteq => FloatOp (Op2 (I.Lteq, I.DOUBLE, I.DOUBLE, I.UINT))
      | P.Float_lteq => Op2 (I.Lteq, I.FLOAT, I.FLOAT, I.UINT)
      | P.Word_lteq => Op2 (I.Lteq, I.UINT, I.UINT, I.UINT)
      | P.Byte_lteq => Op2 (I.Lteq, I.BYTE, I.BYTE, I.UINT)
      | P.Char_lteq => Op2 (I.Lteq, I.BYTE, I.BYTE, I.UINT)
      | P.Int_gteq => Op2 (I.Gteq, I.SINT, I.SINT, I.UINT)
      | P.Real_gteq => FloatOp (Op2 (I.Gteq, I.DOUBLE, I.DOUBLE, I.UINT))
      | P.Float_gteq => Op2 (I.Gteq, I.FLOAT, I.FLOAT, I.UINT)
      | P.Word_gteq => Op2 (I.Gteq, I.UINT, I.UINT, I.UINT)
      | P.Byte_gteq => Op2 (I.Gteq, I.BYTE, I.BYTE, I.UINT)
      | P.Char_gteq => Op2 (I.Gteq, I.BYTE, I.BYTE, I.UINT)
      | P.Byte_toIntX => Op1 (I.SignExt, I.BYTE, I.SINT)
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
      | P.Char_ord => Op1 (I.ZeroExt, I.BYTE, I.SINT)
      | P.Char_chr_unsafe => Op1 (I.Cast, I.SINT, I.BYTE)
      | P.Array_length => Special primArrayLength

      (* these are not used currently *)
      | P.ObjectEqual => raise Control.Bug "ObjectEqual"
      | P.PointerEqual => raise Control.Bug "PointerEqual"
      | P.Byte_equal => raise Control.Bug "Byte_equal"
      | P.Char_equal => raise Control.Bug "Char_equal"
      | P.Int_equal => raise Control.Bug "Int_equal"
      | P.Word_equal => raise Control.Bug "Word_equal"

      (* these are implemented as runtime functions currently *)
      | P.String_array => Ext{name="prim_String_allocateMutable", alloc=true}
      | P.String_vector => Ext{name="prim_String_allocateImmutable", alloc=true}
      | P.String_copy_unsafe => Ext{name="prim_String_copy", alloc=false}
      | P.String_equal => Special (useCmp StrCmp I.MonoEqual)
      | P.String_gt => Special (useCmp StrCmp I.Gt)
      | P.String_gteq => Special (useCmp StrCmp I.Gteq)
      | P.String_lt => Special (useCmp StrCmp I.Lt)
      | P.String_lteq => Special (useCmp StrCmp I.Lteq)
      | P.String_size => Ext{name="prim_String_size", alloc=false}
      | P.String_sub_unsafe => Ext{name="prim_String_sub", alloc=false}
      | P.String_update_unsafe => Ext{name="prim_String_update", alloc=false}
      | P.IntInf_abs => Ext{name="prim_IntInf_abs", alloc=true}
      | P.IntInf_add => Ext{name="prim_IntInf_add", alloc=true}
      | P.IntInf_div => Ext{name="prim_IntInf_div", alloc=true}
      | P.IntInf_equal => Special (useCmp IntInfCmp I.MonoEqual)
      | P.IntInf_gt => Special (useCmp IntInfCmp I.Gt)
      | P.IntInf_gteq => Special (useCmp IntInfCmp I.Gteq)
      | P.IntInf_lt => Special (useCmp IntInfCmp I.Lt)
      | P.IntInf_lteq => Special (useCmp IntInfCmp I.Lteq)
      | P.IntInf_mod => Ext{name="prim_IntInf_mod", alloc=true}
      | P.IntInf_mul => Ext{name="prim_IntInf_mul", alloc=true}
      | P.IntInf_neg => Ext{name="prim_IntInf_neg", alloc=true}
      | P.IntInf_sub => Ext{name="prim_IntInf_sub", alloc=true}
      | P.Ptr_deref_int => Ext{name="prim_UnmanagedMemory_subInt", alloc=false}
      | P.Ptr_deref_real => Ext{name="prim_UnmanagedMemory_subReal",alloc=false}
      | P.Ptr_deref_float => raise Control.Bug "Ptr_deref_float"
      | P.Ptr_deref_word => Ext{name="prim_UnmanagedMemory_subWord",alloc=false}
      | P.Ptr_deref_char => Ext{name="prim_UnmanagedMemory_subByte", alloc=false}
      | P.Ptr_deref_byte => Ext{name="prim_UnmanagedMemory_subByte", alloc=false}

      (* old primitive; never appear for native backend *)
      | P.RuntimePrim _ => raise Control.Bug "RuntimePrim"

  fun transform {prim,
                 dstVarList, dstTyList, argList, argTyList,
                 instSizeList, instTagList,
                 loc} =
      let
        fun primInsn x =
            case (x, dstVarList, argList) of
              (Ext {name, alloc}, _, _) =>
              let
                val isPure =
                    (case BuiltinPrimitiveUtils.raisesException prim of
                      nil => true | _ => false)
                    andalso BuiltinPrimitiveUtils.hasEffect prim
              in
                CallExt {dstVarList = dstVarList,
                         entry = name,
                         isPure = isPure,
                         allocMLValue = alloc,
                         argList = argList,
                         calleeTy = (argTyList, dstTyList),
                         loc = loc}
              end
            | (FloatOp x, dsts, args) =>
              primInsn
                (if !Control.enableUnboxedFloat then x
                 else Ext {name = BuiltinPrimitiveUtils.oldPrimitiveName prim,
                           alloc = true})
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
