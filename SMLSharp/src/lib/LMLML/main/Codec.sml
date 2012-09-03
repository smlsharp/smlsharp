(**
 * This functor adds a codec into the codec registry defined in the
 * <code>Codecs</code> structure.
 * <h4>Implementation note</h4>
 * <p>
 * Development of many multilingualized applications require dynamic codec
 * selection.
 * For example, a software which processes MIME messages have to change
 * dynamically a codec to be used to parse messages.
 * A solution is to package codec specific functions into a record.
 * On the other hand, it is straightforward to package codec specific data
 * types and functions in a module.
 * This functor converts a structure which implements codec specific functions
 * into a record of functions.
 * </p>
 * @author YAMATODANI Kiyoshi
 * @version $Id: Codec.sml,v 1.2.26.3 2010/05/11 07:08:03 kiyoshiy Exp $
 *)
functor Codec(PrimCodec : PRIM_CODEC) :> CODEC =
struct

  structure String = CodecStringBase(PrimCodec)
  structure Char = CodecCharBase(PrimCodec)
  structure Substring =
            CodecSubstringBase
                (struct open PrimCodec val compare = String.compare end)
  local
    structure P =
    struct
      open PrimCodec
      type string = String.string
      type char = String.char
      type substring = Substring.substring
      val implode = String.implode
      val getc = Substring.getc
      val full = Substring.full
      val compare = String.compare
      val compareChar = Char.compare
    end
  in
  structure ParserCombinator = CodecParserCombinatorBase(P)
  structure StringConverter = CodecStringConverterBase(P)
  end

  local

    exception MBS of PrimCodec.string
    exception MBC of PrimCodec.char

    fun error () = raise Fail "BUG: Codec found unexpected constructor."

    fun decode buffer = MBS (PrimCodec.decode buffer)
    fun encode (MBS string) = PrimCodec.encode string
      | encode _ = error ()
    fun convert targetCodec (MBS string) = PrimCodec.convert targetCodec string
      | convert _ _ = error ()

    fun sub (MBS string, i) = MBC(PrimCodec.sub (string, i))
      | sub _ = error ()
    fun substring (MBS string, start, length) =
        MBS(PrimCodec.substring(string, start, length))
      | substring _ = error ()
    fun size (MBS string) = PrimCodec.size string
      | size _ = error ()
    fun concat strings =
        let
          val strings' =
              List.map (fn MBS string => string | _ => error ()) strings
        in MBS(PrimCodec.concat strings')
        end

    fun compareChar (MBC cursor1, MBC cursor2) =
        PrimCodec.compareChar (cursor1, cursor2)
      | compareChar (MBC _, _) = raise Codecs.Unordered
      | compareChar _ = error ()

    val maxOrdw = PrimCodec.maxOrdw
    val minOrdw = PrimCodec.minOrdw
    fun ordw (MBC char) = PrimCodec.ordw char
      | ordw _ = error ()
    fun chrw word32 = MBC(PrimCodec.chrw word32)

    fun toAsciiChar (MBC char) = PrimCodec.toAsciiChar char
      | toAsciiChar _ = error ()
    fun fromAsciiChar char = MBC(PrimCodec.fromAsciiChar char)
    fun charToString (MBC char) = MBS(PrimCodec.charToString char)
      | charToString _ = error ()

    fun isAscii (MBC char) = PrimCodec.isAscii char
      | isAscii _ = error ()
    fun isSpace (MBC char) = PrimCodec.isSpace char
      | isSpace _ = error ()
    fun isLower (MBC char) = PrimCodec.isLower char
      | isLower _ = error ()
    fun isUpper (MBC char) = PrimCodec.isUpper char
      | isUpper _ = error ()
    fun isDigit (MBC char) = PrimCodec.isDigit char
      | isDigit _ = error ()
    fun isHexDigit (MBC char) = PrimCodec.isHexDigit char
      | isHexDigit _ = error ()
    fun isPunct (MBC char) = PrimCodec.isPunct char
      | isPunct _ = error ()
    fun isGraph (MBC char) = PrimCodec.isGraph char
      | isGraph _ = error ()
    fun isCntrl (MBC char) = PrimCodec.isCntrl char
      | isCntrl _ = error ()

    fun dumpChar (MBC char) = PrimCodec.dumpChar char
      | dumpChar _ = error ()
    fun dumpString (MBS string) = PrimCodec.dumpString string
      | dumpString _ = error ()

    val methods = 
        {
             codecNames = PrimCodec.names,
             decode = decode,
             encode = encode,
             convert = convert,

             sub = sub,
             substring = substring,
             size = size,
             concat = concat,

             compareChar = compareChar,

             ordw = ordw,
             chrw = chrw,
             minOrdw = minOrdw,
             maxOrdw = maxOrdw,

             toAsciiChar = toAsciiChar,
             fromAsciiChar = fromAsciiChar,
             charToString = charToString,

             isAscii = isAscii,
             isSpace = isSpace,
             isLower = isLower,
             isUpper = isUpper,
             isDigit = isDigit,
             isHexDigit = isHexDigit,
             isPunct = isPunct,
             isGraph = isGraph,
             isCntrl = isCntrl,

             dumpChar = dumpChar,
             dumpString = dumpString
           } : Codecs.methods

    val _ = Codecs.registerCodec (PrimCodec.names, methods)

  in

  end

end;
