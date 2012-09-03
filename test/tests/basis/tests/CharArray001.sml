(*
test cases for Array structure.
*)

fun L2A list = CharArray.fromList list;
fun L2V list = CharVector.fromList list;
fun S2A string = L2A (String.explode string);
fun A2L array =
    let
      val length = CharArray.length array
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (CharArray.sub(array, n) :: accum)
    in scan (length - 1) [] : char list
    end;
fun V2L vector =
    let
      val length = CharVector.length vector
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (CharVector.sub(vector, n) :: accum)
    in scan (length - 1) [] : char list
    end;

val array_0i = A2L(CharArray.array(0, #"a"));
val array_1i = A2L(CharArray.array(1, #"a"));
val array_2i = A2L(CharArray.array(2, #"a"));
val array_m1i = A2L(CharArray.array(~1, #"a")) handle General.Size => [#"X"];

val fromList_0i = A2L(CharArray.fromList ([] : char list));
val fromList_1i = A2L(CharArray.fromList [#"a"]);
val fromList_2i = A2L(CharArray.fromList [#"a", #"b"]);

val tabulateFun = fn x => Char.chr x;
val tabulate0 = A2L(CharArray.tabulate (0, tabulateFun));
val tabulate1 = A2L(CharArray.tabulate (1, tabulateFun));
val tabulate2 = A2L(CharArray.tabulate (2, tabulateFun));
val tabulatem1 =
    A2L(CharArray.tabulate (~1, tabulateFun)) handle General.Size => [#"X"];

val length1 = CharArray.length (L2A[]);
val length2 = CharArray.length (L2A[#"A"]);
val length3 = CharArray.length (L2A[#"A", #"B"]);

val sub00 = CharArray.sub ((L2A[]), 0) handle General.Subscript => #"X";
val sub0m1 = CharArray.sub ((L2A[]), ~1) handle General.Subscript => #"X";
val sub01 = CharArray.sub ((L2A[]), 1) handle General.Subscript => #"X";
val sub10 = CharArray.sub ((L2A[#"a"]), 0);
val sub11 = CharArray.sub ((L2A[#"b"]), 1) handle General.Subscript => #"X";
val sub1m1 = CharArray.sub ((L2A[#"b"]), ~1) handle General.Subscript => #"X";
val sub20 = CharArray.sub ((L2A[#"a", #"b"]), 0);
val sub21 = CharArray.sub ((L2A[#"a", #"b"]), 1);
val sub22 =
    CharArray.sub ((L2A[#"a", #"b"]), 2) handle General.Subscript => #"X";

(********************)
fun testUpdate (array, index, newValue) =
    (CharArray.update(array, index, newValue); A2L(array));
val update00 =
    testUpdate ((L2A[]), 0, #"A") handle General.Subscript => [#"a"];
val update0m1 =
    testUpdate ((L2A[]), ~1, #"A") handle General.Subscript => [#"a"];
val update01 =
    testUpdate ((L2A[]), 1, #"A") handle General.Subscript => [#"a"];
val update10 = testUpdate ((L2A[#"a"]), 0, #"A");
val update11 =
    testUpdate ((L2A[#"b"]), 1, #"A") handle General.Subscript => [#"X"];
val update1m1 =
    testUpdate ((L2A[#"b"]), ~1, #"A") handle General.Subscript => [#"X"];
val update20 = testUpdate ((L2A[#"a", #"b"]), 0, #"A");
val update21 = testUpdate ((L2A[#"a", #"b"]), 1, #"A");
val update22 =
    testUpdate ((L2A[#"a", #"b"]), 2, #"A") handle General.Subscript => [#"X"];

(********************)
val vector_0 = CharArray.vector (L2A[]);
val vector_1 = CharArray.vector (L2A[#"a"]);
val vector_2 = CharArray.vector (L2A[#"a", #"b"]);

(********************)

fun testCopy (src, dst, di) =
    (CharArray.copy {src = src, dst = dst, di = di}; (A2L src, A2L dst));
(* variation of length of src array *)
val copy_0_3_0 = testCopy(L2A[], L2A[#"z", #"y", #"x"], 0);
val copy_1_3_0 = testCopy(L2A[#"a"], L2A[#"z", #"y", #"x"], 0);
val copy_2_3_0 = testCopy(L2A[#"a", #"b"], L2A[#"z", #"y", #"x"], 0);
(* variation of length of dst array *)
val copy_3_0_0 =
    testCopy(L2A[#"a", #"b", #"c"], L2A[], 0)
    handle Subscript => ([#"X"], [#"X"]);
val copy_3_1_0 =
    testCopy(L2A[#"a", #"b", #"c"], L2A[#"z"], 0)
    handle Subscript => ([#"X"], [#"X"]);
val copy_3_2_0 =
    testCopy(L2A[#"a", #"b", #"c"], L2A[#"z", #"y"], 0)
    handle Subscript => ([#"X"], [#"X"]);
val copy_3_3_0 =
    testCopy(L2A[#"a", #"b", #"c"], L2A[#"z", #"y", #"x"], 0);
val copy_3_4_0 =
    testCopy(L2A[#"a", #"b", #"c"], L2A[#"z", #"y", #"x", #"w"], 0);
(* variation of di *)
val copy_3_4_m1 =
    testCopy(L2A[#"a", #"b", #"c"], L2A[#"z", #"y", #"x", #"w"], ~1)
    handle Subscript => ([#"X"], [#"X"]);
val copy_3_4_0 =
    testCopy(L2A[#"a", #"b", #"c"], L2A[#"z", #"y", #"x", #"w"], 0);
val copy_3_4_1 =
    testCopy(L2A[#"a", #"b", #"c"], L2A[#"z", #"y", #"x", #"w"], 1);
val copy_3_4_2 =
    testCopy(L2A[#"a", #"b", #"c"], L2A[#"z", #"y", #"x", #"w"], 2)
    handle Subscript => ([#"X"], [#"X"]);

(********************)
fun testCopyVec (src, dst, di) =
    (CharArray.copyVec {src = src, dst = dst, di = di}; (V2L src, A2L dst));
(* variation of length of src array *)
val copyVec_0_3_0 = testCopyVec(L2V[], L2A[#"z", #"y", #"x"], 0);
val copyVec_1_3_0 = testCopyVec(L2V[#"a"], L2A[#"z", #"y", #"x"], 0);
val copyVec_2_3_0 = testCopyVec(L2V[#"a", #"b"], L2A[#"z", #"y", #"x"], 0);
(* variation of length of dst array *)
val copyVec_3_0_0 =
    testCopyVec(L2V[#"a", #"b", #"c"], L2A[], 0)
    handle Subscript => ([#"X"], [#"X"]);
val copyVec_3_1_0 =
    testCopyVec(L2V[#"a", #"b", #"c"], L2A[#"z"], 0)
    handle Subscript => ([#"X"], [#"X"]);
val copyVec_3_2_0 =
    testCopyVec(L2V[#"a", #"b", #"c"], L2A[#"z", #"y"], 0)
    handle Subscript => ([#"X"], [#"X"]);
val copyVec_3_3_0 =
    testCopyVec(L2V[#"a", #"b", #"c"], L2A[#"z", #"y", #"x"], 0);
val copyVec_3_4_0 =
    testCopyVec (L2V[#"a", #"b", #"c"], L2A[#"z", #"y", #"x", #"w"], 0);
(* variation of di *)
val copyVec_3_4_m1 =
    testCopyVec (L2V[#"a", #"b", #"c"], L2A[#"z", #"y", #"x", #"w"], ~1)
    handle Subscript => ([#"X"], [#"X"]);
val copyVec_3_4_0 =
    testCopyVec (L2V[#"a", #"b", #"c"], L2A[#"z", #"y", #"x", #"w"], 0);
val copyVec_3_4_1 =
    testCopyVec (L2V[#"a", #"b", #"c"], L2A[#"z", #"y", #"x", #"w"], 1);
val copyVec_3_4_2 =
    testCopyVec(L2V[#"a", #"b", #"c"], L2A[#"z", #"y", #"x", #"w"], 2)
    handle Subscript => ([#"X"], [#"X"]);

(********************)
val appiFun =
    fn (index, ch) => (print(Int.toString index); print(Char.toString ch));
(* safe cases *)
val appi_0 = SOME(CharArray.appi appiFun (S2A""));
val appi_1 = SOME(CharArray.appi appiFun (S2A"a"));
val appi_2 = SOME(CharArray.appi appiFun (S2A"ab"));

(********************)
val appFun = fn x => print (Char.toString x);
val app0 = CharArray.app appFun (L2A[]);
val app1 = CharArray.app appFun (L2A[#"a"]);
val app2 = CharArray.app appFun (L2A[#"a", #"b"]);
val app3 = CharArray.app appFun (L2A[#"a", #"b", #"c"]);

(********************)
val modifyiFun =
    fn (index, ch) => (print(Int.toString index); Char.toUpper ch);
fun testModifyi array =(CharArray.modifyi modifyiFun array; A2L array);
val modifyi_0 = testModifyi (S2A"");
val modifyi_1 = testModifyi (S2A"a");
val modifyi_2 = testModifyi (S2A"ab");

(********************)
val modifyFun = fn x => (print(Char.toString x); Char.toUpper x);
fun testModify array = (CharArray.modify modifyFun array; A2L array);
val modify0 = testModify (L2A[]);
val modify1 = testModify (L2A[#"a"]);
val modify2 = testModify (L2A[#"a", #"b"]);
val modify3 = testModify (L2A[#"a", #"b", #"c"]);

(********************)
val foldliFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
val foldli_0 = CharArray.foldli foldliFun [] (S2A"");
val foldli_1 = CharArray.foldli foldliFun [] (S2A"a");
val foldli_2 = CharArray.foldli foldliFun [] (S2A"ab");
(********************)

val foldlFun = fn (x, xs) => x :: xs;
val foldl0 = CharArray.foldl foldlFun [] ((L2A[]) : CharArray.array);
val foldl1 = CharArray.foldl foldlFun [] (L2A[#"a"]);
val foldl2 = CharArray.foldl foldlFun [] (L2A[#"a", #"b"]);
val foldl3 = CharArray.foldl foldlFun [] (L2A[#"a", #"b", #"c"]);

(********************)
val foldriFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
val foldri_0 = CharArray.foldri foldriFun [] (S2A"");
val foldri_1 = CharArray.foldri foldriFun [] (S2A"a");
val foldri_2 = CharArray.foldri foldriFun [] (S2A"ab");
(********************)

val foldrFun = fn (x, xs) => x :: xs;
val foldr0 = CharArray.foldr foldrFun [] ((L2A[]) : CharArray.array);
val foldr1 = CharArray.foldr foldrFun [] (L2A[#"a"]);
val foldr2 = CharArray.foldr foldrFun [] (L2A[#"a", #"b"]);
val foldr3 = CharArray.foldr foldrFun [] (L2A[#"a", #"b", #"c"]);

(********************)
val findiFun =
    fn (index, value) => (print (Int.toString index); value = #"x");
val findi_0 = CharArray.findi findiFun (L2A[]);
val findi_1F = CharArray.findi findiFun (L2A[#"a"]);
val findi_1T = CharArray.findi findiFun (L2A[#"x"]);
val findi_2F = CharArray.findi findiFun (L2A[#"a", #"b"]);
val findi_2T1 = CharArray.findi findiFun (L2A[#"a", #"x"]);
val findi_2T2 = CharArray.findi findiFun (L2A[#"x", #"a"]);
val findi_2T3 = CharArray.findi findiFun (L2A[#"x", #"x"]);

(********************)
val findFun = fn value => (print (Char.toString value); value = #"x");
val find_0 = CharArray.find findFun (L2A[]);
val find_1F = CharArray.find findFun (L2A[#"a"]);
val find_1T = CharArray.find findFun (L2A[#"x"]);
val find_2F = CharArray.find findFun (L2A[#"a", #"b"]);
val find_2T1 = CharArray.find findFun (L2A[#"a", #"x"]);
val find_2T2 = CharArray.find findFun (L2A[#"x", #"a"]);
val find_2T3 = CharArray.find findFun (L2A[#"x", #"x"]);

(********************)
val existsFun = fn value => (print (Char.toString value); value = #"x");
val exists_0 = CharArray.exists existsFun (L2A[]);
val exists_1F = CharArray.exists existsFun (L2A[#"a"]);
val exists_1T = CharArray.exists existsFun (L2A[#"x"]);
val exists_2F = CharArray.exists existsFun (L2A[#"a", #"b"]);
val exists_2T1 = CharArray.exists existsFun (L2A[#"a", #"x"]);
val exists_2T2 = CharArray.exists existsFun (L2A[#"x", #"a"]);
val exists_2T3 = CharArray.exists existsFun (L2A[#"x", #"x"]);

(********************)
val allFun = fn value => (print (Char.toString value); value = #"x");
val all_0 = CharArray.all allFun (L2A[]);
val all_1F = CharArray.all allFun (L2A[#"a"]);
val all_1T = CharArray.all allFun (L2A[#"x"]);
val all_2F1 = CharArray.all allFun (L2A[#"a", #"b"]);
val all_2F2 = CharArray.all allFun (L2A[#"a", #"x"]);
val all_2F3 = CharArray.all allFun (L2A[#"x", #"a"]);
val all_2T = CharArray.all allFun (L2A[#"x", #"x"]);

(********************)
val collateFun =
    fn (x : char, y) =>
       if x < y
       then General.LESS
       else if x = y then General.EQUAL else General.GREATER;
val collate00 = CharArray.collate collateFun ((L2A[]), (L2A[]));
val collate01 = CharArray.collate collateFun ((L2A[]), (L2A[#"a"]));
val collate10 = CharArray.collate collateFun ((L2A[#"a"]), (L2A[]));
val collate11L = CharArray.collate collateFun ((L2A[#"a"]), (L2A[#"b"]));
val collate11E = CharArray.collate collateFun ((L2A[#"a"]), (L2A[#"a"]));
val collate11G = CharArray.collate collateFun ((L2A[#"b"]), (L2A[#"a"]));
val collate12L =
    CharArray.collate collateFun ((L2A[#"a"]), (L2A[#"a", #"b"]));
val collate12G =
    CharArray.collate collateFun ((L2A[#"b"]), (L2A[#"a", #"b"]));
val collate21L =
    CharArray.collate collateFun ((L2A[#"a", #"b"]), (L2A[#"b"]));
val collate21G =
    CharArray.collate collateFun ((L2A[#"a", #"b"]), (L2A[#"a"]));
val collate22L1 =
    CharArray.collate collateFun ((L2A[#"a", #"b"]), (L2A[#"c", #"b"]));
val collate22L2 =
    CharArray.collate collateFun ((L2A[#"a", #"b"]), (L2A[#"a", #"c"]));
val collate22E =
    CharArray.collate collateFun ((L2A[#"a", #"b"]), (L2A[#"a", #"b"]));
val collate22G1 =
    CharArray.collate collateFun ((L2A[#"c", #"a"]), (L2A[#"b", #"a"]));
val collate22G2 =
    CharArray.collate collateFun ((L2A[#"a", #"c"]), (L2A[#"a", #"b"]));
