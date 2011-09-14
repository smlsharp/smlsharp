(**
 * Array related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "ArrayStructures.smi"

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

structure ArrayStructures :> sig

  structure Vector : sig
    (* same as VECTOR signature except that vector is opaque. *)
    eqtype 'a vector
    val maxLen : int
    val fromList : 'a list -> 'a vector
    val tabulate : int * (int -> 'a) -> 'a vector
    val length : 'a vector -> int
    val sub : 'a vector * int -> 'a
    val update : 'a vector * int * 'a -> 'a vector
    val concat : 'a vector list -> 'a vector
    val appi : (int * 'a -> unit) -> 'a vector -> unit
    val app : ('a -> unit) -> 'a vector -> unit
    val mapi : (int * 'a -> 'b) -> 'a vector -> 'b vector
    val map : ('a -> 'b) -> 'a vector -> 'b vector
    val foldli : (int * 'a * 'b -> 'b) -> 'b -> 'a vector -> 'b
    val foldri : (int * 'a * 'b -> 'b) -> 'b -> 'a vector -> 'b
    val foldl : ('a * 'b -> 'b) -> 'b -> 'a vector -> 'b
    val foldr : ('a * 'b -> 'b) -> 'b -> 'a vector -> 'b
    val findi : (int * 'a -> bool) -> 'a vector -> (int * 'a) option
    val find : ('a -> bool) -> 'a vector -> 'a option
    val exists : ('a -> bool) -> 'a vector -> bool
    val all : ('a -> bool) -> 'a vector -> bool
    val collate : ('a * 'a -> order) -> 'a vector * 'a vector -> order
  end

  structure Array : sig
    (* same as ARRAY signature except that array type is opaque. *)
    eqtype 'a array
    type 'a vector = 'a Vector.vector
    val maxLen : int
    val array : int * 'a -> 'a array
    val fromList : 'a list -> 'a array
    val tabulate : int * (int -> 'a) -> 'a array
    val length : 'a array -> int
    val sub : 'a array * int -> 'a
    val update : 'a array * int * 'a -> unit
    val vector : 'a array -> 'a vector
    val copy : {src : 'a array, dst : 'a array, di : int} -> unit
    val copyVec : {src : 'a vector, dst : 'a array, di : int} -> unit
    val appi : (int * 'a -> unit) -> 'a array -> unit
    val app : ('a -> unit) -> 'a array -> unit
    val modifyi : (int * 'a -> 'a) -> 'a array -> unit
    val modify : ('a -> 'a) -> 'a array -> unit
    val foldli : (int * 'a * 'b -> 'b) -> 'b -> 'a array -> 'b
    val foldri : (int * 'a * 'b -> 'b) -> 'b -> 'a array -> 'b
    val foldl : ('a * 'b -> 'b) -> 'b -> 'a array -> 'b
    val foldr : ('a * 'b -> 'b) -> 'b -> 'a array -> 'b
    val findi : (int * 'a -> bool) -> 'a array -> (int * 'a) option
    val find : ('a -> bool) -> 'a array -> 'a option
    val exists : ('a -> bool) -> 'a array -> bool
    val all : ('a -> bool) -> 'a array -> bool
    val collate : ('a * 'a -> order) -> 'a array * 'a array -> order
  end
  where type 'a array = 'a SMLSharp.PrimArray.array

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
    val concat : 'a slice list -> 'a Vector.vector
    val isEmpty : 'a slice -> bool
    val getItem : 'a slice -> ('a * 'a slice) option
    val appi : (int * 'a -> unit) -> 'a slice -> unit
    val app : ('a -> unit) -> 'a slice -> unit
    val mapi : (int * 'a -> 'b) -> 'a slice -> 'b Vector.vector
    val map : ('a -> 'b) -> 'a slice -> 'b Vector.vector
    val foldli : (int * 'a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val foldri : (int * 'a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val foldl : ('a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val foldr : ('a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val findi : (int * 'a -> bool) -> 'a slice -> (int * 'a) option
    val find : ('a -> bool) -> 'a slice -> 'a option
    val exists : ('a -> bool) -> 'a slice -> bool
    val all : ('a -> bool) -> 'a slice -> bool
    val collate : ('a * 'a -> order) -> 'a slice * 'a slice -> order
  end

  structure ArraySlice : sig
    (* same as ARRAY_SLICE *)
    type 'a slice
    val length : 'a slice -> int
    val sub : 'a slice * int -> 'a
    val update : 'a slice * int * 'a -> unit
    val full : 'a Array.array -> 'a slice
    val slice : 'a Array.array * int * int option -> 'a slice
    val subslice : 'a slice * int * int option -> 'a slice
    val base : 'a slice -> 'a Array.array * int * int
    val vector : 'a slice -> 'a Vector.vector
    val copy : {src : 'a slice, dst : 'a Array.array, di : int} -> unit
    val copyVec : {src : 'a VectorSlice.slice, dst : 'a Array.array, di : int}
                  -> unit
    val isEmpty : 'a slice -> bool
    val getItem : 'a slice -> ('a * 'a slice) option
    val appi : (int * 'a -> unit) -> 'a slice -> unit
    val app : ('a -> unit) -> 'a slice -> unit
    val modifyi : (int * 'a -> 'a) -> 'a slice -> unit
    val modify : ('a -> 'a) -> 'a slice -> unit
    val foldli : (int * 'a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val foldri : (int * 'a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val foldl : ('a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val foldr : ('a * 'b -> 'b) -> 'b -> 'a slice -> 'b
    val findi : (int * 'a -> bool) -> 'a slice -> (int * 'a) option
    val find : ('a -> bool) -> 'a slice -> 'a option
    val exists : ('a -> bool) -> 'a slice -> bool
    val all : ('a -> bool) -> 'a slice -> bool
    val collate : ('a * 'a -> order) -> 'a slice * 'a slice -> order
  end

end
=
struct

  structure ArrayBase =
  struct

    type 'a array = 'a SMLSharp.PrimArray.array
    type 'a vector = 'a array

    (* object size occupies 28 bits of 32-bit object header,
     * and the size of the maximum value is 16 bytes.
     * so we take 2^24 for maxLen. *)
    val maxLen = 0x00ffffff

    (* for Array.array *)
    fun fill (buf, len, elem) =
        let
          fun loop i =
              if i >= len then ()
              else (SMLSharp.PrimArray.update (buf, i, elem); loop (i + 1))
        in
          loop 0;
          buf
        end

    (* for fromList *)
    fun fillWithList (buf, elems) =
        let
          fun loop (i, nil) = ()
            | loop (i, h::t) =
              (SMLSharp.PrimArray.update (buf, i, h); loop (i + 1, t))
        in
          loop (0, elems);
          buf
        end

    (* for tabulate *)
    fun fillWithFn (buf, len, elemFn) =
        let
          fun loop i =
              if i >= len then ()
              else (SMLSharp.PrimArray.update (buf, i, elemFn i); loop (i + 1))
        in
          loop 0;
          buf
        end

    val length = SMLSharp.PrimArray.length
    val sub = SMLSharp.PrimArray.sub

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

    fun appi appFn ary =
        foldli (fn (i,x,()) => appFn (i,x)) () ary

    fun app appFn ary =
        foldli (fn (i,x,()) => appFn x) () ary

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

  end (* ArrayBase *)

  structure Vector =
  struct
    open ArrayBase

    fun fromList elems =
        let
          val len = List.length elems
          val buf = SMLSharp.PrimArray.allocVector len
        in
          fillWithList (buf, elems)
        end

    fun tabulate (size, elemFn) =
        let
          val buf = SMLSharp.PrimArray.allocVector size
        in
          fillWithFn (buf, size, elemFn)
        end

    fun update (vec, index, value) =
        let
          val len = SMLSharp.PrimArray.length vec
        in
          if index < 0 orelse len <= index
          then raise Subscript
          else
            let
              val buf = SMLSharp.PrimArray.allocVector len
            in
              SMLSharp.PrimArray.copy_unsafe (vec, 0, buf, 0, len);
              SMLSharp.PrimArray.update (buf, index, value);
              buf
            end
        end

    fun concat vectors =
        let
          fun totalLength (nil, z) = z
            | totalLength (h::t, z) =
              let val len = SMLSharp.PrimArray.length h
                  val z = len + z
              in if z > maxLen then raise Size else totalLength (t, z)
              end
          val len = totalLength (vectors, 0)
          val buf = SMLSharp.PrimArray.allocVector len
          fun loop (i, nil) = ()
            | loop (i, h::t) =
              let val len = SMLSharp.PrimArray.length h
              in SMLSharp.PrimArray.copy_unsafe (h, 0, buf, i, len);
              loop (i + len, t)
              end
        in
          loop (0, vectors);
          buf
        end

    fun mapi mapFn vec =
        let
          val len = SMLSharp.PrimArray.length vec
          val buf = SMLSharp.PrimArray.allocVector len
          fun loop i =
              if i >= len then ()
              else let val x = SMLSharp.PrimArray.sub (vec, i)
                   in SMLSharp.PrimArray.update (buf, i, mapFn (i, x));
                      loop (i + 1)
                   end
        in
          loop 0;
          buf
        end

    fun map mapFn vec =
        mapi (fn (i,x) => mapFn x) vec

  end (* Vector *)

  structure Array =
  struct
    open ArrayBase

    fun array (len, elem) =
        let
          val buf = SMLSharp.PrimArray.allocArray len
        in
          fill (buf, len, elem)
        end

    fun fromList elems =
        let
          val len = List.length elems
          val buf = SMLSharp.PrimArray.allocArray len
        in
          fillWithList (buf, elems)
        end

    fun tabulate (len, elemFn) =
        let
          val buf = SMLSharp.PrimArray.allocArray len
        in
          fillWithFn (buf, len, elemFn)
        end

    val update = SMLSharp.PrimArray.update

    fun vector ary =
        let
          val len = SMLSharp.PrimArray.length ary
          val buf = SMLSharp.PrimArray.allocVector len
        in
          SMLSharp.PrimArray.copy_unsafe (ary, 0, buf, 0, len);
          buf
        end

    fun copy {src, dst, di} =
        let
          val srclen = SMLSharp.PrimArray.length src
          val dstlen = SMLSharp.PrimArray.length dst
        in
          if di < 0 orelse dstlen < di orelse dstlen - di < srclen
          then raise Subscript
          else SMLSharp.PrimArray.copy_unsafe (src, 0, dst, di, srclen)
        end

    val copyVec = copy

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

  end (* Array *)

  structure ArraySliceBase =
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
          SMLSharp.PrimArray.copy_unsafe (ary, start, buf, 0, length);
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

    fun appi appFn slice =
        foldli (fn (i,x,()) => appFn (i,x)) () slice

    fun app appFn slice =
        foldli (fn (i,x,()) => appFn x) () slice

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

  end (* ArraySliceBase *)

  structure VectorSlice =
  struct
    open ArraySliceBase

    fun concat slices =
        let
          fun totalLength (nil, z) = z
            | totalLength (((vec, start, length):'a slice)::t, z) =
              let val next = length + z
              in if next > ArrayBase.maxLen then raise Size
                 else totalLength (t, next)
              end
          val len = totalLength (slices, 0)
          val buf = SMLSharp.PrimArray.allocVector len
          fun loop (i, nil) = ()
            | loop (i, (vec, start, len)::t) =
              (SMLSharp.PrimArray.copy_unsafe (vec, start, buf, i, len);
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
                  let val x = SMLSharp.PrimArray.sub (vec, i)
                  in SMLSharp.PrimArray.update (buf, i, mapFn (i - start, x));
                     loop (i + 1)
                  end
          in
            loop start;
            buf
          end

    fun map mapFn slice =
        mapi (fn (i,x) => mapFn x) slice

  end (* VectorSlice *)

  structure ArraySlice =
  struct
    open ArraySliceBase

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
          else SMLSharp.PrimArray.copy_unsafe
                 (srcary, srcstart, dst, di, srclen)
        end

    val copyVec = copy

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

end (* ArrayStructures *)

in

open ArrayStructures

type 'a array = 'a Array.array
type 'a vector = 'a Vector.vector

end (* local *)
