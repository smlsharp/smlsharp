(**
 * a map from variable name to its slot index.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SLOT_MAP.sig,v 1.3 2005/11/13 05:16:25 kiyoshiy Exp $
 *)
signature SLOT_MAP =
sig

  (***************************************************************************)

  (** a map from variable name to its slot index *)
  type map

  (** identifier of variables *)
  type varID = SymbolicInstructions.varid

  (** index allocated of variables *)
  type index = BasicTypes.UInt32

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

  (***************************************************************************)

  (** empty map *)
  val empty : map

  (** get the index of the variable *)
  val find : map * SymbolicInstructions.varInfo -> varInfo

  (** insert an entry for an variable *)
  val register : map * varInfo -> map

  (** unin two maps *)
  val union : map * map -> map

  (** add the specified integer to each indexes in the map *)
  val shift : map * BasicTypes.UInt32 -> map

  (** get all entries. *)
  val getAll : map -> varInfo list

  val varInfoToString : varInfo -> string

  val mapToStrings : map -> string list

  (***************************************************************************)

end
