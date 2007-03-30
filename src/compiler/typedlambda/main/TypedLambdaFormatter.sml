(**
 * a pretty printer for the typed lambda calclulus.
 * @copyright (c) 2006, Tohoku University.
 *)
structure TypedLambdaFormatter =
struct
    fun tldecToString btvEnv dec = 
      Control.prettyPrint (TypedLambda.format_tldecl nil dec)
(*
      Control.prettyPrint (TypedLambda.typedtldecl nil dec)
*)
    fun tlexpToString tlexp = 
      Control.prettyPrint (TypedLambda.format_tlexp nil tlexp)
end
