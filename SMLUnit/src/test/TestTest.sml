(**
 * Unit test for SMLUnit.Test
 *
 *  These test cases assume that Unit-tests of the SMLUnit.Assert has been
 * completed.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure TestTest =
struct

  (***************************************************************************)

  structure Test = SMLUnit.Test
  structure Assert = SMLUnit.Assert

  (***************************************************************************)

  exception TestFail

  (***************************************************************************)

  (**
   * custom assertion for the Test.test type
   *)
  fun assertEqualTest (Test.TestLabel pair1) (Test.TestLabel pair2) =
      Assert.assertEqual2Tuple
       (Assert.assertEqualString,assertEqualTest)
       pair1
       pair2
    | assertEqualTest (Test.TestList list1) (Test.TestList list2) =
      Assert.assertEqualList assertEqualTest list1 list2
    | assertEqualTest (Test.TestCase _) (case2 as Test.TestCase _) =
      (*
        We cannot define equality relation on functions.
        Any assertion on functions will success.
      *)
      ()
    | assertEqualTest _ _ = raise Fail "not equal"

  (******************************************)

  (**
   * Test case for labelTests: normal case
   *)
  fun testLabelTests0001 () =
      let
        val arg = []
        val expected = Test.TestList []
      in
        assertEqualTest expected (Test.labelTests arg)
      end

  fun testLabelTests0002 () =
      let
        fun test0002 () = ()
        val arg = [ ("test0002", test0002) ]
        val expected =
            Test.TestList
            [ Test.TestLabel ("test0002", Test.TestCase test0002) ]
      in
        assertEqualTest expected (Test.labelTests arg)
      end

  fun testLabelTests0003 () =
      let
        fun test0003_1 () = ()
        fun test0003_2 () = ()
        val arg = [ ("test0003_1", test0003_1), ("test0003_2", test0003_2) ]
        val expected =
            Test.TestList
            [
              Test.TestLabel ("test0003_1", Test.TestCase test0003_1),
              Test.TestLabel ("test0003_2", Test.TestCase test0003_2)
            ]
      in
        assertEqualTest expected (Test.labelTests arg)
      end

  fun testLabelTests0004 () =
      let
        fun test0004 () = ()
        (* Duplicate entry *)
        val arg = [ ("test0004", test0004), ("test0004", test0004) ]
        val expected =
            Test.TestList
            [
              Test.TestLabel ("test0004", Test.TestCase test0004),
              Test.TestLabel ("test0004", Test.TestCase test0004)
            ]
      in
        assertEqualTest expected (Test.labelTests arg)
      end

  (******************************************)

  (**
   * perform tests
   *
   *  We cannot use the SMLUnit.Test to group test cases because we are testing
   * that structure.
   *)
  fun runTest () =
      let
        val tests =
            [
              ("testLabelTests0001", testLabelTests0001),
              ("testLabelTests0002", testLabelTests0002),
              ("testLabelTests0003", testLabelTests0003),
              ("testLabelTests0004", testLabelTests0004)
            ]
        val failCases =
            foldl
            (fn ((testName, testCase), failCases) =>
                ((testCase (); print "."; failCases)
                 handle TestFail => (print "F"; testName :: failCases)
                      | exn => (print "E"; testName :: failCases)))
            []
            tests
      in
        print "\n";
        app (fn testName => (print testName; print "\n")) (List.rev failCases);
        print "\n"
      end

end;

