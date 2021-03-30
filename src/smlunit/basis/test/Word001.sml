(**
 * test case for Word structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)
structure Word001 =
UnsignedInteger001(struct
                     open Word
                     val assertEqualWord = SMLUnit.Assert.assertEqualWord
                   end);
