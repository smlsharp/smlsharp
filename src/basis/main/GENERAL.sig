signature GENERAL =
sig
  eqtype unit
  type exn = exn
  exception Bind
  exception Match
  exception Chr
  exception Div
  exception Domain
  exception Fail of string
  exception Overflow
  exception Size
  exception Span
  exception Subscript
  val exnName : exn -> string
  val exnMessage : exn -> string
  datatype order = datatype order
  val ! : 'a ref -> 'a
  val := : 'a ref * 'a -> unit
  val o : ('b -> 'c) * ('a -> 'b) -> 'a -> 'c
  val before : 'a * unit -> 'a
  val ignore : 'a -> unit
end
