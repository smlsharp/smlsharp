(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: PatternCalcFormatter.sml,v 1.10 2008/08/05 14:43:59 bochao Exp $
 *)
structure PatternCalcFormatter : PATTERNCALC_FORMATTER =
struct

    fun format_pdeclWrap pdecl =  PatternCalc.format_pdecl ([format_plexpWrap],[format_plpatWrap]) pdecl
    and format_plexpWrap plexp =  PatternCalc.format_plexp ([format_plexpWrap],[format_plpatWrap]) plexp
    and format_plpatWrap plpat =  PatternCalc.format_plpat ([format_plexpWrap],[format_plpatWrap]) plpat
    and format_plstrdecWrap plstrdec = PatternCalc.format_plstrdec ([format_plexpWrap],[format_plpatWrap]) plstrdec
    and format_plstrexpWrap plstrexp = PatternCalc.format_plstrexp ([format_plexpWrap],[format_plpatWrap]) plstrexp
    and format_plsigexpWrap plsigexp = PatternCalc.format_plsigexp ([format_plexpWrap],[format_plpatWrap]) plsigexp

    and format_plspecWrap plspec = PatternCalc.format_plspec ([format_plexpWrap],[format_plpatWrap]) plspec
    and format_pltopdecWrap pltopdec = PatternCalc.format_pltopdec ([format_plexpWrap],[format_plpatWrap]) pltopdec
    fun plpatToString pat = Control.prettyPrint (format_plpatWrap pat)
    fun pldecToString dec = Control.prettyPrint (format_pdeclWrap dec)
    fun pltopdecToString topdec = 
	Control.prettyPrint (format_pltopdecWrap topdec)

end
