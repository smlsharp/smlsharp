use "./DataTypes2Testee.sml";

(*
 * test cases for passing array between SML world and OLE world.
 *)
structure DataTypes2Tester =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure T = DataTypes2Testee

  open AssertOLEValue
  open AssertDotNETValue

  (**********)

  fun testSub1 () =
      let
        val obj = T.newDataTypes2Testee ()
        val va = (Array.fromList [OLE.I4 1, OLE.I4 2, OLE.I4 3], [0w3])
        val _ = assertEqualVARIANTARRAY va (#method_object obj va)
        val _ = assertEqualVariant (OLE.I4 1) (#sub_object obj (va, 0))
      in
        ()
      end

  (******************************************)

  fun init () =
      let
      in
        ()
      end

  fun suite () =
      Test.labelTests
      [
        ("testSub1", testSub1)
      ]

end