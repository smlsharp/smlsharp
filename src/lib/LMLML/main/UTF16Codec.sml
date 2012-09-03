(*
local
*)
  (**
   * implementation of variations of UTF-16 codec: UTF-16LE, UTF-16BE, UTF-16.
   * The argument structure has only a <code>isLEOpt</code> field to indicate
   * the endian in which 16bit integers are serialized.
   * For UTF-16LE, <code>isLEOpt</code> should be <code>SOME true</code>.
   * For UTF-16BE, <code>isLEOpt</code> should be <code>SOME false</code>.
   * For UTF-16, <code>isLEOpt</code> should be <code>NONE</code>.
   *)
  functor UTF16CodecPrimArgBase(P : sig val isLEOpt : bool option end) =
  struct

  val names =
      case P.isLEOpt
       of SOME true => ["UTF-16LE"]
        | SOME false => ["UTF-16BE"]
        | NONE => ["UTF-16"]

  val minOrdw = 0w0 : Word32.word
  val maxOrdw = 0wx10FFFF : Word32.word

  local
    structure V = Vector
    structure VS = VectorSlice
    structure BV = Word8Vector
    structure BVS = Word8VectorSlice

    val W32 = Word32.fromLargeWord o Word8.toLargeWord
    val W8 = Word8.fromLargeWord o Word32.toLargeWord
    val (<<, >>, orb, andb) = (Word32.<<, Word32.>>, Word32.orb, Word32.andb)
    infix << >> orb andb

    (**
     * deserializes a 16bit integer from a byte array.
     * @params isLE buffer index
     * @param isLE true if a 16bit integer is encoded in little endian.
     * @param buffer a byte array in which a 16bit integer is encoded.
     * @param index the index of the first byte of encoded 16bit integer in
     *             the buffer.
     * @return a pair (HB, LB) of most siginificant byte HB in its 1st field
     *         and least siginificant byte LB in its 2nd field.
     *)
    fun decode16 isLE buffer index =
        if isLE
        then (BVS.sub (buffer, index + 1), BVS.sub (buffer, index + 0))
        else (BVS.sub (buffer, index + 0), BVS.sub (buffer, index + 1))

    (**
     * serializes a 16bit integer.
     * @params isLE (HB, LB)
     * @param isLE true if serialize in little endian.
     * @param HB the most siginificant byte of the 16bit integer.
     * @param LB the least siginificant byte of the 16bit integer.
     * @return a list of two 8bit integers which is obtained by serializing
     *        the 16bit integer.
     *)
    fun encode16 isLE (HB, LB) = if isLE then [LB, HB] else [HB, LB]

    (**
     * converts a 16bit integer into a Unicode codepoint.
     *)
    fun C2 (b1, b2) = (W32 b1 << 0w8) orb (W32 b2)

    (**
     * converts a pair of two 16bit integers into a Unicode codepoint.
     *)
    fun C4 (b1, b2, b3, b4) = 
        (* surrogate pair *)
        ((W32 b1 andb 0wx3) << 0w18)
            orb (W32 b2 << 0w10)
            orb ((W32 b3 andb 0wx3) << 0w8)
            orb W32 b4
  in

  (**
   * decodes a code point from a byte sequence.
   * <p>
   * If the first 16-bit word is between 0wxD800 and 0wxDBFF, it is the
   * first word of a surrogate pair.
   * Then, its following 16-bit word should be between 0wxDC00 and 0wxDFFF.
   * The two 16-bit words constitute a surrogate pair.
   * <p>
   * The following two 16-bit words
   * <pre>
   *   1101 10qq xxxx xxxx
   *   1101 11yy zzzz zzzz
   * </pre>
   * are decoded into a 32-bit codepoint
   * <pre>
   *   0000 0000 0000 qqxx xxxx xxyy zzzz zzzz
   * </pre>
   * </p>
   * <p>
   * Note: 
   * <pre>
   *   1101 1000 = 0xD8
   *   1101 1011 = 0xDB
   *   1101 1100 = 0xDC
   *   1101 1111 = 0xDF
   * </pre>
   * </p>
   * <p>
   * For UTF-16 encoding, the string may begin with a byte order mark U+FEFF.
   * If the first two bytes are [FF, FE], endian is little endian.
   * If the first two bytes are [FE, FF], endian is big endian.
   * Otherwise, the string is in big endian order.
   * </p>
   *)
  fun decode buffer =
      let
        val bufferLength = BVS.length buffer
        val (initialIndex, isLE) =
            case P.isLEOpt
             of SOME isLE => (0, isLE)
              | NONE =>
                (
                  2,
                  (2 <= bufferLength)
                  andalso ((0wxFE, 0wxFF) = decode16 true buffer 0)
                )
        fun getNextChar index =
            if index + 1 < bufferLength
            then
              let val (b1, b2) = decode16 isLE buffer index
              in
                if (0wxD8 <= b1 andalso b1 <= 0wxDB)
                   andalso (index + 3 < bufferLength)
                then
                  let val (b3, b4) = decode16 isLE buffer (index + 2)
                  in
                    if 0wxDC <= b3 andalso b3 <= 0wxDF
                    then SOME(C4 (b1, b2, b3, b4), index + 4)
                    else SOME(C2 (b1, b2), index + 2)
                  end
                else SOME(C2 (b1, b2), index + 2)
              end
            else NONE
        fun scan index codePoints =
            case getNextChar index
             of NONE => List.rev codePoints
              | SOME(codePoint, index') =>
                scan index' (codePoint :: codePoints)
      in
        VS.full(V.fromList (scan initialIndex []))
      end

  fun encodeChar dw =
      if 0w0 = (dw andb 0wxF0000)
      then
        case PrimCodecUtil.word32ToBytes dw
         of [0w0, 0w0, b1, b2] => [(b1, b2)]
          | _ => raise Fail "BUG: UTF16Codec.encodeChar"
      else
        let
          val w1 = (dw >> 0w10) andb 0wx3FF
          val b1 = W8 (0wxD8 orb ((w1 andb 0wx3FF) >> 0w8))
          val b2 = W8 (w1 andb 0wxFF)
          val w2 = dw andb 0wx3FF
          val b3 = W8 (0wxDC orb ((w2 andb 0wx3FF) >> 0w8))
          val b4 = W8 (w2 andb 0wxFF)
        in
          [(b1, b2), (b3, b4)]
        end

  fun encode string =
      let
        val (isLE, prefix) =
            case P.isLEOpt
             of SOME true => (true, [])
              | SOME false => (false, [])
              | NONE => (true, [(0wxFE, 0wxFF)])
        val words =
            VS.foldr
                (fn (codePoint, bytess) => encodeChar codePoint @ bytess)
                []
                string
        val bytes = List.concat (List.map (encode16 isLE) (prefix @ words))
      in
        BVS.full(BV.fromList bytes)
      end

  fun convert targetCodec chars = raise Codecs.ConverterNotFound

  end (* local *)

  end (* struct *)

local

  structure UTF16BECodecPrimArg =
  UTF16CodecPrimArgBase(struct val isLEOpt = SOME false end)

  structure UTF16LECodecPrimArg =
  UTF16CodecPrimArgBase(struct val isLEOpt = SOME true end)

  structure UTF16CodecPrimArg =
  UTF16CodecPrimArgBase(struct val isLEOpt = NONE end)

in

(**
 * fundamental functions to access UTF-16BE encoded characters.
 * @author YAMATODANI Kiyoshi
 * @version $Id: UTF16Codec.sml,v 1.3 2007/02/25 12:42:48 kiyoshiy Exp $
 *)
structure UTF16BECodec =
          Codec(FixedLengthCharPrimCodecBase(UTF16BECodecPrimArg))

(**
 * fundamental functions to access UTF-16LE encoded characters.
 * @author YAMATODANI Kiyoshi
 * @version $Id: UTF16Codec.sml,v 1.3 2007/02/25 12:42:48 kiyoshiy Exp $
 *)
structure UTF16LECodec =
          Codec(FixedLengthCharPrimCodecBase(UTF16LECodecPrimArg))

(**
 * fundamental functions to access UTF16 encoded characters.
 * @author YAMATODANI Kiyoshi
 * @version $Id: UTF16Codec.sml,v 1.3 2007/02/25 12:42:48 kiyoshiy Exp $
 *)
structure UTF16Codec =
          Codec(FixedLengthCharPrimCodecBase(UTF16CodecPrimArg))

end