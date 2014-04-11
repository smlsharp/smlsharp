(**
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure RecordLayout2 :> sig

  datatype decl =
      PRIMAPPLY of {boundVar: RecordCalc.varInfo,
                    primInfo: TypedLambda.primInfo,
                    argList: SingletonTyEnv2.value list}

  type computationAccum
  val newComputationAccum : unit -> computationAccum
  val extractDecls : computationAccum -> decl list

  val computeIndex
      : computationAccum
        -> {size: SingletonTyEnv2.value} list * {size: SingletonTyEnv2.value}
        -> SingletonTyEnv2.value
  val computeRecord
      : computationAccum
        -> {tag: SingletonTyEnv2.value, size: SingletonTyEnv2.value} list
        -> {allocSize: SingletonTyEnv2.value,
            fieldIndexes: SingletonTyEnv2.value list,
            bitmaps: {index: SingletonTyEnv2.value,
                      bitmap: SingletonTyEnv2.value} list,
            padding: bool}

end =
struct

  structure T = Types
  structure P = BuiltinPrimitive
  type varInfo = RecordCalc.varInfo

  fun sizeOf ty =
      TypeLayout2.sizeOf
        (valOf (TypeLayout2.runtimeTy BoundTypeVarID.Map.empty ty))

  fun wordSize () =
      sizeOf BuiltinTypes.wordTy

  fun bitmapWordBits () =
      wordSize () * TypeLayout2.charBits

  fun pointerSize () =
      sizeOf BuiltinTypes.boxedTy

  fun maxShift () =
      let
        val maxSize = TypeLayout2.maxSize
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
        {id = id, path = ["$" ^ VarID.toString id], ty = BuiltinTypes.wordTy}
        : varInfo
      end

  datatype value = datatype SingletonTyEnv2.value

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
      | (SIZE (_, n1), SIZE (_, n2)) => Int.compare (n1, n2)
      | (SIZE _, _) => compareByOrder (v1, v2)
      | (CONST n1, CONST n2) => Word32.compare (n1, n2)
      | (CONST _, _) => compareByOrder (v1, v2)
      | (CAST (v1, _), CAST (v2, _)) => compareValue (v1, v2)
      | (CAST _, _) => compareByOrder (v1, v2)
  end (* local *)

  fun const n =
      CONST (LargeWord.fromInt n)

  fun isWordTy ty =
      case TypesBasics.derefTy ty of
        T.CONSTRUCTty {tyCon, ...} =>
        TypID.eq (#id tyCon, #id BuiltinTypes.wordTyCon)
      | _ => false

  fun coerceToWord value =
      case value of
        CONST w => CONST w
      | VAR (var as {ty,...}) =>
        if isWordTy ty
        then VAR var
        else CAST (VAR var, BuiltinTypes.wordTy)
      | SIZE (_, n) => const n
      | TAG (_, n) => const (TypeLayout2.tagValue n)
      | CAST (v, _) => coerceToWord v

  datatype exp =
      ADD of value * value
    | SUB of value * value
    | DIV of value * value
    | AND of value * value
    | OR of value * value
    | LSHIFT of value * value
    | RSHIFT of value * value
    | VALUE of value

  local
    fun commute (v1, v2) =
        case compareValue (v1, v2) of
          GREATER => (v1, v2)
        | EQUAL => (v1, v2)
        | LESS => (v2, v1)
  in
  fun normalizeExp exp =
      case exp of
        ADD (CONST n1, CONST n2) => VALUE (CONST (Word32.+ (n1, n2)))
      | ADD (x, CONST 0w0) => VALUE x
      | ADD (CONST 0w0, x) => VALUE x
      | ADD x => ADD (commute x)
      | SUB (CONST n1, CONST n2) => VALUE (CONST (Word32.- (n1, n2)))
      | SUB (x, CONST 0w0) => VALUE x
      | SUB x => exp
      | DIV (CONST n1, CONST n2) => VALUE (CONST (Word32.div (n1, n2)))
      | DIV (x, CONST 0w1) => VALUE x
      | DIV (x, CONST 0w2) => normalizeExp (RSHIFT (x, CONST 0w1))
      | DIV (x, CONST 0w4) => normalizeExp (RSHIFT (x, CONST 0w2))
      | DIV (x, CONST 0w8) => normalizeExp (RSHIFT (x, CONST 0w3))
      | DIV (x, CONST 0w16) => normalizeExp (RSHIFT (x, CONST 0w4))
      | DIV x => exp
      | AND (CONST n1, CONST n2) => VALUE (CONST (Word32.andb (n1, n2)))
      | AND (x as (v, CONST m)) =>
        if m = Word32.fromInt ~1 then VALUE v else AND (commute x)
      | AND x => AND (commute x)
      | OR (CONST n1, CONST n2) => VALUE (CONST (Word32.orb (n1, n2)))
      | OR (x, CONST 0w0) => VALUE x
      | OR x => OR (commute x)
      | LSHIFT (CONST n1, CONST n2) =>
        VALUE (CONST (Word32.<< (n1, Word.fromInt (Word32.toIntX n2))))
      | LSHIFT (x, CONST 0w0) => VALUE x
      | LSHIFT (x, CONST 0w1) => normalizeExp (ADD (x, x))
      | LSHIFT (x, CONST n) =>
        if n >= Word32.fromInt (bitmapWordBits ())
        then VALUE (CONST 0w0)
        else exp
      | LSHIFT x => exp
      | RSHIFT (CONST n1, CONST n2) =>
        VALUE (CONST (Word32.>> (n1, Word.fromInt (Word32.toIntX n2))))
      | RSHIFT (x, CONST 0w0) => VALUE x
      | RSHIFT (x, CONST n) =>
        if n >= Word32.fromInt (bitmapWordBits ())
        then VALUE (CONST 0w0)
        else exp
      | RSHIFT x => exp
      | VALUE x => exp
  end (* local *)

  local
    fun order (ADD _) = 0
      | order (SUB _) = 1
      | order (DIV _) = 2
      | order (AND _) = 3
      | order (OR _) = 4
      | order (LSHIFT _) = 5
      | order (RSHIFT _) = 6
      | order (VALUE _) = 7
    fun compareByOrder (e1, e2) = Int.compare (order e1, order e2)
    fun comparePair (v1, v2) (v3, v4) =
        case compareValue (v1, v3) of
          EQUAL => compareValue (v2, v4)
        | x => x
  in
  fun compareExp (e1, e2) =
      case (e1, e2) of
        (ADD x, ADD y) => comparePair x y
      | (ADD _, _) => compareByOrder (e1, e2)
      | (SUB x, SUB y) => comparePair x y
      | (SUB _, _) => compareByOrder (e1, e2)
      | (DIV x, DIV y) => comparePair x y
      | (DIV _, _) => compareByOrder (e1, e2)
      | (AND x, AND y) => comparePair x y
      | (AND _, _) => compareByOrder (e1, e2)
      | (OR x, OR y) => comparePair x y
      | (OR _, _) => compareByOrder (e1, e2)
      | (LSHIFT x, LSHIFT y) => comparePair x y
      | (LSHIFT _, _) => compareByOrder (e1, e2)
      | (RSHIFT x, RSHIFT y) => comparePair x y
      | (RSHIFT _, _) => compareByOrder (e1, e2)
      | (VALUE x, VALUE y) => compareValue (x, y)
      | (VALUE _, _) => compareByOrder (e1, e2)
  end (* local *)

  structure ExpMap = BinaryMapFn(type ord_key = exp val compare = compareExp)

  datatype decl =
      PRIMAPPLY of {boundVar: varInfo,
                    primInfo: TypedLambda.primInfo,
                    argList: SingletonTyEnv2.value list}

  type computationAccum =
       (varInfo ExpMap.map * decl list) ref

  fun newComputationAccum () =
      ref (ExpMap.empty, nil) : computationAccum

  fun extractDecls (comp as ref (_, decls) : computationAccum) =
      (comp := (ExpMap.empty, nil); rev decls)

  local
    fun prim1 prim arg var =
        PRIMAPPLY
          {boundVar = var,
           primInfo = {primitive = prim,
                       ty = {boundtvars = BoundTypeVarID.Map.empty,
                             argTyList = [BuiltinTypes.wordTy],
                             resultTy = BuiltinTypes.wordTy}},
           argList = [arg]}

    fun prim2 prim (arg1, arg2) var =
        PRIMAPPLY
          {boundVar = var,
           primInfo = {primitive = prim,
                       ty = {boundtvars = BoundTypeVarID.Map.empty,
                             argTyList = [BuiltinTypes.wordTy,
                                          BuiltinTypes.wordTy],
                             resultTy = BuiltinTypes.wordTy}},
           argList = [arg1, arg2]}
  in

  fun compute (comp as ref (map, decls)) exp =
      let
        val exp = normalizeExp exp
        fun search decl =
            case ExpMap.find (map, exp) of
              SOME var => VAR var
            | NONE =>
              let
                val var = newVar ()
              in
                comp := (ExpMap.insert (map, exp, var), decl var :: decls);
                VAR var
              end
      in
        case exp of
          VALUE v => v
        | ADD x => search (prim2 (P.R (P.M P.Word_add)) x)
        | SUB x => search (prim2 (P.R (P.M P.Word_sub)) x)
        | DIV x => search (prim2 (P.R (P.M P.Word_div_unsafe)) x)
        | AND x => search (prim2 (P.R (P.M P.Word_andb)) x)
        | OR x => search (prim2 (P.R (P.M P.Word_orb)) x)
        | LSHIFT x => search (prim2 (P.R (P.M P.Word_lshift_unsafe)) x)
        | RSHIFT x => search (prim2 (P.R (P.M P.Word_rshift_unsafe)) x)
      end

  end (* local *)

  fun alignSize comp (accumSize, nextFieldSize) =
      case (TypeLayout2.sizeAssumption, TypeLayout2.alignComputation) of
        (TypeLayout2.ALL_SIZES_ARE_POWER_OF_2, TypeLayout2.ALIGN_EQUAL_SIZE) =>
        (*
         * newAccumSize = (accumSize + (fieldSize - 1)) & ~(fieldSize - 1)
         *              = (accumSize + fieldSize - 1) & (-fieldSize)
         *)
        let
          val tmp1 = compute comp (ADD (accumSize, nextFieldSize))
          val tmp2 = compute comp (SUB (tmp1, CONST 0w1))
          val tmp3 = compute comp (SUB (CONST 0w0, nextFieldSize))
          val tmp4 = compute comp (AND (tmp2, tmp3))
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
        val accumSize = compute comp (ADD (fieldIndex, size))
      in
        (padded, {fieldIndex = fieldIndex, accumSize = accumSize} :: layoutRev)
      end

  fun alignAccumSizeRev comp nil = nil
    | alignAccumSizeRev comp ({fieldIndex:value, accumSize}::fieldsRev) =
      let
        (* align accumSize to word boundary *)
        val accumSize = alignSize comp (accumSize, const (wordSize ()))
      in
        {fieldIndex = fieldIndex, accumSize = accumSize}::fieldsRev
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
        val bitIndex = compute comp (DIV (index, pointerSize))
        val prevComp = !comp
        val totalBits = compute comp (DIV (accumSize, pointerSize))
        val tmpBitWidth = compute comp (SUB (totalBits, bitIndex))
        val bitWidth = const (estimateMaxShift tmpBitWidth)
        val _ = comp := prevComp
      in
        (bitIndex, [{tag = tag, bitWidth = bitWidth}])
      end
    | computeBitIndex comp ({tag:value, index, accumSize}::bits) =
      let
        val (nextIndex, bits) = computeBitIndex comp bits
        val pointerSize = const (pointerSize ())
        val bitIndex = compute comp (DIV (index, pointerSize))
        val bitWidth = compute comp (SUB (nextIndex, bitIndex))
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
       words = compute comp (OR (word, bit)) :: words}

  (* lshift must be less than bitmapWordBits *)
  fun shiftBitmap comp (bitmap, CONST 0w0) = bitmap
    | shiftBitmap comp ({maxNumBits, words=nil}, lshift) =
      {maxNumBits = estimateMaxShift lshift, words = [CONST 0w0]}
    | shiftBitmap comp ({maxNumBits, words=word::words}, lshift) =
      let
        val maxShift = estimateMaxShift lshift
        val bitmapWordBits = bitmapWordBits ()
        val rshift = compute comp (SUB (const bitmapWordBits, lshift))
        fun shiftLoop (word, nil, numBits) =
            if numBits + maxShift <= bitmapWordBits
            then (compute comp (LSHIFT (word, lshift)), nil)
            else (compute comp (LSHIFT (word, lshift)),
                  [compute comp (RSHIFT (word, rshift))])
          | shiftLoop (word1, word2::words, numBits) =
            let
              val (word2, words) =
                  shiftLoop (word2, words, numBits - bitmapWordBits)
              val word1 = compute comp (LSHIFT (word, lshift))
              val carry = compute comp (RSHIFT (word, rshift))
              val word2 = compute comp (OR (word2, carry))
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
        val nextIndex = compute comp (ADD (index, const (wordSize ())))
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
        val layoutRev = alignAccumSizeRev comp layoutRev
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
         padding = padded}
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
