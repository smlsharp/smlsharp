(**
 * Vector structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Vector.sml,v 1.12 2006/12/04 04:21:03 kiyoshiy Exp $
 *)
structure Vector =
struct

  (***************************************************************************)

  type 'a vector = 'a array

  (***************************************************************************)

  (* This must be equal to the max size of heap block.
   * It is obtained from SIZE_MASK defined in Heap.hh.
   *)
  val maxLen = 0xFFFFFFF

  fun makeArray (intSize, initial) =
      if maxLen < intSize
      then raise General.Size
      else Array_array(Word.fromInt intSize, initial)
  fun arrayUpdate (array, intIndex, value) =
      Array_update (array, Word.fromInt intIndex, value)
  fun arraySub (array, intIndex) = Array_sub (array, Word.fromInt intIndex)
  fun arrayLength array = Array_length array

  (* ToDo : to create an empty array, new primitive should be added ? *)
  fun 'a makeEmptyVector _ = _cast (Array_array(0w0, 0)) : 'a array

  fun fromList [] = makeEmptyVector ()
    | fromList (head :: tail) =
      let
        val bufferLength = 1 + List.length tail
        val buffer = makeArray (bufferLength, head)
        fun write [] _ = ()
          | write (next :: remains) index =
            (arrayUpdate (buffer, index, next); write remains (index + 1))
      in
        (* write elements from the second element. *)
        write tail 1; 
        buffer
      end

  fun tabulate (number, generator) =
      fromList (List.tabulate (number, fn index => generator index))

  fun 'a length array = arrayLength array

  fun 'a sub (array, index) =
      if index < 0 orelse arrayLength array <= index
      then raise Subscript (* if buffer = NONE, the sub always fails. *)
      else arraySub (array, index)

  fun foldli foldFun initial vector =
      let
        val len = length vector
        fun fold (index, accum) =
            if index = len
            then accum
            else
              let val newAccum = foldFun (index, sub (vector, index), accum)
              in fold (index + 1, newAccum)
              end
      in
        fold (0, initial)
      end
  fun foldl foldFun initial vector =
      foldli (fn (_, element, accum) => foldFun(element, accum)) initial vector

  fun foldri foldFun initial vector =
      let
        val len = length vector
        fun fold (index, accum) =
            if index = ~1
            then accum
            else
              let val newAccum = foldFun (index, sub (vector, index), accum)
              in fold (index - 1, newAccum)
              end
      in
        fold (len - 1, initial)
      end
  fun foldr foldFun initial vector =
      foldri
          (fn (_, element, accum) => foldFun (element, accum)) initial vector

  fun mapi mapFun vector =
      fromList
          (List.rev
               (foldli
                    (fn (index, a, l) => (mapFun (index, a) :: l)) [] vector))

  fun map mapFun vector = mapi (fn (_, element) => mapFun element) vector

  fun appi appFun vector = 
      foldli (fn (index, a, _) => (appFun (index, a))) () vector

  fun app appFun vector = appi (fn (_, element) => appFun element) vector

  fun update (vector, index, value) =
      let fun valueOfIndex i = if i = index then value else sub (vector, i)
      in tabulate (length vector, valueOfIndex)
      end

  fun concat vectors =
      let
        fun copyVec source buffer destIndex =
            appi
                (fn (index, sourceElement) =>
                    arrayUpdate(buffer, destIndex + index, sourceElement))
                source
        val (totalLength, initialValueOpt) =
            List.foldr
                (fn (array, (totalLength, SOME value)) =>
                    (totalLength + arrayLength array, SOME value)
                  | (array, (totalLength, NONE)) =>
                    (case arrayLength array of
                       0 => (totalLength, NONE)
                     | len => 
                       (totalLength + len, SOME(arraySub(array, 0)))))
                (0, NONE)
                vectors
      in
        case (totalLength, initialValueOpt) of
          (0, _) => makeEmptyVector ()
        | (_, SOME initialValue) =>
          let
            val resultBuffer = makeArray(totalLength, initialValue)
            fun write (sourceVector, index) =
                case arrayLength sourceVector of
                  0 => index
                | len => 
                  (
                    copyVec sourceVector resultBuffer index;
                    index + len
                  )
          in
            List.foldl write 0 vectors;
            resultBuffer
          end
        | (_, NONE) => raise Fail "BUG: vector concat"
      end

  fun findi predicate vector =
      let
        val len = length vector
        fun scan index =
            if index = len
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
