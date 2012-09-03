(**
 *  Verifies the behavior of functions in StandAloneSession structure.
 *)
structure StandAloneSessionTest0001 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure Testee = StandAloneSession

  (***************************************************************************)

  val TESTEXECUTE0001_CODE = Word8Array.fromList [0w1, 0w2, 0w3, 0w4]
  val TESTEXECUTE0001_EXPECTED =
      [
        (Word8.fromInt o Word.toInt)
        (SystemDefTypes.byteOrderToWord SystemDef.NativeByteOrder),
        0w0, 0w0, 0w0, 0w4, (* the number of 'bytes' of the code block. *)
        0w1, 0w2, 0w3, 0w4  (* the code block *)
      ]

  fun testExecute0001 () =
      let
          val buffer = ref ([] : Word8.word list)
          val channel = ByteListChannel.openOut {buffer = buffer}
          val session = Testee.openSession {outputChannel = channel}
      in
          #execute session TESTEXECUTE0001_CODE;
          #close session ();
          #close channel ();
          Assert.assertEqualWord8List
          TESTEXECUTE0001_EXPECTED
          (!buffer);
          ()
      end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testExecute0001", testExecute0001)
      ]

  (***************************************************************************)

end