(**
 * test of <code>import</code>, <code>export</code> functions and transporters.
 * @author YAMATODANI Kiyoshi
 * @version $Id: NativeDataTransporterTest0001.sml,v 1.1 2007/05/20 03:53:26 kiyoshiy Exp $
 *)
structure NativeDataTransporterTest0001 =
struct

  (***************************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  structure UM = UnmanagedMemory

  structure Testee = NativeDataTransporter

  (***************************************************************************)

  fun testByte0001() =
      let
        val tr = Testee.boxed Testee.byte
        val v = 0w1 : byte
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val _ = A.assertEqualWord8 0w1 (UM.sub adr)
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualWord8 v v'
      in
        ()
      end

  fun testWordBig0001() =
      let
        val tr = Testee.boxed Testee.wordBig
        val v = 0wx12345678
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val _ = A.assertEqualWord8 0wx12 (UM.sub adr)
        val _ = A.assertEqualWord8 0wx34 (UM.sub (UM.advance(adr, 1)))
        val _ = A.assertEqualWord8 0wx56 (UM.sub (UM.advance(adr, 2)))
        val _ = A.assertEqualWord8 0wx78 (UM.sub (UM.advance(adr, 3)))
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualWord v v'
      in
        ()
      end

  fun testWordLittle0001() =
      let
        val tr = Testee.boxed Testee.wordLittle
        val v = 0wx12345678
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val _ = A.assertEqualWord8 0wx78 (UM.sub adr)
        val _ = A.assertEqualWord8 0wx56 (UM.sub (UM.advance(adr, 1)))
        val _ = A.assertEqualWord8 0wx34 (UM.sub (UM.advance(adr, 2)))
        val _ = A.assertEqualWord8 0wx12 (UM.sub (UM.advance(adr, 3)))
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualWord v v'
      in
        ()
      end

  fun testIntBig0001() =
      let
        val tr = Testee.boxed Testee.intBig
        val v = 0x12345678
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val _ = A.assertEqualWord8 0wx12 (UM.sub adr)
        val _ = A.assertEqualWord8 0wx34 (UM.sub (UM.advance(adr, 1)))
        val _ = A.assertEqualWord8 0wx56 (UM.sub (UM.advance(adr, 2)))
        val _ = A.assertEqualWord8 0wx78 (UM.sub (UM.advance(adr, 3)))
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualInt v v'
      in
        ()
      end

  fun testIntLittle0001() =
      let
        val tr = Testee.boxed Testee.intLittle
        val v = 0x12345678
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val _ = A.assertEqualWord8 0wx78 (UM.sub adr)
        val _ = A.assertEqualWord8 0wx56 (UM.sub (UM.advance(adr, 1)))
        val _ = A.assertEqualWord8 0wx34 (UM.sub (UM.advance(adr, 2)))
        val _ = A.assertEqualWord8 0wx12 (UM.sub (UM.advance(adr, 3)))
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualInt v v'
      in
        ()
      end

  fun testRealBig0001() =
      let
        val tr = Testee.boxed Testee.realBig
        val v = 1.2345678
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualReal v v'
      in
        ()
      end

  fun testRealLittle0001() =
      let
        val tr = Testee.boxed Testee.realLittle
        val v = 1.2345678
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualReal v v'
      in
        ()
      end

  fun testChar0001() =
      let
        val tr = Testee.boxed Testee.char
        val v = #"x"
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualChar v v'
      in
        ()
      end

  fun testString0001() =
      let
        val tr = Testee.boxed Testee.string
        val v = ""
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualString v v'
      in
        ()
      end

  fun testString0002() =
      let
        val tr = Testee.boxed Testee.string
        val v = "x"
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualString v v'
      in
        ()
      end

  fun testString0003() =
      let
        val tr = Testee.boxed Testee.string
        val v = "xyz"
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualString v v'
      in
        ()
      end

  fun testAddress0001() =
      let
        val tr = Testee.boxed Testee.address
        val v = UM.wordToAddress 0w1234
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualWord (UM.addressToWord v) (UM.addressToWord v')
      in
        ()
      end

  fun testTuple20001() =
      let
        val tr = Testee.boxed (Testee.tuple2 (Testee.byte, Testee.int))
        val v = (0w1 : Word8.word, 2345)
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqual2Tuple (A.assertEqualWord8, A.assertEqualInt) v v'
      in
        ()
      end

  fun testTuple30001() =
      let
        val tr =
            Testee.boxed (Testee.tuple3 (Testee.int, Testee.byte, Testee.int))
        val v = (1234, 0w5 : Word8.word, 6789)
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ =
            A.assertEqual3Tuple
                (A.assertEqualInt, A.assertEqualWord8, A.assertEqualInt) v v'
      in
        ()
      end

  fun testTuple40001() =
      let
        val tr =
            Testee.boxed (Testee.tuple4 (Testee.int, Testee.byte, Testee.int, Testee.byte))
        val v = (1234, 0w5 : Word8.word, 6789, 0w1 : Word8.word)
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualInt (#1 v) (#1 v')
        val _ = A.assertEqualWord8 (#2 v) (#2 v')
        val _ = A.assertEqualInt (#3 v) (#3 v')
        val _ = A.assertEqualWord8 (#4 v) (#4 v')
      in
        ()
      end

  fun testTuple50001() =
      let
        val tr =
            Testee.boxed (Testee.tuple5 (Testee.int, Testee.byte, Testee.int, Testee.byte, Testee.int))
        val v = (1234, 0w5 : Word8.word, 6789, 0w1 : Word8.word, 2345)
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualInt (#1 v) (#1 v')
        val _ = A.assertEqualWord8 (#2 v) (#2 v')
        val _ = A.assertEqualInt (#3 v) (#3 v')
        val _ = A.assertEqualWord8 (#4 v) (#4 v')
        val _ = A.assertEqualInt (#5 v) (#5 v')
      in
        ()
      end

  fun testTuple60001() =
      let
        val tr =
            Testee.boxed (Testee.tuple6 (Testee.int, Testee.byte, Testee.int, Testee.byte, Testee.int, Testee.byte))
        val v = (1234, 0w5 : Word8.word, 6789, 0w1 : Word8.word, 2345, 0w6 : Word8.word)
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualInt (#1 v) (#1 v')
        val _ = A.assertEqualWord8 (#2 v) (#2 v')
        val _ = A.assertEqualInt (#3 v) (#3 v')
        val _ = A.assertEqualWord8 (#4 v) (#4 v')
        val _ = A.assertEqualInt (#5 v) (#5 v')
        val _ = A.assertEqualWord8 (#6 v) (#6 v')
      in
        ()
      end

  fun testTuple70001() =
      let
        val tr =
            Testee.boxed (Testee.tuple7 (Testee.int, Testee.byte, Testee.int, Testee.byte, Testee.int, Testee.byte, Testee.int))
        val v = (1234, 0w5 : Word8.word, 6789, 0w1 : Word8.word, 2345, 0w6 : Word8.word, 7890)
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualInt (#1 v) (#1 v')
        val _ = A.assertEqualWord8 (#2 v) (#2 v')
        val _ = A.assertEqualInt (#3 v) (#3 v')
        val _ = A.assertEqualWord8 (#4 v) (#4 v')
        val _ = A.assertEqualInt (#5 v) (#5 v')
        val _ = A.assertEqualWord8 (#6 v) (#6 v')
        val _ = A.assertEqualInt (#7 v) (#7 v')
      in
        ()
      end

  fun testTuple80001() =
      let
        val tr =
            Testee.boxed (Testee.tuple8 (Testee.int, Testee.byte, Testee.int, Testee.byte, Testee.int, Testee.byte, Testee.int, Testee.byte))
        val v = (1234, 0w5 : Word8.word, 6789, 0w1 : Word8.word, 2345, 0w6 : Word8.word, 7890, 0w2 : Word8.word)
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualInt (#1 v) (#1 v')
        val _ = A.assertEqualWord8 (#2 v) (#2 v')
        val _ = A.assertEqualInt (#3 v) (#3 v')
        val _ = A.assertEqualWord8 (#4 v) (#4 v')
        val _ = A.assertEqualInt (#5 v) (#5 v')
        val _ = A.assertEqualWord8 (#6 v) (#6 v')
        val _ = A.assertEqualInt (#7 v) (#7 v')
        val _ = A.assertEqualWord8 (#8 v) (#8 v')
      in
        ()
      end

  fun testTuple90001() =
      let
        val tr =
            Testee.boxed (Testee.tuple9 (Testee.int, Testee.byte, Testee.int, Testee.byte, Testee.int, Testee.byte, Testee.int, Testee.byte, Testee.int))
        val v = (1234, 0w5 : Word8.word, 6789, 0w1 : Word8.word, 2345, 0w6 : Word8.word, 7890, 0w2 : Word8.word, 3456)
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualInt (#1 v) (#1 v')
        val _ = A.assertEqualWord8 (#2 v) (#2 v')
        val _ = A.assertEqualInt (#3 v) (#3 v')
        val _ = A.assertEqualWord8 (#4 v) (#4 v')
        val _ = A.assertEqualInt (#5 v) (#5 v')
        val _ = A.assertEqualWord8 (#6 v) (#6 v')
        val _ = A.assertEqualInt (#7 v) (#7 v')
        val _ = A.assertEqualWord8 (#8 v) (#8 v')
        val _ = A.assertEqualInt (#9 v) (#9 v')
      in
        ()
      end

  fun testTuple100001() =
      let
        val tr =
            Testee.boxed (Testee.tuple10 (Testee.int, Testee.byte, Testee.int, Testee.byte, Testee.int, Testee.byte, Testee.int, Testee.byte, Testee.int, Testee.byte))
        val v = (1234, 0w5 : Word8.word, 6789, 0w1 : Word8.word, 2345, 0w6 : Word8.word, 7890, 0w2 : Word8.word, 3456, 0w7 : Word8.word)
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualInt (#1 v) (#1 v')
        val _ = A.assertEqualWord8 (#2 v) (#2 v')
        val _ = A.assertEqualInt (#3 v) (#3 v')
        val _ = A.assertEqualWord8 (#4 v) (#4 v')
        val _ = A.assertEqualInt (#5 v) (#5 v')
        val _ = A.assertEqualWord8 (#6 v) (#6 v')
        val _ = A.assertEqualInt (#7 v) (#7 v')
        val _ = A.assertEqualWord8 (#8 v) (#8 v')
        val _ = A.assertEqualInt (#9 v) (#9 v')
        val _ = A.assertEqualWord8 (#10 v) (#10 v')
      in
        ()
      end

  fun testRefNonNull0001 () =
      let
        val tRefInt = Testee.refNonNull 0 Testee.int
        val tRefWord = Testee.refNonNull 0w0 Testee.word
        val tr =
            Testee.boxed
                (Testee.tuple2
                     (Testee.tuple2(tRefInt, tRefInt),
                      Testee.tuple2(tRefInt, tRefWord)))
        val (ref1, ref2, ref3) = (ref 1, ref 2, ref 0w3)
        val v = ((ref1, ref2), (ref1, ref3))
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertSameRef (#1 (#1 v)) (#1 (#1 v'))
        val _ = A.assertSameRef (#1 (#2 v)) (#1 (#2 v'))
        val _ = A.assertSameRef (#2 (#1 v)) (#2 (#1 v'))
        val _ = A.assertSameRef (#2 (#2 v)) (#2 (#2 v'))
      in
        ()
      end

  fun testRefNullable0001 () =
      let
        val tRefInt = Testee.refNullable 0 Testee.int
        val tr =
            Testee.boxed (Testee.tuple2(tRefInt, tRefInt))
        val (ref1, ref2) = (SOME(ref 1), NONE)
        val v = (ref1, ref2)
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualOption A.assertSameRef (#1 v) (#1 v')
        val _ = A.assertEqualOption A.assertSameRef (#2 v) (#2 v')
      in
        ()
      end

  fun testBoxed0001 () =
      let
        val tr =
            Testee.boxed
                (Testee.tuple2
                     (Testee.boxed Testee.int,
                      Testee.boxed (Testee.tuple2 (Testee.int, Testee.int))))
        val v = (1, (2, 3))
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualInt (#1 v) (#1 v')
        val _ = A.assertEqualInt (#1 (#2 v)) (#1 (#2 v'))
        val _ = A.assertEqualInt (#2 (#2 v)) (#2 (#2 v'))
      in
        ()
      end

  fun testBoxedNullable0001 () =
      let
        val tBoxedInt = Testee.boxedNullable Testee.int
        val tr = Testee.boxed (Testee.tuple2 (tBoxedInt, tBoxedInt))
        val v = (NONE, SOME 1)
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertEqualOption A.assertEqualInt (#1 v) (#1 v')
        val _ = A.assertEqualOption A.assertEqualInt (#2 v) (#2 v')
      in
        ()
      end

  fun testFlatArray0001 () =
      let
        val tr = Testee.flatArray (Testee.tuple2 (Testee.int, Testee.int))
        val v = Array.fromList [(1, 2), (3, 4)]
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val _ = A.assertEqualInt 1 (UM.subInt adr)
        val _ = A.assertEqualInt 2 (UM.subInt (UM.advance(adr, 4)))
        val _ = A.assertEqualInt 3 (UM.subInt (UM.advance(adr, 8)))
        val _ = A.assertEqualInt 4 (UM.subInt (UM.advance(adr, 12)))
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertSameArray v v'
      in
        ()
      end

  fun testFlatArray0002 () =
      let
        val tr = Testee.flatArray (Testee.tuple2 (Testee.int, Testee.int))
        val v = Array.fromList []
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assertSameArray v v'
      in
        ()
      end

  fun testAlign0001 () =
      let
        val tr =
            Testee.boxed
            (Testee.tuple3
                (Testee.byte, Testee.align 4 Testee.int, Testee.align 4 Testee.int))
        val v = (0w1 : Word8.word, 2, 3)
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val _ = A.assertEqualWord8 0w1 (UM.sub adr)
        val _ = A.assertEqualInt 2 (UM.subInt (UM.advance(adr, 4)))
        val _ = A.assertEqualInt 3 (UM.subInt (UM.advance(adr, 8)))
        val v' = Testee.import e
        val _ = Testee.release e
        val _ =
            A.assertEqual3Tuple
                (A.assertEqualWord8, A.assertEqualInt, A.assertEqualInt)
                v
                v'
      in
        ()
      end

  fun testConv0001 () =
      let
        datatype dt = D | E of word
        val trDt =
            Testee.conv
                (fn (1, _) => D | (2, w) => E w,
                 fn D => (1, 0w0) | E w => (2, w))
                (Testee.tuple2 (Testee.int, Testee.word))
        val tr = Testee.boxed (Testee.tuple2 (trDt, trDt))
        val v = (D, E 0w3)
        val e = Testee.export tr v
        val adr = Testee.addressOf e
        val _ = A.assertEqualInt 1 (UM.subInt adr)
        val _ = A.assertEqualWord 0w0 (UM.subWord (UM.advance(adr, 4)))
        val _ = A.assertEqualInt 2 (UM.subInt (UM.advance(adr, 8)))
        val _ = A.assertEqualWord 0w3 (UM.subWord (UM.advance(adr, 12)))
        val v' = Testee.import e
        val _ = Testee.release e
        val _ = A.assert "fail" (v = v')
      in
        ()
      end

  (***************************************************************************)

  fun suite () =
      T.labelTests
      [
        ("testByte0001", testByte0001),
        ("testWordBig0001", testWordBig0001),
        ("testWordLittle0001", testWordLittle0001),
        ("testIntBig0001", testIntBig0001),
        ("testIntLittle0001", testIntLittle0001),
        ("testRealBig0001", testRealBig0001),
        ("testRealLittle0001", testRealLittle0001),
        ("testChar0001", testChar0001),
        ("testString0001", testString0001),
        ("testString0002", testString0002),
        ("testString0003", testString0003),
        ("testAddress0001", testAddress0001),
        ("testTuple20001", testTuple20001),
        ("testTuple30001", testTuple30001),
        ("testTuple40001", testTuple40001),
        ("testTuple50001", testTuple50001),
        ("testTuple60001", testTuple60001),
        ("testTuple70001", testTuple70001),
        ("testTuple80001", testTuple80001),
        ("testTuple90001", testTuple90001),
        ("testTuple100001", testTuple100001),
        ("testRefNonNull0001", testRefNonNull0001),
        ("testRefNullable0001", testRefNullable0001),
        ("testBoxed0001", testBoxed0001),
        ("testBoxedNullable0001", testBoxedNullable0001),
        ("testFlatArray0001", testFlatArray0001),
        ("testFlatArray0002", testFlatArray0002),
        ("testAlign0001", testAlign0001),
        ("testConv0001", testConv0001)
      ]

  (***************************************************************************)

end
