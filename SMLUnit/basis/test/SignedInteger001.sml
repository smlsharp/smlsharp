(**
 * test cases for Int structure.
 *
 * This module is used as a test case for IntInf structure by copying this
 * and replacing 'Int' to 'IntInf'.
 * 
 * In order to avoid the duplication of the source code, it is possible to
 * convert this module to a functor and derive test cases for each of Int and
 * IntInf from the functor. But it will make the source code less readable.
 * For example, integer literals in this module have to be replaced with
 * variables which are passed in functor parameters.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
functor SignedInteger001
            (I
             : sig
                 include INTEGER
                 val assertEqualInt : int SMLUnit.Assert.assertEqual
               end) =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  structure LI = LargeInt

  (************************************************************)

  val assertEqualInt = I.assertEqualInt
  val assertEqualIntOption = assertEqualOption assertEqualInt
  val assertEqualISOption =
      assertEqualOption (assertEqual2Tuple (assertEqualInt, assertEqualString))
  val assertEqualICListOption =
      assertEqualOption
          (assertEqual2Tuple (assertEqualInt, assertEqualCharList))

  val assertEqual2Int = assertEqual2Tuple (assertEqualInt, assertEqualInt)

  val assertEqual4Bool =
      assertEqual4Tuple
          (assertEqualBool, assertEqualBool, assertEqualBool, assertEqualBool)

  val I2i = I.fromLarge
  val i2I = I.toLarge

  val [p0, p1, p2, p3, p4, p5, p6, p7, p8, p9] =
      List.tabulate (10, I2i o Int.toLarge)
  val [n0, n1, n2, n3, n4, n5, n6, n7, n8, n9] =
      List.tabulate (10, I2i o Int.toLarge o Int.~)
  val p11 = I2i 11
  val n11 = I2i ~11
  val p123 = I2i 123
  val n123 = I2i ~123

  (********************)

  fun tilda001 () =
      let
        val tilda_m = I.~ (I.-(p0, p1))
        val _ = assertEqualInt p1 tilda_m

        val tilda_z = I.~ (I.-(p1, p1))
        val _ = assertEqualInt p0 tilda_z

        val tilda_p = I.~ (I.+(p0, p1))
        val _ = assertEqualInt n1 tilda_p
      in () end

  (********************)

  local
    fun test operator arg expected = assertEqualInt expected (operator arg)
    fun testFailDiv operator args =
        (operator args; fail "Div expected.") handle General.Div => ()
  in

  local val test = test I.*
  in
  fun mul001 () =
      let
        val mul_mm = test (n2, n3) p6
        val mul_mp = test (n2, p3) n6
        val mul_pm = test (p2, n3) n6
        val mul_pp = test (p2, p3) p6
        val mul_zp = test (p0, p3) p0
        val mul_pz = test (p3, p0) p0
        val mul_zz = test (p0, p0) p0
      in () end
  end (* inner local *)

  (********************)

  local
    val test = test I.div
    val testFailDiv = testFailDiv I.div
  in
  fun div001 () =
      let
        val div_mm = test (n8, n3) p2
        val div_mp = test (n8, p3) n3
        val div_pm = test (p8, n3) n3
        val div_pp = test (p8, p3) p2
        val div_zp = test (p0, p3) p0
        val div_pz = testFailDiv (p8, p0)
        val div_zz = testFailDiv (p0, p0)
      in () end
  end (* inner local *)

  (********************)

  local
    val test = test I.mod
    val testFailDiv = testFailDiv I.mod
  in
  fun mod001 () =
      let
        val mod_mm = test (n8, n3) n2
        val mod_mp = test (n8, p3) p1
        val mod_pm = test (p8, n3) n1
        val mod_pp = test (p8, p3) p2
        val mod_zp = test (p0, p3) p0
        val mod_pz = testFailDiv (p8, p0)
        val mod_zz = testFailDiv (p0, p0)
      in () end
  end (* inner local *)

  (********************)

  local
    val test = test I.quot
    val testFailDiv = testFailDiv I.quot
  in
  fun quot001 () =
      let
        val quot_mm = test (n8, n3) p2
        val quot_mp = test (n8, p3) n2
        val quot_pm = test (p8, n3) n2
        val quot_pp = test (p8, p3) p2
        val quot_zp = test (p0, p3) p0
        val quot_pz = testFailDiv (p8, p0)
        val quot_zz = testFailDiv (p0, p0)
      in () end
  end (* inner local *)

  (********************)

  local
    val test = test I.rem
    val testFailDiv = testFailDiv I.rem
  in
  fun rem001 () =
      let
        val rem_mm = test (n8, n3) n2
        val rem_mp = test (n8, p3) n2
        val rem_pm = test (p8, n3) p2
        val rem_pp = test (p8, p3) p2
        val rem_zp = test (p0, p3) p0
        val rem_pz = testFailDiv (p8, p0)
        val rem_zz = testFailDiv (p0, p0)
      in () end
  end (* inner local *)

  (********************)

  local val test = test I.+
  in
  fun add001 () =
      let
        val add_mm = test (n8, n3) n11
        val add_mp = test (n8, p3) n5
        val add_pm = test (p8, n3) p5
        val add_pp = test (p8, p3) p11
        val add_zp = test (p0, p3) p3
        val add_pz = test (p8, p0) p8
        val add_zz = test (p0, p0) p0
      in () end
  end (* inner local *)

  (********************)

  local val test = test I.-
  in
  fun sub001 () =
      let
        val sub_mm = test (n8, n3) n5
        val sub_mp = test (n8, p3) n11
        val sub_pm = test (p8, n3) p11
        val sub_pp = test (p8, p3) p5
        val sub_zp = test (p0, p3) n3
        val sub_pz = test (p8, p0) p8
        val sub_zz = test (p0, p0) p0
      in () end
  end (* inner local *)

  end (* outer local *)

  (********************)

  local
    fun test arg expected = assertEqualOrder expected (I.compare arg)
  in
  fun compare001 () =
      let
        val compare_mmL = test (n8, n3) LESS
        val compare_mmE = test (n8, n8) EQUAL
        val compare_mmG = test (n3, n8) GREATER
        val compare_mp = test (n8, p3) LESS
        val compare_pm = test (p8, n3) GREATER
        val compare_ppL = test (p3, p8) LESS
        val compare_ppE = test (p8, p8) EQUAL
        val compare_ppG = test (p8, p3) GREATER
        val compare_zp = test (p0, p3) LESS
        val compare_pz = test (p8, p0) GREATER
        val compare_zz = test (p0, p0) EQUAL
      in () end
  end (* local *)

  (********************)

  local
    val TTTT = (true, true, true, true)
    val TTFF = (true, true, false, false)
    val TFTF = (true, false, true, false)
    val FTTT = (false, true, true, true)
    val FTTF = (false, true, true, false)
    val FTFF = (false, true, false, false)
    val FFTT = (false, false, true, true)
    val FFFF = (false, false, false, false)
    fun test args expected =
        let
          val r = (I.< args, I.<= args, I.>= args, I.> args)
          val _ = assertEqual4Bool expected r
        in () end
  in
  fun binComp001 () =
      let
        val binComp_mmL = test (n8, n3) TTFF
        val binComp_mmE = test (n8, n8) FTTF
        val binComp_mmG = test (n3, n8) FFTT
        val binComp_mp = test (n8, p3) TTFF
        val binComp_pm = test (p8, n3) FFTT
        val binComp_ppL = test (p3, p8) TTFF
        val binComp_ppE = test (p8, p8) FTTF
        val binComp_ppG = test (p8, p3) FFTT
        val binComp_zp = test (p0, p3) TTFF
        val binComp_pz = test (p8, p0) FFTT
        val binComp_zz = test (p0, p0) FTTF
      in () end
  end (* local *)

  (********************)

  fun abs001 () =
      let
        val abs_m = I.abs (I.-(p0, p1))
        val _ = assertEqualInt p1 abs_m

        val abs_z = I.abs p0
        val _ = assertEqualInt p0 abs_z

        val abs_p = I.abs p1
        val _ = assertEqualInt p1 abs_p
      in () end

  (********************)

  local
    fun test arg expected = assertEqual2Int expected (I.min arg, I.max arg)
  in
  fun minMax001 () =
      let
        val minMax_mmL = test (n8, n3) (n8, n3)
        val minMax_mmE = test (n8, n8) (n8, n8)
        val minMax_mmG = test (n3, n8) (n8, n3)
        val minMax_mp = test (n8, p3) (n8, p3)
        val minMax_pm = test (p8, n3) (n3, p8)
        val minMax_ppL = test (p3, p8) (p3, p8)
        val minMax_ppE = test (p8, p8) (p8, p8)
        val minMax_ppG = test (p8, p3) (p3, p8)
        val minMax_zp = test (p0, p3) (p0, p3)
        val minMax_pz = test (p8, p0) (p0, p8)
        val minMax_zz = test (p0, p0) (p0, p0)
      in () end
  end (* local *)

  (********************)

  fun sign001 () =
      let
        val sign_m = I.sign (I.-(p0, p1))
        val _ = A.assertEqualInt ~1 sign_m

        val sign_z = I.sign p0
        val _ = A.assertEqualInt 0 sign_z

        val sign_p = I.sign p1
        val _ = A.assertEqualInt 1 sign_p
      in () end

  (********************)

  local
    fun test arg expected = assertEqualBool expected (I.sameSign arg)
  in
  fun sameSign001 () =
      let
        val sameSign_mm = test (n1, n2) true
        val sameSign_mz = test (n1, p0) false
        val sameSign_mp = test (n1, p2) false
        val sameSign_zm = test (p0, n2) false
        val sameSign_zz = test (p0, p0) true
        val sameSign_zp = test (p0, p2) false
        val sameSign_pm = test (p1, n2) false
        val sameSign_pz = test (p1, p0) false
        val sameSign_pp = test (p1, p2) true
      in () end
  end (* local *)

  (********************)

  local
    fun test arg1 arg2 expected = assertEqualString expected (I.fmt arg1 arg2)
  in

  fun fmt_bin001 () =
      let
        val fmt_bin_m1 = test StringCvt.BIN n1 "~1"
        val fmt_bin_m2 = test StringCvt.BIN n123 "~1111011"
        val fmt_bin_z = test StringCvt.BIN p0 "0"
        val fmt_bin_p1 = test StringCvt.BIN p1 "1"
        val fmt_bin_p2 = test StringCvt.BIN p123 "1111011"
      in () end

  fun fmt_oct001 () =
      let
        val fmt_oct_m1 = test StringCvt.OCT n1 "~1"
        val fmt_oct_m2 = test StringCvt.OCT n123 "~173"
        val fmt_oct_z = test StringCvt.OCT p0 "0"
        val fmt_oct_p1 = test StringCvt.OCT p1 "1"
        val fmt_oct_p2 = test StringCvt.OCT p123 "173"
      in () end

  fun fmt_dec001 () =
      let
        val fmt_dec_m1 = test StringCvt.DEC n1 "~1"
        val fmt_dec_m2 = test StringCvt.DEC n123 "~123"
        val fmt_dec_z = test StringCvt.DEC p0 "0"
        val fmt_dec_p1 = test StringCvt.DEC p1 "1"
        val fmt_dec_p2 = test StringCvt.DEC p123 "123"
      in () end

  fun fmt_hex001 () =
      let
        val fmt_hex_m1 = test StringCvt.HEX n1 "~1"
        val fmt_hex_m2 = test StringCvt.HEX n123 "~7B"
        val fmt_hex_z = test StringCvt.HEX p0 "0"
        val fmt_hex_p1 = test StringCvt.HEX p1 "1"
        val fmt_hex_p2 = test StringCvt.HEX p123 "7B"
      in () end

  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualString expected (I.toString arg)
  in
  fun toString001 () =
      let
        val toString_m1 = test n1 "~1"
        val toString_m2 = test n123 "~123"
        val toString_z = test p0 "0"
        val toString_p1 = test p1 "1"
        val toString_p2 = test p123 "123"
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualIntOption expected (I.fromString arg)
  in
  fun fromString001 () =
      let
        val fromString_null = test "" NONE
        val fromString_nonum = test "abc123def" NONE
        val fromString_m1 = test "~1" (SOME n1)
        val fromString_m12 = test "~1abc" (SOME n1)
        val fromString_m13 = test " \t\v\f\n\r~1abc" (SOME n1)
        val fromString_m2 = test "~123" (SOME n123)
        val fromString_m22 = test "~123abc" (SOME n123)
        val fromString_z1 = test "0" (SOME p0)
        val fromString_z12 = test "00" (SOME p0)
        val fromString_z12 = test "00abc" (SOME p0)
        val fromString_p1 = test "1" (SOME p1)
        val fromString_p12 = test "1abc" (SOME p1)
        val fromString_p2 = test "123" (SOME p123)
        (* ignore trailer *)
        val fromString_p22 = test "123abc" (SOME p123)
        (* skip initial whitespaces *)
        val fromString_p23 = test " \t\v\f\n\r123abc" (SOME p123)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg1 arg2 expected =
        assertEqualISOption
            expected
            (Option.map
                 (fn (n, cs) => (n, implode cs))
                 (I.scan arg1 List.getItem (explode arg2)))
  in

  fun scan_bin001 () =
      let
        val scan_bin_null = test StringCvt.BIN "" NONE
        val scan_bin_0 = test StringCvt.BIN "0" (SOME(p0, ""))
        val scan_bin_01 = test StringCvt.BIN "00" (SOME(p0, ""))
        val scan_bin_p0 = test StringCvt.BIN "+0" (SOME(p0, ""))
        val scan_bin_t0 = test StringCvt.BIN "~0" (SOME(p0, ""))
        val scan_bin_m0 = test StringCvt.BIN "-0" (SOME(p0, ""))
        val scan_bin_t1 = test StringCvt.BIN "~1" (SOME(n1, ""))
        val scan_bin_t1b = test StringCvt.BIN "~1abc" (SOME(n1, "abc"))
        val scan_bin_t1c = test StringCvt.BIN "~01" (SOME(n1, ""))
        val scan_bin_m1 = test StringCvt.BIN "-1" (SOME(n1, ""))
        val scan_bin_m1b = test StringCvt.BIN "-1abc" (SOME(n1, "abc"))
        val scan_bin_m1c = test StringCvt.BIN "-01" (SOME(n1, ""))
        val scan_bin_p1 = test StringCvt.BIN "+1" (SOME(p1, ""))
        val scan_bin_p1b = test StringCvt.BIN "+1abc" (SOME(p1, "abc"))
        val scan_bin_p1c = test StringCvt.BIN "+01" (SOME(p1, ""))
        val scan_bin_1 = test StringCvt.BIN "1" (SOME(p1, ""))
        val scan_bin_1b = test StringCvt.BIN "1abc" (SOME(p1, "abc"))
        val scan_bin_1c = test StringCvt.BIN "01" (SOME(p1, ""))
      in () end

  fun scan_oct001 () =
      let
        val scan_oct_null = test StringCvt.OCT "" NONE
        val scan_oct_0 = test StringCvt.OCT "0" (SOME(p0, ""))
        val scan_oct_01 = test StringCvt.OCT "00" (SOME(p0, ""))
        val scan_oct_p0 = test StringCvt.OCT "+0" (SOME(p0, ""))
        val scan_oct_t0 = test StringCvt.OCT "~0" (SOME(p0, ""))
        val scan_oct_m0 = test StringCvt.OCT "-0" (SOME(p0, ""))
        val scan_oct_t173 = test StringCvt.OCT "~173" (SOME(n123, ""))
        val scan_oct_t173b = test StringCvt.OCT "~17389a" (SOME(n123, "89a"))
        val scan_oct_t173c = test StringCvt.OCT "~0173" (SOME(n123, ""))
        val scan_oct_m173 = test StringCvt.OCT "-173" (SOME(n123, ""))
        val scan_oct_m173b = test StringCvt.OCT "-17389a" (SOME(n123, "89a"))
        val scan_oct_m173c = test StringCvt.OCT "-0173" (SOME(n123, ""))
        val scan_oct_p173 = test StringCvt.OCT "+173" (SOME(p123, ""))
        val scan_oct_p173b = test StringCvt.OCT "+17389a" (SOME(p123, "89a"))
        val scan_oct_p173c = test StringCvt.OCT "+0173" (SOME(p123, ""))
        val scan_oct_173 = test StringCvt.OCT "173" (SOME(p123, ""))
        val scan_oct_173b = test StringCvt.OCT "17389a" (SOME(p123, "89a"))
        val scan_oct_173c = test StringCvt.OCT "0173" (SOME(p123, ""))
      in () end

  fun scan_dec001 () =
      let
        val scan_dec_null = test StringCvt.DEC "" NONE
        val scan_dec_0 = test StringCvt.DEC "0" (SOME(p0, ""))
        val scan_dec_01 = test StringCvt.DEC "00" (SOME(p0, ""))
        val scan_dec_p0 = test StringCvt.DEC "+0" (SOME(p0, ""))
        val scan_dec_t0 = test StringCvt.DEC "~0" (SOME(p0, ""))
        val scan_dec_m0 = test StringCvt.DEC "-0" (SOME(p0, ""))
        val scan_dec_t123 = test StringCvt.DEC "~123" (SOME(n123, ""))
        val scan_dec_t123b = test StringCvt.DEC "~123a" (SOME(n123, "a"))
        val scan_dec_t123c = test StringCvt.DEC "~0123" (SOME(n123, ""))
        val scan_dec_m123 = test StringCvt.DEC "-123" (SOME(n123, ""))
        val scan_dec_m123b = test StringCvt.DEC "-123a" (SOME(n123, "a"))
        val scan_dec_m123c = test StringCvt.DEC "-0123" (SOME(n123, ""))
        val scan_dec_p123 = test StringCvt.DEC "+123" (SOME(p123, ""))
        val scan_dec_p123b = test StringCvt.DEC "+123a" (SOME(p123, "a"))
        val scan_dec_p123c = test StringCvt.DEC "+0123" (SOME(p123, ""))
        val scan_dec_123 = test StringCvt.DEC "123" (SOME(p123, ""))
        val scan_dec_123b = test StringCvt.DEC "123a" (SOME(p123, "a"))
        val scan_dec_123c = test StringCvt.DEC "0123" (SOME(p123, ""))
      in () end

  fun scan_hex001 () =
      let
        val scan_hex_null = test StringCvt.HEX "" NONE
        val scan_hex_head1 = test StringCvt.HEX "0x " (SOME(p0, "x "))
        val scan_hex_head2 = test StringCvt.HEX "0X " (SOME(p0, "X "))
        val scan_hex_0 = test StringCvt.HEX "0" (SOME(p0, ""))
        val scan_hex_01 = test StringCvt.HEX "00" (SOME(p0, ""))
        val scan_hex_0h1 = test StringCvt.HEX "0x0" (SOME(p0, ""))
        val scan_hex_0h2 = test StringCvt.HEX "0X0" (SOME(p0, ""))
        val scan_hex_p0 = test StringCvt.HEX "+0" (SOME(p0, ""))
        val scan_hex_p0h1 = test StringCvt.HEX "+0x0" (SOME(p0, ""))
        val scan_hex_p0h2 = test StringCvt.HEX "+0X0" (SOME(p0, ""))
        val scan_hex_t0 = test StringCvt.HEX "~0" (SOME(p0, ""))
        val scan_hex_m0 = test StringCvt.HEX "-0" (SOME(p0, ""))
        (* 0x7B = 123 *)
        val scan_hex_t7B = test StringCvt.HEX "~7B" (SOME(n123, ""))
        val scan_hex_t7Bb = test StringCvt.HEX "~7BGg" (SOME(n123, "Gg"))
        val scan_hex_t7Bb_h1 = test StringCvt.HEX "~0x7BGg" (SOME(n123, "Gg"))
        val scan_hex_t7Bb_h2 = test StringCvt.HEX "~0X7BGg" (SOME(n123, "Gg"))
        val scan_hex_t7Bc = test StringCvt.HEX "~07B" (SOME(n123, ""))
        val scan_hex_m7B = test StringCvt.HEX "-7B" (SOME(n123, ""))
        val scan_hex_m7Bb = test StringCvt.HEX "-7BGg" (SOME(n123, "Gg"))
        val scan_hex_m7Bb_h1 = test StringCvt.HEX "-0x7BGg" (SOME(n123, "Gg"))
        val scan_hex_m7Bb_h2 = test StringCvt.HEX "-0X7BGg" (SOME(n123, "Gg"))
        val scan_hex_m7Bc = test StringCvt.HEX "-07B" (SOME(n123, ""))
        val scan_hex_p7B = test StringCvt.HEX "+7B" (SOME(p123, ""))
        val scan_hex_p7Bb = test StringCvt.HEX "+7BGg" (SOME(p123, "Gg"))
        val scan_hex_p7Bb_h1 = test StringCvt.HEX "+0x7BGg" (SOME(p123, "Gg"))
        val scan_hex_p7Bb_h2 = test StringCvt.HEX "+0X7BGg" (SOME(p123, "Gg"))
        val scan_hex_p7Bc = test StringCvt.HEX "+07B" (SOME(p123, ""))
        val scan_hex_7B = test StringCvt.HEX "7B" (SOME(p123, ""))
        val scan_hex_7Bb = test StringCvt.HEX "7BGg" (SOME(p123, "Gg"))
        val scan_hex_7Bb_h1 = test StringCvt.HEX "0x7BGg" (SOME(p123, "Gg"))
        val scan_hex_7Bb_h2 = test StringCvt.HEX "0X7BGg" (SOME(p123, "Gg"))
        val scan_hex_7Bc = test StringCvt.HEX "07B" (SOME(p123, ""))
      in () end

  fun scan_skipWS001 () =
      let
        val scan_skipWS1 = test StringCvt.DEC "  123" (SOME(p123, ""))
        val scan_skipWS2 = test StringCvt.DEC "\t\n\v\f\r123" (SOME(p123, ""))
      in () end

  end (* local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("tilda001", tilda001),
        ("mul001", mul001),
        ("div001", div001),
        ("mod001", mod001),
        ("quot001", quot001),
        ("rem001", rem001),
        ("add001", add001),
        ("sub001", sub001),
        ("compare001", compare001),
        ("binComp001", binComp001),
        ("abs001", abs001),
        ("minMax001", minMax001),
        ("sign001", sign001),
        ("sameSign001", sameSign001),
        ("fmt_bin001", fmt_bin001),
        ("fmt_oct001", fmt_oct001),
        ("fmt_dec001", fmt_dec001),
        ("fmt_hex001", fmt_hex001),
        ("toString001", toString001),
        ("fromString001", fromString001),
        ("scan_bin001", scan_bin001),
        ("scan_oct001", scan_oct001),
        ("scan_dec001", scan_dec001),
        ("scan_hex001", scan_hex001),
        ("scan_skipWS001", scan_skipWS001)
      ]

  (************************************************************)

end