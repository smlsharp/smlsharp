(**
 * Copyright (c) 2006, Tohoku University.
 *)
local

  open RuntimeTypes
  open BasicTypes
  structure E = Executable
  structure ES = ExecutableSerializer
  structure I = Instructions
  structure RM = RawMemory
  structure P = Primitives
  structure H = Heap
  structure C = Counter
  structure RC = RuntimeCounters
  structure RE = RuntimeErrors
  structure SU = SignalUtility
  structure FS = FrameStack

in

(**
 * stack of exception handlers.
 * Each entry consists of
 * <ol>
 *   <li>the address of handler code</li>
 *   <li>a slot index to which the raised exception to be stored</li>
 *   <li>a stack frame</li>
 * </ol>
 * "frame" entry is at the bottom (= lowest address) of entry.
 * @author YAMATODANI Kiyoshi
 * @version $Id: HandlerStack.sml,v 1.4 2006/02/18 04:59:39 ohori Exp $
 *)
structure HandlerStack
  : sig

      (***********************************************************************)

      (** handler stack *)
      type stack

      (***********************************************************************)

      (** initialize handler stack. *)
      val initialize : {memory : cellValue RM.pointer, size : UInt32} -> stack

      (** pop the top handler from the handler stack. *)
      val popHandler : stack -> (FS.frame * UInt32 * codeRef)

      (** pop top handlers for the current stack frame. *)
      val popHandlersOfCurrentFrame : (stack * FS.frame) -> unit

      (** push a handler for the current stack frame onto the handler stack. *)
      val pushHandler : (stack * FS.frame * UInt32 * codeRef) -> unit

      (** remove all handlers from the handler stack. *)
      val popAllHandlers : stack -> unit

      (** indicates whether there is no handler in the stck. *)
      val isEmpty : stack -> bool

      (***********************************************************************)

    end =
struct

  (***************************************************************************)

  type stack =
       {
         top : cellValue RM.pointer ref,
         bottom : cellValue RM.pointer,
         size : UInt32
       }

  (***************************************************************************)

  (** size of stack entry *)
  val SIZE_OF_ENTRY = 0w3 : UInt32

  fun initialize {memory, size} =
      {top = ref memory, bottom = memory, size = size}

  (** translate entries to string from bottom to top *)
  fun toString ({top, bottom, ...} : stack) =
      concat(RM.map (bottom, !top) (cellValueToString o RM.load)) ^ "\n"
      
  fun popHandler ({bottom, top, ...} : stack) =
      if bottom = !top
      then raise RE.InvalidCode "uncaught exception"
      else
        let
          val _ = top := RM.back(!top, 0w1)
          val handlerAddress =
              codeRefOf "handler in handlerStack" (RM.load (!top))
          val _ = top := RM.back(!top, 0w1)
          val exceptionDestination =
              wordOf "exn dest in handler stack" (RM.load (!top))
          val _ = top := RM.back(!top, 0w1)
          val frame = RM.load (!top)
        in (frame, exceptionDestination, handlerAddress) end

  (** pop handlers of which "frame" entry equals to the current frame. *)
  fun popHandlersOfCurrentFrame
          (stack as {bottom, top, ...} : stack, frame : FS.frame) =
      let
        fun pop (currentTop : cellValue RM.pointer) =
            if currentTop = bottom
            then top := currentTop
            else
              let val nextEntry = RM.back(currentTop, SIZE_OF_ENTRY)
              in
                if FS.equalFrame(RM.load nextEntry, frame)
                then pop nextEntry
                else top := currentTop
              end
      in pop (!top) end

  fun pushHandler
      (
        {bottom, top, size} : stack,
        frame,
        exceptionDestination,
        handlerAddress
      ) =
      (
        if RM.<(RM.advance(bottom, size), RM.advance(!top, 0w3))
        then raise RE.InvalidCode "handler stack overflow"
        else ();
        RM.store (!top, frame);
        top := RM.advance(!top, 0w1);
        RM.store (!top, Word exceptionDestination);
        top := RM.advance(!top, 0w1);
        RM.store (!top, CodeRef handlerAddress);
        top := RM.advance(!top, 0w1)
      )

  fun popAllHandlers ({bottom, top, ...} : stack) = top := bottom

  fun isEmpty ({bottom, top, ...} : stack) = RM.==(bottom, !top)

  (***************************************************************************)

end (* structure *)

end (* local *)
