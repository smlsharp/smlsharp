(**
 * test case for Int structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)
structure Int001 =
SignedInteger001(struct
                   open Int
                   val assertEqualInt = SMLUnit.Assert.assertEqualInt
                 end);
