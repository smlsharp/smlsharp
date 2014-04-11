(**
 * pthread.sml
 *
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *
 * NOTE: Thread support is only available in native compile mode.
 *)

structure Pthread =
struct
  type pthread_t = unit ptr   (* ToDo: system dependent *)
  val pthread_create =
      _import "pthread_create"
      : (pthread_t ref, unit ptr, unit ptr -> unit ptr, unit ptr) -> int
  val pthread_join =
      _import "pthread_join"
      : __attribute__((suspend)) (pthread_t, unit ptr ref) -> int
  fun create f =
      let
        val ret = ref _NULL
        val err = pthread_create (ret, _NULL, f, _NULL)
        val ref th = ret
      in
        if err = 0 then () else raise Fail "pthread_create";
        th
      end
   fun join t =
       let
         val dummy = ref (Pointer.NULL () : unit ptr)
       in
         pthread_join (t, dummy)
       end         
end
