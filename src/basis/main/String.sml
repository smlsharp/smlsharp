(**
 * String
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright (C) 2021 SML# Development Team.
 *)

infix 7 * / div mod
infix 6 + -
infixr 5 ::
infix 4 = <> > >= < <=
val op + = SMLSharp_Builtin.Int32.add_unsafe
val op - = SMLSharp_Builtin.Int32.sub_unsafe
val op < = SMLSharp_Builtin.Int32.lt
val op <= = SMLSharp_Builtin.Int32.lteq
val op > = SMLSharp_Builtin.Int32.gt
val op >= = SMLSharp_Builtin.Int32.gteq
structure Int32 = SMLSharp_Builtin.Int32
structure Array = SMLSharp_Builtin.Array
structure String = SMLSharp_Builtin.String

val memcmp = _import "sml_memcmp"
             : __attribute__ ((pure,fast))
               (string, int, string, int, int) -> int

structure String =
struct

  type string = string
  type char = char

  (* object size occupies 28 bits of 32-bit object header.
   * "string" have a sentinel null character at the end of the sequence. *)
  val maxSize = 0x0ffffffe

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
      in
        if start < 0 orelse len < start
           orelse length < 0 orelse len - start < length
        then raise Subscript
        else substring_unsafe (vec, start, length)
      end

  fun extract (vec, start, SOME length) = substring (vec, start, length)
    | extract (vec, start, NONE) =
      let
        val len = String.size vec
      in
        if start < 0 orelse len < start then raise Subscript
        else substring_unsafe (vec, start, len - start)
      end

  fun op ^ (vec1, vec2) =
     let
       val len1 = String.size vec1
       val len2 = String.size vec2
       val allocSize = Int32.add (len1, len2) handle Overflow => raise Size
       val buf = String.alloc allocSize
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
          | totalLength ([vec], z) = Int32.add (z, String.size vec)
          | totalLength (h::t, z) =
            totalLength (t, Int32.add (Int32.add (z, String.size h), sepLen))
        val len = totalLength (vectors, 0) handle Overflow => raise Size
        val buf = String.alloc len
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

  fun translate transFn vec =
      Substring.translate transFn (Substring.full vec)

  fun str c =
      let
        val buf = String.alloc_unsafe 1
      in
        Array.update_unsafe (String.castToArray buf, 0, c);
        buf
      end

  fun explode vec =
      Substring.explode (Substring.full vec)

  fun isPrefix prefix vec =
      Substring.isPrefix prefix (Substring.full vec)

  fun isSuffix suffix vec =
      Substring.isSuffix suffix (Substring.full vec)

  fun isSubstring vec1 vec2 =
      Substring.isSubstring vec1 (Substring.full vec2)

  fun rev (nil, r) = r : string list
    | rev (h::t, r) = rev (t, h::r)

  fun tokens isDelimiter vec =
      let
        val len = String.size vec
        fun add (b, e, z) =
            if b = e then z else substring_unsafe (vec, b, e - b) :: z
        fun loop (beg, i, z) =
            if len <= i then rev (add (beg, i, z), nil)
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
            if len <= i then rev (add (beg, i, z), nil)
            else if isDelimiter (Array.sub_unsafe (String.castToArray vec, i))
            then loop (i + 1, i + 1, add (beg, i, z))
            else loop (beg, i + 1, z)
      in
        loop (0, 0, nil)
      end

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

  fun op < (x, y) = Int32.lt (strcmp (x, y), 0)
  fun op <= (x, y) = Int32.lteq (strcmp (x, y), 0)
  fun op > (x, y) = Int32.gt (strcmp (x, y), 0)
  fun op >= (x, y) = Int32.gteq (strcmp (x, y), 0)

end
