(**
 * CharVectorSlice
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

(* NOTE:
 * CharVector.vector is not "char vector", but "string".
 * The only difference between "char vector" and "string" is that "string"
 * value is always terminated by hidden sentinel null character but
 * "char vector" is not.
 * Due to this difference, CharVectorSlice does not use common implementation
 * code "VectorSlice_common.sml".
 *)

infix 7 * / div mod
infix 6 + -
infixr 5 ::
infix 4 = <> > >= < <=
val op + = SMLSharp_Builtin.Int.add_unsafe
val op - = SMLSharp_Builtin.Int.sub_unsafe
val op > = SMLSharp_Builtin.Int.gt
val op < = SMLSharp_Builtin.Int.lt
val op <= = SMLSharp_Builtin.Int.lteq
val op >= = SMLSharp_Builtin.Int.gteq
structure Array = SMLSharp_Builtin.Array
structure Vector = SMLSharp_Builtin.Vector
structure String = SMLSharp_Builtin.String

structure CharVectorSlice =
struct

  type elem = char
  type vector = string
  type slice = string * int * int  (* array * start * length *)

  (* object size occupies 26 bits of 32-bit object header. In addition,
   * "string" have sentinel zero character at the end of the char sequence *)
  val maxLen = 0x03fffffe

  fun length ((vec, start, length):slice) = length

  fun sub ((vec, start, length):slice, index) =
      if index < 0 orelse length <= index then raise Subscript
      else Array.sub_unsafe (String.castToArray vec, start + index)

  fun full vec =
      (vec, 0, String.size vec) : slice

  fun slice (vec, start, NONE) =
      let
        val len = String.size vec
      in
        if start < 0 orelse len < start then raise Subscript
        else (vec, start, len - start)
      end
    | slice (vec, start, SOME length) =
      let
        val len = String.size vec
      in
        if start < 0 orelse len < start
           orelse length < 0 orelse len - start < length
        then raise Subscript
        else (vec, start, length)
      end

  fun subslice ((vec, start, length):slice, start2, NONE) =
      if start2 < 0 orelse length < start2 then raise Subscript
      else (vec, start + start2, length - start2)
    | subslice ((vec, start, length):slice, start2, SOME length2) =
      if start2 < 0 orelse length < start2
         orelse length2 < 0 orelse length - start2 < length2
      then raise Subscript
      else (vec, start + start2, length2)

  fun base (x:slice) = x

  fun vector ((vec, start, length):slice) =
      let
        val buf = String.alloc_unsafe length
      in
        Array.copy_unsafe (String.castToArray vec, start,
                           String.castToArray buf, 0, length);
        buf
      end

  fun isEmpty ((vec, start, length):slice) = length = 0

  fun getItem ((vec, start, length):slice) =
      if length <= 0 then NONE
      else SOME (Array.sub_unsafe (String.castToArray vec, start),
                 (vec, start + 1, length - 1) : slice)

  fun foldli foldFn z ((vec, start, length):slice) =
      let
        val max = start + length
        fun loop (i, z) =
            if i >= max then z
            else let val x = Array.sub_unsafe (String.castToArray vec, i)
                 in loop (i + 1, foldFn (i - start, x, z))
                 end
      in
        loop (start, z)
      end

  fun foldl foldFn z slice =
      foldli (fn (i,x,z) => foldFn (x,z)) z slice

  fun foldri foldFn z ((vec, start, length):slice) =
      let
        fun loop (i, z) =
            if i < start then z
            else let val x = Array.sub_unsafe (String.castToArray vec, i)
                 in loop (i - 1, foldFn (i - start, x, z))
                 end
      in
        loop (start + length - 1, z)
      end

  fun foldr foldFn z slice =
      foldri (fn (i,x,z) => foldFn (x,z)) z slice

  fun appi appFn slice =
      foldli (fn (i,x,()) => appFn (i,x)) () slice

  fun app appFn slice =
      foldli (fn (i,x,()) => appFn x) () slice

  fun findi predicate ((vec, start, length):slice) =
      let
        val max = start + length
        fun loop i =
            if i >= max then NONE
            else let val x = Array.sub_unsafe (String.castToArray vec, i)
                 in if predicate (i - start, x)
                    then SOME (i, x) else loop (i + 1)
                 end
      in
        loop start
      end

  fun find predicate slice =
      case findi (fn (i,x) => predicate x) slice of
        NONE => NONE
      | SOME (i,x) => SOME x

  fun exists predicate vec =
      case find predicate vec of
        SOME _ => true
      | NONE => false

  fun all predicate ((vec, start, length):slice) =
      let
        val max = start + length
        fun loop i =
            if i >= max then true
            else predicate (Array.sub_unsafe (String.castToArray vec, i))
                 andalso loop (i + 1)
      in
        loop start
      end

  fun collate cmpFn ((vec1, start1, length1):slice,
                     (vec2, start2, length2):slice) =
      let
        fun loop (i, 0, j, 0) = General.EQUAL
          | loop (i, 0, j, _) = General.LESS
          | loop (i, _, j, 0) = General.GREATER
          | loop (i, rest1, j, rest2) =
            let
              val c1 = Array.sub_unsafe (String.castToArray vec1, i)
              val c2 = Array.sub_unsafe (String.castToArray vec2, j)
            in
              case cmpFn (c1, c2) of
                General.EQUAL => loop (i + 1, rest1 - 1, j + 1, rest2 - 1)
              | order => order
            end
      in
        loop (start1, length1, start2, length2)
      end

  fun concat slices =
      let
        fun totalLength (nil : slice list, z) = z
          | totalLength (((vec, start, length):slice)::t, z) =
            let val z = length + z
            in if z > maxLen then raise Size
               else totalLength (t, z)
            end
        val len = totalLength (slices, 0)
        val buf = String.alloc_unsafe len
        fun loop (i, nil) = ()
          | loop (i, (vec, start, len)::t) =
            (Array.copy_unsafe (String.castToArray vec, start,
                                String.castToArray buf, i, len);
             loop (i + len, t))
      in
        loop (0, slices);
        buf
      end

  fun mapi mapFn ((vec, start, length):slice) =
      let
        val buf = String.alloc_unsafe length
        val max = start + length
        fun loop i =
            if i >= max then ()
            else
              let val x = Array.sub_unsafe (String.castToArray vec, i)
                  val x = mapFn (i - start, x)
              in Array.update_unsafe (String.castToArray buf, i, x);
                 loop (i + 1)
              end
      in
        loop start;
        buf
      end

  fun map mapFn slice =
      mapi (fn (i,x) => mapFn x) slice

end
