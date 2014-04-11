(**
 * common implementation of VectorSlice structures
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

(*
 * This file is intended to be included by "_use" from implementation file
 * of each vector slice structures.
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

structure VectorSlice_common =
struct

  type 'a vector = 'a elem vector
  type 'a slice = 'a vector * int * int  (* array * start * length *)

  fun length ((vec, start, length):'a slice) = length

  fun sub ((vec, start, length):'a slice, index) =
      if index >= 0 andalso index < length
      then Vector.sub (vec, start + index)
      else raise Subscript

  fun full vec =
      (vec, 0, Vector.length vec) : 'a slice

  fun slice (vec : 'a vector, start, NONE) =
      let
        val len = Vector.length vec
      in
        if start < 0 orelse len < start then raise Subscript
        else (vec, start, len - start)
      end
    | slice (vec : 'a vector, start, SOME length) =
      let
        val len = Vector.length vec
      in
        if start < 0 orelse len < start
           orelse length < 0 orelse len - start < length
        then raise Subscript
        else (vec, start, length)
      end

  fun subslice ((vec, start, length):'a slice, start2, NONE) =
      if start2 < 0 orelse length < start2 then raise Subscript
      else (vec, start + start2, length - start2)
    | subslice ((vec, start, length):'a slice, start2, SOME length2) =
      if start2 < 0 orelse length < start2
         orelse length2 < 0 orelse length - start2 < length2
      then raise Subscript
      else (vec, start + start2, length2)

  fun base (x:'a slice) = x

  fun vector ((vec, start, length):'a slice) =
      let
        val buf = Array.alloc_unsafe length
      in
        Array.copy_unsafe (Vector.castToArray vec, start, buf, 0, length);
        Array.turnIntoVector buf
      end

  fun isEmpty ((vec, start, length):'a slice) = length = 0

  fun getItem ((vec, start, length):'a slice) =
      if length <= 0 then NONE
      else SOME (Array.sub_unsafe (Vector.castToArray vec, start),
                 (vec, start + 1, length - 1) : 'a slice)

  fun foldli foldFn (z : 'b) ((vec, start, length):'a slice) =
      let
        val max = start + length
        fun loop (i, z : 'b) =
            if i >= max then z
            else let val x = Array.sub_unsafe (Vector.castToArray vec, i)
                 in loop (i + 1, foldFn (i - start, x, z))
                 end
      in
        loop (start, z)
      end

  fun foldl foldFn z slice =
      foldli (fn (i,x,z) => foldFn (x,z)) z slice

  fun foldri foldFn (z : 'b) ((vec, start, length):'a slice) =
      let
        fun loop (i, z : 'b) =
            if i < start then z
            else let val x = Array.sub_unsafe (Vector.castToArray vec, i)
                 in loop (i - 1, foldFn (i - start, x, z))
                 end
      in
        loop (start + length - 1, z)
      end

  fun foldr foldFn z slice =
      foldri (fn (i,x,z) => foldFn (x,z)) z slice

  fun findi predicate ((vec, start, length):'a slice) =
      let
        val max = start + length
        fun loop i =
            if i >= max then NONE
            else let val x = Array.sub_unsafe (Vector.castToArray vec, i)
                 in if predicate (i - start, x)
                    then SOME (i - start, x) else loop (i + 1)
                 end
      in
        loop start
      end
(* bug 294_arraySliceFindi 
  fun findi predicate ((vec, start, length):'a slice) =
      let
        val max = start + length
        fun loop i =
            if i >= max then NONE
            else let val x = Array.sub_unsafe (Vector.castToArray vec, i)
                 in if predicate (i - start, x)
                    then SOME (i, x) else loop (i + 1)
                 end
      in
        loop start
      end
*)

  fun appi appFn slice =
      foldli (fn (i,x,()) => appFn (i,x)) () slice

  fun app appFn slice =
      foldli (fn (i,x,()) => appFn x) () slice

  fun find predicate slice =
      case findi (fn (i,x) => predicate x) slice of
        NONE => NONE
      | SOME (i,x) => SOME x

  fun exists predicate vec =
      case find predicate vec of
        SOME _ => true
      | NONE => false

  fun all predicate ((vec, start, length):'a slice) =
      let
        val max = start + length
        fun loop i =
            if i >= max then true
            else predicate (Array.sub_unsafe (Vector.castToArray vec, i))
                 andalso loop (i + 1)
      in
        loop start
      end

  fun collate cmpFn ((vec1, start1, length1):'a slice,
                     (vec2, start2, length2):'a slice) =
      let
        fun loop (i, 0, j, 0) = General.EQUAL
          | loop (i, 0, j, _) = General.LESS
          | loop (i, _, j, 0) = General.GREATER
          | loop (i, rest1, j, rest2) =
            let
              val c1 = Array.sub_unsafe (Vector.castToArray vec1, i)
              val c2 = Array.sub_unsafe (Vector.castToArray vec2, j)
            in
              case cmpFn (c1, c2) of
                General.EQUAL => loop (i + 1, rest1 - 1, j + 1, rest2 - 1)
              | order => order
            end
      in
        loop (start1, length1, start2, length2)
      end

  fun concat (slices : 'a slice list) =
      let
        fun totalLength (nil : 'a slice list, z) = z
          | totalLength ((vec, start, length)::t, z) =
            let val next = length + z
            in if next > maxLen then raise Size
               else totalLength (t, next)
            end
        val len = totalLength (slices, 0)
        val buf = Array.alloc_unsafe len
        fun loop (i, nil : 'a slice list) = ()
          | loop (i, (vec, start, length)::t) =
            (Array.copy_unsafe (Vector.castToArray vec, start, buf, i, length);
             loop (i + length, t))
      in
        loop (0, slices);
        Array.turnIntoVector buf
      end

  fun mapi (mapFn : int * 'a elem -> 'b) ((vec, start, length):'a slice) =
      let
        val buf = Array.alloc_unsafe length
        val max = start + length
        fun loop i =
            if i >= max then ()
            else
              let val x = Array.sub_unsafe (Vector.castToArray vec, i)
              in Array.update (buf, i, mapFn (i - start, x));
                 loop (i + 1)
              end
      in
        loop start;
        Array.turnIntoVector buf
      end

  fun map mapFn slice =
      mapi (fn (i,x) => mapFn x) slice

end

end (* local *)

