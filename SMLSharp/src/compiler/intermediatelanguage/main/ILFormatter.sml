(**
 * Formatter of Intermediate Language
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ILFormatter.sml,v 1.2 2007/04/18 09:02:19 ducnh Exp $
 *)
structure ILFormatter : ILFORMATTER  =
struct

    fun moduleCodeToString code = Control.prettyPrint (IntermediateLanguage.format_moduleCode code)

end
