(**
 * session implementation for batch mode compile.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: StandAloneSession.sml,v 1.9 2006/02/28 16:11:05 kiyoshiy Exp $
 *)
structure StandAloneSession
          : sig

              include SESSION

              val loadExecutable
                  : ChannelTypes.InputChannel -> Word8Array.array option

            end  = 
struct

  (***************************************************************************)

  open BasicTypes
  structure BT = BasicTypes
  structure CT = ChannelTypes
  structure BTS = BasicTypeSerializer
  structure BTSN = BasicTypeSerializerForNetworkByteOrder
  structure SD = SystemDef
  structure SDT = SystemDefTypes

  (***************************************************************************)

  type InitialParameter =
       {
         (**
          * the destination to which the executable should be sent.
          *)
         outputChannel : CT.OutputChannel
       }

  (***************************************************************************)

  (**
   *  send UInt32 to the output channel in Network byte order (= Big endian)
   *
   * @params outChannel uint32
   * @param outChannel the destination
   * @param uint32 the 32bit word to send
   *)
  fun sendUInt32 (outChannel : CT.OutputChannel) (uint32 : UInt32) =
      BTSN.serializeUInt32 uint32 (#send outChannel)
(*
      let
        val array = Word8Array.array (4, 0w0)
      in
        BTSN.serializeUInt32 array (0, uint32);
        #sendArray outChannel array
      end
*)

  (****************************************)

  fun openSession ({outputChannel} : InitialParameter) =
      let
          fun execute codeBlock =
              (
                #send 
                outputChannel
                ((WordToUInt8 o SDT.byteOrderToWord) SD.NativeByteOrder);
                sendUInt32
                outputChannel
                (IntToUInt32 (Word8Array.length codeBlock));
                #sendArray outputChannel codeBlock
              )
          fun close () = () (* #close outputChannel *)
      in
          {
            execute = execute,
            close = close
          }
      end

  (**
   * a utility function to load a serialized form of executable which was put
   * into a data source by this StandAloneSession.
   * This function is used by RuntimeRunner_ML in the IML benchmark driver.
   * @params channel
   * @param channel a input channel to access the data source which contains
   *            a serialized executable.
   * @return SOME executable if an executable is obtained from the channel.
   *        NONE if the channel reaches EOF.
   *)
  fun loadExecutable (channel : CT.InputChannel) =
      case #receive channel () of
        NONE => NONE
      | SOME byteOrder =>
        if
          (Word8.toInt byteOrder)
          <> Word.toInt(SDT.byteOrderToWord SD.NativeByteOrder)
        then raise Fail "unexpected non-native byteorder."
        else
          let
            (* Total number of bytes is seriarized in network byte order. *)
            val totalBytes =
                BTSN.deserializeUInt32
                    (fn _ =>
                        case #receive channel () of
                          SOME byte => byte
                        | NONE => raise Fail "unexpected EOF")
(*
val _ = print (SDT.byteOrderToString BTSN.byteOrder ^ "\n")
val _ = print ("totalBytes = " ^ UInt32.toString totalBytes ^ "\n")
*)
            val array = #receiveArray channel (BT.UInt32ToInt totalBytes)
          in
            SOME array
          end

  (***************************************************************************)

end
