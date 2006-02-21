(* text-stream-io.sig
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

signature TEXT_STREAM_IO =
  sig
    include STREAM_IO
    val inputLine    : instream -> (string * instream) option
    val outputSubstr : (outstream * substring) -> unit
  end

