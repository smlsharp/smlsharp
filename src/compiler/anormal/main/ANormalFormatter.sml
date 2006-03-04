(**
 * Formatter of A-Normal form.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ANormalFormatter.sml,v 1.6 2006/02/28 16:10:58 kiyoshiy Exp $
 *)
structure ANormalFormatter  =
struct

    fun anexpToString exp = 
	Control.prettyPrint (ANormal.format_anexp exp)

end
