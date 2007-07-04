(**
 * SMLFormat formatters for types declared in the BasicTypes structure.
 * @copyright (c) 2006, Tohoku University.
 *)
structure BasicTypeFormatters =
struct

  (***************************************************************************)

  local
    structure BT = BasicTypes
    fun prefixHex string = "0x" ^ string
    fun formatter toString value =
        let val text = toString value
        in [SMLFormat.FormatExpression.Term (size text, text)] end
  in
  val format_UInt8 = formatter BT.UInt8.toString
  val format_UInt16 = formatter BT.UInt16.toString
  val format_UInt24 = formatter BT.UInt24.toString
  val format_UInt32 = formatter BT.UInt32.toString

  val format_SInt8 = formatter BT.SInt8.toString
  val format_SInt16 = formatter BT.SInt16.toString
  val format_SInt24 = formatter BT.SInt24.toString
  val format_SInt32 = formatter BT.SInt32.toString

  val format_Real32 = formatter BT.Real32.toString
  val format_Real64 = formatter BT.Real64.toString
  end

  (***************************************************************************)

end
