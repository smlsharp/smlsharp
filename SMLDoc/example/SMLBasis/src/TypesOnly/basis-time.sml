(* basis-time.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * This is the basis Time structure with only the time type, so that the
 * basis signatures can compile.  It has to be in a separate file from
 * pre-basis-structs.sml, since it depends on the binding of LargeInt.
 *)

structure Time : TIME =
  struct
    datatype time = TIME of { usec : LargeInt.int }
  end;
