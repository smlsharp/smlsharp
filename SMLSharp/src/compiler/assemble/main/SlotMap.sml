(**
 * a map from variable name to its slot index.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SlotMap.sml,v 1.11 2008/08/06 17:23:39 ohori Exp $
 *)
structure SlotMap : SLOT_MAP =
struct

  (***************************************************************************)

  structure BT = BasicTypes

  (***************************************************************************)

  type varID = SymbolicInstructions.varid

  type index = BT.UInt32

  type label = SymbolicInstructions.address

  type varInfo =
       {
         id : varID,
         displayName : string,
         (** the index of slot allocated for the variable *)
         slot : index,
         (** name of the label at the beginning of lifetime of the variable *)
         beginLabel : label,
         (** name of the label at the end of lifetime of the variable *)
         endLabel : label
       }

  type map = varInfo VarID.Map.map

  (***************************************************************************)

  val empty = VarID.Map.empty : map

  fun find (map, SIVarInfo : SymbolicInstructions.varInfo) =
      case VarID.Map.find (map, #id SIVarInfo) of
        NONE =>
        raise
          Control.Bug
              ("variable " ^ (VarID.toString (#id SIVarInfo)) ^ " is not found")
      | SOME (varInfo : varInfo) => varInfo

  fun register (map, varInfo : varInfo) =
      let val varID = #id varInfo
      in
        case VarID.Map.find (map, varID) of
          NONE => VarID.Map.insert (map, varID, varInfo)
        | SOME _ =>
          raise Control.Bug ("duplicated variable: " ^ (VarID.toString varID))
      end

  fun union (map1, map2) =
      VarID.Map.unionWithi
          (fn (id, _, _) =>
              raise Control.Bug (VarID.toString id ^ " is allocated twice"))
          (map1, map2)

  fun shift (map, shift : BT.UInt32) =
      VarID.Map.map
          (fn {id, displayName, slot, beginLabel, endLabel} : varInfo =>
              {
                id = id,
                displayName = displayName,
                slot = slot + shift,
                beginLabel = beginLabel,
                endLabel = endLabel
              })
          map

  fun getAll map = VarID.Map.listItems map

  fun varInfoToString
          ({id, displayName, slot, beginLabel, endLabel} : varInfo) =
      VarID.toString id
      ^ ","
      ^ displayName
      ^ ","
      ^ BT.UInt32.toString slot
      ^ ","
      ^ (VarID.toString beginLabel)
      ^ "-"
      ^ (VarID.toString endLabel)

  fun mapToStrings map = List.map varInfoToString (VarID.Map.listItems map)

  (***************************************************************************)

end

