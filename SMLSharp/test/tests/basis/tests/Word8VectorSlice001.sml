(*
test cases for Word8VectorSlice structure.
*)

structure VS : MONO_VECTOR_SLICE = Word8VectorSlice;
structure V : MONO_VECTOR = Word8Vector;

fun Words2VS list =
    let val vector = V.fromList (0w99 :: list @ [0w88])
    in VS.slice(vector, 1, SOME(length list)) end;

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
fun makeVector length = V.tabulate (length, fn index => Word8.fromInt index)

(********************)
val length1 = VS.length (Words2VS[]);
val length2 = VS.length (Words2VS[0w1]);
val length3 = VS.length (Words2VS[0w1, 0w2]);

(********************)
val sub00 = VS.sub ((Words2VS[]), 0) handle General.Subscript => 0w1;
val sub0m1 = VS.sub ((Words2VS[]), ~1) handle General.Subscript => 0w1;
val sub01 = VS.sub ((Words2VS[]), 1) handle General.Subscript => 0w1;
val sub10 = VS.sub ((Words2VS[0w1]), 0);
val sub11 = VS.sub ((Words2VS[0w2]), 1) handle General.Subscript => 0w1;
val sub1m1 = VS.sub ((Words2VS[0w2]), ~1) handle General.Subscript => 0w1;
val sub20 = VS.sub ((Words2VS[0w1, 0w2]), 0);
val sub21 = VS.sub ((Words2VS[0w1, 0w2]), 1);
val sub22 = VS.sub ((Words2VS[0w1, 0w2]), 2) handle General.Subscript => 0w3;

(********************)
val full_0 = VS2L(VS.full(V.fromList ([] : Word8.word list)));
val full_1 = VS2L(VS.full(V.fromList ([0w1])));
val full_2 = VS2L(VS.full(V.fromList ([0w1, 0w2])));

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
val slice_1_0_2 = testSlice(1, 0, SOME 1) handle General.Subscript => [0w99];
val slice_1_1_N = testSlice(1, 1, NONE);
val slice_1_1_0 = testSlice(1, 1, SOME 0);
val slice_1_1_1 = testSlice(1, 1, SOME 1) handle General.Subscript => [0w99];
val slice_1_2_N = testSlice(1, 2, NONE) handle General.Subscript => [0w99];
val slice_2_0_N = testSlice(2, 0, NONE);
val slice_2_0_0 = testSlice(2, 0, SOME 0);
val slice_2_0_2 = testSlice(2, 0, SOME 2);
val slice_2_0_3 = testSlice(2, 0, SOME 3) handle General.Subscript => [0w99];
val slice_2_1_N = testSlice(2, 1, NONE);
val slice_2_1_0 = testSlice(2, 1, SOME 0);
val slice_2_1_1 = testSlice(2, 1, SOME 1);
val slice_2_1_2 = testSlice(2, 1, SOME 2) handle General.Subscript => [0w99];
val slice_2_2_N = testSlice(2, 2, NONE);
val slice_2_2_0 = testSlice(2, 2, SOME 0);
val slice_2_2_1 = testSlice(2, 2, SOME 1) handle General.Subscript => [0w99];

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
    testSubslice(5, 1, 3, 1, SOME 3) handle General.Subscript => [0w99];
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
val concat0 = V2L(VS.concat ([] : VS.slice List.list));
val concat10 = V2L(VS.concat ([(Words2VS[])] : VS.slice List.list));
val concat200 =
    V2L(VS.concat (([(Words2VS[]), (Words2VS[])]) : VS.slice List.list));
val concat11 = V2L(VS.concat ([(Words2VS[0w1])]));
val concat201 = V2L(VS.concat ([(Words2VS[]), (Words2VS[0w1])]));
val concat210 = V2L(VS.concat ([(Words2VS[0w1]), (Words2VS[])]));
val concat211 = V2L(VS.concat ([(Words2VS[0w1]), (Words2VS[0w2])]));
val concat222 = V2L(VS.concat ([(Words2VS[0w1, 0w2]), (Words2VS[0w3, 0w4])]));
val concat3303 =
    V2L
        (VS.concat
             ([
                (Words2VS[0w1, 0w2, 0w3]),
                (Words2VS[]),
                (Words2VS[0w7, 0w8, 0w9])
              ]));
val concat3333 =
    V2L
        (VS.concat
             ([
                (Words2VS[0w1, 0w2, 0w3]),
                (Words2VS[0w4, 0w5, 0w6]),
                (Words2VS[0w7, 0w8, 0w9])
              ]));

(********************)
val isEmpty_0 = VS.isEmpty (Words2VS []);
val isEmpty_1 = VS.isEmpty (Words2VS [0w1]);

(********************)
fun testGetItem (srcVectorLength, start, length) =
    let val srcVector = makeVector srcVectorLength
    in
      case VS.getItem(VS.slice(srcVector, start, SOME length)) of
        NONE => (0w99, [0w99])
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
val mapiFun = fn (index, value) => (print(Int.toString index); value);
val mapi_0 = V2L(VS.mapi mapiFun (Words2VS []));
val mapi_1 = V2L(VS.mapi mapiFun (Words2VS [0w0]));
val mapi_2 = V2L(VS.mapi mapiFun (Words2VS [0w0, 0w1]));

(********************)
val mapFun = fn x => (print(Word8.toString x); x + 0w1);
val map0 = V2L(VS.map mapFun (Words2VS[]));
val map1 = V2L(VS.map mapFun (Words2VS[0w1]));
val map2 = V2L(VS.map mapFun (Words2VS[0w1, 0w2]));
val map3 = V2L(VS.map mapFun (Words2VS[0w1, 0w2, 0w3]));

(********************)
val appiFun =
    fn (index, value) =>
       (print(Int.toString index); print(Word8.toString value));
val appi_0 = SOME(VS.appi appiFun (Words2VS []));
val appi_1 = SOME(VS.appi appiFun (Words2VS [0w0]));
val appi_2 = SOME(VS.appi appiFun (Words2VS [0w0, 0w1]));
(********************)

val appFun = fn x => print (Word8.toString x);
val app0 = VS.app appFun (Words2VS []);
val app1 = VS.app appFun (Words2VS [0w0]);
val app2 = VS.app appFun (Words2VS [0w0, 0w1]);
val app3 = VS.app appFun (Words2VS [0w0, 0w1, 0w2]);

(********************)
val foldliFun =
    fn (index, value, accum) => (print(Int.toString index); value :: accum);
val foldli_0 = VS.foldli foldliFun [] (Words2VS []);
val foldli_1 = VS.foldli foldliFun [] (Words2VS [0w0]);
val foldli_2 = VS.foldli foldliFun [] (Words2VS [0w0, 0w1]);

(********************)
val foldlFun = fn (x, xs) => x :: xs;
val foldl0 = VS.foldl foldlFun [] ((Words2VS[]) : VS.slice);
val foldl1 = VS.foldl foldlFun [] (Words2VS[0w1]);
val foldl2 = VS.foldl foldlFun [] (Words2VS[0w1, 0w2]);
val foldl3 = VS.foldl foldlFun [] (Words2VS[0w1, 0w2, 0w3]);

(********************)
val foldriFun =
    fn (index, value, accum) => (print(Int.toString index); value :: accum);
val foldri_0 = VS.foldri foldriFun [] (Words2VS []);
val foldri_1 = VS.foldri foldriFun [] (Words2VS [0w0]);
val foldri_2 = VS.foldri foldriFun [] (Words2VS [0w0, 0w1]);

(********************)
val foldrFun = fn (x, xs) => x :: xs;
val foldr0 = VS.foldr foldrFun [] ((Words2VS[]) : VS.slice);
val foldr1 = VS.foldr foldrFun [] (Words2VS[0w1]);
val foldr2 = VS.foldr foldrFun [] (Words2VS[0w1, 0w2]);
val foldr3 = VS.foldr foldrFun [] (Words2VS[0w1, 0w2, 0w3]);

(********************)
val findiFun =
    fn (index, value) =>
       (print (Int.toString index); value = (0w9 : Word8.word));
val findi_0 = VS.findi findiFun (Words2VS[]);
val findi_1F = VS.findi findiFun (Words2VS[0w1]);
val findi_1T = VS.findi findiFun (Words2VS[0w9]);
val findi_2F = VS.findi findiFun (Words2VS[0w1, 0w2]);
val findi_2T1 = VS.findi findiFun (Words2VS[0w1, 0w9]);
val findi_2T2 = VS.findi findiFun (Words2VS[0w9, 0w1]);
val findi_2T3 = VS.findi findiFun (Words2VS[0w9, 0w9]);

(********************)
val findFun = fn value => (print (Word8.toString value); value = 0w9);
val find_0 = VS.find findFun (Words2VS[]);
val find_1F = VS.find findFun (Words2VS[0w1]);
val find_1T = VS.find findFun (Words2VS[0w9]);
val find_2F = VS.find findFun (Words2VS[0w1, 0w2]);
val find_2T1 = VS.find findFun (Words2VS[0w1, 0w9]);
val find_2T2 = VS.find findFun (Words2VS[0w9, 0w1]);
val find_2T3 = VS.find findFun (Words2VS[0w9, 0w9]);

(********************)
val existsFun = fn value => (print (Word8.toString value); value = 0w9);
val exists_0 = VS.exists existsFun (Words2VS[]);
val exists_1F = VS.exists existsFun (Words2VS[0w1]);
val exists_1T = VS.exists existsFun (Words2VS[0w9]);
val exists_2F = VS.exists existsFun (Words2VS[0w1, 0w2]);
val exists_2T1 = VS.exists existsFun (Words2VS[0w1, 0w9]);
val exists_2T2 = VS.exists existsFun (Words2VS[0w9, 0w1]);
val exists_2T3 = VS.exists existsFun (Words2VS[0w9, 0w9]);

(********************)
val allFun = fn value => (print (Word8.toString value); value = 0w9);
val all_0 = VS.all allFun (Words2VS[]);
val all_1F = VS.all allFun (Words2VS[0w1]);
val all_1T = VS.all allFun (Words2VS[0w9]);
val all_2F1 = VS.all allFun (Words2VS[0w1, 0w2]);
val all_2F2 = VS.all allFun (Words2VS[0w1, 0w9]);
val all_2F3 = VS.all allFun (Words2VS[0w9, 0w1]);
val all_2T = VS.all allFun (Words2VS[0w9, 0w9]);

(********************)
val collateFun =
    fn (x, y) =>
       if x < (y : Word8.word)
       then General.LESS
       else if x = y then General.EQUAL else General.GREATER;
val collate00 = VS.collate collateFun ((Words2VS[]), (Words2VS[]));
val collate01 = VS.collate collateFun ((Words2VS[]), (Words2VS[0w1]));
val collate10 = VS.collate collateFun ((Words2VS[0w1]), (Words2VS[0w0]));
val collate11L = VS.collate collateFun ((Words2VS[0w1]), (Words2VS[0w2]));
val collate11E = VS.collate collateFun ((Words2VS[0w1]), (Words2VS[0w1]));
val collate11G = VS.collate collateFun ((Words2VS[0w2]), (Words2VS[0w1]));
val collate12L = VS.collate collateFun ((Words2VS[0w1]), (Words2VS[0w1, 0w2]));
val collate12G = VS.collate collateFun ((Words2VS[0w2]), (Words2VS[0w1, 0w2]));
val collate21L = VS.collate collateFun ((Words2VS[0w1, 0w2]), (Words2VS[0w2]));
val collate21G = VS.collate collateFun ((Words2VS[0w1, 0w2]), (Words2VS[0w1]));
val collate22L1 =
    VS.collate collateFun ((Words2VS[0w2, 0w1]), (Words2VS[0w3, 0w1]));
val collate22L2 =
    VS.collate collateFun ((Words2VS[0w1, 0w2]), (Words2VS[0w1, 0w3]));
val collate22E =
    VS.collate collateFun ((Words2VS[0w1, 0w2]), (Words2VS[0w1, 0w2]));
val collate22G1 =
    VS.collate collateFun ((Words2VS[0w3, 0w1]), (Words2VS[0w2, 0w1]));
val collate22G2 =
    VS.collate collateFun ((Words2VS[0w1, 0w3]), (Words2VS[0w1, 0w2]));

