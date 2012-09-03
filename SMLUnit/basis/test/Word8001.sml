(**
 * test case for Word8 structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Word8001 =
UnsignedInteger001(struct
                     open Word8
                     val assertEqualWord = SMLUnit.Assert.assertEqualWord8
                   end);
