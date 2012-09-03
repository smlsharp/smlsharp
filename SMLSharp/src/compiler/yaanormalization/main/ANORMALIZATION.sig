(**
 * A-Normalization
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @author NGUYEN Huu-Duc
 * @version $Id: ANORMALIZATION.sig,v 1.3 2007/12/17 12:11:15 katsu Exp $
 *)
signature YAANORMALIZATION = sig

  val normalize
      : Counters.stamp
        -> RBUCalc.rbudecl list
        -> Counters.stamp * YAANormal.topdecl list

end
