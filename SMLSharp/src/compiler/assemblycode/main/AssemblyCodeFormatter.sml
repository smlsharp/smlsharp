(**
 * pretty printer for the assembly code.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: AssemblyCodeFormatter.sml,v 1.1 2007/11/19 06:00:02 katsu Exp $
 *)
structure AssemblyCodeFormatter =
struct

  fun programToString formatter (x : 'target AssemblyCode.program) =
      Control.prettyPrint (AssemblyCode.format_program formatter x)

end
