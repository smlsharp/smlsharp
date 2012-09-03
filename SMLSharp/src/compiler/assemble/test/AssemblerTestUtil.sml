(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: AssemblerTestUtil.sml,v 1.10 2006/02/20 06:52:03 kiyoshiy Exp $
 *)
structure AssemblerTestUtil : ASSEMBLER_TEST_UTIL =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure SA = SlotAllocator  
  structure BT = BasicTypes
  structure SI = SymbolicInstructions
  structure I = Instructions
  structure ISC = InstructionSizeCalculator

  (***************************************************************************)

  local
    val nameToIDMapRef = ref SEnv.empty
    fun find name = SEnv.find (!nameToIDMapRef, name)
    fun register name =
        case find name of
          NONE => 
          let val ID = ID.generate ()
          in nameToIDMapRef := SEnv.insert (!nameToIDMapRef, name, ID); ID
          end
        | SOME ID => ID
  in
  fun makeVarInfo varName =
      {id = register varName, displayName = varName} : SI.varInfo
  fun nameToAddress label = register label
  fun nameToVarID name = register name
  end

  fun makeMonoFunInfo {pointers, atoms} =
      {
        args = [],
        bitmapvals = {args = [], frees = []},
        pointers = map makeVarInfo pointers,
        atoms = map makeVarInfo atoms,
        doubles = [],
        records = []
      } : SI.funInfo

  fun getSlotMap funInfo instructions =
      let
        val (instructions', allocationInfo) =
            SlotAllocator.allocate (funInfo, instructions )
        val (frameSize, slotMap, allocationInfo) =
            StackFrame.fixFrameLayout allocationInfo
      in (instructions', slotMap) end

  fun getEntry funInfo instructions varName =
      let val (_, slotMap) = getSlotMap funInfo instructions
      in #slot (SlotMap.find (slotMap, makeVarInfo varName))
      end

  (**
   * This functions assumes that InstructionSizeCalculator structure is
   * implemented correctly.
   * This function should not be used to test InstructionSizeCalculator.
   *)
  fun funEntrySize (funInfo : SI.funInfo) =
      InstructionSizeCalculator.wordsOfFunEntry funInfo

  (**
   * This functions assumes that StackFrame structure is implemented correctly.
   * This function should not be used to test StackFrame.
   *)
  fun assembledFunInfo (funInfo : SI.funInfo) instructions =
      let
        val (_, slotMap) = getSlotMap funInfo instructions
        fun getEntry varName = SlotMap.find (slotMap, varName)
        fun length list = UInt32.fromInt(List.length list)
        fun getIndex list ({id, ...} : SI.varInfo) =
            let
              fun scan [] _ = raise Control.Bug ("not found:" ^ ID.toString id)
                | scan ((head : SI.varInfo) :: tail) position =
                  if #id head = id
                  then position
                  else scan tail (position + 0w1)
            in
              scan list (0w0 : BT.UInt32)
            end
        fun length list = BT.IntToUInt32(List.length list)
        (* 1 slot reserved for ENV entry. *)
        val pointersSlots = 
          (0w1 + length (#pointers funInfo)) * SA.SLOTS_OF_POINTER_VAR
        val atomsSlots =
          (length (#atoms funInfo) * SA.SLOTS_OF_ATOM_VAR)
          + (length (#doubles funInfo) * SA.SLOTS_OF_DOUBLE_VAR)
        val recordsSlotsList = 
            map
                (fn records => length records * SA.SLOTS_OF_RECORD_VAR)
                (#records funInfo)

        val frameSize =
            StackFrame.frameSize
                {
                  pointersSlots = pointersSlots,
                  atomsSlots = atomsSlots,
                  recordsSlotsList = recordsSlotsList
                }
      in
        I.FunEntry
        {
          arity = length(#args funInfo),
          argsdest = map (#slot o getEntry) (#args funInfo),
          bitmapvalsArgsCount = length(#args(#bitmapvals funInfo)),
          bitmapvalsArgs =
          map (getIndex (#args funInfo)) (#args(#bitmapvals funInfo)),
          bitmapvalsFreesCount = length(#frees(#bitmapvals funInfo)),
          bitmapvalsFrees = #frees(#bitmapvals funInfo),
          frameSize = frameSize,
          startOffset = ISC.wordsOfFunEntry funInfo,
          pointers = pointersSlots,
          atoms = atomsSlots,
          recordGroupsCount = length (#records funInfo),
          recordGroups = recordsSlotsList
        }
      end

  (****************************************)

  fun assertEqualInstruction expected actual =
      if I.equal (expected, actual)
      then actual
      else Assert.failByNotEqual (I.toString expected, I.toString actual)

  fun assertEqualInstructionList expected actual =
      Assert.assertEqualList assertEqualInstruction expected actual

  (***************************************************************************)

end
