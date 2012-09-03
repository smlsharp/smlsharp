(**
 * serializer of primitive types for Little-endian architecture.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PrimitiveSerializerLittleEndian.sml,v 1.7 2007/02/19 14:11:56 kiyoshiy Exp $
 *)
structure PrimitiveSerializerLittleEndian :> PRIMITIVE_SERIALIZER =
struct

  (***************************************************************************)

  structure BT = BasicTypes

  (***************************************************************************)

  type reader = unit -> Word8.word
  type writer = Word8.word -> unit
  type word64 = IEEE754.word64

  (***************************************************************************)

  val byteOrder = SystemDefTypes.LittleEndian

  fun getByteOfWord word index =
      let
        val shifted = Word32.>> (word, Word.fromInt(index * 8))
      in
        Word8.fromLargeWord (Word32.toLargeWord (Word32.andb (shifted, 0wxFF)))
      end

  fun writeLowBytes (word, bytes) writer =
      let
        (* write from least significant byte to most significant byte. *)
        fun scan 0 = ()
          | scan remain =
            (writer (getByteOfWord word (bytes - remain)); scan (remain - 1))
      in scan bytes
      end

  (***************************************************************************)

  fun readBytes bytes reader =
      let
        fun read 0 readBytes =
            (* first element of readBytes is the most significant byte. *)
            foldl
                (fn (byte, word) =>
                    UInt32.orb
                        (
                          UInt32.<< (word, 0w8),
                          UInt32.andb (BT.UInt8ToUInt32 byte, 0wxFF)
                        ))
                (0wx0 : BT.UInt32)
                readBytes
          | read remain readBytes =
            case reader () of byte => read (remain - 1) (byte :: readBytes)
      in
        read bytes []
      end

  (***************************************************************************)

  fun fromWord64 (h, l) = (l, h)
  fun toWord64 (l, h) = (h, l)

  (***************************************************************************)

end