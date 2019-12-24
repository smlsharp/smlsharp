(**
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure RecordLayout2 :> sig

  type computationAccum
  val newComputationAccum : unit -> computationAccum
  val extractDecls : computationAccum -> RecordLayoutCalc.dec list

  val computeIndex
      : computationAccum
        -> {size: RecordLayoutCalc.value} list * {size: RecordLayoutCalc.value}
        -> RecordLayoutCalc.value
  val computeRecord
      : computationAccum
        -> {tag: RecordLayoutCalc.value, size: RecordLayoutCalc.value} list
        -> {allocSize: RecordLayoutCalc.value,
            fieldIndexes: RecordLayoutCalc.value list,
            bitmaps: {index: RecordLayoutCalc.value,
                      bitmap: RecordLayoutCalc.value} list,
            padding: bool}

end =
struct

  structure T = Types
  type varInfo = RecordLayoutCalc.varInfo

  val getSize = RuntimeTypes.getSize

  fun bitmapWordSize () =
      getSize (#size RuntimeTypes.word32Ty)

  fun bitmapWordBits () =
      bitmapWordSize () * TypeLayout2.charBits

  fun pointerSize () =
      getSize (#size RuntimeTypes.recordTy)

  fun maxShift () =
      let
        val maxSize = RuntimeTypes.getSize TypeLayout2.maxSize
        val pointerSize = pointerSize ()
        val maxShift = maxSize div pointerSize
      in
        if maxSize mod pointerSize = 0
        then () else raise Bug.Bug "maxShift 1";
        if 0 < maxShift andalso maxShift < bitmapWordBits ()
        then () else raise Bug.Bug "maxShift 2";
        maxShift
      end

  fun newVar () =
      let
        val id = VarID.generate ()
      in
        {id = id, path = [Symbol.generate ()], ty = BuiltinTypes.word32Ty}
        : varInfo
      end

  datatype value = datatype RecordLayoutCalc.value

  local
    fun order (VAR _) = 0
      | order (TAG _) = 1
      | order (SIZE _) = 2
      | order (CONST _) = 3
      | order (CAST _) = 4
    fun compareByOrder (v1, v2) = Int.compare (order v1, order v2)
  in
  fun compareValue (v1, v2) =
      case (v1, v2) of
        (VAR {id=id1,...}, VAR {id=id2,...}) => VarID.compare (id1, id2)
      | (VAR _, _) => compareByOrder (v1, v2)
      | (TAG (_, n1), TAG (_, n2)) =>
        Int.compare (TypeLayout2.tagValue n1, TypeLayout2.tagValue n2)
      | (TAG _, _) => compareByOrder (v1, v2)
      | (SIZE (_, n1), SIZE (_, n2)) => Int.compare (getSize n1, getSize n2)
      | (SIZE _, _) => compareByOrder (v1, v2)
      | (CONST n1, CONST n2) => Word32.compare (n1, n2)
      | (CONST _, _) => compareByOrder (v1, v2)
      | (CAST (v1, _), CAST (v2, _)) => compareValue (v1, v2)
      | (CAST _, _) => compareByOrder (v1, v2)
  end (* local *)

  fun const n =
      CONST (Word32.fromInt n)

  fun isWordTy ty =
      case TypesBasics.derefTy ty of
        T.CONSTRUCTty {tyCon, ...} =>
        TypID.eq (#id tyCon, #id BuiltinTypes.word32TyCon)
      | _ => false

  fun coerceToWord value =
      case value of
        CONST w => CONST w
      | VAR (var as {ty,...}) =>
        if isWordTy ty
        then VAR var
        else CAST (VAR var, BuiltinTypes.word32Ty)
      | SIZE (_, n) => const (getSize n)
      | TAG (_, n) => const (TypeLayout2.tagValue n)
      | CAST (v, _) => coerceToWord v

  datatype exp = datatype RecordLayoutCalc.exp
  datatype op2 = datatype RecordLayoutCalc.op2

  local
    fun commute (v1, v2) =
        case compareValue (v1, v2) of
          GREATER => (v1, v2)
        | EQUAL => (v1, v2)
        | LESS => (v2, v1)
  in
  fun normalizeExp exp =
      case exp of
        OP (ADD, (CONST n1, CONST n2)) => VALUE (CONST (Word32.+ (n1, n2)))
      | OP (ADD, (x, CONST 0w0)) => VALUE x
      | OP (ADD, (CONST 0w0, x)) => VALUE x
      | OP (ADD, x) => OP (ADD, commute x)
      | OP (SUB, (CONST n1, CONST n2)) => VALUE (CONST (Word32.- (n1, n2)))
      | OP (SUB, (x, CONST 0w0)) => VALUE x
      | OP (SUB, x) => exp
      | OP (DIV, (CONST n1, CONST n2)) => VALUE (CONST (Word32.div (n1, n2)))
      | OP (DIV, (x, CONST 0w1)) => VALUE x
      | OP (DIV, (x, CONST 0w2)) => normalizeExp (OP (RSHIFT, (x, CONST 0w1)))
      | OP (DIV, (x, CONST 0w4)) => normalizeExp (OP (RSHIFT, (x, CONST 0w2)))
      | OP (DIV, (x, CONST 0w8)) => normalizeExp (OP (RSHIFT, (x, CONST 0w3)))
      | OP (DIV, (x, CONST 0w16)) => normalizeExp (OP (RSHIFT, (x, CONST 0w4)))
      | OP (DIV, x) => exp
      | OP (AND, (CONST n1, CONST n2)) => VALUE (CONST (Word32.andb (n1, n2)))
      | OP (AND, (x as (v, CONST m))) =>
        if m = Word32.fromInt ~1 then VALUE v else OP (AND, commute x)
      | OP (AND, x) => OP (AND, commute x)
      | OP (OR, (CONST n1, CONST n2)) => VALUE (CONST (Word32.orb (n1, n2)))
      | OP (OR, (x, CONST 0w0)) => VALUE x
      | OP (OR, x) => OP (OR, commute x)
      | OP (LSHIFT, (CONST 0w0, _)) => VALUE (CONST 0w0)
      | OP (LSHIFT, (CONST n1, CONST n2)) =>
        VALUE (CONST (Word32.<< (n1, Word.fromInt (Word32.toIntX n2))))
      | OP (LSHIFT, (x, CONST 0w0)) => VALUE x
      | OP (LSHIFT, (x, CONST 0w1)) => normalizeExp (OP (ADD, (x, x)))
      | OP (LSHIFT, (x, CONST n)) =>
        if n >= Word32.fromInt (bitmapWordBits ())
        then VALUE (CONST 0w0)
        else exp
      | OP (LSHIFT, x) => exp
      | OP (RSHIFT, (CONST 0w0, _)) => VALUE (CONST 0w0)
      | OP (RSHIFT, (CONST n1, CONST n2)) =>
        VALUE (CONST (Word32.>> (n1, Word.fromInt (Word32.toIntX n2))))
      | OP (RSHIFT, (x, CONST 0w0)) => VALUE x
      | OP (RSHIFT, (x, CONST n)) =>
        if n >= Word32.fromInt (bitmapWordBits ())
        then VALUE (CONST 0w0)
        else exp
      | OP (RSHIFT, x) => exp
      | VALUE x => exp
  end (* local *)

  local
    fun order ADD = 0
      | order SUB = 1
      | order DIV = 2
      | order AND = 3
      | order OR = 4
      | order LSHIFT = 5
      | order RSHIFT = 6
    fun compareByOrder (e1, e2) = Int.compare (order e1, order e2)
    fun compareOp2 ((op1, (v11, v12)), (op2, (v21, v22))) =
        case Int.compare (order op1, order op2) of
          EQUAL => (case compareValue (v11, v21) of
                      EQUAL => compareValue (v21, v22)
                    | x => x)
        | x => x
  in
  fun compareExp (e1, e2) =
      case (e1, e2) of
        (OP x, OP y) => compareOp2 (x, y)
      | (OP x, VALUE y) => GREATER
      | (VALUE x, OP y) => LESS
      | (VALUE x, VALUE y) => compareValue (x, y)
  end (* local *)

  structure ExpMap = BinaryMapFn(type ord_key = exp val compare = compareExp)

  datatype dec = datatype RecordLayoutCalc.dec

  type computationAccum =
       (varInfo ExpMap.map * dec list) ref

  fun newComputationAccum () =
      ref (ExpMap.empty, nil) : computationAccum

  fun extractDecls (comp as ref (_, decls) : computationAccum) =
      (comp := (ExpMap.empty, nil); rev decls)

  fun compute (comp as ref (map, decs)) exp =
      case normalizeExp exp of
        VALUE v => v
      | OP _ =>
        case ExpMap.find (map, exp) of
          SOME var => VAR var
        | NONE =>
          let
            val var = newVar ()
          in
            comp := (ExpMap.insert (map, exp, var), VAL (var, exp) :: decs);
            VAR var
          end

  fun alignSize comp (accumSize, nextFieldSize) =
      case (TypeLayout2.sizeAssumption, TypeLayout2.alignComputation) of
        (TypeLayout2.ALL_SIZES_ARE_POWER_OF_2, TypeLayout2.ALIGN_EQUAL_SIZE) =>
        (*
         * newAccumSize = (accumSize + (fieldSize - 1)) & ~(fieldSize - 1)
         *              = (accumSize + fieldSize - 1) & (-fieldSize)
         *)
        let
          val tmp1 = compute comp (OP (ADD, (accumSize, nextFieldSize)))
          val tmp2 = compute comp (OP (SUB, (tmp1, CONST 0w1)))
          val tmp3 = compute comp (OP (SUB, (CONST 0w0, nextFieldSize)))
          val tmp4 = compute comp (OP (AND, (tmp2, tmp3)))
        in
          tmp4
        end

  fun getAccumSizeRev nil = CONST 0w0
    | getAccumSizeRev ({fieldIndex:value, accumSize}::fieldsRev) = accumSize

  (* computeIndexRev (f_{n+1}, [f_n, ..., f_1]) returns the index of
   * field f_{n+1} of record { f_1, ..., f_n, f_{n+1} }. *)
  fun computeIndexRev comp ({size=lastFieldSize}, fieldsRev) =
      let
        val (padded1, layoutRev) = computeLayoutRev comp fieldsRev
        val accumSize = getAccumSizeRev layoutRev
        val fieldIndex = alignSize comp (accumSize, lastFieldSize)
        val padded2 =
            case (accumSize, fieldIndex) of
              (CONST accumSize, CONST fieldIndex) => accumSize <> fieldIndex
            | _ => true
      in
        (padded1 orelse padded2, fieldIndex, layoutRev)
      end

  (* computeLayoutRev ([f_n, ..., f_1]) returns
   * the layout of record { f_1, ..., f_n }. *)
  and computeLayoutRev comp nil = (false, nil)
    | computeLayoutRev comp ((lastField as {size})::fieldsRev) =
      let
        val (padded, fieldIndex, layoutRev) =
            computeIndexRev comp (lastField, fieldsRev)
        val accumSize = compute comp (OP (ADD, (fieldIndex, size)))
      in
        (padded, {fieldIndex = fieldIndex, accumSize = accumSize} :: layoutRev)
      end

  fun alignAccumSizeRev comp nil = (false, nil)
    | alignAccumSizeRev comp ({fieldIndex:value, accumSize}::fieldsRev) =
      let
        (* align accumSize to word boundary *)
        val accumSize' = alignSize comp (accumSize, const (pointerSize ()))
        val padded =
            case (accumSize, accumSize') of
              (CONST accumSize, CONST accumSize') => accumSize <> accumSize'
            | _ => true
      in
          (padded, {fieldIndex = fieldIndex, accumSize = accumSize'}::fieldsRev)
      end

  fun estimateMaxShift value =
      case value of
        CONST n => Word32.toInt n
      | _ => maxShift ()

  (* computeBitIndex [f_1, ..., f_n] computes each bit in the bitmap of
   * record {f_1, ..., f_n}.
   *)
  fun computeBitIndex comp nil = (CONST 0w0, nil)
    | computeBitIndex comp [{tag, index, accumSize}] =
      let
        val pointerSize = const (pointerSize ())
        val bitIndex = compute comp (OP (DIV, (index, pointerSize)))
        val prevComp = !comp
        val totalBits = compute comp (OP (DIV, (accumSize, pointerSize)))
        val tmpBitWidth = compute comp (OP (SUB, (totalBits, bitIndex)))
        val bitWidth = const (estimateMaxShift tmpBitWidth)
        val _ = comp := prevComp
      in
        (bitIndex, [{tag = tag, bitWidth = bitWidth}])
      end
    | computeBitIndex comp ({tag:value, index, accumSize}::bits) =
      let
        val (nextIndex, bits) = computeBitIndex comp bits
        val pointerSize = const (pointerSize ())
        val bitIndex = compute comp (OP (DIV, (index, pointerSize)))
        val bitWidth = compute comp (OP (SUB, (nextIndex, bitIndex)))
      in
        (bitIndex, {tag = tag, bitWidth = bitWidth} :: bits)
      end

  type bitmap =
       {maxNumBits : int, words : value list}

  val emptyBitmap =
      {maxNumBits = 0, words = nil} : bitmap

  fun setBitmapBit comp ({maxNumBits, words=nil}, bit) =
      {maxNumBits = 1, words = [bit]} : bitmap
    | setBitmapBit comp ({maxNumBits, words=word::words}, bit) =
      {maxNumBits = maxNumBits,
       words = compute comp (OP (OR, (word, bit))) :: words}

  (* lshift must be less than bitmapWordBits *)
  fun shiftBitmap comp (bitmap, CONST 0w0) = bitmap
    | shiftBitmap comp ({maxNumBits, words=nil}, lshift) =
      {maxNumBits = estimateMaxShift lshift, words = [CONST 0w0]}
    | shiftBitmap comp ({maxNumBits, words=word::words}, lshift) =
      let
        val maxShift = estimateMaxShift lshift
        val bitmapWordBits = bitmapWordBits ()
        val rshift = compute comp (OP (SUB, (const bitmapWordBits, lshift)))
        fun shiftLoop (word, nil, numBits) =
            if numBits + maxShift <= bitmapWordBits
            then (compute comp (OP (LSHIFT, (word, lshift))), nil)
            else (compute comp (OP (LSHIFT, (word, lshift))),
                  [compute comp (OP (RSHIFT, (word, rshift)))])
          | shiftLoop (word1, word2::words, numBits) =
            let
              val (word2, words) =
                  shiftLoop (word2, words, numBits - bitmapWordBits)
              val word1 = compute comp (OP (LSHIFT, (word, lshift)))
              val carry = compute comp (OP (RSHIFT, (word, rshift)))
              val word2 = compute comp (OP (OR, (word2, carry)))
            in
              (word1, word2::words)
            end
        val (word, words) = shiftLoop (word, words, maxNumBits)
      in
        {maxNumBits = maxNumBits + maxShift, words = word::words}
      end

  (* computeRecordBitmap [f_1, ..., f_n] computes the record bitmap words
   * of record { f_1, ..., f_n }. *)
  fun computeRecordBitmap comp nil = emptyBitmap
    | computeRecordBitmap comp ({tag, bitWidth}::bits) =
      let
        val bitmap = computeRecordBitmap comp bits
        val bitmap = shiftBitmap comp (bitmap, bitWidth)
        val bitmap = setBitmapBit comp (bitmap, tag)
      in
        bitmap
      end

  fun computeBitmapIndexes comp index nil = (index, nil)
    | computeBitmapIndexes comp index (bitmap::bitmaps) =
      let
        val nextIndex =
            compute comp (OP (ADD, (index, const (bitmapWordSize ()))))
        val (total, bitmaps) = computeBitmapIndexes comp nextIndex bitmaps
      in
        (total, {index = index, bitmap = bitmap : value} :: bitmaps)
      end

  fun computeRecord comp fields =
      let
        val fields =
            map (fn {tag, size} =>
                    {tag = coerceToWord tag, size = coerceToWord size})
                fields
        val sizesRev = rev (map (fn {tag,size} => {size=size}) fields)
        val (padded, layoutRev) = computeLayoutRev comp sizesRev
        val (padded2, layoutRev) = alignAccumSizeRev comp layoutRev
        val bitmapIndex = getAccumSizeRev layoutRev
        val layout = rev layoutRev
        val bits =
            ListPair.mapEq
              (fn ({tag, size}, {fieldIndex, accumSize}) =>
                  {tag = tag, index = fieldIndex, accumSize = accumSize})
              (fields, layout)
        val (_, bits) = computeBitIndex comp bits
        val {maxNumBits, words} = computeRecordBitmap comp bits
        val (allocSize, bitmaps) = computeBitmapIndexes comp bitmapIndex words
      in
        {allocSize = allocSize,
         fieldIndexes = map #fieldIndex layout,
         bitmaps = bitmaps,
         padding = padded orelse padded2}
      end

  fun computeIndex comp (fields, lastField) =
      let
        val fields = map (fn {size} => {size = coerceToWord size}) fields
        val lastField = case lastField of {size} => {size = coerceToWord size}
        val (_, fieldIndex, _) = computeIndexRev comp (lastField, rev fields)
      in
        fieldIndex
      end

end
