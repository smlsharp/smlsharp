(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

functor RTLColoring (
  structure Constraint : RTLCONSTRAINT
  structure Subst : RTLSUBST
  structure Emit : RTLEMIT
  sharing Constraint.Target = Emit.Target
) : RTLCOLORING =
struct

  structure R = RTL
  structure Target = Constraint.Target

  val maxIterations = 0w6

  local
    fun interfere (interference, set1, set2) =
        VarID.Set.foldl
          (fn (id1, interference) =>
              VarID.Set.foldl
                (fn (id2, i) => Interference.interfere (i, id1, id2))
                interference
                set2)
          interference
          set1

    fun add (setMap, id, v) =
        case VarID.Map.find (setMap, id) of
          NONE =>
          VarID.Map.insert (setMap, id, VarID.Set.singleton v)
        | SOME s =>
          VarID.Map.insert (setMap, id, VarID.Set.add (s, v))

    fun disturb (disturbance, disturber, disturbee) =
        VarID.Set.foldl
          (fn (live, disturbance) =>
              VarID.Set.foldl
                (fn (used, disturbance) =>
                    if VarID.eq (live, used) then disturbance
                    else add (disturbance, live, used))
                disturbance
                disturber)
          disturbance
          disturbee

    fun buildInterference (node, {liveIn, liveOut},
                           (interference, disturbance)) =
        let
          val {defs, uses} = RTLUtils.Var.defuse node
          val clobs = RTLUtils.Var.clobs node

          val defs = RTLUtils.Var.toVarIDSet defs
          val uses = RTLUtils.Var.toVarIDSet uses
          val clobs = RTLUtils.Var.toVarIDSet clobs
          val liveIn = RTLUtils.Var.toVarIDSet liveIn
          val liveOut = RTLUtils.Var.toVarIDSet liveOut

          val defs_clobs = VarID.Set.union (defs, clobs)
          val defs_uses_clobs = VarID.Set.union (defs_clobs, uses)
          val allvars = VarID.Set.union (defs_uses_clobs, liveOut)

          val interference =
              VarID.Set.foldl
                (fn (id, i) => Interference.addVar (i, id))
                interference
                allvars

          (* clobs never be spilled. *)
          val interference =
              VarID.Set.foldl
                (fn (id, i) => Interference.disallowSpill (i, id))
                interference
                clobs

          (* defs interfere with liveOut. *)
          (* clobs interfere with (liveOut U defs U uses U clobs). *)
          val interference = interfere (interference, defs, liveOut)
          val interference = interfere (interference, clobs, allvars)

          (* simple spill scoring algorithm based on COINS's algorithm. *)
          val disturbance = disturb (disturbance, defs_clobs, liveOut)
          val disturbance = disturb (disturbance, uses, liveIn)
        in
          (interference, disturbance)
        end
  in

  fun makeInterference graph =
      let
        val (interference, disturbance) =
            RTLLiveness.foldBackward
              buildInterference
              (Interference.empty, VarID.Map.empty)
              (RTLLiveness.liveness graph)

        val interference =
            VarID.Map.foldli
              (fn (id, set, graph) =>
                  Interference.setSpillScore
                    (graph, id, VarID.Set.numItems set))
              interference
              disturbance
      in
        interference
      end

  end (* local *)

  local
    fun varsNode node =
        let
          val {defs, uses} = RTLUtils.Var.defuse node
          val clobs = RTLUtils.Var.clobs node
        in
          RTLUtils.Var.setUnion (RTLUtils.Var.setUnion (defs, uses), clobs)
        end

    fun varsBlock (first, insns, last) =
        let
          val set1 = varsNode (RTLEdit.FIRST first)
          val set2 = varsNode (RTLEdit.LAST last)
        in
          foldl (fn (insn, set) =>
                    RTLUtils.Var.setUnion (varsNode (RTLEdit.MIDDLE insn), set))
                (RTLUtils.Var.setUnion (set1, set2))
                insns
        end              
  in

  fun allVarSet graph =
      VarID.Map.foldl
        (fn (block, set) =>
            RTLUtils.Var.setUnion (varsBlock block, set))
        RTLUtils.Var.emptySet
        graph

  end (* local *)

  fun composeSubst color =
      VarID.Map.map (fn i => Vector.sub (Constraint.registers, i - 1)) color

  fun applyColor (graph, color, regSubst) =
      Subst.substitute
        (fn {id, ty} =>
            case VarID.Map.find (color, id) of
              NONE => raise Control.Bug "applyColor"
            | SOME colorId =>
              SOME (R.REG {id = Vector.sub (regSubst, colorId - 1), ty = ty}))
        graph

  fun makeSlot (vars, spill) =
      let
        fun maxFormat (fmt1:RTL.format, fmt2:RTL.format) =
            {size = Int.max (#size fmt1, #size fmt2),
             align = Int.max (#align fmt1, #align fmt2),
             tag = #tag fmt1} : RTL.format
        val formats =
            RTLUtils.Var.fold
              (fn ({id, ty}, slots) =>
                  case VarID.Map.find (spill, id) of
                    NONE => slots
                  | SOME slotid =>
                    let
                      val fmt = Emit.formatOf ty
                      val fmt = case VarID.Map.find (slots, slotid) of
                                  NONE => fmt
                                | SOME fmt2 => maxFormat (fmt2, fmt)
                    in
                      VarID.Map.insert (slots, slotid, fmt)
                    end)
              VarID.Map.empty
              vars
      in
        VarID.Map.map
          (fn slotid =>
              case VarID.Map.find (formats, slotid) of
                NONE => raise Control.Bug "makeSlotFormat"
              | SOME fmt => {id = slotid, format = fmt})
          spill
      end

  fun applySpill (graph, spill) =
      Subst.substitute
        (fn {id, ty} =>
            case VarID.Map.find (spill, id) of
              NONE => NONE
            | SOME slot => SOME (R.MEM (ty, R.SLOT slot)))
        graph

  fun regallocLoop 0w0 graph =
      raise Control.Bug "regallocLoop: too many loops"
    | regallocLoop count origGraph =
      let
        val graph = Constraint.split origGraph
        val vars = allVarSet graph
        val interference = makeInterference graph
        val interference = Constraint.constrain graph interference

        val interference =
            if !Control.doRegisterCoalescing
            then interference
            else Interference.discardMoves interference

        val {spill, color} =
            Coloring.color {maxColorId = Vector.length Constraint.registers}
                           interference
        val spill = makeSlot (vars, spill)
      in
        if VarID.Map.isEmpty spill
        then (graph, color)
        else regallocLoop (count - 0w1) (applySpill (origGraph, spill))
      end

  fun regalloc program =
      let
        val regSubst =
            Vector.map (fn _ => VarID.generate ()) Constraint.registers
        val registerMap =
            Vector.foldli
              (fn (i, reg, map) =>
                  VarID.Map.insert (map, Vector.sub (regSubst, i), reg))
              VarID.Map.empty
              Constraint.registers
        val program =
            RTLUtils.mapCluster
              (fn graph =>
                  let
                    val (graph, color) = regallocLoop maxIterations graph
                  in
                    applyColor (graph, color, regSubst)
                  end)
              program
      in
        (program, registerMap)
      end

end
