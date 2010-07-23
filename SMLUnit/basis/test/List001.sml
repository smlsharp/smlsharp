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
        val _ = assertTrue null1
        val null2 = List.null [1]
        val _ = assertFalse null2
      in () end

  (********************)

  fun length001 () =
      let
        val length1 = List.length []
        val _ = assertEqualInt 0 length1

        val length2 = List.length [1]
        val _ = assertEqualInt 1 length2
        val length3 = List.length [1, 2]
        val _ = assertEqualInt 2 length3
      in () end

  (********************)

  local
    fun test arg expected = assertEqualIntList expected (List.@ arg)
  in
  fun append001 () =
      let
        val append1 = test ([], []) [] 
        val append2 = test ([1], []) [1] 
        val append3 = test ([], [1]) [1] 
        val append4 = test ([1, 2], []) [1, 2] 
        val append5 = test ([], [1, 2]) [1, 2] 
        val append6 = test ([1], [2]) [1, 2] 
        val append7 = test ([1, 2], [2]) [1, 2, 2] 
        val append8 = test ([1, 2], [2, 3]) [1, 2, 2, 3] 
        val append9 = test ([1], [2, 3]) [1, 2, 3] 
      in () end
  end (* local *)

  (********************)

  fun hd001 () =
      let
        val hd1 = List.hd [] handle List.Empty => 9
        val _ = assertEqualInt 9 hd1

        val hd2 = List.hd [1]
        val _ = assertEqualInt 1 hd2

        val hd3 = List.hd [1, 2]
        val _ = assertEqualInt 1 hd3
      in () end

  (********************)

  fun tl001 () =
      let
        val tl1 = List.tl [] handle List.Empty => [9]
        val _ = assertEqualIntList [9] tl1

        val tl2 = List.tl [1]
        val _ = assertEqualIntList [] tl2

        val tl3 = List.tl [1, 2]
        val _ = assertEqualIntList [2] tl3
      in () end

  (********************)

  fun last001 () =
      let
        val last1 = List.last [] handle List.Empty => 9
        val _ = assertEqualInt 9 last1

        val last2 = List.last [1]
        val _ = assertEqualInt 1 last2

        val last3 = List.last [1, 2]
        val _ = assertEqualInt 2 last3
      in () end

  (********************)

  fun getItem001 () =
      let
        val getItem1 = List.getItem ([] : int List.list)
        val _ = assertEqualIIListOption NONE getItem1

        val getItem2 = List.getItem [1]
        val _ = assertEqualIIListOption (SOME(1, [])) getItem2

        val getItem3 = List.getItem [1, 2]
        val _ = assertEqualIIListOption (SOME(1, [2])) getItem3
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
        val nth00 = testFail ([], 0) 
        val nth0m1 = testFail ([], ~1) 
        val nth01 = testFail ([], 1) 
        val nth10 = test ([1], 0) 1
        val nth11 = testFail ([2], 1) 
        val nth1m1 = testFail ([2], ~1) 
        val nth20 = test ([1, 2], 0) 1
        val nth21 = test ([1, 2], 1) 2
        val nth22 = testFail ([1, 2], 2) 
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
        val take00 = test ([], 0) []
        val take0m1 = testFail ([], ~1)
        val take01 = testFail ([], 1)
        val take10 = test ([1], 0) []
        val take11 = test ([2], 1) [2]
        val take1m1 = testFail ([2], ~1)
        val take12 = testFail ([2], 2)
        val take20 = test ([1, 2], 0) []
        val take21 = test ([1, 2], 1) [1]
        val take22 = test ([1, 2], 2) [1, 2]
        val take23 = testFail ([1, 2], 3)
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
        val drop00 = test ([], 0) []
        val drop0m1 = testFail ([], ~1)
        val drop01 = testFail ([], 1)
        val drop10 = test ([1], 0) [1]
        val drop11 = test ([2], 1) []
        val drop1m1 = testFail ([2], ~1)
        val drop12 = testFail ([2], 2)
        val drop20 = test ([1, 2], 0) [1, 2]
        val drop21 = test ([1, 2], 1) [2]
        val drop22 = test ([1, 2], 2) []
        val drop23 = testFail ([1, 2], 3)
      in () end
  end (* local *)

  (********************)

  fun rev001 () =
      let
        val rev0 = List.rev ([] : int List.list)
        val _ = assertEqualIntList [] rev0

        val rev1 = List.rev [1]
        val _ = assertEqualIntList [1] rev1

        val rev2 = List.rev [1, 2]
        val _ = assertEqualIntList [2, 1] rev2

        val rev3 = List.rev [1, 2, 3]
        val _ = assertEqualIntList [3, 2, 1] rev3
      in () end

  (********************)

  local
    fun test arg expected = assertEqualIntList expected (List.concat arg)
  in
  fun concat001 () =
      let
        val concat0 = test [] [] 
        val concat10 = test [[]] [] 
        val concat200 = test [[], []] [] 
        val concat11 = test [[1]] [1] 
        val concat201 = test [[], [1]] [1] 
        val concat210 = test [[1], []] [1] 
        val concat211 = test [[1], [2]] [1, 2] 
        val concat222 = test [[1, 2], [3, 4]] [1, 2, 3, 4] 
        val concat3303 = test [[1, 2, 3], [], [7, 8, 9]] [1, 2, 3, 7, 8, 9] 
        val concat3333 = test [[1, 2, 3], [4, 5, 6], [7, 8, 9]] [1, 2, 3, 4, 5, 6, 7, 8, 9] 
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualIntList expected (List.revAppend arg)
  in
  fun revAppend001 () =
      let
        val revAppend00 = test ([], []) [] 
        val revAppend01 = test ([], [1]) [1] 
        val revAppend10 = test ([1], []) [1] 
        val revAppend11 = test ([1], [2]) [1, 2] 
        val revAppend20 = test ([1, 2], []) [2, 1] 
        val revAppend02 = test ([], [1, 2]) [1, 2] 
        val revAppend22 = test ([1, 2], [3, 4]) [2, 1, 3, 4] 
        val revAppend33 = test ([1, 2, 3], [4, 5, 6]) [3, 2, 1, 4, 5, 6] 
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
          val _ = assertEqualIntList visited (!s)
        in () end
  in
  fun app001 () =
      let
        val app0 = test [] []
        val app1 = test [1] [1]
        val app2 = test [1, 2] [1, 2]
        val app3 = test [1, 2, 3] [1, 2, 3]
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
          val _ = assertEqualIntList expected r
          val _ = assertEqualIntList visited (!s)
        in () end
  in
  fun map001 () =
      let
        val map0 = test [] [] []
        val map1 = test [1] [10] [1]
        val map2 = test [1, 2] [10, 20] [1, 2]
        val map3 = test [1, 2, 3] [10, 20, 30] [1, 2, 3]
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
          val _ = assertEqualIntList expected r
          val _ = assertEqualIntList visited (!s)
        in () end
  in
  fun mapPartial001 () =
      let
        val mapPartial0 = test [] [] []
        val mapPartial10 = test [0] [] [0]
        val mapPartial11 = test [1] [10] [1]
        val mapPartial200 = test [0, 0] [] [0, 0]
        val mapPartial201 = test [0, 1] [10] [0, 1]
        val mapPartial210 = test [1, 0] [10] [1, 0]
        val mapPartial211 = test [1, 2] [10, 20] [1, 2]
        val mapPartial3010 = test [0, 1, 0] [10] [0, 1, 0]
        val mapPartial3101 = test [1, 0, 2] [10, 20] [1, 0, 2]
        val mapPartial3111 = test [1, 2, 3] [10, 20, 30] [1, 2, 3]
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
          val _ = assertEqualIntOption expected r
          val _ = assertEqualIntList visited (!s)
        in () end
  in
  fun find001 () =
      let
        val find0 = test [] NONE []
        val find10 = test [1] NONE [1]
        val find11 = test [0] (SOME 0) [0]
        val find200 = test [1, 3] NONE [1, 3]
        val find201 = test [1, 2] (SOME 2) [1, 2]
        val find210 = test [0, 1] (SOME 0) [0]
        val find211 = test [2, 4] (SOME 2) [2]
        val find3101 = test [2, 1, 4] (SOME 2) [2]
        val find3010 = test [1, 2, 3] (SOME 2) [1, 2]
        val find3111 = test [2, 4, 6] (SOME 2) [2]
      in () end
  end (* inner local *)

  (********************)

  local
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = List.filter f arg
          val _ = assertEqualIntList expected r
          val _ = assertEqualIntList visited (!s)
        in () end
  in
  fun filter001 () =
      let
        val filter0 = test [] [] []
        val filter10 = test [1] [] [1]
        val filter11 = test [0] [0] [0]
        val filter200 = test [1, 3] [] [1, 3]
        val filter201 = test [1, 2] [2] [1, 2]
        val filter210 = test [0, 1] [0] [0, 1]
        val filter211 = test [2, 4] [2, 4] [2, 4]
        val filter3101 = test [2, 1, 4] [2, 4] [2, 1, 4]
        val filter3010 = test [1, 2, 3] [2] [1, 2, 3]
        val filter3111 = test [2, 4, 6] [2, 4, 6] [2, 4, 6]
      in () end
  end (* inner local *) 

  (********************)

  local
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = List.partition f arg
          val _ = assertEqualIntList2 expected r
          val _ = assertEqualIntList visited (!s)
        in () end
  in
  fun partition001 () =
      let
        val partition0 = test [] ([], []) []
        val partition10 = test [1] ([], [1]) [1]
        val partition11 = test [0] ([0], []) [0]
        val partition200 = test [1, 3] ([], [1, 3]) [1, 3]
        val partition201 = test [1, 2] ([2], [1]) [1, 2]
        val partition210 = test [0, 1] ([0], [1]) [0, 1]
        val partition211 = test [2, 4] ([2, 4], []) [2, 4]
        val partition3101 = test [2, 1, 4] ([2, 4], [1]) [2, 1, 4]
        val partition3010 = test [1, 2, 3] ([2], [1, 3]) [1, 2, 3]
        val partition3111 = test [2, 4, 6] ([2, 4, 6], []) [2, 4, 6]
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
          val _ = assertEqualIntList expected r
          val _ = assertEqualIntList visited (!s)
        in () end
  in
  fun foldl001 () =
      let
        val test = test List.foldl
        val foldl0 = test [] [] []
        val foldl1 = test [1] [1] [1]
        val foldl2 = test [1, 2] [2, 1] [1, 2]
        val foldl3 = test [1, 2, 3] [3, 2, 1] [1, 2, 3]
      in () end

  (********************)

  fun foldr001 () =
      let
        val test = test List.foldr
        val foldr0 = test [] [] []
        val foldr1 = test [1] [1] [1]
        val foldr2 = test [1, 2] [1, 2] [2, 1]
        val foldr3 = test [1, 2, 3] [1, 2, 3] [3, 2, 1]
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
          val _ = assertEqualBool expected r
          val _ = assertEqualIntList visited (!s)
        in () end
  in
  fun exists001 () =
      let
        val test = test List.exists
        val exists0 = test [] false []
        val exists10 = test [1] false [1]
        val exists11 = test [0] true [0]
        val exists200 = test [1, 3] false [1, 3]
        val exists201 = test [1, 2] true [1, 2]
        val exists210 = test [0, 1] true [0]
        val exists211 = test [2, 4] true [2]
        val exists3101 = test [2, 1, 4] true [2]
        val exists3010 = test [1, 2, 3] true [1, 2]
        val exists3111 = test [2, 4, 6] true [2]
      in () end

  (********************)

  fun all001 () =
      let
        val test = test List.all
        val all0 = test [] true []
        val all10 = test [1] false [1]
        val all11 = test [0] true [0]
        val all200 = test [1, 3] false [1]
        val all201 = test [1, 2] false [1]
        val all210 = test [0, 1] false [0, 1]
        val all211 = test [2, 4] true [2, 4]
        val all3101 = test [2, 1, 4] false [2, 1]
        val all3010 = test [1, 2, 3] false [1]
        val all3111 = test [2, 4, 6] true [2, 4, 6]
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
          val _ = assertEqualIntList expected r
          val _ = assertEqualIntList visited (!s)
        in () end
  in
  fun tabulate001 () =
      let
        val tabulate0 = test 0 [] []
        val tabulate1 = test 1 [0] [0]
        val tabulate2 = test 2 [0, 10] [0, 1]
        val tabulatem1 =
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
          val _ = assertEqualOrder expected r
          val _ = assertEqualInt2List visited (!s)
        in () end
  in
  fun collate001 () =
      let
        val collate00 = test ([], []) EQUAL []
        val collate01 = test ([], [1]) LESS []
        val collate10 = test ([1], [0]) GREATER [(1, 0)]
        val collate11L = test ([1], [2]) LESS [(1, 2)]
        val collate11E = test ([1], [1]) EQUAL [(1, 1)]
        val collate11G = test ([2], [1]) GREATER [(2, 1)]
        val collate12L = test ([1], [1, 2]) LESS [(1, 1)]
        val collate12G = test ([2], [1, 2]) GREATER [(2, 1)]
        val collate21L = test ([1, 2], [2]) LESS [(1, 2)]
        val collate21G = test ([1, 2], [1]) GREATER [(1, 1)]
        val collate22L1 = test ([2, 1], [3, 1]) LESS [(2, 3)]
        val collate22L2 = test ([1, 2], [1, 3]) LESS [(1, 1), (2, 3)]
        val collate22E = test ([1, 2], [1, 2]) EQUAL [(1, 1), (2, 2)]
        val collate22G1 = test ([3, 1], [2, 1]) GREATER [(3, 2)]
        val collate22G2 = test ([1, 3], [1, 2]) GREATER [(1, 1), (3, 2)]
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