structure Word8Array = MonoArrayFn (
  struct
    structure Orig = Orig_Word8Array
    structure Slice = Word8ArraySlice
    structure VectorSlice = Word8VectorSlice
  end
)
