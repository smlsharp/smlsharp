(*
test cases for Char structure.
*)

val minChar0 = Char.minChar = (Char.chr 0);

val maxChar0 = Char.maxChar = (Char.chr Char.maxOrd);

val maxOrd0 = Char.maxOrd = (Char.ord Char.maxChar);

val ord0 = Char.ord #"\000";
val ord1 = Char.ord #"\001";

val chr064 = Char.chr 64;
val chr_minus = (Char.chr ~1) handle General.Chr => #"a";
val chr_max = (Char.chr (Char.maxOrd + 1)) handle General.Chr => #"a";

val succ_A = Char.succ #"A";
val succ_min = Char.succ Char.minChar;
val succ_max = (Char.succ Char.maxChar) handle General.Chr => #"a";

val pred_A = Char.pred #"A";
val pred_min = (Char.pred Char.minChar) handle General.Chr => #"a";
val pred_max = Char.pred Char.maxChar;

val lt_lt = Char.< (#"a", #"b");
val lt_eq = Char.< (#"a", #"a");
val lt_gt = Char.< (#"b", #"a");

val lteq_lt = Char.<= (#"a", #"b");
val lteq_eq = Char.<= (#"a", #"a");
val lteq_gt = Char.<= (#"b", #"a");

val gt_lt = Char.> (#"a", #"b");
val gt_eq = Char.> (#"a", #"a");
val gt_gt = Char.> (#"b", #"a");

val gteq_lt = Char.>= (#"a", #"b");
val gteq_eq = Char.>= (#"a", #"a");
val gteq_gt = Char.>= (#"b", #"a");

val compare_lt = Char.compare (#"a", #"b");
val compare_eq = Char.compare (#"a", #"a");
val compare_gt = Char.compare (#"b", #"a");

val contains_null = Char.contains "" #"a";
val contains_f = Char.contains "x" #"a";
val contains_t = Char.contains "a" #"a";
val contains_ff = Char.contains "xy" #"a";
val contains_ft = Char.contains "xa" #"a";
val contains_tf = Char.contains "ax" #"a";
val contains_ftf = Char.contains "xay" #"a";
val contains_tft = Char.contains "axa" #"a";

val notContains_null = Char.notContains "" #"a";
val notContains_f = Char.notContains "x" #"a";
val notContains_t = Char.notContains "a" #"a";
val notContains_ff = Char.notContains "xy" #"a";
val notContains_ft = Char.notContains "xa" #"a";
val notContains_tf = Char.notContains "ax" #"a";
val notContains_ftf = Char.notContains "xay" #"a";
val notContains_tft = Char.notContains "axa" #"a";

val toLower_A = Char.toLower #"A";(* 065 *)
val toLower_Z = Char.toLower #"Z";(* 090 *)
val toLower_a = Char.toLower #"a";(* 097 *)
val toLower_z = Char.toLower #"z";(* 122 *)
val toLower_AT = Char.toLower #"@";(* @ = 064 *)
val toLower_LQ = Char.toLower #"[";(* [ = 091 *)
val toLower_BQ = Char.toLower #"`";(* ` = 096 *)
val toLower_LB = Char.toLower #"{";(* { = 123 *)

val toUpper_A = Char.toUpper #"A";(* 065 *)
val toUpper_Z = Char.toUpper #"Z";(* 090 *)
val toUpper_a = Char.toUpper #"a";(* 097 *)
val toUpper_z = Char.toUpper #"z";(* 122 *)
val toUpper_AT = Char.toUpper #"@";(* @ = 064 *)
val toUpper_LQ = Char.toUpper #"[";(* [ = 091 *)
val toUpper_BQ = Char.toUpper #"`";(* ` = 096 *)
val toUpper_LB = Char.toUpper #"{";(* { = 123 *)

val isAlpha_A = Char.isAlpha #"A";(* 065 *)
val isAlpha_Z = Char.isAlpha #"Z";(* 090 *)
val isAlpha_a = Char.isAlpha #"a";(* 097 *)
val isAlpha_z = Char.isAlpha #"z";(* 122 *)
val isAlpha_0 = Char.isAlpha #"0";
val isAlpha_9 = Char.isAlpha #"9";
val isAlpha_F = Char.isAlpha #"F";
val isAlpha_AT = Char.isAlpha #"@";(* @ = 064 *)
val isAlpha_LQ = Char.isAlpha #"[";(* [ = 091 *)
val isAlpha_BQ = Char.isAlpha #"`";(* ` = 096 *)
val isAlpha_LB = Char.isAlpha #"{";(* { = 123 *)

(* ToDo : test of other functions (isALphaNum, isAscii, ...) *)

val fromString_empty = Char.fromString "";
val fromString_A = Char.fromString "A";
val fromString_ABC = Char.fromString "ABC";
val fromString_alert = Char.fromString "\\a";
val fromString_backspace = Char.fromString "\\b";
val fromString_tab = Char.fromString "\\t";
val fromString_linefeed = Char.fromString "\\n";
val fromString_vtab = Char.fromString "\\v";
val fromString_formfeed = Char.fromString "\\f";
val fromString_return = Char.fromString "\\r";
val fromString_backslash = Char.fromString "\\\\";
val fromString_dquote = Char.fromString "\\\"";
val fromString_ctrl064 = Char.fromString "\\^@";
val fromString_ctrl095 = Char.fromString "\\^_";
val fromString_dec000 = Char.fromString "\\000";
val fromString_dec255 = Char.fromString "\\255";
(*
val fromString_hex0000 = Char.fromString "\\u0000";
val fromString_hex007e = Char.fromString "\\u007e";(* ~ *)
val fromString_hex007E = Char.fromString "\\u007E";
*)
val fromString_multiBySpace = Char.fromString "\\ \\def";
val fromString_multiByTab = Char.fromString "\\\t\\def";
val fromString_multiByNewline = Char.fromString "\\\n\\def";
val fromString_multiByFormfeed = Char.fromString "\\\f\\def";
val fromString_invalidEscape = Char.fromString "\\q";

fun scanTest string =
    Char.scan
        (fn [] => NONE | (head :: tail) => SOME(head, tail))
        (explode string);
val scan_empty = scanTest "";
val scan_A = scanTest "A";
val scan_ABC = scanTest "ABC";
val scan_alert = scanTest "\\a";
val scan_backspace = scanTest "\\b";
val scan_tab = scanTest "\\t";
val scan_linefeed = scanTest "\\n";
val scan_vtab = scanTest "\\v";
val scan_formfeed = scanTest "\\f";
val scan_return = scanTest "\\r";
val scan_backslash = scanTest "\\\\";
val scan_dquote = scanTest "\\\"";
val scan_ctrl064 = scanTest "\\^@";
val scan_ctrl095 = scanTest "\\^_";
val scan_dec000 = scanTest "\\000";
val scan_dec255 = scanTest "\\255";
(*
val scan_hex0000 = scanTest "\\u0000";
val scan_hex007e = scanTest "\\u007e";(* ~ *)
val scan_hex007E = scanTest "\\u007E";
*)
val scan_multiBySpace = scanTest "\\ \\def";
val scan_multiByTab = scanTest "\\\t\\def";
val scan_multiByNewline = scanTest "\\\n\\def";
val scan_multiByFormfeed = scanTest "\\\f\\def";
val scan_invalidEscape = scanTest "\\q";

val toString_A = Char.toString #"A";
val toString_alert = Char.toString #"\a";
val toString_backspace = Char.toString #"\b";
val toString_tab = Char.toString #"\t";
val toString_linefeed = Char.toString #"\n";
val toString_vtab = Char.toString #"\v";
val toString_formfeed = Char.toString #"\f";
val toString_return = Char.toString #"\r";
val toString_backslash = Char.toString #"\\";
val toString_dquote = Char.toString #"\"";
val toString_ctrl064 = Char.toString #"\^@";
val toString_ctrl095 = Char.toString #"\^_";
val toString_dec000 = Char.toString #"\000";
val toString_dec255 = Char.toString #"\255";
(*
val toString_hex0000 = Char.toString #"\u0000";
val toString_hex007e = Char.toString #"\u007e";(* ~ *)
val toString_hex007E = Char.toString #"\u007E";
*)

val toCString_A = Char.toCString #"A";
val toCString_alert = Char.toCString #"\a";
val toCString_backspace = Char.toCString #"\b";
val toCString_tab = Char.toCString #"\t";
val toCString_linefeed = Char.toCString #"\n";
val toCString_vtab = Char.toCString #"\v";
val toCString_formfeed = Char.toCString #"\f";
val toCString_return = Char.toCString #"\r";
val toCString_backslash = Char.toCString #"\\";
val toCString_dquote = Char.toCString #"\"";
val toCString_squote = Char.toCString #"'";
val toCString_question = Char.toCString #"?";
val toCString_ctrl064 = Char.toCString #"\^@";
val toCString_ctrl095 = Char.toCString #"\^_";
val toCString_dec000 = Char.toCString #"\000";
val toCString_dec255 = Char.toCString #"\255";

val fromCString_empty = Char.fromCString "";
val fromCString_A = Char.fromCString "A";
val fromCString_ABC = Char.fromCString "ABC";
val fromCString_alert = Char.fromCString "\\a";
val fromCString_backspace = Char.fromCString "\\b";
val fromCString_tab = Char.fromCString "\\t";
val fromCString_linefeed = Char.fromCString "\\n";
val fromCString_vtab = Char.fromCString "\\v";
val fromCString_formfeed = Char.fromCString "\\f";
val fromCString_return = Char.fromCString "\\r";
val fromCString_backslash = Char.fromCString "\\\\";
val fromCString_dquote = Char.fromCString "\\\"";
val fromCString_squote = Char.fromCString "\\'";
val fromCString_question = Char.fromCString "\\?";
val fromCString_ctrl064 = Char.fromCString "\\^@";
val fromCString_ctrl095 = Char.fromCString "\\^_";
val fromCString_oct000 = Char.fromCString "\\000";
val fromCString_oct101 = Char.fromCString "\\101";(* 0x41 = A *)
val fromCString_hex00 = Char.fromCString "\\x00";
val fromCString_hex7e = Char.fromCString "\\x7e";(* ~ *)
val fromCString_hex7E = Char.fromCString "\\x7E";
