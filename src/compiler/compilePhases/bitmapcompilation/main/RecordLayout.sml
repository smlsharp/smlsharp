(**
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)
structure RecordLayout =
struct

  type var = RecordLayoutCalc.var

  val getSize = RuntimeTypes.getSize

  fun bitmapWordSize () =
      getSize (#size RuntimeTypes.word32Ty)

  fun bitmapWordBits () =
      bitmapWordSize () * RuntimeTypes.charBits

  fun pointerSize () =
      getSize (#size RuntimeTypes.recordTy)

  fun maxShift () =
      let
        val maxSize = RuntimeTypes.getSize RuntimeTypes.maxSize
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
        {id = id, path = []} : var
      end

  datatype value = datatype RecordLayoutCalc.value

  fun compareValue (v1, v2) =
      case (v1, v2) of
        (VAR {id=id1,...}, VAR {id=id2,...}) => VarID.compare (id1, id2)
      | (VAR _, WORD _) => LESS
      | (WORD n1, WORD n2) => Word32.compare (n1, n2)
      | (WORD _, VAR _) => GREATER

  fun const n =
      WORD (Word32.fromInt n)

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
        OP (ADD, (WORD n1, WORD n2)) => VALUE (WORD (Word32.+ (n1, n2)))
      | OP (ADD, (x, WORD 0w0)) => VALUE x
      | OP (ADD, (WORD 0w0, x)) => VALUE x
      | OP (ADD, x) => OP (ADD, commute x)
      | OP (SUB, (WORD n1, WORD n2)) => VALUE (WORD (Word32.- (n1, n2)))
      | OP (SUB, (x, WORD 0w0)) => VALUE x
      | OP (SUB, x) => exp
      | OP (DIV, (WORD n1, WORD n2)) => VALUE (WORD (Word32.div (n1, n2)))
      | OP (DIV, (x, WORD 0w1)) => VALUE x
      | OP (DIV, (x, WORD 0w2)) => normalizeExp (OP (RSHIFT, (x, WORD 0w1)))
      | OP (DIV, (x, WORD 0w4)) => normalizeExp (OP (RSHIFT, (x, WORD 0w2)))
      | OP (DIV, (x, WORD 0w8)) => normalizeExp (OP (RSHIFT, (x, WORD 0w3)))
      | OP (DIV, (x, WORD 0w16)) => normalizeExp (OP (RSHIFT, (x, WORD 0w4)))
      | OP (DIV, x) => exp
      | OP (AND, (WORD n1, WORD n2)) => VALUE (WORD (Word32.andb (n1, n2)))
      | OP (AND, (x as (v, WORD m))) =>
        if m = Word32.fromInt ~1 then VALUE v else OP (AND, commute x)
      | OP (AND, x) => OP (AND, commute x)
      | OP (OR, (WORD n1, WORD n2)) => VALUE (WORD (Word32.orb (n1, n2)))
      | OP (OR, (x, WORD 0w0)) => VALUE x
      | OP (OR, x) => OP (OR, commute x)
      | OP (LSHIFT, (WORD 0w0, _)) => VALUE (WORD 0w0)
      | OP (LSHIFT, (WORD n1, WORD n2)) =>
        VALUE (WORD (Word32.<< (n1, Word.fromInt (Word32.toIntX n2))))
      | OP (LSHIFT, (x, WORD 0w0)) => VALUE x
      | OP (LSHIFT, (x, WORD 0w1)) => normalizeExp (OP (ADD, (x, x)))
      | OP (LSHIFT, (x, WORD n)) =>
        if n >= Word32.fromInt (bitmapWordBits ())
        then VALUE (WORD 0w0)
        else exp
      | OP (LSHIFT, x) => exp
      | OP (RSHIFT, (WORD 0w0, _)) => VALUE (WORD 0w0)
      | OP (RSHIFT, (WORD n1, WORD n2)) =>
        VALUE (WORD (Word32.>> (n1, Word.fromInt (Word32.toIntX n2))))
      | OP (RSHIFT, (x, WORD 0w0)) => VALUE x
      | OP (RSHIFT, (x, WORD n)) =>
        if n >= Word32.fromInt (bitmapWordBits ())
        then VALUE (WORD 0w0)
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

  type computation_accum =
       (var ExpMap.map * dec list) ref

  fun newComputationAccum () =
      ref (ExpMap.empty, nil) : computation_accum

  fun extractDecls (comp as ref (_, decls) : computation_accum) =
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
      case (RuntimeTypes.sizeAssumption, RuntimeTypes.alignComputation) of
        (RuntimeTypes.ALL_SIZES_ARE_POWER_OF_2, RuntimeTypes.ALIGN_EQUAL_SIZE) =>
        (*
         * newAccumSize = (accumSize + (fieldSize - 1)) & ~(fieldSize - 1)
         *              = (accumSize + fieldSize - 1) & (-fieldSize)
         *)
        let
          val tmp1 = compute comp (OP (ADD, (accumSize, nextFieldSize)))
          val tmp2 = compute comp (OP (SUB, (tmp1, WORD 0w1)))
          val tmp3 = compute comp (OP (SUB, (WORD 0w0, nextFieldSize)))
          val tmp4 = compute comp (OP (AND, (tmp2, tmp3)))
        in
          tmp4
        end

  fun getAccumSizeRev nil = WORD 0w0
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
              (WORD accumSize, WORD fieldIndex) => accumSize <> fieldIndex
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
              (WORD accumSize, WORD accumSize') => accumSize <> accumSize'
            | _ => true
      in
          (padded, {fieldIndex = fieldIndex, accumSize = accumSize'}::fieldsRev)
      end

  fun estimateMaxShift value =
      case value of
        WORD n => Word32.toInt n
      | _ => maxShift ()

  (* computeBitIndex [f_1, ..., f_n] computes each bit in the bitmap of
   * record {f_1, ..., f_n}.
   *)
  fun computeBitIndex comp nil = (WORD 0w0, nil)
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
  fun shiftBitmap comp (bitmap, WORD 0w0) = bitmap
    | shiftBitmap comp ({maxNumBits, words=nil}, lshift) =
      {maxNumBits = estimateMaxShift lshift, words = [WORD 0w0]}
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
        val (_, fieldIndex, _) = computeIndexRev comp (lastField, rev fields)
      in
        fieldIndex
      end

end
