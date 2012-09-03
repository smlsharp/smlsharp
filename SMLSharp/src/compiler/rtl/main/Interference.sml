(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure Interference :> sig

  type 'r graph
  type vertexId

  datatype 'r color =
      UNCOLORED
    | COLORED of 'r
    | NEED_SPILL

  exception DisallowSpill

  val format_graph : 'r SMLFormat.BasicFormatters.formatter
                     -> 'r graph SMLFormat.BasicFormatters.formatter
  val format_vertexId : vertexId SMLFormat.BasicFormatters.formatter
  val format_color : 'r SMLFormat.BasicFormatters.formatter
                     -> 'r color SMLFormat.BasicFormatters.formatter

  val empty : 'r graph

  (* high-level interfaces *)
  val addVar : 'r graph * RTL.var -> 'r graph
  val interfere : 'r graph * RTL.var * RTL.var -> 'r graph
  val interfereWithColors : ''r graph * RTL.var * ''r list -> ''r graph
  val coalesce : ''r graph * RTL.var * RTL.var -> ''r graph
  val findVar : 'r graph * RTL.var -> 'r color option
  val foldVar : ({var:RTL.var, slotId:RTL.id, color:'r color} * 'a -> 'a)
                -> 'a -> 'r graph -> 'a
  val requestCoalesce : 'r graph * RTL.var * RTL.var -> 'r graph
  val disallowSpill : 'r graph * RTL.var -> 'r graph
  val isSpillable : 'r graph * RTL.var -> bool

  val numVars : 'r graph -> int
  val numVertexes : 'r graph -> int

  (* for implementation of register allocation algorithm *)
  val adjacencyColors : ''r graph * vertexId -> ''r list
  val numAdjacencies : 'r graph * vertexId -> int
  val setColor : 'r graph * vertexId * 'r color -> 'r graph
  val disableVertex : 'r graph * vertexId -> 'r graph
  val selectVertexes : (vertexId * 'r color -> bool) -> 'r graph
                       -> vertexId list
  val minVertex : (RTL.var -> int) -> 'r graph -> (vertexId * int) option
  val performCoalesce : (''r graph * vertexId * vertexId -> bool)
                        -> ''r graph -> ''r graph

end =
struct

  structure I = RTL

  type vertexId = RTL.id

  datatype 'r color =
      UNCOLORED
    | COLORED of 'r
    | NEED_SPILL

  exception DisallowSpill

  type 'r vertex =
      {
        color: 'r color option,  (* none means "disabled" *)
        adjacencies: VarID.Set.set,
        spillable: bool,
        interferedColors: 'r list
      }

  type 'r graph =
      {
        (* varId -> vertexId *)
        varMap: {var: I.var, vertexId: vertexId} VarID.Map.map,
        (* vertexId -> vertex *)
        graph: 'r vertex VarID.Map.map,
        (* list of coalescable pairs of vertexes *)
        coalescables: (I.var * I.var) list
      }

  fun numVars {varMap,graph,coalescables} = VarID.Map.numItems varMap
  fun numVertexes {varMap,graph,coalescables} = VarID.Map.numItems graph

  val empty =
      {
        varMap = VarID.Map.empty,
        graph = VarID.Map.empty,
        coalescables = nil
      } : 'r graph

  local
    open SMLFormat.BasicFormatters
    open SMLFormat.FormatExpression
    val str = format_string
  in
  val format_vertexId = I.format_id
  fun format_set set =
      format_list (VarID.format_id, str ",")
                  (VarID.Set.listItems set)
  fun format_color fmt UNCOLORED = str "_"
    | format_color fmt (COLORED r) = fmt r
    | format_color fmt NEED_SPILL = str "<SPILL>"

  fun format_vertex opt {color,adjacencies,spillable,interferedColors} =
      let
        val (fmt, graph, pre, post) =
            case opt of
              SOME x => x
            | NONE => (fn x => nil, VarID.Map.empty, nil, [Newline])
        val pre = pre @ (case color of NONE => str "X"
                                     | SOME c => format_color fmt c) @
                  (if spillable then nil else str "!")
      in
        format_list
          (fn v =>
              let
                val adj = VarID.Map.find (graph, v)
              in
                pre @
                (case (color, adj) of
                   (NONE, _) => str " -X-> "
                 | (_, SOME ({color=NONE,...}:'r vertex)) => str " -X-> "
                 | (SOME _, SOME {color=SOME _,...}) => str " ---> "
                 | (_, NONE) => str " -?-> ") @
                (case adj of
                   SOME {color=SOME c,...} =>
                   VarID.format_id v @ str " : " @ format_color fmt c
                 | _ => VarID.format_id v) @
                post
              end,
           nil)
          (VarID.Set.listItems adjacencies) @
        format_list
          (fn r =>
              pre @
              (case color of NONE => str " -X-> <"
                           | SOME _ => str " ---> <") @
              fmt r @ str ">" @ post,
           nil)
          interferedColors
      end

  fun format_graph fmt {varMap, graph, coalescables} =
      str "variables:" @ [StartOfIndent 2] @
      format_list
        (fn (k,{var,vertexId}) =>
            [Newline] @ VarID.format_id k @ str ": " @
            I.format_var var @ str " at " @ I.format_id vertexId,
         nil)
        (VarID.Map.listItemsi varMap) @
      [EndOfIndent, Newline] @
      str "graph:" @ [StartOfIndent 2] @
      format_list
        (fn (k,v) =>
            format_vertex
              (SOME (fmt, graph, [Newline] @ I.format_id k @ str " : ", nil))
              v,
         nil)
        (VarID.Map.listItemsi graph) @
      [EndOfIndent, Newline] @
      str "coalescables: " @
      format_list
        (fn (v1,v2) =>
            str "(" @ I.format_var v1 @ str "," @ I.format_var v2  @str ")",
         str " ")
        coalescables
  end (* local *)

  fun addVar (i as {varMap, graph, coalescables}:'r graph,
              var as {id,...}:I.var) =
      case VarID.Map.find (varMap, #id var) of
        SOME _ => i
      | NONE =>
        let
          val vertex = {color = SOME UNCOLORED,
                        adjacencies = VarID.Set.empty,
                        spillable = true,
                        interferedColors = nil} : 'r vertex
        in
          {
            varMap = VarID.Map.insert (varMap, id, {var=var, vertexId=id}),
            graph = VarID.Map.insert (graph, id, vertex),
            coalescables = nil
          } : 'r graph
        end

  fun vertexId ({varMap, ...}:'r graph, {id,...}:I.var) =
      case VarID.Map.find (varMap, id) of
        SOME {vertexId,...} => vertexId
      | NONE => raise Control.Bug ("vartexId: not found: "
                                   ^ VarID.toString id)

  fun vertex ({graph,...}:'r graph, vid) =
      case VarID.Map.find (graph, vid) of
        SOME v => v : 'r vertex
      | NONE => raise Control.Bug ("vertex: not found: "
                                   ^ VarID.toString vid)

  fun union (l1, l2) =
      foldr (fn (x,z) => if List.exists (fn y => x = y) z
                         then z else x::z)
            l2 l1

  fun addAdjacency ({color,adjacencies,spillable,interferedColors}:'r vertex,
                    vid) =
      {color = color,
       adjacencies = VarID.Set.add (adjacencies, vid),
       spillable = spillable,
       interferedColors = interferedColors} : 'r vertex

  fun addAdjacencyColors ({color,adjacencies,spillable,interferedColors}
                          :''r vertex, colors) =
      {color = color,
       adjacencies = adjacencies,
       spillable = spillable,
       interferedColors = union (interferedColors, colors)} : ''r vertex

  fun setSpillable ({color,adjacencies,spillable=_,interferedColors}:'r vertex,
                    spillable) =
      {color = color,
       adjacencies = adjacencies,
       spillable = spillable,
       interferedColors = interferedColors} : 'r vertex

  fun setVertexColor ({color=_,adjacencies,spillable,
                       interferedColors}:'r vertex, color) =
      {color = color,
       adjacencies = adjacencies,
       spillable = spillable,
       interferedColors = interferedColors} : 'r vertex

  fun disallowSpill (i as {varMap, graph, coalescables}:'r graph, var) =
      let
        val vid = vertexId (i, var)
        val v1 = setSpillable (vertex (i, vid), false)
        val graph = VarID.Map.insert (graph, vid, v1)
      in
        {varMap=varMap, graph=graph, coalescables=coalescables} : 'r graph
      end

  fun isSpillable (i, var) =
      #spillable (vertex (i, vertexId (i, var)))

  fun disableVertex (i as {varMap,graph,coalescables}:'r graph, vid) =
      let
        val v = setVertexColor (vertex (i, vid), NONE)
        val graph = VarID.Map.insert (graph, vid, v)
      in
        {varMap=varMap, graph=graph, coalescables=coalescables} : 'r graph
      end

  fun setColor (i as {varMap,graph,coalescables}:'r graph, vid, color) =
      case (vertex (i, vid), color) of
        ({spillable=false,...}, NEED_SPILL) => raise DisallowSpill
      | (v, _) =>
        let
          val v = setVertexColor (v, SOME color)
          val graph = VarID.Map.insert (graph, vid, v)
        in
          {varMap=varMap, graph=graph, coalescables=coalescables} : 'r graph
        end

  fun interfere (i as {varMap, graph, coalescables}:'r graph, var1, var2) =
      let
        val vid1 = vertexId (i, var1)
        val vid2 = vertexId (i, var2)
      in
        if VarID.eq (vid1, vid2)
        then i
        else
          let
            val v1 = addAdjacency (vertex (i, vid1), vid2)
            val v2 = addAdjacency (vertex (i, vid2), vid1)
            val graph = VarID.Map.insert (graph, vid1, v1)
            val graph = VarID.Map.insert (graph, vid2, v2)
          in
            {varMap=varMap, graph=graph, coalescables=coalescables} : 'r graph
          end
      end

  fun interfereWithColors (i as {varMap, graph, coalescables}:''r graph,
                           var, colors) =
      let
        val vid1 = vertexId (i, var)
        val v1 = addAdjacencyColors (vertex (i, vid1), colors)
        val graph = VarID.Map.insert (graph, vid1, v1)
      in
        {varMap=varMap, graph=graph, coalescables=coalescables} : ''r graph
      end

  fun coalesce (i as {varMap, graph, coalescables}:''r graph, var1, var2) =
      let
        val vid1 = vertexId (i, var1)
        val vid2 = vertexId (i, var2)
      in
        if VarID.eq (vid1, vid2)
        then i
        else
          let
            val v1 = vertex (i, vid1)
            val v2 = vertex (i, vid2)
            val color = if #color v1 = #color v2 then #color v1
                        else raise Control.Bug "coalesce: color mismatch"
            val adjacencies =
                VarID.Set.union (#adjacencies v1, #adjacencies v2)
            val interferedColors = union (#interferedColors v1,
                                          #interferedColors v2)
            val spillable = #spillable v1 andalso #spillable v2

            val _ = if VarID.Set.member (adjacencies, vid1)
                       orelse VarID.Set.member (adjacencies, vid2)
                    then raise Control.Bug "coalesce: interfered"
                    else ()

            val newVertex =
                {color = color,
                 adjacencies = adjacencies,
                 spillable = spillable,
                 interferedColors = interferedColors} : ''r vertex

            val graph = #1 (VarID.Map.remove (graph, vid2))
            val graph = VarID.Map.insert (graph, vid1, newVertex)
            val varMap = VarID.Map.insert (varMap, vid2,
                                                {var=var2, vertexId=vid1})

            val graph =
                VarID.Set.foldl
                  (fn (vid, graph) =>
                      case VarID.Map.find (graph, vid) of
                        NONE => raise Control.Bug "coalesce: vertex not found"
                      | SOME {color,adjacencies,spillable,interferedColors} =>
                        let
                          val adjacencies =
                              VarID.Set.map
                                (fn x => if x = vid2 then vid1 else x)
                                adjacencies
                          val v = {color = color,
                                   adjacencies = adjacencies,
                                   spillable = spillable,
                                   interferedColors = interferedColors}
                        in
                          VarID.Map.insert (graph, vid, v)
                        end)
                  graph
                  adjacencies
          in
            {varMap = varMap, graph = graph, coalescables = coalescables}
            : ''r graph
          end
      end

  fun requestCoalesce ({varMap, graph, coalescables}:'r graph, var1, var2) =
      {varMap = varMap,
       graph = graph,
       coalescables = (var1, var2) :: coalescables} : 'r graph

  fun performCoalesce f (i as {coalescables=nil, ...}:''r graph) = i
    | performCoalesce f (i as {varMap, graph,
                               coalescables as (varId1,varId2)::t}) =
      let
        val vid1 = vertexId (i, varId1)
        val vid2 = vertexId (i, varId2)
      in
        if vid1 = vid2
        then performCoalesce f {varMap=varMap, graph=graph, coalescables=t}
        else if f (i:''r graph, vid1, vid2)
        then
          let
            val {varMap, graph, ...} = coalesce (i:''r graph, varId1, varId2)
          in
            performCoalesce f {varMap=varMap, graph=graph, coalescables=t}
          end
        else
          let
            val {varMap, graph, ...} =
                performCoalesce f {varMap=varMap, graph=graph, coalescables=t}
          in
            {varMap=varMap, graph=graph, coalescables=coalescables}
          end
      end

  fun findVar (i as {varMap,...}:'r graph, {id,...}:I.var) =
      case VarID.Map.find (varMap, id) of
        NONE => NONE
      | SOME {vertexId, ...} => #color (vertex (i, vertexId))

  fun foldVar f z (i as {varMap,...}:'r graph) =
      VarID.Map.foldli
        (fn (varId, {var, vertexId}, z) =>
            case #color (vertex (i, vertexId)) of
              NONE => z
            | SOME color => f ({var=var, slotId=vertexId, color=color}, z))
        z
        varMap

  fun adjacencyColors (i, vid) =
      let
        val {adjacencies, interferedColors, ...} = vertex (i, vid)
        val colors =
            VarID.Set.foldr
              (fn (vid, colors) =>
                  case #color (vertex (i, vid)) of
                    SOME (COLORED c) => c :: colors
                  | _ => colors)
              nil
              adjacencies
      in
        union (interferedColors, colors)
      end

  fun numAdjacencies (i, vid) =
      let
        val {adjacencies, interferedColors, ...} = vertex (i, vid)
        val n =
            VarID.Set.foldl
              (fn (vid, n) =>
                  case #color (vertex (i, vid)) of
                    NONE => n
                  | SOME _ => n + 1)
              0
              adjacencies
      in
        length interferedColors + n
      end

  fun selectVertexes f ({graph, ...}:'r graph) =
      VarID.Map.foldli
        (fn (vid, {color=NONE, ...}, z) => z
          | (vid, {color=SOME color, ...}, z) =>
            if f (vid, color) then vid :: z else z)
        nil
        graph

  fun minVertex f (i as {varMap,...}:'r graph) =
      VarID.Map.foldli
        (fn (varId, {var, vertexId}, z) =>
            case vertex (i, vertexId) of
              {color=NONE,...} => z
            | {spillable=false,...} => z
            | _ =>
              case (f var, z) of
                (n, NONE) => SOME (vertexId, n)
              | (m, SOME (_, n)) => if m < n then SOME (vertexId, m) else z)
        NONE
        varMap

end
