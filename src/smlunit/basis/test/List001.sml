(**
 * test cases for List structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure List001 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  structure I = Int

  (************************************************************)

  val assertEqualISOption =
      assertEqualOption (assertEqual2Tuple (assertEqualInt, assertEqualString))
  val assertEqualIntListList = assertEqualList assertEqualIntList
  val assertEqualInt2 =
      assertEqual2Tuple (assertEqualInt, assertEqualInt)
  val assertEqualInt2List = assertEqualList assertEqualInt2
  val assertEqualIntList2 =
      assertEqual2Tuple (assertEqualIntList, assertEqualIntList)
  val assertEqualIIListOption =
      assertEqualOption(assertEqual2Tuple (assertEqualInt, assertEqualIntList))

  (********************)

  fun null001 () =
      let
        val null1 = List.null ([] : int List.list)
        val () = assertTrue null1
        val null2 = List.null [1]
        val () = assertFalse null2
      in () end

  (********************)

  fun length001 () =
      let
        val length1 = List.length []
        val () = assertEqualInt 0 length1

        val length2 = List.length [1]
        val () = assertEqualInt 1 length2
        val length3 = List.length [1, 2]
        val () = assertEqualInt 2 length3
      in () end

  (********************)

  local
    fun test arg expected = assertEqualIntList expected (List.@ arg)
  in
  fun append001 () =
      let
        val case1 as () = test ([], []) [] 
        val case2 as () = test ([1], []) [1] 
        val case3 as () = test ([], [1]) [1] 
        val case4 as () = test ([1, 2], []) [1, 2] 
        val case5 as () = test ([], [1, 2]) [1, 2] 
        val case6 as () = test ([1], [2]) [1, 2] 
        val case7 as () = test ([1, 2], [2]) [1, 2, 2] 
        val case8 as () = test ([1, 2], [2, 3]) [1, 2, 2, 3] 
        val case9 as () = test ([1], [2, 3]) [1, 2, 3] 
      in () end
  end (* local *)

  (********************)

  fun hd001 () =
      let
        val hd1 = List.hd [] handle List.Empty => 9
        val () = assertEqualInt 9 hd1

        val hd2 = List.hd [1]
        val () = assertEqualInt 1 hd2

        val hd3 = List.hd [1, 2]
        val () = assertEqualInt 1 hd3
      in () end

  (********************)

  fun tl001 () =
      let
        val tl1 = List.tl [] handle List.Empty => [9]
        val () = assertEqualIntList [9] tl1

        val tl2 = List.tl [1]
        val () = assertEqualIntList [] tl2

        val tl3 = List.tl [1, 2]
        val () = assertEqualIntList [2] tl3
      in () end

  (********************)

  fun last001 () =
      let
        val last1 = List.last [] handle List.Empty => 9
        val () = assertEqualInt 9 last1

        val last2 = List.last [1]
        val () = assertEqualInt 1 last2

        val last3 = List.last [1, 2]
        val () = assertEqualInt 2 last3
      in () end

  (********************)

  fun getItem001 () =
      let
        val getItem1 = List.getItem ([] : int List.list)
        val () = assertEqualIIListOption NONE getItem1

        val getItem2 = List.getItem [1]
        val () = assertEqualIIListOption (SOME(1, [])) getItem2

        val getItem3 = List.getItem [1, 2]
        val () = assertEqualIIListOption (SOME(1, [2])) getItem3
      in () end

  (********************)

  local
    fun test arg expected = assertEqualInt expected (List.nth arg)
    fun testFail arg =
        (List.nth arg; fail "nth:Subscript expected.")
        handle General.Subscript => ()
  in
  fun nth001 () =
      let
        val case00 as () = testFail ([], 0) 
        val case0m1 as () = testFail ([], ~1) 
        val case01 as () = testFail ([], 1) 
        val case10 as () = test ([1], 0) 1
        val case11 as () = testFail ([2], 1) 
        val case1m1 as () = testFail ([2], ~1) 
        val case20 as () = test ([1, 2], 0) 1
        val case21 as () = test ([1, 2], 1) 2
        val case22 as () = testFail ([1, 2], 2) 
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualIntList expected (List.take arg)
    fun testFail arg =
        (List.take arg; fail "take:Subscript expected.")
        handle General.Subscript => ()
  in
  fun take001 () =
      let
        val case00 as () = test ([], 0) []
        val case0m1 as () = testFail ([], ~1)
        val case01 as () = testFail ([], 1)
        val case10 as () = test ([1], 0) []
        val case11 as () = test ([2], 1) [2]
        val case1m1 as () = testFail ([2], ~1)
        val case12 as () = testFail ([2], 2)
        val case20 as () = test ([1, 2], 0) []
        val case21 as () = test ([1, 2], 1) [1]
        val case22 as () = test ([1, 2], 2) [1, 2]
        val case23 as () = testFail ([1, 2], 3)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualIntList expected (List.drop arg)
    fun testFail arg =
        (List.drop arg; fail "drop:Subscript expected.")
        handle General.Subscript => ()
  in
  fun drop001 () =
      let
        val case00 as () = test ([], 0) []
        val case0m1 as () = testFail ([], ~1)
        val case01 as () = testFail ([], 1)
        val case10 as () = test ([1], 0) [1]
        val case11 as () = test ([2], 1) []
        val case1m1 as () = testFail ([2], ~1)
        val case12 as () = testFail ([2], 2)
        val case20 as () = test ([1, 2], 0) [1, 2]
        val case21 as () = test ([1, 2], 1) [2]
        val case22 as () = test ([1, 2], 2) []
        val case23 as () = testFail ([1, 2], 3)
      in () end
  end (* local *)

  (********************)

  fun rev001 () =
      let
        val rev0 = List.rev ([] : int List.list)
        val () = assertEqualIntList [] rev0

        val rev1 = List.rev [1]
        val () = assertEqualIntList [1] rev1

        val rev2 = List.rev [1, 2]
        val () = assertEqualIntList [2, 1] rev2

        val rev3 = List.rev [1, 2, 3]
        val () = assertEqualIntList [3, 2, 1] rev3
      in () end

  (********************)

  local
    fun test arg expected = assertEqualIntList expected (List.concat arg)
  in
  fun concat001 () =
      let
        val case0 as () = test [] [] 
        val case10 as () = test [[]] [] 
        val case200 as () = test [[], []] [] 
        val case11 as () = test [[1]] [1] 
        val case201 as () = test [[], [1]] [1] 
        val case210 as () = test [[1], []] [1] 
        val case211 as () = test [[1], [2]] [1, 2] 
        val case222 as () = test [[1, 2], [3, 4]] [1, 2, 3, 4] 
        val case3303 as () = test [[1, 2, 3], [], [7, 8, 9]] [1, 2, 3, 7, 8, 9] 
        val case3333 as () = test [[1, 2, 3], [4, 5, 6], [7, 8, 9]] [1, 2, 3, 4, 5, 6, 7, 8, 9] 
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualIntList expected (List.revAppend arg)
  in
  fun revAppend001 () =
      let
        val case00 as () = test ([], []) [] 
        val case01 as () = test ([], [1]) [1] 
        val case10 as () = test ([1], []) [1] 
        val case11 as () = test ([1], [2]) [1, 2] 
        val case20 as () = test ([1, 2], []) [2, 1] 
        val case02 as () = test ([], [1, 2]) [1, 2] 
        val case22 as () = test ([1, 2], [3, 4]) [2, 1, 3, 4] 
        val case33 as () = test ([1, 2, 3], [4, 5, 6]) [3, 2, 1, 4, 5, 6] 
      in () end
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
          val () = List.app f arg
          val () = assertEqualIntList visited (!s)
        in () end
  in
  fun app001 () =
      let
        val case0 as () = test [] []
        val case1 as () = test [1] [1]
        val case2 as () = test [1, 2] [1, 2]
        val case3 as () = test [1, 2, 3] [1, 2, 3]
      in () end
  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f n = (r := !r @ [n]; n * 10)
        in
          (r, f)
        end
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = List.map f arg
          val () = assertEqualIntList expected r
          val () = assertEqualIntList visited (!s)
        in () end
  in
  fun map001 () =
      let
        val case0 as () = test [] [] []
        val case1 as () = test [1] [10] [1]
        val case2 as () = test [1, 2] [10, 20] [1, 2]
        val case3 as () = test [1, 2, 3] [10, 20, 30] [1, 2, 3]
      in () end
  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f n = (r := !r @ [n]; if 0 < n then SOME (n * 10) else NONE)
        in
          (r, f)
        end
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = List.mapPartial f arg
          val () = assertEqualIntList expected r
          val () = assertEqualIntList visited (!s)
        in () end
  in
  fun mapPartial001 () =
      let
        val case0 as () = test [] [] []
        val case10 as () = test [0] [] [0]
        val case11 as () = test [1] [10] [1]
        val case200 as () = test [0, 0] [] [0, 0]
        val case201 as () = test [0, 1] [10] [0, 1]
        val case210 as () = test [1, 0] [10] [1, 0]
        val case211 as () = test [1, 2] [10, 20] [1, 2]
        val case3010 as () = test [0, 1, 0] [10] [0, 1, 0]
        val case3101 as () = test [1, 0, 2] [10, 20] [1, 0, 2]
        val case3111 as () = test [1, 2, 3] [10, 20, 30] [1, 2, 3]
      in () end

  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f n = (r := !r @ [n]; n mod 2 = 0)
        in
          (r, f)
        end
  in

  local
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = List.find f arg
          val () = assertEqualIntOption expected r
          val () = assertEqualIntList visited (!s)
        in () end
  in
  fun find001 () =
      let
        val case0 as () = test [] NONE []
        val case10 as () = test [1] NONE [1]
        val case11 as () = test [0] (SOME 0) [0]
        val case200 as () = test [1, 3] NONE [1, 3]
        val case201 as () = test [1, 2] (SOME 2) [1, 2]
        val case210 as () = test [0, 1] (SOME 0) [0]
        val case211 as () = test [2, 4] (SOME 2) [2]
        val case3101 as () = test [2, 1, 4] (SOME 2) [2]
        val case3010 as () = test [1, 2, 3] (SOME 2) [1, 2]
        val case3111 as () = test [2, 4, 6] (SOME 2) [2]
      in () end
  end (* inner local *)

  (********************)

  local
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = List.filter f arg
          val () = assertEqualIntList expected r
          val () = assertEqualIntList visited (!s)
        in () end
  in
  fun filter001 () =
      let
        val case0 as () = test [] [] []
        val case10 as () = test [1] [] [1]
        val case11 as () = test [0] [0] [0]
        val case200 as () = test [1, 3] [] [1, 3]
        val case201 as () = test [1, 2] [2] [1, 2]
        val case210 as () = test [0, 1] [0] [0, 1]
        val case211 as () = test [2, 4] [2, 4] [2, 4]
        val case3101 as () = test [2, 1, 4] [2, 4] [2, 1, 4]
        val case3010 as () = test [1, 2, 3] [2] [1, 2, 3]
        val case3111 as () = test [2, 4, 6] [2, 4, 6] [2, 4, 6]
      in () end
  end (* inner local *) 

  (********************)

  local
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = List.partition f arg
          val () = assertEqualIntList2 expected r
          val () = assertEqualIntList visited (!s)
        in () end
  in
  fun partition001 () =
      let
        val case0 as () = test [] ([], []) []
        val case10 as () = test [1] ([], [1]) [1]
        val case11 as () = test [0] ([0], []) [0]
        val case200 as () = test [1, 3] ([], [1, 3]) [1, 3]
        val case201 as () = test [1, 2] ([2], [1]) [1, 2]
        val case210 as () = test [0, 1] ([0], [1]) [0, 1]
        val case211 as () = test [2, 4] ([2, 4], []) [2, 4]
        val case3101 as () = test [2, 1, 4] ([2, 4], [1]) [2, 1, 4]
        val case3010 as () = test [1, 2, 3] ([2], [1, 3]) [1, 2, 3]
        val case3111 as () = test [2, 4, 6] ([2, 4, 6], []) [2, 4, 6]
      in () end
  end (* inner local *)

  end (* outer local *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f (n, accum) = (r := !r @ [n]; n :: accum)
        in
          (r, f)
        end
    fun test fold arg expected visited =
        let
          val (s, f) = makeState ()
          val r = fold f [] arg
          val () = assertEqualIntList expected r
          val () = assertEqualIntList visited (!s)
        in () end
  in
  fun foldl001 () =
      let
        val test = test List.foldl
        val case0 as () = test [] [] []
        val case1 as () = test [1] [1] [1]
        val case2 as () = test [1, 2] [2, 1] [1, 2]
        val case3 as () = test [1, 2, 3] [3, 2, 1] [1, 2, 3]
      in () end

  (********************)

  fun foldr001 () =
      let
        val test = test List.foldr
        val case0 as () = test [] [] []
        val case1 as () = test [1] [1] [1]
        val case2 as () = test [1, 2] [1, 2] [2, 1]
        val case3 as () = test [1, 2, 3] [1, 2, 3] [3, 2, 1]
      in () end

  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f n = (r := !r @ [n]; n mod 2 = 0)
        in
          (r, f)
        end
    fun test predicate arg expected visited =
        let
          val (s, f) = makeState ()
          val r = predicate f arg
          val () = assertEqualBool expected r
          val () = assertEqualIntList visited (!s)
        in () end
  in
  fun exists001 () =
      let
        val test = test List.exists
        val case0 as () = test [] false []
        val case10 as () = test [1] false [1]
        val case11 as () = test [0] true [0]
        val case200 as () = test [1, 3] false [1, 3]
        val case201 as () = test [1, 2] true [1, 2]
        val case210 as () = test [0, 1] true [0]
        val case211 as () = test [2, 4] true [2]
        val case3101 as () = test [2, 1, 4] true [2]
        val case3010 as () = test [1, 2, 3] true [1, 2]
        val case3111 as () = test [2, 4, 6] true [2]
      in () end

  (********************)

  fun all001 () =
      let
        val test = test List.all
        val case0 as () = test [] true []
        val case10 as () = test [1] false [1]
        val case11 as () = test [0] true [0]
        val case200 as () = test [1, 3] false [1]
        val case201 as () = test [1, 2] false [1]
        val case210 as () = test [0, 1] false [0, 1]
        val case211 as () = test [2, 4] true [2, 4]
        val case3101 as () = test [2, 1, 4] false [2, 1]
        val case3010 as () = test [1, 2, 3] false [1]
        val case3111 as () = test [2, 4, 6] true [2, 4, 6]
      in () end

  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f n = (r := !r @ [n]; n * 10)
        in
          (r, f)
        end
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = List.tabulate (arg, f)
          val () = assertEqualIntList expected r
          val () = assertEqualIntList visited (!s)
        in () end
  in
  fun tabulate001 () =
      let
        val case0 as () = test 0 [] []
        val case1 as () = test 1 [0] [0]
        val case2 as () = test 2 [0, 10] [0, 1]
        val case1 as () =
            (
              List.tabulate (~1, fn _ => fail "tabulate: unexpected call.");
              fail "tabulate:Size expected."
            )
            handle General.Size => ()
      in () end
  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f (x, y) = (r := !r @ [(x, y)]; Int.compare (x, y))
        in
          (r, f)
        end
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = List.collate f arg
          val () = assertEqualOrder expected r
          val () = assertEqualInt2List visited (!s)
        in () end
  in
  fun collate001 () =
      let
        val case00 as () = test ([], []) EQUAL []
        val case01 as () = test ([], [1]) LESS []
        val case10 as () = test ([1], [0]) GREATER [(1, 0)]
        val case11L as () = test ([1], [2]) LESS [(1, 2)]
        val case11E as () = test ([1], [1]) EQUAL [(1, 1)]
        val case11G as () = test ([2], [1]) GREATER [(2, 1)]
        val case12L as () = test ([1], [1, 2]) LESS [(1, 1)]
        val case12G as () = test ([2], [1, 2]) GREATER [(2, 1)]
        val case21L as () = test ([1, 2], [2]) LESS [(1, 2)]
        val case21G as () = test ([1, 2], [1]) GREATER [(1, 1)]
        val case22L1 as () = test ([2, 1], [3, 1]) LESS [(2, 3)]
        val case22L2 as () = test ([1, 2], [1, 3]) LESS [(1, 1), (2, 3)]
        val case22E as () = test ([1, 2], [1, 2]) EQUAL [(1, 1), (2, 2)]
        val case22G1 as () = test ([3, 1], [2, 1]) GREATER [(3, 2)]
        val case22G2 as () = test ([1, 3], [1, 2]) GREATER [(1, 1), (3, 2)]
      in () end
  end (* local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("null001", null001),
        ("length001", length001),
        ("append001", append001),
        ("hd001", hd001),
        ("tl001", tl001),
        ("last001", last001),
        ("getItem001", getItem001),
        ("nth001", nth001),
        ("take001", take001),
        ("drop001", drop001),
        ("rev001", rev001),
        ("concat001", concat001),
        ("revAppend001", revAppend001),
        ("app001", app001),
        ("map001", map001),
        ("mapPartial001", mapPartial001),
        ("find001", find001),
        ("filter001", filter001),
        ("partition001", partition001),
        ("foldl001", foldl001),
        ("foldr001", foldr001),
        ("exists001", exists001),
        ("all001", all001),
        ("tabulate001", tabulate001),
        ("collate001", collate001)
      ]

  (************************************************************)

end