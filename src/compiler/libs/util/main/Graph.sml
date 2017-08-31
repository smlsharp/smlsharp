(**
 * Graph structure with strong connected component computation.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: Graph.sml,v 1.6 2007/08/12 23:11:19 ohori Exp $
 *)
structure Graph :> GRAPH = struct
  type node_id = int
  type 'n graph = {max_id : int,
                   nodes : 'n IEnv.map,
                   edges : ISet.set IEnv.map,
                   rev_edges : ISet.set IEnv.map}

  val empty = {max_id = 0,
               nodes = IEnv.empty,
               edges = IEnv.empty,
               rev_edges = IEnv.empty}

  fun addNode {max_id,nodes,edges,rev_edges} nodeInfo =
      let 
        val nid = max_id + 1
      in
        ({max_id = nid,
          nodes = IEnv.insert(nodes,nid,nodeInfo),
          edges = IEnv.insert(edges,nid,ISet.empty),
          rev_edges = IEnv.insert(rev_edges,nid,ISet.empty)},
         nid)
      end

  fun addEdge {max_id,nodes,edges,rev_edges} (fromNid,toNid) =
      let
        val outGoingNodes = 
            case IEnv.find(edges,fromNid) of
              SOME ns => ISet.add(ns,toNid)
            | _ => ISet.singleton(toNid)
        val inComingNodes =
            case IEnv.find(rev_edges,toNid) of
              SOME ns => ISet.add(ns,fromNid)
            | _ => ISet.singleton(fromNid)
      in
        {max_id = max_id,
         nodes = nodes,
         edges = IEnv.insert(edges,fromNid,outGoingNodes),
         rev_edges = IEnv.insert(rev_edges,toNid,inComingNodes)}
      end


  fun listNodes {max_id,nodes,edges,rev_edges} =
      IEnv.listItemsi nodes

  fun getNodeInfo {max_id,nodes,edges,rev_edges} nid =
      IEnv.find (nodes,nid)

  fun getOutGoingNodes {max_id,nodes,edges,rev_edges} nid = 
      case IEnv.find(edges,nid) of
        SOME ns => ns
      | _ => ISet.empty

  fun getInComingNodes {max_id,nodes,edges,rev_edges} nid = 
      case IEnv.find(rev_edges,nid) of
        SOME ns => ns
      | _ => ISet.empty

  fun scc (g as {max_id,nodes,edges,rev_edges}) =
      let
        val count = ref 1
        val max_id = max_id + 1 
        val dfnumber = Array.array (max_id,~1)
        val lowlink = Array.array (max_id,0)
        val onstack = Array.array (max_id,false)                  
        val st = (ref []) : (int list) ref
        val components = (ref []) : ((int list) list) ref 
        fun dfs nid = 
            let
              val _ =  Array.update (dfnumber,nid,!count)
              val _ =  Array.update (lowlink,nid,!count)
              val _ =  ( count := !count + 1 )
              val _ =  st := (nid::(!st))
              val _ =  Array.update (onstack,nid,true)
              val onodes = ISet.listItems (getOutGoingNodes g nid)
              fun f n =
                  if Array.sub(dfnumber,n) = ~1 then
                    (dfs n;
                     let 
                       val tmp = 
                           let
                             val ll1 = Array.sub(lowlink,n)
                             val ll2 = Array.sub(lowlink,nid)
                           in 
                             if ll1 > ll2 then ll2 else ll1 
                           end
                     in 
                       Array.update(lowlink,nid,tmp)
                     end)
                  else
                    let
                      val dfn1 = Array.sub(dfnumber,n)
                      val dfn2 = Array.sub(dfnumber,nid)
                    in  
                      if ( dfn1 < dfn2 ) andalso Array.sub(onstack,n) then
                        let 
                          val ll1 = Array.sub(lowlink,n)
                          val ll2 = Array.sub(lowlink,nid)
                          val tmp = if ll1 > ll2 then ll2 else ll1 
                        in 
                          Array.update(lowlink,nid,tmp)
                        end
                      else ()
                    end
              fun getComponent () =
                  let
                    val (n,st') = 
                      case !st of (n::st')=> (n,st')
                                | nil => 
                                  raise 
                                    Bug.Bug 
                                    "nil to getComponent (valrecoptimization/main/Graph.sml)"
                    val _ = st := st'
                    val _ = Array.update (onstack,n,false)
                  in
                    if n = nid then [n]
                    else ( n :: getComponent () )
                  end
            in
              ( 
               List.app f onodes;
               let 
                 val ll = Array.sub(lowlink,nid)
                 val dfn = Array.sub(dfnumber,nid)
               in 
                 if ll = dfn then
                   let 
                     val c = getComponent()
                     val cs = c :: !components
                   in components := cs
                   end
                 else ()
               end      
              )
            end
            
        fun dfsAll ns =
            case ns of 
              [] => ()
            | (n :: ns1) =>
              let 
                val dfn = Array.sub ( dfnumber, n)
              in 
                if dfn = ~1 then (dfs n;dfsAll(ns1))
                else dfsAll(ns1)
              end
      in
        ( dfsAll (#1 (ListPair.unzip(listNodes g))); 
          !components )
      end
  
  fun printNodes ns = 
      (print "("; List.app (fn nid => (print (Int.toString nid); print " ")) ns ; print ")\n") 
end
