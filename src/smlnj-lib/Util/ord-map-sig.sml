(* ord-map-sig.sml
 *
 * COPYRIGHT (c) 1996 by AT&T Research.  See COPYRIGHT file for details.
 *
 * Abstract signature of an applicative-style finite maps (dictionaries)
 * structure over ordered monomorphic keys.
 *)

(*
Modification made by Atsushi Ohori, 2013-09-22.
The following functions are added
  val insertWith : ('a -> unit) -> 'a map * Key.ord_key * 'a -> 'a map
  val insertWithi : (Key.ord_key * 'a -> unit) -> 'a map * Key.ord_key * 'a -> 'a map
  val findi : 'a map * Key.ord_key -> (Key.ord_key * 'a) option
  val removei : 'a map * Key.ord_key -> Key.ord_key * 'a map * 'a
  val unionWithi2 : ((Key.ord_key * 'a) * (Key.ord_key * 'a) -> (Key.ord_key * 'a))
                     -> ('a map * 'a map) -> 'a map
  val intersectWithi2 : ((Key.ord_key * 'a) * (Key.ord_key * 'b) -> (Key.ord_key * 'c))
                        -> 'a map * 'b map -> 'c map
  val mergeWithi2 : ((Key.ord_key * 'a) * (Key.ord_key * 'b) -> (Key.ord_key * 'c))
                    -> 'a map * 'b map -> 'c map
  val mapi2 : (Key.ord_key * 'a -> Key.ord_key * 'b) -> 'a map -> 'b map

*)

signature ORD_MAP =
  sig

    structure Key : ORD_KEY

    type 'a map

    val empty : 'a map
	(* The empty map *)

    val isEmpty : 'a map -> bool
	(* Return true if and only if the map is empty *)

    val singleton : (Key.ord_key * 'a) -> 'a map
	(* return the specified singleton map *)

    val insert  : 'a map * Key.ord_key * 'a -> 'a map
    val insert' : ((Key.ord_key * 'a) * 'a map) -> 'a map
	(* Insert an item. *)


     val insertWith : ('a -> unit) -> 'a map * Key.ord_key * 'a -> 'a map
      (* ohori: same as insert except that it invokes a function when there is an old item.*)

    val insertWithi : (Key.ord_key * 'a -> unit) -> 'a map * Key.ord_key * 'a -> 'a map
     (* ohori: same as insertWith except that the extra function takes the key in the map.*)

    val find : 'a map * Key.ord_key -> 'a option
	(* Look for an item, return NONE if the item doesn't exist *)

    (* ohori: Same as find except that it retruns the key in the map.  *)
    val findi : 'a map * Key.ord_key -> (Key.ord_key * 'a) option

    val lookup : 'a map * Key.ord_key -> 'a
	(* look for an item, raise the NotFound exception if it doesn't exist *)

    val inDomain : ('a map * Key.ord_key) -> bool
	(* return true, if the key is in the domain of the map *)

    val remove : 'a map * Key.ord_key -> 'a map * 'a
	(* Remove an item, returning new map and value removed.
         * Raises LibBase.NotFound if not found.
	 *)

    (* ohori: same as remove except that it returns that removed key in the map. *)
    val removei : 'a map * Key.ord_key -> Key.ord_key * 'a map * 'a

    val first : 'a map -> 'a option
    val firsti : 'a map -> (Key.ord_key * 'a) option
	(* return the first item in the map (or NONE if it is empty) *)

    val numItems : 'a map ->  int
	(* Return the number of items in the map *)

    val listItems  : 'a map -> 'a list
    val listItemsi : 'a map -> (Key.ord_key * 'a) list
	(* Return an ordered list of the items (and their keys) in the map. *)

    val listKeys : 'a map -> Key.ord_key list
	(* return an ordered list of the keys in the map. *)

    val collate : ('a * 'a -> order) -> ('a map * 'a map) -> order
	(* given an ordering on the map's range, return an ordering
	 * on the map.
	 *)

    val unionWith  : ('a * 'a -> 'a) -> ('a map * 'a map) -> 'a map
    val unionWithi : (Key.ord_key * 'a * 'a -> 'a) -> ('a map * 'a map) -> 'a map
	(* return a map whose domain is the union of the domains of the two input
	 * maps, using the supplied function to define the map on elements that
	 * are in both domains.
	 *)

    (* ohori: same as unionWithi except that the extra function takes two pairs of key and value in the map
       and the key and the value that should be inserted.   *)
    val unionWithi2 : ((Key.ord_key * 'a) * (Key.ord_key * 'a) -> (Key.ord_key * 'a))
                       -> ('a map * 'a map) -> 'a map
    (* ohori: same as unionWithi except that the extra function takes two pairs of key and value in the map
       and the key and the value that should be inserted.   *)
    val unionWithi3 : ((Key.ord_key * 'a) option * (Key.ord_key * 'a) option -> (Key.ord_key * 'a))
                       -> ('a map * 'a map) -> 'a map

    val intersectWith  : ('a * 'b -> 'c) -> ('a map * 'b map) -> 'c map
    val intersectWithi : (Key.ord_key * 'a * 'b -> 'c) -> ('a map * 'b map) -> 'c map
	(* return a map whose domain is the intersection of the domains of the
	 * two input maps, using the supplied function to define the range.
	 *)

    (* ohori: same as intersectWithi except that the extra function takes two pairs of key and value in the map 
       and the key and the value that should be inserted.   *)
    val intersectWithi2 : ((Key.ord_key * 'a) * (Key.ord_key * 'b) -> (Key.ord_key * 'c))
                          -> 'a map * 'b map -> 'c map

    val mergeWith : ('a option * 'b option -> 'c option)
	  -> ('a map * 'b map) -> 'c map
    val mergeWithi : (Key.ord_key * 'a option * 'b option -> 'c option)
	  -> ('a map * 'b map) -> 'c map
	(* merge two maps using the given function to control the merge. For
	 * each key k in the union of the two maps domains, the function
	 * is applied to the image of the key under the map.  If the function
	 * returns SOME y, then (k, y) is added to the resulting map.
	 *)

    (* ohori: same as mergeWithi except that the extra function takes two pairs of key and value in the map 
       and the key and the value that should be inserted.   *)
    val mergeWithi2 : ((Key.ord_key * 'a) option * (Key.ord_key * 'b) option -> (Key.ord_key * 'c) option)
                     -> 'a map * 'b map -> 'c map

    val app  : ('a -> unit) -> 'a map -> unit
    val appi : ((Key.ord_key * 'a) -> unit) -> 'a map -> unit
	(* Apply a function to the entries of the map in map order. *)

    val map  : ('a -> 'b) -> 'a map -> 'b map
    val mapi : (Key.ord_key * 'a -> 'b) -> 'a map -> 'b map
	(* Create a new map by applying a map function to the
         * name/value pairs in the map.
         *)

    (* ohori: same as mapi except that it returns the removed key in the map.   *)
    val mapi2 : (Key.ord_key * 'a -> Key.ord_key * 'b) -> 'a map -> 'b map


    val foldl  : ('a * 'b -> 'b) -> 'b -> 'a map -> 'b
    val foldli : (Key.ord_key * 'a * 'b -> 'b) -> 'b -> 'a map -> 'b
	(* Apply a folding function to the entries of the map
         * in increasing map order.
         *)

    val foldr  : ('a * 'b -> 'b) -> 'b -> 'a map -> 'b
    val foldri : (Key.ord_key * 'a * 'b -> 'b) -> 'b -> 'a map -> 'b
	(* Apply a folding function to the entries of the map
         * in decreasing map order.
         *)

    val filter  : ('a -> bool) -> 'a map -> 'a map
    val filteri : (Key.ord_key * 'a -> bool) -> 'a map -> 'a map
	(* Filter out those elements of the map that do not satisfy the
	 * predicate.  The filtering is done in increasing map order.
	 *)

    val mapPartial  : ('a -> 'b option) -> 'a map -> 'b map
    val mapPartiali : (Key.ord_key * 'a -> 'b option) -> 'a map -> 'b map
	(* map a partial function over the elements of a map in increasing
	 * map order.
	 *)

  end (* ORD_MAP *)
