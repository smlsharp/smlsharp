(**
 * test cases for sequence slice structures.
 * This module tests functions which both mutable and immutable structures
 * provide.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
functor SequenceSlice101(S : SEQUENCE_SLICE) : sig
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
  val assertEqualElemListInt2 =
      assertEqual3Tuple (assertEqualElemList, assertEqualInt, assertEqualInt)
  val assertEqualElemElemListOption =
      assertEqualOption
          (assertEqual2Tuple (assertEqualElem, assertEqualElemList))

  val [n0, n1, n2, n3, n9] = List.map S.intToElem [0, 1, 2, 3, 9]

  val L2S = S.full o S.listToSequence 
  fun S2L slice = S.foldr List.:: [] slice
  fun makeSequence length =
      S.listToSequence(List.tabulate(length, S.intToElem))

  (****************************************)

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
    fun test arg expected =
        assertEqualElemList expected (S2L (S.full (makeSequence arg)))
  in
  fun full001 () =
      let
        val case_0 as () = test 0 []
        val case_1 as () = test 1 [n0]
        val case_2 as () = test 2 [n0, n1]
      in () end
  end (* local *)

  (********************)

  local
    fun test (vectorLength, start, lengthOpt) expected =
        let val vector = makeSequence vectorLength
        in
          assertEqualElemList expected (S2L(S.slice(vector, start, lengthOpt)))
        end
    fun testFail (vectorLength, start, lengthOpt) =
        let val v = makeSequence vectorLength
        in
          (S.slice(v, start, lengthOpt); fail "slice: Subscript expected.")
          handle General.Subscript => ()
        end
  in
  fun slice001 () =
      let
        val case_0_0_N as () = test (0, 0, NONE) []
        val case_1_0_N as () = test (1, 0, NONE) [n0]
        val case_1_0_0 as () = test (1, 0, SOME 0) []
        val case_1_0_1 as () = test (1, 0, SOME 1) [n0]
        val case_1_0_2 as () = testFail (1, 0, SOME 2)
        val case_1_1_N as () = test (1, 1, NONE) []
        val case_1_1_0 as () = test (1, 1, SOME 0) []
        val case_1_1_1 as () = testFail (1, 1, SOME 1)
        val case_1_2_N as () = testFail (1, 2, NONE)
        val case_2_m1_N as () = testFail (2, ~1, NONE)
        val case_2_m1_0 as () = testFail (2, ~1, SOME 0)
        val case_2_0_N as () = test (2, 0, NONE) [n0, n1]
        val case_2_0_m1 as () = testFail (2, 0, SOME ~1)
        val case_2_0_0 as () = test (2, 0, SOME 0) []
        val case_2_0_2 as () = test (2, 0, SOME 2) [n0, n1]
        val case_2_0_3 as () = testFail (2, 0, SOME 3)
        val case_2_1_N as () = test (2, 1, NONE) [n1]
        val case_2_1_m1 as () = testFail (2, 1, SOME ~1)
        val case_2_1_0 as () = test (2, 1, SOME 0) []
        val case_2_1_1 as () = test (2, 1, SOME 1) [n1]
        val case_2_1_2 as () = testFail (2, 1, SOME 2)
        val case_2_2_N as () = test (2, 2, NONE) []
        val case_2_2_m1 as () = testFail (2, 2, SOME ~1)
        val case_2_2_0 as () = test (2, 2, SOME 0) []
        val case_2_2_1 as () = testFail (2, 2, SOME 1)
      in () end
  end (* local *)

(********************)

  local
    fun test (vectorLength, start1, length1, start2, lengthOpt2) expected =
        let
          val vector = makeSequence vectorLength
          val slice1 = S.slice(vector, start1, SOME length1)
          val slice2 = S.subslice(slice1, start2, lengthOpt2)
        in
          assertEqualElemList expected (S2L slice2)
        end
    fun testFail (vectorLength, start1, length1, start2, lengthOpt2) =
        let
          val vector = makeSequence vectorLength
          val slice1 = S.slice(vector, start1, SOME length1)
        in
          (
            S.subslice(slice1, start2, lengthOpt2);
            fail "subslice: Subscript expected."
          )
          handle General.Subscript => ()
        end
  in
  fun subslice001 () =
      let
        val case_5_1_3_m1_N as () = testFail (5, 1, 3, ~1, NONE)
        val case_5_1_3_m1_0 as () = testFail (5, 1, 3, ~1, SOME 0)
        val case_5_1_3_0_N as () = test (5, 1, 3, 0, NONE) [n1, n2, n3]
        val case_5_1_3_0_m1 as () = testFail (5, 1, 3, 0, SOME ~1)
        val case_5_1_3_0_3 as () = test (5, 1, 3, 0, SOME 3) [n1, n2, n3]
        val case_5_1_3_1_N as () = test (5, 1, 3, 1, NONE) [n2, n3]
        val case_5_1_3_1_m1 as () = testFail (5, 1, 3, 1, SOME ~1)
        val case_5_1_3_1_0 as () = test (5, 1, 3, 1, SOME 0) []
        val case_5_1_3_1_1 as () = test (5, 1, 3, 1, SOME 1) [n2]
        val case_5_1_3_1_2 as () = test (5, 1, 3, 1, SOME 2) [n2, n3]
        val case_5_1_3_1_3 as () = testFail (5, 1, 3, 1, SOME 3)
        val case_5_1_3_2_N as () = test (5, 1, 3, 2, NONE) [n3]
        val case_5_1_3_2_m1 as () = testFail (5, 1, 3, 2, SOME ~1)
        val case_5_1_3_2_0 as () = test (5, 1, 3, 2, SOME 0) []
        val case_5_1_3_2_1 as () = test (5, 1, 3, 2, SOME 1) [n3]
      in () end
  end (* local *)

  (********************)

  local
    fun test (vectorLength, start, length) expected =
        let
          val vector = makeSequence vectorLength
          val slice = S.slice (vector, start, SOME length)
        in
          case S.base(slice)
           of (v, s, len) =>
              assertEqualElemListInt2 expected (S.sequenceToList v, s, len)
        end
  in
  fun base001 () =
      let
        val case_0_0_0 as () = test (0, 0, 0) ([], 0, 0)
        val case_2_0_0 as () = test (2, 0, 0) ([n0, n1], 0, 0)
        val case_2_0_1 as () = test (2, 0, 1) ([n0, n1], 0, 1)
        val case_2_1_1 as () = test (2, 1, 1) ([n0, n1], 1, 1)
      in () end
  end (* local *)

  (********************)

  local
    fun test (vectorLength, start, length) expected =
        let
          val vector = makeSequence vectorLength
          val slice = S.slice(vector, start, SOME length)
        in
          assertEqualElemList expected (S.vectorToList (S.vector(slice)))
        end
  in
  fun vector001 () =
      let
        val case_0_0_0 as () = test (0, 0, 0) []
        val case_2_0_0 as () = test (2, 0, 0) []
        val case_2_0_1 as () = test (2, 0, 1) [n0]
        val case_2_1_1 as () = test (2, 1, 1) [n1]
      in () end
  end (* local *)

  (********************)

  local
    fun test (vectorLength, start, length) expected =
        let
          val vector = makeSequence vectorLength
          val slice = S.slice(vector, start, SOME length)
        in
          assertEqualBool expected (S.isEmpty slice)
        end
  in        
  fun isEmpty001 () =
      let
        val case_0_0_0 as () = test (0, 0, 0) true
        val case_1_0_0 as () = test (1, 0, 0) true
        val case_1_0_1 as () = test (1, 0, 1) false
        val case_1_1_0 as () = test (1, 1, 0) true
        val case_2_0_0 as () = test (2, 0, 0) true
        val case_2_0_1 as () = test (2, 0, 1) false
        val case_2_0_2 as () = test (2, 0, 2) false
        val case_2_1_0 as () = test (2, 1, 0) true
        val case_2_1_1 as () = test (2, 1, 1) false
        val case_2_2_0 as () = test (2, 2, 0) true
      in () end
  end (* local *)

  (********************)

  local
    fun test (vectorLength, start, length) expected =
        let val vector = makeSequence vectorLength
        in
          assertEqualElemElemListOption
              expected
              (case S.getItem(S.slice(vector, start, SOME length)) of
                 NONE => NONE
               | SOME(value, slice) => SOME (value, S2L slice))
        end
  in
  fun getItem001 () =
      let
        val case_0_0_0 as () = test (0, 0, 0) NONE
        val case_1_0_0 as () = test (1, 0, 0) NONE
        val case_1_0_1 as () = test (1, 0, 1) (SOME(n0, []))
        val case_1_1_0 as () = test (1, 1, 0) NONE
        val case_2_0_0 as () = test (2, 0, 0) NONE
        val case_2_0_1 as () = test (2, 0, 1) (SOME(n0, []))
        val case_2_0_2 as () = test (2, 0, 2) (SOME(n0, [n1]))
        val case_2_1_0 as () = test (2, 1, 0) NONE
        val case_2_1_1 as () = test (2, 1, 1) (SOME(n1, []))
        val case_2_2_0 as () = test (2, 2, 0) NONE
      in () end
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
        ("length001", length001),
        ("sub001", sub001),
        ("full001", full001),
        ("slice001", slice001),
        ("subslice001", subslice001),
        ("base001", base001),
        ("vector001", vector001),
        ("isEmpty001", isEmpty001),
        ("getItem001", getItem001),
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