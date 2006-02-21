(**
 * a map from a slot index to a bound name in the source code.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SOURCE_NAME_SLOT_MAP.sig,v 1.1 2005/10/22 14:46:31 kiyoshiy Exp $
 *)
signature SOURCE_NAME_SLOT_MAP =
sig

  (***************************************************************************)

  (** map from slot index to its bound name *)
  type map

  (** offset of instruction *)
  type offset = BasicTypes.UInt32

  type slotIndex = BasicTypes.UInt32

  type boundName = string

  (***************************************************************************)

  (** empty map *)
  val empty : map

  (** append an entry to the map. *)
  val append : map * offset * offset * boundName * slotIndex -> map

  val getAll : map -> Executable.nameSlotTableEntry list * boundName list

  (***************************************************************************)

end
