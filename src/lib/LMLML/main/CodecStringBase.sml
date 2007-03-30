functor CodecStringBase(P : PRIM_CODEC) : MB_STRING =
struct

  structure BV = Word8Vector
  structure BVS = Word8VectorSlice

  val toBytesSlice = P.encode

  val toBytes = BVS.vector o toBytesSlice

  val toString = Byte.bytesToString o toBytes

  val fromBytesSlice = P.decode

  val fromBytes = fromBytesSlice o BVS.full

  val fromString = fromBytes o Byte.stringToBytes

  val emptyString = fromString ""
(*
  fun convert toCodecName string =
      P.convert toCodecName string
      handle Codecs.ConverterNotFound =>
             let
               val fromCodecName = hd P.names
               val bytes = P.encode string
             IConv.conv {from = fromCodecName, to = toCodecName} 
*)
  structure S = StringBase(P)
  open S

  val fromAsciiString = implode o (List.map P.fromAsciiChar) o String.explode

  val toAsciiString = 
      String.implode
      o List.map (fn copt => Option.getOpt(P.toAsciiChar copt, #"?"))
      o explode

end