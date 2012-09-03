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

  type map = offset VarID.Map.map

  (***************************************************************************)

  val empty = VarID.Map.empty : map

  fun find (map, labelName) =
      case VarID.Map.find (map, labelName) of
        NONE =>
        raise
          Control.Bug ("label " ^ (VarID.toString labelName) ^ " is not found")
      | SOME offset => offset

  fun register (map, labelName, offset) =
      case VarID.Map.find (map, labelName) of
        NONE => VarID.Map.insert (map, labelName, offset)
      | SOME offset =>
        raise Control.Bug ("duplicated label: " ^ (VarID.toString labelName))

  (***************************************************************************)

end

