(**
 * pretty printer for the machine language of VM.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: VMCodeFormatter.sml,v 1.3 2008/01/23 08:20:07 katsu Exp $
 *)
structure VMCodeFormatter =
struct

  local
    structure FE = SMLFormat.FormatExpression

    val newline1 =
        FE.Indicator {space = true,
                      newline = SOME {priority = FE.Preferred(1)}}
        
    fun term s = FE.Term (size s, s)
  in

  fun formatInsn insn =
      [term (VMMnemonicFormatter.format insn)]

  fun formatInsnList insns =
      foldr (fn (x, z) =>
                formatInsn x @
                (case z of nil => z | _ => newline1 :: z))
            nil
            insns

  fun instructionToString x =
      MachineLanguageFormatter.instructionToString formatInsnList x

  fun programToString x =
      MachineLanguageFormatter.programToString formatInsnList x
(*
      handle VMMnemonicFormatter.Format x =>
             raise Control.Bug (Control.prettyPrint (VMMnemonic.format_instruction x))
*)

  end

end
