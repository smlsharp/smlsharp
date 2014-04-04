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
  val maxChar = 255
  val wordBits = 32
  val byteBits = 8

  fun primFunTy boundtvars ty =
      case TypesBasics.derefTy ty of
        T.FUNMty ([argTy], retTy) =>
        (case TypesBasics.derefTy argTy of
           T.RECORDty tys =>
           {boundtvars = boundtvars,
            argTyList = LabelEnv.listItems tys,
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

  fun elabPrim (primitive, primTy, instTyList, retTy, argExpList) =
      case (primitive, argExpList, instTyList) of
        (P.Cast, [arg], _) =>
        E.Cast (arg, retTy)
      | (P.Cast, _, _) =>
        raise Bug.Bug "compilePrim: Cast"

      | (P.RuntimeTyCast, [arg], _) =>
        E.RuntimeTyCast (arg, retTy)
      | (P.RuntimeTyCast, _, _) =>
        raise Bug.Bug "compilePrim: RuntimeTyCast"

      | (P.BitCast, [arg], _) =>
        E.BitCast (arg, retTy)
      | (P.BitCast, _, _) =>
        raise Bug.Bug "compilePrim: BitCast"

      | (P.Exn_Name, [arg], []) =>
        E.extractExnTagName (E.extractExnTag arg)
      | (P.Exn_Name, _, _) =>
        raise Bug.Bug "compilePrim: Exn_Name"

      | (P.Exn_Message, [arg], []) =>
        E.Tuple [E.App (E.extractExnMsgFn (E.extractExnTag arg), arg),
                 E.extractExnLoc arg]
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

      | (P.Float_notEqual, [arg1, arg2], [_]) =>
        E.If (E.Float_equal (arg1, arg2), E.False, E.True)
      | (P.Float_notEqual, _, _) =>
        raise Bug.Bug "compilePrim: Float_notEqual"

      | (P.Array_alloc, [size], [_]) =>
        E.If (E.Andalso [E.Int_gteq (size, E.Int 0),
                         E.Int_lteq (size, E.Int maxArraySize)],
              E.PrimApply ({primitive = P.R P.Array_alloc_unsafe,
                            ty = primTy},
                           instTyList, retTy, [size]),
              E.Raise (toRCEx B.SizeExExn, retTy))
      | (P.Array_alloc, _, _) =>
        raise Bug.Bug "compilePrim: Array_alloc"

      | (P.String_alloc, [size], []) =>
        E.If (E.Andalso [E.Int_gteq (size, E.Int 0),
                         E.Int_lteq (size, E.Int (maxSize - 1))],
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
                         [E.Int_gteq (di, E.Int 0),
                          E.Int_gteq (E.Var dlen, di),
                          E.Int_gteq (E.Int_sub_unsafe (E.Var dlen, di),
                                      E.Var slen)],
                       E.Array_copy_unsafe
                         (ty, src, E.Int 0, dst, di, E.Var slen),
                       E.Raise (toRCEx B.SubscriptExExn, retTy)))
        end
      | (P.Array_copy, _, _) =>
        raise Bug.Bug "compilePrim: Array_copy"

      | (P.Array_sub, [ary, index], [ty]) =>
        E.If (E.Andalso [E.Int_gteq (index, E.Int 0),
                         E.Int_lt (index, E.Array_length (ty, ary))],
              E.PrimApply ({primitive = P.Array_sub_unsafe,
                            ty = primTy},
                           instTyList, retTy, [ary, index]),
              E.Raise (toRCEx B.SubscriptExExn, retTy))
      | (P.Array_sub, _, _) =>
        raise Bug.Bug "compilePrim: Array_sub"

      | (P.Array_update, [ary, index, elem], [ty]) =>
        E.If (E.Andalso [E.Int_gteq (index, E.Int 0),
                         E.Int_lt (index, E.Array_length (ty, ary))],
              E.PrimApply ({primitive = P.Array_update_unsafe,
                            ty = primTy},
                           instTyList, retTy, [ary, index, elem]),
              E.Raise (toRCEx B.SubscriptExExn, retTy))
      | (P.Array_update, _, _) =>
        raise Bug.Bug "compilePrim: Array_update"

      | (P.String_sub, [ary, index], []) =>
        E.If (E.Andalso [E.Int_gteq (index, E.Int 0),
                         E.Int_lt (index, E.String_size ary)],
              E.String_sub_unsafe (ary, index),
              E.Raise (toRCEx B.SubscriptExExn, retTy))
      | (P.String_sub, _, _) =>
        raise Bug.Bug "compilePrim: String_sub"

      | (P.Vector_length, [vec], [ty]) =>
        elabPrim (P.Array_length, primTy, instTyList, retTy,
                  [E.Cast (vec, E.arrayTy ty)])
      | (P.Vector_length, _, _) =>
        raise Bug.Bug "compilePrim: Vector_length"

      | (P.Vector_sub, [vec, index], [ty]) =>
        elabPrim (P.Array_sub, primTy, instTyList, retTy,
                  [E.Cast (vec, E.arrayTy ty), index])
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

      | (P.Byte_div, [arg1, arg2], []) =>
        E.Switch (arg2,
                  [(C.BYTE 0w0, E.Raise (toRCEx B.DivExExn, retTy))],
                  E.PrimApply ({primitive = P.R (P.M P.Byte_div_unsafe),
                                ty = primTy},
                               instTyList, retTy, [arg1, arg2]))
      | (P.Byte_div, _, _) =>
        raise Bug.Bug "compilePrim: Byte_div"

      | (P.Byte_mod, [arg1, arg2], []) =>
        E.Switch (arg2,
                  [(C.BYTE 0w0, E.Raise (toRCEx B.DivExExn, retTy))],
                  E.PrimApply ({primitive = P.R (P.M P.Byte_mod_unsafe),
                                ty = primTy},
                               instTyList, retTy, [arg1, arg2]))
      | (P.Byte_mod, _, _) =>
        raise Bug.Bug "compilePrim: Byte_mod"

      | (P.Word_div, [arg1, arg2], []) =>
        E.Switch (arg2,
                  [(C.WORD 0w0, E.Raise (toRCEx B.DivExExn, retTy))],
                  E.PrimApply ({primitive = P.R (P.M P.Word_div_unsafe),
                                ty = primTy},
                               instTyList, retTy, [arg1, arg2]))
      | (P.Word_div, _, _) =>
        raise Bug.Bug "compilePrim: Word_div"

      | (P.Word_mod, [arg1, arg2], []) =>
        E.Switch (arg2,
                  [(C.WORD 0w0, E.Raise (toRCEx B.DivExExn, retTy))],
                  E.PrimApply ({primitive = P.R (P.M P.Word_mod_unsafe),
                                ty = primTy},
                               instTyList, retTy, [arg1, arg2]))
      | (P.Word_mod, _, _) =>
        raise Bug.Bug "compilePrim: Word_mod"

      | (P.Int_quot, [arg1, arg2], []) =>
        E.Switch
          (arg2,
           [(C.INT 0, E.Raise (toRCEx B.DivExExn, retTy)),
            (C.INT ~1,
             E.Switch (arg1,
                       [(C.INT minInt, E.Raise (toRCEx B.OverflowExExn, retTy))],
                       E.Int_sub_unsafe (E.Int 0, arg1)))],
           E.Int_quot_unsafe (arg1, arg2))
      | (P.Int_quot, _, _) =>
        raise Bug.Bug "compilePrim: Int_quot"

      | (P.Int_rem, [arg1, arg2], []) =>
        E.Switch (arg2,
                  [(C.INT 0, E.Raise (toRCEx B.DivExExn, retTy)),
                   (C.INT ~1, E.Int 0)],
                  E.Int_rem_unsafe (arg1, arg2))
      | (P.Int_rem, _, _) =>
        raise Bug.Bug "compilePrim: Int_rem"

      | (P.Int_div, [arg1, arg2], []) =>
        E.Switch
          (arg2,
           [(C.INT 0, E.Raise (toRCEx B.DivExExn, retTy)),
            (C.INT ~1,
             E.Switch (arg1,
                       [(C.INT minInt,
                         E.Raise (toRCEx B.OverflowExExn, retTy))],
                       E.Int_sub_unsafe (E.Int 0, arg1)))],
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
               ([(q, E.Int_quot_unsafe (arg1, arg2)),
                 (r, E.Int_rem_unsafe (arg1, arg2)),
                 (s, E.Word_fromInt (E.Word_xorb (E.Word_fromInt arg1,
                                                  E.Word_fromInt arg2)))],
                let
                  val f1 = E.Word_fromInt (E.Int_gteq (E.Var s, E.Int 0))
                  val f2 = E.Word_fromInt (E.Int_eq (E.Var r, E.Int 0))
                  val m = E.Word_sub (E.Word_orb (f1, f2), E.Word 1)
                in
                  E.Int_add_unsafe (E.Var q, E.Word_toIntX m)
                end)
           end)
      | (P.Int_div, _, _) =>
        raise Bug.Bug "compilePrim: Int_div"

      | (P.Int_mod, [arg1, arg2], []) =>
        E.Switch
          (arg2,
           [(C.INT 0, E.Raise (toRCEx B.DivExExn, retTy)),
            (C.INT ~1, E.Int 0)],
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
               ([(r, E.Int_rem_unsafe (arg1, arg2)),
                 (s, E.Word_fromInt (E.Word_xorb (E.Word_fromInt arg1,
                                                  E.Word_fromInt arg2)))],
                let
                  val f1 = E.Word_fromInt (E.Int_gteq (E.Var s, E.Int 0))
                  val f2 = E.Word_fromInt (E.Int_eq (E.Var r, E.Int 0))
                  val m = E.Word_sub (E.Word_orb (f1, f2), E.Word 1)
                in
                  E.Int_add_unsafe
                    (E.Var r,
                     E.Word_toIntX (E.Word_andb (E.Word_fromInt arg2, m)))
                end)
           end)
      | (P.Int_mod, _, _) =>
        raise Bug.Bug "compilePrim: Int_mod"

      | (P.Int_abs, [arg], []) =>
        E.Switch (arg,
                  [(C.INT minInt, E.Raise (toRCEx B.OverflowExExn, retTy))],
                  E.If (E.Int_gteq (arg, E.Int 0),
                        arg,
                        E.Int_sub_unsafe (E.Int 0, arg)))
      | (P.Int_abs, _, _) =>
        raise Bug.Bug "compilePrim: Int_abs"

      | (P.Int_neg, [arg], []) =>
        E.Switch (arg,
                  [(C.INT minInt, E.Raise (toRCEx B.OverflowExExn, retTy))],
                  E.Int_sub_unsafe (E.Int 0, arg))
      | (P.Int_neg, _, _) =>
        raise Bug.Bug "compilePrim: Int_neg"

      | (P.Word_neg, [arg], []) =>
        E.Word_sub (E.Word 0, arg)
      | (P.Word_neg, _, _) =>
        raise Bug.Bug "compilePrim: Word_neg"

      | (P.Real_neg, [arg], []) =>
        E.Real_sub (E.Real 0, arg)
      | (P.Real_neg, _, _) =>
        raise Bug.Bug "compilePrim: Real_neg"

      | (P.Float_neg, [arg], []) =>
        E.Float_sub (E.Float 0, arg)
      | (P.Float_neg, _, _) =>
        raise Bug.Bug "compilePrim: Float_neg"

      | (P.Byte_neg, [arg], []) =>
        E.Byte_sub (E.Word8 0, arg)
      | (P.Byte_neg, _, _) =>
        raise Bug.Bug "compilePrim: Byte_neg"

      | (P.Word_notb, [arg], []) =>
        E.Word_xorb (E.Word ~1, arg)
      | (P.Word_notb, _, _) =>
        raise Bug.Bug "compilePrim: Word_notb"

      | (P.Byte_notb, [arg], []) =>
        E.Byte_xorb (E.Word8 ~1, arg)
      | (P.Byte_notb, _, _) =>
        raise Bug.Bug "compilePrim: Byte_notb"

      | (P.Char_chr, [arg], []) =>
        E.If (E.Andalso [E.Int_gteq (arg, E.Int 0),
                         E.Int_lteq (arg, E.Int maxChar)],
              E.Cast (E.Byte_fromWord (E.Word_fromInt arg), B.charTy),
              E.Raise (toRCEx B.ChrExExn, retTy))
      | (P.Char_chr, _, _) =>
        raise Bug.Bug "compilePrim: Char_chr"

      | (P.Char_gt, [arg1, arg2], []) =>
        E.Byte_gt (E.Cast (arg1, B.word8Ty), E.Cast (arg2, B.word8Ty))
      | (P.Char_gt, _, _) =>
        raise Bug.Bug "compilePrim: Char_gt"

      | (P.Char_gteq, [arg1, arg2], []) =>
        E.Byte_gteq (E.Cast (arg1, B.word8Ty), E.Cast (arg2, B.word8Ty))
      | (P.Char_gteq, _, _) =>
        raise Bug.Bug "compilePrim: Char_gteq"

      | (P.Char_lt, [arg1, arg2], []) =>
        E.Byte_lt (E.Cast (arg1, B.word8Ty), E.Cast (arg2, B.word8Ty))
      | (P.Char_lt, _, _) =>
        raise Bug.Bug "compilePrim: Char_lt"

      | (P.Char_lteq, [arg1, arg2], []) =>
        E.Byte_lteq (E.Cast (arg1, B.word8Ty), E.Cast (arg2, B.word8Ty))
      | (P.Char_lteq, _, _) =>
        raise Bug.Bug "compilePrim: Char_lteq"

      | (P.Char_ord, [arg], []) =>
        E.Word_toIntX (E.Byte_toWord (E.Cast (arg, B.word8Ty)))
      | (P.Char_ord, _, _) =>
        raise Bug.Bug "compilePrim: Char_ord"

      | (P.Float_trunc, [arg], []) =>
        E.If (E.Float_isNan arg,
              E.Raise (toRCEx B.DomainExExn, retTy),
              E.If (E.Andalso [E.Float_gteq (arg, E.Float minInt),
                               E.Float_lteq (arg, E.Float maxInt)],
                    E.PrimApply ({primitive = P.R (P.M P.Float_trunc_unsafe),
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
                    E.PrimApply ({primitive = P.R (P.M P.Real_trunc_unsafe),
                                  ty = primTy},
                                 instTyList, retTy, [arg]),
                    E.Raise (toRCEx B.OverflowExExn, retTy)))
      | (P.Real_trunc, _, _) =>
        raise Bug.Bug "compilePrim: Real_trunc"

      | (P.Int_add, _, _) =>
        raise Bug.Bug "Int_add: not implemented"

      | (P.Int_mul, _, _) =>
        raise Bug.Bug "Int_mul: not implemented"

      | (P.Int_sub, _, _) =>
        raise Bug.Bug "Int_sub: not implemented"

      | (P.Byte_fromInt, [arg], []) =>
        E.Byte_fromWord (E.Word_fromInt arg)
      | (P.Byte_fromInt, _, _) =>
        raise Bug.Bug "compilePrim: Byte_fromInt"

      | (P.Word_toInt, [arg], []) =>
        let
          val v = EmitTypedLambda.newId ()
        in
          E.Let ([(v, E.Word_toIntX arg)],
                 E.If (E.Int_lt (E.Var v, E.Int 0),
                       E.Raise (toRCEx B.OverflowExExn, retTy),
                       E.Var v))
        end
      | (P.Word_toInt, _, _) =>
        raise Bug.Bug "compilePrim: Word_toInt"

      | (P.Byte_toInt, [arg], []) =>
        E.Word_toIntX (E.Byte_toWord arg)
      | (P.Byte_toInt, _, _) =>
        raise Bug.Bug "compilePrim: Byte_toInt"

      | (P.Byte_toWordX, [arg], []) =>
        E.Word_fromInt (E.Byte_toIntX arg)
      | (P.Byte_toWordX, _, _) =>
        raise Bug.Bug "compilePrim: Byte_toWordX"

      | (P.Word_arshift, [arg1, arg2], []) =>
        E.PrimApply ({primitive = P.R (P.M P.Word_arshift_unsafe),
                      ty = primTy},
                     instTyList, retTy,
                     [arg1,
                      E.If (E.Word_lt (arg2, E.Word wordBits), arg2,
                            E.Word (wordBits - 1))])
      | (P.Word_arshift, _, _) =>
        raise Bug.Bug "compilePrim: Word_arshift"

      | (P.Byte_arshift, [arg1, arg2], []) =>
        E.Byte_arshift_unsafe (arg1,
                               E.If (E.Word_lt (arg2, E.Word byteBits),
                                     E.Byte_fromWord arg2,
                                     E.Word8 (byteBits - 1)))
      | (P.Byte_arshift, _, _) =>
        raise Bug.Bug "compilePrim: Byte_arshift"

      | (P.Word_lshift, [arg1, arg2], []) =>
        E.If (E.Word_lt (arg2, E.Word wordBits),
              E.PrimApply ({primitive = P.R (P.M P.Word_lshift_unsafe),
                            ty = primTy},
                           instTyList, retTy, [arg1, arg2]),
              E.Word 0)
      | (P.Word_lshift, _, _) =>
        raise Bug.Bug "compilePrim: Word_lshift"

      | (P.Byte_lshift, [arg1, arg2], []) =>
        E.If (E.Word_lt (arg2, E.Word byteBits),
              E.Byte_lshift_unsafe (arg1, E.Byte_fromWord arg2),
              E.Word8 0)
      | (P.Byte_lshift, _, _) =>
        raise Bug.Bug "compilePrim: Byte_lshift"

      | (P.Word_rshift, [arg1, arg2], []) =>
        E.If (E.Word_lt (arg2, E.Word wordBits),
              E.PrimApply ({primitive = P.R (P.M P.Word_rshift_unsafe),
                            ty = primTy},
                           instTyList, retTy, [arg1, arg2]),
              E.Word 0)
      | (P.Word_rshift, _, _) =>
        raise Bug.Bug "compilePrim: Word_rshift"

      | (P.Byte_rshift, [arg1, arg2], []) =>
        E.If (E.Word_lt (arg2, E.Word byteBits),
              E.Byte_rshift_unsafe (arg1, E.Byte_fromWord arg2),
              E.Word8 0)
      | (P.Byte_rshift, _, _) =>
        raise Bug.Bug "compilePrim: Byte_rshift"

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

      | (P.L prim, args, instTyList) =>
        E.PrimApply ({primitive = prim, ty = primTy},
                     instTyList, retTy, args)

  fun compile {primitive, primTy, instTyList, argExpList, resultTy, loc} =
      let
        val binds = map (fn x => (EmitTypedLambda.newId (), x)) argExpList
        val args = map (fn (id, _) => E.Var id) binds
        val exp1 = elabPrim (primitive, primTy, instTyList, resultTy, args)
      in
        E.Let (binds, exp1)
      end

end
