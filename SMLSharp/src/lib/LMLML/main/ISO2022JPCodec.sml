local

  structure ISO2022JPCodecPrimArg =
  struct

    structure V = Vector
    structure VS = VectorSlice
    structure BV = Word8Vector
    structure BVS = Word8VectorSlice

    structure CS =
    struct
      datatype charset =
               ASCII
             | JIS_X_0208_1978
             | JIS_X_0208_1983
             | JIS_X_0201_Roman
    end

    type string = Word32.word VectorSlice.slice
    type char = Word32.word

    val names = ["ISO-2022-JP", "csISO2022JP"]

    val minOrdw = 0w0 : Word32.word
    val maxOrdw = 0wx3FFFF : Word32.word

    local
      val W32 = Word32.fromLargeWord o Word8.toLargeWord
      val (<<, >>, orb, andb) = (Word32.<<, Word32.>>, Word32.orb, Word32.andb)
      infix << >> orb andb
    in

    val ord_ESC = 0w27 : Word8.word
    val ord_DOLLAR = 0w36 : Word8.word
    val ord_AT = 0w64 : Word8.word
    val ord_LPAREN = 0w40 : Word8.word
    val ord_B = 0w66 : Word8.word
    val ord_J = 0w74 : Word8.word

    val EscapeASCII = [ord_ESC, ord_LPAREN, ord_B]
    val EscapeJIS_X_0208_1978 = [ord_ESC, ord_DOLLAR, ord_AT]
    val EscapeJIS_X_0208_1983 = [ord_ESC, ord_DOLLAR, ord_B]
    val EscapeJIS_X_0201_Roman = [ord_ESC, ord_LPAREN, ord_J]

    (** 
     *  Read specified number of characters from the stream.
     * If characters of specified number are not available, an empty list is
     * returned.
     * @params stream n
     * @param stream
     * @param n the number of characters (from 1 to 3).
     *)
    fun readByteN buffer index n =
        if index + n <= BVS.length buffer
        then
          let
            fun collect index' 0 es = (index', List.rev es)
              | collect index' n es = 
                collect (index' + 1) (n - 1) (BVS.sub(buffer, index') :: es)
          in
            collect index n []
          end
        else (index, []) (* NOTE: return empty *)

    (**
     * skip escape sequences following the cursor as possible.
     *)
    fun eatEscapeSequence buffer (index, charset) =
        let val (index', bytes) = readByteN buffer index 3
        in
          (* to skip consecutive escape sequences, call itself recursively. *)
          if bytes = EscapeASCII
          then eatEscapeSequence buffer (index', CS.ASCII)
          else
            if bytes = EscapeJIS_X_0208_1978
            then eatEscapeSequence buffer (index', CS.JIS_X_0208_1978)
            else
              if bytes = EscapeJIS_X_0208_1983
              then eatEscapeSequence buffer (index', CS.JIS_X_0208_1983)
              else
                if bytes = EscapeJIS_X_0201_Roman
                then eatEscapeSequence buffer (index', CS.JIS_X_0201_Roman)
                else (index, charset) (* non escape sequence *)
        end

    (**
     * get the index and charset of the character next to the cursor.
     * The first byte and second byte of the character are returned.
     * (The second byte is zero for ASCII charset and JIS_X_0201_Roman. )
     *)
    fun nextChar buffer (index, charset) =
        let
          val bytesOfChar =
              case charset
               of CS.ASCII => 1
                | CS.JIS_X_0201_Roman => 1
                | _ => 2
          val (index', bytes) = readByteN buffer index bytesOfChar
        in ((index', charset), bytes) end

    fun decodeChar buffer (index, charset) =
        case
          case nextChar buffer (index, charset)
           of ((_, CS.ASCII), [b]) => SOME(W32 b, 1)
            | ((_, CS.JIS_X_0201_Roman),[b]) =>
              SOME(0wx10000 orb (W32 b), 1)
            | ((_, CS.JIS_X_0208_1978), [b1, b2]) =>
              SOME(0wx20000 orb ((W32 b1) << 0w8) orb (W32 b2), 2)
            | ((_, CS.JIS_X_0208_1983), [b1, b2]) =>
              SOME(0wx30000 orb ((W32 b1) << 0w8) orb (W32 b2), 2)
            | _ => NONE
         of SOME (code, numBytes) => SOME(index + numBytes, charset, code)
          | NONE => NONE

    fun decode buffer =
        let
          fun collect (index, charset) codes =
              case
                decodeChar buffer (eatEscapeSequence buffer (index, charset))
               of NONE => List.rev codes
                | SOME (index, charset, code) =>
                  collect (index, charset) (code :: codes)
        in
          VS.full(V.fromList (collect (0, CS.ASCII) []))
        end

    fun encodeChar charCode =
        case PrimCodecUtil.word32ToBytes charCode
         of [0wx0, 0wx0, 0wx0, b] => (CS.ASCII, [b])
          | [0wx0, 0wx1, 0wx0, b] => (CS.JIS_X_0201_Roman, [b])
          | [0wx0, 0wx2, b1, b2] => (CS.JIS_X_0208_1978, [b1, b2])
          | [0wx0, 0wx3, b1, b2] => (CS.JIS_X_0208_1983, [b1, b2])
          | _ => raise Fail "BUG:ISO2022JPCodec.encodeChar"

    fun getEscape CS.ASCII = EscapeASCII
      | getEscape CS.JIS_X_0208_1978 = EscapeJIS_X_0208_1978
      | getEscape CS.JIS_X_0208_1983 = EscapeJIS_X_0208_1983
      | getEscape CS.JIS_X_0201_Roman = EscapeJIS_X_0201_Roman

    fun getCanonicalSuffix CS.ASCII = NONE
      | getCanonicalSuffix CS.JIS_X_0201_Roman = NONE
      | getCanonicalSuffix _ = SOME EscapeASCII

    fun encode string =
        let
          val (charset, bytess) =
              VS.foldl
                  (fn (code, (charset, bytess)) =>
                      let val (charset', bytes) = encodeChar code
                      in
                        if charset <> charset'
                        then (charset', (getEscape charset' @ bytes) :: bytess)
                        else (charset, bytes :: bytess)
                      end)
                  (CS.ASCII, [])
                  string
          val suffix = Option.getOpt(getCanonicalSuffix charset, [])
        in
          BVS.full(BV.fromList(List.concat(List.rev bytess) @ suffix))
        end
    fun convert targetCodec chars = raise Codecs.ConverterNotFound

    end (* local *)

  end (* struct *)

in

(**
 * fundamental functions to access ISO-2022-JP encoded characters.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: ISO2022JPCodec.sml,v 1.3 2007/02/25 12:42:48 kiyoshiy Exp $
 *)
structure ISO2022JPCodec :> CODEC =
          Codec(FixedLengthCharPrimCodecBase(ISO2022JPCodecPrimArg))

end
