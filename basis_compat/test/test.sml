structure Test = struct
  fun f x =
  let
    open Time
    open Array
    open TextIO
    open Vector
    open OS
    open Socket
    open Posix
    open Byte
    open CharArray
    open RealArray
    open Real64Array
    open Word8Array
    val a = Word8Array.array (5, 0w0)
    val _ = Byte.packString (a, 0, Substring.all x)
    val _ = Word8Array.foldr (op ::) nil a

    val _ = LargeInt.fromInt 0

    val cputimer = Timer.totalCPUTimer ()
    val {gc, sys, usr} = Timer.checkCPUTimer cputimer
    val b = Time.toSeconds sys

    val c = sys = usr

    val x = 0x7fffffff : Int32.int
    val y = Int32.toLarge x
    val z = Int32.toInt y

    val x = 0wx7fffffff : Word32.word
    val y = Word32.toLargeInt x
    val z = Int32.toInt y

    val x = Word8Array.tabulate (1, fn x => Word8.fromInt x)

    val r = Real.toLarge (Real.fromLargeInt (Int.toLarge 1))
    val s = "" ^ Real64.toString (Real64.fromLargeInt (Int.toLarge 1))
  in
    ()
  end
end
