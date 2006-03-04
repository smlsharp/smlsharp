(**
 * a map from the offset of an instruction to the location in the source code.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SOURCE_LOCATION_MAP.sig,v 1.4 2006/02/28 16:10:59 kiyoshiy Exp $
 *)
signature SOURCE_LOCATION_MAP =
sig

  (***************************************************************************)

  (** map from offset to its location *)
  type map

  (** offset of instruction *)
  type offset = BasicTypes.UInt32

  type fileName = string

  (***************************************************************************)

  (** empty map *)
  val empty : map

  (** append an entry to the map. *)
  val append : map * offset * Loc.loc -> map

  val getAll : map -> Executable.locationTableEntry list * fileName list

  (***************************************************************************)

end
