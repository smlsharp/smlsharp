(**
 * base implementation of MONO_VECTOR_SLICE.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MonoVectorSliceBase.sml,v 1.3 2007/09/01 03:21:16 kiyoshiy Exp $
 *)
functor MonoVectorSliceBase
          (V : sig
             include MONO_VECTOR
             type slice = vector * int * int
             val concatSlices : slice list -> vector
           end) =
struct

  (***************************************************************************)

  type elem = V.elem

  type vector = V.vector

  type slice = V.vector * (** start *) int * (** length *) int

  (***************************************************************************)

  fun length (_, _, length) = length

  fun sub ((vector, start, length), index) =
      if (index < 0) orelse (length <= index)
      then raise General.Subscript
      else V.sub(vector, start + index)

  fun full vector = (vector, 0, V.length vector)

  fun slice (vector : V.vector, start : int, lengthOpt) =
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
      
  fun base ((vector, start, length) : slice) = (vector, start, length)

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

  fun mapi mapFun (vector, start, length) =
      V.tabulate
          (length, fn index => mapFun (index, V.sub (vector, start + index)))
  fun map mapFun slice = mapi (fn (_, element) => mapFun element) slice
  fun appi appFun slice =
      foldli (fn (index, a, _) => (appFun (index, a))) () slice
  fun app appFun slice = appi (fn (_, element) => appFun element) slice
                                     
  fun vector slice = V.concatSlices [slice]
  fun concat slices = V.concatSlices slices

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
  fun collate comparator (leftSlice, rightSlice) =
      V.collate comparator (vector leftSlice, vector rightSlice)

  (***************************************************************************)

end;
