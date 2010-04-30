(**
 * Formatter of Intermediate Language
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ILFORMATTER.sig,v 1.2 2007/04/18 09:02:19 ducnh Exp $
 *)
signature ILFORMATTER  =
sig

    val moduleCodeToString : IntermediateLanguage.moduleCode -> string

end
