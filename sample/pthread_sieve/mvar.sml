(**
 * mvar.sml
 *
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure MVar :> sig

  type 'a mvar
  val new : unit -> 'a mvar
  val put : 'a mvar * 'a -> unit
  val take : 'a mvar -> 'a

end =
struct

  type 'a mvar =
       {mutex: Pthread.pthread_mutex_t,
        cond: Pthread.pthread_cond_t,
        content: 'a option ref}

  fun new () =
      let
        val mutex = Pthread.new_pthread_mutex_t ()
        val _ = Pthread.pthread_mutex_init (mutex, Pointer.NULL ())
        val cond = Pthread.new_pthread_cond_t ()
        val _ = Pthread.pthread_cond_init (cond, Pointer.NULL ())
      in
        {mutex = mutex, cond = cond, content = ref NONE} : 'a mvar
      end

  fun waitUntil f (mvar as {mutex, cond, content}:'a mvar) =
      if f (!content) then ()
      else (Pthread.pthread_cond_wait (cond, mutex); waitUntil f mvar)

  fun put (mvar as {mutex, cond, content}:'a mvar, value) =
      (
        Pthread.pthread_mutex_lock mutex;
        waitUntil (not o isSome) mvar;
        content := SOME value;
        Pthread.pthread_cond_signal cond;
        Pthread.pthread_mutex_unlock mutex;
        ()
      )

  fun take (mvar as {mutex, cond, content}:'a mvar) =
      let
        val _ = Pthread.pthread_mutex_lock mutex
        val _ = waitUntil isSome mvar
        val ret = valOf (!content)
      in
        content := NONE;
        Pthread.pthread_cond_signal cond;
        Pthread.pthread_mutex_unlock mutex;
        ret
      end

end
