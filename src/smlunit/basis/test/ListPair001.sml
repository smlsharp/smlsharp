(**
 * test cases for ListPair structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure ListPair001 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  structure I = Int

  (************************************************************)

  val assertEqualInt2 = assertEqual2Tuple (assertEqualInt, assertEqualInt)
  val assertEqualInt2List = assertEqualList assertEqualInt2
  val assertEqualIntList2 =
      assertEqual2Tuple (assertEqualIntList, assertEqualIntList)

  (********************)

  local
    fun test zip input result =
        let
          val r = zip input
          val () = assertEqualInt2List result r
        in
          ()
        end
  in

  local val test = test ListPair.zip
  in
  fun zip001 () =
      let
        val case00 as () = test ([], []) []
        val case01 as () = test ([], [1]) []
        val case10 as () = test ([1], []) []
        val case11 as () = test ([1], [7]) [(1, 7)]
        val case12 as () = test ([1], [7, 8]) [(1, 7)]
        val case21 as () = test ([1, 2], [7]) [(1, 7)]
        val case22 as () = test ([1, 2], [7, 8]) [(1, 7), (2, 8)]
        val case33 as () = test ([1, 2, 3], [7, 8, 9]) [(1, 7), (2, 8), (3, 9)]
      in
        ()
      end
  end (* inner local *)

  (**********)

  local
    val test = test ListPair.zipEq
    fun testFail input =
        (ListPair.zipEq input; fail "zipEq: expect UnequalLengths")
        handle ListPair.UnequalLengths => ()
  in
  fun zipEq001 () =
      let
        val case00 as () = test ([], []) []
        val case01 as () = testFail ([], [1])
        val case10 as () = testFail ([1], [])
        val case11 as () = test ([1], [7]) [(1, 7)]
        val case12 as () = testFail ([1], [7, 8])
        val case21 as () = testFail ([1, 2], [7])
        val case22 as () = test ([1, 2], [7, 8]) [(1, 7), (2, 8)]
        val case33 as () = test ([1, 2, 3], [7, 8, 9]) [(1, 7), (2, 8), (3, 9)]
      in
        ()
      end
  end (* inner local *)

  end (* outer local *)

  (********************)

  local
    fun test input result =
        let
          val r = ListPair.unzip input
          val () = assertEqualIntList2 result r
        in
          ()
        end
  in
  fun unzip001 () =
      let
        val case0 as () = test [] ([], [])
        val case1 as () = test [(1, 7)] ([1], [7])
        val case2 as () = test [(1, 7), (2, 8)] ([1, 2], [7, 8])
      in
        ()
      end
  end

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f n = r := !r @ [n]
        in
          (r, f)
        end
    fun test app input visited =
        let
          val (s, f) = makeState ()
          val () = app f input
          val () = assertEqualInt2List visited (!s)
        in
          ()
        end
  in

  local val test = test ListPair.app
  in
  fun app001 () =
      let
        val case00 as () = test ([], []) []
        val case01 as () = test ([], [7]) []
        val case10 as () = test ([1], []) []
        val case11 as () = test ([1], [7]) [(1, 7)]
        val case12 as () = test ([1], [7, 8]) [(1, 7)]
        val case21 as () = test ([1, 2], [7]) [(1, 7)]
        val case22 as () = test ([1, 2], [7, 8]) [(1, 7), (2, 8)]
        val case33 as () = test ([1, 2, 3], [7, 8, 9]) [(1, 7), (2, 8), (3, 9)]
      in
        ()
      end
  end (* inner local *)

  (**********)

  local
    val test = test ListPair.appEq
    fun testFail input visited =
        let val (s, f) = makeState ()
        in
          (ListPair.appEq f input; fail "appEq: expect UnequalLength")
          handle ListPair.UnequalLengths => assertEqualInt2List visited (!s)
        end
  in
  fun appEq001 () =
      let
        val case00 as () = test ([], []) []
        val case01 as () = testFail ([], [7]) [] 
        val case10 as () = testFail ([1], []) []
        val case11 as () = test ([1], [7]) [(1, 7)]
        val case12 as () = testFail ([1], [7, 8]) [(1, 7)]
        val case21 as () = testFail ([1, 2], [7]) [(1, 7)]
        val case22 as () = test ([1, 2], [7, 8]) [(1, 7), (2, 8)]
        val case33 as () = test ([1, 2, 3], [7, 8, 9]) [(1, 7), (2, 8), (3, 9)]
      in
        ()
      end
  end (* inner local *)

  end (* outer local *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f (x, y) = (r := !r @ [(x, y)]; (x * 10) + y)
        in
          (r, f)
        end
    fun test map input result visited =
        let
          val (s, f) = makeState ()
          val r = map f input
          val () = assertEqualIntList result r
          val () = assertEqualInt2List visited (!s)
        in
          ()
        end
  in

  local val test = test ListPair.map
  in
  fun map001 () =
      let
        val case_00 as () = test ([], []) [] []
        val case_01 as () = test ([], [7]) [] []
        val case_10 as () = test ([1], []) [] []
        val case_11 as () = test ([1], [7]) [17] [(1, 7)]
        val case_12 as () = test ([1], [7, 8]) [17] [(1, 7)]
        val case_21 as () = test ([1, 2], [7]) [17] [(1, 7)]
        val case_22 as () = test ([1, 2], [7, 8]) [17, 28] [(1, 7), (2, 8)]
        val case_33 as () = test ([1, 2, 3], [7, 8, 9]) [17, 28, 39] [(1, 7), (2, 8), (3, 9)]
      in
        ()
      end
  end (* inner local *)

  (**********)

  local
    val test = test ListPair.mapEq
    fun testFail input visited =
        let
          val (s, f) = makeState ()
        in
          (ListPair.mapEq f input; fail "mapEq: expecte UnequalLengths.")
          handle ListPair.UnequalLengths => assertEqualInt2List visited (!s)
        end
  in
  fun mapEq001 () =
      let
        val case_00 as () = test ([], []) [] []
        val case_01 as () = testFail ([], [7]) []
        val case_10 as () = testFail ([1], []) []
        val case_11 as () = test ([1], [7]) [17] [(1, 7)]
        val case_12 as () = testFail ([1], [7, 8]) [(1, 7)]
        val case_21 as () = testFail ([1, 2], [7]) [(1, 7)]
        val case_22 as () = test ([1, 2], [7, 8]) [17, 28] [(1, 7), (2, 8)]
        val case_33 as () = test ([1, 2, 3], [7, 8, 9]) [17, 28, 39] [(1, 7), (2, 8), (3, 9)]
      in
        ()
      end
  end (* inner local *)

  end (* outer local *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f (x, y, accum) = (r := !r @ [(x, y)]; x :: y :: accum)
        in
          (r, f)
        end
    fun test fold input1 input2 expected visited =
        let
          val (s, f) = makeState ()
          val r = fold f input1 input2
          val () = assertEqualIntList expected r
          val () = assertEqualInt2List visited (!s)
        in
          ()
        end
  in

  local val test = test ListPair.foldl
  in
  fun foldl001 () =
      let
        val case00 as () = test [] ([], []) [] []
        val case01 as () = test [] ([], [7]) [] []
        val case10 as () = test [] ([1], []) [] []
        val case11 as () = test [] ([1], [7]) [1, 7] [(1, 7)]
        val case12 as () = test [] ([1], [7, 8]) [1, 7] [(1, 7)]
        val case21 as () = test [] ([1, 2], [7]) [1, 7] [(1, 7)]
        val case22 as () = test [] ([1, 2], [7, 8]) [2, 8, 1, 7] [(1, 7), (2, 8)]
        val case33 as () = test [] ([1, 2, 3], [7, 8, 9]) [3, 9, 2, 8, 1, 7] [(1, 7), (2, 8), (3, 9)]
      in
        ()
      end
  end (* inner local *)

  (**********)

  local val test = test ListPair.foldr
  in
  fun foldr001 () =
      let
        val case00 as () = test [] ([], []) [] []
        val case01 as () = test [] ([], [7]) [] []
        val case10 as () = test [] ([1], []) [] []
        val case11 as () = test [] ([1], [7]) [1, 7] [(1, 7)]
        val case12 as () = test [] ([1], [7, 8]) [1, 7] [(1, 7)]
        val case21 as () = test [] ([1, 2], [7]) [1, 7] [(1, 7)]
        val case22 as () = test [] ([1, 2], [7, 8]) [1, 7, 2, 8] [(2, 8), (1, 7)]
        val case33 as () = test [] ([1, 2, 3], [7, 8, 9]) [1, 7, 2, 8, 3, 9] [(3, 9), (2, 8), (1, 7)]
      in
        ()
      end
  end (* inner local *)

  (**********)

  local
    fun testFail fold input1 input2 visited =
        let
          val (s, f) = makeState ()
        in
          (fold f input1 input2; fail "foldEq: expect UnequalLengths")
          handle ListPair.UnequalLengths => assertEqualInt2List visited (!s)
        end
  in

  local
    val test = test ListPair.foldlEq
    val testFail = testFail ListPair.foldlEq
  in
  fun foldlEq001 () =
      let
        val case00 as () = test [] ([], []) [] []
        val case01 as () = testFail [] ([], [7]) []
        val case10 as () = testFail [] ([1], []) []
        val case11 as () = test [] ([1], [7]) [1, 7] [(1, 7)]
        val case12 as () = testFail [] ([1], [7, 8]) [(1, 7)]
        val case21 as () = testFail [] ([1, 2], [7]) [(1, 7)]
        val case22 as () = test [] ([1, 2], [7, 8]) [2, 8, 1, 7] [(1, 7), (2, 8)]
        val case33 as () = test [] ([1, 2, 3], [7, 8, 9]) [3, 9, 2, 8, 1, 7] [(1, 7), (2, 8), (3, 9)]
      in
        ()
      end
  end (* inner local *)

  (**********)

  local
    val test = test ListPair.foldrEq
    val testFail = testFail ListPair.foldrEq
  in
  fun foldrEq001 () =
      let
        val case00 as () = test [] ([], []) [] []
        val case01 as () = testFail [] ([], [7]) []
        val case10 as () = testFail [] ([1], []) []
        val case11 as () = test [] ([1], [7]) [1, 7] [(1, 7)]
(* ohori: foldr does not visit any node if the two list are of unequal length
        val case12 as () = testFail [] ([1], [7, 8]) [(1, 7)]
        val case21 as () = testFail [] ([1, 2], [7]) [(1, 7)]
*)
        val case12 as () = testFail [] ([1], [7, 8]) []
        val case21 as () = testFail [] ([1, 2], [7]) []
        val case22 as () = test [] ([1, 2], [7, 8]) [1, 7, 2, 8] [(2, 8), (1, 7)]
        val case33 as () = test [] ([1, 2, 3], [7, 8, 9]) [1, 7, 2, 8, 3, 9] [(3, 9), (2, 8), (1, 7)]
      in
        ()
      end
  end (* inner local *)

  end (* outer local for foldlEq and foldrEq *)

  end (* outer local for foldl, foldr, foldlEq and foldrEq *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f (x, y) = (r := !r @ [(x, y)]; x mod 2 = 0 andalso y mod 3 = 0)
        in
          (r, f)
        end
  in

  local
    fun test input expected visited =
        let
          val (s, f) = makeState ()
          val r = ListPair.exists f input
          val () = assertEqualBool expected r
          val () = assertEqualInt2List visited (!s)
        in
          ()
        end
  in
  fun exists001 () =
      let
        val case00 as () = test ([], []) false []
        val case01__f as () = test ([], [7]) false []
        val case01__t as () = test ([], [9]) false []
        val case10_f_ as () = test ([1], []) false []
        val case10_t_ as () = test ([2], []) false []
        val case11_f_f as () = test ([1], [7]) false [(1, 7)]
        val case11_f_t as () = test ([1], [9]) false [(1, 9)]
        val case11_t_t as () = test ([2], [9]) true [(2, 9)]
        val case12_f_ff as () = test ([1], [7, 8]) false [(1, 7)]
        val case12_f_tf as () = test ([1], [9, 8]) false [(1, 9)]
        val case12_t_tf as () = test ([2], [9, 8]) true [(2, 9)]
        val case21_ff_f as () = test ([1, 3], [7]) false [(1, 7)]
        val case21_ff_t as () = test ([1, 3], [9]) false [(1, 9)]
        val case21_tf_f as () = test ([2, 3], [7]) false [(2, 7)]
        val case21_tf_t as () = test ([2, 3], [9]) true [(2, 9)]
        val case22_ff as () = test ([1, 3], [7, 8]) false [(1, 7), (3, 8)]
        val case22_ft as () = test ([1, 2], [7, 9]) true [(1, 7), (2, 9)]
        val case22_tf as () = test ([2, 3], [6, 8]) true [(2, 6)]
        val case22_tt as () = test ([2, 4], [6, 9]) true [(2, 6)]
      in
        ()
      end
  end (* inner local *)

  (**********)

  local
    fun test all input expected visited =
        let
          val (s, f) = makeState ()
          val r = all f input
          val () = assertEqualBool expected r
          val () = assertEqualInt2List visited (!s)
        in
          ()
        end
  in

  local val test = test ListPair.all
  in
  fun all001 () =
      let
        val case00 as () = test ([], []) true []
        val case01__f as () = test ([], [7]) true []
        val case01__t as () = test ([], [9]) true []
        val case10_f_ as () = test ([1], []) true []
        val case10_t_ as () = test ([2], []) true []
        val case11_f_f as () = test ([1], [7]) false [(1, 7)]
        val case11_f_t as () = test ([1], [9]) false [(1, 9)]
        val case11_t_t as () = test ([2], [9]) true [(2, 9)]
        val case12_f_ff as () = test ([1], [7, 8]) false [(1, 7)]
        val case12_f_tf as () = test ([1], [9, 8]) false [(1, 9)]
        val case12_t_tf as () = test ([2], [9, 8]) true [(2, 9)]
        val case21_ff_f as () = test ([1, 3], [7]) false [(1, 7)]
        val case21_ff_t as () = test ([1, 3], [9]) false [(1, 9)]
        val case21_tf_f as () = test ([2, 3], [7]) false [(2, 7)]
        val case21_tf_t as () = test ([2, 3], [9]) true [(2, 9)]
        val case22_ff as () = test ([1, 3], [7, 8]) false [(1, 7)]
        val case22_ft as () = test ([1, 2], [7, 9]) false [(1, 7)]
        val case22_tf as () = test ([2, 3], [6, 8]) false [(2, 6), (3, 8)]
        val case22_tt as () = test ([2, 4], [6, 9]) true [(2, 6), (4, 9)]
      in
        ()
      end
  end (* inner local *)

  (**********)

  (* allEq does not raise UnequalLength when arguments are not equal length. *)
  local val test = test ListPair.allEq
  in
  fun allEq001 () =
      let
        val case00 as () = test ([], []) true []
        val case01__f as () = test ([], [7]) false []
        val case01__t as () = test ([], [9]) false []
        val case10_f_ as () = test ([1], []) false []
        val case10_t_ as () = test ([2], []) false []
        val case11_f_f as () = test ([1], [7]) false [(1, 7)]
        val case11_f_t as () = test ([1], [9]) false [(1, 9)]
        val case11_t_t as () = test ([2], [9]) true [(2, 9)]
        val case12_f_ff as () = test ([1], [7, 8]) false [(1, 7)]
        val case12_f_tf as () = test ([1], [9, 8]) false [(1, 9)]
        val case12_t_tf as () = test ([2], [9, 8]) false [(2, 9)]
        val case21_ff_f as () = test ([1, 3], [7]) false [(1, 7)]
        val case21_ff_t as () = test ([1, 3], [9]) false [(1, 9)]
        val case21_tf_f as () = test ([2, 3], [7]) false [(2, 7)]
        val case21_tf_t as () = test ([2, 3], [9]) false [(2, 9)]
        val case22_ff as () = test ([1, 3], [7, 8]) false [(1, 7)]
        val case22_ft as () = test ([1, 2], [7, 9]) false [(1, 7)]
        val case22_tf as () = test ([2, 3], [6, 8]) false [(2, 6), (3, 8)]
        val case22_tt as () = test ([2, 4], [6, 9]) true [(2, 6), (4, 9)]
      in
        ()
      end
  end (* inner local *)

  end (* outer local for all and allEq *)

  end (* outer local for exists, all and allEq *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("zip001", zip001),
        ("zipEq001", zipEq001),
        ("unzip001", unzip001),
        ("app001", app001),
        ("appEq001", appEq001),
        ("map001", map001),
        ("mapEq001", mapEq001),
        ("foldl001", foldl001),
        ("foldr001", foldr001),
        ("foldlEq001", foldlEq001),
        ("foldrEq001", foldrEq001),
        ("exists001", exists001),
        ("all001", all001),
        ("allEq001", allEq001)
      ]

  (************************************************************)

end
