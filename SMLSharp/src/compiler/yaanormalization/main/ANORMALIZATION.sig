(**
 * A-Normalization
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @author NGUYEN Huu-Duc
 * @version $Id: ANORMALIZATION.sig,v 1.3 2007/12/17 12:11:15 katsu Exp $
 *)
signature YAANORMALIZATION = sig

  val normalize
      : RBUCalc.rbudecl list -> YAANormal.topdecl list

end
