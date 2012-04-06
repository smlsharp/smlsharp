(**
 * String related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "Substring.smi"

structure Substring :> SUBSTRING
    where type string = string
    where type char = char
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
  infix 6 ++ --
  val op ++ = SMLSharp.Word.add
  val op -- = SMLSharp.Word.sub
  fun toWord c = SMLSharp.Word.fromInt (SMLSharp.Char.ord c)
in

  type char = char
  type string = string
  type substring = string * int * int

  val concatWith = StringBase.concatWith
  val explode = StringBase.explode
  val isPrefix = StringBase.isPrefix
  val isSubstring = StringBase.isSubstring
  val isSuffix = StringBase.isSuffix
  val translate = StringBase.translate

  fun sub ((ary, start, length):substring, index) =
      if index < 0 orelse length <= index then raise Subscript
      else SMLSharp.PrimString.sub_unsafe (ary, start + index)

  fun base (x:substring) = x

  fun full ary =
      (ary, 0, SMLSharp.PrimString.size ary) : substring

  fun size ((ary, start, length):substring) = length

  fun isEmpty ((ary, start, length):substring) = length = 0

  fun concat slices =
      let
        fun totalLength (nil, z) = z
          | totalLength (((vec, start, length):substring)::t, z) =
            let val z = length + z
            in if z > StringBase.maxLen then raise Size
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

  fun extract (ary, start, lengthOpt) =
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
        (ary, start, length) : substring
      end

  fun substring (str, start, len) = extract (str, start, SOME len)
  fun string ((ary, start, length):substring) =
      let
        val buf = SMLSharp.PrimString.allocVector length
      in
        SMLSharp.PrimString.copy_unsafe (ary, start, buf, 0, length);
        buf
      end

  fun getc ((ary, start, length):substring) =
      if length <= 0 then NONE
      else SOME (SMLSharp.PrimString.sub_unsafe (ary, start),
                 (ary, start + 1, length - 1) : substring)

  fun first ((str, start, length):substring) =
      if length = 0 then NONE
      else SOME (SMLSharp.PrimString.sub_unsafe (str, start))

  fun triml size =
      if size < 0 then raise Subscript
      else fn (str, start, length):substring =>
              if size < length
              then (str, start + size, length - size) : substring
              else (str, start + length, 0) : substring

  fun trimr size =
      if size < 0 then raise Subscript
      else fn (str, start, length):substring =>
              (str, start, if size < length then length - size else 0) : substring

  fun slice ((ary, start, length):substring, start2, lengthOpt) =
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
        (ary, start + start2, length) : substring
      end

  fun collate cmpFn ((ary1, start1, length1):substring,
                     (ary2, start2, length2):substring) =
      let
        fun loop (i, 0, j, 0) = EQUAL
          | loop (i, 0, j, _) = LESS
          | loop (i, _, j, 0) = GREATER
          | loop (i, rest1, j, rest2) =
            let
              val c1 = SMLSharp.PrimString.sub_unsafe (ary1, i)
              val c2 = SMLSharp.PrimString.sub_unsafe (ary2, j)
            in
              case cmpFn (c1, c2) of
                EQUAL => loop (i + 1, rest1 - 1, j + 1, rest2 - 1)
              | order => order
            end
      in
        loop (start1, length1, start2, length2)
      end

  fun compare x =
      collate Char.compare x

  fun splitl whileFn ((str, start, len):substring) =
      let
        fun loop i =
            if i < len
               andalso whileFn (SMLSharp.PrimString.sub_unsafe
                                  (str, start + i))
            then loop (i + 1)
            else ((str, start, i) : substring, (str, start + i, len - i) : substring)
      in
        loop 0
      end

  fun splitr whileFn ((str, start, len):substring) =
      let
        fun loop i =
            if i > 0
               andalso whileFn (SMLSharp.PrimString.sub_unsafe
                                  (str, start + i - 1))
            then loop (i - 1)
            else ((str, start, i) : substring, (str, start + i, len - i) : substring)
      in
        loop len
      end

  fun splitAt ((str, start, length):substring, index) =
      if index < 0 orelse length < index then raise Subscript
      else ((str, start, index) : substring, (str, index, length - index) : substring)

  fun dropl whileFn ((str, start, length):substring) =
      let
        fun loop (start, length) =
            if length > 0
               andalso whileFn (SMLSharp.PrimString.sub_unsafe (str, start))
            then loop (start + 1, length - 1)
            else (str, start, length) : substring
      in
        loop (start, length)
      end

  fun dropr whileFn ((str, start, length):substring) =
      let
        fun loop length =
            if length > 0
               andalso whileFn (SMLSharp.PrimString.sub_unsafe
                                  (str, start + length - 1))
            then loop (length - 1)
            else (str, start, length) : substring
      in
        loop length
      end

  fun takel whileFn ((str, start, length):substring) =
      let
        fun loop i =
            if i < length
               andalso whileFn (SMLSharp.PrimString.sub_unsafe
                                  (str, start + i))
            then loop (i + 1)
            else (str, start, i) : substring
      in
        loop 0
      end

  fun taker whileFn ((str, start, length):substring) =
      let
        fun loop i =
            if i < length
               andalso whileFn (SMLSharp.PrimString.sub_unsafe
                                  (str, start + i))
            then loop (i + 1)
            else (str, start + length - i, i) : substring
      in
        loop 0
      end

  fun position str1 (arg as (substring as (str2, start, len2):substring)) =
      case StringBase.substringIndex str1 substring of
        NONE => (arg, (str2, start + len2, len2):substring)
      | SOME index =>
        let val prefixLen = index - start
        in ((str2, start, prefixLen) : substring,
            (str2, index, len2 - prefixLen) : substring)
        end

  fun span ((str1, start1, len1):substring, (str2, start2, len2):substring) =
      if String.compare (str1, str2) = EQUAL
         andalso start1 <= start2 + len2
      then (str1, start1, start2 + len2 - start1) : substring
      else raise General.Span


  fun tokens isDelimiter ((str, beg, len):substring) =
      let
        val max = beg + len
        fun add (b, e, z) =
            if b = e then z else ((str, b, e - b):substring) :: z
        fun loop (beg, i, z) =
            if i >= max then rev (add (beg, i, z))
            else if isDelimiter (SMLSharp.PrimString.sub_unsafe (str, i))
            then loop (i + 1, i + 1, add (beg, i, z))
            else loop (beg, i + 1, z)
      in
        loop (beg, beg, nil)
      end

  fun fields isDelimiter ((str, beg, len):substring) =
      let
        val max = beg + len
        fun add (b, e, z) = ((str, b, e - b):substring) :: z
        fun loop (beg, i, z) =
            if i >= max then rev (add (beg, i, z))
            else if isDelimiter (SMLSharp.PrimString.sub_unsafe (str, i))
            then loop (i + 1, i + 1, add (beg, i, z))
            else loop (beg, i + 1, z)
      in
        loop (beg, beg, nil)
      end

    fun foldli foldFn z ((ary, start, length):substring) =
        let
          val max = start + length
          fun loop (i, z) =
              if i >= max then z
              else let val x = SMLSharp.PrimString.sub_unsafe (ary, i)
                   in loop (i + 1, foldFn (i - start, x, z))
                   end
        in
          loop (start, z)
        end

    fun foldl foldFn z slice =
        foldli (fn (i,x,z) => foldFn (x,z)) z slice

    fun foldri foldFn z ((ary, start, length):substring) =
        let
          fun loop (i, z) =
              if i < start then z
              else let val x = SMLSharp.PrimString.sub_unsafe (ary, i)
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
end (* Substring *)

type substring = Substring.substring
