(**
 * pretty printer for the machine language.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: MachineLanguageFormatter.sml,v 1.2 2007/11/13 03:50:53 katsu Exp $
 *)
structure MachineLanguageFormatter =
struct

  fun instructionToString formatTarget (x : 'a MachineLanguage.instruction) =
      Control.prettyPrint (MachineLanguage.format_instruction formatTarget x)

  fun programToString formatTarget (x : 'a MachineLanguage.program) =
      Control.prettyPrint (MachineLanguage.format_program formatTarget x)

end
