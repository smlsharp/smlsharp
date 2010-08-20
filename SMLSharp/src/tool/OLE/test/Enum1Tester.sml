use "./Enum1Testee.sml";

(**
 * test cases for enum.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Enum1Tester =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure T = Enum1Testee

  open AssertOLEValue
  open AssertDotNETValue

  (**********)

  fun testEnumInt1 () =
      let
        val _ = assertEqualint 0 T.Enum_I_I1
        val _ = assertEqualint 1 T.Enum_I_I2
        val _ = assertEqualint 2 T.Enum_I_I3
      in
        ()
      end

  fun testEnumInt2 () =
      let
        val _ = assertEqualint 100 T.Enum_I100_I100
        val _ = assertEqualint 200 T.Enum_I100_I200
        val _ = assertEqualint 300 T.Enum_I100_I300
      in
        ()
      end

  fun testEnumInt3 () =
      let
        val _ = assertEqualint ~0x80000000 T.Enum_IBig_IMIN
        val _ = assertEqualint 0x7FFFFFFF T.Enum_IBig_IMAX
      in
        ()
      end

  fun testEnumUInt1 () =
      let
        val _ = assertEqualint ~1 T.Enum_UIBig_UIMAX
      in
        ()
      end

  fun testEnumLong1 () =
      let
        val _ = assertEqualint 0 T.Enum_L_L1
        val _ = assertEqualint 1 T.Enum_L_L2
        val _ = assertEqualint 2 T.Enum_L_L3
      in
        ()
      end

  fun testEnumByte1 () =
      let
        val _ = assertEqualint 0 T.Enum_B_B1
        val _ = assertEqualint 1 T.Enum_B_B2
        val _ = assertEqualint 2 T.Enum_B_B3
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
        ("testEnumInt1", testEnumInt1),
        ("testEnumInt2", testEnumInt2),
        ("testEnumInt3", testEnumInt3),
        ("testEnumUInt1", testEnumUInt1),
        ("testEnumLong1", testEnumLong1),
        ("testEnumByte1", testEnumByte1)
      ]

end