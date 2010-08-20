use "./DataTypes2Testee.sml";

(**
 * test cases for passing array between SML world and OLE world.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure DataTypes2Tester =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure T = DataTypes2Testee

  open AssertOLEValue
  open AssertDotNETValue

  (**********)

  fun testbyte () =
      let
        val obj = T.newDataTypes2Testee ()
        val va = (Array.fromList [0w1, 0w2, 0w3], [3])
        val _ = assertEqualUI1ARRAY va (#method_byte obj va)
        val _ = assertEqualbyte 0w2 (#sub_byte obj (va, 1))
      in
        ()
      end

  fun testsbyte () =
      let
        val obj = T.newDataTypes2Testee ()
        val va = (Array.fromList [~1, ~2, ~3], [3])
        val _ = assertEqualI1ARRAY va (#method_sbyte obj va)
        val _ = assertEqualsbyte ~2 (#sub_sbyte obj (va, 1))
      in
        ()
      end

  fun testshort () =
      let
        val obj = T.newDataTypes2Testee ()
        val va = (Array.fromList [1, 2, 3], [3])
        val _ = assertEqualI2ARRAY va (#method_short obj va)
        val _ = assertEqualshort 2 (#sub_short obj (va, 1))
      in
        ()
      end

  fun testushort () =
      let
        val obj = T.newDataTypes2Testee ()
        val va = (Array.fromList [0w1, 0w2, 0w3], [3])
        val _ = assertEqualUI2ARRAY va (#method_ushort obj va)
        val _ = assertEqualushort 0w2 (#sub_ushort obj (va, 1))
      in
        ()
      end

  fun testint () =
      let
        val obj = T.newDataTypes2Testee ()
        val va = (Array.fromList [1, 2, 3], [3])
        val _ = assertEqualI4ARRAY va (#method_int obj va)
        val _ = assertEqualint 2 (#sub_int obj (va, 1))
      in
        ()
      end

  fun testuint () =
      let
        val obj = T.newDataTypes2Testee ()
        val va = (Array.fromList [0w1, 0w2, 0w3], [3])
        val _ = assertEqualUI4ARRAY va (#method_uint obj va)
        val _ = assertEqualuint 0w2 (#sub_uint obj (va, 1))
      in
        ()
      end

  fun testlong () =
      let
        val obj = T.newDataTypes2Testee ()
        val va = (Array.fromList [~1, ~2, ~3], [3])
        val _ = assertEqualI8ARRAY va (#method_long obj va)
        val _ = assertEquallong ~2 (#sub_long obj (va, 1))
      in
        ()
      end

  fun testulong () =
      let
        val obj = T.newDataTypes2Testee ()
        val va = (Array.fromList [1, 2, 3], [3])
        val _ = assertEqualUI8ARRAY va (#method_ulong obj va)
        val _ = assertEqualulong 2 (#sub_ulong obj (va, 1))
      in
        ()
      end

  fun testfloat () =
      let
        val obj = T.newDataTypes2Testee ()
        val va = (Array.fromList [1.23, 2.34, 3.45], [3])
        val _ = assertEqualR4ARRAY va (#method_float obj va)
        val _ = assertEqualfloat 2.34 (#sub_float obj (va, 1))
      in
        ()
      end

  fun testdouble () =
      let
        val obj = T.newDataTypes2Testee ()
        val va = (Array.fromList [1.23, 2.34, 3.45], [3])
        val _ = assertEqualR8ARRAY va (#method_double obj va)
        val _ = assertEqualdouble 2.34 (#sub_double obj (va, 1))
      in
        ()
      end

  fun testdecimal () =
      let
        val obj = T.newDataTypes2Testee ()
        val x0 = {scale = 0w0, value = 1}
        val x1 = {scale = 0w0, value = 10}
        val x2 = {scale = 0w0, value = 100}
        val va = (Array.fromList [x0, x1, x2], [3])
        val _ = assertEqualDECIMALARRAY va (#method_decimal obj va)
        val _ = assertEqualdecimal x1 (#sub_decimal obj (va, 1))
      in
        ()
      end

  fun teststring () =
      let
        val obj = T.newDataTypes2Testee ()
        val va = (Array.fromList [OLE.L"A", OLE.L"B", OLE.L"C"], [3])
        val _ = assertEqualBSTRARRAY va (#method_string obj va)
        val _ = assertEqualstring (OLE.L"B") (#sub_string obj (va, 1))
      in
        ()
      end

  fun testbool () =
      let
        val obj = T.newDataTypes2Testee ()
        val va = (Array.fromList [true, false, true], [3])
        val _ = assertEqualBOOLARRAY va (#method_bool obj va)
        val _ = assertEqualbool false (#sub_bool obj (va, 1))
      in
        ()
      end

  fun testobject () =
      let
        val obj = T.newDataTypes2Testee ()
        val x0 = OLE.DISPATCH(#this (T.newDataTypes2Testee ()) ())
        val x1 = OLE.DISPATCH(#this (T.newDataTypes2Testee ()) ())
        val x2 = OLE.DISPATCH(#this (T.newDataTypes2Testee ()) ())
        val va = (Array.fromList [x0, x1, x2], [3])
        val _ = assertEqualVARIANTARRAY va (#method_object obj va)
        val _ = assertEqualobject x1 (#sub_object obj (va, 1))
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
        ("testbyte", testbyte),
        ("testsbyte", testsbyte),
        ("testshort", testshort),
        ("testushort", testushort),
        ("testint", testint),
        ("testuint", testuint),
        ("testlong", testlong),
        ("testulong", testulong),
        ("testfloat", testfloat),
        ("testdouble", testdouble),
        ("testdecimal", testdecimal),
(*
        ("testchar", testchar),
*)
        ("teststring", teststring),
        ("testbool", testbool),
        ("testobject", testobject)
      ]

end