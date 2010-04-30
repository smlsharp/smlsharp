structure X86RTLBackend : sig

  val codegen :
      Counters.stamp
      -> int option   (* compile unit stamp *)
      -> AbstractInstruction2.program
      -> Counters.stamp * SessionTypes.asmOutput

end =
struct
(*
fun puts s = print (s ^ "\n")
fun putfs s = print (Control.prettyPrint s ^ "\n")
*)

  structure R = RTL

  fun codegenTopdecl symbolEnv topdecl =
      case topdecl of
        R.CLUSTER cluster =>
        let
(*
val _  = let
val filename = "a-" ^ Control.prettyPrint (R.format_clusterId (#clusterId cluster)) ^ ".sel"
val f = TextIO.openOut filename
in
Control.ps ("write " ^ filename);
TextIO.output (f, Control.prettyPrint (R.format_cluster cluster));
TextIO.closeOut f
end
*)
(*
        val {clusterId = clusterId,
             frameBitmap = frameBitmap,
             baseLabel = baseLabel,
             body = graph,
             preFrameSize = preFrameSize,
             postFrameSize = postFrameSize,
             loc = loc} = cluster
        val graph = X86Subst.substitute
                    (fn {id,ty} => SOME (R.MEM (ty, R.SLOT {id=id, format=X86Emit.formatOf ty})))
                    graph
        val cluster = {clusterId = clusterId,
                       frameBitmap = frameBitmap,
                       baseLabel = baseLabel,
                       body = graph,
                       preFrameSize = preFrameSize,
                       postFrameSize = postFrameSize,
                       loc = loc} : R.cluster

val err = RTLTypeCheck.checkCluster {symbolEnv=symbolEnv, checkStability=false}
                                    cluster
val _ = case err of
          nil => nil
        | _ => (Control.ps "After Subst:";
                Control.p RTLTypeCheckError.format_errlist err)
*)
(*
val _ =
let
val filename = "a-" ^ Control.prettyPrint (R.format_clusterId clusterId) ^ ".sub"
val f = TextIO.openOut filename
in
Control.ps ("write " ^ filename);
TextIO.output (f, Control.prettyPrint (R.format_cluster cluster));
TextIO.closeOut f
end
*)

(*
val _ = let open FormatByHand in puts "color begin";
        putf R.format_clusterId (#clusterId cluster);
        putf R.format_loc (#loc cluster) end
val t1 = Time.now ()
*)
          val (cluster, alloc) = X86Coloring.regalloc symbolEnv cluster
(*
handle e =>
let open FormatByHand in puts "==COLORING ERROR==";
putf R.format_cluster cluster; raise e end
val t2 = Time.now ()
val _ = let open FormatByHand in
put (%`"color end : "%pi""` (IntInf.toInt (Time.toMicroseconds (Time.-(t2,t1))))) end
*)


(*
val _ = puts "== X86Coloring:"
val _ = putfs (R.format_cluster cluster)
val _ = puts "=="
*)

          (*
           * Structure of Frame:
           *
           * addr
           *  | :          :
           *  | +----------+ [align 16]  -----------------------------
           *  | :PostFrame : (need to allocate)                ^
           *  | |          |                                   |
           *  | +==========+ [align 16]  preOffset = 0         |
           *  | | Frame    | (need to allocate)                | need to alloc
           *  | |          |                                   |
           *  | +==========+ [align 12/16] postOffset = 12     |
           *  | | infoaddr |                                   v
           *  | +----------+ 8/16 <---- ebp --------------------------
           *  | | push ebp |
           *  | +----------+ 4/16
           *  | | ret addr |
           *  | +==========+ [align 16] ---------------------------
           *  | | PreFrame | (allocated by caller)             ^
           *  | :          :                                   | preFrameSize
           *  | |          |                                   v
           *  | +----------+ [align 16] ---------------------------
           *  | :          :
           *  v
           *)

          fun sizeof ty = #size (X86Emit.formatOf ty)
          val maxAlign = sizeof (R.Generic 0)

(*
val _ = FormatByHand.puts "Frame"
*)
          val {cluster, slotIndex, frameSize} =
              RTLFrame.allocate
                {preOffset = 0w0,
                 postOffset = 0w12,
                 frameAlign = maxAlign,
                 wordSize = sizeof (R.Int32 R.U)}
                cluster
(*
handle e =>
let open FormatByHand in puts "==FRAME ERROR==";
putf R.format_cluster cluster; raise e end
*)

(*
val _ = puts "== RTLFrame:"
val _ = putfs (R.format_cluster cluster)
val _ = puts "=="
*)

          fun ceil (m, n) =
              (m + n - 1) - (m + n - 1) mod n
          val postFrameSize =
              ceil (12 + frameSize + #postFrameSize cluster, maxAlign)
              - (12 + frameSize)

          (*
           * addr
           *  | :           :
           *  | +-----------+     --------------------------- (aligned)
           *  | | POSTFRAME |                             ^
           *  | +-----------+     ------                  |
           *  | | frame     |       |                     | allocSize
           *  | +-----------+       | framePointerOffset  |
           *  | |frame info |       v                     v
           *  | +-----------+ %ebp --------------------------
           *  | | push ebp  |       ^                  |
           *  | +-----------+       | systemSpaceSize  |
           *  | |return addr|       v                  | preFrameOrigin
           *  | +-----------+ ---------- (aligned)     |
           *  | | PREFRAME  |   ^ preFrameSize         |
           *  | |           |   v                      v
           *  | +-----------+ -------------------------------
           *  v :           :
           *)

          val systemSpaceSize =
              sizeof (R.Ptr R.Void) + sizeof (R.Ptr R.Code)
          val preFrameOrigin =
              systemSpaceSize + #preFrameSize cluster
          val framePointerOffset =
              frameSize + sizeof (R.Ptr R.Void) (* frame info *)
          val allocSize =
              ceil (systemSpaceSize + framePointerOffset
                    + #postFrameSize cluster, maxAlign)
              - systemSpaceSize
          val postFrameOrigin =
              ~allocSize
          val slotIndex =
              LocalVarID.Map.map (fn i => i - framePointerOffset) slotIndex

(*
val _ = Control.ps ("frameSize = " ^ Int.toString frameSize)
val _ = Control.ps ("preFrameOrigin = " ^ Int.toString preFrameOrigin)
val _ = Control.ps ("framePointerOffset = " ^ Int.toString framePointerOffset)
val _ = Control.ps ("allocSize = " ^ Int.toString allocSize)
val _ = Control.ps ("postFrameOrigin = " ^ Int.toString postFrameOrigin)
val _ = Control.pl (Control.f2 (R.format_id, SMLFormat.BasicFormatters.format_int)) (LocalVarID.Map.listItemsi slotIndex)
*)

          val env =
              {
                regAlloc = alloc,
                slotIndex = slotIndex,
                preFrameOrigin = preFrameOrigin,
                postFrameOrigin = postFrameOrigin,
                frameAllocSize = allocSize
              } : X86Emit.env
        in
          (ClusterID.Map.singleton (#clusterId cluster, env),
           R.CLUSTER cluster)
        end
      | R.TOPLEVEL _ => (ClusterID.Map.empty, topdecl)
      | R.DATA _ => (ClusterID.Map.empty, topdecl)
      | R.BSS _ => (ClusterID.Map.empty, topdecl)
      | R.X86GET_PC_THUNK_BX _ => (ClusterID.Map.empty, topdecl)
      | R.EXTERN _ => (ClusterID.Map.empty, topdecl)

  fun codegenProgram symbolEnv topdecls =
      foldr (fn (topdecl, (env, topdecls)) =>
                let
                  val (env2, topdecl) = codegenTopdecl symbolEnv topdecl
                in
                  (ClusterID.Map.unionWith #2 (env, env2), topdecl::topdecls)
                end)
            (ClusterID.Map.empty, nil)
            topdecls

  fun asmgen program =
      let
        val formatFn =
            case #ossys (Control.targetInfo ()) of
              "darwin" => X86Asm.darwin_instruction
            | "linux" => X86Asm.att_instruction
            | "freebsd" => X86Asm.att_instruction
            | "openbsd" => X86Asm.att_instruction
            | "netbsd" => X86Asm.att_instruction
            | x => raise Control.Bug ("unknown target os: " ^ x)
        val asm = map (SMLFormat.prettyPrint nil o formatFn) program
      in
        fn outFn => app (fn s => (outFn s; outFn "\n")) asm
(*
        fn outFn => (SMLFormat.prettyPrint [SMLFormat.OutputFn outFn] format;
                     ())
*)
      end

  fun codegen stamp unitStamp aicode =
      let
        val _ = Counters.init stamp
(*
val _ =
let
fun left (s,n) = substring (s, size s - n, n)
fun pad0 (s,n) = if size s > n then s else left ("000" ^ s, n)
fun fmt3 i = pad0 (Int.fmt StringCvt.DEC i, 3)
val filename = "a-" ^ fmt3 (valOf unitStamp) ^ ".ai"
val f = TextIO.openOut filename
in
Control.ps ("write " ^ filename);
TextIO.output (f, Control.prettyPrint (AbstractInstruction2.format_program aicode));
TextIO.closeOut f
end
*)

(*
val _ = FormatByHand.puts "select begin"
val t1 = Time.now ()
*)
        val program = X86Select.select unitStamp aicode
(*
handle e =>
let open FormatByHand in puts "==SELECT ERROR==";
putf AbstractInstruction2.format_program aicode; raise e end
val t2 = Time.now ()
val _ = let open FormatByHand in
put (%`"select end : "%pi""` (IntInf.toInt (Time.toMicroseconds (Time.-(t2,t1))))) end
*)

val (symbolEnv, err) = RTLTypeCheck.check {checkStability=false} program
(*
val _ = FormatByHand.putf RTLTypeCheckError.format_errlist err
*)

(*
val _ = puts "== X86Select:"
val _ = putfs (R.format_program program)
val _ = puts "=="
*)
(*
val _ =
let
fun left (s,n) = substring (s, size s - n, n)
fun pad0 (s,n) = if size s > n then s else left ("000" ^ s, n)
fun fmt3 i = pad0 (Int.fmt StringCvt.DEC i, 3)
val filename = "a-" ^ fmt3 (valOf unitStamp) ^ ".sel"
val f = TextIO.openOut filename
in
Control.ps ("write " ^ filename);
TextIO.output (f, Control.prettyPrint (R.format_program program));
TextIO.closeOut f
end
*)
        val (env, program) = codegenProgram symbolEnv program
(*
val _ = FormatByHand.puts "emit begin"
val t1 = Time.now ()
*)
        val code = X86Emit.emit env program
(*
handle e =>
let open FormatByHand in puts "==EMIT ERROR==";
putf R.format_program program;
pmap ClusterID.Map.foldri ClusterID.format_id
     (pmap LocalVarID.Map.foldri LocalVarID.format_id
           X86Asm.format_reg o #regAlloc)
     env;
raise e end
val t2 = Time.now ()
val _ = let open FormatByHand in
put (%`"emit end : "%pi""` (IntInf.toInt (Time.toMicroseconds (Time.-(t2,t1))))) end
*)


        val asm = asmgen code

(*
val _ = Control.ps "==asm=="
val _ = Control.ps asm
val _ = Control.ps "=="
*)
      in
        (Counters.getCounterStamp(), asm)
      end

end
