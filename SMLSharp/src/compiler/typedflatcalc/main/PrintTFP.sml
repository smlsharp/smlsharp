(**
 * @copyright (c) 2006, Tohoku University.
 * @author LIU Bochao
 * @version $Id: PrintTFP.sml,v 1.6 2008/02/23 15:49:54 bochao Exp $
 *)
structure PrintTFP : PRINTTFP =
struct

    fun tfpdecToString dec =
        Control.prettyPrint (TypedFlatCalc.format_tfpdecl nil dec)
    fun tfpTopBlockToString dec =
        Control.prettyPrint (TypedFlatCalc.format_topBlock dec)

end
