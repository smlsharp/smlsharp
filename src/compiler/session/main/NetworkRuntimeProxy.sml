structure NetworkRuntimeProxy : RUNTIME_PROXY =
struct

  (***************************************************************************)

  structure RPT = RuntimeProxyTypes

  (***************************************************************************)

  type InitialParameter =
       {
         runtimePath : string,
         arguments : string list,
         port : int
       }

  (***************************************************************************)

  fun initialize ({runtimePath, arguments, port} : InitialParameter) =
      let
        val command =
            runtimePath
            ^ " -heap " ^ (Int.toString (!Control.VMHeapSize))
            ^ " -stack " ^ (Int.toString (!Control.VMStackSize))
            ^ " -client " ^ (Int.toString port)
            ^ concat (map (fn arg => " " ^ arg) arguments)
        val _ = if OS.Process.system command = OS.Process.success
                then ()
                else raise RPT.Error ("Runtime cannot run.:" ^ command)
        val (runtimeInputChannel, runtimeOutputChannel) =
            ServerSocketChannel.openInOut {port = port}
        fun sendInterrupt () =
            (print "interruption is not supported.\n")
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