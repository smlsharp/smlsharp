(**
 * JSONToML
 * @copyright (c) 2016- Tohoku University.
 * @author Atsushi Ohori
 * @author Katsuhiro Ueno
 * @author Tomohiro Sasaki
 *)

(* This structure is based on functions in Dynamic structure, 
 * and JSONImpl structure. *)

structure JSONToML =
struct

  structure J = JSON
  structure P = SMLSharp_Builtin.Pointer
  structure D = SMLSharp_Builtin.Dynamic

  (* JSONType | RuntimeType
   * ------------------------------
   * INTty    | INT32ty
   * BOOLty   | UINT32ty (CONTAGty)
   * REALty   | DOUBLEty
   * STRINGty | BOXEDty
   * ARRAYty  | BOXEDty
   * RECORDty | BOXEDty
   * OPTIONty | BOXEDty
   * see also TypeLayout2.sml and BuiltinTypeNames.ppg
   *)

  val tag_ptr = 0w1
  val tag_notptr = 0w0

  (* see also TypeLayout2.sml *)
  fun constTag J.INTty = tag_notptr
    | constTag J.BOOLty = tag_notptr
    | constTag J.REALty = tag_notptr
    | constTag J.STRINGty = tag_ptr
    | constTag J.PARTIALINTty = tag_ptr
    | constTag J.PARTIALBOOLty = tag_ptr
    | constTag J.PARTIALREALty = tag_ptr
    | constTag J.PARTIALSTRINGty = tag_ptr
    | constTag (J.ARRAYty _) = tag_ptr
    | constTag (J.RECORDty _) = tag_ptr
    | constTag (J.PARTIALRECORDty _) = tag_ptr
    | constTag (J.OPTIONty _) = tag_ptr
    | constTag J.NULLty = tag_ptr
    | constTag J.DYNty = tag_ptr

  val pointerSize = !SMLSharp_PointerSize.pointerSize

  (* see also TypeLayout2.sml *)
  fun constSize J.INTty = 0w4
    | constSize J.BOOLty = 0w4
    | constSize J.REALty = 0w8
    | constSize J.STRINGty = Word.fromInt pointerSize
    | constSize J.PARTIALINTty = Word.fromInt pointerSize
    | constSize J.PARTIALBOOLty = Word.fromInt pointerSize
    | constSize J.PARTIALSTRINGty = Word.fromInt pointerSize
    | constSize J.PARTIALREALty = Word.fromInt pointerSize
    | constSize (J.ARRAYty _) = Word.fromInt pointerSize
    | constSize (J.RECORDty _) = Word.fromInt pointerSize
    | constSize (J.PARTIALRECORDty _) = Word.fromInt pointerSize
    | constSize (J.OPTIONty _) = Word.fromInt pointerSize
    | constSize J.NULLty = Word.fromInt pointerSize
    | constSize J.DYNty = Word.fromInt pointerSize


  (* returns next field index *)
  fun align (accumSize, nextFieldSize) =
      if accumSize mod nextFieldSize = 0w0
      then accumSize
      else nextFieldSize * (accumSize div nextFieldSize + 0w1)

  (* compute field indexes and accum size *)
  fun computeLayout sizes =
      let
        val sizesRev = List.rev sizes
        val (accumSize, fieldIndexesRev) =
            List.foldr (fn (size, (accumSize, fieldIndexesRev)) =>
                           let val align = align (accumSize, size)
                           in (align + size, align :: fieldIndexesRev)
                           end)
                       (0w0, nil)
                       sizesRev
      in
        (accumSize, List.rev fieldIndexesRev)
      end

  val bitsInBitmap = 32

  (* compute bits in bitmaps *)
  fun computeBits (sizes, fieldIndexes, bitmapIndex) =
      let
        (* make a word array as an array of bits
         * the size of the array is
         * bitmapIndex div pointerSize
         *)
        val bits = Array.tabulate 
                     (Word.toInt bitmapIndex div pointerSize,
                      fn _ => 0w0)
        val _ = ListPair.appEq
                  (fn ({tag, size}, fieldIndex) =>
                      if fieldIndex mod (Word.fromInt pointerSize) <> 0w0
                      then ()
                      else case tag of
                             0w0 => ()
                           | 0w1 => Array.update 
                                      (bits, 
                                       Word.toInt fieldIndex div pointerSize,
                                       0w1)
                           | _ => raise Bug.Bug "JSONToML: computeBits")
                  (sizes, fieldIndexes)
      in
        bits
      end

  val bitmapWordSize = 0w4

  (* compute bitmap words and total allocation size *)
  fun computeBitmaps (bitmapIndex, bits) =
      let
        (* make bitmap from bit array *)
        fun makeBitmapRev (bitmapIndex, bitmapRev, bits) =
            Array.foldli
              (fn (index, bit, bitmapsRev) =>
                  case index mod bitsInBitmap of
                    0 => {index = bitmapIndex + Word.fromInt (index div bitsInBitmap), 
                          bitmap = bit} :: 
                         bitmapsRev
                  | shiftBits => 
                    let val {index, bitmap} = List.hd bitmapsRev
                        val tl = List.tl bitmapsRev
                    in {index = index,
                        bitmap = Word.orb (bitmap, Word.<< (bit, Word.fromInt shiftBits))} :: tl
                    end)
              nil
              bits
        val bitmapsRev = makeBitmapRev (bitmapIndex, nil, bits)
        val allocSize = bitmapIndex + 
                        Word.fromInt (List.length bitmapsRev) * 
                        bitmapWordSize
      in
        (allocSize, List.rev bitmapsRev)
      end

  (* compute total allocation size, field indexes, bitmaps *)
  fun computeRecord fieldSizes =
      let
        val sizes = List.map (fn {tag, size} => size) fieldSizes
        val (accumSize, fieldIndexes) = computeLayout sizes
        val bitmapIndex = align (accumSize, Word.fromInt pointerSize)
        val bits = computeBits (fieldSizes, fieldIndexes, bitmapIndex)
        val (allocSize, bitmaps) = computeBitmaps (bitmapIndex, bits)
      in
        {allocSize = allocSize,
         fieldIndexes = fieldIndexes,
         bitmaps = bitmaps}
      end

  fun computeRecordLayout stringJsonTyList =
      let
        val fieldSizes = 
            map (fn (_, ty) => {tag = constTag ty, size = constSize ty})
                stringJsonTyList
        val ret as {allocSize, fieldIndexes, bitmaps} =
            computeRecord fieldSizes
      in
        (fieldSizes, ret)
      end

  fun toBoxed x = P.refToBoxed (ref x)
  fun fromBoxed x = ! (P.boxedToRef x)

  fun makeView jsonTy = 
   fn json => 
      case (jsonTy, json) of
        (J.NULLty, J.NULLObject) => J.NULLObject
      | (J.OPTIONty _, J.NULLObject) => J.NULLObject
      | (J.OPTIONty J.INTty, J.INT _) => json
      | (J.OPTIONty J.STRINGty, J.STRING _) => json
      | (J.OPTIONty J.REALty, J.REAL _) => json
      | (J.OPTIONty J.BOOLty, J.BOOL _) => json
      | (J.BOOLty, J.BOOL bool) => J.BOOL bool
      | (J.INTty, J.INT int) => J.INT int
      | (J.REALty, J.REAL real) => J.REAL real
      | (J.STRINGty, J.STRING string) => J.STRING string
      | (J.ARRAYty elemTy, J.ARRAY (jsonList, _)) => J.ARRAY (map (makeView elemTy) jsonList, J.ARRAYty elemTy)
      | (J.DYNty, _) => json
      | (J.RECORDty stringJsontyList, J.OBJECT stringJsonList) =>
         J.OBJECT 
         (foldr 
            (fn ((l,ty), fields) =>
                case List.find (fn (l',j) => l = l') stringJsonList of
                  NONE => raise  J.RuntimeTypeError
                | SOME (l',j) => (l, makeView ty j)::fields
            )
            nil
            stringJsontyList
         )
      | (J.PARTIALRECORDty stringJsontyList, J.OBJECT stringJsonList) =>
        (
         J.OBJECT 
           (foldr
              (fn ((l,ty), fields) =>
                  case List.find (fn (l',j) => l = l') stringJsonList of
                    NONE => raise  J.RuntimeTypeError
                  | SOME (l',j) => (l, makeView ty j)::fields
              )
              nil
              stringJsontyList
           )
        )
      | _ => raise J.RuntimeTypeError
  fun makeCoerce json jsonTy viewFn =
      case jsonTy of
        J.DYNty => J.DYN (fn _ => raise J.AttemptToReturnVOIDValue, json) 
      | _ => J.DYN(fn json => viewFn (makeView jsonTy json), json)


  fun makeRecordPlain (stringJsonList, stringJsonTyList) =
      let
        val (fieldSizes, {allocSize, fieldIndexes, bitmaps}) =
            computeRecordLayout stringJsonTyList
        val fields =
            ListPair.mapEq
              (fn (({tag, size}, index), ((l, json), (_, jsonTy))) =>
                  {tag = tag,
                   size = size,
                   dstIndex = index,
                   src = toMLValue (json, jsonTy),
                   srcIndex = 0w0})
              (ListPair.zipEq (fieldSizes, fieldIndexes),
               ListPair.zipEq (stringJsonList, stringJsonTyList))
        val payloadSize = case bitmaps of 
                            {index, ...}::_ => index 
                          | _ => 0w0
        val record = D.allocRecord (payloadSize, allocSize)
      in
        List.app (fn {index, bitmap} =>
                     D.writeWord32
                       (record, index, bitmap))
                 bitmaps;
        List.app (fn {tag, size, dstIndex, src, srcIndex} =>
                     D.copy (record, dstIndex, src, srcIndex, tag, size))
                 fields;
        record
      end
      

  (* see also Dynamic.sml
   * This function must receives label-ascending-sorted JSON and JSONTy list *)
  and makeRecord (stringJsonList, stringJsonTyList) =
      let
        val (fieldSizes, {allocSize, fieldIndexes, bitmaps}) =
            computeRecordLayout stringJsonTyList
        val fields =
            ListPair.mapEq
              (fn (({tag, size}, index), ((l, json), (_, jsonTy))) =>
                  {tag = tag,
                   size = size,
                   dstIndex = index,
                   src = toMLValue (json, jsonTy),
                   srcIndex = 0w0})
              (ListPair.zipEq (fieldSizes, fieldIndexes),
               ListPair.zipEq (stringJsonList, stringJsonTyList))
        val payloadSize = case bitmaps of 
                            {index, ...}::_ => index 
                          | _ => 0w0
        val record = D.allocRecord (payloadSize, allocSize)
      in
        List.app (fn {index, bitmap} =>
                     D.writeWord32
                       (record, index, bitmap))
                 bitmaps;
        List.app (fn {tag, size, dstIndex, src, srcIndex} =>
                     D.copy (record, dstIndex, src, srcIndex, tag, size))
                 fields;
        toBoxed record
      end
      
  and toMLValue (json, J.DYNty) =
      toBoxed
        (J.DYN(fn _ => raise J.AttemptToReturnVOIDValue,
               json)
        )
    | toMLValue (json as J.INT int, J.PARTIALINTty) = 
      toBoxed
        (J.DYN(fn json as J.INT int => int | _ => raise Match,
               json)
        )
    | toMLValue (json as J.BOOL bool, J.PARTIALBOOLty) = 
      toBoxed
        (J.DYN(fn json as J.BOOL bool => bool | _ => raise Match,
               json)
        )
    | toMLValue (json as J.STRING string, J.PARTIALSTRINGty) = 
      toBoxed
        (J.DYN(fn json as J.STRING string => string | _ => raise Match,
               json)
        )
    | toMLValue (json as J.REAL real, J.PARTIALREALty) = 
      toBoxed
        (J.DYN(fn json as J.REAL real => real | _ => raise Match,
               json)
        )
    | toMLValue (J.INT int, J.INTty) = toBoxed int
    | toMLValue (J.BOOL bool, J.BOOLty) = toBoxed bool
    | toMLValue (J.REAL real, J.REALty) = toBoxed real
    | toMLValue (J.STRING string, J.STRINGty) = toBoxed string
    | toMLValue (J.ARRAY (jsonList, _), J.ARRAYty elemTy) =
      let
        (* translate array to nested record *)
        val (cons, consTy) =
            List.foldr 
              (fn (j, (next, nextTy)) => 
                  (J.OBJECT [("1", j), ("2", next)], 
                   J.RECORDty [("1", elemTy), ("2", nextTy)]))
              (J.NULLObject, J.NULLty)
              jsonList
      in
        toMLValue (cons, consTy)
      end
    | toMLValue (json as J.OBJECT stringJsonList,
                 jsonTy as J.PARTIALRECORDty stringJsonTyList) =
      let
        fun compareFun (l1, l2) =
            case (Int.fromString l1, Int.fromString l2) of
              (SOME i1, SOME i2) => Int.> (i1, i2)
            | _ => String.> (l1, l2)
        val stringJsonList = 
            ListMergeSort.sort 
              (fn ((l1, j1), (l2, j2)) => compareFun (l1, l2))
              stringJsonList
        val stringJsonTyList =
            ListMergeSort.sort 
              (fn ((l1, ty1), (l2, ty2)) => String.> (l1, l2))
              stringJsonTyList
        fun mkJson (_,nil) = nil
          | mkJson (nil,_) = nil
          | mkJson ((l1, j1)::tl1, (l2,j2)::tl2) =
            if l1 = l2 then (l1, j1)::mkJson(tl1, tl2)
            else mkJson(tl1, (l2,j2)::tl2)
        val stringJsonList = mkJson (stringJsonList,stringJsonTyList)
      in
        toBoxed (J.DYN
                   (fn json as J.OBJECT stringJsonList =>
                       (makeRecordPlain (stringJsonList, stringJsonTyList))
                     | _ => raise Match,
                    J.OBJECT stringJsonList)
                )
      end
    | toMLValue (json as J.OBJECT stringJsonList, jsonTy as J.RECORDty stringJsonTyList) =
      let
        (* ListMergeSort.sort returns ascending sort. *)
        (* FIXME: If JSON.Object is always sorted, 
         *        this sort codes are not needed.
         *)
        fun compareFun (l1, l2) =
            case (Int.fromString l1, Int.fromString l2) of
              (SOME i1, SOME i2) => Int.> (i1, i2)
            | _ => String.> (l1, l2)
        val stringJsonList = 
            ListMergeSort.sort 
              (fn ((l1, j1), (l2, j2)) => compareFun (l1, l2))
              stringJsonList
        val stringJsonTyList =
            ListMergeSort.sort 
              (fn ((l1, ty1), (l2, ty2)) => String.> (l1, l2))
              stringJsonTyList
      in
        makeRecord (stringJsonList, stringJsonTyList)
      end
    | toMLValue (J.NULLObject, J.OPTIONty _) =
      toBoxed (Pointer.NULL ())
    | toMLValue (json, J.OPTIONty elemTy) =
      (* See DatatypeLayout.sml for LAYOUT_ARG_OR_NULL ({wrap = true}) *)
      toMLValue (J.OBJECT [("1", json)], J.RECORDty [("1", elemTy)])
    | toMLValue (J.NULLObject, J.NULLty) =
      (* for null pointer use *)
      toBoxed (Pointer.NULL ()) 
    | toMLValue (json,jsonTy) =
       raise J.RuntimeTypeError

  fun ('a#json) jsonToML (json, jsonTy) : 'a =
      fromBoxed (toMLValue (json, jsonTy))
end
