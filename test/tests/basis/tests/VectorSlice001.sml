(*
test cases for VectorSlice structure.
*)

structure VS : VECTOR_SLICE = VectorSlice;
structure V : VECTOR = Vector;

fun Ints2VS list =
    let val vector = V.fromList (999 :: list @ [888])
    in VS.slice(vector, 1, SOME(length list)) end;

fun S2VS string =
    let val vector = V.fromList (#"X" :: (String.explode string) @ [#"Y"])
    in VS.slice(vector, 1, SOME(size string)) end;

fun VS2L vector =
    let
      val length = VS.length vector
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (VS.sub(vector, n) :: accum)
    in scan (length - 1) []
    end;
fun V2L vector =
    let
      val length = V.length vector
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (V.sub(vector, n) :: accum)
    in scan (length - 1) []
    end;
fun makeVector length = V.tabulate (length, fn index => index)

(********************)
val length1 = VS.length (Ints2VS[]);
val length2 = VS.length (Ints2VS[1]);
val length3 = VS.length (Ints2VS[1, 2]);

(********************)
val sub00 = VS.sub ((Ints2VS[]), 0) handle General.Subscript => 1;
val sub0m1 = VS.sub ((Ints2VS[]), ~1) handle General.Subscript => 1;
val sub01 = VS.sub ((Ints2VS[]), 1) handle General.Subscript => 1;
val sub10 = VS.sub ((Ints2VS[1]), 0);
val sub11 = VS.sub ((Ints2VS[2]), 1) handle General.Subscript => 1;
val sub1m1 = VS.sub ((Ints2VS[2]), ~1) handle General.Subscript => 1;
val sub20 = VS.sub ((Ints2VS[1, 2]), 0);
val sub21 = VS.sub ((Ints2VS[1, 2]), 1);
val sub22 = VS.sub ((Ints2VS[1, 2]), 2) handle General.Subscript => 3;

(********************)
val full_0 = VS2L(VS.full(V.fromList ([] : int list)));
val full_1 = VS2L(VS.full(V.fromList ([1])));
val full_2 = VS2L(VS.full(V.fromList ([1, 2])));

(********************)
fun testSlice (srcVectorLength, start, lengthOpt) =
    let
      val srcVector = makeVector srcVectorLength
    in VS2L(VS.slice(srcVector, start, lengthOpt))
    end;
val slice_0_0_N = testSlice(0, 0, NONE);
val slice_1_0_N = testSlice(1, 0, NONE);
val slice_1_0_0 = testSlice(1, 0, SOME 0);
val slice_1_0_1 = testSlice(1, 0, SOME 1);
val slice_1_0_2 = testSlice(1, 0, SOME 1) handle General.Subscript => [999];
val slice_1_1_N = testSlice(1, 1, NONE);
val slice_1_1_0 = testSlice(1, 1, SOME 0);
val slice_1_1_1 = testSlice(1, 1, SOME 1) handle General.Subscript => [999];
val slice_1_2_N = testSlice(1, 2, NONE) handle General.Subscript => [999];
val slice_2_0_N = testSlice(2, 0, NONE);
val slice_2_0_0 = testSlice(2, 0, SOME 0);
val slice_2_0_2 = testSlice(2, 0, SOME 2);
val slice_2_0_3 = testSlice(2, 0, SOME 3) handle General.Subscript => [999];
val slice_2_1_N = testSlice(2, 1, NONE);
val slice_2_1_0 = testSlice(2, 1, SOME 0);
val slice_2_1_1 = testSlice(2, 1, SOME 1);
val slice_2_1_2 = testSlice(2, 1, SOME 2) handle General.Subscript => [999];
val slice_2_2_N = testSlice(2, 2, NONE);
val slice_2_2_0 = testSlice(2, 2, SOME 0);
val slice_2_2_1 = testSlice(2, 2, SOME 1) handle General.Subscript => [999];

(********************)
fun testSubslice(srcVectorLength, start1, length1, start2, lengthOpt2) =
    let
      val srcVector = makeVector srcVectorLength
      val slice1 = VS.slice(srcVector, start1, SOME length1)
      val slice2 = VS.subslice(slice1, start2, lengthOpt2)
    in
      VS2L(slice2)
    end;
val subslice_5_1_3_0_N = testSubslice(5, 1, 3, 0, NONE);
val subslice_5_1_3_0_3 = testSubslice(5, 1, 3, 0, SOME 3);
val subslice_5_1_3_1_N = testSubslice(5, 1, 3, 1, NONE);
val subslice_5_1_3_1_0 = testSubslice(5, 1, 3, 1, SOME 0);
val subslice_5_1_3_1_1 = testSubslice(5, 1, 3, 1, SOME 1);
val subslice_5_1_3_1_3 =
    testSubslice(5, 1, 3, 1, SOME 3) handle General.Subscript => [999];
val subslice_5_1_3_2_N = testSubslice(5, 1, 3, 2, NONE);
val subslice_5_1_3_2_1 = testSubslice(5, 1, 3, 1, SOME 1);

(********************)
fun testBase(srcVectorLength, start, length) =
    let
      val srcVector = makeVector srcVectorLength
      val slice = VS.slice(srcVector, start, SOME length)
    in
      case VS.base(slice) of (vector, s, len) => (V2L vector, s, len)
    end;
val base_0_0_0 = testBase(0, 0, 0);
val base_2_0_0 = testBase(2, 0, 0);
val base_2_0_1 = testBase(2, 0, 1);
val base_2_1_1 = testBase(2, 1, 1);

(********************)
fun testVector(srcVectorLength, start, length) =
    let
      val srcVector = makeVector srcVectorLength
      val slice = VS.slice(srcVector, start, SOME length)
    in
      V2L(VS.vector(slice))
    end;
val vector_0_0_0 = testVector(0, 0, 0);
val vector_2_0_0 = testVector(2, 0, 0);
val vector_2_0_1 = testVector(2, 0, 1);
val vector_2_1_1 = testVector(2, 1, 1);

(********************)
val concat0 = V2L(VS.concat ([] : int VS.slice List.list));
val concat10 = V2L(VS.concat ([(Ints2VS[])] : int VS.slice List.list));
val concat200 =
    V2L(VS.concat (([(Ints2VS[]), (Ints2VS[])]) : int VS.slice List.list));
val concat11 = V2L(VS.concat ([(Ints2VS[1])]));
val concat201 = V2L(VS.concat ([(Ints2VS[]), (Ints2VS[1])]));
val concat210 = V2L(VS.concat ([(Ints2VS[1]), (Ints2VS[])]));
val concat211 = V2L(VS.concat ([(Ints2VS[1]), (Ints2VS[2])]));
val concat222 = V2L(VS.concat ([(Ints2VS[1, 2]), (Ints2VS[3, 4])]));
val concat3303 =
    V2L(VS.concat ([(Ints2VS[1, 2, 3]), (Ints2VS[]), (Ints2VS[7, 8, 9])]));
val concat3333 =
    V2L
        (VS.concat
             ([(Ints2VS[1, 2, 3]), (Ints2VS[4, 5, 6]), (Ints2VS[7, 8, 9])]));

(********************)
val isEmpty_0 = VS.isEmpty (Ints2VS []);
val isEmpty_1 = VS.isEmpty (Ints2VS [1]);

(********************)
fun testGetItem (srcVectorLength, start, length) =
    let val srcVector = makeVector srcVectorLength
    in
      case VS.getItem(VS.slice(srcVector, start, SOME length)) of
        NONE => (999, [999])
      | SOME(value, newSlice) => (value, VS2L newSlice)
    end;
val getItem_0_0_0 = testGetItem(0, 0, 0);
val getItem_1_0_0 = testGetItem(1, 0, 0);
val getItem_1_0_1 = testGetItem(1, 0, 1);
val getItem_1_1_0 = testGetItem(1, 1, 0);
val getItem_2_0_0 = testGetItem(2, 0, 0);
val getItem_2_0_1 = testGetItem(2, 0, 1);
val getItem_2_0_2 = testGetItem(2, 0, 2);
val getItem_2_1_0 = testGetItem(2, 1, 0);
val getItem_2_1_1 = testGetItem(2, 1, 1);
val getItem_2_2_0 = testGetItem(2, 2, 0);

(********************)
val mapiFun = fn (index, ch) => (print(Int.toString index); ch);
val mapi_0 = V2L(VS.mapi mapiFun (S2VS""));
val mapi_1 = V2L(VS.mapi mapiFun (S2VS"a"));
val mapi_2 = V2L(VS.mapi mapiFun (S2VS"ab"));

(********************)
val mapFun = fn x => (print(Int.toString x); x + 1);
val map0 = V2L(VS.map mapFun (Ints2VS[]));
val map1 = V2L(VS.map mapFun (Ints2VS[1]));
val map2 = V2L(VS.map mapFun (Ints2VS[1, 2]));
val map3 = V2L(VS.map mapFun (Ints2VS[1, 2, 3]));

(********************)
val appiFun =
    fn (index, ch) => (print(Int.toString index); print(Char.toString ch));
val appi_0 = SOME(VS.appi appiFun (S2VS""));
val appi_1 = SOME(VS.appi appiFun (S2VS"a"));
val appi_2 = SOME(VS.appi appiFun (S2VS"ab"));
(********************)

val appFun = fn x => print (Char.toString x);
val app0 = VS.app appFun (S2VS "");
val app1 = VS.app appFun (S2VS "a");
val app2 = VS.app appFun (S2VS "ab");
val app3 = VS.app appFun (S2VS "abc");

(********************)
val foldliFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
val foldli_0 = VS.foldli foldliFun [] (S2VS"");
val foldli_1 = VS.foldli foldliFun [] (S2VS"a");
val foldli_2 = VS.foldli foldliFun [] (S2VS"ab");

(********************)
val foldlFun = fn (x, xs) => x :: xs;
val foldl0 = VS.foldl foldlFun [] ((Ints2VS[]) : int VS.slice);
val foldl1 = VS.foldl foldlFun [] (Ints2VS[1]);
val foldl2 = VS.foldl foldlFun [] (Ints2VS[1, 2]);
val foldl3 = VS.foldl foldlFun [] (Ints2VS[1, 2, 3]);

(********************)
val foldriFun =
    fn (index, ch, accum) => (print(Int.toString index); ch :: accum);
val foldri_0 = VS.foldri foldriFun [] (S2VS"");
val foldri_1 = VS.foldri foldriFun [] (S2VS"a");
val foldri_2 = VS.foldri foldriFun [] (S2VS"ab");

(********************)
val foldrFun = fn (x, xs) => x :: xs;
val foldr0 = VS.foldr foldrFun [] ((Ints2VS[]) : int VS.slice);
val foldr1 = VS.foldr foldrFun [] (Ints2VS[1]);
val foldr2 = VS.foldr foldrFun [] (Ints2VS[1, 2]);
val foldr3 = VS.foldr foldrFun [] (Ints2VS[1, 2, 3]);

(********************)
val findiFun =
    fn (index, value) => (print (Int.toString index); value = 9);
val findi_0 = VS.findi findiFun (Ints2VS[]);
val findi_1F = VS.findi findiFun (Ints2VS[1]);
val findi_1T = VS.findi findiFun (Ints2VS[9]);
val findi_2F = VS.findi findiFun (Ints2VS[1, 2]);
val findi_2T1 = VS.findi findiFun (Ints2VS[1, 9]);
val findi_2T2 = VS.findi findiFun (Ints2VS[9, 1]);
val findi_2T3 = VS.findi findiFun (Ints2VS[9, 9]);

(********************)
val findFun = fn value => (print (Int.toString value); value = 9);
val find_0 = VS.find findFun (Ints2VS[]);
val find_1F = VS.find findFun (Ints2VS[1]);
val find_1T = VS.find findFun (Ints2VS[9]);
val find_2F = VS.find findFun (Ints2VS[1, 2]);
val find_2T1 = VS.find findFun (Ints2VS[1, 9]);
val find_2T2 = VS.find findFun (Ints2VS[9, 1]);
val find_2T3 = VS.find findFun (Ints2VS[9, 9]);

(********************)
val existsFun = fn value => (print (Int.toString value); value = 9);
val exists_0 = VS.exists existsFun (Ints2VS[]);
val exists_1F = VS.exists existsFun (Ints2VS[1]);
val exists_1T = VS.exists existsFun (Ints2VS[9]);
val exists_2F = VS.exists existsFun (Ints2VS[1, 2]);
val exists_2T1 = VS.exists existsFun (Ints2VS[1, 9]);
val exists_2T2 = VS.exists existsFun (Ints2VS[9, 1]);
val exists_2T3 = VS.exists existsFun (Ints2VS[9, 9]);

(********************)
val allFun = fn value => (print (Int.toString value); value = 9);
val all_0 = VS.all allFun (Ints2VS[]);
val all_1F = VS.all allFun (Ints2VS[1]);
val all_1T = VS.all allFun (Ints2VS[9]);
val all_2F1 = VS.all allFun (Ints2VS[1, 2]);
val all_2F2 = VS.all allFun (Ints2VS[1, 9]);
val all_2F3 = VS.all allFun (Ints2VS[9, 1]);
val all_2T = VS.all allFun (Ints2VS[9, 9]);

(********************)
val collateFun =
    fn (x, y) =>
       if x < y
       then General.LESS
       else if x = y then General.EQUAL else General.GREATER;
val collate00 = VS.collate collateFun ((Ints2VS[]), (Ints2VS[]));
val collate01 = VS.collate collateFun ((Ints2VS[]), (Ints2VS[1]));
val collate10 = VS.collate collateFun ((Ints2VS[1]), (Ints2VS[0]));
val collate11L = VS.collate collateFun ((Ints2VS[1]), (Ints2VS[2]));
val collate11E = VS.collate collateFun ((Ints2VS[1]), (Ints2VS[1]));
val collate11G = VS.collate collateFun ((Ints2VS[2]), (Ints2VS[1]));
val collate12L =  VS.collate collateFun ((Ints2VS[1]), (Ints2VS[1, 2]));
val collate12G =  VS.collate collateFun ((Ints2VS[2]), (Ints2VS[1, 2]));
val collate21L =  VS.collate collateFun ((Ints2VS[1, 2]), (Ints2VS[2]));
val collate21G =  VS.collate collateFun ((Ints2VS[1, 2]), (Ints2VS[1]));
val collate22L1 = VS.collate collateFun ((Ints2VS[2, 1]), (Ints2VS[3, 1]));
val collate22L2 = VS.collate collateFun ((Ints2VS[1, 2]), (Ints2VS[1, 3]));
val collate22E = VS.collate collateFun ((Ints2VS[1, 2]), (Ints2VS[1, 2]));
val collate22G1 = VS.collate collateFun ((Ints2VS[3, 1]), (Ints2VS[2, 1]));
val collate22G2 = VS.collate collateFun ((Ints2VS[1, 3]), (Ints2VS[1, 2]));

