structure X86AsmGen : RTLASMGEN =
struct

  structure Target = X86Asm

  fun formatter () =
      case #ossys (Control.targetInfo ()) of
        "darwin"  => {format_code = X86Asm.darwin_program,
                      format_nextDummy = X86Asm.darwin_nextDummy}
      | "linux"   => {format_code = X86Asm.att_program,
                      format_nextDummy = X86Asm.att_nextDummy}
      | "freebsd" => {format_code = X86Asm.att_program,
                      format_nextDummy = X86Asm.att_nextDummy}
      | "openbsd" => {format_code = X86Asm.att_program,
                      format_nextDummy = X86Asm.att_nextDummy}
      | "netbsd"  => {format_code = X86Asm.att_program,
                      format_nextDummy = X86Asm.att_nextDummy}
      | "mingw"   => {format_code = X86Asm.att_program,
                      format_nextDummy = X86Asm.att_nextDummy}
      | "cygwin"  => {format_code = X86Asm.att_program,
                      format_nextDummy = X86Asm.att_nextDummy}
      | x => raise Control.Bug ("unknown target os: " ^ x)
                   
  fun instructionFormatter () =
      case #ossys (Control.targetInfo ()) of
        "darwin"  => X86Asm.darwin_instruction
      | "linux"   => X86Asm.att_instruction
      | "freebsd" => X86Asm.att_instruction
      | "openbsd" => X86Asm.att_instruction
      | "netbsd"  => X86Asm.att_instruction
      | "mingw"   => X86Asm.att_instruction
      | "cygwin"  => X86Asm.att_instruction
      | x => raise Control.Bug ("unknown target os: " ^ x)
                   
  fun output formatter code =
      fn outFn => outFn (SMLFormat.prettyPrint nil (formatter code)) : unit

  (* code: X86Asm.program = X86Asm.instruction list *)
  (* 2012-9-30 ohori: a minor optimization, which has huge impruvement *)
  fun generate code =
      let
        val format_code = instructionFormatter ()
      in
        fn outFn =>
           List.app 
             (fn instruction => 
                 (outFn (SMLFormat.prettyPrint nil (format_code instruction));
                  outFn "\n")
             )
             code
      end

  fun generateTerminator ({toplevelLabel}:RTLBackendContext.context) =
      case toplevelLabel of
        RTLBackendContext.TOP_NONE => NONE
      | RTLBackendContext.TOP_MAIN => NONE
      | RTLBackendContext.TOP_SEQ {next,...} =>
        let
          val {format_nextDummy, ...} = formatter ()
        in
          SOME (output format_nextDummy [Target.DUMMY_NEXT_TOPLEVEL next])
        end

end
