(**
 * Copyright (c) 2006, Tohoku University.
 *
 * a pretty printer for the record calclulus
 * 
 * @author Atsushi Ohori 
 * @version $Id: RecordCalcFormatter.sml,v 1.2 2006/02/18 04:59:26 ohori Exp $
 *)
structure RecordCalcFormatter =
struct

    fun rcdecToString btvenv dec = 
	Control.prettyPrint (RecordCalc.format_rcdecl nil dec)

end
