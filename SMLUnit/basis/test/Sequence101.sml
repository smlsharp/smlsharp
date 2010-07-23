(**
 * test cases for sequence structures.
 * This module tests functions which both mutable and immutable structures
 * provide.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
functor Sequence101(S : SEQUENCE) =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  (************************************************************)

  val assertEqualElem = assertEqualByCompare S.compareElem S.elemToString
  val assertEqualElemList = assertEqualList assertEqualElem
  val assertEqualElemOption = assertEqualOption assertEqualElem
  val assertEqualIntElem = assertEqual2Tuple (assertEqualInt, assertEqualElem)
  val assertEqualIntElemList = assertEqualList assertEqualIntElem
  val assertEqualIntElemOption = assertEqualOption assertEqualIntElem
  val assertEqualElem2List =
      assertEqualList
          (assertEqual2Tuple (assertEqualElem, assertEqualElem))

  val [n0, n1, n2, n3, n9] = List.map S.intToElem [0, 1, 2, 3, 9]

  val L2S = S.fromList
  fun S2L sequence = S.foldr List.:: [] sequence

  (****************************************)

  local
    fun testi arg expected = assertEqualElemList expected (S2L(S.fromList arg))
  in
  fun fromList001 () =
      let
        val fromList_0i = testi [] []
        val fromList_1i = testi [n1] [n1]
        val fromList_2i = testi [n1, n2] [n1, n2]
      in
        ()
      end
  end (* local *)

  (********************)

  local
    fun tabulateFun x = S.intToElem x
    fun test arg expected =
        assertEqualElemList expected (S2L(S.tabulate(arg, tabulateFun)))
  in
  fun tabulate001 () =
      let
        val tabulate0 = test 0 []
        val tabulate1 = test 1 [n0]
        val tabulate2 = test 2 [n0, n1]
        val tabulatem1 =
            (S.tabulate (~1, tabulateFun); fail "tabulate")
            handle General.Size => ()
      in
        ()
      end
  end (* local *)

  (********************)

  fun length001 () =
      let
        val length1 = S.length (L2S[])
        val _ = assertEqualInt 0 length1
        val length2 = S.length (L2S[n1])
        val _ = assertEqualInt 1 length2
        val length3 = S.length (L2S[n1, n2])
        val _ = assertEqualInt 2 length3
      in
        ()
      end

  (********************)

  local
    fun test (arg1, arg2) expected =
        assertEqualElem expected (S.sub (L2S arg1, arg2))
    fun testError (arg1, arg2) =
        (S.sub (L2S arg1, arg2); fail "Array:sub")
        handle General.Subscript => ()
  in
  fun sub001 () =
      let
        val sub00 = testError ([], 0)
        val sub0m1 = testError ([], ~1)
        val sub01 = testError ([], 1)
        val sub10 = test ([n1], 0) n1
        val sub11 = testError ([n2], 1)
        val sub1m1 = testError ([n2], ~1)
        val sub20 = test ([n1, n2], 0) n1
        val sub21 = test ([n1, n2], 1) n2
        val sub22 = testError ([n1, n2], 2)
      in
        ()
      end        
  end (* local *)

  (********************)

  local
    fun makeStatei () =
        let
          val r = ref []
          fun f (index, n) = r := !r @ [(index, n)]
        in
          (r, f)
        end
    fun test arg visited =
        let
          val (s, f) = makeStatei ()
          val () = S.appi f (L2S arg)
          val _ = assertEqualIntElemList visited (!s)
        in
          ()
        end
  in
  fun appi001 () =
      let
        val appi_0 = test [] []
        val appi_1 = test [n1] [(0, n1)]
        val appi_2 = test [n1, n2] [(0, n1), (1, n2)]
      in
        ()
      end
  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f n = r := !r @ [n]
        in
          (r, f)
        end
    fun test arg visited =
        let
          val (s, f) = makeState ()
          val app0 = S.app f (L2S arg)
          val _ = assertEqualElemList visited (!s)
        in
          ()
        end
  in
  fun app001 () =
      let
        val app0 = test [] []
        val app1 = test [n1] [n1]
        val app2 = test [n1, n2] [n1, n2]
        val app3 = test [n1, n2, n3] [n1, n2, n3]
      in
        ()
      end
  end

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f (n, accum) = (r := !r @ [n]; n :: accum)
        in
          (r, f)
        end
    fun makeStatei () =
        let
          val r = ref []
          fun f (index, n, accum) = (r := !r @ [(index, n)]; n :: accum)
        in
          (r, f)
        end
    fun testi fold arg expected visited =
        let
          val (s, f) = makeStatei ()
          val r = fold f [] (L2S arg)
          val _ = assertEqualElemList expected r
          val _ = assertEqualIntElemList visited (!s)
        in
          ()
        end
    fun test fold arg expected visited =
        let
          val (s, f) = makeState ()
          val r = fold f [] (L2S arg)
          val _ = assertEqualElemList expected r
          val _ = assertEqualElemList visited (!s)
        in
          ()
        end
  in
  local
    val testi = testi S.foldli
    val test = test S.foldl
  in
  fun foldli001 () =
      let
        val foldli_0 = testi [] [] []
        val foldli_1 = testi [n1] [n1] [(0, n1)]
        (* The result is in reverse order. *)
        val foldli_2 = testi [n1, n2] [n2, n1] [(0, n1), (1, n2)]
      in
        ()
      end

  fun foldl001 () =
      let
        val foldl_0 = test [] [] []
        val foldl_1 = test [n1] [n1] [n1]
        (* The result is in reverse order *)
        val foldl_2 = test [n1, n2] [n2, n1] [n1, n2]
        val foldl_3 = test [n1, n2, n3] [n3, n2, n1] [n1, n2, n3]
      in
        ()
      end
  end (* inner local *)

  local
    val testi = testi S.foldri
    val test = test S.foldr
  in
  fun foldri001 () =
      let
        val foldri_0 = testi [] [] []
        val foldri_1 = testi [n1] [n1] [(0, n1)]
        (* result is in normal order. visited is in reverse order *)
        val foldri_2 = testi [n1, n2] [n1, n2] [(1, n2), (0, n1)]
      in
        ()
      end

  fun foldr001 () =
      let
        val foldr_0 = test [] [] []
        val foldr_1 = test [n1] [n1] [n1]
        (* result is in normal order. visited is in reverse order *)
        val foldr_2 = test [n1, n2]  [n1, n2] [n2, n1]
        val foldr3 = test [n1, n2, n3] [n1, n2, n3] [n3, n2, n1]
      in
        ()
      end
  end (* inner local *)

  end (* outer local *)

  (********************)

  local
    fun makeState x =
        let
          val r = ref []
          fun f n = (r := !r @ [n]; EQUAL = S.compareElem (x, n))
        in
          (r, f)
        end
    fun makeStatei x =
        let
          val r = ref []
          fun f (index, n) =
              (r := !r @ [(index, n)]; EQUAL = S.compareElem (x, n))
        in
          (r, f)
        end
  in

  local
    fun testi arg expected visited =
        let
          val (s, f) = makeStatei n9
          val r = S.findi f (L2S  arg)
          val _ = assertEqualIntElemOption expected r
          val _ = assertEqualIntElemList visited (!s)
        in
          ()
        end
    fun test arg expected visited =
        let
          val (s, f) = makeState n9
          val r = S.find f (L2S  arg)
          val _ = assertEqualElemOption expected r
          val _ = assertEqualElemList visited (!s)
        in
          ()
        end
  in
  fun findi001 () =
      let
        val findi_0 = testi [] NONE []
        val findi_1F = testi [n1] NONE [(0, n1)]
        val findi_1T = testi [n9] (SOME(0, n9)) [(0, n9)]
        val findi_2F = testi [n1, n2] NONE [(0, n1), (1, n2)]
        val findi_2T1 = testi [n1, n9] (SOME(1, n9)) [(0, n1), (1, n9)]
        val findi_2T2 = testi [n9, n1] (SOME(0, n9)) [(0, n9)]
        val findi_2T3 = testi [n9, n9] (SOME(0, n9)) [(0, n9)]
      in
        ()
      end

  fun find001 () =
      let
        val find_0 = test [] NONE []
        val find_1F = test [n1] NONE [n1]
        val find_1T = test [n9] (SOME n9) [n9]
        val find_2F = test [n1, n2] NONE [n1, n2]
        val find_2T1 = test [n1, n9] (SOME n9) [n1, n9]
        val find_2T2 = test [n9, n1] (SOME n9) [n9]
        val find_2T3 = test [n9, n9] (SOME n9) [n9]
      in
        ()
      end
  end (* inner local for find and findi *)

  (********************)

  local
    fun test scanner arg expected visited =
        let
          val (s, f) = makeState n9
          val r = scanner f (L2S arg)
          val _ = assertEqualBool expected r
          val _ = assertEqualElemList visited (!s)
        in
          ()
        end
  in

  local
    val test = test S.exists
  in
  fun exists001 () =
      let
        val exists_0 = test [] false []
        val exists_1F = test [n1] false [n1]
        val exists_1T = test [n9] true [n9]
        val exists_2F = test [n1, n2] false [n1, n2]
        val exists_2T1 = test [n1, n9] true [n1, n9]
        val exists_2T2 = test [n9, n1] true [n9]
        val exists_2T3 = test [n9, n9] true [n9]
      in
        ()
      end
  end (* inner local *)

  (********************)

  local
    val test = test S.all
  in
  fun all001 () =
      let
        val all_0 = test [] true [] (* true is returnd for nothing. *)
        val all_1F = test [n1] false [n1]
        val all_1T = test [n9] true [n9]
        val all_2F = test [n1, n2] false [n1] (* visit only first element. *)
        val all_2F2 = test [n1, n9] false [n1]
        val all_2F3 = test [n9, n1] false [n9, n1]
        val all_2T = test [n9, n9] true [n9, n9]
      in
        ()
      end

  end (* inner local *)

  end (* local for exists and all *)

  end (* outer local for find, findi, exists, all. *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f (x, y) = (r := !r @ [(x, y)]; S.compareElem (x, y))
        in
          (r, f)
        end
    fun test (arg1, arg2) expected visited =
        let
          val (s, f) = makeState ()
          val r = S.collate f (L2S arg1, L2S arg2)
          val _ = assertEqualOrder expected r
          val _ = assertEqualElem2List visited (!s)
        in
          ()
        end
  in
  fun collate001 () =
      let
        val collate00 = test ([], []) EQUAL []
        val collate01 = test ([], [n1]) LESS []
        val collate10 = test ([n1], [n0]) GREATER [(n1, n0)]
        val collate11L = test ([n1], [n2]) LESS [(n1, n2)]
        val collate11E = test ([n1], [n1]) EQUAL [(n1, n1)]
        val collate11G = test ([n2], [n1]) GREATER [(n2, n1)]
        val collate12L = test ([n1], [n1, n2]) LESS [(n1, n1)]
        val collate12G = test ([n2], [n1, n2]) GREATER [(n2, n1)]
        val collate21L = test ([n1, n2], [n2]) LESS [(n1, n2)]
        val collate21G = test ([n1, n2], [n1]) GREATER [(n1, n1)]
        val collate22L1 = test ([n2, n1], [n3, n1]) LESS [(n2, n3)]
        val collate22L2 = test ([n1, n2], [n1, n3]) LESS [(n1, n1), (n2, n3)]
        val collate22E = test ([n1, n2], [n1, n2]) EQUAL [(n1, n1), (n2, n2)]
        val collate22G1 = test ([n3, n1], [n2, n1]) GREATER [(n3, n2)]
        val collate22G2 = test ([n1, n3], [n1, n2]) GREATER [(n1, n1), (n3, n2)]
      in
        ()
      end
  end (* local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("fromList001", fromList001),
        ("tabulate001", tabulate001),
        ("length001", length001),
        ("sub001", sub001),
        ("appi001", appi001),
        ("app001", app001),
        ("foldli001", foldli001),
        ("foldl001", foldl001),
        ("foldri001", foldri001),
        ("foldr001", foldr001),
        ("findi001", findi001),
        ("find001", find001),
        ("exists001", exists001),
        ("all001", all001),
        ("collate001", collate001)
      ]

  (************************************************************)

end