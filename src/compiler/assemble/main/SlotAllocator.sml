(**
 * @author YAMATODANI Kiyoshi
 * @author Nguyen Huu Duc
 * @version $Id: SlotAllocator.sml,v 1.13 2007/01/21 13:41:32 kiyoshiy Exp $
 *)
structure SlotAllocator : SLOT_ALLOCATOR =
struct

  (***************************************************************************)

  structure AI = AllocationInfo
  structure BT = BasicTypes
  structure SI = SymbolicInstructions
  structure T = Types

  (***************************************************************************)

  val SLOTS_OF_POINTER_VAR = 0w1 : BT.UInt32
  val SLOTS_OF_ATOM_VAR = 0w1 : BT.UInt32
  val SLOTS_OF_DOUBLE_VAR = 0w2 : BT.UInt32
  val SLOTS_OF_RECORD_VAR = 0w2 : BT.UInt32

  fun createLabel () = T.newVarId()
(*
  val labelSeparator = "$LLS"
  fun createLabel () = labelSeparator + (T.newVarId()) * 4
*)
  (** implementation of slot allocation *)
  fun allocate
      ({pointers, atoms, doubles, records, ...} : SI.funInfo, instructions) =
      let
        val beginLabel = createLabel ()
        val endLabel = createLabel ()
        val newInstructions =
            SI.Label beginLabel :: instructions @ [SI.Label endLabel]

        (* the index of the first variable within the variables list is 0. *)
        fun allocateArea reservedSlots reservedSlotMap slotSize varInfos =
            let
              fun alloc (varInfo : SI.varInfo, {slotCount, slotMap}) =
                  let
                    val slotIndex = slotCount
                    val allocVarInfo =
                        {
                          id = #id varInfo,
                          displayName = #displayName varInfo,
                          slot = slotIndex,
                          beginLabel = beginLabel,
                          endLabel = endLabel
                        }
                  in
                    {
                      slotCount = slotCount + slotSize,
                      slotMap = SlotMap.register (slotMap, allocVarInfo)
                    }
                  end
            in
              foldl
                  alloc
                  {slotCount = reservedSlots, slotMap = reservedSlotMap}
                  varInfos
            end
        (* reserve the first pointer slot for ENV *)
        val pointersAllocation =
            allocateArea
                SLOTS_OF_POINTER_VAR
                SlotMap.empty
                SLOTS_OF_POINTER_VAR
                pointers
        val atomsAllocation =
            allocateArea 0w0 SlotMap.empty SLOTS_OF_ATOM_VAR atoms
        val doublesAllocation =
            allocateArea 0w0 SlotMap.empty SLOTS_OF_DOUBLE_VAR doubles
        val recordsAllocations =
            map (allocateArea 0w0 SlotMap.empty SLOTS_OF_RECORD_VAR) records
      in
        (
          newInstructions,
          {
            pointers = pointersAllocation,
            atoms = atomsAllocation,
            doubles = doublesAllocation,
            records = recordsAllocations
          } : AI.frameAllocationInfo
        )
      end

  (***************************************************************************)

end
