structure S : sig
  type 'a t
  val f : unit -> 'a t
end =
struct
  type 'a t = int
  fun f () = 1 : 'a t
end
