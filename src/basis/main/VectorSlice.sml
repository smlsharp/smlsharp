(**
 * Array related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *
 * @author Atsushi Ohori (refactored from ArrayStructure)
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "VectorSlice.smi"

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
  structure VectorSlice : sig
    (* same as VECTOR_SLICE *)
    type 'a slice
    val length : 'a slice -> int
    val sub : 'a slice * int -> 'a
    val full : 'a Vector.vector -> 'a slice
    val slice : 'a Vector.vector * int * int option -> 'a slice
    val subslice : 'a slice * int * int option -> 'a slice
    val base : 'a slice -> 'a Vector.vector * int * int
    val vector : 'a slice -> 'a Vector.vector
    val isEmpty : 'a slice -> bool
    val getItem : 'a slice -> ('a * 'a slice) option
    val foldli : (int * 'a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val foldl : ('a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val foldri : (int * 'a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val foldr : ('a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val appi : (int * 'a -> unit) -> 'a slice -> unit
    val app : ('a -> unit) -> 'a slice -> unit
    val findi : (int * 'a -> bool) -> 'a slice -> (int * 'a) option
    val find : ('a -> bool) -> 'a slice -> 'a option
    val exists : ('a -> bool) -> 'a slice -> bool
    val all : ('a -> bool) -> 'a slice -> bool
    val collate : ('a * 'a -> order) -> 'a slice * 'a slice -> order
    val concat : 'a slice list -> 'a Vector.vector
    val mapi : (int * 'a -> 'b) -> 'a slice -> 'b Vector.vector
    val map : ('a -> 'b) -> 'a slice -> 'b Vector.vector
  end =
struct
    type 'a slice = 'a Array.vector * int * int  (* array * start * length *)

    fun length ((ary, start, length):'a slice) = length

    fun sub ((ary, start, length):'a slice, index) =
        SMLSharp.PrimArray.sub_vector (ary, start + index)

    fun full ary =
        (ary, 0, SMLSharp.PrimArray.length_vector ary) : 'a slice

    fun slice (ary, start, lengthOpt) =
        let
          val length = SMLSharp.PrimArray.length_vector ary
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
          SMLSharp.PrimArray.copy_unsafe_vector_to_vector (ary, start, buf, 0, length);
          buf
        end

    fun isEmpty ((ary, start, length):'a slice) = length = 0

    fun getItem ((ary, start, length):'a slice) =
        if length <= 0 then NONE
        else SOME (SMLSharp.PrimArray.sub_vector (ary, start),
                   (ary, start + 1, length - 1) : 'a slice)

    fun foldli foldFn z ((ary, start, length):'a slice) =
        let
          val max = start + length
          fun loop (i, z) =
              if i >= max then z
              else let val x = SMLSharp.PrimArray.sub_vector (ary, i)
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
              else let val x = SMLSharp.PrimArray.sub_vector (ary, i)
                   in loop (i - 1, foldFn (i - start, x, z))
                   end
        in
          loop (start + length - 1, z)
        end

    fun foldr foldFn z slice =
        foldri (fn (i,x,z) => foldFn (x,z)) z slice

    fun findi predicate ((ary, start, length):'a slice) =
        let
          val max = start + length
          fun loop i =
              if i >= max then NONE
              else let val x = SMLSharp.PrimArray.sub_vector (ary, i)
                   in if predicate (i - start, x)
                      then SOME (i, x) else loop (i + 1)
                   end
        in
          loop start
        end

    fun appi appFn slice =
        foldli (fn (i,x,()) => appFn (i,x)) () slice

    fun app appFn slice =
        foldli (fn (i,x,()) => appFn x) () slice

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
              else predicate (SMLSharp.PrimArray.sub_vector (ary, i))
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
                val c1 = SMLSharp.PrimArray.sub_vector (ary1, i)
                val c2 = SMLSharp.PrimArray.sub_vector (ary2, j)
              in
                case cmpFn (c1, c2) of
                  EQUAL => loop (i + 1, rest1 - 1, j + 1, rest2 - 1)
                | order => order
              end
        in
          loop (start1, length1, start2, length2)
        end

    fun concat slices =
        let
          fun totalLength (nil, z) = z
            | totalLength (((vec, start, length):'a slice)::t, z) =
              let val next = length + z
              in if next > Array.maxLen then raise Size
                 else totalLength (t, next)
              end
          val len = totalLength (slices, 0)
          val buf = SMLSharp.PrimArray.allocVector len
          fun loop (i, nil) = ()
            | loop (i, (vec, start, len)::t) =
              (SMLSharp.PrimArray.copy_unsafe_vector_to_vector (vec, start, buf, i, len);
               loop (i + len, t))
        in
            loop (0, slices);
            buf
          end

    fun mapi mapFn ((vec, start, length):'a slice) =
          let
            val buf = SMLSharp.PrimArray.allocVector length
            val max = start + length
            fun loop i =
                if i >= max then ()
                else
                  let val x = SMLSharp.PrimArray.sub_vector (vec, i)
                  in SMLSharp.PrimArray.update_vector (buf, i, mapFn (i - start, x));
                     loop (i + 1)
                  end
          in
            loop start;
            buf
          end

    fun map mapFn slice =
        mapi (fn (i,x) => mapFn x) slice

  end (* VectorSlice *)
end (* local *)
