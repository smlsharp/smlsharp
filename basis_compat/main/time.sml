structure Time : TIME =
struct
  open Orig_Time

  fun int32 x =
      let val max = Orig_Int32.toLarge (valOf Orig_Int32.maxInt)
      in Orig_Int32.fromLarge (Orig_LargeInt.mod (x, max))
      end

  val toSeconds = fn t => int32 (toSeconds t)
  val fromSeconds = fn n => fromSeconds (Orig_Int32.toLarge n)
  val toMilliseconds = fn t => int32 (toMilliseconds t)
  val fromMilliseconds = fn n => fromMilliseconds (Orig_Int32.toLarge n)
  val toMicroseconds = fn t => int32 (toMicroseconds t)
  val fromMicroseconds = fn n => fromMicroseconds (Orig_Int32.toLarge n)
end
