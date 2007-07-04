(**
 * AnnotatedCalc utilities
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)

signature ANNOTATEDCALCUTILS = sig

  val convertNumericalLabel : int -> string

  val convertLabel : string -> string

  val newVar : AnnotatedTypes.ty -> AnnotatedCalc.varInfo

end
