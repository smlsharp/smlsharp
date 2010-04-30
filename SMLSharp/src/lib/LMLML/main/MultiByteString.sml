(**
 * The main user interface of the multibyte string library.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MultiByteString.sml,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
structure MultiByteString :> MULTI_BYTE_STRING =
struct

  exception BadFormat = Codecs.BadFormat

  exception Unordered = Codecs.Unordered

  exception UnknownCodec = Codecs.UnknownCodec

  fun getCodecMethods name =
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
  val defaultCodec = ref ("ASCII", getCodecMethods "ASCII")
  val listenersRef = ref ([] : (string -> unit) list)
  end
  fun addDefaultCodecChangeListener listener =
      listenersRef := listener :: (!listenersRef)
  fun setDefaultCodecName codecName =
      (
        defaultCodec := (codecName, getCodecMethods codecName);
        List.app (fn listener => listener codecName) (!listenersRef)
      )
  fun getDefaultCodec () = #2(!defaultCodec)
  fun getDefaultCodecName () = #1(!defaultCodec)

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

  end

  structure String =
  struct

    fun decodeBytesSlice codecName =
        let val methods = getCodecMethods codecName
        in fn buffer => MBS(#decode methods buffer, methods)
        end

    fun decodeBytes codecName = (decodeBytesSlice codecName) o BVS.full

    fun decodeString codecName = (decodeBytes codecName) o Byte.stringToBytes

    structure S = CodecStringBase(Prim)
    open S

  end

  structure Char =
  struct

    fun fromWord codecName =
        let
          val methods = getCodecMethods codecName
          val chrw = #chrw methods
        in fn word32 => MBC(chrw word32, methods)
        end

    fun decodeBytesSlice codecName slice =
        let val mbs = String.decodeBytesSlice codecName slice
        in if 0 = String.size mbs then NONE else SOME(String.sub (mbs, 0))
        end

    fun decodeBytes codecName = (decodeBytesSlice codecName) o BVS.full

    fun decodeString codecName = (decodeBytes codecName) o Byte.stringToBytes

    structure C = CodecCharBase(Prim)
    open C

  end

  end (* local *)

end;
