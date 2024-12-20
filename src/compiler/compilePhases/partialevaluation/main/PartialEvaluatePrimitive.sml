structure PartialEvaluatePrimitive =
struct

  structure R = RecordCalc
  structure P = BuiltinPrimitive
  structure T = BuiltinTypes

  datatype ty =
      INT8ty
    | INT16ty
    | INT32ty
    | INT64ty
    | WORD8ty
    | WORD16ty
    | WORD32ty
    | WORD64ty
    | REAL32ty
    | REAL64ty
    | OTHER

  fun typeOf ty =
      case TypesBasics.revealTy ty of
        Types.CONSTRUCTty {tyCon = {id, ...}, args = []} =>
        if TypID.eq (id, #id T.int8TyCon) then INT8ty
        else if TypID.eq (id, #id T.int16TyCon) then INT16ty
        else if TypID.eq (id, #id T.int32TyCon) then INT32ty
        else if TypID.eq (id, #id T.int64TyCon) then INT64ty
        else if TypID.eq (id, #id T.word8TyCon) then WORD8ty
        else if TypID.eq (id, #id T.word16TyCon) then WORD16ty
        else if TypID.eq (id, #id T.word32TyCon) then WORD32ty
        else if TypID.eq (id, #id T.word64TyCon) then WORD64ty
        else if TypID.eq (id, #id T.real32TyCon) then REAL32ty
        else if TypID.eq (id, #id T.real64TyCon) then REAL64ty
        else OTHER
      | _ => OTHER

  fun getValue (R.RCCAST {exp, ...}) = getValue exp
    | getValue (R.RCVALUE (R.RCCONSTANT (R.INT (R.CHAR c)), _)) =
      SOME (R.RCCONSTANT
              (R.INT (R.WORD8 (SMLSharp_Builtin.Char.castToWord8 c))))
    | getValue (R.RCVALUE (R.RCCONSTANT (R.INT (R.INT8 n)), _)) =
      SOME (R.RCCONSTANT
              (R.INT (R.WORD8 (SMLSharp_Builtin.Word8.fromInt8 n))))
    | getValue (R.RCVALUE (R.RCCONSTANT (R.INT (R.INT16 n)), _)) =
      SOME (R.RCCONSTANT
              (R.INT (R.WORD16 (SMLSharp_Builtin.Word16.fromInt16 n))))
    | getValue (R.RCVALUE (R.RCCONSTANT (R.INT (R.INT32 n)), _)) =
      SOME (R.RCCONSTANT
              (R.INT (R.WORD32 (SMLSharp_Builtin.Word32.fromInt32 n))))
    | getValue (R.RCVALUE (R.RCCONSTANT (R.INT (R.INT64 n)), _)) =
      SOME (R.RCCONSTANT
              (R.INT (R.WORD64 (SMLSharp_Builtin.Word64.fromInt64 n))))
    | getValue (R.RCVALUE (value, _)) = SOME value
    | getValue _ = NONE

  fun removeCast (R.RCCAST {exp, ...}) = removeCast exp
    | removeCast exp = exp

  fun Int8 n loc =
      R.RCVALUE (R.RCCONSTANT (R.INT (R.INT8 n)), loc)
  fun Int16 n loc =
      R.RCVALUE (R.RCCONSTANT (R.INT (R.INT16 n)), loc)
  fun Int32 n loc =
      R.RCVALUE (R.RCCONSTANT (R.INT (R.INT32 n)), loc)
  fun Int64 n loc =
      R.RCVALUE (R.RCCONSTANT (R.INT (R.INT64 n)), loc)
  fun Word8 n loc =
      R.RCVALUE (R.RCCONSTANT (R.INT (R.WORD8 n)), loc)
  fun Word16 n loc =
      R.RCVALUE (R.RCCONSTANT (R.INT (R.WORD16 n)), loc)
  fun Word32 n loc =
      R.RCVALUE (R.RCCONSTANT (R.INT (R.WORD32 n)), loc)
  fun Word64 n loc =
      R.RCVALUE (R.RCCONSTANT (R.INT (R.WORD64 n)), loc)
  fun Real32 n loc =
      R.RCVALUE (R.RCCONSTANT (R.CONST (R.REAL32 n)), loc)
  fun Real64 n loc =
      R.RCVALUE (R.RCCONSTANT (R.CONST (R.REAL64 n)), loc)

  fun Bool b loc =
      let
        val w = if b then 0w1 else 0w0
      in
        R.RCCAST {exp = R.RCVALUE (R.RCCONSTANT (R.INT (R.CONTAG w)), loc),
                  expTy = T.contagTy,
                  targetTy = T.boolTy,
                  cast = R.TypeCast,
                  loc = loc}
      end

  fun eval (primOp : TypedLambda.primInfo) argExpList loc =
      case (#primitive primOp, map getValue argExpList) of
        (P.R (P.M P.IdentityEqual),
         [SOME (R.RCVAR {id = id1, ...}),
          SOME (R.RCVAR {id = id2, ...})]) =>
        if id1 = id2 then SOME (Bool true loc) else NONE

      | (P.R (P.M P.IdentityEqual),
         [SOME (R.RCCONSTANT (R.INT n1)),
          SOME (R.RCCONSTANT (R.INT n2))]) =>
        if n1 = n2 then SOME (Bool true loc) else NONE

      | (P.R (P.M P.IdentityEqual),
         [SOME (R.RCCONSTANT (R.CONST R.UNIT)),
          SOME (R.RCCONSTANT (R.CONST R.UNIT))]) =>
        SOME (Bool true loc)

      | (P.R (P.M P.IdentityEqual),
         [SOME (R.RCCONSTANT (R.CONST R.NULLPOINTER)),
          SOME (R.RCCONSTANT (R.CONST R.NULLPOINTER))]) =>
        SOME (Bool true loc)

      | (P.R (P.M P.IdentityEqual),
         [SOME (R.RCCONSTANT (R.CONST R.NULLBOXED)),
          SOME (R.RCCONSTANT (R.CONST R.NULLBOXED))]) =>
        SOME (Bool true loc)

      | (P.R (P.M P.Int_add_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        (SOME (Int8 (SMLSharp_Builtin.Int8.add
                       (SMLSharp_Builtin.Word8.toInt8X n1,
                        SMLSharp_Builtin.Word8.toInt8X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_add_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        (SOME (Int16 (SMLSharp_Builtin.Int16.add
                        (SMLSharp_Builtin.Word16.toInt16X n1,
                         SMLSharp_Builtin.Word16.toInt16X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_add_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        (SOME (Int32 (SMLSharp_Builtin.Int32.add
                        (SMLSharp_Builtin.Word32.toInt32X n1,
                         SMLSharp_Builtin.Word32.toInt32X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_add_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        (SOME (Int64 (SMLSharp_Builtin.Int64.add
                        (SMLSharp_Builtin.Word64.toInt64X n1,
                         SMLSharp_Builtin.Word64.toInt64X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_gt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int8.gt
                      (SMLSharp_Builtin.Word8.toInt8X n1,
                       SMLSharp_Builtin.Word8.toInt8X n2))
                   loc)

      | (P.R (P.M P.Int_gt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int16.gt
                      (SMLSharp_Builtin.Word16.toInt16X n1,
                       SMLSharp_Builtin.Word16.toInt16X n2))
                   loc)

      | (P.R (P.M P.Int_gt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int32.gt
                      (SMLSharp_Builtin.Word32.toInt32X n1,
                       SMLSharp_Builtin.Word32.toInt32X n2))
                   loc)

      | (P.R (P.M P.Int_gt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int64.gt
                      (SMLSharp_Builtin.Word64.toInt64X n1,
                       SMLSharp_Builtin.Word64.toInt64X n2))
                   loc)

      | (P.R (P.M P.Int_gteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int8.gteq
                      (SMLSharp_Builtin.Word8.toInt8X n1,
                       SMLSharp_Builtin.Word8.toInt8X n2))
                   loc)

      | (P.R (P.M P.Int_gteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int16.gteq
                      (SMLSharp_Builtin.Word16.toInt16X n1,
                       SMLSharp_Builtin.Word16.toInt16X n2))
                   loc)

      | (P.R (P.M P.Int_gteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int32.gteq
                      (SMLSharp_Builtin.Word32.toInt32X n1,
                       SMLSharp_Builtin.Word32.toInt32X n2))
                   loc)

      | (P.R (P.M P.Int_gteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int64.gteq
                      (SMLSharp_Builtin.Word64.toInt64X n1,
                       SMLSharp_Builtin.Word64.toInt64X n2))
                   loc)

      | (P.R (P.M P.Int_lt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int8.lt
                      (SMLSharp_Builtin.Word8.toInt8X n1,
                       SMLSharp_Builtin.Word8.toInt8X n2))
                   loc)

      | (P.R (P.M P.Int_lt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int16.lt
                      (SMLSharp_Builtin.Word16.toInt16X n1,
                       SMLSharp_Builtin.Word16.toInt16X n2))
                   loc)

      | (P.R (P.M P.Int_lt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int32.lt
                      (SMLSharp_Builtin.Word32.toInt32X n1,
                       SMLSharp_Builtin.Word32.toInt32X n2))
                   loc)

      | (P.R (P.M P.Int_lt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int64.lt
                      (SMLSharp_Builtin.Word64.toInt64X n1,
                       SMLSharp_Builtin.Word64.toInt64X n2))
                   loc)

      | (P.R (P.M P.Int_lteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int8.lteq
                      (SMLSharp_Builtin.Word8.toInt8X n1,
                       SMLSharp_Builtin.Word8.toInt8X n2))
                   loc)

      | (P.R (P.M P.Int_lteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int16.lteq
                      (SMLSharp_Builtin.Word16.toInt16X n1,
                       SMLSharp_Builtin.Word16.toInt16X n2))
                   loc)

      | (P.R (P.M P.Int_lteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int32.lteq
                      (SMLSharp_Builtin.Word32.toInt32X n1,
                       SMLSharp_Builtin.Word32.toInt32X n2))
                   loc)

      | (P.R (P.M P.Int_lteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Int64.lteq
                      (SMLSharp_Builtin.Word64.toInt64X n1,
                       SMLSharp_Builtin.Word64.toInt64X n2))
                   loc)

      | (P.R (P.M P.Int_mul_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        (SOME (Int8 (SMLSharp_Builtin.Int8.mul
                       (SMLSharp_Builtin.Word8.toInt8X n1,
                        SMLSharp_Builtin.Word8.toInt8X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_mul_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        (SOME (Int16 (SMLSharp_Builtin.Int16.mul
                        (SMLSharp_Builtin.Word16.toInt16X n1,
                         SMLSharp_Builtin.Word16.toInt16X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_mul_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        (SOME (Int32 (SMLSharp_Builtin.Int32.mul
                        (SMLSharp_Builtin.Word32.toInt32X n1,
                         SMLSharp_Builtin.Word32.toInt32X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_mul_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        (SOME (Int64 (SMLSharp_Builtin.Int64.mul
                        (SMLSharp_Builtin.Word64.toInt64X n1,
                         SMLSharp_Builtin.Word64.toInt64X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_quot_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        (SOME (Int8 (SMLSharp_Builtin.Int8.quot
                       (SMLSharp_Builtin.Word8.toInt8X n1,
                        SMLSharp_Builtin.Word8.toInt8X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_quot_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        (SOME (Int16 (SMLSharp_Builtin.Int16.quot
                        (SMLSharp_Builtin.Word16.toInt16X n1,
                         SMLSharp_Builtin.Word16.toInt16X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_quot_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        (SOME (Int32 (SMLSharp_Builtin.Int32.quot
                        (SMLSharp_Builtin.Word32.toInt32X n1,
                         SMLSharp_Builtin.Word32.toInt32X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_quot_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        (SOME (Int64 (SMLSharp_Builtin.Int64.quot
                        (SMLSharp_Builtin.Word64.toInt64X n1,
                         SMLSharp_Builtin.Word64.toInt64X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_rem_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        (SOME (Int8 (SMLSharp_Builtin.Int8.rem
                       (SMLSharp_Builtin.Word8.toInt8X n1,
                        SMLSharp_Builtin.Word8.toInt8X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_rem_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        (SOME (Int16 (SMLSharp_Builtin.Int16.rem
                        (SMLSharp_Builtin.Word16.toInt16X n1,
                         SMLSharp_Builtin.Word16.toInt16X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_rem_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        (SOME (Int32 (SMLSharp_Builtin.Int32.rem
                        (SMLSharp_Builtin.Word32.toInt32X n1,
                         SMLSharp_Builtin.Word32.toInt32X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_rem_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        (SOME (Int64 (SMLSharp_Builtin.Int64.rem
                        (SMLSharp_Builtin.Word64.toInt64X n1,
                         SMLSharp_Builtin.Word64.toInt64X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_sub_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        (SOME (Int8 (SMLSharp_Builtin.Int8.sub
                       (SMLSharp_Builtin.Word8.toInt8X n1,
                        SMLSharp_Builtin.Word8.toInt8X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_sub_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        (SOME (Int16 (SMLSharp_Builtin.Int16.sub
                        (SMLSharp_Builtin.Word16.toInt16X n1,
                         SMLSharp_Builtin.Word16.toInt16X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_sub_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        (SOME (Int32 (SMLSharp_Builtin.Int32.sub
                        (SMLSharp_Builtin.Word32.toInt32X n1,
                         SMLSharp_Builtin.Word32.toInt32X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_sub_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        (SOME (Int64 (SMLSharp_Builtin.Int64.sub
                        (SMLSharp_Builtin.Word64.toInt64X n1,
                         SMLSharp_Builtin.Word64.toInt64X n2))
                    loc)
         handle Overflow => NONE)

      | (P.R (P.M P.Int_add_overflowCheck),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        ((SMLSharp_Builtin.Int8.add
            (SMLSharp_Builtin.Word8.toInt8X n1,
             SMLSharp_Builtin.Word8.toInt8X n2);
          SOME (Bool false loc))
         handle Overflow => SOME (Bool true loc))

      | (P.R (P.M P.Int_add_overflowCheck),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        ((SMLSharp_Builtin.Int16.add
            (SMLSharp_Builtin.Word16.toInt16X n1,
             SMLSharp_Builtin.Word16.toInt16X n2);
          SOME (Bool false loc))
         handle Overflow => SOME (Bool true loc))

      | (P.R (P.M P.Int_add_overflowCheck),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        ((SMLSharp_Builtin.Int32.add
            (SMLSharp_Builtin.Word32.toInt32X n1,
             SMLSharp_Builtin.Word32.toInt32X n2);
          SOME (Bool false loc))
         handle Overflow => SOME (Bool true loc))

      | (P.R (P.M P.Int_add_overflowCheck),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        ((SMLSharp_Builtin.Int64.add
            (SMLSharp_Builtin.Word64.toInt64X n1,
             SMLSharp_Builtin.Word64.toInt64X n2);
          SOME (Bool false loc))
         handle Overflow => SOME (Bool true loc))

      | (P.R (P.M P.Int_mul_overflowCheck),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        ((SMLSharp_Builtin.Int8.mul
            (SMLSharp_Builtin.Word8.toInt8X n1,
             SMLSharp_Builtin.Word8.toInt8X n2);
          SOME (Bool false loc))
         handle Overflow => SOME (Bool true loc))

      | (P.R (P.M P.Int_mul_overflowCheck),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        ((SMLSharp_Builtin.Int16.mul
            (SMLSharp_Builtin.Word16.toInt16X n1,
             SMLSharp_Builtin.Word16.toInt16X n2);
          SOME (Bool false loc))
         handle Overflow => SOME (Bool true loc))

      | (P.R (P.M P.Int_mul_overflowCheck),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        ((SMLSharp_Builtin.Int32.mul
            (SMLSharp_Builtin.Word32.toInt32X n1,
             SMLSharp_Builtin.Word32.toInt32X n2);
          SOME (Bool false loc))
         handle Overflow => SOME (Bool true loc))

      | (P.R (P.M P.Int_mul_overflowCheck),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        ((SMLSharp_Builtin.Int64.mul
            (SMLSharp_Builtin.Word64.toInt64X n1,
             SMLSharp_Builtin.Word64.toInt64X n2);
          SOME (Bool false loc))
         handle Overflow => SOME (Bool true loc))

      | (P.R (P.M P.Int_sub_overflowCheck),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        ((SMLSharp_Builtin.Int8.sub
            (SMLSharp_Builtin.Word8.toInt8X n1,
             SMLSharp_Builtin.Word8.toInt8X n2);
          SOME (Bool false loc))
         handle Overflow => SOME (Bool true loc))

      | (P.R (P.M P.Int_sub_overflowCheck),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        ((SMLSharp_Builtin.Int16.sub
            (SMLSharp_Builtin.Word16.toInt16X n1,
             SMLSharp_Builtin.Word16.toInt16X n2);
          SOME (Bool false loc))
         handle Overflow => SOME (Bool true loc))

      | (P.R (P.M P.Int_sub_overflowCheck),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        ((SMLSharp_Builtin.Int32.sub
            (SMLSharp_Builtin.Word32.toInt32X n1,
             SMLSharp_Builtin.Word32.toInt32X n2);
          SOME (Bool false loc))
         handle Overflow => SOME (Bool true loc))

      | (P.R (P.M P.Int_sub_overflowCheck),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        ((SMLSharp_Builtin.Int64.sub
            (SMLSharp_Builtin.Word64.toInt64X n1,
             SMLSharp_Builtin.Word64.toInt64X n2);
          SOME (Bool false loc))
         handle Overflow => SOME (Bool true loc))

      | (P.R (P.M P.Real_abs),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n)))]) =>
        SOME (Real32 (SMLSharp_Builtin.Real32.abs n) loc)

      | (P.R (P.M P.Real_abs),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n)))]) =>
        SOME (Real64 (SMLSharp_Builtin.Real64.abs n) loc)

      | (P.R (P.M P.Real_add),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL32 n2)))]) =>
         SOME (Real32 (SMLSharp_Builtin.Real32.add (n1, n2)) loc)

      | (P.R (P.M P.Real_add),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL64 n2)))]) =>
         SOME (Real64 (SMLSharp_Builtin.Real64.add (n1, n2)) loc)

      | (P.R (P.M P.Real_div),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL32 n2)))]) =>
         SOME (Real32 (SMLSharp_Builtin.Real32.div (n1, n2)) loc)

      | (P.R (P.M P.Real_div),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL64 n2)))]) =>
         SOME (Real64 (SMLSharp_Builtin.Real64.div (n1, n2)) loc)

      | (P.R (P.M P.Real_equal),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL32 n2)))]) =>
         SOME (Bool (SMLSharp_Builtin.Real32.equal (n1, n2)) loc)

      | (P.R (P.M P.Real_equal),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL64 n2)))]) =>
         SOME (Bool (SMLSharp_Builtin.Real64.equal (n1, n2)) loc)

      | (P.R (P.M P.Real_unorderedOrEqual),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL32 n2)))]) =>
         SOME (Bool (SMLSharp_Builtin.Real32.ueq (n1, n2)) loc)

      | (P.R (P.M P.Real_unorderedOrEqual),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL64 n2)))]) =>
         SOME (Bool (SMLSharp_Builtin.Real64.ueq (n1, n2)) loc)

      | (P.R (P.M P.Real_gt),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL32 n2)))]) =>
         SOME (Bool (SMLSharp_Builtin.Real32.gt (n1, n2)) loc)

      | (P.R (P.M P.Real_gt),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL64 n2)))]) =>
         SOME (Bool (SMLSharp_Builtin.Real64.gt (n1, n2)) loc)

      | (P.R (P.M P.Real_gteq),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL32 n2)))]) =>
         SOME (Bool (SMLSharp_Builtin.Real32.gteq (n1, n2)) loc)

      | (P.R (P.M P.Real_gteq),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL64 n2)))]) =>
         SOME (Bool (SMLSharp_Builtin.Real64.gteq (n1, n2)) loc)

      | (P.R (P.M P.Real_isNan),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n)))]) =>
        SOME (Bool (SMLSharp_Builtin.Real32.isNan n) loc)

      | (P.R (P.M P.Real_isNan),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n)))]) =>
        SOME (Bool (SMLSharp_Builtin.Real64.isNan n) loc)

      | (P.R (P.M P.Real_lt),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL32 n2)))]) =>
         SOME (Bool (SMLSharp_Builtin.Real32.lt (n1, n2)) loc)

      | (P.R (P.M P.Real_lt),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL64 n2)))]) =>
         SOME (Bool (SMLSharp_Builtin.Real64.lt (n1, n2)) loc)

      | (P.R (P.M P.Real_lteq),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL32 n2)))]) =>
         SOME (Bool (SMLSharp_Builtin.Real32.lteq (n1, n2)) loc)

      | (P.R (P.M P.Real_lteq),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL64 n2)))]) =>
         SOME (Bool (SMLSharp_Builtin.Real64.lteq (n1, n2)) loc)

      | (P.R (P.M P.Real_mul),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL32 n2)))]) =>
         SOME (Real32 (SMLSharp_Builtin.Real32.mul (n1, n2)) loc)

      | (P.R (P.M P.Real_mul),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL64 n2)))]) =>
         SOME (Real64 (SMLSharp_Builtin.Real64.mul (n1, n2)) loc)

      | (P.R (P.M P.Real_rem),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL32 n2)))]) =>
         SOME (Real32 (SMLSharp_Builtin.Real32.rem (n1, n2)) loc)

      | (P.R (P.M P.Real_rem),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL64 n2)))]) =>
         SOME (Real64 (SMLSharp_Builtin.Real64.rem (n1, n2)) loc)

      | (P.R (P.M P.Real_sub),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL32 n2)))]) =>
         SOME (Real32 (SMLSharp_Builtin.Real32.sub (n1, n2)) loc)

      | (P.R (P.M P.Real_sub),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n1))),
          SOME (R.RCCONSTANT (R.CONST (R.REAL64 n2)))]) =>
         SOME (Real64 (SMLSharp_Builtin.Real64.sub (n1, n2)) loc)

      | (P.R (P.M P.Real_fpext_fptrunc),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n)))]) =>
        (case typeOf (#resultTy (#ty primOp)) of
           REAL32ty =>
           SOME (Real32 n loc)
         | REAL64ty =>
           SOME (Real64 (SMLSharp_Builtin.Real32.toReal64 n) loc)
         | _ => NONE)

      | (P.R (P.M P.Real_fpext_fptrunc),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n)))]) =>
        (case typeOf (#resultTy (#ty primOp)) of
           REAL32ty =>
           SOME (Real32 (SMLSharp_Builtin.Real32.fromReal64 n) loc)
         | REAL64ty =>
           SOME (Real64 n loc)
         | _ => NONE)

      | (P.R (P.M P.Real_fptoui),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n)))]) =>
        (*
        (case typeOf (#resultTy (#ty primOp)) of
           WORD8ty =>
           SOME (Word8 (SMLSharp_Builtin.Real32.toWord8_unsafe n) loc)
         | WORD16ty =>
           SOME (Word16 (SMLSharp_Builtin.Real32.toWord16_unsafe n) loc)
         | WORD32ty =>
           SOME (Word32 (SMLSharp_Builtin.Real32.toWord32_unsafe n) loc)
         | WORD64ty =>
           SOME (Word64 (SMLSharp_Builtin.Real32.toWord64_unsafe n) loc)
         | _ => NONE)
        *)
        NONE (* FIXME *)

      | (P.R (P.M P.Real_fptoui),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n)))]) =>
        (*
        (case typeOf (#resultTy (#ty primOp)) of
           WORD8ty =>
           SOME (Word8 (SMLSharp_Builtin.Real64.toWord8_unsafe n) loc)
         | WORD16ty =>
           SOME (Word16 (SMLSharp_Builtin.Real64.toWord16_unsafe n) loc)
         | WORD64ty =>
           SOME (Word32 (SMLSharp_Builtin.Real64.toWord64_unsafe n) loc)
         | WORD64ty =>
           SOME (Word64 (SMLSharp_Builtin.Real64.toWord64_unsafe n) loc)
         | _ => NONE)
        *)
        NONE (* FIXME *)

      | (P.R (P.M P.Real_fromInt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n)))]) =>
        (case typeOf (#resultTy (#ty primOp)) of
           REAL32ty =>
           SOME (Real32 (SMLSharp_Builtin.Real32.fromInt8
                           (SMLSharp_Builtin.Word8.toInt8X n))
                        loc)
         | REAL64ty =>
           SOME (Real64 (SMLSharp_Builtin.Real64.fromInt8
                           (SMLSharp_Builtin.Word8.toInt8X n))
                        loc)
         | _ => NONE)

      | (P.R (P.M P.Real_fromInt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n)))]) =>
        (case typeOf (#resultTy (#ty primOp)) of
           REAL32ty =>
           SOME (Real32 (SMLSharp_Builtin.Real32.fromInt16
                           (SMLSharp_Builtin.Word16.toInt16X n))
                        loc)
         | REAL64ty =>
           SOME (Real64 (SMLSharp_Builtin.Real64.fromInt16
                           (SMLSharp_Builtin.Word16.toInt16X n))
                        loc)
         | _ => NONE)

      | (P.R (P.M P.Real_fromInt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n)))]) =>
        (case typeOf (#resultTy (#ty primOp)) of
           REAL32ty =>
           SOME (Real32 (SMLSharp_Builtin.Real32.fromInt32
                           (SMLSharp_Builtin.Word32.toInt32X n))
                        loc)
         | REAL64ty =>
           SOME (Real64 (SMLSharp_Builtin.Real64.fromInt32
                           (SMLSharp_Builtin.Word32.toInt32X n))
                        loc)
         | _ => NONE)

      | (P.R (P.M P.Real_fromInt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n)))]) =>
        (case typeOf (#resultTy (#ty primOp)) of
           REAL32ty =>
           SOME (Real32 (SMLSharp_Builtin.Real32.fromInt64
                           (SMLSharp_Builtin.Word64.toInt64X n))
                        loc)
         | REAL64ty =>
           SOME (Real64 (SMLSharp_Builtin.Real64.fromInt64
                           (SMLSharp_Builtin.Word64.toInt64X n))
                        loc)
         | _ => NONE)

      | (P.R (P.M P.Real_trunc_unsafe),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL32 n)))]) =>
        (SOME (Int32 (SMLSharp_Builtin.Real32.trunc n) loc)
         handle _ => NONE)

      | (P.R (P.M P.Real_trunc_unsafe),
         [SOME (R.RCCONSTANT (R.CONST (R.REAL64 n)))]) =>
        (SOME (Int32 (SMLSharp_Builtin.Real64.trunc n) loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_add),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        SOME (Word8 (SMLSharp_Builtin.Word8.add (n1, n2)) loc)

      | (P.R (P.M P.Word_add),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        SOME (Word16 (SMLSharp_Builtin.Word16.add (n1, n2)) loc)

      | (P.R (P.M P.Word_add),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        SOME (Word32 (SMLSharp_Builtin.Word32.add (n1, n2)) loc)

      | (P.R (P.M P.Word_add),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        SOME (Word64 (SMLSharp_Builtin.Word64.add (n1, n2)) loc)

      | (P.R (P.M P.Word_andb),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        SOME (Word8 (SMLSharp_Builtin.Word8.andb (n1, n2)) loc)

      | (P.R (P.M P.Word_andb),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        SOME (Word16 (SMLSharp_Builtin.Word16.andb (n1, n2)) loc)

      | (P.R (P.M P.Word_andb),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        SOME (Word32 (SMLSharp_Builtin.Word32.andb (n1, n2)) loc)

      | (P.R (P.M P.Word_andb),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        SOME (Word64 (SMLSharp_Builtin.Word64.andb (n1, n2)) loc)

      | (P.R (P.M P.Word_arshift_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        (SOME (Word8 (SMLSharp_Builtin.Word8.arshift
                        (n1, SMLSharp_Builtin.Word8.toWord32 n2))
                     loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_arshift_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        (SOME (Word16 (SMLSharp_Builtin.Word16.arshift
                        (n1, SMLSharp_Builtin.Word16.toWord32 n2))
                      loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_arshift_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        (SOME (Word32 (SMLSharp_Builtin.Word32.arshift (n1, n2)) loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_arshift_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        (SOME (Word64 (SMLSharp_Builtin.Word64.arshift
                        (n1, SMLSharp_Builtin.Word64.toWord32 n2))
                      loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_div_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        (SOME (Word8 (SMLSharp_Builtin.Word8.div (n1, n2)) loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_div_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        (SOME (Word16 (SMLSharp_Builtin.Word16.div (n1, n2)) loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_div_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        (SOME (Word32 (SMLSharp_Builtin.Word32.div (n1, n2)) loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_div_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        (SOME (Word64 (SMLSharp_Builtin.Word64.div (n1, n2)) loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_gt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word8.gt (n1, n2)) loc)

      | (P.R (P.M P.Word_gt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word16.gt (n1, n2)) loc)

      | (P.R (P.M P.Word_gt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word32.gt (n1, n2)) loc)

      | (P.R (P.M P.Word_gt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word64.gt (n1, n2)) loc)

      | (P.R (P.M P.Word_gteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word8.gteq (n1, n2)) loc)

      | (P.R (P.M P.Word_gteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word16.gteq (n1, n2)) loc)

      | (P.R (P.M P.Word_gteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word32.gteq (n1, n2)) loc)

      | (P.R (P.M P.Word_gteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word64.gteq (n1, n2)) loc)

      | (P.R (P.M P.Word_lshift_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        (SOME (Word8 (SMLSharp_Builtin.Word8.lshift
                        (n1, SMLSharp_Builtin.Word8.toWord32 n2))
                     loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_lshift_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        (SOME (Word16 (SMLSharp_Builtin.Word16.lshift
                        (n1, SMLSharp_Builtin.Word16.toWord32 n2))
                      loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_lshift_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        (SOME (Word32 (SMLSharp_Builtin.Word32.lshift (n1, n2)) loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_lshift_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        (SOME (Word64 (SMLSharp_Builtin.Word64.lshift
                        (n1, SMLSharp_Builtin.Word64.toWord32 n2))
                      loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_lt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word8.lt (n1, n2)) loc)

      | (P.R (P.M P.Word_lt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word16.lt (n1, n2)) loc)

      | (P.R (P.M P.Word_lt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word32.lt (n1, n2)) loc)

      | (P.R (P.M P.Word_lt),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word64.lt (n1, n2)) loc)

      | (P.R (P.M P.Word_lteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word8.lteq (n1, n2)) loc)

      | (P.R (P.M P.Word_lteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word16.lteq (n1, n2)) loc)

      | (P.R (P.M P.Word_lteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word32.lteq (n1, n2)) loc)

      | (P.R (P.M P.Word_lteq),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        SOME (Bool (SMLSharp_Builtin.Word64.lteq (n1, n2)) loc)

      | (P.R (P.M P.Word_mod_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        (SOME (Word8 (SMLSharp_Builtin.Word8.mod (n1, n2)) loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_mod_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        (SOME (Word16 (SMLSharp_Builtin.Word16.mod (n1, n2)) loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_mod_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        (SOME (Word32 (SMLSharp_Builtin.Word32.mod (n1, n2)) loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_mod_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        (SOME (Word64 (SMLSharp_Builtin.Word64.mod (n1, n2)) loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_mul),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        SOME (Word8 (SMLSharp_Builtin.Word8.mul (n1, n2)) loc)

      | (P.R (P.M P.Word_mul),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        SOME (Word16 (SMLSharp_Builtin.Word16.mul (n1, n2)) loc)

      | (P.R (P.M P.Word_mul),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        SOME (Word32 (SMLSharp_Builtin.Word32.mul (n1, n2)) loc)

      | (P.R (P.M P.Word_mul),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        SOME (Word64 (SMLSharp_Builtin.Word64.mul (n1, n2)) loc)

      | (P.R (P.M P.Word_orb),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        SOME (Word8 (SMLSharp_Builtin.Word8.orb (n1, n2)) loc)

      | (P.R (P.M P.Word_orb),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        SOME (Word16 (SMLSharp_Builtin.Word16.orb (n1, n2)) loc)

      | (P.R (P.M P.Word_orb),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        SOME (Word32 (SMLSharp_Builtin.Word32.orb (n1, n2)) loc)

      | (P.R (P.M P.Word_orb),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        SOME (Word64 (SMLSharp_Builtin.Word64.orb (n1, n2)) loc)

      | (P.R (P.M P.Word_rshift_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        (SOME (Word8 (SMLSharp_Builtin.Word8.rshift
                        (n1, SMLSharp_Builtin.Word8.toWord32 n2))
                     loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_rshift_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        (SOME (Word16 (SMLSharp_Builtin.Word16.rshift
                         (n1, SMLSharp_Builtin.Word16.toWord32 n2))
                      loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_rshift_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        (SOME (Word32 (SMLSharp_Builtin.Word32.rshift (n1, n2)) loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_rshift_unsafe),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        (SOME (Word64 (SMLSharp_Builtin.Word64.rshift
                         (n1, SMLSharp_Builtin.Word64.toWord32 n2))
                      loc)
         handle _ => NONE)

      | (P.R (P.M P.Word_sub),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        SOME (Word8 (SMLSharp_Builtin.Word8.sub (n1, n2)) loc)

      | (P.R (P.M P.Word_sub),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        SOME (Word16 (SMLSharp_Builtin.Word16.sub (n1, n2)) loc)

      | (P.R (P.M P.Word_sub),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        SOME (Word32 (SMLSharp_Builtin.Word32.sub (n1, n2)) loc)

      | (P.R (P.M P.Word_sub),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        SOME (Word64 (SMLSharp_Builtin.Word64.sub (n1, n2)) loc)

      | (P.R (P.M P.Word_xorb),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD8 n2)))]) =>
        SOME (Word8 (SMLSharp_Builtin.Word8.xorb (n1, n2)) loc)

      | (P.R (P.M P.Word_xorb),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD16 n2)))]) =>
        SOME (Word16 (SMLSharp_Builtin.Word16.xorb (n1, n2)) loc)

      | (P.R (P.M P.Word_xorb),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD32 n2)))]) =>
        SOME (Word32 (SMLSharp_Builtin.Word32.xorb (n1, n2)) loc)

      | (P.R (P.M P.Word_xorb),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n1))),
          SOME (R.RCCONSTANT (R.INT (R.WORD64 n2)))]) =>
        SOME (Word64 (SMLSharp_Builtin.Word64.xorb (n1, n2)) loc)

      | (P.R (P.M P.Word_zext_trunc),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n)))]) =>
        (case typeOf (#resultTy (#ty primOp)) of
           WORD8ty => SOME (Word8 n loc)
         | WORD16ty => SOME (Word16 (SMLSharp_Builtin.Word8.toWord16 n) loc)
         | WORD32ty => SOME (Word32 (SMLSharp_Builtin.Word8.toWord32 n) loc)
         | WORD64ty => SOME (Word64 (SMLSharp_Builtin.Word8.toWord64 n) loc)
         | _ => NONE)

      | (P.R (P.M P.Word_zext_trunc),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n)))]) =>
        (case typeOf (#resultTy (#ty primOp)) of
           WORD8ty => SOME (Word8 (SMLSharp_Builtin.Word16.toWord8 n) loc)
         | WORD16ty => SOME (Word16 n loc)
         | WORD32ty => SOME (Word32 (SMLSharp_Builtin.Word16.toWord32 n) loc)
         | WORD64ty => SOME (Word64 (SMLSharp_Builtin.Word16.toWord64 n) loc)
         | _ => NONE)

      | (P.R (P.M P.Word_zext_trunc),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n)))]) =>
        (case typeOf (#resultTy (#ty primOp)) of
           WORD8ty => SOME (Word8 (SMLSharp_Builtin.Word32.toWord8 n) loc)
         | WORD16ty => SOME (Word16 (SMLSharp_Builtin.Word32.toWord16 n) loc)
         | WORD32ty => SOME (Word32 n loc)
         | WORD64ty => SOME (Word64 (SMLSharp_Builtin.Word32.toWord64 n) loc)
         | _ => NONE)

      | (P.R (P.M P.Word_zext_trunc),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n)))]) =>
        (case typeOf (#resultTy (#ty primOp)) of
           WORD8ty => SOME (Word8 (SMLSharp_Builtin.Word64.toWord8 n) loc)
         | WORD16ty => SOME (Word16 (SMLSharp_Builtin.Word64.toWord16 n) loc)
         | WORD32ty => SOME (Word32 (SMLSharp_Builtin.Word64.toWord32 n) loc)
         | WORD64ty => SOME (Word64 n loc)
         | _ => NONE)

      | (P.R (P.M P.Word_sext_trunc),
         [SOME (R.RCCONSTANT (R.INT (R.WORD8 n)))]) =>
        (case typeOf (#resultTy (#ty primOp)) of
           WORD8ty => SOME (Word8 n loc)
         | WORD16ty => SOME (Word16 (SMLSharp_Builtin.Word8.toWord16X n) loc)
         | WORD32ty => SOME (Word32 (SMLSharp_Builtin.Word8.toWord32X n) loc)
         | WORD64ty => SOME (Word64 (SMLSharp_Builtin.Word8.toWord64X n) loc)
         | _ => NONE)

      | (P.R (P.M P.Word_sext_trunc),
         [SOME (R.RCCONSTANT (R.INT (R.WORD16 n)))]) =>
        (case typeOf (#resultTy (#ty primOp)) of
           WORD8ty => SOME (Word8 (SMLSharp_Builtin.Word16.toWord8 n) loc)
         | WORD16ty => SOME (Word16 n loc)
         | WORD32ty => SOME (Word32 (SMLSharp_Builtin.Word16.toWord32X n) loc)
         | WORD64ty => SOME (Word64 (SMLSharp_Builtin.Word16.toWord64X n) loc)
         | _ => NONE)

      | (P.R (P.M P.Word_sext_trunc),
         [SOME (R.RCCONSTANT (R.INT (R.WORD32 n)))]) =>
        (case typeOf (#resultTy (#ty primOp)) of
           WORD8ty => SOME (Word8 (SMLSharp_Builtin.Word32.toWord8 n) loc)
         | WORD16ty => SOME (Word16 (SMLSharp_Builtin.Word32.toWord16 n) loc)
         | WORD32ty => SOME (Word32 n loc)
         | WORD64ty => SOME (Word64 (SMLSharp_Builtin.Word32.toWord64X n) loc)
         | _ => NONE)

      | (P.R (P.M P.Word_sext_trunc),
         [SOME (R.RCCONSTANT (R.INT (R.WORD64 n)))]) =>
        (case typeOf (#resultTy (#ty primOp)) of
           WORD8ty => SOME (Word8 (SMLSharp_Builtin.Word64.toWord8 n) loc)
         | WORD16ty => SOME (Word16 (SMLSharp_Builtin.Word64.toWord16 n) loc)
         | WORD32ty => SOME (Word32 (SMLSharp_Builtin.Word64.toWord32 n) loc)
         | WORD64ty => SOME (Word64 n loc)
         | _ => NONE)

      | _ => NONE

end
