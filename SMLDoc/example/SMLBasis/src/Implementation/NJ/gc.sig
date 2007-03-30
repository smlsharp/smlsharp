(* gc.sig
 *
 * COPYRIGHT (c) 1997 AT&T Labs Research.
 *
 * Garbage collector control and stats.
 *)

signature GC =
  sig

    val doGC : int -> unit
    val messages : bool -> unit

  end


