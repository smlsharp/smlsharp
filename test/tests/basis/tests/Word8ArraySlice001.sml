(*
test cases for ArraySlice structure.
*)

structure AS : MONO_ARRAY_SLICE = Word8ArraySlice;
structure A : MONO_ARRAY = Word8Array;
structure VS : MONO_VECTOR_SLICE = Word8VectorSlice;
structure V : MONO_VECTOR = Word8Vector;

fun Words2AS list =
    let val array = A.fromList (0w99 :: list @ [0w88])
    in AS.slice(array, 1, SOME(length list)) end;
fun Words2VS list =
    let val vector = V.fromList (0w99 :: list @ [0w88])
    in VS.slice(vector, 1, SOME(length list)) end;

fun AS2L array =
    let
      val length = AS.length array
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (AS.sub(array, n) :: accum)
    in scan (length - 1) []
    end;
fun VS2L vector =
    let
      val length = VS.length vector
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (VS.sub(vector, n) :: accum)
    in scan (length - 1) []
    end;
fun V2L array =
    let
      val length = A.length array
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (A.sub(array, n) :: accum)
    in scan (length - 1) []
    end;
fun L2V list = V.fromList list;
fun A2L array =
    let
      val length = A.length array
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (A.sub(array, n) :: accum)
    in scan (length - 1) []
    end;
fun L2A list = A.fromList list;
fun makeArray length = A.tabulate (length, fn index => Word8.fromInt index)

(********************)
fun testUpdate(srcArrayLength, start, length, index) =
    let
      val array = makeArray srcArrayLength
      val slice = AS.slice (array, start, SOME length)
    in
      AS.update(slice, index, 0w9);
      (A2L array, AS2L slice)
    end
      handle General.Subscript => ([0w99], [0w99]);
val update_0_0_0_0 = testUpdate(0, 0, 0, 0);
val update_1_0_1_0 = testUpdate(1, 0, 1, 0);
val update_1_0_1_1 = testUpdate(1, 0, 1, 1);
val update_5_1_3_m1 = testUpdate(5, 1, 3, ~1);
val update_5_1_3_0 = testUpdate(5, 1, 3, 0);
val update_5_1_3_2 = testUpdate(5, 1, 3, 2);
val update_5_1_3_3 = testUpdate(5, 1, 3, 3);

(********************)
fun testCopy (src, dst, di) =
    (AS.copy {src = src, dst = dst, di = di}; (AS2L src, A2L dst))
    handle Subscript => ([0w99], [0w99]);
(* variation of length of src array *)
val copy_0_3_0 = testCopy(Words2AS[], L2A[0w9, 0w8, 0w7], 0);
val copy_1_3_0 = testCopy(Words2AS[0w1], L2A[0w9, 0w8, 0w7], 0);
val copy_2_3_0 = testCopy(Words2AS[0w1, 0w2], L2A[0w9, 0w8, 0w7], 0);
(* variation of length of dst array *)
val copy_3_0_0 = testCopy(Words2AS[0w1, 0w2, 0w3], L2A[], 0);
val copy_3_1_0 = testCopy(Words2AS[0w1, 0w2, 0w3], L2A[0w9], 0);
val copy_3_2_0 = testCopy(Words2AS[0w1, 0w2, 0w3], L2A[0w9, 0w8], 0);
val copy_3_3_0 = testCopy(Words2AS[0w1, 0w2, 0w3], L2A[0w9, 0w8, 0w7], 0);
val copy_3_4_0 = testCopy(Words2AS[0w1, 0w2, 0w3], L2A[0w9, 0w8, 0w7, 0w6], 0);
(* variation of di *)
val copy_3_4_m1 =
    testCopy(Words2AS[0w1, 0w2, 0w3], L2A[0w9, 0w8, 0w7, 0w6], ~1);
val copy_3_4_0 = testCopy(Words2AS[0w1, 0w2, 0w3], L2A[0w9, 0w8, 0w7, 0w6], 0);
val copy_3_4_1 = testCopy(Words2AS[0w1, 0w2, 0w3], L2A[0w9, 0w8, 0w7, 0w6], 1);
val copy_3_4_2 = testCopy(Words2AS[0w1, 0w2, 0w3], L2A[0w9, 0w8, 0w7, 0w6], 2);

(********************)
fun testCopyVec (src, dst, di) =
    (AS.copyVec {src = src, dst = dst, di = di}; (VS2L src, A2L dst))
    handle Subscript => ([0w99], [0w99]);
(* variation of length of src array *)
val copyVec_0_3_0 = testCopyVec(Words2VS[], L2A[0w9, 0w8, 0w7], 0);
val copyVec_1_3_0 = testCopyVec(Words2VS[0w1], L2A[0w9, 0w8, 0w7], 0);
val copyVec_2_3_0 = testCopyVec(Words2VS[0w1, 0w2], L2A[0w9, 0w8, 0w7], 0);
(* variation of length of dst array *)
val copyVec_3_0_0 = testCopyVec(Words2VS[0w1, 0w2, 0w3], L2A[], 0);
val copyVec_3_1_0 = testCopyVec(Words2VS[0w1, 0w2, 0w3], L2A[0w9], 0);
val copyVec_3_2_0 = testCopyVec(Words2VS[0w1, 0w2, 0w3], L2A[0w9, 0w8], 0);
val copyVec_3_3_0 =
    testCopyVec(Words2VS[0w1, 0w2, 0w3], L2A[0w9, 0w8, 0w7], 0);
val copyVec_3_4_0 =
    testCopyVec(Words2VS[0w1, 0w2, 0w3], L2A[0w9, 0w8, 0w7, 0w6], 0);
(* variation of di *)
val copyVec_3_4_m1 =
    testCopyVec(Words2VS[0w1, 0w2, 0w3], L2A[0w9, 0w8, 0w7, 0w6], ~1);
val copyVec_3_4_0 =
    testCopyVec(Words2VS[0w1, 0w2, 0w3], L2A[0w9, 0w8, 0w7, 0w6], 0);
val copyVec_3_4_1 =
    testCopyVec(Words2VS[0w1, 0w2, 0w3], L2A[0w9, 0w8, 0w7, 0w6], 1);
val copyVec_3_4_2 =
    testCopyVec(Words2VS[0w1, 0w2, 0w3], L2A[0w9, 0w8, 0w7, 0w6], 2);
