(* hash-cons-set-sig.sml
 *
 * COPYRIGHT (c) 2001 Bell Labs, Lucent Technologies
 *
 * Finnite sets of hash-consed objects.
 *)


signature HASH_CONS_SET =
  sig

    type 'a obj = 'a HashCons.obj

    type 'a set

    val empty : 'a set
	(* The empty set *)

    val singleton : 'a obj -> 'a set
	(* Create a singleton set *)

    val add  : 'a set * 'a obj -> 'a set
    val add' : ('a obj * 'a set) -> 'a set
	(* Insert an item. *)

    val addList : 'a set * 'a obj list -> 'a set
	(* Insert items from list. *)

    val delete : 'a set * 'a obj -> 'a set
	(* Remove an item. Raise NotFound if not found. *)

    val member : 'a set * 'a obj -> bool
	(* Return true if and only if item is an element in the set *)

    val isEmpty : 'a set -> bool
	(* Return true if and only if the set is empty *)

    val equal : ('a set * 'a set) -> bool
	(* Return true if and only if the two sets are equal *)

    val compare : ('a set * 'a set) -> order
	(* does a lexical comparison of two sets *)

    val isSubset : ('a set * 'a set) -> bool
	(* Return true if and only if the first set is a subset of the second *)

    val numItems : 'a set ->  int
	(* Return the number of items in the table *)

    val listItems : 'a set -> 'a obj list
	(* Return an ordered list of the items in the set *)

    val union : 'a set * 'a set -> 'a set
        (* Union *)

    val intersection : 'a set * 'a set -> 'a set
        (* Intersection *)

    val difference : 'a set * 'a set -> 'a set
        (* Difference *)

    val map : ('a obj -> 'b obj) -> 'a set -> 'b set
	(* Create a new set by applying a function to the elements
	 * of the set.
         *)

    val mapPartial : ('a obj -> 'b obj option) -> 'a set -> 'b set
	(* Create a new set by applying a partial function to the elements
	 * of the set.
         *)

    val app : ('a obj -> unit) -> 'a set -> unit
	(* Apply a function to the entries of the set 
         * in decreasing order
         *)

    val foldl : ('a obj * 'b -> 'b) -> 'b -> 'a set -> 'b
	(* Apply a folding function to the entries of the set 
         * in increasing order
         *)

    val foldr : ('a obj * 'b -> 'b) -> 'b -> 'a set -> 'b
	(* Apply a folding function to the entries of the set 
         * in decreasing order
         *)

    val partition : ('a obj -> bool) -> 'a set -> ('a set * 'a set)

    val filter : ('a obj -> bool) -> 'a set -> 'a set

    val exists : ('a obj -> bool) -> 'a set -> bool

    val find : ('a obj -> bool) -> 'a set -> 'a obj option

  end
