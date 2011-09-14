_interface "bin-prim-io.smi"
infix 6 + -
val op + = SMLSharp.Int.add
val op - = SMLSharp.Int.sub
structure Int31Imp = Int
structure PositionImp = Position
(* bin-prim-io.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

structure BinPrimIO = PrimIO (
    structure Vector = Word8Vector
    structure Array = Word8Array
    structure VectorSlice = Word8VectorSlice
    structure ArraySlice = Word8ArraySlice
    val someElem = (0w0 : Word8.word)
    type pos = Position.int
    val compare = PositionImp.compare);


