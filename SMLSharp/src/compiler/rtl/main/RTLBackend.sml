(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

functor RTLBackend (
  structure Select : RTLSELECT
  structure Stabilize : RTLSTABILIZE
  structure Coloring : RTLCOLORING
  structure Emit : RTLEMIT
  structure Frame : RTLFRAME
  structure AsmGen : RTLASMGEN
  structure Target : sig
    type reg
    type program
    type nextDummy
    val format_reg : reg TermFormat.formatter
    val format_program : program TermFormat.formatter
    val format_nextDummy : nextDummy TermFormat.formatter
  end
  sharing Emit = Frame.Emit
  sharing Target = Stabilize.Target
  sharing Target = Coloring.Target
  sharing Target = Emit.Target
  sharing Target = AsmGen.Target
) : sig

  val codegen :
      int option   (* compile unit stamp *)
      -> AbstractInstruction2.program
      -> {code: SessionTypes.asmOutput,
          nextDummy: SessionTypes.asmOutput option}

end =
struct

  structure R = RTL

  val output = TextIO.stdErr  (* for intermediate code and errors *)

  local
    open TermFormat.FormatComb

    fun formatVarIDMap format map =
        assocList (VarID.format_id, format) (VarID.Map.listItemsi map)
    fun formatClusterIDMap format map =
        assocList (ClusterID.format_id, format) (ClusterID.Map.listItemsi map)
  in

  fun formatRTLAndRegAlloc (program, regAlloc) =
      begin_
        text "-- regAlloc:" newline
        $(formatVarIDMap Target.format_reg regAlloc) newline
        text "-- program:" newline
        $(RTL.format_program program)
      end_

  fun formatRTLAndLayoutMap (program, layoutMap) =
      begin_
        text "-- layoutMap:" newline
        $(formatClusterIDMap Emit.format_frameLayout layoutMap) newline
        text "-- program:" newline
        $(RTL.format_program program)
      end_

  fun formatAsmCode {code, nextDummy} =
      begin_
        text "-- code:" newline
        $(Target.format_program code) newline
        text "-- nextDummy:" newline
        $(Target.format_nextDummy nextDummy)
      end_

  end (* local *)

  val phaseTitle = ref ""

  fun printCode flag formatter code =
      if !Control.switchTrace andalso !flag
      then (if !phaseTitle = "" then ()
            else TextIO.output (output, "=== " ^ !phaseTitle ^ ":\n");
            TextIO.output (output, Control.prettyPrint (formatter code));
            TextIO.output (output, "\n");
            TextIO.flushOut output)
      else ()

  fun typeCheck typecheck program =
      if not (!Control.checkType) then () else
      case typecheck program of
        nil => ()
      | err =>
        (TextIO.output (output, "Type Error at " ^ !phaseTitle ^ "\n");
         TextIO.output (output, Control.prettyPrint
                                  (RTLTypeCheckError.format_errlist err));
         TextIO.output (output, "\n");
         TextIO.flushOut output)

  fun doSelect unitStamp aicode =
      let
        val program = Select.select unitStamp aicode
      in
        printCode Control.printRTL RTL.format_program program;
        typeCheck (RTLTypeCheck.check {checkStability=false}) program;
        program
      end

  fun doStabilize program =
      let
        val program = Stabilize.stabilize program
      in
        printCode Control.printRTL RTL.format_program program;
        typeCheck (RTLTypeCheck.check {checkStability=true}) program;
        program
      end

  fun doRename program =
      let
        val program = RTLRename.rename program
      in
        printCode Control.printRTL RTL.format_program program;
        typeCheck (RTLTypeCheck.check {checkStability=true}) program;
        program
      end

  fun doRegisterAllocation program =
      let
        val (program, regAlloc) = Coloring.regalloc program
      in
        printCode Control.printRTL formatRTLAndRegAlloc (program, regAlloc);
        typeCheck (RTLTypeCheck.check {checkStability=true}) program;
        (program, regAlloc)
      end

  fun doFrameAllocation (program, regAlloc) =
      let
        val (program, layoutMap) = Frame.allocate program
      in
        printCode Control.printRTL formatRTLAndLayoutMap (program, layoutMap);
        typeCheck (RTLTypeCheck.check {checkStability=true}) program;
        (program, {regAlloc = regAlloc, layoutMap = layoutMap})
      end

  fun doEmit (program, env) =
      let
        val asmcode = Emit.emit env program
      in
        printCode Control.printRTL formatAsmCode asmcode;
        asmcode
      end

  fun doAsmGen code =
      AsmGen.generate code

  infix 9 ==>
  fun x ==> (title, f) =
      (phaseTitle := title; f x)

  fun codegen unitStamp aicode =
      aicode
      ==> ("RTL Selection", doSelect unitStamp)
      ==> ("RTL Stabilize", doStabilize)
      ==> ("RTL Rename", doRename)
      ==> ("RTL Register Allocation", doRegisterAllocation)
      ==> ("RTL Frame Allocation", doFrameAllocation)
      ==> ("RTL Emit", doEmit)
      ==> ("Assembly Code Generation", doAsmGen)

end
