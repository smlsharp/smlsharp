(**
 * Translation of primitive into typed lambda
 *
 * @copyright (c) 2013, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure PrimitiveTypedLambda : sig

  val toPrimTy : Types.ty -> TypedLambda.primTy

  val compile
      : {primitive : BuiltinPrimitive.primitive,
         primTy : TypedLambda.primTy,
         instTyList : Types.ty list,
         argExpList : EmitTypedLambda.exp list,
         resultTy : Types.ty,
         loc : TypedLambda.loc}
        -> EmitTypedLambda.exp

end =
struct

  structure L = TypedLambda
  structure T = Types
  structure P = BuiltinPrimitive
  structure B = BuiltinTypes
  structure C = ConstantTerm

  structure E = EmitTypedLambda

  (* transform varInfo *)
  fun toRC {longsymbol, id, ty} =
      {path=Symbol.longsymbolToLongid longsymbol,
       id = id,
       ty = ty}
  (* transform exVarInfo *)
  fun toRCEx {longsymbol, ty} =
      {path=Symbol.longsymbolToLongid longsymbol,
       ty = ty}

  (* FIXME : we assume 32 bit machine *)
  val maxSize = 0x03ffffff
  val maxArraySize = (maxSize + 1) div 8 - 1
  val minInt = ~0x80000000
  val maxInt = 0x7fffffff
  val minInt64 = ~0x8000000000000000 : Int64.int
  val maxInt64 = 0x7fffffffffffffff : Int64.int
  val maxChar = 255
  val wordBits = 32
  val word64Bits = 64
  val byteBits = 8

  fun primFunTy boundtvars ty =
      case TypesBasics.derefTy ty of
        T.FUNMty ([argTy], retTy) =>
        (case TypesBasics.derefTy argTy of
           T.RECORDty tys =>
           {boundtvars = boundtvars,
            argTyList = RecordLabel.Map.listItems tys,
            resultTy = retTy}
         | argTy =>
           {boundtvars = boundtvars,
            argTyList = [argTy],
            resultTy = retTy})
      | _ => raise Bug.Bug "decomposeFunTy"

  fun toPrimTy ty =
      case TypesBasics.derefTy ty of
        T.POLYty {boundtvars, body} => primFunTy boundtvars body
      | ty => primFunTy BoundTypeVarID.Map.empty ty

  fun elabPrim (primitive, primTy, instTyList, retTy, argExpList, loc) =
      case (primitive, argExpList, instTyList) of
        (P.Cast P.TypeCast, [arg], _) =>
        E.Cast (arg, retTy)
      | (P.Cast P.TypeCast, _, _) =>
        raise Bug.Bug "compilePrim: Cast"

      | (P.Cast P.RuntimeTyCast, [arg], _) =>
        E.RuntimeTyCast (arg, retTy)
      | (P.Cast P.RuntimeTyCast, _, _) =>
        raise Bug.Bug "compilePrim: RuntimeTyCast"

      | (P.Cast P.BitCast, [arg], _) =>
        E.BitCast (arg, retTy)
      | (P.Cast P.BitCast, _, _) =>
        raise Bug.Bug "compilePrim: BitCast"

      | (P.Exn_Name, [arg], []) =>
        E.extractExnTagName (E.extractExnTag arg)
      | (P.Exn_Name, _, _) =>
        raise Bug.Bug "compilePrim: Exn_Name"

      | (P.Exn_Message, [arg], []) =>
        E.Exn_Message arg
      | (P.Exn_Message, _, _) =>
        raise Bug.Bug "compilePrim: Exn_Message"

      | (P.Equal, [arg1, arg2], [_]) =>
        E.PrimApply ({primitive = P.R (P.M P.RuntimePolyEqual),
                      ty = primTy},
                     instTyList, retTy, [arg1, arg2])
      | (P.Equal, _, _) =>
        raise Bug.Bug "compilePrim: Equal"

      | (P.NotEqual, [arg1, arg2], [_]) =>
        E.If (E.PrimApply ({primitive = P.R (P.M P.RuntimePolyEqual),
                            ty = primTy},
                           instTyList, retTy, [arg1, arg2]),
              E.False, E.True)
      | (P.NotEqual, _, _) =>
        raise Bug.Bug "compilePrim: NotEqual"

      | (P.Real_notEqual, [arg1, arg2], []) =>
        E.If (E.Real_equal (arg1, arg2), E.False, E.True)
      | (P.Real_notEqual, _, _) =>
        raise Bug.Bug "compilePrim: Real_notEqual"

      | (P.Float_notEqual, [arg1, arg2], []) =>
        E.If (E.Float_equal (arg1, arg2), E.False, E.True)
      | (P.Float_notEqual, _, _) =>
        raise Bug.Bug "compilePrim: Float_notEqual"

      | (P.Array_alloc, [size], [_]) =>
        E.If (E.Andalso [E.Int32_gteq (size, E.Int 0),
                         E.Int32_lteq (size, E.Int maxArraySize)],
              E.PrimApply ({primitive = P.R P.Array_alloc_unsafe,
                            ty = primTy},
                           instTyList, retTy, [size]),
              E.Raise (toRCEx B.SizeExExn, retTy))
      | (P.Array_alloc, _, _) =>
        raise Bug.Bug "compilePrim: Array_alloc"

      | (P.String_alloc, [size], []) =>
        E.If (E.Andalso [E.Int32_gteq (size, E.Int 0),
                         E.Int32_lteq (size, E.Int (maxSize - 1))],
              E.String_alloc_unsafe size,
              E.Raise (toRCEx B.SizeExExn, retTy))
      | (P.String_alloc, _, _) =>
        raise Bug.Bug "compilePrim: String_alloc"

      | (P.Array_length, [ary], [ty]) =>
        E.Array_length (ty, ary)
      | (P.Array_length, _, _) =>
        raise Bug.Bug "compilePrim: Array_length"

      | (P.String_size, [ary], []) =>
        E.String_size ary
      | (P.String_size, _, _) =>
        raise Bug.Bug "compilePrim: String_size"

      | (P.Array_copy, [di, dst, src], [ty]) =>
        let
          val slen = EmitTypedLambda.newId ()
          val dlen = EmitTypedLambda.newId ()
        in
          (*
           * array bound check must be overflow-conscious.
           * Evaluation of the in-bounds condition
           *   di >= 0 and dlen >= di + slen
           * may cause overflow at "+" operation.
           * Due to this, out-of-bounds memory access would pass
           * (See 292_arrayCopy).
           * To prevent this, we rewrite the above condition to the following
           * overflow-conscious form:
           *   di >= 0 and dlen >= di and dlen - di >= slen
           *)
          E.Let ([(slen, E.Array_length (ty, src)),
                  (dlen, E.Array_length (ty, dst))],
                 E.If (E.Andalso
                         [E.Int32_gteq (di, E.Int 0),
                          E.Int32_gteq (E.Var dlen, di),
                          E.Int32_gteq (E.Int32_sub_unsafe (E.Var dlen, di),
                                        E.Var slen)],
                       E.Array_copy_unsafe
                         (ty, src, E.Int 0, dst, di, E.Var slen),
                       E.Raise (toRCEx B.SubscriptExExn, retTy)))
        end
      | (P.Array_copy, _, _) =>
        raise Bug.Bug "compilePrim: Array_copy"

      | (P.Array_sub, [ary, index], [ty]) =>
        E.If (E.Andalso [E.Int32_gteq (index, E.Int 0),
                         E.Int32_lt (index, E.Array_length (ty, ary))],
              E.PrimApply ({primitive = P.Array_sub_unsafe,
                            ty = primTy},
                           instTyList, retTy, [ary, index]),
              E.Raise (toRCEx B.SubscriptExExn, retTy))
      | (P.Array_sub, _, _) =>
        raise Bug.Bug "compilePrim: Array_sub"

      | (P.Array_update, [ary, index, elem], [ty]) =>
        E.If (E.Andalso [E.Int32_gteq (index, E.Int 0),
                         E.Int32_lt (index, E.Array_length (ty, ary))],
              E.PrimApply ({primitive = P.Array_update_unsafe,
                            ty = primTy},
                           instTyList, retTy, [ary, index, elem]),
              E.Raise (toRCEx B.SubscriptExExn, retTy))
      | (P.Array_update, _, _) =>
        raise Bug.Bug "compilePrim: Array_update"

      | (P.String_sub, [ary, index], []) =>
        E.If (E.Andalso [E.Int32_gteq (index, E.Int 0),
                         E.Int32_lt (index, E.String_size ary)],
              E.String_sub_unsafe (ary, index),
              E.Raise (toRCEx B.SubscriptExExn, retTy))
      | (P.String_sub, _, _) =>
        raise Bug.Bug "compilePrim: String_sub"

      | (P.Vector_length, [vec], [ty]) =>
        elabPrim (P.Array_length, primTy, instTyList, retTy,
                  [E.Cast (vec, E.arrayTy ty)], loc)
      | (P.Vector_length, _, _) =>
        raise Bug.Bug "compilePrim: Vector_length"

      | (P.Vector_sub, [vec, index], [ty]) =>
        elabPrim (P.Array_sub, primTy, instTyList, retTy,
                  [E.Cast (vec, E.arrayTy ty), index], loc)
      | (P.Vector_sub, _, _) =>
        raise Bug.Bug "compilePrim: Vector_sub"

      | (P.Ref_deref, [refExp], [elemTy]) =>
        E.Ref_deref (elemTy, refExp)
      | (P.Ref_deref, _, _) =>
        raise Bug.Bug "compilePrim: Ref_deref"

      | (P.Ref_assign, [refExp, argExp], [elemTy]) =>
        E.Ref_assign (elemTy, refExp, argExp)
      | (P.Ref_assign, _, _) =>
        raise Bug.Bug "compilePrim: Ref_assign"

      | (P.Word8_div, [arg1, arg2], []) =>
        E.Switch (arg2,
                  [(C.WORD8 0w0, E.Raise (toRCEx B.DivExExn, retTy))],
                  E.PrimApply ({primitive = P.R (P.M P.Word8_div_unsafe),
                                ty = primTy},
                               instTyList, retTy, [arg1, arg2]))
      | (P.Word8_div, _, _) =>
        raise Bug.Bug "compilePrim: Word8_div"

      | (P.Word8_mod, [arg1, arg2], []) =>
        E.Switch (arg2,
                  [(C.WORD8 0w0, E.Raise (toRCEx B.DivExExn, retTy))],
                  E.PrimApply ({primitive = P.R (P.M P.Word8_mod_unsafe),
                                ty = primTy},
                               instTyList, retTy, [arg1, arg2]))
      | (P.Word8_mod, _, _) =>
        raise Bug.Bug "compilePrim: Word8_mod"

      | (P.Word32_div, [arg1, arg2], []) =>
        E.Switch (arg2,
                  [(C.WORD32 0w0, E.Raise (toRCEx B.DivExExn, retTy))],
                  E.PrimApply ({primitive = P.R (P.M P.Word32_div_unsafe),
                                ty = primTy},
                               instTyList, retTy, [arg1, arg2]))
      | (P.Word32_div, _, _) =>
        raise Bug.Bug "compilePrim: Word32_div"

      | (P.Word32_mod, [arg1, arg2], []) =>
        E.Switch (arg2,
                  [(C.WORD32 0w0, E.Raise (toRCEx B.DivExExn, retTy))],
                  E.PrimApply ({primitive = P.R (P.M P.Word32_mod_unsafe),
                                ty = primTy},
                               instTyList, retTy, [arg1, arg2]))
      | (P.Word32_mod, _, _) =>
        raise Bug.Bug "compilePrim: Word32_mod"

      | (P.Word64_div, [arg1, arg2], []) =>
        E.Switch (arg2,
                  [(C.WORD64 0w0, E.Raise (toRCEx B.DivExExn, retTy))],
                  E.PrimApply ({primitive = P.R (P.M P.Word64_div_unsafe),
                                ty = primTy},
                               instTyList, retTy, [arg1, arg2]))
      | (P.Word64_div, _, _) =>
        raise Bug.Bug "compilePrim: Word64_div"

      | (P.Word64_mod, [arg1, arg2], []) =>
        E.Switch (arg2,
                  [(C.WORD64 0w0, E.Raise (toRCEx B.DivExExn, retTy))],
                  E.PrimApply ({primitive = P.R (P.M P.Word64_mod_unsafe),
                                ty = primTy},
                               instTyList, retTy, [arg1, arg2]))
      | (P.Word64_mod, _, _) =>
        raise Bug.Bug "compilePrim: Word64_mod"

      | (P.Int32_quot, [arg1, arg2], []) =>
        E.Switch
          (arg2,
           [(C.INT32 0, E.Raise (toRCEx B.DivExExn, retTy)),
            (C.INT32 ~1,
             E.Switch
               (arg1,
                [(C.INT32 minInt, E.Raise (toRCEx B.OverflowExExn, retTy))],
                E.Int32_sub_unsafe (E.Int 0, arg1)))],
           E.Int32_quot_unsafe (arg1, arg2))
      | (P.Int32_quot, _, _) =>
        raise Bug.Bug "compilePrim: Int32_quot"

      | (P.Int32_rem, [arg1, arg2], []) =>
        E.Switch (arg2,
                  [(C.INT32 0, E.Raise (toRCEx B.DivExExn, retTy)),
                   (C.INT32 ~1, E.Int 0)],
                  E.Int32_rem_unsafe (arg1, arg2))
      | (P.Int32_rem, _, _) =>
        raise Bug.Bug "compilePrim: Int32_rem"

      | (P.Int32_div, [arg1, arg2], []) =>
        E.Switch
          (arg2,
           [(C.INT32 0, E.Raise (toRCEx B.DivExExn, retTy)),
            (C.INT32 ~1,
             E.Switch (arg1,
                       [(C.INT32 minInt,
                         E.Raise (toRCEx B.OverflowExExn, retTy))],
                       E.Int32_sub_unsafe (E.Int 0, arg1)))],
           (*
            * rounding is performed towards negative infinity.
            * q = x quot y
            * r = x rem y
            * s = x xor y
            * x div y = q - ((s < 0 && r != 0) ? 1 : 0)
            *         = q + ((s >= 0 && r == 0) ? 0 : -1)
            *         = q + (((s >= 0) | (r == 0)) - 1
            *)
           let
             val q = EmitTypedLambda.newId ()
             val r = EmitTypedLambda.newId ()
             val s = EmitTypedLambda.newId ()
           in
             E.Let
               ([(q, E.Int32_quot_unsafe (arg1, arg2)),
                 (r, E.Int32_rem_unsafe (arg1, arg2)),
                 (s, E.Word32_fromInt32
                       (E.Word32_xorb (E.Word32_fromInt32 arg1,
                                       E.Word32_fromInt32 arg2)))],
                let
                  val f1 = E.Word32_fromInt32 (E.Int32_gteq (E.Var s, E.Int 0))
                  val f2 = E.Word32_fromInt32 (E.Int32_eq (E.Var r, E.Int 0))
                  val m = E.Word32_sub (E.Word32_orb (f1, f2), E.Word 1)
                in
                  E.Int32_add_unsafe (E.Var q, E.Word32_toInt32X m)
                end)
           end)
      | (P.Int32_div, _, _) =>
        raise Bug.Bug "compilePrim: Int32_div"

      | (P.Int32_mod, [arg1, arg2], []) =>
        E.Switch
          (arg2,
           [(C.INT32 0, E.Raise (toRCEx B.DivExExn, retTy)),
            (C.INT32 ~1, E.Int 0)],
           (*
            * rounding is performed towards negative infinity.
            * r = x rem y
            * s = x xor y
            * x mod y = r + ((s < 0 && r != 0) ? y : 0)
            *         = r + ((s >= 0 || r == 0) ? 0 : y)
            *         = r + ((((s >= 0) | (r == 0)) - 1) & y)
            *)
           let
             val r = EmitTypedLambda.newId ()
             val s = EmitTypedLambda.newId ()
           in
             E.Let
               ([(r, E.Int32_rem_unsafe (arg1, arg2)),
                 (s, E.Word32_fromInt32
                       (E.Word32_xorb (E.Word32_fromInt32 arg1,
                                       E.Word32_fromInt32 arg2)))],
                let
                  val f1 = E.Word32_fromInt32 (E.Int32_gteq (E.Var s, E.Int 0))
                  val f2 = E.Word32_fromInt32 (E.Int32_eq (E.Var r, E.Int 0))
                  val m = E.Word32_sub (E.Word32_orb (f1, f2), E.Word 1)
                in
                  E.Int32_add_unsafe
                    (E.Var r,
                     E.Word32_toInt32X
                       (E.Word32_andb (E.Word32_fromInt32 arg2, m)))
                end)
           end)
      | (P.Int32_mod, _, _) =>
        raise Bug.Bug "compilePrim: Int32_mod"

      | (P.Int32_abs, [arg], []) =>
        E.Switch (arg,
                  [(C.INT32 minInt, E.Raise (toRCEx B.OverflowExExn, retTy))],
                  E.If (E.Int32_gteq (arg, E.Int 0),
                        arg,
                        E.Int32_sub_unsafe (E.Int 0, arg)))
      | (P.Int32_abs, _, _) =>
        raise Bug.Bug "compilePrim: Int32_abs"

      | (P.Int32_neg, [arg], []) =>
        E.Switch (arg,
                  [(C.INT32 minInt, E.Raise (toRCEx B.OverflowExExn, retTy))],
                  E.Int32_sub_unsafe (E.Int 0, arg))
      | (P.Int32_neg, _, _) =>
        raise Bug.Bug "compilePrim: Int32_neg"

      | (P.Int64_quot, [arg1, arg2], []) =>
        E.Switch
          (arg2,
           [(C.INT64 0, E.Raise (toRCEx B.DivExExn, retTy)),
            (C.INT64 ~1,
             E.Switch (arg1,
                       [(C.INT64 minInt64, 
                         E.Raise (toRCEx B.OverflowExExn, retTy))],
                       E.Int64_sub_unsafe (E.Int64 0, arg1)))],
           E.Int64_quot_unsafe (arg1, arg2))
      | (P.Int64_quot, _, _) =>
        raise Bug.Bug "compilePrim: Int64_quot"

      | (P.Int64_rem, [arg1, arg2], []) =>
        E.Switch (arg2,
                  [(C.INT64 0, E.Raise (toRCEx B.DivExExn, retTy)),
                   (C.INT64 ~1, E.Int64 0)],
                  E.Int64_rem_unsafe (arg1, arg2))
      | (P.Int64_rem, _, _) =>
        raise Bug.Bug "compilePrim: Int64_rem"

      | (P.Int64_div, [arg1, arg2], []) =>
        E.Switch
          (arg2,
           [(C.INT64 0, E.Raise (toRCEx B.DivExExn, retTy)),
            (C.INT64 ~1,
             E.Switch (arg1,
                       [(C.INT64 minInt64,
                         E.Raise (toRCEx B.OverflowExExn, retTy))],
                       E.Int64_sub_unsafe (E.Int64 0, arg1)))],
           (*
            * rounding is performed towards negative infinity.
            * q = x quot y
            * r = x rem y
            * s = x xor y
            * x div y = q - ((s < 0 && r != 0) ? 1 : 0)
            *         = q + ((s >= 0 && r == 0) ? 0 : -1)
            *         = q + (((s >= 0) | (r == 0)) - 1
            *)
           let
             val q = EmitTypedLambda.newId ()
             val r = EmitTypedLambda.newId ()
             val s = EmitTypedLambda.newId ()
           in
             E.Let
               ([(q, E.Int64_quot_unsafe (arg1, arg2)),
                 (r, E.Int64_rem_unsafe (arg1, arg2)),
                 (s, E.Word64_fromInt64 
                       (E.Word64_xorb (E.Word64_fromInt64 arg1,
                                       E.Word64_fromInt64 arg2)))],
                let
                  val f1 = E.Word64_fromInt32
                             (E.Int64_gteq (E.Var s, E.Int64 0))
                  val f2 = E.Word64_fromInt32
                             (E.Int64_eq (E.Var r, E.Int64 0))
                  val m = E.Word64_sub (E.Word64_orb (f1, f2), E.Word64 1)
                in
                  E.Int64_add_unsafe (E.Var q, E.Word64_toInt64X m)
                end)
           end)
      | (P.Int64_div, _, _) =>
        raise Bug.Bug "compilePrim: Int64_div"

      | (P.Int64_mod, [arg1, arg2], []) =>
        E.Switch
          (arg2,
           [(C.INT64 0, E.Raise (toRCEx B.DivExExn, retTy)),
            (C.INT64 ~1, E.Int64 0)],
           (*
            * rounding is performed towards negative infinity.
            * r = x rem y
            * s = x xor y
            * x mod y = r + ((s < 0 && r != 0) ? y : 0)
            *         = r + ((s >= 0 || r == 0) ? 0 : y)
            *         = r + ((((s >= 0) | (r == 0)) - 1) & y)
            *)
           let
             val r = EmitTypedLambda.newId ()
             val s = EmitTypedLambda.newId ()
           in
             E.Let
               ([(r, E.Int64_rem_unsafe (arg1, arg2)),
                 (s, E.Word64_fromInt64 
                       (E.Word64_xorb (E.Word64_fromInt64 arg1,
                                       E.Word64_fromInt64 arg2)))],
                let
                  val f1 = E.Word64_fromInt32
                             (E.Int64_gteq (E.Var s, E.Int64 0))
                  val f2 = E.Word64_fromInt32
                             (E.Int64_eq (E.Var r, E.Int64 0))
                  val m = E.Word64_sub (E.Word64_orb (f1, f2), E.Word64 1)
                in
                  E.Int64_add_unsafe
                    (E.Var r,
                     E.Word64_toInt64X
                       (E.Word64_andb (E.Word64_fromInt64 arg2, m)))
                end)
           end)
      | (P.Int64_mod, _, _) =>
        raise Bug.Bug "compilePrim: Int64_mod"

      | (P.Int64_abs, [arg], []) =>
        E.Switch (arg,
                  [(C.INT64 minInt64, E.Raise (toRCEx B.OverflowExExn, retTy))],
                  E.If (E.Int64_gteq (arg, E.Int64 0),
                        arg,
                        E.Int64_sub_unsafe (E.Int64 0, arg)))
      | (P.Int64_abs, _, _) =>
        raise Bug.Bug "compilePrim: Int64_abs"

      | (P.Int64_neg, [arg], []) =>
        E.Switch (arg,
                  [(C.INT64 minInt64, E.Raise (toRCEx B.OverflowExExn, retTy))],
                  E.Int64_sub_unsafe (E.Int64 0, arg))
      | (P.Int64_neg, _, _) =>
        raise Bug.Bug "compilePrim: Int64_neg"

      | (P.Int64_toInt32, [arg], []) =>
        E.If (E.Andalso [E.Int64_gteq (arg, E.Int64 (Int64.fromInt minInt)),
                         E.Int64_lteq (arg, E.Int64 (Int64.fromInt maxInt))],
              E.Word32_toInt32X (E.Word64_toWord32 (E.Word64_fromInt64 arg)),
              E.Raise (toRCEx B.OverflowExExn, retTy))
      | (P.Int64_toInt32, _, _) =>
        raise Bug.Bug "compilePrim: Int64_toInt32"

      | (P.Int64_fromInt32, [arg], []) =>
        E.Word64_fromInt64 (E.Word32_toWord64X (E.Word32_fromInt32 arg))
      | (P.Int64_fromInt32, _, _) =>
        raise Bug.Bug "compilePrim: Int64_fromInt32"

      | (P.Word32_neg, [arg], []) =>
        E.Word32_sub (E.Word 0, arg)
      | (P.Word32_neg, _, _) =>
        raise Bug.Bug "compilePrim: Word32_neg"

      | (P.Word64_neg, [arg], []) =>
        E.Word64_sub (E.Word64 0, arg)
      | (P.Word64_neg, _, _) =>
        raise Bug.Bug "compilePrim: Word64_neg"

      | (P.Real_neg, [arg], []) =>
        E.Real_sub (E.Real 0, arg)
      | (P.Real_neg, _, _) =>
        raise Bug.Bug "compilePrim: Real_neg"

      | (P.Float_neg, [arg], []) =>
        E.Float_sub (E.Float 0, arg)
      | (P.Float_neg, _, _) =>
        raise Bug.Bug "compilePrim: Float_neg"

      | (P.Word8_neg, [arg], []) =>
        E.Word8_sub (E.Word8 0, arg)
      | (P.Word8_neg, _, _) =>
        raise Bug.Bug "compilePrim: Word8_neg"

      | (P.Word32_notb, [arg], []) =>
        E.Word32_xorb (E.Word ~1, arg)
      | (P.Word32_notb, _, _) =>
        raise Bug.Bug "compilePrim: Word32_notb"

      | (P.Word64_notb, [arg], []) =>
        E.Word64_xorb (E.Word64 ~1, arg)
      | (P.Word64_notb, _, _) =>
        raise Bug.Bug "compilePrim: Word64_notb"

      | (P.Word8_notb, [arg], []) =>
        E.Word8_xorb (E.Word8 ~1, arg)
      | (P.Word8_notb, _, _) =>
        raise Bug.Bug "compilePrim: Word8_notb"

      | (P.Char_chr, [arg], []) =>
        E.If (E.Andalso [E.Int32_gteq (arg, E.Int 0),
                         E.Int32_lteq (arg, E.Int maxChar)],
              E.Cast (E.Word32_toWord8 (E.Word32_fromInt32 arg), B.charTy),
              E.Raise (toRCEx B.ChrExExn, retTy))
      | (P.Char_chr, _, _) =>
        raise Bug.Bug "compilePrim: Char_chr"

      | (P.Char_gt, [arg1, arg2], []) =>
        E.Word8_gt (E.Cast (arg1, B.word8Ty), E.Cast (arg2, B.word8Ty))
      | (P.Char_gt, _, _) =>
        raise Bug.Bug "compilePrim: Char_gt"

      | (P.Char_gteq, [arg1, arg2], []) =>
        E.Word8_gteq (E.Cast (arg1, B.word8Ty), E.Cast (arg2, B.word8Ty))
      | (P.Char_gteq, _, _) =>
        raise Bug.Bug "compilePrim: Char_gteq"

      | (P.Char_lt, [arg1, arg2], []) =>
        E.Word8_lt (E.Cast (arg1, B.word8Ty), E.Cast (arg2, B.word8Ty))
      | (P.Char_lt, _, _) =>
        raise Bug.Bug "compilePrim: Char_lt"

      | (P.Char_lteq, [arg1, arg2], []) =>
        E.Word8_lteq (E.Cast (arg1, B.word8Ty), E.Cast (arg2, B.word8Ty))
      | (P.Char_lteq, _, _) =>
        raise Bug.Bug "compilePrim: Char_lteq"

      | (P.Char_ord, [arg], []) =>
        E.Word32_toInt32X (E.Word8_toWord32 (E.Cast (arg, B.word8Ty)))
      | (P.Char_ord, _, _) =>
        raise Bug.Bug "compilePrim: Char_ord"

      | (P.Float_trunc, [arg], []) =>
        E.If (E.Float_isNan arg,
              E.Raise (toRCEx B.DomainExExn, retTy),
              E.If (E.Andalso [E.Float_gteq (arg, E.Float minInt),
                               E.Float_lteq (arg, E.Float maxInt)],
                    E.PrimApply ({primitive = P.R (P.M P.Float_toInt32_unsafe),
                                  ty = primTy},
                                 instTyList, retTy, [arg]),
                    E.Raise (toRCEx B.OverflowExExn, retTy)))
      | (P.Float_trunc, _, _) =>
        raise Bug.Bug "compilePrim: Float_trunc"

      | (P.Real_trunc, [arg], []) =>
        E.If (E.Real_isNan arg,
              E.Raise (toRCEx B.DomainExExn, retTy),
              E.If (E.Andalso [E.Real_gteq (arg, E.Real minInt),
                               E.Real_lteq (arg, E.Real maxInt)],
                    E.PrimApply ({primitive = P.R (P.M P.Real_toInt32_unsafe),
                                  ty = primTy},
                                 instTyList, retTy, [arg]),
                    E.Raise (toRCEx B.OverflowExExn, retTy)))
      | (P.Real_trunc, _, _) =>
        raise Bug.Bug "compilePrim: Real_trunc"

      | (P.Int32_add, _, _) =>
        raise Bug.Bug "Int32_add: not implemented"

      | (P.Int32_mul, _, _) =>
        raise Bug.Bug "Int32_mul: not implemented"

      | (P.Int32_sub, _, _) =>
        raise Bug.Bug "Int32_sub: not implemented"

      | (P.Int64_add, _, _) =>
        raise Bug.Bug "Int64_add: not implemented"

      | (P.Int64_mul, _, _) =>
        raise Bug.Bug "Int64_mul: not implemented"

      | (P.Int64_sub, _, _) =>
        raise Bug.Bug "Int64_sub: not implemented"

      | (P.Word8_fromInt32, [arg], []) =>
        E.Word32_toWord8 (E.Word32_fromInt32 arg)
      | (P.Word8_fromInt32, _, _) =>
        raise Bug.Bug "compilePrim: Word8_fromInt32"

      | (P.Word8_toInt32, [arg], []) =>
        E.Word32_toInt32X (E.Word8_toWord32 arg)
      | (P.Word8_toInt32, _, _) =>
        raise Bug.Bug "compilePrim: Word8_toInt32"

      | (P.Word8_toInt32X, [arg], []) =>
        E.Word32_fromInt32 (E.Word8_toWord32X arg)
      | (P.Word8_toInt32X, _, _) =>
        raise Bug.Bug "compilePrim: Word8_toInt32X"

      | (P.Word32_toInt32, [arg], []) =>
        let
          val v = EmitTypedLambda.newId ()
        in
          E.Let ([(v, E.Word32_toInt32X arg)],
                 E.If (E.Int32_lt (E.Var v, E.Int 0),
                       E.Raise (toRCEx B.OverflowExExn, retTy),
                       E.Var v))
        end
      | (P.Word32_toInt32, _, _) =>
        raise Bug.Bug "compilePrim: Word32_toInt32"

      | (P.Word64_toInt32, [arg], []) =>
        E.If (E.Word64_lteq (arg, E.Word64 (Int64.fromInt maxInt)),
              E.Word32_toInt32X (E.Word64_toWord32 arg),
              E.Raise (toRCEx B.OverflowExExn, retTy))
      | (P.Word64_toInt32, _, _) => 
        raise Bug.Bug "compilePrim: Word64_toInt32"

      | (P.Word64_toInt32X, [arg], []) =>
        let
          val n = E.Word64_toInt64X arg
        in
          E.If (E.Andalso [E.Int64_gteq (n, E.Int64 (Int64.fromInt minInt)),
                           E.Int64_lteq (n, E.Int64 (Int64.fromInt maxInt))],
                E.Word32_toInt32X (E.Word64_toWord32 arg),
                E.Raise (toRCEx B.OverflowExExn, retTy))
        end
      | (P.Word64_toInt32X, _, _) => 
        raise Bug.Bug "compilePrim: Word64_toInt32X"

      | (P.Word64_fromInt32, [arg], []) =>
        E.Word64_fromInt32 arg
      | (P.Word64_fromInt32, _, _) => 
        raise Bug.Bug "compilePrim: Word64_fromInt32"

      | (P.Word32_arshift, [arg1, arg2], []) =>
        E.PrimApply ({primitive = P.R (P.M P.Word32_arshift_unsafe),
                      ty = primTy},
                     instTyList, retTy,
                     [arg1,
                      E.If (E.Word32_lt (arg2, E.Word wordBits), arg2,
                            E.Word (wordBits - 1))])
      | (P.Word32_arshift, _, _) =>
        raise Bug.Bug "compilePrim: Word32_arshift"

      | (P.Word64_arshift, [arg1, arg2], []) =>
        E.Word64_arshift_unsafe (arg1, 
                                 E.If (E.Word32_lt (arg2, E.Word word64Bits),
                                 E.Word32_toWord64 arg2,
                                 E.Word64_fromInt32 (E.Int (word64Bits - 1))))
      | (P.Word64_arshift, _, _) =>
        raise Bug.Bug "compilePrim: Word64_arshift"

      | (P.Word8_arshift, [arg1, arg2], []) =>
        E.Word8_arshift_unsafe (arg1,
                                E.If (E.Word32_lt (arg2, E.Word byteBits),
                                E.Word32_toWord8 arg2,
                                E.Word8 (byteBits - 1)))
      | (P.Word8_arshift, _, _) =>
        raise Bug.Bug "compilePrim: Word8_arshift"

      | (P.Word32_lshift, [arg1, arg2], []) =>
        E.If (E.Word32_lt (arg2, E.Word wordBits),
              E.PrimApply ({primitive = P.R (P.M P.Word32_lshift_unsafe),
                            ty = primTy},
                           instTyList, retTy, [arg1, arg2]),
              E.Word 0)
      | (P.Word32_lshift, _, _) =>
        raise Bug.Bug "compilePrim: Word32_lshift"

      | (P.Word64_lshift, [arg1, arg2], []) =>
        E.If (E.Word32_lt (arg2, E.Word word64Bits),
              E.Word64_lshift_unsafe (arg1, E.Word32_toWord64 arg2),
              E.Word64 0)
      | (P.Word64_lshift, _, _) =>
        raise Bug.Bug "compilePrim: Word64_lshift"

      | (P.Word8_lshift, [arg1, arg2], []) =>
        E.If (E.Word32_lt (arg2, E.Word byteBits),
              E.Word8_lshift_unsafe (arg1, E.Word32_toWord8 arg2),
              E.Word8 0)
      | (P.Word8_lshift, _, _) =>
        raise Bug.Bug "compilePrim: Word8_lshift"

      | (P.Word32_rshift, [arg1, arg2], []) =>
        E.If (E.Word32_lt (arg2, E.Word wordBits),
              E.PrimApply ({primitive = P.R (P.M P.Word32_rshift_unsafe),
                            ty = primTy},
                           instTyList, retTy, [arg1, arg2]),
              E.Word 0)
      | (P.Word32_rshift, _, _) =>
        raise Bug.Bug "compilePrim: Word32_rshift"

      | (P.Word64_rshift, [arg1, arg2], []) =>
        E.If (E.Word32_lt (arg2, E.Word word64Bits),
              E.Word64_rshift_unsafe (arg1, E.Word32_toWord64 arg2),
              E.Word64 0)
      | (P.Word64_rshift, _, _) =>
        raise Bug.Bug "compilePrim: Word64_rshift"

      | (P.Word8_rshift, [arg1, arg2], []) =>
        E.If (E.Word32_lt (arg2, E.Word byteBits),
              E.Word8_rshift_unsafe (arg1, E.Word32_toWord8 arg2),
              E.Word8 0)
      | (P.Word8_rshift, _, _) =>
        raise Bug.Bug "compilePrim: Word8_rshift"

      | (P.Compose, [arg1, arg2], [ty1, ty2, ty3]) =>
        let
          val v = EmitTypedLambda.newId ()
        in
          E.Fn (v, ty3, E.App (arg1, (E.App (arg2, E.Var v))))
        end
      | (P.Compose, _, _) =>
        raise Bug.Bug "compilePrim: Compose"

      | (P.Ignore, [arg], [ty]) =>
        E.Let ([(EmitTypedLambda.newId (), arg)], E.Unit)
      | (P.Ignore, _, _) =>
        raise Bug.Bug "compilePrim: Ignore"

      | (P.Before, [arg1, arg2], [ty]) =>
        let
          val ret = EmitTypedLambda.newId ()
        in
          E.Let ([(ret, arg1), (EmitTypedLambda.newId (), arg2)], E.Var ret)
        end
      | (P.Before, _, _) =>
        raise Bug.Bug "compilePrim: Before"

      | (P.Dynamic, [arg], [ty]) =>
        E.Cast
          (E.Tuple
             [E.Cast (E.Ref_alloc (ty, arg), B.boxedTy),
              E.Word 0,
              case HeapDump.dump ty of
                NONE => E.Null
              | SOME dump =>
                E.Exp (L.TLDUMP {dump = dump, ty = B.boxedTy, loc = loc},
                       B.boxedTy)],
           retTy)
      | (P.Dynamic, _, _) =>
        raise Bug.Bug "compilePrim: Dynamic"

      | (P.L prim, args, instTyList) =>
        E.PrimApply ({primitive = prim, ty = primTy},
                     instTyList, retTy, args)

  fun compile {primitive, primTy, instTyList, argExpList, resultTy, loc} =
      let
        val binds = map (fn x => (EmitTypedLambda.newId (), x)) argExpList
        val args = map (fn (id, _) => E.Var id) binds
        val exp1 = elabPrim (primitive, primTy, instTyList, resultTy, args, loc)
      in
        E.Let (binds, exp1)
      end

end
