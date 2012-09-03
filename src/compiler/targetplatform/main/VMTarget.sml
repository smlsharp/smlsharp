(**
 * Virtual Machine Target.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: VMTarget.sml,v 1.1 2007/09/24 22:28:39 katsu Exp $
 *)

structure VMTarget : TARGET_PLATFORM =
struct
  structure UInt = BasicTypes.UInt32
  structure SInt = BasicTypes.SInt32
  type uint = UInt.word
  type sint = SInt.int

  fun toUInt (x : BasicTypes.UInt32) = x
  fun toSInt (x : BasicTypes.SInt32) = x

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

  fun UIntToUInt32 (x : uint) = x : BasicTypes.UInt32
  fun SIntToSInt32 (x : sint) = x : BasicTypes.SInt32

  val compareUInt = BasicTypes.UInt32.compare
  val compareSInt = BasicTypes.SInt32.compare
  val compareString = String.compare
  val formatUInt = BasicTypes.UInt32.fmt
  val formatSInt = BasicTypes.SInt32.fmt

  val C_UIntType = "unsigned int"
  val C_SIntType = "int"
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

  val C_alignOfInt   = 0w4
  val C_alignOfPtr   = 0w4
  val C_alignOfFloat = 0w4
  val C_alignOfReal  = 0w8

  val C_integerBits = 0w32
end
