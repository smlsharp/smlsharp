functor MonoArrayFn (
  Arg : sig
          structure Orig : Orig_MONO_ARRAY
          structure Slice : MONO_ARRAY_SLICE
          structure VectorSlice : MONO_VECTOR_SLICE
          sharing type Orig.elem = Slice.elem = VectorSlice.elem
          sharing type Orig.array = Slice.array
          sharing type Orig.vector = Slice.vector = VectorSlice.vector
          sharing type Slice.vector_slice = VectorSlice.slice
        end
) : MONO_ARRAY =
struct
  open Arg.Orig

  fun extract x = Arg.Slice.vector (Arg.Slice.slice x)

  fun copy {si, src, len, di, dst} =
      Arg.Slice.copy
      { src = Arg.Slice.slice (src, si, len),
        di = di,
        dst = dst }

  fun copyVec {si, src, len, di, dst} =
      Arg.Slice.copyVec
      { src = Arg.VectorSlice.slice (src, si, len),
        di = di,
        dst = dst }

  fun appi f (array, n, len) =
      Arg.Slice.appi (fn (m, i) => f (m + n, i))
                     (Arg.Slice.slice (array, n, len))

  fun foldli f z (array, n, len) =
      Arg.Slice.foldli (fn (m, i, z) => f (m + n, i, z))
                       z (Arg.Slice.slice (array, n, len))

  fun foldri f z (array, n, len) =
      Arg.Slice.foldri (fn (m, i, z) => f (m + n, i, z))
                       z (Arg.Slice.slice (array, n, len))

  fun modifyi f (array, n, len) =
      Arg.Slice.modifyi (fn (m, i) => f (m + n, i))
                        (Arg.Slice.slice (array, n, len))
end
