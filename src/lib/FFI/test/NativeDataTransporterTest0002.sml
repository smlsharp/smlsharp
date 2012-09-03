(**
 * test of <code>attach</code> function.
 * @author YAMATODANI Kiyoshi
 * @version $Id: NativeDataTransporterTest0002.sml,v 1.1 2007/05/20 03:54:33 kiyoshiy Exp $
 *)
structure NativeDataTransporterTest0002 =
struct

  (***************************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  structure UM = UnmanagedMemory

  structure Testee = NativeDataTransporter

  (***************************************************************************)

  fun testAttach0001() =
      let
        val tr = Testee.boxed (Testee.tuple2 (Testee.word, Testee.word))
        val adr = UM.allocate 8
        val _ = UM.updateWord (UM.advance(adr, 0), 0w1)
        val _ = UM.updateWord (UM.advance(adr, 4), 0w2)
        val e = Testee.attach tr adr
        val v = (0w1, 0w2)
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = UM.release adr
        val _ = A.assertEqual2Tuple (A.assertEqualWord, A.assertEqualWord) v v'
      in
        ()
      end

  (***************************************************************************)

  fun suite () =
      T.labelTests
      [
        ("testAttach0001", testAttach0001)
      ]

  (***************************************************************************)

end
