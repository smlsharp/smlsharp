structure Vector : VECTOR =
struct
  open Orig_Vector

  fun extract x = VectorSlice.vector (VectorSlice.slice x)

  fun mapi f (vector, n, len) =
      VectorSlice.mapi (fn (m, i) => f (m + n, i)) 
                       (VectorSlice.slice (vector, n, len))

  fun appi f (vector, n, len) =
      VectorSlice.appi (fn (m, i) => f (m + n, i)) 
                       (VectorSlice.slice (vector, n, len))

  fun foldli f z (vector, n, len) =
      VectorSlice.foldli (fn (m, i, z) => f (m + n, i, z))
                          z (VectorSlice.slice (vector, n, len))

  fun foldri f z (vector, n, len) =
      VectorSlice.foldri (fn (m, i, z) => f (m + n, i, z))
                          z (VectorSlice.slice (vector, n, len))

end
