(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: TestMain.sml,v 1.1.28.1 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
structure TestMain =
struct

  open SMLUnit.Test

  fun test () =
      let
        val tests =
            TestList
                [
                  TestLabel ("ASCIICodecTest", ASCIICodecTest.suite ()),

                  TestLabel ("EUCJPCodecTest", EUCJPCodecTest.suite ()),
                  TestLabel ("GBKCodecTest", GBKCodecTest.suite ()),
                  TestLabel ("GB2312CodecTest", GB2312CodecTest.suite ()),

                  TestLabel ("ISO2022JPCodecTest", ISO2022JPCodecTest.suite ()),

                  TestLabel ("ShiftJISCodecTest", ShiftJISCodecTest.suite ()),

                  TestLabel ("UTF8CodecTest", UTF8CodecTest.suite ()),
                  TestLabel ("UTF16CodecTest", UTF16CodecTest.suite ()),
                  TestLabel ("MultiByteText", MultiByteTextTest.suite ())
                ]
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end