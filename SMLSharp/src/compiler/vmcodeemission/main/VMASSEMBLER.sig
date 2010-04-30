(**
 * VM assembler.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: VMASSEMBLER.sig,v 1.1 2007/11/19 06:00:02 katsu Exp $
 *)
signature VM_ASSEMBLER =
sig

  val assemble
      : VMMnemonic.instruction list AssemblyCode.section
        -> AssemblyCode.assembledSection

end
