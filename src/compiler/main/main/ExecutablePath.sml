structure ExecutablePath : sig

  val getPath : unit -> string option

end =
struct

  val executable_path =
      _import "prim_executable_path"
      : __attribute__((unsafe,fast,gc)) () -> string

  fun getPath () =
      case executable_path () of
        "" => NONE
      | x => SOME x

end
