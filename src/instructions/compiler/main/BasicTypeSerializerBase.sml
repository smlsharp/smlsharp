
(**
 * base implementation of operand serializer.
 * @author YAMATODANI Kiyoshi
 * @version $Id: BasicTypeSerializerBase.sml,v 1.5 2007/06/20 06:50:41 kiyoshiy Exp $
 *)
functor BasicTypeSerializerBase(PrimitiveSerializer : PRIMITIVE_SERIALIZER)
        :> BASIC_TYPE_SERIALIZER =
struct

  (***************************************************************************)

  structure BT = BasicTypes
  structure PS = PrimitiveSerializer

  (***************************************************************************)

  type reader = unit -> Word8.word
  type writer = Word8.word -> unit

  type 't serializer = 't -> writer -> unit
  type 't deserializer = reader -> 't

  (***************************************************************************)

  val byteOrder = PS.byteOrder

  fun serializeUInt8 value writer = writer value
  fun serializeSInt8 value writer =
      serializeUInt8 (BT.UInt32ToUInt8(BT.SInt8ToUInt32(value))) writer
  fun serializeUInt16 value writer =
      PS.writeLowBytes (BT.UInt16ToUInt32 value, 2) writer
  fun serializeSInt16 value writer =
      PS.writeLowBytes (BT.SInt16ToUInt32 value, 2) writer
  fun serializeUInt24 value writer = 
      PS.writeLowBytes (BT.UInt24ToUInt32 value, 3) writer
  fun serializeSInt24 value writer =
      PS.writeLowBytes (BT.SInt24ToUInt32 value, 3) writer
  fun serializeUInt32 value writer = PS.writeLowBytes (value, 4) writer
  fun serializeSInt32 value writer =
      serializeUInt32 (BT.SInt32ToUInt32 value) writer
  fun serializeReal64 (value : BT.Real64) writer =
      let
        val (n0, n1) = PS.fromWord64 (IEEE754.dump64 value)
      in
        serializeUInt32 n0 writer;
        serializeUInt32 n1 writer
      end

  fun serializeReal32 (value : BT.Real32) writer =
      serializeUInt32 (IEEE754.dump32 value) writer

  (***************************************************************************)

  (** if the most significant bit of lower usedBytes bytes in UInt32 is set,
   * extends sign. *)
  fun extendsSign 4 (word : BT.UInt32) = word
    | extendsSign usedBytes word =
      let
        val (checkWord, maskWord) =
            case usedBytes of
              1 => (0wx80, 0wxFFFFFF00)
            | 2 => (0wx8000, 0wxFFFF0000)
            | 3 => (0wx800000, 0wxFF000000)
            | _ => raise Fail ("why ? " ^ Int.toString usedBytes)
      in
        if 0w0 = BT.UInt32.andb (word, checkWord)
        then word
        else BT.UInt32.orb (word, maskWord)
      end

  fun deserializeUInt8 reader =
      (BT.UInt32ToUInt8 o PS.readBytes 1) reader
  fun deserializeSInt8 reader =
      (BT.SInt32ToSInt8 o BT.UInt32ToSInt32 o extendsSign 1 o PS.readBytes 1)
          reader
  fun deserializeUInt16 reader = (BT.UInt32ToUInt16 o PS.readBytes 2) reader
  fun deserializeSInt16 reader =
      (BT.SInt32ToSInt16 o BT.UInt32ToSInt32 o extendsSign 2 o PS.readBytes 2)
          reader
  fun deserializeUInt24 reader = (BT.UInt32ToUInt24 o PS.readBytes 3) reader
  fun deserializeSInt24 reader =
      (BT.SInt32ToSInt24 o BT.UInt32ToSInt32 o extendsSign 3 o PS.readBytes 3)
          reader
  fun deserializeUInt32 reader = PS.readBytes 4 reader
  fun deserializeSInt32 reader = (BT.UInt32ToSInt32 o PS.readBytes 4) reader
  fun deserializeReal64 reader = 
      IEEE754.load64
          (PS.toWord64 (PS.readBytes 4 reader, PS.readBytes 4 reader))

  fun deserializeReal32 reader = IEEE754.load32 (PS.readBytes 4 reader)

  (***************************************************************************)

end