(**
 * ListPair structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
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

  fun map f (lefts, rights) = List.map f (zip (lefts, rights))

  fun mapEq f =
      let
        fun m accum ([], []) = List.rev accum
          | m accum (left :: lefts, right :: rights) =
            m (f (left, right) :: accum) (lefts, rights)
          | m _ _ = raise UnequalLengths
      in m []
      end

  fun app f (lefts, rights) = List.app f (zip (lefts, rights))

  fun appEq f ([], []) = ()
    | appEq f (left :: lefts, right :: rights) =
      (f (left, right); appEq f (lefts, rights))
    | appEq f _ = raise UnequalLengths

  fun foldl f init (lefts, rights) =
      List.foldl
          (fn ((left, right), accum) => f (left, right, accum))
          init
          (zip (lefts, rights))

  fun foldlEq f init ([], []) = init
    | foldlEq f init (left :: lefts, right :: rights) =
      foldlEq f (f (left, right, init)) (lefts, rights)
    | foldlEq f _ _ = raise UnequalLengths

  fun foldr f init (lefts, rights) =
      List.foldr
          (fn ((left, right), accum) => f (left, right, accum))
          init
          (zip (lefts, rights))

  fun foldrEq f init ([], []) = init
    | foldrEq f init (left :: lefts, right :: rights) =
      f (left, right, foldrEq f init (lefts, rights))
    | foldrEq f _ _ = raise UnequalLengths

  fun all f (lefts, rights) = List.all f (zip (lefts, rights))

  fun allEq f ([], []) = true
    | allEq f (x :: xs, y :: ys) = f (x, y) andalso allEq f (xs, ys)
    | allEq _ _ = false

  fun exists f (lefts, rights) = List.exists f (zip (lefts, rights))

  (***************************************************************************)

end;