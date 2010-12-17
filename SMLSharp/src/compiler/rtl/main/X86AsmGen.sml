structure X86AsmGen : RTLASMGEN =
struct

  structure Target = X86Asm

  fun generate {code, nextDummy} =
      let
        val {format_code, format_nextDummy} =
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
            fn outFn =>
               outFn (SMLFormat.prettyPrint nil (formatter code)) : unit

        val nextDummyOut =
            case nextDummy of
              nil => NONE
            | _::_ => SOME (output format_nextDummy nextDummy)
      in
        {code = output format_code code, nextDummy = nextDummyOut}
      end

end
