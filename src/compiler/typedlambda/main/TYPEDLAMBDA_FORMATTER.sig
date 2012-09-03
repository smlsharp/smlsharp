(**
 * a pretty printer for the typed lambda calclulus.
 * @copyright (c) 2006, Tohoku University.
 *)
signature TYPEDLAMBDA_FORMATTER =
sig
  val tldecToString : Types.btvEnv list -> TypedLambda.tldecl -> string
end
