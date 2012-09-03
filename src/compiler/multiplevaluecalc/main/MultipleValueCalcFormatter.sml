(**
 * a pretty printer for the multiple value calclulus.
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: MultipleValueCalcFormatter.sml,v 1.2 2007/04/18 09:04:00 ducnh Exp $
 *)
structure MultipleValueCalcFormatter : MULTIPLEVALUECALCFORMATTER =
struct
    fun mvexpToString exp = 
      Control.prettyPrint (MultipleValueCalc.format_mvexp exp)

    fun mvdeclToString decl = 
      Control.prettyPrint (MultipleValueCalc.format_mvdecl decl)

end
