(**
 * Pthread binding
 * @author UENO Katsuhiro
 * @copyright (c) 2017 Tohoku University
 *)
structure Pthread :> sig

  type thread

  (* exception raised when a Pthread API reports an error *)
  exception Pthread

  structure Thread :
  sig
    type thread = thread
    val create : (unit -> int) -> thread
    val detach : thread -> unit
    val join : thread -> int
    val exit : int -> unit
    val self : unit -> thread
    val equal : thread * thread -> bool
  end

  type mutex
  structure Mutex :
  sig
    type mutex = mutex
    val create : unit -> mutex
    val lock : mutex -> unit
    val unlock : mutex -> unit
    val trylock : mutex -> bool
    val destroy : mutex -> unit
  end

  type cond
  structure Cond :
  sig
    type cond = cond
    val create : unit -> cond
    val signal : cond -> unit
    val broadcast : cond -> unit
    val wait : cond * mutex -> unit
    val destroy : cond -> unit
  end

end
=
struct

  type pthread_t = unit ptr

  val 'a#boxed pthread_create =
      _import "pthread_create"
      : (pthread_t array, unit ptr, 'a -> unit ptr, 'a) -> int
  val pthread_join =
      _import "pthread_join" : (pthread_t, unit ptr array) -> int
  val pthread_detach =
      _import "pthread_detach" : __attribute__((fast)) pthread_t -> int
  val pthread_exit =
      _import "pthread_exit" : unit ptr -> ()
  val pthread_self =
      _import "pthread_self" : __attribute__((fast)) () -> pthread_t
  val pthread_equal =
      _import "pthread_equal"
      : __attribute__((fast)) (pthread_t, pthread_t) -> int

  type pthread_mutex_t = word8 array
  type pthread_cond_t = word8 array
  (* 60 is enough for pthread_mutex_t and pthread_cond_t *)
  fun alloc () = SMLSharp_Builtin.Array.alloc_unsafe 60 : word8 array

  val pthread_mutex_init =
      _import "pthread_mutex_init"
      : __attribute__((fast)) (pthread_mutex_t, unit ptr) -> int
  val pthread_mutex_destroy =
      _import "pthread_mutex_destroy"
      : __attribute__((fast)) pthread_mutex_t -> int
  val pthread_mutex_lock =
      _import "pthread_mutex_lock"
      : pthread_mutex_t -> int
  val pthread_mutex_trylock =
      _import "pthread_mutex_trylock"
      : __attribute__((fast)) pthread_mutex_t -> int
  val pthread_mutex_unlock =
      _import "pthread_mutex_unlock"
      : __attribute__((fast)) pthread_mutex_t -> int

  val pthread_cond_init =
      _import "pthread_cond_init"
      : __attribute__((fast)) (pthread_cond_t, unit ptr) -> int
  val pthread_cond_destroy =
      _import "pthread_cond_destroy"
      : __attribute__((fast)) pthread_cond_t -> int
  val pthread_cond_signal =
      _import "pthread_cond_signal"
      : __attribute__((fast)) pthread_cond_t -> int
  val pthread_cond_broadcast =
      _import "pthread_cond_broadcast"
      : __attribute__((fast)) pthread_cond_t -> int
  val pthread_cond_wait =
      _import "pthread_cond_wait"
      : (pthread_cond_t, pthread_mutex_t) -> int

  exception Pthread

  fun err 0 = () | err _ = raise Pthread

  type mutex = pthread_mutex_t
  structure Mutex =
  struct
    type mutex = mutex
    fun create () =
        let val a = alloc ()
        in err (pthread_mutex_init (a, SMLSharp_Builtin.Pointer.null ())); a
        end
    fun lock m = err (pthread_mutex_lock m)
    fun trylock m = pthread_mutex_trylock m = 0
    fun unlock m = err (pthread_mutex_unlock m)
    fun destroy m = err (pthread_mutex_destroy m)
  end

  type cond = pthread_cond_t
  structure Cond =
  struct
    type cond = cond
    fun create () =
        let val a = alloc ()
        in err (pthread_cond_init (a, SMLSharp_Builtin.Pointer.null ())); a
        end
    fun signal c = err (pthread_cond_signal c)
    fun broadcast c = err (pthread_cond_broadcast c)
    fun wait (c, m) = err (pthread_cond_wait (c, m))
    fun destroy c = err (pthread_cond_destroy c)
  end

  type thread = pthread_t * (unit -> int)
  structure Thread =
  struct
    type thread = thread

    fun dummy () = 0

    fun self () = (pthread_self (), dummy) : thread

    fun detach ((t,f):thread) =
        let
          val r = pthread_detach t
        in
          SMLSharp_Builtin.Pointer.keepAlive f;
          err r
        end

    fun equal ((t1,f1):thread, (t2,f2):thread) =
        let
          val r = pthread_equal (t1, t2)
        in
          SMLSharp_Builtin.Pointer.keepAlive f1;
          SMLSharp_Builtin.Pointer.keepAlive f2;
          r <> 0
        end

    fun create_main (f : unit -> int) : unit ptr =
        SMLSharp_Builtin.Pointer.fromWord64
          (SMLSharp_Builtin.Word32.toWord64X
             (SMLSharp_Builtin.Word32.fromInt32
                (f ())))
        handle _ => SMLSharp_Builtin.Pointer.null ()

    fun create (f : unit -> int) =
        let
          val p = SMLSharp_Builtin.Array.alloc_unsafe 1
          val r = pthread_create (p, SMLSharp_Builtin.Pointer.null (),
                                  create_main, f)
          val t = SMLSharp_Builtin.Array.sub_unsafe (p, 0)
        in
          err r;
          (t, f) : thread
        end

    fun join ((t,f):thread) =
        let
          val p = SMLSharp_Builtin.Array.alloc_unsafe 1
          val r = pthread_join (t, p)
        in
          SMLSharp_Builtin.Pointer.keepAlive f;
          err r;
          SMLSharp_Builtin.Word32.toInt32X
            (SMLSharp_Builtin.Word64.toWord32
               (SMLSharp_Builtin.Pointer.toWord64
                  (SMLSharp_Builtin.Array.sub_unsafe (p, 0))))
        end

    fun exit n =
        pthread_exit
          (SMLSharp_Builtin.Pointer.fromWord64
             (SMLSharp_Builtin.Word32.toWord64X
                (SMLSharp_Builtin.Word32.fromInt32
                   n)))

  end

end
