(**
 * The main user interface of the multibyte text library.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MultiByteText.sml,v 1.1.2.4 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
structure MultiByteText :> MULTI_BYTE_TEXT =
struct

  exception BadFormat = Codecs.BadFormat

  exception Unordered = Codecs.Unordered

  exception UnknownCodec = Codecs.UnknownCodec

  type codec = Codecs.methods

  fun getCodec name =
      case Codecs.findCodec name
       of NONE => raise UnknownCodec
        | SOME codec => codec

  val getCodecNames = Codecs.getCodecNames

  local
    (* NOTE: ASCIICodec is referenced here in order tell the SML compiler
     * that ASCIICodec must be loaded and registered to Codecs registry
     * before this MultiByteString is loaded.
     *)
    structure A = ASCIICodec
  in
  val defaultCodec = ref (getCodec "ASCII")
  val listenersRef = ref ([] : (codec -> unit) list)
  end
  fun addDefaultCodecChangeListener listener =
      listenersRef := listener :: (!listenersRef)
  fun setDefaultCodec codec =
      (
        defaultCodec := codec;
        List.app (fn listener => listener codec) (!listenersRef)
      )
  fun getDefaultCodec () = !defaultCodec

  local

    structure BV = Word8Vector
    structure BVS = Word8VectorSlice

    datatype string = MBS of Codecs.string * Codecs.methods
    datatype char = MBC of Codecs.char * Codecs.methods

  in

  structure Prim : PRIM_CODEC =
  struct

    type string = string
    type char = char

    val names = ["unified"]

    fun decode slice =
        let val methods = getDefaultCodec ()
        in MBS(#decode methods slice, methods) end
    fun encode (MBS(string, methods)) =
        BVS.full(BVS.vector(#encode methods string))
    fun convert targetCodec (MBS(string, methods)) =
        #convert methods targetCodec string

    (* Note : The encoding of the emptyString is the initial default codec.
     * We must care not to apply the methods of this emptyString to strings
     * of other codec. See the concat function below.
     *)
    val emptyString = decode (BVS.full(BV.fromList []))

    fun sub (MBS(s, m), i) = MBC(#sub m (s, i), m)
    fun substring (MBS(s, m), start, length) =
        MBS(#substring m (s, start, length), m)
    fun size (MBS(s, m)) = #size m s

    (* See VariableLengthCharPrimCodecBase.maxSize. *)
    val maxSize = (BV.maxLen div 2) div 10 * 9

    fun concat [] = emptyString
      | concat (strings as (MBS(s1, m1) :: remain)) =
        (* Note: We must care not to use methods of a zero-length string
         * in the result string. *)
        if 0 < #size m1 s1
        then
          let val rawstrings = List.map (fn MBS(string, _) => string) strings
          in MBS(#concat m1 rawstrings, m1)
          end
        else concat remain

    fun compareChar (MBC(c1, m1), MBC(c2, m2)) = #compareChar m1 (c1, c2)

    fun ordw (MBC(c, m)) = #ordw m c
    fun chrw word32 =
        let val methods = getDefaultCodec ()
        in MBC(#chrw methods word32, methods) end

    fun minOrdw () = #minOrdw (getDefaultCodec ()) ()
    fun maxOrdw () = #maxOrdw (getDefaultCodec ()) ()

    fun charToString (MBC(c, m)) = MBS(#charToString m c, m)
    fun toAsciiChar (MBC(c, m)) = #toAsciiChar m c
    fun fromAsciiChar char =
        let val methods = getDefaultCodec ()
        in MBC(#fromAsciiChar methods char, methods)
        end

    fun isAscii (MBC(c, m)) = #isAscii m c
    fun isSpace (MBC(c, m)) = #isSpace m c
    fun isLower (MBC(c, m)) = #isLower m c
    fun isUpper (MBC(c, m)) = #isUpper m c
    fun isDigit (MBC(c, m)) = #isDigit m c
    fun isHexDigit (MBC(c, m)) = #isHexDigit m c
    fun isPunct (MBC(c, m)) = #isPunct m c
    fun isGraph (MBC(c, m)) = #isGraph m c
    fun isCntrl (MBC(c, m)) = #isCntrl m c

    fun dumpChar (MBC(c, m)) = #dumpChar m c
    fun dumpString (MBS(s, m)) = #dumpString m s

  end

  structure String =
  struct

    fun decodeBytesSlice codec =
        fn buffer => MBS(#decode codec buffer, codec)

    fun decodeBytes codec = (decodeBytesSlice codec) o BVS.full

    fun decodeString codec = (decodeBytes codec) o Byte.stringToBytes

    fun getCodec (MBS(_, methods)) = methods

    structure S = CodecStringBase(Prim)
    open S

  end

  structure Char =
  struct

    fun fromWord codec =
        let
          val chrw = #chrw codec
        in fn word32 => MBC(chrw word32, codec)
        end

    fun decodeBytesSlice codec slice =
        let val mbs = String.decodeBytesSlice codec slice
        in if 0 = String.size mbs then NONE else SOME(String.sub (mbs, 0))
        end

    fun decodeBytes codec = (decodeBytesSlice codec) o BVS.full

    fun decodeString codec = (decodeBytes codec) o Byte.stringToBytes

    fun getCodec (MBC(_, methods)) = methods

    structure C = CodecCharBase(Prim)
    open C

  end

  structure Substring =
  CodecSubstringBase(struct open Prim val compare = String.compare end)

  local
    structure P =
    struct
      open Prim
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

  end (* local *)

end;
