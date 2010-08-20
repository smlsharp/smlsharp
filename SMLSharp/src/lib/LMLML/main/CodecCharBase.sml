(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
functor CodecCharBase(P : PRIM_CODEC) : MULTI_BYTE_CHAR =
struct

  type string = P.string
  type char = P.char

  exception Chr

  fun bytesSliceToMBC slice =
      let val mbs = P.decode slice
      in if 0 = P.size mbs then NONE else SOME(P.sub (mbs, 0))
      end
  val MBCToBytesSlice = P.encode o P.charToString

  val bytesToMBC = bytesSliceToMBC o Word8VectorSlice.full
  val MBCToBytes = Word8VectorSlice.vector o P.encode o P.charToString

  val stringToMBC = bytesToMBC o Byte.stringToBytes
  val MBCToString =
      Byte.bytesToString o Word8VectorSlice.vector o P.encode o P.charToString

  val compare = P.compareChar

  fun contains string1 c2 =
      let
        val stringSize = P.size string1
        fun find i =
            if i < stringSize
            then
              case compare (P.sub (string1, i), c2)
               of EQUAL => true
                | _ => find (i + 1)
            else false
      in
        find 0
      end

  fun notContains string c = not (contains string c)

  val ordw = P.ordw
  fun ord c = Word32.toInt (ordw c)

  fun chrw i =
      if i < 0w0 orelse P.maxOrdw () < i
      then raise Chr
      else P.chrw i

  fun chr int = chrw (Word32.fromInt int)

  fun maxOrdw () = P.maxOrdw ()
  fun minOrdw () = P.minOrdw ()

  fun minChar () = chrw (P.minOrdw ())
  fun maxChar () = chrw (P.maxOrdw ())
  fun maxOrd () = Word32.toInt (P.maxOrdw ())

  fun succ c =
      if ordw c = P.maxOrdw ()
      then raise Chr
      else chrw(ordw c + 0w1)

  fun pred c =
      if ordw c = P.minOrdw ()
      then raise Chr
      else chrw(ordw c - 0w1)

  val toAsciiChar = P.toAsciiChar
  val fromAsciiChar = P.fromAsciiChar

  val isAscii = P.isAscii
  val isSpace = P.isSpace
  val isLower = P.isLower
  val isUpper = P.isUpper
  val isDigit = P.isDigit
  fun isAlpha c = isLower c orelse isUpper c
  val isHexDigit = P.isHexDigit
  fun isAlphaNum c = isAlpha c orelse isDigit c
  val isPunct = P.isPunct
  val isGraph = P.isGraph
  val isCntrl = P.isCntrl
  fun isPrint c = not (isCntrl c)
  fun toLower c =
      if isAlpha c andalso isUpper c
      then (fromAsciiChar o Char.toLower o Option.valOf o toAsciiChar) c
      else c
  fun toUpper c =
      if isAlpha c andalso isLower c
      then (fromAsciiChar o Char.toUpper o Option.valOf o toAsciiChar) c
      else c

  local
    val stringToMBS = P.decode o Word8VectorSlice.full o Byte.stringToBytes
    val MBCToString =
        Byte.bytesToString
        o Word8VectorSlice.vector
        o P.encode
        o P.charToString
    fun fromStringBase converter cstring =
        (* A sequence of ASCII characters may start with a C-escape sequence,
         * which shoule be converted to a character.
         * So, we check whether the string begins with an ASCII character or
         * a non-ASCII (= multi-byte) character.
         *)
        let val string = stringToMBS cstring
        in
          if 0 < P.size string
          then
            if P.isAscii (P.sub (string, 0))
            then Option.map P.fromAsciiChar (converter cstring)
            else SOME(P.sub (string, 0))
          else NONE
        end

    fun toStringBase converter =
        (fn c =>
            case P.toAsciiChar c
             of SOME asciiChar => converter asciiChar
              | NONE => MBCToString c)

  in
  val fromString = fromStringBase Char.fromString
  val toString = toStringBase Char.toString
  val fromCString = fromStringBase Char.fromCString
  val toCString = toStringBase Char.toCString
  end

  fun op < args = compare args = General.LESS
  fun op <= args = compare args <> General.GREATER
  fun op > args = compare args = General.GREATER
  fun op >= args = compare args <> General.LESS

  val dump = P.dumpChar

end