(**
 * Copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc 
 * @version $Id: ANORMAL_TRANSLATOR.sig,v 1.5 2006/02/18 16:04:04 duchuu Exp $
 *)
signature ANORMAL_TRANSLATOR = 
sig

  val translate : BUCCalc.bucdecl list -> ANormal.anexp

end
