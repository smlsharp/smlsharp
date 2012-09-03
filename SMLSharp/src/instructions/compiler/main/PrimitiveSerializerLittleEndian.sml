(**
 * serializer of primitive types for Little-endian architecture.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PrimitiveSerializerLittleEndian.sml,v 1.9 2007/09/01 14:51:28 kiyoshiy Exp $
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

  (* NOTE: This function is called frequently at unpickling.
   *)
  fun readBytes 1 reader = BT.UInt8ToUInt32 (reader ())
    | readBytes 2 reader =
      let
        val b1 = BT.UInt8ToUInt32 (reader ())
        val b2 = BT.UInt8ToUInt32 (reader ())
      in BT.UInt32.orb (BT.UInt32.<< (b2, 0w8), b1) end
    | readBytes 3 reader =
      let
        val b1 = BT.UInt8ToUInt32 (reader ())
        val b2 = BT.UInt8ToUInt32 (reader ())
        val b3 = BT.UInt8ToUInt32 (reader ())
      in
        BT.UInt32.orb
            (
              BT.UInt32.<< (b3, 0w16),
              BT.UInt32.orb(BT.UInt32.<< (b2, 0w8), b1)
            )
      end
    | readBytes 4 reader =
      let
        val b1 = BT.UInt8ToUInt32 (reader ())
        val b2 = BT.UInt8ToUInt32 (reader ())
        val b3 = BT.UInt8ToUInt32 (reader ())
        val b4 = BT.UInt8ToUInt32 (reader ())
      in
        BT.UInt32.orb
            (
              BT.UInt32.<< (b4, 0w24),
              BT.UInt32.orb
                  (
                    BT.UInt32.<< (b3, 0w16),
                    BT.UInt32.orb (BT.UInt32.<< (b2, 0w8), b1)
                  )
            )
      end
    | readBytes n reader =
      raise Fail "Bug PrimitiveSerializerLittleEndian.readBytes"

  (***************************************************************************)

  fun fromWord64 (h, l) = (l, h)
  fun toWord64 (l, h) = (h, l)

  (***************************************************************************)

end