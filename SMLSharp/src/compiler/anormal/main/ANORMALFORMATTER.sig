(**
 * formatter of A-Normal form.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ANORMALFORMATTER.sig,v 1.2 2007/04/19 05:06:52 ducnh Exp $
 *)
signature ANORMALFORMATTER =
sig

 val anexpToString : ANormal.anexp -> string
 val andeclToString : ANormal.andecl -> string

end
