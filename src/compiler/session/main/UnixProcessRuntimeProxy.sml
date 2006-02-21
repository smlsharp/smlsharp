(**
 * Copyright (c) 2006, Tohoku University.
 *)
structure UnixProcessRuntimeProxy : RUNTIME_PROXY =
struct

  (***************************************************************************)

  structure P = Posix

  (***************************************************************************)

  type InitialParameter = {runtimePath : string}

  (***************************************************************************)

  (** the signal which is sent to the IML runtime process to stop the
   * execution. *)
  val InterruptSignal = P.Signal.int

  fun sendSignal signal pid =
      P.Process.kill
          (P.Process.K_PROC pid, P.Signal.fromWord signal)

  fun initialize ({runtimePath} : InitialParameter) =
      let
        val processIDRef = ref NONE
        val (runtimeInputChannel, runtimeOutputChannel) =
            UnixProcessChannel.openProcess
                {fileName = runtimePath, processIDRef = processIDRef}
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
