(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: PrimitiveSerializerBigEndianTest001.sml,v 1.1 2005/12/31 10:22:01 kiyoshiy Exp $
 *)
structure PrimitiveSerializerBigEndianTest001 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure Testee = PrimitiveSerializerBigEndian

  (***************************************************************************)

  fun testByteOrder0001 () =
      if Testee.byteOrder = SystemDefTypes.BigEndian
      then ()
      else Assert.fail "testByteOrder0001"

  (****************************************)

  fun testWriteLowBytes value bytes expected () =
      let
        val list = ref ([] : Word8.word list)
        fun writer byte = list := (!list) @ [byte]
        val _ = Testee.writeLowBytes (value, bytes) writer
      in
        Assert.assertEqualWord8List
            expected
            (!list);
        ()
      end

  (********************)

  val TESTWRITELOWBYTES0001_EXPECTED =
      [0wx78] : Word8.word list
  val TESTWRITELOWBYTES0001_VALUE = 0wx12345678 : Word32.word

  val testWriteLowBytes0001 =
      testWriteLowBytes
          TESTWRITELOWBYTES0001_VALUE 1 TESTWRITELOWBYTES0001_EXPECTED

  (********************)

  val TESTWRITELOWBYTES0002_EXPECTED =
      [0wx56, 0wx78] : Word8.word list
  val TESTWRITELOWBYTES0002_VALUE = 0wx12345678 : Word32.word

  val testWriteLowBytes0002 =
      testWriteLowBytes
          TESTWRITELOWBYTES0002_VALUE 2 TESTWRITELOWBYTES0002_EXPECTED

  (********************)

  val TESTWRITELOWBYTES0003_EXPECTED =
      [0wx34, 0wx56, 0wx78] : Word8.word list
  val TESTWRITELOWBYTES0003_VALUE = 0wx12345678 : Word32.word

  val testWriteLowBytes0003 =
      testWriteLowBytes
          TESTWRITELOWBYTES0003_VALUE 3 TESTWRITELOWBYTES0003_EXPECTED

  (********************)

  val TESTWRITELOWBYTES0004_EXPECTED =
      [0wx12, 0wx34, 0wx56, 0wx78] : Word8.word list
  val TESTWRITELOWBYTES0004_VALUE = 0wx12345678 : Word32.word

  val testWriteLowBytes0004 =
      testWriteLowBytes
          TESTWRITELOWBYTES0004_VALUE 4 TESTWRITELOWBYTES0004_EXPECTED

  (****************************************)

  fun testReadBytes values bytes expected () =
      let
        val list = ref values
        fun reader () = hd (!list) before list := tl (!list)
        val result = Testee.readBytes bytes reader
      in
        Assert.assertEqualWord32 expected result;
        ()
      end

  (********************)

  val TESTREADBYTES0001_EXPECTED = 0wx12 : Word32.word
  val TESTREADBYTES0001_VALUES = [0wx12, 0wx34, 0wx56, 0wx78] : Word8.word list

  val testReadBytes0001 =
      testReadBytes
          TESTREADBYTES0001_VALUES 1 TESTREADBYTES0001_EXPECTED

  (********************)

  val TESTREADBYTES0002_EXPECTED = 0wx1234 : Word32.word
  val TESTREADBYTES0002_VALUES = [0wx12, 0wx34, 0wx56, 0wx78] : Word8.word list

  val testReadBytes0002 =
      testReadBytes
          TESTREADBYTES0002_VALUES 2 TESTREADBYTES0002_EXPECTED

  (********************)

  val TESTREADBYTES0003_EXPECTED = 0wx123456 : Word32.word
  val TESTREADBYTES0003_VALUES = [0wx12, 0wx34, 0wx56, 0wx78] : Word8.word list

  val testReadBytes0003 =
      testReadBytes
          TESTREADBYTES0003_VALUES 3 TESTREADBYTES0003_EXPECTED

  (********************)

  val TESTREADBYTES0004_EXPECTED = 0wx12345678 : Word32.word
  val TESTREADBYTES0004_VALUES = [0wx12, 0wx34, 0wx56, 0wx78] : Word8.word list

  val testReadBytes0004 =
      testReadBytes
          TESTREADBYTES0004_VALUES 4 TESTREADBYTES0004_EXPECTED

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testByteOrder0001", testByteOrder0001),
        ("testWriteLowBytes0001", testWriteLowBytes0001),
        ("testWriteLowBytes0002", testWriteLowBytes0002),
        ("testWriteLowBytes0003", testWriteLowBytes0003),
        ("testWriteLowBytes0004", testWriteLowBytes0004),
        ("testReadBytes0001", testReadBytes0001),
        ("testReadBytes0002", testReadBytes0002),
        ("testReadBytes0003", testReadBytes0003),
        ("testReadBytes0004", testReadBytes0004)
      ]

  (***************************************************************************)

end
