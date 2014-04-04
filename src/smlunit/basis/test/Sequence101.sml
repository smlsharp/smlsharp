(**
 * test cases for sequence structures.
 * This module tests functions which both mutable and immutable structures
 * provide.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
functor Sequence101(S : SEQUENCE) : sig
  val suite : unit -> SMLUnit.Test.test
end =
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
        val case_0i as () = testi [] []
        val case_1i as () = testi [n1] [n1]
        val case_2i as () = testi [n1, n2] [n1, n2]
      in
        ()
      end
  (* ToDo : tests fromList with a list the length of which is greater than
   * S.maxLen. But SML/NJ aborts on creation of such a long list. *)

  end (* local *)

  (********************)

  local
    fun tabulateFun x = S.intToElem x
    fun test arg expected =
        assertEqualElemList expected (S2L(S.tabulate(arg, tabulateFun)))
  in
  fun tabulate001 () =
      let
        val case0 as () = test 0 []
        val case1 as () = test 1 [n0]
        val case2 as () = test 2 [n0, n1]
      in () end
  fun tabulate101 () =
      let
        val case_m1 as () =
            (S.tabulate (~1, tabulateFun); fail "tabulate(~1)")
            handle General.Size => ()
        val case_maxLenPlus1 as () =
            if isSome Int.maxInt andalso S.maxLen < valOf(Int.maxInt)
            then
              (
                S.tabulate (S.maxLen + 1, tabulateFun);
                fail "tabulate(maxLen+1)"
              )
              handle General.Size => ()
            else ()
      in () end
  end (* local *)

  (********************)

  fun length001 () =
      let
        val length1 = S.length (L2S[])
        val () = assertEqualInt 0 length1
        val length2 = S.length (L2S[n1])
        val () = assertEqualInt 1 length2
        val length3 = S.length (L2S[n1, n2])
        val () = assertEqualInt 2 length3
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
        val case00 as () = testError ([], 0)
        val case0m1 as () = testError ([], ~1)
        val case01 as () = testError ([], 1)
        val case10 as () = test ([n1], 0) n1
        val case11 as () = testError ([n2], 1)
        val case1m1 as () = testError ([n2], ~1)
        val case20 as () = test ([n1, n2], 0) n1
        val case21 as () = test ([n1, n2], 1) n2
        val case22 as () = testError ([n1, n2], 2)
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
          val () = assertEqualIntElemList visited (!s)
        in
          ()
        end
  in
  fun appi001 () =
      let
        val case_0 as () = test [] []
        val case_1 as () = test [n1] [(0, n1)]
        val case_2 as () = test [n1, n2] [(0, n1), (1, n2)]
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
          val () = assertEqualElemList visited (!s)
        in
          ()
        end
  in
  fun app001 () =
      let
        val case0 as () = test [] []
        val case1 as () = test [n1] [n1]
        val case2 as () = test [n1, n2] [n1, n2]
        val case3 as () = test [n1, n2, n3] [n1, n2, n3]
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
          val () = assertEqualElemList expected r
          val () = assertEqualIntElemList visited (!s)
        in
          ()
        end
    fun test fold arg expected visited =
        let
          val (s, f) = makeState ()
          val r = fold f [] (L2S arg)
          val () = assertEqualElemList expected r
          val () = assertEqualElemList visited (!s)
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
        val case_0 as () = testi [] [] []
        val case_1 as () = testi [n1] [n1] [(0, n1)]
        (* The result is in reverse order. *)
        val case_2 as () = testi [n1, n2] [n2, n1] [(0, n1), (1, n2)]
      in
        ()
      end

  fun foldl001 () =
      let
        val case_0 as () = test [] [] []
        val case_1 as () = test [n1] [n1] [n1]
        (* The result is in reverse order *)
        val case_2 as () = test [n1, n2] [n2, n1] [n1, n2]
        val case_3 as () = test [n1, n2, n3] [n3, n2, n1] [n1, n2, n3]
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
        val case_0 as () = testi [] [] []
        val case_1 as () = testi [n1] [n1] [(0, n1)]
        (* result is in normal order. visited is in reverse order *)
        val case_2 as () = testi [n1, n2] [n1, n2] [(1, n2), (0, n1)]
      in
        ()
      end

  fun foldr001 () =
      let
        val case_0 as () = test [] [] []
        val case_1 as () = test [n1] [n1] [n1]
        (* result is in normal order. visited is in reverse order *)
        val case_2 as () = test [n1, n2]  [n1, n2] [n2, n1]
        val case3 as () = test [n1, n2, n3] [n1, n2, n3] [n3, n2, n1]
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
          val () = assertEqualIntElemOption expected r
          val () = assertEqualIntElemList visited (!s)
        in
          ()
        end
    fun test arg expected visited =
        let
          val (s, f) = makeState n9
          val r = S.find f (L2S  arg)
          val () = assertEqualElemOption expected r
          val () = assertEqualElemList visited (!s)
        in
          ()
        end
  in
  fun findi001 () =
      let
        val case_0 as () = testi [] NONE []
        val case_1F as () = testi [n1] NONE [(0, n1)]
        val case_1T as () = testi [n9] (SOME(0, n9)) [(0, n9)]
        val case_2F as () = testi [n1, n2] NONE [(0, n1), (1, n2)]
        val case_2T1 as () = testi [n1, n9] (SOME(1, n9)) [(0, n1), (1, n9)]
        val case_2T2 as () = testi [n9, n1] (SOME(0, n9)) [(0, n9)]
        val case_2T3 as () = testi [n9, n9] (SOME(0, n9)) [(0, n9)]
      in
        ()
      end

  fun find001 () =
      let
        val case_0 as () = test [] NONE []
        val case_1F as () = test [n1] NONE [n1]
        val case_1T as () = test [n9] (SOME n9) [n9]
        val case_2F as () = test [n1, n2] NONE [n1, n2]
        val case_2T1 as () = test [n1, n9] (SOME n9) [n1, n9]
        val case_2T2 as () = test [n9, n1] (SOME n9) [n9]
        val case_2T3 as () = test [n9, n9] (SOME n9) [n9]
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
          val () = assertEqualBool expected r
          val () = assertEqualElemList visited (!s)
        in
          ()
        end
  in

  local
    val test = test S.exists
  in
  fun exists001 () =
      let
        val case_0 as () = test [] false []
        val case_1F as () = test [n1] false [n1]
        val case_1T as () = test [n9] true [n9]
        val case_2F as () = test [n1, n2] false [n1, n2]
        val case_2T1 as () = test [n1, n9] true [n1, n9]
        val case_2T2 as () = test [n9, n1] true [n9]
        val case_2T3 as () = test [n9, n9] true [n9]
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
        val case_0 as () = test [] true [] (* true is returnd for nothing. *)
        val case_1F as () = test [n1] false [n1]
        val case_1T as () = test [n9] true [n9]
        val case_2F as () = test [n1, n2] false [n1] (* visit only first element. *)
        val case_2F2 as () = test [n1, n9] false [n1]
        val case_2F3 as () = test [n9, n1] false [n9, n1]
        val case_2T as () = test [n9, n9] true [n9, n9]
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
          val () = assertEqualOrder expected r
          val () = assertEqualElem2List visited (!s)
        in
          ()
        end
  in
  fun collate001 () =
      let
        val case00 as () = test ([], []) EQUAL []
        val case01 as () = test ([], [n1]) LESS []
        val case10 as () = test ([n1], [n0]) GREATER [(n1, n0)]
        val case11L as () = test ([n1], [n2]) LESS [(n1, n2)]
        val case11E as () = test ([n1], [n1]) EQUAL [(n1, n1)]
        val case11G as () = test ([n2], [n1]) GREATER [(n2, n1)]
        val case12L as () = test ([n1], [n1, n2]) LESS [(n1, n1)]
        val case12G as () = test ([n2], [n1, n2]) GREATER [(n2, n1)]
        val case21L as () = test ([n1, n2], [n2]) LESS [(n1, n2)]
        val case21G as () = test ([n1, n2], [n1]) GREATER [(n1, n1)]
        val case22L1 as () = test ([n2, n1], [n3, n1]) LESS [(n2, n3)]
        val case22L2 as () = test ([n1, n2], [n1, n3]) LESS [(n1, n1), (n2, n3)]
        val case22E as () = test ([n1, n2], [n1, n2]) EQUAL [(n1, n1), (n2, n2)]
        val case22G1 as () = test ([n3, n1], [n2, n1]) GREATER [(n3, n2)]
        val case22G2 as () = test ([n1, n3], [n1, n2]) GREATER [(n1, n1), (n3, n2)]
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
        ("tabulate101", tabulate101),
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