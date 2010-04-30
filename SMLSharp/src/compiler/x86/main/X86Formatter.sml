(**
 * pretty printer for x86 code.
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)
structure X86Formatter =
struct

(*
  fun instructionToString x =
      Control.prettyPrint (X86Mnemonic.format_instruction x)
*)

  fun programToString x =
      Control.prettyPrint (X86Mnemonic.debug_program x)

end
