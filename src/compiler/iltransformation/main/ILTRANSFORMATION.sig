(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @author Nguyen Huu-Duc
 * @version $Id: ILTRANSFORMATION.sig,v 1.2 2007/04/18 09:00:43 ducnh Exp $
 *)
signature ILTRANSFORMATION = sig

  val transform : ANormal.andecl list -> IntermediateLanguage.moduleCode

end
