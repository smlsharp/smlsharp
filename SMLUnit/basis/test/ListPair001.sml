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
          val _ = assertEqualInt2List result r
        in
          ()
        end
  in

  local val test = test ListPair.zip
  in
  fun zip001 () =
      let
        val zip00 = test ([], []) []
        val zip01 = test ([], [1]) []
        val zip10 = test ([1], []) []
        val zip11 = test ([1], [7]) [(1, 7)]
        val zip12 = test ([1], [7, 8]) [(1, 7)]
        val zip21 = test ([1, 2], [7]) [(1, 7)]
        val zip22 = test ([1, 2], [7, 8]) [(1, 7), (2, 8)]
        val zip33 = test ([1, 2, 3], [7, 8, 9]) [(1, 7), (2, 8), (3, 9)]
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
        val zipEq00 = test ([], []) []
        val zipEq01 = testFail ([], [1])
        val zipEq10 = testFail ([1], [])
        val zipEq11 = test ([1], [7]) [(1, 7)]
        val zipEq12 = testFail ([1], [7, 8])
        val zipEq21 = testFail ([1, 2], [7])
        val zipEq22 = test ([1, 2], [7, 8]) [(1, 7), (2, 8)]
        val zipEq33 = test ([1, 2, 3], [7, 8, 9]) [(1, 7), (2, 8), (3, 9)]
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
          val _ = assertEqualIntList2 result r
        in
          ()
        end
  in
  fun unzip001 () =
      let
        val unzip0 = test [] ([], [])
        val unzip1 = test [(1, 7)] ([1], [7])
        val unzip2 = test [(1, 7), (2, 8)] ([1, 2], [7, 8])
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
          val _ = assertEqualInt2List visited (!s)
        in
          ()
        end
  in

  local val test = test ListPair.app
  in
  fun app001 () =
      let
        val app00 = test ([], []) []
        val app01 = test ([], [7]) []
        val app10 = test ([1], []) []
        val app11 = test ([1], [7]) [(1, 7)]
        val app12 = test ([1], [7, 8]) [(1, 7)]
        val app21 = test ([1, 2], [7]) [(1, 7)]
        val app22 = test ([1, 2], [7, 8]) [(1, 7), (2, 8)]
        val app33 = test ([1, 2, 3], [7, 8, 9]) [(1, 7), (2, 8), (3, 9)]
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
        val appEq00 = test ([], []) []
        val appEq01 = testFail ([], [7]) [] 
        val appEq10 = testFail ([1], []) []
        val appEq11 = test ([1], [7]) [(1, 7)]
        val appEq12 = testFail ([1], [7, 8]) [(1, 7)]
        val appEq21 = testFail ([1, 2], [7]) [(1, 7)]
        val appEq22 = test ([1, 2], [7, 8]) [(1, 7), (2, 8)]
        val appEq33 = test ([1, 2, 3], [7, 8, 9]) [(1, 7), (2, 8), (3, 9)]
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
          val _ = assertEqualIntList result r
          val _ = assertEqualInt2List visited (!s)
        in
          ()
        end
  in

  local val test = test ListPair.map
  in
  fun map001 () =
      let
        val map_00 = test ([], []) [] []
        val map_01 = test ([], [7]) [] []
        val map_10 = test ([1], []) [] []
        val map_11 = test ([1], [7]) [17] [(1, 7)]
        val map_12 = test ([1], [7, 8]) [17] [(1, 7)]
        val map_21 = test ([1, 2], [7]) [17] [(1, 7)]
        val map_22 = test ([1, 2], [7, 8]) [17, 28] [(1, 7), (2, 8)]
        val map_33 = test ([1, 2, 3], [7, 8, 9]) [17, 28, 39] [(1, 7), (2, 8), (3, 9)]
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
        val mapEq_00 = test ([], []) [] []
        val mapEq_01 = testFail ([], [7]) []
        val mapEq_10 = testFail ([1], []) []
        val mapEq_11 = test ([1], [7]) [17] [(1, 7)]
        val mapEq_12 = testFail ([1], [7, 8]) [(1, 7)]
        val mapEq_21 = testFail ([1, 2], [7]) [(1, 7)]
        val mapEq_22 = test ([1, 2], [7, 8]) [17, 28] [(1, 7), (2, 8)]
        val mapEq_33 = test ([1, 2, 3], [7, 8, 9]) [17, 28, 39] [(1, 7), (2, 8), (3, 9)]
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
          val _ = assertEqualIntList expected r
          val _ = assertEqualInt2List visited (!s)
        in
          ()
        end
  in

  local val test = test ListPair.foldl
  in
  fun foldl001 () =
      let
        val foldl00 = test [] ([], []) [] []
        val foldl01 = test [] ([], [7]) [] []
        val foldl10 = test [] ([1], []) [] []
        val foldl11 = test [] ([1], [7]) [1, 7] [(1, 7)]
        val foldl12 = test [] ([1], [7, 8]) [1, 7] [(1, 7)]
        val foldl21 = test [] ([1, 2], [7]) [1, 7] [(1, 7)]
        val foldl22 = test [] ([1, 2], [7, 8]) [2, 8, 1, 7] [(1, 7), (2, 8)]
        val foldl33 = test [] ([1, 2, 3], [7, 8, 9]) [3, 9, 2, 8, 1, 7] [(1, 7), (2, 8), (3, 9)]
      in
        ()
      end
  end (* inner local *)

  (**********)

  local val test = test ListPair.foldr
  in
  fun foldr001 () =
      let
        val foldr00 = test [] ([], []) [] []
        val foldr01 = test [] ([], [7]) [] []
        val foldr10 = test [] ([1], []) [] []
        val foldr11 = test [] ([1], [7]) [1, 7] [(1, 7)]
        val foldr12 = test [] ([1], [7, 8]) [1, 7] [(1, 7)]
        val foldr21 = test [] ([1, 2], [7]) [1, 7] [(1, 7)]
        val foldr22 = test [] ([1, 2], [7, 8]) [1, 7, 2, 8] [(2, 8), (1, 7)]
        val foldr33 = test [] ([1, 2, 3], [7, 8, 9]) [1, 7, 2, 8, 3, 9] [(3, 9), (2, 8), (1, 7)]
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
        val foldlEq00 = test [] ([], []) [] []
        val foldlEq01 = testFail [] ([], [7]) []
        val foldlEq10 = testFail [] ([1], []) []
        val foldlEq11 = test [] ([1], [7]) [1, 7] [(1, 7)]
        val foldlEq12 = testFail [] ([1], [7, 8]) [(1, 7)]
        val foldlEq21 = testFail [] ([1, 2], [7]) [(1, 7)]
        val foldlEq22 = test [] ([1, 2], [7, 8]) [2, 8, 1, 7] [(1, 7), (2, 8)]
        val foldlEq33 = test [] ([1, 2, 3], [7, 8, 9]) [3, 9, 2, 8, 1, 7] [(1, 7), (2, 8), (3, 9)]
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
        val foldrEq00 = test [] ([], []) [] []
        val foldrEq01 = testFail [] ([], [7]) []
        val foldrEq10 = testFail [] ([1], []) []
        val foldrEq11 = test [] ([1], [7]) [1, 7] [(1, 7)]
        val foldrEq12 = testFail [] ([1], [7, 8]) [(1, 7)]
        val foldrEq21 = testFail [] ([1, 2], [7]) [(1, 7)]
        val foldrEq22 = test [] ([1, 2], [7, 8]) [1, 7, 2, 8] [(2, 8), (1, 7)]
        val foldrEq33 = test [] ([1, 2, 3], [7, 8, 9]) [1, 7, 2, 8, 3, 9] [(3, 9), (2, 8), (1, 7)]
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
          val _ = assertEqualBool expected r
          val _ = assertEqualInt2List visited (!s)
        in
          ()
        end
  in
  fun exists001 () =
      let
        val exists00 = test ([], []) false []
        val exists01__f = test ([], [7]) false []
        val exists01__t = test ([], [9]) false []
        val exists10_f_ = test ([1], []) false []
        val exists10_t_ = test ([2], []) false []
        val exists11_f_f = test ([1], [7]) false [(1, 7)]
        val exists11_f_t = test ([1], [9]) false [(1, 9)]
        val exists11_t_t = test ([2], [9]) true [(2, 9)]
        val exists12_f_ff = test ([1], [7, 8]) false [(1, 7)]
        val exists12_f_tf = test ([1], [9, 8]) false [(1, 9)]
        val exists12_t_tf = test ([2], [9, 8]) true [(2, 9)]
        val exists21_ff_f = test ([1, 3], [7]) false [(1, 7)]
        val exists21_ff_t = test ([1, 3], [9]) false [(1, 9)]
        val exists21_tf_f = test ([2, 3], [7]) false [(2, 7)]
        val exists21_tf_t = test ([2, 3], [9]) true [(2, 9)]
        val exists22_ff = test ([1, 3], [7, 8]) false [(1, 7), (3, 8)]
        val exists22_ft = test ([1, 2], [7, 9]) true [(1, 7), (2, 9)]
        val exists22_tf = test ([2, 3], [6, 8]) true [(2, 6)]
        val exists22_tt = test ([2, 4], [6, 9]) true [(2, 6)]
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
          val _ = assertEqualBool expected r
          val _ = assertEqualInt2List visited (!s)
        in
          ()
        end
  in

  local val test = test ListPair.all
  in
  fun all001 () =
      let
        val all00 = test ([], []) true []
        val all01__f = test ([], [7]) true []
        val all01__t = test ([], [9]) true []
        val all10_f_ = test ([1], []) true []
        val all10_t_ = test ([2], []) true []
        val all11_f_f = test ([1], [7]) false [(1, 7)]
        val all11_f_t = test ([1], [9]) false [(1, 9)]
        val all11_t_t = test ([2], [9]) true [(2, 9)]
        val all12_f_ff = test ([1], [7, 8]) false [(1, 7)]
        val all12_f_tf = test ([1], [9, 8]) false [(1, 9)]
        val all12_t_tf = test ([2], [9, 8]) true [(2, 9)]
        val all21_ff_f = test ([1, 3], [7]) false [(1, 7)]
        val all21_ff_t = test ([1, 3], [9]) false [(1, 9)]
        val all21_tf_f = test ([2, 3], [7]) false [(2, 7)]
        val all21_tf_t = test ([2, 3], [9]) true [(2, 9)]
        val all22_ff = test ([1, 3], [7, 8]) false [(1, 7)]
        val all22_ft = test ([1, 2], [7, 9]) false [(1, 7)]
        val all22_tf = test ([2, 3], [6, 8]) false [(2, 6), (3, 8)]
        val all22_tt = test ([2, 4], [6, 9]) true [(2, 6), (4, 9)]
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
        val allEq00 = test ([], []) true []
        val allEq01__f = test ([], [7]) false []
        val allEq01__t = test ([], [9]) false []
        val allEq10_f_ = test ([1], []) false []
        val allEq10_t_ = test ([2], []) false []
        val allEq11_f_f = test ([1], [7]) false [(1, 7)]
        val allEq11_f_t = test ([1], [9]) false [(1, 9)]
        val allEq11_t_t = test ([2], [9]) true [(2, 9)]
        val allEq12_f_ff = test ([1], [7, 8]) false [(1, 7)]
        val allEq12_f_tf = test ([1], [9, 8]) false [(1, 9)]
        val allEq12_t_tf = test ([2], [9, 8]) false [(2, 9)]
        val allEq21_ff_f = test ([1, 3], [7]) false [(1, 7)]
        val allEq21_ff_t = test ([1, 3], [9]) false [(1, 9)]
        val allEq21_tf_f = test ([2, 3], [7]) false [(2, 7)]
        val allEq21_tf_t = test ([2, 3], [9]) false [(2, 9)]
        val allEq22_ff = test ([1, 3], [7, 8]) false [(1, 7)]
        val allEq22_ft = test ([1, 2], [7, 9]) false [(1, 7)]
        val allEq22_tf = test ([2, 3], [6, 8]) false [(2, 6), (3, 8)]
        val allEq22_tt = test ([2, 4], [6, 9]) true [(2, 6), (4, 9)]
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