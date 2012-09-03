(**
 * Formatter of A-Normal form
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @author NGUYEN Huu-Duc
 * @version $Id: ANormalFormatter.sml,v 1.1 2007/09/24 22:28:40 katsu Exp $
 *)
structure YAANormalFormatter =
struct

    fun anexpToString exp =
        Control.prettyPrint (YAANormal.format_anexp exp)

    fun andeclToString decl =
        Control.prettyPrint (YAANormal.format_andecl decl)

    fun topdeclToString cluster =
        Control.prettyPrint (YAANormal.format_topdecl cluster)

end
