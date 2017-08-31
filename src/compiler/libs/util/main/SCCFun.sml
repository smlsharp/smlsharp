(**
 * @copyright (c) 2004-2012 Tohoku University.
 * @author Duc-Huu Nguyen 
 * @author Atsushi Ohori
 *)
signature SCC =
sig
  type graph
  type elem
  val empty : graph
  val addNode : graph * elem -> graph
  val addEdge : graph * elem * elem -> graph
  val scc : graph -> elem list list
end

functor SCCFun (IMap:ORD_MAP) :> SCC where type elem = IMap.Key.ord_key =
struct
  type elem = IMap.Key.ord_key
  type graph = elem Graph.graph * int IMap.map
  val empty = (Graph.empty, IMap.empty)
  fun addNode ((graph, intmap), elem) =
      let
        val (graph , nodeId) = Graph.addNode graph elem
        val intmap = IMap.insert(intmap, elem, nodeId)
      in
        (graph, intmap)
      end
  fun addEdge ((graph, intmap), elem1, elem2) =
      let
        val ((graph, intmap),id1) = 
            case IMap.find(intmap, elem1) of
              SOME id => ((graph, intmap),id)
            | NONE => 
              let
                val (graph , nodeId) = Graph.addNode graph elem1
                val intmap = IMap.insert(intmap, elem1, nodeId)
              in
                ((graph, intmap), nodeId)
              end
        val ((graph, intmap),id2) = 
            case IMap.find(intmap, elem2) of
              SOME id => ((graph, intmap),id)
            | NONE => 
              let
                val (graph , nodeId) = Graph.addNode graph elem2
                val intmap = IMap.insert(intmap, elem2, nodeId)
              in
                ((graph, intmap), nodeId)
              end
        val graph = Graph.addEdge graph (id1, id2)
      in
        (graph, intmap)
      end
      fun scc (graph, intmap) =
          let
            fun getElem id = 
                case Graph.getNodeInfo graph id of
                  SOME elem => elem
                | NONE => raise Bug.Bug "undefined id"
            val idListList = Graph.scc graph
          in
            map (fn idlist => map getElem idlist) idListList
          end
  fun listNode (graph, intmap) =
      let
        val idElemList = Graph.listNodes graph
      in
        map (fn (x,y) => y) idElemList
      end
end

