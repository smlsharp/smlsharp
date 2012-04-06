(**
 * String related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *
 * @author Atsushi Ohori
 * @copyright 2010, 2011, Tohoku University.
 *)

_interface "String.smi"

structure String : STRING
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
  val strcmp = _import "strcmp" : (string, string) -> int
in
  type string = string
  type char = char
  val maxSize = StringBase.maxLen
  val sub = StringBase.sub
  val map = StringBase.map
  val concat = StringBase.concat
  val size = SMLSharp.PrimString.size
  val implode = StringBase.fromList
  val collate = StringBase.collate

  fun extract x = CharVectorSlice.vector (CharVectorSlice.slice x)
  fun substring (str, start, len) = extract (str, start, SOME len)
  fun op ^ (str1, str2) =
     let
       val len1 = SMLSharp.PrimString.size str1
       val len2 = SMLSharp.PrimString.size str2
       val buf = SMLSharp.PrimString.allocVector (len1 + len2)
     in
       SMLSharp.PrimString.copy_unsafe (str1, 0, buf, 0, len1);
       SMLSharp.PrimString.copy_unsafe (str2, 0, buf, len1, len2);
       buf
     end
  fun concatWith sep nil = ""
    | concatWith sep [x] = x
    | concatWith sep strings =
      StringBase.concatWith
        sep
        (List.map (fn str => (str, 0, SMLSharp.PrimString.size str)) strings)
  fun str c =
      let
        val buf = SMLSharp.PrimString.allocVector 1
      in
        SMLSharp.PrimString.update_unsafe (buf, 0, c);
        buf
      end

  fun explode str =
      StringBase.explode (str, 0, SMLSharp.PrimString.size str)

  fun translate transFn str =
      StringBase.translate transFn (str, 0, SMLSharp.PrimString.size str)

  fun tokens isDelimiter str =
      let
        val len = SMLSharp.PrimString.size str
        fun add (b, e, z) =
            if b = e then z
            else StringBase.substring_unsafe (str, b, e - b) :: z
        fun loop (beg, i, z) =
            if i >= len then rev (add (beg, i, z))
            else if isDelimiter (SMLSharp.PrimString.sub_unsafe (str, i))
            then loop (i + 1, i + 1, add (beg, i, z))
            else loop (beg, i + 1, z)
      in
        loop (0, 0, nil)
      end

  fun fields isDelimiter str =
      let
        val len = SMLSharp.PrimString.size str
        fun add (b, e, z) = StringBase.substring_unsafe (str, b, e - b) :: z
        fun loop (beg, i, z) =
            if i >= len then rev (add (beg, i, z))
            else if isDelimiter (SMLSharp.PrimString.sub_unsafe (str, i))
            then loop (i + 1, i + 1, add (beg, i, z))
            else loop (beg, i + 1, z)
      in
        loop (0, 0, nil)
      end

  fun isPrefix prefix str =
      StringBase.isPrefix prefix (str, 0, SMLSharp.PrimString.size str)

  fun isSuffix suffix str =
      StringBase.isSuffix suffix (str, 0, SMLSharp.PrimString.size str)

  fun isSubstring str1 str2 =
      StringBase.isSubstring str1 (str2, 0, SMLSharp.PrimString.size str2)


  fun compare (x, y) =
      if SMLSharp.identityEqual (SMLSharp.PrimString.toBoxed x,
                                   SMLSharp.PrimString.toBoxed y)
      then EQUAL
      else case strcmp (x, y) of
             0 => EQUAL
           | n => if n < 0 then LESS else GREATER

  fun op < (x, y) = SMLSharp.Int.lt (strcmp (x, y), 0)
  fun op <= (x, y) = SMLSharp.Int.lteq (strcmp (x, y), 0)
  fun op > (x, y) = SMLSharp.Int.gt (strcmp (x, y), 0)
  fun op >= (x, y) = SMLSharp.Int.gteq (strcmp (x, y), 0)

  fun toString s =
      translate Char.toString s
  fun toCString s =
      translate Char.toCString s

  fun scan getc strm =
      let
        val (zero, strm) =
            case SMLSharpScanChar.scanEscapeSpaces getc strm of
              NONE => (false, strm)
            | SOME (_, strm) => (true, strm)
      in
        case SMLSharpScanChar.scanRepeat1 SMLSharpScanChar.scanChar
                                            getc strm of
            NONE => if zero then SOME ("", strm) else NONE
          | SOME (chars, strm) => SOME (implode chars, strm)
        end

  fun fromString s =
      StringCvt.scanString scan s

  fun fromCString s =
      let
        fun scan getc strm =
            case SMLSharpScanChar.scanRepeat1 SMLSharpScanChar.scanCChar
                                              getc strm of
              NONE => NONE
            | SOME (chars, strm) => SOME (implode chars, strm)
      in
        StringCvt.scanString scan s
      end

end (* String *)
end

val op ^ = String.^
val concat = String.concat
val explode = String.explode
val implode = String.implode
val size = String.size
val str = String.str
val substring = String.substring
