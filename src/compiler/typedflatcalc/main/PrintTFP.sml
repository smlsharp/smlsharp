(**
 * @copyright (c) 2006, Tohoku University.
 * @author LIU Bochao
 * @version $Id: PrintTFP.sml,v 1.4 2006/02/27 06:31:09 bochao Exp $
 *)
structure PrintTFP : PRINTTFP =
struct

    fun tfpdecToString btvEnv dec =
        Control.prettyPrint (TypedFlatCalc.format_tfpdecl nil dec)

end
