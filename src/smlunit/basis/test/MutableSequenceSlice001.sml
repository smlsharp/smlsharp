(**
 * test cases for mutable sequence slice structures.
 * This module tests functions which mutable structures provide while immutable
 * structures do not.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
functor MutableSequenceSlice001(A : MUTABLE_SEQUENCE_SLICE) : sig
  val suite : unit -> SMLUnit.Test.test
end =
struct

  (************************************************************)

  structure T = SMLUnit.Test
  open SMLUnit.Assert

  (************************************************************)

  val assertEqualElem = assertEqualByCompare A.compareElem A.elemToString
  val assertEqualElemList = assertEqualList assertEqualElem
  val assertEqualElemOption = assertEqualOption assertEqualElem
  val assertEqualIntElem = assertEqual2Tuple (assertEqualInt, assertEqualElem)
  val assertEqualIntElemList = assertEqualList assertEqualIntElem
  val assertEqualIntElemOption = assertEqualOption assertEqualIntElem
  val assertEqualElem2List =
      assertEqualList
          (assertEqual2Tuple (assertEqualElem, assertEqualElem))
  val assertEqualElemList2 =
      assertEqual2Tuple (assertEqualElemList, assertEqualElemList)

  val [n0, n1, n2, n3, n4, n5, n6, n7, n8, n9] =
      List.map A.intToElem [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

  val L2S = A.full o A.listToSequence 
  fun S2L slice = A.foldr List.:: [] slice
  val L2A = A.listToSequence
  val A2L = A.sequenceToList
  fun makeSequence length =
      A.listToSequence(List.tabulate(length, A.intToElem))

  (****************************************)

  local
    fun test (arrayLength, start, length, index, elem) expected =
      let
        val array = makeSequence arrayLength
        val slice = A.slice (array, start, SOME length)
        val () = A.update(slice, index, elem)
      in
        assertEqualElemList expected (A.sequenceToList array)
      end
    fun testFail (arrayLength, start, length, index, elem) =
      let
        val array = makeSequence arrayLength
        val slice = A.slice (array, start, SOME length)
      in
        (A.update(slice, index, elem); fail "update: Subscript expected.")
        handle General.Subscript => ()
      end
  in
  fun update0001 () =
      let
        val case_0_0_0_0 as () = testFail (0, 0, 0, 0, n9)
        val case_1_0_1_0 as () = test (1, 0, 1, 0, n9) [n9]
        val case_1_0_1_1 as () = testFail (1, 0, 1, 1, n9) 
        val case_5_1_3_m1 as () = testFail (5, 1, 3, ~1, n9)
        val case_5_1_3_0 as () = test (5, 1, 3, 0, n9) [n0, n9, n2, n3, n4]
        val case_5_1_3_2 as () = test (5, 1, 3, 2, n9) [n0, n1, n2, n9, n4]
        val case_5_1_3_3 as () = testFail (5, 1, 3, 3, n9)
      in () end
  end (* local *)

  (********************)

  local
    fun test (src, dst, di) expected =
        let
          val src = L2S src
          val dst = makeSequence dst
          val () = A.copy {src = src, dst = dst, di = di}
        in
          assertEqualElemList2 expected (S2L src, A2L dst)
        end
    fun testFail (src, dst, di) =
        let
          val src = L2S src
          val dst = makeSequence dst
        in
          (
            A.copy {src = src, dst = dst, di = di};
            fail "copy:Subscript expected."
          )
          handle General.Subscript => ()
        end
  in
  fun copy0001 () =
      let
        (* variation of length of src array *)
        val case_0_3_0 as () = test ([], 3, 0) ([], [n0, n1, n2])
        val case_1_3_0 as () = test ([n9], 3, 0) ([n9], [n9, n1, n2])
        val case_2_3_0 as () = test ([n9, n8], 3, 0) ([n9, n8], [n9, n8, n2])

        (* variation of length of dst array *)
        val case_3_0_0 as () = testFail ([n9, n8, n7], 0, 0)
        val case_3_1_0 as () = testFail ([n9, n8, n7], 1, 0)
        val case_3_2_0 as () = testFail ([n9, n8, n7], 2, 0)
        val case_3_3_0 as () = test ([n9, n8, n7], 3, 0) ([n9, n8, n7], [n9, n8, n7])
        val case_3_4_0 as () =
            test ([n9, n8, n7], 4, 0) ([n9, n8, n7], [n9, n8, n7, n3])

        (* variation of di *)
        val case_3_4_m1 as () = testFail ([n9, n8, n7], 4, ~1)
        val case_3_4_0 as () =
            test ([n9, n8, n7], 4, 0) ([n9, n8, n7], [n9, n8, n7, n3])
        val case_3_4_1 as () =
            test ([n9, n8, n7], 4, 1) ([n9, n8, n7], [n0, n9, n8, n7])
        val case_3_4_2 as () = testFail ([n9, n8, n7], 4, 2)
      in () end
  end (* local *)

  (********************)

  local
    fun test (src, dst, di) expected =
        let
          val src = A.sliceVec (A.listToVector src, 0, NONE)
          val dst = makeSequence dst
          val () = A.copyVec {src = src, dst = dst, di = di}
        in
          assertEqualElemList expected (A2L dst)
        end
    fun testFail (src, dst, di) =
        let
          val src = A.sliceVec (A.listToVector src, 0, NONE)
          val dst = makeSequence dst
        in
          (
            A.copyVec {src = src, dst = dst, di = di};
            fail "copyVec:Subscript expected."
          )
          handle General.Subscript => ()
        end
  in
  fun copyVec0001 () =
      let
        (* variation of length of src array *)
        val case_0_3_0 as () = test ([], 3, 0) [n0, n1, n2]
        val case_1_3_0 as () = test ([n9], 3, 0) [n9, n1, n2]
        val case_2_3_0 as () = test ([n9, n8], 3, 0) [n9, n8, n2]

        (* variation of length of dst array *)
        val case_3_0_0 as () = testFail ([n9, n8, n7], 0, 0)
        val case_3_1_0 as () = testFail ([n9, n8, n7], 1, 0)
        val case_3_2_0 as () = testFail ([n9, n8, n7], 2, 0)
        val case_3_3_0 as () = test ([n9, n8, n7], 3, 0) [n9, n8, n7]
        val case_3_4_0 as () = test ([n9, n8, n7], 4, 0) [n9, n8, n7, n3]

        (* variation of di *)
        val case_3_4_m1 as () = testFail ([n9, n8, n7], 4, ~1)
        val case_3_4_0 as () = test ([n9, n8, n7], 4, 0) [n9, n8, n7, n3]
        val case_3_4_1 as () = test ([n9, n8, n7], 4, 1) [n0, n9, n8, n7]
        val case_3_4_2 as () = testFail ([n9, n8, n7], 4, 2)
      in () end
  end (* local *)

  (********************)

  local
    fun makeStatei () =
        let
          val r = ref []
          fun f (index, n) = (r := !r @ [(index, n)]; A.nextElem n)
        in
          (r, f)
        end
    fun test (arrayLength, start, length) expected visited =
        let
          val (s, f) = makeStatei ()
          val array = makeSequence arrayLength
          val slice = A.slice (array, start, SOME length)
          val () = A.modifyi f slice
          val () = assertEqualElemList expected (A2L array)
          val () = assertEqualIntElemList visited (!s)
        in
          ()
        end
  in
  fun modifyi0001 () =
      let
        val case_0_0_0 as () = test (0, 0, 0) [] []
        val case_1_0_1 as () = test (1, 0, 1) [n1] [(0, n0)]
        val case_1_1_0 as () = test (1, 1, 0) [n0] []
        val case_2_0_0 as () = test (2, 0, 0) [n0, n1] []
        val case_2_0_1 as () = test (2, 0, 1) [n1, n1] [(0, n0)]
        val case_2_0_2 as () = test (2, 0, 2) [n1, n2] [(0, n0), (1, n1)]
        val case_2_1_0 as () = test (2, 1, 0) [n0, n1] []
        val case_2_1_1 as () = test (2, 1, 1) [n0, n2] [(0, n1)]
        val case_2_2_0 as () = test (2, 2, 0) [n0, n1] []
      in
        ()
      end
  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f n = (r := !r @ [n]; A.nextElem n)
        in
          (r, f)
        end
    fun test (arrayLength, start, length) expected visited =
        let
          val (s, f) = makeState ()
          val array = makeSequence arrayLength
          val slice = A.slice (array, start, SOME length)
          val () = A.modify f slice
          val () = assertEqualElemList expected (A2L array)
          val () = assertEqualElemList visited (!s)
        in
          ()
        end
  in
  fun modify0001 () =
      let
        val case_0_0_0 as () = test (0, 0, 0) [] []
        val case_1_0_1 as () = test (1, 0, 1) [n1] [n0]
        val case_1_1_0 as () = test (1, 1, 0) [n0] []
        val case_2_0_0 as () = test (2, 0, 0) [n0, n1] []
        val case_2_0_1 as () = test (2, 0, 1) [n1, n1] [n0]
        val case_2_0_2 as () = test (2, 0, 2) [n1, n2] [n0, n1]
        val case_2_1_0 as () = test (2, 1, 0) [n0, n1] []
        val case_2_1_1 as () = test (2, 1, 1) [n0, n2] [n1]
        val case_2_2_0 as () = test (2, 2, 0) [n0, n1] []
      in
        ()
      end
  end (* local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("update0001", update0001),
        ("copy0001", copy0001),
        ("copyVec0001", copyVec0001),
        ("modifyi0001", modifyi0001),
        ("modify0001", modify0001)
      ]

  (************************************************************)

end
