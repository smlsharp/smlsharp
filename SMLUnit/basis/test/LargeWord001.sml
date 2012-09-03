(**
 * test case for LargeWord structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure LargeWord001 =
UnsignedInteger001(struct
                     open LargeWord
                     val assertEqualWord = AssertLargeWord.assertEqualWord
                   end);
