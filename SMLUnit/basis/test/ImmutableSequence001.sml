(**
 * test cases for immutable sequence structures.
 * This module tests functions which immutable structures provide while mutable
 * structures do not.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
functor ImmutableSequence001(V : IMMUTABLE_SEQUENCE) : sig
  val suite : unit -> SMLUnit.Test.test
end =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  (************************************************************)

  val assertEqualElem = assertEqualByCompare V.compareElem V.elemToString
  val assertEqualElemList = assertEqualList assertEqualElem
  val assertEqualIntElem = assertEqual2Tuple (assertEqualInt, assertEqualElem)
  val assertEqualIntElemList = assertEqualList assertEqualIntElem

  val [n0, n1, n2, n3, n4, n5, n6, n7, n8, n9] =
      List.map V.intToElem [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

  val L2V = V.fromList
  fun V2L vector = V.foldr List.:: [] vector

  (****************************************)

  local
    fun test arg expected =
      let val newVector = V.update arg
      in assertEqualElemList expected (V2L newVector) end
    fun testFail arg =
        (V.update arg; fail "update:Subscript expected.")
        handle General.Subscript => ()
  in
  fun update0001 () =
      let
        val case00 as () = testFail (L2V[], 0, n9)
        val case0m1 as () = testFail (L2V[], ~1, n9)
        val case01 as () = testFail (L2V[], 1, n9)
        val case10 as () = test (L2V[n1], 0, n9) [n9]
        val case11 as () = testFail (L2V[n2], 1, n9)
        val case1m1 as () = testFail (L2V[n2], ~1, n9)
        val case20 as () = test (L2V[n1, n2], 0, n9) [n9, n2]
        val case21 as () = test (L2V[n1, n2], 1, n9) [n1, n9]
        val case22 as () = testFail (L2V[n1, n2], 2, n9)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqualElemList expected (V2L(V.concat (List.map L2V arg)))
  in
  fun concat0001 () =
      let
        val case0 as () = test [] []
        val case10 as () = test [[]] []
        val case200 as () = test [[], []] []
        val case11 as () = test [[n1]] [n1]
        val case201 as () = test [[], [n1]] [n1]
        val case210 as () = test [[n1], []] [n1]
        val case211 as () = test [[n1], [n2]] [n1, n2]
        val case222 as () = test [[n1, n2], [n3, n4]] [n1, n2, n3, n4]
        val case3303 as () = test [[n1, n2, n3], [], [n7, n8, n9]] [n1, n2, n3, n7, n8, n9]
        val case3333 as () = test [[n1, n2, n3], [n4, n5, n6], [n7, n8, n9]] [n1, n2, n3, n4, n5, n6, n7, n8, n9]
      in () end
  end (* local *)

  (********************)

  local
    fun makeStatei () =
        let
          val r = ref []
          fun f (index, n) = (r := !r @ [(index, n)]; V.nextElem n)
        in
          (r, f)
        end
    fun test arg expected visited =
        let
          val (s, f) = makeStatei ()
          val vector = V.mapi f (L2V arg)
          val () = assertEqualElemList expected (V2L vector)
          val () = assertEqualIntElemList visited (!s)
        in
          ()
        end
  in
  fun mapi0001 () =
      let
        val case_0 as () = test [] [] []
        val case_1 as () = test [n1] [n2] [(0, n1)]
        val case_2 as () = test [n1, n2] [n2, n3] [(0, n1), (1, n2)]
      in () end
  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f n = (r := !r @ [n]; V.nextElem n)
        in
          (r, f)
        end
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val vector = V.map f (L2V arg)
          val () = assertEqualElemList expected (V2L vector)
          val () = assertEqualElemList visited (!s)
        in
          ()
        end
  in
  fun map0001 () =
      let
        val case0 as () = test [] [] []
        val case1 as () = test [n1] [n2] [n1]
        val case2 as () = test [n1, n2] [n2, n3] [n1, n2]
        val case3 as () = test [n1, n2, n3] [n2, n3, n4] [n1, n2, n3]
      in () end
  end (* local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("update0001", update0001),
        ("concat0001", concat0001),
        ("mapi0001", mapi0001),
        ("map0001", map0001)
      ]

  (************************************************************)

end