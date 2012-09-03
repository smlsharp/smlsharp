(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc 
 * @version $Id: ANORMAL_TRANSLATOR.sig,v 1.6 2006/02/28 16:10:59 kiyoshiy Exp $
 *)
signature ANORMAL_TRANSLATOR = 
sig

  val translate : BUCCalc.bucdecl list -> ANormal.anexp

end
