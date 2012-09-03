(**
 * session implementation for interactive mode compile.
 * This module is used to compile the SML# with MLton compiler.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: InteractiveSessionFactory_MLton.sml,v 1.1 2007/02/23 12:36:11 kiyoshiy Exp $
 *)
structure InteractiveSessionFactory =
struct

  (***************************************************************************)

  structure BT = BasicTypes
  structure SD = SystemDef
  structure SDT = SystemDefTypes

  (***************************************************************************)

  type InitialParameter =
       {
         terminalInputChannel : ChannelTypes.InputChannel,
         terminalOutputChannel : ChannelTypes.OutputChannel,
         terminalErrorChannel : ChannelTypes.OutputChannel,
         arguments : string list
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
        * Int32.int (* isPinnedBuffer *)
        -> unit;

  val VMExecute =
      _import "smlsharp_execute"
      : Word32.word * Word8Vector.vector -> Int32.int;

  (* MLton document says that strings are not null terminated. 
   *  see http://mlton.org/ForeignFunctionInterfaceTypes
   * So, we have to append null character to each string.
   *)
  fun appendNull string = string ^ "\000"

  fun openSession (params : InitialParameter) =
      let
        val name = appendNull (CommandLine.name())
        val argsArray =
            Array.fromList (map appendNull (#arguments params))
        val _ =
            VMInitialize
                (
                  !Control.VMHeapSize,
                  !Control.VMStackSize,
                  1, (* indicating interactive mode. *)
                  name,
                  Array.length argsArray,
                  argsArray,
                  0 (* indicating that the command name and args move by GC. *)
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
