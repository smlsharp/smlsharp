structure Byte : BYTE =
struct
  open Orig_Byte

  val unpackString = fn arg => unpackString (Word8ArraySlice.slice arg)
  val unpackStringVec = fn arg => unpackStringVec (Word8VectorSlice.slice arg)
end
