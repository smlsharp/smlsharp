structure Socket : SOCKET =
struct
  open Orig_Socket

  type 'a buf = {buf:'a, i:int, sz:int option}

  val sendVec = fn (sock, {buf, i, sz}) =>
      sendVec (sock, Word8VectorSlice.slice (buf, i, sz))
  val sendArr = fn (sock, {buf, i, sz}) =>
      sendArr (sock, Word8ArraySlice.slice (buf, i, sz))
  val sendVec' = fn (sock, {buf, i, sz}, flags) =>
      sendVec' (sock, Word8VectorSlice.slice (buf, i, sz), flags)
  val sendArr' = fn (sock, {buf, i, sz}, flags) =>
      sendArr' (sock, Word8ArraySlice.slice (buf, i, sz), flags)
  val sendVecTo = fn (sock, addr : 'a sock_addr, {buf, i, sz}) =>
      (sendVecTo (sock, addr, Word8VectorSlice.slice (buf, i, sz)); 0)
  val sendArrTo = fn (sock, addr, {buf, i, sz}) =>
      (sendArrTo (sock, addr, Word8ArraySlice.slice (buf, i, sz)); 0)
  val sendVecTo' = fn (sock, addr, {buf, i, sz}, flags) =>
      (sendVecTo' (sock, addr, Word8VectorSlice.slice (buf, i, sz), flags); 0)
  val sendArrTo' = fn (sock, addr, {buf, i, sz}, flags) =>
      (sendArrTo' (sock, addr, Word8ArraySlice.slice (buf, i, sz), flags); 0)
  val recvArr = fn (sock, {buf, i, sz}) =>
      recvArr (sock, Word8ArraySlice.slice (buf, i, sz))
  val recvArr' = fn (sock, {buf, i, sz}, flags) =>
      recvArr' (sock, Word8ArraySlice.slice (buf, i, sz), flags)
  val recvArrFrom = fn (sock, {buf, i}) =>
      recvArrFrom (sock, Word8ArraySlice.slice (buf, i, NONE))
  val recvArrFrom' = fn (sock, {buf, i}, flags) =>
      recvArrFrom' (sock, Word8ArraySlice.slice (buf, i, NONE), flags)

end
