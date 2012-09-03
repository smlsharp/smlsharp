(**
 * base of implementations of the MONO_VECTOR signature.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MonoVectorBase.sml,v 1.9 2007/12/19 02:00:56 kiyoshiy Exp $
 *)
functor MonoVectorBase
        (B
         : sig
           type elem
           type vector
           val maxLen : int
           val makeVector : int * elem -> vector
           val makeEmptyVector : unit -> vector
           val length : vector -> int
           val sub : vector * int -> elem
           val update : vector * int * elem -> unit
           val copy
               : {src : vector, si : int, dst : vector, di : int, len : int}
                 -> unit
         end) =
struct

  (***************************************************************************)

  type vector = B.vector

  type elem = B.elem

  (* shared with MonoVectorSliceBase. *)
  type slice = vector * (** start *) int * (** length *) int

  (***************************************************************************)

  val maxLen = B.maxLen

  fun makeVector (intSize, init) =
      if intSize < 0 orelse maxLen < intSize
      then raise General.Size
      else B.makeVector (intSize, init)

  fun fromList [] = B.makeEmptyVector ()
    | fromList (head :: tail) =
      let
        val bufferLength = 1 + List.length tail
        val buffer = makeVector (bufferLength, head)
        fun write [] _ = ()
          | write (next :: remains) index =
            (B.update (buffer, index, next); write remains (index + 1))
      in
        (* write elements from the second element. *)
        write tail 1; 
        buffer
      end

  fun tabulate (number, generator) =
      fromList (List.tabulate (number, fn index => generator index))

  fun length vector = B.length vector

  fun sub (vector, index) =
      if index < 0 orelse (B.length vector) <= index
      then raise Subscript (* if buffer = NONE, the sub always fails. *)
      else B.sub (vector, index)

  fun foldli foldFun initial vector =
      let
        val length = length vector
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
  fun foldl foldFun initial vector =
      foldli
          (fn (_, element, accum) => foldFun (element, accum)) initial vector

  fun foldri foldFun initial vector =
      let
        val length = length vector
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
  fun foldr foldFun initial vector =
      foldri
          (fn (_, element, accum) => foldFun (element, accum))
          initial
          vector

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

  (** A utility for VectorSlice and other structures.*)
  val copy = B.copy

  fun concatSlices (slices : slice list) =
      let
        val (totalLength, initialValueOpt) =
            List.foldr
                (fn ((_, _, length), (totalLength, SOME value)) =>
                    (totalLength + length, SOME value)
                  | ((_, _, 0), (totalLength, NONE)) => (totalLength, NONE)
                  | ((vector, _, length), (totalLength, NONE)) =>
                    (totalLength + length, SOME(B.sub(vector, 0))))
                (0, NONE)
                slices
      in
        case (totalLength, initialValueOpt) of
          (0, _) => B.makeEmptyVector ()
        | (_, SOME initialValue) =>
          let
            val resultBuffer = makeVector(totalLength, initialValue)
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
  fun concat vectors =
      concatSlices
          (List.map (fn vector => (vector, 0, B.length vector)) vectors)

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
      not (Option.isSome(find (fn value => not(predicate value)) vector))

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
