(**
 * ListPair structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ListPair.sml,v 1.3 2005/07/26 08:35:52 kiyoshiy Exp $
 *)
structure ListPair = 
struct

  (***************************************************************************)

  exception UnequalLengths

  (***************************************************************************)

  fun zipImpl checkEq (lefts, rights) =
      let
        fun scan [] [] accum = List.rev accum
          | scan [] _ accum =
            if checkEq then raise UnequalLengths else List.rev accum
          | scan _ [] accum = 
            if checkEq then raise UnequalLengths else List.rev accum
          | scan (left :: lefts) (right :: rights) accum =
            scan lefts rights ((left, right) :: accum)
      in scan lefts rights []
      end
  val zip = zipImpl false
  val zipEq = zipImpl true

  fun unzip pairs =
      let
        fun scan [] lefts rights = (List.rev lefts, List.rev rights)
          | scan ((left, right) :: pairs) lefts rights =
            scan pairs (left :: lefts) (right :: rights)
      in scan pairs [] []
      end

  fun mapImpl checkEq f (lefts, rights) =
      List.map f (zipImpl checkEq (lefts, rights))
  val map = mapImpl false
  val mapEq = mapImpl true

  fun appImpl checkEq f (lefts, rights) =
      List.app f (zipImpl checkEq (lefts, rights))
  val app = appImpl false
  val appEq = appImpl true

  fun foldlImpl checkEq f init (lefts, rights) =
      List.foldl
          (fn ((left, right), accum) => f (left, right, accum))
          init
          (zipImpl checkEq (lefts, rights))
  val foldl = foldlImpl false
  val foldlEq = foldlImpl true

  fun foldrImpl checkEq f init (lefts, rights) =
      List.foldr
          (fn ((left, right), accum) => f (left, right, accum))
          init
          (zipImpl checkEq (lefts, rights))
  val foldr = foldrImpl false
  val foldrEq = foldrImpl true

  fun allImpl checkEq f (lefts, rights) =
      List.all f (zipImpl checkEq (lefts, rights))
  val all = allImpl false
  val allEq = allImpl true

  fun exists f (lefts, rights) = List.exists f (zip (lefts, rights))

  (***************************************************************************)

end;