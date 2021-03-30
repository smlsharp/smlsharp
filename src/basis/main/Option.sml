(**
 * Option structure.
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)

structure Option =
struct

  exception Option

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

  datatype option = datatype option

end
