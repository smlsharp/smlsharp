(**
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)
structure Main =
struct

  val _ = CM.mkusefile;

  val tree = Tree.Node(Tree.Leaf 1, Tree.Node(Tree.Leaf 2, Tree.Leaf 3))

  fun main () =
      Tree.format_tree (SMLPP.BasicFormatters.format_int) tree

end