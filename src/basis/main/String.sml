(**
 * String
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infix 7 * / div mod
infix 6 + -
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

val memcmp = _import "sml_memcmp"
             : __attribute__ ((no_callback, pure))
               (string, int, string, int, int) -> int

structure String =
struct

  type string = string
  type char = char

  (* object size occupies 26 bits of 32-bit object header. In addition,
   * "string" have sentinel zero character at the end of the char sequence *)
  val maxSize = 0x03fffffe

  val sub = String.sub
  val size = String.size
  val map = CharVector.map
  val concat = CharVector.concat
  val implode = CharVector.fromList
  val collate = CharVector.collate

  fun substring_unsafe (vec, start, length) =
      let
        val buf = String.alloc_unsafe length
      in
        Array.copy_unsafe (String.castToArray vec, start,
                           String.castToArray buf, 0, length);
        buf
      end

  fun substring (vec, start, length) =
      let
        val len = String.size vec
        val _ = if start < 0 orelse len < start orelse len - start < length
                then raise Subscript else ()
      in
        substring_unsafe (vec, start, length)
      end

  fun extract (vec, start, SOME length) = substring (vec, start, length)
    | extract (vec, start, NONE) =
      let
        val len = String.size vec
        val _ = if start < 0 orelse len < start then raise Subscript else ()
        val len = len - start
      in
        substring_unsafe (vec, start, len)
      end

  fun op ^ (vec1, vec2) =
     let
       val len1 = String.size vec1
       val len2 = String.size vec2
       val buf = String.alloc (len1 + len2)
     in
       Array.copy_unsafe (String.castToArray vec1, 0,
                          String.castToArray buf, 0, len1);
       Array.copy_unsafe (String.castToArray vec2, 0,
                          String.castToArray buf, len1, len2);
       buf
     end

  fun concatWith sep nil = ""
    | concatWith sep [x] = x
    | concatWith sep vectors =
      let
        val sepLen = String.size sep
        fun totalLength (nil, z) = z
          | totalLength ([vec], z) =
            let val z = z + String.size vec
            in if z > maxSize then raise Size else z
            end
          | totalLength (h::t, z) =
            let val z = z + sepLen + String.size h
            in if z > maxSize then raise Size else totalLength (t, z)
            end
        val len = totalLength (vectors, 0)
        val buf = String.alloc_unsafe len
        fun loop (i, nil) = ()
          | loop (i, h::t) =
            let
              val len = String.size h
            in
              Array.copy_unsafe (String.castToArray h, 0,
                                 String.castToArray buf, i, len);
              case t of
                nil => ()
              | _::_ =>
                let val i = i + len
                in Array.copy_unsafe (String.castToArray sep, 0,
                                      String.castToArray buf, i, sepLen);
                   loop (i + sepLen, t)
                end
            end
      in
        loop (0, vectors);
        buf
      end

  fun str c =
      let
        val buf = String.alloc_unsafe 1
      in
        Array.update_unsafe (String.castToArray buf, 0, c);
        buf
      end

  fun explode vec =
      let
        val len = String.size vec
        fun loop (i, z) =
            if i >= 0
            then loop (i - 1, Array.sub_unsafe (String.castToArray vec, i) :: z)
            else z
      in
        loop (len - 1, nil)
      end

  fun translate transFn vec =
      let
        val len = String.size vec
        fun init (i, totalSize, buf) =
            if i < len then
              let val c = Array.sub_unsafe (String.castToArray vec, i)
                  val x = transFn c
                  val n = String.size x
              in if totalSize + n > maxSize then raise Size else ();
                 init (i + 1, totalSize + n, x :: buf)
              end
            else (totalSize, buf)
        val (totalSize, buf) = init (0, 0, nil)
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

  fun rev (nil, r) = r : string list
    | rev (h::t, r) = rev (t, h::r)

  fun tokens isDelimiter vec =
      let
        val len = String.size vec
        fun add (b, e, z) =
            if b = e then z else substring_unsafe (vec, b, e - b) :: z
        fun loop (beg, i, z) =
            if i >= len then rev (add (beg, i, z), nil)
            else if isDelimiter (Array.sub_unsafe (String.castToArray vec, i))
            then loop (i + 1, i + 1, add (beg, i, z))
            else loop (beg, i + 1, z)
      in
        loop (0, 0, nil)
      end

  fun fields isDelimiter vec =
      let
        val len = String.size vec
        fun add (b, e, z) = substring_unsafe (vec, b, e - b) :: z
        fun loop (beg, i, z) =
            if i >= len then rev (add (beg, i, z), nil)
            else if isDelimiter (Array.sub_unsafe (String.castToArray vec, i))
            then loop (i + 1, i + 1, add (beg, i, z))
            else loop (beg, i + 1, z)
      in
        loop (0, 0, nil)
      end

  fun isPrefix prefix vec =
      let
        val len = String.size prefix
      in
        len <= String.size vec andalso memcmp (prefix, 0, vec, 0, len) = 0
      end

  fun isSuffix suffix vec =
      let
        val len1 = String.size suffix
        val len2 = String.size vec
      in
        len1 <= len2 andalso memcmp (suffix, 0, vec, len2 - len1, len1) = 0
      end

  fun isSubstring vec1 vec2 =
      Substring.isSubstring vec1 (Substring.full vec2)

  fun strcmp (vec1, vec2) =
      let
        val len1 = String.size vec1
        val len2 = String.size vec2
        val min = if len1 < len2 then len1 else len2
      in
        case memcmp (vec1, 0, vec2, 0, min) of
          0 => len1 - len2
        | n => n
      end

  fun compare (vec1, vec2) =
      case strcmp (vec1, vec2) of
        0 => General.EQUAL
      | n => if n < 0 then General.LESS else General.GREATER

  fun op < (x, y) = SMLSharp_Builtin.Int.lt (strcmp (x, y), 0)
  fun op <= (x, y) = SMLSharp_Builtin.Int.lteq (strcmp (x, y), 0)
  fun op > (x, y) = SMLSharp_Builtin.Int.gt (strcmp (x, y), 0)
  fun op >= (x, y) = SMLSharp_Builtin.Int.gteq (strcmp (x, y), 0)

  fun toString s =
      translate Char.toString s
  fun toRawString s =
      translate Char.toRawString s
  fun toCString s =
      translate Char.toCString s

  fun scan getc strm =
      case getc strm of
        NONE => SOME ("", strm)
      | SOME _ =>
        let
          val (zero, strm) =
              case SMLSharp_ScanChar.scanEscapeSpaces getc strm of
                NONE => (false, strm)
              | SOME (_, strm) => (true, strm)
        in
          case SMLSharp_ScanChar.scanRepeat1 SMLSharp_ScanChar.scanChar
                                             getc strm of
            NONE => if zero then SOME ("", strm) else NONE
          | SOME (chars, strm) => SOME (implode chars, strm)
        end

  fun fromString s =
      StringCvt.scanString scan s

  fun fromCString "" = SOME ""
    | fromCString s =
      let
        fun scan getc strm =
            case SMLSharp_ScanChar.scanRepeat1 SMLSharp_ScanChar.scanCChar
                                               getc strm of
              NONE => NONE
            | SOME (chars, strm) => SOME (implode chars, strm)
      in
        StringCvt.scanString scan s
      end

end
