(**
 * Copyright (c) 2006, Tohoku University.
 *
 * a map from the offset of an instruction to the location in the source code.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SOURCE_LOCATION_MAP.sig,v 1.3 2006/02/18 04:59:16 ohori Exp $
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
