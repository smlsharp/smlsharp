(**
 * Array related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *
 * @author Atsushi Ohori (refactored from ArrayStructure)
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "ArraySlice.smi"

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
  structure ArraySlice :> sig
    (* same as ARRAY_SLICE *)
    type 'a slice
    val length : 'a slice -> int
    val sub : 'a slice * int -> 'a
    val full : 'a Array.array -> 'a slice
    val slice : 'a Array.array * int * int option -> 'a slice
    val subslice : 'a slice * int * int option -> 'a slice
    val base : 'a slice -> 'a Array.array * int * int
    val vector : 'a slice -> 'a Vector.vector
    val isEmpty : 'a slice -> bool
    val getItem : 'a slice -> ('a * 'a slice) option
    val foldli : (int * 'a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val foldri : (int * 'a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val foldl : ('a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val foldr : ('a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val appi : (int * 'a -> unit) -> 'a slice -> unit
    val app : ('a -> unit) -> 'a slice -> unit
    val findi : (int * 'a -> bool) -> 'a slice -> (int * 'a) option
    val find : ('a -> bool) -> 'a slice -> 'a option
    val exists : ('a -> bool) -> 'a slice -> bool
    val all : ('a -> bool) -> 'a slice -> bool
    val collate : ('a * 'a -> order) -> 'a slice * 'a slice -> order
    val update : 'a slice * int * 'a -> unit
    val copy : {src : 'a slice, dst : 'a Array.array, di : int} -> unit
    val copyVec : {src : 'a VectorSlice.slice, dst : 'a Array.array, di : int}
                  -> unit
    val modifyi : (int * 'a -> 'a) -> 'a slice -> unit
    val modify : ('a -> 'a) -> 'a slice -> unit
  end=
struct
    type 'a slice = 'a Array.array * int * int  (* array * start * length *)
    fun length ((ary, start, length):'a slice) = length

    fun sub ((ary, start, length):'a slice, index) =
        SMLSharp.PrimArray.sub (ary, start + index)

    fun full ary =
        (ary, 0, SMLSharp.PrimArray.length ary) : 'a slice

    fun slice (ary, start, lengthOpt) =
        let
          val length = SMLSharp.PrimArray.length ary
          val _ = if start < 0 orelse length < start
                  then raise Subscript else ()
          val length =
              case lengthOpt of
                NONE => length - start
              | SOME len =>
                if len < 0 orelse length - start < len then raise Subscript
                else len
        in
          (ary, start, length) : 'a slice
        end

    fun subslice ((ary, start, length):'a slice, start2, lengthOpt) =
        let
          val _ = if start2 < 0 orelse length < start2
                  then raise Subscript else ()
          val length =
              case lengthOpt of
                NONE => length - start2
              | SOME len =>
                if len < 0 orelse length - start2 < len then raise Subscript
                else len
        in
          (ary, start + start2, length) : 'a slice
        end

    fun base (x:'a slice) = x

    fun vector ((ary, start, length):'a slice) =
        let
          val buf = SMLSharp.PrimArray.allocVector length
        in
          SMLSharp.PrimArray.copy_unsafe_array_to_vector (ary, start, buf, 0, length);
          buf
        end

    fun isEmpty ((ary, start, length):'a slice) = length = 0

    fun getItem ((ary, start, length):'a slice) =
        if length <= 0 then NONE
        else SOME (SMLSharp.PrimArray.sub (ary, start),
                   (ary, start + 1, length - 1) : 'a slice)

    fun foldli foldFn z ((ary, start, length):'a slice) =
        let
          val max = start + length
          fun loop (i, z) =
              if i >= max then z
              else let val x = SMLSharp.PrimArray.sub (ary, i)
                   in loop (i + 1, foldFn (i - start, x, z))
                   end
        in
          loop (start, z)
        end

    fun foldl foldFn z slice =
        foldli (fn (i,x,z) => foldFn (x,z)) z slice

    fun foldri foldFn z ((ary, start, length):'a slice) =
        let
          fun loop (i, z) =
              if i < start then z
              else let val x = SMLSharp.PrimArray.sub (ary, i)
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

    fun findi predicate ((ary, start, length):'a slice) =
        let
          val max = start + length
          fun loop i =
              if i >= max then NONE
              else let val x = SMLSharp.PrimArray.sub (ary, i)
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

    fun exists predicate ary =
        case find predicate ary of
          SOME _ => true
        | NONE => false

    fun all predicate ((ary, start, length):'a slice) =
        let
          val max = start + length
          fun loop i =
              if i >= max then true
              else predicate (SMLSharp.PrimArray.sub (ary, i))
                   andalso loop (i + 1)
        in
          loop start
        end

    fun collate cmpFn ((ary1, start1, length1):'a slice,
                       (ary2, start2, length2):'a slice) =
        let
          fun loop (i, 0, j, 0) = EQUAL
            | loop (i, 0, j, _) = LESS
            | loop (i, _, j, 0) = GREATER
            | loop (i, rest1, j, rest2) =
              let
                val c1 = SMLSharp.PrimArray.sub (ary1, i)
                val c2 = SMLSharp.PrimArray.sub (ary2, j)
              in
                case cmpFn (c1, c2) of
                  EQUAL => loop (i + 1, rest1 - 1, j + 1, rest2 - 1)
                | order => order
              end
        in
          loop (start1, length1, start2, length2)
        end

    fun update ((ary, start, length):'a slice, index, elem) =
        if index < 0 orelse length <= index
        then raise Subscript
        else SMLSharp.PrimArray.update (ary, start + index, elem)

    fun copy {src = (srcary, srcstart, srclen):'a slice, dst, di} =
        let
          val dstlen = SMLSharp.PrimArray.length dst
        in
          if di < 0 orelse dstlen < di orelse dstlen - di < srclen
          then raise Subscript
          else SMLSharp.PrimArray.copy_unsafe_array_to_array
                 (srcary, srcstart, dst, di, srclen)
        end

    fun copyVec {src, dst, di} =
        let
          val (srcary, srcstart, srclen) = VectorSlice.base src
          val dstlen = SMLSharp.PrimArray.length dst
        in
          if di < 0 orelse dstlen < di orelse dstlen - di < srclen
          then raise Subscript
          else SMLSharp.PrimArray.copy_unsafe_vector_to_array
                 (srcary, srcstart, dst, di, srclen)
        end

    fun modifyi mapFn ((ary, start, length):'a slice) =
        let
          val max = start + length
          fun loop i =
              if i >= max then ()
              else
                let val x = SMLSharp.PrimArray.sub (ary, i)
                in SMLSharp.PrimArray.update (ary, i, mapFn (i - start, x));
                   loop (i + 1)
                end
        in
          loop start
        end

    fun modify mapFn slice =
        modifyi (fn (i,x) => mapFn x) slice

  end (* ArraySlice *)
end (* local *)
