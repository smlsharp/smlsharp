
(**
 * base implementation of operand serializer.
 * @author YAMATODANI Kiyoshi
 * @version $Id: BasicTypeSerializerBase.sml,v 1.1 2005/12/31 12:34:00 kiyoshiy Exp $
 *)
functor BasicTypeSerializerBase(PrimitiveSerializer : PRIMITIVE_SERIALIZER)
        :> BASIC_TYPE_SERIALIZER =
struct

  (***************************************************************************)

  open BasicTypes
  open PrimitiveSerializer

  (***************************************************************************)

  type reader = unit -> Word8.word
  type writer = Word8.word -> unit

  type 't serializer = 't -> writer -> unit
  type 't deserializer = reader -> 't

  (***************************************************************************)

  val byteOrder = PrimitiveSerializer.byteOrder

  fun serializeUInt8 value writer = writer value
  fun serializeSInt8 value writer =
      serializeUInt8 (UInt32ToUInt8(SInt8ToUInt32(value))) writer
  fun serializeUInt16 value writer =
      writeLowBytes (UInt16ToUInt32 value, 2) writer
  fun serializeSInt16 value writer =
      writeLowBytes (SInt16ToUInt32 value, 2) writer
  fun serializeUInt24 value writer = 
      writeLowBytes (UInt24ToUInt32 value, 3) writer
  fun serializeSInt24 value writer =
      writeLowBytes (SInt24ToUInt32 value, 3) writer
  fun serializeUInt32 value writer = writeLowBytes (value, 4) writer
  fun serializeSInt32 value writer =
      serializeUInt32 (SInt32ToUInt32 value) writer
  fun serializeReal64 (value : Real64) writer =
      let
        val unsafeArray = (Unsafe.cast value) : Unsafe.Word8Array.array
        val _ =
            List.tabulate
            (
              8,
              fn index =>
                 let val byte = Unsafe.Word8Array.sub (unsafeArray, index)
                 in writer byte end
            )
      in
        ()
      end

  (***************************************************************************)

  (** if the most significant bit of lower usedBytes bytes in UInt32 is set,
   * extends sign. *)
  fun extendsSign 4 (word : UInt32) = word
    | extendsSign usedBytes word =
      let
        val (checkWord, maskWord) =
            case usedBytes of
              1 => (0wx80, 0wxFFFFFF00)
            | 2 => (0wx8000, 0wxFFFF0000)
            | 3 => (0wx800000, 0wxFF000000)
            | _ => raise Fail ("why ? " ^ Int.toString usedBytes)
      in
        if 0w0 = UInt32.andb (word, checkWord)
        then word
        else UInt32.orb (word, maskWord)
      end

  fun deserializeUInt8 reader =
      (UInt32ToUInt8 o (readBytes 1)) reader
  fun deserializeSInt8 reader =
      (SInt32ToSInt8 o UInt32ToSInt32 o (extendsSign 1) o (readBytes 1))
          reader
  fun deserializeUInt16 reader =
      (UInt32ToUInt16 o (readBytes 2)) reader
  fun deserializeSInt16 reader =
      (SInt32ToSInt16 o UInt32ToSInt32 o (extendsSign 2) o (readBytes 2))
          reader
  fun deserializeUInt24 reader =
      (UInt32ToUInt24 o (readBytes 3)) reader
  fun deserializeSInt24 reader =
      (SInt32ToSInt24 o UInt32ToSInt32 o (extendsSign 3) o (readBytes 3))
          reader
  fun deserializeUInt32 reader = readBytes 4 reader
  fun deserializeSInt32 reader = (UInt32ToSInt32 o (readBytes 4)) reader
  fun deserializeReal64 reader = 
      let
        val unsafeArray = Unsafe.Word8Array.create 8
        val _ =
            List.tabulate
            (
              8,
              fn index =>
                 case reader () of
                   byte => Unsafe.Word8Array.update (unsafeArray, index, byte)
            )
        val value = (Unsafe.cast unsafeArray) : Real64
      in
        value
      end

  (***************************************************************************)

end