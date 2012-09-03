(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: AllocationInfo.sml,v 1.6 2005/11/13 05:16:25 kiyoshiy Exp $
 *)
structure AllocationInfo =
struct

  (***************************************************************************)

  structure BT = BasicTypes

  (***************************************************************************)

  (** allocation information for variables whose type is same.
   * <p>
   * NOTE: slotCount and the number of elements in slotMap is not always the
   * same. Slots for padding may be included in slotCount.
   * </p>
   *)
  type areaAllocationInfo =
       {
         (** the numer of slots *) slotCount : BT.UInt32,
         (** a map from each variable to the first slot allocated for the
          * variable. *) slotMap : SlotMap.map
       }

  (** allocation information for a function *)
  type frameAllocationInfo =
       {
         (** allocation information for pointer variables *)
         pointers : areaAllocationInfo,
         (** allocation information for atom variables.
          * After StackFrame.fixIndex, it includes double type variables *)
         atoms : areaAllocationInfo,
         (** allocation information for double variables. *)
         doubles : areaAllocationInfo,
         (** allocation informations for polytype variables *)
         records : areaAllocationInfo list
       }

  fun areaAllocationInfoToString {slotCount, slotMap} =
      concat
          ([
             "count = ",
             UInt32.toString slotCount,
             "\n",
             "entries: \n"
           ]
           @ (map (fn s => "  " ^ s ^ "\n") (SlotMap.mapToStrings slotMap)))

  fun frameAllocationInfoToString {pointers, atoms, doubles, records} =
      concat
          ([
             "pointers:",
             areaAllocationInfoToString pointers,
             "atoms:",
             areaAllocationInfoToString atoms,
             "doubles:",
             areaAllocationInfoToString doubles,
             "records:"
           ]
           @ (map areaAllocationInfoToString records))

  (***************************************************************************)

end
