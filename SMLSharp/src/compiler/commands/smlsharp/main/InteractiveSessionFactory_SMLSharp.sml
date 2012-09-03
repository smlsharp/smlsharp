(**
 * session implementation for interactive mode compile.
 * This module is used to compile the SML# with MLton compiler.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: InteractiveSessionFactory_SMLSharp.sml,v 1.4 2007/08/24 01:57:09 kiyoshiy Exp $
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

  fun openSession (params : InitialParameter) =
      let
        (* Because Control.runtimeDLLPath can be changed in running, we obtain
         * runtimeDLLPath each time.
         *)
        val libsmlsharp = DynamicLink.dlopen (!Control.runtimeDLLPath)

        val fptr_smlsharp_initialize =
            DynamicLink.dlsym (libsmlsharp, "smlsharp_initialize")
        val smlsharp_initialize =
            fptr_smlsharp_initialize
            : _import (int, int, int, string, int, string array, int) -> unit

        val fptr_smlsharp_execute =
            DynamicLink.dlsym (libsmlsharp, "smlsharp_execute")
        val smlsharp_execute =
            fptr_smlsharp_execute: _import (word, Word8Vector.vector) -> int

        val name = CommandLine.name ()
        val argsArray = Array.fromList (CommandLine.arguments ())
        val _ =
            smlsharp_initialize
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
              smlsharp_execute
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
