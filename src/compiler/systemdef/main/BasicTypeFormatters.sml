(**
 * SMLFormat formatters for types declared in the BasicTypes structure.
 * @copyright (c) 2006, Tohoku University.
 *)
structure BasicTypeFormatters =
struct

  (***************************************************************************)

  local
    fun prefixHex string = "0x" ^ string
    fun formatter toString value =
        let val text = toString value
        in [SMLFormat.FormatExpression.Term (size text, text)] end
  in
  val format_UInt8 = formatter UInt8.toString
  val format_UInt16 = formatter UInt16.toString
  val format_UInt24 = formatter UInt24.toString
  val format_UInt32 = formatter UInt32.toString

  val format_SInt8 = formatter SInt8.toString
  val format_SInt16 = formatter SInt16.toString
  val format_SInt24 = formatter SInt24.toString
  val format_SInt32 = formatter SInt32.toString

  val format_Real64 = formatter Real64.toString
  end

  (***************************************************************************)

end
