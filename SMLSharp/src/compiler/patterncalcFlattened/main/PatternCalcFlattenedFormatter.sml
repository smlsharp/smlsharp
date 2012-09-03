(**
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: PatternCalcFlattenedFormatter.sml,v 1.4 2008/08/05 14:43:59 bochao Exp $
 *)
structure PatternCalcFlattenedFormatter : PATTERNCALCFLATTENED_FORMATTER =
struct
    open PatternCalcFlattened

    fun format_pdfeclWrap pdfecl =  
        format_pdfdecl ([format_plfexpWrap],[format_plfpatWrap]) pdfecl
    and format_plfexpWrap plfexp =  
        format_plfexp ([format_plfexpWrap],[format_plfpatWrap]) plfexp
    and format_plfpatWrap plfpat =  
        format_plfpat ([format_plfexpWrap],[format_plfpatWrap]) plfpat
    and format_plfspecWrap plfspec =
        format_plfspec ([format_plfexpWrap],[format_plfpatWrap]) plfspec
    and format_plftopdecWrap plftopdec = 
        format_plftopdec ([format_plfexpWrap],[format_plfpatWrap]) 
                         plftopdec
    fun plfpatToString pat = Control.prettyPrint (format_plfpatWrap pat)
    fun plfdecToString dec = Control.prettyPrint (format_pdfeclWrap dec)
    fun plftopdecToString topdec = 
	Control.prettyPrint (format_plftopdecWrap topdec)
end
