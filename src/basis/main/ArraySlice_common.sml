(**
 * common implementation of ArraySlice structures
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

(*
 * This file is intended to be included by "_use" from implementation file
 * of each array slice structures.
 * Before include this file, each implementation must define the following
 * things.

(* the type of the element of the array *)
type 'a elem = ...

(* maximum length of the array *)
val maxLen = ...

(* corresponding VectorSlice structure *)
structure VectorSlice = ...

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

structure ArraySlice_common =
struct

  type 'a array = 'a elem array
  type 'a vector = 'a elem vector
  type 'a slice = 'a array * int * int  (* array * start * length *)

  fun length ((ary, start, length):'a slice) = length

  fun sub ((ary, start, length):'a slice, index) =
      if index < 0 orelse length <= index then raise Subscript
      else Array.sub_unsafe (ary, start + index)

  fun full ary = (ary, 0, Array.length ary) : 'a slice

  fun slice (ary, start, NONE) =
      let
        val len = Array.length ary
      in
        if start < 0 orelse len < start then raise Subscript
        else (ary, start, len - start)
      end
    | slice (ary, start, SOME length) =
      let
        val len = Array.length ary
      in
        if start < 0 orelse len < start
           orelse length < 0 orelse len - start < length
        then raise Subscript
        else (ary, start, length)
      end

  fun subslice ((ary, start, length):'a slice, start2, NONE) =
      if start2 < 0 orelse length < start2 then raise Subscript
      else (ary, start + start2, length - start2)
    | subslice ((ary, start, length):'a slice, start2, SOME length2) =
      if start2 < 0 orelse length < start2
         orelse length2 < 0 orelse length - start2 < length2
      then raise Subscript
      else (ary, start + start2, length2)

  fun base (x:'a slice) = x

  fun vector ((ary, start, length):'a slice) =
      let
        val buf = Array.alloc length
      in
        Array.copy_unsafe (ary, start, buf, 0, length);
        Array.turnIntoVector buf
      end

  fun isEmpty ((ary, start, length):'a slice) = length = 0

  fun getItem ((ary, start, length):'a slice) =
      if length <= 0 then NONE
      else SOME (Array.sub_unsafe (ary, start),
                 (ary, start + 1, length - 1) : 'a slice)

  fun foldli foldFn (z : 'b) ((ary, start, length):'a slice) =
      let
        fun loop (i, z : 'b) =
            if i >= start + length then z
            else loop (i + 1, foldFn (i - start, Array.sub_unsafe (ary, i), z))
      in
        loop (start, z)
      end

  fun foldl foldFn z slice =
      foldli (fn (i,x,z) => foldFn (x,z)) z slice

  fun foldri foldFn (z : 'b) ((ary, start, length):'a slice) =
      let
        fun loop (i, z : 'b) =
            if i < start then z
            else loop (i - 1, foldFn (i - start, Array.sub_unsafe (ary, i), z))
      in
        loop (start + length - 1, z)
      end

  fun foldr foldFn z slice =
      foldri (fn (i,x,z) => foldFn (x,z)) z slice

  fun appi appFn slice =
      foldli (fn (i,x,()) => appFn (i,x)) () slice

  fun app appFn slice =
      foldli (fn (i,x,()) => appFn x) () slice

(* bug 294_arraySliceFindi 
  fun findi predicate ((ary, start, length):'a slice) =
      let
        fun loop i =
            if i >= start + length then NONE
            else let val x = Array.sub_unsafe (ary, i)
                 in if predicate (i - start, x)
                    then SOME (i, x) else loop (i + 1)
                 end
      in
        loop start
      end
*)
  fun findi predicate ((ary, start, length):'a slice) =
      let
        fun loop i =
            if i >= start + length then NONE
            else let val x = Array.sub_unsafe (ary, i)
                 in if predicate (i - start, x)
                    then SOME (i - start, x) else loop (i + 1)
                 end
      in
        loop start
      end

  fun find predicate slice =
      case findi (fn (i,x) => predicate x) slice of
        NONE => NONE
      | SOME (i,x) => SOME x

  fun exists predicate ary =
      case find predicate ary of
        SOME _ => true
      | NONE => false

  fun all predicate ((ary, start, length):'a slice) =
      let
        fun loop i =
            if i >= start + length then true
            else predicate (Array.sub_unsafe (ary, i)) andalso loop (i + 1)
      in
        loop start
      end

  fun collate cmpFn ((ary1, start1, length1):'a slice,
                     (ary2, start2, length2):'a slice) =
      let
        fun loop (i, 0, j, 0) = General.EQUAL
          | loop (i, 0, j, _) = General.LESS
          | loop (i, _, j, 0) = General.GREATER
          | loop (i, rest1, j, rest2) =
            let
              val c1 = Array.sub_unsafe (ary1, i)
              val c2 = Array.sub_unsafe (ary2, j)
            in
              case cmpFn (c1, c2) of
                General.EQUAL => loop (i + 1, rest1 - 1, j + 1, rest2 - 1)
              | order => order
            end
      in
        loop (start1, length1, start2, length2)
      end

  fun update ((ary, start, length):'a slice, index, elem) =
      if index < 0 orelse length <= index
      then raise Subscript
      else Array.update_unsafe (ary, start + index, elem)

  fun copy {src = (ary, start, length):'a slice, dst, di} =
      let
        val dstlen = Array.length dst
      in
        if di >= 0 andalso dstlen >= di andalso dstlen - di >= length
        then Array.copy_unsafe (ary, start, dst, di, length)
        else raise Subscript
      end

  fun copyVec {src, dst, di} =
      let
        val (vec, start, length) = VectorSlice.base src
        val dstlen = Array.length dst
      in
        if di >= 0 andalso dstlen >= di andalso dstlen - di >= length
        then Array.copy_unsafe (Vector.castToArray vec, start, dst, di, length)
        else  raise Subscript
      end

  fun modifyi mapFn ((ary, start, length):'a slice) =
      let
        fun loop i =
            if i >= start + length then ()
            else
              let val x = Array.sub_unsafe (ary, i)
              in Array.update_unsafe (ary, i, mapFn (i - start, x));
                 loop (i + 1)
              end
      in
        loop start
      end

  fun modify mapFn slice =
      modifyi (fn (i,x) => mapFn x) slice

end

end (* local *)
