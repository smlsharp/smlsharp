(**
 * common implementation of Slice structures
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, 2019, Tohoku University.
 *)

(*
This file is included by "_use" from *{Vector,Array}.sml.
Before include this file, the following must be defined:

structure Seq =
struct
  type 'a seq = ...            (* the type of the sequence *)
  type 'a elem = ...           (* the type of the element *)
  val castToArray = ...        (* cast the sequence to array *)
  val length = ...             (* length of the sequence *)
  val alloc = ...              (* allocate a seq with size check *)
  val alloc_unsafe = ...       (* allocate a seq without size check *)

  type 'a vector = ...         (* the type of the vector *)
  val castVectorToArray = ...  (* cast the vector to array *)
  val allocVector = ...        (* allocate a vector with size check *)
  val allocVector_unsafe = ... (* allocate a vector without size check *)
  fun empty () = ...           (* empty vector *)

  structure VectorSlice = ...  (* corresponding VectorSlice structure *)
end
*)

local
  infix 7 * / div mod
  infix 6 + -
  infixr 5 ::
  infix 4 = <> > >= < <=
  val op + = SMLSharp_Builtin.Int32.add_unsafe
  val op - = SMLSharp_Builtin.Int32.sub_unsafe
  val op < = SMLSharp_Builtin.Int32.lt
  val op <= = SMLSharp_Builtin.Int32.lteq
  val op >= = SMLSharp_Builtin.Int32.gteq
  structure Int32 = SMLSharp_Builtin.Int32
  structure Array = SMLSharp_Builtin.Array
in

structure Slice_common =
struct

  type 'a slice = 'a Seq.seq * int * int  (* array * start * length *)
  (* invariant: start >= 0, length >= 0, 0 <= start + length <= length array *)

  fun base (x:'a slice) = x

  fun full seq = (seq, 0, Seq.length seq) : 'a slice

  fun length ((seq, start, length):'a slice) = length

  fun isEmpty ((seq, start, length):'a slice) = length = 0

  fun sub ((seq, start, length):'a slice, index) =
      if index < 0 orelse length <= index then raise Subscript
      else Array.sub_unsafe (Seq.castToArray seq, start + index)

  fun update ((seq, start, length):'a slice, index, elem) =
      if index < 0 orelse length <= index then raise Subscript
      else Array.update_unsafe (Seq.castToArray seq, start + index, elem)

  fun copy {src = (seq, start, length):'a slice, dst : 'a Seq.seq, di} =
      let
        val dstlen = Seq.length dst
      in
        if di < 0 orelse dstlen < di orelse dstlen - di < length
        then raise Subscript
        else Array.copy_unsafe (Seq.castToArray seq, start,
                                Seq.castToArray dst, di, length)
      end

  fun 'a copyVec {src, dst, di} =
      let
        val (vec : 'a Seq.vector, start, length) = Seq.VectorSlice.base src
        val dstlen = Seq.length dst
      in
        if di < 0 orelse dstlen < di orelse dstlen - di < length
        then raise Subscript
        else Array.copy_unsafe (Seq.castVectorToArray vec, start,
                                Seq.castToArray dst, di, length)
      end

  fun vector ((seq, start, length):'a slice) =
      let
        val buf = Seq.allocVector_unsafe length
      in
        Array.copy_unsafe (Seq.castToArray seq, start,
                           Seq.castVectorToArray buf, 0, length);
        buf
      end

  fun concatWith sep [] = Seq.emptyVector () : 'a Seq.vector
    | concatWith sep [x : 'a slice] = vector x
    | concatWith sep slices =
      let
        val sepLen = Seq.length sep
        fun totalLength (z, nil : 'a slice list) = z
          | totalLength (z, [(_,_,len)]) = Int32.add (z, len)
          | totalLength (z, (_,_,len)::t) =
            totalLength (Int32.add (Int32.add (z, len), sepLen), t)
        val len = totalLength (0, slices) handle Overflow => raise Size
        val buf = Seq.allocVector len
        fun loop (i, nil : 'a slice list) = ()
          | loop (i, (vec, beg, len)::t) =
            (Array.copy_unsafe (Seq.castToArray vec, beg,
                                Seq.castVectorToArray buf, i, len);
             case t of
               nil => ()
             | _::_ =>
               let val i = i + len
               in Array.copy_unsafe (Seq.castToArray sep, 0,
                                     Seq.castVectorToArray buf, i, sepLen);
                  loop (i + sepLen, t)
               end)
      in
        loop (0, slices);
        buf
      end

  fun concat nil = Seq.emptyVector () : 'a Seq.vector
    | concat [x : 'a slice] = vector x
    | concat slices =
      let
        fun totalLength (nil : 'a slice list, z) = z
          | totalLength ((vec, start, length)::t, z) =
            totalLength (t, Int32.add (length, z))
        val len = totalLength (slices, 0) handle Overflow => raise Size
        val buf = Seq.allocVector len
        fun loop (i, nil : 'a slice list) = ()
          | loop (i, (vec, start, length)::t) =
            (Array.copy_unsafe (Seq.castToArray vec, start,
                                Seq.castVectorToArray buf, i, length);
             loop (i + length, t))
      in
        loop (0, slices);
        buf
      end

  fun translate transFn ((vec, start, length):'a slice) =
      let
        fun init (i, totalSize, buf) =
            if i >= start + length then (totalSize, buf)
            else let val c = Array.sub_unsafe (Seq.castToArray vec, i)
                     val x = transFn c
                     val n = Seq.length x
                     val totalSize =
                         Int32.add (totalSize, n) handle Overflow => raise Size
                 in init (i + 1, totalSize, x :: buf)
                 end
        val (totalSize, buf) = init (start, 0, nil)
        val dst = Seq.alloc totalSize
        fun concat (i, nil) = dst
          | concat (i, h::t) =
            let val len = Seq.length h
                val i = i - len
            in Array.copy_unsafe (Seq.castToArray h, 0,
                                  Seq.castToArray dst, i, len);
               concat (i, t)
            end
      in
        concat (totalSize, buf)
      end

  fun collate cmpFn ((seq1, start1, length1):'a slice,
                     (seq2, start2, length2):'a slice) =
      let
        fun loop (i, 0, j, 0) = General.EQUAL
          | loop (i, 0, j, _) = General.LESS
          | loop (i, _, j, 0) = General.GREATER
          | loop (i, rest1, j, rest2) =
            let
              val c1 = Array.sub_unsafe (Seq.castToArray seq1, i)
              val c2 = Array.sub_unsafe (Seq.castToArray seq2, j)
            in
              case cmpFn (c1, c2) of
                General.EQUAL => loop (i + 1, rest1 - 1, j + 1, rest2 - 1)
              | order => order
            end
      in
        loop (start1, length1, start2, length2)
      end

  fun explode ((seq, start, length):'a slice) =
      let
        fun loop (i, z) =
            if i >= start
            then loop (i - 1, Array.sub_unsafe (Seq.castToArray seq, i) :: z)
            else z
      in
        loop (start + length - 1, nil)
      end

  fun subsequence (seq, start, length) =
      let
        val len = Seq.length seq
      in
        if start < 0 orelse len < start
           orelse length < 0 orelse len - start < length
        then raise Subscript
        else (seq, start, length)
      end

  fun slice (seq, start, SOME length) = subsequence (seq, start, length)
    | slice (seq, start, NONE) =
      let
        val len = Seq.length seq
      in
        if start < 0 orelse len < start then raise Subscript
        else (seq, start, len - start)
      end

  fun subslice ((seq, start, length):'a slice, start2, lengthOpt) =
      if start2 < 0 orelse length < start2 then raise Subscript
      else case lengthOpt of
             NONE => (seq, start + start2, length - start2)
           | SOME len =>
             if len < 0 orelse length - start2 < len then raise Subscript
             else (seq, start + start2, len)

  fun getItem ((seq, start, length):'a slice) =
      if length <= 0 then NONE
      else SOME (Array.sub_unsafe (Seq.castToArray seq, start),
                 (seq, start + 1, length - 1))

  fun foldli foldFn z ((seq, start, length):'a slice) =
      let
        fun loop (i, z) =
            if i >= start + length then z
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in loop (i + 1, foldFn (i - start, x, z))
                 end
      in
        loop (start, z)
      end

  fun foldl foldFn z ((seq, start, length):'a slice) =
      let
        fun loop (i, z) =
            if i >= start + length then z
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in loop (i + 1, foldFn (x, z))
                 end
      in
        loop (start, z)
      end

  fun foldri foldFn z ((seq, start, length):'a slice) =
      let
        fun loop (i, z) =
            if i < start then z
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in loop (i - 1, foldFn (i - start, x, z))
                 end
      in
        loop (start + length - 1, z)
      end

  fun foldr foldFn z ((seq, start, length):'a slice) =
      let
        fun loop (i, z) =
            if i < start then z
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in loop (i - 1, foldFn (x, z))
                 end
      in
        loop (start + length - 1, z)
      end

  fun appi appFn ((seq, start, length):'a slice) =
      let
        fun loop i =
            if i >= start + length then ()
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in appFn (i - start, x); loop (i + 1)
                 end
      in
        loop start
      end

  fun app appFn ((seq, start, length):'a slice) =
      let
        fun loop i =
            if i >= start + length then ()
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in appFn x; loop (i + 1)
                 end
      in
        loop start
      end

  fun findi predicate ((seq, start, length):'a slice) =
      let
        fun loop i =
            if i >= start + length then NONE
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in if predicate (i - start, x)
                    then SOME (i - start, x) else loop (i + 1)
                 end
      in
        loop start
      end

  fun find predicate ((seq, start, length):'a slice) =
      let
        fun loop i =
            if i >= start + length then NONE
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in if predicate x then SOME x else loop (i + 1)
                 end
      in
        loop start
      end

  fun exists predicate ((seq, start, length):'a slice) =
      let
        fun loop i =
            if i >= start + length then false
            else predicate (Array.sub_unsafe (Seq.castToArray seq, i))
                 orelse loop (i + 1)
      in
        loop start
      end

  fun all predicate ((seq, start, length):'a slice) =
      let
        fun loop i =
            if i >= start + length then true
            else predicate (Array.sub_unsafe (Seq.castToArray seq, i))
                 andalso loop (i + 1)
      in
        loop start
      end

  fun mapi mapFn ((seq, start, length):'a slice) =
      let
        val buf = Seq.alloc_unsafe length
        fun loop i =
            if i >= start + length then ()
            else
              let val x = Array.sub_unsafe (Seq.castToArray seq, i)
              in Array.update_unsafe
                   (Seq.castToArray buf, i - start, mapFn (i - start, x));
                 loop (i + 1)
              end
      in
        loop start;
        buf
      end

  fun map mapFn ((seq, start, length):'a slice) =
      let
        val buf = Seq.alloc_unsafe length
        fun loop i =
            if i >= start + length then ()
            else
              let val x = Array.sub_unsafe (Seq.castToArray seq, i)
              in Array.update_unsafe
                   (Seq.castToArray buf, i - start, mapFn x);
                 loop (i + 1)
              end
      in
        loop start;
        buf
      end

  fun modifyi mapFn ((seq, start, length):'a slice) =
      let
        fun loop i =
            if start + length <= i then ()
            else
              let val x = Array.sub_unsafe (Seq.castToArray seq, i)
              in Array.update_unsafe
                   (Seq.castToArray seq, i, mapFn (i - start, x));
                 loop (i + 1)
              end
      in
        loop start
      end

  fun modify mapFn ((seq, start, length):'a slice) =
      let
        fun loop i =
            if start + length <= i then ()
            else
              let val x = Array.sub_unsafe (Seq.castToArray seq, i)
              in Array.update_unsafe (Seq.castToArray seq, i, mapFn x);
                 loop (i + 1)
              end
      in
        loop start
      end

end

end (* local *)
