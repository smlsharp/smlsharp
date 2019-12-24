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

  type vid = VarID.id

  val newId = VarID.generate

  datatype exp =
      Exp of TypedLambda.tlexp * Types.ty
    | Const of TypedLambda.tlconst * Types.ty
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
    | Real64 of real64
    | Real32 of real32
    | String of string
    | Unit
    | Null
    | True
    | False
    | SizeOf of Types.ty
    | IndexOf of Types.ty * RecordLabel.label
    | ExVar of RecordCalc.exVarInfo
    | Cast of exp * Types.ty
    | BitCast of exp * Types.ty
    | PrimApply of TypedLambda.primInfo * Types.ty list * Types.ty * exp list
    | If of exp * exp * exp
    | Andalso of exp list
    | Switch of exp * (TypedLambda.tlconst * exp) list * exp
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

  fun op1 prim ty exp =
      monoPrimApp (P.R (P.M prim), [ty], ty, [exp])
  fun op2 prim ty (exp1, exp2) =
      monoPrimApp (P.R (P.M prim), [ty, ty], ty, [exp1, exp2])
  fun cmp1 prim ty exp =
      monoPrimApp (P.R (P.M prim), [ty], B.boolTy, [exp])
  fun cmp2 prim ty (exp1, exp2) =
      monoPrimApp (P.R (P.M prim), [ty, ty], B.boolTy, [exp1, exp2])
  fun conv prim (fromTy, toTy) exp1 =
      monoPrimApp (P.R (P.M prim), [fromTy], toTy, [exp1])

  fun Int_eq intTy (x, y) = IdentityEqual (intTy, x, y)
  fun Int_lt intTy x = cmp2 P.Int_lt intTy x
  fun Int_gteq intTy x = cmp2 P.Int_gteq intTy x
  fun Int_lteq intTy x = cmp2 P.Int_lteq intTy x
  fun Int_quot_unsafe intTy x = op2 P.Int_quot_unsafe intTy x
  fun Int_rem_unsafe intTy x = op2 P.Int_rem_unsafe intTy x
  fun Int_add_unsafe intTy x = op2 P.Int_add_unsafe intTy x
  fun Int_mul_unsafe intTy x = op2 P.Int_mul_unsafe intTy x
  fun Int_sub_unsafe intTy x = op2 P.Int_sub_unsafe intTy x
  fun Int_add_overflowCheck intTy x = cmp2 P.Int_add_overflowCheck intTy x
  fun Int_mul_overflowCheck intTy x = cmp2 P.Int_mul_overflowCheck intTy x
  fun Int_sub_overflowCheck intTy x = cmp2 P.Int_sub_overflowCheck intTy x
  fun Int_toInt_unsafe x y = conv P.Word_sext_trunc x y

  fun Word_lt wordTy x = cmp2 P.Word_lt wordTy x
  fun Word_gt wordTy x = cmp2 P.Word_gt wordTy x
  fun Word_lteq wordTy x = cmp2 P.Word_lteq wordTy x
  fun Word_gteq wordTy x = cmp2 P.Word_gteq wordTy x
  fun Word_arshift_unsafe wordTy x = op2 P.Word_arshift_unsafe wordTy x
  fun Word_rshift_unsafe wordTy x = op2 P.Word_rshift_unsafe wordTy x
  fun Word_lshift_unsafe wordTy x = op2 P.Word_lshift_unsafe wordTy x
  fun Word_div_unsafe wordTy x = op2 P.Word_div_unsafe wordTy x
  fun Word_mod_unsafe wordTy x = op2 P.Word_mod_unsafe wordTy x
  fun Word_add wordTy x = op2 P.Word_add wordTy x
  fun Word_sub wordTy x = op2 P.Word_sub wordTy x
  fun Word_andb wordTy x = op2 P.Word_andb wordTy x
  fun Word_orb wordTy x = op2 P.Word_orb wordTy x
  fun Word_xorb wordTy x = op2 P.Word_xorb wordTy x
  fun Word_fromInt x y = conv P.Word_sext_trunc x y
  fun Word_toInt x y = conv P.Word_zext_trunc x y
  fun Word_toIntX_unsafe x y = conv P.Word_sext_trunc x y
  fun Word_toWord x y = conv P.Word_zext_trunc x y

  fun Real_isNan realTy x = cmp1 P.Real_isNan realTy x
  fun Real_equal realTy x = cmp2 P.Real_equal realTy x
  fun Real_gteq realTy x = cmp2 P.Real_gteq realTy x
  fun Real_lteq realTy x = cmp2 P.Real_lteq realTy x
  fun Real_sub realTy x = op2 P.Real_sub realTy x

  fun ObjectSize (ty, exp) =
      monoPrimApp (P.R (P.M P.ObjectSize),
                   [ty], B.word32Ty,
                   [exp])

  fun Array_alloc_unsafe (elemTy, lenExp) =
      polyPrimApp (P.R P.Array_alloc_unsafe,
                   fn t => [B.int32Ty], fn t => arrayTy t,
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
      Cast (Word_div_unsafe B.word32Ty (ObjectSize (arrayTy elemTy, exp1),
                                        Cast (SizeOf elemTy, B.word32Ty)),
            B.int32Ty)

  fun Array_sub_unsafe (elemTy, arrayExp, indexExp) =
      polyPrimApp
        (P.Array_sub_unsafe,
         fn t => [arrayTy t, B.int32Ty],
         fn t => t,
         elemTy,
         [arrayExp, indexExp])

  fun Array_update_unsafe (elemTy, arrayExp, indexExp, argExp) =
      polyPrimApp
        (P.Array_update_unsafe,
         fn t => [arrayTy t, B.int32Ty, t],
         fn t => B.unitTy,
         elemTy,
         [arrayExp, indexExp, argExp])

  fun Array_copy_unsafe (elemTy, src, si, dst, di, len) =
      polyPrimApp
        (P.R P.Array_copy_unsafe,
         fn t => [arrayTy t, B.int32Ty, arrayTy t, B.int32Ty, B.int32Ty],
         fn t => B.unitTy,
         elemTy,
         [src, si, dst, di, len])

  fun Vector_alloc_unsafe (elemTy, lenExp) =
      polyPrimApp (P.R P.Vector_alloc_unsafe,
                   fn t => [B.int32Ty], fn t => arrayTy t,
                   elemTy,
                   [lenExp])

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
              (vid2, Vector_alloc_unsafe
                       (B.charTy,
                        Int_add_unsafe B.int32Ty (Var vid1, Int32 1))),
              (vid3, Array_update_unsafe
                       (B.charTy, Cast (Var vid2, arrayTy B.charTy),
                        Var vid1, Char 0))],
             Cast (Var vid2, B.stringTy))
      end

  fun String_size exp1 =
      Cast (Word_sub B.word32Ty (ObjectSize (B.stringTy, exp1), Word32 1),
            B.int32Ty)

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
      Loc.posToString pos1

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
              Word_orb B.word32Ty
                       (Cast (IndexOf (argTy, label), B.word32Ty), Word32 1)
            | NONE => Word32 0)
         | ty =>
           if isStringTy ty
           then Cast
                  (IndexOf (tupleTy [B.exntagTy, B.stringTy, B.stringTy],
                            RecordLabel.fromInt 3),
                   B.word32Ty)
           else Word32 0)
      | _ => Word32 0

  val exnTagImplTy =
      tupleTy [B.stringTy, B.word32Ty]

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
              Word_andb B.word32Ty (Var vid2, Word32 ~2),
              Switch
                (Var vid2,
                 [(L.WORD32 0w0, Null)],
                 Switch
                   (Word_andb B.word32Ty (Var vid2, Word32 1),
                    [(L.WORD32 0w0, Cast (Var vid1, B.boxedTy))],
                    extractExnArg (Var vid1, B.boxedTy)))])
      end

  fun composeExn (tagExp, loc, NONE) =
      Cast (Tuple [tagExp, String (locToString loc)], B.exnTy)
    | composeExn (tagExp, loc, SOME argExp) =
      Cast (Tuple [tagExp, String (locToString loc), argExp], B.exnTy)

  fun emitExp loc env exp =
      case exp of
        Exp x => x
      | Const (const, ty) =>
        (L.TLCONSTANT {const = L.C const, ty = ty, loc = loc}, ty)
      | Int8 n =>
        (L.TLCONSTANT {const = L.C (L.INT8 (Int8.fromInt n)),
                       ty = B.int8Ty,
                       loc = loc},
         B.int8Ty)
      | Int16 n =>
        (L.TLCONSTANT {const = L.C (L.INT16 (Int16.fromInt n)),
                       ty = B.int16Ty,
                       loc = loc},
         B.int16Ty)
      | Int32 n =>
        (L.TLCONSTANT {const = L.C (L.INT32 (Int32.fromInt n)),
                       ty = B.int32Ty,
                       loc = loc},
         B.int32Ty)
      | Int64 n =>
        (L.TLCONSTANT {const = L.C (L.INT64 (Int64.fromInt n)),
                       ty = B.int64Ty,
                       loc = loc},
         B.int64Ty)
      | Word8 n =>
        (L.TLCONSTANT {const = L.C (L.WORD8 (Word8.fromInt n)),
                       ty = B.word8Ty,
                       loc = loc},
         B.word32Ty)
      | Word16 n =>
        (L.TLCONSTANT {const = L.C (L.WORD16 (Word16.fromInt n)),
                       ty = B.word16Ty,
                       loc = loc},
         B.word32Ty)
      | Word32 n =>
        (L.TLCONSTANT {const = L.C (L.WORD32 (Word32.fromInt n)),
                       ty = B.word32Ty,
                       loc = loc},
         B.word32Ty)
      | Word64 n =>
        (L.TLCONSTANT {const = L.C (L.WORD64 (Word64.fromInt n)),
                       ty = B.word64Ty,
                       loc = loc},
         B.word64Ty)
      | Char n =>
        (L.TLCONSTANT {const = L.C (L.CHAR (chr n)),
                       ty = B.charTy,
                       loc = loc},
         B.charTy)
      | ConTag n =>
        (L.TLCONSTANT {const = L.C (L.CONTAG (Word32.fromInt n)),
                       ty = B.contagTy,
                       loc = loc},
         B.contagTy)
      | Real64 n =>
        (L.TLCONSTANT {const = L.C (L.REAL64 n),
                       ty = B.real64Ty,
                       loc = loc},
         B.real64Ty)
      | Real32 n =>
        (L.TLCONSTANT {const = L.C (L.REAL32 n),
                       ty = B.real32Ty,
                       loc = loc},
         B.real32Ty)
      | String x =>
        (L.TLCONSTANT {const = L.S (L.STRING x),
                       ty = B.stringTy,
                       loc = loc},
         B.stringTy)
      | Unit =>
        (L.TLCONSTANT {const = L.C L.UNIT,
                       ty = B.unitTy,
                       loc = loc},
         B.unitTy)
      | Null =>
        (L.TLCONSTANT {const = L.C L.NULLBOXED,
                       ty = B.boxedTy,
                       loc = loc},
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
              branches = [{constant = L.CONTAG 0w0, exp = exp3}],
              defaultExp = exp2,
              resultTy = ty2,
              loc = loc},
           ty2)
        end
      | Andalso nil => emitExp loc env True
      | Andalso [x] => emitExp loc env x
      | Andalso (True::t) => emitExp loc env (Andalso t)
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
