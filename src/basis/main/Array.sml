(**
 * Array structure.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *
 * @author Atsushi Ohori (refactored)
 * @copyright 2010, 2011, Tohoku University.
 *)

(* 2012-1-07 ohori 
   I have refactored this from ArrayStructures. 
   Since array is the basic structure, we should minimize redefinitions, 
   and inline primitives as much as possible.
*)

_interface "Array.smi"

local
  infix 7 * / div mod
  infix 6 + -
  infixr 5 ::
  infix 4 = <> > >= < <=
  val op + = SMLSharp.Int.add
  val op - = SMLSharp.Int.sub
  val op > = SMLSharp.Int.gt
  val op < = SMLSharp.Int.lt
  val op <= = SMLSharp.Int.lteq
  val op >= = SMLSharp.Int.gteq
in
  structure Array : sig
    type 'a array = 'a array
    type 'a vector = 'a vector
    val maxLen : int
    val array : int * 'a -> 'a array
    val fromList : 'a list -> 'a array
    val tabulate : int * (int -> 'a) -> 'a array
    val length : 'a array -> int
    val sub : 'a array * int -> 'a
    val update : 'a array * int * 'a -> unit
    val foldli : (int * 'a * 'b -> 'b) -> 'b -> 'a array -> 'b
    val foldl : ('a * 'b -> 'b) -> 'b -> 'a array -> 'b
    val foldri : (int * 'a * 'b -> 'b) -> 'b -> 'a array -> 'b
    val foldr : ('a * 'b -> 'b) -> 'b -> 'a array -> 'b
    val appi : (int * 'a -> unit) -> 'a array -> unit
    val app : ('a -> unit) -> 'a array -> unit
    val findi : (int * 'a -> bool) -> 'a array -> (int * 'a) option
    val find : ('a -> bool) -> 'a array -> 'a option
    val exists : ('a -> bool) -> 'a array -> bool
    val all : ('a -> bool) -> 'a array -> bool
    val collate : ('a * 'a -> order) -> 'a array * 'a array -> order
    val vector : 'a array -> 'a vector
    val copy : {src : 'a array, dst : 'a array, di : int} -> unit
    val copyVec : {src : 'a vector, dst : 'a array, di : int} -> unit
    val modifyi : (int * 'a -> 'a) -> 'a array -> unit
    val modify : ('a -> 'a) -> 'a array -> unit
  end =
struct
  type 'a array = 'a array
  type 'a vector = 'a vector

  (* object size occupies 28 bits of 32-bit object header,
   * and the size of the maximum value is 16 bytes.
   * so we take 2^24 for maxLen. *)
  val maxLen = 0x00ffffff

  fun array (len, elem) =
      let
        val buf = SMLSharp.PrimArray.allocArray len
        fun loop i =
            if i >= len then ()
            else (SMLSharp.PrimArray.update (buf, i, elem); loop (i + 1))
      in
        loop 0;
        buf
      end

  fun fromList elems =
      let
        val len = List.length elems
        val buf = SMLSharp.PrimArray.allocArray len
        fun loop (i, nil) = ()
          | loop (i, h::t) =
            (SMLSharp.PrimArray.update (buf, i, h); loop (i + 1, t))
      in
        loop (0, elems);
        buf
      end

  fun tabulate (len, elemFn) =
      let
        val buf = SMLSharp.PrimArray.allocArray len
        fun loop i =
            if i >= len then ()
            else (SMLSharp.PrimArray.update (buf, i, elemFn i); loop (i + 1))
      in
        loop 0;
        buf
      end

  val length = SMLSharp.PrimArray.length
  val sub = SMLSharp.PrimArray.sub
  val update = SMLSharp.PrimArray.update

  fun foldli foldFn z ary =
      let
        val len = SMLSharp.PrimArray.length ary
        fun loop (i, z) =
            if i >= len then z
            else let val x = SMLSharp.PrimArray.sub (ary, i)
                 in loop (i + 1, foldFn (i, x, z))
                 end
      in
        loop (0, z)
      end

  fun foldl foldFn z ary =
      foldli (fn (i,x,z) => foldFn (x,z)) z ary

  fun foldri foldFn z ary =
      let
        val len = SMLSharp.PrimArray.length ary
        fun loop (i, z) =
            if i < 0 then z
            else let val x = SMLSharp.PrimArray.sub (ary, i)
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


  fun findi predicate ary =
      let
        val len = SMLSharp.PrimArray.length ary
        fun loop i =
            if i >= len then NONE
            else let val x = SMLSharp.PrimArray.sub (ary, i)
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

  fun all predicate ary =
      let
        val len = SMLSharp.PrimArray.length ary
        fun loop i =
            if i >= len then true
            else predicate (SMLSharp.PrimArray.sub (ary, i))
                 andalso loop (i + 1)
      in
        loop 0
      end

  fun collate cmpFn (ary1, ary2) =
      let
        val len1 = SMLSharp.PrimArray.length ary1
        val len2 = SMLSharp.PrimArray.length ary2
        fun loop (i, 0, 0) = EQUAL
          | loop (i, 0, _) = LESS
          | loop (i, _, 0) = GREATER
          | loop (i, rest1, rest2) =
            let
              val c1 = SMLSharp.PrimArray.sub (ary1, i)
              val c2 = SMLSharp.PrimArray.sub (ary2, i)
            in
              case cmpFn (c1, c2) of
                EQUAL => loop (i + 1, rest1 - 1, rest2 - 1)
              | order => order
            end
      in
        loop (0, len1, len2)
      end

  fun vector ary =
      let
        val len = SMLSharp.PrimArray.length ary
        val buf = SMLSharp.PrimArray.allocVector len
      in
        SMLSharp.PrimArray.copy_unsafe_array_to_vector (ary, 0, buf, 0, len);
        buf
      end

  fun copy {src, dst, di} =
      let
        val srclen = SMLSharp.PrimArray.length src
        val dstlen = SMLSharp.PrimArray.length dst
      in
        if di < 0 orelse dstlen < di orelse dstlen - di < srclen
        then raise Subscript
        else SMLSharp.PrimArray.copy_unsafe_array_to_array (src, 0, dst, di, srclen)
      end

  fun copyVec {src, dst, di} =
      let
        val srclen = SMLSharp.PrimArray.length_vector src
        val dstlen = SMLSharp.PrimArray.length dst
      in
        if di < 0 orelse dstlen < di orelse dstlen - di < srclen
        then raise Subscript
        else SMLSharp.PrimArray.copy_unsafe_vector_to_array (src, 0, dst, di, srclen)
      end


  fun modifyi mapFn ary =
      let
        val len = SMLSharp.PrimArray.length ary
        fun loop i =
            if i >= len then ()
            else let val x = SMLSharp.PrimArray.sub (ary, i)
                 in SMLSharp.PrimArray.update (ary, i, mapFn (i, x));
                    loop (i + 1)
                 end
      in
        loop 0
      end

  fun modify mapFn ary =
      modifyi (fn (i,x) => mapFn x) ary

end
end
