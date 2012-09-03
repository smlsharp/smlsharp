(**
 * compare two sequences and calculate their differences.
 *
 * @author UENO Katsuhiro
 * @version $Id: Diff.sml,v 1.1 2005/12/13 16:43:52 katsuu Exp $
 *)
structure Diff : sig

  datatype ('a,'b) edit = ADD of 'b | DEL of 'a | KEEP of 'a
  val diff : ('a * 'b -> bool) -> 'a list * 'b list -> ('a,'b) edit list

end
= struct

  infix 9 ==

  (**
   * An edit operation from 'a to 'b.
   *
   * ADD and DEL means insertion and deletion respectively,
   * KEEP means no edit operation (i.e. just keep original one.)
   *)
  datatype ('a,'b) edit = ADD of 'b | DEL of 'a | KEEP of 'a

  (**
   * An editgraph.
   *
   * This program assumes that each member of fromList and toList puts
   * onto horizontal and vertical axis of an editgraph left to right
   * and up to bottom, respectively.
   * So a horizontal edge in a editgraph corresponds to a deletion,
   * and a vertical edge corresponds to an insertion.
   *)
  type ('a,'b) editgraph = 'a list * 'b list   (* fromList * toList *)

  (**
   * A path from source to a grid point in a editgraph.
   *
   * First element is a path from source to the grid point, and
   * another one is sub-editgraph which will be visited from there.
   *)
  type ('a,'b) path =
       ('a,'b) edit list   (* sequence from source to here (reversed) *)
       * ('a,'b) editgraph (* sub-editgraph which will be visited from here *)

  fun snake (op ==) (path, graph as (from::fromList, to::toList)) =
      if from == to
      then snake (op ==) (KEEP from :: path, (fromList, toList))
      else (path, graph)
    | snake (op ==) x = x

  fun add (path, (fromList, to::toList)) =
      (ADD to :: path, (fromList, toList))
    | add x = x

  fun del (path, (from::fromList, toList)) =
      (DEL from :: path, (fromList, toList))
    | del x = x

  fun sink (path, (nil, nil)) = true
    | sink _ = false

  fun rest (path, (fromList, toList)) = length fromList

  fun path (path, (fromList, toList)) = rev path

  fun walkLeft path =
      let fun walk (walked as (p as (path, (from::fromList, toList)))::_) =
              walk ((DEL from :: path, (fromList, toList)) :: walked)
            | walk walked = walked
      in walk [path]
      end

  fun walkDown path =
      let fun walk (walked as (p as (path, (fromList, to::toList)))::_) =
              walk ((ADD to :: path, (fromList, toList)) :: walked)
            | walk walked = walked
      in walk [path]
      end

  fun distance l = length ((List.filter (fn (KEEP _) => false | _ => true) l))
  fun shorter (l1, l2) = if distance l2 < distance l1 then l2 else l1
  fun shorter3 (l1, l2, l3) = shorter (shorter (l1, l2), l3)

  (**
   * An implementation of naive diff algorithm.
   *
   * Calculate the shortest path from source for every grid point in a
   * editgraph.
   *)
  fun naiveDiff (op ==) (fromList, toList) =
      let
          val initialPaths =
              foldl (fn (from, paths) => (DEL from :: hd paths) :: paths)
                    [nil]
                    fromList

          val fromList = rev fromList

          fun nextPaths f (fromList as _::fromList')
                          (prevPaths as _::prevPaths') =
              let val paths = nextPaths f fromList' prevPaths'
              in f (fromList, prevPaths, paths) :: paths
              end
            | nextPaths f fromList prevPaths =
              f (fromList, prevPaths, nil) :: nil

          val finalPaths =
              foldl (fn (to, prevPaths) =>
                        nextPaths
                            (fn (from::_, prev::prevLeft::_, left::_) =>
                                if from == to
                                then shorter3 (DEL from :: left,
                                               ADD to :: prev,
                                               KEEP from :: prevLeft)
                                else shorter  (ADD to :: prev,
                                               DEL from :: left)
                              | (_, prev::_, nil) => ADD to :: prev
                              | _ => raise Match)
                            fromList
                            prevPaths)
                    initialPaths
                    toList
      in
          rev (hd finalPaths)
      end

  (**
   * An implementation of O(ND) algorithm.
   *
   * @see E. W. Myers, "An O(ND) difference algorithm and its variations,"
   *      Algorithmica, 1 (1986), pp.251--266.
   *)
  fun ondDiff (op ==) (fromList, toList) =
      let
          val snake = snake (op ==)

          fun next leftDiag rightDiag =
              snake (if rest rightDiag < rest leftDiag
                     then add rightDiag
                     else del leftDiag)

          fun search (prevDiags as (leftMost as (_,(_,_::_)))::_) =
              let val diag = snake (add leftMost)
              in if sink diag
                 then path diag
                 else search2 prevDiags [diag]
              end
            | search prevDiags =
              search2 prevDiags nil

          and search2 (left::(prevDiags as right::_)) nextDiags =
              let val diag = next left right
              in if sink diag
                 then path diag
                 else search2 prevDiags (diag :: nextDiags)
              end
            | search2 ((rightMost as (_,(_::_,_)))::prevDiags) nextDiags =
              let val diag = snake (del rightMost)
              in if sink diag
                 then path diag
                 else search2 prevDiags (diag :: nextDiags)
              end
            | search2 ((rightMost as (_,(nil,_)))::prevDiags) nextDiags =
              if sink rightMost
              then path rightMost
              else search2 prevDiags nextDiags
            | search2 nil nextDiags =
              search (rev nextDiags)
      in
          search [snake (nil, (fromList, toList))]
      end

  (**
   * An implementation of O(NP) algorithm.
   *
   * @see S. Wu, U. Manber, G. Myers, W. Miller, "An O(NP) Sequence
   *      Comparison Algorithm," Information Processing Letters archive,
   *      Volume 35 Issue 6, September 1990, pp.317--323.
   *)
  fun onpDiff (op ==) (fromList, toList) =
      let
          val snake = snake (op ==)

          fun next leftDiag rightDiag =
              snake (if rest rightDiag < rest leftDiag
                     then add rightDiag
                     else del leftDiag)

          fun searchLeft ((leftMost as (_,(_,nil)))::prevDiags) nil =
              searchLeft prevDiags nil
            | searchLeft (leftMost::prevDiags) nil =
              searchLeft prevDiags [snake (add leftMost)]
            | searchLeft (right::prevDiags) (nextDiags as left::_) =
              searchLeft prevDiags (next left right :: nextDiags)
            | searchLeft nil nextDiags =
              nextDiags

          fun searchRight ((rightMost as (_,(nil,_)))::prevDiags) nil =
              searchRight prevDiags nil
            | searchRight (rightMost::prevDiags) nil =
              searchRight prevDiags [snake (del rightMost)]
            | searchRight (left::prevDiags) (nextDiags as right::_) =
              searchRight prevDiags (next left right :: nextDiags)
            | searchRight nil nextDiags =
              nextDiags

          fun search leftDiags deltaDiag rightDiags =
              if sink deltaDiag
              then path deltaDiag
              else let val leftDiags = rev (deltaDiag :: leftDiags)
                       val rightDiags = rev (deltaDiag :: rightDiags)
                       val nextLeftDiags = searchLeft leftDiags nil
                       val nextRightDiags = searchRight rightDiags nil
                       val nextDeltaDiags =
                           case (nextLeftDiags, nextRightDiags) of
                               (left::_, right::_) => next left right
                             | (left::_, nil) => del left
                             | (nil, right::_) => add right
                             | (nil, nil) => deltaDiag
                   in search nextLeftDiags nextDeltaDiags nextRightDiags
                   end

          val sourceDiag = snake (nil, (fromList, toList))

          fun makeInitialDiags (_::leftDiags) (_::rightDiags) =
              makeInitialDiags leftDiags rightDiags
            | makeInitialDiags nil (right::rightDiags) =
              (rightDiags @ [sourceDiag], right, nil)
            | makeInitialDiags (left::leftDiags) nil =
              (nil, left, leftDiags @ [sourceDiag])
            | makeInitialDiags nil nil = (nil, sourceDiag, nil)

          val (leftDiags, deltaDiag, rightDiags) =
              makeInitialDiags (walkDown (add sourceDiag))
                               (walkLeft (del sourceDiag))
      in
          search leftDiags (snake deltaDiag) rightDiags
      end

  (**
   * compares two lists and returns descriptions of their differences.
   * In other words, calculates the shortest edit sequence from
   * 'a list to 'b list.
   *
   * @params eq (from, to)
   * @param eq    returns true if two arguments are equal.
   * @param from  sequence before editing.
   * @param to    sequence after editing.
   *)
  (*
   * export only one, the most efficient implementation.
   * Any other implementations are just for example :)
   *)
  val diff = onpDiff

end
