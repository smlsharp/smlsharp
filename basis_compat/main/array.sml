structure Array : ARRAY =
struct
  open Orig_Array

  fun extract x = ArraySlice.vector (ArraySlice.slice x)

  fun copy {si, src, len, di, dst} =
      ArraySlice.copy
      { src = ArraySlice.slice (src, si, len),
        di = di,
        dst = dst }

  fun copyVec {si, src, len, di, dst} =
      ArraySlice.copyVec
      { src = VectorSlice.slice (src, si, len),
        di = di,
        dst = dst }

  fun appi f (array, n, len) =
      ArraySlice.appi (fn (m, i) => f (m + n, i)) 
                      (ArraySlice.slice (array, n, len))

  fun foldli f z (array, n, len) =
      ArraySlice.foldli (fn (m, i, z) => f (m + n, i, z))
                        z (ArraySlice.slice (array, n, len))

  fun foldri f z (array, n, len) =
      ArraySlice.foldri (fn (m, i, z) => f (m + n, i, z))
                        z (ArraySlice.slice (array, n, len))

  fun modifyi f (array, n, len) =
      ArraySlice.modifyi (fn (m, i) => f (m + n, i))
                         (ArraySlice.slice (array, n, len))

end
