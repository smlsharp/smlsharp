(**
 * Substring
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright (C) 2021 SML# Development Team.
 *)

structure Seq =
struct
  type 'a seq = string
  type 'a elem = char
  val castToArray = SMLSharp_Builtin.String.castToArray
  val length = SMLSharp_Builtin.String.size
  val alloc = SMLSharp_Builtin.String.alloc
  val alloc_unsafe = SMLSharp_Builtin.String.alloc_unsafe
  type 'a vector = string
  val castVectorToArray = SMLSharp_Builtin.String.castToArray
  val allocVector = SMLSharp_Builtin.String.alloc
  val allocVector_unsafe = SMLSharp_Builtin.String.alloc_unsafe
  fun emptyVector () = ""
  structure VectorSlice = struct fun base x = x end
end

_use "./Slice_common.sml"

infix 7 * / div mod
infix 6 + - ^
infixr 5 ::
infix 4 = <> > >= < <=
val op + = SMLSharp_Builtin.Int32.add_unsafe
val op - = SMLSharp_Builtin.Int32.sub_unsafe
val op < = SMLSharp_Builtin.Int32.lt
val op <= = SMLSharp_Builtin.Int32.lteq
val op >= = SMLSharp_Builtin.Int32.gteq
structure Array = SMLSharp_Builtin.Array
structure String = SMLSharp_Builtin.String
structure Word32 = SMLSharp_Builtin.Word32
structure Word8 = SMLSharp_Builtin.Word8
structure Char = SMLSharp_Builtin.Char

structure Substring =
struct
  open Slice_common
  type char = char
  type string = string
  type substring = unit slice
  val size = length
  val string = vector
  val substring = subsequence
  val extract = slice
  val slice = subslice
  val getc = getItem

  val memcmp = _import "sml_memcmp"
               : __attribute__ ((pure,fast))
                               (string, int, string, int, int) -> int

  fun isPrefix prefix ((vec, start, length):substring) =
      let
        val len = String.size prefix
      in
        len <= length
        andalso memcmp (prefix, 0, vec, start, len) = 0
      end

  fun isSuffix suffix ((vec, start, length):substring) =
      let
        val len = String.size suffix
      in
        len <= length
        andalso memcmp (suffix, 0, vec, start + length - len, len) = 0
      end

  fun strstr vec1 ((vec2, start, length):substring) =
      let
        val len1 = String.size vec1
      in
        if length < len1 then ~1
        else if len1 = length
        then if memcmp (vec1, 0, vec2, start, length) = 0 then start else ~1
        else
          let
            (* Rabin-Karp algorithm *)
            val prime = 0w127
            fun ord c =
                Word8.toWord32 (Char.castToWord8 c)
            fun sub (vec, i) =
                ord (Array.sub_unsafe (String.castToArray vec, i))
            fun hash_add (hash, ch) =
                Word32.add (Word32.mul (hash, prime), ch)
            fun hash1 (i, hash) =
                if i < len1
                then hash1 (i + 1, hash_add (hash, sub (vec1, i)))
                else hash
            val hash1 = hash1 (0, 0w0)
            fun hash2 (i, hash) =
                if i < len1
                then hash2 (i + 1, hash_add (hash, sub (vec2, start + i)))
                else hash
            val hash2 = hash2 (0, 0w0)
            fun hashDel (0, z) = z
              | hashDel (n, z) = hashDel (n - 1, Word32.mul (z, prime))
            val hashDel = hashDel (len1, 0w1)
            fun rotate {hash, del, add} =
                Word32.sub (Word32.add (Word32.mul (hash, prime), add),
                            Word32.mul (del, hashDel))
            val limit = length - len1 + start
            fun search (i, hash2) =
                if hash1 = hash2 andalso memcmp (vec1, 0, vec2, i, len1) = 0
                then i
                else if limit <= i then ~1
                else search (i + 1, rotate {hash = hash2, del = sub (vec2, i),
                                            add = sub (vec2, i + len1)})
          in
            search (start, hash2)
          end
      end

  fun isSubstring vec1 slice =
      strstr vec1 slice >= 0

  fun first ((vec, start, length):substring) =
      if length <= 0 then NONE
      else SOME (Array.sub_unsafe (String.castToArray vec, start))

  fun triml size ((vec, start, length):substring) =
      if size < 0 then raise Subscript
      else if size < length
      then (vec, start + size, length - size)
      else (vec, start + length, 0)

  fun trimr size ((vec, start, length):substring) =
      if size < 0 then raise Subscript
      else (vec, start, if size < length then length - size else 0)

  fun splitl whileFn ((vec, start, length):substring) =
      let
        fun loop i =
            if i < length andalso
               whileFn (Array.sub_unsafe (String.castToArray vec, start + i))
            then loop (i + 1)
            else ((vec, start, i), (vec, start + i, length - i))
      in
        loop 0
      end

  fun splitr whileFn ((vec, start, length):substring) =
      let
        fun loop i =
            if 0 < i andalso
               whileFn (Array.sub_unsafe
                          (String.castToArray vec, start + i - 1))
            then loop (i - 1)
            else ((vec, start, i), (vec, start + i, length - i))
      in
        loop length
      end

  fun splitAt ((vec, start, length):substring, index) =
      if index < 0 orelse length < index then raise Subscript
      else ((vec, start, index), (vec, start + index, length - index))

  fun dropl whileFn ((vec, start, length):substring) =
      let
        fun loop (i, length) =
            if 0 < length andalso
               whileFn (Array.sub_unsafe (String.castToArray vec, i))
            then loop (i + 1, length - 1)
            else (vec, i, length)
      in
        loop (start, length)
      end

  fun dropr whileFn ((vec, start, length):substring) =
      let
        fun loop length =
            if 0 < length andalso
               whileFn (Array.sub_unsafe
                          (String.castToArray vec, start + length - 1))
            then loop (length - 1)
            else (vec, start, length)
      in
        loop length
      end

  fun takel whileFn ((vec, start, length):substring) =
      let
        fun loop i =
            if i < length andalso
               whileFn (Array.sub_unsafe (String.castToArray vec, start + i))
            then loop (i + 1)
            else (vec, start, i)
      in
        loop 0
      end

  fun taker whileFn ((vec, start, length):substring) =
      let
        fun loop len =
            if len < length andalso
               whileFn (Array.sub_unsafe
                          (String.castToArray vec, start + length - len - 1))
            then loop (len + 1)
            else (vec, start + length - len, len)
      in
        loop 0
      end

  fun position vec1 (slice as (vec2, start, length):substring) =
      let
        val i = strstr vec1 slice
      in
        if i < 0
        then (slice, (vec2, start + length, 0))
        else let val len1 = i - start
             in ((vec2, start, len1), (vec2, i, length - len1))
             end
      end

  fun span ((vec1, start1, length1):substring,
            (vec2, start2, length2):substring) =
      if vec1 = vec2 andalso start1 <= start2 + length2
      then (vec1, start1, start2 + length2 - start1)
      else raise General.Span

  fun compare ((vec1, start1, length1):substring,
               (vec2, start2, length2):substring) =
      let
        val len = if length1 < length2 then length1 else length2
      in
        case memcmp (vec1, start1, vec2, start2, len) of
          0 => if length1 = length2 then General.EQUAL
               else if length1 < length2 then General.LESS
               else General.GREATER
        | n => if n < 0 then General.LESS else General.GREATER
      end

  fun rev (nil, r) = r : substring list
    | rev (h::t, r) = rev (t, h::r)

  fun tokens isDelimiter ((vec, start, length):substring) =
      let
        fun add (b, e, z) =
            if b = e then z else (vec, b, e - b) :: z
        fun loop (beg, i, z) =
            if start + length <= i then rev (add (beg, i, z), nil)
            else if isDelimiter (Array.sub_unsafe (String.castToArray vec, i))
            then loop (i + 1, i + 1, add (beg, i, z))
            else loop (beg, i + 1, z)
      in
        loop (start, start, nil)
      end

  fun fields isDelimiter ((vec, start, length):substring) =
      let
        fun add (b, e, z) = (vec, b, e - b) :: z
        fun loop (beg, i, z) =
            if start + length <= i then rev (add (beg, i, z), nil)
            else if isDelimiter (Array.sub_unsafe (String.castToArray vec, i))
            then loop (i + 1, i + 1, add (beg, i, z))
            else loop (beg, i + 1, z)
      in
        loop (start, start, nil)
      end

end
