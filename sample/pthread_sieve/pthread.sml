(**
 * pthread.sml
 *
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *
 * NOTE: Thread support is only available in native compile mode.
 *)

structure Pthread :> sig

  type pthread_t
  type pthread_mutex_t
  type pthread_cond_t

  val new_pthread_mutex_t : unit -> pthread_mutex_t
  val new_pthread_cond_t : unit -> pthread_cond_t

  val pthread_join : pthread_t * unit ptr ref -> int
  val pthread_mutex_init : pthread_mutex_t * unit ptr -> int
  val pthread_mutex_lock : pthread_mutex_t -> int
  val pthread_mutex_unlock : pthread_mutex_t -> int
  val pthread_cond_init : pthread_cond_t * unit ptr -> int
  val pthread_cond_wait : pthread_cond_t * pthread_mutex_t -> int
  val pthread_cond_signal : pthread_cond_t -> int

  val create : (unit ptr -> unit ptr) -> pthread_t

end =
struct

  type pthread_t = unit ptr   (* ToDo: system dependent *)

  val sizeof_pthread_mutex_t = 124  (* ToDo: system dependent *)
  val sizeof_pthread_cond_t = 124  (* ToDo: system dependent *)

  type pthread_mutex_t = Word8Array.array
  type pthread_cond_t = Word8Array.array

  fun new_pthread_t_ref () = ref (Pointer.NULL () : unit ptr)
  fun new_pthread_mutex_t () =
      Word8Array.array (sizeof_pthread_mutex_t, 0w0) : pthread_mutex_t
  fun new_pthread_cond_t () =
      Word8Array.array (sizeof_pthread_cond_t, 0w0) : pthread_cond_t

  val pthread_create =
      _import "pthread_create"
      : (pthread_t ref, unit ptr, unit ptr -> unit ptr, unit ptr) -> int
  val pthread_join =
      _import "pthread_join"
      : (pthread_t, unit ptr ref) -> int
  val pthread_mutex_init =
      _import "pthread_mutex_init"
      : (pthread_mutex_t, unit ptr) -> int
  val pthread_mutex_lock =
      _import "pthread_mutex_lock"
      : __attribute__((suspend)) pthread_mutex_t -> int
  val pthread_mutex_unlock =
      _import "pthread_mutex_unlock"
      : pthread_mutex_t -> int
  val pthread_cond_init =
      _import "pthread_cond_init"
      : (pthread_cond_t, unit ptr) -> int
  val pthread_cond_wait =
      _import "pthread_cond_wait"
      : __attribute__((suspend))
        (pthread_cond_t, pthread_mutex_t) -> int
  val pthread_cond_signal =
      _import "pthread_cond_signal"
      : pthread_cond_t -> int

  fun create f =
      let
        val ret = ref _NULL
        val err = pthread_create (ret, _NULL, f, _NULL)
        val ref th = ret
      in
        if err = 0 then () else raise Fail "pthread_create";
        th
      end

end
