(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: Executable.sml,v 1.6 2007/06/20 06:50:41 kiyoshiy Exp $
 *)
structure Executable : EXECUTABLE =
struct

  (***************************************************************************)

  structure BT = BasicTypes

  (***************************************************************************)

  type serializedString =
       {length : BasicTypes.UInt32, string : BasicTypes.UInt8 list}

  type nameSlotTableEntry =
       {
         lifeTimeBeginOffset : BasicTypes.UInt32,
         lifeTimeEndOffset : BasicTypes.UInt32,
         nameIndex : BasicTypes.UInt32,
         slotIndex : BasicTypes.UInt32
       }

  type nameSlotTable =
       {
         nameSlotsCount : BasicTypes.UInt32,
         nameSlots : nameSlotTableEntry list,
         boundNamesCount : BasicTypes.UInt32,
         boundNameOffsets : BasicTypes.UInt32 list,
         boundNames : serializedString list
       }

  type locationTableEntry =
       {
         offset : BT.UInt32,
         fileNameIndex : BT.UInt32,
         leftLine : BT.UInt32,
         leftCol : BT.UInt32,
         rightLine : BT.UInt32,
         rightCol : BT.UInt32
       }

  type locationTable =
       {
         locationsCount : BT.UInt32,
         locations : locationTableEntry list,
         fileNamesCount : BT.UInt32,
         fileNameOffsets : BT.UInt32 list,
         fileNames : serializedString list
       }

  type executable =
       {
         byteOrder : SystemDefTypes.byteOrder,
         instructionsSize : BT.UInt32,
         instructions : Instructions.instruction list,
         locationTable : locationTable,
         nameSlotTable : nameSlotTable
       }

  (***************************************************************************)

  val emptyLocationTable =
       {
         locationsCount = 0w0,
         locations = [],
         fileNamesCount = 0w0,
         fileNameOffsets = [],
         fileNames = []
       } : locationTable

  val emptyNameSlotTable =
       {
         nameSlotsCount = 0w0,
         nameSlots = [],
         boundNamesCount = 0w0,
         boundNameOffsets = [],
         boundNames = []
       } : nameSlotTable

  local
    fun toDecString uint32 = Int.toString(BT.UInt32.toInt uint32)
    fun UInt8ListToString bytes = BT.UInt8ListToString bytes
    fun deserializeString {string, length} = 
        BT.UInt8ListToString (List.take (string, BT.UInt32.toInt length))
  in
  fun locationTableEntryToString
      {offset, fileNameIndex, leftLine, leftCol, rightLine, rightCol} =
       "{offset = " ^ BT.UInt32.toString offset ^ ", \
        \fileNameIndex = " ^ BT.UInt32.toString fileNameIndex ^ ", \
        \leftLine = " ^ toDecString leftLine ^ ", \
        \leftCol = " ^ toDecString leftCol ^ ", \
        \rightLine = " ^ toDecString rightLine ^ ", \
        \rightCol = " ^ toDecString rightCol ^
       "}"
  fun locationTableToString
      {locationsCount, locations, fileNamesCount, fileNameOffsets, fileNames} =
      "{\n\
      \locations:\n" ^
      concat
          (map
               (fn entry => locationTableEntryToString entry ^ "\n")
               locations) ^
      "fileNameOffsets:\n" ^
      concat (map (fn offset => (toDecString offset) ^ "\n") fileNameOffsets) ^
      "fileNames:\n" ^
      concat
          (map
               (fn name => (deserializeString name) ^ "\n")
               fileNames) ^
      "}"
  fun nameSlotTableEntryToString
      {lifeTimeBeginOffset, lifeTimeEndOffset, nameIndex, slotIndex} =
       "{beginOffset = " ^ BT.UInt32.toString lifeTimeBeginOffset ^ ", \
        \endOffset = " ^ BT.UInt32.toString lifeTimeEndOffset ^ ", \
        \nameIndex = " ^ BT.UInt32.toString nameIndex ^ ", \
        \slotIndex = " ^ BT.UInt32.toString slotIndex ^ 
       "}"
  fun nameSlotTableToString (table : nameSlotTable) =
      "{\n\
      \nameSlots:\n" ^
      concat
          (map
               (fn entry => nameSlotTableEntryToString entry ^ "\n")
               (#nameSlots table)) ^
      "boundNameOffsets:\n" ^
      (concat
           (map
                (fn offset => (toDecString offset) ^ "\n")
                (#boundNameOffsets table))) ^
      "boundNames:\n" ^
      (concat
           (map
                (fn name => (deserializeString name) ^ "\n")
                (#boundNames table))) ^
      "}"

  fun getFileNamesOfLocationTable (locationTable : locationTable) = 
      let
        val fileNames = #fileNames locationTable
      in map deserializeString fileNames
      end

  end

  (***************************************************************************)

end
