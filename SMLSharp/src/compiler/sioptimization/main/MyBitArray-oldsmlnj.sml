structure MyBitArray =
struct
  open BitArray

  fun appi f ary =
      BitArray.appi f (ary, 0, NONE)
  fun copy {di, dst, src} =
      BitArray.copy {di = di, dst = dst, src = src, len = NONE, si = 0}

end
