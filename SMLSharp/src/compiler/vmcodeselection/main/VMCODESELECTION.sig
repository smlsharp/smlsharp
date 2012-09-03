(**
 * VM instruction selection.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: VMCODESELECTION.sig,v 1.6 2008/01/23 08:20:07 katsu Exp $
 *)
signature VMCODESELECTION =
sig

  val select
      : Counters.stamp
        -> AbstractInstruction.program
        -> Counters.stamp
           * VMMnemonic.instruction list MachineLanguage.program

  val labelString
      : MachineLanguage.id -> string

end
