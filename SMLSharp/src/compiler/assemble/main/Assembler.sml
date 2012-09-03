(**
 *  This structure translates instructions with symbolic references into
 * instructions in lower level representation.
 * <p>
 * Symbolic references in operands are translated into offset of instruction
 * or index in stack frame.
 * </p>
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @author Nguyen Huu Duc
 * @version $Id: Assembler.sml,v 1.75 2008/08/06 17:23:39 ohori Exp $
 *)
structure Assembler :> ASSEMBLER =
struct

  (***************************************************************************)

  structure AI = AllocationInfo
  structure BT = BasicTypes
  structure E = AssembleError
  structure Float = Real
  structure I = Instructions
  structure ISC = InstructionSizeCalculator
  structure LocMap = SourceLocationMap
  structure NameSlotMap = SourceNameSlotMap
  structure SD = SystemDef
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
  val CT.CounterSetInternal AssemblerCounterSet =
      #addSet CT.root ("assembler", CT.ORDER_OF_ADDITION)
  val CT.CounterSetInternal ElapsedCounterSet =
      #addSet AssemblerCounterSet ("elapsed time", CT.ORDER_OF_ADDITION)
  val allocateSlotTimeCounter =
      #addElapsedTime ElapsedCounterSet "allocate slot"
  val fixIndexTimeCounter =
      #addElapsedTime ElapsedCounterSet "fix index"
  val calcOffsetTimeCounter =
      #addElapsedTime ElapsedCounterSet "calc offset"
  val buildNameSlotMapTimeCounter =
      #addElapsedTime ElapsedCounterSet "build name slot map"
  val firstPassTimeCounter =
      #addElapsedTime ElapsedCounterSet "first pass"
  val makeDebugInfoTimeCounter =
      #addElapsedTime ElapsedCounterSet "make debug info"
  val secondPassTimeCounter =
      #addElapsedTime ElapsedCounterSet "second pass"
  val instructionsCounter =
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

  (* link symbol table *)
  type symbolTable =
      {index: int SEnv.map, symbols: string list, length: int}

  val emptySymbolTable =
      {index = SEnv.empty, symbols = nil, length = 0}

  fun symbolTableEntry (tab as ref ({index, symbols, length}:symbolTable))
                       name =
      case SEnv.find (index, name) of
        SOME n => n
      | NONE => (tab := {index = SEnv.insert (index, name, length),
                         symbols = name :: symbols,
                         length = length + size name + 1}; length)

  fun makeSymbolTable ({symbols, ...}:symbolTable) =
      String.concat (map (fn x => x ^ "\000") (rev symbols))

  local
    (* zero of 16 bits width *)
    val zeroPadding = BT.IntToUInt16 0

    fun length list = BT.IntToUInt32(List.length list)

    val nan = 0.0 / 0.0
    val inf = 1.0 / 0.0

    fun realOf value =
        case Real.fromString value of
          SOME real => real
        | NONE =>
          (* SML/NJ has a bug that Real.fromString "nan" returns NONE.
           * Also for "inf". *)
          case value of
            "nan" => nan
          | "inf" => inf
          | "~inf" => ~inf
          | _ => raise Control.Bug("invalid real format:" ^ value)

    fun floatOf value =
        case Float.fromString value of
          SOME float => float
        | NONE =>
          case value of
            "nan" => nan
          | "inf" => inf
          | "~inf" => ~inf
          | _ => raise Control.Bug("invalid float format:" ^ value)

  (**
   * translates a symbolic instruction to a raw instruction.
   * <p>
   * NOTE:the instruction should not be a Label instruction
   * </p>
   *)
  fun toRawInstruction VI LO symbolEntry instruction =
      let
      in
        case instruction of
          SI.LoadInt {value, destination} =>
          I.LoadInt {value = value, destination = VI destination}
        | SI.LoadLargeInt {value, destination} =>
          I.LoadLargeInt {value = LO value, destination = VI destination}
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
            val realValue = realOf value
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
        | SI.LoadFloat {value, destination} =>
          let val realValue = floatOf value
          in
            I.LoadFloat
               {
                 value = BT.RealToReal64 realValue,
                 destination = VI destination
               }
          end
        | SI.LoadChar {value, destination} =>
          I.LoadChar {value = value, destination = VI destination}
        | SI.LoadEmptyBlock {destination} =>
          I.LoadEmptyBlock {destination = VI destination}
        | SI.LoadAddress {address, destination} =>
          I.LoadAddress {address = LO address, destination = VI destination}
        | SI.Access {variableEntry, variableSize, destination} =>
          (case variableSize of
            SI.SINGLE =>
            I.Access_S
                {
                  variableIndex = VI variableEntry,
                  destination = VI destination
               }
          | SI.DOUBLE =>
            I.Access_D
                {
                  variableIndex = VI variableEntry,
                  destination = VI destination
                }
          | SI.VARIANT v =>
            I.Access_V
                {
                  variableIndex = VI variableEntry,
                  variableSizeIndex = VI v,
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
                   variableSizeIndex = VI v,
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
                   variableSizeIndex = VI v,
                   destination = VI destination
                 })
        | SI.GetField {fieldOffset, fieldSize, blockEntry, destination} =>
          (case fieldSize of
             SI.SINGLE =>
             I.GetField_S
                 {
                   fieldOffset = fieldOffset,
                   blockIndex = VI blockEntry,
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.GetField_D
                 {
                   fieldOffset = fieldOffset,
                   blockIndex = VI blockEntry,
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.GetField_V
                 {
                   fieldOffset = fieldOffset,
                   fieldSizeIndex = VI v,
                   blockIndex = VI blockEntry,
                   destination = VI destination
                 })
        | SI.GetFieldIndirect
              {fieldOffsetEntry, fieldSize, blockEntry, destination} =>
          (case fieldSize of
             SI.SINGLE =>
             I.GetFieldIndirect_S
                 {
                   fieldOffsetIndex = VI fieldOffsetEntry,
                   blockIndex = VI blockEntry,
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.GetFieldIndirect_D
                 {
                   fieldOffsetIndex = VI fieldOffsetEntry,
                   blockIndex = VI blockEntry,
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.GetFieldIndirect_V
                 {
                   fieldOffsetIndex = VI fieldOffsetEntry,
                   fieldSizeIndex = VI v,
                   blockIndex = VI blockEntry,
                   destination = VI destination
                 })
        | SI.GetNestedField
          {nestLevel, fieldOffset, fieldSize, blockEntry, destination} =>
          (case fieldSize of
             SI.SINGLE =>
             I.GetNestedField_S
                 {
                   nestLevel = nestLevel,
                   fieldOffset = fieldOffset,
                   blockIndex = VI blockEntry,
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.GetNestedField_D
                 {
                   nestLevel = nestLevel,
                   fieldOffset = fieldOffset,
                   blockIndex = VI blockEntry,
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.GetNestedField_V
                 {
                   nestLevel = nestLevel,
                   fieldOffset = fieldOffset,
                   fieldSizeIndex = VI v,
                   blockIndex = VI blockEntry,
                   destination = VI destination
                 })
        | SI.GetNestedFieldIndirect
          {nestLevelEntry, fieldOffsetEntry, fieldSize, blockEntry, destination} =>
          (case fieldSize of
             SI.SINGLE =>
             I.GetNestedFieldIndirect_S
                 {
                   nestLevelIndex = VI nestLevelEntry,
                   fieldOffsetIndex = VI fieldOffsetEntry,
                   blockIndex = VI blockEntry,
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.GetNestedFieldIndirect_D
                 {
                   nestLevelIndex = VI nestLevelEntry,
                   fieldOffsetIndex = VI fieldOffsetEntry,
                   blockIndex = VI blockEntry,
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.GetNestedFieldIndirect_V
                 {
                   nestLevelIndex = VI nestLevelEntry,
                   fieldOffsetIndex = VI fieldOffsetEntry,
                   fieldSizeIndex = VI v,
                   blockIndex = VI blockEntry,
                   destination = VI destination
                 })
        | SI.SetField {fieldOffset, fieldSize, blockEntry, newValueEntry} =>
          (case fieldSize of
             SI.SINGLE =>
             I.SetField_S
                 {
                   fieldOffset = fieldOffset,
                   blockIndex = VI blockEntry,
                   newValueIndex = VI newValueEntry
                 }
           | SI.DOUBLE =>
             I.SetField_D
                 {
                   fieldOffset = fieldOffset,
                   blockIndex = VI blockEntry,
                   newValueIndex = VI newValueEntry
                 }
           | SI.VARIANT v =>
             I.SetField_V
                 {
                   fieldOffset = fieldOffset,
                   fieldSizeIndex = VI v,
                   blockIndex = VI blockEntry,
                   newValueIndex = VI newValueEntry
                 })
        | SI.SetFieldIndirect
              {fieldOffsetEntry, fieldSize, blockEntry, newValueEntry} =>
          (case fieldSize of
             SI.SINGLE =>
             I.SetFieldIndirect_S
                 {
                   fieldOffsetIndex = VI fieldOffsetEntry,
                   blockIndex = VI blockEntry,
                   newValueIndex = VI newValueEntry
                 }
           | SI.DOUBLE =>
             I.SetFieldIndirect_D
                 {
                   fieldOffsetIndex = VI fieldOffsetEntry,
                   blockIndex = VI blockEntry,
                   newValueIndex = VI newValueEntry
                 }
           | SI.VARIANT v =>
             I.SetFieldIndirect_V
                 {
                   fieldOffsetIndex = VI fieldOffsetEntry,
                   fieldSizeIndex = VI v,
                   blockIndex = VI blockEntry,
                   newValueIndex = VI newValueEntry
                 })

        | SI.SetNestedField
              {
                nestLevel,
                fieldOffset,
                fieldSize,
                blockEntry,
                newValueEntry
              } =>
          (case fieldSize of
             SI.SINGLE =>
             I.SetNestedField_S
                 {
                   nestLevel = nestLevel,
                   fieldOffset = fieldOffset,
                   blockIndex = VI blockEntry,
                   newValueIndex = VI newValueEntry
                 }
           | SI.DOUBLE =>
             I.SetNestedField_D
                 {
                   nestLevel = nestLevel,
                   fieldOffset = fieldOffset,
                   blockIndex = VI blockEntry,
                   newValueIndex = VI newValueEntry
                 }
           | SI.VARIANT v =>
             I.SetNestedField_V
                 {
                   nestLevel = nestLevel,
                   fieldOffset = fieldOffset,
                   fieldSizeIndex = VI v,
                   blockIndex = VI blockEntry,
                   newValueIndex = VI newValueEntry
                 })

        | SI.SetNestedFieldIndirect
              {
                nestLevelEntry,
                fieldOffsetEntry,
                fieldSize,
                blockEntry,
                newValueEntry
              } =>
          (case fieldSize of
             SI.SINGLE =>
             I.SetNestedFieldIndirect_S
                 {
                   nestLevelIndex = VI nestLevelEntry,
                   fieldOffsetIndex = VI fieldOffsetEntry,
                   blockIndex = VI blockEntry,
                   newValueIndex = VI newValueEntry
                 }
           | SI.DOUBLE =>
             I.SetNestedFieldIndirect_D
                 {
                   nestLevelIndex = VI nestLevelEntry,
                   fieldOffsetIndex = VI fieldOffsetEntry,
                   blockIndex = VI blockEntry,
                   newValueIndex = VI newValueEntry
                 }
           | SI.VARIANT v =>
             I.SetNestedFieldIndirect_V
                 {
                   nestLevelIndex = VI nestLevelEntry,
                   fieldOffsetIndex = VI fieldOffsetEntry,
                   fieldSizeIndex = VI v,
                   blockIndex = VI blockEntry,
                   newValueIndex = VI newValueEntry
                 })
        | SI.CopyBlock {blockEntry, nestLevelEntry, destination} =>
          I.CopyBlock
          {
            blockIndex = VI blockEntry,
            nestLevelIndex = VI nestLevelEntry,
            destination = VI destination
          }

        | SI.CopyArray
              {srcEntry,srcOffsetEntry,dstEntry,dstOffsetEntry,lengthEntry,elementSize} =>
          (case elementSize of
             SI.SINGLE => 
             I.CopyArray_S
                 {
                   srcIndex = VI srcEntry,
                   srcOffsetIndex = VI srcOffsetEntry,
                   dstIndex = VI dstEntry,
                   dstOffsetIndex = VI dstOffsetEntry,
                   lengthIndex = VI lengthEntry
                 }
           |SI.DOUBLE =>
             I.CopyArray_D
                 {
                   srcIndex = VI srcEntry,
                   srcOffsetIndex = VI srcOffsetEntry,
                   dstIndex = VI dstEntry,
                   dstOffsetIndex = VI dstOffsetEntry,
                   lengthIndex = VI lengthEntry
                 }
           | SI.VARIANT v =>
             I.CopyArray_V
                 {
                   srcIndex = VI srcEntry,
                   srcOffsetIndex = VI srcOffsetEntry,
                   dstIndex = VI dstEntry,
                   dstOffsetIndex = VI dstOffsetEntry,
                   lengthIndex = VI lengthEntry,
                   elementSizeIndex = VI v
                 })
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
                  variableIndex = VI newValueEntry
                 }
           | SI.DOUBLE =>
             I.SetGlobal_D
                 {
                  globalArrayIndex = globalArrayIndex,
                  offset = offset,
                  variableIndex = VI newValueEntry
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
                primitive,
                argEntries,
                destination
              } =>
          (case VMPrimitive.primImpl primitive of
             VMPrimitive.Internal1 maker =>
             maker
                 {
                   argIndex = VI (hd argEntries),
                   destination = VI destination
                 }
           | VMPrimitive.Internal2 maker => 
             maker
                 {
                   argIndex1 = VI (hd argEntries),
                   argIndex2 = VI (hd (tl argEntries)),
                   destination = VI destination
                 }
           | VMPrimitive.External name => 
             I.CallPrim
             {
               argsCount = length argEntries,
               primSymbolIndex = BT.IntToUInt32 (symbolEntry name),
               argIndexes = map VI argEntries,
               destination = VI destination
             }
             )
        | SI.ForeignApply
              {
                switchTag,
                attributes,
                closureEntry,
                argEntries,
                destination
              } =>
          let
            val conventionCode =
                case #callingConvention attributes
                 of SOME Absyn.FFI_CDECL => Constants.FFI_CC_CDECL
                  | SOME Absyn.FFI_STDCALL => Constants.FFI_CC_STDCALL
                  | NONE => Constants.FFI_CC_DEFAULT
          in
            I.ForeignApply
              {
                argsCount = length argEntries,
                switchTag = switchTag,
                convention = BT.UInt32.fromInt conventionCode,
                closureIndex = VI closureEntry,
                argIndexes = map VI argEntries,
                destination = VI destination
              }
          end
        | SI.RegisterCallback
              {
                closureEntry,
                sizeTag,
                destination
              } =>
          I.RegisterCallback
              {
                closureIndex = VI closureEntry,
                sizeTag = sizeTag,
                destination = VI destination
              }

        | SI.Apply_0 {closureEntry, destinations = []} =>
          I.Apply_0_0
              {
               closureIndex = VI closureEntry
              }

        | SI.Apply_1 {closureEntry, argEntry, argSize, destinations = []} =>
          (case argSize of
             SI.SINGLE =>
             I.Apply_S_0
                 {
                   closureIndex = VI closureEntry,
                   argIndex = VI argEntry
                 }
           | SI.DOUBLE =>
             I.Apply_D_0
                 {
                   closureIndex = VI closureEntry,
                   argIndex = VI argEntry
                 }
           | SI.VARIANT v =>
             I.Apply_V_0
                 {
                   closureIndex = VI closureEntry,
                   argIndex = VI argEntry,
                   argSizeIndex = VI v
                 }
          )
        | SI.Apply_MS {closureEntry, argEntries, destinations = []} =>
          I.Apply_MS_0
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
        | SI.Apply_ML {closureEntry, argEntries, lastArgSize, destinations = []} =>
          (
           case lastArgSize of
             SI.SINGLE =>
             I.Apply_MS_0
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
           | SI.DOUBLE =>
             I.Apply_MLD_0
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
           | SI.VARIANT v =>
             I.Apply_MLV_0
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               lastArgSizeIndex = VI v
              }
          )
        | SI.Apply_MF {closureEntry, argEntries, argSizes, destinations = []} =>
          I.Apply_MF_0
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizes = argSizes
              }
        | SI.Apply_MV {closureEntry, argEntries, argSizeEntries, destinations = []} =>
          I.Apply_MV_0
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizeIndexes = map VI argSizeEntries
              }

        | SI.Apply_0 {closureEntry, destinations = [destination]} =>
          I.Apply_0_1
              {
               closureIndex = VI closureEntry,
               destination = VI destination
              }

        | SI.Apply_1 {closureEntry, argEntry, argSize, destinations = [destination]} =>
          (case argSize of
             SI.SINGLE =>
             I.Apply_S_1
                 {
                   closureIndex = VI closureEntry,
                   argIndex = VI argEntry,
                   destination = VI destination
                 }
           | SI.DOUBLE =>
             I.Apply_D_1
                 {
                   closureIndex = VI closureEntry,
                   argIndex = VI argEntry,
                   destination = VI destination
                 }
           | SI.VARIANT v =>
             I.Apply_V_1
                 {
                   closureIndex = VI closureEntry,
                   argIndex = VI argEntry,
                   argSizeIndex = VI v,
                   destination = VI destination
                 }
          )
        | SI.Apply_MS {closureEntry, argEntries, destinations = [destination]} =>
          I.Apply_MS_1
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destination = VI destination
              }
        | SI.Apply_ML {closureEntry, argEntries, lastArgSize, destinations = [destination]} =>
          (
           case lastArgSize of
             SI.SINGLE =>
             I.Apply_MS_1
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destination = VI destination
              }
           | SI.DOUBLE =>
             I.Apply_MLD_1
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destination = VI destination
              }
           | SI.VARIANT v =>
             I.Apply_MLV_1
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               lastArgSizeIndex = VI v,
               destination = VI destination
              }
          )
        | SI.Apply_MF {closureEntry, argEntries, argSizes, destinations = [destination]} =>
          I.Apply_MF_1
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizes = argSizes,
               destination = VI destination
              }
        | SI.Apply_MV {closureEntry, argEntries, argSizeEntries, destinations = [destination]} =>
          I.Apply_MV_1
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizeIndexes = map VI argSizeEntries,
               destination = VI destination
              }

        | SI.Apply_0 {closureEntry, destinations} =>
          I.Apply_0_M
              {
               closureIndex = VI closureEntry,
               destsCount = length destinations,
               destinations = map VI destinations
              }

        | SI.Apply_1 {closureEntry, argEntry, argSize, destinations} =>
          (case argSize of
             SI.SINGLE =>
             I.Apply_S_M
                 {
                   closureIndex = VI closureEntry,
                   argIndex = VI argEntry,
                   destsCount = length destinations,
                   destinations = map VI destinations
                 }
           | SI.DOUBLE =>
             I.Apply_D_M
                 {
                   closureIndex = VI closureEntry,
                   argIndex = VI argEntry,
                   destsCount = length destinations,
                   destinations = map VI destinations
                 }
           | SI.VARIANT v =>
             I.Apply_V_M
                 {
                   closureIndex = VI closureEntry,
                   argIndex = VI argEntry,
                   argSizeIndex = VI v,
                   destsCount = length destinations,
                   destinations = map VI destinations
                 }
          )
        | SI.Apply_MS {closureEntry, argEntries, destinations} =>
          I.Apply_MS_M
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destsCount = length destinations,
               destinations = map VI destinations
              }
        | SI.Apply_ML {closureEntry, argEntries, lastArgSize, destinations} =>
          (
           case lastArgSize of
             SI.SINGLE =>
             I.Apply_MS_M
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destsCount = length destinations,
               destinations = map VI destinations
              }
           | SI.DOUBLE =>
             I.Apply_MLD_M
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destsCount = length destinations,
               destinations = map VI destinations
              }
           | SI.VARIANT v =>
             I.Apply_MLV_M
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               lastArgSizeIndex = VI v,
               destsCount = length destinations,
               destinations = map VI destinations
              }
          )
        | SI.Apply_MF {closureEntry, argEntries, argSizes, destinations} =>
          I.Apply_MF_M
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizes = argSizes,
               destsCount = length destinations,
               destinations = map VI destinations
              }
        | SI.Apply_MV {closureEntry, argEntries, argSizeEntries, destinations} =>
          I.Apply_MV_M
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizeIndexes = map VI argSizeEntries,
               destsCount = length destinations,
               destinations = map VI destinations
              }

        | SI.TailApply_0 {closureEntry} =>
          I.TailApply_0
              {
               closureIndex = VI closureEntry
              }

        | SI.TailApply_1 {closureEntry, argEntry, argSize} =>
          (case argSize of
             SI.SINGLE =>
             I.TailApply_S
                 {
                   closureIndex = VI closureEntry,
                   argIndex = VI argEntry
                 }
           | SI.DOUBLE =>
             I.TailApply_D
                 {
                   closureIndex = VI closureEntry,
                   argIndex = VI argEntry
                 }
           | SI.VARIANT v =>
             I.TailApply_V
                 {
                   closureIndex = VI closureEntry,
                   argIndex = VI argEntry,
                   argSizeIndex = VI v
                 }
          )
        | SI.TailApply_MS {closureEntry, argEntries} =>
          I.TailApply_MS
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
        | SI.TailApply_ML {closureEntry, argEntries, lastArgSize} =>
          (
           case lastArgSize of
             SI.SINGLE =>
             I.TailApply_MS
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
           | SI.DOUBLE =>
             I.TailApply_MLD
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
           | SI.VARIANT v =>
             I.TailApply_MLV
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               lastArgSizeIndex = VI v
              }
          )
        | SI.TailApply_MF {closureEntry, argEntries, argSizes} =>
          I.TailApply_MF
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizes = argSizes
              }
        | SI.TailApply_MV {closureEntry, argEntries, argSizeEntries} =>
          I.TailApply_MV
              {
               closureIndex = VI closureEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizeIndexes = map VI argSizeEntries
              }

        | SI.CallStatic_0 {entryPoint, envEntry, destinations = []} =>
          I.CallStatic_0_0
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry
              }

        | SI.CallStatic_1 {entryPoint, envEntry, argEntry, argSize, destinations = []} =>
          (case argSize of
             SI.SINGLE =>
             I.CallStatic_S_0
                 {
                  entryPoint = LO entryPoint,
                  envIndex = VI envEntry,
                  argIndex = VI argEntry
                 }
           | SI.DOUBLE =>
             I.CallStatic_D_0
                 {
                  entryPoint = LO entryPoint,
                  envIndex = VI envEntry,
                  argIndex = VI argEntry
                 }
           | SI.VARIANT v =>
             I.CallStatic_V_0
                 {
                  entryPoint = LO entryPoint,
                  envIndex = VI envEntry,
                  argIndex = VI argEntry,
                  argSizeIndex = VI v
                 }
          )
        | SI.CallStatic_MS {entryPoint, envEntry, argEntries, destinations = []} =>
          I.CallStatic_MS_0
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
        | SI.CallStatic_ML {entryPoint, envEntry, argEntries, lastArgSize, destinations = []} =>
          (
           case lastArgSize of
             SI.SINGLE =>
             I.CallStatic_MS_0
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
           | SI.DOUBLE =>
             I.CallStatic_MLD_0
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
           | SI.VARIANT v =>
             I.CallStatic_MLV_0
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               lastArgSizeIndex = VI v
              }
          )
        | SI.CallStatic_MF {entryPoint, envEntry, argEntries, argSizes, destinations = []} =>
          I.CallStatic_MF_0
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizes = argSizes
              }
        | SI.CallStatic_MV {entryPoint, envEntry, argEntries, argSizeEntries, destinations = []} =>
          I.CallStatic_MV_0
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizeIndexes = map VI argSizeEntries
              }

        | SI.CallStatic_0 {entryPoint, envEntry, destinations = [destination]} =>
          I.CallStatic_0_1
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               destination = VI destination
              }

        | SI.CallStatic_1 {entryPoint, envEntry, argEntry, argSize, destinations = [destination]} =>
          (case argSize of
             SI.SINGLE =>
             I.CallStatic_S_1
                 {
                  entryPoint = LO entryPoint,
                  envIndex = VI envEntry,
                  argIndex = VI argEntry,
                  destination = VI destination
                 }
           | SI.DOUBLE =>
             I.CallStatic_D_1
                 {
                  entryPoint = LO entryPoint,
                  envIndex = VI envEntry,
                  argIndex = VI argEntry,
                  destination = VI destination
                 }
           | SI.VARIANT v =>
             I.CallStatic_V_1
                 {
                  entryPoint = LO entryPoint,
                  envIndex = VI envEntry,
                  argIndex = VI argEntry,
                  argSizeIndex = VI v,
                  destination = VI destination
                 }
          )
        | SI.CallStatic_MS {entryPoint, envEntry, argEntries, destinations = [destination]} =>
          I.CallStatic_MS_1
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destination = VI destination
              }
        | SI.CallStatic_ML {entryPoint, envEntry, argEntries, lastArgSize, destinations = [destination]} =>
          (
           case lastArgSize of
             SI.SINGLE =>
             I.CallStatic_MS_1
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destination = VI destination
              }
           | SI.DOUBLE =>
             I.CallStatic_MLD_1
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destination = VI destination
              }
           | SI.VARIANT v =>
             I.CallStatic_MLV_1
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               lastArgSizeIndex = VI v,
               destination = VI destination
              }
          )
        | SI.CallStatic_MF {entryPoint, envEntry, argEntries, argSizes, destinations = [destination]} =>
          I.CallStatic_MF_1
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizes = argSizes,
               destination = VI destination
              }
        | SI.CallStatic_MV {entryPoint, envEntry, argEntries, argSizeEntries, destinations = [destination]} =>
          I.CallStatic_MV_1
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizeIndexes = map VI argSizeEntries,
               destination = VI destination
              }

        | SI.CallStatic_0 {entryPoint, envEntry, destinations} =>
          I.CallStatic_0_M
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               destsCount = length destinations,
               destinations = map VI destinations
              }

        | SI.CallStatic_1 {entryPoint, envEntry, argEntry, argSize, destinations} =>
          (case argSize of
             SI.SINGLE =>
             I.CallStatic_S_M
                 {
                  entryPoint = LO entryPoint,
                  envIndex = VI envEntry,
                  argIndex = VI argEntry,
                  destsCount = length destinations,
                  destinations = map VI destinations
                 }
           | SI.DOUBLE =>
             I.CallStatic_D_M
                 {
                  entryPoint = LO entryPoint,
                  envIndex = VI envEntry,
                  argIndex = VI argEntry,
                  destsCount = length destinations,
                  destinations = map VI destinations
                 }
           | SI.VARIANT v =>
             I.CallStatic_V_M
                 {
                  entryPoint = LO entryPoint,
                  envIndex = VI envEntry,
                  argIndex = VI argEntry,
                  argSizeIndex = VI v,
                  destsCount = length destinations,
                  destinations = map VI destinations
                 }
          )
        | SI.CallStatic_MS {entryPoint, envEntry, argEntries, destinations} =>
          I.CallStatic_MS_M
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destsCount = length destinations,
               destinations = map VI destinations
              }
        | SI.CallStatic_ML {entryPoint, envEntry, argEntries, lastArgSize, destinations} =>
          (
           case lastArgSize of
             SI.SINGLE =>
             I.CallStatic_MS_M
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destsCount = length destinations,
               destinations = map VI destinations
              }
           | SI.DOUBLE =>
             I.CallStatic_MLD_M
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destsCount = length destinations,
               destinations = map VI destinations
              }
           | SI.VARIANT v =>
             I.CallStatic_MLV_M
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               lastArgSizeIndex = VI v,
               destsCount = length destinations,
               destinations = map VI destinations
              }
          )
        | SI.CallStatic_MF {entryPoint, envEntry, argEntries, argSizes, destinations} =>
          I.CallStatic_MF_M
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizes = argSizes,
               destsCount = length destinations,
               destinations = map VI destinations
              }
        | SI.CallStatic_MV {entryPoint, envEntry, argEntries, argSizeEntries, destinations} =>
          I.CallStatic_MV_M
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizeIndexes = map VI argSizeEntries,
               destsCount = length destinations,
               destinations = map VI destinations
              }

        | SI.TailCallStatic_0 {entryPoint, envEntry} =>
          I.TailCallStatic_0
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry
              }

        | SI.TailCallStatic_1 {entryPoint, envEntry, argEntry, argSize} =>
          (case argSize of
             SI.SINGLE =>
             I.TailCallStatic_S
                 {
                  entryPoint = LO entryPoint,
                  envIndex = VI envEntry,
                  argIndex = VI argEntry
                 }
           | SI.DOUBLE =>
             I.TailCallStatic_D
                 {
                  entryPoint = LO entryPoint,
                  envIndex = VI envEntry,
                  argIndex = VI argEntry
                 }
           | SI.VARIANT v =>
             I.TailCallStatic_V
                 {
                  entryPoint = LO entryPoint,
                  envIndex = VI envEntry,
                  argIndex = VI argEntry,
                  argSizeIndex = VI v
                 }
          )
        | SI.TailCallStatic_MS {entryPoint, envEntry, argEntries} =>
          I.TailCallStatic_MS
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
        | SI.TailCallStatic_ML {entryPoint, envEntry, argEntries, lastArgSize} =>
          (
           case lastArgSize of
             SI.SINGLE =>
             I.TailCallStatic_MS
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
           | SI.DOUBLE =>
             I.TailCallStatic_MLD
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
           | SI.VARIANT v =>
             I.TailCallStatic_MLV
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               lastArgSizeIndex = VI v
              }
          )
        | SI.TailCallStatic_MF {entryPoint, envEntry, argEntries, argSizes} =>
          I.TailCallStatic_MF
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizes = argSizes
              }
        | SI.TailCallStatic_MV {entryPoint, envEntry, argEntries, argSizeEntries} =>
          I.TailCallStatic_MV
              {
               entryPoint = LO entryPoint,
               envIndex = VI envEntry,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizeIndexes = map VI argSizeEntries
              }

        | SI.RecursiveCallStatic_0 {entryPoint, destinations = []} =>
          I.RecursiveCallStatic_0_0
              {
               entryPoint = LO entryPoint
              }

        | SI.RecursiveCallStatic_1 {entryPoint, argEntry, argSize, destinations = []} =>
          (case argSize of
             SI.SINGLE =>
             I.RecursiveCallStatic_S_0
                 {
                  entryPoint = LO entryPoint,
                  argIndex = VI argEntry
                 }
           | SI.DOUBLE =>
             I.RecursiveCallStatic_D_0
                 {
                  entryPoint = LO entryPoint,
                  argIndex = VI argEntry
                 }
           | SI.VARIANT v =>
             I.RecursiveCallStatic_V_0
                 {
                  entryPoint = LO entryPoint,
                  argIndex = VI argEntry,
                  argSizeIndex = VI v
                 }
          )
        | SI.RecursiveCallStatic_MS {entryPoint, argEntries, destinations = []} =>
          I.RecursiveCallStatic_MS_0
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
        | SI.RecursiveCallStatic_ML {entryPoint, argEntries, lastArgSize, destinations = []} =>
          (
           case lastArgSize of
             SI.SINGLE =>
             I.RecursiveCallStatic_MS_0
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
           | SI.DOUBLE =>
             I.RecursiveCallStatic_MLD_0
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
           | SI.VARIANT v =>
             I.RecursiveCallStatic_MLV_0
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               lastArgSizeIndex = VI v
              }
          )
        | SI.RecursiveCallStatic_MF {entryPoint, argEntries, argSizes, destinations = []} =>
          I.RecursiveCallStatic_MF_0
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizes = argSizes
              }
        | SI.RecursiveCallStatic_MV {entryPoint, argEntries, argSizeEntries, destinations = []} =>
          I.RecursiveCallStatic_MV_0
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizeIndexes = map VI argSizeEntries
              }

        | SI.RecursiveCallStatic_0 {entryPoint, destinations = [destination]} =>
          I.RecursiveCallStatic_0_1
              {
               entryPoint = LO entryPoint,
               destination = VI destination
              }

        | SI.RecursiveCallStatic_1 {entryPoint, argEntry, argSize, destinations = [destination]} =>
          (case argSize of
             SI.SINGLE =>
             I.RecursiveCallStatic_S_1
                 {
                  entryPoint = LO entryPoint,
                  argIndex = VI argEntry,
                  destination = VI destination
                 }
           | SI.DOUBLE =>
             I.RecursiveCallStatic_D_1
                 {
                  entryPoint = LO entryPoint,
                  argIndex = VI argEntry,
                  destination = VI destination
                 }
           | SI.VARIANT v =>
             I.RecursiveCallStatic_V_1
                 {
                  entryPoint = LO entryPoint,
                  argIndex = VI argEntry,
                  argSizeIndex = VI v,
                  destination = VI destination
                 }
          )
        | SI.RecursiveCallStatic_MS {entryPoint, argEntries, destinations = [destination]} =>
          I.RecursiveCallStatic_MS_1
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destination = VI destination
              }
        | SI.RecursiveCallStatic_ML {entryPoint, argEntries, lastArgSize, destinations = [destination]} =>
          (
           case lastArgSize of
             SI.SINGLE =>
             I.RecursiveCallStatic_MS_1
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destination = VI destination
              }
           | SI.DOUBLE =>
             I.RecursiveCallStatic_MLD_1
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destination = VI destination
              }
           | SI.VARIANT v =>
             I.RecursiveCallStatic_MLV_1
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               lastArgSizeIndex = VI v,
               destination = VI destination
              }
          )
        | SI.RecursiveCallStatic_MF {entryPoint, argEntries, argSizes, destinations = [destination]} =>
          I.RecursiveCallStatic_MF_1
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizes = argSizes,
               destination = VI destination
              }
        | SI.RecursiveCallStatic_MV {entryPoint, argEntries, argSizeEntries, destinations = [destination]} =>
          I.RecursiveCallStatic_MV_1
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizeIndexes = map VI argSizeEntries,
               destination = VI destination
              }

        | SI.RecursiveCallStatic_0 {entryPoint, destinations} =>
          I.RecursiveCallStatic_0_M
              {
               entryPoint = LO entryPoint,
               destsCount = length destinations,
               destinations = map VI destinations
              }

        | SI.RecursiveCallStatic_1 {entryPoint, argEntry, argSize, destinations} =>
          (case argSize of
             SI.SINGLE =>
             I.RecursiveCallStatic_S_M
                 {
                  entryPoint = LO entryPoint,
                  argIndex = VI argEntry,
                  destsCount = length destinations,
                  destinations = map VI destinations
                 }
           | SI.DOUBLE =>
             I.RecursiveCallStatic_D_M
                 {
                  entryPoint = LO entryPoint,
                  argIndex = VI argEntry,
                  destsCount = length destinations,
                  destinations = map VI destinations
                 }
           | SI.VARIANT v =>
             I.RecursiveCallStatic_V_M
                 {
                  entryPoint = LO entryPoint,
                  argIndex = VI argEntry,
                  argSizeIndex = VI v,
                  destsCount = length destinations,
                  destinations = map VI destinations
                 }
          )
        | SI.RecursiveCallStatic_MS {entryPoint, argEntries, destinations} =>
          I.RecursiveCallStatic_MS_M
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destsCount = length destinations,
               destinations = map VI destinations
              }
        | SI.RecursiveCallStatic_ML {entryPoint, argEntries, lastArgSize, destinations} =>
          (
           case lastArgSize of
             SI.SINGLE =>
             I.RecursiveCallStatic_MS_M
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destsCount = length destinations,
               destinations = map VI destinations
              }
           | SI.DOUBLE =>
             I.RecursiveCallStatic_MLD_M
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               destsCount = length destinations,
               destinations = map VI destinations
              }
           | SI.VARIANT v =>
             I.RecursiveCallStatic_MLV_M
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               lastArgSizeIndex = VI v,
               destsCount = length destinations,
               destinations = map VI destinations
              }
          )
        | SI.RecursiveCallStatic_MF {entryPoint, argEntries, argSizes, destinations} =>
          I.RecursiveCallStatic_MF_M
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizes = argSizes,
               destsCount = length destinations,
               destinations = map VI destinations
              }
        | SI.RecursiveCallStatic_MV {entryPoint, argEntries, argSizeEntries, destinations} =>
          I.RecursiveCallStatic_MV_M
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizeIndexes = map VI argSizeEntries,
               destsCount = length destinations,
               destinations = map VI destinations
              }

        | SI.RecursiveTailCallStatic_0 {entryPoint} =>
          I.RecursiveTailCallStatic_0
              {
               entryPoint = LO entryPoint
              }

        | SI.RecursiveTailCallStatic_1 {entryPoint, argEntry, argSize} =>
          (case argSize of
             SI.SINGLE =>
             I.RecursiveTailCallStatic_S
                 {
                  entryPoint = LO entryPoint,
                  argIndex = VI argEntry
                 }
           | SI.DOUBLE =>
             I.RecursiveTailCallStatic_D
                 {
                  entryPoint = LO entryPoint,
                  argIndex = VI argEntry
                 }
           | SI.VARIANT v =>
             I.RecursiveTailCallStatic_V
                 {
                  entryPoint = LO entryPoint,
                  argIndex = VI argEntry,
                  argSizeIndex = VI v
                 }
          )
        | SI.RecursiveTailCallStatic_MS {entryPoint, argEntries} =>
          I.RecursiveTailCallStatic_MS
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
        | SI.RecursiveTailCallStatic_ML {entryPoint, argEntries, lastArgSize} =>
          (
           case lastArgSize of
             SI.SINGLE =>
             I.RecursiveTailCallStatic_MS
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
           | SI.DOUBLE =>
             I.RecursiveTailCallStatic_MLD
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries
              }
           | SI.VARIANT v =>
             I.RecursiveTailCallStatic_MLV
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               lastArgSizeIndex = VI v
              }
          )
        | SI.RecursiveTailCallStatic_MF {entryPoint, argEntries, argSizes} =>
          I.RecursiveTailCallStatic_MF
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizes = argSizes
              }
        | SI.RecursiveTailCallStatic_MV {entryPoint, argEntries, argSizeEntries} =>
          I.RecursiveTailCallStatic_MV
              {
               entryPoint = LO entryPoint,
               argsCount = length argEntries,
               argIndexes = map VI argEntries,
               argSizeIndexes = map VI argSizeEntries
              }

        | SI.MakeBlock
              {
                bitmapEntry,
                sizeEntry,
                fieldEntries,
                fieldSizeEntries,
                destination
              } =>
          I.MakeBlock
          {
            fieldsCount = length fieldEntries,
            bitmapIndex = VI bitmapEntry,
            sizeIndex = VI sizeEntry,
            fieldIndexes = map VI fieldEntries,
            fieldSizeIndexes = map VI fieldSizeEntries,
            destination = VI destination
          }
        | SI.MakeFixedSizeBlock
              {
                bitmapEntry,
                size,
                fieldEntries,
                fieldSizes,
                destination
              } =>
          I.MakeFixedSizeBlock
          {
            fieldsCount = length fieldEntries,
            bitmapIndex = VI bitmapEntry,
            size = size,
            fieldIndexes = map VI fieldEntries,
            fieldSizes = fieldSizes,
            destination = VI destination
          }
        | SI.MakeBlockOfSingleValues
              {
               bitmapEntry,
               fieldEntries,
               destination
              } =>
          I.MakeBlockOfSingleValues
              {
               bitmapIndex = VI bitmapEntry,
               fieldsCount = length fieldEntries,
               fieldIndexes = map VI fieldEntries,
               destination = VI destination
              }
        | SI.MakeArray
              {
                bitmapEntry,
                sizeEntry,
                initialValueEntry,
                initialValueSize,
                isMutable,
                destination
              } =>
          (case initialValueSize of
             SI.SINGLE =>
             I.MakeArray_S
                 {
                  bitmapIndex = VI bitmapEntry,
                  sizeIndex = VI sizeEntry,
                  initialValueIndex = VI initialValueEntry,
                  isMutable = if isMutable then 0w1 else 0w0,
                  destination = VI destination
                 }
           | SI.DOUBLE =>
             I.MakeArray_D
                 {
                  bitmapIndex = VI bitmapEntry,
                  sizeIndex = VI sizeEntry,
                  initialValueIndex = VI initialValueEntry,
                  isMutable = if isMutable then 0w1 else 0w0,
                  destination = VI destination
                 }
           | SI.VARIANT v =>
             I.MakeArray_V
                 {
                  bitmapIndex = VI bitmapEntry,
                  sizeIndex = VI sizeEntry,
                  initialValueIndex = VI initialValueEntry,
                  initialValueSize = VI v,
                  isMutable = if isMutable then 0w1 else 0w0,
                  destination = VI destination
                 }
          )
        | SI.MakeClosure {entryPoint, envEntry, destination} =>
          I.MakeClosure
          {
            entryPoint = LO entryPoint,
            envIndex = VI envEntry,
            destination = VI destination
          }
        | SI.Raise {exceptionEntry} =>
          I.Raise {exceptionIndex = VI exceptionEntry}
        | SI.PushHandler{handlerStart, exceptionEntry, ...} =>
          I.PushHandler
          {
            handler = LO handlerStart,
            exceptionIndex = VI exceptionEntry
          }
        | SI.PopHandler _ => I.PopHandler
        | SI.Label _ => raise Control.Bug "Label is not expected."
        | SI.Location _ => raise Control.Bug "Label is not expected."
        | SI.SwitchInt{targetEntry, cases, default} =>
          I.SwitchInt
          {
            targetIndex = VI targetEntry,
            casesCount = length cases,
            cases =
            List.concat
            (map
             (fn {const, destination} =>
                 [const, BT.UInt32ToSInt32(LO destination)])
             cases),
            default = LO default
          }
        | SI.SwitchLargeInt{targetEntry, cases, default} =>
          I.SwitchLargeInt
          {
            targetIndex = VI targetEntry,
            casesCount = length cases,
            cases =
            List.concat
            (map
                 (fn {const, destination} => [LO const, LO destination])
                 cases),
            default = LO default
          }
        | SI.SwitchWord{targetEntry, cases, default} =>
          I.SwitchWord
          {
            targetIndex = VI targetEntry,
            casesCount = length cases,
            cases =
            List.concat
            (map (fn {const, destination} => [const, LO destination]) cases),
            default = LO default
          }
        | SI.SwitchChar{targetEntry, cases, default} =>
          I.SwitchChar
          {
            targetIndex = VI targetEntry,
            casesCount = length cases,
            cases =
            List.concat
            (map (fn {const, destination} => [const, LO destination]) cases),
            default = LO default
          }
        | SI.SwitchString{targetEntry, cases, default} =>
          I.SwitchString
          {
            targetIndex = VI targetEntry,
            casesCount = length cases,
            cases =
            List.concat
            (map
                 (fn {const, destination} => [LO const, LO destination])
                 cases),
            default = LO default
          }
        | SI.Jump {destination} => I.Jump{destination = LO destination}
        | SI.IndirectJump {destination} =>
          I.IndirectJump {destination = VI destination}
        | SI.Exit => I.Exit
        | SI.Return_0 => I.Return_0
        | SI.Return_1 {variableEntry, variableSize} =>
          (case variableSize of
             SI.SINGLE => I.Return_S {variableIndex = VI variableEntry}
           | SI.DOUBLE => I.Return_D {variableIndex = VI variableEntry}
           | SI.VARIANT v =>
             I.Return_V
                 {
                   variableIndex = VI variableEntry,
                   variableSizeIndex = VI v
                 })
        | SI.Return_MS {variableEntries = []} => I.Return_0
        | SI.Return_MS {variableEntries = [variableEntry]} =>
          I.Return_S
              {
               variableIndex = VI variableEntry
              }
        | SI.Return_MS {variableEntries} =>
          I.Return_MS
              {
               variablesCount = length variableEntries,
               variableIndexes = map VI variableEntries
              }
        | SI.Return_ML {variableEntries = [variableEntry], lastVariableSize} =>
          (case lastVariableSize of
             SI.SINGLE => 
             I.Return_S
                 {
                  variableIndex = VI variableEntry
                 }
           | SI.DOUBLE =>
             I.Return_D
                 {
                  variableIndex = VI variableEntry
                 }
           | SI.VARIANT v =>
             I.Return_V
                 {
                  variableIndex = VI variableEntry,
                  variableSizeIndex = VI v
                 }
          )
        | SI.Return_ML {variableEntries, lastVariableSize} =>
          (case lastVariableSize of
             SI.SINGLE => 
             I.Return_MS
                 {
                  variablesCount = length variableEntries,
                  variableIndexes = map VI variableEntries
                 }
           | SI.DOUBLE =>
             I.Return_MLD
                 {
                  variablesCount = length variableEntries,
                  variableIndexes = map VI variableEntries
                 }
           | SI.VARIANT v =>
             I.Return_MLV
                 {
                  variablesCount = length variableEntries,
                  variableIndexes = map VI variableEntries,
                  lastVariableSizeIndex = VI v
                 }
          )
        | SI.Return_MF {variableEntries = [], variableSizes = []} => I.Return_0
        | SI.Return_MF {variableEntries = [variableEntry], variableSizes = [0w1]} =>
          I.Return_S
              {
               variableIndex = VI variableEntry
              }
        | SI.Return_MF {variableEntries = [variableEntry], variableSizes = [0w2]} =>
          I.Return_D
              {
               variableIndex = VI variableEntry
              }
        | SI.Return_MF {variableEntries, variableSizes} =>
          I.Return_MF
              {
               variablesCount = length variableEntries,
               variableIndexes = map VI variableEntries,
               variableSizes = variableSizes
              }
        | SI.Return_MV {variableEntries = [], variableSizeEntries = []} => I.Return_0
        | SI.Return_MV {variableEntries = [variableEntry], variableSizeEntries = [variableSizeEntry]} =>
          I.Return_V
              {
               variableIndex = VI variableEntry,
               variableSizeIndex = VI variableSizeEntry
              }
        | SI.Return_MV {variableEntries, variableSizeEntries} =>
          I.Return_MV
              {
               variablesCount = length variableEntries,
               variableIndexes = map VI variableEntries,
               variableSizeIndexes = map VI variableSizeEntries
              }
        | SI.ConstString {string} =>
          I.ConstString
          {
            length = BT.UInt32.fromInt (String.size string),
            string = BT.StringToPaddedUInt8List string
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
        | SI.AddLargeInt_Const_1{argValue1, argEntry2, destination} =>
          I.AddLargeInt_Const_1
          {
           argValue1 = LO argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.AddLargeInt_Const_2{argEntry1, argValue2, destination} =>
          I.AddLargeInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = LO argValue2,
           destination = VI destination
          }
        | SI.AddReal_Const_1{argValue1, argEntry2, destination} =>
          let val realValue = realOf argValue1
          in
            I.AddReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.AddReal_Const_2{argEntry1, argValue2, destination} =>
          let val realValue = realOf argValue2
          in
            I.AddReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }

          end
        | SI.AddFloat_Const_1{argValue1, argEntry2, destination} =>
          let val floatValue = floatOf argValue1
          in
            I.AddFloat_Const_1
                {
                 argValue1 = BT.RealToReal32 floatValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }
          end
        | SI.AddFloat_Const_2{argEntry1, argValue2, destination} =>
          let val floatValue = floatOf argValue2
          in
            I.AddFloat_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal32 floatValue,
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
        | SI.SubLargeInt_Const_1{argValue1, argEntry2, destination} =>
          I.SubLargeInt_Const_1
          {
           argValue1 = LO argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.SubLargeInt_Const_2{argEntry1, argValue2, destination} =>
          I.SubLargeInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = LO argValue2,
           destination = VI destination
          }
        | SI.SubReal_Const_1{argValue1, argEntry2, destination} =>
          let val realValue = realOf argValue1
          in
            I.SubReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }
          end
        | SI.SubReal_Const_2{argEntry1, argValue2, destination} =>
          let val realValue = realOf argValue2
          in
            I.SubReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }
          end
        | SI.SubFloat_Const_1{argValue1, argEntry2, destination} =>
          let val floatValue = floatOf argValue1
          in
            I.SubFloat_Const_1
                {
                 argValue1 = BT.RealToReal32 floatValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }
          end
        | SI.SubFloat_Const_2{argEntry1, argValue2, destination} =>
          let val floatValue = floatOf argValue2
          in
            I.SubFloat_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal32 floatValue,
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
        | SI.MulLargeInt_Const_1{argValue1, argEntry2, destination} =>
          I.MulLargeInt_Const_1
          {
           argValue1 = LO argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.MulLargeInt_Const_2{argEntry1, argValue2, destination} =>
          I.MulLargeInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = LO argValue2,
           destination = VI destination
          }
        | SI.MulReal_Const_1{argValue1, argEntry2, destination} =>
          let val realValue = realOf argValue1
          in
            I.MulReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }
          end
        | SI.MulReal_Const_2{argEntry1, argValue2, destination} =>
          let val realValue = realOf argValue2
          in
            I.MulReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }
          end
        | SI.MulFloat_Const_1{argValue1, argEntry2, destination} =>
          let val floatValue = floatOf argValue1
          in
            I.MulFloat_Const_1
                {
                 argValue1 = BT.RealToReal32 floatValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }
          end
        | SI.MulFloat_Const_2{argEntry1, argValue2, destination} =>
          let val floatValue = floatOf argValue2
          in
            I.MulFloat_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal32 floatValue,
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
        | SI.DivLargeInt_Const_1{argValue1, argEntry2, destination} =>
          I.DivLargeInt_Const_1
          {
           argValue1 = LO argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.DivLargeInt_Const_2{argEntry1, argValue2, destination} =>
          I.DivLargeInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = LO argValue2,
           destination = VI destination
          }
        | SI.DivReal_Const_1{argValue1, argEntry2, destination} =>
          let val realValue = realOf argValue1
          in
            I.DivReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.DivReal_Const_2{argEntry1, argValue2, destination} =>
          let val realValue = realOf argValue2
          in
            I.DivReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }

          end
        | SI.DivFloat_Const_1{argValue1, argEntry2, destination} =>
          let val floatValue = floatOf argValue1
          in
            I.DivFloat_Const_1
                {
                 argValue1 = BT.RealToReal32 floatValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.DivFloat_Const_2{argEntry1, argValue2, destination} =>
          let val floatValue = floatOf argValue2
          in
            I.DivFloat_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal32 floatValue,
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
        | SI.ModLargeInt_Const_1{argValue1, argEntry2, destination} =>
          I.ModLargeInt_Const_1
          {
           argValue1 = LO argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.ModLargeInt_Const_2{argEntry1, argValue2, destination} =>
          I.ModLargeInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = LO argValue2,
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
        | SI.QuotLargeInt_Const_1{argValue1, argEntry2, destination} =>
          I.QuotLargeInt_Const_1
          {
           argValue1 = LO argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.QuotLargeInt_Const_2{argEntry1, argValue2, destination} =>
          I.QuotLargeInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = LO argValue2,
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
        | SI.RemLargeInt_Const_1{argValue1, argEntry2, destination} =>
          I.RemLargeInt_Const_1
          {
           argValue1 = LO argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.RemLargeInt_Const_2{argEntry1, argValue2, destination} =>
          I.RemLargeInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = LO argValue2,
           destination = VI destination
          }

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
        | SI.LtLargeInt_Const_1{argValue1, argEntry2, destination} =>
          I.LtLargeInt_Const_1
          {
           argValue1 = LO argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.LtLargeInt_Const_2{argEntry1, argValue2, destination} =>
          I.LtLargeInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = LO argValue2,
           destination = VI destination
          }
        | SI.LtReal_Const_1{argValue1, argEntry2, destination} =>
          let val realValue = realOf argValue1
          in
            I.LtReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.LtReal_Const_2{argEntry1, argValue2, destination} =>
          let val realValue = realOf argValue2
          in
            I.LtReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }

          end
        | SI.LtFloat_Const_1{argValue1, argEntry2, destination} =>
          let val floatValue = floatOf argValue1
          in
            I.LtFloat_Const_1
                {
                 argValue1 = BT.RealToReal32 floatValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.LtFloat_Const_2{argEntry1, argValue2, destination} =>
          let val floatValue = floatOf argValue2
          in
            I.LtFloat_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal32 floatValue,
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
        | SI.GtLargeInt_Const_1{argValue1, argEntry2, destination} =>
          I.GtLargeInt_Const_1
          {
           argValue1 = LO argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.GtLargeInt_Const_2{argEntry1, argValue2, destination} =>
          I.GtLargeInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = LO argValue2,
           destination = VI destination
          }
        | SI.GtReal_Const_1{argValue1, argEntry2, destination} =>
          let val realValue = realOf argValue1
          in
            I.GtReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.GtReal_Const_2{argEntry1, argValue2, destination} =>
          let val realValue = realOf argValue2
          in
            I.GtReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }

          end
        | SI.GtFloat_Const_1{argValue1, argEntry2, destination} =>
          let val floatValue = floatOf argValue1
          in
            I.GtFloat_Const_1
                {
                 argValue1 = BT.RealToReal32 floatValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.GtFloat_Const_2{argEntry1, argValue2, destination} =>
          let val floatValue = floatOf argValue2
          in
            I.GtFloat_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal32 floatValue,
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
        | SI.LteqLargeInt_Const_1{argValue1, argEntry2, destination} =>
          I.LteqLargeInt_Const_1
          {
           argValue1 = LO argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.LteqLargeInt_Const_2{argEntry1, argValue2, destination} =>
          I.LteqLargeInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = LO argValue2,
           destination = VI destination
          }
        | SI.LteqReal_Const_1{argValue1, argEntry2, destination} =>
          let val realValue = realOf argValue1
          in
            I.LteqReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.LteqReal_Const_2{argEntry1, argValue2, destination} =>
          let val realValue = realOf argValue2
          in
            I.LteqReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }

          end
        | SI.LteqFloat_Const_1{argValue1, argEntry2, destination} =>
          let val floatValue = floatOf argValue1
          in
            I.LteqFloat_Const_1
                {
                 argValue1 = BT.RealToReal32 floatValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.LteqFloat_Const_2{argEntry1, argValue2, destination} =>
          let val floatValue = floatOf argValue2
          in
            I.LteqFloat_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal32 floatValue,
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
        | SI.GteqLargeInt_Const_1{argValue1, argEntry2, destination} =>
          I.GteqLargeInt_Const_1
          {
           argValue1 = LO argValue1,
           argIndex2 = VI argEntry2,
           destination = VI destination
          }
        | SI.GteqLargeInt_Const_2{argEntry1, argValue2, destination} =>
          I.GteqLargeInt_Const_2
          {
           argIndex1 = VI argEntry1,
           argValue2 = LO argValue2,
           destination = VI destination
          }
        | SI.GteqReal_Const_1{argValue1, argEntry2, destination} =>
          let val realValue = realOf argValue1
          in
            I.GteqReal_Const_1
                {
                 argValue1 = BT.RealToReal64 realValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.GteqReal_Const_2{argEntry1, argValue2, destination} =>
          let val realValue = realOf argValue2
          in
            I.GteqReal_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal64 realValue,
                 destination = VI destination
                }

          end
        | SI.GteqFloat_Const_1{argValue1, argEntry2, destination} =>
          let val floatValue = floatOf argValue1
          in
            I.GteqFloat_Const_1
                {
                 argValue1 = BT.RealToReal32 floatValue,
                 argIndex2 = VI argEntry2,
                 destination = VI destination
                }

          end
        | SI.GteqFloat_Const_2{argEntry1, argValue2, destination} =>
          let val floatValue = floatOf argValue2
          in
            I.GteqFloat_Const_2
                {
                 argIndex1 = VI argEntry1,
                 argValue2 = BT.RealToReal32 floatValue,
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

  (* NOTE: Because the number of args is not so many, the linear search
   *     will not harm. *)
  fun indexOfArgInArgs (funInfo : IMFunInfo) (arg : SI.varInfo) =
      let
        fun findi _ [] =
            raise
              Control.Bug (VarID.toString (#id arg) ^ " is not found in args.")
          | findi index ((hdArg : SI.varInfo) :: tlArgs) =
            if VarID.eq(#id hdArg, #id arg)
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
          symbolTableRef
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

        val symbolEntry = symbolTableEntry symbolTableRef

        fun translate (SI.Label _, rawInstructions) = rawInstructions
          | translate (SI.Location _, rawInstructions) = rawInstructions
          | translate (symInstruction, rawInstructions) =
            let
              val rawInstruction =
                  toRawInstruction VI LO symbolEntry symInstruction
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
          length = BT.UInt32.fromInt (String.size fileName),
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
                            + (BT.UInt32.fromInt(List.length string) div 0w4)
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
          locationsCount = BT.UInt32.fromInt(List.length locationTableEntries),
          locations = locationTableEntries,
          fileNamesCount = BT.UInt32.fromInt (List.length fileNames),
          fileNameOffsets = fileNameOffsets,
          fileNames = packedFileNames
        } : Executable.locationTable
      end
  fun buildNameSlotTable (nameSlotTableEntries, boundNames) =
      let
        val (packedBoundNames, boundNameOffsets) = packStringList boundNames
      in
        {
          nameSlotsCount = BT.UInt32.fromInt(List.length nameSlotTableEntries),
          nameSlots = nameSlotTableEntries,
          boundNamesCount = BT.UInt32.fromInt (List.length boundNames),
          boundNameOffsets = boundNameOffsets,
          boundNames = packedBoundNames
        } : Executable.nameSlotTable
      end
  end

  fun convertCluster ({frameInfo, functionCodes, loc} : SI.clusterCode) =
      map
          (fn {name, loc, args, instructions} =>
              {
               name = name,
               loc = loc,
               funInfo = 
               {
                args = args,
                bitmapvals = #bitmapvals frameInfo,
                pointers = #pointers frameInfo,
                atoms = #atoms frameInfo,
                doubles = #doubles frameInfo,
                records = #records frameInfo
               },
               instructions = instructions
              }
          )
          functionCodes

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
  fun assemble  clusterList =
      let
        val SIfunctionCodes = List.concat (map convertCluster clusterList)
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
        val symbolTable = ref emptySymbolTable
        val rawInstructions =
            foldr (toRawInstructions labelMap symbolTable) [] IMfunctionCodes

        val _ = #stop secondPassTimeCounter ()

(*
        val _ = #add instructionsCounter (List.length rawInstructions)
*)
      in
        case getErrors () of
          [] => 
          (
           {
            byteOrder = SD.NativeByteOrder,
            instructionsSize = lastOffset,
            instructions = rawInstructions,
            linkSymbolTable = makeSymbolTable (!symbolTable),
            locationTable = locationTable,
            nameSlotTable = nameSlotTable
            } : Executable.executable)
        | errors => raise UE.UserErrors (getErrorsAndWarnings ())
      end
        handle exn => raise exn

  (***************************************************************************)

end
