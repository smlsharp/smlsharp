include "Word8Vector.smi"
include "Word8VectorSlice.smi"
include "Word8Array.smi"

signature BYTE =
sig
  val byteToChar : SMLSharp.Word8.word -> char
  val charToByte : char -> SMLSharp.Word8.word
  val bytesToString : Word8Vector.vector -> string
  val stringToBytes : string -> Word8Vector.vector
  val unpackStringVec : Word8VectorSlice.slice -> string
  val unpackString : Word8ArraySlice.slice -> string
  val packString : Word8Array.array * int * substring -> unit
end
