(**
 * @copyright (c) 2006, Tohoku University.
 *)
structure SystemDefTypes =
struct

  datatype byteOrder = datatype SMLSharpConfiguration.byteOrder

  fun byteOrderToWord LittleEndian = 0w0
    | byteOrderToWord BigEndian = 0w1

  fun wordToByteOrder 0w0 = LittleEndian
    | wordToByteOrder 0w1 = BigEndian
    | wordToByteOrder w = raise Fail ("unknown byteorder:" ^ Word.toString w)

  fun byteOrderToString LittleEndian = "LittleEndian"
    | byteOrderToString BigEndian = "BigEndian"

end
