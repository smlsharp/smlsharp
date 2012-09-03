(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: BUCCalcFormatter.sml,v 1.5 2006/02/28 16:11:00 kiyoshiy Exp $
 *)
structure BUCCalcFormatter =
struct

    fun bucdeclToString btvenv decl = 
	Control.prettyPrint (BUCCalc.format_bucdecl nil decl)

end
