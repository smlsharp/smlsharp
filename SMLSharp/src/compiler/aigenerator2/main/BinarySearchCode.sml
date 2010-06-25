(**
 * binary search code generator
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: BinarySearchCode.sml,v 1.3 2007/12/15 08:30:34 bochao Exp $
 *)
structure BinarySearchCode : sig

  val generate
      : (
          'context                             (* global context *)
          * 'code                              (* code accumulator *)
          * 'env                               (* environment *)
          * 'choice                            (* a choice branch *)
          * AbstractInstruction2.label option  (* label of this node *)
          * AbstractInstruction2.label option  (* left child label *)
          * AbstractInstruction2.label option  (* right child label *)
          ->
          'context                             (* new global context *)
          * 'code                              (* code accumulator *)
          * 'env                               (* env for choice *)
          * 'env                               (* env for left child *)
          * 'env                               (* env for right child *)
        )
        ->
        'context                               (* initial global context *)
        * 'code                                (* initial code accumulator *)
        * 'env                                 (* initial environment *)
        * 'choice list                         (* choices (sorted) *)
        ->
        'context                               (* updated global context *)
        * 'code                                (* updated code accumulator *)
        * 'env list                            (* environments for choices *)

end =
struct

fun newLocalId () = VarID.generate ()


  datatype 'a tree = NODE of 'a * 'a tree * 'a tree | LEAF

  (*
   * [1,2,3,4,5]     ==>        [4]
   *                           /   \
   *                         [2]   [5]
   *                        /   \
   *                      [1]   [3]
   *)
  fun makeTree choices numNodes nodeId =
      let
        val leftNodeId = nodeId * 2 + 1
        val rightNodeId = nodeId * 2 + 2

        val (leftTree, choice::choices) =
            if leftNodeId >= numNodes
            then (LEAF, choices)
            else makeTree choices numNodes leftNodeId
        val (rightTree, choices) =
            if rightNodeId >= numNodes
            then (LEAF, choices)
            else makeTree choices numNodes rightNodeId
      in
        (NODE (choice, leftTree, rightTree), choices)
      end

  fun makeBinaryTree nil = LEAF
    | makeBinaryTree choices = #1 (makeTree choices (length choices) 0)

  fun generate f (context, code, env, choices) =
      let
        fun visit context code env label LEAF = (context, code, nil)
          | visit context code env label (NODE (choice, leftTree, rightTree)) =
            let
              val leftLabel =
                  case leftTree of
                    NODE _ => SOME (newLocalId ()) | LEAF => NONE
              val rightLabel =
                  case rightTree of
                    NODE _ => SOME (newLocalId ()) | LEAF => NONE

              val (context, code, newEnv, leftEnv, rightEnv) =
                  f (context, code, env, choice, label, leftLabel, rightLabel)

              val (context, code, leftEnvList) =
                  visit context code leftEnv leftLabel leftTree
              val (context, code, rightEnvList) =
                  visit context code rightEnv rightLabel rightTree
            in
              (context, code, leftEnvList @ [newEnv] @ rightEnvList)
            end
      in
        visit context code env NONE (makeBinaryTree choices)
      end

end
