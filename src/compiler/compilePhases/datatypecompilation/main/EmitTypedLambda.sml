(**
 * Support for building typed lambda terms
 *
 * @copyright (c) 2013, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure EmitTypedLambda =
struct

  structure L = TypedLambda
  structure T = Types
  structure P = BuiltinPrimitive
  structure B = BuiltinTypes
  structure C = ConstantTerm

  type vid = VarID.id

  val newId = VarID.generate

  datatype exp =
      Exp of TypedLambda.tlexp * Types.ty
    | Int8 of int
    | Int16 of int
    | Int32 of int
    | Int64 of int
    | Word8 of int
    | Word16 of int
    | Word32 of int
    | Word64 of int
    | Char of int
    | ConTag of int
    | Real64 of int
    | Real32 of int
    | String of string
    | Unit
    | Null
    | True
    | False
    | SizeOf of Types.ty
    | IndexOf of Types.ty * RecordLabel.label
    | ExVar of RecordCalc.exVarInfo
    | Cast of exp * Types.ty
    | RuntimeTyCast of exp * Types.ty
    | BitCast of exp * Types.ty
    | PrimApply of TypedLambda.primInfo * Types.ty list * Types.ty * exp list
    | If of exp * exp * exp
    | Andalso of exp list
    | Switch of exp * (ConstantTerm.constant * exp) list * exp
    | Raise of RecordCalc.exExnInfo * Types.ty
    | Fn of vid * Types.ty * exp
    | App of exp * exp
    | Let of (vid * exp) list * exp
    | Var of vid
    | TLLet of decl list * exp
    | TLVar of TypedLambda.varInfo
    | Record of RecordLabel.label list * exp list
    | Select of RecordLabel.label * exp
  and decl =
      Decl of TypedLambda.tldecl * TypedLambda.loc
    | Bind of TypedLambda.varInfo * exp

  fun isAtomic exp =
      case exp of
        L.TLFOREIGNAPPLY _ => false
      | L.TLCALLBACKFN _ => false
      | L.TLSIZEOF _ => true
      | L.TLTAGOF _ => true
      | L.TLINDEXOF _ => true
      | L.TLCONSTANT _ => true
      | L.TLFOREIGNSYMBOL _ => true
      | L.TLVAR _ => true
      | L.TLEXVAR _ => false
      | L.TLPRIMAPPLY _ => false
      | L.TLAPPM _ => false
      | L.TLLET _ => false
      | L.TLRECORD _ => false
      | L.TLSELECT _ => false
      | L.TLMODIFY _ => false
      | L.TLRAISE _ => false
      | L.TLHANDLE _ => false
      | L.TLSWITCH _ => false
      | L.TLCATCH _ => false
      | L.TLTHROW _ => false
      | L.TLFNM _ => false
      | L.TLPOLY _ => false
      | L.TLTAPP _ => false
      | L.TLCAST {exp, expTy, targetTy, cast, loc} => isAtomic exp
      | L.TLDUMP _ => false

  fun Tuple exps =
      Record (ListPair.unzip (RecordLabel.tupleList exps))

  fun SelectN (n, exp) =
      Select (RecordLabel.fromInt n, exp)

  fun arrayTy ty =
      T.CONSTRUCTty {tyCon = B.arrayTyCon, args = [ty]}
  fun vectorTy ty =
      T.CONSTRUCTty {tyCon = B.vectorTyCon, args = [ty]}
  fun refTy ty =
      T.CONSTRUCTty {tyCon = B.refTyCon, args = [ty]}
  fun tupleTy tys =
      T.RECORDty (RecordLabel.tupleMap tys)

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

  fun polyPrimApp (prim, argTys, retTy, instTy, args) =
      let
        val tid = BoundTypeVarID.generate ()
        val univKind = #kind Types.univKind
        val btvEnv = BoundTypeVarID.Map.singleton (tid, univKind)
        val btvTy = T.BOUNDVARty tid
      in
        PrimApply ({primitive = prim,
                    ty = {boundtvars = btvEnv,
                          argTyList = argTys btvTy,
                          resultTy = retTy btvTy}},
                    [instTy],
                    retTy instTy,
                    args)
      end

  fun monoPrimApp (prim, argTys, retTy, args) =
      PrimApply ({primitive = prim,
                  ty = {boundtvars = BoundTypeVarID.Map.empty,
                        argTyList = argTys,
                        resultTy = retTy}},
                 nil,
                 retTy,
                 args)

  fun IdentityEqual (ty, exp1, exp2) =
      monoPrimApp (P.R (P.M P.IdentityEqual),
                   [ty, ty], B.boolTy,
                   [exp1, exp2])

  fun IsNull exp1 =
      IdentityEqual (B.boxedTy, exp1, Null)

  fun op2 prim intTy (exp1, exp2) =
      monoPrimApp (P.R (P.M prim), [intTy, intTy], intTy, [exp1, exp2])
  fun cmp prim intTy (exp1, exp2) =
      monoPrimApp (P.R (P.M prim), [intTy, intTy], B.boolTy, [exp1, exp2])

  fun Int8_eq (exp1, exp2) = IdentityEqual (B.int8Ty, exp1, exp2)
  fun Int8_gt x = cmp P.Int8_gt B.int8Ty x
  fun Int8_lt x = cmp P.Int8_lt B.int8Ty x
  fun Int8_gteq x = cmp P.Int8_gteq B.int8Ty x
  fun Int8_lteq x = cmp P.Int8_lteq B.int8Ty x
  fun Int8_quot_unsafe x = op2 P.Int8_quot_unsafe B.int8Ty x
  fun Int8_rem_unsafe x = op2 P.Int8_rem_unsafe B.int8Ty x
  fun Int8_sub_unsafe x = op2 P.Int8_sub_unsafe B.int8Ty x
  fun Int8_add_unsafe x = op2 P.Int8_add_unsafe B.int8Ty x
  fun Int8_mul_unsafe x = op2 P.Int8_mul_unsafe B.int8Ty x
  fun Int8_sub_overflowCheck x = cmp P.Int8_sub_overflowCheck B.int8Ty x
  fun Int8_add_overflowCheck x = cmp P.Int8_add_overflowCheck B.int8Ty x
  fun Int8_mul_overflowCheck x = cmp P.Int8_mul_overflowCheck B.int8Ty x

  fun Int16_eq (exp1, exp2) = IdentityEqual (B.int16Ty, exp1, exp2)
  fun Int16_gt x = cmp P.Int16_gt B.int16Ty x
  fun Int16_lt x = cmp P.Int16_lt B.int16Ty x
  fun Int16_gteq x = cmp P.Int16_gteq B.int16Ty x
  fun Int16_lteq x = cmp P.Int16_lteq B.int16Ty x
  fun Int16_quot_unsafe x = op2 P.Int16_quot_unsafe B.int16Ty x
  fun Int16_rem_unsafe x = op2 P.Int16_rem_unsafe B.int16Ty x
  fun Int16_sub_unsafe x = op2 P.Int16_sub_unsafe B.int16Ty x
  fun Int16_add_unsafe x = op2 P.Int16_add_unsafe B.int16Ty x
  fun Int16_mul_unsafe x = op2 P.Int16_mul_unsafe B.int16Ty x
  fun Int16_sub_overflowCheck x = cmp P.Int16_sub_overflowCheck B.int16Ty x
  fun Int16_add_overflowCheck x = cmp P.Int16_add_overflowCheck B.int16Ty x
  fun Int16_mul_overflowCheck x = cmp P.Int16_mul_overflowCheck B.int16Ty x

  fun Int32_eq (exp1, exp2) = IdentityEqual (B.intTy, exp1, exp2)
  fun Int32_gt x = cmp P.Int32_gt B.intTy x
  fun Int32_lt x = cmp P.Int32_lt B.intTy x
  fun Int32_gteq x = cmp P.Int32_gteq B.intTy x
  fun Int32_lteq x = cmp P.Int32_lteq B.intTy x
  fun Int32_quot_unsafe x = op2 P.Int32_quot_unsafe B.intTy x
  fun Int32_rem_unsafe x = op2 P.Int32_rem_unsafe B.intTy x
  fun Int32_sub_unsafe x = op2 P.Int32_sub_unsafe B.intTy x
  fun Int32_add_unsafe x = op2 P.Int32_add_unsafe B.intTy x
  fun Int32_mul_unsafe x = op2 P.Int32_mul_unsafe B.intTy x
  fun Int32_sub_overflowCheck x = cmp P.Int32_sub_overflowCheck B.intTy x
  fun Int32_add_overflowCheck x = cmp P.Int32_add_overflowCheck B.intTy x
  fun Int32_mul_overflowCheck x = cmp P.Int32_mul_overflowCheck B.intTy x

  fun Int64_eq (exp1, exp2) = IdentityEqual (B.int64Ty, exp1, exp2)
  fun Int64_gt x = cmp P.Int64_gt B.int64Ty x
  fun Int64_lt x = cmp P.Int64_lt B.int64Ty x
  fun Int64_gteq x = cmp P.Int64_gteq B.int64Ty x
  fun Int64_lteq x = cmp P.Int64_lteq B.int64Ty x
  fun Int64_quot_unsafe x = op2 P.Int64_quot_unsafe B.int64Ty x
  fun Int64_rem_unsafe x = op2 P.Int64_rem_unsafe B.int64Ty x
  fun Int64_sub_unsafe x = op2 P.Int64_sub_unsafe B.int64Ty x
  fun Int64_add_unsafe x = op2 P.Int64_add_unsafe B.int64Ty x
  fun Int64_mul_unsafe x = op2 P.Int64_mul_unsafe B.int64Ty x
  fun Int64_sub_overflowCheck x = cmp P.Int64_sub_overflowCheck B.int64Ty x
  fun Int64_add_overflowCheck x = cmp P.Int64_add_overflowCheck B.int64Ty x
  fun Int64_mul_overflowCheck x = cmp P.Int64_mul_overflowCheck B.int64Ty x

  fun Word8_gt x = cmp P.Word8_gt B.word8Ty x
  fun Word8_lt x = cmp P.Word8_lt B.word8Ty x
  fun Word8_gteq x = cmp P.Word8_gteq B.word8Ty x
  fun Word8_lteq x = cmp P.Word8_lteq B.word8Ty x
  fun Word8_div_unsafe x = op2 P.Word8_div_unsafe B.word8Ty x
  fun Word8_mod_unsafe x = op2 P.Word8_mod_unsafe B.word8Ty x
  fun Word8_sub x = op2 P.Word8_sub B.word8Ty x
  fun Word8_add x = op2 P.Word8_add B.word8Ty x
  fun Word8_orb x = op2 P.Word8_orb B.word8Ty x
  fun Word8_xorb x = op2 P.Word8_xorb B.word8Ty x
  fun Word8_andb x = op2 P.Word8_andb B.word8Ty x
  fun Word8_arshift_unsafe x = op2 P.Word8_arshift_unsafe B.word8Ty x
  fun Word8_rshift_unsafe x = op2 P.Word8_rshift_unsafe B.word8Ty x
  fun Word8_lshift_unsafe x = op2 P.Word8_lshift_unsafe B.word8Ty x

  fun Word16_gt x = cmp P.Word16_gt B.word16Ty x
  fun Word16_lt x = cmp P.Word16_lt B.word16Ty x
  fun Word16_gteq x = cmp P.Word16_gteq B.word16Ty x
  fun Word16_lteq x = cmp P.Word16_lteq B.word16Ty x
  fun Word16_div_unsafe x = op2 P.Word16_div_unsafe B.word16Ty x
  fun Word16_mod_unsafe x = op2 P.Word16_mod_unsafe B.word16Ty x
  fun Word16_sub x = op2 P.Word16_sub B.word16Ty x
  fun Word16_add x = op2 P.Word16_add B.word16Ty x
  fun Word16_orb x = op2 P.Word16_orb B.word16Ty x
  fun Word16_xorb x = op2 P.Word16_xorb B.word16Ty x
  fun Word16_andb x = op2 P.Word16_andb B.word16Ty x
  fun Word16_arshift_unsafe x = op2 P.Word16_arshift_unsafe B.word16Ty x
  fun Word16_rshift_unsafe x = op2 P.Word16_rshift_unsafe B.word16Ty x
  fun Word16_lshift_unsafe x = op2 P.Word16_lshift_unsafe B.word16Ty x

  fun Word32_gt x = cmp P.Word32_gt B.wordTy x
  fun Word32_lt x = cmp P.Word32_lt B.wordTy x
  fun Word32_gteq x = cmp P.Word32_gteq B.wordTy x
  fun Word32_lteq x = cmp P.Word32_lteq B.wordTy x
  fun Word32_div_unsafe x = op2 P.Word32_div_unsafe B.wordTy x
  fun Word32_mod_unsafe x = op2 P.Word32_mod_unsafe B.wordTy x
  fun Word32_sub x = op2 P.Word32_sub B.wordTy x
  fun Word32_add x = op2 P.Word32_add B.wordTy x
  fun Word32_orb x = op2 P.Word32_orb B.wordTy x
  fun Word32_xorb x = op2 P.Word32_xorb B.wordTy x
  fun Word32_andb x = op2 P.Word32_andb B.wordTy x
  fun Word32_arshift_unsafe x = op2 P.Word32_arshift_unsafe B.wordTy x
  fun Word32_rshift_unsafe x = op2 P.Word32_rshift_unsafe B.wordTy x
  fun Word32_lshift_unsafe x = op2 P.Word32_lshift_unsafe B.wordTy x

  fun Word64_gt x = cmp P.Word64_gt B.word64Ty x
  fun Word64_lt x = cmp P.Word64_lt B.word64Ty x
  fun Word64_gteq x = cmp P.Word64_gteq B.word64Ty x
  fun Word64_lteq x = cmp P.Word64_lteq B.word64Ty x
  fun Word64_div_unsafe x = op2 P.Word64_div_unsafe B.word64Ty x
  fun Word64_mod_unsafe x = op2 P.Word64_mod_unsafe B.word64Ty x
  fun Word64_sub x = op2 P.Word64_sub B.word64Ty x
  fun Word64_add x = op2 P.Word64_add B.word64Ty x
  fun Word64_orb x = op2 P.Word64_orb B.word64Ty x
  fun Word64_xorb x = op2 P.Word64_xorb B.word64Ty x
  fun Word64_andb x = op2 P.Word64_andb B.word64Ty x
  fun Word64_arshift_unsafe x = op2 P.Word64_arshift_unsafe B.word64Ty x
  fun Word64_rshift_unsafe x = op2 P.Word64_rshift_unsafe B.word64Ty x
  fun Word64_lshift_unsafe x = op2 P.Word64_lshift_unsafe B.word64Ty x

  fun Word8_toWord16 exp1 =
      monoPrimApp (P.R (P.M P.Word8_toWord16),
                   [B.word8Ty], B.word16Ty,
                   [exp1])

  fun Word8_toWord16X exp1 =
      monoPrimApp (P.R (P.M P.Word8_toWord16X),
                   [B.word8Ty], B.word16Ty,
                   [exp1])

  fun Word8_toWord32 exp1 =
      monoPrimApp (P.R (P.M P.Word8_toWord32),
                   [B.word8Ty], B.wordTy,
                   [exp1])

  fun Word8_toWord32X exp1 =
      monoPrimApp (P.R (P.M P.Word8_toWord32X),
                   [B.word8Ty], B.wordTy,
                   [exp1])

  fun Word8_toWord64 exp1 =
      monoPrimApp (P.R (P.M P.Word8_toWord64),
                   [B.word8Ty], B.word64Ty,
                   [exp1])

  fun Word8_toWord64X exp1 =
      monoPrimApp (P.R (P.M P.Word8_toWord64X),
                   [B.word8Ty], B.word64Ty,
                   [exp1])

  fun Word16_toWord8 exp1 =
      monoPrimApp (P.R (P.M P.Word16_toWord8),
                   [B.word16Ty], B.word8Ty,
                   [exp1])

  fun Word16_toWord32 exp1 =
      monoPrimApp (P.R (P.M P.Word16_toWord32),
                   [B.word16Ty], B.wordTy,
                   [exp1])

  fun Word16_toWord32X exp1 =
      monoPrimApp (P.R (P.M P.Word16_toWord32X),
                   [B.word16Ty], B.wordTy,
                   [exp1])

  fun Word16_toWord64 exp1 =
      monoPrimApp (P.R (P.M P.Word16_toWord64),
                   [B.word16Ty], B.word64Ty,
                   [exp1])

  fun Word16_toWord64X exp1 =
      monoPrimApp (P.R (P.M P.Word16_toWord64X),
                   [B.word16Ty], B.word64Ty,
                   [exp1])

  fun Word32_toWord8 exp1 =
      monoPrimApp (P.R (P.M P.Word32_toWord8),
                   [B.wordTy], B.word8Ty,
                   [exp1])

  fun Word32_toWord16 exp1 =
      monoPrimApp (P.R (P.M P.Word32_toWord16),
                   [B.wordTy], B.word16Ty,
                   [exp1])

  fun Word32_toWord64 exp =
      monoPrimApp (P.R (P.M P.Word32_toWord64),
                   [B.wordTy], B.word64Ty,
                   [exp])

  fun Word32_toWord64X exp =
      monoPrimApp (P.R (P.M P.Word32_toWord64X),
                   [B.wordTy], B.word64Ty,
                   [exp])

  fun Word64_toWord8 exp1 =
      monoPrimApp (P.R (P.M P.Word64_toWord8),
                   [B.word64Ty], B.word8Ty,
                   [exp1])

  fun Word64_toWord16 exp1 =
      monoPrimApp (P.R (P.M P.Word64_toWord16),
                   [B.word64Ty], B.word16Ty,
                   [exp1])

  fun Word64_toWord32 exp =
      monoPrimApp (P.R (P.M P.Word64_toWord32),
                   [B.word64Ty], B.wordTy,
                   [exp])

  fun Word32_fromInt32 exp =
      RuntimeTyCast (exp, B.wordTy)

  fun Word32_toInt32X exp =
      RuntimeTyCast (exp, B.intTy)

  fun Real32_isNan exp1 =
      monoPrimApp (P.R (P.M P.Real32_isNan),
                   [B.real32Ty], B.boolTy,
                   [exp1])

  fun Real32_equal (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Real32_equal),
(* bug 303_Real32NotEqual
                   [B.realTy, B.realTy], B.boolTy,*)
                   [B.real32Ty, B.real32Ty], B.boolTy,
                   [exp1, exp2])

  fun Real32_gteq (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Real32_gteq),
                   [B.real32Ty, B.real32Ty], B.boolTy,
                   [exp1, exp2])

  fun Real32_lteq (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Real32_lteq),
                   [B.real32Ty, B.real32Ty], B.boolTy,
                   [exp1, exp2])

  fun Real32_sub (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Real32_sub),
                   [B.real32Ty, B.real32Ty], B.real32Ty,
                   [exp1, exp2])

  fun Real32_toInt32_unsafe exp =
      monoPrimApp (P.R (P.M P.Real32_toInt32_unsafe),
                   [B.real32Ty], B.intTy,
                   [exp])

  fun Real64_isNan exp1 =
      monoPrimApp (P.R (P.M P.Real64_isNan),
                   [B.realTy], B.boolTy,
                   [exp1])

  fun Real64_equal (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Real64_equal),
                   [B.realTy, B.realTy], B.boolTy,
                   [exp1, exp2])

  fun Real64_gteq (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Real64_gteq),
                   [B.realTy, B.realTy], B.boolTy,
                   [exp1, exp2])

  fun Real64_lteq (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Real64_lteq),
                   [B.realTy, B.realTy], B.boolTy,
                   [exp1, exp2])

  fun Real64_sub (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Real64_sub),
                   [B.realTy, B.realTy], B.realTy,
                   [exp1, exp2])

  fun Real64_toInt32_unsafe exp =
      monoPrimApp (P.R (P.M P.Real64_toInt32_unsafe),
                   [B.realTy], B.intTy,
                   [exp])

  fun ObjectSize (ty, exp) =
      monoPrimApp (P.R (P.M P.ObjectSize),
                   [ty], B.wordTy,
                   [exp])

  fun Array_turnIntoVector (elemTy, aryExp) =
      polyPrimApp (P.R (P.M P.Array_turnIntoVector),
                   fn t => [arrayTy t],
                   fn t => vectorTy t,
                   elemTy,
                   [aryExp])

  fun Array_alloc_unsafe (elemTy, lenExp) =
      polyPrimApp (P.R P.Array_alloc_unsafe,
                   fn t => [B.intTy], fn t => arrayTy t,
                   elemTy,
                   [lenExp])

  fun Array_alloc_init (elemTy, elems) =
      polyPrimApp (P.Array_alloc_init,
                   fn t => List.tabulate (length elems, fn _ => t),
                   fn t => arrayTy t,
                   elemTy,
                   elems)

  fun Vector_alloc_init (elemTy, elems) =
      polyPrimApp (P.Vector_alloc_init,
                   fn t => List.tabulate (length elems, fn _ => t),
                   fn t => arrayTy t,
                   elemTy,
                   elems)

  fun Vector_alloc_init_fresh (elemTy, elems) =
      polyPrimApp (P.Vector_alloc_init_fresh,
                   fn t => List.tabulate (length elems, fn _ => t),
                   fn t => arrayTy t,
                   elemTy,
                   elems)

  fun Array_length (elemTy, exp1) =
      Word32_toInt32X (Word32_div_unsafe (ObjectSize (arrayTy elemTy, exp1),
                                          Cast (SizeOf elemTy, B.wordTy)))

  fun Array_sub_unsafe (elemTy, arrayExp, indexExp) =
      polyPrimApp (P.Array_sub_unsafe,
                   fn t => [arrayTy t, B.intTy],
                   fn t => t,
                   elemTy,
                   [arrayExp, indexExp])

  fun Array_update_unsafe (elemTy, arrayExp, indexExp, argExp) =
      polyPrimApp (P.Array_update_unsafe,
                   fn t => [arrayTy t, B.intTy, t],
                   fn t => B.unitTy,
                   elemTy,
                   [arrayExp, indexExp, argExp])

  fun Array_copy_unsafe (elemTy, src, si, dst, di, len) =
      polyPrimApp (P.R P.Array_copy_unsafe,
                   fn t => [arrayTy t, B.intTy, arrayTy t, B.intTy, B.intTy],
                   fn t => B.unitTy,
                   elemTy,
                   [src, si, dst, di, len])

  (*
   * "'a ref" is "'a array" of just one element.
   *)

  fun Ref_alloc (elemTy, exp1) =
      Cast (Array_alloc_init (elemTy, [exp1]), refTy elemTy)

  fun Ref_deref (elemTy, exp) =
      Array_sub_unsafe (elemTy, Cast (exp, arrayTy elemTy), Int32 0)

  fun Ref_assign (elemTy, refExp, argExp) =
      Array_update_unsafe
        (elemTy, Cast (refExp, arrayTy elemTy), Int32 0, argExp)

  (*
   * a "string" is a "char vector" with one sentinel character at the
   * end of its character sequence. A "string" of N characters is an
   * "char vector" of (N+1) characters.
   *)

  fun String_alloc_unsafe lenExp =
      let
        val vid1 = newId ()
        val vid2 = newId ()
        val vid3 = newId ()
      in
        Let ([(vid1, lenExp),
              (vid2, Array_alloc_unsafe
                       (B.charTy, Int32_add_unsafe (Var vid1, Int32 1))),
              (vid3, Array_update_unsafe
                       (B.charTy, Var vid2, Var vid1, Char 0))],
             Cast (Array_turnIntoVector (B.charTy, Var vid2), B.stringTy))
      end

  fun String_size exp1 =
      Int32_sub_unsafe (Array_length (B.charTy, Cast (exp1, arrayTy B.charTy)),
                        Int32 1)

  fun String_sub_unsafe (strExp, indexExp) =
      Cast (Array_sub_unsafe (B.charTy, Cast (strExp, arrayTy B.charTy),
                              indexExp),
            B.charTy)

  fun String_update_unsafe (strExp, indexExp, argExp) =
      Array_update_unsafe (B.charTy, Cast (strExp, arrayTy B.charTy),
                           indexExp, Cast (argExp, B.charTy))

  fun String_copy_unsafe (src, si, dst, di, len) =
      Array_copy_unsafe (B.charTy, Cast (src, arrayTy B.charTy), si,
                         Cast (src, arrayTy B.charTy), di, len)

  fun isStringTy ty =
      case TypesBasics.derefTy ty of
        T.CONSTRUCTty {tyCon,...} => TypID.eq (#id tyCon, #id B.stringTyCon)
      | _ => false

  fun locToString ((pos1, pos2):Loc.loc) =
      Loc.fileNameOfPos pos1 ^ ":" ^ Int.toString (Loc.lineOfPos pos1)

  (*
   * An exception objet is implemented as either
   * a pair (exntag * string) if it has no argument, or
   * a triple (exntag * string * \tau) where \tau is the type of the argument
   * of the exception.
   * The second "string" element indicates the location where the exception
   * object is created.
   *
   * An exception tag is implemented as (string * word) ref, where
   * "string" is the name of the exception and
   * "word" is a message index that is a value indicating how to extract
   * a message from an exception object with this tag.
   * "ref" is required to realize the generativity of exceptions.
   *
   * A message index consists of 1-bit flag R and an offset O.
   * If R is 1, then the argument is an record containing a string.
   * Otherwise, a message string is directly in the exception object.
   * O is the offset of the string field in either the argument record or
   * the exception object.
   * If message index is 0, there is no exception message.
   *)

  fun extractExnTag exnExp =
      SelectN (1, Cast (exnExp, tupleTy [B.exntagTy]))

  fun extractExnLoc exnExp =
      SelectN (2, Cast (exnExp, tupleTy [B.exntagTy, B.stringTy]))

  fun extractExnArg (exnExp, argTy) =
      SelectN (3, Cast (exnExp, tupleTy [B.exntagTy, B.stringTy, argTy]))

  fun exnMessageIndex exnConTy =
      case TypesBasics.derefTy exnConTy of
        T.FUNMty ([argTy], _) =>
        (case TypesBasics.derefTy argTy of
           T.RECORDty tys =>
           (case List.find (isStringTy o #2) (RecordLabel.Map.listItemsi tys) of
              SOME (label, _) =>
              Word32_orb (Cast (IndexOf (argTy, label), B.wordTy), Word32 1)
            | NONE => Word32 0)
         | ty =>
           if isStringTy ty
           then Cast
                  (IndexOf (tupleTy [B.exntagTy, B.stringTy, B.stringTy],
                            RecordLabel.fromInt 3),
                   B.wordTy)
           else Word32 0)
      | _ => Word32 0

  val exnTagImplTy =
      tupleTy [B.stringTy, B.wordTy]

  fun allocExnTag {builtin, path, ty} =
      Cast ((if builtin then Vector_alloc_init else Vector_alloc_init_fresh)
              (exnTagImplTy, [Tuple [String (Symbol.longsymbolToString path),
                                     exnMessageIndex ty]]),
            B.exntagTy)

  fun extractExnTagName tagExp =
      SelectN (1, Ref_deref (exnTagImplTy, Cast (tagExp, refTy exnTagImplTy)))

  fun extractExnMsgIndex tagExp =
      SelectN (2, Ref_deref (exnTagImplTy, Cast (tagExp, refTy exnTagImplTy)))

  fun Exn_Message exnExp =
      let
        val vid1 = newId ()
        val vid2 = newId ()
      in
        Let
          ([(vid1, exnExp),
            (vid2, extractExnMsgIndex (extractExnTag (Var vid1)))],
           Tuple
             [extractExnLoc (Var vid1),
              Word32_andb (Var vid2, Word32 ~2),
              Switch
                (Var vid2,
                 [(C.WORD32 0w0, Null)],
                 Switch
                   (Word32_andb (Var vid2, Word32 1),
                    [(C.WORD32 0w0, Cast (Var vid1, B.boxedTy))],
                    extractExnArg (Var vid1, B.boxedTy)))])
      end

  fun composeExn (tagExp, loc, NONE) =
      Cast (Tuple [tagExp, String (locToString loc)], B.exnTy)
    | composeExn (tagExp, loc, SOME argExp) =
      Cast (Tuple [tagExp, String (locToString loc), argExp], B.exnTy)

  fun emitExp loc env exp =
      case exp of
        Exp x => x
      | Int8 n =>
        (L.TLCONSTANT {const = C.INT8 (Int8.fromInt n),
                       ty = B.int8Ty,
                       loc = loc},
         B.intTy)
      | Int16 n =>
        (L.TLCONSTANT {const = C.INT16 (Int16.fromInt n),
                       ty = B.int16Ty,
                       loc = loc},
         B.intTy)
      | Int32 n =>
        (L.TLCONSTANT {const = C.INT32 (Int32.fromInt n),
                       ty = B.intTy,
                       loc = loc},
         B.intTy)
      | Int64 n =>
        (L.TLCONSTANT {const = C.INT64 (Int64.fromInt n),
                       ty = B.int64Ty,
                       loc = loc},
         B.int64Ty)
      | Word8 n =>
        (L.TLCONSTANT {const = C.WORD8 (Word8.fromInt n),
                       ty = B.word8Ty,
                       loc = loc},
         B.wordTy)
      | Word16 n =>
        (L.TLCONSTANT {const = C.WORD16 (Word16.fromInt n),
                       ty = B.word16Ty,
                       loc = loc},
         B.wordTy)
      | Word32 n =>
        (L.TLCONSTANT {const = C.WORD32 (Word32.fromInt n),
                       ty = B.wordTy,
                       loc = loc},
         B.wordTy)
      | Word64 n =>
        (L.TLCONSTANT {const = C.WORD64 (Word64.fromInt n),
                       ty = B.word64Ty,
                       loc = loc},
         B.word64Ty)
      | Char n =>
        (L.TLCONSTANT {const = C.CHAR (chr n), ty = B.charTy, loc = loc},
         B.charTy)
      | ConTag n =>
        (L.TLCONSTANT {const = C.CONTAG (Word32.fromInt n),
                       ty = B.contagTy,
                       loc = loc},
         B.contagTy)
      | Real64 n =>
        (L.TLCONSTANT {const = C.REAL64 (Int32.toString n),
                       ty = B.realTy,
                       loc = loc},
         B.realTy)
      | Real32 n =>
        (L.TLCONSTANT {const = C.REAL32 (Int32.toString n),
                       ty = B.real32Ty,
                       loc = loc},
         B.real32Ty)
      | String x =>
        (L.TLCONSTANT {const = C.STRING x, ty = B.stringTy, loc = loc},
         B.stringTy)
      | Unit =>
        (L.TLCONSTANT {const = C.UNIT, ty = B.unitTy, loc = loc},
         B.unitTy)
      | Null =>
        (L.TLCONSTANT {const = C.NULLBOXED, ty = B.boxedTy, loc = loc},
         B.boxedTy)
      | False => emitExp loc env (Cast (ConTag 0, B.boolTy))
      | True => emitExp loc env (Cast (ConTag 1, B.boolTy))
      | SizeOf ty =>
        (L.TLSIZEOF {ty = ty, loc = loc}, T.SINGLETONty (T.SIZEty ty))
      | IndexOf (ty, label) =>
        (L.TLINDEXOF {recordTy = ty, label = label, loc = loc},
         T.SINGLETONty (T.INDEXty (label, ty)))
      | ExVar v =>
        (L.TLEXVAR {exVarInfo = v, loc = loc},
         #ty v)
      | Cast (exp, ty) =>
        let
          val (exp, expTy) = emitExp loc env exp
        in
          (L.TLCAST {exp = exp, expTy = expTy, targetTy = ty,
                     cast = P.TypeCast, loc = loc},
           ty)
        end
      | RuntimeTyCast (exp, ty) =>
        let
          val (exp, expTy) = emitExp loc env exp
        in
          (L.TLCAST {exp = exp, expTy = expTy, targetTy = ty,
                     cast = P.RuntimeTyCast, loc = loc},
           ty)
        end
      | BitCast (exp, ty) =>
        let
          val (exp, expTy) = emitExp loc env exp
        in
          (L.TLCAST {exp = exp, expTy = expTy, targetTy = ty,
                     cast = P.BitCast, loc = loc},
           ty)
        end
      | PrimApply (primInfo, instTyList, retTy, argExpList) =>
        let
          val argExpList = map (fn e => #1 (emitExp loc env e)) argExpList
        in
          (L.TLPRIMAPPLY {primInfo = primInfo,
                          instTyList = instTyList,
                          argExpList = argExpList,
                          loc = loc},
           retTy)
        end
      | If (exp1, exp2, exp3) =>
        let
          val (exp1, ty1) = emitExp loc env exp1
          val (exp2, ty2) = emitExp loc env exp2
          val (exp3, ty3) = emitExp loc env exp3
        in
          (L.TLSWITCH
             {switchExp = L.TLCAST {exp = exp1,
                                    expTy = ty1,
                                    targetTy = B.contagTy,
                                    cast = P.TypeCast,
                                    loc = loc},
              expTy = B.contagTy,
              branches = [{constant = C.CONTAG 0w0, exp = exp3}],
              defaultExp = exp2,
              resultTy = ty2,
              loc = loc},
           ty2)
        end
      | Andalso nil => emitExp loc env True
      | Andalso [x] => emitExp loc env x
      | Andalso (h::t) => emitExp loc env (If (h, Andalso t, False))
      | Switch (switchExp, branches, defaultExp) =>
        let
          val (switchExp, expTy) = emitExp loc env switchExp
          val branches =
              map (fn (c,e) => {constant = c, exp = #1 (emitExp loc env e)})
                  branches
          val (defaultExp, resultTy) = emitExp loc env defaultExp
        in
          (L.TLSWITCH {switchExp = switchExp,
                       expTy = expTy,
                       branches = branches,
                       defaultExp = defaultExp,
                       resultTy = resultTy,
                       loc = loc},
           resultTy)
        end
      | Raise ({path, ...}, ty) =>
        let
          val tagExp = ExVar {path = path, ty = B.exntagTy}
          val (argExp, _) = emitExp loc env (composeExn (tagExp, loc, NONE))
        in
          (L.TLRAISE {argExp = argExp, resultTy = ty, loc = loc},
           ty)
        end
      | Fn (vid, argTy, exp) =>
        let
          val argVar = {id = vid, ty = argTy, path = [Symbol.generate ()]}
          val argExp = L.TLVAR {varInfo = argVar, loc = loc}
          val env = VarID.Map.insert (env, vid, (argExp, argTy))
          val (exp, bodyTy) = emitExp loc env exp
        in
          (L.TLFNM {argVarList = [argVar],
                    bodyTy = bodyTy,
                    bodyExp = exp,
                    loc = loc},
           T.FUNMty ([argTy], bodyTy))
        end
      | App (exp1, exp2) =>
        let
          val (exp1, ty1) = emitExp loc env exp1
          val (exp2, ty2) = emitExp loc env exp2
          val retTy =
              case TypesBasics.derefTy ty1 of
                T.FUNMty ([argTy], retTy) => retTy
              | _ => raise Bug.Bug "emitExp: App"
        in
          (L.TLAPPM {funExp = exp1,
                     funTy = ty1,
                     argExpList = [exp2],
                     loc = loc},
           retTy)
        end
      | Let (nil, exp) => emitExp loc env exp
      | Let ((vid, exp1)::t, exp2) =>
        let
          val (exp1, ty1) = emitExp loc env exp1
          val exp2 = Let (t, exp2)
        in
          if isAtomic exp1
          then emitExp loc (VarID.Map.insert (env, vid, (exp1, ty1))) exp2
          else
            let
              val varInfo =
                  {id = vid, ty = ty1, path = [Symbol.generate ()]}
              val varExp = L.TLVAR {varInfo = varInfo, loc = loc}
              val env = VarID.Map.insert (env, vid, (varExp, ty1))
              val (exp2, ty2) = emitExp loc env exp2
            in
              (L.TLLET {localDecl = L.TLVAL {boundVar = varInfo,
                                             boundExp = exp1,
                                             loc = loc},
                        mainExp = exp2,
                        loc = loc},
               ty2)
            end
        end
      | Var id =>
        (case VarID.Map.find (env, id) of
           SOME x => x
         | NONE => raise Bug.Bug "emitExp: Var")
      | TLLet (nil, exp2) => emitExp loc env exp2
      | TLLet (decl::decls, exp) =>
        let
          val (decl, loc2) =
              case decl of
                Decl x => x
              | Bind (var, exp) =>
                (L.TLVAL {boundVar = var,
                          boundExp = #1 (emitExp loc env exp),
                          loc = loc},
                 loc)
          val (exp, ty) = emitExp loc env (TLLet (decls, exp))
        in
          (L.TLLET {localDecl = decl, mainExp = exp, loc = loc2}, ty)
        end
      | TLVar varInfo =>
        (L.TLVAR {varInfo = varInfo, loc = loc}, #ty varInfo)
      | Record (labels, exps) =>
        let
          val exps = map (emitExp loc env) exps
          val fields = ListPair.foldlEq
                         (fn (label, x, z) => RecordLabel.Map.insert (z, label, x))
                         RecordLabel.Map.empty
                         (labels, exps)
          val recordTy = T.RECORDty (RecordLabel.Map.map #2 fields)
        in
          (L.TLRECORD {isMutable = false,
                       fields = RecordLabel.Map.map #1 fields,
                       recordTy = recordTy,
                       loc = loc},
           recordTy)
        end
      | Select (label, exp) =>
        let
          val (recordExp, recordTy) = emitExp loc env exp
          val resultTy =
              case TypesBasics.derefTy recordTy of
                T.RECORDty fields =>
                (case RecordLabel.Map.find (fields, label) of
                   SOME ty => ty
                 | NONE => raise Bug.Bug "emitExp: Select")
              | _ => raise Bug.Bug "emitExp: Select"
        in
          (L.TLSELECT {recordExp = recordExp,
                       indexExp = L.TLINDEXOF {label = label,
                                               recordTy = recordTy,
                                               loc = loc},
                       label = label,
                       recordTy = recordTy,
                       resultTy = resultTy,
                       loc = loc},
           resultTy)
        end

  fun emit loc exp =
      #1 (emitExp loc VarID.Map.empty exp)

end
