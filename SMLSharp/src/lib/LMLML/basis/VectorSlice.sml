(**
 * VectorSlice structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: VectorSlice.sml,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
structure VectorSlice =
struct

  (***************************************************************************)

  structure V = Vector

  (***************************************************************************)

  type 'a vector = 'a V.vector

  type 'a slice = 'a V.vector * (** start *) int * (** length *) int

  (***************************************************************************)

  fun length (_, _, length) = length

  fun sub ((vector, start, length), index) =
      if (index < 0) orelse (length <= index)
      then raise General.Subscript
      else V.sub(vector, start + index)

  fun full vector = (vector, 0, V.length vector)

  fun 'a slice (vector : 'a V.vector, start : int, lengthOpt) =
      let
        val vectorLength = V.length vector
        val length = 
            case lengthOpt of
              NONE =>
              if (start < 0) orelse (vectorLength < start)
              then raise General.Subscript
              else vectorLength - start
            | SOME length =>
              if
                (start < 0)
                orelse (length < 0)
                orelse (vectorLength < start + length)
              then raise General.Subscript
              else length
      in
        (vector, start, length)
      end

  fun subslice ((vector, start1, length1), start2, length2Opt) =
      let
        val length = 
            case length2Opt of
              NONE =>
              if (start2 < 0) orelse (length1 < start2)
              then raise General.Subscript
              else length1 - start2
            | SOME length2 =>
              if
                (start2 < 0)
                orelse (length2 < 0)
                orelse (length1 < start2 + length2)
              then raise General.Subscript
              else length2
        val start = start1 + start2
      in
        (vector, start, length)
      end
      
  fun 'a base ((vector, start, length) : 'a slice) = (vector, start, length)

  fun foldli foldFun initial (vector, start, length) =
      let
        fun fold (index, accum) =
            if index = length
            then accum
            else
              let
                val newAccum =
                    foldFun (index, V.sub (vector, start + index), accum)
              in fold (index + 1, newAccum)
              end
      in
        fold (0, initial)
      end
  fun foldri foldFun initial (vector, start, length) = 
      let
        fun fold (index, accum) =
            if index = ~1
            then accum
            else
              let
                val newAccum =
                    foldFun (index, V.sub (vector, start + index), accum)
              in fold (index - 1, newAccum)
              end
      in
        fold (length - 1, initial)
      end
  fun foldl foldFun initial slice = 
      foldli (fn (_, element, accum) => foldFun(element, accum)) initial slice
  fun foldr foldFun initial slice = 
      foldri (fn (_, element, accum) => foldFun (element, accum)) initial slice
  fun mapi mapFun slice =
      V.fromList
          (List.rev
               (foldli
                    (fn (index, a, l) => (mapFun (index, a) :: l)) [] slice))
  fun map mapFun slice = mapi (fn (_, element) => mapFun element) slice
  fun appi appFun slice =
      foldli (fn (index, a, _) => (appFun (index, a))) () slice
  fun app appFun slice = appi (fn (_, element) => appFun element) slice
                                     
  fun vector slice = V.tabulate(length slice, fn index => sub (slice, index))
  fun concat slices =
      let
        fun prependSliceElementsToList (slice, list) =
            foldr (fn (value, list) => value :: list) list slice
        val list = List.foldr prependSliceElementsToList [] slices
      in
        V.fromList list
      end
  fun isEmpty (_, _, length) = length = 0
  fun getItem (vector, start, 0) = NONE
    | getItem (vector, start, length) =
      let val item = V.sub (vector, start)
      in SOME(item, (vector, start + 1, length - 1))
      end

  fun findi predicate (vector, start, length) = 
      let
        fun scan index =
            if index = length
            then NONE
            else
              let val value = V.sub (vector, start + index)
              in
                if predicate (index, value)
                then SOME(index, value)
                else scan (index + 1)
              end
      in
        scan 0
      end
  fun find predicate slice =
      Option.map
          (fn (_, value) => value)
          (findi (fn (_, value) => predicate value) slice)
  fun exists predicate slice = Option.isSome(find predicate slice)
  fun all predicate slice = 
      not(Option.isSome(find (fn value => not(predicate value)) slice))
  fun collate elementCollate (left, right) =
      let
        fun scan _ 0 0 = General.EQUAL
          | scan _ 0 _ = General.LESS
          | scan _ _ 0 = General.GREATER
          | scan index leftRemain rightRemain =
            case elementCollate(sub (left, index), sub (right, index)) of
              General.EQUAL =>
              scan (index + 1) (leftRemain - 1) (rightRemain - 1)
            | diff => diff
      in
        scan 0 (length left) (length right)
      end

  (***************************************************************************)

end;