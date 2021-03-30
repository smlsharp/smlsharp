(**
 * test case for Position structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)
structure Position001 =
SignedInteger001(struct
                   open Position
                   val assertEqualInt =
                       SMLUnit.Assert.AssertPosition.assertEqualInt
                 end);
