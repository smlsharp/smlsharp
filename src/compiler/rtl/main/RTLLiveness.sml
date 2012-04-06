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

  val foldBackwardSlot
      : (RTLEdit.node * livenessSlot * 'a -> 'a) -> 'a
        -> livenessSlot RTLEdit.annotatedGraph
        -> 'a

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
        val {defs, uses} = RTLUtils.Var.defuse node
      in
        RTLUtils.Var.setUnion (RTLUtils.Var.setMinus (liveSet, defs), uses)
      end

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
        RTLEdit.map (fn {answerIn,answerOut,...} =>
                        {liveIn=answerIn, liveOut=answerOut}) graph
      end


  fun passSlot (node, liveSet) =
      let
        val {defs, uses} = RTLUtils.Slot.defuse node
      in
        RTLUtils.Slot.setUnion (RTLUtils.Slot.setMinus (liveSet, defs), uses)
      end

  fun livenessSlot graph =
      let
        val graph = RTLUtils.analyzeFlowBackward
                      {init = RTLUtils.Slot.emptySet,
                       join = RTLUtils.Slot.setUnion,
                       pass = passSlot,
                       filterIn = fn (_,x) => x,
                       filterOut = fn (_,x) => x,
                       changed = fn {old,new} =>
                                    not (RTLUtils.Slot.setIsSubset (new,old))}
                      graph
      in
        RTLEdit.map (fn {answerIn,answerOut,...} =>
                        {liveIn=answerIn, liveOut=answerOut}) graph
      end

  fun foldBackwardSlot f z graph =
      RTLEdit.fold
        (fn (focus, z) =>
            let
              val {liveOut,...}:livenessSlot = RTLEdit.annotation focus
              val (_, z) =
                  RTLEdit.foldBackward
                    (fn (node, (liveOut, z)) =>
                        let
                          val liveIn = passSlot (node, liveOut)
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

end
