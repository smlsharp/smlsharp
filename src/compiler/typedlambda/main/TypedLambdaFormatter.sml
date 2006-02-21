(*
 * Copyright (c) 2006, Tohoku University.
 *
 * a pretty printer for the typed lambda calclulus
 *)
structure TypedLambdaFormatter =
struct
    fun tldecToString btvEnv dec = 
	Control.prettyPrint (TypedLambda.format_tldecl nil dec)
    fun tlexpToString tlexp = 
	Control.prettyPrint (TypedLambda.format_tlexp nil tlexp)
end
