include "basis/main/CHAR.sig"
include "basis/main/STRING.sig"
include "basis/main/SUBSTRING.sig"
include "basis/main/MONO_VECTOR.sig"
include "basis/main/MONO_ARRAY.sig"
include "basis/main/MONO_VECTOR_SLICE.sig"
include "basis/main/MONO_ARRAY_SLICE.sig"

signature TEXT =
sig
  structure Char : CHAR
  structure String : STRING
  structure Substring : SUBSTRING
  structure CharVector : MONO_VECTOR
  structure CharArray : MONO_ARRAY
  structure CharVectorSlice : MONO_VECTOR_SLICE
  structure CharArraySlice : MONO_ARRAY_SLICE
  sharing type
      Char.char
    = String.char
    = Substring.char
    = CharVector.elem
    = CharArray.elem
    = CharVectorSlice.elem
    = CharArraySlice.elem
  sharing type
      Char.string
    = String.string
    = Substring.string
    = CharVector.vector
    = CharArray.vector
    = CharVectorSlice.vector
    = CharArraySlice.vector
  sharing type
      CharArray.array
    = CharArraySlice.array
  sharing type
      CharVectorSlice.slice
    = CharArraySlice.vector_slice
end
