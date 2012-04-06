(**
 * x86 RTL
 * @copyright (c) 2009, 2010, 2011, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure Coloring :> sig

  type graph
  type regId = int

  val format_graph : graph TermFormat.formatter

  (* Let A and B be variables. We say A disturbs B if
   * A is either used or defined by an instruction within the live
   * range of B.  It subsumes that the live range of A and B
   * interfere each other. *)
  val newGraph : unit -> graph
  val addReg : graph * regId -> unit
  val disturb : graph * RTL.var * RTL.var -> unit
(*
  val interfere : graph * VarID.id * VarID.id -> unit
*)
  val interfereWithRegs : graph * RTL.var * regId list -> unit
  val allocReg : graph * RTL.var * regId -> unit
  val sameReg : graph * RTL.var * RTL.var -> unit
  val coalescable : graph * RTL.var * RTL.var -> unit
  val disallowSpill : graph * RTL.var -> unit

  val coloring : graph
                 -> {regSubst: regId VarID.Map.map,
                     spillSubst: RTLUtils.Var.set VarID.Map.map}

end =
struct
  structure LinkedList :> sig
    type 'a list
    type 'a item
    val new : unit -> 'a list
    val add : 'a list * 'a -> 'a item
    val move : 'a item * 'a list -> unit
    val moveAll : 'a list -> 'a list
    val elem : 'a item -> 'a
    val first : 'a list -> 'a item option
    val listItems : 'a list -> 'a item List.list
    val foldl : ('a item * 'b -> 'b) -> 'b -> 'a list -> 'b
    val app : ('a item -> unit) -> 'a list -> unit
  end =
  struct
    datatype 'a next = NIL | NEXT of 'a item
    withtype 'a item = 'a next ref ref * 'a next ref * 'a
    type 'a list = 'a next ref

    fun new () = ref NIL

    fun add (head, elem) =
        let
          val next = ref (!head)
          val item = (ref head, next, elem)
        in
          case !head of NIL => () | NEXT (p,n,i) => p := next;
          head := NEXT item;
          item
        end

    fun move (item as (prev, next, _), head) =
        (case !next of NIL => () | NEXT (p,n,i) => p := !prev;
         !prev := !next;
         next := !head;
         prev := head;
         case !head of NIL => () | NEXT (p,n,i) => p := next;
         head := NEXT item)

    fun moveAll head =
        let
          val newHead = ref (!head)
        in
          case !head of NIL => () | NEXT (p,n,i) => p := newHead;
          newHead
        end

    fun elem ((_,_,elem):'a item) = elem

    fun first (ref NIL) = NONE
      | first (ref (NEXT item)) = SOME item

    fun listItems (ref NIL) = nil
      | listItems (ref (NEXT (item as (p,n,i)))) = item :: listItems n

    fun foldl f z (ref next) =
        let
          fun loop (NIL, z) = z
            | loop (NEXT (item as (p,n,i)), z) = loop (!n, f (item, z))
        in
          loop (next, z)
        end

    fun app f l =
        foldl (fn (x, ()) => f x) () l
  end

  type regId = int
  type vertexId = int

  datatype workset =
      SimplifySet | FreezeSet | SpillSet | SelectStack | ColoredSet

  datatype vertexItem =
      V of {id: vertexId,
            available: bool ref,
            color: regId option ref,
            belongTo: workset ref,
            degree: int ref,
            adjacencies: vertex IEnv.map ref,
            moves: move IEnv.map ref,
            vars: RTLUtils.Var.set ref,
            disturbCount: int ref,
            disturbedBy: VarID.Set.set ref,
            allowSpill: bool ref}
  and moveItem =
      MOVE of (vertex * vertex) ref
  withtype vertex = vertexItem LinkedList.item
  and move = moveItem LinkedList.item

  type graph =
      {
        varMap: vertex VarID.Map.map ref,       (* variable -> vertex *)
        regMap: vertex IEnv.map ref,            (* regId -> vertex *)
        vertexCount: int ref,                   (* counter for vertexId *)
        numColors: int ref,
        simplifySet: vertexItem LinkedList.list,
        coalesceSet: moveItem LinkedList.list,
        freezeSet: vertexItem LinkedList.list,
        spillSet: vertexItem LinkedList.list,
        selectStack: vertexItem LinkedList.list,
        coloredSet: vertexItem LinkedList.list
      }

  local
    open TermFormat.FormatComb
  in

  fun format_vertex_id v =
      case LinkedList.elem v of
        V {id, available, ...} =>
        begin_ $(if !available then begin_ end_ else term "!") $(int id) end_

  fun format_move move =
      case LinkedList.elem move of
        MOVE (ref (v1, v2)) =>
        tuple2 (format_vertex_id, format_vertex_id) (v1, v2)

  fun format_vertex_simple vertex =
      let
        val V {adjacencies, moves, color, available, degree, ...} =
            LinkedList.elem vertex
        val adjs = map LinkedList.elem (IEnv.listItems (!adjacencies))
        val adjs = List.filter (fn V {available,...} => !available) adjs
        val adjs = map (fn V {id,...} => id) adjs
      in
        begin_
          $(int (!degree))
          $(if !available then begin_ end_ else term "!")
          $(tuple2 (list int, list format_move) (adjs, IEnv.listItems (!moves)))
          $(case !color of
              SOME regId => begin_ text "<" $(int regId) text ">" end_
            | NONE => begin_ end_)
        end_
      end

  local
    fun formatVarMap map =
        assocList (VarID.format_id, format_vertex_id)
                  (VarID.Map.listItemsi map)
    fun formatRegMap map =
        assocList (int, format_vertex_id) (IEnv.listItemsi map)
    fun vertexId vertex =
        case LinkedList.elem vertex of V {id,...} => id
    fun formatVertexList l =
        assocList (int, format_vertex_simple)
                  (map (fn v => (vertexId v, v)) (LinkedList.listItems l))
    fun formatMoveList l =
        list format_move (LinkedList.listItems l)
  in

  fun format_graph ({varMap, regMap, vertexCount, numColors,
                     simplifySet, coalesceSet, freezeSet, spillSet,
                     selectStack, coloredSet}:graph) =
      record
        [("varMap", formatVarMap (!varMap)),
         ("regMap", formatRegMap (!regMap)),
         ("vertexCount", int (!vertexCount)),
         ("numColors", int (!numColors)),
         ("simplifySet", formatVertexList simplifySet),
         ("freezeSet", formatVertexList freezeSet),
         ("spillSet", formatVertexList spillSet),
         ("selectStack", formatVertexList selectStack),
         ("coloredSet", formatVertexList coloredSet),
         ("coalesceSet", formatMoveList coalesceSet)]

  end (* local *)

  local
    fun printVertex vertex =
        let
          val V {id, adjacencies=adj, ...} = LinkedList.elem vertex
        in
          print (Int.toString id ^ ":");
          IEnv.appi
            (fn (i,v) =>
                case LinkedList.elem v of
                  V {available=ref true, ...} => print (" " ^ Int.toString i)
                | _ => ())
            (!adj);
          print "\n"
        end

    fun add (moveMap, id1, id2) =
        case IEnv.find (moveMap, id1) of
          NONE => IEnv.insert (moveMap, id1, ISet.singleton id2)
        | SOME x => IEnv.insert (moveMap, id1, ISet.add (x, id2))

    fun makeMoveMap coalesceSet =
        LinkedList.foldl
          (fn (move, moveMap) =>
              let
                val MOVE (ref (v1, v2)) = LinkedList.elem move
                val V {id=id1,...} = LinkedList.elem v1
                val V {id=id2,...} = LinkedList.elem v2
                val moveMap = add (moveMap, id1, id2)
                val moveMap = add (moveMap, id2, id1)
              in
                moveMap
              end)
          IEnv.empty
          coalesceSet
  in

  fun printGraph ({simplifySet, coalesceSet, freezeSet, spillSet,
                   coloredSet, ...}:graph) =
      (
        print "----\n";
        print "SimplifySet\n";
        LinkedList.app printVertex simplifySet;
        print "FreezeSet\n";
        LinkedList.app printVertex freezeSet;
        print "SpillSet\n";
        LinkedList.app printVertex spillSet;
        print "ColoredSet\n";
        LinkedList.app printVertex coloredSet;
        print "Moves\n";
        IEnv.appi
          (fn (id1, ids) =>
              (print (Int.toString id1 ^ ":");
               ISet.app (fn id => print (" " ^ Int.toString id)) ids;
               print "\n"))
          (makeMoveMap coalesceSet);
        print "----\n"
      )

  end (* local *)

  fun LOG msg vertexes =
      let open TermFormat.FormatComb in
        begin_ puts text msg dspace $(list format_vertex_id vertexes) end_
      end

  end (* local *)

  exception ASSERT of string

  local
    fun makeVertexMap ({vertexCount, simplifySet, freezeSet, spillSet,
                        selectStack, coloredSet, ...}:graph) =
        let
          fun add map vs =
              LinkedList.foldl
                (fn (vertex, z) =>
                    case LinkedList.elem vertex of
                      v as V {id, ...} =>
                      case IEnv.find (z, id) of
                        SOME _ => raise ASSERT "duplicate vertex"
                      | NONE =>
                        (if id >= 0 andalso id < !vertexCount then ()
                         else raise ASSERT "invalid vertex id";
                         IEnv.insert (z, id, v)))
                map
                vs
          val map = IEnv.empty
          val map = add map simplifySet
          val map = add map freezeSet
          val map = add map spillSet
          val map = add map selectStack
          val map = add map coloredSet
        in
          map
        end

    fun checkVars vertexMap =
        (
          IEnv.foldl
            (fn (V {id, vars, ...}, allVars) =>
                (RTLUtils.Var.app
                   (fn {id, ...} =>
                       if RTLUtils.Var.inDomain (allVars, id)
                       then raise ASSERT "duplicate var"
                       else ())
                   (!vars);
                 RTLUtils.Var.setUnion (allVars, !vars)))
            RTLUtils.Var.emptySet
            vertexMap;
          ()
        )

    fun checkVertexExists vertexMap (v as V {id,...}) =
        case IEnv.find (vertexMap, id) of
          NONE => raise ASSERT ("vertex not found " ^ Int.toString id)
        | SOME v2 => if v = v2 then ()
                     else raise ASSERT "vertex not identical"

    fun checkAdjacencies vertexMap (v1 as V {id,adjacencies,...}) =
        IEnv.appi
          (fn (key, v2) =>
              let
                val v2 as V {id=id2, adjacencies=adj2, ...} = LinkedList.elem v2
              in
                checkVertexExists vertexMap v2;
                if key = id2 then ()
                else raise ASSERT "adjacent id mismatch";
                if v1 = v2
                then raise ASSERT "adjacent myself" else ();
                case IEnv.find (!adj2, id) of
                  NONE =>
                  raise ASSERT ("adjacencies: reverse entry not found: "
                                ^ Int.toString id ^ " -> " ^ Int.toString key)
                | SOME v3 =>
                  case LinkedList.elem v3 of
                    v3 =>
                    if v1 = v3 then ()
                    else raise ASSERT "adjacencies: reverse entry mismatch"
              end)
          (!adjacencies)

    fun checkMove vertexMap move =
        let
          val move as MOVE (ref (v1, v2)) = LinkedList.elem move
          val v1 as V {id=id1, moves=moves1, adjacencies=adj1, color=color1,
                       available=available1, ...} = LinkedList.elem v1
          val v2 as V {id=id2, moves=moves2, color=color2,
                       available=available2, ...} = LinkedList.elem v2
          val _ = checkVertexExists vertexMap v1
          val _ = checkVertexExists vertexMap v2
        in
          if id1 = id2
          then raise ASSERT "move between same vertex"
          else ();
          if IEnv.inDomain (!adj1, id2)
          then raise ASSERT "move between adjacencies"
          else ();
          if !available1 andalso !available2
          then () else raise ASSERT "move not between available vertexes";
          case IEnv.find (!moves1, id2) of
            NONE => raise ASSERT "move entry not found"
          | SOME move' =>
            case LinkedList.elem move' of
              move' => if move = move' then ()
                       else raise ASSERT "move entry mistmach";
          case IEnv.find (!moves2, id1) of
            NONE => raise ASSERT "move entry not found"
          | SOME move' =>
            case LinkedList.elem move' of
              move' => if move = move' then ()
                       else raise ASSERT "move entry mistmach";
          case (!color1, !color2) of
            (SOME c1, SOME c2) =>
            if c1 = c2 then () else raise ASSERT "move between different color"
          | _ => ()
        end

    fun checkMoves vertexMap (v1 as V {id,moves,...}) =
        IEnv.appi
          (fn (key, move) =>
              let
                val MOVE (ref (v2, v3)) = LinkedList.elem move
                val _ = checkMove vertexMap move
                val v2 = LinkedList.elem v2
                val v3 = LinkedList.elem v3
              in
                if v1 = v2 then ()
                else if v1 = v3 then ()
                else raise ASSERT "move peer not found"
              end)
          (!moves)

    fun checkDegree (v as V {degree,adjacencies,...}) =
        let
          val count =
              IEnv.numItems
                (IEnv.filter
                   (fn v => case LinkedList.elem v of
                              V {available,...} => !available)
                   (!adjacencies))
        in
          if !degree = count then ()
          else raise ASSERT "degree and actual degree mismatch"
        end

    fun checkVertex vertexMap vertex =
        (
          checkVertexExists vertexMap vertex;
          checkAdjacencies vertexMap vertex;
          checkDegree vertex;
          checkMoves vertexMap vertex
        )

    fun checkVarMap vertexMap varMap =
        VarID.Map.appi
          (fn (varId, vertex) =>
              let
                val v as V {id, vars, ...} = LinkedList.elem vertex
              in
                checkVertexExists vertexMap v;
                if RTLUtils.Var.inDomain (!vars, varId) then ()
                else raise ASSERT "invalid varMap entry"
              end)
          varMap

    fun checkRegMap vertexMap regMap =
        IEnv.appi
          (fn (regId, vertex) =>
              let
                val v as V {color, ...} = LinkedList.elem vertex
              in
                checkVertexExists vertexMap v;
                if !color = SOME regId
                then ()
                else raise ASSERT "invalid regMap entry"
              end)
          regMap

    fun checkSimplifySet numColors simplifySet =
        LinkedList.app
          (fn vertex =>
              let
                val V {degree, moves, color, available, belongTo, ...} =
                    LinkedList.elem vertex
              in
                if !degree < numColors
                then () else raise ASSERT "simplifySet: degree";
                if IEnv.isEmpty (!moves)
                then () else raise ASSERT "simplifySet: moves";
                if not (isSome (!color))
                then () else raise ASSERT "simplifySet: color";
                if !available
                then () else raise ASSERT "simplifySet: available";
                if !belongTo = SimplifySet
                then () else raise ASSERT "simplifySet: belongTo"
              end)
          simplifySet

    fun checkFreezeSet numColors freezeSet =
        LinkedList.app
          (fn vertex =>
              let
                val V {degree, moves, color, available, belongTo, ...} =
                    LinkedList.elem vertex
              in
                if !degree < numColors
                then () else raise ASSERT "freezeSet: degree";
                if not (IEnv.isEmpty (!moves))
                then () else raise ASSERT "freezeSet: moves";
                if not (isSome (!color))
                then () else raise ASSERT "freezeSet: color";
                if !available
                then () else raise ASSERT "freezeSet: available";
                if !belongTo = FreezeSet
                then () else raise ASSERT "freezeSet: belongTo"
              end)
          freezeSet

    fun checkSpillSet numColors spillSet =
        LinkedList.app
          (fn vertex =>
              let
                val V {degree, moves, color, available, belongTo, ...} =
                    LinkedList.elem vertex
              in
                if !degree >= numColors
                then () else raise ASSERT "spillSet: degree";
                if not (isSome (!color))
                then () else raise ASSERT "spillSet: color";
                if !available
                then () else raise ASSERT "spillSet: available";
                if !belongTo = SpillSet
                then () else raise ASSERT "spillSet: belongTo"
              end)
          spillSet

    fun checkSelectStack numColors selectStack =
        LinkedList.app
          (fn vertex =>
              let
                val V {degree, moves, color, available, belongTo, ...} =
                    LinkedList.elem vertex
              in
                if not (isSome (!color))
                then () else raise ASSERT "selectStack: color";
                if not (!available)
                then () else raise ASSERT "selectStack: available";
                if !belongTo = SelectStack
                then () else raise ASSERT "selectStack: belongTo"
              end)
          selectStack

    fun checkColoredSet numColors coloredSet =
        LinkedList.app
          (fn vertex =>
              let
                val V {color, available, belongTo, ...} =
                    LinkedList.elem vertex
              in
                if isSome (!color)
                then () else raise ASSERT "coloredSet: color";
                if !available
                then () else raise ASSERT "coloredSet: available";
                if !belongTo = ColoredSet
                then () else raise ASSERT "coloredSet: belongTo"
              end)
          coloredSet

    fun checkCoalsceSet vertexMap coalesceSet =
        LinkedList.app (checkMove vertexMap) coalesceSet
  in

  fun checkInvaliant (graph as {varMap, regMap, vertexCount,
                                numColors, simplifySet, coalesceSet, freezeSet,
                                spillSet, selectStack, coloredSet}:graph) =
      let
        val vertexMap = makeVertexMap graph
      in
        IEnv.app (checkVertex vertexMap) vertexMap;
        checkVars vertexMap;
        checkVarMap vertexMap (!varMap);
        checkRegMap vertexMap (!regMap);
        checkSimplifySet (!numColors) simplifySet;
        checkFreezeSet (!numColors) freezeSet;
        checkSpillSet (!numColors) spillSet;
        checkSelectStack (!numColors) selectStack;
        checkColoredSet (!numColors) coloredSet;
        checkCoalsceSet vertexMap coalesceSet;
        ()
      end
      handle ASSERT msg =>
             let open TermFormat.FormatComb in
               begin_ text "****************" newline
                      puts text "ASSERTION FAILED: " text msg newline
                      $(format_graph graph) newline
                      text "****************" end_;
               raise Control.Bug ("ASSERT: " ^ msg)
             end

  end (* local *)

  fun newGraph () =
      {
        varMap = ref VarID.Map.empty,
        regMap = ref IEnv.empty,
        vertexCount = ref 0,
        numColors = ref 0,
        simplifySet = LinkedList.new (),
        coalesceSet = LinkedList.new (),
        freezeSet = LinkedList.new (),
        spillSet = LinkedList.new (),
        selectStack = LinkedList.new (),
        coloredSet = LinkedList.new ()
      } : graph

  fun newVertex (graph as {vertexCount, simplifySet, ...}:graph) =
      let
        val id = !vertexCount
        val item = V {id = id,
                      available = ref true,
                      color = ref NONE,
                      belongTo = ref SimplifySet,
                      degree = ref 0,
                      adjacencies = ref IEnv.empty,
                      moves = ref IEnv.empty,
                      vars = ref RTLUtils.Var.emptySet,
                      disturbCount = ref 0,
                      disturbedBy = ref VarID.Set.empty,
                      allowSpill = ref true}
        val vertex = LinkedList.add (simplifySet, item)
      in
        vertexCount := !vertexCount + 1;
        vertex
      end

  fun touchVar (graph as {varMap, ...}:graph) (var as {id,...}:RTL.var) =
      case VarID.Map.find (!varMap, id) of
        SOME vertex => vertex
      | NONE =>
        let
          val vertex = newVertex graph
          val V {vars, ...} = LinkedList.elem vertex
        in
          vars := RTLUtils.Var.setUnion (!vars, RTLUtils.Var.singleton var);
          varMap := VarID.Map.insert (!varMap, id, vertex);
          (*checkInvaliant graph handle e => raise e;*)
          vertex
        end

  fun unifyColor (color1 : regId option, color2 : regId option) =
      case (color1, color2) of
        (NONE, color2) => color2
      | (color1, NONE) => color1
      | (SOME c1, SOME c2) =>
        if c1 = c2 then color1
        else raise Control.Bug "unifyColor: intend to unify different colors"

  fun unifiableColors (color1 : regId option, color2 : regId option) =
      case (color1, color2) of
        (SOME c1, SOME c2) => c1 = c2
      | _ => true

  local

    fun addMove (graph as {coalesceSet, freezeSet, ...}:graph)
                (vertex1, vertex2) =
        let
          val V {id=id1, moves=moves1, adjacencies=adj1, belongTo=belongTo1,
                 color=color1, ...} = LinkedList.elem vertex1
          val V {id=id2, moves=moves2, belongTo=belongTo2, color=color2, ...} =
              LinkedList.elem vertex2
        in
(*
let open TermFormat.FormatComb in
  begin_ puts text "addMove "
         $(tuple2 (format_vertex_id, format_vertex_id) (vertex1, vertex2))
         end_ end;
*)
          if IEnv.inDomain (!moves1, id2)
             orelse IEnv.inDomain (!adj1, id2)
             orelse id1 = id2
             orelse not (unifiableColors (!color1, !color2))
          then ()
          else
            let
              val moveItem = MOVE (ref (vertex1, vertex2))
              val move = LinkedList.add (coalesceSet, moveItem)
            in
              moves1 := IEnv.insert (!moves1, id2, move);
              moves2 := IEnv.insert (!moves2, id1, move);
              if !belongTo1 = SimplifySet
              then (belongTo1 := FreezeSet;
                    LinkedList.move (vertex1, freezeSet))
              else ();
              if !belongTo2 = SimplifySet
              then (belongTo2 := FreezeSet;
                    LinkedList.move (vertex2, freezeSet))
              else ()
            end
        (*checkInvaliant graph handle e => raise e*)
        end

  in

  fun coalescable (graph, varId1, varId2) =
      addMove graph (touchVar graph varId1, touchVar graph varId2)

  end (* local *)

  (* called when the number of moves has changed. *)
  fun decrementNumMoves (graph as {simplifySet, ...}:graph) vertex =
      let
        val V {moves, available, belongTo, ...} = LinkedList.elem vertex
      in
        if !belongTo = FreezeSet andalso IEnv.isEmpty (!moves)
        then (belongTo := SimplifySet; LinkedList.move (vertex, simplifySet))
        else ()
      end

  fun removeAllMoves (graph as {simplifySet, ...}:graph) vertex =
      let
        val trash = LinkedList.new ()
        val V {id, moves, available, ...} = LinkedList.elem vertex
      in
        IEnv.app
          (fn move =>
              let
                val MOVE (r as ref (v1, v2)) = LinkedList.elem move
                val V {id=id1, ...} = LinkedList.elem v1
                val peer = if id = id1 then v2 else v1
                val V {moves, ...} = LinkedList.elem peer
              in
                moves := #1 (IEnv.remove (!moves, id));
                LinkedList.move (move, trash);
                decrementNumMoves graph peer
              end)
          (!moves);
        moves := IEnv.empty
        (* the invaliant does not hold here. *)
      end

  fun activateMove (graph as {coalesceSet, ...}:graph) vertex =
      let
        val V {moves, ...} = LinkedList.elem vertex
      in
        IEnv.app
          (fn move =>
              ((*case LinkedList.elem move of
                 MOVE (ref (v1,v2)) => LOG "activate move" [v1,v2];*)
               LinkedList.move (move, coalesceSet)))
          (!moves)
      end

  (* called when the number of actual available adajencies has changed. *)
  fun decrementDegree (graph as {simplifySet, freezeSet, numColors, ...})
                      vertex =
      let
        val V {available, degree, adjacencies, moves, belongTo, ...} =
            LinkedList.elem vertex
        val newDegree = !degree - 1
        val _ = degree := newDegree
      in
        if newDegree = !numColors - 1
        then (if !available
              then (activateMove graph vertex;
                    IEnv.app (activateMove graph) (!adjacencies))
              else ();
              if !belongTo = SpillSet
              then if IEnv.isEmpty (!moves)
                   then (belongTo := SimplifySet;
                         LinkedList.move (vertex, simplifySet))
                   else (belongTo := FreezeSet;
                         LinkedList.move (vertex, freezeSet))
              else ())
        else ()
      end

  (* called when the number of actual available adajencies has changed. *)
  fun incrementDegree (graph as {spillSet, numColors, ...}:graph) vertex =
      let
        val V {degree, belongTo, ...} = LinkedList.elem vertex
        val newDegree = !degree + 1
        val _ = degree := newDegree
      in
        if newDegree = !numColors
        then if !belongTo = FreezeSet orelse !belongTo = SimplifySet
             then (belongTo := SpillSet;
                   LinkedList.move (vertex, spillSet))
             else ()
        else ()
      end

  local
    fun addEdge graph (vertex1, vertex2) =
        let
          val V {id=id1, adjacencies=adj1, moves=moves1, belongTo=belongTo1,
                 ...} = LinkedList.elem vertex1
          val V {id=id2, adjacencies=adj2, moves=moves2, belongTo=belongTo2,
                 ...} = LinkedList.elem vertex2
        in
          if id1 = id2 orelse IEnv.inDomain (!adj1, id2)
          then ()
          else (adj1 := IEnv.insert (!adj1, id2, vertex2);
                incrementDegree graph vertex1;
                adj2 := IEnv.insert (!adj2, id1, vertex1);
                incrementDegree graph vertex2;
                case IEnv.find (!moves1, id2) of
                  NONE => ()
                | SOME move =>
                  (moves1 := #1 (IEnv.remove (!moves1, id2));
                   moves2 := #1 (IEnv.remove (!moves2, id1));
                   LinkedList.move (move, LinkedList.new ());
                   decrementNumMoves graph vertex1;
                   decrementNumMoves graph vertex2))
          (*;checkInvaliant graph handle e => raise e*)
        end

  in

  fun addReg (graph as {regMap, vertexCount, numColors, coloredSet, ...}:graph,
              regId) =
      if IEnv.numItems (!regMap) <> !vertexCount
      then raise Control.Bug "addReg: not initial"
      else
        case IEnv.find (!regMap, regId) of
          SOME _ => raise Control.Bug "addReg: duplicate reg"
        | NONE =>
          let
            val vertex = newVertex graph
            val V {color, belongTo, ...} = LinkedList.elem vertex
          in
            LinkedList.move (vertex, coloredSet);
            color := SOME regId;
            belongTo := ColoredSet;
            IEnv.app (fn v => addEdge graph (vertex, v)) (!regMap);
            regMap := IEnv.insert (!regMap, regId, vertex);
            numColors := !numColors + 1
            (*;checkInvaliant graph handle e => raise e*)
          end

(*
  fun interfere (graph, varId1, varId2) =
      let
        val vertex1 = touchVar graph varId1
        val vertex2 = touchVar graph varId2
      in
        addEdge graph (vertex1, vertex2);
        checkInvaliant graph
        handle e => raise e
      end
*)

  fun disturb (graph, var1, var2) =    (* var1 disturbs var2 *)
      let
        val vertex1 = touchVar graph var1
        val vertex2 = touchVar graph var2
        val V {disturbCount=disturbCount1, ...} = LinkedList.elem vertex1
        val V {disturbedBy=disturbedBy2, ...} = LinkedList.elem vertex2
      in
(*
let open TermFormat.FormatComb in
  begin_ puts text "disturb "
         $(tuple2 (RTL.format_var, RTL.format_var) (var1, var2))
         text " = "
         $(tuple2 (format_vertex_id, format_vertex_id) (vertex1, vertex2))
         end_ end;
*)
        addEdge graph (vertex1, vertex2);
        disturbCount1 := !disturbCount1 + 1;
        disturbedBy2 := VarID.Set.add (!disturbedBy2, #id var1)
(*
        checkInvaliant graph
        handle e => raise e
*)
      end

  fun interfereWithRegs (graph as {regMap, ...}, varId, regIds) =
      let
        val vertex = touchVar graph varId
      in
        app (fn regId =>
                case IEnv.find (!regMap, regId) of
                  NONE => raise Control.Bug "interfereWithRegs"
                | SOME v => addEdge graph (vertex, v))
            regIds
        (*;checkInvaliant graph handle e => raise e*)
      end

  end (* local *)

  fun sortVertexPair (vertex1, vertex2) =
      let
        val V {degree=degree1, moves=moves1, ...} = LinkedList.elem vertex1
        val V {degree=degree2, moves=moves2, ...} = LinkedList.elem vertex2
        val n1 = !degree1 + IEnv.numItems (!moves1)
        val n2 = !degree2 + IEnv.numItems (!moves2)
      in
        if n1 >= n2
        then (vertex1, vertex2)
        else (vertex2, vertex1)
      end

  fun combine (graph as {simplifySet, freezeSet, spillSet, coloredSet,
                         numColors, ...}:graph) (vertex1, vertex2) =
      let
        val moveTrash = LinkedList.new ()
        val V {id=id1, available=available1, color=color1, degree=degree1,
               belongTo=belongTo1,
               adjacencies=adj1, moves=moves1, vars=vars1, disturbedBy=dist1,
               disturbCount=count1, allowSpill=allow1} =
            LinkedList.elem vertex1
        val V {id=id2, available=available2, color=color2, degree=degree2,
               belongTo=belongTo2,
               adjacencies=adj2, moves=moves2, vars=vars2, disturbedBy=dist2,
               disturbCount=count2, allowSpill=allow2} =
            LinkedList.elem vertex2
(*
val pre = let open TermFormat.FormatComb in begin_ text "*** BEFORE ***" newline $(format_graph graph) end_ end
*)
      in
        if id1 = id2 then raise Control.Bug "combine" else ();
(*
let open TermFormat.FormatComb in
  begin_ puts text "combine "
         $(tuple2 (format_vertex_id, format_vertex_id) (vertex1, vertex2))
         space $(tuple2 (int, int) (IEnv.numItems (!adj1), IEnv.numItems (!adj2)))
         space $(tuple2 (int, int) (IEnv.numItems (!moves1), IEnv.numItems (!moves2))) end_ end;
*)
(*
LOG "combine" [vertex1, vertex2];
*)
        available2 := false;
        vars1 := RTLUtils.Var.setUnion (!vars1, !vars2);
        dist1 := VarID.Set.union (!dist1, !dist2);
        count1 := !count1 + !count2;
        allow1 := (!allow1 andalso !allow2);
        color1 := unifyColor (!color1, !color2);

        if isSome (!color1) andalso !belongTo1 <> ColoredSet
        then (belongTo1 := ColoredSet; LinkedList.move (vertex1, coloredSet))
        else ();

        IEnv.app
          (fn peer =>
              case LinkedList.elem peer of
                V {id, available, adjacencies=adj, moves, ...} =>
                (adj := #1 (IEnv.remove (!adj, id2));
                 if IEnv.inDomain (!adj, id1)
                 then decrementDegree graph peer
                 else (adj := IEnv.insert (!adj, id1, vertex1);
                       adj1 := IEnv.insert (!adj1, id, peer);
                       if !available then degree1 := !degree1 + 1 else ();
                       case IEnv.find (!moves1, id) of
                         NONE => ()
                       | SOME move =>
                         (moves1 := #1 (IEnv.remove (!moves1, id));
                          moves := #1 (IEnv.remove (!moves, id1));
                          LinkedList.move (move, moveTrash);
                          decrementNumMoves graph peer))))
          (!adj2);
          
(*
let open F in begin_ puts text "*** ADJ ***" newline $(format_graph graph) end_ end;
*)

        IEnv.app
          (fn move =>
              case LinkedList.elem move of
                m as MOVE (r as ref (v3, v4)) =>
                let
(*
val _ = let open F in begin_ puts text "**** MOVE " $(format_move m) text " *****" end_ end
*)
                  val V {id=id3, ...} = LinkedList.elem v3
                  val peer = if id3 = id2 then v4 else v3
(*
val _ = let open F in begin_ puts $(format_vertex_id peer) end_ end
*)
                  val V {id, moves, adjacencies, color, ...} =
                      LinkedList.elem peer
                in
                  moves := #1 (IEnv.remove (!moves, id2));
                  if id = id1
                     orelse IEnv.inDomain (!adjacencies, id1)
                     orelse IEnv.inDomain (!moves, id1)
                     orelse not (unifiableColors (!color1, !color))
                  then ((*LOG "trash move" [v3,v4];*)
                        LinkedList.move (move, moveTrash);
                        decrementNumMoves graph peer)
                  else (r := (vertex1, peer);
                        moves := IEnv.insert (!moves, id1, move);
                        moves1 := IEnv.insert (!moves1, id, move))

(*
;
let open F in begin_ puts $(format_graph graph) end_ end
*)
                end)
          (!moves2);

        case !belongTo1 of
          SimplifySet =>
          if !degree1 >= !numColors
          then (belongTo1 := SpillSet; LinkedList.move (vertex1, spillSet))
          else if IEnv.isEmpty (!moves1)
          then ()
          else (belongTo1 := FreezeSet; LinkedList.move (vertex1, freezeSet))
        | FreezeSet =>
          if !degree1 >= !numColors
          then (belongTo1 := SpillSet; LinkedList.move (vertex1, spillSet))
          else if IEnv.isEmpty (!moves1)
          then (belongTo1 := SimplifySet; LinkedList.move (vertex1, simplifySet))
          else ()
        | _ => ();

        LinkedList.move (vertex2, LinkedList.new ())
(*
        ;checkInvaliant graph handle e => raise e
*)
(*;
        checkInvaliant graph
handle e => 
((*print (Control.prettyPrint pre); print "\n";*)raise e)
*)
      end

  fun sameVertex (vertex1, vertex2) =
      let
        val V {id=id1,...} = LinkedList.elem vertex1
        val V {id=id2,...} = LinkedList.elem vertex2
      in
        id1 = id2
      end

  fun rebuildVarMap ({varMap, regMap, ...}:graph) (vertex1, vertex2) =
      let
        val V {vars, color, ...} = LinkedList.elem vertex2
      in
(*
        print ("rebuildVarMap " ^ Int.toString (VarID.Set.numItems (RTLUtils.Var.toVarIDSet (!vars)) + (case !color of NONE => 0 | SOME _ => 1)) ^ "\n");
*)
        RTLUtils.Var.app
          (fn {id,...} => varMap := VarID.Map.insert (!varMap, id, vertex1))
          (!vars);
        case !color of
          NONE => ()
        | SOME regId => regMap := IEnv.insert (!regMap, regId, vertex1)
      end

  fun allocReg (graph as {varMap, regMap, ...}, var, regId) =
      let
        val vertex2 = touchVar graph var
      in
        case IEnv.find (!regMap, regId) of
          NONE => raise Control.Bug "allocReg"
        | SOME vertex1 =>
(*
let open TermFormat.FormatComb in
  begin_ puts text "allocReg "
         $(tuple2 (RTL.format_var, int) (var, regId))
         text " = "
         $(tuple2 (format_vertex_id, format_vertex_id) (vertex2, vertex1))
         end_ end;
*)
           if sameVertex (vertex1, vertex2)
           then ()
           else
             let
               val (vertex1, vertex2) = sortVertexPair (vertex1, vertex2)
             in
               combine graph (vertex1, vertex2);
               rebuildVarMap graph (vertex1, vertex2)
             end
           (*;checkInvaliant graph handle e => raise e*)
      end

  fun sameReg (graph as {varMap, ...}, var1, var2) =
      let
        val vertex1 = touchVar graph var1
        val vertex2 = touchVar graph var2
      in
(*
let open TermFormat.FormatComb in
  begin_ puts text "sameReg "
         $(tuple2 (RTL.format_var, RTL.format_var) (var1, var2))
         text " = "
         $(tuple2 (format_vertex_id, format_vertex_id) (vertex1, vertex2))
         end_ end;
*)
        if sameVertex (vertex1, vertex2)
        then ()
        else
          let
            val (vertex1, vertex2) = sortVertexPair (vertex1, vertex2)
          in
            combine graph (vertex1, vertex2);
            rebuildVarMap graph (vertex1, vertex2)
          end
          (*;checkInvaliant graph handle e => raise e*)
      end

  fun disallowSpill (graph, varId) =
      let
        val vertex = touchVar graph varId
        val V {allowSpill, ...} = LinkedList.elem vertex
      in
        allowSpill := false
      (*;checkInvaliant graph handle e => raise e*)
      end

  fun selectSpill (graph as {spillSet, ...}:graph) =
      let
        (* select a vertex v such that
         * (1) v is disturbed by the maximum number of vertexes, or
         * (2) v disturbs the minimum number of vertexes, or
         * (3) v has the maximum degree.
         *)
        type score = {vertex: vertex,
                      disturbedBy: int,
                      disturbCount: int,
                      degree: int}
(*
val _  = print "begin selectSpill\n"
*)
        fun scoreOf vertex =
(*
let val r =
*)
            case LinkedList.elem vertex of
              V {disturbedBy, disturbCount, degree, allowSpill, ...} =>
              if !allowSpill
              then SOME ({vertex = vertex,
                          disturbedBy = VarID.Set.numItems (!disturbedBy),
                          disturbCount = !disturbCount,
                          degree = !degree} : score)
              else NONE
(*
in
let open TermFormat.FormatComb in begin_ puts text "score of " $(format_vertex_id vertex)
text " : " $(case r of NONE => term "NONE"
                     | SOME s => tuple3 (int, int, int)
                                        (#disturbedBy s,
                                         #disturbCount s,
                                         #degree s))
end_
end;
r
end
*)

        fun larger (NONE, NONE) = NONE
          | larger (x1 as SOME _, NONE) = x1
          | larger (NONE, x2 as SOME _) = x2
          | larger (x1 as SOME (s1:score), x2 as SOME (s2:score)) =
            if #disturbedBy s1 > #disturbedBy s2 then x1
            else if #disturbedBy s1 < #disturbedBy s2 then x2
            else if #disturbCount s1 < #disturbCount s2 then x1
            else if #disturbCount s1 > #disturbCount s2 then x2
            else if #degree s1 >= #degree s2 then x1 else x2

        val maxScore =
            LinkedList.foldl
              (fn (vertex, z) => larger (z, scoreOf vertex))
              NONE
              spillSet
      in
        case maxScore of
          NONE => NONE
        | SOME {vertex, ...} => SOME vertex
      end

  fun select (graph as {selectStack, ...}) vertex =
      let
        val V {available, adjacencies, belongTo, ...} = LinkedList.elem vertex
      in
        removeAllMoves graph vertex;
        available := false;
        IEnv.app (decrementDegree graph) (!adjacencies);
        belongTo := SelectStack;
        LinkedList.move (vertex, selectStack)
        (*;checkInvaliant graph handle e => raise e*)
      end

  fun briggs ({numColors, ...}:graph) (vertex1, vertex2) =
      let
        val V {degree=degree1, ...} = LinkedList.elem vertex1
        val V {degree=degree2, ...} = LinkedList.elem vertex2
      in
        !degree1 + !degree2 < !numColors
      end

  local
    exception False
  in
  fun george ({numColors, ...}:graph) (vertex1, vertex2) =
      let
        val V {adjacencies=adj1, color=color1, ...} = LinkedList.elem vertex1
        val V {adjacencies=adj2, id=id2, ...} = LinkedList.elem vertex2
      in
        (* coalescing with a colored register by George's condition
         * sometimes significantly increases the disturbance factor
         * of precolored nodes, and causes many spills. To avoid
         * this, we return false if vertex1 is colored node. *)
        case !color1 of
          SOME _ => false
        | NONE =>
          (IEnv.app
             (fn vertex =>
                 case LinkedList.elem vertex of
                   V {adjacencies=adj, available=ref true, degree, ...} =>
                   if IEnv.inDomain (!adj, id2) orelse !degree < !numColors
                   then () else raise False
                 | _ => ())
             (!adj1);
           true) handle False => false
      end
  end (* local *)

  fun simplify (graph as {simplifySet, ...}) =
(
      (*checkInvaliant graph handle e => raise e;*)
      case LinkedList.first simplifySet of
        NONE => coalesce graph
      | SOME vertex =>
        (
          (*LOG "simplify" [vertex];*)
          select graph vertex;
(*
printGraph graph;
*)
          simplify graph
        )
)

  and coalesce (graph as {coalesceSet, ...}) =
(
      (*checkInvaliant graph handle e => raise e;*)
      case LinkedList.first coalesceSet of
        NONE => freeze graph
      | SOME move =>
        case LinkedList.elem move of
          MOVE (ref (v1, v2)) =>
          if briggs graph (v1, v2)
                  orelse george graph (v1, v2)
                  orelse george graph (v2, v1)
          then ((*LOG "coalesce" [v1, v2];*)
                combine graph (sortVertexPair (v1, v2));
(*
printGraph graph;
*)
                simplify graph)
          else ((*LOG "failed to coalesce" [v1, v2];*)
                LinkedList.move (move, LinkedList.new ());
(*
printGraph graph;
*)
                coalesce graph)
)

  and freeze (graph as {simplifySet, freezeSet, ...}) =
(
      (*checkInvaliant graph handle e => raise e;*)
      case LinkedList.first freezeSet of
        NONE => spill graph
      | SOME vertex =>
        let
          val V {belongTo, ...} = LinkedList.elem vertex
        in
          (*LOG "freeze" [vertex];*)
          removeAllMoves graph vertex;
          belongTo := SimplifySet;
          LinkedList.move (vertex, simplifySet);
(*
printGraph graph;
*)
          simplify graph
       end
)

  and spill (graph as {spillSet, ...}) =
(
      (*checkInvaliant graph handle e => raise e;*)
      case LinkedList.first spillSet of
        NONE => ()
      | SOME _ =>
        case selectSpill graph of
          NONE => raise Control.Bug "spill: no spill candidate"
        | SOME vertex =>
          ((*LOG "potential spill" [vertex];*)
(*
let open F in
begin_ puts $(list VarID.format_id (VarID.Set.listItems (case LinkedList.elem vertex of V {vars, ...} => !vars))) end_ end;
*)
           select graph vertex;
(*
printGraph graph;
*)
           simplify graph)
)

  fun selectColor (args as (regMap : vertex IEnv.map,
                            {selectStack, coloredSet, ...}:graph)) =
      case LinkedList.first selectStack of
        NONE => ()
      | SOME vertex =>
        let
          val V {adjacencies, color, available, ...} = LinkedList.elem vertex
          val colors =
              IEnv.foldl
                (fn (vertex, colors) =>
                    case LinkedList.elem vertex of
                      V {available=ref true, color=ref (SOME regId), ...} =>
                      if IEnv.inDomain (colors, regId)
                      then #1 (IEnv.remove (colors, regId))
                      else colors
                    | _ => colors)
                regMap
                (!adjacencies)
        in
          color := Option.map #1 (IEnv.firsti colors);
          (*
          case !color of
            SOME r => LOG ("color " ^ Int.toString r) [vertex]
          | NONE => LOG "actual spill" [vertex];
           *)
          available := true;
          LinkedList.move (vertex, coloredSet);
          selectColor args
        end

  fun makeColorMap ({coloredSet, ...}:graph) =
      LinkedList.foldl
        (fn (v, z as {regSubst, spillSubst}) =>
            case LinkedList.elem v of
              V {vars = ref vars, color = ref (SOME regId), ...} =>
              let
                val regSubst =
                    RTLUtils.Var.fold
                      (fn ({id,...}, z) => VarID.Map.insert (z, id, regId))
                      regSubst
                      vars
              in
                {regSubst = regSubst, spillSubst = spillSubst}
              end
            | V {vars = ref vars, color = ref NONE, ...} =>
              let
                val spillSubst =
                    RTLUtils.Var.fold
                      (fn ({id,...}, z) => VarID.Map.insert (z, id, vars))
                      spillSubst
                      vars
              in
                {regSubst = regSubst, spillSubst = spillSubst}
              end)
        {regSubst=VarID.Map.empty, spillSubst=VarID.Map.empty}
        coloredSet

  fun coloring (graph as {varMap, regMap, vertexCount, numColors, coloredSet,
                          ...}:graph) =
      let
(*
        val _ = print ("start coloring with " ^ 
                       !numColors ^ " registers for " ^
                       Int.toString (IEnv.numItems (!varMap)) ^
                       " variables, " ^
                       Int.toString vertexCount ^
                       " vertexes, " ^ 
                       
  *)
        val _ = varMap := VarID.Map.empty
        val regMap = !regMap before regMap := IEnv.empty
        val _ = if !numColors <= 0
                then raise Control.Bug "coloring: no register" else ()
(*
        val _ = printGraph graph
*)
(*
        val _ = checkInvaliant graph
*)
        val _ = simplify graph
        val _ = selectColor (regMap, graph)
        val maps = makeColorMap graph
      in
        (* initialize graph *)
        vertexCount := 0;
        numColors := 0;
        LinkedList.moveAll (#coloredSet graph);
        maps
      end

end
