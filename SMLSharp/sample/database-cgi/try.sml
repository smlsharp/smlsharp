structure Try : sig
  type ('a, 'b) cont
  val try : (unit -> 'a) -> ('a,'b) cont -> 'b
  val finally : ('a, (unit -> unit) -> 'a) cont
end =
struct
  datatype 'a ret = RET of 'a | ERR of exn
  type ('a,'b) cont = 'a ret -> 'b
  fun try tryFn cont = cont (RET (tryFn ()) handle e => ERR e)
  fun finally (RET x) finalFn = (finalFn () : unit; x)
    | finally (ERR e) finalFn = (finalFn (); raise e)
end
