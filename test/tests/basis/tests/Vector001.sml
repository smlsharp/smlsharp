(*
test cases for Vector structure.
*)

fun L2V list = Vector.fromList list;
fun S2V string = L2V (String.explode string);
fun V2L vector =
    let
      val length = Vector.length vector
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (Vector.sub(vector, n) :: accum)
    in scan (length - 1) []
    end;

val fromList_0i = V2L(Vector.fromList ([] : int list));
val fromList_0r = V2L(Vector.fromList ([] : real list));
val fromList_0ii = V2L(Vector.fromList ([] : (int * int) list));
val fromList_1i = V2L(Vector.fromList [1]);
val fromList_1r = V2L(Vector.fromList [1.23]);
val fromList_1ii = V2L(Vector.fromList [(1, 2)]);
val fromList_2i = V2L(Vector.fromList [1, 2]);
val fromList_2r = V2L(Vector.fromList [1.23, 2.34]);
val fromList_2ii = V2L(Vector.fromList [(1, 2), (3, 4)]);

val tabulateFun = fn x => x;
val tabulate0 = V2L(Vector.tabulate (0, tabulateFun));
val tabulate1 = V2L(Vector.tabulate (1, tabulateFun));
val tabulate2 = V2L(Vector.tabulate (2, tabulateFun));
val tabulatem1 =
    V2L(Vector.tabulate (~1, tabulateFun)) handle General.Size => [999];

val length1 = Vector.length (L2V[]);
val length2 = Vector.length (L2V[1]);
val length3 = Vector.length (L2V[1, 2]);

val sub00 = Vector.sub ((L2V[]), 0) handle General.Subscript => 1;
val sub0m1 = Vector.sub ((L2V[]), ~1) handle General.Subscript => 1;
val sub01 = Vector.sub ((L2V[]), 1) handle General.Subscript => 1;
val sub10 = Vector.sub ((L2V[1]), 0);
val sub11 = Vector.sub ((L2V[2]), 1) handle General.Subscript => 1;
val sub1m1 = Vector.sub ((L2V[2]), ~1) handle General.Subscript => 1;
val sub20 = Vector.sub ((L2V[1, 2]), 0);
val sub21 = Vector.sub ((L2V[1, 2]), 1);
val sub22 = Vector.sub ((L2V[1, 2]), 2) handle General.Subscript => 3;

(********************)
fun testUpdate (vector, index, newValue) =
    let val newVector = Vector.update(vector, index, newValue)
    in (V2L(vector), V2L(newVector)) end;
val update00 =
    testUpdate ((L2V[]), 0, 9) handle General.Subscript => ([1], [1]);
val update0m1 =
    testUpdate ((L2V[]), ~1, 9) handle General.Subscript => ([1], [1]);
val update01 =
    testUpdate ((L2V[]), 1, 9) handle General.Subscript => ([1], [1]);
val update10 = testUpdate ((L2V[1]), 0, 9);
val update11 =
    testUpdate ((L2V[2]), 1, 9) handle General.Subscript => ([999], [999]);
val update1m1 =
    testUpdate ((L2V[2]), ~1, 9) handle General.Subscript => ([999], [999]);
val update20 = testUpdate ((L2V[1, 2]), 0, 9);
val update21 = testUpdate ((L2V[1, 2]), 1, 9);
val update22 =
    testUpdate ((L2V[1, 2]), 2, 9) handle General.Subscript => ([999], [999]);

(********************)

val concat0 = V2L(Vector.concat ([] : int Vector.vector List.list));
val concat10 = V2L(Vector.concat ([(L2V[])] : int Vector.vector List.list));
val concat200 =
    V2L(Vector.concat (([(L2V[]), (L2V[])]) : int Vector.vector List.list));
val concat11 = V2L(Vector.concat ([(L2V[1])]));
val concat201 = V2L(Vector.concat ([(L2V[]), (L2V[1])]));
val concat210 = V2L(Vector.concat ([(L2V[1]), (L2V[])]));
val concat211 = V2L(Vector.concat ([(L2V[1]), (L2V[2])]));
val concat222 = V2L(Vector.concat ([(L2V[1, 2]), (L2V[3, 4])]));
val concat3303 =
    V2L(Vector.concat ([(L2V[1, 2, 3]), (L2V[]), (L2V[7, 8, 9])]));
val concat3333 =
    V2L(Vector.concat ([(L2V[1, 2, 3]), (L2V[4, 5, 6]), (L2V[7, 8, 9])]));

(********************)
val mapiFun = fn (index, ch) => (print(Int.toString index); ch);
val mapi_0 = V2L(Vector.mapi mapiFun (S2V""));
val mapi_1 = V2L(Vector.mapi mapiFun (S2V"a"));
val mapi_2 = V2L(Vector.mapi mapiFun (S2V"ab"));

(********************)

val mapFun = fn x => (print(Int.toString x); x + 1);
val map0 = V2L(Vector.map mapFun (L2V[]));
val map1 = V2L(Vector.map mapFun (L2V[1]));
val map2 = V2L(Vector.map mapFun (L2V[1, 2]));
val map3 = V2L(Vector.map mapFun (L2V[1, 2, 3]));

(********************)
val appiFun =
    fn (index, ch) => (print(Int.toString index); print(Char.toString ch));
val appi_0 = SOME(Vector.appi appiFun (S2V""));
val appi_1 = SOME(Vector.appi appiFun (S2V"a"));
val appi_2 = SOME(Vector.appi appiFun (S2V"ab"));
(********************)

val appFun = fn x => print x;
val app0 = Vector.app appFun (L2V[]);
val app1 = Vector.app appFun (L2V["a"]);
val app2 = Vector.app appFun (L2V["a", "b"]);
val app3 = Vector.app appFun (L2V["a", "b", "c"]);

(********************)
val foldliFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
val foldli_0 = Vector.foldli foldliFun [] (S2V"");
val foldli_1 = Vector.foldli foldliFun [] (S2V"a");
val foldli_2 = Vector.foldli foldliFun [] (S2V"ab");
(********************)

val foldlFun = fn (x, xs) => x :: xs;
val foldl0 = Vector.foldl foldlFun [] ((L2V[]) : int Vector.vector);
val foldl1 = Vector.foldl foldlFun [] (L2V[1]);
val foldl2 = Vector.foldl foldlFun [] (L2V[1, 2]);
val foldl3 = Vector.foldl foldlFun [] (L2V[1, 2, 3]);

(********************)
val foldriFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
val foldri_0 = Vector.foldri foldriFun [] (S2V"");
val foldri_1 = Vector.foldri foldriFun [] (S2V"a");
val foldri_2 = Vector.foldri foldriFun [] (S2V"ab");
(********************)

val foldrFun = fn (x, xs) => x :: xs;
val foldr0 = Vector.foldr foldrFun [] ((L2V[]) : int Vector.vector);
val foldr1 = Vector.foldr foldrFun [] (L2V[1]);
val foldr2 = Vector.foldr foldrFun [] (L2V[1, 2]);
val foldr3 = Vector.foldr foldrFun [] (L2V[1, 2, 3]);

(********************)
val findiFun =
    fn (index, value) => (print (Int.toString index); value = #"x");
val findi_0 = Vector.findi findiFun (L2V[]);
val findi_1F = Vector.findi findiFun (L2V[#"a"]);
val findi_1T = Vector.findi findiFun (L2V[#"x"]);
val findi_2F = Vector.findi findiFun (L2V[#"a", #"b"]);
val findi_2T1 = Vector.findi findiFun (L2V[#"a", #"x"]);
val findi_2T2 = Vector.findi findiFun (L2V[#"x", #"a"]);
val findi_2T3 = Vector.findi findiFun (L2V[#"x", #"x"]);

(********************)
val findFun = fn value => (print (Char.toString value); value = #"x");
val find_0 = Vector.find findFun (L2V[]);
val find_1F = Vector.find findFun (L2V[#"a"]);
val find_1T = Vector.find findFun (L2V[#"x"]);
val find_2F = Vector.find findFun (L2V[#"a", #"b"]);
val find_2T1 = Vector.find findFun (L2V[#"a", #"x"]);
val find_2T2 = Vector.find findFun (L2V[#"x", #"a"]);
val find_2T3 = Vector.find findFun (L2V[#"x", #"x"]);

(********************)
val existsFun = fn value => (print (Char.toString value); value = #"x");
val exists_0 = Vector.exists existsFun (L2V[]);
val exists_1F = Vector.exists existsFun (L2V[#"a"]);
val exists_1T = Vector.exists existsFun (L2V[#"x"]);
val exists_2F = Vector.exists existsFun (L2V[#"a", #"b"]);
val exists_2T1 = Vector.exists existsFun (L2V[#"a", #"x"]);
val exists_2T2 = Vector.exists existsFun (L2V[#"x", #"a"]);
val exists_2T3 = Vector.exists existsFun (L2V[#"x", #"x"]);

(********************)
val allFun = fn value => (print (Char.toString value); value = #"x");
val all_0 = Vector.all allFun (L2V[]);
val all_1F = Vector.all allFun (L2V[#"a"]);
val all_1T = Vector.all allFun (L2V[#"x"]);
val all_2F1 = Vector.all allFun (L2V[#"a", #"b"]);
val all_2F2 = Vector.all allFun (L2V[#"a", #"x"]);
val all_2F3 = Vector.all allFun (L2V[#"x", #"a"]);
val all_2T = Vector.all allFun (L2V[#"x", #"x"]);

(********************)
val collateFun =
    fn (x, y) =>
       if x < y
       then General.LESS
       else if x = y then General.EQUAL else General.GREATER;
val collate00 = Vector.collate collateFun ((L2V[]), (L2V[]));
val collate01 = Vector.collate collateFun ((L2V[]), (L2V[1]));
val collate10 = Vector.collate collateFun ((L2V[1]), (L2V[0]));
val collate11L = Vector.collate collateFun ((L2V[1]), (L2V[2]));
val collate11E = Vector.collate collateFun ((L2V[1]), (L2V[1]));
val collate11G = Vector.collate collateFun ((L2V[2]), (L2V[1]));
val collate12L =  Vector.collate collateFun ((L2V[1]), (L2V[1, 2]));
val collate12G =  Vector.collate collateFun ((L2V[2]), (L2V[1, 2]));
val collate21L =  Vector.collate collateFun ((L2V[1, 2]), (L2V[2]));
val collate21G =  Vector.collate collateFun ((L2V[1, 2]), (L2V[1]));
val collate22L1 = Vector.collate collateFun ((L2V[2, 1]), (L2V[3, 1]));
val collate22L2 = Vector.collate collateFun ((L2V[1, 2]), (L2V[1, 3]));
val collate22E = Vector.collate collateFun ((L2V[1, 2]), (L2V[1, 2]));
val collate22G1 = Vector.collate collateFun ((L2V[3, 1]), (L2V[2, 1]));
val collate22G2 = Vector.collate collateFun ((L2V[1, 3]), (L2V[1, 2]));
