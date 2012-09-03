(**
 * a pretty printer for the record calclulus.
 * 
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: RecordCalcFormatter.sml,v 1.4 2008/02/23 15:49:54 bochao Exp $
 *)
structure RecordCalcFormatter =
struct

    fun rcdecToString btvenv dec = 
	Control.prettyPrint (RecordCalc.format_rcdecl nil dec)
    fun topGroupToString group =
        Control.prettyPrint (RecordCalc.format_topBlock group)
end
