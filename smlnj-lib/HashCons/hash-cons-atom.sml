(* hash-cons-atom.sml
 *
 * COPYRIGHT (c) 2001 Bell Labs, Lucent Technologies
 *)

structure HashConsAtom = HashConsGroundFn (
  struct
    type hash_key = Atom.atom
    val sameKey = Atom.same
    val hashVal = Atom.hash
  end)
