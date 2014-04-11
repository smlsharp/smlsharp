(**
 * test case for Position structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Position001 =
SignedInteger001(struct
                   open Position
                   val assertEqualInt =
                       SMLUnit.Assert.AssertPosition.assertEqualInt
                 end);
