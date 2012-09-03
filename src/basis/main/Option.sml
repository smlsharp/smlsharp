(**
 * Option structure.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "Option.smi"

structure Option :> OPTION
  where type 'a option = 'a option
=
struct

  datatype option = datatype option
  exception Option = Option

  fun getOpt (SOME value, _) = value
    | getOpt (NONE, default) = default

  fun isSome (SOME _) = true
    | isSome NONE = false

  fun valOf (SOME value) = value
    | valOf NONE = raise Option

  fun filter predicate value =
      if predicate value then SOME value else NONE

  fun join NONE = NONE
    | join (SOME value) = value

  fun app f NONE = ()
    | app f (SOME value) = f value

  fun map f NONE = NONE
    | map f (SOME value) = SOME (f value)

  fun mapPartial f NONE = NONE
    | mapPartial f (SOME value) = f value

  fun compose (f, g) =
      fn value =>
         case g value of
           NONE => NONE
         | SOME value => SOME (f value)

  fun composePartial (f, g) =
      fn value =>
         case g value of
           NONE => NONE
         | SOME value => f value

end

val getOpt = Option.getOpt
val isSome = Option.isSome
val valOf = Option.valOf
