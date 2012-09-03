(* match-tree.sml
 *
 * COPYRIGHT (c) 1994 AT&T Bell Laboratories.
 *
 * Match trees are used to represent the results of matching regular
 * expressions.
 *)

signature MATCH_TREE =
  sig

  (* a match tree is used to represent the results of a nested
   * grouping of regular expressions.
   *)
    datatype 'a match_tree = Match of 'a * 'a match_tree list

    val root : 'a match_tree -> 'a
	(* return the root (outermost) match in the tree *)
    val nth : ('a match_tree * int) -> 'a (* raises Subscript *)
	(* return the nth match in the tree; matches are labeled in pre-order
	 * starting at 0.
	 *)
    val map : ('a -> 'b) -> 'a match_tree -> 'b match_tree
	(* map a function over the tree (in preorder) *)
    val app : ('a -> unit) -> 'a match_tree -> unit
	(* apply a given function over ever element of the tree (in preorder) *)
    val find : ('a -> bool) -> 'a match_tree -> 'a option
	(* find the first match that satisfies the predicate (or NONE) *)
    val num : 'a match_tree -> int
	(* return the number of submatches included in the match tree *)
  end;
