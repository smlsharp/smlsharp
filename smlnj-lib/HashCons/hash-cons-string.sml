(* hash-cons-string.sml
 *
 * COPYRIGHT (c) 2001 Bell Labs, Lucent Technologies
 *)

structure HashConsString = HashConsGroundFn (
  struct
    type hash_key = string
    val sameKey = (op = : string * string -> bool)
    val hashVal = HashString.hashString
  end)
