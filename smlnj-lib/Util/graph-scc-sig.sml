(* graph-scc-sig.sml
 *
 * COPYRIGHT (c) 1999 Lucent Bell Laboratories.
 *
 *   Calculate strongly-connected components of directed graph.
 *   The graph can have nodes with self-loops.
 *
 * author: Matthias Blume
 *) 

signature GRAPH_SCC =
  sig

    structure Nd : ORD_KEY

    type node = Nd.ord_key

    datatype component
      = SIMPLE of node			(* singleton, no self-loop *)
      | RECURSIVE of node list

    val topOrder': { roots: node list, follow: node -> node list }
		   -> component list
	(* take root node(s) and follow function and return
	 * list of topologically sorted strongly-connected components;
	 * the component that contains the first of the given "roots"
	 * goes first
	 *)

    val topOrder : { root: node, follow: node -> node list }
		   -> component list
        (* for backward compatibility;
	 * AXIOM: topOrder{root,follow}==topOrder'{roots=[root],follow=follow}
	 *)

  end
