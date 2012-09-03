(**
 *  Abstraction of a stack frame which depends on the implementation of the
 * IML runtime.
 * <p>
 * The stack frame layout is as follows.
 * Assume that the function is typed with k type variables:
 * <pre>
 *    val f : ['a1, 'a2, ..., 'ak. ty]
 * </pre>
 * NOTE: In assembled code and runtime, double values area is included in atoms
 * area.
 * <pre>
 * {
 *    frameSize,          ; the number of cells of the frame
 *    funinfo,            ; a pointer to the funinfo of this frame
 *    bitmap,             ; frame bitmap. (see below.)
 *    returnAddress,
 *    pointers[0],     ; pointer values (this slot is reserved for ENV)
 *       :
 *    pointers[pointers-1],
 *    atoms[0],        ; atom values
 *       :
 *    atoms[atoms-1],
 *    records('a1)[0], ; record values depending on 'a1
 *       :
 *    records('a1)[records('a1)-1],
 *       :
 *    records('ak)[0],
 *       :
 *    records('ak)[records('ak)-1]
 *  }
 * </pre>
 * </p>
 * <p>
 * NOTE: <code>records('ai)</code> are not equal to the number of variables
 * of real type and of 'ai.
 * Each variable of 'ai occupies two slots.
 * Therefore, the stack frame holds <code>records('ai)/2</code> variables of
 * the type 'ai.
 * But, this <code>StackFrame</code> structure does not concern this
 * conversion between the slots number and the variables number.
 * It is the task of <code>SlotAllocator</code> structure.
 * </p>
 * <p>
 * The frame bitmap for the above frame is composed from k bits.
 * It is composed as follows.
 *       b1 | (b2 << 1) | ... | (b(k-1) << (k - 2)) | (bk << (k - 1))
 * (bi is the bit for a type variable ti.)
 * That is, the least siginificant bit of the bitmap indicates the
 * instantiated type of the last type variable bk.
 * </p>
 * @author YAMATODANI Kiyoshi
 * @author Nguyen Huu Duc
 * @version $Id: StackFrame.sml,v 1.14 2007/06/20 06:50:41 kiyoshiy Exp $
 *)
structure StackFrame : STACK_FRAME =
struct

  (***************************************************************************)

  structure AI = AllocationInfo
  structure BT = BasicTypes
  structure E = AssembleError

  (***************************************************************************)

  (**
   * maximum number of record groups.
   *)
  val MAX_RECORD_GROUPS = 32

  (** the index of the first slot of a frame. *)
  val FRAME_SLOT_BASE = 0w1 : BT.UInt32

  val DOUBLE_SLOT_ALIGNMENT = 0w2 : BT.UInt32
  val RECORD_SLOT_ALIGNMENT = 0w2 : BT.UInt32
  val FRAME_ALIGNMENT = 0w2 : BT.UInt32

  (**
   * the number of words occupied by fixed header of a frame.
   * <ul>
   *   <li>frame size</li>
   *   <li>a pointer to the funinfo of this frame</li>
   *   <li>bitmap</li>
   *   <li>return address</li>
   * </ul>
   *)
  val WORDS_OF_FRAME_HEADER = 0w4 : BT.UInt32

  (**
   * calculates the number of words necessary to allocate a frame which
   * contains specified variables.
   *)
  fun frameSize {pointersSlots, atomsSlots, recordsSlotsList} =
      let
        (** utility function *)
        fun total wordList = foldl (op +) (0w0 : BT.UInt32) wordList
        val recordsSlots = total recordsSlotsList

        val frameSize =
            WORDS_OF_FRAME_HEADER +
            pointersSlots +
            atomsSlots +
            recordsSlots
      in
          frameSize
      end

  (**
   * converts slot indexes to frame indexes to fix the layout of stack frame.
   * <p>
   * <dl>
   *   <dt>frame index</dt>
   *   <dd>the index of a slot within the frame it belongs to.
   *     The index of first slot is 1.</dd>
   *   <dt>slot index</dt>
   *   <dd>the index of a slot within the list of slots of the same
   *     bitmap type. The index of the first slot is 0.</dd>
   * </dl>
   * </p>
   * <p>
   *  In the result allocationInfo, frame indexes of doubles and records are
   * aligned at double-word boundary in a frame.
   *  To achieve this, this function inserts some nonused slots between atoms
   * slots and doubles slots, if necessary.
   * </p>
   * <p>
   *  In the result allocationInfo, slots for 'real float' variables are
   * included in slots for atoms.
   *  'doubles' of the result allocationInfo is empty.
   * </p>
   *)
  fun fixFrameLayout
          (frameAllocationInfo as {pointers, atoms, doubles, records}
           : AI.frameAllocationInfo) =
      let
(*
        val _ = print "****** before fixLayout *****\n"
        val _ =
            print (AI.frameAllocationInfoToString frameAllocationInfo)
*)
        val _ =
            if MAX_RECORD_GROUPS < List.length records
            then raise E.TooManyRecordGroups
            else ()

        (* the frame index of first pointer slot *)
        val firstPointerIndex = FRAME_SLOT_BASE + WORDS_OF_FRAME_HEADER
        val pointersSlots = #slotCount pointers

        (* the frame index of the first atom slot *)
        val firstAtomIndex = firstPointerIndex + pointersSlots
        local
          val firstDoubleIndex = firstAtomIndex + (#slotCount atoms)
          (*  If the first double slot is not aligned, some atom slots for
           * padding is inserted before it.
           * NOTE:
           * Because slot index is 1 base, boundary indexes are
           *     1, 3, ..., (a * n + 1)
           * ('a' is the number of alignment words.)
           * For example, assume alignment = 4, then,
           * (index = 1) => (padding = 0), 2 => 3, 3 => 2, 4 => 1, ...
           *)
          val padding =
              case
                (firstDoubleIndex - FRAME_SLOT_BASE) mod DOUBLE_SLOT_ALIGNMENT
               of
                0w0 => 0w0
              | modulo => DOUBLE_SLOT_ALIGNMENT - modulo
        in
        val atomsSlots = (#slotCount atoms) + padding
        end

        (* the frame index of the first double slot *)
        val firstDoubleIndex = firstAtomIndex + atomsSlots
        val doublesSlots = #slotCount doubles

        (* Because double slots are aligned, records slots are also
         * automatically aligned. *)
        (* the frame index of the first record group *)
        val firstRecordsIndex = firstDoubleIndex + doublesSlots

        val pointersInfo =
            {
              slotCount = pointersSlots,
              slotMap = SlotMap.shift (#slotMap pointers, firstPointerIndex)
            }
        val atomsInfo =
            {
              slotCount = atomsSlots + doublesSlots,
              slotMap =
              SlotMap.union
                  (
                    SlotMap.shift (#slotMap atoms, firstAtomIndex),
                    SlotMap.shift (#slotMap doubles, firstDoubleIndex)
                  )
            }

        val (lastSlot, recordsInfos) =
            foldl
                (fn (allocInfo, (usedSlots, infos)) =>
                    let
                      (* the number of slots preceding the first data entry
                       * of this group. *)
                      val slotsBeforeRecord = usedSlots

                      val slotCount = #slotCount allocInfo
                      val slotMap =
                          SlotMap.shift (#slotMap allocInfo, slotsBeforeRecord)
                      val info =
                          {slotCount = #slotCount allocInfo, slotMap = slotMap}
                    in
                      (slotsBeforeRecord + slotCount, info :: infos)
                    end)
                (firstRecordsIndex, [])
                records
        val recordsInfos = List.rev recordsInfos

        (* get union of all maps for this frame *)
        val unionedSlotMap = 
            foldl
                SlotMap.union
                (#slotMap pointersInfo)
                ((#slotMap atomsInfo) :: (map #slotMap recordsInfos))

        val frameSize =
            frameSize
                {
                  pointersSlots = #slotCount pointersInfo,
                  atomsSlots = #slotCount atomsInfo,
                  recordsSlotsList = map #slotCount recordsInfos
                }

        val _ =
            if 0w0 = frameSize mod FRAME_ALIGNMENT
            then ()
            else
              raise
                Control.Bug
                    ("non aligned frame size:" ^ BT.UInt32.toString frameSize)

        val newFrameAllocationInfo = 
            {
              pointers = pointersInfo,
              atoms = atomsInfo,
              doubles = {slotCount = 0w0, slotMap = SlotMap.empty},
              records = recordsInfos
            } : AI.frameAllocationInfo
(*
        val _ = print "****** after fixLayout *****\n"
        val _ =
            print (AI.frameAllocationInfoToString newFrameAllocationInfo)
*)
      in
        (frameSize, unionedSlotMap, newFrameAllocationInfo)
      end

  (***************************************************************************)

end

