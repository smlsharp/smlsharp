(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: ISO2022JPCodecTest.sml,v 1.1.2.1 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
structure ISO2022JPCodecTest =
struct

  open SMLUnit.Test

  structure MBCharTest0001 = CodecCharBaseTest0001(ISO2022JPCodec)
  structure MBStringTest0001 = CodecStringBaseTest0001(ISO2022JPCodec)
  structure MBSubstringTest0001 = CodecSubstringBaseTest0001(ISO2022JPCodec)

  fun suite () =
      TestList
      [
        TestLabel ("MBCharTest0001", MBCharTest0001.suite ()),
        TestLabel ("MBStringTest0001", MBStringTest0001.suite ()),
        TestLabel ("MBSubstringTest0001", MBSubstringTest0001.suite ())
      ]

end