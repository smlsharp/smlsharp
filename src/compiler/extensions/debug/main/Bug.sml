(**
 * bug exception
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)

structure Bug =
struct
  exception Bug of string

  (** this is set by Control.ppg *)
  val debugPrint = ref false
  val printInfo = ref false
  fun prettyPrint expressions = SMLFormat.prettyPrint nil expressions
  val printError = fn string => if !debugPrint then print string else ()
  val printMessage = fn string => if !printInfo then print string else ()
end
