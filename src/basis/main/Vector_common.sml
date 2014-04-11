(**
 * common implementation of Vector structures
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

(*
 * This file is intended to be included by "_use" from implementation file
 * of each vector structures.
 * Before include this file, each implementation must define the following
 * things.

(* the type of the element of the vector *)
type 'a elem = ...

(* maximum length of the vector *)
val maxLen = ...

*)

local
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
in

structure Vector_common =
struct

  type 'a vector = 'a elem vector

  val maxLen = maxLen

  fun fromList (elems : 'a elem list) =
      let
        fun length (z, nil : 'a elem list) = z
          | length (z, h::t) = length (z + 1, t)
        val len = length (0, elems)
        val buf = Array.alloc len
        fun loop (i, nil) = ()
          | loop (i, h::t) = (Array.update_unsafe (buf, i, h); loop (i + 1, t))
      in
        loop (0, elems);
        Array.turnIntoVector buf
      end

  fun tabulate (size, elemFn : int -> 'a elem) =
      let
        val buf = Array.alloc size
        fun loop i =
            if i >= size then ()
            else (Array.update_unsafe (buf, i, elemFn i); loop (i + 1))
      in
        loop 0;
        Array.turnIntoVector buf
      end

  val length = Vector.length
  val sub = Vector.sub

  fun foldli foldFn (z : 'b) (vec : 'a vector) =
      let
        val len = Vector.length vec
        fun loop (i, z : 'b) =
            if i >= len then z
            else let val x = Array.sub_unsafe (Vector.castToArray vec, i)
                 in loop (i + 1, foldFn (i, x, z))
                 end
      in
        loop (0, z)
      end

  fun foldl foldFn z vec =
      foldli (fn (i,x,z) => foldFn (x,z)) z vec

  fun foldri foldFn (z : 'b) (vec : 'a vector) =
      let
        val len = Vector.length vec
        fun loop (i, z : 'b) =
            if i < 0 then z
            else let val x = Array.sub_unsafe (Vector.castToArray vec, i)
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

  fun findi predicate (vec : 'a vector) =
      let
        val len = Vector.length vec
        fun loop i =
            if i >= len then NONE
            else let val x = Array.sub_unsafe (Vector.castToArray vec, i)
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

  fun all predicate (vec : 'a vector) =
      let
        val len = Vector.length vec
        fun loop i =
            if i >= len then true
            else predicate (Array.sub_unsafe (Vector.castToArray vec, i))
                 andalso loop (i + 1)
      in
        loop 0
      end

  fun collate cmpFn (vec1 : 'a vector, vec2 : 'a vector) =
      let
        val len1 = Vector.length vec1
        val len2 = Vector.length vec2
        fun loop (i, 0, 0) = General.EQUAL
          | loop (i, 0, _) = General.LESS
          | loop (i, _, 0) = General.GREATER
          | loop (i, rest1, rest2) =
            let
              val c1 = Array.sub_unsafe (Vector.castToArray vec1, i)
              val c2 = Array.sub_unsafe (Vector.castToArray vec2, i)
            in
              case cmpFn (c1, c2) of
                General.EQUAL => loop (i + 1, rest1 - 1, rest2 - 1)
              | order => order
            end
      in
        loop (0, len1, len2)
      end

  fun update (vec, index, value) =
      let
        val len = Vector.length vec
        val buf = Array.alloc_unsafe len
      in
        Array.copy_unsafe (Vector.castToArray vec, 0, buf, 0, len);
        Array.update (buf, index, value);
        Array.turnIntoVector buf
      end

  fun concat nil = Array.turnIntoVector (Array.alloc_unsafe 0)
    | concat [x] = x
    | concat (vectors : 'a vector list) =
      let
        fun totalLength (nil : 'a vector list, z) = z
          | totalLength (h::t, z) =
            let val len = Vector.length h
                val z = len + z
            in if z > maxLen then raise Size else totalLength (t, z)
            end
        val len = totalLength (vectors, 0)
        val buf = Array.alloc_unsafe len
        fun loop (i, nil : 'a vector list) = ()
          | loop (i, h::t) =
            let
              val len = Vector.length h
            in
              Array.copy_unsafe (Vector.castToArray h, 0, buf, i, len);
              loop (i + len, t)
            end
      in
        loop (0, vectors);
        Array.turnIntoVector buf
      end

  fun mapi (mapFn : int * 'a elem -> 'b) (vec : 'a vector) =
      let
        val len = Vector.length vec
        val buf = Array.alloc_unsafe len
        fun loop i =
            if i >= len then ()
            else let val x = Array.sub_unsafe (Vector.castToArray vec, i)
                 in Array.update_unsafe (buf, i, mapFn (i, x));
                    loop (i + 1)
                 end
      in
        loop 0;
        Array.turnIntoVector buf
      end

  fun map mapFn vec =
      mapi (fn (i,x) => mapFn x) vec

end

end (* local *)
