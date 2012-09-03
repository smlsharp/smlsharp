(**
 * Pretty printer of the typed pattern calculus.
 * @copyright (c) 2006, Tohoku University.
 * @author Atushi Ohori 
 * @author Liu Bochao
 * @version $Id: TypedCalcFormatter.sml,v 1.12 2006/03/14 01:38:11 bochao Exp $
 *)
structure TypedCalcFormatter : TYPEDCALC_FORMATTER =
struct

    fun tptopdecToString btvEnv dec =
        Control.prettyPrint (TypedCalc.format_tptopdecl nil dec)
    fun tptpmstrdeclToString btvEnv dec =
        Control.prettyPrint (TypedCalc.format_tpmstrdecl nil dec)
    fun tpdecToString btvEnv dec =
        Control.prettyPrint (TypedCalc.format_tpdecl nil dec)
    fun tpexpToString btvEnv exp =
        Control.prettyPrint (TypedCalc.format_tpexp nil exp)
    fun tpmstrexpToString btvEnv strExp =
        Control.prettyPrint (TypedCalc.format_tpmstrexp nil strExp)
    fun tpmsigexpToString btvEnv sigExp =
	Control.prettyPrint (TypedCalc.format_tpmsigexp nil sigExp)

end
