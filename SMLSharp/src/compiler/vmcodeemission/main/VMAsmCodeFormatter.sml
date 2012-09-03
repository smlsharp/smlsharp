(**
 * pretty printer for the assembly code of VM.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: VMAsmCodeFormatter.sml,v 1.1 2007/11/19 06:00:02 katsu Exp $
 *)
structure VMAsmCodeFormatter =
struct

  fun assemblyCodeToString x =
      AssemblyCodeFormatter.programToString VMCodeFormatter.formatInsnList x

end
