(**
 * Formatter of A-Normal form.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ANormalFormatter.sml,v 1.7 2007/04/19 05:06:52 ducnh Exp $
 *)
structure ANormalFormatter : ANORMALFORMATTER  =
struct

    fun anexpToString exp = Control.prettyPrint (ANormal.format_anexp exp)
    fun andeclToString decl = Control.prettyPrint (ANormal.format_andecl decl)

end
