(**
 * session implementation for batch mode compile.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: StandAloneSession.sml,v 1.14 2007/12/19 04:45:37 katsu Exp $
 *)
structure StandAloneSession
          : sig

              include SESSION

              val loadExecutable
                  : ChannelTypes.InputChannel -> SessionTypes.compileResult option

            end  = 
struct

  (***************************************************************************)

  structure BT = BasicTypes
  structure CT = ChannelTypes
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
  fun sendUInt32 (outChannel : CT.OutputChannel) uint32 =
      BTSN.serializeUInt32 uint32 (#send outChannel)
(*
      let
        val array = Word8Array.array (4, 0w0)
      in
        BTSN.serializeUInt32 array (0, uint32);
        #sendArray outChannel array
      end
*)

  local
    exception EOF
  in
  fun receiveUInt32 (inChannel : CT.InputChannel) =
      (SOME
           (BTSN.deserializeUInt32
                (fn _ =>
                    case #receive inChannel () of
                      SOME byte => byte
                    | NONE => raise EOF)))
      handle EOF => NONE
  end           

  (****************************************)

  fun openSession ({outputChannel} : InitialParameter) =
      let
          fun execute codeBlock =
              (
                sendUInt32
                outputChannel
                (BT.IntToUInt32 (Word8Vector.length codeBlock));
                #sendVector outputChannel codeBlock
              )
          val execute =
              fn SessionTypes.CODEBLOCK objfile => execute objfile
               | _ => raise Control.Bug "compilation result mismatch"
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
      case receiveUInt32 channel
       of SOME totalBytes =>
          let
(*
val _ = print (SDT.byteOrderToString BTSN.byteOrder ^ "\n")
val _ = print ("totalBytes = " ^ UInt32.toString totalBytes ^ "\n")
*)
            val vector = #receiveVector channel (BT.UInt32ToInt totalBytes)
          in
            SOME (SessionTypes.CODEBLOCK vector)
          end
        | NONE => NONE

  (***************************************************************************)

end
