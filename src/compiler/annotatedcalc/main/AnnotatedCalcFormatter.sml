(**
 * a pretty printer for the annotated typed lambda calclulus.
 * @copyright (c) 2006, Tohoku University.
 *)
structure AnnotatedCalcFormatter : ANNOTATEDCALCFORMATTER =
struct
    fun actyToString ty = 
      Control.prettyPrint (AnnotatedTypes.format_ty ty)

    fun acexpToString exp = 
      Control.prettyPrint (AnnotatedCalc.format_acexp exp)

    fun acdeclToString decl = 
      Control.prettyPrint (AnnotatedCalc.format_acdecl decl)

    fun acdeclToStringWithType decl = 
      Control.prettyPrint (AnnotatedCalc.formatWithType_acdecl decl)
end
