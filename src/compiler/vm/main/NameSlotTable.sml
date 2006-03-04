(**
 * @copyright (c) 2006, Tohoku University.
 *)
local

  open RuntimeTypes
  open BasicTypes
  structure C = Counter
  structure E = Executable
  structure ES = ExecutableSerializer
  structure H = Heap
  structure I = Instructions
  structure P = Primitives
  structure RC = RuntimeCounters
  structure RE = RuntimeErrors
  structure RM = RawMemory
  structure SU = SignalUtility
  structure U = Utility
in
(**
 * This module manipulates the runtime table of variable name map.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: NameSlotTable.sml,v 1.6 2006/02/28 16:11:12 kiyoshiy Exp $
 *)
structure NameSlotTable
          : sig
             val getSlotOfName : codeRef -> string -> UInt32 option
             val getNameOfSlot : codeRef -> UInt32 -> string option
             val getLiveLocalVariables : codeRef -> (UInt32 * string) list
          end =
struct

  (***************************************************************************)

  fun getNameSlotTableEntries ({nameSlots, ...} : E.nameSlotTable) offset =
      let
        fun isLiveEntry (entry : E.nameSlotTableEntry) =
            (#lifeTimeBeginOffset entry <= offset)
            andalso (offset <= #lifeTimeEndOffset entry)
      in
        List.filter isLiveEntry nameSlots
      end

  fun getLiveLocalVariables 
          {executable = {nameSlotTable, ...} : executable, offset} =
      let
        val {nameSlots, boundNames, ...} : E.nameSlotTable = nameSlotTable
        val liveSlots = getNameSlotTableEntries nameSlotTable offset
        fun getSlotNamePair (entry : E.nameSlotTableEntry) =
            let
              val name = 
                  U.deserializeString
                      (List.nth (boundNames, UInt32ToInt (#nameIndex entry)))
            in
              (#slotIndex entry, name)
            end
        val slotNamePairs = List.map getSlotNamePair liveSlots
      in
        slotNamePairs
      end

  fun getSlotOfName 
          {executable = {nameSlotTable, ...} : executable, offset} name =
      let
        val {nameSlots, boundNames, ...} : E.nameSlotTable = nameSlotTable
        val liveSlots = getNameSlotTableEntries nameSlotTable offset
        val nameIndexOpt =
            List.find
                (fn (index, boundName) => name = U.deserializeString boundName)
                (ListPair.zip
                     (List.tabulate(length boundNames, fn x => x), boundNames))
      in
        case nameIndexOpt of
          NONE => NONE
        | SOME(nameIndex, _) =>
          let
            val entryOpt =
                List.find
                    (fn (entry : E.nameSlotTableEntry) =>
                        #nameIndex entry = IntToUInt32 nameIndex)
                    liveSlots
          in
            case entryOpt of
              NONE => NONE
            | SOME{slotIndex, ...} => SOME slotIndex
          end
      end

  fun getNameOfSlot
          {executable = {nameSlotTable, ...} : executable, offset} slot =
      let
        val {nameSlots, boundNames, ...} : E.nameSlotTable = nameSlotTable
        val liveSlots = getNameSlotTableEntries nameSlotTable offset
        val entry =
            List.find
                (fn (entry : E.nameSlotTableEntry) => #slotIndex entry = slot)
                liveSlots
      in

        TextIO.print ("offset = " ^ UInt32.toString offset ^ 
                      ", slot = " ^ UInt32.toString slot ^ "\n");

        case entry of
          NONE => NONE
        | SOME{nameIndex, ...} =>
          let val boundName = List.nth (boundNames, UInt32.toInt nameIndex)
          in SOME (U.deserializeString boundName)
          end
      end

  (***************************************************************************)

end (* structure *)

end (* local *)
