_interface "./thread_smlsharp.smi"

structure Thread =
struct
  val threadtype = "seq"
  type thread = {1: int}
  fun create (f : unit -> int) = {1 = f ()}
  fun join ({1=n} : thread) = n
end
