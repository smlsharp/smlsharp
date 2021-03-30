(**
 * IO
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)

structure IO =
struct
  datatype buffer_mode = NO_BUF | LINE_BUF | BLOCK_BUF
  exception Io of {name : string, function : string, cause : exn}
  exception BlockingNotSupported
  exception NonblockingNotSupported
  exception RandomAccessNotSupported
  exception TerminatedStream
  exception ClosedStream
end
