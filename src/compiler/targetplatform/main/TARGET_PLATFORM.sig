(**
 * Target Platform.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: TARGET_PLATFORM.sig,v 1.1 2007/09/24 22:28:39 katsu Exp $
 *)

signature TARGET_PLATFORM =
sig
  eqtype uint
  eqtype sint

  structure UInt : WORD
  sharing type uint = UInt.word
  structure SInt : INTEGER
  sharing type sint = SInt.int

  val toUInt : BasicTypes.UInt32 -> uint
  val toSInt : BasicTypes.SInt32 -> sint
  val charToUInt : char -> uint
  val intToUInt : int -> uint
  val intToSInt : int -> sint
  val UIntToInt : uint -> int
  val SIntToInt : sint -> int
  val wordToUInt : word -> uint
  val wordToSInt : word -> sint
  val UIntToWord : uint -> word
  val SIntToWord : sint -> word
  val UIntToSInt : uint -> sint
  val SIntToUInt : sint -> uint
  val compareUInt : uint * uint -> order
  val compareSInt : sint * sint -> order
  val compareString : string * string -> order

  (* kludges *)
  val UIntToUInt32 : uint -> BasicTypes.UInt32
  val SIntToSInt32 : sint -> BasicTypes.SInt32

  val formatUInt : StringCvt.radix -> uint -> string
  val formatSInt : StringCvt.radix -> sint -> string

  (* FIXME: we want more types! *)
  val C_UIntType  : string    (* "unsigned int" *)
  val C_SIntType  : string    (* "signed int" *)
  val C_UCharType : string    (* "unsigned char" *)
  val C_SCharType : string    (* "signed char" *)
  val C_RealType  : string    (* "double" *)
  val C_FloatType : string    (* "float" *)
  val C_PtrType   : string    (* "void *" *)

  val C_UIntSuffix : string   (* "U" *)
  val C_SIntSuffix : string   (* "" *)

  val C_sizeOfInt : word      (* sizeof(C_UIntType) *)
  val C_sizeOfPtr : word      (* sizeof(C_PtrType) *)
  val C_sizeOfReal : word     (* sizeof(C_RealType) *)
  val C_sizeOfFloat : word    (* sizeof(C_FloatType) *)

  val C_alignOfInt : word     (* __alignof__(C_UIntType) *)
  val C_alignOfPtr : word     (* __alignof__(C_PtrType) *)
  val C_alignOfReal : word    (* __alignof__(C_RealType) *)
  val C_alignOfFloat : word   (* __alignof__(C_FloatType) *)

  (* NOTE: According to C specification, both size and alignment of char
   *       is always 1. *)

  val C_integerBits : word

end
