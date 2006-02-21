(**
 * Copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ANormalFormatter.sml,v 1.5 2006/02/18 16:04:03 duchuu Exp $
 *)
structure ANormalFormatter  =
struct

    fun anexpToString exp = 
	Control.prettyPrint (ANormal.format_anexp exp)

end
