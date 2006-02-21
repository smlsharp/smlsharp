(**
 * Copyright (c) 2006, Tohoku University.
 *
 *  This structure implements the protocol for interactive communication with
 * IML runtime.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: InteractiveSession.sml,v 1.12 2006/02/18 04:59:28 ohori Exp $
 *)
structure InteractiveSession : SESSION = 
struct

  (***************************************************************************)

  open BasicTypes
  structure SU = SignalUtility
  structure RTP = RuntimeProxyTypes

  (***************************************************************************)

  type InitialParameter =
       {
         terminalInputChannel : ChannelTypes.InputChannel,
         terminalOutputChannel : ChannelTypes.OutputChannel,
         terminalErrorChannel : ChannelTypes.OutputChannel,
         runtimeProxy : RTP.Proxy
(*
         (**
          * the destination to which the messages should be sent.
          *)
         messageInputChannel : ChannelTypes.InputChannel,
         (**
          * the destination to which the messages should be sent.
          *)
         messageOutputChannel : ChannelTypes.OutputChannel
*)
       }

  (****************************************)

  type ByteArray = Word8Array.array

  type FileDescriptor = UInt32

  type ByteOrder = SystemDefTypes.byteOrder

  type MajorCode = UInt8

  type MinorCode = UInt8

  datatype Result = Success | Failure of (MajorCode * MinorCode * ByteArray)

  (********************)

  type InitializationResult = Result

  type ExitRequest = {exitCode : SInt32}

  type ExecutionRequest = {endian : ByteOrder, code : ByteArray}

  type ExecutionResult = Result

  type OutputRequest = {descriptor : FileDescriptor, data : ByteArray}

  type OutputResult = Result

  type InputRequest = {length : UInt32}

  type InputResult = {result : Result, data : ByteArray option}

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

  (***************************************************************************)

  exception MessageFormatException of string

  exception ProtocolException of string

  exception ExecutionException of (MajorCode * MinorCode * ByteArray)

  exception Interrupted

  (***************************************************************************)

  fun wrapByHandler wrapee arg =
      (wrapee arg)
      handle exn as (SessionTypes.Error _) => raise exn
           | exn => raise (SessionTypes.Error exn)

  fun wrapBySignalHandler (proxy : RTP.Proxy) wrapee arg =
      let
          fun handler signalName = ()
(*
              #sendInterrupt proxy ()
*)
      in
(*
          SU.doWithAction ["INT", "CHLD"] (SU.Handle handler) wrapee arg
*)
          SU.doWithAction ["INT"] (SU.Handle handler) wrapee arg
(*
 Ignore is sufficient for the purpose, but it causes strange status of
messaging between the compiler and the runtime.
          SU.doWithAction ["INT"] SU.Ignore wrapee arg
*)
      end

  fun sendUInt32 (channel : ChannelTypes.OutputChannel) uint32 =
      let
          fun out uint32 = #send channel (UInt32ToUInt8 uint32)
      in
          (
            out (UInt32.>> (uint32, 0w24));
            out (UInt32.>> (uint32, 0w16));
            out (UInt32.>> (uint32, 0w8));
            out uint32
          )
      end

  fun sendSInt32 (channel : ChannelTypes.OutputChannel) sint32 =
      sendUInt32 channel (SInt32ToUInt32 sint32)

  fun sendByteArray (channel : ChannelTypes.OutputChannel) array =
      (
        sendUInt32 channel (IntToUInt32 (Word8Array.length array));
        #sendArray channel array
      )

  fun sendResult (channel : ChannelTypes.OutputChannel) result =
      case result of
          Success => #send channel 0w0
        | Failure(majorCode, minorCode, description) =>
          (
            #send channel majorCode;
            #send channel minorCode;
            sendByteArray channel description
          )

  fun sendExitRequest channel ({exitCode} : ExitRequest) =
      sendSInt32 channel exitCode

  fun sendExecutionRequest channel ({endian, code} : ExecutionRequest) =
      (
        #send channel (WordToUInt8(SystemDefTypes.byteOrderToWord endian));
        sendByteArray channel code
      )

  fun sendOutputResult channel result = sendResult channel result

  fun sendInputResult channel ({result, data} : InputResult) =
      (
        sendResult channel result;
        case result of
            Success => sendByteArray channel (valOf data)
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

  fun receiveUInt32 (channel : ChannelTypes.InputChannel) =
      let
          fun receive () =
              case #receive channel () of
                  NONE => raise MessageFormatException "cannot receive UInt32"
                | SOME(byte) => UInt8ToUInt32 byte
          val byte1 = receive()
          val byte2 = receive()
          val byte3 = receive()
          val byte4 = receive()
          val orb = UInt32.orb
          val << = UInt32.<<
          infix orb
      in
          (
            (<< (byte1, 0w24)) orb
            (<< (byte2, 0w16)) orb
            (<< (byte3, 0w8)) orb
            byte4
          )
      end

  fun receiveFileDescriptor channel = receiveUInt32 channel

  fun receiveByteArray channel =
      let
          val length = UInt32ToInt (receiveUInt32 channel)
          val data = #receiveArray channel length
      in
          if Word8Array.length data <> length then
              raise
              MessageFormatException
              "cannot receive sufficient bytes of array."
          else data
      end

  fun receiveResult (channel : ChannelTypes.InputChannel) =
      case #receive channel () of
          NONE => raise MessageFormatException "cannot receive MajorCode"
        | SOME(0w0) => Success
        | SOME(majorCode) =>
          case #receive channel() of
              NONE => raise MessageFormatException "cannot receive MinorCode"
            | SOME(minorCode) =>
              let val description = receiveByteArray channel
              in Failure(majorCode, minorCode, description)
              end

  fun receiveInitializationResult channel = receiveResult channel

  fun receiveExecutionResult channel = receiveResult channel

  fun receiveOutputRequest channel =
      let
          val descriptor = receiveFileDescriptor channel
          val data = receiveByteArray channel
      in {descriptor = descriptor, data = data} end

  fun receiveInputRequest channel =
      let val length = receiveUInt32 channel
      in {length = length} end

  fun receiveMessage channel =
      case #receive channel () of
          NONE => raise MessageFormatException "cannot receive messageType."
        | SOME(messageType) =>
          case messageType of
              0w0 => InitializationResult(receiveInitializationResult channel)
            | 0w3 => ExecutionResult(receiveExecutionResult channel)
            | 0w4 => OutputRequest(receiveOutputRequest channel)
            | 0w6 => InputRequest(receiveInputRequest channel)
            | _ =>
              raise
              MessageFormatException
              ("unknown messageType:" ^ Word8.toString messageType)

  (****************************************)

  fun inputLine length (channel : ChannelTypes.InputChannel) =
      let
          fun readUntilEOL (bytesToRead : UInt32) buffer =
              if 0w0 = bytesToRead then buffer
              else
                  case #receive channel () of
                      NONE => buffer
                    | SOME(0w10 (* \n *)) => (0w10 :: buffer)
                    | SOME(byte) =>
                      readUntilEOL (bytesToRead - 0w1) (byte :: buffer)
      in
          Word8Array.fromList
          (List.rev (readUntilEOL length []))
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
                    case  receive () of
                        ExecutionResult result => result
                      | InputRequest {length} =>
                        let val input = inputLine length terminalInputChannel
                        in
                            sendMessage
                            messageOutputChannel
                            (InputResult{result = Success, data = SOME input});
                            waitForExecutionResult ()
                        end
                      | OutputRequest {descriptor, data} =>
                        let
                            val channel =
                                case descriptor of
                                    0w1 => terminalOutputChannel
                                  | 0w2 => terminalErrorChannel
                                  | _ =>
                                    raise
                                        ProtocolException
                                            ("invalid descriptor:" ^
                                             (UInt32.toString descriptor))
                        in
                            #sendArray channel data;
                            sendMessage
                                messageOutputChannel
                                (OutputResult Success);
                            waitForExecutionResult ()
                        end
                      | message => raise ProtocolException "invalid message."
                  end
                                                   
              fun execute codeBlock =
                  (
                    sendMessage
                    messageOutputChannel
                    (
                      ExecutionRequest
                      {endian = SystemDef.NativeByteOrder, code = codeBlock}
                    );
                    case waitForExecutionResult () of
                        Success => ()
                      | Failure(majorCode, minorCode, description) =>
                        raise
                        ExecutionException(majorCode, minorCode, description)
                  )
              fun close () =
                  sendMessage
                  messageOutputChannel
                  (ExitRequest{exitCode = IntToSInt32 0})
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
