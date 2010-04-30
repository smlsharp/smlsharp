(**
 * utilities for A-Normal form.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ANORMALUTILS.sig,v 1.2 2007/04/19 05:06:52 ducnh Exp $
 *)

signature ANORMALUTILS = sig

  val getLocOfExp : ANormal.anexp -> Loc.loc

  val getLocOfDecl : ANormal.andecl -> Loc.loc

end
