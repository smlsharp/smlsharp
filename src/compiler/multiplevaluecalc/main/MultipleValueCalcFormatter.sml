(**
 * a pretty printer for the multiple value calclulus.
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: MultipleValueCalcFormatter.sml,v 1.6 2008/02/23 15:49:54 bochao Exp $
 *)
structure MultipleValueCalcFormatter : MULTIPLEVALUECALCFORMATTER =
struct
local
    fun mvexpToString exp = 
      Control.prettyPrint (MultipleValueCalc.format_mvexp exp)

    fun mvexpToStringTyped exp = 
      Control.prettyPrint (MultipleValueCalc.typedmvexp exp)

    fun mvdeclToString decl = 
      Control.prettyPrint (MultipleValueCalc.format_mvdecl decl)

    fun mvdeclToStringTyped decl = 
        Control.prettyPrint (MultipleValueCalc.typedmvdecl decl)

in
    val mvexpToString = fn x => 
       (if !Control.printWithType then mvexpToStringTyped
        else mvexpToString) x
      
    val mvdeclToString = fn x =>
       (if !Control.printWithType then mvdeclToStringTyped
        else mvdeclToString) x

end
end
