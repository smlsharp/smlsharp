(**
 * This module is compiled only when native byte order is little endian.
 * @author YAMATODANI Kiyoshi
 * @version $Id: BasicTypeSerializer_ForLittleEndian.sml,v 1.1 2005/12/31 12:34:00 kiyoshiy Exp $
 *)
structure BasicTypeSerializer : BASIC_TYPE_SERIALIZER =
          BasicTypeSerializerBase(PrimitiveSerializerLittleEndian)
