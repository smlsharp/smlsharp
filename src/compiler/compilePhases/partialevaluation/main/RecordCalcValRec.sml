(**
 * @copyright (C) 2024 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure RecordCalcValRec =
struct

  structure R = RecordCalc

  type bind = {var : RecordCalc.varInfo, exp : RecordCalc.rcexp}

  datatype ord = PRE of VarID.id | POST of VarID.id

  fun addEdge graph from to =
      case VarID.Map.find (graph, from) of
        NONE => VarID.Map.insert (graph, from, [to])
      | SOME t => VarID.Map.insert (graph, from, to :: t)

  fun inverse graph =
      VarID.Map.foldli
        (fn (from, succs, graph) =>
            foldl (fn (to, graph) => addEdge graph to from) graph succs)
        VarID.Map.empty
        graph

  fun dfs graph visited found nil = (visited, found)
    | dfs graph visited found (POST id :: ids) =
      dfs graph visited (id :: found) ids
    | dfs graph visited found (PRE id :: ids) =
      if VarID.Set.member (visited, id)
      then dfs graph visited found ids
      else case VarID.Map.find (graph, id) of
             NONE => dfs graph (VarID.Set.add (visited, id)) (id :: found) ids
           | SOME succs =>
             dfs graph
                 (VarID.Set.add (visited, id))
                 found
                 (map PRE succs @ POST id :: ids)

  fun scc graph nodes =
      let
        val (_, postorder) = dfs graph VarID.Set.empty nil (map PRE nodes)
        val inv = inverse graph
        fun loop visited components (id :: ids) =
            if VarID.Set.member (visited, id)
            then loop visited components ids
            else
              let
                val (visited, found) = dfs inv visited nil [PRE id]
              in
                loop visited (found :: components) ids
              end
          | loop visited components nil = components
      in
        loop VarID.Set.empty nil postorder
      end

  fun decompose (binds : bind list, loc) =
      let
        val binds =
            foldl
              (fn (bind as {var = {id, ...}, exp}, binds) =>
                  VarID.Map.insert (binds, id, (bind, RecordCalcFv.fvExp exp)))
              VarID.Map.empty
              binds
        val graph =
            VarID.Map.foldli
              (fn (from, ({exp, ...}, counts), graph) =>
                  VarID.Map.foldli
                    (fn (to, n, graph) =>
                        if n > 0 andalso VarID.Map.inDomain (binds, to)
                        then addEdge graph from to
                        else graph)
                    graph
                    counts)
              VarID.Map.empty
              binds
        val components = scc graph (VarID.Map.listKeys binds)
        val groups =
            map (map (fn id => VarID.Map.lookup (binds, id))) components
            handle LibBase.NotFound => raise Bug.Bug "decompose"
      in
        map (fn [(bind as {var, exp}, counts)] =>
                if VarID.Map.inDomain (counts, #id var)
                then R.RCVALREC ([bind], loc)
                else R.RCVAL {var = var, exp = exp, loc = loc}
              | binds => R.RCVALREC (map #1 binds, loc))
            groups
      end

end
