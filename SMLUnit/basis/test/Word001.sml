(**
 * test case for Word structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Word001 =
UnsignedInteger001(struct
                     open Word
                     val assertEqualWord = SMLUnit.Assert.assertEqualWord
                   end);
