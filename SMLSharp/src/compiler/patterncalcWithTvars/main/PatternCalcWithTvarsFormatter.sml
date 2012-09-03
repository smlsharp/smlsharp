(**
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: PatternCalcWithTvarsFormatter.sml,v 1.10 2008/08/05 14:43:59 bochao Exp $
 *)
structure PatternCalcWithTvarsFormatter : PATTERNCALCWITHTVARS_FORMATTER =
struct

    fun pttopdecToString topdec = 
	Control.prettyPrint (PatternCalcWithTvars.format_pttopdec topdec)

    fun ptdecToString dec = 
	Control.prettyPrint (PatternCalcWithTvars.format_ptdecl dec)

    fun ptexpToString exp = 
	Control.prettyPrint (PatternCalcWithTvars.format_ptexp exp)
end
