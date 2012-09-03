(**
 * a pretty printer for the annotated typed lambda calclulus.
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
signature ANNOTATEDCALCFORMATTER =
sig
    val actyToString : AnnotatedTypes.ty -> string

    val acexpToString : AnnotatedCalc.acexp -> string

    val acdeclToString : AnnotatedCalc.acdecl -> string

    val acdeclToStringWithType : AnnotatedCalc.acdecl -> string
end
