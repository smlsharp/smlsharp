(**
 * Copyright (c) 2006, Tohoku University.
 *
 *  This structure translates instructions with symbolic references into
 * instructions in lower level representation.
 * <p>
 * Symbolic references in operands are translated into offset of instruction
 * or index in stack frame.
 * </p>
 *
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @author Nguyen Huu Duc
 * @version $Id: Assembler.sml,v 1.53 2006/02/18 04:59:16 ohori Exp $
 *)
structure Assembler :> ASSEMBLER =
struct

  (***************************************************************************)

  structure AI = AllocationInfo
  structure BT = BasicTypes
  structure E = AssembleError
  structure I = Instructions
  structure ISC = InstructionSizeCalculator
  structure LocMap = SourceLocationMap
  structure NameSlotMap = SourceNameSlotMap
  structure P = Primitives
  structure SF = StackFrame
  structure SI = SymbolicInstructions
  structure SIF = SymbolicInstructionsFormatter
  structure UE = UserError

  (***************************************************************************)

  (** intermediate form of the function prologue information passed from the
   * first subphase to the second subphase. *)
  type IMFunInfo = 
       {
         (** the number of slots required for this frame. *)
         frameSize : BT.UInt32,
         (** the label of the head of the function body. *)
         startOffset : BT.UInt32,
         (** argument names *)
         args : SI.varInfo list,
         (** elements to compose the bitmap value for frames of the function *)
         bitmapvals : {args : SI.varInfo list, frees : BT.UInt32 list},
         (** the number of slots for variables of pointer type. *)
         pointersSlots : BT.UInt32,
         (** the number of slots for variables of atom type and double type. *)
         atomsSlots : BT.UInt32,
         (** a list of the numbers of slots for variables of each polymorphic
          * types. *)
         recordsSlots : BT.UInt32 list
       }

  (** information about a function sufficient to generate byte code
   * sequence for the function *)
  type IMFunctionCode = (SlotMap.map * IMFunInfo * SI.instruction list)

  (***************************************************************************)

  (**
   * the exception raised when an undefined label reference is found.
   *)
  exception UndefinedLabel of string

  (***************************************************************************)

  structure CT = Counter
  val CT.CounterSet AssemblerCounterSet =
      #addSet CT.root ("assembler", CT.ORDER_OF_ADDITION)
  val CT.CounterSet ElapsedCounterSet =
      #addSet AssemblerCounterSet ("elapsed time", CT.ORDER_OF_ADDITION)
  val CT.ElapsedTimeCounter allocateSlotTimeCounter =
      #addElapsedTime ElapsedCounterSet "allocate slot"
  val CT.ElapsedTimeCounter fixIndexTimeCounter =
      #addElapsedTime ElapsedCounterSet "fix index"
  val CT.ElapsedTimeCounter calcOffsetTimeCounter =
      #addElapsedTime ElapsedCounterSet "calc offset"
  val CT.ElapsedTimeCounter buildNameSlotMapTimeCounter =
      #addElapsedTime ElapsedCounterSet "build name slot map"
  val CT.ElapsedTimeCounter firstPassTimeCounter =
      #addElapsedTime ElapsedCounterSet "first pass"
  val CT.ElapsedTimeCounter makeDebugInfoTimeCounter =
      #addElapsedTime ElapsedCounterSet "make debug info"
  val CT.ElapsedTimeCounter secondPassTimeCounter =
      #addElapsedTime ElapsedCounterSet "second pass"
  val CT.AccumulationCounter instructionsCounter =
      #addAccumulation AssemblerCounterSet "instructions"

  local
    val errorQueue = UE.createQueue ()
  in
  fun initializeErrorQueue () = UE.clearQueue errorQueue

  fun getErrorsAndWarnings () = UE.getErrorsAndWarnings errorQueue
  fun getErrors () = UE.getErrors errorQueue
  fun getWarnings () = UE.getWarnings errorQueue
  val enqueueError = UE.enqueueError errorQueue
  val enqueueWarning = UE.enqueueWarning errorQueue
  end

  (**
   * builds a slot map, a label map and a location map for a function.
   * This is the first half of assemble process.
   * <p>
   * The slot map is built by allocation of frame slots to local variables.
   * The slot allocation algorithm adopted in this version examines only the
   * funInfo. In future version which adopts more sophisticated allocation
   * algorithm, instruction sequence might be scanned repeatedly.
   * </p>
   * <p>
   * The label map is built by resolution of address of each label.
   * The address resolution is straightforward.
   * As a point to notice, the first instruction of this function should be
   * labeled with the functionName.
   * </p>
   * <p>
   * The location map is also built by resolution of address of each label.
   * </p>
   * <p>
   * NOTE: The number of words occupied by the function prologue instruction
   * depends on the number of slots allocated to all local variables.
   * Therefore, slot allocation precedes address resolution.
   * </p>
   *
   *)
  fun buildMaps
      (
        {
          name = functionVarInfo : SI.varInfo,
          loc,
          funInfo : SI.funInfo,
          instructions
        },
        (
          initialOffset,
          globalLabelMap,
          globalLocMap,
          globalNameSlotMap,
          functionCodes
        )
      ) =
      let

        val _ = #start allocateSlotTimeCounter ()

        (* allocate slot *)
        val (newInstructions, frameAllocationInfo) =
            SlotAllocator.allocate (funInfo, instructions)

        val _ = #stop allocateSlotTimeCounter ()


        val _ = #start fixIndexTimeCounter ()

        val (frameSize, slotMap, frameAllocationInfo) =
            SF.fixFrameLayout frameAllocationInfo
        val _ = 
            if 0w0 < #slotCount (#doubles frameAllocationInfo)
            then
              raise Control.Bug "doubles should be empty after fixFrameLayout."
            else ()

        val _ = #stop fixIndexTimeCounter ()


        (* address resolution *)

        val _ = #start calcOffsetTimeCounter ()

        val appendLocMap = 
            if !Control.generateExnHistory
            then LocMap.append
            else fn (locMap, _, _) => locMap

        fun calcOffsetOfLabel (instruction, (nextOffset, labelMap, locMap)) =
            case instruction of
              SI.Label label =>
              let
                val newLabelMap =
                    LabelMap.register (labelMap, label, nextOffset)
              in
                (nextOffset, newLabelMap, locMap)
              end
            | SI.Location loc =>
              (nextOffset, labelMap, appendLocMap (locMap, nextOffset, loc))
            | _ =>
              let val instructionSize = ISC.wordsOfInstruction instruction
              in (nextOffset + instructionSize, labelMap, locMap)
              end
        val bodyStartOffset = initialOffset + (ISC.wordsOfFunEntry funInfo)
        val (lastOffset, labelMap, locMap) =
            foldl
                calcOffsetOfLabel
                (
                  bodyStartOffset,
                  LabelMap.register
                      (globalLabelMap, #id functionVarInfo, initialOffset),
                  appendLocMap(globalLocMap, initialOffset, loc)
                )
            newInstructions

        val _ = #stop calcOffsetTimeCounter ()

        val _ = #start buildNameSlotMapTimeCounter ()

        val nameSlotMap =
            if !Control.generateDebugInfo
            then
              let
                fun LO labelName = LabelMap.find (labelMap, labelName)
                val varInfos = SlotMap.getAll slotMap
                fun register
                        (
                          {id, displayName, slot, beginLabel, endLabel},
                          nameSlotMap
                        ) =
                    let
                      val beginOffset = LO beginLabel
                      val endOffset = LO endLabel
                    in
                      NameSlotMap.append
                      (nameSlotMap, beginOffset, endOffset, displayName, slot)
                    end
              in
                List.foldr register globalNameSlotMap varInfos
              end
            else globalNameSlotMap

        val _ = #stop buildNameSlotMapTimeCounter ()

        val IMFunInfo = 
            {
              frameSize = frameSize,
              startOffset = bodyStartOffset,
              args = #args funInfo,
              bitmapvals = #bitmapvals funInfo,
              pointersSlots = #slotCount (#pointers frameAllocationInfo),
              atomsSlots = #slotCount (#atoms frameAllocationInfo),
              recordsSlots = map #slotCount (#records frameAllocationInfo)
            } : IMFunInfo
        val functionCode = (slotMap, IMFunInfo, newInstructions)
        val newFunctionCodes = (functionCode, loc) :: functionCodes
      in
        (lastOffset, labelMap, locMap, nameSlotMap, newFunctionCodes)
      end
        handle
        exn as E.TooManyRecordGroups =>
        (
          enqueueError (loc, exn);
          (0w0, globalLabelMap, globalLocMap, globalNameSlotMap, [])
        )
      | Control.Bug message => raise Control.BugWithLoc (message, loc)

  local
    (* zero of 16 bits width *)
    val zeroPadding = BT.IntToUInt16 0

  (**
   * translates a symbolic instruction to a raw instruction.
   * <p>
   * NOTE:the instruction should not be a Label instruction
   * </p>
   *)
  fun toRawInstruction VI LO instruction =
      let
      in
        case instruction of
          SI.LoadInt {value, destination} =>
          I.LoadInt {value = value, destination = VI destination}
        | SI.LoadWord {value, destination} =>
          I.LoadWord {value = value, destination = VI destination}
        | SI.LoadString {string, destination} =>
          I.LoadString
          {
            string = LO string,
            destination = VI destination
          }
        | SI.LoadReal {value, destination} =>
          let
            val realValue =
                case Real.fromString value of
                  NONE => raise Control.Bug("invalid real format:" ^ value)
                | SOME real => real
            val operand = 
                {
                 value = BT.RealToReal64 realValue,
                 destination = VI destination
                }
          in
            if !Control.enableUnboxedFloat
            then I.LoadReal operand
            else I.LoadBoxedReal operand
          end
        | SI.LoadChar {value, destination} =>
          I.LoadChar {value = value, destination = VI destination}
        | SI.LoadEmptyBlock {destination} =>
          I.LoadEmptyBlock {destination = VI destination}
        | SI.Access {variableEntry, variableSize, destination} =>
          (case variableSize of
            SI.SINGLE =>
            I.Access_S
                {
                  variableOffset = VI variableEntry,
                  destination = VI destination
               }
          | SI.DOUBLE =>
            I.Access_D
                {
                  variableOffset = VI variableEntry,
                  destination = VI destination
                }
          | SI.VARIANT v =>
            I.Access_V
                {
                  variableOffset = VI variableEntry,
                  variableSize = VI v,
                  destination = VI destination
                })
        | SI.AccessEnv {offset, variableSize, destination} =>
          (case variableSize of
             SI.SINGLE =>
             I.AccessEnv_S
                 {
                   offset = offset, 
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.AccessEnv_D
                 {
                   offset = offset, 
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.AccessEnv_V
                 {
                   offset = offset, 
                   variableSize = VI v,
                   destination = VI destination
                 })
        | SI.AccessEnvIndirect {offset, variableSize, destination} =>
          (case variableSize of
             SI.SINGLE =>
             I.AccessEnvIndirect_S
                 {
                   offset = offset, 
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.AccessEnvIndirect_D
                 {
                   offset = offset, 
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.AccessEnvIndirect_V
                 {
                   offset = offset, 
                   variableSize = VI v,
                   destination = VI destination
                 })
        | SI.AccessNestedEnv {nestLevel, offset, variableSize, destination} =>
          (case variableSize of
             SI.SINGLE =>
             I.AccessNestedEnv_S
                 {
                   nestLevel = nestLevel,
                   offset = offset, 
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.AccessNestedEnv_D
                 {
                   nestLevel = nestLevel,
                   offset = offset, 
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.AccessNestedEnv_V
                 {
                   nestLevel = nestLevel,
                   offset = offset, 
                   variableSize = VI v,
                   destination = VI destination
                 })
        | SI.AccessNestedEnvIndirect
              {nestLevel, offset, variableSize, destination} =>
          (case variableSize of
             SI.SINGLE =>
             I.AccessNestedEnvIndirect_S
                 {
                   nestLevel = nestLevel,
                   offset = offset, 
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.AccessNestedEnvIndirect_D
                 {
                   nestLevel = nestLevel,
                   offset = offset, 
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.AccessNestedEnvIndirect_V
                 {
                   nestLevel = nestLevel,
                   offset = offset, 
                   variableSize = VI v,
                   destination = VI destination
                 })
        | SI.GetField {fieldOffset, fieldSize, blockEntry, destination} =>
          (case fieldSize of
             SI.SINGLE =>
             I.GetField_S
                 {
                   fieldOffset = fieldOffset,
                   blockOffset = VI blockEntry,
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.GetField_D
                 {
                   fieldOffset = fieldOffset,
                   blockOffset = VI blockEntry,
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.GetField_V
                 {
                   fieldOffset = fieldOffset,
                   fieldSize = VI v,
                   blockOffset = VI blockEntry,
                   destination = VI destination
                 })
        | SI.GetFieldIndirect
              {fieldEntry, fieldSize, blockEntry, destination} =>
          (case fieldSize of
             SI.SINGLE =>
             I.GetFieldIndirect_S
                 {
                   fieldOffset = VI fieldEntry,
                   blockOffset = VI blockEntry,
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.GetFieldIndirect_D
                 {
                   fieldOffset = VI fieldEntry,
                   blockOffset = VI blockEntry,
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.GetFieldIndirect_V
                 {
                   fieldOffset = VI fieldEntry,
                   fieldSize = VI v,
                   blockOffset = VI blockEntry,
                   destination = VI destination
                 })
        | SI.GetNestedFieldIndirect
          {nestLevelEntry, offsetEntry, fieldSize, blockEntry, destination} =>
          (case fieldSize of
             SI.SINGLE =>
             I.GetNestedFieldIndirect_S
                 {
                   nestLevel = VI nestLevelEntry,
                   fieldOffset = VI offsetEntry,
                   blockOffset = VI blockEntry,
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.GetNestedFieldIndirect_D
                 {
                   nestLevel = VI nestLevelEntry,
                   fieldOffset = VI offsetEntry,
                   blockOffset = VI blockEntry,
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.GetNestedFieldIndirect_V
                 {
                   nestLevel = VI nestLevelEntry,
                   fieldOffset = VI offsetEntry,
                   fieldSize = VI v,
                   blockOffset = VI blockEntry,
                   destination = VI destination
                 })
        | SI.SetField {fieldOffset, fieldSize, blockEntry, newValueEntry} =>
          (case fieldSize of
             SI.SINGLE =>
             I.SetField_S
                 {
                   fieldOffset = fieldOffset,
                   blockOffset = VI blockEntry,
                   newValueOffset = VI newValueEntry
                 }
           | SI.DOUBLE =>
             I.SetField_D
                 {
                   fieldOffset = fieldOffset,
                   blockOffset = VI blockEntry,
                   newValueOffset = VI newValueEntry
                 }
           | SI.VARIANT v =>
             I.SetField_V
                 {
                   fieldOffset = fieldOffset,
                   fieldSize = VI v,
                   blockOffset = VI blockEntry,
                   newValueOffset = VI newValueEntry
                 })
        | SI.SetFieldIndirect
              {fieldEntry, fieldSize, blockEntry, newValueEntry} =>
          (case fieldSize of
             SI.SINGLE =>
             I.SetFieldIndirect_S
                 {
                   fieldOffset = VI fieldEntry,
                   blockOffset = VI blockEntry,
                   newValueOffset = VI newValueEntry
                 }
           | SI.DOUBLE =>
             I.SetFieldIndirect_D
                 {
                   fieldOffset = VI fieldEntry,
                   blockOffset = VI blockEntry,
                   newValueOffset = VI newValueEntry
                 }
           | SI.VARIANT v =>
             I.SetFieldIndirect_V
                 {
                   fieldOffset = VI fieldEntry,
                   fieldSize = VI v,
                   blockOffset = VI blockEntry,
                   newValueOffset = VI newValueEntry
                 })
        | SI.SetNestedFieldIndirect
              {
                nestLevelEntry,
                offsetEntry,
                fieldSize,
                blockEntry,
                newValueEntry
              } =>
          (case fieldSize of
             SI.SINGLE =>
             I.SetNestedFieldIndirect_S
                 {
                   nestLevel = VI nestLevelEntry,
                   fieldOffset = VI offsetEntry,
                   blockOffset = VI blockEntry,
                   newValueOffset = VI newValueEntry
                 }
           | SI.DOUBLE =>
             I.SetNestedFieldIndirect_D
                 {
                   nestLevel = VI nestLevelEntry,
                   fieldOffset = VI offsetEntry,
                   blockOffset = VI blockEntry,
                   newValueOffset = VI newValueEntry
                 }
           | SI.VARIANT v =>
             I.SetNestedFieldIndirect_V
                 {
                   nestLevel = VI nestLevelEntry,
                   fieldOffset = VI offsetEntry,
                   fieldSize = VI v,
                   blockOffset = VI blockEntry,
                   newValueOffset = VI newValueEntry
                 })
        | SI.CopyBlock {blockEntry, destination} =>
          I.CopyBlock
          {
            blockOffset = VI blockEntry,
            destination = VI destination
          }

        | SI.GetGlobal{globalArrayIndex,offset,variableSize,destination} =>
          (
           case variableSize of
             SI.SINGLE =>
             I.GetGlobal_S
                 {
                  globalArrayIndex = globalArrayIndex,
                  offset = offset,
                  destination = VI destination
                 }
           | SI.DOUBLE =>
             I.GetGlobal_D
                 {
                  globalArrayIndex = globalArrayIndex,
                  offset = offset,
                  destination = VI destination
                 }
           | SI.VARIANT v => raise Control.Bug "global object must have fixed size"
          )
        | SI.SetGlobal{globalArrayIndex,offset,variableSize,newValueEntry} =>
          (
           case variableSize of
             SI.SINGLE =>
             I.SetGlobal_S
                 {
                  globalArrayIndex = globalArrayIndex,
                  offset = offset,
                  variableOffset = VI newValueEntry
                 }
           | SI.DOUBLE =>
             I.SetGlobal_D
                 {
                  globalArrayIndex = globalArrayIndex,
                  offset = offset,
                  variableOffset = VI newValueEntry
                 }
           | SI.VARIANT v => raise Control.Bug "global object must have fixed size"
          )
        | SI.InitGlobalArrayUnboxed{globalArrayIndex,arraySize} =>
          I.InitGlobalArrayUnboxed
              {
               globalArrayIndex = globalArrayIndex,
               arraySize = arraySize
              }
        | SI.InitGlobalArrayBoxed{globalArrayIndex,arraySize} =>
          I.InitGlobalArrayBoxed
              {
               globalArrayIndex = globalArrayIndex,
               arraySize = arraySize
              }
        | SI.InitGlobalArrayDouble{globalArrayIndex,arraySize} =>
          I.InitGlobalArrayDouble
              {
               globalArrayIndex = globalArrayIndex,
               arraySize = arraySize
              }
        | SI.GetEnv {destination} => I.GetEnv {destination = VI destination}
        | SI.CallPrim
              {
                argsCount,
                primitive,
                argEntries,
                argSizes,
                destination,
                resultSize
              } =>
          (case #instruction primitive of
             P.Internal1 maker =>
             maker
                 ({
                   argIndex = VI (hd argEntries),
                   destination = VI destination
                 } : P.operand1)
           | P.Internal2 maker => 
             maker
                 ({
                   argIndex1 = VI (hd argEntries),
                   argIndex2 = VI (hd (tl argEntries)),
                   destination = VI destination
                 } : P.operand2)
           | P.Internal3 maker => 
             maker
                 ({
                   argIndex1 = VI (hd argEntries),
                   argIndex2 = VI (hd (tl argEntries)),
                   argIndex3 = VI (hd (tl (tl argEntries))),
                   destination = VI destination
                 } : P.operand3)
           | P.InternalN maker => 
             maker
                 ({
                   argsCount = argsCount,
                   argIndexes = map VI argEntries,
                   destination = VI destination
                 } : P.operandN)
           | P.External primitive => 
             I.CallPrim
             {
               argsCount = argsCount,
               primitive = BT.IntToUInt32 primitive,
               argIndexes = map VI argEntries,
               destination = VI destination
             })
        | SI.ForeignApply
              {
                argsCount,
                closureEntry,
                argEntries,
                argSizes,
                resultSize,
                destination
              } =>
          I.ForeignApply
              {
                argsCount = argsCount,
                closureOffset = VI closureEntry,
                argIndexes = map VI argEntries,
                destination = VI destination
              }
        | SI.Apply_S
          {closureEntry, argEntry, argSize, destination} =>
          (case argSize of
             SI.SINGLE =>
             I.Apply_S
                 {
                   closureOffset = VI closureEntry,
                   argOffset = VI argEntry,
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.Apply_D
                 {
                   closureOffset = VI closureEntry,
                   argOffset = VI argEntry,
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.Apply_V
                 {
                   closureOffset = VI closureEntry,
                   argOffset = VI argEntry,
                   argSizeOffset = VI v,
                   destination = VI destination
                 })
        | SI.Apply_ML
          {argsCount, closureEntry, argEntries, lastArgSize, destination} =>
          (case lastArgSize of
             SI.SINGLE =>
             I.Apply_ML_S
                 {
                   argsCount = argsCount,
                   closureOffset = VI closureEntry,
                   argOffsets = map VI argEntries,
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.Apply_ML_D
                 {
                   argsCount = argsCount,
                   closureOffset = VI closureEntry,
                   argOffsets = map VI argEntries,
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.Apply_ML_V
                 {
                   argsCount = argsCount,
                   closureOffset = VI closureEntry,
                   argOffsets = map VI argEntries,
                   lastArgSizeOffset = VI v,
                   destination = VI destination
                 })
        | SI.Apply_M
          {argsCount, closureEntry, argEntries, argSizeEntries, destination} =>
          I.Apply_M
              {
               argsCount = argsCount,
               closureOffset = VI closureEntry,
               argOffsets = map VI argEntries,
               argSizeOffsets = map VI argSizeEntries,
               destination = VI destination
              }
        | SI.TailApply_S
          {closureEntry, argEntry, argSize} =>
          (case argSize of
             SI.SINGLE =>
             I.TailApply_S
                 {
                   closureOffset = VI closureEntry,
                   argOffset = VI argEntry
                 }
           | SI.DOUBLE =>
             I.TailApply_D
                 {
                   closureOffset = VI closureEntry,
                   argOffset = VI argEntry
                 }
           | SI.VARIANT v =>
             I.TailApply_V
                 {
                   closureOffset = VI closureEntry,
                   argOffset = VI argEntry,
                   argSizeOffset = VI v
                 })
        | SI.TailApply_ML
          {argsCount, closureEntry, argEntries, lastArgSize} =>
          (case lastArgSize of
             SI.SINGLE =>
             I.TailApply_ML_S
                 {
                   argsCount = argsCount,
                   closureOffset = VI closureEntry,
                   argOffsets = map VI argEntries
                 }
           | SI.DOUBLE =>
             I.TailApply_ML_D
                 {
                   argsCount = argsCount,
                   closureOffset = VI closureEntry,
                   argOffsets = map VI argEntries
                 }
           | SI.VARIANT v =>
             I.TailApply_ML_V
                 {
                   argsCount = argsCount,
                   closureOffset = VI closureEntry,
                   argOffsets = map VI argEntries,
                   lastArgSizeOffset = VI v
                 })
        | SI.TailApply_M
          {argsCount, closureEntry, argEntries, argSizeEntries} =>
          I.TailApply_M
              {
               argsCount = argsCount,
               closureOffset = VI closureEntry,
               argOffsets = map VI argEntries,
               argSizeOffsets = map VI argSizeEntries
              }
        | SI.CallStatic_S
              {entryPoint, envEntry, argEntry, argSize, destination} =>
          (case argSize of
             SI.SINGLE =>
             I.CallStatic_S
                 {
                   entryPoint = LO entryPoint,
                   envOffset = VI envEntry,
                   argOffset = VI argEntry,
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.CallStatic_D
                 {
                   entryPoint = LO entryPoint,
                   envOffset = VI envEntry,
                   argOffset = VI argEntry,
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.CallStatic_V
                 {
                   entryPoint = LO entryPoint,
                   envOffset = VI envEntry,
                   argOffset = VI argEntry,
                   argSizeOffset = VI v,
                   destination = VI destination
                 })
        | SI.CallStatic_ML
              {argsCount, entryPoint, envEntry, argEntries, lastArgSize, destination} =>
          (case lastArgSize of
             SI.SINGLE =>
             I.CallStatic_ML_S
                 {
                   argsCount = argsCount,
                   entryPoint = LO entryPoint,
                   envOffset = VI envEntry,
                   argOffsets = map VI argEntries,
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.CallStatic_ML_D
                 {
                   argsCount = argsCount,
                   entryPoint = LO entryPoint,
                   envOffset = VI envEntry,
                   argOffsets = map VI argEntries,
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.CallStatic_ML_V
                 {
                   argsCount = argsCount,
                   entryPoint = LO entryPoint,
                   envOffset = VI envEntry,
                   argOffsets = map VI argEntries,
                   lastArgSizeOffset = VI v,
                   destination = VI destination
                 })
        | SI.CallStatic_M
              {argsCount, entryPoint, envEntry, argEntries, argSizeEntries, destination} =>
          I.CallStatic_M
              {
               argsCount = argsCount,
               entryPoint = LO entryPoint,
               envOffset = VI envEntry,
               argOffsets = map VI argEntries,
               argSizeOffsets = map VI argSizeEntries,
               destination = VI destination
              }
        | SI.TailCallStatic_S
              {entryPoint, envEntry, argEntry, argSize} =>
          (case argSize of
             SI.SINGLE =>
             I.TailCallStatic_S
                 {
                   entryPoint = LO entryPoint,
                   envOffset = VI envEntry,
                   argOffset = VI argEntry
                 }
           | SI.DOUBLE =>
             I.TailCallStatic_D
                 {
                   entryPoint = LO entryPoint,
                   envOffset = VI envEntry,
                   argOffset = VI argEntry
                 }
           | SI.VARIANT v =>
             I.TailCallStatic_V
                 {
                   entryPoint = LO entryPoint,
                   envOffset = VI envEntry,
                   argOffset = VI argEntry,
                   argSizeOffset = VI v
                 })
        | SI.TailCallStatic_ML
              {argsCount, entryPoint, envEntry, argEntries, lastArgSize} =>
          (case lastArgSize of
             SI.SINGLE =>
             I.TailCallStatic_ML_S
                 {
                   argsCount = argsCount,
                   entryPoint = LO entryPoint,
                   envOffset = VI envEntry,
                   argOffsets = map VI argEntries
                 }
           | SI.DOUBLE =>
             I.TailCallStatic_ML_D
                 {
                   argsCount = argsCount,
                   entryPoint = LO entryPoint,
                   envOffset = VI envEntry,
                   argOffsets = map VI argEntries
                 }
           | SI.VARIANT v =>
             I.TailCallStatic_ML_V
                 {
                   argsCount = argsCount,
                   entryPoint = LO entryPoint,
                   envOffset = VI envEntry,
                   argOffsets = map VI argEntries,
                   lastArgSizeOffset = VI v
                 })
        | SI.TailCallStatic_M
              {argsCount, entryPoint, envEntry, argEntries, argSizeEntries} =>
          I.TailCallStatic_M
              {
               argsCount = argsCount,
               entryPoint = LO entryPoint,
               envOffset = VI envEntry,
               argOffsets = map VI argEntries,
               argSizeOffsets = map VI argSizeEntries
              }

        | SI.RecursiveCallStatic_S
              {entryPoint, argEntry, argSize, destination} =>
          (case argSize of
             SI.SINGLE =>
             I.RecursiveCallStatic_S
                 {
                   entryPoint = LO entryPoint,
                   argOffset = VI argEntry,
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.RecursiveCallStatic_D
                 {
                   entryPoint = LO entryPoint,
                   argOffset = VI argEntry,
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.RecursiveCallStatic_V
                 {
                   entryPoint = LO entryPoint,
                   argOffset = VI argEntry,
                   argSizeOffset = VI v,
                   destination = VI destination
                 })
        | SI.RecursiveCallStatic_M
              {argsCount, entryPoint, argEntries, argSizeEntries, destination} =>
          I.RecursiveCallStatic_M
              {
               entryPoint = LO entryPoint,
               argsCount = argsCount,
               argOffsets = map VI argEntries,
               argSizeOffsets = map VI argSizeEntries,
               destination = VI destination
              }
        | SI.RecursiveTailCallStatic_S
              {entryPoint, argEntry, argSize} =>
          (case argSize of
             SI.SINGLE =>
             I.RecursiveTailCallStatic_S
                 {
                   entryPoint = LO entryPoint,
                   argOffset = VI argEntry
                 }
           | SI.DOUBLE =>
             I.RecursiveTailCallStatic_D
                 {
                   entryPoint = LO entryPoint,
                   argOffset = VI argEntry
                 }
           | SI.VARIANT v =>
             I.RecursiveTailCallStatic_V
                 {
                   entryPoint = LO entryPoint,
                   argOffset = VI argEntry,
                   argSizeOffset = VI v
                 })
        | SI.RecursiveTailCallStatic_M
              {argsCount, entryPoint, argEntries, argSizeEntries} =>
          I.RecursiveTailCallStatic_M
              {
               entryPoint = LO entryPoint,
               argsCount = argsCount,
               argOffsets = map VI argEntries,
               argSizeOffsets = map VI argSizeEntries
              }
        | SI.SelfRecursiveCallStatic_S
              {entryPoint, argEntry, argSize, destination} =>
          (case argSize of
             SI.SINGLE =>
             I.SelfRecursiveCallStatic_S
                 {
                   entryPoint = LO entryPoint,
                   argOffset = VI argEntry,
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.SelfRecursiveCallStatic_D
                 {
                   entryPoint = LO entryPoint,
                   argOffset = VI argEntry,
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.SelfRecursiveCallStatic_V
                 {
                   entryPoint = LO entryPoint,
                   argOffset = VI argEntry,
                   argSizeOffset = VI v,
                   destination = VI destination
                 })
        | SI.SelfRecursiveCallStatic_M
              {argsCount, entryPoint, argEntries, argSizeEntries, destination} =>
          I.SelfRecursiveCallStatic_M
              {
               entryPoint = LO entryPoint,
               argsCount = argsCount,
               argOffsets = map VI argEntries,
               argSizeOffsets = map VI argSizeEntries,
               destination = VI destination
              }
        | SI.SelfRecursiveTailCallStatic_S
              {entryPoint, argEntry, argSize} =>
          (case argSize of
             SI.SINGLE =>
             I.SelfRecursiveTailCallStatic_S
                 {
                   entryPoint = LO entryPoint,
                   argOffset = VI argEntry
                 }
           | SI.DOUBLE =>
             I.SelfRecursiveTailCallStatic_D
                 {
                   entryPoint = LO entryPoint,
                   argOffset = VI argEntry
                 }
           | SI.VARIANT v =>
             I.SelfRecursiveTailCallStatic_V
                 {
                   entryPoint = LO entryPoint,
                   argOffset = VI argEntry,
                   argSizeOffset = VI v
                 })
        | SI.SelfRecursiveTailCallStatic_M
              {argsCount, entryPoint, argEntries, argSizeEntries} =>
          I.SelfRecursiveTailCallStatic_M
              {
               entryPoint = LO entryPoint,
               argsCount = argsCount,
               argOffsets = map VI argEntries,
               argSizeOffsets = map VI argSizeEntries
              }
        | SI.MakeBlock
              {
                fieldsCount,
                bitmapEntry,
                sizeEntry,
                fieldEntries,
                fieldSizeEntries,
                destination
              } =>
          I.MakeBlock
          {
            fieldsCount = fieldsCount,
            bitmapIndex = VI bitmapEntry,
            sizeIndex = VI sizeEntry,
            fieldIndexes = map VI fieldEntries,
            fieldSizeIndexes = map VI fieldSizeEntries,
            destination = VI destination
          }
        | SI.MakeBlockOfSingleValues
              {
               fieldsCount,
               bitmapEntry,
               fieldEntries,
               destination
              } =>
          I.MakeBlockOfSingleValues
              {
               bitmapIndex = VI bitmapEntry,
               fieldsCount = fieldsCount,
               fieldIndexes = map VI fieldEntries,
               destination = VI destination
              }
        | SI.MakeArray
              {
                bitmapEntry,
                sizeEntry,
                initialValueEntry,
                initialValueSize,
                destination
              } =>
          (case initialValueSize of
             SI.SINGLE =>
             I.MakeArray_S
                 {
                  bitmapIndex = VI bitmapEntry,
                  sizeIndex = VI sizeEntry,
                  initialValueIndex = VI initialValueEntry,
                  destination = VI destination
                 }
           | SI.DOUBLE =>
             I.MakeArray_D
                 {
                  bitmapIndex = VI bitmapEntry,
                  sizeIndex = VI sizeEntry,
                  initialValueIndex = VI initialValueEntry,
                  destination = VI destination
                 }
           | SI.VARIANT v =>
             I.MakeArray_V
                 {
                  bitmapIndex = VI bitmapEntry,
                  sizeIndex = VI sizeEntry,
                  initialValueIndex = VI initialValueEntry,
                  initialValueSize = VI v,
                  destination = VI destination
                 }
          )
        | SI.MakeClosure {entryPoint, ENVEntry, destination} =>
          I.MakeClosure
          {
            entryPoint = LO entryPoint,
            ENVOffset = VI ENVEntry,
            destination = VI destination
          }
        | SI.Raise {exceptionEntry} =>
          I.Raise {exceptionOffset = VI exceptionEntry}
        | SI.PushHandler{handler, exceptionEntry} =>
          I.PushHandler
          {
            handler = LO handler,
            exceptionOffset = VI exceptionEntry
          }
        | SI.PopHandler => I.PopHandler
        | SI.Label _ => raise Control.Bug "Label is not expected."
        | SI.Location _ => raise Control.Bug "Label is not expected."
        | SI.SwitchInt{targetEntry, casesCount, cases, default} =>
          I.SwitchInt
          {
            targetOffset = VI targetEntry,
            casesCount = casesCount,
            cases =
            List.concat
            (map
             (fn {const, destination} =>
                 [const, BT.UInt32ToSInt32(LO destination)])
             cases),
            default = LO default
          }
        | SI.SwitchWord{targetEntry, casesCount, cases, default} =>
          I.SwitchWord
          {
            targetOffset = VI targetEntry,
            casesCount = casesCount,
            cases =
            List.concat
            (map (fn {const, destination} => [const, LO destination]) cases),
            default = LO default
          }
        | SI.SwitchChar{targetEntry, casesCount, cases, default} =>
          I.SwitchChar
          {
            targetOffset = VI targetEntry,
            casesCount = casesCount,
            cases =
            List.concat
            (map (fn {const, destination} => [const, LO destination]) cases),
            default = LO default
          }
        | SI.SwitchString{targetEntry, casesCount, cases, default} =>
          I.SwitchString
          {
            targetOffset = VI targetEntry,
            casesCount = casesCount,
            cases =
            List.concat
            (map
                 (fn {const, destination} => [LO const, LO destination])
                 cases),
            default = LO default
          }
        | SI.Jump {destination} => I.Jump{destination = LO destination}
        | SI.Exit => I.Exit
        | SI.Return {variableEntry, variableSize} =>
          (case variableSize of
             SI.SINGLE => I.Return_S {variableOffset = VI variableEntry}
           | SI.DOUBLE => I.Return_D {variableOffset = VI variableEntry}
           | SI.VARIANT v =>
             I.Return_V
                 {
                   variableOffset = VI variableEntry,
                   variableSize = VI v
                 })
        | SI.ConstString {string} =>
          I.ConstString
          {
            length = UInt32.fromInt (String.size string),
            string = BT.StringToPaddedUInt8List string
          }
        | SI.FFIVal {funNameEntry, libNameEntry, destination} =>
          I.FFIVal
              {
                funNameOffset = VI funNameEntry,
                libNameOffset = VI libNameEntry,
                destination = VI destination
              }

        | SI.AddInt_Const_1{argValue1, argEntry2, destination} =>
          I.AddInt_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.AddInt_Const_2{argEntry1, argValue2, destination} =>
          I.AddInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.AddReal_Const_1{argValue1, argEntry2, destination} =>
          let
            val realValue =
                case Real.fromString argValue1 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue1)
                | SOME real => real
          in
            I.AddReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.AddReal_Const_2{argEntry1, argValue2, destination} =>
          let
            val realValue =
                case Real.fromString argValue2 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue2)
                | SOME real => real
          in
            I.AddReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }

          end
        | SI.AddWord_Const_1{argValue1, argEntry2, destination} =>
          I.AddWord_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.AddWord_Const_2{argEntry1, argValue2, destination} =>
          I.AddWord_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.AddByte_Const_1{argValue1, argEntry2, destination} =>
          I.AddByte_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.AddByte_Const_2{argEntry1, argValue2, destination} =>
          I.AddByte_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

        | SI.SubInt_Const_1{argValue1, argEntry2, destination} =>
          I.SubInt_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.SubInt_Const_2{argEntry1, argValue2, destination} =>
          I.SubInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.SubReal_Const_1{argValue1, argEntry2, destination} =>
          let
            val realValue =
                case Real.fromString argValue1 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue1)
                | SOME real => real
          in
            I.SubReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.SubReal_Const_2{argEntry1, argValue2, destination} =>
          let
            val realValue =
                case Real.fromString argValue2 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue2)
                | SOME real => real
          in
            I.SubReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }

          end
        | SI.SubWord_Const_1{argValue1, argEntry2, destination} =>
          I.SubWord_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.SubWord_Const_2{argEntry1, argValue2, destination} =>
          I.SubWord_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.SubByte_Const_1{argValue1, argEntry2, destination} =>
          I.SubByte_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.SubByte_Const_2{argEntry1, argValue2, destination} =>
          I.SubByte_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

        | SI.MulInt_Const_1{argValue1, argEntry2, destination} =>
          I.MulInt_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.MulInt_Const_2{argEntry1, argValue2, destination} =>
          I.MulInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.MulReal_Const_1{argValue1, argEntry2, destination} =>
          let
            val realValue =
                case Real.fromString argValue1 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue1)
                | SOME real => real
          in
            I.MulReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.MulReal_Const_2{argEntry1, argValue2, destination} =>
          let
            val realValue =
                case Real.fromString argValue2 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue2)
                | SOME real => real
          in
            I.MulReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }

          end
        | SI.MulWord_Const_1{argValue1, argEntry2, destination} =>
          I.MulWord_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.MulWord_Const_2{argEntry1, argValue2, destination} =>
          I.MulWord_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.MulByte_Const_1{argValue1, argEntry2, destination} =>
          I.MulByte_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.MulByte_Const_2{argEntry1, argValue2, destination} =>
          I.MulByte_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

        | SI.DivInt_Const_1{argValue1, argEntry2, destination} =>
          I.DivInt_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.DivInt_Const_2{argEntry1, argValue2, destination} =>
          I.DivInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.DivReal_Const_1{argValue1, argEntry2, destination} =>
          let
            val realValue =
                case Real.fromString argValue1 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue1)
                | SOME real => real
          in
            I.DivReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.DivReal_Const_2{argEntry1, argValue2, destination} =>
          let
            val realValue =
                case Real.fromString argValue2 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue2)
                | SOME real => real
          in
            I.DivReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }

          end
        | SI.DivWord_Const_1{argValue1, argEntry2, destination} =>
          I.DivWord_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.DivWord_Const_2{argEntry1, argValue2, destination} =>
          I.DivWord_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.DivByte_Const_1{argValue1, argEntry2, destination} =>
          I.DivByte_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.DivByte_Const_2{argEntry1, argValue2, destination} =>
          I.DivByte_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

        | SI.ModInt_Const_1{argValue1, argEntry2, destination} =>
          I.ModInt_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.ModInt_Const_2{argEntry1, argValue2, destination} =>
          I.ModInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.ModWord_Const_1{argValue1, argEntry2, destination} =>
          I.ModWord_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.ModWord_Const_2{argEntry1, argValue2, destination} =>
          I.ModWord_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.ModByte_Const_1{argValue1, argEntry2, destination} =>
          I.ModByte_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.ModByte_Const_2{argEntry1, argValue2, destination} =>
          I.ModByte_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

        | SI.QuotInt_Const_1{argValue1, argEntry2, destination} =>
          I.QuotInt_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.QuotInt_Const_2{argEntry1, argValue2, destination} =>
          I.QuotInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

        | SI.RemInt_Const_1{argValue1, argEntry2, destination} =>
          I.RemInt_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.RemInt_Const_2{argEntry1, argValue2, destination} =>
          I.RemInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

(* temporarily disable

        | SI.LtInt_Const_1{argValue1, argEntry2, destination} =>
          I.LtInt_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.LtInt_Const_2{argEntry1, argValue2, destination} =>
          I.LtInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.LtReal_Const_1{argValue1, argEntry2, destination} =>
          let
            val realValue =
                case Real.fromString argValue1 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue1)
                | SOME real => real
          in
            I.LtReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.LtReal_Const_2{argEntry1, argValue2, destination} =>
          let
            val realValue =
                case Real.fromString argValue2 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue2)
                | SOME real => real
          in
            I.LtReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }

          end
        | SI.LtWord_Const_1{argValue1, argEntry2, destination} =>
          I.LtWord_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.LtWord_Const_2{argEntry1, argValue2, destination} =>
          I.LtWord_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.LtByte_Const_1{argValue1, argEntry2, destination} =>
          I.LtByte_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.LtByte_Const_2{argEntry1, argValue2, destination} =>
          I.LtByte_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.LtChar_Const_1{argValue1, argEntry2, destination} =>
          I.LtChar_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.LtChar_Const_2{argEntry1, argValue2, destination} =>
          I.LtChar_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

        | SI.GtInt_Const_1{argValue1, argEntry2, destination} =>
          I.GtInt_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.GtInt_Const_2{argEntry1, argValue2, destination} =>
          I.GtInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.GtReal_Const_1{argValue1, argEntry2, destination} =>
          let
            val realValue =
                case Real.fromString argValue1 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue1)
                | SOME real => real
          in
            I.GtReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.GtReal_Const_2{argEntry1, argValue2, destination} =>
          let
            val realValue =
                case Real.fromString argValue2 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue2)
                | SOME real => real
          in
            I.GtReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }

          end
        | SI.GtWord_Const_1{argValue1, argEntry2, destination} =>
          I.GtWord_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.GtWord_Const_2{argEntry1, argValue2, destination} =>
          I.GtWord_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.GtByte_Const_1{argValue1, argEntry2, destination} =>
          I.GtByte_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.GtByte_Const_2{argEntry1, argValue2, destination} =>
          I.GtByte_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.GtChar_Const_1{argValue1, argEntry2, destination} =>
          I.GtChar_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.GtChar_Const_2{argEntry1, argValue2, destination} =>
          I.GtChar_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

        | SI.LteqInt_Const_1{argValue1, argEntry2, destination} =>
          I.LteqInt_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.LteqInt_Const_2{argEntry1, argValue2, destination} =>
          I.LteqInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.LteqReal_Const_1{argValue1, argEntry2, destination} =>
          let
            val realValue =
                case Real.fromString argValue1 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue1)
                | SOME real => real
          in
            I.LteqReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.LteqReal_Const_2{argEntry1, argValue2, destination} =>
          let
            val realValue =
                case Real.fromString argValue2 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue2)
                | SOME real => real
          in
            I.LteqReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }

          end
        | SI.LteqWord_Const_1{argValue1, argEntry2, destination} =>
          I.LteqWord_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.LteqWord_Const_2{argEntry1, argValue2, destination} =>
          I.LteqWord_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.LteqByte_Const_1{argValue1, argEntry2, destination} =>
          I.LteqByte_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.LteqByte_Const_2{argEntry1, argValue2, destination} =>
          I.LteqByte_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.LteqChar_Const_1{argValue1, argEntry2, destination} =>
          I.LteqChar_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.LteqChar_Const_2{argEntry1, argValue2, destination} =>
          I.LteqChar_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

        | SI.GteqInt_Const_1{argValue1, argEntry2, destination} =>
          I.GteqInt_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.GteqInt_Const_2{argEntry1, argValue2, destination} =>
          I.GteqInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.GteqReal_Const_1{argValue1, argEntry2, destination} =>
          let
            val realValue =
                case Real.fromString argValue1 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue1)
                | SOME real => real
          in
            I.GteqReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.GteqReal_Const_2{argEntry1, argValue2, destination} =>
          let
            val realValue =
                case Real.fromString argValue2 of
                  NONE => raise Control.Bug("invalid real format:" ^ argValue2)
                | SOME real => real
          in
            I.GteqReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }

          end
        | SI.GteqWord_Const_1{argValue1, argEntry2, destination} =>
          I.GteqWord_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.GteqWord_Const_2{argEntry1, argValue2, destination} =>
          I.GteqWord_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.GteqByte_Const_1{argValue1, argEntry2, destination} =>
          I.GteqByte_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.GteqByte_Const_2{argEntry1, argValue2, destination} =>
          I.GteqByte_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }
        | SI.GteqChar_Const_1{argValue1, argEntry2, destination} =>
          I.GteqChar_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.GteqChar_Const_2{argEntry1, argValue2, destination} =>
          I.GteqChar_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

*)

        | SI.Word_andb_Const_1{argValue1, argEntry2, destination} =>
          I.Word_andb_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.Word_andb_Const_2{argEntry1, argValue2, destination} =>
          I.Word_andb_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

        | SI.Word_orb_Const_1{argValue1, argEntry2, destination} =>
          I.Word_orb_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.Word_orb_Const_2{argEntry1, argValue2, destination} =>
          I.Word_orb_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

        | SI.Word_xorb_Const_1{argValue1, argEntry2, destination} =>
          I.Word_xorb_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.Word_xorb_Const_2{argEntry1, argValue2, destination} =>
          I.Word_xorb_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

        | SI.Word_leftShift_Const_1{argValue1, argEntry2, destination} =>
          I.Word_leftShift_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.Word_leftShift_Const_2{argEntry1, argValue2, destination} =>
          I.Word_leftShift_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

        | SI.Word_logicalRightShift_Const_1{argValue1, argEntry2, destination} =>
          I.Word_logicalRightShift_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.Word_logicalRightShift_Const_2{argEntry1, argValue2, destination} =>
          I.Word_logicalRightShift_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

        | SI.Word_arithmeticRightShift_Const_1{argValue1, argEntry2, destination} =>
          I.Word_arithmeticRightShift_Const_1
          {
           argValue1 = argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.Word_arithmeticRightShift_Const_2{argEntry1, argValue2, destination} =>
          I.Word_arithmeticRightShift_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = argValue2,
           destination = VI destination
          }

      end

  fun length list = BT.IntToUInt32(List.length list)

  (* NOTE: Because the number of args is not so many, the linear search
   *     will not harm. *)
  fun indexOfArgInArgs (funInfo : IMFunInfo) (arg : SI.varInfo) =
      let
        fun findi _ [] =
            raise
              Control.Bug (ID.toString (#id arg) ^ " is not found in args.")
          | findi index ((hdArg : SI.varInfo) :: tlArgs) =
            if #id hdArg = #id arg
            then index
            else findi (index + 0w1) tlArgs
      in findi (0w0 : BT.UInt32) (#args funInfo) end

  in (* local *)

  (**
   *  Translates a function code to a list of raw instructions, replacing
   * symbolic references with indexes and offsets using maps built by the
   * first subphase.
   * This is the first half of assemble process.
   * <p>
   * NOTE: While the label map is shared by all functions,
   * the variable map is local within each function.
   * </p>
   *
   * @params
   *   labelMap (slotMap, funInfo, symbolicInstructions)
   * @param labelMap the label environment
   * @param slotMap the variable environment
   * @param funInfo the funInfo of this function
   * @param symbolicInstructions a list of symbolic instructions and location
   * @return a raw instructions list to which the raw instructions for this
   *       function
   *)
  fun toRawInstructions
          labelMap
          (
            ((slotMap, funInfo, instructions) : IMFunctionCode, loc),
            rawInstructions
          ) =
      let
        fun VI varInfo = #slot (SlotMap.find (slotMap, varInfo))
        fun LO labelName = LabelMap.find (labelMap, labelName)

        val indexInArgs = indexOfArgInArgs funInfo

        val rawFunEntry =
            I.FunEntry
            {
              startOffset = #startOffset funInfo,
              arity = length (#args funInfo),
              argsdest = map VI (#args funInfo),
              bitmapvalsArgsCount = length(#args(#bitmapvals funInfo)),
              bitmapvalsArgs = map indexInArgs (#args(#bitmapvals funInfo)),
              bitmapvalsFreesCount = length(#frees(#bitmapvals funInfo)),
              bitmapvalsFrees = #frees(#bitmapvals funInfo),
              frameSize = #frameSize funInfo,
              pointers = #pointersSlots funInfo,
              atoms = #atomsSlots funInfo,
              recordGroupsCount = length(#recordsSlots funInfo),
              recordGroups = #recordsSlots funInfo
           }

        fun translate (SI.Label _, rawInstructions) = rawInstructions
          | translate (SI.Location _, rawInstructions) = rawInstructions
          | translate (symInstruction, rawInstructions) =
            let
              val rawInstruction =
                  toRawInstruction VI LO symInstruction
(*
              (* check code *)
              val tempBuffer = Word8Array.array (10240, 0w0)
              val calculatedSize =
                  BT.UInt32ToInt (ISC.wordsOfInstruction symInstruction) * 4
              val serializedSize =
                  InstructionSerializer.serialize
                      ([rawInstruction], tempBuffer, 0)
              val _ =
                  if calculatedSize <> serializedSize
                  then
                    raise
                      Control.Bug
                          ("incorrect size of instruction:\
                           \ instruction = " ^
                           SIF.instructionToString symInstruction
                           ^ ", calculated = " ^ Int.toString calculatedSize
                           ^ ", serialized = " ^ Int.toString serializedSize)
                  else ()
*)
            in
              rawInstruction :: rawInstructions
            end
      in
        rawFunEntry :: (foldr translate rawInstructions instructions)
      end
        handle Control.Bug message => raise Control.BugWithLoc (message, loc)

  end (* local *)

  local
    fun packString fileName =
        {
          length = UInt32.fromInt (String.size fileName),
          string = BT.StringToPaddedUInt8List fileName
        }
    fun packStringList strings =
        let
          val packedStrings = map packString strings
          val (_, stringOffsets) =
              List.foldl
                  (fn ({string, ...}, (lastOffset, offsets)) =>
                      let
                        val words =
                            0w1 (* one word where string length is stored. *)
                            + (UInt32.fromInt(List.length string) div 0w4)
                      in (lastOffset + words, lastOffset :: offsets) end)
                  (0w0, [])
                  packedStrings
        in (packedStrings, List.rev stringOffsets)
        end
  in
  fun buildLocationTable (locationTableEntries, fileNames) =
      let
        val (packedFileNames, fileNameOffsets) = packStringList fileNames
      in
        {
          locationsCount = UInt32.fromInt (List.length locationTableEntries),
          locations = locationTableEntries,
          fileNamesCount = UInt32.fromInt (List.length fileNames),
          fileNameOffsets = fileNameOffsets,
          fileNames = packedFileNames
        } : Executable.locationTable
      end
  fun buildNameSlotTable (nameSlotTableEntries, boundNames) =
      let
        val (packedBoundNames, boundNameOffsets) = packStringList boundNames
      in
        {
          nameSlotsCount = UInt32.fromInt (List.length nameSlotTableEntries),
          nameSlots = nameSlotTableEntries,
          boundNamesCount = UInt32.fromInt (List.length boundNames),
          boundNameOffsets = boundNameOffsets,
          boundNames = packedBoundNames
        } : Executable.nameSlotTable
      end
  end

  (**
   *  Translate symolic instructions to raw instructions.
   * <p>
   * This function replaces the symbolic references with the slot index and
   * the offset.
   * To accomplish this, it does:
   * <ul>
   *   <li>allocates frame slot to each local variables and passed arguments.
   *   </li>
   *   <li>calculates the offset of each instruction from the beginning of
   *       code block.</li>
   * </ul>
   * </p>
   * <p>
   * Frame slot allocation of this version adopts simple algorithm.
   * To each variable, one slot is allocated. That is, the number of slots is
   * equal to the number of variables.
   * </p>
   * <p>
   * This phase consists of two subphases.
   * The first subphase builds the two maps:
   * <ul>
   *   <li>a map from variable to its slot index</li>
   *   <li>a map from label to its offset from the beginning of
   *       the code sequence obtained by concatenation of code sequences
   *       previously built for other preceding functions</li>
   * </ul>
   * The second subphase translates each instruction, replacing operands using
   * these maps.
   * <ul>
   *   <li>local variable name is replaced with its slot index.</li>
   *   <li>label reference is replaced with its offset</li>
   * </ul>
   * </p>
   *
   * @params {mainFunctionName, functions}
   * @param mainFunctionName the name of the main function. Other functions
   *                   are called directly or indirectly from this function.
   * @param functions a list of pairs of function information and
   *                      symbolic instructions of the body of the function
   * @return a list of raw instructions
   *)
  fun assemble {mainFunctionName, functions = SIfunctionCodes} =
      let
        val _ = initializeErrorQueue ()

        val initialOffset = 0w0 : BT.UInt32

        val _ = #start firstPassTimeCounter ()

        (* first subphase *)
        val (lastOffset, labelMap, locMap, nameSlotMap, IMfunctionCodes) =
            foldl
                buildMaps
                (
                  initialOffset,
                  LabelMap.empty,
                  LocMap.empty,
                  NameSlotMap.empty,
                  []
                )
            SIfunctionCodes
        val IMfunctionCodes = List.rev IMfunctionCodes

        val _ = #stop firstPassTimeCounter ()

        val _ = #start makeDebugInfoTimeCounter ()

        val locationTable =
            if !Control.generateExnHistory
            then
              let
                val (locationTableEntries, fileNames) = LocMap.getAll locMap
(*
val _ = print "locations:\n"
val _ = List.app (fn ent => (print "  ";print (Executable.locationTableEntryToString ent); print "\n")) locationTableEntries
val _ = print "fileNames:\n"
val _ = List.app (fn name => (print "  ";print name; print "\n")) fileNames
val _ = print "end\n\n"
*)
              in
                buildLocationTable (locationTableEntries, fileNames)
              end
            else Executable.emptyLocationTable

        val nameSlotTable =
            if !Control.generateDebugInfo
            then
              let
                val (nameSlotTableEntries, boundNames) =
                    NameSlotMap.getAll nameSlotMap
(*
val _ = print "nameSlots:\n"
val _ = List.app (fn ent => (print "  ";print (Executable.nameSlotTableEntryToString ent); print "\n")) nameSlotTableEntries
val _ = print "boundNames:\n"
val _ = List.app (fn name => (print "  ";print name; print "\n")) boundNames
val _ = print "end\n\n"
*)
              in
                buildNameSlotTable (nameSlotTableEntries, boundNames)
              end
            else Executable.emptyNameSlotTable

        val _ = #stop makeDebugInfoTimeCounter ()

        val _ = #start secondPassTimeCounter ()

        (* second subphase *)
        val rawInstructions =
            foldr (toRawInstructions labelMap) [] IMfunctionCodes

        val _ = #stop secondPassTimeCounter ()

(*
        val _ = #add instructionsCounter (List.length rawInstructions)
*)
      in
        case getErrors () of
          [] => 
          {
            instructionsSize = lastOffset,
            instructions = rawInstructions,
            locationTable = locationTable,
            nameSlotTable = nameSlotTable
          } : Executable.executable
        | errors => raise UE.UserErrors (getErrorsAndWarnings ())
      end

  (***************************************************************************)

end
