(**
 * Copyright (c) 2006, Tohoku University.
 *
 * a pretty printer for the raw symtax of core ML
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: AbsynFormatter.sml,v 1.5 2006/02/18 04:59:15 ohori Exp $
 *)
structure AbsynFormatter : ABSYN_FORMATTER =
struct

  (***************************************************************************)

  fun parseResultToString res =
      Control.prettyPrint (Absyn.format_parseresult res)

  fun locToString loc = Control.prettyPrint (Loc.format_loc loc)

  fun decToString dec = Control.prettyPrint (Absyn.format_dec dec)

  fun expToString exp = Control.prettyPrint (Absyn.format_exp exp)

  fun topdecToString dec = Control.prettyPrint (Absyn.format_topdec dec)
  (***************************************************************************)

end
	
