(*
test cases for Bool structure.
*)
val not_true = Bool.not Bool.true;
val not_false = Bool.not Bool.false;

val fromString_empty = Bool.fromString "";
val fromString_true = Bool.fromString "true";
val fromString_false = Bool.fromString "false";
val fromString_space_true = Bool.fromString " \t\ntrue";
val fromString_TRUE = Bool.fromString "TRUE";
val fromString_FALSE = Bool.fromString "FALSE";
val fromString_true_trailer = Bool.fromString "truefalse";

fun checkScanResult NONE = NONE
  | checkScanResult (SOME(result, substring)) =
    SOME(result, Substring.string substring);
fun checkScan string =
    checkScanResult(Bool.scan Substring.getc (Substring.full string));
val scan_empty = checkScan "";
val scan_true = checkScan "true";
val scan_false = checkScan "false";
val scan_space_true = checkScan " \t\ntrue";
val scan_TRUE = checkScan "TRUE";
val scan_FALSE = checkScan "FALSE";
val scan_true_trailer = checkScan "truefalse";

val toString_true = Bool.toString Bool.true;
val toString_false = Bool.toString Bool.false;
