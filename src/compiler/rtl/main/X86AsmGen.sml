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
                   
  fun output formatter code =
      fn outFn => outFn (SMLFormat.prettyPrint nil (formatter code)) : unit

  fun generate code =
      let
        val {format_code, ...} = formatter ()
      in
        output format_code code
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
