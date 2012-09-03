(*
test cases for Substring structure.
*)

val ss_0 = Substring.extract ("abc", 1, SOME 0)
val ss_1 = Substring.extract ("abc", 1, SOME 1)
val ss_2 = Substring.extract ("abcd", 1, SOME 2)

fun checkSS substring =
    SOME(Substring.base substring, Substring.string substring);
fun check2SS (left, right) =
    SOME
        (
          Substring.base left, Substring.string left,
          Substring.base right, Substring.string right
        );
fun checkSSs substrings =
    map
        (fn substring =>
            (Substring.base substring, Substring.string substring))
        substrings;

(********************)
(* safe cases *)
val extract_0_0_N = checkSS(Substring.extract("", 0, NONE));
val extract_0_0_0 = checkSS(Substring.extract("", 0, SOME 0));
val extract_1_0_N = checkSS(Substring.extract("a", 0, NONE));
val extract_1_0_0 = checkSS(Substring.extract("a", 0, SOME 0));
val extract_1_0_1 = checkSS(Substring.extract("a", 0, SOME 1));
val extract_1_1_N = checkSS(Substring.extract("a", 1, NONE));
val extract_1_1_0 = checkSS(Substring.extract("a", 1, SOME 0));
val extract_2_0_N = checkSS(Substring.extract("ab", 0, NONE));
val extract_2_0_0 = checkSS(Substring.extract("ab", 0, SOME 0));
val extract_2_0_1 = checkSS(Substring.extract("ab", 0, SOME 1));
val extract_2_0_2 = checkSS(Substring.extract("ab", 0, SOME 2));
val extract_2_1_N = checkSS(Substring.extract("ab", 1, NONE));
val extract_2_1_0 = checkSS(Substring.extract("ab", 1, SOME 0));
val extract_2_1_1 = checkSS(Substring.extract("ab", 1, SOME 1));
val extract_2_2_N = checkSS(Substring.extract("ab", 2, NONE));
val extract_2_2_0 = checkSS(Substring.extract("ab", 2, SOME 0));
(* error cases *)
val extract_2_m1_N =
    checkSS(Substring.extract("ab", ~1, NONE)) handle Subscript => NONE;
val extract_2_3_N =
    checkSS(Substring.extract("ab", 3, NONE)) handle Subscript => NONE;
val extract_2_m1_0 =
    checkSS(Substring.extract("ab", ~1, SOME 0)) handle Subscript => NONE;
val extract_2_0_m1 =
    checkSS(Substring.extract("ab", ~1, SOME ~1)) handle Subscript => NONE;
val extract_2_1_2 =
    checkSS(Substring.extract("ab", 1, SOME 2)) handle Subscript => NONE;

(********************)
(* safe cases *)
val substring_0_0_0 = checkSS(Substring.substring("", 0, 0));
val substring_1_0_0 = checkSS(Substring.substring("a", 0, 0));
val substring_1_0_1 = checkSS(Substring.substring("a", 0, 1));
val substring_1_1_0 = checkSS(Substring.substring("a", 1, 0));
val substring_2_0_0 = checkSS(Substring.substring("ab", 0, 0));
val substring_2_0_1 = checkSS(Substring.substring("ab", 0, 1));
val substring_2_0_2 = checkSS(Substring.substring("ab", 0, 2));
val substring_2_1_0 = checkSS(Substring.substring("ab", 1, 0));
val substring_2_1_1 = checkSS(Substring.substring("ab", 1, 1));
val substring_2_2_0 = checkSS(Substring.substring("ab", 2, 0));
(* error cases *)
val substring_2_m1_0 =
    checkSS(Substring.substring("ab", ~1, 0)) handle Subscript => NONE;
val substring_2_0_m1 =
    checkSS(Substring.substring("ab", ~1, ~1)) handle Subscript => NONE;
val substring_2_1_2 =
    checkSS(Substring.substring("ab", 1, 2)) handle Subscript => NONE;

(********************)
val full_empty = checkSS(Substring.full "");
val full_1 = checkSS(Substring.full "a");
val full_2 = checkSS(Substring.full "ab");
val full_10 = checkSS(Substring.full "abcdefghij");

(********************)
val isEmpty_0 = Substring.isEmpty(Substring.full "");
val isEmpty_1_0_N = Substring.isEmpty(Substring.extract("a", 0, NONE));
val isEmpty_1_0_0 = Substring.isEmpty(Substring.extract("a", 0, SOME 0));
val isEmpty_1_0_1 = Substring.isEmpty(Substring.extract("a", 0, SOME 1));
val isEmpty_1_1_N = Substring.isEmpty(Substring.extract("a", 1, NONE));

(********************)
val getc_0 = Substring.getc(Substring.full "");
val getc_1_0_N = Substring.getc(Substring.extract("a", 0, NONE));
val getc_1_0_0 = Substring.getc(Substring.extract("a", 0, SOME 0));
val getc_1_0_1 = Substring.getc(Substring.extract("a", 0, SOME 1));
val getc_1_1_N = Substring.getc(Substring.extract("a", 1, NONE));

(********************)
val first_0 = Substring.first(Substring.full "");
val first_1_0_N = Substring.first(Substring.extract("a", 0, NONE));
val first_1_0_0 = Substring.first(Substring.extract("a", 0, SOME 0));
val first_1_0_1 = Substring.first(Substring.extract("a", 0, SOME 1));
val first_1_1_N = Substring.first(Substring.extract("a", 1, NONE));

(********************)
val triml_0_0 = checkSS(Substring.triml 0 (Substring.full ""));
val triml_1_0 = checkSS(Substring.triml 1 (Substring.full ""));(* safe *)
val triml_0_1 = checkSS(Substring.triml 0 (Substring.substring("abc", 1, 1)));
val triml_1_1 = checkSS(Substring.triml 1 (Substring.substring("abc", 1, 1)));
val triml_2_1 = checkSS(Substring.triml 2 (Substring.substring("abc", 1, 1)));
val triml_0_2 = checkSS(Substring.triml 0 (Substring.substring("abcd", 1, 2)));
val triml_1_2 = checkSS(Substring.triml 1 (Substring.substring("abcd", 1, 2)));
val triml_2_2 = checkSS(Substring.triml 2 (Substring.substring("abcd", 1, 2)));
val triml_3_2 = checkSS(Substring.triml 3 (Substring.substring("abcd", 1, 2)));
(* error case *)
val triml_m1 = SOME(Substring.triml ~1) handle Subscript => NONE;

(********************)
val trimr_0_0 = checkSS(Substring.trimr 0 (Substring.full ""));
val trimr_1_0 = checkSS(Substring.trimr 1 (Substring.full ""));(* safe *)
val trimr_0_1 = checkSS(Substring.trimr 0 (Substring.substring("abc", 1, 1)));
val trimr_1_1 = checkSS(Substring.trimr 1 (Substring.substring("abc", 1, 1)));
val trimr_2_1 = checkSS(Substring.trimr 2 (Substring.substring("abc", 1, 1)));
val trimr_0_2 = checkSS(Substring.trimr 0 (Substring.substring("abcd", 1, 2)));
val trimr_1_2 = checkSS(Substring.trimr 1 (Substring.substring("abcd", 1, 2)));
val trimr_2_2 = checkSS(Substring.trimr 2 (Substring.substring("abcd", 1, 2)));
val trimr_3_2 = checkSS(Substring.trimr 3 (Substring.substring("abcd", 1, 2)));
(* error case *)
val trimr_m1 = SOME(Substring.trimr ~1) handle Subscript => NONE;

(********************)
(* safe cases *)
val slice_0_0_N = checkSS(Substring.slice(ss_0, 0, NONE));
val slice_0_0_0 = checkSS(Substring.slice(ss_0, 0, SOME 0));
val slice_1_0_N = checkSS(Substring.slice(ss_1, 0, NONE));
val slice_1_0_0 = checkSS(Substring.slice(ss_1, 0, SOME 0));
val slice_1_0_1 = checkSS(Substring.slice(ss_1, 0, SOME 1));
val slice_1_1_N = checkSS(Substring.slice(ss_1, 1, NONE));
val slice_1_1_0 = checkSS(Substring.slice(ss_1, 1, SOME 0));
val slice_2_0_N = checkSS(Substring.slice(ss_2, 0, NONE));
val slice_2_0_0 = checkSS(Substring.slice(ss_2, 0, SOME 0));
val slice_2_0_1 = checkSS(Substring.slice(ss_2, 0, SOME 1));
val slice_2_0_2 = checkSS(Substring.slice(ss_2, 0, SOME 2));
val slice_2_1_N = checkSS(Substring.slice(ss_2, 1, NONE));
val slice_2_1_0 = checkSS(Substring.slice(ss_2, 1, SOME 0));
val slice_2_1_1 = checkSS(Substring.slice(ss_2, 1, SOME 1));
val slice_2_2_N = checkSS(Substring.slice(ss_2, 2, NONE));
val slice_2_2_0 = checkSS(Substring.slice(ss_2, 2, SOME 0));
(* error cases *)
val slice_2_m1_N =
    checkSS(Substring.slice(ss_2, ~1, NONE)) handle Subscript => NONE;
val slice_2_3_N =
    checkSS(Substring.slice(ss_2, 3, NONE)) handle Subscript => NONE;
val slice_2_m1_0 =
    checkSS(Substring.slice(ss_2, ~1, SOME 0)) handle Subscript => NONE;
val slice_2_0_m1 =
    checkSS(Substring.slice(ss_2, ~1, SOME ~1)) handle Subscript => NONE;
val slice_2_1_2 =
    checkSS(Substring.slice(ss_2, 1, SOME 2)) handle Subscript => NONE;

(********************)
val sub_0_0 = Substring.sub(ss_0, 0) handle Subscript => #"E";
val sub_1_m1 = Substring.sub(ss_1, ~1) handle Subscript => #"E";;
val sub_1_0 = Substring.sub(ss_1, 0);
val sub_1_1 = Substring.sub(ss_1, 1) handle Subscript => #"E";
val sub_2_m1 = Substring.sub(ss_2, ~1) handle Subscript => #"E";;
val sub_2_0 = Substring.sub(ss_2, 0);
val sub_2_1 = Substring.sub(ss_2, 1);
val sub_2_2 = Substring.sub(ss_2, 2) handle Subscript => #"E";

(********************)
val size_0 = Substring.size ss_0;
val size_1 = Substring.size ss_1;
val size_2 = Substring.size ss_2;

(********************)
val concat_0 = Substring.concat [];
val concat_1 = Substring.concat [ss_2];
val concat_2_diff = Substring.concat [ss_2, ss_1];
val concat_2_same = Substring.concat [ss_2, ss_2];
val concat_2_02 = Substring.concat [ss_0, ss_2];
val concat_2_20 = Substring.concat [ss_2, ss_0];
val concat_3_202 = Substring.concat [ss_2, ss_0, ss_2];
val concat_3_212 = Substring.concat [ss_2, ss_1, ss_2];

(********************)
val explode_0_0_0 = Substring.explode(Substring.substring("", 0, 0));
val explode_1_0_0 = Substring.explode(Substring.substring("a", 0, 0));
val explode_1_0_1 = Substring.explode(Substring.substring("a", 0, 1));
val explode_1_1_0 = Substring.explode(Substring.substring("a", 1, 0));
val explode_2_0_0 = Substring.explode(Substring.substring("ab", 0, 0));
val explode_2_0_1 = Substring.explode(Substring.substring("ab", 0, 1));
val explode_2_0_2 = Substring.explode(Substring.substring("ab", 0, 2));
val explode_2_1_0 = Substring.explode(Substring.substring("ab", 1, 0));
val explode_2_1_1 = Substring.explode(Substring.substring("ab", 1, 1));
val explode_2_2_0 = Substring.explode(Substring.substring("ab", 2, 0));

(********************)
val isPrefix_0_0 = Substring.isPrefix "" ss_0;
val isPrefix_1_0 = Substring.isPrefix "a" ss_0;
val isPrefix_0_1 =
    Substring.isPrefix "" (Substring.extract("abc", 1, SOME 1));
val isPrefix_1_1t =
    Substring.isPrefix "b" (Substring.extract("abc", 1, SOME 1));
val isPrefix_1_1f =
    Substring.isPrefix "a" (Substring.extract("abc", 1, SOME 1));
val isPrefix_1_2t =
    Substring.isPrefix "b" (Substring.extract("abc", 1, SOME 2));
val isPrefix_1_2f =
    Substring.isPrefix "a" (Substring.extract("abc", 1, SOME 2));
val isPrefix_2_2t =
    Substring.isPrefix "bc" (Substring.extract("abc", 1, SOME 2));
val isPrefix_2_2f =
    Substring.isPrefix "bd" (Substring.extract("abc", 1, SOME 2));
val isPrefix_2_3t =
    Substring.isPrefix "bc" (Substring.extract("abcde", 1, SOME 3));
val isPrefix_2_3f =
    Substring.isPrefix "bd" (Substring.extract("abcde", 1, SOME 3));
val isPrefix_3_3t =
    Substring.isPrefix "bcd" (Substring.extract("abcde", 1, SOME 3));
val isPrefix_3_3f =
    Substring.isPrefix "ccd" (Substring.extract("abcde", 1, SOME 3));

(********************)
val compare_0_0 =
    Substring.compare
    (Substring.extract("abc", 1, SOME 0), Substring.extract("xyz", 1, SOME 0));
val compare_0_1 =
    Substring.compare
    (Substring.extract("abc", 1, SOME 0), Substring.extract("xyz", 1, SOME 1));
val compare_1_0 =
    Substring.compare
    (Substring.extract("abc", 1, SOME 1), Substring.extract("xyz", 1, SOME 0));
val compare_1_1_lt =
    Substring.compare
    (Substring.extract("abc", 1, SOME 1), Substring.extract("xyz", 1, SOME 1));
val compare_1_1_eq =
    Substring.compare
    (Substring.extract("abc", 1, SOME 1), Substring.extract("xbz", 1, SOME 1));
val compare_1_1_gt =
    Substring.compare
    (Substring.extract("xyz", 1, SOME 1), Substring.extract("abc", 1, SOME 1));
val compare_1_2_lt =
    Substring.compare
    (Substring.extract("abc", 1, SOME 1), Substring.extract("xyz", 1, SOME 2));
val compare_1_2_gt =
    Substring.compare
    (Substring.extract("xyz", 1, SOME 1), Substring.extract("ayc", 1, SOME 2));
val compare_2_1_lt =
    Substring.compare
    (Substring.extract("abc", 1, SOME 2), Substring.extract("xyz", 1, SOME 1));
val compare_2_1_gt =
    Substring.compare
    (Substring.extract("xbz", 1, SOME 2), Substring.extract("abc", 1, SOME 1));
val compare_2_2_lt =
    Substring.compare
    (Substring.extract("abc", 1, SOME 2), Substring.extract("xyz", 1, SOME 2));
val compare_2_2_eq =
    Substring.compare
    (Substring.extract("abc", 1, SOME 2), Substring.extract("xbc", 1, SOME 2));
val compare_2_2_gt =
    Substring.compare
    (Substring.extract("xyz", 1, SOME 2), Substring.extract("abc", 1, SOME 2));

(********************)
(* reverse of Char.collate *)
fun collateFun (left, right : char) =
    if left < right
    then General.GREATER
    else if left = right then General.EQUAL else General.LESS;
val collate_0_0 =
    Substring.collate collateFun
    (Substring.extract("abc", 1, SOME 0), Substring.extract("xyz", 1, SOME 0));
val collate_0_1 =
    Substring.collate collateFun
    (Substring.extract("abc", 1, SOME 0), Substring.extract("xyz", 1, SOME 1));
val collate_1_0 =
    Substring.collate collateFun
    (Substring.extract("abc", 1, SOME 1), Substring.extract("xyz", 1, SOME 0));
val collate_1_1_lt =
    Substring.collate collateFun
    (Substring.extract("abc", 1, SOME 1), Substring.extract("xyz", 1, SOME 1));
val collate_1_1_eq =
    Substring.collate collateFun
    (Substring.extract("abc", 1, SOME 1), Substring.extract("xbz", 1, SOME 1));
val collate_1_1_gt =
    Substring.collate collateFun
    (Substring.extract("xyz", 1, SOME 1), Substring.extract("abc", 1, SOME 1));
val collate_1_2_lt =
    Substring.collate collateFun
    (Substring.extract("abc", 1, SOME 1), Substring.extract("xyz", 1, SOME 2));
val collate_1_2_gt =
    Substring.collate collateFun
    (Substring.extract("xyz", 1, SOME 1), Substring.extract("ayc", 1, SOME 2));
val collate_2_1_lt =
    Substring.collate collateFun
    (Substring.extract("abc", 1, SOME 2), Substring.extract("xyz", 1, SOME 1));
val collate_2_1_gt =
    Substring.collate collateFun
    (Substring.extract("xbz", 1, SOME 2), Substring.extract("abc", 1, SOME 1));
val collate_2_2_lt =
    Substring.collate collateFun
    (Substring.extract("abc", 1, SOME 2), Substring.extract("xyz", 1, SOME 2));
val collate_2_2_eq =
    Substring.collate collateFun
    (Substring.extract("abc", 1, SOME 2), Substring.extract("xbc", 1, SOME 2));
val collate_2_2_gt =
    Substring.collate collateFun
    (Substring.extract("xyz", 1, SOME 2), Substring.extract("abc", 1, SOME 2));

(********************)
fun splitFun char = char = #"A";
val splitl_0 = check2SS(Substring.splitl splitFun (Substring.full ""));
val splitl_1_f =
    check2SS(Substring.splitl splitFun (Substring.substring ("abc", 1, 1)));
val splitl_1_t =
    check2SS(Substring.splitl splitFun (Substring.substring ("aAc", 1, 1)));
val splitl_2_f =
    check2SS(Substring.splitl splitFun (Substring.substring ("abcd", 1, 2)));
val splitl_2_0 =
    check2SS(Substring.splitl splitFun (Substring.substring ("aAcd", 1, 2)));
val splitl_2_1 =
    check2SS(Substring.splitl splitFun (Substring.substring ("aaAd", 1, 2)));
val splitl_3_f =
    check2SS(Substring.splitl splitFun (Substring.substring ("abcde", 1, 3)));
val splitl_3_0 =
    check2SS(Substring.splitl splitFun (Substring.substring ("aAcAe", 1, 3)));
val splitl_3_1 =
    check2SS(Substring.splitl splitFun (Substring.substring ("abAAe", 1, 3)));
val splitl_3_2 =
    check2SS(Substring.splitl splitFun (Substring.substring ("abcAe", 1, 3)));

val splitr_0 = check2SS(Substring.splitr splitFun (Substring.full ""));
val splitr_1_f =
    check2SS(Substring.splitr splitFun (Substring.substring ("abc", 1, 1)));
val splitr_1_t =
    check2SS(Substring.splitr splitFun (Substring.substring ("aAc", 1, 1)));
val splitr_2_f =
    check2SS(Substring.splitr splitFun (Substring.substring ("abcd", 1, 2)));
val splitr_2_0 =
    check2SS(Substring.splitr splitFun (Substring.substring ("aAcd", 1, 2)));
val splitr_2_1 =
    check2SS(Substring.splitr splitFun (Substring.substring ("aaAd", 1, 2)));
val splitr_3_f =
    check2SS(Substring.splitr splitFun (Substring.substring ("abcde", 1, 3)));
val splitr_3_0 =
    check2SS(Substring.splitr splitFun (Substring.substring ("aAcAe", 1, 3)));
val splitr_3_1 =
    check2SS(Substring.splitr splitFun (Substring.substring ("abAAe", 1, 3)));
val splitr_3_2 =
    check2SS(Substring.splitr splitFun (Substring.substring ("abcAe", 1, 3)));

(********************)
val splitAt_0_0 = check2SS(Substring.splitAt(Substring.full "", 0));
val splitAt_0_m1 =
    check2SS(Substring.splitAt(Substring.full "", ~1))
    handle General.Subscript => NONE;
val splitAt_0_1 =
    check2SS(Substring.splitAt(Substring.full "", 1))
    handle General.Subscript => NONE;
val splitAt_1_0 =
    check2SS(Substring.splitAt(Substring.substring ("abc", 1, 1), 0));
val splitAt_1_1 =
    check2SS(Substring.splitAt(Substring.substring ("abc", 1, 1), 1));
val splitAt_1_2 =
    check2SS(Substring.splitAt(Substring.substring ("abc", 1, 1), 2))
    handle General.Subscript => NONE;
val splitAt_1_m1 =
    check2SS(Substring.splitAt(Substring.substring ("abc", 1, 1), ~1))
    handle General.Subscript => NONE;
val splitAt_2_0 =
    check2SS(Substring.splitAt(Substring.substring ("abcd", 1, 2), 0));
val splitAt_2_1 =
    check2SS(Substring.splitAt(Substring.substring ("abcd", 1, 2), 1));
val splitAt_2_2 =
    check2SS(Substring.splitAt(Substring.substring ("abcd", 1, 2), 2));
val splitAt_2_3 =
    check2SS(Substring.splitAt(Substring.substring ("abcd", 1, 2), 3))
    handle General.Subscript => NONE;
val splitAt_2_m1 =
    check2SS(Substring.splitAt(Substring.substring ("abcd", 1, 2), ~1))
    handle General.Subscript => NONE;
val splitAt_3_0 =
    check2SS(Substring.splitAt(Substring.substring ("abcde", 1, 3), 0));
val splitAt_3_1 =
    check2SS(Substring.splitAt(Substring.substring ("abcde", 1, 3), 1));
val splitAt_3_2 =
    check2SS(Substring.splitAt(Substring.substring ("abcde", 1, 3), 2));
val splitAt_3_3 =
    check2SS(Substring.splitAt(Substring.substring ("abcde", 1, 3), 3));
val splitAt_3_4 =
    check2SS(Substring.splitAt(Substring.substring ("abcde", 1, 3), 4))
    handle General.Subscript => NONE;
val splitAt_3_m1 =
    check2SS(Substring.splitAt(Substring.substring ("abcde", 1, 3), ~1))
    handle General.Subscript => NONE;

(********************)
val dropFun = splitFun;
val dropl_0 = checkSS(Substring.dropl dropFun (Substring.full ""));
val dropl_1_f =
    checkSS(Substring.dropl dropFun (Substring.substring ("abc", 1, 1)));
val dropl_1_t =
    checkSS(Substring.dropl dropFun (Substring.substring ("aAc", 1, 1)));
val dropl_2_f =
    checkSS(Substring.dropl dropFun (Substring.substring ("abcd", 1, 2)));
val dropl_2_0 =
    checkSS(Substring.dropl dropFun (Substring.substring ("aAcd", 1, 2)));
val dropl_2_1 =
    checkSS(Substring.dropl dropFun (Substring.substring ("aaAd", 1, 2)));
val dropl_3_f =
    checkSS(Substring.dropl dropFun (Substring.substring ("abcde", 1, 3)));
val dropl_3_0 =
    checkSS(Substring.dropl dropFun (Substring.substring ("aAcAe", 1, 3)));
val dropl_3_1 =
    checkSS(Substring.dropl dropFun (Substring.substring ("abAAe", 1, 3)));
val dropl_3_2 =
    checkSS(Substring.dropl dropFun (Substring.substring ("abcAe", 1, 3)));

val dropr_0 = checkSS(Substring.dropr dropFun (Substring.full ""));
val dropr_1_f =
    checkSS(Substring.dropr dropFun (Substring.substring ("abc", 1, 1)));
val dropr_1_t =
    checkSS(Substring.dropr dropFun (Substring.substring ("aAc", 1, 1)));
val dropr_2_f =
    checkSS(Substring.dropr dropFun (Substring.substring ("abcd", 1, 2)));
val dropr_2_0 =
    checkSS(Substring.dropr dropFun (Substring.substring ("aAcd", 1, 2)));
val dropr_2_1 =
    checkSS(Substring.dropr dropFun (Substring.substring ("aaAd", 1, 2)));
val dropr_3_f =
    checkSS(Substring.dropr dropFun (Substring.substring ("abcde", 1, 3)));
val dropr_3_0 =
    checkSS(Substring.dropr dropFun (Substring.substring ("aAcAe", 1, 3)));
val dropr_3_1 =
    checkSS(Substring.dropr dropFun (Substring.substring ("abAAe", 1, 3)));
val dropr_3_2 =
    checkSS(Substring.dropr dropFun (Substring.substring ("abcAe", 1, 3)));

(********************)
val takeFun = splitFun;
val takel_0 = checkSS(Substring.takel takeFun (Substring.full ""));
val takel_1_f =
    checkSS(Substring.takel takeFun (Substring.substring ("abc", 1, 1)));
val takel_1_t =
    checkSS(Substring.takel takeFun (Substring.substring ("aAc", 1, 1)));
val takel_2_f =
    checkSS(Substring.takel takeFun (Substring.substring ("abcd", 1, 2)));
val takel_2_0 =
    checkSS(Substring.takel takeFun (Substring.substring ("aAcd", 1, 2)));
val takel_2_1 =
    checkSS(Substring.takel takeFun (Substring.substring ("aaAd", 1, 2)));
val takel_3_f =
    checkSS(Substring.takel takeFun (Substring.substring ("abcde", 1, 3)));
val takel_3_0 =
    checkSS(Substring.takel takeFun (Substring.substring ("aAcAe", 1, 3)));
val takel_3_1 =
    checkSS(Substring.takel takeFun (Substring.substring ("abAAe", 1, 3)));
val takel_3_2 =
    checkSS(Substring.takel takeFun (Substring.substring ("abcAe", 1, 3)));

val taker_0 = checkSS(Substring.taker takeFun (Substring.full ""));
val taker_1_f =
    checkSS(Substring.taker takeFun (Substring.substring ("abc", 1, 1)));
val taker_1_t =
    checkSS(Substring.taker takeFun (Substring.substring ("aAc", 1, 1)));
val taker_2_f =
    checkSS(Substring.taker takeFun (Substring.substring ("abcd", 1, 2)));
val taker_2_0 =
    checkSS(Substring.taker takeFun (Substring.substring ("aAcd", 1, 2)));
val taker_2_1 =
    checkSS(Substring.taker takeFun (Substring.substring ("aaAd", 1, 2)));
val taker_3_f =
    checkSS(Substring.taker takeFun (Substring.substring ("abcde", 1, 3)));
val taker_3_0 =
    checkSS(Substring.taker takeFun (Substring.substring ("aAcAe", 1, 3)));
val taker_3_1 =
    checkSS(Substring.taker takeFun (Substring.substring ("abAAe", 1, 3)));
val taker_3_2 =
    checkSS(Substring.taker takeFun (Substring.substring ("abcAe", 1, 3)));

(********************)
val position_0_0 = check2SS(Substring.position "" ss_0);
val position_0_1 =
    check2SS(Substring.position "" (Substring.substring ("abc", 1, 1)));
val position_1_1_m1 =
    check2SS(Substring.position "a" (Substring.substring ("abc", 1, 1)));
val position_1_1_1 =
    check2SS(Substring.position "c" (Substring.substring ("abc", 1, 1)));
val position_1_1_0t =
    check2SS(Substring.position "b" (Substring.substring ("abc", 1, 1)));
val position_1_2_m1 =
    check2SS(Substring.position "a" (Substring.substring ("abcd", 1, 2)));
val position_1_2_0 =
    check2SS(Substring.position "b" (Substring.substring ("abcd", 1, 2)));
val position_1_2_1 =
    check2SS(Substring.position "c" (Substring.substring ("abcd", 1, 2)));
val position_1_2_2 =
    check2SS(Substring.position "d" (Substring.substring ("abcd", 1, 2)));
val position_2_1_f1 =
    check2SS(Substring.position "ab" (Substring.substring ("abc", 1, 1)));
val position_2_1_f2 =
    check2SS(Substring.position "bc" (Substring.substring ("abc", 1, 1)));
val position_2_2_m1 =
    check2SS(Substring.position "ab" (Substring.substring ("abcd", 1, 2)));
val position_2_2_0 =
    check2SS(Substring.position "bc" (Substring.substring ("abcd", 1, 2)));
val position_2_2_1 =
    check2SS(Substring.position "cd" (Substring.substring ("abcd", 1, 2)));
val position_2_2_2 =
    check2SS(Substring.position "de" (Substring.substring ("abcd", 1, 2)));
val position_2_3_m1 =
    check2SS(Substring.position "ab" (Substring.substring ("abcdef", 1, 3)));
val position_2_3_0 =
    check2SS(Substring.position "bc" (Substring.substring ("abcdef", 1, 3)));
val position_2_3_1 =
    check2SS(Substring.position "cd" (Substring.substring ("abcdef", 1, 3)));
val position_2_3_2 =
    check2SS(Substring.position "de" (Substring.substring ("abcdef", 1, 3)));
val position_2_3_3 =
    check2SS(Substring.position "ef" (Substring.substring ("abcdef", 1, 3)));
(* the 'position' must search the longest suffix. *)
val position_longest =
    check2SS(Substring.position "bc" (Substring.substring ("abcdbcf", 1, 5)));

(********************)
fun makeSpanSS string (leftStart, leftLength) (rightStart, rightLength) =
    let
      val left = Substring.substring (string, leftStart, leftLength)
      val right = Substring.substring (string, rightStart, rightLength)
    in checkSS (Substring.span (left, right))
    end;
(*
  (ls, le): the start index and the end index of left substring.
  (rs, re): the start index and the end index of right substring.
 There are 6 cases in the relation between the ls and the right substring.
  (A) ls < rs, (B) ls = rs, (C) rs < ls < re, (D) ls = re, (E) re < ls
And, same relations between the le and the right substring.
Some combinations are not considered because they are impossible. 
*)
val span_0_0_A_A = makeSpanSS "abcde" (1, 0) (3, 0);
val span_1_1_A_A = makeSpanSS "abcde" (1, 1) (3, 1);
val span_1_1_B_B = makeSpanSS "abcde" (1, 1) (1, 1);
val span_1_1_E_E =
    makeSpanSS "abcde" (3, 1) (1, 1) handle General.Span => NONE;
val span_1_2_A_A = makeSpanSS "abcde" (1, 1) (3, 2);
val span_1_2_B_B = makeSpanSS "abcde" (1, 1) (1, 2);
val span_1_2_D_D = makeSpanSS "abcde" (2, 1) (1, 2);
val span_1_2_E_E =
    makeSpanSS "abcde" (3, 1) (1, 2) handle General.Span => NONE;
val span_2_1_A_A = makeSpanSS "abcde" (1, 2) (3, 1);
val span_2_1_A_B = makeSpanSS "abcde" (1, 2) (2, 1);
val span_2_1_B_E = makeSpanSS "abcde" (1, 2) (1, 1);
val span_2_1_E_E =
    makeSpanSS "abcde" (2, 2) (1, 1) handle General.Span => NONE;
val span_2_2_A_A = makeSpanSS "abcdef" (1, 2) (3, 2);
val span_2_2_A_B = makeSpanSS "abcdef" (1, 2) (2, 2);
val span_2_2_B_D = makeSpanSS "abcdef" (1, 2) (1, 2);
val span_2_2_D_E = makeSpanSS "abcdef" (2, 2) (1, 2);
val span_2_2_E_E =
    makeSpanSS "abcdef" (3, 2) (1, 2) handle General.Span => NONE;
val span_3_1_A_A = makeSpanSS "abcdef" (1, 3) (4, 1);
val span_3_1_A_B = makeSpanSS "abcdef" (1, 3) (3, 1);
val span_3_1_A_E = makeSpanSS "abcdef" (1, 3) (2, 1);
val span_3_1_B_E = makeSpanSS "abcdef" (1, 3) (1, 1);
val span_3_1_E_E =
    makeSpanSS "abcdef" (2, 3) (1, 1) handle General.Span => NONE;
val span_3_2_A_A = makeSpanSS "abcdefg" (1, 3) (4, 2);
val span_3_2_A_B = makeSpanSS "abcdefg" (1, 3) (3, 2);
val span_3_2_A_D = makeSpanSS "abcdefg" (1, 3) (2, 2);
val span_3_2_B_E = makeSpanSS "abcdefg" (1, 3) (1, 2);
val span_3_2_D_E = makeSpanSS "abcdefg" (2, 3) (1, 2);
val span_3_2_E_E =
    makeSpanSS "abcdefg" (2, 3) (1, 2) handle General.Span => NONE;
val span_3_3_A_A = makeSpanSS "abcdefgh" (1, 3) (4, 3);
val span_3_3_A_B = makeSpanSS "abcdefgh" (1, 3) (3, 3);
val span_3_3_A_C = makeSpanSS "abcdefgh" (1, 3) (2, 3);
val span_3_3_B_D = makeSpanSS "abcdefgh" (1, 3) (1, 3);
val span_3_3_C_E = makeSpanSS "abcdefgh" (2, 3) (1, 3);
val span_3_3_D_E = makeSpanSS "abcdefgh" (3, 3) (1, 3);
val span_3_3_E_E =
    makeSpanSS "abcdefgh" (4, 3) (1, 3) handle General.Span => NONE;;
val span_2_3_A_A = makeSpanSS "abcdefg" (1, 2) (3, 3);
val span_2_3_A_B = makeSpanSS "abcdefg" (1, 2) (2, 3);
val span_2_3_B_C = makeSpanSS "abcdefg" (1, 2) (1, 3);
val span_2_3_C_D = makeSpanSS "abcdefg" (2, 2) (1, 3);
val span_2_3_D_E = makeSpanSS "abcdefg" (3, 2) (1, 3);
val span_2_3_E_E =
    makeSpanSS "abcdefg" (4, 2) (1, 3) handle General.Span => NONE;;
(* le + 1 < rs *)
val span_3_3_A_A_2 = makeSpanSS "abcdefghi" (1, 3) (5, 3);

(********************)
fun translateFun ch =
    let val string = implode [ch, ch] in print string; string end;
val translate0 =
    Substring.translate translateFun (Substring.substring ("abc", 1, 0));
val translate1 =
    Substring.translate translateFun (Substring.substring ("abc", 1, 1));
val translate2 =
    Substring.translate translateFun (Substring.substring ("abcd", 1, 2));

(********************)
fun tokensFun ch = ch = #"|";
val tokens_empty =
    checkSSs(Substring.tokens tokensFun (Substring.substring ("abc", 1, 0)));
val tokens_00 =
    checkSSs(Substring.tokens tokensFun (Substring.substring ("a|b", 1, 1)));
val tokens_01 =
    checkSSs(Substring.tokens tokensFun (Substring.substring ("a|bc", 1, 2)));
val tokens_10 =
    checkSSs(Substring.tokens tokensFun (Substring.substring ("ab|c", 1, 2)));
val tokens_11 =
    checkSSs(Substring.tokens tokensFun (Substring.substring ("ab|cd", 1, 3)));
val tokens_000 =
    checkSSs(Substring.tokens tokensFun (Substring.substring ("a||b", 1, 2)));
val tokens_001 =
    checkSSs(Substring.tokens tokensFun (Substring.substring ("a||bc", 1, 3)));
val tokens_010 =
    checkSSs(Substring.tokens tokensFun (Substring.substring ("a|b|c", 1, 3)));
val tokens_011 =
    checkSSs
    (Substring.tokens tokensFun (Substring.substring ("a|b|cd", 1, 4)));
val tokens_100 =
    checkSSs
    (Substring.tokens tokensFun (Substring.substring ("ab||c", 1, 3)));
val tokens_101 =
    checkSSs
    (Substring.tokens tokensFun (Substring.substring ("ab||cd", 1, 4)));
val tokens_110 =
    checkSSs
    (Substring.tokens tokensFun (Substring.substring ("ab|c|d", 1, 4)));
val tokens_111 =
    checkSSs
    (Substring.tokens tokensFun (Substring.substring ("ab|c|de", 1, 5)));
val tokens_222 =
    checkSSs
    (Substring.tokens tokensFun (Substring.substring ("abc|de|fgh", 1, 8)));

(********************)
fun fieldsFun ch = ch = #"|";
val fields_empty =
    checkSSs(Substring.fields fieldsFun (Substring.substring ("abc", 1, 0)));
val fields_00 =
    checkSSs(Substring.fields fieldsFun (Substring.substring ("a|b", 1, 1)));
val fields_01 =
    checkSSs(Substring.fields fieldsFun (Substring.substring ("a|bc", 1, 2)));
val fields_10 =
    checkSSs(Substring.fields fieldsFun (Substring.substring ("ab|c", 1, 2)));
val fields_11 =
    checkSSs(Substring.fields fieldsFun (Substring.substring ("ab|cd", 1, 3)));
val fields_000 =
    checkSSs(Substring.fields fieldsFun (Substring.substring ("a||b", 1, 2)));
val fields_001 =
    checkSSs(Substring.fields fieldsFun (Substring.substring ("a||bc", 1, 3)));
val fields_010 =
    checkSSs(Substring.fields fieldsFun (Substring.substring ("a|b|c", 1, 3)));
val fields_011 =
    checkSSs
    (Substring.fields fieldsFun (Substring.substring ("a|b|cd", 1, 4)));
val fields_100 =
    checkSSs
    (Substring.fields fieldsFun (Substring.substring ("ab||c", 1, 3)));
val fields_101 =
    checkSSs
    (Substring.fields fieldsFun (Substring.substring ("ab||cd", 1, 4)));
val fields_110 =
    checkSSs
    (Substring.fields fieldsFun (Substring.substring ("ab|c|d", 1, 4)));
val fields_111 =
    checkSSs
    (Substring.fields fieldsFun (Substring.substring ("ab|c|de", 1, 5)));
val fields_222 =
    checkSSs
    (Substring.fields fieldsFun (Substring.substring ("abc|de|fgh", 1, 8)));

(********************)
fun foldlFun (ch, accum) = (print (implode [ch]); ch :: accum);
val foldl_0 = Substring.foldl foldlFun [] (Substring.substring("abc", 1, 0));
val foldl_1 = Substring.foldl foldlFun [] (Substring.substring("abc", 1, 1));
val foldl_2 = Substring.foldl foldlFun [] (Substring.substring("abcd", 1, 2));
val foldl_3 = Substring.foldl foldlFun [] (Substring.substring("abcde", 1, 3));

(********************)
fun foldrFun (ch, accum) = (print (implode [ch]); ch :: accum);
val foldr_0 = Substring.foldr foldrFun [] (Substring.substring("abc", 1, 0));
val foldr_1 = Substring.foldr foldrFun [] (Substring.substring("abc", 1, 1));
val foldr_2 = Substring.foldr foldrFun [] (Substring.substring("abcd", 1, 2));
val foldr_3 = Substring.foldr foldrFun [] (Substring.substring("abcde", 1, 3));

(********************)
fun appFun ch =
    let val string = implode [ch, ch] in print string end;
val app0 = Substring.app appFun (Substring.substring ("abc", 1, 0));
val app1 = Substring.app appFun (Substring.substring ("abc", 1, 1));
val app2 = Substring.app appFun (Substring.substring ("abcd", 1, 2));

