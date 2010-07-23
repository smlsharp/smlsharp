(**
 * test cases for ListPair structure.
 *
 * Test cases for *Eq functions, such as zipEq, appEp, etc., should be added,
 * although Basis implementation in SML/NJ does not provide them.
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
    fun test input result =
        let
          val r = ListPair.zip input
          val _ = assertEqualInt2List result r
        in
          ()
        end
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
  end

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

  local
    fun makeState () =
        let
          val r = ref []
          fun f n = r := !r @ [n]
        in
          (r, f)
        end
    fun test input visited =
        let
          val (s, f) = makeState ()
          val app00 = ListPair.app f ([], [])
          val _ = assertEqualInt2List [] (!s)
        in
          ()
        end
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
  end

  local
    fun makeState () =
        let
          val r = ref []
          fun f (x, y) = (r := !r @ [(x, y)]; (x * 10) + y)
        in
          (r, f)
        end
    fun test input result visited =
        let
          val (s, f) = makeState ()
          val r = ListPair.map f input
          val _ = assertEqualIntList result r
          val _ = assertEqualInt2List visited (!s)
        in
          ()
        end
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
  end

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
    val testl = test ListPair.foldl
    val testr = test ListPair.foldr
  in
  fun foldl001 () =
      let
        val foldl00 = testl [] ([], []) [] []
        val foldl01 = testl [] ([], [7]) [] []
        val foldl10 = testl [] ([1], []) [] []
        val foldl11 = testl [] ([1], [7]) [1, 7] [(1, 7)]
        val foldl12 = testl [] ([1], [7, 8]) [1, 7] [(1, 7)]
        val foldl21 = testl [] ([1, 2], [7]) [1, 7] [(1, 7)]
        val foldl22 = testl [] ([1, 2], [7, 8]) [2, 8, 1, 7] [(1, 7), (2, 8)]
        val foldl33 = testl [] ([1, 2, 3], [7, 8, 9]) [3, 9, 2, 8, 1, 7] [(1, 7), (2, 8), (3, 9)]
      in
        ()
      end
  fun foldr001 () =
      let
        val foldr00 = testr [] ([], []) [] []
        val foldr01 = testr [] ([], [7]) [] []
        val foldr10 = testr [] ([1], []) [] []
        val foldr11 = testr [] ([1], [7]) [1, 7] [(1, 7)]
        val foldr12 = testr [] ([1], [7, 8]) [1, 7] [(1, 7)]
        val foldr21 = testr [] ([1, 2], [7]) [1, 7] [(1, 7)]
        val foldr22 = testr [] ([1, 2], [7, 8]) [1, 7, 2, 8] [(2, 8), (1, 7)]
        val foldr33 = testr [] ([1, 2, 3], [7, 8, 9]) [1, 7, 2, 8, 3, 9] [(3, 9), (2, 8), (1, 7)]
      in
        ()
      end
  end

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
  end

  local
    fun test input expected visited =
        let
          val (s, f) = makeState ()
          val r = ListPair.all f input
          val _ = assertEqualBool expected r
          val _ = assertEqualInt2List visited (!s)
        in
          ()
        end
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
  end (* local *)

  end (* local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("zip001", zip001),
        ("unzip001", unzip001),
        ("app001", app001),
        ("map001", map001),
        ("foldl001", foldl001),
        ("foldr001", foldr001),
        ("exists001", exists001),
        ("all001", all001)
      ]

  (************************************************************)

end