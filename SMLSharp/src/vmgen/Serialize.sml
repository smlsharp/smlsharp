(**
 * basic serializer.
 * @author UENO Katsuhiro
 * @version $Id: Serialize.sml,v 1.4 2007/12/25 14:25:34 katsu Exp $
 *)
functor SerializeFn
(
  val dumpH : Word8Array.array * int * word -> unit
  val dumpW : Word8Array.array * int * Word32.word -> unit
  val dumpL : Word8Array.array * int * Word64.word -> unit
) =
struct

  type buf = Word8Array.array

  val dumpB = Word8Array.update
  val dumpH = dumpH
  val dumpW = dumpW
  val dumpL = dumpL

  fun dumpNB (buf, i, x) =
      dumpB (buf, i, Word8.fromInt x)
  fun dumpNH (buf, i, x) =
      dumpH (buf, i, Word.fromInt x)
  fun dumpN (buf, i, x) =
      dumpW (buf, i, Word32.fromLargeInt (Int32.toLarge x))
  fun dumpNL (buf, i, x) =
      dumpL (buf, i, Word64.fromLargeInt (Int64.toLarge x))
  fun dumpW64 (buf, i, x) =
      dumpL (buf, i, Word64.fromLarge (Word32.toLarge x))
  fun dumpN64 (buf, i, x) =
      dumpNL (buf, i, Int64.fromLarge (Int32.toLarge x))
  fun dumpWord (buf, i, x) =
      dumpW (buf, i, Word32.fromLarge (Word.toLarge x))
  fun dumpWord64 (buf, i, x) =
      dumpL (buf, i, Word64.fromLarge (Word.toLarge x))

  local
    fun dumpWs (buf, i, 0, w) = ()
      | dumpWs (buf, i, n, h::t) =
        (dumpW (buf, i, h); dumpWs (buf, i+4, n-1, t))
      | dumpWs (buf, i, n, nil) =
        (dumpW (buf, i, 0w0); dumpWs (buf, i+4, n-1, nil))
  in

  (* FIXME: presicion *)
  fun dumpF (buf, i, f) =
      dumpWs (buf, i, 2, IEEE754_64.dump (valOf (Real.fromString f)))

  fun dumpFS (buf, i, f) =
      dumpWs (buf, i, 1, IEEE754_32.dump (valOf (Real.fromString f)))

  fun dumpFL (buf, i, f) =
      dumpWs (buf, i, 4, IEEE754_80.dump (valOf (Real.fromString f)))

  end

end

local

  infix >> >>> >>>> &&& &&&&
  val (op >>) = Word.>>
  val (op >>>) = Word32.>>
  val (op >>>>) = Word64.>>
  val (op &&&) = Word32.andb
  val (op &&&&) = Word64.andb

  fun w8 w = Word8.fromInt (Word.toIntX w)
  fun w32_8 w = Word8.fromInt (Word32.toIntX w)
  fun w64_8 w = Word8.fromInt (Word64.toIntX w)

  structure DumpLE =
  struct
    fun dumpH (buf, i, x) =
        (
          Word8Array.update (buf, i+0, w8 x);
          Word8Array.update (buf, i+1, w8 (x >> 0w8))
        )

    fun dumpW (buf, i, x) =
        (
          Word8Array.update (buf, i+0, w32_8 (x &&& 0wxff));
          Word8Array.update (buf, i+1, w32_8 (x >>> 0w8));
          Word8Array.update (buf, i+2, w32_8 (x >>> 0w16));
          Word8Array.update (buf, i+3, w32_8 (x >>> 0w24))
        )

    fun dumpL (buf, i, x) =
        (
          Word8Array.update (buf, i+0, w64_8 (x &&&& 0wxff));
          Word8Array.update (buf, i+1, w64_8 (x >>>> 0w8));
          Word8Array.update (buf, i+2, w64_8 (x >>>> 0w16));
          Word8Array.update (buf, i+3, w64_8 (x >>>> 0w24));
          Word8Array.update (buf, i+4, w64_8 (x >>>> 0w32));
          Word8Array.update (buf, i+5, w64_8 (x >>>> 0w40));
          Word8Array.update (buf, i+6, w64_8 (x >>>> 0w48));
          Word8Array.update (buf, i+7, w64_8 (x >>>> 0w56))
        )
  end

  structure DumpBE =
  struct
    fun dumpH (buf, i, x) =
        (
          Word8Array.update (buf, i+1, w8 (x >> 0w8));
          Word8Array.update (buf, i+0, w8 x)
        )

    fun dumpW (buf, i, x) =
        (
          Word8Array.update (buf, i+3, w32_8 (x >>> 0w24));
          Word8Array.update (buf, i+2, w32_8 (x >>> 0w16));
          Word8Array.update (buf, i+1, w32_8 (x >>> 0w8));
          Word8Array.update (buf, i+0, w32_8 (x &&& 0wxff))
        )

    fun dumpL (buf, i, x) =
        (
          Word8Array.update (buf, i+7, w64_8 (x >>>> 0w56));
          Word8Array.update (buf, i+6, w64_8 (x >>>> 0w48));
          Word8Array.update (buf, i+5, w64_8 (x >>>> 0w40));
          Word8Array.update (buf, i+4, w64_8 (x >>>> 0w32));
          Word8Array.update (buf, i+3, w64_8 (x >>>> 0w24));
          Word8Array.update (buf, i+2, w64_8 (x >>>> 0w16));
          Word8Array.update (buf, i+1, w64_8 (x >>>> 0w8));
          Word8Array.update (buf, i+0, w64_8 (x &&&& 0wxff))
        )
  end

in

structure SerializeLE = SerializeFn(DumpLE)
structure SerializeBE = SerializeFn(DumpBE)

end
