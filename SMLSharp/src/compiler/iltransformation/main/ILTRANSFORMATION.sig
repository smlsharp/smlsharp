(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @author Nguyen Huu-Duc
 * @version $Id: ILTRANSFORMATION.sig,v 1.3 2007/12/15 08:30:34 bochao Exp $
 *)
signature ILTRANSFORMATION = sig

  val transform : Counters.stamp -> 
                  ANormal.andecl list -> 
                  (Counters.stamp * IntermediateLanguage.moduleCode)

end
