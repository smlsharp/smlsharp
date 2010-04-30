signature TYPECHECK_TYPEDLAMBDA = sig
  val typecheck : TypedLambda.topBlock list -> UserError.errorInfo list
end
