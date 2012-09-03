(**
 *  the signature of the module which provides operations on the dependency
 * graph.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: DependencyGraph.sml,v 1.2 2004/10/20 03:18:39 kiyoshiy Exp $
 *)
structure DependencyGraph :> DEPENDENCY_GRAPH =
struct

  (*
   * We could use Array2 structure to represent 2-dimensional array.
   * But we avoid use it because Array2 is optional in SML Basis library.
   *)
  (*
   * if node S depends node D, graph(S)(D) = true
   *)
  type 'a graph = ('a option * bool) Array.array Array.array

  fun create (nodesCount) =
      Array.tabulate
      (nodesCount, fn _ => Array.array(nodesCount, (NONE, false)))
  fun dependsOn graph {src, dest, attr} =
      Array.update(Array.sub(graph, src), dest, (SOME attr, true))
  fun isDependsOn graph {src, dest} = Array.sub(Array.sub(graph, src), dest)
  fun getClosure (graph : 'a graph) (toTrace, startIndex) =
      let
        val visitedArray = Array.array (Array.length graph, false)
        fun isVisited index = Array.sub (visitedArray, index)
        fun setVisited index = Array.update (visitedArray, index, true)

        fun visit (index, closure) =
            (setVisited index;
             index::
             (Array.foldli
             (fn (destIndex, (attr, isDependsOn), closure) =>
                 if isDependsOn andalso not(isVisited destIndex)
                 then case attr of
                        SOME attr =>
                        if toTrace attr
                        then visit (destIndex, closure)
                        else closure
                      | NONE => visit (destIndex, closure)
                 else closure)
             closure
             (Array.sub (graph, index), 0, NONE)))
      in
        visit (startIndex, [])
      end
  fun getClosureRev (graph : 'a graph) (toTrace, startIndex) =
      let
        val visitedArray = Array.array (Array.length graph, false)
        fun isVisited index = Array.sub (visitedArray, index)
        fun setVisited index = Array.update (visitedArray, index, true)

        (*
         * collect indexes of elements which depend on the element of the
         * index.
         *)
        fun visit (index, closure) =
            (setVisited index;
             index::
             (Array.foldli
              (fn (srcIndex, subArray, closure) =>
                  case Array.sub (subArray, index) of
                    (attr, isDependsOn) =>
                    if isDependsOn andalso not(isVisited srcIndex)
                    then case attr of
                           SOME attr =>
                           if toTrace attr
                           then visit (srcIndex, closure)
                           else closure
                         | NONE => visit (srcIndex, closure)
                    else closure)
              closure
              (graph, 0, NONE)))
      in
        visit (startIndex, [])
      end

  fun sort (graph : 'a graph) toTrace =
      let
        val visitedArray = Array.array (Array.length graph, false)
        fun isVisited index = Array.sub (visitedArray, index)
        fun setVisited index = Array.update (visitedArray, index, true)

        (*
         *  This function returs a list whose elements are ordered so that
         * index s is in front of index d if s depends on d.
         *  This function returns a list consisted of:
         * <ol>
         *   <li>the element e of the 'index'
         *   <li>all elements the e depends on and not included in the
         *      'sorted'.
         *   <li>the 'sorted' (this may include elements the e depends on.)
         * </ol>
         *  The 'sorted' does not include any element which depends on the
         * element of the 'index'.
         *)
        fun visit (index, sorted) =
            (setVisited index;
             index::
             (Array.foldli
             (fn (destIndex, (attr, isDependsOn), sorted) =>
                 if isDependsOn andalso not(isVisited destIndex)
                 then case attr of
                        SOME attr =>
                        if toTrace attr
                        then visit (destIndex, sorted)
                        else sorted
                      | NONE => visit (destIndex, sorted)
                 else sorted)
             sorted
             (Array.sub (graph, index), 0, NONE)))
      in
        List.rev
        (Array.foldli
         (fn (index, _, sorted) =>
             if isVisited index then sorted else visit (index, sorted))
         []
         (graph, 0, NONE))
      end
end

