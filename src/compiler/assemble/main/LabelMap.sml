(**
 * a map from label to its offset.
 * @author YAMATODANI Kiyoshi
 * @version $Id: LabelMap.sml,v 1.4 2005/11/20 04:01:46 kiyoshiy Exp $
 *)
structure LabelMap : LABEL_MAP =
struct

  (***************************************************************************)

  structure BT = BasicTypes

  (***************************************************************************)

  type label = SymbolicInstructions.address

  type offset = BT.UInt32

  type map = offset ID.Map.map

  (***************************************************************************)

  val empty = ID.Map.empty : map

  fun find (map, labelName) =
      case ID.Map.find (map, labelName) of
        NONE =>
        raise
          Control.Bug ("label " ^ (ID.toString labelName) ^ " is not found")
      | SOME offset => offset

  fun register (map, labelName, offset) =
      case ID.Map.find (map, labelName) of
        NONE => ID.Map.insert (map, labelName, offset)
      | SOME offset =>
        raise Control.Bug ("duplicated label: " ^ (ID.toString labelName))

  (***************************************************************************)

end

