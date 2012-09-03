(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure RTLLiveness : sig

  type liveness = {liveIn: RTLUtils.Var.set, liveOut: RTLUtils.Var.set}
  type livenessSlot = {liveIn: RTLUtils.Slot.set, liveOut: RTLUtils.Slot.set}

  val liveness
      : RTL.graph -> liveness RTLEdit.annotatedGraph

  val foldBackward
      : (RTLEdit.node * liveness * 'a -> 'a) -> 'a
        -> liveness RTLEdit.annotatedGraph
        -> 'a

  val livenessSlot
      : RTL.graph -> livenessSlot RTLEdit.annotatedGraph

end
=
struct

  structure I = RTL

  type liveness = {liveIn: RTLUtils.Var.set, liveOut: RTLUtils.Var.set}
  type livenessSlot = {liveIn: RTLUtils.Slot.set, liveOut: RTLUtils.Slot.set}

  val union = RTLUtils.Var.setUnion
  val minus = RTLUtils.Var.setMinus

  fun pass (node, liveSet) =
      let
(*
val _ = Control.ps "--"
val _ = Control.p RTLEdit.format_node node
val _ = Control.p RTLUtils.Var.format_set liveSet
*)
        val {defs, uses} = RTLUtils.Var.defuse node
(*
val _ = Control.p RTLUtils.Var.format_set defs
val _ = Control.p RTLUtils.Var.format_set uses
val s = let
*)
      in
        RTLUtils.Var.setUnion (RTLUtils.Var.setMinus (liveSet, defs), uses)
      end
(*
val _ = Control.p RTLUtils.Var.format_set s
val _ = Control.ps "--"
in s end
*)

  fun foldBackward f z graph =
      RTLEdit.fold
        (fn (focus, z) =>
            let
              val {liveOut,...}:liveness = RTLEdit.annotation focus
              val (_, z) =
                  RTLEdit.foldBackward
                    (fn (node, (liveOut, z)) =>
                        let
                          val liveIn = pass (node, liveOut)
                          val z = f (node, {liveIn=liveIn, liveOut=liveOut}, z)
                        in
                          (liveIn, z)
                        end)
                    (liveOut, z)
                    focus
            in
              z
            end)
        z
        graph

(*
  fun defuseOfBlock (graph, label) =
      RTLEdit.analyzeForward
        (fn (node, {defSet, useSet}) =>
            let
              val {defs, uses} = RTLUtils.defuse node
              val useSet =
                  VarID.Map.foldli
                    (fn (id, var, useSet) =>
                        case VarID.Map.find (defSet, id) of
                          SOME _ => useSet
                        | NONE => VarID.Map.insert (useSet, id, var))
                    useSet uses
            in
              {useSet = useSet, defSet = union (defSet, defs)}
            end)
        {defSet = empty, useSet = empty}
        (RTLEdit.focusFirst (graph, label))

  fun liveness graph =
      let
        val {edges, exits} = RTLUtils.edges graph
        val blockInfo =
            I.LabelMap.mapi
              (fn (label, {preds, succs}) =>
                  {preds = preds,
                   succs = succs,
                   defuse = defuseOfBlock (graph, label)})
              edges

        fun loop (nil, result) = result
          | loop (label::workSet, result) =
            let
              val {preds, succs, defuse as {defSet, useSet}} =
                  I.LabelMap.lookup (blockInfo, label)
              val {liveIn, liveOut} =
                  case I.LabelMap.find (result, label) of
                    NONE => {liveIn = empty, liveOut = empty}
                  | SOME x => x
              fun liveInOf l = #liveIn (I.LabelMap.lookup (result, l))
              val newLiveOut =
                  foldl (fn (l, liveOut) => union (liveOut, liveInOf l))
                        empty succs
              val newLiveIn =
                  union (minus (newLiveOut, defSet), useSet)
              val workSet =
                  if isSubset (newLiveIn, liveIn)
                  then workSet
                  else preds @ workSet
              val result =
                  I.LabelMap.insert (result, label,
                                          {liveIn = newLiveIn,
                                           liveOut = newLiveOut})
            in
              loop (workSet, result)
            end
      in
        loop (exits, I.LabelMap.empty)
      end
*)

  fun liveness graph =
      let
        val graph = RTLUtils.analyzeFlowBackward
                      {init = RTLUtils.Var.emptySet,
                       join = RTLUtils.Var.setUnion,
                       pass = pass,
                       filterIn = fn (_,x) => x,
                       filterOut = fn (_,x) => x,
                       changed = fn {old,new} =>
                                    not (RTLUtils.Var.setIsSubset (new,old))}
                      graph
      in
(*
        Control.ps "== liveness";
        Control.p (RTLEdit.format_annotatedGraph (RTLUtils.format_answer RTLUtils.Var.format_set)) graph;
        Control.ps "==";
*)
        RTLEdit.map (fn {answerIn,answerOut,...} =>
                        {liveIn=answerIn, liveOut=answerOut}) graph
      end


  fun passSlot (node, liveSet) =
      let
(*
val _ = Control.ps "=="
val _ = Control.p RTLEdit.format_node node
val _ = Control.p RTLUtils.Slot.format_set liveSet
*)
        val {defs, uses} = RTLUtils.Slot.defuse node
(*
val x =let
*)
      in
        RTLUtils.Slot.setUnion (RTLUtils.Slot.setMinus (liveSet, defs), uses)
      end
(*
val _ = Control.p RTLUtils.Slot.format_set x
val _ = Control.ps "=="
in
x
end
*)

  fun livenessSlot graph =
      let
(*
val _ = Control.ps "====liveness begin===="
*)
        val graph = RTLUtils.analyzeFlowBackward
                      {init = RTLUtils.Slot.emptySet,
                       join = RTLUtils.Slot.setUnion,
                       pass = passSlot,
                       filterIn = fn (_,x) => x,
                       filterOut = fn (_,x) => x,
                       changed = fn {old,new} =>
                                    not (RTLUtils.Slot.setIsSubset (new,old))}
                      graph
(*
val _ = Control.ps "====liveness end===="
*)
      in
        RTLEdit.map (fn {answerIn,answerOut,...} =>
                        {liveIn=answerIn, liveOut=answerOut}) graph
      end

end
