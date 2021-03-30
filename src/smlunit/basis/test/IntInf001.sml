(**
 * test case for IntInf structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)
structure IntInf001 =
SignedInteger001(struct
                   open IntInf
                   val assertEqualInt =
                       SMLUnit.Assert.assertEqualByCompare
                           IntInf.compare
                           IntInf.toString
                 end);
