(**
 * test cases for mutable 2-dimension sequence structures.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
functor Mutable2DSequence001(A : MUTABLE_2D_SEQUENCE) =
struct

  (************************************************************)

  structure T = SMLUnit.Test
  open SMLUnit.Assert

  (************************************************************)

  val assertEqual2Int = assertEqual2Tuple (assertEqualInt, assertEqualInt)

  val assertEqualElem = assertEqualByCompare A.compareElem A.elemToString
  val assertEqualElemList = assertEqualList assertEqualElem
  val assertEqualElemListList = assertEqualList assertEqualElemList
  val assertEqualElemOption = assertEqualOption assertEqualElem
  val assertEqualIntElem = assertEqual2Tuple (assertEqualInt, assertEqualElem)
  val assertEqualIntElemList = assertEqualList assertEqualIntElem
  val assertEqualIntElemOption = assertEqualOption assertEqualIntElem
  val assertEqualElem2List =
      assertEqualList (assertEqual2Tuple (assertEqualElem, assertEqualElem))
  val assertEqualInt2List = 
      assertEqualList (assertEqual2Tuple (assertEqualInt, assertEqualInt))
  val assertEqualInt2ElemList = 
      assertEqualList
          (assertEqual3Tuple (assertEqualInt, assertEqualInt, assertEqualElem))

  val [n0, n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12] =
      List.map A.intToElem [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

  val L2A = A.fromList
  val L2V = A.listToVector
  val V2L = A.vectorToList

  (*
   * toList o A.fromList = id
   *)
  fun toList array =
      let
        fun arrayToList iRow accum =
            if iRow = A.nRows array
            then List.rev accum
            else arrayToList (iRow + 1) (V2L (A.row (array, iRow)) :: accum)
      in arrayToList 0 []
      end

  fun makeRegion (array, row, col, nrows, ncols) =
      {base = array, row = row, col = col, nrows = nrows, ncols = ncols}

  (****************************************)

  fun equality001 () =
      let
        val a_0_0_1 = A.fromList []
        val a_0_0_2 = A.fromList []
        val case_0_T as () = assertTrue (a_0_0_1 = a_0_0_1)
        val case_0_F as () = assertFalse (a_0_0_1 = a_0_0_2)

        val a_1_0_1 = A.fromList [[]]
        val a_1_0_2 = A.fromList [[]]
        val case_0_T as () = assertTrue (a_1_0_1 = a_1_0_1)
        val case_0_F as () = assertFalse (a_1_0_1 = a_1_0_2)

        val a_1_1_1 = A.fromList [[n1]]
        val a_1_1_2 = A.fromList [[n1]]
        val case_1_T as () = assertTrue (a_1_1_1 = a_1_1_1)
        val case_1_F as () = assertFalse (a_1_1_1 = a_1_1_2)
      in () end

  (********************)

  local
    fun test (r, c) =
        let
          val array = A.array (r, c, n0)
          val () = assertEqual2Int (r, c) (A.dimensions array)
          val () = assertEqualInt r (A.nRows array)
          val () = assertEqualInt c (A.nCols array)
        in () end
  in
  fun array001 () =
      let
        val case_0_0 as () = test (0, 0)
        val case_0_1 as () = test (0, 1)
        val case_1_0 as () = test (1, 0)
        val case_1_1 as () = test (1, 1)
        val case_1_2 as () = test (1, 2)
        val case_2_1 as () = test (2, 1)
        val case_2_2 as () = test (2, 2)
      in () end
  end (* local *)
  local
    fun testSize (r, c) =
        (A.array (r, c, n0); fail "expect Size") handle General.Size => ()
  in
  fun array101 () =
      let
        val case_n1_1 as () = testSize (~1, 1)
        val case_1_n1 as () = testSize (1, ~1)
      in () end
  end

  (********************)

  local
    fun test list =
        let
          val argRows = List.length list
          val argCols = case list of [] => 0 | (hd::_) => List.length hd

          val array = A.fromList list
          val () = assertEqual2Int (argRows, argCols) (A.dimensions array)
          val () = assertEqualInt argRows (A.nRows array)
          val () = assertEqualInt argCols (A.nCols array)

          fun assertArray _ [] = ()
            | assertArray iRow (row :: rows) =
              let
                fun assertRow _ [] = ()
                  | assertRow iCol (elem :: elems) =
                    (
                      assertEqualElem elem (A.sub (array, iRow, iCol));
                      assertRow (iCol + 1) elems
                     )
              in
                assertRow 0 row; assertArray (iRow + 1) rows
              end

          val () = assertArray 0 list
        in () end
    fun testSize list =
        (A.fromList list; fail "expect Size") handle General.Size => ()
  in
  fun fromList001 () =
      let
        val case_0_0 as () = test []
        val case_1_0 as () = test [[]]
        val case_1_1 as () = test [[n0]]
        val case_1_2 as () = test [[n0, n1]]
        val case_2_1 as () = test [[n0], [n1]]
        val case_2_2 as () = test [[n0, n1], [n2, n3]]
      in () end
  fun fromList101 () =
      let
        val case_0_1 as () = testSize [[], [n0]]
        val case_1_0 as () = testSize [[n0], []]
      in () end
  end (* local *)

  (********************)

  local
    fun makeElement (iRow, iCol) = A.intToElem (iRow * 10 + iCol)
    fun makeState () =
        let
          val s = ref []
          fun f (iRow, iCol) =
              let val elem = makeElement (iRow, iCol)
              in s := (!s) @ [(iRow, iCol)]; elem end
        in (s, f) end
    fun test order (nRows, nCols) visited =
        let
          val (state, tabulateFun) = makeState ()
          val array = A.tabulate order (nRows, nCols, tabulateFun)
          val () = assertEqual2Int (nRows, nCols) (A.dimensions array)
          val () = assertEqualInt nRows (A.nRows array)
          val () = assertEqualInt nCols (A.nCols array)
          val () = assertEqualInt2List visited (!state)

          fun assertArray iRow =
              if iRow = nRows
              then ()
              else
                let
                  fun assertRow iCol =
                      if iCol = nCols
                      then ()
                      else
                        let val elem = makeElement (iRow, iCol)
                        in
                          assertEqualElem elem (A.sub (array, iRow, iCol));
                          assertRow (iCol + 1)
                        end
                in
                  assertRow 0; assertArray (iRow + 1)
                end

          val () = assertArray 0
        in () end
    fun testSize order (nRows, nCols) =
        (
          A.tabulate order (nRows, nCols, fn _ => fail "unexpected call");
          fail "expect Size"
        ) handle General.Size => ()
  in
  fun tabulate001 () =
      let
        val case_0_0 as () = test A.RowMajor (0, 0) []
        val case_0_1 as () = test A.RowMajor (0, 1) []
        val case_1_0 as () = test A.RowMajor (1, 0) []
        val case_1_1 as () = test A.RowMajor (1, 1) [(0, 0)]
        val case_2_1 as () = test A.RowMajor (2, 1) [(0, 0), (1, 0)]
        val case_1_2 as () = test A.RowMajor (1, 2) [(0, 0), (0, 1)]
        val case_2_2 as () = test A.RowMajor (2, 2) [(0, 0), (0, 1), (1, 0), (1, 1)]
        val case_3_3 as () = test A.RowMajor (3, 3) [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2), (2, 0), (2, 1), (2, 2)]
      in () end
  fun tabulate002 () =
      let
        val case_0_0 as () = test A.ColMajor (0, 0) []
        val case_0_1 as () = test A.ColMajor (0, 1) []
        val case_1_0 as () = test A.ColMajor (1, 0) []
        val case_1_1 as () = test A.ColMajor (1, 1) [(0, 0)]
        val case_2_1 as () = test A.ColMajor (2, 1) [(0, 0), (1, 0)]
        val case_1_2 as () = test A.ColMajor (1, 2) [(0, 0), (0, 1)]
        val case_2_2 as () = test A.ColMajor (2, 2) [(0, 0), (1, 0), (0, 1), (1, 1)]
        val case_3_3 as () = test A.ColMajor (3, 3) [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)]
      in () end
  fun tabulate101 () =
      let
        val case_R_1_n1 as () = testSize A.RowMajor (1, ~1)
        val case_C_1_n1 as () = testSize A.ColMajor (1, ~1)
        val case_R_n1_1 as () = testSize A.RowMajor (~1, 1)
        val case_C_n1_1 as () = testSize A.ColMajor (~1, 1)
        val case_R_n1_n1 as () = testSize A.RowMajor (~1, ~1)
        val case_C_n1_n1 as () = testSize A.ColMajor (~1, ~1)
      in () end
  end (* local *)

  (********************)

  local
    fun testSubscript (nRows, nCols, iRow, iCol) =
        let val array = A.array (nRows, nCols, n0)
        in
          (A.sub (array, iRow, iCol); fail "expect Subscript")
          handle General.Subscript => ()
        end
  in
  (* We assume that sub is tested in other test cases. *)

  (* error case *)
  fun sub101 () =
      let
        val case_1_1_n1_0 = testSubscript (1, 1, ~1, 0)
        val case_1_1_0_n1 = testSubscript (1, 1, 0, ~1)
        val case_1_1_1_0 = testSubscript (1, 1, 1, 0)
        val case_1_1_0_1 = testSubscript (1, 1, 0, 1)
      in () end
  end (* local *)

  (********************)

  local
    fun test elements (iRow, iCol, newElem) expected =
        let
          val array = A.fromList elements
          val () = A.update (array, iRow, iCol, newElem)

          fun assertArray _ [] = ()
            | assertArray iR (row :: rows) =
              let
                fun assertRow _ [] = ()
                  | assertRow iC (elem :: elems) =
                    (
                      assertEqualElem elem (A.sub (array, iR, iC));
                      assertRow (iC + 1) elems
                    )
              in assertRow 0 row; assertArray (iR + 1) rows end
          val () = assertArray 0 expected
        in () end
    fun testFail elements (iRow, iCol, newElem) =
        let val array = A.fromList elements
        in
          (A.update (array, iRow, iCol, newElem); fail "expect Subscript")
          handle General.Subscript => ()
        end
  in
  fun update001 () =
      let
        val case_1_1_0_0 as () = test [[n0]] (0, 0, n1) [[n1]]
        val case_1_1_0_1 as () = testFail [[n0]] (0, 1, n1)
        val case_1_1_1_0 as () = testFail [[n0]] (1, 0, n1)
        val case_1_2_0_0 as () = test [[n0, n1]] (0, 0, n2) [[n2, n1]]
        val case_1_2_0_1 as () = test [[n0, n1]] (0, 1, n2) [[n0, n2]]
        val case_1_2_0_2 as () = testFail [[n0, n1]] (0, 2, n2)
        val case_1_2_1_0 as () = testFail [[n0, n1]] (1, 0, n2)
        val case_2_1_0_0 as () = test [[n0], [n1]] (0, 0, n2) [[n2], [n1]]
        val case_2_1_0_1 as () = testFail [[n0], [n1]] (0, 1, n2)
        val case_2_1_1_0 as () = test [[n0], [n1]] (1, 0, n2) [[n0], [n2]]
        val case_2_1_1_1 as () = testFail [[n0], [n1]] (1, 1, n2)
        val case_2_2_0_0 as () = test [[n0, n1], [n2, n3]] (0, 0, n4) [[n4, n1], [n2, n3]]
        val case_2_2_0_1 as () = test [[n0, n1], [n2, n3]] (0, 1, n4) [[n0, n4], [n2, n3]]
        val case_2_2_1_0 as () = test [[n0, n1], [n2, n3]] (1, 0, n4) [[n0, n1], [n4, n3]]
        val case_2_2_1_1 as () = test [[n0, n1], [n2, n3]] (1, 1, n4) [[n0, n1], [n2, n4]]
        val case_2_2_1_2 as () = testFail [[n0, n1], [n2, n3]] (1, 2, n4)
        val case_2_2_2_1 as () = testFail [[n0, n1], [n2, n3]] (2, 1, n4)
      in () end
  end (* local *)

  (********************)

  (* We assume that dimensions, nCols and nRows are tested in other test cases.
   *)

  (********************)

  local
    fun test elements iRow expected =
        let
          val array = A.fromList elements
          val row = A.row (array, iRow)
        in assertEqualElemList expected (V2L row) end
    fun testFail elements iRow =
        let val array = A.fromList elements
        in
          (A.row (array, iRow); fail "expect Subscript.")
          handle General.Subscript => ()
        end
  in
  fun row001 () =
      let
        val case_1_1_n1 as () = testFail [[n0]] ~1
        val case_1_1_0 as () = test [[n0]] 0 [n0]
        val case_1_1_1 as () = testFail [[n0]] 1
        val case_1_2_0 as () = test [[n0, n1]] 0 [n0, n1]
        val case_1_2_1 as () = testFail [[n0, n1]] 1
        val case_2_1_0 as () = test [[n0], [n1]] 0 [n0]
        val case_2_1_1 as () = test [[n0], [n1]] 1 [n1]
        val case_2_2_0 as () = test [[n0, n1], [n2, n3]] 0 [n0, n1]
        val case_2_2_1 as () = test [[n0, n1], [n2, n3]] 1 [n2, n3]
      in () end
  end (* local *)

  (********************)

  local
    fun test elements iCol expected =
        let
          val array = A.fromList elements
          val col = A.column (array, iCol)
        in assertEqualElemList expected (V2L col) end
    fun testFail elements iCol =
        let val array = A.fromList elements
        in
          (A.column (array, iCol); fail "expect Subscript.")
          handle General.Subscript => ()
        end
  in
  fun col001 () =
      let
        val case_1_1_n1 as () = testFail [[n0]] ~1
        val case_1_1_0 as () = test [[n0]] 0 [n0]
        val case_1_1_1 as () = testFail [[n0]] 1
        val case_1_2_0 as () = test [[n0, n1]] 0 [n0]
        val case_1_2_1 as () = test [[n0, n1]] 1 [n1]
        val case_2_1_0 as () = test [[n0], [n1]] 0 [n0, n1]
        val case_2_1_1 as () = testFail [[n0], [n1]] 1
        val case_2_2_0 as () = test [[n0, n1], [n2, n3]] 0 [n0, n2]
        val case_2_2_1 as () = test [[n0, n1], [n2, n3]] 1 [n1, n3]
      in () end
  end (* local *)

  (********************)

  local
    fun test
            ((elems, row, col, nrows, ncols), dst, dst_row, dst_col) expected =
        let
          val src = A.fromList elems
          val dst = A.fromList dst
          val region = makeRegion (src, row, col, nrows, ncols)
          val () =
              A.copy
                {src = region, dst = dst, dst_row = dst_row, dst_col = dst_col}
          val () = assertEqualElemListList expected (toList dst)
        in () end
    fun testFail ((elems, row, col, nrows, ncols), dst, dst_row, dst_col) =
        let
          val src = A.fromList elems
          val dst = A.fromList dst
          val region = makeRegion (src, row, col, nrows, ncols)
        in
          (
            A.copy
              {src = region, dst = dst, dst_row = dst_row, dst_col = dst_col};
            fail "expect Subscript"
          )
          handle General.Subscript => ()
        end
  in
  (* test case where src and dst are not same array. *)
  (* variation in dst *)
  fun copy001 () =
      let
        val case_1_1_0_0_N_N_1_1_0_0 as () =
            test (([[n0]], 0, 0, NONE, NONE), [[n1]], 0, 0) [[n0]]
        val case_1_1_0_0_N_N_2_2_0_0 as () =
            test (([[n0]], 0, 0, NONE, NONE), [[n1, n2], [n3, n4]], 0, 0) [[n0, n2], [n3, n4]]
        val case_1_1_0_0_N_N_2_2_0_1 as () =
            test (([[n0]], 0, 0, NONE, NONE), [[n1, n2], [n3, n4]], 0, 1) [[n1, n0], [n3, n4]]
        val case_1_1_0_0_N_N_2_2_1_0 as () =
            test (([[n0]], 0, 0, NONE, NONE), [[n1, n2], [n3, n4]], 1, 0) [[n1, n2], [n0, n4]]
        val case_1_1_0_0_N_N_2_2_1_1 as () =
            test (([[n0]], 0, 0, NONE, NONE), [[n1, n2], [n3, n4]], 1, 1) [[n1, n2], [n3, n0]]
      in () end
  (* variation in dst *)
  fun copy002 () =
      let
        val src = [[n0, n1], [n2, n3]]
        val dst = [[n4, n5, n6], [n7, n8, n9], [n10, n11, n12]]
        val case_2_2_0_0_N_N_3_3_0_0 as () =
            test ((src, 0, 0, NONE, NONE), dst, 0, 0) [[n0, n1, n6], [n2, n3, n9], [n10, n11, n12]]
        val case_2_2_0_0_N_N_3_3_1_1 as () =
            test ((src, 0, 0, NONE, NONE), dst, 1, 1) [[n4, n5, n6], [n7, n0, n1], [n10, n2, n3]]
        val case_2_2_0_0_N_N_3_3_1_2 as () =
            testFail ((src, 0, 0, NONE, NONE), dst, 1, 2)
        val case_2_2_0_0_N_N_3_3_2_1 as () =
            testFail ((src, 0, 0, NONE, NONE), dst, 2, 1)
      in () end
  (* variation in row and col of src *)
  fun copy003 () =
      let
        val src = [[n0, n1, n2], [n3, n4, n5], [n6, n7, n8]]
        val dst = [[n9, n10], [n11, n12]]
        val case_3_3_0_0_N_N_2_2_0_0 as () =
            testFail ((src, 0, 0, NONE, NONE), dst, 0, 0)
        val case_3_3_0_1_N_N_2_2_0_0 as () =
            testFail ((src, 0, 1, NONE, NONE), dst, 0, 0)
        val case_3_3_1_0_N_N_2_2_0_0 as () =
            testFail ((src, 1, 0, NONE, NONE), dst, 0, 0)
        val case_3_3_1_1_N_N_2_2_0_0 as () =
            test ((src, 1, 1, NONE, NONE), dst, 0, 0) [[n4, n5], [n7, n8]]
        val case_3_3_1_2_N_N_2_2_0_0 as () =
            test ((src, 1, 2, NONE, NONE), dst, 0, 0) [[n5, n10], [n8, n12]]
        val case_3_3_2_1_N_N_2_2_0_0 as () =
            test ((src, 2, 1, NONE, NONE), dst, 0, 0) [[n7, n8], [n11, n12]]
        val case_3_3_2_2_N_N_2_2_0_0 as () =
            test ((src, 2, 2, NONE, NONE), dst, 0, 0) [[n8, n10], [n11, n12]]
        val case_3_3_2_3_N_N_2_2_0_0 as () =
            test ((src, 2, 3, NONE, NONE), dst, 0, 0) dst (* empty region *)
        val case_3_3_3_2_N_N_2_2_0_0 as () =
            test ((src, 3, 2, NONE, NONE), dst, 0, 0) dst (* empty region *)
        val case_3_3_3_3_N_N_2_2_0_0 as () =
            test ((src, 3, 3, NONE, NONE), dst, 0, 0) dst (* empty region *)
      in () end
  (* variation in nrows and ncols of src *)
  fun copy004 () =
      let
        val src = [[n0, n1, n2], [n3, n4, n5], [n6, n7, n8]]
        val dst = [[n9, n10], [n11, n12]]
        val case_3_3_1_1_S0_S0_2_2_0_0 as () =
            test ((src, 1, 1, SOME 0, SOME 0), dst, 0, 0) dst
        val case_3_3_1_1_S0_S1_2_2_0_0 as () =
            test ((src, 1, 1, SOME 0, SOME 1), dst, 0, 0) dst
        val case_3_3_1_1_S1_S0_2_2_0_0 as () =
            test ((src, 1, 1, SOME 1, SOME 0), dst, 0, 0) dst
        val case_3_3_1_1_S1_S1_2_2_0_0 as () =
            test ((src, 1, 1, SOME 1, SOME 1), dst, 0, 0) [[n4, n10], [n11, n12]]
        val case_3_3_1_1_S1_S2_2_2_0_0 as () =
            test ((src, 1, 1, SOME 1, SOME 2), dst, 0, 0) [[n4, n5], [n11, n12]]
        val case_3_3_1_1_S2_S1_2_2_0_0 as () =
            test ((src, 1, 1, SOME 2, SOME 1), dst, 0, 0) [[n4, n10], [n7, n12]]
        val case_3_3_1_1_S2_S2_2_2_0_0 as () =
            test ((src, 1, 1, SOME 2, SOME 2), dst, 0, 0) [[n4, n5], [n7, n8]]
        val case_3_3_1_1_S2_S3_2_2_0_0 as () =
            testFail ((src, 1, 1, SOME 2, SOME 3), dst, 0, 0)
        val case_3_3_1_1_S3_S2_2_2_0_0 as () =
            testFail ((src, 1, 1, SOME 3, SOME 2), dst, 0, 0)
      in () end
  (* test case where src array and dst array are the same array. *)
  fun copy005 () =
      let
        val src = [[n0, n1, n2], [n3, n4, n5], [n6, n7, n8]]
        val dst = src
        (* src_row < dst_row, src_col < dst_col *)
        val case_lt_lt as () =
            test ((src, 0, 0, SOME 2, SOME 2), dst, 1, 1) [[n0, n1, n2], [n3, n0, n1], [n6, n3, n4]]
        (* src_row < dst_row, src_col = dst_col *)
        val case_lt_eq as () =
            test ((src, 0, 0, SOME 2, SOME 2), dst, 1, 0) [[n0, n1, n2], [n0, n1, n5], [n3, n4, n8]]
        (* src_row < dst_row, src_col > dst_col *)
        val case_lt_gt as () =
            test ((src, 0, 1, SOME 2, SOME 2), dst, 1, 0) [[n0, n1, n2], [n1, n2, n5], [n4, n5, n8]]
        (* src_row = dst_row, src_col < dst_col *)
        val case_eq_lt as () =
            test ((src, 0, 0, SOME 2, SOME 2), dst, 0, 1) [[n0, n0, n1], [n3, n3, n4], [n6, n7, n8]]
        (* src_row = dst_row, src_col = dst_col *)
        val case_eq_eq as () =
            test ((src, 0, 0, SOME 2, SOME 2), dst, 0, 0) src
        (* src_row = dst_row, src_col > dst_col *)
        val case_eq_gt as () =
            test ((src, 0, 1, SOME 2, SOME 2), dst, 0, 0) [[n1, n2, n2], [n4, n5, n5], [n6, n7, n8]]
        (* src_row > dst_row, src_col < dst_col *)
        val case_gt_lt as () =
            test ((src, 1, 0, SOME 2, SOME 2), dst, 0, 1) [[n0, n3, n4], [n3, n6, n7], [n6, n7, n8]]
        (* src_row > dst_row, src_col = dst_col *)
        val case_gt_eq as () =
            test ((src, 1, 0, SOME 2, SOME 2), dst, 0, 0) [[n3, n4, n2], [n6, n7, n5], [n6, n7, n8]]
        (* src_row > dst_row, src_col > dst_col *)
        val case_gt_gt as () =
            test ((src, 1, 1, SOME 2, SOME 2), dst, 0, 0) [[n4, n5, n2], [n7, n8, n5], [n6, n7, n8]]
      in () end

  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val s = ref []
          fun f (row, col, elem) = (s := (!s) @ [(row, col, elem)])
        in (s, f) end
    fun test order (elems, row, col, nrows, ncols) visited =
        let
          val (state, appiFun) = makeState ()
          val array = A.fromList elems
          val region = makeRegion (array, row, col, nrows, ncols)
          val () = A.appi order appiFun region
          val () = assertEqualInt2ElemList visited (!state)
        in () end
    fun testFail order (elems, row, col, nrows, ncols) =
        let
          val (state, appiFun) = makeState ()
          val array = A.fromList elems
          val region = makeRegion (array, row, col, nrows, ncols)
        in
          (A.appi order appiFun region; fail "expect Subscript")
          handle General.Subscript => ()
        end
    val src = [[n0, n1, n2], [n3, n4, n5], [n6, n7, n8]]
  in
  fun appi001 () =
      let
        val test = test A.RowMajor
        val case_R_0_0_N_N as () =
            test (src, 0, 0, NONE, NONE) [(0, 0, n0), (0, 1, n1), (0, 2, n2), (1, 0, n3), (1, 1, n4), (1, 2, n5), (2, 0, n6), (2, 1, n7), (2, 2, n8)]
        val case_R_1_1_N_N as () =
            test (src, 1, 1, NONE, NONE) [(1, 1, n4), (1, 2, n5), (2, 1, n7), (2, 2, n8)]
        val case_R_1_2_N_N as () =
            test (src, 1, 2, NONE, NONE) [(1, 2, n5), (2, 2, n8)]
        val case_R_2_1_N_N as () =
            test (src, 2, 1, NONE, NONE) [(2, 1, n7), (2, 2, n8)]
        val case_R_3_3_N_N as () =
            test (src, 3, 3, NONE, NONE) []
        val case_R_1_1_S1_S1 as () =
            test (src, 1, 1, SOME 1, SOME 1) [(1, 1, n4)]
        val case_R_1_1_S1_S2 as () =
            test (src, 1, 1, SOME 1, SOME 2) [(1, 1, n4), (1, 2, n5)]
        val case_R_1_1_S2_S1 as () =
            test (src, 1, 1, SOME 2, SOME 1) [(1, 1, n4), (2, 1, n7)]
        val case_R_1_1_S2_S2 as () =
            test (src, 1, 1, SOME 2, SOME 2) [(1, 1, n4), (1, 2, n5), (2, 1, n7), (2, 2, n8)]
      in () end
  fun appi002 () =
      let
        val test = test A.ColMajor
        val case_R_0_0_N_N as () =
            test (src, 0, 0, NONE, NONE) [(0, 0, n0), (1, 0, n3), (2, 0, n6), (0, 1, n1), (1, 1, n4), (2, 1, n7), (0, 2, n2), (1, 2, n5), (2, 2, n8)]
        val case_R_1_1_N_N as () =
            test (src, 1, 1, NONE, NONE) [(1, 1, n4), (2, 1, n7), (1, 2, n5), (2, 2, n8)]
        val case_R_1_2_N_N as () =
            test (src, 1, 2, NONE, NONE) [(1, 2, n5), (2, 2, n8)]
        val case_R_2_1_N_N as () =
            test (src, 2, 1, NONE, NONE) [(2, 1, n7), (2, 2, n8)]
        val case_R_3_3_N_N as () =
            test (src, 3, 3, NONE, NONE) []
        val case_R_1_1_S1_S1 as () =
            test (src, 1, 1, SOME 1, SOME 1) [(1, 1, n4)]
        val case_R_1_1_S1_S2 as () =
            test (src, 1, 1, SOME 1, SOME 2) [(1, 1, n4), (1, 2, n5)]
        val case_R_1_1_S2_S1 as () =
            test (src, 1, 1, SOME 2, SOME 1) [(1, 1, n4), (2, 1, n7)]
        val case_R_1_1_S2_S2 as () =
            test (src, 1, 1, SOME 2, SOME 2) [(1, 1, n4), (2, 1, n7), (1, 2, n5), (2, 2, n8)]
      in () end
  fun appi101 () =
      let
        val testFail = testFail A.RowMajor
        (* invalid col *)
        val case_R_0_4_N_N as () = testFail (src, 0, 4, NONE, NONE)
        (* invalid row *)
        val case_R_4_0_N_N as () = testFail (src, 4, 0, NONE, NONE)
        (* invalid ncol *)
        val case_R_0_0_N_S4 as () = testFail (src, 0, 0, NONE, SOME 4)
        (* invalid nrow *)
        val case_R_0_0_S4_N as () = testFail (src, 0, 0, SOME 4, NONE)
      in () end
  fun appi102 () =
      let
        val testFail = testFail A.ColMajor
        (* invalid col *)
        val case_R_0_4_N_N as () = testFail (src, 0, 4, NONE, NONE)
        (* invalid row *)
        val case_R_4_0_N_N as () = testFail (src, 4, 0, NONE, NONE)
        (* invalid ncol *)
        val case_R_0_0_N_S4 as () = testFail (src, 0, 0, NONE, SOME 4)
        (* invalid nrow *)
        val case_R_0_0_S4_N as () = testFail (src, 0, 0, SOME 4, NONE)
      in () end
  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val s = ref []
          fun f elem = (s := (!s) @ [elem])
        in (s, f) end
    fun test order elems visited =
        let
          val (state, appFun) = makeState ()
          val array = A.fromList elems
          val () = A.app order appFun array
          val () = assertEqualElemList visited (!state)
        in () end
  in
  fun app001 () =
      let
        val test = test A.RowMajor
        val case_R_0_0 as () = test [] []
        val case_R_3_3 as () =
            test [[n0, n1, n2], [n3, n4, n5], [n6, n7, n8]] [n0, n1, n2, n3, n4, n5, n6, n7, n8]
      in () end
  fun app002 () =
      let
        val test = test A.ColMajor
        val case_R_0_0 as () = test [] []
        val case_R_3_3 as () =
            test [[n0, n1, n2], [n3, n4, n5], [n6, n7, n8]] [n0, n3, n6, n1, n4, n7, n2, n5, n8]
      in () end
  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val s = ref []
          fun f (row, col, elem, accum) =
              (s := (!s) @ [(row, col, elem)]; accum @ [elem])
        in (s, f) end
    fun test order (elems, row, col, nrows, ncols) expected visited =
        let
          val (state, foldiFun) = makeState ()
          val array = A.fromList elems
          val region = makeRegion (array, row, col, nrows, ncols)
          val result = A.foldi order foldiFun [] region
          val () = assertEqualInt2ElemList visited (!state)
          val () = assertEqualElemList expected result
        in () end
    fun testFail order (elems, row, col, nrows, ncols) =
        let
          val (state, foldiFun) = makeState ()
          val array = A.fromList elems
          val region = makeRegion (array, row, col, nrows, ncols)
        in
          (A.foldi order foldiFun [] region; fail "expect Subscript")
          handle General.Subscript => ()
        end
    val src = [[n0, n1, n2], [n3, n4, n5], [n6, n7, n8]]
  in
  fun foldi001 () =
      let
        val test = test A.RowMajor
        val case_R_0_0_N_N as () =
            test (src, 0, 0, NONE, NONE) [n0, n1, n2, n3, n4, n5, n6, n7, n8] [(0, 0, n0), (0, 1, n1), (0, 2, n2), (1, 0, n3), (1, 1, n4), (1, 2, n5), (2, 0, n6), (2, 1, n7), (2, 2, n8)]
        val case_R_1_1_N_N as () =
            test (src, 1, 1, NONE, NONE) [n4, n5, n7, n8] [(1, 1, n4), (1, 2, n5), (2, 1, n7), (2, 2, n8)]
        val case_R_1_2_N_N as () =
            test (src, 1, 2, NONE, NONE) [n5, n8] [(1, 2, n5), (2, 2, n8)]
        val case_R_2_1_N_N as () =
            test (src, 2, 1, NONE, NONE) [n7, n8] [(2, 1, n7), (2, 2, n8)]
        val case_R_3_3_N_N as () =
            test (src, 3, 3, NONE, NONE) [] []
        val case_R_1_1_S1_S1 as () =
            test (src, 1, 1, SOME 1, SOME 1) [n4] [(1, 1, n4)]
        val case_R_1_1_S1_S2 as () =
            test (src, 1, 1, SOME 1, SOME 2) [n4, n5] [(1, 1, n4), (1, 2, n5)]
        val case_R_1_1_S2_S1 as () =
            test (src, 1, 1, SOME 2, SOME 1) [n4, n7] [(1, 1, n4), (2, 1, n7)]
        val case_R_1_1_S2_S2 as () =
            test (src, 1, 1, SOME 2, SOME 2) [n4, n5, n7, n8] [(1, 1, n4), (1, 2, n5), (2, 1, n7), (2, 2, n8)]
      in () end
  fun foldi002 () =
      let
        val test = test A.ColMajor
        val case_R_0_0_N_N as () =
            test (src, 0, 0, NONE, NONE) [n0, n3, n6, n1, n4, n7, n2, n5, n8] [(0, 0, n0), (1, 0, n3), (2, 0, n6), (0, 1, n1), (1, 1, n4), (2, 1, n7), (0, 2, n2), (1, 2, n5), (2, 2, n8)]
        val case_R_1_1_N_N as () =
            test (src, 1, 1, NONE, NONE) [n4, n7, n5, n8] [(1, 1, n4), (2, 1, n7), (1, 2, n5), (2, 2, n8)]
        val case_R_1_2_N_N as () =
            test (src, 1, 2, NONE, NONE) [n5, n8] [(1, 2, n5), (2, 2, n8)]
        val case_R_2_1_N_N as () =
            test (src, 2, 1, NONE, NONE) [n7, n8] [(2, 1, n7), (2, 2, n8)]
        val case_R_3_3_N_N as () =
            test (src, 3, 3, NONE, NONE) [] []
        val case_R_1_1_S1_S1 as () =
            test (src, 1, 1, SOME 1, SOME 1) [n4] [(1, 1, n4)]
        val case_R_1_1_S1_S2 as () =
            test (src, 1, 1, SOME 1, SOME 2) [n4, n5] [(1, 1, n4), (1, 2, n5)]
        val case_R_1_1_S2_S1 as () =
            test (src, 1, 1, SOME 2, SOME 1) [n4, n7] [(1, 1, n4), (2, 1, n7)]
        val case_R_1_1_S2_S2 as () =
            test (src, 1, 1, SOME 2, SOME 2) [n4, n7, n5, n8] [(1, 1, n4), (2, 1, n7), (1, 2, n5), (2, 2, n8)]
      in () end
  fun foldi101 () =
      let
        val testFail = testFail A.RowMajor
        (* invalid col *)
        val case_R_0_4_N_N as () = testFail (src, 0, 4, NONE, NONE)
        (* invalid row *)
        val case_R_4_0_N_N as () = testFail (src, 4, 0, NONE, NONE)
        (* invalid ncol *)
        val case_R_0_0_N_S4 as () = testFail (src, 0, 0, NONE, SOME 4)
        (* invalid nrow *)
        val case_R_0_0_S4_N as () = testFail (src, 0, 0, SOME 4, NONE)
      in () end
  fun foldi102 () =
      let
        val testFail = testFail A.ColMajor
        (* invalid col *)
        val case_R_0_4_N_N as () = testFail (src, 0, 4, NONE, NONE)
        (* invalid row *)
        val case_R_4_0_N_N as () = testFail (src, 4, 0, NONE, NONE)
        (* invalid ncol *)
        val case_R_0_0_N_S4 as () = testFail (src, 0, 0, NONE, SOME 4)
        (* invalid nrow *)
        val case_R_0_0_S4_N as () = testFail (src, 0, 0, SOME 4, NONE)
      in () end
  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val s = ref []
          fun f (elem, accum) = (s := (!s) @ [elem]; accum @ [elem])
        in (s, f) end
    fun test order elems expected visited =
        let
          val (state, foldFun) = makeState ()
          val array = A.fromList elems
          val result = A.fold order foldFun [] array
          val () = assertEqualElemList visited (!state)
          val () = assertEqualElemList expected result
        in () end
  in
  fun fold001 () =
      let
        val test = test A.RowMajor
        val case_R_0_0 as () = test [] [] []
        val case_R_3_3 as () =
            test [[n0, n1, n2], [n3, n4, n5], [n6, n7, n8]] [n0, n1, n2, n3, n4, n5, n6, n7, n8] [n0, n1, n2, n3, n4, n5, n6, n7, n8]
      in () end
  fun fold002 () =
      let
        val test = test A.ColMajor
        val case_R_0_0 as () = test [] [] []
        val case_R_3_3 as () =
            test [[n0, n1, n2], [n3, n4, n5], [n6, n7, n8]] [n0, n3, n6, n1, n4, n7, n2, n5, n8] [n0, n3, n6, n1, n4, n7, n2, n5, n8]
      in () end
  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val s = ref []
          fun f (row, col, elem) =
              (s := (!s) @ [(row, col, elem)]; A.nextElem elem)
        in (s, f) end
    fun test order (elems, row, col, nrows, ncols) expected visited =
        let
          val (state, modifyiFun) = makeState ()
          val array = A.fromList elems
          val region = makeRegion (array, row, col, nrows, ncols)
          val () = A.modifyi order modifyiFun region
          val () = assertEqualInt2ElemList visited (!state)
          val () = assertEqualElemListList expected (toList array)
        in () end
    fun testFail order (elems, row, col, nrows, ncols) =
        let
          val (state, modifyiFun) = makeState ()
          val array = A.fromList elems
          val region = makeRegion (array, row, col, nrows, ncols)
        in
          (A.modifyi order modifyiFun region; fail "expect Subscript")
          handle General.Subscript => ()
        end
    val src = [[n0, n1, n2], [n3, n4, n5], [n6, n7, n8]]
  in
  fun modifyi001 () =
      let
        val test = test A.RowMajor
        val case_R_0_0_N_N as () =
            test (src, 0, 0, NONE, NONE) [[n1, n2, n3], [n4, n5, n6], [n7, n8, n9]] [(0, 0, n0), (0, 1, n1), (0, 2, n2), (1, 0, n3), (1, 1, n4), (1, 2, n5), (2, 0, n6), (2, 1, n7), (2, 2, n8)]
        val case_R_1_1_N_N as () =
            test (src, 1, 1, NONE, NONE) [[n0, n1, n2], [n3, n5, n6], [n6, n8, n9]] [(1, 1, n4), (1, 2, n5), (2, 1, n7), (2, 2, n8)]
        val case_R_1_2_N_N as () =
            test (src, 1, 2, NONE, NONE) [[n0, n1, n2], [n3, n4, n6], [n6, n7, n9]] [(1, 2, n5), (2, 2, n8)]
        val case_R_2_1_N_N as () =
            test (src, 2, 1, NONE, NONE) [[n0, n1, n2], [n3, n4, n5], [n6, n8, n9]] [(2, 1, n7), (2, 2, n8)]
        val case_R_3_3_N_N as () =
            test (src, 3, 3, NONE, NONE) src []
        val case_R_1_1_S1_S1 as () =
            test (src, 1, 1, SOME 1, SOME 1) [[n0, n1, n2], [n3, n5, n5], [n6, n7, n8]] [(1, 1, n4)]
        val case_R_1_1_S1_S2 as () =
            test (src, 1, 1, SOME 1, SOME 2) [[n0, n1, n2], [n3, n5, n6], [n6, n7, n8]] [(1, 1, n4), (1, 2, n5)]
        val case_R_1_1_S2_S1 as () =
            test (src, 1, 1, SOME 2, SOME 1) [[n0, n1, n2], [n3, n5, n5], [n6, n8, n8]] [(1, 1, n4), (2, 1, n7)]
        val case_R_1_1_S2_S2 as () =
            test (src, 1, 1, SOME 2, SOME 2) [[n0, n1, n2], [n3, n5, n6], [n6, n8, n9]] [(1, 1, n4), (1, 2, n5), (2, 1, n7), (2, 2, n8)]
      in () end
  fun modifyi002 () =
      let
        val test = test A.ColMajor
        val case_R_0_0_N_N as () =
            test (src, 0, 0, NONE, NONE) [[n1, n2, n3], [n4, n5, n6], [n7, n8, n9]] [(0, 0, n0), (1, 0, n3), (2, 0, n6), (0, 1, n1), (1, 1, n4), (2, 1, n7), (0, 2, n2), (1, 2, n5), (2, 2, n8)]
        val case_R_1_1_N_N as () =
            test (src, 1, 1, NONE, NONE) [[n0, n1, n2], [n3, n5, n6], [n6, n8, n9]] [(1, 1, n4), (2, 1, n7), (1, 2, n5), (2, 2, n8)]
        val case_R_1_2_N_N as () =
            test (src, 1, 2, NONE, NONE) [[n0, n1, n2], [n3, n4, n6], [n6, n7, n9]] [(1, 2, n5), (2, 2, n8)]
        val case_R_2_1_N_N as () =
            test (src, 2, 1, NONE, NONE) [[n0, n1, n2], [n3, n4, n5], [n6, n8, n9]] [(2, 1, n7), (2, 2, n8)]
        val case_R_3_3_N_N as () =
            test (src, 3, 3, NONE, NONE) src []
        val case_R_1_1_S1_S1 as () =
            test (src, 1, 1, SOME 1, SOME 1) [[n0, n1, n2], [n3, n5, n5], [n6, n7, n8]] [(1, 1, n4)]
        val case_R_1_1_S1_S2 as () =
            test (src, 1, 1, SOME 1, SOME 2) [[n0, n1, n2], [n3, n5, n6], [n6, n7, n8]] [(1, 1, n4), (1, 2, n5)]
        val case_R_1_1_S2_S1 as () =
            test (src, 1, 1, SOME 2, SOME 1) [[n0, n1, n2], [n3, n5, n5], [n6, n8, n8]] [(1, 1, n4), (2, 1, n7)]
        val case_R_1_1_S2_S2 as () =
            test (src, 1, 1, SOME 2, SOME 2) [[n0, n1, n2], [n3, n5, n6], [n6, n8, n9]] [(1, 1, n4), (2, 1, n7), (1, 2, n5), (2, 2, n8)]
      in () end
  fun modifyi101 () =
      let
        val testFail = testFail A.RowMajor
        (* invalid col *)
        val case_R_0_4_N_N as () = testFail (src, 0, 4, NONE, NONE)
        (* invalid row *)
        val case_R_4_0_N_N as () = testFail (src, 4, 0, NONE, NONE)
        (* invalid ncol *)
        val case_R_0_0_N_S4 as () = testFail (src, 0, 0, NONE, SOME 4)
        (* invalid nrow *)
        val case_R_0_0_S4_N as () = testFail (src, 0, 0, SOME 4, NONE)
      in () end
  fun modifyi102 () =
      let
        val testFail = testFail A.ColMajor
        (* invalid col *)
        val case_R_0_4_N_N as () = testFail (src, 0, 4, NONE, NONE)
        (* invalid row *)
        val case_R_4_0_N_N as () = testFail (src, 4, 0, NONE, NONE)
        (* invalid ncol *)
        val case_R_0_0_N_S4 as () = testFail (src, 0, 0, NONE, SOME 4)
        (* invalid nrow *)
        val case_R_0_0_S4_N as () = testFail (src, 0, 0, SOME 4, NONE)
      in () end
  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val s = ref []
          fun f elem = (s := (!s) @ [elem]; A.nextElem elem)
        in (s, f) end
    fun test order elems expected visited =
        let
          val (state, modifyFun) = makeState ()
          val array = A.fromList elems
          val () = A.modify order modifyFun array
          val () = assertEqualElemList visited (!state)
          val () = assertEqualElemListList expected (toList array)
        in () end
  in
  fun modify001 () =
      let
        val test = test A.RowMajor
        val case_R_0_0 as () = test [] [] []
        val case_R_3_3 as () =
            test [[n0, n1, n2], [n3, n4, n5], [n6, n7, n8]] [[n1, n2, n3], [n4, n5, n6], [n7, n8, n9]] [n0, n1, n2, n3, n4, n5, n6, n7, n8]
      in () end
  fun modify002 () =
      let
        val test = test A.ColMajor
        val case_R_0_0 as () = test [] [] []
        val case_R_3_3 as () =
            test [[n0, n1, n2], [n3, n4, n5], [n6, n7, n8]] [[n1, n2, n3], [n4, n5, n6], [n7, n8, n9]] [n0, n3, n6, n1, n4, n7, n2, n5, n8]
      in () end
  end (* local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("equality001", equality001),
        ("array001", array001),
        ("array101", array101),
        ("fromList001", fromList001),
        ("fromList101", fromList101),
        ("tabulate001", tabulate001),
        ("tabulate101", tabulate101),
        ("tabulate002", tabulate002),
        ("sub101", sub101),
        ("update001", update001),
        ("row001", row001),
        ("col001", col001),
        ("copy001", copy001),
        ("copy002", copy002),
        ("copy003", copy003),
        ("copy004", copy004),
        ("copy005", copy005),
        ("appi001", appi001),
        ("appi002", appi002),
        ("appi101", appi101),
        ("appi102", appi102),
        ("app001", app001),
        ("app002", app002),
        ("foldi001", foldi001),
        ("foldi002", foldi002),
        ("foldi101", foldi101),
        ("foldi102", foldi102),
        ("fold001", fold001),
        ("fold002", fold002),
        ("modifyi001", modifyi001),
        ("modifyi002", modifyi002),
        ("modifyi101", modifyi101),
        ("modifyi102", modifyi102),
        ("modify001", modify001),
        ("modify002", modify002)
      ]

  (************************************************************)

end
