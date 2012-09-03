(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: NetworkRuntimeProxy.sml,v 1.5 2007/02/24 09:22:23 kiyoshiy Exp $
 *)
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
        val _ = if OS.Process.isSuccess (OS.Process.system command)
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
