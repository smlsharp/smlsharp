(**
 * x86 RTL
 * @copyright (c) 2009, 2010, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure Interference :> sig

  type graph
  type vertexId = int
  type colorId = int   (* sequential number from 1 *)

  val empty : graph
  val format_graph : graph TermFormat.formatter

  val addVar : graph * RTL.id -> graph
  val interfere : graph * RTL.id * RTL.id -> graph
  val interfereWithColors : graph * RTL.id * colorId list -> graph
  val coalesce : graph * RTL.id * RTL.id -> graph
  val addMove : graph * RTL.id * RTL.id -> graph
  val disallowSpill : graph * RTL.id -> graph
  (* smaller scores resists spill. default score is 0. *)
  val setSpillScore : graph * RTL.id * int -> graph
  val discardMoves : graph -> graph

  val maxVertexId : graph -> vertexId
  val vertexes : graph -> vertexId list
  val precolor : vertexId -> colorId option
  val adjacencies : graph * vertexId -> ISet.set
  val degree : graph * vertexId -> int
  val moves : graph * vertexId -> ISet.set
  val movePairs : graph -> (vertexId * vertexId) list
  val spillScore : graph * vertexId -> bool * int
  val coalesceVertex : graph * vertexId * vertexId -> graph
  val removeEdges : graph * vertexId -> graph
  val removeMove : graph * vertexId * vertexId -> graph
  val fold : (VarID.id * vertexId * 'a -> 'a) -> 'a -> graph -> 'a
  val derefAlias : graph * vertexId -> vertexId

end =
struct

  (* negative vertexId indicates a precolored vertex. *)
  type vertexId = int
  type colorId = int

  type graph =
      {
        varMap: vertexId VarID.Map.map,    (* varId -> vertexId *)
        aliasMap: vertexId IEnv.map,       (* coalesced vertexId -> vertexId *)
        adjMap: ISet.set IEnv.map,         (* vertexId -> vertexId set *)
        moveMap: ISet.set IEnv.map,        (* vertexId -> vertexId set *)
        scoreMap: (bool * int) IEnv.map,   (* vertexId -> spill score *)
        count: vertexId                    (* counter for vertexId *)
      }

  val empty =
      {varMap = VarID.Map.empty,
       aliasMap = IEnv.empty,
       adjMap = IEnv.empty,
       moveMap = IEnv.empty,
       scoreMap = IEnv.empty,
       count = 0} : graph

  fun format_graph ({varMap, aliasMap, adjMap, moveMap, scoreMap,
                     count}:graph) =
      let
        open TermFormat.FormatComb
        fun formatISet set = list int (ISet.listItems set)
        fun formatIEnv f map = assocList (int, f) (IEnv.listItemsi map)
        fun formatVarIDSet set = list VarID.format_id (VarID.Set.listItems set)
        fun formatVarIDMap f map =
            assocList (VarID.format_id, f) (VarID.Map.listItemsi map)
        fun formatAllow x = term (if x then "ALLOW" else "DISALLOW")
      in
        record
          [("varMap", formatVarIDMap int varMap),
           ("aliasMap", formatIEnv int aliasMap),
           ("adjMap", formatIEnv formatISet adjMap),
           ("moveMap", formatIEnv formatISet moveMap),
           ("scoreMap", formatIEnv (tuple2 (formatAllow, int)) scoreMap),
           ("count", int count)]
      end

  fun ISet_delete (set, item) =
      ISet.delete (set, item) handle _ => set

  fun IEnv_remove (map, key) =
      #1 (IEnv.remove (map, key)) handle _ => map

  fun precolorVertexId (colorId:colorId) =
      if colorId > 0 then ~colorId : vertexId
      else raise Control.Bug "precolorVertexId: invalid color id"

  fun precolor (vertexId:vertexId) =
      if vertexId < 0 then SOME (~vertexId) else NONE

  fun vertexId ({varMap, ...}:graph, varId) =
      case VarID.Map.find (varMap, varId) of
        SOME vid => vid
      | NONE => raise Control.Bug ("vertexId: var " ^ VarID.toString varId)

  fun adjacencies ({adjMap, ...}:graph, vid) =
      case IEnv.find (adjMap, vid) of
        SOME set => set
      | NONE => ISet.empty

  fun degree (graph, vid) =
      ISet.numItems (adjacencies (graph, vid))

  fun moves ({moveMap, ...}:graph, vid) =
      case IEnv.find (moveMap, vid) of
        SOME set => set
      | NONE => ISet.empty

  fun spillScore ({scoreMap, ...}:graph, vid) =
      case IEnv.find (scoreMap, vid) of
        SOME n => n
      | NONE => (true, 0)

  fun maxVertexId ({count, ...}:graph) = count

  fun derefAlias (graph as {aliasMap, ...}:graph, vid) =
      case IEnv.find (aliasMap, vid) of
        NONE => vid
      | SOME vid => derefAlias (graph, vid)

  fun vertexes (graph as {varMap, ...}:graph) =
      ISet.listItems
        (VarID.Map.foldl (fn (i, z) => ISet.add (z, derefAlias (graph, i)))
                         ISet.empty varMap)

  fun addVar (graph as {varMap, count=vertexId, ...}:graph, varId) =
      case VarID.Map.find (varMap, varId) of
        SOME _ => graph
      | NONE =>
        {varMap = VarID.Map.insert (#varMap graph, varId, vertexId),
         aliasMap = #aliasMap graph,
         adjMap = #adjMap graph,
         moveMap = #moveMap graph,
         scoreMap = #scoreMap graph,
         count = vertexId + 1} : graph

  fun interfere (graph, varId1, varId2) =
      let
        val vid1 = vertexId (graph, varId1)
        val vid2 = vertexId (graph, varId2)
      in
        if vid1 = vid2 then graph else
        let
          val adj1 = ISet.add (adjacencies (graph, vid1), vid2)
          val adj2 = ISet.add (adjacencies (graph, vid2), vid1)
          val adjMap = IEnv.insert (#adjMap graph, vid1, adj1)
          val adjMap = IEnv.insert (adjMap, vid2, adj2)
        in
          {varMap = #varMap graph,
           aliasMap = #aliasMap graph,
           adjMap = adjMap,
           moveMap = #moveMap graph,
           scoreMap = #scoreMap graph,
           count = #count graph} : graph
        end
      end

  fun interfereWithColor (graph:graph, varId, colorId) =
      let
        val vid1 = vertexId (graph, varId)
        val vid2 = precolorVertexId colorId
        val adj1 = ISet.add (adjacencies (graph, vid1), vid2)
      in
        {varMap = #varMap graph,
         aliasMap = #aliasMap graph,
         adjMap = IEnv.insert (#adjMap graph, vid1, adj1),
         moveMap = #moveMap graph,
         scoreMap = #scoreMap graph,
         count = #count graph} : graph
      end

  fun interfereWithColors (graph, var, colors) =
      foldl (fn (x,z) => interfereWithColor (z, var, x)) graph colors

  fun addMove (graph, varId1, varId2) =
      let
        val vid1 = vertexId (graph, varId1)
        val vid2 = vertexId (graph, varId2)
      in
        if vid1 = vid2 then graph else
        let
          val move1 = ISet.add (moves (graph, vid1), vid2)
          val move2 = ISet.add (moves (graph, vid2), vid1)
          val moveMap = IEnv.insert (#moveMap graph, vid1, move1)
          val moveMap = IEnv.insert (moveMap, vid2, move2)
        in
          {varMap = #varMap graph,
           aliasMap = #aliasMap graph,
           adjMap = #adjMap graph,
           moveMap = moveMap,
           scoreMap = #scoreMap graph,
           count = #count graph} : graph
        end
      end

  fun discardMoves (graph:graph) =
      {varMap = #varMap graph,
       aliasMap = #aliasMap graph,
       adjMap = #adjMap graph,
       moveMap = IEnv.empty,
       scoreMap = #scoreMap graph,
       count = #count graph} : graph

  fun removeEdges (graph, vid1) =
      let
        val adj1 = adjacencies (graph, vid1)
        val adjMap = IEnv_remove (#adjMap graph, vid1)
        val adjMap =
            ISet.foldl
              (fn (vid2, adjMap) =>
                  case IEnv.find (adjMap, vid2) of
                    NONE => adjMap
                  | SOME adj2 =>
                    IEnv.insert (adjMap, vid2, ISet.delete (adj2, vid1)))
              adjMap
              adj1
      in
        {varMap = #varMap graph,
         aliasMap = #aliasMap graph,
         adjMap = adjMap,
         moveMap = #moveMap graph,
         scoreMap = #scoreMap graph,
         count = #count graph} : graph
      end

  fun removeMove (graph, vid1, vid2) =
      let
        val move1 = ISet_delete (moves (graph, vid1), vid2)
        val move2 = ISet_delete (moves (graph, vid2), vid1)
        val moveMap = IEnv.insert (#moveMap graph, vid1, move1)
        val moveMap = IEnv.insert (moveMap, vid2, move2)
      in
        {varMap = #varMap graph,
         aliasMap = #aliasMap graph,
         adjMap = #adjMap graph,
         moveMap = moveMap,
         scoreMap = #scoreMap graph,
         count = #count graph} : graph
      end

  fun setSpillScore (graph, var, score) =
      let
        val vid = vertexId (graph, var)
        val (allow, _) = spillScore (graph, vid)
      in
        {varMap = #varMap graph,
         aliasMap = #aliasMap graph,
         adjMap = #adjMap graph,
         moveMap = #moveMap graph,
         scoreMap = IEnv.insert (#scoreMap graph, vid, (allow, score)),
         count = #count graph} : graph
      end

  fun disallowSpill (graph, var) =
      let
        val vid = vertexId (graph, var)
        val (_, score) = spillScore (graph, vid)
      in
        {varMap = #varMap graph,
         aliasMap = #aliasMap graph,
         adjMap = #adjMap graph,
         moveMap = #moveMap graph,
         scoreMap = IEnv.insert (#scoreMap graph, vid, (false, score)),
         count = #count graph} : graph
      end

  fun replaceVertexId (map, idset, oldVid, newVid) =
      ISet.foldl
        (fn (vid, map) =>
            case IEnv.find (map, vid) of
              NONE => map
            | SOME set =>
              let
                val set = ISet_delete (set, oldVid)
                val set = ISet.add (set, newVid)
              in
                IEnv.insert (map, vid, set)
              end)
        map
        idset

  fun coalesceVertex (graph, vid1, vid2) =
      let
        val adj1 = adjacencies (graph, vid1)
        val adj2 = adjacencies (graph, vid2)
        val newAdj = ISet.union (adj1, adj2)
        val _ = if ISet.member (adj1, vid2) orelse ISet.member (adj2, vid1)
                then raise Control.Bug "coalesceVertex: interfered"
                else ()

        val move1 = ISet_delete (moves (graph, vid1), vid2)
        val move2 = ISet_delete (moves (graph, vid2), vid1)
        val newMove = ISet.union (move1, move2)

        val (allow1, score1) = spillScore (graph, vid1)
        val (allow2, score2) = spillScore (graph, vid2)
        val newScore = (allow1 andalso allow2, score1 + score2)

        val adjMap = replaceVertexId (#adjMap graph, adj2, vid2, vid1)
        val moveMap = replaceVertexId (#moveMap graph, move2, vid2, vid1)
        val adjMap = IEnv_remove (adjMap, vid2)
        val moveMap = IEnv_remove (moveMap, vid2)
        val scoreMap = IEnv_remove (#scoreMap graph, vid2)
      in
        {varMap = #varMap graph,
         aliasMap = IEnv.insert (#aliasMap graph, vid2, vid1),
         adjMap = IEnv.insert (adjMap, vid1, newAdj),
         moveMap = IEnv.insert (moveMap, vid1, newMove),
         scoreMap = IEnv.insert (scoreMap, vid1, newScore),
         count = #count graph} : graph
      end

  fun coalesce (graph, varId1, varId2) =
      coalesceVertex (graph, vertexId (graph, varId1), vertexId (graph, varId2))

  fun fold f z (graph as {varMap, ...}:graph) =
      VarID.Map.foldli
        (fn (varId, vid, z) => f (varId, derefAlias (graph, vid), z))
        z
        varMap

  fun movePairs ({moveMap, ...}:graph) =
      IEnv.foldri
        (fn (vid1, set, z) =>
            ISet.foldr
              (fn (vid2, z) => if vid1 < vid2 then (vid1, vid2)::z else z)
              z
              set)
        nil
        moveMap

end
