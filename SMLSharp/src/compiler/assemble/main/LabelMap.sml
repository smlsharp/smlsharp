(**
 * a map from label to its offset.
 * @author YAMATODANI Kiyoshi
 * @version $Id: LabelMap.sml,v 1.5 2008/08/06 17:23:39 ohori Exp $
 *)
structure LabelMap : LABEL_MAP =
struct

  (***************************************************************************)

  structure BT = BasicTypes

  (***************************************************************************)

  type label = SymbolicInstructions.address

  type offset = BT.UInt32

  type map = offset LocalVarID.Map.map

  (***************************************************************************)

  val empty = LocalVarID.Map.empty : map

  fun find (map, labelName) =
      case LocalVarID.Map.find (map, labelName) of
        NONE =>
        raise
          Control.Bug ("label " ^ (LocalVarID.toString labelName) ^ " is not found")
      | SOME offset => offset

  fun register (map, labelName, offset) =
      case LocalVarID.Map.find (map, labelName) of
        NONE => LocalVarID.Map.insert (map, labelName, offset)
      | SOME offset =>
        raise Control.Bug ("duplicated label: " ^ (LocalVarID.toString labelName))

  (***************************************************************************)

end

