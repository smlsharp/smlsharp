(**
 * a pretty printer for the record calclulus.
 * 
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: RecordCalcFormatter.sml,v 1.3 2006/02/28 16:11:04 kiyoshiy Exp $
 *)
structure RecordCalcFormatter =
struct

    fun rcdecToString btvenv dec = 
	Control.prettyPrint (RecordCalc.format_rcdecl nil dec)

end
