(**
 * IO structure.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "IO.smi"

structure IO :> IO =
struct
  datatype buffer_mode = NO_BUF | LINE_BUF | BLOCK_BUF
  exception Io of {name : string, function : string, cause : exn}
  exception BlockingNotSupported
  exception NonblockingNotSupported
  exception RandomAccessNotSupported
  exception TerminatedStream
  exception ClosedStream
end
