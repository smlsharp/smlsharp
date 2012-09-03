(**
 * List structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: List.sml,v 1.5 2005/05/03 09:25:13 kiyoshiy Exp $
 *)
structure List =
struct

  (***************************************************************************)

  datatype list = datatype list

  (***************************************************************************)

  exception Empty

  (***************************************************************************)

  fun null [] = true
    | null _ = false

  fun length [] = 0
    | length list =
      let
        fun scan [] result = result
          | scan (_ :: tail) len = scan tail (len + 1)
      in scan list 0 end

  fun rev list =
      let
        fun scan [] result = result
          | scan (head :: tail) result = scan tail (head :: result)
      in scan list [] end

  fun op @ ([], right) = right
    | op @ (left, []) = left
    | op @ (left, right) =
      let
        fun scan [] right = right
          | scan (head :: tail) right = scan tail (head :: right)
      in scan (rev left) right
      end

  fun hd [] = raise Empty
    | hd (head :: _) = head

  fun tl [] = raise Empty
    | tl (_ :: tail) = tail

  fun last [] = raise Empty
    | last [lastItem] = lastItem
    | last (_ :: tail) = last tail

  fun getItem [] = Option.NONE
    | getItem (head :: tail) = Option.SOME(head, tail)

  fun nth (list, index) =
      let
        fun scan [] _ = raise General.Subscript
          | scan (head :: _) 0 = head
          | scan (_ :: tail) index = scan tail (index - 1)
      in
        if index < 0 then raise General.Subscript else scan list index
      end

  fun take (list, len) =
      let
        fun scan _ result 0 = rev result
          | scan [] _ _ = raise General.Subscript
          | scan (head :: tail) result remain =
            scan tail (head :: result) (remain - 1)
      in
        if len < 0 then raise General.Subscript else scan list [] len
      end
      
  fun drop (list, len) =
      let
        fun scan tail 0 = tail
          | scan [] _ = raise General.Subscript
          | scan (_ :: tail) remain = scan tail (remain - 1)
      in
        if len < 0 then raise General.Subscript else scan list len
      end

  fun revAppend (left, right) =
      let
        fun scan [] right = right
          | scan (head :: tail) right = scan tail (head :: right)
      in scan left right end

  fun concat lists =
      let
        fun scan [] result = rev result
          | scan (head :: tail) result = scan tail (revAppend (head, result))
      in scan lists [] end

  fun app f [] = ()
    | app f (head :: tail) = (f head; app f tail)

  fun map f list = 
      let
        fun scan [] result = rev result
          | scan (head :: tail) result = scan tail ((f head) :: result)
      in scan list [] end

  fun find predicate [] = Option.NONE
    | find predicate (head :: tail) =
      if predicate head then Option.SOME head else find predicate tail
                          
  fun filter predicate list =
      let
        fun scan [] result = rev result
          | scan (head :: tail) result =
            scan tail (if predicate head then head :: result else result)
      in scan list [] end

  fun mapPartial f list =
      ((map Option.valOf) o (filter Option.isSome) o (map f)) list

  fun partition predicate list =
      let
        fun scan [] positives negatives = (rev positives, rev negatives)
          | scan (head :: tail) positives negatives =
            if predicate head
            then scan tail (head :: positives) negatives
            else scan tail positives (head :: negatives)
      in scan list [] [] end

  fun foldl f initial list =
      let
        fun scan [] result = result
          | scan (head :: tail) result = scan tail (f (head, result))
      in scan list initial end

  fun foldr f initial list =
      let
        fun scan [] result = result
          | scan (head :: tail) result = f (head, scan tail result)
      in scan list initial end

  fun exists predicate [] = false
    | exists predicate (head :: tail) =
      if predicate head then true else exists predicate tail

  fun all predicate [] = true
    | all predicate (head :: tail) =
      if predicate head then all predicate tail else false

  fun tabulate (count, f) =
      let
        fun scan index result =
            if index = count
            then rev result
            else scan (index + 1) ((f index) :: result)
      in if count < 0 then raise General.Size else scan 0 []
      end

  fun collate elementCollate (lefts, rights) =
      let
        fun scan [] (_::_) = General.LESS
          | scan [] [] = General.EQUAL
          | scan (_::_) [] = General.GREATER
          | scan (left :: lefts) (right :: rights) =
            case elementCollate (left, right) of
              General.EQUAL => scan lefts rights
            | diff => diff
      in scan lefts rights
      end

  (***************************************************************************)

end;
