(*
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)

structure TextIO =
struct
  open TextIO
  val inputLine =
      fn stream =>
         case inputLine stream of
           "" => NONE
         | line => SOME line
end;

structure OS =
struct
  open OS
  structure Path =
  struct
    open Path
    val mkAbsolute = fn {path, relativeTo} => mkAbsolute (path, relativeTo)
    val mkRelative = fn {path, relativeTo} => mkRelative (path, relativeTo)
  end
end