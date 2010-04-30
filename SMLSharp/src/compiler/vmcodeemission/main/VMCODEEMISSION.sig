(**
 * VM code emission.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: VMCODEEMISSION.sig,v 1.3 2007/11/19 06:00:02 katsu Exp $
 *)
signature VMCODEEMISSION =
sig

  val emit
      : VMMnemonic.instruction list MachineLanguage.program ->
        VMMnemonic.instruction list AssemblyCode.program

end
