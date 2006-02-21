(**
 * Copyright (c) 2006, Tohoku University.
 *
 * a map from a slot index to a bound name in the source code.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SourceNameSlotMap.sml,v 1.3 2006/02/18 04:59:16 ohori Exp $
 *)
structure SourceNameSlotMap : SOURCE_NAME_SLOT_MAP =
struct

  (***************************************************************************)

  (**
   *  an ordered set of Executable.nameSlotTableEntry.
   * Entries are ordered by beginOffset in the ascending order.
   * If two entries have the same beginOffset, they are ordered by endOffset
   * in the ascending order.
   * If both beginOffset and endOffset are the same, those entries are sorted
   * in undefined order.
   *  Because more than one entry may share the same beginOffset and endOffset,
   * BinarySet is used, not BinaryMap.
   *)
  structure EntrySet =
  BinarySetFn
  (struct
     type ord_key = Executable.nameSlotTableEntry
     fun compare (left : ord_key, right : ord_key) =
         case
           UInt32.compare
               (#lifeTimeBeginOffset left, #lifeTimeBeginOffset right)
          of EQUAL =>
             (case
                UInt32.compare
                    (#lifeTimeEndOffset left, #lifeTimeEndOffset right)
               of EQUAL => LESS (* never return EQUAL *)
                | order => order)
           | order => order
   end)

  (***************************************************************************)

  (** offset of instruction *)
  type offset = BasicTypes.UInt32

  type slotIndex = BasicTypes.UInt32

  type boundName = string

  type boundNameIndex = int

  type entry = Executable.nameSlotTableEntry

  type map =
       {
         entrySet : EntrySet.set,
         (**
          *  list of boundNames.
          * BoundNames are sorted in the reverse order of addition.
          * That is, the last added name is at the head of the list.
          *  This list may contain duplication of boundNames. It wastes memory.
          * But, duplication of boundNames is expected to be not much.
          * The time cost to eliminate duplication is more expensive than this
          * memory cost.
          *)
         boundNames : boundName list,
         (** the number of bound names in the boundNames field.
          * This value is used as the index of an entry which is added to
          * the boundNames next.
          * That is, index 0 is allocated to the first added entry.
          *)
         boundNamesCount : int
       }

  (***************************************************************************)

  val empty =
      {entrySet = EntrySet.empty, boundNames = [], boundNamesCount = 0} : map

  fun append (map, beginOffset, endOffset, boundName, slotIndex) =
      case map of
        {entrySet, boundNames, boundNamesCount} =>
        let
          val newBoundNames = boundName :: boundNames (* reverse order *)
          val boundNameIndex = boundNamesCount
          val newBoundNamesCount = boundNamesCount + 1
          val entry = 
              {
                lifeTimeBeginOffset = beginOffset,
                lifeTimeEndOffset = endOffset,
                nameIndex = BasicTypes.IntToUInt32 boundNameIndex,
                slotIndex = slotIndex
              } : entry
          val newEntrySet = EntrySet.add (entrySet, entry)
        in
          {
            entrySet = newEntrySet,
            boundNames = newBoundNames,
            boundNamesCount = newBoundNamesCount
          }
        end

   fun getAll ({entrySet, boundNames, ...} : map) =
      let
        val entries = EntrySet.listItems entrySet
        val orderedBoundNames = List.rev boundNames
      in
        (entries, orderedBoundNames)
      end

  (***************************************************************************)

end
