(**
 * Vector structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Vector.sml,v 1.19 2008/03/11 08:53:57 katsu Exp $
 *)
structure Vector =
struct

  (***************************************************************************)

  type 'a vector = 'a array

  (* shared with VectorSlice. *)
  type 'a slice = 'a vector * (** start *) int * (** length *) int

  (***************************************************************************)

  (* This must be equal to the max size of heap block.
   * It is obtained from SIZE_MASK defined in Heap.hh.
   *)
  val maxLen = 0x7FFFFFF

  structure P =
  struct
    fun makeVector (intSize, initial) =
        if intSize < 0 orelse maxLen < intSize
        then raise General.Size
        else SMLSharp.PrimArray.vector(intSize, initial)
    (* ToDo : to create an empty array, new primitive should be added ? *)
    fun makeEmptyVector _ = _cast (SMLSharp.PrimArray.vector(0, 0)) : 'a vector

    fun update (array, intIndex, value) =
        SMLSharp.PrimArray.update_unsafe (array, intIndex, value)
    fun copy (src, srcIndex, dst, dstIndex, length) =
        SMLSharp.PrimArray.copy_unsafe (src, srcIndex, dst, dstIndex, length)
    fun sub (array, intIndex) = SMLSharp.PrimArray.sub_unsafe (array, intIndex)
    fun length array = SMLSharp.PrimArray.length array
  end

(*
 Ohori: This function should not be used. I will eliminate any use of this in VecorSlice later. 
*)
  fun fromList [] = P.makeEmptyVector ()
    | fromList (head :: tail) =
      let
        val bufferLength = 1 + List.length tail
        val buffer = P.makeVector (bufferLength, head)
        fun write [] _ = ()
          | write (next :: remains) index =
            (P.update (buffer, index, next); write remains (index + 1))
      in
        (* write elements from the second element. *)
        write tail 1; 
        buffer
      end

  fun tabulate (number, generator) =
      if number = 0 then P.makeEmptyVector ()
      else
        let
          val target = P.makeVector (number, generator 0)
          fun fill i = 
              if i = number
              then ()
              else (P.update(target, i, generator i); fill (i + 1))
          val _ = fill 1
        in
          target
        end

  fun length vector = P.length vector

  fun sub (vector, index) =
      if index < 0 orelse P.length vector <= index
      then raise Subscript (* if buffer = NONE, the sub always fails. *)
      else P.sub (vector, index)

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
      let
        val length = P.length vector
      in
        if length = 0 then P.makeEmptyVector()
        else
          let
            val target = P.makeVector(length, mapFun (0, P.sub(vector, 0)))
            fun fill i = 
                if i = length
                then ()
                else
                  (
                    P.update(target, i, mapFun (i, P.sub(vector, i)));
                    fill (i + 1)
                  )
            val _ = fill 1
          in
            target
          end
      end

  fun map mapFun vector = mapi (fn (_, element) => mapFun element) vector

  fun appi appFun vector = 
      foldli (fn (index, a, _) => (appFun (index, a))) () vector

  fun app appFun vector = appi (fn (_, element) => appFun element) vector

  fun update (vector, index, value) =
      if index < 0 orelse length vector <= index
      then raise General.Subscript
      else
        let fun valueOfIndex i = if i = index then value else sub (vector, i)
        in tabulate (length vector, valueOfIndex)
        end

  (** A utility for VectorSlice and other structures.*)
  fun copy {src, si, dst, di, len} =
      P.copy (src, si, dst, di, len)

  fun concatSlices (slices : 'a slice list) =
      let
        val (totalLength, initialValueOpt) =
            List.foldr
                (fn ((_, _, length), (totalLength, SOME value)) =>
                    (totalLength + length, SOME value)
                  | ((_, _, 0), (totalLength, NONE)) => (totalLength, NONE)
                  | ((vector, _, length), (totalLength, NONE)) =>
                    (totalLength + length, SOME(P.sub(vector, 0))))
                (0, NONE)
                slices
      in
        case (totalLength, initialValueOpt) of
          (0, _) => P.makeEmptyVector ()
        | (_, SOME initialValue) =>
          let
            val resultBuffer = P.makeVector(totalLength, initialValue)
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
          (List.map (fn vector => (vector, 0, P.length vector)) vectors)

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

end
