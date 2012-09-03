(**
 *  This structure implements the protocol for interactive communication with
 * IML runtime.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: YAInteractiveSession.sml,v 1.1 2008/01/10 04:43:12 katsu Exp $
 *)
structure YAInteractiveSession : SESSION = 
struct

  (***************************************************************************)

  structure BT = BasicTypes
  structure C = Constants
  structure ST = SessionTypes
  structure SU = SignalUtility
  structure RTP = RuntimeProxyTypes

  (***************************************************************************)

  type InitialParameter =
       {
         terminalInputChannel : ChannelTypes.InputChannel,
         terminalOutputChannel : ChannelTypes.OutputChannel,
         terminalErrorChannel : ChannelTypes.OutputChannel,
         runtimeProxy : RTP.Proxy
       }

  (****************************************)

  type ByteArray = Word8Array.array

  type ByteVector = Word8Array.vector

  type FileDescriptor = BT.UInt32

  type ByteOrder = SystemDefTypes.byteOrder

  type MajorCode = BT.UInt8

  type MinorCode = BT.UInt8

  datatype Result = Success | Failure of (MajorCode * MinorCode * ByteVector)

  (********************)

  type InitializationResult = Result

  type ExitRequest = {exitCode : BT.SInt32}

  type ExecutionRequest = {code : ObjectFile.objectFile}

  type ExecutionResult = Result

  type OutputRequest = {descriptor : FileDescriptor, data : ByteVector}

  type OutputResult = Result

  type InputRequest = {length : BT.UInt32}

  type InputResult = {result : Result, data : ByteVector option}

  type ChangeDirectoryRequest = {directory : ByteVector}

  (********************)

  datatype Message =
           InitializationResult of InitializationResult
         | ExitRequest of ExitRequest
         | ExecutionRequest of ExecutionRequest
         | ExecutionResult of ExecutionResult
         | OutputRequest of OutputRequest
         | OutputResult of OutputResult
         | InputRequest of InputRequest
         | InputResult of InputResult
         | ChangeDirectoryRequest of ChangeDirectoryRequest

  (***************************************************************************)

  exception MessageFormatException of string

  exception ProtocolException of string

  exception ExecutionException of (MajorCode * MinorCode * ByteVector)

  exception Interrupted

  (***************************************************************************)

  fun wrapByHandler wrapee arg =
      (wrapee arg)
      handle exn as (ST.Failure _) => raise exn
           | exn as (ST.Fatal _) => raise exn
           | exn as (ST.Exit _) => raise exn
           | exn => raise (ST.Failure exn)

  fun handleInternalError exn =
      (
        print "Internal Error: ";
        print (exnMessage exn);
        print "\n"
      )

  fun wrapBySignalHandler (proxy : RTP.Proxy) wrapee arg =
      let
          fun handler signalName = ()
(*
              #sendInterrupt proxy ()
*)
      in
(*
          SU.doWithAction [SU.SIGINT, "CHLD"] (SU.Handle handler) wrapee arg
*)
          SU.doWithAction [SU.SIGINT] (SU.Handle handler) wrapee arg
(*
 Ignore is sufficient for the purpose, but it causes strange status of
messaging between the compiler and the runtime.
          SU.doWithAction [SU.SIGINT] SU.Ignore wrapee arg
*)
      end

  (** send a UInt32 in NetworkByteOrder. *)
  fun sendUInt32 (channel : ChannelTypes.OutputChannel) uint32 =
      let
          fun out uint32 = #send channel (BT.UInt32ToUInt8 uint32)
      in
          (
            out (BT.UInt32.>> (uint32, 0w24));
            out (BT.UInt32.>> (uint32, 0w16));
            out (BT.UInt32.>> (uint32, 0w8));
            out uint32
          )
      end

  fun sendSInt32 (channel : ChannelTypes.OutputChannel) sint32 =
      sendUInt32 channel (BT.SInt32ToUInt32 sint32)

  fun sendByteArray (channel : ChannelTypes.OutputChannel) array =
      (
        sendUInt32 channel (BT.IntToUInt32 (Word8Array.length array));
        #sendArray channel array
      )

  fun sendByteVector (channel : ChannelTypes.OutputChannel) vector =
      (
        sendUInt32 channel (BT.IntToUInt32 (Word8Vector.length vector));
        #sendVector channel vector
      )

  fun sendResult (channel : ChannelTypes.OutputChannel) result =
      case result of
          Success => #send channel 0w0
        | Failure(majorCode, minorCode, description) =>
          (
            #send channel majorCode;
            #send channel minorCode;
            sendByteVector channel description
          )

  fun sendExitRequest channel ({exitCode} : ExitRequest) =
      sendSInt32 channel exitCode

  fun sendExecutionRequest channel ({code} : ExecutionRequest) =
      (
        ELFWriterLE.write (sendByteArray channel, code, nil);
        sendUInt32 channel 0w0
      )

  fun sendOutputResult channel result = sendResult channel result

  fun sendInputResult channel ({result, data} : InputResult) =
      (
        sendResult channel result;
        case result of
            Success => sendByteVector channel (valOf data)
          | _ => ()
      )

  fun sendMessage channel message =
      case message of
          ExitRequest exitRequest =>
          (#send channel 0w1; sendExitRequest channel exitRequest)
        | ExecutionRequest executionRequest =>
          (#send channel 0w2; sendExecutionRequest channel executionRequest)
        | OutputResult outputResult =>
          (#send channel 0w5; sendOutputResult channel outputResult)
        | InputResult inputResult =>
          (#send channel 0w7; sendInputResult channel inputResult)
        | _ => raise ProtocolException "invalid message to send."

  (********************)

  (** receive a UInt32 in NetworkByteOrder. *)
  fun receiveUInt32 (channel : ChannelTypes.InputChannel) =
      let
          fun receive () =
              case #receive channel () of
                  NONE => raise MessageFormatException "cannot receive UInt32"
                | SOME(byte) => BT.UInt8ToUInt32 byte
          val byte1 = receive()
          val byte2 = receive()
          val byte3 = receive()
          val byte4 = receive()
          val orb = BT.UInt32.orb
          val << = BT.UInt32.<<
          infix orb
      in
          (
            (<< (byte1, 0w24)) orb
            (<< (byte2, 0w16)) orb
            (<< (byte3, 0w8)) orb
            byte4
          )
      end

  fun receiveSInt32 channel =
      BT.UInt32ToSInt32(receiveUInt32 channel)

  fun receiveFileDescriptor channel = receiveUInt32 channel

  fun receiveByteArray channel =
      let
          val length = BT.UInt32ToInt (receiveUInt32 channel)
          val data = #receiveArray channel length
      in
          if Word8Array.length data <> length
          then
            raise
              MessageFormatException
                  "cannot receive sufficient bytes of array."
          else data
      end

  fun receiveByteVector channel =
      let
          val length = BT.UInt32ToInt (receiveUInt32 channel)
          val data = #receiveVector channel length
      in
          if Word8Vector.length data <> length
          then
            raise
              MessageFormatException
                  "cannot receive sufficient bytes of array."
          else data
      end

  fun receiveResult (channel : ChannelTypes.InputChannel) =
      case #receive channel () of
          NONE => raise MessageFormatException "cannot receive MajorCode"
        | SOME majorCode =>
          if majorCode = Word8.fromInt C.MAJOR_CODE_SUCCESS
          then Success
          else
            case #receive channel() of
              NONE =>
              raise
                (ST.Fatal(MessageFormatException "cannot receive MinorCode"))
            | SOME(minorCode) =>
              let val description = receiveByteVector channel
              in
                if majorCode = Word8.fromInt C.MAJOR_CODE_FATAL
                then
                  raise
                    ST.Fatal
                        (ExecutionException(majorCode, minorCode, description))
                else Failure(majorCode, minorCode, description)
              end

  fun receiveInitializationResult channel = receiveResult channel

  fun receiveExecutionResult channel = receiveResult channel

  fun receiveExitRequest channel = {exitCode = receiveSInt32 channel}

  fun receiveOutputRequest channel =
      let
          val descriptor = receiveFileDescriptor channel
          val data = receiveByteVector channel
      in {descriptor = descriptor, data = data} end

  fun receiveInputRequest channel =
      let val length = receiveUInt32 channel
      in {length = length} end

  fun receiveChangeDirectoryRequest channel =
      let
        val data = receiveByteVector channel
      in
        {directory = data}
      end

  fun receiveMessage channel =
      case #receive channel () of
          NONE => raise MessageFormatException "cannot receive messageType."
        | SOME(messageType) =>
          let val messageType = Word8.toInt messageType
          in
            if messageType = C.MESSAGE_TYPE_INITIALIZATION_RESULT
            then InitializationResult(receiveInitializationResult channel)
            else if messageType = C.MESSAGE_TYPE_EXIT_REQUEST
            then ExitRequest(receiveExitRequest channel)
            else if messageType = C.MESSAGE_TYPE_EXECUTION_RESULT
            then ExecutionResult(receiveExecutionResult channel)
            else if messageType = C.MESSAGE_TYPE_OUTPUT_REQUEST
            then OutputRequest(receiveOutputRequest channel)
            else if messageType = C.MESSAGE_TYPE_INPUT_REQUEST
            then InputRequest(receiveInputRequest channel)
            else if messageType = C.MESSAGE_TYPE_CHANGE_DIRECTORY_REQUEST
            then ChangeDirectoryRequest(receiveChangeDirectoryRequest channel)
            else
              raise
                MessageFormatException
                    ("unknown messageType:" ^ Int.toString messageType)
          end

  (****************************************)

  fun inputLine length (channel : ChannelTypes.InputChannel) =
      let
          fun readUntilEOL (bytesToRead : BT.UInt32) buffer =
              if 0w0 = bytesToRead then buffer
              else
                  case #receive channel () of
                      NONE => buffer
                    | SOME(0w10 (* \n *)) => (0w10 :: buffer)
                    | SOME(byte) =>
                      readUntilEOL (bytesToRead - 0w1) (byte :: buffer)
      in
          Word8Vector.fromList (List.rev (readUntilEOL length []))
      end

  fun openSession 
       ({
         terminalInputChannel,
         terminalOutputChannel,
         terminalErrorChannel,
         runtimeProxy =
         proxy
             as
             {
               inputChannel = messageInputChannel,
               outputChannel = messageOutputChannel,
               ...
             }
        } : InitialParameter) =
      case receiveMessage messageInputChannel of
          InitializationResult(Success) =>
          let
            fun waitForExecutionResult () =
                let
                  fun receive () =
                      (wrapBySignalHandler
                           proxy receiveMessage messageInputChannel)
                      handle OS.SysErr _ => receive ()
                in
                  case receive () of
                    ExecutionResult result => result
                  | ExitRequest {exitCode} => raise ST.Exit exitCode
                  | InputRequest {length} =>
                    let
                      val input =
                          (inputLine length terminalInputChannel)
                          handle e =>
                                 (
                                   handleInternalError e;
                                   Word8Vector.fromList []
                                 )
                    in
                      sendMessage
                          messageOutputChannel
                          (InputResult{result = Success, data = SOME input});
                      waitForExecutionResult ()
                    end
                  | OutputRequest {descriptor, data} =>
                    (
                      (let
                         val channel =
                             case descriptor of
                               0w1 => terminalOutputChannel
                             | 0w2 => terminalErrorChannel
                             | _ =>
                               raise
                                 ProtocolException
                                     ("invalid descriptor:" ^
                                      (BT.UInt32.toString descriptor))
                       in
                         #sendVector channel data;
                         #flush channel ()
                       end)
                      handle e => (handleInternalError e; ());
                      sendMessage messageOutputChannel (OutputResult Success);
                      waitForExecutionResult ()
                    )
                  | ChangeDirectoryRequest {directory = bytes} =>
                    (
                      let
                        val directory = Byte.bytesToString bytes
                      in
                        OS.FileSys.chDir directory
                      end
                        handle e => (handleInternalError e; ());
                      (* no response *)
                      waitForExecutionResult ()
                    )
                  | message => (
raise ProtocolException "invalid message."
)
                end
                                                   
            fun execute (SessionTypes.OBJECTFILE objfile) =
                (
                  sendMessage
                      messageOutputChannel
                      (ExecutionRequest {code = objfile});
                  case waitForExecutionResult () of
                    Success => ()
                  | Failure(majorCode, minorCode, description) =>
                    raise
                      ExecutionException(majorCode, minorCode, description)
                )
              | execute _ = raise Control.Bug "compilation result mismatch"

            fun close () =
                sendMessage
                    messageOutputChannel
                    (ExitRequest{exitCode = BT.IntToSInt32 0})
          in
            {
              execute = wrapByHandler execute,
              close = wrapByHandler close
            }
          end
        | InitializationResult(Failure(failDetail)) =>
          raise ExecutionException failDetail
        | message =>
          raise ProtocolException "cannot receive InitializationResult"

  val openSession = wrapByHandler openSession

  (***************************************************************************)

end
