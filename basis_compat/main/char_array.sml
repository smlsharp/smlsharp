structure CharArray = MonoArrayFn (
  struct
    structure Orig = Orig_CharArray
    structure Slice = CharArraySlice
    structure VectorSlice = CharVectorSlice
  end
)
