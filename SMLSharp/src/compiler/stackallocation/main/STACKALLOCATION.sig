(**
 * Stack allcation.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: STACKALLOCATION.sig,v 1.2 2007/11/13 03:50:53 katsu Exp $
 *)
signature STACKALLOCATION =
sig

  val allocate
      : 'target MachineLanguage.program -> 'target MachineLanguage.program

end
