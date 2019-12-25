(**
 * MassiveThreads binding
 * @author UENO Katsuhiro
 * @copyright (c) 2017 Tohoku University
 *)
structure Myth :> sig

  type thread

  (* exception raised when a massivethread API reports an error *)
  exception Myth

  structure Thread :
  sig
    type thread = thread

    (* Create a user thread.
     * To avoid memory leak, a thread created by this function must be
     * abandoned by either detach or join.
     * Uncaught exceptions in a user thread are ignored.
     *)
    val create : (unit -> int) -> thread

    (* Request to reclaim memory for the given thread when the thread
     * terminates. *)
    val detach : thread -> unit

    (* Wait until the given user thread terminates and reclaim memory
     * for the given thread.  Note that it cannot join with a detached 
     * or joined thread. *)
    val join : thread -> int

    (* Abort the current thread. *)
    val exit : int -> unit

    (* Yield control to other user thread. *)
    val yield : unit -> unit

    (* Obtain the thread id of current user thread *)
    val self : unit -> thread

    (* Compare two thread id *)
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

(*
   val bar = create n : n threadのバリアを作成
   wait bar : 現在のスレッドが，barでまつ；
              waitを呼ぶスレッドがバリアのサイズに達するまでwait
*)
  type barrier
  structure Barrier :
  sig
    type barrier = barrier
    val create : int -> barrier
    val wait : barrier -> bool
    val destroy : barrier -> unit
  end

end
=
struct

  type myth_thread_t = unit ptr

  val 'a#boxed myth_create =
      _import "myth_create" : ('a -> unit ptr, 'a) -> myth_thread_t
  val myth_join =
      _import "myth_join" : (myth_thread_t, unit ptr array) -> int
  val myth_detach =
      _import "myth_detach" : __attribute__((fast)) myth_thread_t -> int
  val myth_yield =
      _import "myth_yield" : () -> ()
  val myth_yield_ex =
      _import "myth_yield_ex" : int -> ()
  val myth_exit =
      _import "myth_exit" : unit ptr -> ()
  val myth_self =
      _import "myth_self" : __attribute__((fast)) () -> myth_thread_t
  val myth_equal =
      _import "myth_equal"
      : __attribute__((fast)) (myth_thread_t, myth_thread_t) -> int

  type myth_barrier_t = word8 array
  type myth_mutex_t = word8 array
  type myth_cond_t = word8 array
  (* 60 is enough for myth_mutex_t, myth_cond_t, and myth_barrier_t *)
  fun alloc () = SMLSharp_Builtin.Array.alloc_unsafe 60 : word8 array

  val myth_barrier_init =
      _import "myth_barrier_init"
      : __attribute__((fast)) (myth_barrier_t, unit ptr, word) -> int
  val myth_barrier_destroy =
      _import "myth_barrier_destroy"
      : __attribute__((fast)) myth_barrier_t -> int
  val myth_barrier_wait =
      _import "myth_barrier_wait"
      : myth_barrier_t -> int

  val myth_mutex_init =
      _import "myth_mutex_init"
      : __attribute__((fast)) (myth_mutex_t, unit ptr) -> int
  val myth_mutex_destroy =
      _import "myth_mutex_destroy"
      : __attribute__((fast)) myth_mutex_t -> int
  val myth_mutex_lock =
      _import "myth_mutex_lock"
      : myth_mutex_t -> int
  val myth_mutex_trylock =
      _import "myth_mutex_trylock"
      : __attribute__((fast)) myth_mutex_t -> int
  val myth_mutex_unlock =
      _import "myth_mutex_unlock"
      : __attribute__((fast)) myth_mutex_t -> int

  val myth_cond_init =
      _import "myth_cond_init"
      : __attribute__((fast)) (myth_cond_t, unit ptr) -> int
  val myth_cond_destroy =
      _import "myth_cond_destroy"
      : __attribute__((fast)) myth_cond_t -> int
  val myth_cond_signal =
      _import "myth_cond_signal"
      : __attribute__((fast)) myth_cond_t -> int
  val myth_cond_broadcast =
      _import "myth_cond_broadcast"
      : __attribute__((fast)) myth_cond_t -> int
  val myth_cond_wait =
      _import "myth_cond_wait"
      : (myth_cond_t, myth_mutex_t) -> int

  exception Myth

  fun err 0 = () | err _ = raise Myth

  type mutex = myth_mutex_t
  structure Mutex =
  struct
    type mutex = mutex
    fun create () =
        let val a = alloc ()
        in err (myth_mutex_init (a, SMLSharp_Builtin.Pointer.null ())); a
        end
    fun lock m = err (myth_mutex_lock m)
    fun trylock m = myth_mutex_trylock m = 0
    fun unlock m = err (myth_mutex_unlock m)
    fun destroy m = err (myth_mutex_destroy m)
  end

  type cond = myth_cond_t
  structure Cond =
  struct
    type cond = cond
    fun create () =
        let val a = alloc ()
        in err (myth_cond_init (a, SMLSharp_Builtin.Pointer.null ())); a
        end
    fun signal c = err (myth_cond_signal c)
    fun broadcast c = err (myth_cond_broadcast c)
    fun wait (c, m) = err (myth_cond_wait (c, m))
    fun destroy c = err (myth_cond_destroy c)
  end

  type barrier = myth_barrier_t
  structure Barrier =
  struct
    type barrier = barrier
    fun create n =
        let val a = alloc ()
            val n = Word.fromInt n
        in err (myth_barrier_init (a, SMLSharp_Builtin.Pointer.null (), n)); a
        end
    fun wait b = let val n = myth_barrier_wait b
                 in n = 1 orelse (err n; true)
                 end
    fun destroy b = err (myth_barrier_destroy b)
  end

  type thread = myth_thread_t * (unit -> int)
  structure Thread =
  struct
    type thread = thread

    fun dummy () = 0

    fun self () = (myth_self (), dummy) : thread

    val yield = myth_yield

    fun detach ((t,f):thread) =
        let
          val r = myth_detach t
        in
          SMLSharp_Builtin.Pointer.keepAlive f;
          err r
        end

    fun equal ((t1,f1):thread, (t2,f2):thread) =
        let
          val r = myth_equal (t1, t2)
        in
          SMLSharp_Builtin.Pointer.keepAlive f1;
          SMLSharp_Builtin.Pointer.keepAlive f2;
          r <> 0
        end

    fun create_main (f : unit -> int) =
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
          err r;
          SMLSharp_Builtin.Word32.toInt32X
            (SMLSharp_Builtin.Word64.toWord32
               (SMLSharp_Builtin.Pointer.toWord64
                  (SMLSharp_Builtin.Array.sub_unsafe (p, 0))))
        end

    fun exit n =
        myth_exit
          (SMLSharp_Builtin.Pointer.fromWord64
             (SMLSharp_Builtin.Word32.toWord64X
                (SMLSharp_Builtin.Word32.fromInt32
                   n)))

  end

end
