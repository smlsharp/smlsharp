(**
 * Translation of primitive into typed lambda
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)

structure PrimitiveTypedLambda =
struct

  structure L = TypedLambda
  structure T = Types
  structure P = BuiltinPrimitive
  structure B = BuiltinTypes
  structure E = EmitTypedLambda

  val int8min = ~128 : int8
  val int16min = ~32768 : int16
  val int32min = ~2147483648 : int32
  val int64min = ~9223372036854775808 : int64

  val int8min_r64 = ~128.0 : real64
  val int8max_r64 =  127.0 : real64
  val int16min_r64 = ~32768.0 : real64
  val int16max_r64 =  32767.0 : real64
  val int32min_r64 = ~2147483648.0 : real64
  val int32max_r64 =  2147483647.0 : real64
  val int64min_r64 = ~9223372036854775808.0 : real64 (* c3e0000000000000 *)
  val int64max_r64 =  9223372036854774784.0 : real64 (* 43dfffffffffffff *)

  val int8min_r32 = ~128.0 : real32
  val int8max_r32 =  127.0 : real32
  val int16min_r32 = ~32768.0 : real32
  val int16max_r32 =  32767.0 : real32
  val int32min_r32 = ~2147483648.0 : real32 (* cf000000 *)
  val int32max_r32 =  2147483520.0 : real32  (* 4effffff *)
  val int64min_r32 = ~9223372036854775808.0 : real32 (* df000000 *)
  val int64max_r32 =  9223371487098961920.0 : real32 (* 5effffff *)

  val numBits_int8 = 8
  val numBits_int16 = 16
  val numBits_int32 = 32
  val numBits_int64 = 64

  (* char is 8-bit *)
  val maxChar = 255
  (* the maximum size that can be stored in the object header *)
  val maxObjectSize = 0x0fffffff
  val maxStringSize = maxObjectSize - 1

  fun maxArraySize elemTy =
      E.Cast
        (E.Word_div_unsafe
           B.word32Ty
           (E.Word32 maxObjectSize, E.Cast (E.SizeOf elemTy, B.word32Ty)),
         B.int32Ty)

  datatype int_ty =
      INT8ty
    | INT16ty
    | INT32ty
    | INT64ty

  datatype word_ty =
      WORD8ty
    | WORD16ty
    | WORD32ty
    | WORD64ty

  datatype real_ty =
      REAL32ty
    | REAL64ty

  fun intTy ty =
      case TypesBasics.derefTy ty of
        T.CONSTRUCTty {tyCon, args=[]} =>
        if TypID.eq (#id tyCon, #id B.int8TyCon) then INT8ty
        else if TypID.eq (#id tyCon, #id B.int16TyCon) then INT16ty
        else if TypID.eq (#id tyCon, #id B.int32TyCon) then INT32ty
        else if TypID.eq (#id tyCon, #id B.int64TyCon) then INT64ty
        else raise Bug.Bug "intTy expected"
      | _ => raise Bug.Bug "intTy expected"

  fun wordTy ty =
      case TypesBasics.derefTy ty of
        T.CONSTRUCTty {tyCon, args=[]} =>
        if TypID.eq (#id tyCon, #id B.word8TyCon) then WORD8ty
        else if TypID.eq (#id tyCon, #id B.word16TyCon) then WORD16ty
        else if TypID.eq (#id tyCon, #id B.word32TyCon) then WORD32ty
        else if TypID.eq (#id tyCon, #id B.word64TyCon) then WORD64ty
        else raise Bug.Bug "wordTy expected"
      | _ => raise Bug.Bug "wordTy expected"

  fun realTy ty =
      case TypesBasics.derefTy ty of
        T.CONSTRUCTty {tyCon, args=[]} =>
        if TypID.eq (#id tyCon, #id B.real32TyCon) then REAL32ty
        else if TypID.eq (#id tyCon, #id B.real64TyCon) then REAL64ty
        else raise Bug.Bug "realTy expected"
      | _ => raise Bug.Bug "realTy expected"

  fun int_wordTy ty =
      case intTy ty of
        INT8ty => B.word8Ty
      | INT16ty => B.word16Ty
      | INT32ty => B.word32Ty
      | INT64ty => B.word64Ty

  fun int_range_real rty ity =
      case (realTy rty, intTy ity) of
        (REAL32ty, INT8ty) => (E.Real32 int8min_r32, E.Real32 int8max_r32)
      | (REAL32ty, INT16ty) => (E.Real32 int16min_r32, E.Real32 int16max_r32)
      | (REAL32ty, INT32ty) => (E.Real32 int32min_r32, E.Real32 int32max_r32)
      | (REAL32ty, INT64ty) => (E.Real32 int64min_r32, E.Real32 int64max_r32)
      | (REAL64ty, INT8ty) => (E.Real64 int8min_r64, E.Real64 int8max_r64)
      | (REAL64ty, INT16ty) => (E.Real64 int16min_r64, E.Real64 int16max_r64)
      | (REAL64ty, INT32ty) => (E.Real64 int32min_r64, E.Real64 int32max_r64)
      | (REAL64ty, INT64ty) => (E.Real64 int64min_r64, E.Real64 int64max_r64)

  fun word_const ty n =
      case wordTy ty of
        WORD8ty => L.WORD8 (Word8.fromInt n)
      | WORD16ty => L.WORD16 (Word16.fromInt n)
      | WORD32ty => L.WORD32 (Word32.fromInt n)
      | WORD64ty => L.WORD64 (Word64.fromInt n)

  fun word_constExp ty =
      case wordTy ty of
        WORD8ty => E.Word8
      | WORD16ty => E.Word16
      | WORD32ty => E.Word32
      | WORD64ty => E.Word64

  fun int_const ty n =
      case intTy ty of
        INT8ty => L.INT8 (Int8.fromInt n)
      | INT16ty => L.INT16 (Int16.fromInt n)
      | INT32ty => L.INT32 (Int32.fromInt n)
      | INT64ty => L.INT64 (Int64.fromInt n)

  fun int_constExp ty n =
      E.Int (int_const ty n)

  fun int_min ty =
      case intTy ty of
        INT8ty => L.INT8 int8min
      | INT16ty => L.INT16 int16min
      | INT32ty => L.INT32 int32min
      | INT64ty => L.INT64 int64min

  fun int_minExp ty =
      E.Int (int_min ty)

  fun int_numBits ty =
      case intTy ty of
        INT8ty => numBits_int8 - 1
      | INT16ty => numBits_int16 - 1
      | INT32ty => numBits_int32 - 1
      | INT64ty => numBits_int64 - 1

  fun word_numBits ty =
      case wordTy ty of
        WORD8ty => numBits_int8
      | WORD16ty => numBits_int16
      | WORD32ty => numBits_int32
      | WORD64ty => numBits_int64

  fun real_zero ty =
      case realTy ty of
        REAL32ty => E.Real32 0.0
      | REAL64ty => E.Real64 0.0

  fun word_canTrunc ty truncBits exp =
      (* check whether exp is of the form
       * 1111...1111xxxxx.....xxxxx      0000...0000xxxxx.....xxxxx
       *            <- truncBits ->  or             <- truncBits ->
       * <------- wordBits ------->      <------- wordBits ------->
       *)
      E.Word_lteq
        ty
        (E.Word_add
           ty
           (E.Word_arshift_unsafe ty (exp, word_constExp ty truncBits),
            word_constExp ty 1),
         word_constExp ty 1)

  fun bool_toWord32 exp =
      E.Cast (exp, B.word32Ty)

  fun Array_sub (elemTy, ary, index) =
      E.If (E.Andalso
              [E.Int_gteq B.int32Ty (index, E.Int32 0),
               E.Int_lt B.int32Ty (index, E.Array_length (elemTy, ary))],
            E.Array_sub_unsafe (elemTy, ary, index),
            E.Raise (B.SubscriptExExn, elemTy))

  fun elabPrim (primitive, primTy, instTyList, retTy, argExpList, loc) =
      case (primitive, argExpList, #argTyList primTy, instTyList) of
        (P.Cast P.TypeCast, [arg], _, _) =>
        E.Cast (arg, retTy)
      | (P.Cast P.TypeCast, _, _, _) =>
        raise Bug.Bug "compilePrim: Cast"

      | (P.Cast P.BitCast, [arg], _, _) =>
        E.BitCast (arg, retTy)
      | (P.Cast P.BitCast, _, _, _) =>
        raise Bug.Bug "compilePrim: BitCast"

      | (P.Equal, [arg1, arg2], _, [_]) =>
        E.PrimApply ({primitive = P.R (P.M P.RuntimePolyEqual),
                      ty = primTy},
                     instTyList, retTy, [arg1, arg2])
      | (P.Equal, _, _, _) =>
        raise Bug.Bug "compilePrim: Equal"

      | (P.NotEqual, [arg1, arg2], _, [_]) =>
        E.If (E.PrimApply ({primitive = P.R (P.M P.RuntimePolyEqual),
                            ty = primTy},
                           instTyList, retTy, [arg1, arg2]),
              E.False, E.True)
      | (P.NotEqual, _, _, _) =>
        raise Bug.Bug "compilePrim: NotEqual"

      | (P.Real_notEqual, [arg1, arg2], [ty, _], []) =>
        E.If (E.Real_equal ty (arg1, arg2), E.False, E.True)
      | (P.Real_notEqual, _, _, _) =>
        raise Bug.Bug "compilePrim: Real32_notEqual"

      | (P.Array_alloc, [size], _, [elemTy]) =>
        E.If (E.Andalso [E.Int_gteq B.int32Ty (size, E.Int32 0),
                         E.Int_lteq B.int32Ty (size, maxArraySize elemTy)],
              E.Array_alloc_unsafe (elemTy, size),
              E.Raise (B.SizeExExn, retTy))
      | (P.Array_alloc, _, _, _) =>
        raise Bug.Bug "compilePrim: Array_alloc"

      | (P.Vector_alloc, [size], _, [elemTy]) =>
        E.If (E.Andalso [E.Int_gteq B.int32Ty (size, E.Int32 0),
                         E.Int_lteq B.int32Ty (size, maxArraySize elemTy)],
              E.Vector_alloc_unsafe (elemTy, size),
              E.Raise (B.SizeExExn, retTy))
      | (P.Vector_alloc, _, _, _) =>
        raise Bug.Bug "compilePrim: Vector_alloc"

      | (P.String_alloc_unsafe, [size], _, []) =>
        E.String_alloc_unsafe size
      | (P.String_alloc_unsafe, _, _, _) =>
        raise Bug.Bug "compilePrim: String_alloc_unsafe"

      | (P.String_alloc, [size], [ty], []) =>
        E.If (E.Andalso [E.Int_gteq B.int32Ty (size, E.Int32 0),
                         E.Int_lteq B.int32Ty (size, E.Int32 maxStringSize)],
              E.String_alloc_unsafe size,
              E.Raise (B.SizeExExn, retTy))
      | (P.String_alloc, _, _, _) =>
        raise Bug.Bug "compilePrim: String_alloc"

      | (P.Array_length, [ary], _, [elemTy]) =>
        E.Array_length (elemTy, ary)
      | (P.Array_length, _, _, _) =>
        raise Bug.Bug "compilePrim: Array_length"

      | (P.String_size, [arg], _, []) =>
        E.String_size arg
      | (P.String_size, _, _, _) =>
        raise Bug.Bug "compilePrim: String_size"

      | (P.Array_copy, [di, dst, src], _, [elemTy]) =>
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
           *   di >= 0 and di <= dlen and dlen - di >= slen
           *)
          E.Let
            ([(slen, E.Array_length (elemTy, src)),
              (dlen, E.Array_length (elemTy, dst))],
             E.If
               (E.Andalso
                  [E.Int_gteq B.int32Ty (di, E.Int32 0),
                   E.Int_lteq B.int32Ty (di, E.Var dlen),
                   E.Int_gteq
                     B.int32Ty
                     (E.Int_sub_unsafe B.int32Ty (E.Var dlen, di), E.Var slen)],
                E.Array_copy_unsafe
                  (elemTy, src, E.Int32 0, dst, di, E.Var slen),
                E.Raise (B.SubscriptExExn, retTy)))
        end
      | (P.Array_copy, _, _, _) =>
        raise Bug.Bug "compilePrim: Array_copy"

      | (P.Array_sub, [ary, index], _, [elemTy]) =>
        Array_sub (elemTy, ary, index)
      | (P.Array_sub, _, _, _) =>
        raise Bug.Bug "compilePrim: Array_sub"

      | (P.Array_update, [ary, index, elem], _, [elemTy]) =>
        E.If (E.Andalso
                [E.Int_gteq B.int32Ty (index, E.Int32 0),
                 E.Int_lt B.int32Ty (index, E.Array_length (elemTy, ary))],
              E.Array_update_unsafe (elemTy, ary, index, elem),
              E.Raise (B.SubscriptExExn, retTy))
      | (P.Array_update, _, _, _) =>
        raise Bug.Bug "compilePrim: Array_update"

      | (P.String_sub, [ary, index], [_, ty], []) =>
        E.If (E.Andalso
                [E.Int_gteq B.int32Ty (index, E.Int32 0),
                 E.Int_lt B.int32Ty (index, E.String_size ary)],
              E.String_sub_unsafe (ary, index),
              E.Raise (B.SubscriptExExn, retTy))
      | (P.String_sub, _, _, _) =>
        raise Bug.Bug "compilePrim: String_sub"

      | (P.Vector_length, [vec], _, [elemTy]) =>
        E.Array_length (elemTy, E.Cast (vec, E.arrayTy elemTy))
      | (P.Vector_length, _, _, _) =>
        raise Bug.Bug "compilePrim: Vector_length"

      | (P.Vector_sub, [vec, index], _, [elemTy]) =>
        Array_sub (elemTy, E.Cast (vec, E.arrayTy elemTy), index)
      | (P.Vector_sub, _, _, _) =>
        raise Bug.Bug "compilePrim: Vector_sub"

      | (P.Ref_deref, [refExp], _, [elemTy]) =>
        E.Ref_deref (elemTy, refExp)
      | (P.Ref_deref, _, _, _) =>
        raise Bug.Bug "compilePrim: Ref_deref"

      | (P.Ref_assign, [refExp, argExp], _, [elemTy]) =>
        E.Ref_assign (elemTy, refExp, argExp)
      | (P.Ref_assign, _, _, _) =>
        raise Bug.Bug "compilePrim: Ref_assign"

      | (P.Word_arshift, [arg1, arg2], [ty1, ty2], []) =>
        E.If (E.Word_lt ty2 (arg2, word_constExp ty2 (word_numBits ty1)),
              E.Word_arshift_unsafe ty1 (arg1, E.Word_toWord (ty2, ty1) arg2),
              E.Word_arshift_unsafe
                ty1 (arg1, word_constExp ty1 (word_numBits ty1 - 1)))
      | (P.Word_arshift, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_arshift"

      | (P.Word_lshift, [arg1, arg2], [ty1, ty2], []) =>
        E.If (E.Word_lt ty2 (arg2, word_constExp ty2 (word_numBits ty1)),
              E.Word_lshift_unsafe ty1 (arg1, E.Word_toWord (ty2, ty1) arg2),
              word_constExp ty1 0)
      | (P.Word_lshift, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_lshift"

      | (P.Word_rshift, [arg1, arg2], [ty1, ty2], []) =>
        E.If (E.Word_lt ty2 (arg2, word_constExp ty2 (word_numBits ty1)),
              E.Word_rshift_unsafe ty1 (arg1, E.Word_toWord (ty2, ty1) arg2),
              word_constExp ty1 0)
      | (P.Word_rshift, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_rshift"

      | (P.Word_div, [arg1, arg2], [_, ty], []) =>
        E.Switch (arg2,
                  [(word_const ty 0, E.Raise (B.DivExExn, retTy))],
                  E.Word_div_unsafe ty (arg1, arg2))
      | (P.Word_div, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_div"

      | (P.Word_mod, [arg1, arg2], [_, ty], []) =>
        E.Switch (arg2,
                  [(word_const ty 0, E.Raise (B.DivExExn, retTy))],
                  E.Word_mod_unsafe ty (arg1, arg2))
      | (P.Word_mod, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_mod"

      | (P.Word_neg, [arg], [ty], []) =>
        E.Word_sub ty (word_constExp ty 0, arg)
      | (P.Word_neg, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_neg"

      | (P.Word_notb, [arg], [ty], []) =>
        E.Word_xorb ty (word_constExp ty ~1, arg)
      | (P.Word_notb, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_notb"

      | (P.Word_fromInt, [arg], [ty], []) =>
        if word_numBits retTy = int_numBits ty + 1
        then E.Cast (arg, retTy)
        else E.Word_fromInt (ty, retTy) arg
      | (P.Word_fromInt, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_fromInt"

      | (P.Word_toIntX, [arg], [ty], []) =>
        let
          val wordBits = word_numBits ty
          val intBits = int_numBits retTy
        in
          if wordBits = intBits + 1
          then E.Cast (arg, retTy)
          else if wordBits < intBits + 1
          then E.Word_toIntX_unsafe (ty, retTy) arg
          else E.If (word_canTrunc ty intBits arg,
                     E.Word_toIntX_unsafe (ty, retTy) arg,
                     E.Raise (B.OverflowExExn, retTy))
        end
      | (P.Word_toIntX, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_toIntX"

      | (P.Word_toInt, [arg], [ty], []) =>
        let
          val wordBits = word_numBits ty
          val intBits = int_numBits retTy
        in
          if wordBits < intBits
          then E.Word_toInt (ty, retTy) arg
          else E.Switch
                 (E.Word_rshift_unsafe ty (arg, word_constExp ty intBits),
                  [(word_const ty 0, E.Word_toInt (ty, retTy) arg)],
                  E.Raise (B.OverflowExExn, retTy))
        end
      | (P.Word_toInt, _, _, _) =>
        raise Bug.Bug "compilePrim: Word_toInt"

      | (P.Int_abs, [arg], _, []) =>
        E.Switch
          (arg,
           [(int_min retTy, E.Raise (B.OverflowExExn, retTy))],
           E.If (E.Int_lt retTy (arg, int_constExp retTy 0),
                 E.Int_sub_unsafe retTy (int_constExp retTy 0, arg),
                 arg))
      | (P.Int_abs, _, _, _) =>
        raise Bug.Bug "compilePrim: Int8_abs"

      | (P.Int_neg, [arg], _, []) =>
        E.Switch
          (arg,
           [(int_min retTy, E.Raise (B.OverflowExExn, retTy))],
           E.Int_sub_unsafe retTy (int_constExp retTy 0, arg))
      | (P.Int_neg, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_neg"

      | (P.Int_add, [arg1, arg2], _, []) =>
        E.Switch
          (E.Cast (E.Int_add_overflowCheck retTy (arg1, arg2), B.int32Ty),
           [(L.INT32 0, E.Int_add_unsafe retTy (arg1, arg2))],
           E.Raise (B.OverflowExExn, retTy))
      | (P.Int_add, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_add"

      | (P.Int_mul, [arg1, arg2], _, []) =>
        E.Switch
          (E.Cast (E.Int_mul_overflowCheck retTy (arg1, arg2), B.int32Ty),
           [(L.INT32 0, E.Int_mul_unsafe retTy (arg1, arg2))],
           E.Raise (B.OverflowExExn, retTy))
      | (P.Int_mul, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_mul"

      | (P.Int_sub, [arg1, arg2], _, []) =>
        E.Switch
          (E.Cast (E.Int_sub_overflowCheck retTy (arg1, arg2), B.int32Ty),
           [(L.INT32 0, E.Int_sub_unsafe retTy (arg1, arg2))],
           E.Raise (B.OverflowExExn, retTy))
      | (P.Int_sub, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_sub"

      | (P.Int_div, [arg1, arg2], _, []) =>
        let
          val wordTy = int_wordTy retTy
          val Word_add = E.Word_add wordTy
          val Word_andb = E.Word_andb wordTy
          val Word_orb = E.Word_orb wordTy
          val Word_xorb = E.Word_xorb wordTy
          fun Word_fromInt x = E.Cast (x, wordTy)
          fun Word_toInt x = E.Cast (x, retTy)
          val bool_toWord = E.Word_toWord (B.word32Ty, wordTy) o bool_toWord32
          val q = EmitTypedLambda.newId ()
          val r = EmitTypedLambda.newId ()
          val s = EmitTypedLambda.newId ()
        in
          E.Switch
            (arg2,
             [(int_const retTy 0, E.Raise (B.DivExExn, retTy))],
             (*
              * Overflow check
              *   (x == minInt) && (y == -1)
              * = ((x ^ minInt) | (y + 1)) == 0
              *)
             E.Switch
               (Word_orb (Word_xorb (Word_fromInt arg1,
                                     E.Cast (int_minExp retTy, wordTy)),
                          Word_add (Word_fromInt arg2,
                                    E.Cast (int_constExp retTy 1, wordTy))),
                [(word_const wordTy 0, E.Raise (B.OverflowExExn, retTy))],
                (*
                 * div rounds the quotient towards negative infinity.
                 *    7 div  3 =  2     7 quot  3 =  2
                 *    7 div ~3 = ~3     7 quot ~3 = ~2
                 *   ~7 div  3 = ~3    ~7 quot  3 = ~2
                 *   ~7 div ~3 =  2    ~7 quot ~3 =  2
                 * q = x quot y
                 * r = x rem y
                 * s = x xor y
                 * x div y = q - ((s < 0) && (r != 0))
                 *         = q - ((s < 0) & ((r == 0) ^ 1))
                 *)
                E.Let
                  ([(q, E.Int_quot_unsafe retTy (arg1, arg2)),
                    (r, E.Int_rem_unsafe retTy (arg1, arg2)),
                    (s, Word_toInt (Word_xorb (Word_fromInt arg1,
                                               Word_fromInt arg2)))],
                   let
                     val f1 = bool_toWord
                                (E.Int_lt retTy (E.Var s, int_constExp retTy 0))
                     val f2 = bool_toWord
                                (E.Int_eq retTy (E.Var r, int_constExp retTy 0))
                     val m = Word_andb
                               (f1, Word_xorb (f2, word_constExp wordTy 1))
                   in
                     E.Int_sub_unsafe retTy (E.Var q, Word_toInt m)
                   end)))
        end
      | (P.Int_div, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_div"

      | (P.Int_mod, [arg1, arg2], _, []) =>
        let
          val wordTy = int_wordTy retTy
          val Word_sub = E.Word_sub wordTy
          val Word_andb = E.Word_andb wordTy
          val Word_orb = E.Word_orb wordTy
          val Word_xorb = E.Word_xorb wordTy
          fun Word_fromInt x = E.Cast (x, wordTy)
          fun Word_toInt x = E.Cast (x, retTy)
          val bool_toWord = E.Word_toWord (B.word32Ty, wordTy) o bool_toWord32
          val r = EmitTypedLambda.newId ()
          val s = EmitTypedLambda.newId ()
        in
          E.Switch
            (arg2,
             [(int_const retTy 0, E.Raise (B.DivExExn, retTy)),
              (int_const retTy ~1, int_constExp retTy 0)],
             (*
              * mod rounds the quotient towards negative infinity.
              *    7 mod  3 =  1     7 rem  3 =  1
              *    7 mod ~3 = ~2     7 rem ~3 =  1
              *   ~7 mod  3 =  2    ~7 rem  3 = ~1
              *   ~7 mod ~3 = ~1    ~7 rem ~3 = ~1
              * r = x rem y
              * s = x xor y
              * x mod y = r + (((s < 0) && (r != 0)) ? y : 0)
              *         = r + ((-((s < 0) & ((r == 0) ^ 1))) & y)
              *)
             E.Let
               ([(r, E.Int_rem_unsafe retTy (arg1, arg2)),
                 (s, Word_toInt (Word_xorb (Word_fromInt arg1,
                                            Word_fromInt arg2)))],
                let
                  val f1 = bool_toWord
                             (E.Int_lt retTy (E.Var s, int_constExp retTy 0))
                  val f2 = bool_toWord
                             (E.Int_eq retTy (E.Var r, int_constExp retTy 0))
                  val m = Word_andb (f1, Word_xorb (f2, word_constExp wordTy 1))
                  val n = Word_sub (word_constExp wordTy 0, m)
                  val a = Word_andb (n, Word_fromInt arg2)
                in
                  E.Int_add_unsafe retTy (E.Var r, Word_toInt a)
                end))
        end
      | (P.Int_mod, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_mod"

      | (P.Int_quot, [arg1, arg2], _, []) =>
        let
          val wordTy = int_wordTy retTy
          val Word_add = E.Word_add wordTy
          val Word_orb = E.Word_orb wordTy
          val Word_xorb = E.Word_xorb wordTy
          fun Word_fromInt x = E.Cast (x, wordTy)
        in
          E.Switch
            (arg2,
             [(int_const retTy 0, E.Raise (B.DivExExn, retTy))],
             (*
              * Overflow check
              *   (x == minInt) && (y == -1)
              * = ((x ^ minInt) | (y + 1)) == 0
              *)
             E.Switch
               (Word_orb (Word_xorb (Word_fromInt arg1,
                                     E.Cast (int_minExp retTy, wordTy)),
                          Word_add (Word_fromInt arg2,
                                    E.Cast (int_constExp retTy 1, wordTy))),
                [(word_const wordTy 0, E.Raise (B.OverflowExExn, retTy))],
                E.Int_quot_unsafe retTy (arg1, arg2)))
        end
      | (P.Int_quot, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_quot"

      | (P.Int_rem, [arg1, arg2], _, []) =>
        let
          val wordTy = int_wordTy retTy
          val Word_orb = E.Word_orb wordTy
          val Word_xorb = E.Word_xorb wordTy
          fun Word_fromInt x = E.Cast (x, wordTy)
        in
          E.Switch
            (arg2,
             [(int_const retTy 0, E.Raise (B.DivExExn, retTy)),
              (int_const retTy ~1, int_constExp retTy 0)],
             E.Int_rem_unsafe retTy (arg1, arg2))
        end
      | (P.Int_rem, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_rem"

      | (P.Int_toInt, [arg], [ty], []) =>
        let
          val fromBits = int_numBits ty
          val toBits = int_numBits retTy
          val wordTy = int_wordTy ty
          fun Word_fromInt x = E.Cast (x, wordTy)
        in
          if fromBits = toBits
          then arg
          else if fromBits < toBits
          then E.Int_toInt_unsafe (ty, retTy) arg
          else E.If (word_canTrunc wordTy toBits (Word_fromInt arg),
                     E.Int_toInt_unsafe (ty, retTy) arg,
                     E.Raise (B.OverflowExExn, retTy))
        end
      | (P.Int_toInt, _, _, _) =>
        raise Bug.Bug "compilePrim: Int_toInt"

      | (P.Char_chr, [arg], [ty], []) =>
        E.If (E.Andalso [E.Int_gteq ty (arg, int_constExp ty 0),
                         case intTy ty of
                           INT8ty => E.True
                         | _ => E.Int_lteq ty (arg, int_constExp ty maxChar)],
              E.Cast (E.Word_fromInt (ty, B.word8Ty) arg, B.charTy),
              E.Raise (B.ChrExExn, B.charTy))
      | (P.Char_chr, _, _, _) =>
        raise Bug.Bug "compilePrim: Char_chr"

      | (P.Char_gt, [arg1, arg2], _, []) =>
        E.Word_gt
          B.word8Ty (E.Cast (arg1, B.word8Ty), E.Cast (arg2, B.word8Ty))
      | (P.Char_gt, _, _, _) =>
        raise Bug.Bug "compilePrim: Char_gt"

      | (P.Char_gteq, [arg1, arg2], _, []) =>
        E.Word_gteq
          B.word8Ty (E.Cast (arg1, B.word8Ty), E.Cast (arg2, B.word8Ty))
      | (P.Char_gteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Char_gteq"

      | (P.Char_lt, [arg1, arg2], _, []) =>
        E.Word_lt
          B.word8Ty (E.Cast (arg1, B.word8Ty), E.Cast (arg2, B.word8Ty))
      | (P.Char_lt, _, _, _) =>
        raise Bug.Bug "compilePrim: Char_lt"

      | (P.Char_lteq, [arg1, arg2], _, []) =>
        E.Word_lteq
          B.word8Ty (E.Cast (arg1, B.word8Ty), E.Cast (arg2, B.word8Ty))
      | (P.Char_lteq, _, _, _) =>
        raise Bug.Bug "compilePrim: Char_lteq"

      | (P.Char_ord, [arg], [ty], []) =>
        (case intTy retTy of
           INT8ty =>
           E.If (E.Int_gteq B.int8Ty (E.Cast (arg, B.int8Ty), E.Int8 0),
                 E.Cast (arg, B.int8Ty),
                 E.Raise (B.OverflowExExn, retTy))
         | _ =>
           E.Word_toInt (B.word8Ty, retTy) (E.Cast (arg, B.word8Ty)))
      | (P.Char_ord, _, _, _) =>
        raise Bug.Bug "compilePrim: Char_ord"

      | (P.Real_neg, [arg], [ty], []) =>
        E.Real_sub ty (real_zero ty, arg)
      | (P.Real_neg, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_neg"

      | (P.Real_trunc, [arg], [ty], []) =>
        E.If (E.Real_isNan ty arg,
              E.Raise (B.DomainExExn, retTy),
              E.If (E.Andalso
                      [E.Real_gteq ty (arg, #1 (int_range_real ty retTy)),
                       E.Real_lteq ty (arg, #2 (int_range_real ty retTy))],
                    E.PrimApply ({primitive = P.R (P.M P.Real_trunc_unsafe),
                                  ty = primTy},
                                 instTyList, retTy, [arg]),
                    E.Raise (B.OverflowExExn, retTy)))
      | (P.Real_trunc, _, _, _) =>
        raise Bug.Bug "compilePrim: Real_trunc"

      | (P.Compose, [arg1, arg2], _, [ty1, ty2, ty3]) =>
        let
          val v = EmitTypedLambda.newId ()
        in
          E.Fn (v, ty3, E.App (arg1, (E.App (arg2, E.Var v))))
        end
      | (P.Compose, _, _, _) =>
        raise Bug.Bug "compilePrim: Compose"

      | (P.Ignore, [arg], _, [ty]) =>
        E.Let ([(EmitTypedLambda.newId (), arg)], E.Unit)
      | (P.Ignore, _, _, _) =>
        raise Bug.Bug "compilePrim: Ignore"

      | (P.Before, [arg1, arg2], _, [ty]) =>
        let
          val ret = EmitTypedLambda.newId ()
        in
          E.Let ([(ret, arg1), (EmitTypedLambda.newId (), arg2)], E.Var ret)
        end
      | (P.Before, _, _, _) =>
        raise Bug.Bug "compilePrim: Before"

      | (P.Ptr_null, nil, _, [ty]) =>
        let
          fun ptrTy ty = T.CONSTRUCTty {tyCon = B.ptrTyCon, args= [ty]}
        in
          E.Cast (E.Const L.NULLPOINTER, ptrTy ty)
        end
      | (P.Ptr_null, _, _, _) =>
        raise Bug.Bug "compilePrim: Ptr_null"

      | (P.Boxed_null, nil, _, _) =>
        E.Null
      | (P.Boxed_null, _, _, _) =>
        raise Bug.Bug "compilePrim: Boxed_null"

      | (P.L prim, args, _, instTyList) =>
        E.PrimApply ({primitive = prim, ty = primTy},
                     instTyList, retTy, args)

  (*
   * - primTy's argTyList is empty only when the argument type is unit.
   * - argument record is exploded when it must have at least two fields.
   * - argument record must not be exploded for polymorphic primitives.
   *
   * types in builtin.smi      TypedLambda.primTy
   * unit -> ty                [] -> ty
   * int -> ty                 [int] -> ty
   * {} -> ty                  [{}] -> ty
   * {1: int} -> ty            [{1: int}] -> ty
   * int * real -> ty          [int, real] -> ty
   * {a: int, b: real} -> ty   [int, real] -> ty
   * 'a -> ty                  ['a] -> ty
   * 'a * 'b -> ty             ['a, 'b] -> ty
   *)
  fun primFunTy boundtvars ty =
      case TypesBasics.derefTy ty of
        T.FUNMty ([argTy], retTy) =>
        (case TypesBasics.derefTy argTy of
           ty as T.RECORDty tys =>
           {boundtvars = boundtvars,
            argTyList = if RecordLabel.Map.numItems tys <= 1
                        then [ty]
                        else RecordLabel.Map.listItems tys,
            resultTy = retTy}
         | ty as T.CONSTRUCTty {tyCon, args = []} =>
           {boundtvars = boundtvars,
            argTyList = if TypID.eq (#id tyCon, #id B.unitTyCon)
                        then nil
                        else [ty],
            resultTy = retTy}
         | argTy =>
           {boundtvars = boundtvars,
            argTyList = [argTy],
            resultTy = retTy})
      | _ => raise Bug.Bug "decomposeFunTy"

  fun toPrimTy ty =
      case TypesBasics.derefTy ty of
        T.POLYty {boundtvars, constraints, body} => primFunTy boundtvars body
      | ty => primFunTy BoundTypeVarID.Map.empty ty

  fun explodeRecord (L.TLRECORD {fields, ...}, T.RECORDty tys) =
      (nil,
       RecordLabel.Map.listItems
         (RecordLabel.Map.mergeWith
            (fn (SOME exp, SOME ty) => SOME (E.Exp (exp, ty))
              | _ => raise Bug.Bug "explodeRecord")
            (fields, tys)))
    | explodeRecord (exp, expTy as T.RECORDty tys) =
      let
        val vid = EmitTypedLambda.newId ()
      in
        ([(vid, E.Exp (exp, expTy))],
         map (fn label => E.Select (label, E.Var vid))
             (RecordLabel.Map.listKeys tys))
      end
    | explodeRecord (exp, expTy as T.CONSTRUCTty {tyCon, args = []}) =
      if TypID.eq (#id B.unitTyCon, #id tyCon)
      then (nil, nil)
      else (nil, [E.Exp (exp, expTy)])
    | explodeRecord (exp, expTy) =
      (nil, [E.Exp (exp, expTy)])

  fun unwrapLet (L.TLLET {decl, body, loc}) =
      let
        val (decls, body) = unwrapLet body
      in
        (E.Decl (decl, loc) :: decls, body)
      end
    | unwrapLet mainExp = (nil, mainExp)

  fun compile {primOp={primitive, ty}, instTyList, argExp, loc} =
      let
        val (primInstTy, instTyList) =
            case instTyList of
              NONE => (TypesBasics.derefTy ty, nil)
            | SOME tys => (TypesBasics.tpappTy (ty, tys), tys)
        val (argTy, retTy) =
            case primInstTy of
              T.FUNMty ([argTy], retTy) => (TypesBasics.derefTy argTy, retTy)
            | _ => raise Bug.Bug "compile: not a function type"
        val (decls, argExp) = unwrapLet argExp
        val primTy = toPrimTy ty
        val (binds1, argExps) =
            case #argTyList primTy of
              [_] => (nil, [E.Exp (argExp, argTy)])
            | _ => explodeRecord (argExp, argTy)
        val _ = if length argExps = length (#argTyList primTy) then ()
                else raise Bug.Bug "compile: arity mismatch"
        val binds2 = map (fn x => (EmitTypedLambda.newId (), x)) argExps
        val args = map (fn (id, _) => E.Var id) binds2
        val exp1 = elabPrim (primitive, primTy, instTyList, retTy, args, loc)
      in
        EmitTypedLambda.emit
          loc
          (E.TLLet (decls, E.Let (binds1 @ binds2, exp1)))
      end

end
