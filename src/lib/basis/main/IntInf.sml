(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: IntInf.sml,v 1.1 2005/08/11 03:43:57 kiyoshiy Exp $
 *)
structure IntInf : INT_INF =
struct

  (***************************************************************************)

  open Int

  fun divMod (left, right) = (Int.div (left, right), Int.mod (left, right))

  fun quotRem (left, right) = (Int.quot (left, right), Int.rem (left, right))

  fun pow (left, 0) = 1
    | pow (left, right) =
      let
        fun loop 0 result = result
          | loop remain result = loop (remain - 1) (left * result)
      in
        if right < 0
        then
          if left = 0
          then raise General.Div
          else if 1 = abs left then 0 (* ? *) else 0
        else
          loop (right - 1) left
      end

  fun log2 x = raise Unimplemented "log2"

  fun orb (left, right) = raise Unimplemented "orb"

  fun xorb (left, right) = raise Unimplemented "xorb"

  fun andb (left, right) = raise Unimplemented "andb"

  fun notb x = raise Unimplemented "notb"

  fun << (left, right) = raise Unimplemented "<<"

  fun ~>> (left, right) = raise Unimplemented "~>>"

  (***************************************************************************)

end;