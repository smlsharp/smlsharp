(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure RTLDominate : sig

  val dominators : RTL.graph -> RTL.LabelSet.set RTL.LabelMap.map

  val loopHeaders : RTL.graph -> RTL.label list

end
=
struct

  fun intersectSets nil = RTL.LabelSet.empty
    | intersectSets (set::sets) = foldl RTL.LabelSet.intersection set sets

  fun loop edges dom =
      let
        val finished = ref true
        val dom =
            RTL.LabelMap.foldli
              (fn (label, {preds, succs}, dom) =>
                  let
                    val old =
                        case RTL.LabelMap.find (dom, label) of
                          NONE => raise Control.Bug "RTLDominate.loop"
                        | SOME set => set
                    val sets =
                        map (fn l =>
                                case RTL.LabelMap.find (dom, l) of
                                  NONE => raise Control.Bug "RTLDominate.loop"
                                | SOME set => set)
                            preds
                    val set = intersectSets sets
                    val new = RTL.LabelSet.add (set, label)
                  in
                    if RTL.LabelSet.isSubset (old, new)
                    then dom
                    else (finished := false;
                          RTL.LabelMap.insert (dom, label, new))
                  end)
              dom
              edges
      in
        if !finished then dom else loop edges dom
      end

  fun dominatorsEdges edges =
      let
        val allNodes = RTL.LabelSet.fromList (RTL.LabelMap.listKeys edges)
        val dom = RTL.LabelMap.mapi
                    (fn (label, {preds=nil,...}) => RTL.LabelSet.singleton label
                      | _ => allNodes)
                    edges
      in
        loop edges dom
      end

  fun dominators graph =
      dominatorsEdges (RTLEdit.annotations (RTLUtils.edges graph))

  fun loopHeaders graph =
      let
        val edges = RTLEdit.annotations (RTLUtils.edges graph)
        val doms = dominatorsEdges edges
      in
        RTL.LabelMap.foldri
          (fn (label, {preds,...}, heads) =>
              if List.exists
                   (fn l => case RTL.LabelMap.find (doms, l) of
                              NONE => raise Control.Bug "loopHeaders"
                            | SOME set => RTL.LabelSet.member (set, label))
                   preds
              then label :: heads
              else heads)
          nil
          edges
      end

end
