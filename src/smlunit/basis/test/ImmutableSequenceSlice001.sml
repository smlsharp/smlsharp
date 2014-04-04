(**
 * test cases for immutable sequence slice structures.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
functor ImmutableSequenceSlice001(V : IMMUTABLE_SEQUENCE_SLICE) : sig
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

  val [n0, n1, n2, n3, n4, n5, n6, n7, n8, n9] =
      List.map V.intToElem [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

  val L2S = V.full o V.listToSequence 
  fun S2L slice = V.foldr List.:: [] slice
  fun makeSequence length =
      V.listToSequence(List.tabulate(length, V.intToElem))

  (****************************************)

  local
    fun test arg expected =
        assertEqualElemList
            expected (V.sequenceToList(V.concat (List.map L2S arg)))
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
          val vector = V.mapi f (L2S arg)
          val () = assertEqualElemList expected (V.vectorToList vector)
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
          val vector = V.map f (L2S arg)
          val () = assertEqualElemList expected (V.vectorToList vector)
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
        ("concat0001", concat0001),
        ("mapi0001", mapi0001),
        ("map0001", map0001)
      ]

  (************************************************************)

end