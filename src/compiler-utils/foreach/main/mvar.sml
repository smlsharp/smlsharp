(**
 * mvar.sml (copied from sample for myth)
 *
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure MVar =
struct
  type 'a mvar =
       {mutex: Myth.mutex,
        cond: Myth.cond,
        content: 'a option ref}

  fun new () =
      let
        val mutex = Myth.Mutex.create ()
        val cond = Myth.Cond.create()
      in
        {mutex = mutex, cond = cond, content = ref NONE} : 'a mvar
      end

  fun waitUntil f (mvar as {mutex, cond, content}:'a mvar) =
      if f (!content) then ()
      else (Myth.Cond.wait (cond, mutex); waitUntil f mvar)

  fun put (mvar as {mutex, cond, content}:'a mvar, value) =
      (
        Myth.Mutex.lock mutex;
        waitUntil (not o isSome) mvar;
        content := SOME value;
        Myth.Cond.broadcast cond;
        Myth.Mutex.unlock mutex;
        ()
      )

  fun take (mvar as {mutex, cond, content}:'a mvar) =
      let
        val _ = Myth.Mutex.lock mutex
        val _ = waitUntil isSome mvar
        val ret = valOf (!content)
      in
        content := NONE;
        Myth.Cond.broadcast cond;
        Myth.Mutex.unlock mutex;
        ret
      end

  fun read (mvar as {mutex, cond, content}:'a mvar) =
      let
        val _ = Myth.Mutex.lock mutex
        val _ = waitUntil isSome mvar
        val ret = valOf (!content)
      in
        Myth.Mutex.unlock mutex;
        ret
      end

  fun isSome (mvar as {mutex, cond, content}:'a mvar) =
      let
        val _ = Myth.Mutex.lock mutex
        val ret = case !content of NONE => false | SOME _ => true
      in
        Myth.Cond.signal cond;
        Myth.Mutex.unlock mutex;
        ret
      end

end
