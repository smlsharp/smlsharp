(**
 * TextIO structure.
 * @author AT&T Research
 * @author YAMATODANI Kiyoshi
 * @version $Id: TextIO.sml,v 1.1 2005/08/14 09:36:18 kiyoshiy Exp $
 *)
(* text-io.sml
 *
 * COPYRIGHT (c) 1996 AT&T Research.
 *
 * The implementation of the TextIO stack on Posix systems.
 *
 *)
structure TextIO
          :> TEXT_IO
                 where type StreamIO.reader = TextPrimIO.reader
                 where type StreamIO.writer = TextPrimIO.writer
                 where type StreamIO.pos = TextPrimIO.pos
          = TextIOFn (structure OSPrimIO = TextOSPrimIO);

