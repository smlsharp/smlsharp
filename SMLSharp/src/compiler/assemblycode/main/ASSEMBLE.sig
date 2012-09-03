(**
 * General assembler.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: ASSEMBLE.sig,v 1.1 2007/11/19 06:00:02 katsu Exp $
 *)
signature ASSEMBLE =
sig

  val assemble
      : ('target AssemblyCode.section -> AssemblyCode.assembledSection)
        -> 'target AssemblyCode.program
        -> ObjectFile.objectFile

end
