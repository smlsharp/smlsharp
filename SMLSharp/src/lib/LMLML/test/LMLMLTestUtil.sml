(**
 * Utility functions for LMLML unit test.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: LMLMLTestUtil.sml,v 1.1.2.3 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
functor LMLMLTestUtil(Codec : CODEC) =
struct

  (***************************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test

  structure MBS = Codec.String
  structure MBSS = Codec.Substring
  structure MBC = Codec.Char

  (***************************************************************************)
(*
  fun S string = MBS.stringToMBS string
*)
  fun S string = MBS.fromAsciiString string
(*
  fun C char = valOf(MBC.stringToMBC (str char))
*)
  fun C char = MBC.fromAsciiChar char

  fun SS string =
      let val stringLen = size string
      in
(*
        MBSS.substring (MBS.stringToMBS ("x" ^ string ^ "y"), 1, stringLen)
*)
        MBSS.substring (S ("x" ^ string ^ "y"), 1, stringLen)
      end

  val asciiStringToBytes =
      Word8Vector.fromList o (map (Word8.fromInt o Char.ord)) o String.explode
  val bytesToAsciiString = 
      String.implode
      o (Word8Vector.foldr (fn (b, cs) => (Char.chr o Word8.toInt) b :: cs) [])
  val asciiStringToBytesSlice = Word8VectorSlice.full o asciiStringToBytes
  val bytesSliceToAsciiString = bytesToAsciiString o Word8VectorSlice.vector

  val asciiCharToBytes = asciiStringToBytes o String.str
  fun bytesToAsciiChar bytes = String.sub(bytesToAsciiString bytes, 0)
  val asciiCharToBytesSlice = asciiStringToBytesSlice o String.str
  fun bytesSliceToAsciiChar slice =
      String.sub(bytesSliceToAsciiString slice, 0)

  structure Assert =
  struct

  open A

  val assertEqualMBC =
      assertEqual
          (fn (c1, c2) => MBC.compare (c1, c2) = EQUAL) MBC.MBCToString;

  val assertEqualMBS =
      assertEqual (fn (s1, s2) => MBS.compare (s1, s2) = EQUAL) MBS.MBSToString

  val assertEqualMBSS =
      assertEqual
          (fn (s1, s2) => MBSS.compare (s1, s2) = EQUAL)
          (MBS.MBSToString o MBSS.string)

  val assertEqualMBCOption =
      assertEqualOption assertEqualMBC

  val assertEqualMBSOption =
      assertEqualOption assertEqualMBS

  val assertEqualMBCList = assertEqualList assertEqualMBC

  val assertEqualMBSList = assertEqualList assertEqualMBS

  val assertEqualMBSSList = assertEqualList assertEqualMBSS

  val assertEqualBytes = 
      assertEqualContainer
          (Word8Vector.length, Word8Vector.sub, assertEqualWord8)

  val assertEqualBytesSlice =
      assertEqualContainer
          (Word8VectorSlice.length, Word8VectorSlice.sub, assertEqualWord8)

  end

end