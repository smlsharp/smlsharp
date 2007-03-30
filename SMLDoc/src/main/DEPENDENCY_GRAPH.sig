(**
 *  the signature of the module which provides operations on the dependency
 * graph.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: DEPENDENCY_GRAPH.sig,v 1.2 2004/10/20 03:18:39 kiyoshiy Exp $
 *)
signature DEPENDENCY_GRAPH =
sig

  (***************************************************************************)

  (** dependency graph *)
  type 'a graph

  (***************************************************************************)

  (**
   * creates a initial graph contains no edges between the nodes.
   * @params nodes
   * @param nodes the number of the nodes in the graph
   * @return the dependency graph
   *)
  val create : int -> 'a graph

  (**
   *  Put a edge between the specified nodes.
   * This function updates the graph.
   * @params graph {src, dest, attr}
   * @param graph the dependency graph
   * @param src the index of the node which depends on the dest.
   * @param dest the index of the node which is depended on by the src.
   * @param attr additional attributes of this dependency.
   * @return unit
   *)
  val dependsOn : 'a graph -> {src : int, dest : int, attr : 'a} -> unit

  (**
   * indicates whether there is a edge between the specified nodes.
   * @params graph {src, dest}
   * @param graph the dependency graph
   * @param src the index of the node which may depend on the dest.
   * @param dest the index of the node which may be depended on by the src.
   * @return a pair of the additional attribute if there is a link and
   *                  the boolean value which is true if there is a link.
   *)
  val isDependsOn : 'a graph -> {src : int, dest : int} -> ('a option * bool)
                                                           
  (**
   * get the closure of the dependency relation.
   * @params graph (traceFun, start)
   * @param graph the dependency graph
   * @param traceFun a function which is given an attribute of a link and
   *              returns true if this link should be traced.
   * @param start the index of the node of the start point of trace
   * @return a list of indexes of nodes reachable from the start by tracing
   *              dependency links.
   *)
  val getClosure : 'a graph -> (('a -> bool) * int) -> int list

  (**
   * the reverse version of the <code>getClosure</code>.
   * This function trace links from the node which is depended on and to the
   * node which depends on.
   *)
  val getClosureRev : 'a graph -> (('a -> bool) * int) -> int list

  (**
   * topological sort on the dependency graph
   * @params graph traceFun
   * @param graph the dependency graph
   * @param traceFun a function which is given attribute of link and returns
   *      if this link should be traced.
   * @return a list of node indexes sorted. The index A precedes the index B
   *       in this list if the node A depends on the node B.
   *)
  val sort : 'a graph -> ('a -> bool) -> int list

  (***************************************************************************)

end
