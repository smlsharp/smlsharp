_interface "./thread_smlsharp.smi"

type pthread_t = unit ptr
val 'a#boxed pthread_create =
    _import "pthread_create"
    : (pthread_t array, unit ptr, 'a -> unit ptr, 'a) -> int
val pthread_join =
    _import "pthread_join" : (pthread_t, unit ptr array) -> int

structure Thread =
struct
  val threadtype = "pthread"
  type thread = pthread_t * (unit -> int)
  fun create_main (f : unit -> int) : unit ptr =
      SMLSharp_Builtin.Pointer.fromWord64
        (SMLSharp_Builtin.Word32.toWord64X
           (SMLSharp_Builtin.Word32.fromInt32
              (f ())))
      handle _ => SMLSharp_Builtin.Pointer.null ()
  fun create (f : unit -> int) =
      let val a = SMLSharp_Builtin.Array.alloc_unsafe 1
          val r = pthread_create
                    (a, SMLSharp_Builtin.Pointer.null (), create_main, f)
      in if r <> 0 then raise Fail "pthread_create failed" else ();
         (SMLSharp_Builtin.Array.sub_unsafe (a, 0), f)
      end
  fun join ((t,f):thread) =
      let
        val p = SMLSharp_Builtin.Array.alloc_unsafe 1
        val r = pthread_join (t, p)
      in
        if r <> 0 then raise Fail "pthread_join failed" else ();
        SMLSharp_Builtin.Pointer.keepAlive f;
        SMLSharp_Builtin.Word32.toInt32X
          (SMLSharp_Builtin.Word64.toWord32
             (SMLSharp_Builtin.Pointer.toWord64
                (SMLSharp_Builtin.Array.sub_unsafe (p, 0))))
      end
end
