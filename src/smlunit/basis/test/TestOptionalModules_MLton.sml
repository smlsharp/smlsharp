(**
 * test set for Basis modules which are classified into 'optional'. 
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: TestMain.sml,v 1.1.28.1 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
structure TestOptionalModules =
struct

  local
    open SMLUnit.Test
  in
  fun tests () =
      [
        TestLabel ("IntInf001", IntInf001.suite ()),
        TestLabel ("IntInf101", IntInf101.suite ()),
        TestLabel ("Array2001", Array2001.suite ()),
        TestLabel ("CharArray2001", CharArray2001.suite ()),
        TestLabel ("RealArray001", RealArray001.suite ()),
        TestLabel ("RealArray101", RealArray101.suite ()),
        TestLabel ("RealVector001", RealVector001.suite ()),
        TestLabel ("RealVector101", RealVector101.suite ()),
        TestLabel ("Word8Array2001", Word8Array2001.suite ())
      ]
  end (* local *)

end