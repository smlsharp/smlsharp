(**
 * declaration of serialize and deserialize functions for basic types.
 * @author YAMATODANI Kiyoshi
 * @version $Id: BASIC_TYPE_SERIALIZER.sig,v 1.1 2005/12/31 12:33:59 kiyoshiy Exp $
 *)
signature BASIC_TYPE_SERIALIZER =
sig

  (***************************************************************************)
  
  type reader = unit -> Word8.word
  type writer = Word8.word -> unit

  type 't serializer = 't -> writer -> unit
  type 't deserializer = reader -> 't

  (***************************************************************************)

  (** the byte order which this serializer assumes. *)
  val byteOrder : SystemDefTypes.byteOrder

  val serializeUInt8 : BasicTypes.UInt8 serializer
  val serializeSInt8 : BasicTypes.SInt8 serializer
  val serializeUInt16 : BasicTypes.UInt16 serializer
  val serializeSInt16 : BasicTypes.SInt16 serializer
  val serializeUInt24 : BasicTypes.UInt24 serializer
  val serializeSInt24 : BasicTypes.SInt24 serializer
  val serializeUInt32 : BasicTypes.UInt32 serializer
  val serializeSInt32 : BasicTypes.SInt32 serializer
  val serializeReal64 : BasicTypes.Real64 serializer

  val deserializeUInt8 : BasicTypes.UInt8 deserializer
  val deserializeSInt8 : BasicTypes.SInt8 deserializer
  val deserializeUInt16 : BasicTypes.UInt16 deserializer
  val deserializeSInt16 : BasicTypes.SInt16 deserializer
  val deserializeUInt24 : BasicTypes.UInt24 deserializer
  val deserializeSInt24 : BasicTypes.SInt24 deserializer
  val deserializeUInt32 : BasicTypes.UInt32 deserializer
  val deserializeSInt32 : BasicTypes.SInt32 deserializer
  val deserializeReal64 : BasicTypes.Real64 deserializer

  (***************************************************************************)

end