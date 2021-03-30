(**
 * test case for Word8 structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)
structure Word8001 =
UnsignedInteger001(struct
                     open Word8
                     val assertEqualWord = SMLUnit.Assert.assertEqualWord8
                   end);
