(**
 * test cases for mutable sequence structures.
 * This module tests functions which mutable structures provide while immutable
 * structures do not.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
functor MutableSequence001(A : MUTABLE_SEQUENCE) =
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

  val [n0, n1, n2, n3, n4, n5, n6, n7, n8, n9] =
      List.map A.intToElem [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

  val L2A = A.fromList
  val L2V = A.listToVector
  fun A2L array = A.foldr List.:: [] array
  val V2L = A.vectorToList

  (****************************************)

  local
    fun testi arg expected = assertEqualElemList expected (A2L(A.array arg))
  in
  fun array001 () =
      let
        val array_0i = testi (0, n1) []
        val array_1i = testi (1, n1) [n1]
        val array_2i = testi (2, n1) [n1, n1]
      in
        ()
      end
  fun array101 () =
      let
        val array_m1i =
            (A.array (~1, n1); fail "array(~1)") handle General.Size => ()
        val array_maxLenPlus1 =
            (A.array (A.maxLen + 1, n1); fail "array(maxLen+1)")
            handle General.Size => ()
      in
        ()
      end
  end (* local *)

  (********************)

  local
    fun test (arg as (array, _, _)) expected =
        assertEqualElemList (A.update arg; A2L array) expected
    fun testError arg =
        (A.update arg; fail "A.update") handle General.Subscript => ()
  in
  fun update001 () =
      let
        val update00 = testError (L2A[], 0, n9)
        val update0m1 = testError (L2A[], ~1, n9)
        val update01 = testError (L2A[], 1, n9)
        val update10 = test (L2A[n1], 0, n9) [n9]
        val update11 = testError (L2A[n2], 1, n9)
        val update1m1 = testError (L2A[n2], ~1, n9)
        val update20 = test (L2A[n1, n2], 0, n9) [n9, n2]
        val update21 = test (L2A[n1, n2], 1, n9) [n1, n9]
        val update22 = testError (L2A[n1, n2], 2, n9)
      in
        ()
      end
  end (* local *)

  (********************)

  fun vector001 () =
      let
        val vector_0 = V2L(A.vector (L2A[]))
        val _ = assertEqualElemList [] vector_0
        val vector_1 = V2L(A.vector (L2A[n1]))
        val _ = assertEqualElemList [n1] vector_1
        val vector_2 = V2L(A.vector (L2A[n1, n2]))
        val _ = assertEqualElemList [n1, n2] vector_2
      in
        ()
      end

  (********************)

  local
    fun test (src, dst, di) (expected1, expected2) =
        let
          val src = L2A src
          val dst = L2A dst
          val () = A.copy {src = src, dst = dst, di = di}
          val _ = assertEqualElemList expected1 (A2L src)
          val _ = assertEqualElemList expected2 (A2L dst)
        in
          ()
        end
    fun testError (src, dst, di) =
        (A.copy {src = L2A src, dst = L2A dst, di = di}; fail "A.copy")
        handle General.Subscript => ()
  in
  fun copy001 () =
      let
        (* variation of length of src array *)
        val copy_0_3_0 = test ([], [n9, n8, n7], 0) ([], [n9, n8, n7])
        val copy_1_3_0 = test ([n1], [n9, n8, n7], 0) ([n1], [n1, n8, n7])
        val copy_2_3_0 = test ([n1, n2], [n9, n8, n7], 0) ([n1, n2], [n1, n2, n7])

        (* variation of length of dst array *)
        val copy_3_0_0 = testError ([n1, n2, n3], [], 0)
        val copy_3_1_0 = testError ([n1, n2, n3], [n9], 0)
        val copy_3_2_0 = testError ([n1, n2, n3], [n9, n8], 0)
        val copy_3_3_0 = test ([n1, n2, n3], [n9, n8, n7], 0) ([n1, n2, n3], [n1, n2, n3])
        val copy_3_4_0 = test ([n1, n2, n3], [n9, n8, n7, n6], 0) ([n1, n2, n3], [n1, n2, n3, n6])

        (* variation of di *)
        val copy_3_4_m1 = testError ([n1, n2, n3], [n9, n8, n7, n6], ~1)
        val copy_3_4_0 = test ([n1, n2, n3], [n9, n8, n7, n6], 0) ([n1, n2, n3], [n1, n2, n3, n6])
        val copy_3_4_1 = test ([n1, n2, n3], [n9, n8, n7, n6], 1) ([n1, n2, n3], [n9, n1, n2, n3])
        val copy_3_4_2 = testError ([n1, n2, n3], [n9, n8, n7, n6], 2)
      in
        ()
      end
  end (* local *)

  (********************)

  local
    fun test (src, dst, di) (expected1, expected2) =
        let
          val src = L2V src
          val dst = L2A dst
          val () = A.copyVec {src = src, dst = dst, di = di}
          val _ = assertEqualElemList expected1 (V2L src)
          val _ = assertEqualElemList expected2 (A2L dst)
        in
          ()
        end
    fun testError (src, dst, di) =
        (A.copyVec {src = L2V src, dst = L2A dst, di = di}; fail "A.copyVec")
        handle General.Subscript => ()
  in
  fun copyVec001 () =
      let
        (* variation of length of src array *)
        val copyVec_0_3_0 = test ([], [n9, n8, n7], 0) ([], [n9, n8, n7])
        val copyVec_1_3_0 = test ([n1], [n9, n8, n7], 0) ([n1], [n1, n8, n7])
        val copyVec_2_3_0 = test ([n1, n2], [n9, n8, n7], 0) ([n1, n2], [n1, n2, n7])

        (* variation of length of dst array *)
        val copyVec_3_0_0 = testError ([n1, n2, n3], [], 0)
        val copyVec_3_1_0 = testError ([n1, n2, n3], [n9], 0)
        val copyVec_3_2_0 = testError ([n1, n2, n3], [n9, n8], 0)
        val copyVec_3_3_0 = test ([n1, n2, n3], [n9, n8, n7], 0) ([n1, n2, n3], [n1, n2, n3])
        val copyVec_3_4_0 = test ([n1, n2, n3], [n9, n8, n7, n6], 0) ([n1, n2, n3], [n1, n2, n3, n6])

        (* variation of di *)
        val copyVec_3_4_m1 = testError ([n1, n2, n3], [n9, n8, n7, n6], ~1)
        val copyVec_3_4_0 = test ([n1, n2, n3], [n9, n8, n7, n6], 0) ([n1, n2, n3], [n1, n2, n3, n6])
        val copyVec_3_4_1 = test ([n1, n2, n3], [n9, n8, n7, n6], 1) ([n1, n2, n3], [n9, n1, n2, n3])
        val copyVec_3_4_2 = testError ([n1, n2, n3], [n9, n8, n7, n6], 2)
      in
        ()
      end
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
    fun test arg expected visited =
        let
          val (s, f) = makeStatei ()
          val array = L2A arg
          val () = A.modifyi f array
          val _ = assertEqualElemList expected (A2L array)
          val _ = assertEqualIntElemList visited (!s)
        in
          ()
        end
  in
  fun modifyi001 () =
      let
        val modifyi_0 = test [] [] []
        val modifyi_1 = test [n1] [n2] [(0, n1)]
        val modifyi_2 = test [n1, n2] [n2, n3] [(0, n1), (1, n2)]
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
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val array = L2A arg
          val () = A.modify f array
          val _ = assertEqualElemList expected (A2L array)
          val _ = assertEqualElemList visited (!s)
        in
          ()
        end
  in
  fun modify001 () =
      let
        val modify0 = test [] [] []
        val modify1 = test [n1] [n2] [n1]
        val modify2 = test [n1, n2] [n2, n3] [n1, n2]
        val modify3 = test [n1, n2, n3] [n2, n3, n4] [n1, n2, n3]
      in
        ()
      end
  end (* local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("array001", array001),
        ("array101", array101),
(*
        ("fromList001", fromList001),
        ("tabulate001", tabulate001),
        ("length001", length001),
        ("sub001", sub001),
*)
        ("update001", update001),
        ("vector001", vector001),
        ("copy001", copy001),
        ("copyVec001", copyVec001),
(*
        ("appi001", appi001),
        ("app001", app001),
*)
        ("modifyi001", modifyi001),
        ("modify001", modify001)
(*
        ("foldli001", foldli001),
        ("foldl001", foldl001),
        ("foldri001", foldri001),
        ("foldr001", foldr001),
        ("findi001", findi001),
        ("find001", find001),
        ("exists001", exists001),
        ("all001", all001),
        ("collate001", collate001)
*)
      ]

  (************************************************************)

end