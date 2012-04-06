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

  fun newLabel () = VarID.generate ()

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
        val newLabel = newLabel()
        val newLast = lastFn newLabel
        val newFirst = I.BEGIN {label=newLabel, align=1, loc=Loc.noloc}
        val preBlock = unzip (first, pre, nil, newLast)
        val graph = I.LabelMap.insert (graph, label, preBlock)
        val focus = {first=newFirst, pre=nil, post=post, last=last,
                     context={label=newLabel, graph=graph}} : focus
      in
        (focus, newLabel)
      end

(*
  fun insertLastAfter (focus as {post = nil,
                                 last = I.JUMP {destinations = [label], ...},
                                 ...} : focus,
                       lastFn) =
      (insertLast (focus, lastFn label), label)
*)
  fun insertLastAfter ({first,pre,post,last,context={label,graph}}, lastFn) =
      let
        val newLabel = newLabel ()
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

end
