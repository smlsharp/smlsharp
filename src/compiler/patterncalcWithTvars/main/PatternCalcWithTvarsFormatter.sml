(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @version $Id: PatternCalcWithTvarsFormatter.sml,v 1.6 2006/02/18 04:59:25 ohori Exp $
 *)
structure PatternCalcWithTvarsFormatter : PATTERNCALCWITHTVARS_FORMATTER =
struct

    fun format_ptdeclWrap pdecl =  PatternCalcWithTvars.format_ptdecl pdecl
    and format_ptexpWrap ptexp =  PatternCalcWithTvars.format_ptexp ptexp
    and format_ptpatWrap ptpat =  PatternCalcWithTvars.format_ptpat  ptpat
    and format_ptstrdecWrap ptstrdec = PatternCalcWithTvars.format_ptstrdec ptstrdec
    and format_ptstrexpWrap ptstrexp = PatternCalcWithTvars.format_ptstrexp ptstrexp
    and format_ptsigexpWrap ptsigexp = PatternCalcWithTvars.format_ptsigexp ptsigexp
    and format_ptspecWrap ptspec = PatternCalcWithTvars.format_ptspec ptspec
    and format_pttopdecWrap pttopdec = PatternCalcWithTvars.format_pttopdec pttopdec

    fun pttopdecToString topdec = 
	Control.prettyPrint (format_pttopdecWrap topdec)

end
