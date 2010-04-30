(*
test cases for Array structure.
*)

fun L2A list = Array.fromList list;
fun L2V list = Vector.fromList list;
fun S2A string = L2A (String.explode string);
fun A2L array =
    let
      val length = Array.length array
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (Array.sub(array, n) :: accum)
    in scan (length - 1) []
    end;
fun V2L vector =
    let
      val length = Vector.length vector
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (Vector.sub(vector, n) :: accum)
    in scan (length - 1) []
    end;

val array_0i = A2L(Array.array(0, 1));
val array_0r = A2L(Array.array(0, 1.23));
val array_0ii = A2L(Array.array(0, (1, 2)));
val array_1i = A2L(Array.array(1, 1));
val array_1r = A2L(Array.array(1, 1.23));
val array_1ii = A2L(Array.array(1, (1, 2)));
val array_2i = A2L(Array.array(2, 1));
val array_2r = A2L(Array.array(2, 1.23));
val array_2ii = A2L(Array.array(2, (1, 2)));
val array_m1i = A2L(Array.array(~1, 1)) handle General.Size => [999];

val fromList_0i = A2L(Array.fromList ([] : int list));
val fromList_0r = A2L(Array.fromList ([] : real list));
val fromList_0ii = A2L(Array.fromList ([] : (int * int) list));
val fromList_1i = A2L(Array.fromList [1]);
val fromList_1r = A2L(Array.fromList [1.23]);
val fromList_1ii = A2L(Array.fromList [(1, 2)]);
val fromList_2i = A2L(Array.fromList [1, 2]);
val fromList_2r = A2L(Array.fromList [1.23, 2.34]);
val fromList_2ii = A2L(Array.fromList [(1, 2), (3, 4)]);

val tabulateFun = fn x => x;
val tabulate0 = A2L(Array.tabulate (0, tabulateFun));
val tabulate1 = A2L(Array.tabulate (1, tabulateFun));
val tabulate2 = A2L(Array.tabulate (2, tabulateFun));
val tabulatem1 =
    A2L(Array.tabulate (~1, tabulateFun)) handle General.Size => [999];

val length1 = Array.length (L2A[]);
val length2 = Array.length (L2A[1]);
val length3 = Array.length (L2A[1, 2]);

val sub00 = Array.sub ((L2A[]), 0) handle General.Subscript => 1;
val sub0m1 = Array.sub ((L2A[]), ~1) handle General.Subscript => 1;
val sub01 = Array.sub ((L2A[]), 1) handle General.Subscript => 1;
val sub10 = Array.sub ((L2A[1]), 0);
val sub11 = Array.sub ((L2A[2]), 1) handle General.Subscript => 1;
val sub1m1 = Array.sub ((L2A[2]), ~1) handle General.Subscript => 1;
val sub20 = Array.sub ((L2A[1, 2]), 0);
val sub21 = Array.sub ((L2A[1, 2]), 1);
val sub22 = Array.sub ((L2A[1, 2]), 2) handle General.Subscript => 3;

(********************)
fun testUpdate (array, index, newValue) =
    (Array.update(array, index, newValue); A2L(array));
val update00 = testUpdate ((L2A[]), 0, 9) handle General.Subscript => [1];
val update0m1 = testUpdate ((L2A[]), ~1, 9) handle General.Subscript => [1];
val update01 = testUpdate ((L2A[]), 1, 9) handle General.Subscript => [1];
val update10 = testUpdate ((L2A[1]), 0, 9);
val update11 = testUpdate ((L2A[2]), 1, 9) handle General.Subscript => [999];
val update1m1 = testUpdate ((L2A[2]), ~1, 9) handle General.Subscript => [999];
val update20 = testUpdate ((L2A[1, 2]), 0, 9);
val update21 = testUpdate ((L2A[1, 2]), 1, 9);
val update22 =
    testUpdate ((L2A[1, 2]), 2, 9) handle General.Subscript => [999];

(********************)

val vector_0 = V2L(Array.vector (L2A([] : int list)));
val vector_1 = V2L(Array.vector (L2A[1]));
val vector_2 = V2L(Array.vector (L2A[1, 2]));

(********************)

fun testCopy (src, dst, di) =
    (Array.copy {src = src, dst = dst, di = di}; (A2L src, A2L dst));
(* variation of length of src array *)
val copy_0_3_0 = testCopy(L2A[], L2A[9, 8, 7], 0);
val copy_1_3_0 = testCopy(L2A[1], L2A[9, 8, 7], 0);
val copy_2_3_0 = testCopy(L2A[1, 2], L2A[9, 8, 7], 0);
(* variation of length of dst array *)
val copy_3_0_0 =
    testCopy(L2A[1, 2, 3], L2A[], 0) handle Subscript => ([~1], [~1]);
val copy_3_1_0 =
    testCopy(L2A[1, 2, 3], L2A[9], 0) handle Subscript => ([~1], [~1]);
val copy_3_2_0 =
    testCopy(L2A[1, 2, 3], L2A[9, 8], 0) handle Subscript => ([~1], [~1]);
val copy_3_3_0 = testCopy(L2A[1, 2, 3], L2A[9, 8, 7], 0);
val copy_3_4_0 = testCopy(L2A[1, 2, 3], L2A[9, 8, 7, 6], 0);
(* variation of di *)
val copy_3_4_m1 =
    testCopy(L2A[1, 2, 3], L2A[9, 8, 7, 6], ~1)
    handle Subscript => ([~1], [~1]);
val copy_3_4_0 = testCopy(L2A[1, 2, 3], L2A[9, 8, 7, 6], 0);
val copy_3_4_1 = testCopy(L2A[1, 2, 3], L2A[9, 8, 7, 6], 1);
val copy_3_4_2 =
    testCopy(L2A[1, 2, 3], L2A[9, 8, 7, 6], 2)
    handle Subscript => ([~1], [~1]);

(********************)
fun testCopyVec (src, dst, di) =
    (Array.copyVec {src = src, dst = dst, di = di}; (V2L src, A2L dst));
(* variation of length of src array *)
val copyVec_0_3_0 = testCopyVec(L2V[], L2A[9, 8, 7], 0);
val copyVec_1_3_0 = testCopyVec(L2V[1], L2A[9, 8, 7], 0);
val copyVec_2_3_0 = testCopyVec(L2V[1, 2], L2A[9, 8, 7], 0);
(* variation of length of dst array *)
val copyVec_3_0_0 =
    testCopyVec(L2V[1, 2, 3], L2A[], 0) handle Subscript => ([~1], [~1]);
val copyVec_3_1_0 =
    testCopyVec(L2V[1, 2, 3], L2A[9], 0) handle Subscript => ([~1], [~1]);
val copyVec_3_2_0 =
    testCopyVec(L2V[1, 2, 3], L2A[9, 8], 0) handle Subscript => ([~1], [~1]);
val copyVec_3_3_0 = testCopyVec(L2V[1, 2, 3], L2A[9, 8, 7], 0);
val copyVec_3_4_0 = testCopyVec(L2V[1, 2, 3], L2A[9, 8, 7, 6], 0);
(* variation of di *)
val copyVec_3_4_m1 =
    testCopyVec(L2V[1, 2, 3], L2A[9, 8, 7, 6], ~1)
    handle Subscript => ([~1], [~1]);
val copyVec_3_4_0 = testCopyVec(L2V[1, 2, 3], L2A[9, 8, 7, 6], 0);
val copyVec_3_4_1 = testCopyVec(L2V[1, 2, 3], L2A[9, 8, 7, 6], 1);
val copyVec_3_4_2 =
    testCopyVec(L2V[1, 2, 3], L2A[9, 8, 7, 6], 2)
    handle Subscript => ([~1], [~1]);

(********************)
val appiFun =
    fn (index, ch) => (print(Int.toString index); print(Char.toString ch));
val appi_0 = SOME(Array.appi appiFun (S2A""));
val appi_1 = SOME(Array.appi appiFun (S2A"a"));
val appi_2 = SOME(Array.appi appiFun (S2A"ab"));
(********************)

val appFun = fn x => print x;
val app0 = Array.app appFun (L2A[]);
val app1 = Array.app appFun (L2A["a"]);
val app2 = Array.app appFun (L2A["a", "b"]);
val app3 = Array.app appFun (L2A["a", "b", "c"]);

(********************)
val modifyiFun =
    fn (index, ch) => (print(Int.toString index); Char.toUpper ch);
fun testModifyi array = (Array.modifyi modifyiFun array; A2L array);
(* safe cases *)
val modifyi_0 = testModifyi (S2A"");
val modifyi_1 = testModifyi (S2A"a");
val modifyi_2 = testModifyi (S2A"ab");
(********************)

val modifyFun = fn x => (print(Int.toString x); x + 1);
fun testModify array =
    (Array.modify modifyFun array; A2L array);
val modify0 = testModify (L2A[]);
val modify1 = testModify (L2A[1]);
val modify2 = testModify (L2A[1, 2]);
val modify3 = testModify (L2A[1, 2, 3]);

(********************)
val foldliFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
val foldli_0 = Array.foldli foldliFun [] (S2A"");
val foldli_1 = Array.foldli foldliFun [] (S2A"a");
val foldli_2 = Array.foldli foldliFun [] (S2A"ab");

(********************)
val foldlFun = fn (x, xs) => x :: xs;
val foldl0 = Array.foldl foldlFun [] ((L2A[]) : int Array.array);
val foldl1 = Array.foldl foldlFun [] (L2A[1]);
val foldl2 = Array.foldl foldlFun [] (L2A[1, 2]);
val foldl3 = Array.foldl foldlFun [] (L2A[1, 2, 3]);

(********************)
val foldriFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
(* safe cases *)
val foldri_0 = Array.foldri foldriFun [] (S2A"");
val foldri_1 = Array.foldri foldriFun [] (S2A"a");
val foldri_2 = Array.foldri foldriFun [] (S2A"ab");

(********************)
val foldrFun = fn (x, xs) => x :: xs;
val foldr0 = Array.foldr foldrFun [] ((L2A[]) : int Array.array);
val foldr1 = Array.foldr foldrFun [] (L2A[1]);
val foldr2 = Array.foldr foldrFun [] (L2A[1, 2]);
val foldr3 = Array.foldr foldrFun [] (L2A[1, 2, 3]);

(********************)
val findiFun =
    fn (index, value) => (print (Int.toString index); value = #"x");
val findi_0 = Array.findi findiFun (L2A[]);
val findi_1F = Array.findi findiFun (L2A[#"a"]);
val findi_1T = Array.findi findiFun (L2A[#"x"]);
val findi_2F = Array.findi findiFun (L2A[#"a", #"b"]);
val findi_2T1 = Array.findi findiFun (L2A[#"a", #"x"]);
val findi_2T2 = Array.findi findiFun (L2A[#"x", #"a"]);
val findi_2T3 = Array.findi findiFun (L2A[#"x", #"x"]);

(********************)
val findFun = fn value => (print (Char.toString value); value = #"x");
val find_0 = Array.find findFun (L2A[]);
val find_1F = Array.find findFun (L2A[#"a"]);
val find_1T = Array.find findFun (L2A[#"x"]);
val find_2F = Array.find findFun (L2A[#"a", #"b"]);
val find_2T1 = Array.find findFun (L2A[#"a", #"x"]);
val find_2T2 = Array.find findFun (L2A[#"x", #"a"]);
val find_2T3 = Array.find findFun (L2A[#"x", #"x"]);

(********************)
val existsFun = fn value => (print (Char.toString value); value = #"x");
val exists_0 = Array.exists existsFun (L2A[]);
val exists_1F = Array.exists existsFun (L2A[#"a"]);
val exists_1T = Array.exists existsFun (L2A[#"x"]);
val exists_2F = Array.exists existsFun (L2A[#"a", #"b"]);
val exists_2T1 = Array.exists existsFun (L2A[#"a", #"x"]);
val exists_2T2 = Array.exists existsFun (L2A[#"x", #"a"]);
val exists_2T3 = Array.exists existsFun (L2A[#"x", #"x"]);

(********************)
val allFun = fn value => (print (Char.toString value); value = #"x");
val all_0 = Array.all allFun (L2A[]);
val all_1F = Array.all allFun (L2A[#"a"]);
val all_1T = Array.all allFun (L2A[#"x"]);
val all_2F1 = Array.all allFun (L2A[#"a", #"b"]);
val all_2F2 = Array.all allFun (L2A[#"a", #"x"]);
val all_2F3 = Array.all allFun (L2A[#"x", #"a"]);
val all_2T = Array.all allFun (L2A[#"x", #"x"]);

(********************)
val collateFun =
    fn (x, y) =>
       if x < y
       then General.LESS
       else if x = y then General.EQUAL else General.GREATER;
val collate00 = Array.collate collateFun ((L2A[]), (L2A[]));
val collate01 = Array.collate collateFun ((L2A[]), (L2A[1]));
val collate10 = Array.collate collateFun ((L2A[1]), (L2A[0]));
val collate11L = Array.collate collateFun ((L2A[1]), (L2A[2]));
val collate11E = Array.collate collateFun ((L2A[1]), (L2A[1]));
val collate11G = Array.collate collateFun ((L2A[2]), (L2A[1]));
val collate12L =  Array.collate collateFun ((L2A[1]), (L2A[1, 2]));
val collate12G =  Array.collate collateFun ((L2A[2]), (L2A[1, 2]));
val collate21L =  Array.collate collateFun ((L2A[1, 2]), (L2A[2]));
val collate21G =  Array.collate collateFun ((L2A[1, 2]), (L2A[1]));
val collate22L1 = Array.collate collateFun ((L2A[2, 1]), (L2A[3, 1]));
val collate22L2 = Array.collate collateFun ((L2A[1, 2]), (L2A[1, 3]));
val collate22E = Array.collate collateFun ((L2A[1, 2]), (L2A[1, 2]));
val collate22G1 = Array.collate collateFun ((L2A[3, 1]), (L2A[2, 1]));
val collate22G2 = Array.collate collateFun ((L2A[1, 3]), (L2A[1, 2]));
