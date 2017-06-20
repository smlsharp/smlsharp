(**
 * Translation of primitive into typed lambda
 *
 * @copyright (c) 2013, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure L = TypedLambda
structure T = Types
structure P = BuiltinPrimitive
structure B = BuiltinTypes
structure C = ConstantTerm
structure E = EmitTypedLambda

functor IntPrim(
  val intTy : T.ty
  val wordTy : T.ty
  val numBits_log2 : int
  val INT : int -> C.constant
  val WORD : int -> C.constant
  val Int : int -> E.exp
  val Word : int -> E.exp
  val Int_lt : E.exp * E.exp -> E.exp
  val Int_eq : E.exp * E.exp -> E.exp
  val Int_add_unsafe : E.exp * E.exp -> E.exp
  val Int_sub_unsafe : E.exp * E.exp -> E.exp
  val Int_mul_unsafe : E.exp * E.exp -> E.exp
  val Int_add_overflowCheck : E.exp * E.exp -> E.exp
  val Int_sub_overflowCheck : E.exp * E.exp -> E.exp
  val Int_mul_overflowCheck : E.exp * E.exp -> E.exp
  val Int_quot_unsafe : E.exp * E.exp -> E.exp
  val Int_rem_unsafe : E.exp * E.exp -> E.exp
  val Word_fromWord32 : E.exp -> E.exp
  val Word_fromWord32X : E.exp -> E.exp
  val Word_toWord32 : E.exp -> E.exp
  val Word_toWord32X : E.exp -> E.exp
  val Word_sub : E.exp * E.exp -> E.exp
  val Word_add : E.exp * E.exp -> E.exp
  val Word_xorb : E.exp * E.exp -> E.exp
  val Word_andb : E.exp * E.exp -> E.exp
  val Word_orb : E.exp * E.exp -> E.exp
  val Word_rshift_unsafe : E.exp * E.exp -> E.exp
  val Word_lshift_unsafe : E.exp * E.exp -> E.exp
  val Word_arshift_unsafe : E.exp * E.exp -> E.exp
  val Word_div_unsafe : E.exp * E.exp -> E.exp
  val Word_mod_unsafe : E.exp * E.exp -> E.exp
) =
struct

  val numBits = Word.toIntX (Word.<< (0w1, Word.fromInt numBits_log2))
  val minInt = Word_lshift_unsafe (Word 1, Word (numBits - 1))
  fun toWord exp = E.RuntimeTyCast (exp, wordTy)
  fun toInt exp = E.RuntimeTyCast (exp, intTy)
  fun boolToWord32 exp = E.RuntimeTyCast (exp, B.wordTy)
  fun boolToWord exp = Word_fromWord32 (boolToWord32 exp)

  fun Int_add retTy (arg1, arg2) =
      E.Switch
        (Int_add_overflowCheck (arg1, arg2),
         [(C.INT32 0, Int_add_unsafe (arg1, arg2))],
         E.Raise (B.OverflowExExn, retTy))

  fun Int_sub retTy (arg1, arg2) =
      E.Switch
        (Int_sub_overflowCheck (arg1, arg2),
         [(C.INT32 0, Int_sub_unsafe (arg1, arg2))],
         E.Raise (B.OverflowExExn, retTy))

  fun Int_mul retTy (arg1, arg2) =
      E.Switch
        (Int_mul_overflowCheck (arg1, arg2),
         [(C.INT32 0, Int_mul_unsafe (arg1, arg2))],
         E.Raise (B.OverflowExExn, retTy))

  fun Int_quot retTy (arg1, arg2) =
      (*
       * Overflow check
       *   (x == minInt) && (y == -1)
       * = ((x ^ minInt) | (y + 1)) == 0
       * ( = (y != 0) && (let (c,r) = add(x,x) in (r | adc(y,0,c)) == 0) )
       *)
      E.Switch
        (arg2,
         [(INT 0, E.Raise (B.DivExExn, retTy))],
         E.Switch
           (Word_orb (Word_xorb (toWord arg1, minInt),
                      Word_add (toWord arg2, Word 1)),
            [(WORD 0, E.Raise (B.OverflowExExn, retTy))],
            Int_quot_unsafe (arg1, arg2)))

  fun Int_rem retTy (arg1, arg2) =
      E.Switch
        (arg2,
         [(INT 0, E.Raise (B.DivExExn, retTy))],
         E.Switch
           (Word_add (toWord arg2, Word 1),
            [(WORD 0, Int 0)],
            Int_rem_unsafe (arg1, arg2)))

  fun Int_div retTy (arg1, arg2) =
      (*
       * Overflow check
       *   (x == minInt) && (y == -1)
       * = ((x ^ minInt) | (y + 1)) == 0
       *)
      E.Switch
        (arg2,
         [(INT 0, E.Raise (B.DivExExn, retTy))],
         E.Switch
           (Word_orb (Word_xorb (toWord arg1, minInt),
                      Word_add (toWord arg2, Word 1)),
            [(WORD 0, E.Raise (B.OverflowExExn, retTy))],
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
            let
              val q = EmitTypedLambda.newId ()
              val r = EmitTypedLambda.newId ()
              val s = EmitTypedLambda.newId ()
            in
              E.Let
                ([(q, Int_quot_unsafe (arg1, arg2)),
                  (r, Int_rem_unsafe (arg1, arg2)),
                  (s, toInt (Word_xorb (toWord arg1, toWord arg2)))],
                 let
                   val f1 = boolToWord (Int_lt (E.Var s, Int 0))
                   val f2 = boolToWord (Int_eq (E.Var r, Int 0))
                   val m = Word_andb (f1, Word_xorb (f2, Word 1))
                 in
                   Int_sub_unsafe (E.Var q, toInt m)
                 end)
            end))

  fun Int_mod retTy (arg1, arg2) =
      E.Switch
        (arg2,
         [(INT 0, E.Raise (B.DivExExn, retTy))],
         E.Switch
           (Word_add (toWord arg2, Word 1),
            [(WORD 0, Int 0)],
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
            let
              val r = EmitTypedLambda.newId ()
              val s = EmitTypedLambda.newId ()
            in
              E.Let
                ([(r, Int_rem_unsafe (arg1, arg2)),
                  (s, toInt (Word_xorb (toWord arg1, toWord arg2)))],
                 let
                   val f1 = boolToWord (Int_lt (E.Var s, Int 0))
                   val f2 = boolToWord (Int_eq (E.Var r, Int 0))
                   val m = Word_andb (f1, Word_xorb (f2, Word 1))
                   val a = Word_andb (Word_sub (Word 0, m), toWord arg2)
                 in
                   Int_add_unsafe (E.Var r, a)
                 end)
            end))

  fun Int_abs retTy arg =
      (*
       * Overflow check  (x == minInt) = ((x ^ minInt) == 0)
       * abs(x) = (x + (-(x < 0))) ^ (-(x < 0))
       *)
      E.Switch
        (Word_xorb (toWord arg, minInt),
         [(WORD 0, E.Raise (B.OverflowExExn, retTy))],
         let
           val y = EmitTypedLambda.newId ()
         in
           E.Let
             ([(y, Word_sub (Word 0, boolToWord (Int_lt (arg, Int 0))))],
              Word_xorb (Word_add (toWord arg, E.Var y), E.Var y))
         end)
           
  fun Int_neg retTy arg =
      (*
       * Overflow check  (x == minInt) = ((x ^ minInt) == 0)
       *)
      E.Switch
        (Word_xorb (toWord arg, minInt),
         [(WORD 0, E.Raise (B.OverflowExExn, retTy))],
         Int_sub_unsafe (Int 0, arg))

  fun Word_div retTy (arg1, arg2) =
      E.Switch
        (arg2,
         [(WORD 0, E.Raise (B.DivExExn, retTy))],
         Word_div_unsafe (arg1, arg2))

  fun Word_mod retTy (arg1, arg2) =
      E.Switch
        (arg2,
         [(WORD 0, E.Raise (B.DivExExn, retTy))],
         Word_mod_unsafe (arg1, arg2))

  fun Word_lshift retTy (arg1, arg2) =
      E.Switch
        (E.Word32_rshift_unsafe (arg2, E.Word32 numBits_log2),
         [(WORD 0, Word_lshift_unsafe (arg1, Word_fromWord32 arg2))],
         Word 0)

  fun Word_rshift retTy (arg1, arg2) =
      E.Switch
        (E.Word32_rshift_unsafe (arg2, E.Word32 numBits_log2),
         [(WORD 0, Word_rshift_unsafe (arg1, Word_fromWord32 arg2))],
         Word 0)

  fun Word_arshift retTy (arg1, arg2) =
      E.Switch
        (E.Word32_rshift_unsafe (arg2, E.Word32 numBits_log2),
         [(WORD 0, Word_arshift_unsafe (arg1, Word_fromWord32 arg2))],
         Word_arshift_unsafe (arg1, Word (numBits - 1)))

  fun Word_neg retTy arg =
      Word_sub (Word 0, arg)

  fun Word_notb retTy arg =
      Word_xorb (Word ~1, arg)

  fun Word_fromInt32_extend retTy arg =
      Word_fromWord32X (E.Word32_fromInt32 arg)

  fun Word_fromInt32_trunc retTy arg =
      Word_fromWord32X (E.Word32_fromInt32 arg)

  fun Word_toInt32_extend retTy arg =
      E.Word32_toInt32X (Word_toWord32 arg)

  fun Word_toInt32_trunc retTy arg =
      (*
       * Check whether or not the value fits in int32.
       *   x < (1 << 31)
       * = (x >> 31) == 0
       *)
      E.Switch
        (Word_rshift_unsafe (toWord arg, Word 31),
         [(WORD 0, E.Word32_toInt32X (Word_toWord32 arg))],
         E.Raise (B.OverflowExExn, retTy))

  fun Word_toInt32X_extend retTy arg =
      E.Word32_toInt32X (Word_toWord32X arg)

  fun Word_toInt32X_trunc retTy arg =
      (*
       * Check whether or not the value fits in int32.
       *   (minInt <= x) && (x <= maxInt)
       * = (~(x | maxInt) == 0) || ((x & minInt) == 0)
       * = ((~x & minInt) == 0) || ((x & minInt) == 0)
       * = (((-(x < 0)) ^ x) & minInt) == 0
       * = ((-(x < 0)) ^ x) >> 31 == 0
       *)
      let
        val m = Word_sub (Word 0, boolToWord (Int_lt (toInt arg, Int 0)))
      in
        E.Switch
          (Word_rshift_unsafe (Word_xorb (m, arg), Word 31),
           [(WORD 0, Word_toWord32 arg)],
           E.Raise (B.OverflowExExn, retTy))
      end

  fun Int_toInt32_extend retTy arg =
      E.Word32_toInt32X (Word_toWord32X (toWord arg))

  fun Int_toInt32_trunc retTy arg =
      (*
       * Check whether or not the value fits in int32.
       *   (minInt <= x) && (x <= maxInt)
       * = (~(x | maxInt) == 0) || ((x & minInt) == 0)
       * = ((~x & minInt) == 0) || ((x & minInt) == 0)
       * = (((-(x < 0)) ^ x) & minInt) == 0
       * = ((-(x < 0)) ^ x) >> 31 == 0
       *)
      let
        val m = Word_sub (Word 0, boolToWord (Int_lt (arg, Int 0)))
      in
        E.Switch
          (Word_rshift_unsafe (Word_xorb (m, toWord arg), Word 31),
           [(WORD 0, E.Word32_toInt32X (Word_toWord32 (toWord arg)))],
           E.Raise (B.OverflowExExn, retTy))
      end

  fun Int_fromInt32_extend retTy arg =
      toInt (Word_fromWord32X (E.Word32_fromInt32 arg))

  fun Int_fromInt32_trunc retTy arg =
      (*
       * Check whether or not the value fits in int.
       *   (minInt <= x) && (x <= maxInt)
       * = (~(x | maxInt) == 0) || ((x & minInt) == 0)
       * = ((~x & minInt) == 0) || ((x & minInt) == 0)
       * = (((-(x < 0)) ^ x) & minInt) == 0
       * = ((-(x < 0)) ^ x) >> (numBits - 1) == 0
       *)
      let
        val f1 = boolToWord32 (E.Int32_lt (arg, E.Int32 0))
        val f2 = E.Word32_sub (E.Word32 0, f1)
        val f3 = E.Word32_xorb (f2, E.Word32_fromInt32 arg)
      in
        E.Switch
          (E.Word32_rshift_unsafe (f3, E.Word32 (numBits - 1)),
           [(C.WORD32 0w0, toInt (Word_fromWord32X (E.Word32_fromInt32 arg)))],
           E.Raise (B.OverflowExExn, retTy))
      end

end

structure Int8Prim =
  IntPrim(
    val intTy = B.int8Ty
    val wordTy = B.word8Ty
    val numBits_log2 = 3
    val INT = C.INT8 o Int8.fromInt
    val WORD = C.WORD8 o Word8.fromInt
    val Int = E.Int8
    val Word = E.Word8
    val Int_lt = E.Int8_lt
    val Int_eq = E.Int8_eq
    val Int_add_unsafe = E.Int8_add_unsafe
    val Int_sub_unsafe = E.Int8_sub_unsafe
    val Int_mul_unsafe = E.Int8_mul_unsafe
    val Int_add_overflowCheck = E.Int8_add_overflowCheck
    val Int_sub_overflowCheck = E.Int8_sub_overflowCheck
    val Int_mul_overflowCheck = E.Int8_mul_overflowCheck
    val Int_quot_unsafe = E.Int8_quot_unsafe
    val Int_rem_unsafe = E.Int8_rem_unsafe
    val Word_fromWord32 = E.Word32_toWord8
    val Word_toWord32 = E.Word8_toWord32
    val Word_fromWord32X = E.Word32_toWord8
    val Word_toWord32X = E.Word8_toWord32X
    val Word_sub = E.Word8_sub
    val Word_add = E.Word8_add
    val Word_xorb = E.Word8_xorb
    val Word_andb = E.Word8_andb
    val Word_orb = E.Word8_orb
    val Word_lshift_unsafe = E.Word8_lshift_unsafe
    val Word_rshift_unsafe = E.Word8_rshift_unsafe
    val Word_arshift_unsafe = E.Word8_arshift_unsafe
    val Word_div_unsafe = E.Word8_div_unsafe
    val Word_mod_unsafe = E.Word8_mod_unsafe
  )

structure Int16Prim =
  IntPrim(
    val intTy = B.int16Ty
    val wordTy = B.word16Ty
    val numBits_log2 = 4
    val INT = C.INT16 o Int16.fromInt
    val WORD = C.WORD16 o Word16.fromInt
    val Int = E.Int16
    val Word = E.Word16
    val Int_lt = E.Int16_lt
    val Int_eq = E.Int16_eq
    val Int_add_unsafe = E.Int16_add_unsafe
    val Int_sub_unsafe = E.Int16_sub_unsafe
    val Int_mul_unsafe = E.Int16_mul_unsafe
    val Int_add_overflowCheck = E.Int16_add_overflowCheck
    val Int_sub_overflowCheck = E.Int16_sub_overflowCheck
    val Int_mul_overflowCheck = E.Int16_mul_overflowCheck
    val Int_quot_unsafe = E.Int16_quot_unsafe
    val Int_rem_unsafe = E.Int16_rem_unsafe
    val Word_fromWord32 = E.Word32_toWord16
    val Word_toWord32 = E.Word16_toWord32
    val Word_fromWord32X = E.Word32_toWord16
    val Word_toWord32X = E.Word16_toWord32X
    val Word_sub = E.Word16_sub
    val Word_add = E.Word16_add
    val Word_xorb = E.Word16_xorb
    val Word_andb = E.Word16_andb
    val Word_orb = E.Word16_orb
    val Word_lshift_unsafe = E.Word16_lshift_unsafe
    val Word_rshift_unsafe = E.Word16_rshift_unsafe
    val Word_arshift_unsafe = E.Word16_arshift_unsafe
    val Word_div_unsafe = E.Word16_div_unsafe
    val Word_mod_unsafe = E.Word16_mod_unsafe
  )

structure Int32Prim =
  IntPrim(
    val intTy = B.intTy
    val wordTy = B.wordTy
    val numBits_log2 = 5
    val INT = C.INT32
    val WORD = C.WORD32 o Word32.fromInt
    val Int = E.Int32
    val Word = E.Word32
    val Int_lt = E.Int32_lt
    val Int_eq = E.Int32_eq
    val Int_add_unsafe = E.Int32_add_unsafe
    val Int_sub_unsafe = E.Int32_sub_unsafe
    val Int_mul_unsafe = E.Int32_mul_unsafe
    val Int_add_overflowCheck = E.Int32_add_overflowCheck
    val Int_sub_overflowCheck = E.Int32_sub_overflowCheck
    val Int_mul_overflowCheck = E.Int32_mul_overflowCheck
    val Int_quot_unsafe = E.Int32_quot_unsafe
    val Int_rem_unsafe = E.Int32_rem_unsafe
    val Word_fromWord32 = fn x => x
    val Word_toWord32 = fn x => x
    val Word_fromWord32X = fn x => x
    val Word_toWord32X = fn x => x
    val Word_sub = E.Word32_sub
    val Word_add = E.Word32_add
    val Word_xorb = E.Word32_xorb
    val Word_andb = E.Word32_andb
    val Word_orb = E.Word32_orb
    val Word_lshift_unsafe = E.Word32_lshift_unsafe
    val Word_rshift_unsafe = E.Word32_rshift_unsafe
    val Word_arshift_unsafe = E.Word32_arshift_unsafe
    val Word_div_unsafe = E.Word32_div_unsafe
    val Word_mod_unsafe = E.Word32_mod_unsafe
  )

structure Int64Prim =
  IntPrim(
    type i = Int64.int
    val intTy = B.int64Ty
    val wordTy = B.word64Ty
    val numBits_log2 = 6
    val INT = C.INT64 o Int64.fromInt
    val WORD = C.WORD64 o Word64.fromInt
    val Int = E.Int64
    val Word = E.Word64
    val Int_lt = E.Int64_lt
    val Int_eq = E.Int64_eq
    val Int_add_unsafe = E.Int64_add_unsafe
    val Int_sub_unsafe = E.Int64_sub_unsafe
    val Int_mul_unsafe = E.Int64_mul_unsafe
    val Int_add_overflowCheck = E.Int64_add_overflowCheck
    val Int_sub_overflowCheck = E.Int64_sub_overflowCheck
    val Int_mul_overflowCheck = E.Int64_mul_overflowCheck
    val Int_quot_unsafe = E.Int64_quot_unsafe
    val Int_rem_unsafe = E.Int64_rem_unsafe
    val Word_fromWord32 = E.Word32_toWord64
    val Word_toWord32 = E.Word64_toWord32
    val Word_fromWord32X = E.Word32_toWord64X
    val Word_toWord32X = E.Word64_toWord32
    val Word_sub = E.Word64_sub
    val Word_add = E.Word64_add
    val Word_xorb = E.Word64_xorb
    val Word_andb = E.Word64_andb
    val Word_orb = E.Word64_orb
    val Word_lshift_unsafe = E.Word64_lshift_unsafe
    val Word_rshift_unsafe = E.Word64_rshift_unsafe
    val Word_arshift_unsafe = E.Word64_arshift_unsafe
    val Word_div_unsafe = E.Word64_div_unsafe
    val Word_mod_unsafe = E.Word64_mod_unsafe
  )

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
        T.POLYty {boundtvars, constraints, body} => primFunTy boundtvars body
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

      | (P.Real64_notEqual, [arg1, arg2], []) =>
        E.If (E.Real64_equal (arg1, arg2), E.False, E.True)
      | (P.Real64_notEqual, _, _) =>
        raise Bug.Bug "compilePrim: Real64_notEqual"

      | (P.Real32_notEqual, [arg1, arg2], []) =>
        E.If (E.Real32_equal (arg1, arg2), E.False, E.True)
      | (P.Real32_notEqual, _, _) =>
        raise Bug.Bug "compilePrim: Real32_notEqual"

      | (P.Array_alloc, [size], [_]) =>
        E.If (E.Andalso [E.Int32_gteq (size, E.Int32 0),
                         E.Int32_lteq (size, E.Int32 maxArraySize)],
              E.PrimApply ({primitive = P.R P.Array_alloc_unsafe,
                            ty = primTy},
                           instTyList, retTy, [size]),
              E.Raise (B.SizeExExn, retTy))
      | (P.Array_alloc, _, _) =>
        raise Bug.Bug "compilePrim: Array_alloc"

      | (P.String_alloc, [size], []) =>
        E.If (E.Andalso [E.Int32_gteq (size, E.Int32 0),
                         E.Int32_lteq (size, E.Int32 (maxSize - 1))],
              E.String_alloc_unsafe size,
              E.Raise (B.SizeExExn, retTy))
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
                         [E.Int32_gteq (di, E.Int32 0),
                          E.Int32_gteq (E.Var dlen, di),
                          E.Int32_gteq (E.Int32_sub_unsafe (E.Var dlen, di),
                                        E.Var slen)],
                       E.Array_copy_unsafe
                         (ty, src, E.Int32 0, dst, di, E.Var slen),
                       E.Raise (B.SubscriptExExn, retTy)))
        end
      | (P.Array_copy, _, _) =>
        raise Bug.Bug "compilePrim: Array_copy"

      | (P.Array_sub, [ary, index], [ty]) =>
        E.If (E.Andalso [E.Int32_gteq (index, E.Int32 0),
                         E.Int32_lt (index, E.Array_length (ty, ary))],
              E.PrimApply ({primitive = P.Array_sub_unsafe,
                            ty = primTy},
                           instTyList, retTy, [ary, index]),
              E.Raise (B.SubscriptExExn, retTy))
      | (P.Array_sub, _, _) =>
        raise Bug.Bug "compilePrim: Array_sub"

      | (P.Array_update, [ary, index, elem], [ty]) =>
        E.If (E.Andalso [E.Int32_gteq (index, E.Int32 0),
                         E.Int32_lt (index, E.Array_length (ty, ary))],
              E.PrimApply ({primitive = P.Array_update_unsafe,
                            ty = primTy},
                           instTyList, retTy, [ary, index, elem]),
              E.Raise (B.SubscriptExExn, retTy))
      | (P.Array_update, _, _) =>
        raise Bug.Bug "compilePrim: Array_update"

      | (P.String_sub, [ary, index], []) =>
        E.If (E.Andalso [E.Int32_gteq (index, E.Int32 0),
                         E.Int32_lt (index, E.String_size ary)],
              E.String_sub_unsafe (ary, index),
              E.Raise (B.SubscriptExExn, retTy))
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

      | (P.Word8_arshift, [arg1, arg2], []) =>
        Int8Prim.Word_arshift retTy (arg1, arg2)
      | (P.Word8_arshift, _, _) =>
        raise Bug.Bug "compilePrim: Word8_arshift"

      | (P.Word8_div, [arg1, arg2], []) =>
        Int8Prim.Word_div retTy (arg1, arg2)
      | (P.Word8_div, _, _) =>
        raise Bug.Bug "compilePrim: Word8_div"

      | (P.Word8_fromInt32, [arg], []) =>
        Int8Prim.Word_fromInt32_trunc retTy arg
      | (P.Word8_fromInt32, _, _) =>
        raise Bug.Bug "compilePrim: Word8_fromInt32"

      | (P.Word8_lshift, [arg1, arg2], []) =>
        Int8Prim.Word_lshift retTy (arg1, arg2)
      | (P.Word8_lshift, _, _) =>
        raise Bug.Bug "compilePrim: Word8_lshift"

      | (P.Word8_mod, [arg1, arg2], []) =>
        Int8Prim.Word_mod retTy (arg1, arg2)
      | (P.Word8_mod, _, _) =>
        raise Bug.Bug "compilePrim: Word8_mod"

      | (P.Word8_neg, [arg], []) =>
        Int8Prim.Word_neg retTy arg
      | (P.Word8_neg, _, _) =>
        raise Bug.Bug "compilePrim: Word8_neg"

      | (P.Word8_notb, [arg], []) =>
        Int8Prim.Word_notb retTy arg
      | (P.Word8_notb, _, _) =>
        raise Bug.Bug "compilePrim: Word8_notb"

      | (P.Word8_rshift, [arg1, arg2], []) =>
        Int8Prim.Word_rshift retTy (arg1, arg2)
      | (P.Word8_rshift, _, _) =>
        raise Bug.Bug "compilePrim: Word8_rshift"

      | (P.Word8_toInt32, [arg], []) =>
        Int8Prim.Word_toInt32_extend retTy arg
      | (P.Word8_toInt32, _, _) =>
        raise Bug.Bug "compilePrim: Word8_toInt32"

      | (P.Word8_toInt32X, [arg], []) =>
        Int8Prim.Word_toInt32X_extend retTy arg
      | (P.Word8_toInt32X, _, _) =>
        raise Bug.Bug "compilePrim: Word8_toInt32X"

      | (P.Word16_arshift, [arg1, arg2], []) =>
        Int16Prim.Word_arshift retTy (arg1, arg2)
      | (P.Word16_arshift, _, _) =>
        raise Bug.Bug "compilePrim: Word16_arshift"

      | (P.Word16_div, [arg1, arg2], []) =>
        Int16Prim.Word_div retTy (arg1, arg2)
      | (P.Word16_div, _, _) =>
        raise Bug.Bug "compilePrim: Word16_div"

      | (P.Word16_fromInt32, [arg], []) =>
        Int16Prim.Word_fromInt32_trunc retTy arg
      | (P.Word16_fromInt32, _, _) =>
        raise Bug.Bug "compilePrim: Word16_fromInt32"

      | (P.Word16_lshift, [arg1, arg2], []) =>
        Int16Prim.Word_lshift retTy (arg1, arg2)
      | (P.Word16_lshift, _, _) =>
        raise Bug.Bug "compilePrim: Word16_lshift"

      | (P.Word16_mod, [arg1, arg2], []) =>
        Int16Prim.Word_mod retTy (arg1, arg2)
      | (P.Word16_mod, _, _) =>
        raise Bug.Bug "compilePrim: Word16_mod"

      | (P.Word16_neg, [arg], []) =>
        Int16Prim.Word_neg retTy arg
      | (P.Word16_neg, _, _) =>
        raise Bug.Bug "compilePrim: Word16_neg"

      | (P.Word16_notb, [arg], []) =>
        Int16Prim.Word_notb retTy arg
      | (P.Word16_notb, _, _) =>
        raise Bug.Bug "compilePrim: Word16_notb"

      | (P.Word16_rshift, [arg1, arg2], []) =>
        Int16Prim.Word_rshift retTy (arg1, arg2)
      | (P.Word16_rshift, _, _) =>
        raise Bug.Bug "compilePrim: Word16_rshift"

      | (P.Word16_toInt32, [arg], []) =>
        Int16Prim.Word_toInt32_extend retTy arg
      | (P.Word16_toInt32, _, _) =>
        raise Bug.Bug "compilePrim: Word16_toInt32"

      | (P.Word16_toInt32X, [arg], []) =>
        Int16Prim.Word_toInt32X_extend retTy arg
      | (P.Word16_toInt32X, _, _) =>
        raise Bug.Bug "compilePrim: Word16_toInt32X"

      | (P.Word32_arshift, [arg1, arg2], []) =>
        Int32Prim.Word_arshift retTy (arg1, arg2)
      | (P.Word32_arshift, _, _) =>
        raise Bug.Bug "compilePrim: Word32_arshift"

      | (P.Word32_div, [arg1, arg2], []) =>
        Int32Prim.Word_div retTy (arg1, arg2)
      | (P.Word32_div, _, _) =>
        raise Bug.Bug "compilePrim: Word32_div"

      | (P.Word32_lshift, [arg1, arg2], []) =>
        Int32Prim.Word_lshift retTy (arg1, arg2)
      | (P.Word32_lshift, _, _) =>
        raise Bug.Bug "compilePrim: Word32_lshift"

      | (P.Word32_mod, [arg1, arg2], []) =>
        Int32Prim.Word_mod retTy (arg1, arg2)
      | (P.Word32_mod, _, _) =>
        raise Bug.Bug "compilePrim: Word32_mod"

      | (P.Word32_neg, [arg], []) =>
        Int32Prim.Word_neg retTy arg
      | (P.Word32_neg, _, _) =>
        raise Bug.Bug "compilePrim: Word32_neg"

      | (P.Word32_notb, [arg], []) =>
        Int32Prim.Word_notb retTy arg
      | (P.Word32_notb, _, _) =>
        raise Bug.Bug "compilePrim: Word32_notb"

      | (P.Word32_rshift, [arg1, arg2], []) =>
        Int32Prim.Word_rshift retTy (arg1, arg2)
      | (P.Word32_rshift, _, _) =>
        raise Bug.Bug "compilePrim: Word32_rshift"

      | (P.Word32_toInt32, [arg], []) =>
        Int32Prim.Word_toInt32_trunc retTy arg
      | (P.Word32_toInt32, _, _) =>
        raise Bug.Bug "compilePrim: Word32_toInt32"

      | (P.Word64_arshift, [arg1, arg2], []) =>
        Int64Prim.Word_arshift retTy (arg1, arg2)
      | (P.Word64_arshift, _, _) =>
        raise Bug.Bug "compilePrim: Word64_arshift"

      | (P.Word64_div, [arg1, arg2], []) =>
        Int64Prim.Word_div retTy (arg1, arg2)
      | (P.Word64_div, _, _) =>
        raise Bug.Bug "compilePrim: Word64_div"

      | (P.Word64_fromInt32, [arg], []) =>
        Int64Prim.Word_fromInt32_trunc retTy arg
      | (P.Word64_fromInt32, _, _) =>
        raise Bug.Bug "compilePrim: Word16_fromInt32"

      | (P.Word64_lshift, [arg1, arg2], []) =>
        Int64Prim.Word_lshift retTy (arg1, arg2)
      | (P.Word64_lshift, _, _) =>
        raise Bug.Bug "compilePrim: Word64_lshift"

      | (P.Word64_mod, [arg1, arg2], []) =>
        Int64Prim.Word_mod retTy (arg1, arg2)
      | (P.Word64_mod, _, _) =>
        raise Bug.Bug "compilePrim: Word64_mod"

      | (P.Word64_neg, [arg], []) =>
        Int64Prim.Word_neg retTy arg
      | (P.Word64_neg, _, _) =>
        raise Bug.Bug "compilePrim: Word64_neg"

      | (P.Word64_notb, [arg], []) =>
        Int64Prim.Word_notb retTy arg
      | (P.Word64_notb, _, _) =>
        raise Bug.Bug "compilePrim: Word64_notb"

      | (P.Word64_rshift, [arg1, arg2], []) =>
        Int64Prim.Word_rshift retTy (arg1, arg2)
      | (P.Word64_rshift, _, _) =>
        raise Bug.Bug "compilePrim: Word64_rshift"

      | (P.Word64_toInt32, [arg], []) =>
        Int64Prim.Word_toInt32_trunc retTy arg
      | (P.Word64_toInt32, _, _) =>
        raise Bug.Bug "compilePrim: Word64_toInt32"

      | (P.Word64_toInt32X, [arg], []) =>
        Int64Prim.Word_toInt32X_trunc retTy arg
      | (P.Word64_toInt32X, _, _) =>
        raise Bug.Bug "compilePrim: Word64_toInt32X"

      | (P.Int8_abs, [arg], []) =>
        Int8Prim.Int_abs retTy arg
      | (P.Int8_abs, _, _) =>
        raise Bug.Bug "compilePrim: Int8_abs"

      | (P.Int8_add, [arg1, arg2], []) =>
        Int8Prim.Int_add retTy (arg1, arg2)
      | (P.Int8_add, _, _) =>
        raise Bug.Bug "compilePrim: Int8_add"

      | (P.Int8_div, [arg1, arg2], []) =>
        Int8Prim.Int_div retTy (arg1, arg2)
      | (P.Int8_div, _, _) =>
        raise Bug.Bug "compilePrim: Int8_div"

      | (P.Int8_fromInt32, [arg], []) =>
        Int8Prim.Int_fromInt32_trunc retTy arg
      | (P.Int8_fromInt32, _, _) =>
        raise Bug.Bug "compilePrim: Int8_fromInt32"

      | (P.Int8_mod, [arg1, arg2], []) =>
        Int8Prim.Int_mod retTy (arg1, arg2)
      | (P.Int8_mod, _, _) =>
        raise Bug.Bug "compilePrim: Int8_mod"

      | (P.Int8_mul, [arg1, arg2], []) =>
        Int8Prim.Int_mul retTy (arg1, arg2)
      | (P.Int8_mul, _, _) =>
        raise Bug.Bug "compilePrim: Int8_mul"

      | (P.Int8_neg, [arg], []) =>
        Int8Prim.Int_neg retTy arg
      | (P.Int8_neg, _, _) =>
        raise Bug.Bug "compilePrim: Int8_neg"

      | (P.Int8_quot, [arg1, arg2], []) =>
        Int8Prim.Int_quot retTy (arg1, arg2)
      | (P.Int8_quot, _, _) =>
        raise Bug.Bug "compilePrim: Int8_quot"

      | (P.Int8_rem, [arg1, arg2], []) =>
        Int8Prim.Int_rem retTy (arg1, arg2)
      | (P.Int8_rem, _, _) =>
        raise Bug.Bug "compilePrim: Int8_rem"

      | (P.Int8_sub, [arg1, arg2], []) =>
        Int8Prim.Int_sub retTy (arg1, arg2)
      | (P.Int8_sub, _, _) =>
        raise Bug.Bug "compilePrim: Int8_sub"

      | (P.Int8_toInt32, [arg], []) =>
        Int8Prim.Int_toInt32_extend retTy arg
      | (P.Int8_toInt32, _, _) =>
        raise Bug.Bug "compilePrim: Int8_toInt32"

      | (P.Int16_abs, [arg], []) =>
        Int16Prim.Int_abs retTy arg
      | (P.Int16_abs, _, _) =>
        raise Bug.Bug "compilePrim: Int16_abs"

      | (P.Int16_add, [arg1, arg2], []) =>
        Int16Prim.Int_add retTy (arg1, arg2)
      | (P.Int16_add, _, _) =>
        raise Bug.Bug "compilePrim: Int16_add"

      | (P.Int16_div, [arg1, arg2], []) =>
        Int16Prim.Int_div retTy (arg1, arg2)
      | (P.Int16_div, _, _) =>
        raise Bug.Bug "compilePrim: Int16_div"

      | (P.Int16_fromInt32, [arg], []) =>
        Int16Prim.Int_fromInt32_trunc retTy arg
      | (P.Int16_fromInt32, _, _) =>
        raise Bug.Bug "compilePrim: Int16_fromInt32"

      | (P.Int16_mod, [arg1, arg2], []) =>
        Int16Prim.Int_mod retTy (arg1, arg2)
      | (P.Int16_mod, _, _) =>
        raise Bug.Bug "compilePrim: Int16_mod"

      | (P.Int16_mul, [arg1, arg2], []) =>
        Int16Prim.Int_mul retTy (arg1, arg2)
      | (P.Int16_mul, _, _) =>
        raise Bug.Bug "compilePrim: Int16_mul"

      | (P.Int16_neg, [arg], []) =>
        Int16Prim.Int_neg retTy arg
      | (P.Int16_neg, _, _) =>
        raise Bug.Bug "compilePrim: Int16_neg"

      | (P.Int16_quot, [arg1, arg2], []) =>
        Int16Prim.Int_quot retTy (arg1, arg2)
      | (P.Int16_quot, _, _) =>
        raise Bug.Bug "compilePrim: Int16_quot"

      | (P.Int16_rem, [arg1, arg2], []) =>
        Int16Prim.Int_rem retTy (arg1, arg2)
      | (P.Int16_rem, _, _) =>
        raise Bug.Bug "compilePrim: Int16_rem"

      | (P.Int16_sub, [arg1, arg2], []) =>
        Int16Prim.Int_sub retTy (arg1, arg2)
      | (P.Int16_sub, _, _) =>
        raise Bug.Bug "compilePrim: Int16_sub"

      | (P.Int16_toInt32, [arg], []) =>
        Int16Prim.Int_toInt32_extend retTy arg
      | (P.Int16_toInt32, _, _) =>
        raise Bug.Bug "compilePrim: Int16_toInt32"

      | (P.Int32_abs, [arg], []) =>
        Int32Prim.Int_abs retTy arg
      | (P.Int32_abs, _, _) =>
        raise Bug.Bug "compilePrim: Int32_abs"

      | (P.Int32_add, [arg1, arg2], []) =>
        Int32Prim.Int_add retTy (arg1, arg2)
      | (P.Int32_add, _, _) =>
        raise Bug.Bug "compilePrim: Int32_add"

      | (P.Int32_div, [arg1, arg2], []) =>
        Int32Prim.Int_div retTy (arg1, arg2)
      | (P.Int32_div, _, _) =>
        raise Bug.Bug "compilePrim: Int32_div"

      | (P.Int32_mod, [arg1, arg2], []) =>
        Int32Prim.Int_mod retTy (arg1, arg2)
      | (P.Int32_mod, _, _) =>
        raise Bug.Bug "compilePrim: Int32_mod"

      | (P.Int32_mul, [arg1, arg2], []) =>
        Int32Prim.Int_mul retTy (arg1, arg2)
      | (P.Int32_mul, _, _) =>
        raise Bug.Bug "compilePrim: Int32_mul"

      | (P.Int32_neg, [arg], []) =>
        Int32Prim.Int_neg retTy arg
      | (P.Int32_neg, _, _) =>
        raise Bug.Bug "compilePrim: Int32_neg"

      | (P.Int32_quot, [arg1, arg2], []) =>
        Int32Prim.Int_quot retTy (arg1, arg2)
      | (P.Int32_quot, _, _) =>
        raise Bug.Bug "compilePrim: Int32_quot"

      | (P.Int32_rem, [arg1, arg2], []) =>
        Int32Prim.Int_rem retTy (arg1, arg2)
      | (P.Int32_rem, _, _) =>
        raise Bug.Bug "compilePrim: Int32_rem"

      | (P.Int32_sub, [arg1, arg2], []) =>
        Int32Prim.Int_sub retTy (arg1, arg2)
      | (P.Int32_sub, _, _) =>
        raise Bug.Bug "compilePrim: Int32_sub"

      | (P.Int64_abs, [arg], []) =>
        Int64Prim.Int_abs retTy arg
      | (P.Int64_abs, _, _) =>
        raise Bug.Bug "compilePrim: Int64_abs"

      | (P.Int64_add, [arg1, arg2], []) =>
        Int64Prim.Int_add retTy (arg1, arg2)
      | (P.Int64_add, _, _) =>
        raise Bug.Bug "compilePrim: Int64_add"

      | (P.Int64_div, [arg1, arg2], []) =>
        Int64Prim.Int_div retTy (arg1, arg2)
      | (P.Int64_div, _, _) =>
        raise Bug.Bug "compilePrim: Int64_div"

      | (P.Int64_fromInt32, [arg], []) =>
        Int64Prim.Int_fromInt32_extend retTy arg
      | (P.Int64_fromInt32, _, _) =>
        raise Bug.Bug "compilePrim: Int64_fromInt32"

      | (P.Int64_mod, [arg1, arg2], []) =>
        Int64Prim.Int_mod retTy (arg1, arg2)
      | (P.Int64_mod, _, _) =>
        raise Bug.Bug "compilePrim: Int64_mod"

      | (P.Int64_mul, [arg1, arg2], []) =>
        Int64Prim.Int_mul retTy (arg1, arg2)
      | (P.Int64_mul, _, _) =>
        raise Bug.Bug "compilePrim: Int64_mul"

      | (P.Int64_neg, [arg], []) =>
        Int64Prim.Int_neg retTy arg
      | (P.Int64_neg, _, _) =>
        raise Bug.Bug "compilePrim: Int64_neg"

      | (P.Int64_quot, [arg1, arg2], []) =>
        Int64Prim.Int_quot retTy (arg1, arg2)
      | (P.Int64_quot, _, _) =>
        raise Bug.Bug "compilePrim: Int64_quot"

      | (P.Int64_rem, [arg1, arg2], []) =>
        Int64Prim.Int_rem retTy (arg1, arg2)
      | (P.Int64_rem, _, _) =>
        raise Bug.Bug "compilePrim: Int64_rem"

      | (P.Int64_sub, [arg1, arg2], []) =>
        Int64Prim.Int_sub retTy (arg1, arg2)
      | (P.Int64_sub, _, _) =>
        raise Bug.Bug "compilePrim: Int64_sub"

      | (P.Int64_toInt32, [arg], []) =>
        Int64Prim.Int_toInt32_trunc retTy arg
      | (P.Int64_toInt32, _, _) =>
        raise Bug.Bug "compilePrim: Int64_toInt32"

      | (P.Char_chr, [arg], []) =>
        E.If (E.Andalso [E.Int32_gteq (arg, E.Int32 0),
                         E.Int32_lteq (arg, E.Int32 maxChar)],
              E.Cast (E.Word32_toWord8 (E.Word32_fromInt32 arg), B.charTy),
              E.Raise (B.ChrExExn, retTy))
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

      | (P.Real64_neg, [arg], []) =>
        E.Real64_sub (E.Real64 0, arg)
      | (P.Real64_neg, _, _) =>
        raise Bug.Bug "compilePrim: Real64_neg"

      | (P.Real32_neg, [arg], []) =>
        E.Real32_sub (E.Real32 0, arg)
      | (P.Real32_neg, _, _) =>
        raise Bug.Bug "compilePrim: Real32_neg"

      | (P.Real32_trunc, [arg], []) =>
        E.If (E.Real32_isNan arg,
              E.Raise (B.DomainExExn, retTy),
              E.If (E.Andalso [E.Real32_gteq (arg, E.Real32 minInt),
                               E.Real32_lteq (arg, E.Real32 maxInt)],
                    E.PrimApply ({primitive = P.R (P.M P.Real32_toInt32_unsafe),
                                  ty = primTy},
                                 instTyList, retTy, [arg]),
                    E.Raise (B.OverflowExExn, retTy)))
      | (P.Real32_trunc, _, _) =>
        raise Bug.Bug "compilePrim: Real32_trunc"

      | (P.Real64_trunc, [arg], []) =>
        E.If (E.Real64_isNan arg,
              E.Raise (B.DomainExExn, retTy),
              E.If (E.Andalso [E.Real64_gteq (arg, E.Real64 minInt),
                               E.Real64_lteq (arg, E.Real64 maxInt)],
                    E.PrimApply ({primitive = P.R (P.M P.Real64_toInt32_unsafe),
                                  ty = primTy},
                                 instTyList, retTy, [arg]),
                    E.Raise (B.OverflowExExn, retTy)))
      | (P.Real64_trunc, _, _) =>
        raise Bug.Bug "compilePrim: Real64_trunc"

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
              E.Word32 0,
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
