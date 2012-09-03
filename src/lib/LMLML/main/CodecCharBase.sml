functor CodecCharBase(P : PRIM_CODEC) : MB_CHAR =
struct

  type string = P.string
  type char = P.char

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

  val chrw = P.chrw

  fun chr int = chrw (Word32.fromInt int)

  fun maxOrdw () = P.maxOrdw ()
  fun minOrdw () = P.minOrdw ()

  fun minChar () = chrw (P.minOrdw ())
  fun maxChar () = chrw (P.maxOrdw ())
  fun maxOrd () = Word32.toInt (P.maxOrdw ())

  val toAsciiChar = P.toAsciiChar
  val fromAsciiChar = P.fromAsciiChar

  val isAscii = P.isAscii
  val isSpace = P.isSpace
  val isLower = P.isLower
  val isUpper = P.isUpper
  val isDigit = P.isDigit
  fun isAlpha c = isLower c orelse isUpper c
  val isHexDigit = P.isHexDigit
  fun isAlphaNum c = isAlpha c andalso isDigit c
  val isPunct = P.isPunct
  val isGraph = P.isGraph
  val isCntrl = P.isCntrl
  fun isPrint c = not (isCntrl c)

  val toString =
      Byte.bytesToString o Word8VectorSlice.vector o P.encode o P.charToString

  fun fromBytesSlice slice =
      let val mbs = P.decode slice
      in if 0 = P.size mbs then NONE else SOME(P.sub (mbs, 0))
      end

  val fromBytes = fromBytesSlice o Word8VectorSlice.full

  val fromString = fromBytes o Byte.stringToBytes

  fun op < args = compare args = General.LESS
  fun op <= args = compare args <> General.GREATER
  fun op > args = compare args = General.GREATER
  fun op >= args = compare args <> General.LESS

end