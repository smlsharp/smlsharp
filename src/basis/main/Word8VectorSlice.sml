(**
 * String related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "Word8VectorSlice.smi"

structure Word8VectorSlice :> MONO_VECTOR_SLICE
    where type vector = string
    where type elem = SMLSharp.Word8.word
=
struct
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
    type elem = SMLSharp.Word8.word
    type vector = string
    type slice = vector * int * int  (* array * start * length *)
    fun length ((ary, start, length):slice) = length

    fun sub ((ary, start, length):slice, index) =
        if index < 0 orelse length <= index then raise Subscript
        else SMLSharp.Word8.sub_unsafe (ary, start + index)

    fun full ary =
        (ary, 0, SMLSharp.PrimString.size ary) : slice

    fun slice (ary, start, lengthOpt) =
        let
          val length = SMLSharp.PrimString.size ary
          val _ = if start < 0 orelse length < start
                  then raise Subscript else ()
          val length =
              case lengthOpt of
                NONE => length - start
              | SOME len =>
                if len < 0 orelse length - start < len then raise Subscript
                else len
        in
          (ary, start, length) : slice
        end

    fun subslice ((ary, start, length):slice, start2, lengthOpt) =
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
          (ary, start + start2, length) : slice
        end

    fun base (x:slice) = x

    fun vector ((ary, start, length):slice) =
        let
          val buf = SMLSharp.PrimString.allocVector length
        in
          SMLSharp.PrimString.copy_unsafe (ary, start, buf, 0, length);
          buf
        end

    fun isEmpty ((ary, start, length):slice) = length = 0

    fun getItem ((ary, start, length):slice) =
        if length <= 0 then NONE
        else SOME (SMLSharp.Word8.sub_unsafe (ary, start),
                   (ary, start + 1, length - 1) : slice)

    fun foldli foldFn z ((ary, start, length):slice) =
        let
          val max = start + length
          fun loop (i, z) =
              if i >= max then z
              else let val x = SMLSharp.Word8.sub_unsafe (ary, i)
                   in loop (i + 1, foldFn (i - start, x, z))
                   end
        in
          loop (start, z)
        end

    fun foldl foldFn z slice =
        foldli (fn (i,x,z) => foldFn (x,z)) z slice

    fun foldri foldFn z ((ary, start, length):slice) =
        let
          fun loop (i, z) =
              if i < start then z
              else let val x = SMLSharp.Word8.sub_unsafe (ary, i)
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

    fun findi predicate ((ary, start, length):slice) =
        let
          val max = start + length
          fun loop i =
              if i >= max then NONE
              else let val x = SMLSharp.Word8.sub_unsafe (ary, i)
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

    fun all predicate ((ary, start, length):slice) =
        let
          val max = start + length
          fun loop i =
              if i >= max then true
              else predicate (SMLSharp.Word8.sub_unsafe (ary, i))
                   andalso loop (i + 1)
        in
          loop start
        end

    fun collate cmpFn ((ary1, start1, length1):slice,
                       (ary2, start2, length2):slice) =
        let
          fun loop (i, 0, j, 0) = EQUAL
            | loop (i, 0, j, _) = LESS
            | loop (i, _, j, 0) = GREATER
            | loop (i, rest1, j, rest2) =
              let
                val c1 = SMLSharp.Word8.sub_unsafe (ary1, i)
                val c2 = SMLSharp.Word8.sub_unsafe (ary2, j)
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
            | totalLength (((vec, start, length):slice)::t, z) =
              let val z = length + z
              in if z > Word8Vector.maxLen then raise Size
                 else totalLength (t, z)
              end
          val len = totalLength (slices, 0)
          val buf = SMLSharp.PrimString.allocVector len
          fun loop (i, nil) = ()
            | loop (i, (vec, start, len)::t) =
              (SMLSharp.PrimString.copy_unsafe (vec, start, buf, i, len);
               loop (i + len, t))
        in
            loop (0, slices);
            buf
          end

    fun mapi mapFn ((vec, start, length):slice) =
          let
            val buf = SMLSharp.PrimString.allocVector length
            val max = start + length
            fun loop i =
                if i >= max then ()
                else
                  let val x = SMLSharp.Word8.sub_unsafe (vec, i)
                      val x = mapFn (i - start, x)
                  in SMLSharp.Word8.update_unsafe (buf, i, x);
                     loop (i + 1)
                  end
          in
            loop start;
            buf
          end

    fun map mapFn slice =
        mapi (fn (i,x) => mapFn x) slice

  end
end  (* Word8VectorSlice *)
