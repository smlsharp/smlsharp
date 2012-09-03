(*
test cases for RealVector structure.
*)

fun L2V list = RealVector.fromList (map Real.fromInt list);
fun V2L vector =
    let
      val length = RealVector.length vector
      fun scan ~1 accum = map Real.round accum
        | scan n accum = scan (n - 1) (RealVector.sub(vector, n) :: accum)
    in scan (length - 1) [] : int list
    end;

val fromList_0i = V2L(RealVector.fromList ([] : real list));
val fromList_1i = V2L(RealVector.fromList [1.0]);
val fromList_2i = V2L(RealVector.fromList [1.0, 2.0]);

val tabulateFun = fn x => Real.fromInt x;
val tabulate0 = V2L(RealVector.tabulate (0, tabulateFun));
val tabulate1 = V2L(RealVector.tabulate (1, tabulateFun));
val tabulate2 = V2L(RealVector.tabulate (2, tabulateFun));
val tabulatem1 =
    V2L(RealVector.tabulate (~1, tabulateFun)) handle General.Size => [9];

val length1 = RealVector.length (L2V[]);
val length2 = RealVector.length (L2V[1]);
val length3 = RealVector.length (L2V[1, 2]);

val sub00 = RealVector.sub ((L2V[]), 0) handle General.Subscript => 9.9;
val sub0m1 = RealVector.sub ((L2V[]), ~1) handle General.Subscript => 9.9;
val sub01 = RealVector.sub ((L2V[]), 1) handle General.Subscript => 9.9;
val sub10 = RealVector.sub ((L2V[1]), 0);
val sub11 = RealVector.sub ((L2V[2]), 1) handle General.Subscript => 9.9;
val sub1m1 = RealVector.sub ((L2V[2]), ~1) handle General.Subscript => 9.9;
val sub20 = RealVector.sub ((L2V[1, 2]), 0);
val sub21 = RealVector.sub ((L2V[1, 2]), 1);
val sub22 = RealVector.sub ((L2V[1, 2]), 2) handle General.Subscript => 9.9;

(********************)

val concat0 = RealVector.concat ([] : RealVector.vector List.list);
val concat10 = RealVector.concat ([L2V[]] : RealVector.vector List.list);
val concat200 =
    RealVector.concat ([L2V[], L2V[]] : RealVector.vector List.list);
val concat11 = RealVector.concat [L2V[1]];
val concat201 = RealVector.concat [L2V[], L2V[1]];
val concat210 = RealVector.concat [L2V[1], L2V[]];
val concat211 = RealVector.concat [L2V[1], L2V[2]];
val concat222 = RealVector.concat [L2V[1,2], L2V[3,4]];
val concat3303 = RealVector.concat [L2V[1,2,3], L2V[], L2V[7,8,9]];
val concat3333 = RealVector.concat [L2V[1,2,3], L2V[4,5,6], L2V[7,8,9]];

(********************)
fun testUpdate (vector, index, newValue) =
    (RealVector.update(vector, index, Real.fromInt newValue); V2L(vector));
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
    fn (index, n) => (print(Int.toString index); print(Real.toString n));
(* safe cases *)
val appi_0 = SOME(RealVector.appi appiFun (L2V []));
val appi_1 = SOME(RealVector.appi appiFun (L2V [1]));
val appi_2 = SOME(RealVector.appi appiFun (L2V [1, 2]));

(********************)
val appFun = fn x => print (Real.toString x);
val app0 = RealVector.app appFun (L2V[]);
val app1 = RealVector.app appFun (L2V[1]);
val app2 = RealVector.app appFun (L2V[1, 2]);
val app3 = RealVector.app appFun (L2V[1, 2, 3]);

(********************)
val mapiFun =
    fn (index, n) => (print(Int.toString index); n * 10.0 : real);
(* safe cases *)
val mapi_0 = SOME(RealVector.mapi mapiFun (L2V []));
val mapi_1 = SOME(RealVector.mapi mapiFun (L2V [1]));
val mapi_2 = SOME(RealVector.mapi mapiFun (L2V [1, 2]));

(********************)
val mapFun = fn x => (print (Real.toString x); x * 10.0);
val map0 = RealVector.map mapFun (L2V[]);
val map1 = RealVector.map mapFun (L2V[1]);
val map2 = RealVector.map mapFun (L2V[1, 2]);
val map3 = RealVector.map mapFun (L2V[1, 2, 3]);

(********************)
val foldliFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
val foldli_0 = RealVector.foldli foldliFun [] (L2V []);
val foldli_1 = RealVector.foldli foldliFun [] (L2V [1]);
val foldli_2 = RealVector.foldli foldliFun [] (L2V [1, 2]);
(********************)

val foldlFun = fn (x, xs) => x :: xs;
val foldl0 = RealVector.foldl foldlFun [] ((L2V[]) : RealVector.vector);
val foldl1 = RealVector.foldl foldlFun [] (L2V[1]);
val foldl2 = RealVector.foldl foldlFun [] (L2V[1, 2]);
val foldl3 = RealVector.foldl foldlFun [] (L2V[1, 2, 3]);

(********************)
val foldriFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
val foldri_0 = RealVector.foldri foldriFun [] (L2V []);
val foldri_1 = RealVector.foldri foldriFun [] (L2V [1]);
val foldri_2 = RealVector.foldri foldriFun [] (L2V [1, 2]);
(********************)

val foldrFun = fn (x, xs) => x :: xs;
val foldr0 = RealVector.foldr foldrFun [] ((L2V[]) : RealVector.vector);
val foldr1 = RealVector.foldr foldrFun [] (L2V[1]);
val foldr2 = RealVector.foldr foldrFun [] (L2V[1, 2]);
val foldr3 = RealVector.foldr foldrFun [] (L2V[1, 2, 3]);

(********************)
val findiFun =
    fn (index, value) =>
       (print (Int.toString index); (value <= 9.0) andalso (9.0 <= value));
val findi_0 = RealVector.findi findiFun (L2V[]);
val findi_1F = RealVector.findi findiFun (L2V[1]);
val findi_1T = RealVector.findi findiFun (L2V[9]);
val findi_2F = RealVector.findi findiFun (L2V[1, 2]);
val findi_2T1 = RealVector.findi findiFun (L2V[1, 9]);
val findi_2T2 = RealVector.findi findiFun (L2V[9, 1]);
val findi_2T3 = RealVector.findi findiFun (L2V[9, 9]);

(********************)
val findFun = fn value => (print (Real.toString value); 9.0 <= value);
val find_0 = RealVector.find findFun (L2V[]);
val find_1F = RealVector.find findFun (L2V[1]);
val find_1T = RealVector.find findFun (L2V[9]);
val find_2F = RealVector.find findFun (L2V[1, 2]);
val find_2T1 = RealVector.find findFun (L2V[1, 9]);
val find_2T2 = RealVector.find findFun (L2V[9, 1]);
val find_2T3 = RealVector.find findFun (L2V[9, 9]);

(********************)
val existsFun = fn value => (print (Real.toString value); 9.0 <= value);
val exists_0 = RealVector.exists existsFun (L2V[]);
val exists_1F = RealVector.exists existsFun (L2V[1]);
val exists_1T = RealVector.exists existsFun (L2V[9]);
val exists_2F = RealVector.exists existsFun (L2V[1, 2]);
val exists_2T1 = RealVector.exists existsFun (L2V[1, 9]);
val exists_2T2 = RealVector.exists existsFun (L2V[9, 1]);
val exists_2T3 = RealVector.exists existsFun (L2V[9, 9]);

(********************)
val allFun = fn value => (print (Real.toString value); 9.0 <= value);
val all_0 = RealVector.all allFun (L2V[]);
val all_1F = RealVector.all allFun (L2V[1]);
val all_1T = RealVector.all allFun (L2V[9]);
val all_2F1 = RealVector.all allFun (L2V[1, 2]);
val all_2F2 = RealVector.all allFun (L2V[1, 9]);
val all_2F3 = RealVector.all allFun (L2V[9, 1]);
val all_2T = RealVector.all allFun (L2V[9, 9]);

(********************)
val collateFun =
    fn (x : real, y) =>
       if x < y
       then General.LESS
       else if x <= y andalso y <= x then General.EQUAL else General.GREATER;
val collate00 = RealVector.collate collateFun ((L2V[]), (L2V[]));
val collate01 = RealVector.collate collateFun ((L2V[]), (L2V[1]));
val collate10 = RealVector.collate collateFun ((L2V[1]), (L2V[]));
val collate11L = RealVector.collate collateFun ((L2V[1]), (L2V[2]));
val collate11E = RealVector.collate collateFun ((L2V[1]), (L2V[1]));
val collate11G = RealVector.collate collateFun ((L2V[2]), (L2V[1]));
val collate12L = RealVector.collate collateFun ((L2V[1]), (L2V[1, 2]));
val collate12G = RealVector.collate collateFun ((L2V[2]), (L2V[1, 2]));
val collate21L = RealVector.collate collateFun ((L2V[1, 2]), (L2V[2]));
val collate21G = RealVector.collate collateFun ((L2V[1, 2]), (L2V[1]));
val collate22L1 = RealVector.collate collateFun ((L2V[1, 2]), (L2V[3, 2]));
val collate22L2 = RealVector.collate collateFun ((L2V[1, 2]), (L2V[1, 3]));
val collate22E = RealVector.collate collateFun ((L2V[1, 2]), (L2V[1, 2]));
val collate22G1 = RealVector.collate collateFun ((L2V[3, 1]), (L2V[2, 1]));
val collate22G2 = RealVector.collate collateFun ((L2V[1, 3]), (L2V[1, 2]));
