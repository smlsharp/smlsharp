(*
test cases for Vector structure.
*)

val fromList_0 = CharVector.fromList ([] : char list);
val fromList_1 = CharVector.fromList [#"a"];
val fromList_2 = CharVector.fromList [#"a", #"b"];

val tabulateFun = fn x => (Char.chr (Char.ord #"a" + x));
val tabulate0 = CharVector.tabulate (0, tabulateFun);
val tabulate1 = CharVector.tabulate (1, tabulateFun);
val tabulate2 = CharVector.tabulate (2, tabulateFun);
val tabulatem1 =
    CharVector.tabulate (~1, tabulateFun) handle General.Size => "XXX";

val length1 = CharVector.length "";
val length2 = CharVector.length "a";
val length3 = CharVector.length "ab";

val sub00 = CharVector.sub ("", 0) handle General.Subscript => #"x";
val sub0m1 = CharVector.sub ("", ~1) handle General.Subscript => #"x";
val sub01 = CharVector.sub ("", 1) handle General.Subscript => #"x";
val sub10 = CharVector.sub ("a", 0);
val sub11 = CharVector.sub ("a", 1) handle General.Subscript => #"x";
val sub1m1 = CharVector.sub ("a", ~1) handle General.Subscript => #"x";
val sub20 = CharVector.sub ("ab", 0);
val sub21 = CharVector.sub ("ab", 1);
val sub22 = CharVector.sub ("ab", 2) handle General.Subscript => #"x";

(********************)

val concat0 = CharVector.concat ([] : CharVector.vector List.list);
val concat10 = CharVector.concat ([""] : CharVector.vector List.list);
val concat200 =
    CharVector.concat (["", ""] : CharVector.vector List.list);
val concat11 = CharVector.concat ["a"];
val concat201 = CharVector.concat ["", "a"];
val concat210 = CharVector.concat ["a", ""];
val concat211 = CharVector.concat ["a", "b"];
val concat222 = CharVector.concat ["ab", "cd"];
val concat3303 = CharVector.concat ["abc", "", "xyz"];
val concat3333 = CharVector.concat ["abc", "def", "ghi"];

(********************)
fun testUpdate (vector, index, newValue) =
    let val newVector = CharVector.update(vector, index, newValue)
    in (vector : string, newVector : string) end;
val update00 =
    testUpdate ("", 0, #"x") handle General.Subscript => ("a", "a");
val update0m1 =
    testUpdate ("", ~1, #"x") handle General.Subscript => ("a", "a");
val update01 =
    testUpdate ("", 1, #"x") handle General.Subscript => ("a", "a");
val update10 = testUpdate ("a", 0, #"x");
val update11 =
    testUpdate ("b", 1, #"x") handle General.Subscript => ("X", "X");
val update1m1 =
    testUpdate ("b", ~1, #"x") handle General.Subscript => ("X", "X");
val update20 = testUpdate ("ab", 0, #"x");
val update21 = testUpdate ("ab", 1, #"x");
val update22 =
    testUpdate ("ab", 2, #"x") handle General.Subscript => ("X", "X");

(********************)
val appiFun =
    fn (index, ch) => (print(Int.toString index); print(Char.toString ch));
val appi_0 = CharVector.appi appiFun "";
val appi_1 = CharVector.appi appiFun "a";
val appi_2 = CharVector.appi appiFun "ab";

(********************)
val appFun = fn x => print(Char.toString x);
val app0 = CharVector.app appFun "";
val app1 = CharVector.app appFun "a";
val app2 = CharVector.app appFun "ab";
val app3 = CharVector.app appFun "abc";

(********************)
val mapiFun = fn (index, ch) => (print(Int.toString index); ch);
val mapi_0 = CharVector.mapi mapiFun "";
val mapi_1 = CharVector.mapi mapiFun "a";
val mapi_2 = CharVector.mapi mapiFun "ab";

(********************)
val mapFun = fn x => (print(Char.toString x); Char.toUpper x);
val map0 = CharVector.map mapFun "";
val map1 = CharVector.map mapFun "a";
val map2 = CharVector.map mapFun "ab";
val map3 = CharVector.map mapFun "abc";

(********************)
val foldliFun =
    fn (index, ch, accum) =>
       (print(Int.toString index); ch :: accum : char list);
val foldli_0 = CharVector.foldli foldliFun [] "";
val foldli_1 = CharVector.foldli foldliFun [] "a";
val foldli_2 = CharVector.foldli foldliFun [] "ab";

(********************)

val foldlFun = fn (x, xs) => x :: xs : char list;
val foldl0 = CharVector.foldl foldlFun [] "";
val foldl1 = CharVector.foldl foldlFun [] "a";
val foldl2 = CharVector.foldl foldlFun [] "ab";
val foldl3 = CharVector.foldl foldlFun [] "abc";

(********************)
val foldriFun =
    fn (index, ch, accum) =>
       (print(Int.toString index); ch :: accum : char list);
val foldri_0 = CharVector.foldri foldriFun [] "";
val foldri_1 = CharVector.foldri foldriFun [] "a";
val foldri_2 = CharVector.foldri foldriFun [] "ab";
(********************)

val foldrFun = fn (x, xs) => x :: xs : char list;
val foldr0 = CharVector.foldr foldrFun [] "";
val foldr1 = CharVector.foldr foldrFun [] "a";
val foldr2 = CharVector.foldr foldrFun [] "ab";
val foldr3 = CharVector.foldr foldrFun [] "abc";

(********************)
val findiFun =
    fn (index, value) => (print (Int.toString index); value = #"x");
val findi_0 = CharVector.findi findiFun "";
val findi_1F = CharVector.findi findiFun "a";
val findi_1T = CharVector.findi findiFun "x";
val findi_2F = CharVector.findi findiFun "ab";
val findi_2T1 = CharVector.findi findiFun "ax";
val findi_2T2 = CharVector.findi findiFun "xa";
val findi_2T3 = CharVector.findi findiFun "xx";

(********************)
val findFun = fn value => (print (Char.toString value); value = #"x");
val find_0 = CharVector.find findFun "";
val find_1F = CharVector.find findFun "a";
val find_1T = CharVector.find findFun "x";
val find_2F = CharVector.find findFun "ab";
val find_2T1 = CharVector.find findFun "ax";
val find_2T2 = CharVector.find findFun "xa";
val find_2T3 = CharVector.find findFun "xx";

(********************)
val existsFun = fn value => (print (Char.toString value); value = #"x");
val exists_0 = CharVector.exists existsFun "";
val exists_1F = CharVector.exists existsFun "a";
val exists_1T = CharVector.exists existsFun "x";
val exists_2F = CharVector.exists existsFun "ab";
val exists_2T1 = CharVector.exists existsFun "ax";
val exists_2T2 = CharVector.exists existsFun "xa";
val exists_2T3 = CharVector.exists existsFun "xx";

(********************)
val allFun = fn value => (print (Char.toString value); value = #"x");
val all_0 = CharVector.all allFun "";
val all_1F = CharVector.all allFun "a";
val all_1T = CharVector.all allFun "x";
val all_2F1 = CharVector.all allFun "ab";
val all_2F2 = CharVector.all allFun "ax";
val all_2F3 = CharVector.all allFun "xa";
val all_2T = CharVector.all allFun "xx";

(********************)
val collateFun =
    fn (x : char, y) =>
       if x < y
       then General.LESS
       else if x = y then General.EQUAL else General.GREATER;
val collate00 = CharVector.collate collateFun ("", "");
val collate01 = CharVector.collate collateFun ("", "b");
val collate10 = CharVector.collate collateFun ("b", "a");
val collate11L = CharVector.collate collateFun ("b", "c");
val collate11E = CharVector.collate collateFun ("b", "b");
val collate11G = CharVector.collate collateFun ("c", "b");
val collate12L =  CharVector.collate collateFun ("b", "bc");
val collate12G =  CharVector.collate collateFun ("c", "bc");
val collate21L =  CharVector.collate collateFun ("bc", "c");
val collate21G =  CharVector.collate collateFun ("bc", "b");
val collate22L1 = CharVector.collate collateFun ("cb", "db");
val collate22L2 = CharVector.collate collateFun ("bc", "bd");
val collate22E = CharVector.collate collateFun ("bc", "bc");
val collate22G1 = CharVector.collate collateFun ("db", "cb");
val collate22G2 = CharVector.collate collateFun ("bd", "bc");
