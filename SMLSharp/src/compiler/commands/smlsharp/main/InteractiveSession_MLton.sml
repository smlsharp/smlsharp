(**
 * session implementation for interactive mode compile.
 * This module is used to compile the SML# by MLton compiler.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: InteractiveSession_MLton.sml,v 1.12 2008/01/01 05:22:27 kiyoshiy Exp $
 *)
structure InteractiveSession : SESSION =
struct

  (***************************************************************************)

  structure BT = BasicTypes
  structure RTP = RuntimeProxyTypes
  structure SD = SystemDef
  structure SDT = SystemDefTypes

  (***************************************************************************)

  type InitialParameter =
       {
         terminalInputChannel : ChannelTypes.InputChannel,
         terminalOutputChannel : ChannelTypes.OutputChannel,
         terminalErrorChannel : ChannelTypes.OutputChannel,
         runtimeProxy : RTP.Proxy
       }

  (***************************************************************************)
(*
 mlton -output smlsharp.exe -verbose 2 -keep o -default-ann 'allowFFI true' -link-opt '-L../../../../runtime/byterun/main/ -lsmlsharp -ldl -lstdc++ -lsupc++' sources.mlb
*)

  val VMInitialize = 
      _import "smlsharp_initialize"
      : Int32.int (* heap size *)
        * Int32.int (* stack size *)
        * Int32.int (* isInteractive *)
        * string (* command name *)
        * Int32.int (* the number of command args *)
        * string array (* command args *)
        -> unit;

  val VMExecute =
      _import "smlsharp_executeRawExecutable"
      : Word32.word * Word8Vector.vector -> Int32.int;

  (* MLton document says that strings are not null terminated. 
   *  see http://mlton.org/ForeignFunctionInterfaceTypes
   * So, we have to append null character to each string.
   *)
  fun appendNull string = string ^ "\000"

  fun openSession (params : InitialParameter) =
      let
        val argsArray =
            Array.fromList (map appendNull (CommandLine.arguments ()))
        val _ =
            VMInitialize
                (
                  !Control.VMHeapSize,
                  !Control.VMStackSize,
                  1, (* indicating interactive mode. *)
                  appendNull (CommandLine.name ()),
                  Array.length argsArray,
                  argsArray
                )
        fun execute codeBlock =
            (
              VMExecute
                (BT.IntToUInt32 (Word8Vector.length codeBlock), codeBlock);
              ()
            )
        fun close () = () (* #close outputChannel *)
      in
          {
            execute = execute,
            close = close
          }
      end

  (***************************************************************************)

end
