(*
test cases for Word8Vector structure.
*)

fun L2V list = Word8Vector.fromList (map Word8.fromInt list);
fun V2L vector =
    let
      val length = Word8Vector.length vector
      fun scan ~1 accum = map Word8.toInt accum
        | scan n accum = scan (n - 1) (Word8Vector.sub(vector, n) :: accum)
    in scan (length - 1) [] : int list
    end;

val fromList_0i = V2L(Word8Vector.fromList ([] : Word8.word list));
val fromList_1i = V2L(Word8Vector.fromList [0w1]);
val fromList_2i = V2L(Word8Vector.fromList [0w1, 0w2]);

val tabulateFun = fn x => Word8.fromInt x;
val tabulate0 = V2L(Word8Vector.tabulate (0, tabulateFun));
val tabulate1 = V2L(Word8Vector.tabulate (1, tabulateFun));
val tabulate2 = V2L(Word8Vector.tabulate (2, tabulateFun));
val tabulatem1 =
    V2L(Word8Vector.tabulate (~1, tabulateFun)) handle General.Size => [9];

val length1 = Word8Vector.length (L2V[]);
val length2 = Word8Vector.length (L2V[1]);
val length3 = Word8Vector.length (L2V[1, 2]);

val sub00 = Word8Vector.sub ((L2V[]), 0) handle General.Subscript => 0w9;
val sub0m1 = Word8Vector.sub ((L2V[]), ~1) handle General.Subscript => 0w9;
val sub01 = Word8Vector.sub ((L2V[]), 1) handle General.Subscript => 0w9;
val sub10 = Word8Vector.sub ((L2V[1]), 0);
val sub11 = Word8Vector.sub ((L2V[2]), 1) handle General.Subscript => 0w9;
val sub1m1 = Word8Vector.sub ((L2V[2]), ~1) handle General.Subscript => 0w9;
val sub20 = Word8Vector.sub ((L2V[1, 2]), 0);
val sub21 = Word8Vector.sub ((L2V[1, 2]), 1);
val sub22 = Word8Vector.sub ((L2V[1, 2]), 2) handle General.Subscript => 0w9;

(********************)

val concat0 = Word8Vector.concat ([] : Word8Vector.vector List.list);
val concat10 = Word8Vector.concat ([L2V[]] : Word8Vector.vector List.list);
val concat200 =
    Word8Vector.concat ([L2V[], L2V[]] : Word8Vector.vector List.list);
val concat11 = Word8Vector.concat [L2V[1]];
val concat201 = Word8Vector.concat [L2V[], L2V[1]];
val concat210 = Word8Vector.concat [L2V[1], L2V[]];
val concat211 = Word8Vector.concat [L2V[1], L2V[2]];
val concat222 = Word8Vector.concat [L2V[1,2], L2V[3,4]];
val concat3303 = Word8Vector.concat [L2V[1,2,3], L2V[], L2V[7,8,9]];
val concat3333 = Word8Vector.concat [L2V[1,2,3], L2V[4,5,6], L2V[7,8,9]];

(********************)
fun testUpdate (vector, index, newValue) =
    (Word8Vector.update(vector, index, Word8.fromInt newValue); V2L(vector));
val update00 = testUpdate ((L2V[]), 0, 1) handle General.Subscript => [1];
val update0m1 = testUpdate ((L2V[]), ~1, 1) handle General.Subscript => [1];
val update01 = testUpdate ((L2V[]), 1, 1) handle General.Subscript => [1];
val update10 = testUpdate ((L2V[1]), 0, 1);
val update11 = testUpdate ((L2V[2]), 1, 1) handle General.Subscript => [9];
val update1m1 = testUpdate ((L2V[2]), ~1, 1) handle General.Subscript => [9];
val update20 = testUpdate ((L2V[1, 2]), 0, 1);
val update21 = testUpdate ((L2V[1, 2]), 1, 1);
val update22 = testUpdate ((L2V[1, 2]), 2, 1) handle General.Subscript => [9];

(********************)
val appiFun =
    fn (index, n) => (print(Int.toString index); print(Word8.toString n));
(* safe cases *)
val appi_0 = SOME(Word8Vector.appi appiFun (L2V []));
val appi_1 = SOME(Word8Vector.appi appiFun (L2V [1]));
val appi_2 = SOME(Word8Vector.appi appiFun (L2V [1, 2]));

(********************)
val appFun = fn x => print (Word8.toString x);
val app0 = Word8Vector.app appFun (L2V[]);
val app1 = Word8Vector.app appFun (L2V[1]);
val app2 = Word8Vector.app appFun (L2V[1, 2]);
val app3 = Word8Vector.app appFun (L2V[1, 2, 3]);

(********************)
val mapiFun =
    fn (index, n) => (print(Int.toString index); n * 0w10 : Word8.word);
(* safe cases *)
val mapi_0 = SOME(Word8Vector.mapi mapiFun (L2V []));
val mapi_1 = SOME(Word8Vector.mapi mapiFun (L2V [1]));
val mapi_2 = SOME(Word8Vector.mapi mapiFun (L2V [1, 2]));

(********************)
val mapFun = fn x => (print (Word8.toString x); x * 0w10);
val map0 = Word8Vector.map mapFun (L2V[]);
val map1 = Word8Vector.map mapFun (L2V[1]);
val map2 = Word8Vector.map mapFun (L2V[1, 2]);
val map3 = Word8Vector.map mapFun (L2V[1, 2, 3]);

(********************)
val foldliFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
val foldli_0 = Word8Vector.foldli foldliFun [] (L2V []);
val foldli_1 = Word8Vector.foldli foldliFun [] (L2V [1]);
val foldli_2 = Word8Vector.foldli foldliFun [] (L2V [1, 2]);
(********************)

val foldlFun = fn (x, xs) => x :: xs;
val foldl0 = Word8Vector.foldl foldlFun [] ((L2V[]) : Word8Vector.vector);
val foldl1 = Word8Vector.foldl foldlFun [] (L2V[1]);
val foldl2 = Word8Vector.foldl foldlFun [] (L2V[1, 2]);
val foldl3 = Word8Vector.foldl foldlFun [] (L2V[1, 2, 3]);

(********************)
val foldriFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
val foldri_0 = Word8Vector.foldri foldriFun [] (L2V []);
val foldri_1 = Word8Vector.foldri foldriFun [] (L2V [1]);
val foldri_2 = Word8Vector.foldri foldriFun [] (L2V [1, 2]);
(********************)

val foldrFun = fn (x, xs) => x :: xs;
val foldr0 = Word8Vector.foldr foldrFun [] ((L2V[]) : Word8Vector.vector);
val foldr1 = Word8Vector.foldr foldrFun [] (L2V[1]);
val foldr2 = Word8Vector.foldr foldrFun [] (L2V[1, 2]);
val foldr3 = Word8Vector.foldr foldrFun [] (L2V[1, 2, 3]);

(********************)
val findiFun =
    fn (index, value) =>
       (print (Int.toString index); value = (0w9 : Word8.word));
val findi_0 = Word8Vector.findi findiFun (L2V[]);
val findi_1F = Word8Vector.findi findiFun (L2V[1]);
val findi_1T = Word8Vector.findi findiFun (L2V[9]);
val findi_2F = Word8Vector.findi findiFun (L2V[1, 2]);
val findi_2T1 = Word8Vector.findi findiFun (L2V[1, 9]);
val findi_2T2 = Word8Vector.findi findiFun (L2V[9, 1]);
val findi_2T3 = Word8Vector.findi findiFun (L2V[9, 9]);

(********************)
val findFun = fn value => (print (Word8.toString value); value = 0w9);
val find_0 = Word8Vector.find findFun (L2V[]);
val find_1F = Word8Vector.find findFun (L2V[1]);
val find_1T = Word8Vector.find findFun (L2V[9]);
val find_2F = Word8Vector.find findFun (L2V[1, 2]);
val find_2T1 = Word8Vector.find findFun (L2V[1, 9]);
val find_2T2 = Word8Vector.find findFun (L2V[9, 1]);
val find_2T3 = Word8Vector.find findFun (L2V[9, 9]);

(********************)
val existsFun = fn value => (print (Word8.toString value); value = 0w9);
val exists_0 = Word8Vector.exists existsFun (L2V[]);
val exists_1F = Word8Vector.exists existsFun (L2V[1]);
val exists_1T = Word8Vector.exists existsFun (L2V[9]);
val exists_2F = Word8Vector.exists existsFun (L2V[1, 2]);
val exists_2T1 = Word8Vector.exists existsFun (L2V[1, 9]);
val exists_2T2 = Word8Vector.exists existsFun (L2V[9, 1]);
val exists_2T3 = Word8Vector.exists existsFun (L2V[9, 9]);

(********************)
val allFun = fn value => (print (Word8.toString value); value = 0w9);
val all_0 = Word8Vector.all allFun (L2V[]);
val all_1F = Word8Vector.all allFun (L2V[1]);
val all_1T = Word8Vector.all allFun (L2V[9]);
val all_2F1 = Word8Vector.all allFun (L2V[1, 2]);
val all_2F2 = Word8Vector.all allFun (L2V[1, 9]);
val all_2F3 = Word8Vector.all allFun (L2V[9, 1]);
val all_2T = Word8Vector.all allFun (L2V[9, 9]);

(********************)
val collateFun =
    fn (x : Word8.word, y) =>
       if x < y
       then General.LESS
       else if x = y then General.EQUAL else General.GREATER;
val collate00 = Word8Vector.collate collateFun ((L2V[]), (L2V[]));
val collate01 = Word8Vector.collate collateFun ((L2V[]), (L2V[1]));
val collate10 = Word8Vector.collate collateFun ((L2V[1]), (L2V[]));
val collate11L = Word8Vector.collate collateFun ((L2V[1]), (L2V[2]));
val collate11E = Word8Vector.collate collateFun ((L2V[1]), (L2V[1]));
val collate11G = Word8Vector.collate collateFun ((L2V[2]), (L2V[1]));
val collate12L = Word8Vector.collate collateFun ((L2V[1]), (L2V[1, 2]));
val collate12G = Word8Vector.collate collateFun ((L2V[2]), (L2V[1, 2]));
val collate21L = Word8Vector.collate collateFun ((L2V[1, 2]), (L2V[2]));
val collate21G = Word8Vector.collate collateFun ((L2V[1, 2]), (L2V[1]));
val collate22L1 = Word8Vector.collate collateFun ((L2V[1, 2]), (L2V[3, 2]));
val collate22L2 = Word8Vector.collate collateFun ((L2V[1, 2]), (L2V[1, 3]));
val collate22E = Word8Vector.collate collateFun ((L2V[1, 2]), (L2V[1, 2]));
val collate22G1 = Word8Vector.collate collateFun ((L2V[3, 1]), (L2V[2, 1]));
val collate22G2 = Word8Vector.collate collateFun ((L2V[1, 3]), (L2V[1, 2]));
