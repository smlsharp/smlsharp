(**
 * Graph signature with strong connected component computation.
 * 
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: GRAPH.sig,v 1.4 2006/02/28 16:11:11 kiyoshiy Exp $
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


