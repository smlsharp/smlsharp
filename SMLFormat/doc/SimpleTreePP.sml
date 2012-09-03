(**
 *  a simple pretty printer of tree structure to describe
 * the algorithm used by the SMLPP pplib.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: SimpleTreePP.sml,v 1.1 2005/10/12 11:41:10 kiyoshiy Exp $
 *)
structure SimpleTreePP
          : sig

              (** tree of strings *)
              datatype tree = Node of tree list | Leaf of string

              (** pretty printer.
               * @args columns tree
               * @arg columns the number of columns
               * @arg tree the tree to be printed
               *)
              val pp : int -> tree -> string list

            end =
struct

  val indentUnit = "  "

  datatype tree = Node of tree list | Leaf of string

  datatype sizedTree =
           (** annotated with the number of columns required to print
            * sub trees in one line. *)
           NodeS of sizedTree list * int
         | LeafS of string

  fun getLeaf (NodeS(subTrees, _)) = List.concat(map getLeaf subTrees)
    | getLeaf (LeafS string) = [string]

  (**
   *  calculates the length of a string obtained by concatenation
   * of leaves below the tree.
   *)
  fun calcSize tree =
      case tree of
        Node subTrees =>
        let
          val (newSubTrees, length) =
              foldr
                  (fn (subTree, (newSubTrees, sumOfLength)) =>
                      let val (length, newSubTree) = calcSize subTree
                      in
                        (newSubTree :: newSubTrees, length + sumOfLength)
                      end)
                  ([], 0)
                  subTrees
        in (length, NodeS (newSubTrees, length))
        end
      | Leaf string =>
        let val length = size string
        in (length, LeafS string)
        end

  (**
   * If the string obtained by concatenation of all leaves
   * under the tree can be printed within the specified columns,
   * this function prints it in one line.
   * Otherwise, subtrees are printed in separated lines with
   * indent extended.
   *)
  fun printTree indent columns (NodeS (subTrees, length)) =
      if length <= columns
      then
        let val allLeavesString = concat (List.concat(map getLeaf subTrees))
        in [indent ^ allLeavesString]
        end
      else
        let
          val newIndent = indent ^ indentUnit
          val newColumns = columns - size indentUnit
        in
          List.concat(map (printTree newIndent newColumns) subTrees)
        end
    | printTree indent columns (LeafS string) = [indent ^ string]

  fun pp columns tree =
      let val (_, sizedTree) = calcSize tree
      in printTree "" columns sizedTree
      end

end;
