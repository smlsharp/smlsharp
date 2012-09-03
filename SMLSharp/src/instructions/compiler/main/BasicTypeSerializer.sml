(**
 * declaration of serialize and deserialize functions for basic types.
 * @author YAMATODANI Kiyoshi
 * @version $Id: BASIC_TYPE_SERIALIZER.sig,v 1.2 2007/01/10 09:43:44 katsu Exp $
 *)
structure BasicTypeSerializer : BASIC_TYPE_SERIALIZER =
struct

  type reader = unit -> Word8.word
  type writer = Word8.word -> unit
  type 't serializer = 't -> writer -> unit
  type 't deserializer = reader -> 't

  val byteOrder = Configuration.NativeByteOrder

  val (serializeUInt8,
       serializeSInt8,
       serializeUInt16,
       serializeSInt16,
       serializeUInt24,
       serializeSInt24,
       serializeUInt32,
       serializeSInt32,
       serializeReal32,
       serializeReal64,
       deserializeUInt8,
       deserializeSInt8,
       deserializeUInt16,
       deserializeSInt16,
       deserializeUInt24,
       deserializeSInt24,
       deserializeUInt32,
       deserializeSInt32,
       deserializeReal32,
       deserializeReal64) =
      case byteOrder of
        SystemDefTypes.BigEndian =>
        (BasicTypeSerializer_ForBigEndian.serializeUInt8,
         BasicTypeSerializer_ForBigEndian.serializeSInt8,
         BasicTypeSerializer_ForBigEndian.serializeUInt16,
         BasicTypeSerializer_ForBigEndian.serializeSInt16,
         BasicTypeSerializer_ForBigEndian.serializeUInt24,
         BasicTypeSerializer_ForBigEndian.serializeSInt24,
         BasicTypeSerializer_ForBigEndian.serializeUInt32,
         BasicTypeSerializer_ForBigEndian.serializeSInt32,
         BasicTypeSerializer_ForBigEndian.serializeReal32,
         BasicTypeSerializer_ForBigEndian.serializeReal64,
         BasicTypeSerializer_ForBigEndian.deserializeUInt8,
         BasicTypeSerializer_ForBigEndian.deserializeSInt8,
         BasicTypeSerializer_ForBigEndian.deserializeUInt16,
         BasicTypeSerializer_ForBigEndian.deserializeSInt16,
         BasicTypeSerializer_ForBigEndian.deserializeUInt24,
         BasicTypeSerializer_ForBigEndian.deserializeSInt24,
         BasicTypeSerializer_ForBigEndian.deserializeUInt32,
         BasicTypeSerializer_ForBigEndian.deserializeSInt32,
         BasicTypeSerializer_ForBigEndian.deserializeReal32,
         BasicTypeSerializer_ForBigEndian.deserializeReal64)
      | SystemDefTypes.LittleEndian =>
        (BasicTypeSerializer_ForLittleEndian.serializeUInt8,
         BasicTypeSerializer_ForLittleEndian.serializeSInt8,
         BasicTypeSerializer_ForLittleEndian.serializeUInt16,
         BasicTypeSerializer_ForLittleEndian.serializeSInt16,
         BasicTypeSerializer_ForLittleEndian.serializeUInt24,
         BasicTypeSerializer_ForLittleEndian.serializeSInt24,
         BasicTypeSerializer_ForLittleEndian.serializeUInt32,
         BasicTypeSerializer_ForLittleEndian.serializeSInt32,
         BasicTypeSerializer_ForLittleEndian.serializeReal32,
         BasicTypeSerializer_ForLittleEndian.serializeReal64,
         BasicTypeSerializer_ForLittleEndian.deserializeUInt8,
         BasicTypeSerializer_ForLittleEndian.deserializeSInt8,
         BasicTypeSerializer_ForLittleEndian.deserializeUInt16,
         BasicTypeSerializer_ForLittleEndian.deserializeSInt16,
         BasicTypeSerializer_ForLittleEndian.deserializeUInt24,
         BasicTypeSerializer_ForLittleEndian.deserializeSInt24,
         BasicTypeSerializer_ForLittleEndian.deserializeUInt32,
         BasicTypeSerializer_ForLittleEndian.deserializeSInt32,
         BasicTypeSerializer_ForLittleEndian.deserializeReal32,
         BasicTypeSerializer_ForLittleEndian.deserializeReal64)

end
