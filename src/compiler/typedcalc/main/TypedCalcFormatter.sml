(**
 * Pretty printer of the typed pattern calculus.
 * @copyright (c) 2006, Tohoku University.
 * @author Atushi Ohori 
 * @author Liu Bochao
 * @version $Id: TypedCalcFormatter.sml,v 1.11 2006/02/28 16:11:07 kiyoshiy Exp $
 *)
structure TypedCalcFormatter : TYPEDCALC_FORMATTER =
struct

    fun tptopdecToString btvEnv dec =
        Control.prettyPrint (TypedCalc.format_tptopdecl nil dec)
    fun tpdecToString btvEnv dec =
        Control.prettyPrint (TypedCalc.format_tpdecl nil dec)
    fun tpexpToString btvEnv exp =
        Control.prettyPrint (TypedCalc.format_tpexp nil exp)
    fun tpmstrexpToString btvEnv strExp =
        Control.prettyPrint (TypedCalc.format_tpmstrexp nil strExp)
    fun tpmsigexpToString btvEnv sigExp =
	Control.prettyPrint (TypedCalc.format_tpmsigexp nil sigExp)

end
