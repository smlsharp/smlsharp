(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: MultiByteStringTest.sml,v 1.1.28.1 2010/05/09 13:52:28 kiyoshiy Exp $
 *)
structure EUCJPCodecTest =
struct

  open SMLUnit.Test

  structure MBCharTest0001 = CodecCharBaseTest0001(EUCJPCodec)
  structure MBStringTest0001 = CodecStringBaseTest0001(EUCJPCodec)
  structure MBSubstringTest0001 = CodecSubstringBaseTest0001(EUCJPCodec)

  fun suite () =
      TestList
      [
        TestLabel ("MBCharTest0001", MBCharTest0001.suite ()),
        TestLabel ("MBStringTest0001", MBStringTest0001.suite ()),
        TestLabel ("MBSubstringTest0001", MBSubstringTest0001.suite ())
      ]

end