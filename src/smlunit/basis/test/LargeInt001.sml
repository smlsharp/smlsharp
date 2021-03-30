(**
 * test case for LargeInt structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)
structure LargeInt001 =
SignedInteger001(struct
                   open LargeInt
                   val assertEqualInt =
                       SMLUnit.Assert.AssertLargeInt.assertEqualInt
                 end);
