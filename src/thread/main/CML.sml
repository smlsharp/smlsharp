(**
 * Concurrent ML library
 * @author UENO Katsuhiro
 * @copyright (c) 2017 Tohoku University
 *)
(* ToDo: garbage collection of threads *)

structure CML =
struct

  (* structure Cond = Myth.Cond *)
  structure Mutex = Myth.Mutex
  structure Thread = Concurrent.Thread
  structure Ivar = Concurrent.Ivar
  structure Couple = Concurrent.Couple
  structure Future = Concurrent.Future
  val yield = Thread.yield

  (*
  val m = Mutex.create ()
  fun print x = (Mutex.lock m; TextIO.print x; Mutex.unlock m)
  *)

  structure Gate :> sig
    type gate
    val create : unit -> gate
    val gate : gate -> bool
  end =
  struct
    type gate = {m : Mutex.mutex, b : bool ref}
    fun create () = {m = Mutex.create (), b = ref true}
    fun gate {m, b} = (Mutex.lock m; !b before (b := false; Mutex.unlock m))
  end

  exception Kill
  exception Never
  type 'a pipe = ('a option, bool) Couple.couple
  type 'a chan = ('a pipe, unit) Couple.couple
  type withnack_id = unit ref
  type pass = withnack_id list Ivar.var
  type path = pass * withnack_id list
  type 'a event = path -> Gate.gate -> 'a option
  type thread_id = unit event ref

  fun channel () = Couple.create () : 'a chan

  fun sendEvt (ch, v) (_:path) gate =
      case Ivar.get (Couple.left (ch, Couple.create ())) of
        (c, ()) =>
        case Gate.gate gate of
          false => (Couple.left (c, NONE); raise Kill)
        | true =>
          case Ivar.get (Couple.left (c, SOME v)) of
            (_, false) => NONE
          | (_, true) => SOME ()

  fun recvEvt ch (_:path) gate =
      case Ivar.get (Couple.right (ch, ())) of
        (c, ()) =>
        case Gate.gate gate of
          false => (Couple.right (c, false); raise Kill)
        | true => #1 (Ivar.get (Couple.right (c, true)))

  fun alwaysEvt x (_:path) gate =
      if Gate.gate gate then SOME x else raise Kill

  fun never (_:path) (_:Gate.gate) : 'a option =
      raise Never

  fun nackEvent (pass, self) (_:path) gate =
      if List.exists (fn x => x = self) (Ivar.get pass)
      then raise Never
      else if Gate.gate gate then SOME () else raise Kill

  fun guard (f : unit -> 'a event) path =
      let
        val f = Future.spawn (fn () => (f () handle _ => never) path)
      in
        fn gate => Future.sync f gate
      end

  fun wrap (event : 'a event, f) path =
      let val e = event path in fn gate => Option.map f (e gate) end

  fun withNack (f : unit event -> 'a event) ((pass, ids):path) =
      let
        val id = ref ()
        val ids = id::ids
        val f = Future.spawn
                  (fn () => (f (nackEvent (pass, id)) handle _ => never)
                              (pass, ids))
      in
        fn gate =>
           case Future.sync f gate of
             NONE => NONE
           | x => (Ivar.set (pass, ids); x)
      end

  fun choose nil = never
    | choose [event] = event
    | choose events =
      fn path =>
         let
           val events = map (fn e => e path) events
         in
           fn gate =>
              let
                val ret = Ivar.create ()
                fun t e () = (yield (); Ivar.set (ret, e gate); ())
              in
                app (fn e => Thread.spawn (t e)) events;
                Ivar.get ret
              end
         end

  fun sync event =
      let
        val pass = Ivar.create ()
        fun loop ev =
            case ev (Gate.create ()) of
              NONE => (yield (); loop ev)
            | SOME v => v
      in
        loop (event (pass, nil)) before (Ivar.set (pass, nil); ())
      end

  fun send x = sync (sendEvt x)
  fun recv x = sync (recvEvt x)
  fun select x = sync (choose x)

  fun joinEvent finished (_:path) gate =
      let
        val x = Ivar.get finished
      in
        if Gate.gate gate then SOME x else raise Kill
      end

  fun spawn f =
      let
        val v = Ivar.create ()
      in
        Thread.spawn (fn () => (f () handle _ => (); Ivar.set (v, ()); ()));
        ref (joinEvent v)
      end

  fun spawnc f x = spawn (fn () => f x)

  fun joinEvt (ref x : thread_id) = x

  fun futureEvt f =
      let
        val v = Ivar.create ()
      in
        Future.wrap (f, fn x => (Ivar.set (v, x); ()));
        joinEvent v
      end

end
