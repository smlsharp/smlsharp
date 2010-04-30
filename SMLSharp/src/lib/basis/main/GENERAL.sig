(* general.sig
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

signature GENERAL =
  sig

    type unit = unit

    type exn = exn

    exception Bind
    exception Match
    exception Subscript
    exception Size
    exception Overflow
    exception Chr
    exception Div
    exception Domain
    exception Span

    exception Fail of string

    datatype order = LESS | EQUAL | GREATER

    val !  : 'a ref -> 'a
    val := : ('a ref * 'a) -> unit

    val o      : ('b -> 'c) * ('a -> 'b) -> ('a -> 'c)
    val before : ('a * unit) -> 'a
    val ignore : 'a -> unit

    val exnName : exn -> string
    val exnMessage: exn -> string

  end
