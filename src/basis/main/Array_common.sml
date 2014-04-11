(**
 * common implementation of Array structures
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

(*
 * This file is intended to be included by "_use" from implementation file
 * of each array structures.
 * Before include this file, each implementation must define the following
 * things.

(* the type of the element of the array *)
type 'a elem = ...

(* maximum length of the array *)
val maxLen = ...

*)

local
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
  structure Array = SMLSharp_Builtin.Array
in

structure Array_common =
struct

  type 'a array = 'a elem array
  type 'a vector = 'a elem vector

  val maxLen = maxLen

  fun array (len, elem : 'a elem) =
      let
        val buf = Array.alloc len
        fun loop i =
            if i >= len then ()
            else (Array.update_unsafe (buf, i, elem); loop (i + 1))
      in
        loop 0;
        buf
      end

  fun fromList (elems : 'a elem list) =
      let
        fun length (z, nil : 'a elem list) = z
          | length (z, h::t) = length (z + 1, t)
        val len = length (0, elems)
        val buf = Array.alloc len
        fun loop (i, nil : 'a elem list) = ()
          | loop (i, h::t) = (Array.update_unsafe (buf, i, h); loop (i + 1, t))
      in
        loop (0, elems);
        buf
      end

  fun tabulate (len, elemFn : int -> 'a elem) =
      let
        val buf = Array.alloc len
        fun loop i =
            if i >= len then ()
            else (Array.update_unsafe (buf, i, elemFn i); loop (i + 1))
      in
        loop 0;
        buf
      end

  val length = Array.length
  val sub = Array.sub
  val update = Array.update

  fun foldli foldFn (z : 'b) (ary : 'a elem array) =
      let
        val len = Array.length ary
        fun loop (i, z : 'b) =
            if i >= len then z
            else let val x = Array.sub_unsafe (ary, i)
                 in loop (i + 1, foldFn (i, x, z))
                 end
      in
        loop (0, z)
      end

  fun foldl foldFn z ary =
      foldli (fn (i,x,z) => foldFn (x,z)) z ary

  fun foldri foldFn (z : 'b) (ary : 'a elem array) =
      let
        val len = Array.length ary
        fun loop (i, z) =
            if i < 0 then z
            else let val x = Array.sub_unsafe (ary, i)
                 in loop (i - 1, foldFn (i, x, z))
                 end
      in
        loop (len - 1, z)
      end

  fun foldr foldFn z ary =
      foldri (fn (i,x,z) => foldFn (x,z)) z ary

  fun appi appFn ary =
      foldli (fn (i,x,()) => appFn (i,x)) () ary

  fun app appFn ary =
      foldli (fn (i,x,()) => appFn x) () ary

  fun findi predicate (ary : 'a array) =
      let
        val len = Array.length ary
        fun loop i =
            if i >= len then NONE
            else let val x = Array.sub_unsafe (ary, i)
                 in if predicate (i, x) then SOME (i, x) else loop (i + 1)
                 end
      in
        loop 0
      end

  fun find predicate ary =
      case findi (fn (i,x) => predicate x) ary of
        SOME (i,x) => SOME x
      | NONE => NONE

  fun exists predicate ary =
      case find predicate ary of
        SOME _ => true
      | NONE => false

  fun all predicate (ary : 'a array) =
      let
        val len = Array.length ary
        fun loop i =
            if i >= len then true
            else predicate (Array.sub_unsafe (ary, i))
                 andalso loop (i + 1)
      in
        loop 0
      end

  fun collate cmpFn (ary1 : 'a array, ary2 : 'a array) =
      let
        val len1 = Array.length ary1
        val len2 = Array.length ary2
        fun loop (i, 0, 0) = General.EQUAL
          | loop (i, 0, _) = General.LESS
          | loop (i, _, 0) = General.GREATER
          | loop (i, rest1, rest2) =
            let
              val c1 = Array.sub_unsafe (ary1, i)
              val c2 = Array.sub_unsafe (ary2, i)
            in
              case cmpFn (c1, c2) of
                General.EQUAL => loop (i + 1, rest1 - 1, rest2 - 1)
              | order => order
            end
      in
        loop (0, len1, len2)
      end

  fun vector (ary : 'a array) =
      let
        val len = Array.length ary
        val buf = Array.alloc_unsafe len
      in
        Array.copy_unsafe (ary, 0, buf, 0, len);
        Array.turnIntoVector buf
      end

  val copy = Array.copy

  fun copyVec {src : 'a vector, dst : 'a array, di} =
      Array.copy {src = SMLSharp_Builtin.Vector.castToArray src,
                  dst = dst, di = di}

  fun modifyi mapFn (ary : 'a array) =
      let
        val len = Array.length ary
        fun loop i =
            if i >= len then ()
            else let val x = Array.sub_unsafe (ary, i)
                 in Array.update_unsafe (ary, i, mapFn (i, x));
                    loop (i + 1)
                 end
      in
        loop 0
      end

  fun modify mapFn ary =
      modifyi (fn (i,x) => mapFn x) ary

end

end (* local *)
