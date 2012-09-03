(**
 * VM assembler.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: VMAssembler.sml,v 1.3 2008/01/23 08:20:07 katsu Exp $
 *)
structure VMAssembler : VM_ASSEMBLER =
struct

  structure VM = VMMnemonic
  structure A = AssemblyCode

  fun assemble {alignment, code} =
      let
        val (bytecode, labels, externs, locs) =
(
            VMMnemonicAssembler32LE.assemble code
            handle VMMnemonicAssembler32LE.LabelNotFound (VM.LABELREF x) =>
                   raise Control.Bug ("LabelNotFound: "^x)
                 | VMMnemonicAssembler32LE.LabelNotFound (VM.LOCALLABELREF x) =>
                   raise Control.Bug ("LabelNotFound: @"^Int.toString x)
                 | VMMnemonicAssembler32LE.LabelNotFound (VM.REL x) =>
                   raise Control.Bug ("LabelNotFound: REL")
                 | VMMnemonicAssembler32LE.LabelDoubled x =>
                   raise Control.Bug ("LabelDoubled: "^x)
                 | VMMnemonicAssembler32LE.Assemble x =>
                   raise Control.Bug
                           ("Assemble: "^
                            Control.prettyPrint (VMCodeFormatter.formatInsn x))
(*
                   raise Control.Bug
                           ("Assemble"^
                            Control.prettyPrint
                                (VMMnemonic.format_instruction x))
*)
)
(*
handle e =>
(
(*
 print (AbstractInstructionFormatter.programToString aicode ^ "\n");
*)
(*
 print (Control.prettyPrint (VMCodeFormatter.formatInsnList code)^"\n");
*)
 raise e
)
*)
        val symbols =
            SEnv.map Word32.fromInt labels

        val relocation =
            map
              (fn {offset, size, extern} =>
                  let
                    val (name, kind) =
                        case extern of
                          VM.INTERNALREF l => (l, A.LOCAL)
                        | VM.GLOBALREF l => (l, A.UNDEF)
                        | VM.EXTCODEREF l => (l, A.UNDEF)
                        | VM.EXTDATAREF l => (l, A.UNDEF)
                        | VM.FFREF l => (l, A.UNDEF)
                        | VM.PRIMREF l => (l, A.UNDEF)

                    val ty =
                        if size = 0w4 then A.ABS32
                        else raise Control.Bug "assemble: relocationType"
                  in
                    {
                      offset = Word32.fromInt offset,
                      symbolName = name,
                      relocType = ty,
                      relocKind = kind
                    } : A.relocation
                  end)
              externs
      in
        {
          content = bytecode,
          symbols = symbols,
          relocation = relocation,
          alignment = alignment,
          locs = locs
        } : A.assembledSection
      end

end
