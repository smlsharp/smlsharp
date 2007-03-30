(**
 * A wrapper module of the iconv (3C) function of POSIX.
 * @author YAMATODANI Kiyoshi
 * @version $Id: IConv.sml,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
structure IConv
  : sig

      (** The conversion from fromcode to tocode is not supported. *)
      exception ConverterNotFound

      (** converts a serialized representation of a multibyte string from one
       * encoding to another encoding. *)
      val conv
          : {from : string, to : string}
            -> Word8VectorSlice.slice
            -> Word8VectorSlice.slice

    end =
struct

  exception ConverterNotFound

  (*
   * #include <iconv.h>
   * iconv_t iconv_open (const char* tocode, const char* fromcode);
   * int iconv_close (iconv_t cd);
   * size_t iconv (iconv_t cd,
   *               const char* * inbuf, size_t * inbytesleft,
   *               char* * outbuf, size_t * outbytesleft); 
   *)

  val iconv_open =
      _external IConvFFI.nameOfIconv_open of IConvFFI.libIConvName
          : {string, string} -> word;
  val iconv_close =
      _external IConvFFI.nameOfIconv_close of IConvFFI.libIConvName
          : {word} -> int;
  val iconv =
      _external IConvFFI.nameOfIconv of IConvFFI.libIConvName
          : {word, word ref, word ref, word ref, word ref} -> int;

  structure V = Word8Vector;
  structure VS = Word8VectorSlice;
  structure UM = UnmanagedMemory;

  fun conv {from, to} buffer =
      let
        val CD = iconv_open (to, from)
        val _ = if ~1 = Word.toInt CD
                then raise ConverterNotFound
                else ()

        val inBufferSize = V.length buffer
        val rawInBufferRef = ref (UM.export buffer)
        val inBytesLeft = ref (Word.fromInt inBufferSize)
        val outBufferSize = inBufferSize * 2
        val rawOutBuffer = UM.allocate outBufferSize

        (* iconv on Cygwin converts one character at a time.
         *)
        fun loop outBuffers =
            let
              val outBytesLeft = ref (Word.fromInt outBufferSize)
              val rawOutBufferRef = ref rawOutBuffer
              val result =
                  iconv
                      (
                        CD,
                        rawInBufferRef, inBytesLeft,
                        rawOutBufferRef, outBytesLeft
                      )
              (* ToDo : check error code. If it is E2BIG, reallocate larger
               * buffer and retry. *)
              val _ = if ~1 = result then raise Fail "error" else ()
              val outBuffer =
                  UM.import
                      (
                        rawOutBuffer,
                        outBufferSize - Word.toInt (!outBytesLeft)
                      )
            in
              if 0w0 = !inBytesLeft
              then V.concat(List.rev (outBuffer :: outBuffers))
              else loop (outBuffer :: outBuffers)
            end
        val outBuffers = loop []
      in
        iconv_close CD;
        UM.release rawOutBuffer;
        VS.full outBuffers
      end

end;
