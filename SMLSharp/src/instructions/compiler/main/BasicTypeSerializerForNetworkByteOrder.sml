(**
 * This module serializes/deserializes byte array in which values are
 * embedded in the network byte order
 * @author YAMATODANI Kiyoshi
 * @version $Id: BasicTypeSerializerForNetworkByteOrder.sml,v 1.1 2005/12/31 12:34:00 kiyoshiy Exp $
 *)
structure BasicTypeSerializerForNetworkByteOrder : BASIC_TYPE_SERIALIZER =
          BasicTypeSerializerBase(PrimitiveSerializerBigEndian)
