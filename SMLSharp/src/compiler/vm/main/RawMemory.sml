(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: RawMemory.sml,v 1.11 2007/09/20 09:02:54 matsu Exp $
 *)
structure RawMemory : RAW_MEMORY =
struct

  (***************************************************************************)

  open BasicTypes
  structure C = Counter

  (***************************************************************************)

  type 'a pointer = ('a Array.array * UInt32)

  (***************************************************************************)

  val C.CounterSetInternal RMCounterSet =
      #addSet C.root ("RawMemory", C.ORDER_OF_ADDITION)
  val loadCounter =
      #addAccumulation RMCounterSet "load"
  val storeCounter =
      #addAccumulation RMCounterSet "store"

  fun initialize (initialValue, size) =
      (Array.array (UInt32.toInt size, initialValue), 0w0 : UInt32)
  fun seek ((array, position), offset) =
      if 0 < offset
      then (array, position + UInt32.fromInt offset)
      else (array, position - UInt32.fromInt (~offset))
  fun advance ((array, position : UInt32), count) = (array, position + count)
  fun back ((array, position : UInt32), count) = (array, position - count)
  fun offset (array, position) = position
  fun load (array, position) = 
      (#inc loadCounter (); Array.sub (array, UInt32.toInt position))
  fun store ((array, position), value) =
      (
        #inc storeCounter ();
        Array.update (array, UInt32.toInt position, value)
(*
        (* a real value occupies 2 cells, the first is a Real cell, the second is Word 0w0*)
        case value of
          RuntimeTypes.Real _ => Array.update (array, (UInt32.toInt position) + 1, RuntimeTypes.Word 0w0)
        | _ => ()
*)
      )

  fun distance ((leftArray, leftOffset), (rightArray, rightOffset)) =
      if leftArray = rightArray
      then
        if leftOffset < rightOffset
        then UInt32.- (rightOffset, leftOffset)
        else UInt32.- (leftOffset, rightOffset)
      else raise Fail "op - expects same array."
  fun (leftArray, leftOffset) < (rightArray, rightOffset) =
      leftArray = rightArray andalso UInt32.< (leftOffset, rightOffset)
  fun (leftArray, leftOffset) > (rightArray, rightOffset) =
      leftArray = rightArray andalso UInt32.> (leftOffset, rightOffset)
  fun (leftArray, leftOffset) <= (rightArray, rightOffset) =
      leftArray = rightArray andalso UInt32.<= (leftOffset, rightOffset)
  fun (leftArray, leftOffset) >= (rightArray, rightOffset) =
      leftArray = rightArray andalso UInt32.>= (leftOffset, rightOffset)
  infix ==
  fun (leftArray, leftOffset) == (rightArray, rightOffset) =
      leftArray = rightArray andalso (leftOffset : UInt32) = rightOffset

  fun compare ((leftArray, leftOffset), (rightArray, rightOffset)) =
      if leftArray = rightArray
      then UInt32.compare (leftOffset, rightOffset)
      else raise Fail "BUG: RawMemory.compare: not same array."

  fun toString (array, offset) = "0wx" ^ (UInt32.fmt StringCvt.HEX offset)

  fun map ((leftArray, leftOffset), (rightArray, rightOffset)) function =
      if leftArray <> rightArray
      then raise Fail "should point to the same memory."
      else
        let
          val results =
              ArraySlice.foldri
              (fn (m,i,z) => (fn (index, _, results) =>
                  (function (leftArray, UInt32.fromInt index)) :: results) (m + UInt32.toInt leftOffset, i, z))
              []
              (ArraySlice.slice(
                leftArray,
                UInt32.toInt leftOffset,
                SOME (UInt32.toInt(rightOffset - leftOffset)))
              )
        in
          results
        end

  (***************************************************************************)

end
