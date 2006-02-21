(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author LIU Bochao
 * @version $Id: PrintTFP.sml,v 1.3 2006/02/18 11:06:34 duchuu Exp $
 *)
structure PrintTFP : PRINTTFP =
struct

    fun tfpdecToString btvEnv dec =
        Control.prettyPrint (TypedFlatCalc.format_tfpdecl nil dec)

end
