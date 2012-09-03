(**
 * @copyright (c) 2006, Tohoku University.
 *)
local

  open RuntimeTypes
  open BasicTypes
  structure E = Executable
  structure ES = ExecutableSerializer
  structure BTS = BasicTypeSerializer
  structure I = Instructions
  structure RM = RawMemory
  structure P = Primitives
  structure H = Heap
  structure C = Counter
  structure RC = RuntimeCounters
  structure RE = RuntimeErrors
  structure SU = SignalUtility

in

(**
 * This module manipulates the runtime frame stack.
 * About the layout of stack frames, refer to comment in Assembler.sml.
 * @author YAMATODANI Kiyoshi
 * @version $Id: FrameStack.sml,v 1.17 2007/06/08 15:21:54 ducnh Exp $
 *)
structure FrameStack
  : sig

      (***********************************************************************)

      type stack

      type frame = cellValue

      (***********************************************************************)

      (** create and initialize the stack. *)
      val initialize : {memory : cellValue RM.pointer, size : UInt32} -> stack

      (** indicates two frames are the same. *)
      val equalFrame : (frame * frame) -> bool

      (** get the contents of slot in the current frame. *)
      val load : (stack * UInt32) -> cellValue
      val load_N : (stack * UInt32 * UInt32) -> cellValue list

      val getSlotOfFrame : frame -> UInt32 -> cellValue

      (** store a value into a slot in the current frame. *)
      val store : (stack * UInt32 * cellValue) -> unit
      val store_N : (stack * UInt32 * cellValue list) -> unit

      (** load the saved pointer to the environment block stored in the current
       * frame. *)
      val loadENV : stack -> cellValue

      val loadENVOfFrame : frame -> cellValue

      (** save a pointer to environment block into a frame slot. *)
      val storeENV : (stack * cellValue) -> unit

      (** allocates new frame *)
      val allocateFrame :
          (stack * UInt32 * codeRef * UInt32 * codeRef) -> frame

      (** get a pointer to the current stack frame. *)
      val getCurrentFrame : stack -> frame

      val getFrames : stack -> frame list

      val getReturnAddressOfFrame : frame -> codeRef

      val getCurrentExecutable : stack -> executable

      (** pop the top frame.
       * returns the return address stored in the frame. *)
      val popFrame : stack -> codeRef

      (** pop top frames until the specified frame. *)
      val popFramesUntil : (stack * frame) -> unit

      (** remove all frames from the stack. *)
      val popAllFrames : stack -> unit

      (** get textual representation of frame stack. *)
      val frameToString : stack -> frame -> string

      val extractFrame
          : frame
            -> {
                 frameSize : UInt32,
                 bitmap : UInt32,
                 atomsCount : UInt32,
                 pointersCount : UInt32,
                 recordGroupsCount : UInt32,
                 recordGroups : UInt32 list
               }

      (** trace pointers in stack *)
      val traceStack : stack -> H.rootTracer -> unit

      (***********************************************************************)

    end =
struct

  (***************************************************************************)

  type stack =
       {
         SP : cellValue RM.pointer ref,
         bottom : cellValue RM.pointer,
         size : UInt32
       }

  type frame = cellValue

  (***************************************************************************)

  val C.CounterSet frameStackCounterSet =
      #addSet RC.VMCounterSet ("Frame", C.ORDER_OF_ADDITION)
  val C.MinMaxCounter usedCellsCounter =
      #addMinMax frameStackCounterSet "usedCells"
  val C.MinMaxCounter frameSizeCounter = 
      #addMinMax frameStackCounterSet "frameSize"
  val C.AccumulationCounter getSlotCounter =
      #addAccumulation frameStackCounterSet "getSlot"
  val C.AccumulationCounter setSlotCounter =
      #addAccumulation frameStackCounterSet "setSlot"

  (* index of slots begins from 1. *)
  val frameSizeINDEX = 0w1 : UInt32
  val funinfoINDEX = 0w2 : UInt32
  val bitmapINDEX = 0w3 : UInt32
  val returnSlotINDEX = 0w4 : UInt32
  val WORDS_OF_FRAME_HEADER = 0w4 : UInt32
  val firstPointerIndex = 0w5 : UInt32

  fun initialize {memory, size : UInt32} =
      {SP = ref memory, bottom = memory, size = size} : stack

  fun equalFrame (Pointer left, Pointer right) = RM.==(left, right)
    | equalFrame (left, right) =
      raise
        RE.InvalidCode
            ("equalFrame expects two pointers, but found " ^
             (cellValueToString left) ^ ", " ^ (cellValueToString right))

  (** get the contents of slot whose index is specified relative to the
   * specified SP *)
  fun getSlotOfSP SP index = 
      (#inc getSlotCounter (); RM.load (RM.back(SP, index)))
  fun getSlot ({SP, ...} : stack) index = getSlotOfSP (!SP) index
  fun getSlotOfFrame frame index =
      getSlotOfSP (pointerOf "getSlotOfFrame" frame) index

  (** store a value into a slot in the current frame. *)
  fun setSlot ({SP, ...} : stack, index, value) =
      (#inc setSlotCounter (); RM.store (RM.back(!SP, index), value))

  fun getCurrentFrame ({SP, ...} : stack) = Pointer (!SP)

  fun frameToString stack frame =
      let
        val SP = pointerOf "frame" frame
        val funInfo =
            codeRefOf "funInfo in frame" (getSlotOfSP SP funinfoINDEX)
        val bitmap = wordOf "bitmap in frame" (getSlotOfSP SP bitmapINDEX)
        val frameSize =
            wordOf "frameSize in frame" (getSlotOfSP SP frameSizeINDEX)
        val returnAddress = getSlotOfSP SP returnSlotINDEX

        val entries =
            List.tabulate
                (
                  UInt32ToInt (frameSize - 0w4),
                  fn index => getSlotOfSP SP (IntToUInt32 index + 0w1 + 0w3)
                )
      in
        "{\n" ^
        "  bitmap=" ^ UInt32.toString bitmap ^ ",\n" ^
        "  frameSize=" ^ UInt32.toString frameSize ^ ",\n" ^
        "  slots=[" ^
        concat (map (fn value => cellValueToString value ^ ", ") entries) ^
        "]\n" ^
        "}"
      end

  (**
   * get the contents of the current stack frame.
   *)
  fun extractFrame (frame : frame) =
      let
        val frameSize =
            wordOf
                "frameSize in frame" (getSlotOfFrame frame frameSizeINDEX)
        val bitmap =
            wordOf "bitmap in frame" (getSlotOfFrame frame bitmapINDEX)
        val funinfo =
            codeRefOf "funinfo in frame" (getSlotOfFrame frame funinfoINDEX)

        fun getUInt32 index =
            let
              val buffer = #instructionsArray(#executable funinfo)
              val pos =
                  ref (UInt32ToInt ((#offset funinfo + index) * BytesOfUInt32))
              fun reader () =
                  Word8Array.sub (buffer, !pos) before pos := !pos + 1
            in
              BTS.deserializeUInt32 reader
            end

        (* FunEntry, frameSize, startOffset *)
        val arity = getUInt32 0w3
        val bitmapvalsFreesCount = getUInt32 (0w3 + 0w1 + arity)
        val bitmapvalsArgsCount =
            getUInt32 (0w3 + 0w1 + arity + 0w1 + bitmapvalsFreesCount)
        val pointersOffset = 
            0w3
            + 0w1 + arity
            + 0w1 + bitmapvalsFreesCount
            + 0w1 + bitmapvalsArgsCount
        val pointersCount = getUInt32 pointersOffset
        val atomsCount = getUInt32 (pointersOffset + 0w1)
        val recordGroupsCount = getUInt32 (pointersOffset + 0w2)
        val recordGroups =
            List.tabulate
            (
              UInt32ToInt recordGroupsCount,
              fn index => getUInt32 (pointersOffset + 0w3 + IntToUInt32 index)
            )
      in
        {
          frameSize = frameSize,
          bitmap = bitmap,
          atomsCount = atomsCount,
          pointersCount = pointersCount,
          recordGroupsCount = recordGroupsCount,
          recordGroups = recordGroups
        }
      end

  fun extractFrameOfStack ({SP, ...} : stack) =
      extractFrame (Pointer (!SP))

  fun getCurrentExecutable (stack as {SP, ...} : stack) =
      let
        val funInfo =
            codeRefOf "getCurrentExecutable" (getSlot stack funinfoINDEX)
      in
        #executable funInfo
      end

  (**
   * indicates whether the frame slot is for pointer value. 
   *)
  fun isPointerSlot (stack, index) =
      let
        val frameInfo = extractFrameOfStack stack
        val bitmap = #bitmap frameInfo
        val recordGroups = #recordGroups frameInfo

        fun isInRegion (first, count) =
            first <= index andalso index < first + count

        fun isInRecordRegion ([], first, bitmap) = false
          | isInRecordRegion (count :: remain, first, bitmap) =
            if isInRegion (first, count)
            then 0w0 <> UInt32.andb (bitmap, 0w1)
            else
              isInRecordRegion (remain, first + count, UInt32.>> (bitmap, 0w1))

        val firstRecordIndex =
            firstPointerIndex
            + #pointersCount frameInfo
            + #atomsCount frameInfo
(*
val _ = print ("firstPointerIndex = " ^ UInt32.toString firstPointerIndex ^ "\n");
val _ = print ("# pointers = " ^ UInt32.toString (#pointersCount frameInfo) ^ "\n")
val _ = print ("# atoms = " ^ UInt32.toString (#atomsCount frameInfo) ^ "\n")
val _ = print ("firstRecordIndex = " ^ UInt32.toString firstRecordIndex ^ "\n");
*)
      in
        isInRegion (firstPointerIndex, #pointersCount frameInfo)
        orelse isInRecordRegion (recordGroups, firstRecordIndex, bitmap)
      end

  fun isVariableSlot (stack, index) = 
      let val frameSize = #frameSize (extractFrameOfStack stack)
      in (firstPointerIndex <= index) andalso (index <= frameSize)
      end

  (** load the value of a slot in the current frame. *)
  fun load (stack, index) =
      if false = isVariableSlot (stack, index)
      then
        raise
          RE.InvalidCode
              ("Load: index = " ^ UInt32.toString index ^ " in a frame " ^
               frameToString stack (getCurrentFrame stack))
      else
        let val value = getSlot stack index
        in
          if isPointerSlot (stack, index)
          then
            if isPointerValue value
            then ()
            else
              raise
                RE.InvalidCode
                    ("load slot " ^ UInt32.toString index ^ "  a pointer, " ^
                     "but holds " ^ cellValueToString value)
          else
            if isAtomValue value
            then ()
            else
              raise
                RE.InvalidCode
                    ("load slot " ^ UInt32.toString index ^ " expects an atom \
                      \or a real, holds " ^ cellValueToString value);
          value
        end
  fun load_N (stack, index, count) =
      List.tabulate
          (
            UInt32ToInt count,
            (fn i => getSlot stack (index + IntToUInt32 i))
          )

  fun store (stack, index, value) =
      if false = isVariableSlot (stack, index)
      then
        raise
          RE.InvalidCode
              ("Store: index = " ^ UInt32.toString index ^ " in a frame " ^
               frameToString stack (getCurrentFrame stack))
      else
        (
          if isPointerSlot (stack, index)
          then
            if isPointerValue value
            then ()
            else
              raise
                RE.InvalidCode
                    ("store slot " ^ UInt32.toString index ^ " expects a \
                     \pointer, but " ^ cellValueToString value)
          else
            if isAtomValue value
            then ()
            else
              raise
                RE.InvalidCode
                    ("store slot " ^ UInt32.toString index ^ " expects an\
                      \ atom or a real, but " ^ cellValueToString value);
          setSlot (stack, index, value)
        )

  fun store_N (stack, index, values) =
      (
        foldl
            (fn (value, i) => (store(stack, i, value); i + 0w1))
           index
           values;
        ()
      )

  fun loadENV stack = getSlot stack firstPointerIndex

  fun loadENVOfFrame frame = getSlotOfFrame frame firstPointerIndex

  fun storeENV (stack, ENV) = setSlot (stack, firstPointerIndex, ENV)

  fun allocateFrame
      (
        stack as {SP, bottom, size, ...} : stack,
        frameSize,
        funinfoAddress,
        bitmap,
        returnAddress
      ) =
      let fun set (index, value) = setSlot (stack, index, value)
      in
        if RM.<(RM.advance(bottom, size), RM.advance(!SP, frameSize))
        then raise RE.InvalidCode "frame stack over flow"
        else ();
        (*
         * Uninitialized slot may contain invalid pointer which was stored
         * by previous function call which used the area of this frame.
         * To avoid tracing this pointer mistakenly in GC, every slot is
         * initialized with non-pointer values.
         *)
        RM.map
        (!SP, RM.advance(!SP, frameSize))
        (fn pointer => RM.store (pointer, Word 0w0));

        SP := RM.advance(!SP, frameSize);
        set (frameSizeINDEX, Word frameSize);
        set (funinfoINDEX, CodeRef funinfoAddress);
        set (bitmapINDEX, Word bitmap);
        set (returnSlotINDEX, CodeRef returnAddress);
          
        #set frameSizeCounter (UInt32.toInt frameSize);
        #set usedCellsCounter (UInt32.toInt (RM.distance (!SP, bottom)));
        Pointer (!SP)
      end

  fun popFrame (stack as {SP, ...} : stack) =
      let
        val frameSize =
            wordOf "frameSize in frame" (getSlot stack frameSizeINDEX)
        val returnAddress = getSlot stack returnSlotINDEX
      in
        SP := RM.back(!SP, frameSize);
        codeRefOf "returnAddress in frame" (returnAddress)
      end

  fun popFramesUntil ({SP, ...} : stack, frame) =
      SP := pointerOf "arg to popFramesUntil" frame

  fun popAllFrames ({SP, bottom, ...} : stack) = SP := bottom

  fun getReturnAddressOfFrame frame =
      let
        val SP = pointerOf "getReturnAddressOfFrame" frame
        val frameSize =
            wordOf "frameSize in frame" (getSlotOfSP SP frameSizeINDEX)
        val returnAddress = getSlotOfSP SP returnSlotINDEX
        val codeRef = codeRefOf "returnAddress in frame" (returnAddress)
      in
        codeRef
      end

  fun getFrames ({SP, bottom, ...} : stack) =
      let
        fun scan (currentSP, frames) =
            if RM.==(currentSP, bottom)
            then
              (*
              (* the bottom frame is a dummy initial frame allocated at the
               * beginning of execute. *)
              if List.null frames then [] else List.rev (tl frames)
               *)
              List.rev frames
            else
              let
                val frameSize =
                    wordOf
                        "frameSize in frame"
                        (getSlotOfSP currentSP frameSizeINDEX)
                val nextSP = RM.back(currentSP, frameSize)
              in
                scan (nextSP, (Pointer currentSP) :: frames)
              end
      in
        scan (!SP, [])
      end

  fun traceStack ({SP, bottom, size} : stack) rootTracer =
      let
        fun get (SP, index) =
            getSlot {SP = ref SP, bottom = bottom, size = size} index
        fun set (SP, index, value) =
            setSlot ({SP = ref SP, bottom = bottom, size = size}, index, value)

        (** trace pointers array. *)
        fun traceRegion cursorSP begin count = 
            let
              fun trace (_, 0w0) = ()
                | trace (index, remain) =
                  let val newValue = rootTracer (get (cursorSP, index))
                  in
                    set (cursorSP, index, newValue);
                    trace (index + 0w1, remain - 0w1)
                  end
            in trace (begin, count) end

        (** trace record groups in a frame *)
        fun traceRecordGroups cursorSP firstRecordIndex recordCounts =
            let
              (* Assume k record groups.
               * The bitmap has k bits, the (k-1) th bit indicates the type of
               * 1st record group, and the 0th bit indicates type of the k-th
               * group.
               *)
              val bitmap =
                  wordOf "bitmap in frame" (get(cursorSP, bitmapINDEX))
              fun traceGroup (_, _, []) = ()
                | traceGroup (bitmap, firstIndex, recordCount :: remain) =
                  (
                    if 0w0 <> UInt32.andb (bitmap, 0w1)
                    then traceRegion cursorSP firstIndex recordCount
                    else ();
                    traceGroup
                        (
                          UInt32.>> (bitmap, 0w1),
                          firstIndex + recordCount,
                          remain
                        )
                  )
            in
              traceGroup (bitmap, firstRecordIndex, recordCounts)
            end

        (** trace frames *)
        fun traceFrame cursorSP =
            if RM.==(cursorSP, bottom)
            then ()
            else
              let
                val funinfo =
                    extractFrameOfStack
                        {SP = ref cursorSP, bottom = bottom, size = size}
                val firstRecordIndex =
                    firstPointerIndex +
                    (#pointersCount funinfo) +
                    (#atomsCount funinfo)
              in
(*
                  traceRegion cursorSP 0w1 (#frameSize funinfo);
*)
                (* trace pointers *)
                traceRegion
                    cursorSP firstPointerIndex (#pointersCount funinfo);
                (* trace recordGroups *)
                traceRecordGroups
                    cursorSP firstRecordIndex (#recordGroups funinfo);

                traceFrame (RM.back(cursorSP, #frameSize funinfo))
              end
      in
        traceFrame (!SP)
      end

  (***************************************************************************)

end (* structure *)

end (* local *)
