(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure RTLEdit : sig

  type focus

  datatype node =
      FIRST of RTL.first
    | MIDDLE of RTL.instruction
    | LAST of RTL.last

  val format_focus : focus SMLFormat.BasicFormatters.formatter
  val format_node : node SMLFormat.BasicFormatters.formatter

  val jump : RTL.label -> RTL.last

  (* create a graph *)
  val singletonFirst : RTL.first -> focus
  val singleton : RTL.instruction -> focus
  val singletonLast : RTL.last -> focus

  (* edit a graph *)
  val focusEnter : RTL.graph -> focus
  val focusExit : RTL.graph -> focus
  val focusFirst : RTL.graph * RTL.label -> focus
  val focusLast : RTL.graph * RTL.label -> focus
  val unfocus : focus -> RTL.graph
  val gotoLast : focus -> focus
  val atFirst : focus -> bool
  val atLast : focus -> bool
  val insertBefore : focus * RTL.instruction list -> focus
  val insertAfter : focus * RTL.instruction list -> focus
  val insertFirst : focus * RTL.first -> focus
  val insertLast : focus * RTL.last -> focus
  val makeLabelBefore : focus -> focus * RTL.label
  val makeLabelAfter : focus -> focus * RTL.label
  val insertLastBefore : focus * (RTL.label -> RTL.last) -> focus * RTL.label
  val insertLastAfter : focus * (RTL.label -> RTL.last) -> focus * RTL.label

  (* compose graphs *)
  val spliceBefore : focus * RTL.graph -> focus
  val spliceAfter : focus * RTL.graph -> focus
  val mergeGraph : RTL.graph * RTL.graph -> RTL.graph
  val spliceGraph : RTL.graph * RTL.graph -> RTL.graph
  val extend : (node -> RTL.graph) -> RTL.graph -> RTL.graph

  (* annotated graph for flow analysis *)
  type 'a annotatedGraph
  type 'a blockFocus
  val format_annotatedGraph :
      'a SMLFormat.BasicFormatters.formatter
      -> 'a annotatedGraph SMLFormat.BasicFormatters.formatter
  val annotate : RTL.graph * 'a -> 'a annotatedGraph
  val graph : 'a annotatedGraph -> RTL.graph
  val annotations: 'a annotatedGraph -> 'a RTL.LabelMap.map
  val map : ('a -> 'b) -> 'a annotatedGraph -> 'b annotatedGraph
  val fold : ('a blockFocus * 'b -> 'b) -> 'b -> 'a annotatedGraph -> 'b
  val rewrite : ('a blockFocus -> RTL.graph) -> 'a annotatedGraph -> RTL.graph
  val focusBlock : 'a annotatedGraph * RTL.label -> 'a blockFocus
  val unfocusBlock : 'a blockFocus -> 'a annotatedGraph
  val annotation : 'a blockFocus -> 'a
  val blockLabel : 'a blockFocus -> RTL.label
  val block : 'a blockFocus -> RTL.block
  val setAnnotation : 'a blockFocus * 'a -> 'a blockFocus
  val foldForward : (node * 'b -> 'b) -> 'b -> 'a blockFocus -> 'b
  val foldBackward : (node * 'b -> 'b) -> 'b -> 'a blockFocus -> 'b
  val rewriteForward :
      (node * 'a -> RTL.graph * 'a) -> 'a blockFocus -> RTL.graph
  val rewriteBackward :
      (node * 'a -> RTL.graph * 'a) -> 'a blockFocus -> RTL.graph




(*
  val foldBlockForward : (node * 'a -> 'a) -> 'a -> RTL.block -> 'a
  val foldBlockBackward : (node * 'a -> 'a) -> 'a -> RTL.block -> 'a
  val rewriteBlockForward :
      (node * 'a -> RTL.graph * 'a) -> 'a -> RTL.block -> RTL.graph * 'a
  val rewriteBlockBackward :
      (node * 'a -> RTL.graph * 'a) -> 'a -> RTL.block -> RTL.graph * 'a
*)


(*
  val newGraph : RTL.first -> focus
*)
(*
  val newBlock : RTL.graph * RTL.first -> focus
*)
(*
  val focusEnter : RTL.graph -> focus
  val focusExit : RTL.graph -> focus
  val replaceEnter : RTL.graph * RTL.first -> RTL.graph
*)
(*
  val moveNext : focus -> focus
  val movePrev : focus -> focus
  val nextNode : focus -> node
  val prevNode : focus -> node
*)
(*
  val current : focus -> c
  val moveNext : focus -> cursor
  val movePrev : focus -> cursor
  val succ : focus -> tail
  val pred : focus -> head
*)
(*
  val removeNextInsn : focus -> focus
  val removePrevInsn : focus -> focus
*)





(*
  val analyzeForward : (RTL.node * 'a -> 'a) -> 'a -> focus -> 'a
  val analyzeBackward : (RTL.node * 'a -> 'a) -> 'a -> focus -> 'a
*)
(*
  val analyzeForward : (node * 'a -> 'a) -> 'a -> focus -> 'a
  val analyzeBackward : (node * 'a -> 'a) -> 'a -> focus -> 'a
*)


(*
  val rewriteForward : (node * 'a -> RTL.graph * 'a)
                       -> (RTL.label -> 'a)
                       -> RTL.graph -> RTL.graph
  val rewriteBackward : (node * 'a -> RTL.graph * 'a)
                        -> (RTL.label -> 'a)
                       -> RTL.graph -> RTL.graph
*)

(*
  val accumulateForward : (node * 'a * 'b -> 'a * 'b)
                          -> 'a -> (RTL.label -> 'b)
                          -> RTL.graph -> 'a
  val accumulateBackward : (node * 'a * 'b -> 'a * 'b)
                          -> 'a -> (RTL.label -> 'b)
                          -> RTL.graph -> 'a
*)

end =
struct

  structure I = RTL

  type focus =
      {
        first: I.first,
        pre: I.instruction list,
        post: I.instruction list,
        last: I.last,
        context: {label: I.label, graph: I.graph}
      }

  datatype node =
      FIRST of RTL.first
    | MIDDLE of RTL.instruction
    | LAST of RTL.last

  local
    open SMLFormat.FormatExpression
    open SMLFormat.BasicFormatters
  in
  fun format_focus {first,pre,post,last,context={label,graph}} =
      I.format_label label @ format_string ":" @ [Newline] @
      I.format_first first @ [Newline] @
      format_list (fn x => I.format_instruction x @ [Newline], nil) (rev pre) @
      format_string "<<focus>>" @ [Newline] @
      format_list (fn x => I.format_instruction x @ [Newline], nil) post @
      I.format_last last @ [Newline] @
      I.format_graph graph
  end

  fun format_node (FIRST first) = I.format_first first
    | format_node (MIDDLE insn) = I.format_instruction insn
    | format_node (LAST last) = I.format_last last

  fun Bug prefix label =
      Control.Bug (prefix ^ ": " ^ Control.prettyPrint (I.format_label label))

  fun newLabel () = Counters.newLocalId ()

  fun firstLabel (I.BEGIN {label, ...}) = label
    | firstLabel (I.CODEENTRY {label, ...}) = label
    | firstLabel (I.HANDLERENTRY {label, ...}) = label
    | firstLabel I.ENTER = newLabel ()

  fun singletonFirst first =
      {first=first, pre=nil, post=nil, last=I.EXIT,
       context={label=firstLabel first, graph=I.emptyGraph}} : focus

  fun singleton insn =
      {first=I.ENTER, pre=[insn], post=nil, last=I.EXIT,
       context={label=newLabel (), graph=I.emptyGraph}} : focus

  fun singletonLast last =
      {first=I.ENTER, pre=nil, post=nil, last=last,
       context={label=newLabel (), graph=I.emptyGraph}} : focus

  fun focusFirst (graph, label) =
      case I.LabelMap.find (graph, label) of
        NONE => raise Bug "focusFirst: not found" label
      | SOME (block as (first,mid,last)) =>
        {first=first, pre=nil, post=mid, last=last,
         context={label=label, graph=graph}} : focus

  fun gotoLast ({first, pre, post, last, context}:focus) =
      {first=first, pre=foldl (op ::) pre post, post=nil, last=last,
       context=context} : focus

  fun focusLast (focus, label) =
      gotoLast (focusFirst (focus, label))

  fun unzip (first, pre, post, last) =
      (first, foldl (op ::) post pre, last) : I.block

  fun unfocus ({first,pre,post,last,context={label,graph}}:focus) =
      I.LabelMap.insert (graph, label, unzip (first,pre,post,last))

  fun decomposeFocus ({first,pre,post,last,context={label,graph}}:focus) =
      ({label=label, first=first, pre=pre}, {post=post, last=last},
       (#1 (I.LabelMap.remove (graph, label)) handle NotFound => graph))

  fun atFirst ({pre=nil,...}:focus) = true
    | atFirst _ = false

  fun atLast ({post=nil,...}:focus) = true
    | atLast _ = false

  fun moveNext ({first, pre, post=h::t, last, context}:focus) =
      {first=first, pre=h::pre, post=t, last=last, context=context} : focus
    | moveNext focus = focus

  fun movePrev ({first, pre=h::t, post, last, context}:focus) =
      {first=first, pre=t, post=h::post, last=last, context=context} : focus
    | movePrev focus = focus

  fun prevNode ({first, pre=h::t, ...}:focus) = MIDDLE h
    | prevNode ({first, pre=nil, ...}) = FIRST first

  fun nextNode ({post=h::t, last, ...}:focus) = MIDDLE h
    | nextNode ({post=nil, last, ...}) = LAST last

  fun insertBefore ({first, pre, post, last, context}:focus, insns) =
      {first=first, pre=foldl (op ::) pre insns, post=post, last=last,
       context=context} : focus

  fun insertAfter ({first, pre, post, last, context}:focus, insns) =
      {first=first, pre=pre, post=insns @ post, last=last,
       context=context} : focus

  fun insertLast ({first, pre, post, last=_, context}:focus, last) =
      {first=first, pre=pre, post=nil, last=last, context=context} : focus

  fun insertFirst (focus, first) =
      let
        val label = firstLabel first
        val (_, {post, last}, graph) = decomposeFocus focus
      in
        case I.LabelMap.find (graph, label) of
          SOME _ => raise Bug "insertFirst: already exist" label
        | NONE => {first=first, pre=nil, post=post, last=last,
                   context={label=label, graph=graph}} : focus
      end

  fun checkENTER_EXIT graph =
      I.LabelMap.foldli
        (fn (label, (first,_,last), (f,l)) =>
            let
              fun check s (l1, NONE) = SOME l1
                | check s (l1, SOME l2) =
                  raise Control.Bug 
                          ("doubled " ^ s ^ ": " ^
                           Control.prettyPrint (I.format_label l1) ^
                           " and " ^ Control.prettyPrint (I.format_label l2))
            in
              (case first of I.ENTER => check "ENTER" (label, f) | _ => f,
               case last of I.EXIT => check "EXIT" (label, l) | _ => l)
            end)
        (NONE, NONE)
        graph

  fun mergeGraph (graph1, graph2) =
      let
        val graph = I.LabelMap.unionWithi
                      (fn (l,_,_) => raise Bug "mergeGraph: doubled" l)
                      (graph1, graph2)
      in
        checkENTER_EXIT graph;
        graph
      end

  local
    exception Found of I.label * I.block
    fun find f (graph:I.graph) =
        (I.LabelMap.appi (fn x => if f x then raise Found x else ()) graph;
         NONE) handle Found x => SOME x
  in

  fun focusEnter graph =
      case find (fn (l,(I.ENTER,_,_)) => true | _ => false) graph of
        NONE => raise Control.Bug "focusEnter: no ENTER"
      | SOME (label, (first, mid, last)) =>
        {first=first, pre=nil, post=mid, last=last,
         context={label=label,graph=graph}} : focus

  fun focusExit graph =
      case find (fn (l,(_,_,I.EXIT)) => true | _ => false) graph of
        NONE => raise Control.Bug "focusExit: no EXIT"
      | SOME (label, (first, mid, last)) =>
        {first=first, pre=rev mid, post=nil, last=last,
         context={label=label,graph=graph}} : focus

  end (* local *)

  fun spliceHead ({label, first, pre}, graph) =
      case I.LabelMap.find (graph, label) of
        SOME _ => raise Bug "spliceHead: label already exist" label
      | NONE =>
        let
          val (_, {post, last}, graph) = decomposeFocus (focusEnter graph)
        in
          {first=first, pre=pre, post=post, last=last,
           context={label=label, graph=graph}} : focus
        end

  fun spliceTail (graph, {post, last}) =
      let
        val ({label, first, pre}, _, graph) = decomposeFocus (focusExit graph)
      in
        {first=first, pre=pre, post=post, last=last,
         context={label=label, graph=graph}} : focus
      end

  local
    fun mergeFocus ({first,pre,post,last,context={label,graph}}:focus, graph2) =
        {first=first, pre=pre, post=post, last=last,
         context={label=label, graph=mergeGraph (graph, graph2)}}:focus
  in

  fun spliceBefore (focus, graph2) =
      let
        val (head, tail, graph) = decomposeFocus focus
        val graph2 = unfocus (spliceHead (head, graph2))
        val focus = spliceTail (graph2, tail)
      in
        mergeFocus (focus, graph)
      end

  fun spliceAfter (focus, graph2) =
      let
        val (head, tail, graph) = decomposeFocus focus
        val graph2 = unfocus (spliceTail (graph2, tail))
        val focus = spliceHead (head, graph2)
      in
        mergeFocus (focus, graph)
      end

  end (* local *)

  fun spliceGraph (graph1, graph2) =
      let
        val (head, _, graph1) = decomposeFocus (focusExit graph1)
        val graph2 = unfocus (spliceHead (head, graph2))
      in
        mergeGraph (graph1, graph2)
      end

  fun insertLastBefore ({first,pre,post,last,context={label,graph}}:focus,
                        lastFn) =
      let
        val newLabel = Counters.newLocalId ()
        val newLast = lastFn newLabel
        val newFirst = I.BEGIN {label=newLabel, align=1, loc=Loc.noloc}
        val preBlock = unzip (first, pre, nil, newLast)
        val graph = I.LabelMap.insert (graph, label, preBlock)
        val focus = {first=newFirst, pre=nil, post=post, last=last,
                     context={label=newLabel, graph=graph}} : focus
      in
        (focus, newLabel)
      end

  fun insertLastAfter (focus as {post = nil,
                                 last = I.JUMP {destinations = [label], ...},
                                 ...} : focus,
                       lastFn) =
      (insertLast (focus, lastFn label), label)
    | insertLastAfter ({first,pre,post,last,context={label,graph}}, lastFn) =
      let
        val newLabel = Counters.newLocalId ()
        val newLast = lastFn newLabel
        val newFirst = I.BEGIN {label=newLabel, align=1, loc=Loc.noloc}
        val postBlock = unzip (newFirst, nil, post, last)
        val graph = I.LabelMap.insert (graph, newLabel, postBlock)
        val focus = {first=first, pre=pre, post=nil, last=newLast,
                     context={label=label, graph=graph}} : focus
      in
        (focus, newLabel)
      end

  fun jump label =
      I.JUMP {jumpTo = I.ABSADDR (I.LABEL label),
              destinations = [label]}

  fun makeLabelAfter focus =
      insertLastAfter (focus, jump)

  fun makeLabelBefore (focus as {first, pre=nil, context, ...}:focus) =
      (focus, #label context)
    | makeLabelBefore focus =
      insertLastBefore (focus, jump)


(*
  fun analyzeForward f z (focus as {first,pre,post,last,...}:focus) =
      let
        val z = case pre of
                  nil => f (FIRST first, z)
                | h::t => f (MIDDLE h, z)
        val z = foldl (fn (x,z) => f (MIDDLE x, z)) z post
      in
        f (LAST last, z)
      end

  fun analyzeBackward f z (focus as {first,pre,post,last,...}:focus) =
      let
        val z = case post of
                  nil => f (LAST last, z)
                | h::t => f (MIDDLE h, z)
        val z = foldl (fn (x,z) => f (MIDDLE x, z)) z pre
      in
        f (FIRST first, z)
      end
*)


  fun foldBlockForward f z (first, mid, last) =
      let
        val z = f (FIRST first, z)
        val z = foldl (fn (i,z) => f (MIDDLE i, z)) z mid
        val z = f (LAST last, z)
      in
        z
      end

  fun foldBlockBackward f z (first, mid, last) =
      let
        val z = f (LAST last, z)
        val z = foldr (fn (i,z) => f (MIDDLE i, z)) z mid
        val z = f (FIRST first, z)
      in
        z
      end

  fun rewriteBlockForward f z (first, mid, last) =
      let
        val (graph, z) = f (FIRST first, z)
        val (graph, z) =
            foldl (fn (i,(graph,z)) =>
                      let
                        val (g, z) = f (MIDDLE i, z)
                      in
                        (spliceGraph (graph, g), z)
                      end)
                  (graph, z)
                  mid
        val (g, z) = f (LAST last, z)
      in
        (spliceGraph (graph, g), z)
      end

  fun rewriteBlockBackward f z (first, mid, last) =
      let
        val (graph, z) = f (LAST last, z)
        val (graph, z) =
            foldr (fn (i,(graph,z)) =>
                      let
                        val (g, z) = f (MIDDLE i, z)
                      in
                        (spliceGraph (g, graph), z)
                      end)
                  (graph, z)
                  mid
        val (g, z) = f (FIRST first, z)
      in
        (spliceGraph (g, graph), z)
      end

  fun extend f graph =
      I.LabelMap.foldli
        (fn (label, block, graph) =>
            let
              val (g, _) = rewriteBlockForward (fn (n,z) => (f n, z)) () block
            in
              mergeGraph (graph, g)
            end)
        I.emptyGraph
        graph




  type 'a annotatedGraph = {ann:'a I.LabelMap.map, graph:I.graph}
  type 'a blockFocus = {label: I.label,
                        block: I.block,
                        graph: 'a annotatedGraph}

  local
    open SMLFormat.BasicFormatters
    open SMLFormat.FormatExpression
  in
  fun format_annotatedGraph fmt {ann, graph} =
      format_string "annotation: " @
      [StartOfIndent 2] @
      format_list (fn (x,y) => [Newline] @ I.format_label x @
                               format_string ": " @ [Guard (NONE, fmt y)],
                   nil)
                  (I.LabelMap.listItemsi ann) @
      [EndOfIndent, Newline] @ format_string "graph: " @
      [StartOfIndent 2, Newline] @ I.format_graph graph @ [EndOfIndent]
  end

  fun annotate (graph, ann) = {ann = I.LabelMap.map (fn _ => ann) graph,
                               graph = graph}
  fun graph {ann, graph} = graph
  fun annotations {ann, graph} = ann
  fun map f {ann, graph} = {ann = I.LabelMap.map f ann, graph = graph}
  fun fold f z (g as {ann, graph}) =
      I.LabelMap.foldli
        (fn (label, block, z) => f ({label=label, block=block, graph=g}, z))
        z graph
  fun rewrite f graph =
      fold (fn (focus, graph) => mergeGraph (graph, f focus))
           RTL.emptyGraph
           graph
  fun focusBlock (g as {ann, graph}, label) =
      case I.LabelMap.find (graph, label) of
        SOME block => {label=label, block=block, graph=g}
      | NONE => raise Bug "focusBlock: not found" label
  fun unfocusBlock {label, block, graph} = graph
  fun annotation {label, block, graph={ann,graph}} =
      case I.LabelMap.find (ann, label) of
        SOME x => x
      | NONE => raise Bug "annotation: not found" label
  fun blockLabel {label, block, graph} = label
  fun block {label, block, graph} = block
  fun setAnnotation ({label, block, graph={ann,graph}}, x) =
      {label=label, block=block, graph={ann=I.LabelMap.insert (ann, label, x),
                                        graph=graph}}

  fun foldForward f z {label, block=(first, mid, last), graph} =
      let
        val z = f (FIRST first, z)
        val z = foldl (fn (i,z) => f (MIDDLE i, z)) z mid
        val z = f (LAST last, z)
      in
        z
      end

  fun foldBackward f z {label, block=(first, mid, last), graph} =
      let
        val z = f (LAST last, z)
        val z = foldr (fn (i,z) => f (MIDDLE i, z)) z mid
        val z = f (FIRST first, z)
      in
        z
      end

  fun rewriteForward f (focus as {label, block=(first, mid, last), graph}) =
      let
        val z = annotation focus
        val (graph, z) = f (FIRST first, z)
        val (graph, z) =
            foldl (fn (i,(graph,z)) =>
                      let
                        val (g, z) = f (MIDDLE i, z)
                      in
                        (spliceGraph (graph, g), z)
                      end)
                  (graph, z)
                  mid
        val (g, z) = f (LAST last, z)
      in
        spliceGraph (graph, g)
      end

  fun rewriteBackward f (focus as {label, block=(first, mid, last), graph}) =
      let
        val z = annotation focus
        val (graph, z) = f (LAST last, z)
        val (graph, z) =
            foldr (fn (i,(graph,z)) =>
                      let
                        val (g, z) = f (MIDDLE i, z)
                      in
                        (spliceGraph (g, graph), z)
                      end)
                  (graph, z)
                  mid
        val (g, z) = f (FIRST first, z)
      in
        spliceGraph (g, graph)
      end






(*
  fun accumulateForward f z graph =





  fun accumulateBackward f z graph =









        I.LabelMap.empty
        graph


  fun extend f graph =
      rewriteForward (fn (node, ()) => (f node, ()))
                     (fn _ => ())
                     graph







  fun rewriteForward f initFn graph =
      I.LabelMap.foldli
        (fn (label, (first, mid, last), newGraph) =>
            let
              val z = initFn label
              val (graph, z) = f (FIRST first, z)
              val (graph, z) =
                  foldl (fn (insn, (graph, z)) =>
                            let
                              val (graph2, z) = f (MIDDLE insn, z)
                            in
                              (spliceGraph (graph, graph2), z)
                            end)
                        (graph, z)
                        mid
              val (graph2, z) = f (LAST last, z)
              val graph = spliceGraph (graph, graph2)
            in
              mergeGraph (newGraph, graph)
            end)
        I.LabelMap.empty
        graph

  fun rewriteBackward f initFn graph =
      I.LabelMap.foldli
        (fn (label, (first, mid, last), newGraph) =>
            let
              val z = initFn label
              val (graph, z) = f (LAST last, z)
              val (graph, z) =
                  foldr (fn (insn, (graph, z)) =>
                            let
                              val (graph2, z) = f (MIDDLE insn, z)
                            in
                              (spliceGraph (graph2, graph), z)
                            end)
                        (graph, z)
                        mid
              val (graph2, z) = f (FIRST first, z)
              val graph = spliceGraph (graph2, graph)
            in
              mergeGraph (newGraph, graph)
            end)
        I.LabelMap.empty
        graph

  fun extend f graph =
      rewriteForward (fn (node, ()) => (f node, ()))
                     (fn _ => ())
                     graph

*)



(*
  fun accumulateBackward f z initFn graph =
      I.LabelMap.foldli
        (fn (label, _, z) =>
            let
              val ansOut = initFn label
              val (z, ansOut) =
                  analyzeBackward
                    (fn (node, (z, ansOut)) => f (node, z, ansOut))
                    (z, ansOut)
                    (focusLast (graph, label))
            in
              z
            end)
        z
        graph

  fun accumulateForward f z initFn graph =
      I.LabelMap.foldli
        (fn (label, _, z) =>
            let
              val ansIn = initFn label
              val (z, ansIn) =
                  analyzeForward
                    (fn (node, (z, ansIn)) => f (node, z, ansIn))
                    (z, ansIn)
                    (focusFirst (graph, label))
            in
              z
            end)
        z
        graph
*)


end












(*
  fun extend f graph =
      I.LabelMap.foldli
        (fn (label, (first, mid, last), newGraph) =>
            let
              val srcFocus = {first=first, pre=nil, post=mid, last=last,
                              context={label=label, graph=graph}} : focus
              val graph = f (FIRST (first, srcFocus))
              fun loop (dstFocus, FIRST (_, srcFocus)) =
                  raise Control.Bug "extend"
                | loop (dstFocus, x as MIDDLE (_, srcFocus)) =
                  loop (spliceBefore (dstFocus, f x), moveNext srcFocus)
                | loop (dstFocus, x as LAST (_, srcFocus)) =
                  unfocus (spliceBefore (dstFocus, f x))
              val graph = loop (focusExit graph, moveNext srcFocus)
            in
              unionGraph (newGraph, graph)
            end)
        I.LabelMap.empty
        graph

  fun analyzeForward f z (focus as {first,pre,post,last,context}:focus) =
      let
        val z = case pre of
                  nil => f (FIRST (first, focus))
                | h::t => f (MIDDLE (h, {first=first, pre=h::pre, post=t,
                                         last=last, context=context}))




        val z = case pre of
                  nil => f (I.FIRST first, z)
                | h::t => f (I.INSN h, z)
        val z = foldl (fn (x,z) => f (I.INSN x, z)) z post
      in
        f (I.LAST last, z)
      end

  fun analyzeBackward f z (focus as {first,pre,post,last,...}:focus) =
      let
        val z = case post of
                  nil => f (I.LAST last, z)
                | h::t => f (I.INSN h, z)
        val z = foldl (fn (x,z) => f (I.INSN x, z)) z pre
      in
        f (I.FIRST first, z)
      end
*)



(*
fun checkENTER_EXIT graph =
    I.LabelMap.foldl
      (fn ((I.ENTER,_,_), (false,z)) => (true,z)
        | ((I.ENTER,_,_), (true,z)) =>
          raise Control.Bug "checkGraph: doubled ENTER"
        | ((_,_,I.EXIT), (z,false)) => (z, false)
        | ((_,_,I.EXIT), (z,true)) =>
          raise Control.Bug "checkGraph: doubled EXIT"
        | (_, z) => z)
      (false, false)
      graph

fun mergeGraph (graph1, graph2) =
    let
      val graph =
          I.LabelMap.unionWithi
            (fn (l,_,_) => raise Bug "unionGraph: doubled" l)
            (graph1, graph2)
    in
      checkENTER_EXIT graph;
      graph
    end
*)



(*
(*
  fun replaceEnter (graph, first) =
      let
        val {pre, post, last, context={label,graph}, ...} = focusEnter graph
        val graph = #1 (I.LabelMap.remove (graph, label))
        val newLabel = firstLabel first
      in
        I.LabelMap.insert (graph, newLabel, unzip (first, pre, post, last))
      end
*)

  fun unionGraph (graph1, graph2) =
      I.LabelMap.unionWithi
          (fn (l, _, _) =>
              raise Control.Bug ("unionGraph: doubled: "
                                 ^ Control.prettyPrint (I.format_label l)))
          (graph1, graph2)

(*
 * newLabel:       label:           newLabel:
 *   [ head' ]  ,   ENTER            [ head' ]
 *                    |      ====>       | <----
 *                 [ tail ]          [ tail ]
 *
 *                 graph G           graph G|(~label)
 *)
  fun spliceHead (newLabel, first, pre, graph) =
      let
        val ({post, last}, graph) = removeEnter graph
      in
        case I.LabelMap.find (graph, newLabel) of
          SOME _ => raise Control.Bug ("spliceHead: label already exist: "
                                       ^ LocalVarID.toString newLabel)
        | NONE => {first=first, pre=pre, post=post, last=last,
                   context={label=newLabel, graph=graph}} : focus
      end
(*
  fun spliceHead (newLabel, first, pre, graph) =
      let
        val {post, last, context={label,graph}, ...} = focusEnter graph
        val graph = #1 (I.LabelMap.remove (graph, label))
                    handle LibBase.NotFound => graph
      in
        case I.LabelMap.find (graph, label) of
          SOME _ => raise Control.Bug ("spliceHead: label already exist: "
                                       ^ LocalVarID.toString label)
        | NONE =>
          {first=first, pre=pre, post=post, last=last,
           context={label=label, graph=graph}} : focus
      end
*)


  (*
   *                label:            label:
   *   [ tail' ]  ,  [ head ]          [ head ]
   *                    |      ====>       | <-----
   *                   EXIT            [ tail' ]
   *
   *                 graph G           graph G
   *)
  fun spliceTail (graph, post, last) =
      let
        val {label, first, pre} = focusExit graph
      in
        {first=first, pre=pre, post=post, last=last,
         context={label=label, graph=graph}} : focus
      end

  (*
   *  label1:      label2:          label1:
   *   [ head ]  ,   ENTER           [ head ]
   *      |            |      ====>     |
   *     EXIT       [ tail ]         [ tail ]
   *
   *   graph G1     graph G2         graph (G1 U G2|(~label2))
   *)
  fun spliceGraph (graph1, graph2) =
      let
        val {first, pre, label} = focusExit graph1
        val graph2 = unfocus (spliceHead (label, first, pre, graph2))
      in
        unionGraph (graph1, graph2)
      end
*)


(*
  (*
   *  focus:        graph:
   *   [ head ]      ENTER           [ head ]
   *      | <---- ,    |       ====>    | <----
   *   [ tail ]     [ tail' ]        [ tail' ]
   *
   *   graph G      graph G'         graph (G U G')
   *)
  fun replaceLast (f as {first,pre,post,last,context={label,graph}}:focus, graph2) =
      let
(*
val _ = puts "== spliceLast"
val _ = putfs (I.format_focus f)
val _ = puts "--"
val _ = putfs (I.format_graph graph2)
*)
        val focus = spliceHead (label, first, pre, graph2)
(*
val _ = puts "== head"
val _ = putfs (I.format_focus focus)
*)
      in
(*
let
val f =
*)
        mergeGraph (focus, graph)
(*
in
puts "== spliceLast result";
putfs (I.format_focus f);
puts "==";
f
end
*)
      end
*)

(*
  fun mergeGraph ({first,pre,post,last,context={label,graph}}:focus, graph2) =
(*
      case I.LabelMap.find (graph2, label) of
        SOME _ =>
        raise Control.Bug ("mergeGraph: doubled " ^ LocalVarID.toString label)
      | NONE =>
*)
        {first=first, pre=pre, post=post, last=last,
         context={label=label, graph=unionGraph (graph, graph2)}} : focus
*)

(*

  fun spliceBefore (f as {first,pre,post,last,context={label,graph}}:focus, graph2) =
      let
(*
val _ = puts "== spliceBefore"
val _ = putfs (I.format_focus f)
val _ = puts "--"
val _ = putfs (I.format_graph graph2)
*)
        val graph2 = unfocus (spliceHead (label, first, pre, graph2))
(*
val _ = puts "== head"
val _ = putfs (I.format_graph graph2)
*)
        val focus = spliceTail (graph2, post, last)
(*
val _ = puts "== tail"
val _ = putfs (I.format_focus focus)
*)
        val graph = #1 (I.LabelMap.remove (graph, label))
                    handle LibBase.NotFound => graph
      in
(*
let
val f =
*)
        mergeGraph (focus, graph)
(*
in
puts "== spliceBefore result";
putfs (I.format_focus f);
puts "==";
f
end
*)
      end


  fun spliceAfter ({first,pre,post,last,context={label,graph}}:focus, graph2) =
      let
        val graph2 = unfocus (spliceTail (graph2, post, last))
        val focus = spliceHead (label, first, pre, graph2)
      in
        mergeGraph (focus, graph)
      end

*)


(*
  fun succ ({first, pre, post=h::t, last, context}:focus) =
      TAIL (h, {first=first, pre=h::pre, post=t, last=last, context=context})
    | succ (focus as {first, pre, post=nil, last, context}) =
      LAST (last, focus)

  fun pred ({first, pre=h::t, post, last, context}:focus) =
      HEAD (h, {first=first, pre=t, post=h::post, last=last, context=context})
    | pred (focus as {first, pre=nil, post, last, context}) =
      FIRST (first, focus)
*)



(*
  fun moveNext ({first, pre, post=h::t, last, context}:focus) =
      MIDDLE (h, {first=first, pre=h::pre, post=t, last=last, context=context})
    | moveNext ({first, pre, post as nil, last, context}) =
      LAST (last, {first=first, pre=pre, post=post, last=last, context=context})

  fun current (focus as {first, pre=nil, post, last, context}:focus) =
      FIRST (first, focus)
    | current (focus as {first, pre, post=h::t, last, context}:focus) =
      MIDDLE (h, {first=first, pre=h::pre, post=t, last=last, context=context})
    | moveNext ({first, pre, post as nil, last, context}) =
      LAST (last, {first=first, pre=pre, post=post, last=last, context=context})

  fun movePrev ({first, pre=h::t, post, last, context}:focus) =
      MIDDLE (h, {first=first, pre=t, post=h::post, last=last, context=context})
    | movePrev ({first, pre as nil, post, last, context}:focus) =
      FIRST (first, {first=first, pre=pre, post=post, last=last,
                     context=context})
*)


(*
  fun removeNextInsn ({first, pre, post=h::t, last, context}:focus) =
      {first=first, pre=pre, post=t, last=last, context=context} : focus
    | removeNextInsn focus = focus

  fun removePrevInsn ({first, pre=h::t, post, last, context}:focus) =
      {first=first, pre=t, post=post, last=last, context=context} : focus
    | removePrevInsn focus = focus
*)

(*
  val emptyGraph : unit -> focus
  val focusCluster : RTL.cluster -> clusterFocus
  val unfocusCluster : clusterFocus -> RTL.cluster
  val focusFirst : clusterFocus * RTL.label -> focus
  val focusLast : clusterFocus * RTL.label -> focus
*)
(*
  datatype cursor =
      FIRST of RTL.first * focus
    | MIDDLE of RTL.instruction * focus
    | LAST of RTL.last * focus
*)
(*
  datatype head =
      FIRST of RTL.first * focus
    | HEAD of RTL.instruction * focus

  datatype tail =
      LAST of RTL.last * focus
    | TAIL of RTL.instruction * focus
*)

(*
  datatype cursor =
      FIRST of RTL.first * focus
    | MIDDLE of RTL.instruction * focus
    | LAST of RTL.last * focus
*)




(*













  fun emptyGraph () =
      {first=I.ENTER, pre=nil, post=nil, last=I.EXIT,
       context={label=Counters.newLocalId (), graph=I.LabelMap.empty}}
      : focus






  type clusterFocus =
      {
        cluster: I.cluster
      }

  exception Found
  exception NotFound
  exception Unterminated

  type focus =
      {
        first: I.first,
        pre: I.instruction list,
        post: I.instruction list,
        last: I.last option,
        context: {label: I.label,
                  graph: I.graph,
                  cluster: I.cluster option}
      }

  fun emptyGraph () =
      {first=I.ENTER, pre=nil, post=nil, last=I.EXIT,
       context = {label = Counters.newLocalId (),
                  graph = I.LabelMap.empty,
                  cluster = NONE}}
      : focus

  fun focusCluster (cluster as {body, ...}:I.cluster) =
      {graph = body, cluster = cluster} : clusterFocus

  fun unfocusCluster ({graph, cluster={frameBitmap,body,preFrameAligned,loc}}
                      : clusterFocus) =
      {
        frameBitmap = frameBitmap,
        body = graph,
        preFrameAligned = preFrameAligned,
        loc = loc
      } : I.cluster

  fun emptyGraph cluster =
      {first = I.ENTER, pre = nil, post = nil, last = SOME I.EXIT,
       context = {label = Counters.newLocalId (),
                  focus = {graph = I.LabelMap.empty,
                           cluster = cluster}}}




  fun focusFirst (focus as {graph, cluster}:clusterFocus, label) =
      case I.LabelMap.find (graph, label) of
        NONE => raise NotFound
      | SOME (block as {body=(first,mid,last)}) =>
        {first=first, pre=nil, post=mid, last=SOME last,
         context={label=label, focus=focus}} : focus

  fun gotoLast ({first, pre, post, last, context}:focus) =
      {first=first, pre=foldl (op ::) pre post, post=nil, last=last,
       context=context} : focus

  fun focusLast (focus, label) =
      gotoLast (focusFirst (focus, label))

  fun unzip (first, pre, post, SOME last) =
      {body=(first, foldl (op ::) post pre, last)}
    | unzip _ = raise Unterminated

  fun unfocus (focus as {first, pre, post, last,
                         context={label, focus={graph,cluster}}} : focus) =
      {graph = I.LabelMap.insert (graph, label,
                                       unzip (first,pre,post,last)),
       cluster = cluster} : clusterFocus

  fun firstLabel (I.BEGIN {label, ...}) = label
    | firstLabel (I.CODEENTRY _) = Counters.newLocalId ()
    | firstLabel (I.HANDLERENTRY {label, ...}) = label

  fun addFirst (focus as {graph, cluster}:clusterFocus, first) =
      let
        val label = firstLabel first
      in
        case I.LabelMap.find (graph, label) of
          SOME _ => raise Found
        | NONE =>
          {first=first, pre=nil, post=nil, last=NONE,
           context={label=label, focus=focus}} : focus
      end

  fun atFirst ({pre=nil,...}:focus) = true
    | atFirst _ = false

  fun atLast ({post=nil,...}:focus) = true
    | atLast _ = false

  fun moveNext ({first, pre, post=h::t, last, context}:focus) =
      {first=first, pre=h::pre, post=t, last=last, context=context} : focus
    | moveNext focus = focus

  fun movePrev ({first, pre=h::t, post, last, context}:focus) =
      {first=first, pre=t, post=h::post, last=last, context=context} : focus
    | movePrev focus = focus

  fun prevNode ({first, pre=h::t, ...}:focus) = I.INSN h
    | prevNode ({first, pre=nil, ...}) = I.FIRST first

  fun tryNextNode ({post=h::t, last, ...}:focus) = SOME (I.INSN h)
    | tryNextNode ({post=nil, last=SOME last, ...}) = SOME (I.LAST last)
    | tryNextNode ({post=nil, last=NONE, ...}) = NONE

  fun nextNode focus =
      case tryNextNode focus of
        SOME x => x
      | NONE => raise Unterminated

  fun insertBefore ({first, pre, post, last, context}:focus, insns) =
      {first=first, pre=foldl (op ::) pre insns, post=post, last=last,
       context=context} : focus

  fun insertAfter ({first, pre, post, last, context}:focus, insns) =
      {first=first, pre=pre, post=insns @ post, last=last,
       context=context} : focus

  fun insertFirst ({first=_, pre, post, last, context}:focus, first) =
      {first=first, pre=nil, post=post, last=last, context=context} : focus

  fun insertLast ({first, pre, post, last=_, context}:focus, last) =
      {first=first, pre=pre, post=nil, last=SOME last, context=context} : focus

  fun removeNextInsn ({first, pre, post=h::t, last, context}:focus) =
      {first=first, pre=pre, post=t, last=last, context=context} : focus
    | removeNextInsn focus = focus

  fun removePrevInsn ({first, pre=h::t, post, last, context}:focus) =
      {first=first, pre=t, post=post, last=last, context=context} : focus
    | removePrevInsn focus = focus

  fun makeLabelAfter (focus as {first, pre=nil, post, last, context}:focus) =
      (focus, #label context)
    | makeLabelAfter ({first, pre, post, last,
                       context={label,focus={graph,cluster}}}) =
      let
        val newLabel = Counters.newLocalId ()
        val newLast = I.JUMP {jumpTo=I.CONST (I.LABEL label),
                              destinations = [label]}
        val newFirst = I.BEGIN {label=label, align=1, loc=Loc.noloc}
        val postBlock = unzip (newFirst, nil, post, last)
        val graph = I.LabelMap.insert (graph, newLabel, postBlock)
        val focus = {first=first, pre=pre, post=nil, last=SOME newLast,
                     context={label=label,
                              focus={graph=graph, cluster=cluster}}} : focus
      in
        (focus, label)
      end

  fun makeLabelBefore (focus as {first, pre=nil, post, last, context}:focus) =
      (focus, #label context)
    | makeLabelBefore ({first, pre, post, last,
                        context={label,focus={graph,cluster}}}) =
      let
        val newLabel = Counters.newLocalId ()
        val newLast = I.JUMP {jumpTo=I.CONST (I.LABEL label),
                              destinations = [label]}
        val newFirst = I.BEGIN {label=label, align=1, loc=Loc.noloc}
        val preBlock = unzip (first, pre, nil, SOME newLast)
        val graph = I.LabelMap.insert (graph, label, preBlock)
        val focus = {first=newFirst, pre=nil, post=post, last=last,
                     context={label=newLabel,
                              focus={graph=graph, cluster=cluster}}} : focus
      in
        (focus, label)
      end

  fun repeatForward f z focus =
      let
        val (focus, z) = f (focus, prevNode focus, z)
        fun loop (focus as {post=h::t,...}:focus, z) =
            let
              val (focus, z) = f (focus, I.INSN h, z)
            in
              loop (moveNext focus, z)
            end
          | loop (focus as {post=nil, last=SOME last, ...}, z) =
            f (focus, I.LAST last, z)
          | loop ({post=nil, last=NONE, ...}, z) = z
      in
        loop (focus, z)
      end

  fun repeatBackward f z (focus as {last, ...}:focus) =
      let
        val (focus, z) = case last of
                           SOME last => f (focus,
        val (focus, z) = f (focus, nextNode focus, z)



  fun analyzeForward f z focus =
      let
        val z = f (prevNode focus, z)
        fun loop (focus as {post=h::t, ...}:focus, z) =
            let
              val (focus, z) = f (focus, z)
            in
              loop (moveNext focus, z)
            end
          | loop (focus as {post=nil, last=SOME last, ...}, z) =
            f (I.LAST last, z)



            in


            in






  fun analyzeForward f g z focus =
      let
        val z = f (prevNode focus, z)
        fun loop (focus, z) =
            if atLast focus
            then case #last focus of







        fun loop (focus, z) =
            let
              val z = f (prevNode focus, z)
            in
              if atLast focus
              then case #last focus of
                     NONE => z
                   | SOME last => f (I.LAST last, z)
              else loop (moveNext




  fun analyzeForward f z focus =
      let
        fun loop (focus, z) =
            if atLast focus
            then case #last focus of
                   NONE => z
                 | SOME last => f (I.LAST last, z)
            else loop (moveNext focus, f (prevNode focus, z))
      in
        loop (focus, z)
      end

  fun analyzeBackward f z focus =
      let
        fun loop (focus, z) =
            let
              val z = f (nextNode focus, z)
            in
              if atFirst focus
              then f (I.FIRST (#first focus), z)
              else loop (movePrev focus, z)
            end
      in
        loop (focus, z)
      end



(*
structure RTLEdit : sig

  type clusterFocus
  type blockFocus
  type insnFocus
  exception UnclosedBlock
  exception Exist

  val focusCluster: RTL.cluster -> clusterFocus
  val unfocusCluster : clusterFocus -> RTL.cluster
  val focusBlock : clusterFocus * RTL.label -> blockFocus
  val unfocusBlock : blockFocus -> clusterFocus
  val focusFirst : blockFocus -> insnFocus
  val focusLast : blockFocus -> insnFocus
  val unfocus : insnFocus -> blockFocus

  val firstInsn : insnFocus -> RTL.first
  val lastInsn : insnFocus -> RTL.last option
  val moveFirst : insnFocus -> RTL.first * insnFocus
  val moveLast : insnFocus -> insnFocus * RTL.last
  val moveNext : insnFocus -> RTL.instruction option * insnFocus
  val movePrev : insnFocus -> insnFocus * RTL.instruction option

(*
  val firstInsn : insnFocus -> RTL.first option
  val prevInsn : insnFocus -> RTL.instruction option
  val nextInsn : insnFocus -> RTL.instruction option
  val lastInsn : insnFocus -> RTL.last option
  val moveNext : insnFocus -> insnFocus
  val movePrev : insnFocus -> insnFocus
*)
  val insertInsn : insnFocus * RTL.instruction list -> insnFocus
  val appendInsn : insnFocus * RTL.instruction list -> insnFocus
  val deleteNext : insnFocus -> insnFocus
  val deletePrev : insnFocus -> insnFocus

  val closeBlock : insnFocus * RTL.last -> blockFocus
  val newBlock : clusterFocus * RTL.first -> insnFocus
  val appendLabel : insnFocus * RTL.label * RTL.loc -> insnFocus

(*
  val truncateBlock : insnFocus * RTL.last -> insnFocus
  val newBlock : clusterFocus * RTL.first -> blockFocus
  val appendLabel : insnFocus * RTL.label -> insnFocus
*)


(*
  val foldBlocks : (blockFocus * 'a -> 'a) -> 'a -> clusterFocus -> 'a
*)

(*
  val insertLast : insnFocus * RTL.last * label -> insnFocus
*)

  val analyzeForward : (RTL.node * 'a -> 'a) -> 'a -> blockFocus -> 'a
  val analyzeBackward : (RTL.node * 'a -> 'a) -> 'a -> blockFocus -> 'a



end =
struct

  structure I = RTL

  type clusterFocus =
      {
        graph: I.block I.LabelMap.map,
        cluster: I.cluster
      }

  type blockFocus =
      {
        label: I.label,
        block: I.block,
        focus: clusterFocus
      }

  type insnFocus =
      {
        first: I.first,
        pre: I.instruction list,   (* reverse order *)
        post: I.instruction list,
        last: I.last option,
        focus: blockFocus
      }

  exception UnclosedBlock
  exception Exist

  fun focusCluster (cluster as {body, ...} : I.cluster) =
      {graph = body, cluster = cluster} : clusterFocus

  fun unfocusCluster ({graph, cluster} : clusterFocus) =
      {
        frameBitmap = #frameBitmap cluster,
        body = graph,
        preFrameAligned = #preFrameAligned cluster,
        loc = #loc cluster
      } : I.cluster

  fun focusBlock (focus as {graph, cluster} : clusterFocus, label) =
      case I.LabelMap.find (graph, label) of
        NONE => raise UnclosedBlock
      | SOME block =>
        {label = label, block = block, focus = focus} : blockFocus

  fun unfocusBlock ({label, block, focus={graph, cluster}} : blockFocus) =
      {
        graph = I.LabelMap.insert (graph, label, block),
        cluster = cluster
      } : clusterFocus

  fun focusFirst (focus as {block={body=(first,middle,last),...}, ...}
                  : blockFocus) =
      {first = first, pre = nil, post = middle, last = SOME last,
       focus = focus} : insnFocus

  fun focusLast (focus as {block={body=(first,middle,last),...}, ...}
                 : blockFocus) =
      {first = first, pre = rev middle, post = nil, last = SOME last,
       focus = focus} : insnFocus

  fun unfocus ({first, pre, post, last=SOME last, focus={label, block, focus}}
               : insnFocus) =
      {
        label = label,
        block = {body = (first, foldl (op ::) post pre, last)},
        focus = focus
      } : blockFocus
    | unfocus _ = raise Control.Bug "unfocus"

  fun firstInsn ({first, ...}:insnFocus) = first
  fun lastInsn ({last, ...}:insnFocus) = last

  fun moveFirst ({first, pre, post, last, focus} : insnFocus) =
      (first, {first=first, pre=nil, post=foldl (op ::) post pre,
               last=last, focus=focus} : insnFocus)

  fun moveLast ({first, pre, post, last as SOME l, focus} : insnFocus) =
      ({first=first, pre=foldl (op ::) pre post, post=nil,
        last=last, focus=focus} : insnFocus, l)
    | moveLast _ = raise UnclosedBlock

  fun moveNext ({first, pre, post=h::t, last, focus} : insnFocus) =
      (SOME h,
       {first=first, pre=pre, post=t, last=last, focus=focus} : insnFocus)
    | moveNext focus = (NONE, focus)

  fun movePrev ({first, pre=h::t, post, last, focus} : insnFocus) =
      ({first=first, pre=t, post=post, last=last, focus=focus} : insnFocus,
       SOME h)
    | movePrev focus = (focus, NONE)


(*
  fun firstInsn ({first, pre=nil, ...} : insnFocus) = SOME first
    | firstInsn _ = NONE
  fun lastInsn ({last, post=nil, ...} : insnFocus) = SOME last
    | lastInsn _ = NONE
  fun nextInsn ({post=h::_, ...} : insnFocus) = SOME h
    | nextInsn _ = NONE
  fun prevInsn ({pre=h::_, ...} : insnFocus) = SOME h
    | prevInsn _ = NONE
*)

  fun insertInsn ({first, pre, post, last, focus} : insnFocus, insns) =
      {first = first,
       pre = pre,
       post = insns @ post,
       last = last,
       focus = focus} : insnFocus

  fun appendInsn ({first, pre, post, last, focus} : insnFocus, insns) =
      {first = first,
       pre = foldl (op ::) pre insns,
       post = post,
       last = last,
       focus = focus} : insnFocus

(*
  fun moveNext ({first, pre, post=h::t, last, focus} : insnFocus) =
      {first=first, pre=h::pre, post=t, last=last, focus=focus} : insnFocus
    | moveNext focus = focus

  fun movePrev ({first, pre=h::t, post, last, focus} : insnFocus) =
      {first=first, pre=t, post=h::post, last=last, focus=focus} : insnFocus
    | movePrev focus = focus
*)

  fun deleteNext ({first, pre, post=h::t, last, focus} : insnFocus) =
      {first=first, pre=pre, post=t, last=last, focus=focus} : insnFocus
    | deleteNext focus = focus

  fun deletePrev ({first, pre=h::t, post, last, focus} : insnFocus) =
      {first=first, pre=t, post=post, last=last, focus=focus} : insnFocus
    | deletePrev focus = focus

  fun closeBlock ({first, pre, post, last=NONE, focus} : insnFocus, newLast) =
      unfocus {first = first, pre = pre, post = post,
               last = SOME newLast, focus = focus}
    | closeBlock _ = raise Exist

  fun firstLabel (I.BEGIN {label, ...}) = label
    | firstLabel (I.ENTRY _) = Counters.newLocalId ()
    | firstLabel (I.WITH_PROLOGUE (_, first)) = firstLabel first

  fun newBlock (focus as {graph, cluster} : clusterFocus, first) =
      let
        val label = firstLabel first
      in
        case I.LabelMap.find (graph, label) of
          SOME _ => raise Exist
        | NONE =>
          {
            first = first, pre = nil, post = nil, last = NONE,
            focus = {label = label,
                     block = {body = (first, nil, I.RET {uses=nil})},
                     focus = focus}
          } : insnFocus
      end

  fun appendLabel ({first, pre, post, last, focus} : insnFocus, label, loc) =
      let
        val focusPre = {first=first, pre=pre, post=nil,
                        last = SOME (I.JUMP {jumpTo = I.CONST (I.LABEL label),
                                             destinations = [label]}),
                        focus = focus}
        val focus = unfocus focusPre
        val focus = unfocusBlock focus
        val begin = I.BEGIN {label = label, align = 1, defs = nil, loc = loc}
        val lastInsn = case last of SOME x => x | NONE => I.RET {uses=nil}
      in
        {
          first = begin, pre = nil, post = post, last = last,
          focus = {label = label,
                   block = {body = (first, post, lastInsn)},
                   focus = focus} : blockFocus
        } : insnFocus
      end



(*
  fun truncateBlock ({first, pre, post, last, focus} : insnFocus, newLast) =
      {first=first, pre=pre, post=nil, last=newLast, focus=focus} : insnFocus


  fun firstLoc (I.BEGIN {loc, ...}) = loc
    | firstLoc (I.ENTRY {loc, ...}) = loc
    | firstLoc (I.WITH_PROLOGUE (_, first)) = firstLoc first
    | firstLoc I.ENTER = raise Control.Bug "firstLoc"

  fun beginBlock (focus as {graph, cluster} : clusterFocus, first, last) =
      let
        val label = firstLabel first
      in
        case I.LabelMap.find (graph, label) of
          SOME _ => raise Control.Bug "newBlock"
        | NONE =>
          {
            label = label,
            block = {body = (first, nil, I.RET {uses=nil})},
            focus = focus
          } : blockFocus
      end

  fun newBlock (focus, first) =
      beginBlock (focus, first, I.RET {uses=nil})

  fun appendLabel ({first, pre, post, last, focus} : insnFocus, label) =
      let
        val focusPre = {first=first, pre=pre, post=nil,
                        last = I.JUMP {jumpTo = I.CONST (I.LABEL label),
                                       destinations = [label]},
                        focus = focus}
        val focus = unfocus focusPre
        val focus = unfocusBlock focus
        val begin = I.BEGIN {label = label, align = 1, defs = nil,
                             loc = firstLoc first}
        val focus = beginBlock (focus, begin, last)
      in
        focusFirst focus
      end
*)


(*

  fun insertLast ({first, pre, post, last, focus} : insnFocus, last, label) =
      let
        val focusPre = {first=first, pre=pre, post=nil, last=last, focus=focus}
        val focus = unfocus focus
        val loc = #loc (#block focus)
        val focus = unfocusBlock focus

        val newBlock = {body = (begin, post, last), loc = loc}


        val focus = addBlock (focus, label,


                    blockFocus






  fun startBlock ({first, pre, post, last, focus} : insnFocus) =
      let
        val focusPre = {first=first, pre=pre, post=nil, last=jmp, focus=focus}
        val focus = unfocus focus




        val focusPost = {first=begin, pre=nil, post=post, last=last, focus=focus}



*)



(*
  fun foldBlocks f z (focus as {graph, ...}:clusterFocus) =
      I.LabelMap.foldli
        (fn (label, block, z) =>
            let
              val c = {label = label, block = block, focus = focus}
              val (c, z) = f (c, z)
              val
            in

        z
        graph
*)

  fun analyzeForward f z blockFocus =
      let
        val focus = focusFirst blockFocus
        val (first, focus) = moveFirst focus
        val z = f (I.FIRST first, z)
        fun loop ((SOME insn, focus), z) =
            loop (moveNext focus, f (I.INSN insn, z))
          | loop ((NONE, focus), z) =
            f (I.LAST (#2 (moveLast focus)), z)
      in
        loop (moveNext focus, z)
      end

  fun analyzeBackward f z blockFocus =
      let
        val focus = focusLast blockFocus
        val (focus, last) = moveLast focus
        val z = f (I.LAST last, z)
        fun loop ((focus, SOME insn), z) =
            loop (movePrev focus, f (I.INSN insn, z))
          | loop ((focus, NONE), z) =
            f (I.FIRST (#1 (moveFirst focus)), z)
      in
        loop (movePrev focus, z)
      end
*)


end
*)
