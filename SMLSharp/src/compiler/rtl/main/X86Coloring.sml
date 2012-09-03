(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure X86Coloring : RTLCOLORING =
struct
(*
fun puts s = print (s ^ "\n")
fun putfs s = print (Control.prettyPrint s ^ "\n")
*)

  structure I = RTL
  structure X = X86Asm
  structure Target = X86Asm
  datatype color = datatype Interference.color

  val maxIterations = 0w16

  fun addInterference (node, {liveOut,...}:RTLLiveness.liveness,
                       (interference, disturbance)) =
      let
(*
val _ = Control.p RTLEdit.format_node node
val _ = Control.p RTLUtils.Var.format_set liveOut
*)
        val {defs, uses} = RTLUtils.Var.defuse node
        val clobs = RTLUtils.Var.clobs node

        val vars = RTLUtils.Var.setUnion (defs, uses)
        val vars = RTLUtils.Var.setUnion (vars, liveOut)
        val vars = RTLUtils.Var.setUnion (vars, clobs)

        val interference =
            RTLUtils.Var.fold
              (fn (v, i) => Interference.addVar (i, v))
              interference
              vars

        (* defs interfere with liveOut. *)
        val interference =
            RTLUtils.Var.fold
              (fn (v1, interference) =>
                  RTLUtils.Var.fold
                    (fn (v2, i) => Interference.interfere (i, v1, v2))
                    interference
                    liveOut)
              interference
              defs

        (* clobs interfere with (liveOut U defs U uses U clobs). *)
        val interference =
            RTLUtils.Var.fold
              (fn (v1, interference) =>
                  RTLUtils.Var.fold
                    (fn (v2, i) => Interference.interfere (i, v1, v2))
                    interference
                    vars)
              interference
              clobs

        (* simple spill scoring algorithm based on COINS's algorithm. *)
        fun add (setMap, id, v) =
            case LocalVarID.Map.find (setMap, id) of
              NONE =>
              LocalVarID.Map.insert (setMap, id, LocalVarID.Set.singleton v)
            | SOME s =>
              LocalVarID.Map.insert (setMap, id, LocalVarID.Set.add (s, v))

        val vars = RTLUtils.Var.setUnion (defs, uses)
        val disturbance =
            RTLUtils.Var.fold
              (fn ({id=alive,...}, disturbance) =>
                  RTLUtils.Var.fold
                    (fn ({id=used,...}, disturbance) =>
                        add (disturbance, alive, used))
                    disturbance
                    vars)
              disturbance
              liveOut
      in
        (interference, disturbance)
      end
(*
        val {defs, uses} = RTLUtils.Var.defuse node
        fun add interference vars =
            LocalVarID.Map.foldl
              (fn (var, interference) =>
                  Interference.addVar (interference, var))
              interference
              vars
        val interference = add interference defs
        val interference = add interference liveSet
      in
        LocalVarID.Map.foldl
          (fn (var1, interference) =>
              LocalVarID.Map.foldl
                (fn (var2, interference) =>
                    if LocalVarID.eq (#id var1, #id var2)
                    then interference
                    else Interference.interfere (interference, var1, var2))
                interference
                liveSet)
          interference
          liveSet
      end
*)

  fun makeInterference graph =
      let
        val (interference, disturbance) =
            RTLLiveness.foldBackward
              addInterference
              (Interference.empty, LocalVarID.Map.empty)
              (RTLLiveness.liveness graph)
        val spillScore =
            LocalVarID.Map.map LocalVarID.Set.numItems disturbance
      in
        (interference, spillScore)
      end


  local

    fun spillScore score ({id,...}:I.var) =
        case LocalVarID.Map.find (score, id) of
          NONE => 0
        | SOME x => ~x

    fun remove (graph, stack, vid::vids) =
        remove (Interference.disableVertex (graph, vid),
                vid::stack, vids)
      | remove (graph, stack, nil) = (graph, stack)

    fun simplify (score, graph, stack) =
        let
          val numRegisters = length X86Constraint.allRegisters
          val colorables =
              Interference.selectVertexes
                  (fn (vid, _) =>
                      Interference.numAdjacencies (graph, vid) < numRegisters)
                  graph
        in
          case colorables of
            _::_ =>
            let
              val (graph, stack) = remove (graph, stack, colorables)
(*
val _ = Control.ps "--simplify--"
val _ = Control.pl Interference.format_vertexId stack
val _ = Control.p (Interference.format_graph X86Asm.format_reg) graph
val _ = Control.ps "---"
*)
            in
              simplify (score, graph, stack)
            end
          | nil =>
            case Interference.minVertex (spillScore score) graph of
              SOME (varId, _) =>
              let
                val (graph, stack) = remove (graph, stack, [varId])
(*
val _ = Control.ps "--spill--"
val _ = Control.pl Interference.format_vertexId stack
val _ = Control.p (Interference.format_graph X86Asm.format_reg) graph
val _ = Control.ps "---"
*)
              in
                simplify (score, graph, stack)
              end
            | NONE =>
              (* remove unspillable vertexes. *)
              remove (graph, stack,
                      Interference.selectVertexes (fn _ => true) graph)
        end

    fun selectColor (vid, nil, assigned) = NEED_SPILL
      | selectColor (vid, reg::candidates, nil) = COLORED reg
      | selectColor (vid, reg::candidates, assigned as (h::t)) =
        if reg = h then selectColor (vid, candidates, t)
        else if List.all (fn x => reg <> x) t
        then COLORED reg
        else selectColor (vid, candidates, assigned)

    fun select (graph, nil) = graph
      | select (graph, vid::stack) =
        let
          val adjacencies = Interference.adjacencyColors (graph, vid)
          val color = selectColor (vid, X86Constraint.allRegisters,
                                   adjacencies)
          val graph = Interference.setColor (graph, vid, color)
(*
                      handle Interference.DisallowSpill =>
let open FormatByHand in puts "==ERROR==";
putf Interference.format_vertexId vid;
putf (Interference.format_graph X86Asm.format_reg) graph;
raise Control.Bug "select: unspillable vertex" end
*)
(*
val _ = Control.ps "--color--"
val _ = Control.pl Interference.format_vertexId (vid::stack)
val _ = Control.p (Interference.format_color X86Asm.format_reg) color
val _ = Control.ps "---"
*)
        in
          select (graph, stack)
        end

  in

  fun coloring (graph, score) =
      select (simplify (score, graph, nil))

  end (* local *)

  fun regallocLoop (graph, 0w0) =
      raise Control.Bug "regallocLoop: too many loops"
    | regallocLoop (graph, count) =
      let
(*
val _ = Control.ps "--graph--"
val _ = Control.p I.format_graph graph
val _ = Control.ps "---"
*)

(*
val _ = Control.ps " Interference"
*)
(*
val _ = FormatByHand.puts "  liveness begin"
val t1 = Time.now ()
*)
        val (interference, spillScore) = makeInterference graph
(*
val t2 = Time.now ()
val _ = let open FormatByHand in
put (%`"  liveness end : "%pi""` (IntInf.toInt (Time.toMicroseconds (Time.-(t2,t1))))) end
*)

(*
val _ = Control.ps "--interference--"
val _ = Control.p (Interference.format_graph X86Asm.format_reg) interference
val _ = Control.ps "---score---"
val _ = Control.pl (Control.f2 (I.format_id, Control.fi))
                   (LocalVarID.Map.listItemsi spillScore)
val _ = Control.ps "---"
*)

(*
val _ = Control.ps " Constraint"
*)
(*
val _ = FormatByHand.puts "  constraint begin"
val t1 = Time.now ()
*)
        val interference = X86Constraint.constrain graph interference
(*
val t2 = Time.now ()
val _ = let open FormatByHand in
put (%`"  constraint end : "%pi""` (IntInf.toInt (Time.toMicroseconds (Time.-(t2,t1))))) end
val _ = let open FormatByHand in
putf (%`"numVertexes = "%pi""`) (Interference.numVertexes interference);
putf (%`"numVars = "%pi""`) (Interference.numVars interference)
end
*)

(*
val _ = Control.ps "--interference+constaint--"
val _ = Control.p (Interference.format_graph X86Asm.format_reg) interference
val _ = Control.ps "---"
*)

(*
val _ = Control.ps " Coloring"
*)
        val interference = coloring (interference, spillScore)
(*
val _ = Control.ps "--colored--"
val _ = Control.p (Interference.format_graph X86Asm.format_reg) interference
val _ = Control.ps "---"
*)

        val (spills, alloc) =
            Interference.foldVar
              (fn ({var=var, color=UNCOLORED, ...}, _) =>
                  raise Control.Bug "regalloc"
                | ({var={id, ty}, color=NEED_SPILL, slotId}, (spills, alloc)) =>
                  let
                    val fmt = X86Emit.formatOf ty
                    val dst = I.MEM (ty, I.SLOT {id=slotId, format=fmt})
                  in
                    (LocalVarID.Map.insert (spills, id, dst), alloc)
                  end
                | ({var={id, ty}, color=COLORED c, ...}, (spills, alloc)) =>
                  (spills, LocalVarID.Map.insert (alloc, id, c)))
              (LocalVarID.Map.empty, LocalVarID.Map.empty)
              interference

(*
val _ = Control.ps "--alloc--"
val _ = Control.pl (Control.f2 (I.format_id,X86Asm.format_reg)) (LocalVarID.Map.listItemsi alloc)
val _ = Control.pl (Control.f2 (I.format_id,I.format_dst)) (LocalVarID.Map.listItemsi spills)
val _ = Control.ps "--"
*)

      in
        if LocalVarID.Map.isEmpty spills
        then (graph, alloc)
        else
          let
(*
val _ = Control.ps " Substitute"
*)
            val graph =
                X86Subst.substitute
                  (fn {id,...}:I.var => LocalVarID.Map.find (spills, id))
                  graph
          in
            regallocLoop (graph, count - 0w1)
          end
      end
(*
      handle e =>
let open FormatByHand in puts "==REGALLOC ERROR==";
putf RTL.format_graph graph; raise e end
*)


  fun regalloc symbolEnv ({clusterId, frameBitmap, baseLabel, body,
                 preFrameSize, postFrameSize, loc}:I.cluster) =
      let
(*
val _ = Control.ps " Stabilize"
*)
(*
val _ = FormatByHand.puts "  stabilize begin"
val t1 = Time.now ()
*)
        val graph = RTLStabilize.stabilize body
(*
val t2 = Time.now ()
val _ = let open FormatByHand in
put (%`"  stabilize end : "%pi""` (IntInf.toInt (Time.toMicroseconds (Time.-(t2,t1))))) end
*)

val err = RTLTypeCheck.checkCluster {symbolEnv=symbolEnv, checkStability=true}
                                    {clusterId = clusterId,
                                     frameBitmap = frameBitmap,
                                     baseLabel = baseLabel,
                                     body = graph,
                                     preFrameSize=preFrameSize,
                                     postFrameSize=postFrameSize,
                                     loc = loc}
val _ = case err of
          nil => nil
        | _ => let open FormatByHand in puts "After Stabilize:";
               putf RTLTypeCheckError.format_errlist err end
(*
val _ =
let
val filename = "a-" ^ Control.prettyPrint (I.format_clusterId clusterId) ^ ".stab"
val f = TextIO.openOut filename
in
Control.ps ("write " ^ filename);
TextIO.output (f, Control.prettyPrint (I.format_graph graph));
TextIO.closeOut f
end
*)

(*
val _ = puts "== X86Stabilize:"
val _ = putfs (I.format_graph graph)
val _ = puts "=="
*)

(*
val _ = Control.ps " Split"
*)
(*
val _ = FormatByHand.puts "  split begin"
val t1 = Time.now ()
*)
        val graph = X86Constraint.split graph
(*
val t2 = Time.now ()
val _ = let open FormatByHand in
put (%`"  split end : "%pi""` (IntInf.toInt (Time.toMicroseconds (Time.-(t2,t1))))) end
*)

val err = RTLTypeCheck.checkCluster {symbolEnv=symbolEnv, checkStability=true}
                                    {clusterId = clusterId,
                                     frameBitmap = frameBitmap,
                                     baseLabel = baseLabel,
                                     body = graph,
                                     preFrameSize=preFrameSize,
                                     postFrameSize=postFrameSize,
                                     loc = loc}
val _ = case err of
          nil => nil
        | _ => let open FormatByHand in puts "After Split:";
               putf RTLTypeCheckError.format_errlist err end

(*
val _ =
let
val filename = "a-" ^ Control.prettyPrint (I.format_clusterId clusterId) ^ ".split"
val f = TextIO.openOut filename
in
Control.ps ("write " ^ filename);
TextIO.output (f, Control.prettyPrint (I.format_graph graph));
TextIO.closeOut f
end
*)

(*
val _ = puts "== X86Split:"
val _ = putfs (I.format_graph graph)
val _ = puts "=="
*)

        val (graph, alloc) = regallocLoop (graph, maxIterations)

val err = RTLTypeCheck.checkCluster {symbolEnv=symbolEnv, checkStability=true}
                                    {clusterId = clusterId,
                                     frameBitmap = frameBitmap,
                                     baseLabel = baseLabel,
                                     body = graph,
                                     preFrameSize=preFrameSize,
                                     postFrameSize=postFrameSize,
                                     loc = loc}
(*
val _ = case err of
          nil => nil
        | _ => (Control.ps "After Regalloc:";
                Control.p RTLTypeCheckError.format_errlist err)
val _ =
let
val filename = "a-" ^ Control.prettyPrint (I.format_clusterId clusterId) ^ ".reg"
val f = TextIO.openOut filename
in
Control.ps ("write " ^ filename);
TextIO.output (f, Control.prettyPrint (I.format_graph graph));
TextIO.closeOut f
end
*)

        val cluster = {clusterId = clusterId,
                       frameBitmap = frameBitmap,
                       baseLabel = baseLabel,
                       body = graph,
                       preFrameSize = preFrameSize,
                       postFrameSize = postFrameSize,
                       loc = loc} : I.cluster
      in
        (cluster, alloc)
      end

end
