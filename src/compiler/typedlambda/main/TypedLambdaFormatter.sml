(**
 * a pretty printer for the typed lambda calclulus.
 * @copyright (c) 2006, Tohoku University.
 *)
structure TypedLambdaFormatter =
struct
    fun tldecToString dec = 
      Control.prettyPrint (TypedLambda.format_tldecl nil dec)

    fun tldecToStringWithType dec =
      Control.prettyPrint (TypedLambda.formatWithType_tldecl nil dec)

    fun tlexpToString tlexp = 
        Control.prettyPrint (TypedLambda.format_tlexp nil tlexp)

    fun tlexpToStringWithType tlexp = 
        Control.prettyPrint (TypedLambda.formatWithType_tlexp nil tlexp)
end
