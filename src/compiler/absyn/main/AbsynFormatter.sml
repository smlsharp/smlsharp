(**
 * a pretty printer for the raw symtax of core ML.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: AbsynFormatter.sml,v 1.10 2008/08/04 13:25:37 bochao Exp $
 *)
structure AbsynFormatter : ABSYN_FORMATTER =
struct

  fun unitParseResultToString res =
      Control.prettyPrint (Absyn.format_unitparseresult res)

  fun locToString loc = Control.prettyPrint (Loc.format_loc loc)

  fun decToString dec = Control.prettyPrint (Absyn.format_dec dec)

  fun expToString exp = Control.prettyPrint (Absyn.format_exp exp)

  fun topdecToString dec = Control.prettyPrint (Absyn.format_topdec dec)

  fun typebindToString ty = Control.prettyPrint (Absyn.format_typbind ty)

  fun tvarToString tvar = Control.prettyPrint (Absyn.format_tvar tvar)

  fun tyToString ty = Control.prettyPrint (Absyn.format_ty ty)

end
	
