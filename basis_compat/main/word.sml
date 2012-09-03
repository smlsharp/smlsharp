functor WordFn (Orig : Orig_WORD) : WORD =
struct
  open Orig
  val fromLargeInt = fn x => Orig.fromLargeInt (Orig_Int32.toLarge x)
  val toLargeInt = fn x => Orig_Int32.fromLarge (Orig.toLargeInt x)
  val toLargeIntX = toLargeInt
end

structure Word8 = WordFn(Orig_Word8)
structure Word31 = WordFn(Orig_Word31)
structure Word = WordFn(Orig_Word)
structure Word32 = WordFn(Orig_Word32)
