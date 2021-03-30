(**
 * test case for LargeWord structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)
structure LargeWord001 =
UnsignedInteger001(struct
                     open LargeWord
                     val assertEqualWord =
                         SMLUnit.Assert.AssertLargeWord.assertEqualWord
                   end);
