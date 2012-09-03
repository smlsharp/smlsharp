_interface "Byte.smi"

structure Byte : sig
  (* same as BYTE *)
  val byteToChar : SMLSharp.Word8.word -> char
  val charToByte : char -> SMLSharp.Word8.word
  val bytesToString : Word8Vector.vector -> string
  val stringToBytes : string -> Word8Vector.vector
  val unpackStringVec : Word8VectorSlice.slice -> string
  val unpackString : Word8ArraySlice.slice -> string
  val packString : Word8Array.array * int * Substring.substring -> unit
end =
struct
local
  infix 6 + -
  infix 4 <
  val op - = SMLSharp.Int.sub
  val op < = SMLSharp.Int.lt
in
  val byteToChar = SMLSharp.Word8.toChar
  val charToByte = SMLSharp.Word8.fromChar
  fun bytesToString x = x : string
  fun stringToBytes x = x : Word8Vector.vector
  val unpackStringVec = Word8VectorSlice.vector
  val unpackString = Word8ArraySlice.vector
  fun packString (dst, di, src) =
      let
        val (srcary, srcstart, srclen) = Substring.base src
        val dstlen = Word8Array.length dst
      in
        if di < 0 orelse dstlen < di orelse dstlen - di < srclen
        then raise Subscript
        else SMLSharp.PrimString.copy_unsafe
               (srcary, srcstart, dst, di, srclen)
      end
end
end (* Byte *)
