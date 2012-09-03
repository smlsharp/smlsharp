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

  val maxIterations = 0w4

  local
    fun disturb (coloring, vars1, vars2) =
        RTLUtils.Var.fold
          (fn (var1, ()) =>
              RTLUtils.Var.fold
                (fn (var2, ()) =>
                    Coloring.disturb (coloring, var1, var2))
                ()
                vars2)
          ()
          vars1

    fun buildInterference coloring (node, {liveIn, liveOut}, ()) =
        let
          val {defs, uses} = RTLUtils.Var.defuse node
          val clobs = RTLUtils.Var.clobs node
          val liveIn_defs = RTLUtils.Var.setUnion (liveIn, defs)
          val liveOut_defs = RTLUtils.Var.setUnion (liveOut, defs)
          val allVars = RTLUtils.Var.setUnion (liveIn_defs, clobs)
        in
(*
let open TermFormat.FormatComb in
begin_ puts
       text "!! " $(RTLEdit.format_node node) newline
       text "use =" $(RTLUtils.Var.format_set uses) newline
       text "def =" $(RTLUtils.Var.format_set defs) newline
       text "clob=" $(RTLUtils.Var.format_set clobs) newline
       text "liveIn =" $(RTLUtils.Var.format_set liveIn) newline
       text "liveOut=" $(RTLUtils.Var.format_set liveOut)
end_ end;
*)
          (*
           *           <----- liveIn ----->
           *
           *  insn      |  |  |    |  |  |    vertical lines indicates
           *  +---------*--*--*-+  *  *  *    live ranges.
           *  |         : use : |  |  |  |
           *  | clob    :  :  : |  |  |  |
           *  | *  *    :  :  : |  |  |  |
           *  | |  |          : |  |  |  |
           *  | *  * :    :   : |  |  |  |
           *  |      :def :   : |  |  |  |
           *  +------*----*---:-+  *  *  *
           *         :    |   |    |  |  |
           *     (DEAD)
           *             <--- liveOut ---->
           *
           * Each var in use disturbs all vars in liveIn.
           * Each var in def disturbs all vars in (liveOut U def).
           * Each var in clob disturbs all vars in (liveIn U def U clob).
           *)
          disturb (coloring, uses, liveIn);
          disturb (coloring, defs, liveOut_defs);
          disturb (coloring, clobs, allVars)
        end
  in

  fun addInterference (coloring:Coloring.graph, graph) =
let
(*
val _ = print "liveness:\n"
*)
val x =
        (RTLLiveness.liveness graph)
(*
val _ = print "liveness fold:\n"
*)
in
      RTLLiveness.foldBackward
        (buildInterference coloring)
        ()
        x
end
(*
        (RTLLiveness.liveness graph)
*)

  end (* local *)

  fun maxSlot (NONE:RTL.slot option, slot2:RTL.slot) = SOME slot2
    | maxSlot (SOME {id=id1, format=fmt1}, {format=fmt2, ...}) =
      SOME ({id = id1,
             format = {size = Int.max (#size fmt1, #size fmt2),
                       align = Int.max (#align fmt1, #align fmt2),
                       tag = #tag fmt1}} : RTL.slot)

  fun makeSpillSlot spills =
      VarID.Map.map
        (fn vars =>
            RTLUtils.Var.fold
              (fn ({id, ty}, max) =>
                  maxSlot (max, {id = id, format = Emit.formatOf ty}))
              NONE
              vars)
        spills

  fun applySpillSubst spillSubst graph =
      let
(*
val _ = let open TermFormat.FormatComb in
          begin_ puts text "***** spill *****" newline
                 $(assocList (VarID.format_id, RTLUtils.Var.format_set)
                             (VarID.Map.listItemsi spillSubst)) newline
                 text "**************" end_ end
*)
        val subst = makeSpillSlot spillSubst
      in
        Subst.substitute
          (fn {id, ty} =>
              case VarID.Map.find (subst, id) of
                SOME (SOME slot) => SOME (R.MEM (ty, R.SLOT slot))
              | SOME NONE => raise Control.Bug "applySpillSubst"
              | NONE => NONE)
          graph
      end

  fun applyRegSubst (regSubst, regVarMap) graph =
      Subst.substitute
        (fn {id, ty} =>
            case VarID.Map.find (regSubst, id) of
              NONE => raise Control.Bug ("applyRegSubst " ^ VarID.toString id)
            | SOME regId => SOME (R.REG {id = Vector.sub (regVarMap, regId),
                                         ty = ty}))
        graph

  fun regallocLoop 0w0 regVarMap graph =
      raise Control.Bug "regallocLoop: too many loops"
    | regallocLoop count regVarMap origGraph =
      let
        val coloring = Coloring.newGraph ()
        val _ = Vector.appi (fn (regId,_) => Coloring.addReg (coloring, regId))
                            regVarMap

        val graph = Constraint.split origGraph
(*
val _ = if count = maxIterations
        then print "===========================================================================\n"
        else ()
val _ = print ("Iteration " ^ Word.fmt StringCvt.DEC count ^ "\n")
val n = VarID.Map.foldl
          (fn ((first, insns, last), n) => n + 2 + length insns)
          0
          graph
val z = VarID.Map.foldl
        (fn ((first, insns, last), z) =>
            let
              val {defs, uses} = RTLUtils.Var.defuseFirst first
              val clobs = RTLUtils.Var.clobsFirst first
              val z = RTLUtils.Var.setUnion (RTLUtils.Var.setUnion (RTLUtils.Var.setUnion (defs, uses), clobs), z)
              val z = foldl
                      (fn (insn, z) =>
                          let
                            val {defs, uses} = RTLUtils.Var.defuseInsn insn
                            val clobs = RTLUtils.Var.clobsInsn insn
                            val z = RTLUtils.Var.setUnion (RTLUtils.Var.setUnion (RTLUtils.Var.setUnion (defs, uses), clobs), z)
                          in
                            z
                          end)
                      z
                      insns
              val {defs, uses} = RTLUtils.Var.defuseLast last
              val clobs = RTLUtils.Var.clobsLast last
              val z = RTLUtils.Var.setUnion (RTLUtils.Var.setUnion (RTLUtils.Var.setUnion (defs, uses), clobs), z)
            in
              z
            end)
        RTLUtils.Var.emptySet
        graph
val _ = print (Int.toString n ^ " instructions, " ^ Int.toString (VarID.Set.numItems (RTLUtils.Var.toVarIDSet z)) ^ " variables\n")
*)
(*
val _ = let open TermFormat.FormatComb in
          begin_ puts
                 text "***** split *****" newline
                 $(RTL.format_graph graph) newline
                 text "**************" end_ end
*)
        val _ = addInterference (coloring, graph)
(*
val _ = print "constrain:\n"
*)
        val _ = Constraint.constrain graph coloring
(*
val _ = print "coloring:\n"
*)
        val {regSubst, spillSubst} = Coloring.coloring coloring
(*
val _ = print "coloring done:\n"
*)
      in
        if VarID.Map.isEmpty spillSubst
        then applyRegSubst (regSubst, regVarMap) graph
        else regallocLoop (count - 0w1) regVarMap
                          (applySpillSubst spillSubst origGraph)
      end

  fun regalloc program =
      let
        val registers =
            Vector.map (fn reg => (VarID.generate (), reg)) Constraint.registers
        val regVarMap =
            Vector.map #1 registers
        val allocMap =
            Vector.foldl
              (fn ((varId, reg), z) => VarID.Map.insert (z, varId, reg))
              VarID.Map.empty
              registers
        val program =
            RTLUtils.mapCluster
              (regallocLoop maxIterations regVarMap)
              program
      in
        (program, allocMap)
      end

end
