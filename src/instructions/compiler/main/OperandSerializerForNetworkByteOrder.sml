(**
 * This module serializes/deserializes byte array in which values are embedded in the network byte order
 * @author YAMATODANI Kiyoshi
 * @version $Id: OperandSerializerForNetworkByteOrder.sml,v 1.1 2005/09/14 03:21:35 kiyoshiy Exp $
 *)
structure OperandSerializerForNetworkByteOrder : OPERAND_SERIALIZER =
OperandSerializerBase(PrimitiveSerializerBigEndian)
