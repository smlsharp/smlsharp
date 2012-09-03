(**
 * IO structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: IO.sml,v 1.1 2005/07/15 07:25:43 kiyoshiy Exp $
 *)
structure IO :> IO =
struct

  (***************************************************************************)

  datatype buffer_mode = NO_BUF | LINE_BUF | BLOCK_BUF

  (***************************************************************************)

  exception Io of {name : string, function : string, cause : exn}

  exception BlockingNotSupported

  exception NonblockingNotSupported

  exception RandomAccessNotSupported

  exception TerminatedStream

  exception ClosedStream

  (***************************************************************************)

end;
