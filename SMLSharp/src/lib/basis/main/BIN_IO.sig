(* bin-io.sig
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)
(**
 * BIN_IO signature
 * @version $Id: BIN_IO.sig,v 1.3 2005/07/29 14:14:09 kiyoshiy Exp $
 *)
signature BIN_IO =
  sig
    include IMPERATIVE_IO
            where type StreamIO.vector = Word8Vector.vector
            where type StreamIO.elem = Word8.word
            where type StreamIO.reader = BinPrimIO.reader
            where type StreamIO.writer = BinPrimIO.writer
            where type StreamIO.pos = BinPrimIO.pos

    val openIn     : string -> instream
    val openOut    : string -> outstream
    val openAppend : string -> outstream
  end
