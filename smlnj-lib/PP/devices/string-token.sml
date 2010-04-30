(* string-token.sml
 *
 * COPYRIGHT (c) 1998 Bell Labs, Lucent Technologies.
 *
 * A trivial implementation of tokens as strings w/o style information.
 *)

structure StringToken : PP_TOKEN =
  struct
    type style = unit
    type token = string
    fun string s = s
    fun style _ = ()
    fun size s = String.size s
  end
