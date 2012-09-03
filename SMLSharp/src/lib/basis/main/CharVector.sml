(**
 * CharVector structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: CharVector.sml,v 1.6 2007/12/19 02:00:56 kiyoshiy Exp $
 *)
structure CharVector =
struct

  (***************************************************************************)

  type vector = String.string
  type elem = char
  type slice = vector * int * int

  (***************************************************************************)

  val maxLen = String.maxSize

  val fromList = String.implode

  (* ToDo : instead of fromList, it is more efficient to allocate a buffer
   * by 'String_allocate' first, then, fill it by 'String_update'. *)
  val tabulate = fromList o List.tabulate

  val length = String.size

  val sub = String.sub

  val concat = String.concat

  fun update (vector, index, value) =
      let fun valueOfIndex i = if i = index then value else sub (vector, i)
      in tabulate (length vector, valueOfIndex)
      end

  fun copy {src, si, dst, di, len} =
      SMLSharp.PrimString.copy_unsafe (src, si, dst, di, len)

  fun concatSlices (slices : slice list) =
      let
        val (totalLength, initialValueOpt) =
            List.foldr
                (fn ((_, _, length), (totalLength, SOME value)) =>
                    (totalLength + length, SOME value)
                  | ((_, _, 0), (totalLength, NONE)) => (totalLength, NONE)
                  | ((array, _, length), (totalLength, NONE)) =>
                    (totalLength + length, SOME(sub(array, 0))))
                (0, NONE)
                slices
      in
        case (totalLength, initialValueOpt) of
          (0, _) => ""
        | (_, SOME initialValue) =>
          let
            val resultBuffer =
                SMLSharp.PrimString.vector (totalLength, initialValue)
            fun write ((src, start, 0), index) = index
              | write ((src, start, length), index) =
                  (
                    copy
                        {
                          src = src,
                          si = start,
                          dst = resultBuffer,
                          di = index,
                          len = length
                        };
                    index + length
                  )
          in
            List.foldl write 0 slices;
            resultBuffer
          end
        | (_, NONE) => raise Fail "BUG: vector concat"
      end

  (* ToDo : As tabulate, mapi should be rewritten to efficient one. *)
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