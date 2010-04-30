(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: YAUnixProcessRuntimeProxy.sml,v 1.1 2008/01/10 04:43:12 katsu Exp $
 *)
structure YAUnixProcessRuntimeProxy : RUNTIME_PROXY =
struct

  (***************************************************************************)

  structure P = Posix

  (***************************************************************************)

  type InitialParameter = {runtimePath : string, arguments : string list}

  (***************************************************************************)

  (** the signal which is sent to the IML runtime process to stop the
   * execution. *)
  val InterruptSignal = P.Signal.int

  fun sendSignal signal pid =
      P.Process.kill
          (P.Process.K_PROC pid, P.Signal.fromWord signal)

  fun initialize ({runtimePath, arguments} : InitialParameter) =
      let
        val processIDRef = ref NONE
        val (runtimeInputChannel, runtimeOutputChannel) =
            YAUnixProcessChannel.openProcess
                {
                  fileName = runtimePath,
                  processIDRef = processIDRef,
                  arguments = arguments
                }
        fun sendInterrupt () = 
            sendSignal
                (Posix.Signal.toWord InterruptSignal) 
                (valOf(! processIDRef))

        fun release () =
            (
              #close runtimeInputChannel ();
              #close runtimeOutputChannel ()
            )
      in
        {
          inputChannel = runtimeInputChannel,
          outputChannel = runtimeOutputChannel,
          sendInterrupt = sendInterrupt,
          release = release
        } : RuntimeProxyTypes.Proxy
      end

  (***************************************************************************)

end;
