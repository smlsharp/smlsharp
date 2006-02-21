(*
 * Copyright (c) 2006, Tohoku University.
 *
 * a pretty printer for the typed lambda calclulus
 *)

signature TYPEDLAMBDA_FORMATTER =
sig
  val tldecToString : Types.btvEnv list -> TypedLambda.tldecl -> string
end
