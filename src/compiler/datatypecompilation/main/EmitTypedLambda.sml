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
    | Int of int
    | Int64 of int64
    | Word of int
    | Word64 of int64
    | Word8 of int
    | Char of int
    | ConTag of int
    | Real of int
    | Float of int
    | String of string
    | Unit
    | Null
    | True
    | False
    | SizeOf of Types.ty
    | IndexOf of Types.ty * string
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
    | Record of string list * exp list
    | Select of string * exp
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
      | L.TLLOCALCODE _ => false
      | L.TLGOTO _ => false
      | L.TLFNM _ => false
      | L.TLPOLY _ => false
      | L.TLTAPP _ => false
      | L.TLCAST {exp, expTy, targetTy, cast, loc} => isAtomic exp
      | L.TLDUMP _ => false

  fun Tuple exps =
      Record (List.tabulate (length exps, fn i => Int.toString (i+1)), exps)

  fun tupleFields fields =
      let
        fun loop i nil = LabelEnv.empty
          | loop i (h::t) =
            LabelEnv.insert (loop (i+1) t, Int.toString i, h)
      in
        loop 1 fields
      end

  fun arrayTy ty =
      T.CONSTRUCTty {tyCon = B.arrayTyCon, args = [ty]}
  fun vectorTy ty =
      T.CONSTRUCTty {tyCon = B.vectorTyCon, args = [ty]}
  fun refTy ty =
      T.CONSTRUCTty {tyCon = B.refTyCon, args = [ty]}
  fun tupleTy tys =
      T.RECORDty (tupleFields tys)

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

  fun polyPrimApp (prim, argTys, retTy, instTy, args) =
      let
        val tid = BoundTypeVarID.generate ()
        val univKind = {eqKind = Absyn.NONEQ, tvarKind = T.UNIV}
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

  fun Int32_eq (exp1, exp2) =
      IdentityEqual (B.intTy, exp1, exp2)

  fun Int32_gteq (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Int32_gteq),
                   [B.intTy, B.intTy], B.boolTy,
                   [exp1, exp2])

  fun Int32_lt (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Int32_lt),
                   [B.intTy, B.intTy], B.boolTy,
                   [exp1, exp2])

  fun Int32_lteq (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Int32_lteq),
                   [B.intTy, B.intTy], B.boolTy,
                   [exp1, exp2])

  fun Int32_quot_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Int32_quot_unsafe),
                   [B.intTy, B.intTy], B.intTy,
                   [exp1, exp2])

  fun Int32_rem_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Int32_rem_unsafe),
                   [B.intTy, B.intTy], B.intTy,
                   [exp1, exp2])

  fun Int32_sub_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Int32_sub_unsafe),
                   [B.intTy, B.intTy], B.intTy,
                   [exp1, exp2])

  fun Int32_add_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Int32_add_unsafe),
                   [B.intTy, B.intTy], B.intTy,
                   [exp1, exp2])

  fun Int64_eq (exp1, exp2) =
      IdentityEqual (B.int64Ty, exp1, exp2)

  fun Int64_gteq (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Int64_gteq),
                   [B.int64Ty, B.int64Ty], B.boolTy,
                   [exp1, exp2])

  fun Int64_lt (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Int64_lt),
                   [B.int64Ty, B.int64Ty], B.boolTy,
                   [exp1, exp2])

  fun Int64_lteq (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Int64_lteq),
                   [B.int64Ty, B.int64Ty], B.boolTy,
                   [exp1, exp2])

  fun Int64_quot_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Int64_quot_unsafe),
                   [B.int64Ty, B.int64Ty], B.int64Ty,
                   [exp1, exp2])

  fun Int64_rem_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Int64_rem_unsafe),
                   [B.int64Ty, B.int64Ty], B.int64Ty,
                   [exp1, exp2])

  fun Int64_sub_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Int64_sub_unsafe),
                   [B.int64Ty, B.int64Ty], B.int64Ty,
                   [exp1, exp2])

  fun Int64_add_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Int64_add_unsafe),
                   [B.int64Ty, B.int64Ty], B.int64Ty,
                   [exp1, exp2])

  fun Word32_add (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word32_add),
                   [B.wordTy, B.wordTy], B.wordTy,
                   [exp1, exp2])

  fun Word32_sub (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word32_sub),
                   [B.wordTy, B.wordTy], B.wordTy,
                   [exp1, exp2])

  fun Word32_div_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word32_div_unsafe),
                   [B.wordTy, B.wordTy], B.wordTy,
                   [exp1, exp2])

  fun Word32_orb (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word32_orb),
                   [B.wordTy, B.wordTy], B.wordTy,
                   [exp1, exp2])

  fun Word32_andb (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word32_andb),
                   [B.wordTy, B.wordTy], B.wordTy,
                   [exp1, exp2])

  fun Word32_xorb (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word32_xorb),
                   [B.wordTy, B.wordTy], B.wordTy,
                   [exp1, exp2])

  fun Word32_lt (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word32_lt),
                   [B.wordTy, B.wordTy], B.boolTy,
                   [exp1, exp2])

  fun Word32_fromInt32 exp =
      RuntimeTyCast (exp, B.wordTy)

  fun Word32_toInt32X exp =
      RuntimeTyCast (exp, B.intTy)

  fun Word32_toWord8 exp1 =
      monoPrimApp (P.R (P.M P.Word32_toWord8),
                   [B.wordTy], B.word8Ty,
                   [exp1])

  fun Word32_toWord64 exp =
      monoPrimApp (P.R (P.M P.Word32_toWord64),
                   [B.wordTy], B.word64Ty,
                   [exp])

  fun Word32_toWord64X exp =
      monoPrimApp (P.R (P.M P.Word32_toWord64X),
                   [B.wordTy], B.word64Ty,
                   [exp])

  fun Word64_arshift_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word64_arshift_unsafe),
                   [B.word64Ty, B.word64Ty], B.word64Ty,
                   [exp1, exp2])

  fun Word64_rshift_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word64_rshift_unsafe),
                   [B.word64Ty, B.word64Ty], B.word64Ty,
                   [exp1, exp2])

  fun Word64_lshift_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word64_lshift_unsafe),
                   [B.word64Ty, B.word64Ty], B.word64Ty,
                   [exp1, exp2])

  fun Word64_add (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word64_add),
                   [B.word64Ty, B.word64Ty], B.word64Ty,
                   [exp1, exp2])

  fun Word64_sub (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word64_sub),
                   [B.word64Ty, B.word64Ty], B.word64Ty,
                   [exp1, exp2])

  fun Word64_div_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word64_div_unsafe),
                   [B.word64Ty, B.word64Ty], B.word64Ty,
                   [exp1, exp2])

  fun Word64_orb (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word64_orb),
                   [B.word64Ty, B.word64Ty], B.word64Ty,
                   [exp1, exp2])

  fun Word64_andb (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word64_andb),
                   [B.word64Ty, B.word64Ty], B.word64Ty,
                   [exp1, exp2])

  fun Word64_xorb (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word64_xorb),
                   [B.word64Ty, B.word64Ty], B.word64Ty,
                   [exp1, exp2])

  fun Word64_lt (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word64_lt),
                   [B.word64Ty, B.word64Ty], B.boolTy,
                   [exp1, exp2])

  fun Word64_lteq (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word64_lteq),
                   [B.word64Ty, B.word64Ty], B.boolTy,
                   [exp1, exp2])

  fun Word64_fromInt32 exp =
      monoPrimApp (P.R (P.M P.Word32_toWord64X),
                   [B.wordTy], B.word64Ty,
                   [RuntimeTyCast (exp, B.wordTy)])

  fun Word64_toWord32 exp =
      monoPrimApp (P.R (P.M P.Word64_toWord32),
                   [B.word64Ty], B.wordTy,
                   [exp])

  fun Word64_fromInt64 exp =
      RuntimeTyCast (exp, B.word64Ty)

  fun Word64_toInt64X exp =
      RuntimeTyCast (exp, B.int64Ty)

  fun Float_isNan exp1 =
      monoPrimApp (P.R (P.M P.Float_isNan),
                   [B.real32Ty], B.boolTy,
                   [exp1])

  fun Float_equal (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Float_equal),
(* bug 303_Real32NotEqual
                   [B.realTy, B.realTy], B.boolTy,*)
                   [B.real32Ty, B.real32Ty], B.boolTy,
                   [exp1, exp2])

  fun Float_gteq (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Float_gteq),
                   [B.real32Ty, B.real32Ty], B.boolTy,
                   [exp1, exp2])

  fun Float_lteq (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Float_lteq),
                   [B.real32Ty, B.real32Ty], B.boolTy,
                   [exp1, exp2])

  fun Float_sub (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Float_sub),
                   [B.real32Ty, B.real32Ty], B.real32Ty,
                   [exp1, exp2])

  fun Float_toInt32_unsafe exp =
      monoPrimApp (P.R (P.M P.Float_toInt32_unsafe),
                   [B.real32Ty], B.intTy,
                   [exp])

  fun Real_isNan exp1 =
      monoPrimApp (P.R (P.M P.Real_isNan),
                   [B.realTy], B.boolTy,
                   [exp1])

  fun Real_equal (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Real_equal),
                   [B.realTy, B.realTy], B.boolTy,
                   [exp1, exp2])

  fun Real_gteq (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Real_gteq),
                   [B.realTy, B.realTy], B.boolTy,
                   [exp1, exp2])

  fun Real_lteq (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Real_lteq),
                   [B.realTy, B.realTy], B.boolTy,
                   [exp1, exp2])

  fun Real_sub (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Real_sub),
                   [B.realTy, B.realTy], B.realTy,
                   [exp1, exp2])

  fun Real_toInt32_unsafe exp =
      monoPrimApp (P.R (P.M P.Real_toInt32_unsafe),
                   [B.realTy], B.intTy,
                   [exp])

  fun Word8_sub (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word8_sub),
                   [B.word8Ty, B.word8Ty], B.word8Ty,
                   [exp1, exp2])

  fun Word8_xorb (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word8_xorb),
                   [B.word8Ty, B.word8Ty], B.word8Ty,
                   [exp1, exp2])

  fun Word8_arshift_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word8_arshift_unsafe),
                   [B.word8Ty, B.word8Ty], B.word8Ty,
                   [exp1, exp2])

  fun Word8_rshift_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word8_rshift_unsafe),
                   [B.word8Ty, B.word8Ty], B.word8Ty,
                   [exp1, exp2])

  fun Word8_lshift_unsafe (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word8_lshift_unsafe),
                   [B.word8Ty, B.word8Ty], B.word8Ty,
                   [exp1, exp2])

  fun Word8_lt (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word8_lt),
                   [B.word8Ty, B.word8Ty], B.boolTy,
                   [exp1, exp2])

  fun Word8_lteq (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word8_lteq),
                   [B.word8Ty, B.word8Ty], B.boolTy,
                   [exp1, exp2])

  fun Word8_gt (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word8_gt),
                   [B.word8Ty, B.word8Ty], B.boolTy,
                   [exp1, exp2])

  fun Word8_gteq (exp1, exp2) =
      monoPrimApp (P.R (P.M P.Word8_gteq),
                   [B.word8Ty, B.word8Ty], B.boolTy,
                   [exp1, exp2])

  fun Word8_toWord32 exp1 =
      monoPrimApp (P.R (P.M P.Word8_toWord32),
                   [B.word8Ty], B.wordTy,
                   [exp1])

  fun Word8_toWord32X exp1 =
      monoPrimApp (P.R (P.M P.Word8_toWord32X),
                   [B.word8Ty], B.wordTy,
                   [exp1])

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
      Array_sub_unsafe (elemTy, Cast (exp, arrayTy elemTy), Int 0)

  fun Ref_assign (elemTy, refExp, argExp) =
      Array_update_unsafe (elemTy, Cast (refExp, arrayTy elemTy), Int 0, argExp)

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
                       (B.charTy, Int32_add_unsafe (Var vid1, Int 1))),
              (vid3, Array_update_unsafe
                       (B.charTy, Var vid2, Var vid1, Char 0))],
             Cast (Array_turnIntoVector (B.charTy, Var vid2), B.stringTy))
      end

  fun String_size exp1 =
      Int32_sub_unsafe (Array_length (B.charTy, Cast (exp1, arrayTy B.charTy)),
                        Int 1)

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
      Select ("1", Cast (exnExp, tupleTy [B.exntagTy]))

  fun extractExnLoc exnExp =
      Select ("2", Cast (exnExp, tupleTy [B.exntagTy, B.stringTy]))

  fun extractExnArg (exnExp, argTy) =
      Select ("3", Cast (exnExp, tupleTy [B.exntagTy, B.stringTy, argTy]))

  fun exnMessageIndex exnConTy =
      case TypesBasics.derefTy exnConTy of
        T.FUNMty ([argTy], _) =>
        (case TypesBasics.derefTy argTy of
           T.RECORDty tys =>
           (case List.find (isStringTy o #2) (LabelEnv.listItemsi tys) of
              SOME (label, _) =>
              Word32_orb (Cast (IndexOf (argTy, label), B.wordTy), Word 1)
            | NONE => Word 0)
         | ty =>
           if isStringTy ty
           then Cast
                  (IndexOf (tupleTy [B.exntagTy, B.stringTy, B.stringTy], "3"),
                   B.wordTy)
           else Word 0)
      | _ => Word 0

  val exnTagImplTy =
      tupleTy [B.stringTy, B.wordTy]

  fun allocExnTag {builtin, path, ty} =
      Cast ((if builtin then Vector_alloc_init else Vector_alloc_init_fresh)
              (exnTagImplTy, [Tuple [String (String.concatWith "." path),
                                     exnMessageIndex ty]]),
            B.exntagTy)

  fun extractExnTagName tagExp =
      Select ("1", Ref_deref (exnTagImplTy, Cast (tagExp, refTy exnTagImplTy)))

  fun extractExnMsgIndex tagExp =
      Select ("2", Ref_deref (exnTagImplTy, Cast (tagExp, refTy exnTagImplTy)))

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
              Word32_andb (Var vid2, Word ~2),
              Switch
                (Var vid2,
                 [(C.WORD32 0w0, Null)],
                 Switch
                   (Word32_andb (Var vid2, Word 1),
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
      | Int n =>
        (L.TLCONSTANT {const = C.INT32 (Int32.fromInt n),
                       ty = B.intTy,
                       loc = loc},
         B.intTy)
      | Int64 n =>
        (L.TLCONSTANT {const = C.INT64 n,
                       ty = B.int64Ty,
                       loc = loc},
         B.int64Ty)
      | Word n =>
        (L.TLCONSTANT {const = C.WORD32 (Word32.fromInt n),
                       ty = B.wordTy,
                       loc = loc},
         B.wordTy)
      | Word64 n =>
        (L.TLCONSTANT {const = C.WORD64 
                                 (Word64.fromLargeInt (Int64.toLarge n)),
                       ty = B.word64Ty,
                       loc = loc},
         B.word64Ty)
      | Word8 n =>
        (L.TLCONSTANT {const = C.WORD8 (Word8.fromInt n),
                       ty = B.word8Ty,
                       loc = loc},
         B.word8Ty)
      | Char n =>
        (L.TLCONSTANT {const = C.CHAR (chr n), ty = B.charTy, loc = loc},
         B.charTy)
      | ConTag n =>
        (L.TLCONSTANT {const = C.CONTAG (Word32.fromInt n),
                       ty = B.contagTy,
                       loc = loc},
         B.contagTy)
      | Real n =>
        (L.TLCONSTANT {const = C.REAL (Int32.toString n),
                       ty = B.realTy,
                       loc = loc},
         B.realTy)
      | Float n =>
        (L.TLCONSTANT {const = C.FLOAT (Int32.toString n),
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
          val argVar = {id = vid, ty = argTy, path = ["$" ^ VarID.toString vid]}
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
                  {id = vid, ty = ty1, path = ["$" ^ VarID.toString vid]}
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
                         (fn (label, x, z) => LabelEnv.insert (z, label, x))
                         LabelEnv.empty
                         (labels, exps)
          val recordTy = T.RECORDty (LabelEnv.map #2 fields)
        in
          (L.TLRECORD {isMutable = false,
                       fields = LabelEnv.map #1 fields,
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
                (case LabelEnv.find (fields, label) of
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
