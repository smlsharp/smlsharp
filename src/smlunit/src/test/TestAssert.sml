(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure TestAssert =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert

  (***************************************************************************)

  exception TestFail

  (***************************************************************************)

  local
    fun testSuccess value1 value2 =
        Assert.assertEqualAlternatives Assert.assertEqualInt value1 value2
    fun testFailure value1 value2 =
        (Assert.assertEqualAlternatives Assert.assertEqualInt value1 value2;
        raise TestFail)
        handle Assert.Fail _ => ()
  in

  fun testAssertEqualAlternatives0000 () = testFailure [] 1
  fun testAssertEqualAlternatives0010 () = testFailure [2] 1
  fun testAssertEqualAlternatives0011 () = testSuccess [1] 1
  fun testAssertEqualAlternatives0020 () = testFailure [2, 3] 1
  fun testAssertEqualAlternatives0021 () = testSuccess [1, 3] 1
  fun testAssertEqualAlternatives0022 () = testSuccess [2, 1] 1
  fun testAssertEqualAlternatives0030 () = testFailure [2, 3, 4] 1
  fun testAssertEqualAlternatives0031 () = testSuccess [1, 3, 4] 1
  fun testAssertEqualAlternatives0032 () = testSuccess [2, 1, 4] 1
  fun testAssertEqualAlternatives0034 () = testSuccess [2, 3, 1] 1

  end (* local *)

  fun testFail0001 () =
      let
        val message = "message"
      in
        (Assert.fail message;
         raise TestFail)
        handle Assert.Fail (Assert.GeneralFailure failMessage) =>
               if failMessage = message then () else raise TestFail
      end

  (****************************************)

  fun testAssertEqualUnit0001 () =
      let
        val value = ()
      in
        (if Assert.assertEqualUnit value value = value
         then ()
         else raise TestFail)
        handle Assert.Fail message => raise TestFail
      end

  (****************************************)

  fun testAssertEqualInt0001 () =
      let
        val value = 100
      in
        (Assert.assertEqualInt value value)
        handle Assert.Fail message => raise TestFail
      end

  fun testAssertEqualInt0002 () =
      let
        val value1 = 100
        val value2 = 200
      in
        (Assert.assertEqualInt value1 value2;raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
      end

  (****************************************)

  fun testAssertEqualWord0001 () =
      let
        val value = Word.fromInt 100
      in
        (Assert.assertEqualWord value value)
        handle Assert.Fail message => raise TestFail
      end

  fun testAssertEqualWord0002 () =
      let
        val value1 = Word.fromInt 100
        val value2 = Word.fromInt 200
      in
        (Assert.assertEqualWord value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
      end

  (****************************************)

  fun testAssertEqualWord80001 () =
      let
        val value = Word8.fromInt 100
      in
        (Assert.assertEqualWord8 value value)
        handle Assert.Fail message => raise TestFail
      end

  fun testAssertEqualWord80002 () =
      let
        val value1 = Word8.fromInt 100
        val value2 = Word8.fromInt 200
      in
        (Assert.assertEqualWord8 value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
      end

  (****************************************)

  fun testAssertEqualWord320001 () =
      let
        val value = Word32.fromInt 100
      in
        (Assert.assertEqualWord32 value value)
        handle Assert.Fail message => raise TestFail
      end

  fun testAssertEqualWord320002 () =
      let
        val value1 = Word32.fromInt 100
        val value2 = Word32.fromInt 200
      in
        (Assert.assertEqualWord32 value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
      end

  (****************************************)

  fun testAssertEqualReal0001 () =
      let
        val value = 1.234
      in
        (Assert.assertEqualReal value value)
        handle Assert.Fail message => raise TestFail
      end

  fun testAssertEqualReal0002 () =
      let
        val value1 = 1.234
        val value2 = 5.678
      in
        (Assert.assertEqualReal value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
      end

  (****************************************)

  fun testAssertEqualChar0001 () =
      let
        val value = #"a"
      in
        (Assert.assertEqualChar value value)
        handle Assert.Fail message => raise TestFail
      end

  fun testAssertEqualChar0002 () =
      let
        val value1 = #"b"
        val value2 = #"c"
      in
        (Assert.assertEqualChar value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
      end

  (****************************************)

  fun testAssertEqualString0001 () =
      let
        val value = "a"
      in
        (Assert.assertEqualString value value)
        handle Assert.Fail message => raise TestFail
      end

  fun testAssertEqualString0002 () =
      let
        val value = ""
      in
        (Assert.assertEqualString value value)
        handle Assert.Fail message => raise TestFail
      end

  fun testAssertEqualString0003 () =
      let
        val value = "abcdefghijklmnopqrstuvwxyz "
      in
        (Assert.assertEqualString value value)
        handle Assert.Fail message => raise TestFail
      end

  fun testAssertEqualString0004 () =
      let
        val value1 = "b"
        val value2 = "c"
      in
        (Assert.assertEqualString value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
      end

  fun testAssertEqualString0005 () =
      let
        val value1 = ""
        val value2 = "c"
      in
        (Assert.assertEqualString value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
      end

  fun testAssertEqualString0006 () =
      let
        val value1 = "c"
        val value2 = ""
      in
        (Assert.assertEqualString value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
      end

  (****************************************)

  fun testAssertEqualSubstring0001 () =
      let
        val value = Substring.full "a"
      in
        (Assert.assertEqualSubstring value value)
        handle Assert.Fail message => raise TestFail
      end

  fun testAssertEqualSubstring0002 () =
      let
        val value = Substring.full ""
      in
        (Assert.assertEqualSubstring value value)
        handle Assert.Fail message => raise TestFail
      end

  fun testAssertEqualSubstring0003 () =
      let
        val value = Substring.full "abcdefghijklmnopqrstuvwxyz "
      in
        (Assert.assertEqualSubstring value value)
        handle Assert.Fail message => raise TestFail
      end

  fun testAssertEqualSubstring0004 () =
      let
        val value1 = Substring.full "b"
        val value2 = Substring.full "c"
      in
        (Assert.assertEqualSubstring value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
      end

  fun testAssertEqualSubstring0005 () =
      let
        val value1 = Substring.full ""
        val value2 = Substring.full "c"
      in
        (Assert.assertEqualSubstring value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
      end

  fun testAssertEqualSubstring0006 () =
      let
        val value1 = Substring.full "c"
        val value2 = Substring.full ""
      in
        (Assert.assertEqualSubstring value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
      end

  (****************************************)

  exception TestException of string

  fun testEqualExceptionName0001 () =
      let
        val message = "test"
        val value = TestException message
      in
        Assert.assertEqualExceptionName value value
      end

  fun testEqualExceptionName0002 () =
      let
        val message1 = "test1"
        val message2 = "test2"
        val value1 = TestException message1
        val value2 = TestException message2
      in
        Assert.assertEqualExceptionName value1 value2
      end

  fun testEqualExceptionName0003 () =
      let
        exception OtherException of string
        val message = "test"
        val value1 = TestException message
        val value2 = OtherException message
      in
        (Assert.assertEqualExceptionName value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
      end

  (****************************************)

(*
  fun testEqualExceptionMessage0001 () =
      let
        val message = "test"
        val value = TestException message
      in
        case Assert.assertEqualExceptionMessage value value
         of TestException errorMessage =>
            if message = errorMessage then () else raise TestFail
          | _ => raise TestFail
      end

  fun testEqualExceptionMessage0002 () =
      let
        val message1 = "test1"
        val message2 = "test2"
        val value1 = TestException message1
        val value2 = TestException message2
(*        val value2 = Fail message2
        val value2 = Fail message2 *)
      in
        (Assert.assertEqualExceptionMessage value1 value2; raise TestFail)
        handle Assert.Fail _ => ()
      end

  fun testEqualExceptionMessage0003 () =
      let
        exception OtherException of string
        val message = "test"
        val value1 = TestException message
        val value2 = OtherException message
      in
        (Assert.assertEqualExceptionMessage value1 value2; raise TestFail)
        handle Assert.Fail _ => ()
      end
*)

  (****************************************)

  fun testAssertEqualRef0001 () =
      let
        val value = ref 1
      in
        Assert.assertEqualRef Assert.assertEqualInt value value
      end

  fun testAssertEqualRef0002 () =
      let
        (*
         * Although value1 and value2 point different locations,
         * the assertion succeeds because these locations hold the equal value.
         *)
        val value1 = ref 1
        val value2 = ref 1
      in
        Assert.assertEqualRef Assert.assertEqualInt value1 value2
      end

  fun testAssertEqualRef0003 () =
      let
        val value1 = ref 1
        val value2 = ref 2
      in
        (
          Assert.assertEqualRef Assert.assertEqualInt value1 value2;
          raise TestFail
        )
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  (****************************************)

  fun testAssertSameRef0001 () =
      let
        val value = ref 1
      in
        Assert.assertSameRef value value
      end

  fun testAssertSameRef0002 () =
      let
        (*
         * The assertion fails because value1 and value2 point different
         * locations, although these locations hold the equal value.
         *)
        val value1 = ref 1
        val value2 = ref 1
      in
        (Assert.assertSameRef value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertSameRef0003 () =
      let
        val value1 = ref 1
        val value2 = ref 2
      in
        (Assert.assertSameRef value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  (****************************************)

  fun testAssertEqualBool0001 () =
      let
        val value = true
      in
        Assert.assertEqualBool value value
      end

  fun testAssertEqualBool0002 () =
      let
        val value = false
      in
        Assert.assertEqualBool value value
      end

  fun testAssertEqualBool0003 () =
      let
        val value1 = true
        val value2 = false
      in
        (Assert.assertEqualBool value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqualBool0004 () =
      let
        val value1 = false
        val value2 = true
      in
        (Assert.assertEqualBool value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  (****************************************)

  fun testAssertTrue0001 () =
      let
        val value = true
      in
        Assert.assertTrue value
      end

  fun testAssertTrue0002 () =
      let
        val value = false
      in
        (Assert.assertTrue value; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  (****************************************)

  fun testAssertFalse0001 () =
      let
        val value = false
      in
        Assert.assertFalse value
      end

  fun testAssertFalse0002 () =
      let
        val value = true
      in
        (Assert.assertFalse value; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  (****************************************)

  fun testAssertEqualOption0001 () =
      let
        val value = SOME 1
      in
        Assert.assertEqualOption Assert.assertEqualInt value value
      end

  fun testAssertEqualOption0002 () =
      let
        val value = NONE
      in
        Assert.assertEqualOption Assert.assertEqualInt value value
      end

  fun testAssertEqualOption0003 () =
      let
        val value1 = SOME 1
        val value2 = NONE
      in
        (
          Assert.assertEqualOption Assert.assertEqualInt value1 value2;
          raise TestFail
        )
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqualOption0004 () =
      let
          val value1 = NONE
          val value2 = SOME 1
      in
        (
          Assert.assertEqualOption Assert.assertEqualInt value1 value2;
          raise TestFail
        )
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  (****************************************)

  fun testAssertSome0001 () =
      let
        val value = SOME 1
      in
        Assert.assertSome value
      end

  fun testAssertSome0002 () =
      let
        val value = NONE
      in
        (Assert.assertSome value; raise TestFail)
        handle Assert.Fail _ => ()
             | _ => raise TestFail
      end

  (****************************************)

  fun testAssertNone0001 () =
      let
        val value = NONE
      in
        Assert.assertNone value
      end

  fun testAssertNone0002 () =
      let
        val value = SOME 1
      in
        (Assert.assertNone value; raise TestFail)
        handle Assert.Fail _ => ()
             | _ => raise TestFail
      end

  (****************************************)

  fun testAssertEqualOrderLL () =
      let
        val value1 = LESS
        val value2 = LESS
      in
        Assert.assertEqualOrder value1 value2
      end

  fun testAssertEqualOrderLE () =
      let
        val value1 = LESS
        val value2 = EQUAL
      in
        (Assert.assertEqualOrder value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqualOrderLG () =
      let
        val value1 = LESS
        val value2 = GREATER
      in
        (Assert.assertEqualOrder value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqualOrderEL () =
      let
        val value1 = EQUAL
        val value2 = LESS
      in
        (Assert.assertEqualOrder value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqualOrderEE () =
      let
        val value1 = EQUAL
        val value2 = EQUAL
      in
        Assert.assertEqualOrder value1 value2
      end

  fun testAssertEqualOrderEG () =
      let
        val value1 = EQUAL
        val value2 = GREATER
      in
        (Assert.assertEqualOrder value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqualOrderGL () =
      let
        val value1 = GREATER
        val value2 = LESS
      in
        (Assert.assertEqualOrder value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqualOrderGE () =
      let
        val value1 = GREATER
        val value2 = EQUAL
      in
        (Assert.assertEqualOrder value1 value2; raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqualOrderGG () =
      let
        val value1 = GREATER
        val value2 = GREATER
      in
        Assert.assertEqualOrder value1 value2
      end

  (****************************************)

  fun testAssertEqual2Tuple0001 () =
      let
        val value1 = (1, true)
        val value2 = (1, true)
      in
          Assert.assertEqual2Tuple
          (Assert.assertEqualInt, Assert.assertEqualBool)
          value1
          value2
      end

  fun testAssertEqual2Tuple0002 () =
      let
        val value1 = (1, true)
        val value2 = (2, true)
      in
        (Assert.assertEqual2Tuple
         (Assert.assertEqualInt, Assert.assertEqualBool)
         value1
         value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqual2Tuple0003 () =
      let
        val value1 = (1, true)
        val value2 = (1, false)
      in
        (Assert.assertEqual2Tuple
         (Assert.assertEqualInt, Assert.assertEqualBool)
         value1
         value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  (****************************************)

  fun testAssertEqual3Tuple0001 () =
      let
        val value1 = (1, true, "foo")
        val value2 = (1, true, "foo")
      in
          Assert.assertEqual3Tuple
          (
            Assert.assertEqualInt,
            Assert.assertEqualBool,
            Assert.assertEqualString
          )
          value1
          value2
      end

  fun testAssertEqual3Tuple0002 () =
      let
        val value1 = (1, true, "foo")
        val value2 = (2, true, "foo")
      in
        (Assert.assertEqual3Tuple
         (
           Assert.assertEqualInt,
           Assert.assertEqualBool,
           Assert.assertEqualString
         )
         value1
         value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqual3Tuple0003 () =
      let
        val value1 = (1, true, "foo")
        val value2 = (1, false, "foo")
      in
        (Assert.assertEqual3Tuple
         (
           Assert.assertEqualInt,
           Assert.assertEqualBool,
           Assert.assertEqualString
         )
         value1
         value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqual3Tuple0004 () =
      let
        val value1 = (1, true, "foo")
        val value2 = (1, true, "bar")
      in
        (Assert.assertEqual3Tuple
         (
           Assert.assertEqualInt,
           Assert.assertEqualBool,
           Assert.assertEqualString
         )
         value1
         value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  (****************************************)

  fun testAssertEqual4Tuple0001 () =
      let
        val value1 = (1, true, "foo", 0w1)
        val value2 = (1, true, "foo", 0w1)
      in
          Assert.assertEqual4Tuple
          (
            Assert.assertEqualInt,
            Assert.assertEqualBool,
            Assert.assertEqualString,
            Assert.assertEqualWord
          )
          value1
          value2
      end

  fun testAssertEqual4Tuple0002 () =
      let
        val value1 = (1, true, "foo", 0w1)
        val value2 = (2, true, "foo", 0w1)
      in
        (Assert.assertEqual4Tuple
         (
           Assert.assertEqualInt,
           Assert.assertEqualBool,
           Assert.assertEqualString,
           Assert.assertEqualWord
         )
         value1
         value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqual4Tuple0003 () =
      let
        val value1 = (1, true, "foo", 0w1)
        val value2 = (1, false, "foo", 0w1)
      in
        (Assert.assertEqual4Tuple
         (
           Assert.assertEqualInt,
           Assert.assertEqualBool,
           Assert.assertEqualString,
           Assert.assertEqualWord
         )
         value1
         value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqual4Tuple0004 () =
      let
        val value1 = (1, true, "foo", 0w1)
        val value2 = (1, true, "bar", 0w1)
      in
        (Assert.assertEqual4Tuple
         (
           Assert.assertEqualInt,
           Assert.assertEqualBool,
           Assert.assertEqualString,
           Assert.assertEqualWord
         )
         value1
         value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqual4Tuple0005 () =
      let
        val value1 = (1, true, "foo", 0w1)
        val value2 = (1, true, "foo", 0w2)
      in
        (Assert.assertEqual4Tuple
         (
           Assert.assertEqualInt,
           Assert.assertEqualBool,
           Assert.assertEqualString,
           Assert.assertEqualWord
         )
         value1
         value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  (****************************************)

  fun testAssertEqual5Tuple0001 () =
      let
        val value1 = (1, true, "foo", 0w1, #"a")
        val value2 = (1, true, "foo", 0w1, #"a")
      in
          Assert.assertEqual5Tuple
          (
            Assert.assertEqualInt,
            Assert.assertEqualBool,
            Assert.assertEqualString,
            Assert.assertEqualWord,
            Assert.assertEqualChar
          )
          value1
          value2
      end

  fun testAssertEqual5Tuple0002 () =
      let
        val value1 = (1, true, "foo", 0w1, #"a")
        val value2 = (2, true, "foo", 0w1, #"a")
      in
        (Assert.assertEqual5Tuple
         (
           Assert.assertEqualInt,
           Assert.assertEqualBool,
           Assert.assertEqualString,
           Assert.assertEqualWord,
           Assert.assertEqualChar
         )
         value1
         value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqual5Tuple0003 () =
      let
        val value1 = (1, true, "foo", 0w1, #"a")
        val value2 = (1, false, "foo", 0w1, #"a")
      in
        (Assert.assertEqual5Tuple
         (
           Assert.assertEqualInt,
           Assert.assertEqualBool,
           Assert.assertEqualString,
           Assert.assertEqualWord,
           Assert.assertEqualChar
         )
         value1
         value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqual5Tuple0004 () =
      let
        val value1 = (1, true, "foo", 0w1, #"a")
        val value2 = (1, true, "bar", 0w1, #"a")
      in
        (Assert.assertEqual5Tuple
         (
           Assert.assertEqualInt,
           Assert.assertEqualBool,
           Assert.assertEqualString,
           Assert.assertEqualWord,
           Assert.assertEqualChar
         )
         value1
         value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqual5Tuple0005 () =
      let
        val value1 = (1, true, "foo", 0w1, #"a")
        val value2 = (1, true, "foo", 0w2, #"a")
      in
        (Assert.assertEqual5Tuple
         (
           Assert.assertEqualInt,
           Assert.assertEqualBool,
           Assert.assertEqualString,
           Assert.assertEqualWord,
           Assert.assertEqualChar
         )
         value1
         value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  fun testAssertEqual5Tuple0006 () =
      let
        val value1 = (1, true, "foo", 0w1, #"a")
        val value2 = (1, true, "foo", 0w1, #"b")
      in
        (Assert.assertEqual5Tuple
         (
           Assert.assertEqualInt,
           Assert.assertEqualBool,
           Assert.assertEqualString,
           Assert.assertEqualWord,
           Assert.assertEqualChar
         )
         value1
         value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => ()
             | _ => raise TestFail
      end

  (****************************************)

  fun testAssertEqualVector0001 () =
      let
        val list1 = []
        val value1 = Vector.fromList list1
        val value2 = Vector.fromList list1
      in
        Assert.assertEqualVector Assert.assertEqualInt value1 value2
      end

  fun testAssertEqualVector0002 () =
      let
        val list1 = [1]
        val value1 = Vector.fromList list1
        val value2 = Vector.fromList list1
      in
        Assert.assertEqualVector Assert.assertEqualInt value1 value2
      end

  fun testAssertEqualVector0003 () =
      let
        val list1 = [1, 2]
        val value1 = Vector.fromList list1
        val value2 = Vector.fromList list1
      in
        Assert.assertEqualVector Assert.assertEqualInt value1 value2
      end

  fun testAssertEqualVector0004 () =
      let
        val list1 = [1, 2, 3]
        val value1 = Vector.fromList list1
        val value2 = Vector.fromList list1
      in
        Assert.assertEqualVector Assert.assertEqualInt value1 value2
      end

  (*
   0 - 1
  *)
  fun testAssertEqualVector1000 () =
      let
        val value1 = Vector.fromList []
        val value2 = Vector.fromList [1]
      in
        (Assert.assertEqualVector Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   1 - 0
  *)
  fun testAssertEqualVector1001 () =
      let
        val value1 = Vector.fromList [1]
        val value2 = Vector.fromList []
      in
        (Assert.assertEqualVector Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   1 - 1
  *)
  fun testAssertEqualVector1002 () =
      let
        val value1 = Vector.fromList [2]
        val value2 = Vector.fromList [3]
      in
        (Assert.assertEqualVector Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   1 - 2
  *)
  fun testAssertEqualVector1003 () =
      let
        val value1 = Vector.fromList [2]
        val value2 = Vector.fromList [2, 3]
      in
        (Assert.assertEqualVector Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   2 - 0
  *)
  fun testAssertEqualVector1004 () =
      let
        val value1 = Vector.fromList [1, 2]
        val value2 = Vector.fromList []
      in
        (Assert.assertEqualVector Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   2 - 1
  *)
  fun testAssertEqualVector1005 () =
      let
        val value1 = Vector.fromList [1, 2]
        val value2 = Vector.fromList [1]
      in
        (Assert.assertEqualVector Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   2 - 2
  *)
  fun testAssertEqualVector1006 () =
      let
        val value1 = Vector.fromList [1, 2]
        val value2 = Vector.fromList [1, 3]
      in
        (Assert.assertEqualVector Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   2 - 3
  *)
  fun testAssertEqualVector1007 () =
      let
        val value1 = Vector.fromList [1, 2]
        val value2 = Vector.fromList [1, 2, 3]
      in
        (Assert.assertEqualVector Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   3 - 0
  *)
  fun testAssertEqualVector1008 () =
      let
        val value1 = Vector.fromList [1, 2, 3]
        val value2 = Vector.fromList []
      in
        (Assert.assertEqualVector Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   3 - 1
  *)
  fun testAssertEqualVector1009 () =
      let
        val value1 = Vector.fromList [1, 2, 3]
        val value2 = Vector.fromList [1]
      in
        (Assert.assertEqualVector Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   3 - 2
  *)
  fun testAssertEqualVector1010 () =
      let
        val value1 = Vector.fromList [1, 2, 3]
        val value2 = Vector.fromList [1, 2]
      in
        (Assert.assertEqualVector Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   3 - 3
  *)
  fun testAssertEqualVector1011 () =
      let
        val value1 = Vector.fromList [1, 2, 3]
        val value2 = Vector.fromList [1, 2, 4]
      in
        (Assert.assertEqualVector Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   3 - 4
  *)
  fun testAssertEqualVector1012 () =
      let
        val value1 = Vector.fromList [1, 2, 3]
        val value2 = Vector.fromList [1, 2, 3, 4]
      in
        (Assert.assertEqualVector Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (****************************************)

  fun testAssertEqualArray0001 () =
      let
        val list1 = []
        val value1 = Array.fromList list1
        val value2 = Array.fromList list1
      in
        Assert.assertEqualArray Assert.assertEqualInt value1 value2
      end

  fun testAssertEqualArray0002 () =
      let
        val list1 = [1]
        val value1 = Array.fromList list1
        val value2 = Array.fromList list1
      in
        Assert.assertEqualArray Assert.assertEqualInt value1 value2
      end

  fun testAssertEqualArray0003 () =
      let
        val list1 = [1, 2]
        val value1 = Array.fromList list1
        val value2 = Array.fromList list1
      in
        Assert.assertEqualArray Assert.assertEqualInt value1 value2
      end

  fun testAssertEqualArray0004 () =
      let
        val list1 = [1, 2, 3]
        val value1 = Array.fromList list1
        val value2 = Array.fromList list1
      in
        Assert.assertEqualArray Assert.assertEqualInt value1 value2
      end

  (*
   0 - 1
  *)
  fun testAssertEqualArray1000 () =
      let
        val value1 = Array.fromList []
        val value2 = Array.fromList [1]
      in
        (Assert.assertEqualArray Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   1 - 0
  *)
  fun testAssertEqualArray1001 () =
      let
        val value1 = Array.fromList [1]
        val value2 = Array.fromList []
      in
        (Assert.assertEqualArray Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   1 - 1
  *)
  fun testAssertEqualArray1002 () =
      let
        val value1 = Array.fromList [2]
        val value2 = Array.fromList [3]
      in
        (Assert.assertEqualArray Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   1 - 2
  *)
  fun testAssertEqualArray1003 () =
      let
        val value1 = Array.fromList [2]
        val value2 = Array.fromList [2, 3]
      in
        (Assert.assertEqualArray Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   2 - 0
  *)
  fun testAssertEqualArray1004 () =
      let
        val value1 = Array.fromList [1, 2]
        val value2 = Array.fromList []
      in
        (Assert.assertEqualArray Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   2 - 1
  *)
  fun testAssertEqualArray1005 () =
      let
        val value1 = Array.fromList [1, 2]
        val value2 = Array.fromList [1]
      in
        (Assert.assertEqualArray Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   2 - 2
  *)
  fun testAssertEqualArray1006 () =
      let
        val value1 = Array.fromList [1, 2]
        val value2 = Array.fromList [1, 3]
      in
        (Assert.assertEqualArray Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   2 - 3
  *)
  fun testAssertEqualArray1007 () =
      let
        val value1 = Array.fromList [1, 2]
        val value2 = Array.fromList [1, 2, 3]
      in
        (Assert.assertEqualArray Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   3 - 0
  *)
  fun testAssertEqualArray1008 () =
      let
        val value1 = Array.fromList [1, 2, 3]
        val value2 = Array.fromList []
      in
        (Assert.assertEqualArray Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   3 - 1
  *)
  fun testAssertEqualArray1009 () =
      let
        val value1 = Array.fromList [1, 2, 3]
        val value2 = Array.fromList [1]
      in
        (Assert.assertEqualArray Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   3 - 2
  *)
  fun testAssertEqualArray1010 () =
      let
        val value1 = Array.fromList [1, 2, 3]
        val value2 = Array.fromList [1, 2]
      in
        (Assert.assertEqualArray Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   3 - 3
  *)
  fun testAssertEqualArray1011 () =
      let
        val value1 = Array.fromList [1, 2, 3]
        val value2 = Array.fromList [1, 2, 4]
      in
        (Assert.assertEqualArray Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   3 - 4
  *)
  fun testAssertEqualArray1012 () =
      let
        val value1 = Array.fromList [1, 2, 3]
        val value2 = Array.fromList [1, 2, 3, 4]
      in
        (Assert.assertEqualArray Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (****************************************)

  fun testAssertEqualList0001 () =
      let
        val list1 = []
        val value1 = list1
        val value2 = list1
      in
        Assert.assertEqualList Assert.assertEqualInt value1 value2
      end

  fun testAssertEqualList0002 () =
      let
        val list1 = [1]
        val value1 = list1
        val value2 = list1
      in
        Assert.assertEqualList Assert.assertEqualInt value1 value2
      end

  fun testAssertEqualList0003 () =
      let
        val list1 = [1, 2]
        val value1 = list1
        val value2 = list1
      in
        Assert.assertEqualList Assert.assertEqualInt value1 value2
      end

  fun testAssertEqualList0004 () =
      let
        val list1 = [1, 2, 3]
        val value1 = list1
        val value2 = list1
      in
        Assert.assertEqualList Assert.assertEqualInt value1 value2
      end

  (*
   0 - 1
  *)
  fun testAssertEqualList1000 () =
      let
        val value1 = []
        val value2 = [1]
      in
        (Assert.assertEqualList Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   1 - 0
  *)
  fun testAssertEqualList1001 () =
      let
        val value1 = [1]
        val value2 = []
      in
        (Assert.assertEqualList Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   1 - 1
  *)
  fun testAssertEqualList1002 () =
      let
        val value1 = [2]
        val value2 = [3]
      in
        (Assert.assertEqualList Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   1 - 2
  *)
  fun testAssertEqualList1003 () =
      let
        val value1 = [2]
        val value2 = [2, 3]
      in
        (Assert.assertEqualList Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   2 - 0
  *)
  fun testAssertEqualList1004 () =
      let
        val value1 = [1, 2]
        val value2 = []
      in
        (Assert.assertEqualList Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   2 - 1
  *)
  fun testAssertEqualList1005 () =
      let
        val value1 = [1, 2]
        val value2 = [1]
      in
        (Assert.assertEqualList Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   2 - 2
  *)
  fun testAssertEqualList1006 () =
      let
        val value1 = [1, 2]
        val value2 = [1, 3]
      in
        (Assert.assertEqualList Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   2 - 3
  *)
  fun testAssertEqualList1007 () =
      let
        val value1 = [1, 2]
        val value2 = [1, 2, 3]
      in
        (Assert.assertEqualList Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   3 - 0
  *)
  fun testAssertEqualList1008 () =
      let
        val value1 = [1, 2, 3]
        val value2 = []
      in
        (Assert.assertEqualList Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   3 - 1
  *)
  fun testAssertEqualList1009 () =
      let
        val value1 = [1, 2, 3]
        val value2 = [1]
      in
        (Assert.assertEqualList Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   3 - 2
  *)
  fun testAssertEqualList1010 () =
      let
        val value1 = [1, 2, 3]
        val value2 = [1, 2]
      in
        (Assert.assertEqualList Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   3 - 3
  *)
  fun testAssertEqualList1011 () =
      let
        val value1 = [1, 2, 3]
        val value2 = [1, 2, 4]
      in
        (Assert.assertEqualList Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (*
   3 - 4
  *)
  fun testAssertEqualList1012 () =
      let
        val value1 = [1, 2, 3]
        val value2 = [1, 2, 3, 4]
      in
        (Assert.assertEqualList Assert.assertEqualInt value1 value2;
         raise TestFail)
        handle Assert.Fail (Assert.NotEqualFailure _) => () | _ => raise TestFail
      end

  (***************************************************************************)

  (**
   * performs tests
   *)
  fun runTest () =
      let
        val tests =
            [
               ("testAssertEqualAlternatives0000", testAssertEqualAlternatives0000),
               ("testAssertEqualAlternatives0010", testAssertEqualAlternatives0010),
               ("testAssertEqualAlternatives0011", testAssertEqualAlternatives0011),
               ("testAssertEqualAlternatives0020", testAssertEqualAlternatives0020),
               ("testAssertEqualAlternatives0021", testAssertEqualAlternatives0021),
               ("testAssertEqualAlternatives0022", testAssertEqualAlternatives0022),
               ("testAssertEqualAlternatives0030", testAssertEqualAlternatives0030),
               ("testAssertEqualAlternatives0031", testAssertEqualAlternatives0031),
               ("testAssertEqualAlternatives0032", testAssertEqualAlternatives0032),
               ("testAssertEqualAlternatives0034", testAssertEqualAlternatives0034),

               ("testFail0001", testFail0001),
               ("testAssertEqualUnit0001", testAssertEqualUnit0001),
               ("testAssertEqualInt0001", testAssertEqualInt0001),
               ("testAssertEqualInt0002", testAssertEqualInt0002),
               ("testAssertEqualWord0001", testAssertEqualWord0001),
               ("testAssertEqualWord0002", testAssertEqualWord0002),
               ("testAssertEqualWord80001", testAssertEqualWord80001),
               ("testAssertEqualWord80002", testAssertEqualWord80002),
               ("testAssertEqualWord320001", testAssertEqualWord320001),
               ("testAssertEqualWord320002", testAssertEqualWord320002),
               ("testAssertEqualReal0001", testAssertEqualReal0001),
               ("testAssertEqualReal0002", testAssertEqualReal0002),
               ("testAssertEqualChar0001", testAssertEqualChar0001),
               ("testAssertEqualChar0002", testAssertEqualChar0002),
               ("testAssertEqualString0001", testAssertEqualString0001),
               ("testAssertEqualString0002", testAssertEqualString0002),
               ("testAssertEqualString0003", testAssertEqualString0003),
               ("testAssertEqualString0004", testAssertEqualString0004),
               ("testAssertEqualString0005", testAssertEqualString0005),
               ("testAssertEqualString0006", testAssertEqualString0006),
               ("testAssertEqualSubstring0001", testAssertEqualSubstring0001),
               ("testAssertEqualSubstring0002", testAssertEqualSubstring0002),
               ("testAssertEqualSubstring0003", testAssertEqualSubstring0003),
               ("testAssertEqualSubstring0004", testAssertEqualSubstring0004),
               ("testAssertEqualSubstring0005", testAssertEqualSubstring0005),
               ("testAssertEqualSubstring0006", testAssertEqualSubstring0006),
               ("testEqualExceptionName0001", testEqualExceptionName0001),
               ("testEqualExceptionName0002", testEqualExceptionName0002),
               ("testEqualExceptionName0003", testEqualExceptionName0003),
(*
               (
                 "testEqualExceptionMessage0001",
                 testEqualExceptionMessage0001
               ),
               (
                 "testEqualExceptionMessage0002",
                 testEqualExceptionMessage0002
               ),
               (
                 "testEqualExceptionMessage0003",
                 testEqualExceptionMessage0003
               ),
*)
               ("testAssertEqualRef0001", testAssertEqualRef0001),
               ("testAssertEqualRef0002", testAssertEqualRef0002),
               ("testAssertEqualRef0003", testAssertEqualRef0003),
               ("testAssertSameRef0001", testAssertSameRef0001),
               ("testAssertSameRef0002", testAssertSameRef0002),
               ("testAssertSameRef0003", testAssertSameRef0003),
               ("testAssertEqualBool0001", testAssertEqualBool0001),
               ("testAssertEqualBool0002", testAssertEqualBool0002),
               ("testAssertEqualBool0003", testAssertEqualBool0003),
               ("testAssertEqualBool0004", testAssertEqualBool0004),
               ("testAssertTrue0001", testAssertTrue0001),
               ("testAssertTrue0002", testAssertTrue0002),
               ("testAssertFalse0001", testAssertFalse0001),
               ("testAssertFalse0002", testAssertFalse0002),
               ("testAssertEqualOption0001", testAssertEqualOption0001),
               ("testAssertEqualOption0002", testAssertEqualOption0002),
               ("testAssertEqualOption0003", testAssertEqualOption0003),
               ("testAssertEqualOption0004", testAssertEqualOption0004),
               ("testAssertSome0001", testAssertSome0001),
               ("testAssertSome0002", testAssertSome0002),
               ("testAssertNone0001", testAssertNone0001),
               ("testAssertNone0002", testAssertNone0002),

               ("testAssertEqualOrderLL", testAssertEqualOrderLL),
               ("testAssertEqualOrderLE", testAssertEqualOrderLE),
               ("testAssertEqualOrderLG", testAssertEqualOrderLG),
               ("testAssertEqualOrderEL", testAssertEqualOrderEL),
               ("testAssertEqualOrderEE", testAssertEqualOrderEE),
               ("testAssertEqualOrderEG", testAssertEqualOrderEG),
               ("testAssertEqualOrderGL", testAssertEqualOrderGL),
               ("testAssertEqualOrderGE", testAssertEqualOrderGE),
               ("testAssertEqualOrderGG", testAssertEqualOrderGG),

               ("testAssertEqual2Tuple0001", testAssertEqual2Tuple0001),
               ("testAssertEqual2Tuple0002", testAssertEqual2Tuple0002),
               ("testAssertEqual2Tuple0003", testAssertEqual2Tuple0003),
               ("testAssertEqual3Tuple0001", testAssertEqual3Tuple0001),
               ("testAssertEqual3Tuple0002", testAssertEqual3Tuple0002),
               ("testAssertEqual3Tuple0003", testAssertEqual3Tuple0003),
               ("testAssertEqual3Tuple0004", testAssertEqual3Tuple0004),
               ("testAssertEqual4Tuple0001", testAssertEqual4Tuple0001),
               ("testAssertEqual4Tuple0002", testAssertEqual4Tuple0002),
               ("testAssertEqual4Tuple0003", testAssertEqual4Tuple0003),
               ("testAssertEqual4Tuple0004", testAssertEqual4Tuple0004),
               ("testAssertEqual4Tuple0005", testAssertEqual4Tuple0005),
               ("testAssertEqual5Tuple0001", testAssertEqual5Tuple0001),
               ("testAssertEqual5Tuple0002", testAssertEqual5Tuple0002),
               ("testAssertEqual5Tuple0003", testAssertEqual5Tuple0003),
               ("testAssertEqual5Tuple0004", testAssertEqual5Tuple0004),
               ("testAssertEqual5Tuple0005", testAssertEqual5Tuple0005),
               ("testAssertEqual5Tuple0006", testAssertEqual5Tuple0006),
               ("testAssertEqualVector0001", testAssertEqualVector0001),
               ("testAssertEqualVector0002", testAssertEqualVector0002),
               ("testAssertEqualVector0003", testAssertEqualVector0003),
               ("testAssertEqualVector0004", testAssertEqualVector0004),
               ("testAssertEqualVector1000", testAssertEqualVector1000),
               ("testAssertEqualVector1001", testAssertEqualVector1001),
               ("testAssertEqualVector1002", testAssertEqualVector1002),
               ("testAssertEqualVector1003", testAssertEqualVector1003),
               ("testAssertEqualVector1004", testAssertEqualVector1004),
               ("testAssertEqualVector1005", testAssertEqualVector1005),
               ("testAssertEqualVector1006", testAssertEqualVector1006),
               ("testAssertEqualVector1007", testAssertEqualVector1007),
               ("testAssertEqualVector1008", testAssertEqualVector1008),
               ("testAssertEqualVector1009", testAssertEqualVector1009),
               ("testAssertEqualVector1010", testAssertEqualVector1010),
               ("testAssertEqualVector1011", testAssertEqualVector1011),
               ("testAssertEqualVector1012", testAssertEqualVector1012),
               ("testAssertEqualArray0001", testAssertEqualArray0001),
               ("testAssertEqualArray0002", testAssertEqualArray0002),
               ("testAssertEqualArray0003", testAssertEqualArray0003),
               ("testAssertEqualArray0004", testAssertEqualArray0004),
               ("testAssertEqualArray1000", testAssertEqualArray1000),
               ("testAssertEqualArray1001", testAssertEqualArray1001),
               ("testAssertEqualArray1002", testAssertEqualArray1002),
               ("testAssertEqualArray1003", testAssertEqualArray1003),
               ("testAssertEqualArray1004", testAssertEqualArray1004),
               ("testAssertEqualArray1005", testAssertEqualArray1005),
               ("testAssertEqualArray1006", testAssertEqualArray1006),
               ("testAssertEqualArray1007", testAssertEqualArray1007),
               ("testAssertEqualArray1008", testAssertEqualArray1008),
               ("testAssertEqualArray1009", testAssertEqualArray1009),
               ("testAssertEqualArray1010", testAssertEqualArray1010),
               ("testAssertEqualArray1011", testAssertEqualArray1011),
               ("testAssertEqualArray1012", testAssertEqualArray1012),
               ("testAssertEqualList0001", testAssertEqualList0001),
               ("testAssertEqualList0002", testAssertEqualList0002),
               ("testAssertEqualList0003", testAssertEqualList0003),
               ("testAssertEqualList0004", testAssertEqualList0004),
               ("testAssertEqualList1000", testAssertEqualList1000),
               ("testAssertEqualList1001", testAssertEqualList1001),
               ("testAssertEqualList1002", testAssertEqualList1002),
               ("testAssertEqualList1003", testAssertEqualList1003),
               ("testAssertEqualList1004", testAssertEqualList1004),
               ("testAssertEqualList1005", testAssertEqualList1005),
               ("testAssertEqualList1006", testAssertEqualList1006),
               ("testAssertEqualList1007", testAssertEqualList1007),
               ("testAssertEqualList1008", testAssertEqualList1008),
               ("testAssertEqualList1009", testAssertEqualList1009),
               ("testAssertEqualList1010", testAssertEqualList1010),
               ("testAssertEqualList1011", testAssertEqualList1011),
               ("testAssertEqualList1012", testAssertEqualList1012)
            ]
        val failCases =
            foldl
            (fn ((testName, testCase), failCases) =>
                ((testCase (); print "."; failCases)
                 handle TestFail =>
                        (print "F"; (testName ^ " by Fail") :: failCases)
                      | exn =>
                        (print "E";
                         (testName ^ " by " ^ exnMessage exn) :: failCases)))
            []
            tests
      in
        print "\n";
        app (fn testName => (print testName; print "\n")) (List.rev failCases);
        print "\n"
      end

  (***************************************************************************)

end;

