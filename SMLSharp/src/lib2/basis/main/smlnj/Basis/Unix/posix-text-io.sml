_interface "posix-text-io.smi"
(* text-io.sml
 *
 * COPYRIGHT (c) 1996 AT&T Research.
 *
 * The implementation of the TextIO stack on Posix systems.
 *
 *)

(*
structure TextIO :> TEXT_IO
    where type StreamIO.reader = TextPrimIO.reader
    where type StreamIO.writer = TextPrimIO.writer
    where type StreamIO.pos = TextPrimIO.pos
structure TextIO
  = TextIOFn (structure OSPrimIO = PosixTextPrimIO);
*)
structure SMLSharpSMLNJ_TextIO
  = SMLSharpSMLNJ_TextIOFn (structure OSPrimIO = SMLSharpSMLNJ_PosixTextPrimIO);

