(**
 * Copyright (c) 2006, Tohoku University.
 *
 * The IML runtime.
 * <p>
 * This module provides a virtual machine which executes IML instructions.
 * </p>
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: VM.sig,v 1.14 2006/02/18 04:59:41 ohori Exp $
 *)
signature VM =
sig

  (***************************************************************************)

  (** virtual machine *)
  type VM

  type primitive =
       {
         name : string,
         function
         : VM
           -> Heap.heap
           -> RuntimeTypes.cellValue list
           -> RuntimeTypes.cellValue list,
         argSizes : BasicTypes.UInt32 list
       }

  type debugger =
       {
         onBreakPointHit
         : VM
           -> RuntimeTypes.codeRef
           -> (
                Instructions.OPCODE_instruction
                * (** indicates to keep break point *) bool
              ),
         onUncaughtException
         : VM -> RuntimeTypes.codeRef -> RuntimeTypes.cellValue -> unit,
         onRuntimeError : VM -> RuntimeTypes.codeRef -> exn -> unit
       }

  (***************************************************************************)

  (**
   * exception which is raised by implementation of primitive functions to
   * indicate an exception should be raised in the source language.
   *)
  exception PrimitiveException of RuntimeTypes.cellValue

  (***************************************************************************)

  val instTrace : bool ref
  val stateTrace : bool ref
  val heapTrace : bool ref

  (** create an initial virtual machine.
   *)
  val initialize :
      {
        name : string,
        arguments : string list,
        (** the size of the heap. *)
        heapSize : BasicTypes.UInt32,
        (** the size of the frame stack. *)
        frameStackSize : BasicTypes.UInt32,
        (** the size of the handler stack. *)
        handlerStackSize : BasicTypes.UInt32,
        (** the max number of globals *)
        globalCount : BasicTypes.UInt32,
        (** channel to be used as standard input. *)
        standardInput : ChannelTypes.InputChannel,
        (** channel to be used as standard output.
         * For example, the "print" primitive emit the text to this channel.
         *)
        standardOutput : ChannelTypes.OutputChannel,
        (** channel to be used as standard error. *)
        standardError : ChannelTypes.OutputChannel,
        primitives : primitive IEnv.map,
        debuggerOpt : debugger option
      }
        -> VM

  (** execute a byte instruction sequence *)
  val execute : (VM * RuntimeTypes.executable) -> unit

  (** the name of this VM instance. *)
  val getName : VM -> string

  (** the initialize arguments for invocation of the VM instance. *)
  val getArguments : VM -> string list

  val print : VM -> string -> unit

  val getFrameStack : VM -> FrameStack.stack

  val getHeap : VM -> Heap.heap

  val getCurrentCodeRef : VM -> RuntimeTypes.codeRef

  (***************************************************************************)

end
