(**
 * @copyright (c) 2008, Tohoku University.
 * @version $Id: EffectCalcFormatter.sml,v 1.1 2008/05/08 09:06:03 katsu Exp $
 *)
structure EffectCalcFormatter =
struct

    fun ecdeclToString dec =
        Control.prettyPrint (EffectCalc.format_ecdecl dec)

    fun ecexpToString exp =
        Control.prettyPrint (EffectCalc.format_ecexp exp)

    fun ecvalueToString value =
        Control.prettyPrint (EffectCalc.format_ecvalue value)

end
