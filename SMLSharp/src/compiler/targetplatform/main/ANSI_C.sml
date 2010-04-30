(**
 * ANSI C Target.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: ANSI_C.sml,v 1.1 2007/09/24 22:28:39 katsu Exp $
 *)

structure ANSI_C : TARGET_PLATFORM =
struct
  type uint = UInt32.word
  type sint = SInt32.int

  fun toUInt (x : UInt32.word) = x
  fun toSInt (x : SInt32.int) = x

  fun charToUInt x = BasicTypes.IntToUInt32 (ord x)
  val intToUInt = BasicTypes.IntToUInt32
  val intToSInt = BasicTypes.IntToSInt32
  val UIntToInt = BasicTypes.UInt32ToInt
  val SIntToInt = BasicTypes.SInt32ToInt
  val wordToUInt = BasicTypes.WordToUInt32
  val wordToSInt = BasicTypes.WordToSInt32
  val UIntToWord = BasicTypes.UInt32ToWord
  val SIntToWord = BasicTypes.SInt32ToWord
  val UIntToSInt = BasicTypes.UInt32ToSInt32
  val SIntToUInt = BasicTypes.SInt32ToUInt32

  fun UIntToUInt32 (x : uint) = x : UInt32.word
  fun SIntToSInt32 (x : sint) = x : SInt32.int

  val compareUInt = UInt32.compare
  val compareSInt = SInt32.compare
  val compareString = String.compare
  val formatUInt = UInt32.fmt
  val formatSInt = SInt32.fmt

  val C_UIntType  = "unsigned int"
  val C_SIntType  = "signed int"
  val C_UCharType = "unsigned char"
  val C_SCharType = "signed char"
  val C_RealType  = "double"
  val C_FloatType = "float"

  val C_UIntSuffix = "U"
  val C_SIntSuffix = ""

  val C_sizeOfInt = 0w4
  val C_sizeOfPtr = 0w4
  val C_sizeOfFloat = 0w4
  val C_sizeOfReal = 0w8
  val C_alignOfInt = C_sizeOfInt
  val C_alignOfPtr = C_sizeOfPtr
  val C_alignOfReal = C_sizeOfReal

  val C_integerBits = 0w16   (* int has at least 16 bit *)

end
