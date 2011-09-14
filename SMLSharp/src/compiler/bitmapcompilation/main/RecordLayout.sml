(**
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure RecordLayout :> sig

  datatype value =
      CONST of LargeWord.word
    | VAR of BitmapCalc.varInfo * AnnotatedTypes.ty option (* cast *)

  datatype decl =
      MOVE of BitmapCalc.varInfo * value
    | PRIMAPPLY of {boundVar: BitmapCalc.varInfo,
                    primInfo: BitmapCalc.primInfo,
                    argList: value list}

  type bitmap

val printValue : value -> unit
val printValues : value list -> unit
val printBitmap : bitmap -> unit

  val const : int -> value
  val toLargeWord : value -> LargeWord.word option
  val castToWord : value -> value

  val emptyBitmap : bitmap
  val bitmapWords : bitmap -> value list

  val computeIndex : {size: value} list * {size: value} -> decl list * value
  val computeRecord : {tag: value, size: value} list
                      -> decl list
                         * {totalSize: value,
                            fieldIndexes: value list,
                            bitmap: value list}

  val addBitsToBitmap : {tag: value} list * bitmap -> decl list * bitmap

end =
struct

  structure T = AnnotatedTypes
  structure B = BitmapCalc
  structure P = BuiltinPrimitive

  fun newVar () =
      let
        val id = VarID.generate ()
      in
        {id = id, path = ["$" ^ VarID.toString id], ty = T.wordty} : B.varInfo
      end

  datatype value =
      CONST of LargeWord.word
    | VAR of BitmapCalc.varInfo * AnnotatedTypes.ty option

fun printValue v =
    case v of
      CONST x => print (LargeWord.toString x)
    | VAR (v,_) => print (Control.prettyPrint (BitmapCalc.format_varInfo v))
fun printValues l =
    app (fn v => (printValue v; print ",")) l

  fun const n = CONST (LargeWord.fromInt n)
  fun toLargeWord (CONST w) = SOME w
    | toLargeWord (VAR _) = NONE
  fun castToWord (CONST w) = CONST w
    | castToWord (VAR (var as {ty,...}, _)) =
      if (case ty of
            T.CONty {tyCon,...} =>
            TypID.eq (#id tyCon, #id BuiltinEnv.WORDtyCon)
          | _ => false)
      then VAR (var, NONE)
      else VAR (var, SOME T.wordty)

  datatype exp =
      ADD of value * value
    | SUB of value * value
    | DIV of value * value
    | AND of value * value
    | OR of value * value
    | LSHIFT of value * value
    | RSHIFT of value * value
    | NOT of value
    | VALUE of value

  datatype decl =
      MOVE of BitmapCalc.varInfo * value
    | PRIMAPPLY of {boundVar: BitmapCalc.varInfo,
                    primInfo: BitmapCalc.primInfo,
                    argList: value list}

  type bitmap =
      {maxNumBits: int, words: value list}  (* lower word first *)
fun printBitmap ({maxNumBits,words}:bitmap) =
    (print "["; printValues words; print "]:"; print (Int.toString maxNumBits))
    
  val emptyBitmap =
      {maxNumBits = 0, words = nil} : bitmap

  fun bitmapWords ({words,...}:bitmap) = words

  datatype bind = BIND of (B.varInfo * exp) list
  val emptyBind = BIND nil
  fun addBind (BIND bind, var, exp) = BIND ((var, exp)::bind)

  fun comm (CONST x, VAR y) = (VAR y, CONST x)
    | comm (VAR (v1 as ({id=id1,...},_)), VAR (v2 as ({id=id2,...},_))) =
      (case VarID.compare (id1, id2) of
         GREATER => (VAR v2, VAR v1)
       | _ => (VAR v1, VAR v2))
    | comm x = x
  fun comm x = x

  fun optimizeExp exp =
      case exp of
        ADD (CONST x, CONST y) => VALUE (CONST (LargeWord.+ (x, y)))
      | ADD (CONST 0w0, y) => VALUE y
      | ADD (x, CONST 0w0) => VALUE x
      | ADD x => ADD (comm x)
      | SUB (CONST x, CONST y) => VALUE (CONST (LargeWord.- (x, y)))
      | SUB (x, CONST 0w0) => VALUE x
      | SUB x => SUB x
      | DIV (CONST x, CONST y) => VALUE (CONST (LargeWord.div (x, y)))
      | DIV (x, CONST 0w1) => VALUE x
      | DIV x => DIV x
      | AND (CONST x, CONST y) => VALUE (CONST (LargeWord.andb (x, y)))
      | AND (CONST 0w0, y) => VALUE (CONST 0w0)
      | AND (x, CONST 0w0) => VALUE (CONST 0w0)
      | AND x => AND (comm x)
      | OR (CONST x, CONST y) => VALUE (CONST (LargeWord.orb (x, y)))
      | OR (CONST 0w0, y) => VALUE y
      | OR (x, CONST 0w0) => VALUE x
      | OR x => OR (comm x)
      | LSHIFT (CONST x, CONST y) =>
        VALUE (CONST (LargeWord.<< (x, Word.fromLarge y)))
      | LSHIFT (CONST 0w0, y) => VALUE (CONST 0w0)
      | LSHIFT (x, CONST 0w0) => VALUE x
      | LSHIFT x => LSHIFT x
      | RSHIFT (CONST x, CONST y) =>
        VALUE (CONST (LargeWord.>> (x, Word.fromLarge y)))
      | RSHIFT (CONST 0w0, y) => VALUE (CONST 0w0)
      | RSHIFT (x, CONST 0w0) => VALUE x
      | RSHIFT x => RSHIFT x
      | NOT (CONST x) => VALUE (CONST (LargeWord.notb x))
      | NOT x => NOT x
      | VALUE x => VALUE x

  fun insert bind exp =
      case optimizeExp exp of
        VALUE x => (bind, x)
      | exp =>
        let
          val v = newVar ()
        in
          (addBind (bind, v, exp), VAR (v, NONE))
        end

  fun PrimApply1 (var, prim, arg) =
      PRIMAPPLY
        {boundVar = var,
         primInfo = {primitive = prim,
                     ty = AnnotatedTypesUtils.makeClosureFunTy
                            ([T.wordty], T.wordty)},
         argList = [arg]}

  fun PrimApply2 (var, prim, arg1, arg2) =
      PRIMAPPLY
        {boundVar = var,
         primInfo = {primitive = prim,
                     ty = AnnotatedTypesUtils.makeClosureFunTy
                            ([T.wordty, T.wordty], T.wordty)},
         argList = [arg1, arg2]}

  fun bindToDecl (var, exp) =
      case exp of
        ADD (v1, v2) => PrimApply2 (var, P.Word_add, v1, v2)
      | SUB (v1, v2) => PrimApply2 (var, P.Word_sub, v1, v2)
      | DIV (v1, v2) => PrimApply2 (var, P.Word_div, v1, v2)
      | AND (v1, v2) => PrimApply2 (var, P.Word_andb, v1, v2)
      | OR (v1, v2) => PrimApply2 (var, P.Word_orb, v1, v2)
      | LSHIFT (v1, v2) => PrimApply2 (var, P.Word_lshift, v1, v2)
      | RSHIFT (v1, v2) => PrimApply2 (var, P.Word_rshift, v1, v2)
      | NOT v => PrimApply1 (var, P.Word_notb, v)
      | VALUE v => MOVE (var, v)

  fun toDecls (BIND binds) =
      rev (map bindToDecl binds)

  fun alignSize bind (recordSize, nextFieldSize) =
      case TypeLayout.alignComputation of
        TypeLayout.TRAILING_ZEROES =>
        let
          (* align = next & (-next)
           * newSize = (size + (align - 1)) & ~(align - 1)
           *         = (size - 1 - (-align)) & (-align)
           *)
          val (bind, bits) = insert bind (SUB (CONST 0w0, nextFieldSize))
          val (bind, align) = insert bind (AND (nextFieldSize, bits))
          val (bind, nmask) = insert bind (SUB (CONST 0w0, align))
          val (bind, size1) = insert bind (SUB (recordSize, CONST 0w1))
          val (bind, size2) = insert bind (SUB (size1, nmask))
          val (bind, size3) = insert bind (AND (size2, nmask))
        in
          (bind, size3)
        end

  (* computeIndexRev (f_{n+1}, [f_n, ..., f_1]) returns the index of
   * field f_{n+1} of record { f_1, ..., f_n, f_{n+1} }. *)
  fun computeIndexRev bind ({size=lastFieldSize}, fieldsRev) =
      let
        val (bind, layout) = computeLayoutRev bind fieldsRev
        val totalSize = case layout of nil => CONST 0w0
                                     | {totalSize,...}::_ => totalSize
        val (bind, fieldIndex) = alignSize bind (totalSize, lastFieldSize)
(*
val _ = (print "fieldIndex([";
printValues (rev (map #size fieldsRev));
print "],";
printValue lastFieldSize;
print ") = ";
printValue fieldIndex;
print "\n")
*)
      in
        (bind, fieldIndex, layout)
      end

  (* computeLayoutRev ([f_n, ..., f_1]) computes the total size
   * of record { f_1, ..., f_n }. *)
  and computeLayoutRev bind nil = (bind, nil)
    | computeLayoutRev bind ((lastField as {size})::fieldsRev) =
      let
        val (bind, fieldIndex, layout) =
            computeIndexRev bind (lastField, fieldsRev)
        val (bind, totalSize) = insert bind (ADD (fieldIndex, size))
(*
val _ = (print "totalSize(";
printValues (rev (map #size (lastField::fieldsRev)));
print ") = ";
printValue totalSize;
print "\n")
*)
      in
        (bind, {fieldIndex=fieldIndex, totalSize=totalSize}::layout)
      end

  fun alignTotalSize bind nil = (bind, nil)
    | alignTotalSize bind ({fieldIndex:value, totalSize}::t) =
      let
        (* align totalSize to word boundary *)
        val wordSize = const (TypeLayout.sizeOf RuntimeTypes.UINTty)
        val (bind, totalSize) = alignSize bind (totalSize, wordSize)
      in
        (bind, {fieldIndex=fieldIndex, totalSize=totalSize}::t)
      end

  fun computeIndex (fields, lastField) =
      let
        val fields = map (fn {size} => {size = castToWord size}) fields
        val lastField = case lastField of {size} => {size = castToWord size}
        val (bind, fieldIndex, layout) =
            computeIndexRev emptyBind (lastField, rev fields)
      in
        (toDecls bind, fieldIndex)
      end

  fun setBitmapBit bind ({maxNumBits, words=nil}:bitmap, bit) =
      (bind, {maxNumBits=1, words=[bit]}:bitmap)
    | setBitmapBit bind ({maxNumBits, words=word::words}, bit) =
      let
        val (bind, word) = insert bind (OR (word, bit))
      in
        (bind, {maxNumBits=maxNumBits, words=word::words})
      end

  fun maxShift () =
      let
        val pointerSize = TypeLayout.sizeOf RuntimeTypes.BOXEDty
        val _ = if TypeLayout.maxSize mod pointerSize = 0
                then () else raise Control.Bug "toMaxShift"
      in
        TypeLayout.maxSize div pointerSize
      end

  fun coerceToInt (CONST x, n) = LargeWord.toInt x
    | coerceToInt (VAR _, n) = n

  fun shiftBitmapBits bind (bitmap, CONST 0w0) = (bind, bitmap)
    | shiftBitmapBits bind ({maxNumBits, words}:bitmap, shift) =
      let
        val maxShift = coerceToInt (shift, maxShift ())
        val _ = if 0 < maxShift andalso maxShift < TypeLayout.bitmapWordBits
                then () else raise Control.Bug "shiftBitmapBits"
      in
        case words of
          nil => (bind, {maxNumBits = maxShift, words = [CONST 0w0]})
        | word::words =>
          let
            val (bind, rshift) =
                if maxNumBits + maxShift > TypeLayout.bitmapWordBits
                then insert bind (SUB (const TypeLayout.bitmapWordBits, shift))
                else (bind, CONST 0w0)  (* dummy *)
            fun numBitsLastWord n =
                ((n - 1) mod TypeLayout.bitmapWordBits) + 1
            fun shiftLoop (bind, word, nil) =
                if numBitsLastWord maxNumBits + maxShift
                   > TypeLayout.bitmapWordBits then
                  let
                    val (bind, carry) = insert bind (RSHIFT (word, rshift))
                    val (bind, word) = insert bind (LSHIFT (word, shift))
                  in
                    (bind, word, [carry])
                  end
                else
                  let
                    val (bind, word) = insert bind (LSHIFT (word, shift))
                  in
                    (bind, word, nil)
                  end
              | shiftLoop (bind, word, word2::words) =
                let
                  val (bind, word2, words) = shiftLoop (bind, word2, words)
                  val (bind, carry) = insert bind (RSHIFT (word, rshift))
                  val (bind, word2) = insert bind (OR (word2, carry))
                  val (bind, word) = insert bind (LSHIFT (word, shift))
                in
                  (bind, word, word2::words)
                end
            val (bind, word, words) = shiftLoop (bind, word, words)
            val bitmap = {maxNumBits = maxNumBits + maxShift,
                          words = word::words} : bitmap
          in
            (bind, bitmap)
          end
      end

  (* computeRecordBitmapRev [f_n, ..., f_1] computes the record bitmap
   * of record { f_1, ..., f_n }. *)
  fun computeRecordBitmapRev bind (bitmap, nil) = (bind, bitmap)
    | computeRecordBitmapRev bind (bitmap, {tag, bitShift}::bitsRev) =
      let
(*
val _ = (print "shiftBitmap(";
printBitmap bitmap;
print ",";
printValue bitShift;
print ") = ")
*)
        val (bind, bitmap) = shiftBitmapBits bind (bitmap, bitShift)
(*
val _ = (
printBitmap bitmap;
print "\n")
val _ = (print "setBitmapBit(";
printBitmap bitmap;
print ",";
printValue tag;
print ") = ")
*)
        val (bind, bitmap) = setBitmapBit bind (bitmap, tag)
(*
val _ = (
printBitmap bitmap;
print "\n")
*)
      in
        computeRecordBitmapRev bind (bitmap, bitsRev)
      end

  (* computeBitIndex [f_1, ..., f_n] computes the range of bit indexes
   * in the record bitmap of the bits corresponding to fields f_n.
   *)
  fun computeBitIndex bind nil = (bind, CONST 0w0, nil)
    | computeBitIndex bind [{tag, fieldIndex, totalSize}] =
      let
        val pointerSize = const (TypeLayout.sizeOf RuntimeTypes.BOXEDty)
        val (bind, bitIndex) = insert bind (DIV (fieldIndex, pointerSize))
        val (bind, bitSize) =
            case (totalSize, bitIndex) of
              (CONST _, CONST _) =>
              let
                val (bind, nextIndex) =
                    insert bind (DIV (totalSize, pointerSize))
              in
                insert bind (SUB (nextIndex, bitIndex))
              end
            | _ => (bind, const (maxShift ()))
      in
        (bind, bitIndex, [{tag = tag, bitShift = bitSize}])
      end
    | computeBitIndex bind ({tag, fieldIndex, totalSize}::bits) =
      let
        val (bind, nextIndex, results) = computeBitIndex bind bits
        val pointerSize = const (TypeLayout.sizeOf RuntimeTypes.BOXEDty)
        val (bind, bitIndex) = insert bind (DIV (fieldIndex, pointerSize))
        val (bind, bitSize) = insert bind (SUB (nextIndex, bitIndex))
      in
        (bind, bitIndex, {tag = tag, bitShift = bitSize} :: results)
      end
       
  fun computeRecord fields =
      let
(*
val _ = print "--- computeRecord begin ---\n"
val _ = (print "tag: "; printValues (map #tag fields); print "\n")
val _ = (print "size: "; printValues (map #size fields); print "\n")
*)
        val fields = map (fn {tag,size} =>
                             {tag = castToWord tag, size = castToWord size})
                         fields
        val sizes = map (fn {tag,size} => {size=size}) fields
        val (bind, layoutRev) = computeLayoutRev emptyBind (rev sizes)
        val (bind, layoutRev) = alignTotalSize bind layoutRev
        val totalSize = case layoutRev of nil => CONST 0w0
                                        | {totalSize,...}::_ => totalSize
        val layout = rev layoutRev
        val fields =
            ListPair.mapEq
              (fn ({tag,size}, {fieldIndex, totalSize}) =>
                  {tag = tag, fieldIndex = fieldIndex, totalSize = totalSize})
              (fields, layout)
        val (bind, _, bits) = computeBitIndex bind fields
(*
val _ = (print "bit: "; printValues (map #tag bits); print "\n")
val _ = (print "shift: "; printValues (map #bitShift bits); print "\n")
*)
        val (bind, bitmap) = computeRecordBitmapRev bind (emptyBitmap, rev bits)
(*
val _ = print "--- computeRecord end ---\n"
*)
      in
        (toDecls bind,
         {totalSize = totalSize,
          fieldIndexes = map #fieldIndex layout,
          bitmap = #words bitmap})
      end

  fun addBitsToBitmapRev bind (nil, bitmap:bitmap) = (bind, bitmap)
    | addBitsToBitmapRev bind ({tag}::bitsRev, bitmap as {maxNumBits, words}) =
      case words of
        nil =>
        addBitsToBitmapRev bind (bitsRev, {maxNumBits = 1, words = [tag]})
      | _::_ =>
        let
(*
val _ = (print "shiftBitmap(";
printBitmap bitmap;
print ") = ")
*)
          val (bind, bitmap) = shiftBitmapBits bind (bitmap, CONST 0w1)
(*
val _ = (
printBitmap bitmap;
print "\n")
val _ = (print "setBitmap(";
printBitmap bitmap;
print ",";
printValue tag;
print ") = ")
*)
          val (bind, bitmap) = setBitmapBit bind (bitmap, tag)
(*
val _ = (
printBitmap bitmap;
print "\n")
*)
        in
          addBitsToBitmapRev bind (bitsRev, bitmap)
        end

  fun addBitsToBitmap (bits, bitmap) =
      let
(*
val _ = print "--- addBitsToBitmap start ---\n"
val _ = (print "bits: ";
printValues (map #tag bits);
print "\n")
*)
        val bits = map (fn {tag} => {tag = castToWord tag}) bits
        val (bind, bitmap) = addBitsToBitmapRev emptyBind (rev bits, bitmap)
(*
val _ = (print "return: ";
printBitmap bitmap;
print "\n")
val _ = print "--- addBitsToBitmap end ---\n"
*)
      in
        (toDecls bind, bitmap)
      end

end
