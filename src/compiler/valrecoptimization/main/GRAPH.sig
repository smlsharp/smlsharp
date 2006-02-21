(**
 * Copyright (c) 2006, Tohoku University.
 *
 * Graph signature with strong connected component computation
 * 
 * @author NGUYEN Huu-Duc
 * @version $Id: GRAPH.sig,v 1.3 2006/02/18 16:04:07 duchuu Exp $
 *)
signature GRAPH = sig
    type node_id = int
    type 'n graph
    
    val empty : 'n graph
				    
    val addNode  : 'n graph -> 'n -> ('n graph * node_id)
    val addEdge  : 'n graph -> node_id * node_id  -> 'n graph

    val listNodes : 'n graph -> (node_id * 'n) list
    val getNodeInfo : 'n graph -> node_id -> 'n option
 
    val scc : 'n graph  -> (node_id list) list
    val printNodes : node_id list -> unit
end
