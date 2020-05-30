_interface "./thread_smlsharp.smi"

type myth_thread_t = unit ptr
val 'a#boxed myth_create =
    _import "myth_create" : ('a -> unit ptr, 'a) -> myth_thread_t
val myth_join =
    _import "myth_join" : (myth_thread_t, unit ptr array) -> int

structure Thread =
struct
  val threadtype = "myth"
  type thread = myth_thread_t * (unit -> int)
  fun create_main (f : unit -> int) : unit ptr =
      SMLSharp_Builtin.Pointer.fromWord64
        (SMLSharp_Builtin.Word32.toWord64X
           (SMLSharp_Builtin.Word32.fromInt32
              (f ())))
      handle _ => SMLSharp_Builtin.Pointer.null ()
  fun create (f : unit -> int) =
      (myth_create (create_main, f), f) : thread
  fun join ((t,f):thread) =
      let
        val p = SMLSharp_Builtin.Array.alloc_unsafe 1
        val r = myth_join (t, p)
      in
        SMLSharp_Builtin.Pointer.keepAlive f;
        SMLSharp_Builtin.Word32.toInt32X
          (SMLSharp_Builtin.Word64.toWord32
             (SMLSharp_Builtin.Pointer.toWord64
                (SMLSharp_Builtin.Array.sub_unsafe (p, 0))))
      end
end
