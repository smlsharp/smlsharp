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

  type map = varInfo LocalVarID.Map.map

  (***************************************************************************)

  val empty = LocalVarID.Map.empty : map

  fun find (map, SIVarInfo : SymbolicInstructions.varInfo) =
      case LocalVarID.Map.find (map, #id SIVarInfo) of
        NONE =>
        raise
          Control.Bug
              ("variable " ^ (LocalVarID.toString (#id SIVarInfo)) ^ " is not found")
      | SOME (varInfo : varInfo) => varInfo

  fun register (map, varInfo : varInfo) =
      let val varID = #id varInfo
      in
        case LocalVarID.Map.find (map, varID) of
          NONE => LocalVarID.Map.insert (map, varID, varInfo)
        | SOME _ =>
          raise Control.Bug ("duplicated variable: " ^ (LocalVarID.toString varID))
      end

  fun union (map1, map2) =
      LocalVarID.Map.unionWithi
          (fn (id, _, _) =>
              raise Control.Bug (LocalVarID.toString id ^ " is allocated twice"))
          (map1, map2)

  fun shift (map, shift : BT.UInt32) =
      LocalVarID.Map.map
          (fn {id, displayName, slot, beginLabel, endLabel} : varInfo =>
              {
                id = id,
                displayName = displayName,
                slot = slot + shift,
                beginLabel = beginLabel,
                endLabel = endLabel
              })
          map

  fun getAll map = LocalVarID.Map.listItems map

  fun varInfoToString
          ({id, displayName, slot, beginLabel, endLabel} : varInfo) =
      LocalVarID.toString id
      ^ ","
      ^ displayName
      ^ ","
      ^ BT.UInt32.toString slot
      ^ ","
      ^ (LocalVarID.toString beginLabel)
      ^ "-"
      ^ (LocalVarID.toString endLabel)

  fun mapToStrings map = List.map varInfoToString (LocalVarID.Map.listItems map)

  (***************************************************************************)

end

