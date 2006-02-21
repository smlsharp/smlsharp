(**
 * Copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: BUCCalcFormatter.sml,v 1.4 2006/02/18 16:04:05 duchuu Exp $
 *)
structure BUCCalcFormatter =
struct

    fun bucdeclToString btvenv decl = 
	Control.prettyPrint (BUCCalc.format_bucdecl nil decl)

end
