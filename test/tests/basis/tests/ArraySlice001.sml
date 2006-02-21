(*
test cases for ArraySlice structure.
*)

structure AS : ARRAY_SLICE = ArraySlice;
structure A : ARRAY = Array;
structure VS : VECTOR_SLICE = VectorSlice;
structure V : VECTOR = Vector;

fun Ints2AS list =
    let val array = A.fromList (999 :: list @ [888])
    in AS.slice(array, 1, SOME(length list)) end;
fun Ints2VS list =
    let val vector = V.fromList (999 :: list @ [888])
    in VS.slice(vector, 1, SOME(length list)) end;

fun S2AS string =
    let val array = A.fromList (#"X" :: (String.explode string) @ [#"Y"])
    in AS.slice(array, 1, SOME(size string)) end;

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
fun L2V list = Vector.fromList list;
fun A2L array =
    let
      val length = Array.length array
      fun scan ~1 accum = accum
        | scan n accum = scan (n - 1) (Array.sub(array, n) :: accum)
    in scan (length - 1) []
    end;
fun L2A list = Array.fromList list;
fun makeArray length = A.tabulate (length, fn index => index)

(********************)
fun testUpdate(srcArrayLength, start, length, index) =
    let
      val array = makeArray srcArrayLength
      val slice = AS.slice (array, start, SOME length)
    in
      AS.update(slice, index, 9);
      (A2L array, AS2L slice)
    end
      handle General.Subscript => ([999], [999]);
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
    handle Subscript => ([~1], [~1]);
(* variation of length of src array *)
val copy_0_3_0 = testCopy(Ints2AS[], L2A[9, 8, 7], 0);
val copy_1_3_0 = testCopy(Ints2AS[1], L2A[9, 8, 7], 0);
val copy_2_3_0 = testCopy(Ints2AS[1, 2], L2A[9, 8, 7], 0);
(* variation of length of dst array *)
val copy_3_0_0 = testCopy(Ints2AS[1, 2, 3], L2A[], 0);
val copy_3_1_0 = testCopy(Ints2AS[1, 2, 3], L2A[9], 0);
val copy_3_2_0 = testCopy(Ints2AS[1, 2, 3], L2A[9, 8], 0);
val copy_3_3_0 = testCopy(Ints2AS[1, 2, 3], L2A[9, 8, 7], 0);
val copy_3_4_0 = testCopy(Ints2AS[1, 2, 3], L2A[9, 8, 7, 6], 0);
(* variation of di *)
val copy_3_4_m1 = testCopy(Ints2AS[1, 2, 3], L2A[9, 8, 7, 6], ~1);
val copy_3_4_0 = testCopy(Ints2AS[1, 2, 3], L2A[9, 8, 7, 6], 0);
val copy_3_4_1 = testCopy(Ints2AS[1, 2, 3], L2A[9, 8, 7, 6], 1);
val copy_3_4_2 = testCopy(Ints2AS[1, 2, 3], L2A[9, 8, 7, 6], 2);

(********************)
fun testCopyVec (src, dst, di) =
    (AS.copyVec {src = src, dst = dst, di = di}; (VS2L src, A2L dst))
    handle Subscript => ([~1], [~1]);
(* variation of length of src array *)
val copyVec_0_3_0 = testCopyVec(Ints2VS[], L2A[9, 8, 7], 0);
val copyVec_1_3_0 = testCopyVec(Ints2VS[1], L2A[9, 8, 7], 0);
val copyVec_2_3_0 = testCopyVec(Ints2VS[1, 2], L2A[9, 8, 7], 0);
(* variation of length of dst array *)
val copyVec_3_0_0 = testCopyVec(Ints2VS[1, 2, 3], L2A[], 0);
val copyVec_3_1_0 = testCopyVec(Ints2VS[1, 2, 3], L2A[9], 0);
val copyVec_3_2_0 = testCopyVec(Ints2VS[1, 2, 3], L2A[9, 8], 0);
val copyVec_3_3_0 = testCopyVec(Ints2VS[1, 2, 3], L2A[9, 8, 7], 0);
val copyVec_3_4_0 = testCopyVec(Ints2VS[1, 2, 3], L2A[9, 8, 7, 6], 0);
(* variation of di *)
val copyVec_3_4_m1 = testCopyVec(Ints2VS[1, 2, 3], L2A[9, 8, 7, 6], ~1);
val copyVec_3_4_0 = testCopyVec(Ints2VS[1, 2, 3], L2A[9, 8, 7, 6], 0);
val copyVec_3_4_1 = testCopyVec(Ints2VS[1, 2, 3], L2A[9, 8, 7, 6], 1);
val copyVec_3_4_2 = testCopyVec(Ints2VS[1, 2, 3], L2A[9, 8, 7, 6], 2);
