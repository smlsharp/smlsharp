(**
 * Substring
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

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
structure String = SMLSharp_Builtin.String
structure Char = SMLSharp_Builtin.Char
structure Word = SMLSharp_Builtin.Word
structure Word8 = SMLSharp_Builtin.Word8

val memcmp = _import "sml_memcmp"
             : __attribute__ ((no_callback, pure))
               (string, int, string, int, int) -> int

structure Substring =
struct

  type char = char
  type string = string
  type substring = string * int * int (* string * start * length *)

  (* object size occupies 26 bits of 32-bit object header. In addition,
   * "string" have sentinel zero character at the end of the char sequence *)
  val maxSize = 0x03fffffe

  fun substring_unsafe ((vec, start, length):substring) =
      let
        val buf = String.alloc_unsafe length
      in
        Array.copy_unsafe (String.castToArray vec, start,
                           String.castToArray buf, 0, length);
        buf
      end

  fun concatWith sep [] = ""
    | concatWith sep [x] = substring_unsafe x
    | concatWith sep slices =
      let
        val sepLen = String.size sep
        fun totalLength (nil : substring list, z) = z
          | totalLength ([(_,_,len)], z) =
            let val z = z + len
            in if z > maxSize then raise Size else z
            end
          | totalLength ((_,_,len)::t, z) =
            let val z = z + sepLen + len
            in if z > maxSize then raise Size else totalLength (t, z)
            end
        val len = totalLength (slices, 0)
        val buf = String.alloc_unsafe len
        fun loop (i, nil : substring list) = ()
          | loop (i, (vec, beg, len)::t) =
            (Array.copy_unsafe (String.castToArray vec, beg,
                                String.castToArray buf, i, len);
             case t of
               nil => ()
             | _::_ =>
               let val i = i + len
               in Array.copy_unsafe (String.castToArray sep, 0,
                                     String.castToArray buf, i, sepLen);
                  loop (i + sepLen, t)
               end)
      in
        loop (0, slices);
        buf
      end

  fun explode ((vec, start, length):substring) =
      let
        fun loop (i, z) =
            if i >= start
            then loop (i - 1, Array.sub_unsafe (String.castToArray vec, i) :: z)
            else z
      in
        loop (start + length - 1, nil)
      end

  fun isPrefix prefix ((vec, start, length):substring) =
      let
        val len = String.size prefix
      in
        len <= length andalso memcmp (prefix, 0, vec, start, len) = 0
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
        if len1 > length then ~1
        else if len1 = length
        then if memcmp (vec1, 0, vec2, start, length) = 0 then start else ~1
        else
          let
            (* Rabin-Karp algorithm *)
            val limit = length - len1 + start
            val base = 0w127
            fun sub (vec, i) =
                Word8.toWord
                  (Char.castToWord8
                     (Array.sub_unsafe (String.castToArray vec, i)))
            fun hash_add (hash, ch) =
                Word.add (Word.mul (hash, base), ch)
            fun hash1_init (i, hash) =
                if i < len1
                then hash1_init (i+1, hash_add (hash, sub (vec1, i)))
                else hash
            fun hash2_init (i, hash) =
                if i < len1
                then hash2_init (i+1, hash_add (hash, sub (vec2, start+i)))
                else hash
            fun baseDel_init (0, z) = z
              | baseDel_init (n, z) = baseDel_init (n - 1, Word.mul (z, base))
            val hash1 = hash1_init (0, 0w0)
            val hash2 = hash2_init (0, 0w0)
            val baseDel = baseDel_init (len1, 0w1)
            fun hash_rot (hash, del, add) =
                Word.sub (Word.add (Word.mul (hash, base), add),
                          Word.mul (del, baseDel))
            fun search (i, hash2) =
                if hash1 = hash2 andalso memcmp (vec1, 0, vec2, i, len1) = 0
                then i
                else if i >= limit then ~1
                else let val del = sub (vec2, i)
                         val add = sub (vec2, i + len1)
                     in search (i + 1, hash_rot (hash2, del, add))
                     end
          in
            search (start, hash2)
          end
      end

  fun isSubstring vec1 slice =
      strstr vec1 slice >= 0

  fun translate transFn ((vec, start, length):substring) =
      let
        fun init (i, totalSize, buf) =
            if i < start + length then
              let val c = Array.sub_unsafe (String.castToArray vec, i)
                  val x = transFn c
                  val n = String.size x
              in if totalSize + n > maxSize then raise Size else ();
                 init (i + 1, totalSize + n, x :: buf)
              end
            else (totalSize, buf)
        val (totalSize, buf) = init (start, 0, nil)
        val dst = String.alloc_unsafe totalSize
        fun concat (i, nil) = dst
          | concat (i, h::t) =
            let val len = String.size h
                val i = i - len
            in Array.copy_unsafe (String.castToArray h, 0,
                                  String.castToArray dst, i, len);
               concat (i, t)
            end
      in
        concat (totalSize, buf)
      end

  fun sub ((vec, start, length):substring, index) =
      if index < 0 orelse length <= index then raise Subscript
      else Array.sub_unsafe (String.castToArray vec, start + index)

  fun base (x:substring) = x

  fun full vec = (vec, 0, String.size vec) : substring

  fun size ((vec, start, length):substring) = length

  fun isEmpty ((vec, start, length):substring) = length = 0

  fun concat nil = ""
    | concat [x] = substring_unsafe x
    | concat slices =
      let
        fun totalLength (nil : substring list, z) = z
          | totalLength ((vec, start, length)::t, z) =
            let val z = length + z
            in if z > maxSize then raise Size else totalLength (t, z)
            end
        val len = totalLength (slices, 0)
        val buf = String.alloc_unsafe len
        fun loop (i, nil : substring list) = ()
          | loop (i, (vec, start, length)::t) =
            (Array.copy_unsafe (String.castToArray vec, start,
                                String.castToArray buf, i, length);
             loop (i + length, t))
      in
        loop (0, slices);
        buf
      end

  fun substring (x as (vec, start, length)) =
      let
        val len = String.size vec
      in
        if start < 0 orelse len < start
           orelse length < 0 orelse len - start < length
        then raise Subscript
        else x : substring
      end

  fun extract (vec, start, SOME length) = substring (vec, start, length)
    | extract (vec, start, NONE) =
      let
        val len = String.size vec
      in
        if start < 0 orelse len < start then raise Subscript
        else (vec, start, len - start)
      end

  fun string ((vec, start, length):substring) =
      let
        val buf = String.alloc_unsafe length
      in
        Array.copy_unsafe (String.castToArray vec, start,
                           String.castToArray buf, 0, length);
        buf
      end

  fun getc ((vec, start, length):substring) =
      if length <= 0 then NONE
      else SOME (Array.sub_unsafe (String.castToArray vec, start),
                 (vec, start + 1, length - 1) : substring)

  fun first ((vec, start, length):substring) =
      if length = 0 then NONE
      else SOME (Array.sub_unsafe (String.castToArray vec, start))

  fun triml size =
      if size < 0 then raise Subscript
      else fn (vec, start, length):substring =>
              if size < length
              then (vec, start + size, length - size)
              else (vec, start + length, 0)

  fun trimr size =
      if size < 0 then raise Subscript
      else fn (vec, start, length):substring =>
              (vec, start, if size < length then length - size else 0)

  fun slice ((vec, start, length):substring, start2, lengthOpt) =
      if start2 < 0 orelse length < start2 then raise Subscript
      else case lengthOpt of
             NONE => (vec, start + start2, length - start2)
           | SOME len =>
             if len < 0 orelse length - start2 < len then raise Subscript
             else (vec, start + start2, len)

  fun collate cmpFn ((vec1, start1, length1):substring,
                     (vec2, start2, length2):substring) =
      let
        fun loop (i, 0, j, 0) = General.EQUAL
          | loop (i, 0, j, _) = General.LESS
          | loop (i, _, j, 0) = General.GREATER
          | loop (i, rest1, j, rest2) =
            let
              val c1 = Array.sub_unsafe (String.castToArray vec1, i)
              val c2 = Array.sub_unsafe (String.castToArray vec2, j)
            in
              case cmpFn (c1, c2) of
                General.EQUAL => loop (i + 1, rest1 - 1, j + 1, rest2 - 1)
              | order => order
            end
      in
        loop (start1, length1, start2, length2)
      end

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

  fun splitl whileFn ((vec, start, length):substring) =
      let
        fun loop i =
            if i < length
               andalso
               whileFn (Array.sub_unsafe (String.castToArray vec, start + i))
            then loop (i + 1)
            else ((vec, start, i), (vec, start + i, length - i))
      in
        loop 0
      end

  fun splitr whileFn ((vec, start, len):substring) =
      let
        fun loop i =
            if i > 0
               andalso
               whileFn (Array.sub_unsafe
                          (String.castToArray vec, start + i - 1))
            then loop (i - 1)
            else ((vec, start, i), (vec, start + i, len - i))
      in
        loop len
      end

  fun splitAt ((vec, start, length):substring, index) =
      if index < 0 orelse length < index then raise Subscript
      else ((vec, start, index), (vec, start + index, length - index))

  fun dropl whileFn ((vec, start, length):substring) =
      let
        fun loop (i, length) =
            if length > 0
               andalso whileFn (Array.sub_unsafe (String.castToArray vec, i))
            then loop (i + 1, length - 1)
            else (vec, i, length)
      in
        loop (start, length)
      end

  fun dropr whileFn ((vec, start, length):substring) =
      let
        fun loop length =
            if length > 0
               andalso
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
            if i < length
               andalso
               whileFn (Array.sub_unsafe (String.castToArray vec, start + i))
            then loop (i + 1)
            else (vec, start, i)
      in
        loop 0
      end

  fun taker whileFn ((vec, start, length):substring) =
      let
        fun loop len =
            if len < length
               andalso
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
      if (String.identityEqual (vec1, vec2)
          orelse (let val len1 = String.size vec1
                      val len2 = String.size vec2
                  in len1 = len2 andalso memcmp (vec1, 0, vec2, 0, len1) = 0
                  end))
         andalso start1 <= start2 + length2
      then (vec1, start1, start2 + length2 - start1)
      else raise General.Span

  fun rev (nil, r) = r : substring list
    | rev (h::t, r) = rev (t, h::r)

  fun tokens isDelimiter ((vec, start, length):substring) =
      let
        fun add (b, e, z) =
            if b = e then z else (vec, b, e - b) :: z
        fun loop (beg, i, z) =
            if i >= start + length then rev (add (beg, i, z), nil)
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
            if i >= start + length then rev (add (beg, i, z), nil)
            else if isDelimiter (Array.sub_unsafe (String.castToArray vec, i))
            then loop (i + 1, i + 1, add (beg, i, z))
            else loop (beg, i + 1, z)
      in
        loop (start, start, nil)
      end

  fun foldli foldFn (z : 'b) ((vec, start, length):substring) =
      let
        fun loop (i, z : 'b) =
            if i >= start + length then z
            else let val x = Array.sub_unsafe (String.castToArray vec, i)
                 in loop (i + 1, foldFn (i - start, x, z))
                 end
      in
        loop (start, z)
      end

  fun foldl foldFn z slice =
      foldli (fn (i,x,z) => foldFn (x,z)) z slice

  fun foldri foldFn (z : 'b) ((vec, start, length):substring) =
      let
        fun loop (i, z : 'b) =
            if i < start then z
            else let val x = Array.sub_unsafe (String.castToArray vec, i)
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

end
