(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure ReflectionControl =
struct
  (* max number of elements in lists and arrays to be printed *)
  val maxDepth = ref 200
  val maxNestLevel = ref 5
  val maxExnNestLevel = ref 2
  val ellipsis = [SMLFormat.FormatExpression.Term (3, "...")]
  val printWidth = ref 80
end
