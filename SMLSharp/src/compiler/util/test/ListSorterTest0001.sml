(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: ListSorterTest0001.sml,v 1.1 2005/12/14 09:38:29 kiyoshiy Exp $
 *)
structure ListSorterTest0001 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure Testee = ListSorter

  (***************************************************************************)

  fun intListToString list =
      List.foldr
          (fn (value, string) => Int.toString value ^ string)
          ""
          list
  fun testSort expected lists =
      List.app
          (fn list =>
              (
                Assert.assertEqualString
                    (intListToString expected)
                    (intListToString(ListSorter.sort Int.compare list));
                ()
              ))
          lists

  (****************************************)

  val TESTSORT0000_EXPECTED = []
  val TESTSORT0000_SORTEE = [[]]

  fun testSort0000() =
      testSort TESTSORT0000_EXPECTED TESTSORT0000_SORTEE

  (****************************************)

  val TESTSORT0010_EXPECTED = [1]
  val TESTSORT0010_SORTEE = [[1]]

  fun testSort0010() =
      testSort TESTSORT0010_EXPECTED TESTSORT0010_SORTEE

  (****************************************)

  val TESTSORT0020_EXPECTED = [1, 2]
  val TESTSORT0020_SORTEE = [[1, 2], [2, 1]]

  fun testSort0020() =
      testSort TESTSORT0020_EXPECTED TESTSORT0020_SORTEE

  (****************************************)

  val TESTSORT0030_EXPECTED = [1, 2, 3]
  val TESTSORT0030_SORTEE =
      [[1, 2, 3], [1, 3, 2], [2, 3, 1], [2, 1, 3], [3, 1, 2], [3, 2, 1]]

  fun testSort0030() =
      testSort TESTSORT0030_EXPECTED TESTSORT0030_SORTEE

  (****************************************)

  val TESTSORT0031_EXPECTED = [1, 1, 2]
  val TESTSORT0031_SORTEE = [[1, 1, 2], [1, 2, 1], [2, 1, 1]]

  fun testSort0031() =
      testSort TESTSORT0031_EXPECTED TESTSORT0031_SORTEE

  (****************************************)

  val TESTSORT0032_EXPECTED = [1, 1, 1]
  val TESTSORT0032_SORTEE = [[1, 1, 1]]

  fun testSort0032() =
      testSort TESTSORT0032_EXPECTED TESTSORT0032_SORTEE

  (****************************************)

  val TESTSORT0040_EXPECTED = [1, 2, 3, 4]
  val TESTSORT0040_SORTEE =
      [
        [1, 2, 3, 4], [1, 2, 4, 3],
        [1, 3, 2, 4], [1, 3, 4, 2],
        [1, 4, 2, 3], [1, 4, 3, 2],
        [2, 1, 3, 4], [2, 1, 4, 3],
        [2, 3, 1, 4], [2, 3, 4, 1],
        [2, 4, 1, 3], [2, 4, 3, 1],
        [3, 1, 2, 4], [3, 1, 4, 2],
        [3, 2, 1, 4], [3, 2, 4, 1],
        [3, 4, 1, 2], [3, 4, 2, 1],
        [4, 1, 2, 3], [4, 1, 3, 2],
        [4, 2, 1, 3], [4, 2, 3, 1],
        [4, 3, 1, 2], [4, 3, 2, 1]
      ]

  fun testSort0040() =
      testSort TESTSORT0040_EXPECTED TESTSORT0040_SORTEE

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testSort0000", testSort0000),
        ("testSort0010", testSort0010),
        ("testSort0020", testSort0020),
        ("testSort0030", testSort0030),
        ("testSort0031", testSort0031),
        ("testSort0032", testSort0032),
        ("testSort0040", testSort0040)
      ]

  (***************************************************************************)

end
