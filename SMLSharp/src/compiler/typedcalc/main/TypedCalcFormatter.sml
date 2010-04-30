(**
 * Pretty printer of the typed pattern calculus.
 * @copyright (c) 2006, Tohoku University.
 * @author Atushi Ohori 
 * @author Liu Bochao
 * @version $Id: TypedCalcFormatter.sml,v 1.15 2008/08/05 14:44:00 bochao Exp $
 *)
structure TypedCalcFormatter : TYPEDCALC_FORMATTER =
struct

    fun tpdecToString btvEnv dec =
        Control.prettyPrint (TypedCalc.format_tpdecl nil dec)
    fun tpexpToString btvEnv exp =
        Control.prettyPrint (TypedCalc.format_tpexp nil exp)
    fun tptopdecToString btvEnv dec =
        Control.prettyPrint (TypedCalc.format_tptopdecl nil dec)

end
