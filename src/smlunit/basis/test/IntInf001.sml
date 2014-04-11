(**
 * test case for IntInf structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure IntInf001 =
SignedInteger001(struct
                   open IntInf
                   val assertEqualInt =
                       SMLUnit.Assert.assertEqualByCompare
                           IntInf.compare
                           IntInf.toString
                 end);
