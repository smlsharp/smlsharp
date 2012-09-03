structure RealArray = MonoArrayFn (
  struct
    structure Orig = Orig_RealArray
    structure Slice = RealArraySlice
    structure VectorSlice = RealVectorSlice
  end
)
