(*
test cases for StringCvt.
*)
val reader = fn [] => NONE | (head :: tail) => SOME(head, tail);

val padLeft0 = StringCvt.padLeft #"a" 0 "xx";
val padLeft1 = StringCvt.padLeft #"a" 1 "xx";
val padLeft2 = StringCvt.padLeft #"a" 2 "xx";
val padLeft3 = StringCvt.padLeft #"a" 3 "xx";
val padLeft4 = StringCvt.padLeft #"a" 4 "xx";

val padRight0 = StringCvt.padRight #"a" 0 "xx";
val padRight1 = StringCvt.padRight #"a" 1 "xx";
val padRight2 = StringCvt.padRight #"a" 2 "xx";
val padRight3 = StringCvt.padRight #"a" 3 "xx";
val padRight4 = StringCvt.padRight #"a" 4 "xx";

fun splitlFun c = c = #"a" orelse c = #"b" orelse c = #"c";
val splitl0 = StringCvt.splitl splitlFun reader [];
val splitl10 = StringCvt.splitl splitlFun reader [#"x"];
val splitl11 = StringCvt.splitl splitlFun reader [#"a"];
val splitl200 = StringCvt.splitl splitlFun reader [#"x", #"y"];
val splitl201 = StringCvt.splitl splitlFun reader [#"x", #"a"];
val splitl210 = StringCvt.splitl splitlFun reader [#"a", #"y"];
val splitl211 = StringCvt.splitl splitlFun reader [#"a", #"b"];
val splitl3000 = StringCvt.splitl splitlFun reader [#"x", #"y", #"z"];
val splitl3001 = StringCvt.splitl splitlFun reader [#"x", #"y", #"a"];
val splitl3010 = StringCvt.splitl splitlFun reader [#"x", #"a", #"z"];
val splitl3100 = StringCvt.splitl splitlFun reader [#"a", #"y", #"z"];
val splitl3110 = StringCvt.splitl splitlFun reader [#"a", #"b", #"z"];
val splitl3111 = StringCvt.splitl splitlFun reader [#"a", #"b", #"c"];

fun takelFun c = c = #"a" orelse c = #"b" orelse c = #"c";
val takel0 = StringCvt.takel takelFun reader [];
val takel10 = StringCvt.takel takelFun reader [#"x"];
val takel11 = StringCvt.takel takelFun reader [#"a"];
val takel200 = StringCvt.takel takelFun reader [#"x", #"y"];
val takel201 = StringCvt.takel takelFun reader [#"x", #"a"];
val takel210 = StringCvt.takel takelFun reader [#"a", #"y"];
val takel211 = StringCvt.takel takelFun reader [#"a", #"b"];
val takel3000 = StringCvt.takel takelFun reader [#"x", #"y", #"z"];
val takel3001 = StringCvt.takel takelFun reader [#"x", #"y", #"a"];
val takel3010 = StringCvt.takel takelFun reader [#"x", #"a", #"z"];
val takel3100 = StringCvt.takel takelFun reader [#"a", #"y", #"z"];
val takel3110 = StringCvt.takel takelFun reader [#"a", #"b", #"z"];
val takel3111 = StringCvt.takel takelFun reader [#"a", #"b", #"c"];

fun droplFun c = c = #"a" orelse c = #"b" orelse c = #"c";
val dropl0 = StringCvt.dropl droplFun reader [];
val dropl10 = StringCvt.dropl droplFun reader [#"x"];
val dropl11 = StringCvt.dropl droplFun reader [#"a"];
val dropl200 = StringCvt.dropl droplFun reader [#"x", #"y"];
val dropl201 = StringCvt.dropl droplFun reader [#"x", #"a"];
val dropl210 = StringCvt.dropl droplFun reader [#"a", #"y"];
val dropl211 = StringCvt.dropl droplFun reader [#"a", #"b"];
val dropl3000 = StringCvt.dropl droplFun reader [#"x", #"y", #"z"];
val dropl3001 = StringCvt.dropl droplFun reader [#"x", #"y", #"a"];
val dropl3010 = StringCvt.dropl droplFun reader [#"x", #"a", #"z"];
val dropl3100 = StringCvt.dropl droplFun reader [#"a", #"y", #"z"];
val dropl3110 = StringCvt.dropl droplFun reader [#"a", #"b", #"z"];
val dropl3111 = StringCvt.dropl droplFun reader [#"a", #"b", #"c"];

(*
whitespace characters are space (032), newline(010), tab(009),
carriage return(013), vertical tab(011), formfeed(012)
*)
val skipWS0 = StringCvt.skipWS reader [];
val skipWS1 = StringCvt.skipWS reader [#"a"];
val skipWS2 =
    StringCvt.skipWS
        reader [#"\032", #"\010", #"\009", #"\013", #"\011", #"\012", #"a"];

val scanStringFun =
    fn reader =>
       fn stream =>
          case reader stream of
            NONE => NONE
          | SOME(ch, newStream) => SOME((ch, ch), newStream)
val scanString0 = StringCvt.scanString scanStringFun "";
val scanString1 = StringCvt.scanString scanStringFun "a";
val scanString2 = StringCvt.scanString scanStringFun "ab";
