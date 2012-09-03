structure ExecutablePath : sig
  val getPath : unit -> string option
end =
struct
  fun getPath () = NONE
end
