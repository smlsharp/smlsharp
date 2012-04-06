(**
 * String related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *
 * @author Atsushi Ohori (refactored from StringStructure)
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "Word8Vector.smi"

structure Word8Vector :> MONO_VECTOR
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
    type vector = string
    type elem = SMLSharp.Word8.word
    (* object size occupies 28 bits of 32-bit object header. *)
    val maxLen = 0x0fffffff

    val length = SMLSharp.PrimString.size

    fun sub (ary, index) =
        if index < 0 orelse SMLSharp.PrimString.size ary <= index
        then raise Subscript
        else SMLSharp.Word8.sub_unsafe (ary, index)

    fun foldli foldFn z ary =
        let
          val len = SMLSharp.PrimString.size ary
          fun loop (i, z) =
              if i >= len then z
              else let val x = SMLSharp.Word8.sub_unsafe (ary, i)
                   in loop (i + 1, foldFn (i, x, z))
                   end
        in
          loop (0, z)
        end

    fun foldl foldFn z ary =
        foldli (fn (i,x,z) => foldFn (x,z)) z ary

    fun foldri foldFn z ary =
        let
          val len = SMLSharp.PrimString.size ary
          fun loop (i, z) =
              if i < 0 then z
              else let val x = SMLSharp.Word8.sub_unsafe (ary, i)
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
          val len = SMLSharp.PrimString.size ary
          fun loop i =
              if i >= len then NONE
              else let val x = SMLSharp.Word8.sub_unsafe (ary, i)
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
          val len = SMLSharp.PrimString.size ary
          fun loop i =
              if i >= len then true
              else predicate (SMLSharp.Word8.sub_unsafe (ary, i))
                   andalso loop (i + 1)
        in
          loop 0
        end

    fun collate cmpFn (ary1, ary2) =
        let
          val len1 = SMLSharp.PrimString.size ary1
          val len2 = SMLSharp.PrimString.size ary2
          fun loop (i, 0, 0) = EQUAL
            | loop (i, 0, _) = LESS
            | loop (i, _, 0) = GREATER
            | loop (i, rest1, rest2) =
              let
                val c1 = SMLSharp.Word8.sub_unsafe (ary1, i)
                val c2 = SMLSharp.Word8.sub_unsafe (ary2, i)
              in
                case cmpFn (c1, c2) of
                  EQUAL => loop (i + 1, rest1 - 1, rest2 - 1)
                | order => order
              end
        in
          loop (0, len1, len2)
        end

    fun fromList elems =
        let
          fun length (nil : elem list, z) = z
            | length (h::t, z) = length (t, z + 1)
          val len = length (elems, 0)
          val buf = SMLSharp.PrimString.allocVector len
          fun fill (i, nil) = ()
            | fill (i, h::t) =
              (SMLSharp.Word8.update_unsafe (buf, i, h); fill (i + 1, t))
        in
          fill (0, elems);
          buf
        end

    fun tabulate (len, elemFn) =
        let
          val buf = SMLSharp.PrimString.allocVector len
          fun fill i =
              if i >= len then ()
              else (SMLSharp.Word8.update_unsafe (buf, i, elemFn i);
                    fill (i + 1))
        in
          fill 0;
          buf
        end

    fun update (vec, index, value) =
        let
          val len = SMLSharp.PrimString.size vec
        in
          if index < 0 orelse len <= index
          then raise Subscript
          else
            let
              val buf = SMLSharp.PrimString.allocVector len
            in
              SMLSharp.PrimString.copy_unsafe (vec, 0, buf, 0, len);
              SMLSharp.Word8.update_unsafe (buf, index, value);
              buf
            end
        end

    fun concat vectors =
        let
          fun totalLength (nil, z) = z
            | totalLength (h::t, z) =
              let val len = SMLSharp.PrimString.size h
                  val z = len + z
              in if z > maxLen then raise Size else totalLength (t, z)
              end
          val len = totalLength (vectors, 0)
          val buf = SMLSharp.PrimString.allocVector len
          fun loop (i, nil) = ()
            | loop (i, h::t) =
              let val len = SMLSharp.PrimString.size h
              in SMLSharp.PrimString.copy_unsafe (h, 0, buf, i, len);
              loop (i + len, t)
              end
        in
          loop (0, vectors);
          buf
        end

    fun mapi mapFn vec =
        let
          val len = SMLSharp.PrimString.size vec
          val buf = SMLSharp.PrimString.allocVector len
          fun loop i =
              if i >= len then ()
              else
                let val x = SMLSharp.Word8.sub_unsafe (vec, i)
                in SMLSharp.Word8.update_unsafe (buf, i, mapFn (i, x));
                loop (i + 1)
                end
        in
          loop 0;
          buf
        end

    fun map mapFn vec =
        mapi (fn (i,x) => mapFn x) vec

  end (* Word8Vector *)
end (* local *)
