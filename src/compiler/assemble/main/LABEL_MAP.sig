(**
 * a map from label to its offset.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: LABEL_MAP.sig,v 1.5 2006/02/28 16:10:59 kiyoshiy Exp $
 *)
signature LABEL_MAP =
sig

  (***************************************************************************)

  (** map from label to its offset *)
  type map

  (** label name *)
  type label = SymbolicInstructions.address

  (** offset of labels *)
  type offset = BasicTypes.UInt32

  (***************************************************************************)

  (** empty map *)
  val empty : map

  (** get offset of a label *)
  val find : map * label -> offset

  (** insert an entry for label to the map. *)
  val register : map * label * offset -> map

  (***************************************************************************)

end
