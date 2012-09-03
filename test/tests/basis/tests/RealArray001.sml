(*
test cases for RealArray structure.
*)

fun L2A list = RealArray.fromList (map Real.fromInt list);
fun L2V list = RealVector.fromList (map Real.fromInt list);
fun A2L array =
    let
      val length = RealArray.length array
      fun scan ~1 accum = map Real.round accum
        | scan n accum = scan (n - 1) (RealArray.sub(array, n) :: accum)
    in scan (length - 1) [] : int list
    end;
fun V2L vector =
    let
      val length = RealVector.length vector
      fun scan ~1 accum = map Real.round accum
        | scan n accum = scan (n - 1) (RealVector.sub(vector, n) :: accum)
    in scan (length - 1) [] : int list
    end;

val array_0i = A2L(RealArray.array(0, 1.0));
val array_1i = A2L(RealArray.array(1, 1.0));
val array_2i = A2L(RealArray.array(2, 1.0));
val array_m1i = A2L(RealArray.array(~1, 1.0)) handle General.Size => [9];

val fromList_0i = A2L(RealArray.fromList ([] : real list));
val fromList_1i = A2L(RealArray.fromList [1.0]);
val fromList_2i = A2L(RealArray.fromList [1.0, 2.0]);

val tabulateFun = fn x => Real.fromInt x;
val tabulate0 = A2L(RealArray.tabulate (0, tabulateFun));
val tabulate1 = A2L(RealArray.tabulate (1, tabulateFun));
val tabulate2 = A2L(RealArray.tabulate (2, tabulateFun));
val tabulatem1 =
    A2L(RealArray.tabulate (~1, tabulateFun)) handle General.Size => [9];

val length1 = RealArray.length (L2A[]);
val length2 = RealArray.length (L2A[1]);
val length3 = RealArray.length (L2A[1, 2]);

val sub00 = RealArray.sub ((L2A[]), 0) handle General.Subscript => 9.9;
val sub0m1 = RealArray.sub ((L2A[]), ~1) handle General.Subscript => 9.9;
val sub01 = RealArray.sub ((L2A[]), 1) handle General.Subscript => 9.9;
val sub10 = RealArray.sub ((L2A[1]), 0);
val sub11 = RealArray.sub ((L2A[2]), 1) handle General.Subscript => 9.9;
val sub1m1 = RealArray.sub ((L2A[2]), ~1) handle General.Subscript => 9.9;
val sub20 = RealArray.sub ((L2A[1, 2]), 0);
val sub21 = RealArray.sub ((L2A[1, 2]), 1);
val sub22 = RealArray.sub ((L2A[1, 2]), 2) handle General.Subscript => 9.9;

(********************)
fun testUpdate (array, index, newValue) =
    (RealArray.update(array, index, Real.fromInt newValue); A2L(array));
val update00 = testUpdate ((L2A[]), 0, 1) handle General.Subscript => [1];
val update0m1 = testUpdate ((L2A[]), ~1, 1) handle General.Subscript => [1];
val update01 = testUpdate ((L2A[]), 1, 1) handle General.Subscript => [1];
val update10 = testUpdate ((L2A[1]), 0, 1);
val update11 = testUpdate ((L2A[2]), 1, 1) handle General.Subscript => [9];
val update1m1 = testUpdate ((L2A[2]), ~1, 1) handle General.Subscript => [9];
val update20 = testUpdate ((L2A[1, 2]), 0, 1);
val update21 = testUpdate ((L2A[1, 2]), 1, 1);
val update22 = testUpdate ((L2A[1, 2]), 2, 1) handle General.Subscript => [9];

(********************)
val vector_0 = RealArray.vector (L2A[]);
val vector_1 = RealArray.vector (L2A[1]);
val vector_2 = RealArray.vector (L2A[1, 2]);

(********************)

fun testCopy (src, dst, di) =
    (RealArray.copy {src = src, dst = dst, di = di}; (A2L src, A2L dst));
(* variation of length of src array *)
val copy_0_3_0 = testCopy(L2A[], L2A[7, 8, 9], 0);
val copy_1_3_0 = testCopy(L2A[1], L2A[7, 8, 9], 0);
val copy_2_3_0 = testCopy(L2A[1, 2], L2A[7, 8, 9], 0);
(* variation of length of dst array *)
val copy_3_0_0 =
    testCopy(L2A[1, 2, 3], L2A[], 0) handle Subscript => ([9], [9]);
val copy_3_1_0 =
    testCopy(L2A[1, 2, 3], L2A[7], 0) handle Subscript => ([9], [9]);
val copy_3_2_0 =
    testCopy(L2A[1, 2, 3], L2A[7, 8], 0) handle Subscript => ([9], [9]);
val copy_3_3_0 = testCopy(L2A[1, 2, 3], L2A[7, 8, 9], 0);
val copy_3_4_0 = testCopy(L2A[1, 2, 3], L2A[7, 8, 9, 6], 0);
(* variation of di *)
val copy_3_4_m1 =
    testCopy(L2A[1, 2, 3], L2A[7, 8, 9, 6], ~1) handle Subscript => ([9], [9]);
val copy_3_4_0 = testCopy(L2A[1, 2, 3], L2A[7, 8, 9, 6], 0);
val copy_3_4_1 = testCopy(L2A[1, 2, 3], L2A[7, 8, 9, 6], 1);
val copy_3_4_2 =
    testCopy(L2A[1, 2, 3], L2A[7, 8, 9, 6], 2) handle Subscript => ([9], [9]);

(********************)
fun testCopyVec (src, dst, di) =
    (RealArray.copyVec {src = src, dst = dst, di = di}; (V2L src, A2L dst));
(* variation of length of src array *)
val copyVec_0_3_0 = testCopyVec(L2V[], L2A[7, 8, 9], 0);
val copyVec_1_3_0 = testCopyVec(L2V[1], L2A[7, 8, 9], 0);
val copyVec_2_3_0 = testCopyVec(L2V[1, 2], L2A[7, 8, 9], 0);
(* variation of length of dst array *)
val copyVec_3_0_0 =
    testCopyVec(L2V[1, 2, 3], L2A[], 0) handle Subscript => ([9], [9]);
val copyVec_3_1_0 =
    testCopyVec(L2V[1, 2, 3], L2A[7], 0) handle Subscript => ([9], [9]);
val copyVec_3_2_0 =
    testCopyVec(L2V[1, 2, 3], L2A[7, 8], 0) handle Subscript => ([9], [9]);
val copyVec_3_3_0 = testCopyVec(L2V[1, 2, 3], L2A[7, 8, 9], 0);
val copyVec_3_4_0 = testCopyVec (L2V[1, 2, 3], L2A[7, 8, 9, 6], 0);
(* variation of di *)
val copyVec_3_4_m1 =
    testCopyVec (L2V[1, 2, 3], L2A[7, 8, 9, 6], ~1)
    handle Subscript => ([9], [9]);
val copyVec_3_4_0 = testCopyVec (L2V[1, 2, 3], L2A[7, 8, 9, 6], 0);
val copyVec_3_4_1 = testCopyVec (L2V[1, 2, 3], L2A[7, 8, 9, 6], 1);
val copyVec_3_4_2 =
    testCopyVec(L2V[1, 2, 3], L2A[7, 8, 9, 6], 2)
    handle Subscript => ([9], [9]);

(********************)
val appiFun =
    fn (index, n) => (print(Int.toString index); print(Real.toString n));
(* safe cases *)
val appi_0 = SOME(RealArray.appi appiFun (L2A []));
val appi_1 = SOME(RealArray.appi appiFun (L2A [1]));
val appi_2 = SOME(RealArray.appi appiFun (L2A [1, 2]));

(********************)
val appFun = fn x => print (Real.toString x);
val app0 = RealArray.app appFun (L2A[]);
val app1 = RealArray.app appFun (L2A[1]);
val app2 = RealArray.app appFun (L2A[1, 2]);
val app3 = RealArray.app appFun (L2A[1, 2, 3]);

(********************)
val modifyiFun =
    fn (index, n) => (print(Int.toString index); n * 10.0 : real);
fun testModifyi array =(RealArray.modifyi modifyiFun array; A2L array);
val modifyi_0 = testModifyi (L2A []);
val modifyi_1 = testModifyi (L2A [1]);
val modifyi_2 = testModifyi (L2A [1, 2]);

(********************)
val modifyFun = fn x => (print(Real.toString x); x * 10.0 : real);
fun testModify array = (RealArray.modify modifyFun array; A2L array);
val modify0 = testModify (L2A[]);
val modify1 = testModify (L2A[1]);
val modify2 = testModify (L2A[1, 2]);
val modify3 = testModify (L2A[1, 2, 3]);

(********************)
val foldliFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
val foldli_0 = RealArray.foldli foldliFun [] (L2A []);
val foldli_1 = RealArray.foldli foldliFun [] (L2A [1]);
val foldli_2 = RealArray.foldli foldliFun [] (L2A [1, 2]);
(********************)

val foldlFun = fn (x, xs) => x :: xs;
val foldl0 = RealArray.foldl foldlFun [] ((L2A[]) : RealArray.array);
val foldl1 = RealArray.foldl foldlFun [] (L2A[1]);
val foldl2 = RealArray.foldl foldlFun [] (L2A[1, 2]);
val foldl3 = RealArray.foldl foldlFun [] (L2A[1, 2, 3]);

(********************)
val foldriFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
val foldri_0 = RealArray.foldri foldriFun [] (L2A []);
val foldri_1 = RealArray.foldri foldriFun [] (L2A [1]);
val foldri_2 = RealArray.foldri foldriFun [] (L2A [1, 2]);
(********************)

val foldrFun = fn (x, xs) => x :: xs;
val foldr0 = RealArray.foldr foldrFun [] ((L2A[]) : RealArray.array);
val foldr1 = RealArray.foldr foldrFun [] (L2A[1]);
val foldr2 = RealArray.foldr foldrFun [] (L2A[1, 2]);
val foldr3 = RealArray.foldr foldrFun [] (L2A[1, 2, 3]);

(********************)
val findiFun =
    fn (index, value) =>
       (print (Int.toString index); 9.0 <= value);
val findi_0 = RealArray.findi findiFun (L2A[]);
val findi_1F = RealArray.findi findiFun (L2A[1]);
val findi_1T = RealArray.findi findiFun (L2A[9]);
val findi_2F = RealArray.findi findiFun (L2A[1, 2]);
val findi_2T1 = RealArray.findi findiFun (L2A[1, 9]);
val findi_2T2 = RealArray.findi findiFun (L2A[9, 1]);
val findi_2T3 = RealArray.findi findiFun (L2A[9, 9]);

(********************)
val findFun = fn value => (print (Real.toString value); 9.0 <= value);
val find_0 = RealArray.find findFun (L2A[]);
val find_1F = RealArray.find findFun (L2A[1]);
val find_1T = RealArray.find findFun (L2A[9]);
val find_2F = RealArray.find findFun (L2A[1, 2]);
val find_2T1 = RealArray.find findFun (L2A[1, 9]);
val find_2T2 = RealArray.find findFun (L2A[9, 1]);
val find_2T3 = RealArray.find findFun (L2A[9, 9]);

(********************)
val existsFun = fn value => (print (Real.toString value); 9.0 <= value);
val exists_0 = RealArray.exists existsFun (L2A[]);
val exists_1F = RealArray.exists existsFun (L2A[1]);
val exists_1T = RealArray.exists existsFun (L2A[9]);
val exists_2F = RealArray.exists existsFun (L2A[1, 2]);
val exists_2T1 = RealArray.exists existsFun (L2A[1, 9]);
val exists_2T2 = RealArray.exists existsFun (L2A[9, 1]);
val exists_2T3 = RealArray.exists existsFun (L2A[9, 9]);

(********************)
val allFun = fn value => (print (Real.toString value); 9.0 <= value);
val all_0 = RealArray.all allFun (L2A[]);
val all_1F = RealArray.all allFun (L2A[1]);
val all_1T = RealArray.all allFun (L2A[9]);
val all_2F1 = RealArray.all allFun (L2A[1, 2]);
val all_2F2 = RealArray.all allFun (L2A[1, 9]);
val all_2F3 = RealArray.all allFun (L2A[9, 1]);
val all_2T = RealArray.all allFun (L2A[9, 9]);

(********************)
val collateFun =
    fn (x : real, y) =>
       if x < y
       then General.LESS
       else if x <= y andalso y <= x then General.EQUAL else General.GREATER;
val collate00 = RealArray.collate collateFun ((L2A[]), (L2A[]));
val collate01 = RealArray.collate collateFun ((L2A[]), (L2A[1]));
val collate10 = RealArray.collate collateFun ((L2A[1]), (L2A[]));
val collate11L = RealArray.collate collateFun ((L2A[1]), (L2A[2]));
val collate11E = RealArray.collate collateFun ((L2A[1]), (L2A[1]));
val collate11G = RealArray.collate collateFun ((L2A[2]), (L2A[1]));
val collate12L = RealArray.collate collateFun ((L2A[1]), (L2A[1, 2]));
val collate12G = RealArray.collate collateFun ((L2A[2]), (L2A[1, 2]));
val collate21L = RealArray.collate collateFun ((L2A[1, 2]), (L2A[2]));
val collate21G = RealArray.collate collateFun ((L2A[1, 2]), (L2A[1]));
val collate22L1 = RealArray.collate collateFun ((L2A[1, 2]), (L2A[3, 2]));
val collate22L2 = RealArray.collate collateFun ((L2A[1, 2]), (L2A[1, 3]));
val collate22E = RealArray.collate collateFun ((L2A[1, 2]), (L2A[1, 2]));
val collate22G1 = RealArray.collate collateFun ((L2A[3, 1]), (L2A[2, 1]));
val collate22G2 = RealArray.collate collateFun ((L2A[1, 3]), (L2A[1, 2]));
