(**
 * implementation of channel on a sub process.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: UnixProcessChannel.sml,v 1.21 2007/12/04 06:35:46 kiyoshiy Exp $
 *)
structure UnixProcessChannel =
struct

  (***************************************************************************)

  structure P = Posix
  structure SU = SignalUtility
  structure CU = ChannelUtility
  structure Process = P.Process

  (***************************************************************************)

  type InitialParameter =
       {
         (** name of the executable file *)
         fileName : string,
         (** command line arguments *)
         arguments : string list,
         processIDRef : Process.pid option ref
       }

  (***************************************************************************)

  exception ProcessNotActive

  (***************************************************************************)

  val COMMANDARG = "-pipe" (* command option to server *)

  fun pidToString pid =
      Word32.toString(Process.pidToWord pid)

  fun openProcess {fileName, arguments, processIDRef} =
      let
        (* creta pipe *)
        val {outfd = parentOutFD, infd = childInFD} = P.IO.pipe()
        val {outfd = childOutFD, infd = parentInFD} = P.IO.pipe()
        val FDToString = (Word32.fmt StringCvt.DEC) o P.FileSys.fdToWord
        val (inFDString, outFDString) =
            (fn f=> (f childInFD,f childOutFD)) FDToString
        val commandLineArguments =
            [
              fileName, 
              "-heap", Int.toString (!Control.VMHeapSize),
              "-stack", Int.toString (!Control.VMStackSize),
              COMMANDARG, inFDString, outFDString
            ]
            @ arguments
        val {outFD, inFD, pid} = 
            (* fork *)
            case Process.fork () of
              NONE => 
              (* setup connection *)
              (* exec *)
              Process.exec (fileName, commandLineArguments)
            | SOME(pid) =>
              (
                P.IO.close childInFD;
                P.IO.close childOutFD;
                {outFD = parentOutFD, inFD = parentInFD, pid = pid}
              )
(*
val _ = print ("PID = " ^ pidToString pid ^ "\n")
*)
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
		fun read (array, i) =
                  if i >= Word8Array.length array then array
                  else
                      let val buf = {buf = array, i = i, sz = NONE}
                          val n = P.IO.readArr (inFD, Word8ArraySlice.slice (array,i,NONE) (*buf*))
                      in read (array, i + n)
                      end
            in
		read (array, 0)
            end
        fun receiveVector required =
            Word8ArraySlice.vector (Word8ArraySlice.slice (receiveArray required, 0, NONE))
        fun receive () =
            let
		val array = receiveArray 1
            in SOME(Word8Array.sub(array, 0)) end
        fun sendArray array =
            let
		val _ = assertProcessAlive ()
		fun write (array, i) =
                  if i >= Word8Array.length array then ()
                  else
                      let val buf = {buf = array, i = i, sz = NONE}
                          val n = P.IO.writeArr (outFD, Word8ArraySlice.slice (array,i,NONE) (*buf*))
                      in write (array, i + n)
                      end
            in
		write (array, 0)
            end
        fun sendVector vector =
            let
		val _ = assertProcessAlive ()
		fun write (vector, i) =
                    if i >= Word8Vector.length vector then ()
                    else
                    let val buf = {buf = vector, i = i, sz = NONE}
                        val n = P.IO.writeVec (outFD, Word8VectorSlice.slice (vector,i,NONE) (*buf*))
                    in write (vector, i + n)
                    end
            in
		write (vector, 0)
            end
        fun send word =
            sendArray (Word8Array.array (1, word))

        val getLine = CU.mkGetLine receive
        val print = CU.mkPrint sendArray
	    
        fun flush () = ()
        fun isEOF () = false
		       
      in
          processIDRef := SOME pid;
          (
           {
            receive = receive,
            receiveArray = receiveArray,
            receiveVector = receiveVector,
            getLine = getLine,
            getPos = NONE,
            seek = NONE,
            close = closeIn,
            isEOF = isEOF
           } : ChannelTypes.InputChannel,
           {
            send = send,
            sendArray = sendArray,
            sendVector = sendVector,
            print = print,
            getPos = NONE,
            seek = NONE,
            flush = flush,
            close = closeOut
           } : ChannelTypes.OutputChannel
          )
      end
      
  (***************************************************************************)

end
