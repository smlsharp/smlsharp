(**
 * CharVector structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: CharVector.sml,v 1.3 2005/07/27 14:10:26 kiyoshiy Exp $
 *)
structure CharVector =
struct

  (***************************************************************************)

  type vector = String.string
  type elem = char

  (***************************************************************************)

  val maxLen = String.maxSize

  val fromList = String.implode

  val tabulate = fromList o List.tabulate

  val length = String.size

  val sub = String.sub

  val concat = String.concat

  fun update (vector, index, value) =
      let fun valueOfIndex i = if i = index then value else sub (vector, i)
      in tabulate (length vector, valueOfIndex)
      end

  fun mapi mapFun vector =
      let val length = size vector
      in
        String.implode
            (List.tabulate
                 (length, fn index => mapFun (index, sub (vector, index))))
      end
  val map = String.map

  fun appi appFun vector =
      let
        val length = size vector
        fun scan index =
            if index = length
            then ()
            else (appFun (index, sub (vector, index)); scan (index + 1))
      in scan 0
      end
  fun app f vector = List.app f (String.explode vector)

  fun foldli foldFun initial vector =
      let
        val length = size vector
        fun fold (index, accum) =
            if index = length
            then accum
            else
              let val newAccum = foldFun (index, sub (vector, index), accum)
              in fold (index + 1, newAccum)
              end
      in
        fold (0, initial)
      end

  fun foldri foldFun initial vector =
      let
        val length = size vector
        fun fold (index, accum) =
            if index = ~1
            then accum
            else
              let val newAccum = foldFun (index, sub (vector, index), accum)
              in fold (index - 1, newAccum)
              end
      in
        fold (length - 1, initial)
      end

  fun foldl f initial vector = List.foldl f initial (String.explode vector)
  fun foldr f initial vector = List.foldr f initial (String.explode vector)

  fun findi predicate vector =
      let
        val length = length vector
        fun scan index =
            if index = length
            then NONE
            else
              let val value = sub (vector, index)
              in
                if predicate (index, value)
                then SOME(index, value)
                else scan (index + 1)
              end
      in
        scan 0
      end
      
  fun find predicate vector =
      Option.map
          (fn (_, value) => value)
          (findi (fn (_, value) => predicate value) vector)

  fun exists predicate vector = Option.isSome(find predicate vector)

  fun all predicate vector =
      not(Option.isSome(find (fn value => not(predicate value)) vector))

  val collate = String.collate

  (***************************************************************************)

end;