(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: EXECUTABLE.sig,v 1.5 2007/01/13 03:35:00 kiyoshiy Exp $
 *)
signature EXECUTABLE =
sig

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
         offset : BasicTypes.UInt32,
         fileNameIndex : BasicTypes.UInt32,
         leftLine : BasicTypes.UInt32,
         leftCol : BasicTypes.UInt32,
         rightLine : BasicTypes.UInt32,
         rightCol : BasicTypes.UInt32
       }

  type locationTable =
       {
         locationsCount : BasicTypes.UInt32,
         locations : locationTableEntry list,
         fileNamesCount : BasicTypes.UInt32,
         fileNameOffsets : BasicTypes.UInt32 list,
         fileNames : serializedString list
       }

  type executable =
       {
         byteOrder : SystemDefTypes.byteOrder,
         instructionsSize : BasicTypes.UInt32,
         instructions : Instructions.instruction list,
         locationTable : locationTable,
         nameSlotTable : nameSlotTable
       }

  (***************************************************************************)

  val emptyLocationTable : locationTable
  val emptyNameSlotTable : nameSlotTable
  val locationTableEntryToString : locationTableEntry -> string
  val locationTableToString : locationTable -> string
  val nameSlotTableEntryToString : nameSlotTableEntry -> string
  val nameSlotTableToString : nameSlotTable -> string
  val getFileNamesOfLocationTable : locationTable -> string list

  (***************************************************************************)

end
