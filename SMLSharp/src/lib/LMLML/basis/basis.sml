(*
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)

(*
(* ToDo : SML/NJ 110.0.7 does not provide Word8VectorSlice,
 * we use inefficient way to extract a part of vector.
 *)
structure Word8VectorSlice =
struct

  fun slice (vector, index, lenOpt) =
      let
        val len = Option.getOpt(lenOpt, Word8Vector.length vector - index)
      in
        Word8Vector.tabulate
            (len, fn i => Word8Vector.sub (vector, index + i))
      end

  fun vector vec = vec

end;
*)
(*
structure VectorSlice =
struct

  open Vector

  fun isEmpty vector = 0 = length vector
  fun full vector = vector
  val subslice = extract
  fun find predicate vector =
      let
        val len = length vector
        fun scan index =
            if len <= index
            then NONE
            else
              let val cursor = sub (vector, index)
              in if predicate cursor then SOME cursor else scan (index + 1)
              end
      in
        scan 0
      end
  fun collate collater (vector1, vector2) =
      let
        val len1 = length vector1
        val len2 = length vector2
        fun scan index =
            if len1 <= index
            then if len2 <= index then EQUAL else LESS
            else
              case collater (sub (vector1, index), sub (vector2, index))
               of EQUAL => scan (index + 1)
                | order => order
      in
        scan 0
      end

end
*)
structure List =
struct
  open List
  fun collate f ([], []) = General.EQUAL
    | collate f ([], _) = General.LESS
    | collate f (_, []) = General.GREATER
    | collate f (e1 :: l1, e2 :: l2) =
      case f (e1, e2)
       of EQUAL => collate f (l1, l2)
        | order => order
end
(*
structure BinPrimIO =
struct
  structure V = Word8Vector
  structure A = Word8Array
  open BinPrimIO
  fun openVector v = let
	val pos = ref 0
	val closed = ref false
	fun checkClosed () = if !closed then raise IO.ClosedStream else ()
	val len = V.length v
	fun avail () = len - !pos
	fun readV n = let
	    val p = !pos
	    val m = Int.min (n, len - p)
	in
	    checkClosed ();
	    pos := p + m;
	    V.extract (v, p, SOME m)
	end
	fun readA {buf, i, sz} = let
	    val p = !pos
            val n = getOpt(sz, A.length buf - i)
	    val m = Int.min (n, len - p)
	in
	    checkClosed ();
	    pos := p + m;
	    A.copyVec { src = v, si = p, len = SOME m, dst = buf, di = i };
	    m
	end
	fun checked k () = (checkClosed (); k)
    in
	(* random access not supported because pos type is abstract *)
	RD { name = "<vector>",
	     chunkSize = len,
	     readVec = SOME readV,
	     readArr = SOME readA,
	     readVecNB = SOME (SOME o readV),
	     readArrNB = SOME (SOME o readA),
	     block = SOME checkClosed,
	     canInput = SOME (checked true),
	     avail = SOME o avail,
	     getPos = NONE,
	     setPos = NONE,
	     endPos = NONE,
	     verifyPos = NONE,
	     close = fn () => closed := true,
	     ioDesc = NONE }
    end

end;

*)