(**
 * Utility functions for implementation of PRIM_CODEC.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PrimCodecUtil.sml,v 1.2.28.1 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
structure PrimCodecUtil
  : sig

      datatype range =
          (**
           * Byte (min, max) matches with a byte b,
           * if min <= b and b <= max.
           *)
          Byte of Word8.word * Word8.word

        | (**
           * Or [s1, s2, ..., sn] matches
           * with a byte sequence bs,
           * if, for any 1 <= i <= n, si matches with bs.
           *)
          Or of range list

        | (**
           * Seq [r1, r2, ..., rn] matches with a byte list [b1, b2, ..., bm],
           * if n = m and, for all 1 <= i <= n, ri matches bi.
           *)
          Seq of range list

      (**
       *  Given ranges, the nextChar makes a function which decides whether
       * the bytes sequence in a byte array matches with any range in the
       * ranges to consitute a character.
       * @params range (buffer, start)
       * @param range a list of a range and a tag
       * @param buffer a byte buffer
       * @param start the index in the buffer of the first byte of the next
       *          character.
       * @return SOME(bytes, tag, index), if the byte sequence matches the
       *      range.
       *      <ul>
       *      <li>a byte sequence of the matched region in the buffer,
       *      <li>a tag of matched range,
       *      <li>the index of the next byte following the matched region.
       *      </ul>
       *      NONE, if the byte sequence does not match the range.
       *)
      val nextChar
          : (range * 'tag) list
            -> (Word8VectorSlice.slice * int)
            -> (Word8.word list * 'tag * int) option

      (**
       * If a 32 bit word <code>w</code> is equivalent to
       * <pre>
       *   (b1 << 24) | (b2 << 16) | (b3 << 8) | b4
       * </pre>
       * (<code>b1, b2, b3, b4</code> are 1-byte values), 
       * it returns <code>[b1, b2, b3, b4]</code> .
       * @params w
       * @param w a 32 bit word
       *)
      val word32ToBytes : Word32.word -> Word8.word list

      (**
       * If a list of four 1-byte values <code>[b1, b2, b3, b4]</code>,
       * it returns a 32-bit word which is obtained by
       * <pre>
       *   (b1 << 24) | (b2 << 16) | (b3 << 8) | b4 .
       * </pre>
       * If the argument list has more than 4 elements, elements other than
       * last four elements are ignored.
       * @params bytes
       * @param a list of 1-byte values
       * @return a 32-bit word
       *)
      val bytesToWord32 : Word8.word list -> Word32.word

      (**
       * drop a sequence of zeros prefixing a byte list.
       * <p>
       * For example,
       * <pre>
       *   dropPrefixZeros [0w0, 0w0, 0w0, 0w1, 0w2]
       * </pre>
       * returns <code>[0w1, 0w2]</code>.
       * </p>
       *)
      val dropPrefixZeros : Word8.word list -> Word8.word list

    end =
struct

  structure VS = Word8VectorSlice

  datatype range =
           Byte of Word8.word * Word8.word
         | Or of range list
         | Seq of range list

  fun nextChar range (buffer, start) =
      let
        fun match index (Byte (min, max)) =
            if index < VS.length buffer
            then
              let val b = VS.sub (buffer, index)
              in
                if min <= b andalso b <= max
                then SOME(index + 1) (* return the index of next byte. *)
                else NONE
              end
            else NONE
          | match index (Seq ranges) =
            let
              fun matchSeq index [] = SOME(index)
                | matchSeq index (range :: ranges) =
                  case match index range
                   of NONE => NONE
                    | SOME(index') => matchSeq index' ranges
            in matchSeq index ranges
            end
          | match index (Or ranges) =
            let
              fun matchOr [] = NONE
                | matchOr (range :: ranges) =
                  case match index range
                   of NONE => matchOr ranges
                    | SOME(index') => SOME(index')
            in matchOr ranges
            end
        fun find [] = NONE
          | find ((range, tag) :: ranges) =
            case match start range
             of NONE => find ranges
              | SOME(next) =>
                let
                  val bytes =
                      VS.foldr
                          (fn (b, bs) => b :: bs)
                          []
                          (VS.subslice(buffer, start, SOME(next - start)))
                in
                  SOME(bytes, tag, next)
                end
      in
(*
        (print "begin nextChar";
        find range before print ".\n")
*)
        find range
      end

  local
    val W32 = Word32.fromLargeWord o Word8.toLargeWord
    val W8 = Word8.fromLargeWord o Word32.toLargeWord
    open Word32
    infix << >> orb andb
  in

  fun word32ToBytes w32 =
      map
          W8
          [
            (w32 andb 0wxFF000000) >> 0w24,
            (w32 andb 0wxFF0000) >> 0w16,
            (w32 andb 0wxFF00) >> 0w8,
            (w32 andb 0wxFF)
          ]

  fun bytesToWord32 (bytes : Word8.word list) =
      List.foldl
          (fn (byte, word) => (word << 0w8) orb (W32 byte))
          0w0
          bytes

  fun dropPrefixZeros (bytes : Word8.word list) =
      #2 (List.partition (fn b => b = 0w0) bytes)

  end

end;