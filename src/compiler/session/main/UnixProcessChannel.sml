(**
 * Copyright (c) 2006, Tohoku University.
 *
 * implementation of channel on a sub process.
 * @author YAMATODANI Kiyoshi
 * @version $Id: UnixProcessChannel.sml,v 1.11 2006/02/18 04:59:28 ohori Exp $
 *)
structure UnixProcessChannel =
struct

  (***************************************************************************)

  structure P = Posix
  structure SU = SignalUtility
  structure Process = P.Process

  (***************************************************************************)

  type InitialParameter =
       {
         (** name of the executable file *)
         fileName : string,
         processIDRef : Process.pid option ref
       }

  (***************************************************************************)

  exception ProcessNotActive

  (***************************************************************************)

  val COMMANDARG = "-pipe" (* command option to server *)

  fun pidToString pid =
      Word32.toString(Process.pidToWord pid)

  fun openProcess {fileName, processIDRef} =
      let
          (* creta pipe *)
          val {outfd = parentOutFD, infd = childInFD} = P.IO.pipe();
          val {outfd = childOutFD, infd = parentInFD} = P.IO.pipe();
          val FDToString = (Word32.fmt StringCvt.DEC) o P.FileSys.fdToWord
          val (inFDString, outFDString) =
              (fn f=> (f childInFD,f childOutFD)) FDToString
          val {outFD, inFD, pid} = 
              (* fork *)
              case Process.fork () of
                  NONE => 
                  (* setup connection *)
                  (* exec *)
                  Process.exec
                      (
                        fileName,
                        [fileName, COMMANDARG, inFDString, outFDString]
                      )
                | SOME(pid) =>
                  (
                    P.IO.close childInFD;
                    P.IO.close childOutFD;
                    {outFD = parentOutFD, inFD = parentInFD, pid = pid}
                  )
val _ = print ("PID = " ^ pidToString pid ^ "\n")
          fun assertProcessAlive () = 
              case Process.waitpid_nh (Process.W_CHILD pid, []) of
                  NONE => ()
                | SOME(pid', Process.W_EXITSTATUS _) =>
                  if pid' = pid then raise ProcessNotActive else ()
                | SOME(pid', Process.W_EXITED) => 
                  if pid' = pid then raise ProcessNotActive else ()
                | SOME(pid', exitStatus) => 
                  if pid' = pid then raise ProcessNotActive else ()

          local
              val isEitherClosed = ref false
              fun killProcess () = 
                  let 
                    fun kill () = 
(print "force to kill\n";
                        Process.kill (Process.K_PROC pid, P.Signal.kill)
)
                  in
                  if (!isEitherClosed)
                  then
                      (
                        case Process.waitpid (Process.W_CHILD pid, []) of
                          (_, Process.W_EXITSTATUS _) => ()
                        | (_, Process.W_EXITED) => ()
                        | (_, _) => kill ();
                        ()
                      )
                  else isEitherClosed := true
                  end
          in
	  fun closeOut () = (P.IO.close outFD; killProcess ())
          fun closeIn () = (P.IO.close inFD; killProcess ())
          end
	  fun receiveArray required =
              let
                  val _ = assertProcessAlive ()
                  val array = Word8Array.array (required, 0w0)
                  val read =
                      P.IO.readArr (inFD, {buf = array, i = 0, sz = NONE})
              in array end
          fun receive () =
              let
                  val array = receiveArray 1
              in SOME(Word8Array.sub(array, 0)) end
          fun send word =
              (
                assertProcessAlive ();
                P.IO.writeArr
                (outFD, {buf = Word8Array.array(1, word), i = 0, sz = NONE});
                ()
              )
	  fun sendArray array =
              (
                assertProcessAlive ();
                P.IO.writeArr (outFD, {buf = array, i = 0, sz = NONE});
                ()
              )

          fun flush () = ()
          fun isEOF () = false

      in
        processIDRef := SOME pid;
        (
          {
            receive = receive,
            receiveArray = receiveArray,
            close = closeIn,
            isEOF = isEOF
          } : ChannelTypes.InputChannel,
          {
            send = send,
            sendArray = sendArray,
            flush = flush,
            close = closeOut
          } : ChannelTypes.OutputChannel
        )
      end

  (***************************************************************************)

end
