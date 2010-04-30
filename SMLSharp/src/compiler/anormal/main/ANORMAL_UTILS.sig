(**
 * utilities for A-Normal form.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ANORMAL_UTILS.sig,v 1.4 2006/02/28 16:10:58 kiyoshiy Exp $
 *)

signature ANORMAL_UTILS = sig

  val getLocOfExp : ANormal.anexp -> Loc.loc

end
