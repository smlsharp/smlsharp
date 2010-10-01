(**
 * This module is compiled only when native byte order is big endian.
 * @author YAMATODANI Kiyoshi
 * @version $Id: BasicTypeSerializer_ForBigEndian.sml,v 1.1 2005/12/31 12:34:00 kiyoshiy Exp $
 *)
structure BasicTypeSerializer_ForBigEndian : BASIC_TYPE_SERIALIZER =
          BasicTypeSerializerBase(PrimitiveSerializerBigEndian)
