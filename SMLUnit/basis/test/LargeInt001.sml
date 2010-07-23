(**
 * test case for LargeInt structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure LargeInt001 =
SignedInteger001(struct
                   open LargeInt
                   val assertEqualInt = AssertLargeInt.assertEqualInt
                 end);
