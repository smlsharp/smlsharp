(*
test cases for String structure.
*)

(********************)
val size_0 = String.size "";
val size_1 = String.size "a";
val size_2 = String.size "ab";

(********************)
val sub_0_0 = String.sub("", 0) handle Subscript => #"E";
val sub_1_m1 = String.sub("a", ~1) handle Subscript => #"E";;
val sub_1_0 = String.sub("a", 0);
val sub_1_1 = String.sub("a", 1) handle Subscript => #"E";
val sub_2_m1 = String.sub("ab", ~1) handle Subscript => #"E";;
val sub_2_0 = String.sub("ab", 0);
val sub_2_1 = String.sub("ab", 1);
val sub_2_2 = String.sub("ab", 2) handle Subscript => #"E";

(********************)

(* safe cases *)
val extract_0_0_N = String.extract("", 0, NONE);
val extract_0_0_0 = String.extract("", 0, SOME 0);
val extract_1_0_N = String.extract("a", 0, NONE);
val extract_1_0_0 = String.extract("a", 0, SOME 0);
val extract_1_0_1 = String.extract("a", 0, SOME 1);
val extract_1_1_N = String.extract("a", 1, NONE);
val extract_1_1_0 = String.extract("a", 1, SOME 0);
val extract_2_0_N = String.extract("ab", 0, NONE);
val extract_2_0_0 = String.extract("ab", 0, SOME 0);
val extract_2_0_1 = String.extract("ab", 0, SOME 1);
val extract_2_0_2 = String.extract("ab", 0, SOME 2);
val extract_2_1_N = String.extract("ab", 1, NONE);
val extract_2_1_0 = String.extract("ab", 1, SOME 0);
val extract_2_1_1 = String.extract("ab", 1, SOME 1);
val extract_2_2_N = String.extract("ab", 2, NONE);
val extract_2_2_0 = String.extract("ab", 2, SOME 0);
(* error cases *)
val extract_2_m1_N =
    (String.extract("ab", ~1, NONE)) handle Subscript => "x";
val extract_2_3_N =
    (String.extract("ab", 3, NONE)) handle Subscript => "x";
val extract_2_m1_0 =
    (String.extract("ab", ~1, SOME 0)) handle Subscript => "x";
val extract_2_0_m1 =
    (String.extract("ab", ~1, SOME ~1)) handle Subscript => "x";
val extract_2_1_2 =
    (String.extract("ab", 1, SOME 2)) handle Subscript => "x";

(********************)
(* safe cases *)
val substring_0_0_0 = String.substring("", 0, 0);
val substring_1_0_0 = String.substring("a", 0, 0);
val substring_1_0_1 = String.substring("a", 0, 1);
val substring_1_1_0 = String.substring("a", 1, 0);
val substring_2_0_0 = String.substring("ab", 0, 0);
val substring_2_0_1 = String.substring("ab", 0, 1);
val substring_2_0_2 = String.substring("ab", 0, 2);
val substring_2_1_0 = String.substring("ab", 1, 0);
val substring_2_1_1 = String.substring("ab", 1, 1);
val substring_2_2_0 = String.substring("ab", 2, 0);
(* error cases *)
val substring_2_m1_0 =
    (String.substring("ab", ~1, 0)) handle Subscript => "x";
val substring_2_0_m1 =
    (String.substring("ab", ~1, ~1)) handle Subscript => "x";
val substring_2_1_2 =
    (String.substring("ab", 1, 2)) handle Subscript => "x";

(********************)
val concat2_0_0 = String.^ ("", "");
val concat2_0_1 = String.^ ("", "a");
val concat2_1_0 = String.^ ("a", "");
val concat2_1_1 = String.^ ("a", "b");
val concat2_1_2 = String.^ ("a", "bc");
val concat2_2_2 = String.^ ("ab", "bc");

(********************)
val concat_0 = String.concat [];
val concat_1 = String.concat ["ab"];
val concat_2_diff = String.concat ["ab", "a"];
val concat_2_same = String.concat ["ab", "ab"];
val concat_2_02 = String.concat ["", "ab"];
val concat_2_20 = String.concat ["ab", ""];
val concat_3_202 = String.concat ["ab", "", "ab"];
val concat_3_212 = String.concat ["ab", "a", "ab"];

(********************)

(* ToDo : test String.str *)

(********************)
val implode_0 = String.implode [];
val implode_1 = String.implode [#"a"];
val implode_2 = String.implode [#"a", #"b"];
val implode_3 = String.implode [#"a", #"b", #"c"];

(********************)
val explode_0 = String.explode("");
val explode_1 = String.explode("a");
val explode_2 = String.explode("ab");
val explode_3 = String.explode("abc");

(********************)
fun mapFun (ch : char) = #"x";
val map0 = String.map mapFun ""
val map1 = String.map mapFun "b";
val map2 = String.map mapFun "bc";

(********************)
fun translateFun ch =
    let val string = implode [ch, ch]
    in print string; string : String.string end;
val translate0 = String.translate translateFun ""
val translate1 = String.translate translateFun "b";
val translate2 = String.translate translateFun "bc";

(********************)
fun tokensFun ch = ch = #"|";
val tokens_empty = String.tokens tokensFun "";
val tokens_00 = String.tokens tokensFun "|";
val tokens_01 = String.tokens tokensFun "|b";
val tokens_10 = String.tokens tokensFun "b|";
val tokens_11 = String.tokens tokensFun "b|c";
val tokens_000 = String.tokens tokensFun "||";
val tokens_001 = String.tokens tokensFun "||b";
val tokens_010 = String.tokens tokensFun "|b|";
val tokens_011 = String.tokens tokensFun "|b|c";
val tokens_100 = String.tokens tokensFun "b||";
val tokens_101 = String.tokens tokensFun "b||c";
val tokens_110 = String.tokens tokensFun "b|c|";
val tokens_111 = String.tokens tokensFun "b|c|d";
val tokens_222 = String.tokens tokensFun "bc|de|fg";

(********************)
fun fieldsFun ch = ch = #"|";
val fields_empty = String.fields fieldsFun "";
val fields_00 = String.fields fieldsFun "|";
val fields_01 = String.fields fieldsFun "|b";
val fields_10 = String.fields fieldsFun "b|";
val fields_11 = String.fields fieldsFun "b|c";
val fields_000 = String.fields fieldsFun "||";
val fields_001 = String.fields fieldsFun "||b";
val fields_010 = String.fields fieldsFun "|b|";
val fields_011 = String.fields fieldsFun "|b|c";
val fields_100 = String.fields fieldsFun "b||";
val fields_101 = String.fields fieldsFun "b||c";
val fields_110 = String.fields fieldsFun "b|c|";
val fields_111 = String.fields fieldsFun "b|c|d";
val fields_222 = String.fields fieldsFun "bc|de|fg";

(********************)
val isPrefix_0_0 = String.isPrefix "" "";
val isPrefix_1_0 = String.isPrefix "a" "";
val isPrefix_0_1 = String.isPrefix "" "b";
val isPrefix_1_1t = String.isPrefix "b" "b";
val isPrefix_1_1f = String.isPrefix "a" "b";
val isPrefix_1_2t = String.isPrefix "b" "bc";
val isPrefix_1_2f = String.isPrefix "a" "bc";
val isPrefix_2_2t = String.isPrefix "bc" "bc";
val isPrefix_2_2f = String.isPrefix "bd" "bc";
val isPrefix_2_3t = String.isPrefix "bc" "bcd";
val isPrefix_2_3f = String.isPrefix "bd" "bcd";
val isPrefix_3_3t = String.isPrefix "bcd" "bcd";
val isPrefix_3_3f = String.isPrefix "ccd" "bcd";

(********************)
val isSuffix_0_0 = String.isSuffix "" "";
val isSuffix_1_0 = String.isSuffix "a" "";
val isSuffix_0_1 = String.isSuffix "" "b";
val isSuffix_1_1t = String.isSuffix "b" "b";
val isSuffix_1_1f = String.isSuffix "a" "b";
val isSuffix_1_2t = String.isSuffix "c" "bc";
val isSuffix_1_2f = String.isSuffix "a" "bc";
val isSuffix_2_2t = String.isSuffix "bc" "bc";
val isSuffix_2_2f = String.isSuffix "bd" "bc";
val isSuffix_2_3t = String.isSuffix "cd" "bcd";
val isSuffix_2_3f = String.isSuffix "bd" "bcd";
val isSuffix_3_3t = String.isSuffix "bcd" "bcd";
val isSuffix_3_3f = String.isSuffix "ccd" "bcd";

(********************)
val isSubstring_0_0 = String.isSubstring "" "";
val isSubstring_1_0 = String.isSubstring "a" "";
val isSubstring_0_1 = String.isSubstring "" "b";
val isSubstring_1_1t = String.isSubstring "b" "b";
val isSubstring_1_1f = String.isSubstring "a" "b";
val isSubstring_1_2t1 = String.isSubstring "c" "bc";
val isSubstring_1_2t2 = String.isSubstring "b" "bc";
val isSubstring_1_2f = String.isSubstring "a" "bc";
val isSubstring_2_2t = String.isSubstring "bc" "bc";
val isSubstring_2_2f = String.isSubstring "bd" "bc";
val isSubstring_2_3t1 = String.isSubstring "bc" "bcd";
val isSubstring_2_3t2 = String.isSubstring "cd" "bcd";
val isSubstring_2_3f = String.isSubstring "bd" "bcd";
val isSubstring_3_3t = String.isSubstring "bcd" "bcd";
val isSubstring_3_3f = String.isSubstring "ccd" "bcd";

(********************)
val compare_0_0 = String.compare ("", "");
val compare_0_1 = String.compare ("", "y");
val compare_1_0 = String.compare ("b", "");
val compare_1_1_lt = String.compare ("b", "y");
val compare_1_1_eq = String.compare ("b", "b");
val compare_1_1_gt = String.compare ("y", "b");
val compare_1_2_lt = String.compare ("b", "yz");
val compare_1_2_gt = String.compare ("y", "yc");
val compare_2_1_lt = String.compare ("bc", "y");
val compare_2_1_gt = String.compare ("bz", "b");
val compare_2_2_lt = String.compare ("bc", "yz");
val compare_2_2_eq = String.compare ("bc", "bc");
val compare_2_2_gt = String.compare ("yz", "bc");

(********************)
(* reverse of Char.collate *)
fun collateFun (left, right : char) =
    if left < right
    then General.GREATER
    else if left = right then General.EQUAL else General.LESS;
val collate_0_0 = String.collate collateFun ("", "");
val collate_0_1 = String.collate collateFun ("", "y");
val collate_1_0 = String.collate collateFun ("b", "");
val collate_1_1_lt = String.collate collateFun ("b", "y");
val collate_1_1_eq = String.collate collateFun ("b", "b");
val collate_1_1_gt = String.collate collateFun ("y", "b");
val collate_1_2_lt = String.collate collateFun ("b", "yz");
val collate_1_2_gt = String.collate collateFun ("y", "yc");
val collate_2_1_lt = String.collate collateFun ("bc", "y");
val collate_2_1_gt = String.collate collateFun ("bz", "b");
val collate_2_2_lt = String.collate collateFun ("bc", "yz");
val collate_2_2_eq = String.collate collateFun ("bc", "bc");
val collate_2_2_gt = String.collate collateFun ("yz", "bc");

(* ToDo : toString, scan, fromString, toCString, fromCString *)