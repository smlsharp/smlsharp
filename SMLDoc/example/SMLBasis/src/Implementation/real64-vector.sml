(* real64-vector.sml
 *
 * COPYRIGHT (c) 1997 Bell Labs, Lucent Technologies.
 *
 * Vectors of Real64.real values.
 * NOTE: currently, we do not have sufficient tag bits to use a packed
 * representation for this type.
 *)

structure Real64Vector : MONO_VECTOR
    where type elem = Real64.real
  = struct
    type elem = Real64.real
    type vector = elem Vector.vector
    
    val maxLen = Vector.maxLen

    val fromList = Vector.fromList
    val tabulate = Vector.tabulate

    val length   = Vector.length
    val sub      = Vector.sub
    val update   = Vector.update
    val concat   = Vector.concat

    val appi   = Vector.appi
    val app    = Vector.app
    val mapi   = Vector.mapi
    val map    = Vector.map
    val foldli = Vector.foldli
    val foldri = Vector.foldri
    val foldl  = Vector.foldl
    val foldr  = Vector.foldr

    val findi   = Vector.findi
    val find    = Vector.find
    val exists  = Vector.exists
    val all     = Vector.all
    val collate = Vector.collate

  end
