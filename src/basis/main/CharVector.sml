(**
 * CharVector
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

(* NOTE:
 * CharVector.vector is not "char vector", but "string".
 * The only difference between "char vector" and "string" is that "string"
 * value is always terminated by hidden sentinel null character but
 * "char vector" is not.
 * Due to this difference, CharVector does not use common implementation
 * code "Vector_common.sml".
 *)

infix 7 * / div mod
infix 6 + - ^
infixr 5 ::
infix 4 = <> > >= < <=
val op + = SMLSharp_Builtin.Int.add_unsafe
val op - = SMLSharp_Builtin.Int.sub_unsafe
val op > = SMLSharp_Builtin.Int.gt
val op < = SMLSharp_Builtin.Int.lt
val op <= = SMLSharp_Builtin.Int.lteq
val op >= = SMLSharp_Builtin.Int.gteq
structure String = SMLSharp_Builtin.String
structure Array = SMLSharp_Builtin.Array
structure Vector = SMLSharp_Builtin.Vector

structure CharVector =
struct

  type vector = string
  type elem = char

  (* object size occupies 26 bits of 32-bit object header. In addition,
   * "string" have sentinel zero character at the end of the char sequence *)
  val maxLen = 0x03fffffe

  val length = String.size
  val sub = String.sub

  fun foldli foldFn z vec =
      let
        val len = String.size vec
        fun loop (i, z) =
            if i >= len then z
            else let val x = Array.sub_unsafe (String.castToArray vec, i)
                 in loop (i + 1, foldFn (i, x, z))
                 end
      in
        loop (0, z)
      end

  fun foldl foldFn z vec =
      foldli (fn (i,x,z) => foldFn (x,z)) z vec

  fun foldri foldFn z vec =
      let
        val len = String.size vec
        fun loop (i, z) =
            if i < 0 then z
            else let val x = Array.sub_unsafe (String.castToArray vec, i)
                 in loop (i - 1, foldFn (i, x, z))
                 end
      in
        loop (len - 1, z)
      end

  fun foldr foldFn z vec =
      foldri (fn (i,x,z) => foldFn (x,z)) z vec

  fun appi appFn vec =
      foldli (fn (i,x,()) => appFn (i,x)) () vec

  fun app appFn vec =
      foldli (fn (i,x,()) => appFn x) () vec

  fun findi predicate vec =
      let
        val len = String.size vec
        fun loop i =
            if i >= len then NONE
            else let val x = Array.sub_unsafe (String.castToArray vec, i)
                 in if predicate (i, x) then SOME (i, x) else loop (i + 1)
                 end
      in
        loop 0
      end

  fun find predicate vec =
      case findi (fn (i,x) => predicate x) vec of
        SOME (i,x) => SOME x
      | NONE => NONE

  fun exists predicate vec =
      case find predicate vec of
        SOME _ => true
      | NONE => false

  fun all predicate vec =
      let
        val len = String.size vec
        fun loop i =
            if i >= len then true
            else predicate (Array.sub_unsafe (String.castToArray vec, i))
                 andalso loop (i + 1)
      in
        loop 0
      end

  fun collate cmpFn (vec1, vec2) =
      let
        val len1 = String.size vec1
        val len2 = String.size vec2
        fun loop (i, 0, 0) = General.EQUAL
          | loop (i, 0, _) = General.LESS
          | loop (i, _, 0) = General.GREATER
          | loop (i, rest1, rest2) =
            let
              val c1 = Array.sub_unsafe (String.castToArray vec1, i)
              val c2 = Array.sub_unsafe (String.castToArray vec2, i)
            in
              case cmpFn (c1, c2) of
                General.EQUAL => loop (i + 1, rest1 - 1, rest2 - 1)
              | order => order
            end
      in
        loop (0, len1, len2)
      end

  fun fromList elems =
      let
        fun length (nil : char list, z) = z
          | length (h::t, z) = length (t, z + 1)
        val len = length (elems, 0)
        val buf = String.alloc len
        fun fill (i, nil) = ()
          | fill (i, h::t) =
            (Array.update_unsafe (String.castToArray buf, i, h);
             fill (i + 1, t))
      in
        fill (0, elems);
        buf
      end

  fun tabulate (len, elemFn) =
      let
        val buf = String.alloc len
        fun fill i =
            if i >= len then ()
            else (Array.update_unsafe (String.castToArray buf, i, elemFn i);
                  fill (i + 1))
      in
        fill 0;
        buf
      end

  fun update (vec, index, value) =
      let
        val len = String.size vec
        val buf = String.alloc_unsafe len
      in
        if index < 0 orelse index >= len then raise Subscript else ();
        Array.copy_unsafe (String.castToArray vec, 0,
                           String.castToArray buf, 0, len);
        Array.update_unsafe (String.castToArray buf, index, value);
        buf
      end

  fun concat nil = ""
    | concat [x] = x
    | concat vectors =
      let
        fun totalLength (nil, z) = z
          | totalLength (h::t, z) =
            let val len = String.size h
                val z = len + z
            in if z > maxLen then raise Size else totalLength (t, z)
            end
        val len = totalLength (vectors, 0)
        val buf = String.alloc_unsafe len
        fun loop (i, nil) = ()
          | loop (i, h::t) =
            let val len = String.size h
            in Array.copy_unsafe (String.castToArray h, 0,
                                  String.castToArray buf, i, len);
               loop (i + len, t)
            end
      in
        loop (0, vectors);
        buf
      end

  fun mapi mapFn vec =
      let
        val len = String.size vec
        val buf = String.alloc_unsafe len
        fun loop i =
            if i >= len then ()
            else
              let val x = Array.sub_unsafe (String.castToArray vec, i)
              in Array.update_unsafe (String.castToArray buf, i, mapFn (i, x));
                 loop (i + 1)
              end
      in
        loop 0;
        buf
      end

  fun map mapFn vec =
      mapi (fn (i,x) => mapFn x) vec

end
