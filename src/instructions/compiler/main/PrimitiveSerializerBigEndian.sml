
(**
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: PrimitiveSerializerBigEndian.sml,v 1.5 2005/12/31 10:22:01 kiyoshiy Exp $
 *)
structure PrimitiveSerializerBigEndian :> PRIMITIVE_SERIALIZER =
struct

  (***************************************************************************)

  open BasicTypes

  (***************************************************************************)

  type reader = unit -> Word8.word
  type writer = Word8.word -> unit

  (***************************************************************************)

  val byteOrder = SystemDefTypes.BigEndian

  fun getByteOfWord word index =
      let
        val shifted = Word32.>> (word, Word.fromInt(index * 8))
      in
        Word8.fromLargeWord (Word32.andb (shifted, 0wxFF))
      end

  fun writeLowBytes (word, bytes) writer =
      let
        (* write from most significant byte to least significant byte. *)
        fun scan 0 = ()
          | scan remain =
            (writer (getByteOfWord word (remain - 1)); scan (remain - 1))
      in scan bytes
      end

  (***************************************************************************)

  fun readBytes bytes reader =
      let
        fun read 0 readBytes =
            (* first element of readBytes is the least significant byte. *)
            foldr
                (fn (byte, word) =>
                    UInt32.orb
                        (
                          UInt32.<< (word, 0w8),
                          UInt32.andb (UInt8ToUInt32 byte, 0wxFF)
                        ))
                (0wx0 : UInt32)
                readBytes
          | read remain readBytes =
            case reader () of byte => read (remain - 1) (byte :: readBytes)
      in
        read bytes []
      end

  (***************************************************************************)

end