functor MonoVectorFn (
  Arg : sig
          structure Orig : Orig_MONO_VECTOR
          structure Slice : MONO_VECTOR_SLICE
          sharing type Orig.elem = Slice.elem
          sharing type Orig.vector = Slice.vector
        end
) : MONO_VECTOR =
struct
  open Arg.Orig

  fun extract x = Arg.Slice.vector (Arg.Slice.slice x)

  fun appi f (array, n, len) =
      Arg.Slice.appi (fn (m, i) => f (m + n, i))
                     (Arg.Slice.slice (array, n, len))

  fun mapi f (array, n, len) =
      Arg.Slice.mapi (fn (m, i) => f (m + n, i))
                     (Arg.Slice.slice (array, n, len))

  fun foldli f z (array, n, len) =
      Arg.Slice.foldli (fn (m, i, z) => f (m + n, i, z))
                       z (Arg.Slice.slice (array, n, len))

  fun foldri f z (array, n, len) =
      Arg.Slice.foldri (fn (m, i, z) => f (m + n, i, z))
                       z (Arg.Slice.slice (array, n, len))

end
