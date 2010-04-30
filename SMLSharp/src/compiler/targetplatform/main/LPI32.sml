(**
 * LPI32 Target.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: LPI32.sml,v 1.1 2007/09/24 22:28:39 katsu Exp $
 *)

structure LPI32 : TARGET_PLATFORM =
struct
  structure UInt = UInt32
  structure SInt = SInt32
  type uint = UInt.word
  type sint = SInt.int

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

  val C_UIntType = "unsigned long"
  val C_SIntType = "long"
  val C_UCharType = "unsigned char"
  val C_SCharType = "signed char"
  val C_RealType = "double"
  val C_FloatType = "float"
  val C_PtrType = "void *"

  val C_UIntSuffix = "UL"
  val C_SIntSuffix = "L"

  val C_sizeOfInt = 0w4
  val C_sizeOfPtr = 0w4
  val C_sizeOfFloat = 0w4
  val C_sizeOfReal = 0w8

  val C_alignOfInt   = C_sizeOfInt     (* conservative *)
  val C_alignOfPtr   = C_sizeOfPtr     (* conservative *)
  val C_alignOfFloat = C_sizeOfFloat   (* conservative *)
  val C_alignOfReal  = C_sizeOfReal    (* conservative *)

  val C_integerBits = 0w32

end
