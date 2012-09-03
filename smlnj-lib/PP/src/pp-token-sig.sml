(* pp-token-sig.sml
 *
 * COPYRIGHT (c) 1997 Bell Labs, Lucent Technologies.
 *
 * User-defined pretty-printer tokens.
 *)

signature PP_TOKEN =
  sig
    type token
    type style

    val string : token -> string
    val style  : token -> style
    val size   : token -> int

  end;

