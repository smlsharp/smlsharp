(**
 * x86 RTL
 * @copyright (c) 2009, 2010, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure Coloring :> sig

  val color : {maxColorId: Interference.colorId}
              -> Interference.graph
              -> {spill: VarID.id VarID.Map.map,
                  color: Interference.colorId VarID.Map.map}

end =
struct

  structure PairOrdKey =
  struct
    type ord_key = Interference.vertexId * Interference.vertexId
    fun compare ((i1, j1), (i2, j2)) =
        let
          val (i1, j1) = if i1 < j1 then (i1, j1) else (j1, i1)
          val (i2, j2) = if i2 < j2 then (i2, j2) else (j2, i2)
        in
          case Int.compare (i1, i2) of
            EQUAL => Int.compare (j1, j2)
          | x => x
        end
  end
  structure PairMap = BinaryMapMaker(PairOrdKey)

  type workset =
      {
        graph: Interference.graph ref,
        numColors: int,
        simplifySet: Interference.vertexId list ref,
        freezeSet: unit IEnv.map ref,
        spillSet: ISet.set ref,
        moveSet: unit PairMap.map ref,
        stack: (Interference.vertexId * ISet.set) list ref
      }

  fun format_workset ({graph, numColors, simplifySet, freezeSet, spillSet,
                       moveSet, stack}:workset) =
      let open TermFormat.FormatComb in
        record
          [("simplifySet", list int (!simplifySet)),
           ("freezeSet", list int (IEnv.listKeys (!freezeSet))),
           ("spillSet", list int (ISet.listItems (!spillSet))),
           ("moveSet", list (tuple2 (int, int)) (PairMap.listKeys (!moveSet))),
           ("stack", list (tuple2 (int, list int o ISet.listItems)) (!stack))]
      end

  (* for debug *)
  val allocLog = ref nil : (string * int list) list ref  (* for debug *)
  fun LOG s l = allocLog := (s,l) :: !allocLog
  fun showLog () =
      String.concat
        (map (fn (s,l) =>
                 foldl (fn (i,z) => z ^ " " ^ Int.toString i) s l ^ "\n")
             (rev (!allocLog)))

  fun checkInvaliant (workset as {graph, numColors, simplifySet, freezeSet,
                                  spillSet, moveSet, stack} : workset) =
      let
        val graph = !graph
        val origSimplifySet = !simplifySet
        val simplifySet = ISet.fromList (!simplifySet)
        val freezeSet = IEnv.foldli (fn (i,_,z) => ISet.add (z,i)) ISet.empty
                        (!freezeSet)
        val spillSet = !spillSet
        val moveSet = !moveSet
        val stackSet = ISet.fromList (map #1 (!stack))

        fun bug s =
            let open TermFormat.FormatComb in
            (print ("==== INVALIANT DOES NOT HOLD ====\n");
             print s;
             print "\n";
             print (Control.prettyPrint (format_workset workset));
             print "\n=========\n";
             print (Control.prettyPrint (Interference.format_graph graph));
             print "\n=========\n";
             raise Control.Bug ("invaliant: " ^ s))
            end
        val fmt = Int.toString

        val allSet = foldl ISet.union simplifySet [freezeSet,spillSet,stackSet]
        val allMoves = Interference.movePairs graph
        val numAll = ISet.numItems allSet
        val numSimplify = ISet.numItems simplifySet
        val numFreeze = ISet.numItems freezeSet
        val numSpill = ISet.numItems spillSet
        val numStack = ISet.numItems stackSet
        fun significant i = Interference.degree (graph, i) >= numColors
        fun isNotMoveRelated i = ISet.isEmpty (Interference.moves (graph, i))
        fun isRemembered i =
            ISet.member (freezeSet, i) orelse ISet.member (spillSet, i)
        fun pairEq x y = PairOrdKey.compare (x, y) = EQUAL
      in
        if length origSimplifySet = ISet.numItems simplifySet
        then () else bug "duplicated item in simplifySet";
        if length (!stack) = ISet.numItems stackSet
        then () else bug "duplicated item in stack";
        if numAll = numSimplify + numFreeze + numSpill + numStack
        then () else bug "not disjoint";
        if Interference.vertexes graph = ISet.listItems allSet
        then () else bug "not cover all vertexes";
        case ISet.find significant simplifySet of
          NONE => ()
        | SOME i => bug ("node " ^ fmt i ^ " in simplifySet is significant");
        case ISet.find significant freezeSet of
          NONE => ()
        | SOME i => bug ("node " ^ fmt i ^ " in freezeSet is significant");
        case ISet.find (not o significant) spillSet of
          NONE => ()
        | SOME i => bug ("node " ^ fmt i ^ " in spillSet is insignificant");
        case ISet.find (not o isNotMoveRelated) simplifySet of
          NONE => ()
        | SOME i => bug ("node " ^ fmt i ^ " in simplifySet is move-related.");
        case ISet.find isNotMoveRelated freezeSet of
          NONE => ()
        | SOME i => bug ("node " ^ fmt i ^ " in freezeSet is not\
                                           \ move-related.");
        case ISet.find (fn x => Interference.degree (graph, x) > 0) stackSet of
          NONE => ()
        | SOME i => bug ("node " ^ fmt i ^ " in stack is not detached");
        case List.find (fn k => not (List.exists (pairEq k) allMoves))
                       (PairMap.listKeys moveSet) of
          NONE => ()
        | SOME (i,j) => bug ("move (" ^ fmt i ^ "," ^ fmt j ^ ")\
                             \ in moveSet doesn't exist");
        case List.find (fn (i,j) => not (isRemembered i andalso isRemembered j))
                       (PairMap.listKeys moveSet) of
          NONE => ()
        | SOME (i,j) => bug ("move (" ^ fmt i ^ "," ^ fmt j ^ ")\
                             \ in moveSet is not valid");
        ()
      end

  fun makeWorkSet numColors graph =
      let
        val simplifySet = ref nil
        val freezeSet = ref IEnv.empty
        val spillSet = ref ISet.empty
        val _ =
            app (fn vid =>
                    if Interference.degree (graph, vid) >= numColors
                    then spillSet := ISet.add (!spillSet, vid)
                    else if ISet.isEmpty (Interference.moves (graph, vid))
                    then simplifySet := vid :: !simplifySet
                    else freezeSet := IEnv.insert (!freezeSet, vid, ()))
                (Interference.vertexes graph)
        val moveSet =
            foldl (fn (k,z) => PairMap.insert (z, k, ()))
                  PairMap.empty
                  (Interference.movePairs graph)
      in
        {graph = ref graph,
         numColors = numColors,
         simplifySet = simplifySet,
         freezeSet = freezeSet,
         spillSet = spillSet,
         moveSet = ref moveSet,
         stack = ref nil} : workset
      end

  fun cancelFreeze ({graph, simplifySet, freezeSet, ...}:workset, vid) =
      (freezeSet := #1 (IEnv.remove (!freezeSet, vid));
       simplifySet := vid :: !simplifySet)
      handle e => raise Control.Bug ("cancelFreeze: " ^ exnMessage e)

  fun freezeMove (workset as {graph, numColors, freezeSet, simplifySet,
                              moveSet, ...}:workset, vid1, vid2) =
      (
        (* LOG "freeze" [vid1,vid2]; *)
        graph := Interference.removeMove (!graph, vid1, vid2);
        if PairMap.inDomain (!moveSet, (vid1, vid2))
        then moveSet := #1 (PairMap.remove (!moveSet, (vid1, vid2)))
        else ();
        if IEnv.inDomain (!freezeSet, vid2)
           andalso ISet.isEmpty (Interference.moves (!graph, vid2))
        then cancelFreeze (workset, vid2)
        else ()
      )

  fun freezeMoves (workset as {graph, ...}, vid) =
      ISet.app (fn i => freezeMove (workset, vid, i))
               (Interference.moves (!graph, vid))

  fun enableMoves (workset as {graph, moveSet, ...}:workset, vid) =
      moveSet :=
        ISet.foldl
          (fn (i, moveSet) => PairMap.insert (moveSet, (vid, i), ()))
          (!moveSet)
          (Interference.moves (!graph, vid))

  fun freezeToSpill ({graph, spillSet, freezeSet, ...}:workset, vid) =
      (freezeSet := #1 (IEnv.remove (!freezeSet, vid));
       spillSet := ISet.add (!spillSet, vid))
      handle e => raise Control.Bug ("freezeToSpill: " ^ exnMessage e)

  fun forget ({freezeSet, spillSet, ...}:workset, vid) =
      (if IEnv.inDomain (!freezeSet, vid)
       then freezeSet := #1 (IEnv.remove (!freezeSet, vid))
       else spillSet := ISet.delete (!spillSet, vid))
      handle e => raise Control.Bug ("forget: " ^ exnMessage e)

  fun afterDecrement (workset as {graph, numColors, simplifySet, freezeSet,
                                  spillSet, ...}, vid) =
      (
        case Interference.precolor vid of
          SOME _ => ()
        | NONE =>
          if Interference.degree (!graph, vid) = numColors - 1
          then (spillSet := ISet.delete (!spillSet, vid);
                if ISet.isEmpty (Interference.moves (!graph, vid))
                then simplifySet := vid :: !simplifySet
                else (freezeSet := IEnv.insert (!freezeSet, vid, ());
                      enableMoves (workset, vid)))
          else ()
      ) handle e => raise Control.Bug ("afterDecrement: " ^ exnMessage e)

  fun detachVertex (workset as {graph, numColors, stack, ...}, vid) =
      let
        val oldGraph = !graph
        val adj = Interference.adjacencies (oldGraph, vid)
        val newGraph = Interference.removeEdges (oldGraph, vid)
      in
        graph := newGraph;
        stack := (vid, adj) :: !stack;
        ISet.app (fn i => afterDecrement (workset, i)) adj
      end

  fun updateMoveSet (moveSet, oldVid, moves, newVid) =
      ISet.foldl
        (fn (i, moveSet) =>
            let
              val moveSet = #1 (PairMap.remove (moveSet, (oldVid, i)))
                            handle _ => moveSet
            in
              if i = newVid then moveSet
              else PairMap.insert (moveSet, (newVid, i), ())
            end)
        moveSet
        moves

  fun combine (workset as {graph, numColors, moveSet, freezeSet, ...}:workset,
               vid1, vid2) =
      let
        (* val _ = LOG "combine" [vid1,vid2] *)
        val oldGraph = !graph
        val moves2 = Interference.moves (oldGraph, vid2)
        val adj1 = Interference.adjacencies (oldGraph, vid1)
        val adj2 = Interference.adjacencies (oldGraph, vid2)
      in
        graph := Interference.coalesceVertex (oldGraph, vid1, vid2);
        forget (workset, vid2);
        moveSet := updateMoveSet (!moveSet, vid2, moves2, vid1);
        ISet.app (fn i => if ISet.member (adj1, i)
                          then afterDecrement (workset, i)
                          else ())
                 adj2;
        if IEnv.inDomain (!freezeSet, vid1)
        then if Interference.degree (!graph, vid1) >= numColors
             then freezeToSpill (workset, vid1)
             else if ISet.isEmpty (Interference.moves (!graph, vid1))
             then cancelFreeze (workset, vid1)
             else ()
        else ()
      end

  local
    fun ISet_all f set =
        not (ISet.exists (fn x => not (f x)) set)
    fun george (graph, numColors, vid1, vid2) =
        let
          val adj1 = Interference.adjacencies (graph, vid1)
          val adj2 = Interference.adjacencies (graph, vid2)
        in
          ISet_all
            (fn i =>
                ISet.member (adj2, i)
                orelse (case Interference.precolor i of
                          NONE => Interference.degree (graph, i) < numColors
                        | SOME _ =>
                          (* assume that precolored nodes are interferenced
                           * each other. Since each of them have at least
                           * K - 1 neighbors by this assumption, if there are
                           * an interference between a precolored node and
                           * a non-precolored node, then the precolored node
                           * have at least K neighbors. *)
                          false))
            adj1
        end
  in

  fun checkCoalesce ({graph = ref graph, numColors, ...}:workset, vid1, vid2) =
      (george (graph, numColors, vid1, vid2)
       orelse george (graph, numColors, vid2, vid1))

  end (* local *)

  fun higherScore ((true, _), (false, _)) = true
    | higherScore ((a1, s1:int), (a2, s2)) = a1 = a2 andalso s1 > s2

  fun selectSpill (graph, set) =
      case ISet.listItems set of
        nil => raise Control.Bug "selectSpill"
      | h::t =>
        #1 (ISet.foldl
              (fn (vid1, z as (vid2, score2)) =>
                  let
                    val score1 = Interference.spillScore (graph, vid1)
                  in
                    if higherScore (score1, score2) then (vid1, score1) else z
                  end)
              (h, Interference.spillScore (graph, h))
              set)

  local

    fun simplify (workset as {graph, simplifySet, ...}:workset) =
        let
          (* val _ = checkInvaliant workset *)
          (* val _ = LOG "simplify" (!simplifySet) *)
          val set = !simplifySet
        in
          simplifySet := nil;
          app (fn i => detachVertex (workset, i)) set;
          case !simplifySet of
            _::_ => simplify workset
          | nil => coalesce workset
        end

    and coalesce (workset as {graph, moveSet, freezeSet, ...}:workset) =
        (
          (* checkInvaliant workset; *)
          case PairMap.firsti (!moveSet) of
            NONE => freeze workset
          | SOME (k as (vid1, vid2), ()) =>
            (moveSet := #1 (PairMap.remove (!moveSet, k));
             if ISet.member (Interference.adjacencies (!graph, vid1), vid2)
             then (freezeMove (workset, vid1, vid2);
                   if IEnv.inDomain (!freezeSet, vid1)
                      andalso ISet.isEmpty (Interference.moves (!graph, vid1))
                   then cancelFreeze (workset, vid1)
                   else ();
                   coalesce workset)
             else if checkCoalesce (workset, vid1, vid2)
             then (combine (workset, vid1, vid2);
                   simplify workset)
             else coalesce workset)
        )

    and freeze (workset as {freezeSet, simplifySet, ...}:workset) =
        (
          (* checkInvaliant workset; *)
          case IEnv.firsti (!freezeSet) of
            NONE => spill workset
          | SOME (vid, ()) =>
            (freezeMoves (workset, vid);
             cancelFreeze (workset, vid);
             simplify workset)
        )

    and spill (workset as {graph, spillSet, simplifySet, ...}:workset) =
        (
          (* checkInvaliant workset; *)
          if ISet.isEmpty (!spillSet) then ()
          else
            let
              val vid = selectSpill (!graph, !spillSet)
              (* val _ = LOG "spill" [vid] *)
            in
              spillSet := ISet.delete (!spillSet, vid);
              freezeMoves (workset, vid);
              detachVertex (workset, vid);
              simplify workset
            end
        )

  in

  val mainLoop = simplify

  end (* local *)

  local

    datatype color =
        COLOR of Interference.colorId
      | SPILL of VarID.id option ref

    fun findColor numColors usedColors =
        let
          fun loop i =
              if i > numColors then SPILL (ref NONE)
              else if ISet.member (usedColors, i)
              then loop (i + 1) else COLOR i
        in
          loop 1
        end

    fun findSlotId (r as ref NONE, varId) = (r := SOME varId; varId)
      | findSlotId (ref (SOME id), varId) = id

  in

  fun assignColor (graph, numColors, nil, colorMap) = colorMap
    | assignColor (graph, numColors, (vid, adj)::stack, colorMap) =
      let
        (* val _ = LOG "color" [vid] *)
        val adj = ISet.map (fn i => Interference.derefAlias (graph, i)) adj
        val usedColors =
            ISet.foldl
              (fn (i,z) =>
                  case Interference.precolor i of
                    SOME colorId => ISet.add (z, colorId)
                  | NONE =>
                    case IEnv.find (colorMap, i) of
                      SOME (COLOR colorId) => ISet.add (z, colorId)
                    | _ => z)
              ISet.empty
              adj

        val color = findColor numColors usedColors
        val colorMap = IEnv.insert (colorMap, vid, color)
      in
        assignColor (graph, numColors, stack, colorMap)
      end

  fun makeSubst (graph, colorMap) =
      Interference.fold
        (fn (id, vid, {spill, color}) =>
            case IEnv.find (colorMap, vid) of
              SOME (COLOR colorId) =>
              {spill = spill, color = VarID.Map.insert (color, id, colorId)}
            | SOME (SPILL slotId) =>
              if not (#1 (Interference.spillScore (graph, vid)))
              then raise Control.Bug ("unspillable vertex " ^ Int.toString vid
                                      ^ " is spilled")
              else {spill = VarID.Map.insert (spill, id,
                                              findSlotId (slotId, id)),
                    color = color}
            | NONE => raise Control.Bug "makeSubst")
        {spill = VarID.Map.empty, color = VarID.Map.empty}
        graph

  end (* local *)

  fun color {maxColorId} graph =
      let
        (* val _ = allocLog := nil *)
        val workset = makeWorkSet maxColorId graph
        val () = mainLoop workset
        val {graph = ref graph, stack = ref stack, ...} = workset
        val colorMap = assignColor (graph, maxColorId, stack, IEnv.empty)
      in
        makeSubst (graph, colorMap)
      end

end
