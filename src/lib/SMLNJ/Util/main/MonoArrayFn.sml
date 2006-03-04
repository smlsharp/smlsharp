(* mono-array-fn.sml
 *
 * COPYRIGHT (c) 1997 Bell Labs, Lucent Technologies.
 *
 * This simple functor allows easy construction of new monomorphic array
 * structures.
 *)

functor MonoArrayFn (type elem) :> MONO_ARRAY where type elem = elem
  = struct
    open Array
    type elem = elem
    type array = elem Array.array
    type vector = elem Vector.vector
  end

