(**
 *  Verifies the behavior of functions in ByteListChannel structure.
 *)
structure ByteListChannelTest0001 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure Testee = ByteListChannel

  (***************************************************************************)

  val TESTSEND0001_VALUE = 0w12 : Word8.word
  val TESTSEND0001_EXPECTED = [0w12] : Word8.word list

  fun testSend0001 () =
      let
          val buffer = ref ([] : Word8.word list)
          val channel = Testee.openOut {buffer = buffer}
      in
          #send channel TESTSEND0001_VALUE;
          #close channel ();
          Assert.assertEqualWord8List TESTSEND0001_EXPECTED (!buffer);
          ()
      end

  (****************************************)

  val TESTSENDARRAY0001_VALUE = Word8Array.fromList [0w12, 0w34, 0w56]
  val TESTSENDARRAY0001_EXPECTED = [0w12, 0w34, 0w56] : Word8.word list

  fun testSendArray0001 () =
      let
          val buffer = ref ([] : Word8.word list)
          val channel = Testee.openOut {buffer = buffer}
      in
          #sendArray channel TESTSENDARRAY0001_VALUE;
          #close channel ();
          Assert.assertEqualWord8List TESTSENDARRAY0001_EXPECTED (!buffer);
          ()
      end

  (****************************************)

  val TESTRECEIVE0001_VALUE = [0w12] : Word8.word list
  val TESTRECEIVE0001_EXPECTED = SOME(0w12 : Word8.word)

  fun testReceive0001 () =
      let
          val buffer = TESTRECEIVE0001_VALUE
          val channel = Testee.openIn {buffer = buffer}
      in
          Assert.assertEqualWord8Option
          (#receive channel ())
          TESTRECEIVE0001_EXPECTED;
          #close channel ()
      end

  (****************************************)

  val TESTRECEIVE0002_VALUE = [] : Word8.word list
  val TESTRECEIVE0002_EXPECTED = NONE

  fun testReceive0002 () =
      let
          val buffer = TESTRECEIVE0002_VALUE
          val channel = Testee.openIn {buffer = buffer}
      in
          Assert.assertEqualWord8Option
          (#receive channel ())
          TESTRECEIVE0002_EXPECTED;
          #close channel ()
      end

  (****************************************)

  val TESTRECEIVEARRAY0001_REQUIREDLENGTH = 2;
  val TESTRECEIVEARRAY0001_VALUE = [0w12, 0w13, 0w14] : Word8.word list
  val TESTRECEIVEARRAY0001_EXPECTED = Word8Array.fromList [0w12, 0w13]

  fun testReceiveArray0001 () =
      let
          val buffer = TESTRECEIVEARRAY0001_VALUE
          val channel = Testee.openIn {buffer = buffer}
      in
          Assert.assertEqualWord8Array
          (#receiveArray channel TESTRECEIVEARRAY0001_REQUIREDLENGTH)
          TESTRECEIVEARRAY0001_EXPECTED;
          #close channel ()
      end

  (****************************************)

  val TESTRECEIVEARRAY0002_REQUIREDLENGTH = 3;
  val TESTRECEIVEARRAY0002_VALUE = [0w12, 0w13] : Word8.word list
  val TESTRECEIVEARRAY0002_EXPECTED = Word8Array.fromList [0w12, 0w13]

  fun testReceiveArray0002 () =
      let
          val buffer = TESTRECEIVEARRAY0002_VALUE
          val channel = Testee.openIn {buffer = buffer}
      in
          Assert.assertEqualWord8Array
          (#receiveArray channel TESTRECEIVEARRAY0002_REQUIREDLENGTH)
          TESTRECEIVEARRAY0002_EXPECTED;
          #close channel ()
      end

  (****************************************)

  val TESTISEOF0001_VALUE = [0w12] : Word8.word list

  fun testIsEOF0001 () =
      let
          val buffer = TESTISEOF0001_VALUE
          val channel = Testee.openIn {buffer = buffer}
      in
          Assert.assertFalse (#isEOF channel ());
          #close channel ()
      end

  (****************************************)

  val TESTISEOF0002_VALUE = [0w12] : Word8.word list

  fun testIsEOF0002 () =
      let
          val buffer = TESTISEOF0002_VALUE
          val channel = Testee.openIn {buffer = buffer}
      in
          #receive channel (); (* throw away *)
          Assert.assertTrue (#isEOF channel ());
          #close channel ()
      end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testSend0001", testSend0001),
        ("testSendArray0001", testSendArray0001),
        ("testReceive0001", testReceive0001),
        ("testReceive0002", testReceive0002),
        ("testReceiveArray0001", testReceiveArray0001),
        ("testReceiveArray0002", testReceiveArray0002),
        ("testIsEOF0001", testIsEOF0001),
        ("testIsEOF0002", testIsEOF0002)
      ]

  (***************************************************************************)

end
