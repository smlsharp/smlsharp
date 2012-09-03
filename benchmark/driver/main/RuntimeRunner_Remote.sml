(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: RuntimeRunner_Remote.sml,v 1.5 2005/10/24 07:28:23 kiyoshiy Exp $
 *)
structure RuntimeRunner_Remote : RUNTIME_RUNNER =
struct

  (***************************************************************************)

  structure CU = ChannelUtility
  structure U = Utility

  (***************************************************************************)
val heapSize = 40960000

  fun execute {executableFileName, outputChannel} =
      let
        val outputFileName = U.replaceExt "out" executableFileName
        val command =
            RuntimePath.runtimePath ^
            " -heap 8192000 " ^ 
            " -file " ^ executableFileName
            ^ " > " ^ outputFileName
            ^ " 2>&1 "
        val status = OS.Process.system command
      in
        U.finally
            (FileChannel.openIn {fileName = outputFileName})
            (fn inputChannel =>
                CU.copy (inputChannel, outputChannel))
            U.closeInputChannel;
        status
      end

  (***************************************************************************)

end
