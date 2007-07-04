(**
 * a map from variable name to its slot index.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SlotMap.sml,v 1.10 2007/06/20 06:50:41 kiyoshiy Exp $
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

  type map = varInfo ID.Map.map

  (***************************************************************************)

  val empty = ID.Map.empty : map

  fun find (map, SIVarInfo : SymbolicInstructions.varInfo) =
      case ID.Map.find (map, #id SIVarInfo) of
        NONE =>
        raise
          Control.Bug
              ("variable " ^ (ID.toString (#id SIVarInfo)) ^ " is not found")
      | SOME (varInfo : varInfo) => varInfo

  fun register (map, varInfo : varInfo) =
      let val varID = #id varInfo
      in
        case ID.Map.find (map, varID) of
          NONE => ID.Map.insert (map, varID, varInfo)
        | SOME _ =>
          raise Control.Bug ("duplicated variable: " ^ (ID.toString varID))
      end

  fun union (map1, map2) =
      ID.Map.unionWithi
          (fn (id, _, _) =>
              raise Control.Bug (ID.toString id ^ " is allocated twice"))
          (map1, map2)

  fun shift (map, shift : BT.UInt32) =
      ID.Map.map
          (fn {id, displayName, slot, beginLabel, endLabel} : varInfo =>
              {
                id = id,
                displayName = displayName,
                slot = slot + shift,
                beginLabel = beginLabel,
                endLabel = endLabel
              })
          map

  fun getAll map = ID.Map.listItems map

  fun varInfoToString
          ({id, displayName, slot, beginLabel, endLabel} : varInfo) =
      ID.toString id
      ^ ","
      ^ displayName
      ^ ","
      ^ BT.UInt32.toString slot
      ^ ","
      ^ (ID.toString beginLabel)
      ^ "-"
      ^ (ID.toString endLabel)

  fun mapToStrings map = List.map varInfoToString (ID.Map.listItems map)

  (***************************************************************************)

end

