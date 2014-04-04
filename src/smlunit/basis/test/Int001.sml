(**
 * test case for Int structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Int001 =
SignedInteger001(struct
                   open Int
                   val assertEqualInt = SMLUnit.Assert.assertEqualInt
                 end);
