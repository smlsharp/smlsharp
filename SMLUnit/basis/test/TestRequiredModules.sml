(**
 * test set for Basis modules which are classified into 'required'. 
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: TestMain.sml,v 1.1.28.1 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
structure TestRequiredModules =
struct

  local
    open SMLUnit.Test
  in
  fun tests () =
      let
        val tests =
                [
                  TestLabel ("Array001", Array001.suite ()),
                  TestLabel ("Array101", Array101.suite ()),
                  TestLabel ("ArraySlice001", ArraySlice001.suite ()),
                  TestLabel ("ArraySlice101", ArraySlice101.suite ()),
                  TestLabel ("Bool001", Bool001.suite ()),
                  TestLabel ("Byte001", Byte001.suite ()),
                  TestLabel ("Char001", Char001.suite ()),
                  TestLabel ("CharArray001", CharArray001.suite ()),
                  TestLabel ("CharArray101", CharArray101.suite ()),
                  TestLabel ("CharArraySlice001", CharArraySlice001.suite ()),
                  TestLabel ("CharArraySlice101", CharArraySlice101.suite ()),
                  TestLabel ("CharVector001", CharVector001.suite ()),
                  TestLabel ("CharVector101", CharVector101.suite ()),
                  TestLabel ("CharVectorSlice001", CharVectorSlice001.suite ()),
                  TestLabel ("CharVectorSlice101", CharVectorSlice101.suite ()),
                  TestLabel ("Date001", Date001.suite ()),
                  TestLabel ("General001", General001.suite ()),
                  TestLabel ("IEEEReal001", IEEEReal001.suite ()),
                  TestLabel ("Int001", Int001.suite ()),
                  TestLabel ("LargeInt001", LargeInt001.suite ()),
                  TestLabel ("LargeWord001", LargeWord001.suite ()),
                  TestLabel ("List001", List001.suite ()),
                  TestLabel ("ListPair001", ListPair001.suite ()),
                  TestLabel ("Math001", Math001.suite ()),
                  TestLabel ("Option001", Option001.suite ()),
                  TestLabel ("Position001", Position001.suite ()),
                  TestLabel ("Real001", Real001.suite ()),
                  TestLabel ("String001", String001.suite ()),
                  TestLabel ("StringCvt001", StringCvt001.suite ()),
                  TestLabel ("Substring001", Substring001.suite ()),
                  TestLabel ("Time001", Time001.suite ()),
                  TestLabel ("Vector001", Vector001.suite ()),
                  TestLabel ("Vector101", Vector101.suite ()),
                  TestLabel ("VectorSlice001", VectorSlice001.suite ()),
                  TestLabel ("VectorSlice101", VectorSlice101.suite ()),
                  TestLabel ("Word001", Word001.suite ()),
                  TestLabel ("Word8001", Word8001.suite ()),
                  TestLabel ("Word8Array001", Word8Array001.suite ()),
                  TestLabel ("Word8Array101", Word8Array101.suite ()),
                  TestLabel ("Word8ArraySlice001", Word8ArraySlice001.suite ()),
                  TestLabel ("Word8ArraySlice101", Word8ArraySlice101.suite ()),
                  TestLabel ("Word8Vector001", Word8Vector001.suite ()),
                  TestLabel ("Word8Vector101", Word8Vector101.suite ()),
                  TestLabel ("Word8VectorSlice101", Word8VectorSlice101.suite ()),
                  TestLabel ("Word8VectorSlice001", Word8VectorSlice001.suite ())
                ]
      in
        tests
      end
  end (* local *)

end