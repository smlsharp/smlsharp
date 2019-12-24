(**
 * Utilities for concurrency
 * @author UENO Katsuhiro
 * @copyright (c) 2017 Tohoku University
 *)
structure Concurrent =
struct

  open Myth

  fun waitSome r cm =
      case !r of NONE => (Cond.wait cm; waitSome r cm) | SOME x => x
  fun waitNone r cm =
      case !r of NONE => () | SOME _ => (Cond.wait cm; waitNone r cm)

  (* P. S. Barth, R. S. Nikhil, Arvind, M-structures: Extending a
   * Parallel, Non-strict, Functional Langauge with State.  In Proc.
   * FPCA 1991, pp.538--568. *)
  structure Mvar :> sig
    type 'a var
    val create : unit -> 'a var
    val put : 'a var * 'a -> unit
    val take : 'a var -> 'a
  end =
  struct
    type 'a var = {m : Mutex.mutex, cp : Cond.cond, ct : Cond.cond,
                   v : 'a option ref}
    fun create () = {m = Mutex.create (), cp = Cond.create (),
                     ct = Cond.create (), v = ref NONE}
    fun put ({m,cp,ct,v},x) =
        (Mutex.lock m;
         waitNone v (cp, m);
         v := SOME x before (Cond.signal ct; Mutex.unlock m))
    fun take {m,cp,ct,v} =
        (Mutex.lock m;
         waitSome v (ct, m)
         before (v := NONE; Cond.signal cp; Mutex.unlock m))
  end

  (* Arvind, R. S. Nikhil, K.  K. Pingali, I-structures: Data Structures
   * for Parallel Computing, TOPLAS, vol.11, pp.598--632.
   *)
  structure Ivar :> sig
    type 'a var
    val create : unit -> 'a var
    val set : 'a var * 'a -> bool
    val get : 'a var -> 'a
  end =
  struct
    type 'a var = {m : Mutex.mutex, c : Cond.cond, v : 'a option ref}
    fun create () = {m = Mutex.create (), c = Cond.create (), v = ref NONE}
    fun set ({m,c,v},x) =
        (Mutex.lock m;
         (case !v of
            NONE => (v := SOME x; Cond.broadcast c; true)
          | SOME _ => false)
         before Mutex.unlock m)
    fun get {m,c,v} =
        (Mutex.lock m;
         waitSome v (c, m)
         before Mutex.unlock m)
  end

  structure Couple :> sig
    type ('a,'b) couple
    val create : unit -> ('a,'b) couple
    val left : ('a,'b) couple * 'a -> ('a * 'b) Ivar.var
    val right : ('a,'b) couple * 'b -> ('a * 'b) Ivar.var
  end =
  struct
    datatype ('a,'b) t =
        EMPTY
      | LEFT of ('a * 'b) Ivar.var * 'a
      | RIGHT of ('a * 'b) Ivar.var * 'b
    type ('a,'b) couple =
        {m : Mutex.mutex, cl : Cond.cond, cr : Cond.cond, v : ('a,'b) t ref}
    fun create () =
        {m = Mutex.create (), cl = Cond.create (), cr = Cond.create (),
         v = ref EMPTY}
    fun put m v f x =
        let val d = Ivar.create () in v := f (d, x); Mutex.unlock m; d end
    fun out m c v d x =
        (v := EMPTY; Cond.signal c; Mutex.unlock m; Ivar.set (d, x); d)
    fun leftLoop (w as {m,cl,cr,v}) x =
        case !v of
          LEFT _ => (Cond.wait (cl, m); leftLoop w x)
        | EMPTY => put m v LEFT x
        | RIGHT (d, y) => out m cr v d (x, y)
    fun left (w as {m,...}, x) =
        (Mutex.lock m; leftLoop w x)
    fun rightLoop (w as {m,cl,cr,v}) y =
        case !v of
          RIGHT _ => (Cond.wait (cr, m); rightLoop w y)
        | EMPTY => put m v RIGHT y
        | LEFT (d, x) => out m cl v d (x, y)
    fun right (w as {m,...}, y) =
        (Mutex.lock m; rightLoop w y)
  end

  structure Thread =
  struct

    val 'a#boxed sml_cmpswap =
        _import "sml_cmpswap" : __attribute__((fast)) ('a ref, 'a, 'a) -> int

    (* The list of closures that are to be used in a user thread to be
     * created but is not being used because the thread does not get
     * started.  This list saves such closures from garbage collection. *)
    val saved = ref nil : (unit -> unit) option ref list list ref

    fun save c =
        let
          val old = !saved
          val new = c :: old
        in
          case sml_cmpswap (saved, old, new) of 0 => save c | _ => ()
        end

    fun gc saved =
        let
          fun loop1 r nil = r : (unit -> unit) option ref list
            | loop1 r (ref NONE :: t) = loop1 r t
            | loop1 r (h :: t) = loop1 (h :: r) t
          fun loop2 r nil = r
            | loop2 r (h :: t) = loop2 (loop1 r h) t
        in
          loop2 nil saved
        end

    fun unsave () =
        let
          val new = nil : (unit -> unit) option ref list list
        in
          case !saved of
            nil => ()
          | old =>
            let val x = sml_cmpswap (saved, old, new)
            in case x of
              0 => ()
            | _ => case gc old of nil => () | l => save l
            end
        end

    fun spawn f =
        let
          val c = ref (SOME f)
        in
          Myth.Thread.create
            (fn () => (Myth.Thread.detach (Myth.Thread.self ());
                       c := NONE;
                       f () : unit;
                       0));
          ()
        end

    val yield = Myth.Thread.yield

  end

  structure Future :> sig
    type 'a future
    val spawn : (unit -> 'a) -> 'a future
    val wrap : 'a future * ('a -> 'b) -> 'b future
    val wrapHandle : 'a future * (exn -> 'a) -> 'a future
    val sync : 'a future -> 'a
  end =
  struct
    datatype 'a ret = RET of 'a | ERR of exn
    type 'a future = 'a ret Ivar.var
    fun spawn f =
        let
          val v = Ivar.create ()
        in
          Thread.spawn
            (fn () => (Ivar.set (v, RET (f ()) handle e => ERR e); ()));
          v
        end
    fun sync v =
        case Ivar.get v of
          RET x => x
        | ERR e => raise e
    fun wrap (v, f) =
        spawn (fn () => f (sync v))
    fun wrapHandle (v, f) =
        spawn (fn () => case Ivar.get v of RET x => x | ERR e => f e)
  end

end


