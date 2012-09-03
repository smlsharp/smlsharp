structure Int31 : INTEGER =
struct
  open Orig_Int31
  val fromLarge = fn x => Orig_Int31.fromLarge (Orig_Int32.toLarge x)
  val toLarge = fn x => Orig_Int32.fromLarge (Orig_Int31.toLarge x)
end

structure Int : INTEGER where type int = int =
struct
  open Orig_Int
  val fromLarge = fn x => Orig_Int.fromLarge (Orig_Int32.toLarge x)
  val toLarge = fn x => Orig_Int32.fromLarge (Orig_Int.toLarge x)
end

structure Int32 : INTEGER =
struct
  open Orig_Int32
  val fromLarge = fn x => x
  val toLarge = fn x => x
end
