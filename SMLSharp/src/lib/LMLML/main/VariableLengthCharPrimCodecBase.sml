(**
 * generator of a primitive codec module for a codec.
 * <p>
 * It requires that the codec satisfies the following condition.
 * <ul>
 *   <li>Encoding is stateless.
 *     </li>
 *   <li>ASCII characters are encoded in one byte of less than or equal to 127.
 *     </li>
 * </ul>
 * </p>
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: VariableLengthCharPrimCodecBase.sml,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
functor VariableLengthCharPrimCodecBase
            (P
             : sig
               type tag
               val maxOrdw : Word32.word
               val minOrdw : Word32.word
               val names : String.string list
               val table : (PrimCodecUtil.range * tag) list
               val getOrd : Word8.word list * tag -> Word32.word
               val convert
                   : String.string
                     -> (Word8.word list * tag) list
                     -> Word8VectorSlice.slice
               val encodeChar : Word32.word -> Word8.word list
             end) : PRIM_CODEC =
struct

  structure V = Vector
  structure VS = VectorSlice
  structure BV = Word8Vector
  structure BVS = Word8VectorSlice

  (**
   * A multibyte string is represented as a triple of a byte array and an
   * array of character's offsets in the byte array, and the offset of end
   * of the characters sequence.
   * <p>
   * For example, a multibyte string represented as
   * <pre>
   *   MBS([b1, b2, b3, b4, b5], [0, 2], 4)
   * </pre>
   * consists of two characters [b1, b2] and [b3, b4].
   * </p>
   *)
  datatype string = MBS of BV.vector * int VectorSlice.slice * int

  (** A character extracted from a multibyte string is represented as a pair
   * of the string and the index of the character in the string.
   * <p>
   * For example, the following represents a character encoded as [b3, b4].
   * <pre>
   *   (MBS([b1, b2, b3, b4, b5], [0, 2], 4), 1)
   * </pre>
   * </p>
   *)
  type char = string * int

  val emptyString = MBS(BV.fromList [], VS.full(V.fromList []), 0)

  val names = P.names

  val nextChar = PrimCodecUtil.nextChar P.table

  fun decode bufferSlice =
      let
        (* we want character offset in the base array, not in the vector slice.
         *)
        val (buffer, start, length) = BVS.base bufferSlice
        fun collect index offsets =
            case nextChar (bufferSlice, index)
             of SOME(_, _, index') => collect index' (start + index :: offsets)
              | NONE => (List.rev offsets, index)
        val (offsets, last) = collect 0 []
      in
(*
        print "[";
        app (fn i => print (Int.toString i ^ ",")) indexes;
        print "]";
*)
        MBS(buffer, VS.full(V.fromList offsets), last)
      end

  fun getRangeInBytes (MBS(buffer, offsets, last)) =
      if VS.isEmpty offsets
      then NONE
      else SOME(VS.sub (offsets, 0), last)

  fun encode (string as MBS(buffer, _, _)) =
      case getRangeInBytes string
       of SOME(startOffset, endOffset) =>
          BVS.slice (buffer, startOffset, SOME (endOffset - startOffset))
        | NONE => BVS.full(BV.fromList [])

  fun convert targetCodec =
      let val converter = P.convert targetCodec
      in
        fn (MBS(buffer, offsets, last)) =>
           let
             val bufferSlice = BVS.full buffer
             fun collect index chars =
                 case nextChar (bufferSlice, VS.sub(offsets, index))
                  of SOME(bytes, tag, _) =>
                     collect (index + 1) ((bytes, tag) :: chars)
                   | NONE => List.rev chars
             val chars = collect 0 []
           in
             converter chars
           end
      end

  fun sub (string as MBS(_, offsets, _), index) =
      if 0 <= index andalso index < VS.length offsets
      then (string, index)
      else raise Subscript

  fun substring (MBS(buffer, offsets, last), start, length) =
      let
        val offsets' = VS.subslice (offsets, start, SOME length)
        val last' =
            if start + length < VS.length offsets
            then VS.sub (offsets, start + length)
            else last
      in MBS(buffer, offsets', last')
      end

  fun size (MBS(_, offsets, _)) = VS.length offsets

  fun concat [] = emptyString
    | concat [string] = string
(*
    | concat strings = decode (BVS.full (BVS.concat (List.map encode strings)))
*)
    | concat strings =
      let
        fun f (
                string as MBS(buffer, offsets, last),
                (buffers, offsetss, totalBytes)
              ) =
            case getRangeInBytes string
             of SOME(startOffset, lastOffset) =>
                let
                  val numBytes = lastOffset - startOffset
                  val buffer' =
                      BVS.slice(buffer, startOffset, SOME numBytes)
                  (* shift every offsets *)
                  val offsets' =
                      VS.map
                          (fn offset => offset - startOffset + totalBytes)
                          offsets
                  val totalBytes' = totalBytes + numBytes
                in
                  (buffer' :: buffers, offsets' :: offsetss, totalBytes')
                end
              | NONE => (buffers, offsetss, totalBytes)
        val (buffers, offsetss, totalBytes) = List.foldl f ([], [], 0) strings
        val buffer = BVS.concat(List.rev buffers)
        val offsets = VS.full(V.concat(List.rev offsetss))
      in
        MBS(buffer, offsets, totalBytes)
      end            

  fun minOrdw () = P.minOrdw
  fun maxOrdw () = P.maxOrdw

  fun ordw (MBS(buffer, cursor, _), index) =
      let val offset = VS.sub (cursor, index)
      in
        case nextChar (BVS.full buffer, offset)
         of SOME(bytes, tag, _) => P.getOrd (bytes, tag)
          | NONE => raise Codecs.BadFormat
      end

  fun chrw charCode =
      (decode (BVS.full(BV.fromList(P.encodeChar charCode))), 0)

  fun toAsciiChar char =
      let val charCode = ordw char
      in
        if charCode <= 0w127
        then SOME(Char.chr (Word32.toInt charCode))
        else NONE
      end

  fun fromAsciiChar char =
      let val mbs = decode(BVS.full(BV.fromList[Word8.fromInt(Char.ord char)]))
      in if 0 < size mbs then (mbs, 0) else raise General.Chr
      end

  fun charToString (MBS(buffer, offsets, last), index) =
      let
        val last' =
            if index + 1 < VS.length offsets
            then VS.sub(offsets, index + 1)
            else last
      in
        MBS(buffer, VS.subslice(offsets, index, SOME 1), last')
      end

  local
    fun nextAsciiChar (MBS(buffer, offsets, _), index) =
        case nextChar (BVS.full buffer, VS.sub(offsets, index))
         of SOME([b1], tag, _) => SOME(Char.chr (Word8.toInt b1))
          | _ => NONE
    fun mapCharPred f char =
        case nextAsciiChar char of SOME(c) => f c | NONE => false
  in

  fun compareChar
          (
            (MBS(buffer1, offsets1, _), index1),
            (MBS(buffer2, offsets2, _), index2)
          ) =
        case
          (
            nextChar (BVS.full buffer1, VS.sub(offsets1, index1)), 
            nextChar (BVS.full buffer2, VS.sub(offsets2, index2))
          )
         of (SOME(bytes1, _, _), SOME(bytes2, _, _)) =>
            (* ToDo : is this correct? *)
            List.collate Word8.compare (bytes1, bytes2)
          | (NONE, NONE) => General.EQUAL
          | (NONE, SOME _) => General.LESS
          | (SOME _, NONE) => General.GREATER

  fun isAscii cursor = Option.isSome(nextAsciiChar cursor)
  val isSpace = mapCharPred Char.isSpace
  val isLower = mapCharPred Char.isLower
  val isUpper = mapCharPred Char.isUpper
  val isDigit = mapCharPred Char.isDigit
  val isHexDigit = mapCharPred Char.isHexDigit
  val isPunct = mapCharPred Char.isPunct
  val isGraph = mapCharPred Char.isGraph
  val isCntrl = mapCharPred Char.isCntrl
  end

end
