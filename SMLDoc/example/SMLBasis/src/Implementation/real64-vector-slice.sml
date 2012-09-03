(*  real64-vector-slice.sml
 *
 * Copyright (c) 2003 by The Fellowship of SML/NJ
 *
 * Author: Matthias Blume (blume@tti-c.org)
 *)
structure Real64VectorSlice :> MONO_VECTOR_SLICE
			           where type elem = real
				   where type vector = Real64Vector.vector
= struct

    open VectorSlice

    type elem = real
    type vector = Real64Vector.vector
    type slice = elem VectorSlice.slice
end
