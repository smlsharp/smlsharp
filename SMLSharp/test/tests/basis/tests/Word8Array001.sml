(*
test cases for Word8Array structure.
*)

fun L2A list = Word8Array.fromList (map Word8.fromInt list);
fun L2V list = Word8Vector.fromList (map Word8.fromInt list);
fun A2L array =
    let
      val length = Word8Array.length array
      fun scan ~1 accum = map Word8.toInt accum
        | scan n accum = scan (n - 1) (Word8Array.sub(array, n) :: accum)
    in scan (length - 1) [] : int list
    end;
fun V2L vector =
    let
      val length = Word8Vector.length vector
      fun scan ~1 accum = map Word8.toInt accum
        | scan n accum = scan (n - 1) (Word8Vector.sub(vector, n) :: accum)
    in scan (length - 1) [] : int list
    end;

val array_0i = A2L(Word8Array.array(0, 0w1));
val array_1i = A2L(Word8Array.array(1, 0w1));
val array_2i = A2L(Word8Array.array(2, 0w1));
val array_m1i = A2L(Word8Array.array(~1, 0w1)) handle General.Size => [9];

val fromList_0i = A2L(Word8Array.fromList ([] : Word8.word list));
val fromList_1i = A2L(Word8Array.fromList [0w1]);
val fromList_2i = A2L(Word8Array.fromList [0w1, 0w2]);

val tabulateFun = fn x => Word8.fromInt x;
val tabulate0 = A2L(Word8Array.tabulate (0, tabulateFun));
val tabulate1 = A2L(Word8Array.tabulate (1, tabulateFun));
val tabulate2 = A2L(Word8Array.tabulate (2, tabulateFun));
val tabulatem1 =
    A2L(Word8Array.tabulate (~1, tabulateFun)) handle General.Size => [9];

val length1 = Word8Array.length (L2A[]);
val length2 = Word8Array.length (L2A[1]);
val length3 = Word8Array.length (L2A[1, 2]);

val sub00 = Word8Array.sub ((L2A[]), 0) handle General.Subscript => 0w9;
val sub0m1 = Word8Array.sub ((L2A[]), ~1) handle General.Subscript => 0w9;
val sub01 = Word8Array.sub ((L2A[]), 1) handle General.Subscript => 0w9;
val sub10 = Word8Array.sub ((L2A[1]), 0);
val sub11 = Word8Array.sub ((L2A[2]), 1) handle General.Subscript => 0w9;
val sub1m1 = Word8Array.sub ((L2A[2]), ~1) handle General.Subscript => 0w9;
val sub20 = Word8Array.sub ((L2A[1, 2]), 0);
val sub21 = Word8Array.sub ((L2A[1, 2]), 1);
val sub22 = Word8Array.sub ((L2A[1, 2]), 2) handle General.Subscript => 0w9;

(********************)
fun testUpdate (array, index, newValue) =
    (Word8Array.update(array, index, Word8.fromInt newValue); A2L(array));
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
val vector_0 = Word8Array.vector (L2A[]);
val vector_1 = Word8Array.vector (L2A[1]);
val vector_2 = Word8Array.vector (L2A[1, 2]);

(********************)

fun testCopy (src, dst, di) =
    (Word8Array.copy {src = src, dst = dst, di = di}; (A2L src, A2L dst));
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
    (Word8Array.copyVec {src = src, dst = dst, di = di}; (V2L src, A2L dst));
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
    fn (index, n) => (print(Int.toString index); print(Word8.toString n));
(* safe cases *)
val appi_0 = SOME(Word8Array.appi appiFun (L2A []));
val appi_1 = SOME(Word8Array.appi appiFun (L2A [1]));
val appi_2 = SOME(Word8Array.appi appiFun (L2A [1, 2]));

(********************)
val appFun = fn x => print (Word8.toString x);
val app0 = Word8Array.app appFun (L2A[]);
val app1 = Word8Array.app appFun (L2A[1]);
val app2 = Word8Array.app appFun (L2A[1, 2]);
val app3 = Word8Array.app appFun (L2A[1, 2, 3]);

(********************)
val modifyiFun =
    fn (index, n) => (print(Int.toString index); n * 0w10 : Word8.word);
fun testModifyi array =(Word8Array.modifyi modifyiFun array; A2L array);
val modifyi_0 = testModifyi (L2A []);
val modifyi_1 = testModifyi (L2A [1]);
val modifyi_2 = testModifyi (L2A [1, 2]);

(********************)
val modifyFun = fn x => (print(Word8.toString x); x * 0w10 : Word8.word);
fun testModify array = (Word8Array.modify modifyFun array; A2L array);
val modify0 = testModify (L2A[]);
val modify1 = testModify (L2A[1]);
val modify2 = testModify (L2A[1, 2]);
val modify3 = testModify (L2A[1, 2, 3]);

(********************)
val foldliFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
val foldli_0 = Word8Array.foldli foldliFun [] (L2A []);
val foldli_1 = Word8Array.foldli foldliFun [] (L2A [1]);
val foldli_2 = Word8Array.foldli foldliFun [] (L2A [1, 2]);
(********************)

val foldlFun = fn (x, xs) => x :: xs;
val foldl0 = Word8Array.foldl foldlFun [] ((L2A[]) : Word8Array.array);
val foldl1 = Word8Array.foldl foldlFun [] (L2A[1]);
val foldl2 = Word8Array.foldl foldlFun [] (L2A[1, 2]);
val foldl3 = Word8Array.foldl foldlFun [] (L2A[1, 2, 3]);

(********************)
val foldriFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
val foldri_0 = Word8Array.foldri foldriFun [] (L2A []);
val foldri_1 = Word8Array.foldri foldriFun [] (L2A [1]);
val foldri_2 = Word8Array.foldri foldriFun [] (L2A [1, 2]);
(********************)

val foldrFun = fn (x, xs) => x :: xs;
val foldr0 = Word8Array.foldr foldrFun [] ((L2A[]) : Word8Array.array);
val foldr1 = Word8Array.foldr foldrFun [] (L2A[1]);
val foldr2 = Word8Array.foldr foldrFun [] (L2A[1, 2]);
val foldr3 = Word8Array.foldr foldrFun [] (L2A[1, 2, 3]);

(********************)
val findiFun =
    fn (index, value) =>
       (print (Int.toString index); value = (0w9 : Word8.word));
val findi_0 = Word8Array.findi findiFun (L2A[]);
val findi_1F = Word8Array.findi findiFun (L2A[1]);
val findi_1T = Word8Array.findi findiFun (L2A[9]);
val findi_2F = Word8Array.findi findiFun (L2A[1, 2]);
val findi_2T1 = Word8Array.findi findiFun (L2A[1, 9]);
val findi_2T2 = Word8Array.findi findiFun (L2A[9, 1]);
val findi_2T3 = Word8Array.findi findiFun (L2A[9, 9]);

(********************)
val findFun = fn value => (print (Word8.toString value); value = 0w9);
val find_0 = Word8Array.find findFun (L2A[]);
val find_1F = Word8Array.find findFun (L2A[1]);
val find_1T = Word8Array.find findFun (L2A[9]);
val find_2F = Word8Array.find findFun (L2A[1, 2]);
val find_2T1 = Word8Array.find findFun (L2A[1, 9]);
val find_2T2 = Word8Array.find findFun (L2A[9, 1]);
val find_2T3 = Word8Array.find findFun (L2A[9, 9]);

(********************)
val existsFun = fn value => (print (Word8.toString value); value = 0w9);
val exists_0 = Word8Array.exists existsFun (L2A[]);
val exists_1F = Word8Array.exists existsFun (L2A[1]);
val exists_1T = Word8Array.exists existsFun (L2A[9]);
val exists_2F = Word8Array.exists existsFun (L2A[1, 2]);
val exists_2T1 = Word8Array.exists existsFun (L2A[1, 9]);
val exists_2T2 = Word8Array.exists existsFun (L2A[9, 1]);
val exists_2T3 = Word8Array.exists existsFun (L2A[9, 9]);

(********************)
val allFun = fn value => (print (Word8.toString value); value = 0w9);
val all_0 = Word8Array.all allFun (L2A[]);
val all_1F = Word8Array.all allFun (L2A[1]);
val all_1T = Word8Array.all allFun (L2A[9]);
val all_2F1 = Word8Array.all allFun (L2A[1, 2]);
val all_2F2 = Word8Array.all allFun (L2A[1, 9]);
val all_2F3 = Word8Array.all allFun (L2A[9, 1]);
val all_2T = Word8Array.all allFun (L2A[9, 9]);

(********************)
val collateFun =
    fn (x : Word8.word, y) =>
       if x < y
       then General.LESS
       else if x = y then General.EQUAL else General.GREATER;
val collate00 = Word8Array.collate collateFun ((L2A[]), (L2A[]));
val collate01 = Word8Array.collate collateFun ((L2A[]), (L2A[1]));
val collate10 = Word8Array.collate collateFun ((L2A[1]), (L2A[]));
val collate11L = Word8Array.collate collateFun ((L2A[1]), (L2A[2]));
val collate11E = Word8Array.collate collateFun ((L2A[1]), (L2A[1]));
val collate11G = Word8Array.collate collateFun ((L2A[2]), (L2A[1]));
val collate12L = Word8Array.collate collateFun ((L2A[1]), (L2A[1, 2]));
val collate12G = Word8Array.collate collateFun ((L2A[2]), (L2A[1, 2]));
val collate21L = Word8Array.collate collateFun ((L2A[1, 2]), (L2A[2]));
val collate21G = Word8Array.collate collateFun ((L2A[1, 2]), (L2A[1]));
val collate22L1 = Word8Array.collate collateFun ((L2A[1, 2]), (L2A[3, 2]));
val collate22L2 = Word8Array.collate collateFun ((L2A[1, 2]), (L2A[1, 3]));
val collate22E = Word8Array.collate collateFun ((L2A[1, 2]), (L2A[1, 2]));
val collate22G1 = Word8Array.collate collateFun ((L2A[3, 1]), (L2A[2, 1]));
val collate22G2 = Word8Array.collate collateFun ((L2A[1, 3]), (L2A[1, 2]));
