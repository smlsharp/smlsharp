(**
 * A-Normal Optimization
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @author NGUYEN Huu-Duc
 * @version $Id: ANORMALOPTIMIZATION.sig,v 1.1 2007/09/24 22:28:40 katsu Exp $
 *)
signature YAANORMALOPTIMIZATION = sig

  val optimize : YAANormal.topdecl list -> YAANormal.topdecl list

end
