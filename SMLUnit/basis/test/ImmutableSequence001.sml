(**
 * test cases for immutable sequence structures.
 * This module tests functions which immutable structures provide while mutable
 * structures do not.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
functor ImmutableSequence001(V : IMMUTABLE_SEQUENCE) =
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
        val update00 = testFail (L2V[], 0, n9)
        val update0m1 = testFail (L2V[], ~1, n9)
        val update01 = testFail (L2V[], 1, n9)
        val update10 = test (L2V[n1], 0, n9) [n9]
        val update11 = testFail (L2V[n2], 1, n9)
        val update1m1 = testFail (L2V[n2], ~1, n9)
        val update20 = test (L2V[n1, n2], 0, n9) [n9, n2]
        val update21 = test (L2V[n1, n2], 1, n9) [n1, n9]
        val update22 = testFail (L2V[n1, n2], 2, n9)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqualElemList expected (V2L(V.concat (List.map L2V arg)))
  in
  fun concat0001 () =
      let
        val concat0 = test [] []
        val concat10 = test [[]] []
        val concat200 = test [[], []] []
        val concat11 = test [[n1]] [n1]
        val concat201 = test [[], [n1]] [n1]
        val concat210 = test [[n1], []] [n1]
        val concat211 = test [[n1], [n2]] [n1, n2]
        val concat222 = test [[n1, n2], [n3, n4]] [n1, n2, n3, n4]
        val concat3303 = test [[n1, n2, n3], [], [n7, n8, n9]] [n1, n2, n3, n7, n8, n9]
        val concat3333 = test [[n1, n2, n3], [n4, n5, n6], [n7, n8, n9]] [n1, n2, n3, n4, n5, n6, n7, n8, n9]
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
          val _ = assertEqualElemList expected (V2L vector)
          val _ = assertEqualIntElemList visited (!s)
        in
          ()
        end
  in
  fun mapi0001 () =
      let
        val mapi_0 = test [] [] []
        val mapi_1 = test [n1] [n2] [(0, n1)]
        val mapi_2 = test [n1, n2] [n2, n3] [(0, n1), (1, n2)]
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
          val _ = assertEqualElemList expected (V2L vector)
          val _ = assertEqualElemList visited (!s)
        in
          ()
        end
  in
  fun map0001 () =
      let
        val map0 = test [] [] []
        val map1 = test [n1] [n2] [n1]
        val map2 = test [n1, n2] [n2, n3] [n1, n2]
        val map3 = test [n1, n2, n3] [n2, n3, n4] [n1, n2, n3]
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