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
               end) : sig
  val suite : unit -> SMLUnit.Test.test
end =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  structure AI = AssertInt
  structure ALI = AssertLargeInt
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
  val I2Int = Int.fromLarge

  val [p0, p1, p2, p3, p4, p5, p6, p7, p8, p9] =
      List.tabulate (10, I2i o Int.toLarge)
  val [n0, n1, n2, n3, n4, n5, n6, n7, n8, n9] =
      List.tabulate (10, I2i o Int.toLarge o Int.~)
  val p11 = I2i 11
  val n11 = I2i ~11
  val p123 = I2i 123
  val n123 = I2i ~123

  val (maxIntInt, maxIntInt_I) =
      (case Int.precision
        of SOME 31 => (I2i 0x3FFFFFFF, I2Int 0x3FFFFFFF)
         | SOME 32 => (I2i 0x7FFFFFFF, I2Int 0x7FFFFFFF)
         | SOME 64 => (I2i 0x7FFFFFFFFFFFFFFF, I2Int 0x7FFFFFFFFFFFFFFF)
         | NONE => (I2i 0x7FFFFFFFFFFFFFFF, I2Int 0x7FFFFFFFFFFFFFFF)) (* ? *)
      handle General.Overflow =>
              (* if I.precision < Int.precision *) (I2i 0, I2Int 0)
  val (minIntInt, minIntInt_I) =
      (case Int.precision
        of SOME 31 => (I2i ~0x40000000, I2Int ~0x40000000)
         | SOME 32 => (I2i ~0x80000000, I2Int ~0x80000000)
         | SOME 64 => (I2i ~0x8000000000000000, I2Int ~0x8000000000000000)
         | NONE => (I2i ~0x8000000000000000, I2Int ~0x8000000000000000))(* ? *)
      handle General.Overflow =>
             (* if I.precision < Int.precision *) (I2i 0, I2Int 0)

  val (maxInt, maxInt_L : LargeInt.int) =
      case I.precision
       of SOME 31 => (I2i 0x3FFFFFFF, 0x3FFFFFFF)
        | SOME 32 => (I2i 0x7FFFFFFF, 0x7FFFFFFF)
        | SOME 64 => (I2i 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF)
        | NONE =>  (I2i 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF) (* ? *)
  val (minInt, minInt_L : LargeInt.int) =
      case I.precision
       of SOME 31 => (I2i ~0x40000000, ~0x40000000)
        | SOME 32 => (I2i ~0x80000000, ~0x80000000)
        | SOME 64 => (I2i ~0x8000000000000000, ~0x8000000000000000)
        | NONE => (I2i ~0x8000000000000000, ~0x8000000000000000) (* ? *)

  (********************)

  local
    fun test arg expected = ALI.assertEqualInt expected (I.toLarge arg)
  in
  fun toLarge001 () =
      let
        val case_p1 as () = test (I2i 1) 1
        val case_zero as () = test (I2i 0) 0
        val case_n1 as () = test (I2i ~1) ~1
      in () end
  fun toLarge002 () =
      let
        val case_maxInt as () = test maxInt maxInt_L
        val case_minInt as () = test minInt minInt_L
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualInt expected (I.fromLarge arg)
    fun testFail arg =
        (I.fromLarge arg; fail "expect Overflow.")
        handle General.Overflow => ()
  in
  fun fromLargeInt001 () =
      let
        val case_p1 as () = test 1 (I2i 1)
        val case_zero as () = test 0 (I2i 0)
        val case_n1 as () = test ~1 (I2i ~1)
      in () end
  fun fromLargeInt002 () =
      let
        val case_maxInt as () = test maxInt_L maxInt
        val case_minInt as () = test minInt_L minInt
      in () end
  fun fromLargeInt101 () =
      if getOpt(I.precision, 999) < getOpt(LargeInt.precision, 999)
      then
        let
          val case_maxIntPlus1 as () = testFail (maxInt_L + 1)
          val case_minIntMinus1 as () = testFail (minInt_L - 1)
        in () end
      else ()
  end (* local *)
      
  (********************)

  local
    fun test arg expected = AI.assertEqualInt expected (I.toInt arg)
    fun testFail arg = (I.toInt arg; fail "expect Overflow")
                       handle General.Overflow => ()
  in
  fun toInt001 () =
      let
        val case_p1 as () = test (I2i 1) 1
        val case_zero as () = test (I2i 0) 0
        val case_n1 as () = test (I2i ~1) ~1
      in () end
  fun toInt002 () =
      if getOpt(I.precision, 999) <= getOpt(Int.precision, 999)
      then
        let
          val case_maxInt as () = test maxInt (I2Int maxInt_L)
          val case_minInt as () = test minInt (I2Int minInt_L)
        in () end
      else ()
  (* tests whether toInt raises Overflow when the precision of Int.int
   * is less than the precision of I.int. *)
  fun toInt101 () =
      if getOpt(Int.precision, 999) < getOpt(I.precision, 999)
      then
        let
          val case_maxIntPlus1 as () = testFail (I.+(maxIntInt, I2i 1))
          val case_minIntMinus1 as () = testFail (I.-(minIntInt, I2i 1))
        in () end
      else ()

  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualInt expected (I.fromInt arg)
    fun testFail arg =
        (I.fromInt arg; fail "expect Overflow.") handle General.Overflow => ()
  in
  fun fromInt001 () =
      let
        val case_p1 as () = test 1 (I2i 1)
        val case_zero as () = test 0 (I2i 0)
        val case_n1 as () = test ~1 (I2i ~1)
      in () end
  fun fromInt002 () =
      if getOpt(Int.precision, 999) <= getOpt(I.precision, 999)
      then
        let
          val case_maxInt as () = test maxIntInt_I maxIntInt
          val case_minInt as () = test minIntInt_I minIntInt
        in () end
      else ()
  fun fromInt101 () =
      if getOpt(I.precision, 999) < getOpt(Int.precision, 999)
      then
        let
          val case_maxIntPlus1 as () = testFail (I2Int maxInt_L + 1)
          val case_minIntMinus1 as () = testFail (I2Int minInt_L - 1)
        in () end
      else ()
  end (* local *)
      
  (********************)

  local
    fun test operator arg expected = assertEqualInt expected (operator arg)
    fun testOverflow operator args =
        (operator args; fail "expect Overflow.") handle General.Overflow => ()
    fun testDiv operator args =
        (operator args; fail "expect Div.") handle General.Div => ()
  in

  local
    val test = test I.+
    val testOverflow = testOverflow I.+
  in
  fun add001 () =
      let
        val case_mm as () = test (n8, n3) n11
        val case_mp as () = test (n8, p3) n5
        val case_pm as () = test (p8, n3) p5
        val case_pp as () = test (p8, p3) p11
        val case_zp as () = test (p0, p3) p3
        val case_pz as () = test (p8, p0) p8
        val case_zz as () = test (p0, p0) p0
      in () end
  fun add101 () =
      case I.precision
       of SOME _ =>
          let
            val case_maxInt_0 as () = test (maxInt, I2i 0) maxInt
(*
            val case_maxInt_p1 as () = testOverflow (maxInt, I2i 1)
            val case_maxInt_maxInt as () = testOverflow (maxInt, maxInt)
*)
            val case_maxInt_minInt as () =
                case I.precision
                 of SOME _ => test (maxInt, minInt) (I2i ~1)
                  | NONE => ()
                            
            val case_minInt_0 as () = test (minInt, I2i 0) minInt
(*
            val case_minInt_n1 as () = testOverflow (minInt, I2i ~1)
            val case_minInt_minInt as () = testOverflow (minInt, minInt)
*)
          in () end
        | NONE => ()
  end (* inner local *)

  (********************)

  local
    val test = test I.-
    val testOverflow = testOverflow I.-
  in
  fun sub001 () =
      let
        val case_mm as () = test (n8, n3) n5
        val case_mp as () = test (n8, p3) n11
        val case_pm as () = test (p8, n3) p11
        val case_pp as () = test (p8, p3) p5
        val case_zp as () = test (p0, p3) n3
        val case_pz as () = test (p8, p0) p8
        val case_zz as () = test (p0, p0) p0
      in () end
  fun sub101 () =
      case I.precision
       of SOME _ =>
          let
            val case_maxInt_0 as () = test (maxInt, I2i 0) maxInt
            val case_maxInt_maxInt as () = test (maxInt, maxInt) (I2i 0)

            val case_minInt_0 as () = test (minInt, I2i 0) minInt
(*
            val case_minInt_p1 as () = testOverflow (minInt, I2i 1)
*)
            val case_minInt_minInt as () = test (minInt, minInt) (I2i 0)
(*
            val case_0_minInt as () = testOverflow (I2i 0, minInt)
*)
          in () end
        | NONE => ()
  end (* inner local *)

  (********************)

  local
    val test = test I.*
    val testOverflow = testOverflow I.*
  in
  fun mul001 () =
      let
        val case_mm as () = test (n2, n3) p6
        val case_mp as () = test (n2, p3) n6
        val case_pm as () = test (p2, n3) n6
        val case_pp as () = test (p2, p3) p6
        val case_zp as () = test (p0, p3) p0
        val case_pz as () = test (p3, p0) p0
        val case_zz as () = test (p0, p0) p0
      in () end

  fun mul101 () =
      case I.precision
       of SOME prec =>
          let
(*
            val case_pp as () = testOverflow (maxInt, I2i 2)
            val case_nn as () = testOverflow (minInt, I2i ~1)
*)
          in () end
        | NONE => ()

  (* A test case where the multiplication causes an overflow but the lower bits
   * of the result of multiplication is greater than multiplicand and
   * multiplier.
   * 0x20000000 * 0xA = 0x140000000
   *                  =  0x40000000 (in 31/32bit)
   *)
  fun mul102 () =
      case I.precision
       of SOME prec => 
          let
            val left = case prec
                        of 31 => I2i 0x20000000
                         | 32 => I2i 0x20000000
                         | 64 => I2i 0x2000000000000000
            val right = I2i 0xA
(*
            val case_mulOverflow1 as () = testOverflow (left, right)
*)
          in () end
        | NONE => ()
  end (* inner local *)

  (********************)

  local
    val test = test I.div
    val testDiv = testDiv I.div
    val testOverflow = testOverflow I.div
  in
  fun div001 () =
      let
        val case_mm as () = test (n8, n3) p2
        val case_mp as () = test (n8, p3) n3
        val case_pm as () = test (p8, n3) n3
        val case_pp as () = test (p8, p3) p2
        val case_zp as () = test (p0, p3) p0
      in () end
  fun div101 () =
      let      
        val case_pz as () = testDiv (p8, p0)
        val case_zz as () = testDiv (p0, p0)
      in () end
  fun div102 () =
      case I.precision
       of SOME _ =>
          let
            val case_nn as () = testOverflow (minInt, I2i ~1)
          in () end
        | NONE => ()
  end (* inner local *)

  (********************)

  local
    val test = test I.mod
    val testDiv = testDiv I.mod
  in
  fun mod001 () =
      let
        val case_mm as () = test (n8, n3) n2
        val case_mp as () = test (n8, p3) p1
        val case_pm as () = test (p8, n3) n1
        val case_pp as () = test (p8, p3) p2
        val case_zp as () = test (p0, p3) p0
      in () end
  fun mod101 () =
      let
        val case_pz as () = testDiv (p8, p0)
        val case_zz as () = testDiv (p0, p0)
      in () end
  fun mod102 () =
      case I.precision
       of SOME _ =>
          let
            (* minInt mod ~1 succeeds, while minInt div ~1 overflow.. *)
            val case_nn as () = test (minInt, I2i ~1) p0
          in () end
        | NONE => ()
  end (* inner local *)

  (********************)

  local
    val test = test I.quot
    val testDiv = testDiv I.quot
    val testOverflow = testOverflow I.quot
  in
  fun quot001 () =
      let
        val case_mm as () = test (n8, n3) p2
        val case_mp as () = test (n8, p3) n2
        val case_pm as () = test (p8, n3) n2
        val case_pp as () = test (p8, p3) p2
        val case_zp as () = test (p0, p3) p0
      in () end
  fun quot101 () =
      let
        val case_pz as () = testDiv (p8, p0)
        val case_zz as () = testDiv (p0, p0)
      in () end
  fun quot102 () =
      case I.precision
       of SOME _ =>
          let
            val case_nn as () = testOverflow (minInt, I2i ~1)
          in () end
        | NONE => ()   
  end (* inner local *)

  (********************)

  local
    val test = test I.rem
    val testDiv = testDiv I.rem
  in
  fun rem001 () =
      let
        val case_mm as () = test (n8, n3) n2
        val case_mp as () = test (n8, p3) n2
        val case_pm as () = test (p8, n3) p2
        val case_pp as () = test (p8, p3) p2
        val case_zp as () = test (p0, p3) p0
      in () end
  fun rem101 () =
      let
        val case_pz as () = testDiv (p8, p0)
        val case_zz as () = testDiv (p0, p0)
      in () end
  fun rem102 () =
      case I.precision
       of SOME _ =>
          let
            (* minInt rem ~1 succeeds, while minInt quot ~1 overflows. *)
            val case_nn as () = test (minInt, I2i ~1) p0
          in () end
        | NONE => ()   
  end (* inner local *)

  end (* outer local *)

  (********************)

  local
    fun test arg expected = assertEqualOrder expected (I.compare arg)
  in
  fun compare001 () =
      let
        val case_mmL as () = test (n8, n3) LESS
        val case_mmE as () = test (n8, n8) EQUAL
        val case_mmG as () = test (n3, n8) GREATER
        val case_mp as () = test (n8, p3) LESS
        val case_pm as () = test (p8, n3) GREATER
        val case_ppL as () = test (p3, p8) LESS
        val case_ppE as () = test (p8, p8) EQUAL
        val case_ppG as () = test (p8, p3) GREATER
        val case_zp as () = test (p0, p3) LESS
        val case_pz as () = test (p8, p0) GREATER
        val case_zz as () = test (p0, p0) EQUAL
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
          val () = assertEqual4Bool expected r
        in () end
  in
  fun binComp001 () =
      let
        val case_mmL as () = test (n8, n3) TTFF
        val case_mmE as () = test (n8, n8) FTTF
        val case_mmG as () = test (n3, n8) FFTT
        val case_mp as () = test (n8, p3) TTFF
        val case_pm as () = test (p8, n3) FFTT
        val case_ppL as () = test (p3, p8) TTFF
        val case_ppE as () = test (p8, p8) FTTF
        val case_ppG as () = test (p8, p3) FFTT
        val case_zp as () = test (p0, p3) TTFF
        val case_pz as () = test (p8, p0) FFTT
        val case_zz as () = test (p0, p0) FTTF
      in () end
  end (* local *)

  (********************)

  fun tilda001 () =
      let
        val tilda_m = I.~ (I.-(p0, p1))
        val () = assertEqualInt p1 tilda_m

        val tilda_z = I.~ (I.-(p1, p1))
        val () = assertEqualInt p0 tilda_z

        val tilda_p = I.~ (I.+(p0, p1))
        val () = assertEqualInt n1 tilda_p
      in () end
  fun tilda101 () =
      case I.precision
       of SOME _ =>
          let
            val case_minInt as () = (I.~ minInt; fail "expect Overflow")
                               handle General.Overflow => ()
          in () end
        | NONE => ()

  (********************)

  fun abs001 () =
      let
        val abs_m = I.abs (I.-(p0, p1))
        val () = assertEqualInt p1 abs_m

        val abs_z = I.abs p0
        val () = assertEqualInt p0 abs_z

        val abs_p = I.abs p1
        val () = assertEqualInt p1 abs_p
      in () end
  fun abs101 () =
      case I.precision
       of SOME _ =>
          let
            val case_minInt as () =
                (I.abs minInt; fail "expect Overflow")
                handle General.Overflow => ()
          in () end
        | NONE => ()

  (********************)

  local
    fun test arg expected = assertEqual2Int expected (I.min arg, I.max arg)
  in
  fun minMax001 () =
      let
        val case_mmL as () = test (n8, n3) (n8, n3)
        val case_mmE as () = test (n8, n8) (n8, n8)
        val case_mmG as () = test (n3, n8) (n8, n3)
        val case_mp as () = test (n8, p3) (n8, p3)
        val case_pm as () = test (p8, n3) (n3, p8)
        val case_ppL as () = test (p3, p8) (p3, p8)
        val case_ppE as () = test (p8, p8) (p8, p8)
        val case_ppG as () = test (p8, p3) (p3, p8)
        val case_zp as () = test (p0, p3) (p0, p3)
        val case_pz as () = test (p8, p0) (p0, p8)
        val case_zz as () = test (p0, p0) (p0, p0)
      in () end
  end (* local *)

  (********************)

  fun sign001 () =
      let
        val sign_m = I.sign (I.-(p0, p1))
        val () = A.assertEqualInt ~1 sign_m

        val sign_z = I.sign p0
        val () = A.assertEqualInt 0 sign_z

        val sign_p = I.sign p1
        val () = A.assertEqualInt 1 sign_p
      in () end

  (********************)

  local
    fun test arg expected = assertEqualBool expected (I.sameSign arg)
  in
  fun sameSign001 () =
      let
        val case_mm as () = test (n1, n2) true
        val case_mz as () = test (n1, p0) false
        val case_mp as () = test (n1, p2) false
        val case_zm as () = test (p0, n2) false
        val case_zz as () = test (p0, p0) true
        val case_zp as () = test (p0, p2) false
        val case_pm as () = test (p1, n2) false
        val case_pz as () = test (p1, p0) false
        val case_pp as () = test (p1, p2) true
      in () end
  end (* local *)

  (********************)

  local
    fun test arg1 arg2 expected = assertEqualString expected (I.fmt arg1 arg2)
  in

  fun fmt_bin001 () =
      let
        val case_bin_m1 as () = test StringCvt.BIN n1 "~1"
        val case_bin_m2 as () = test StringCvt.BIN n123 "~1111011"
        val case_bin_z as () = test StringCvt.BIN p0 "0"
        val case_bin_p1 as () = test StringCvt.BIN p1 "1"
        val case_bin_p2 as () = test StringCvt.BIN p123 "1111011"
      in () end

  fun fmt_oct001 () =
      let
        val case_oct_m1 as () = test StringCvt.OCT n1 "~1"
        val case_oct_m2 as () = test StringCvt.OCT n123 "~173"
        val case_oct_z as () = test StringCvt.OCT p0 "0"
        val case_oct_p1 as () = test StringCvt.OCT p1 "1"
        val case_oct_p2 as () = test StringCvt.OCT p123 "173"
      in () end

  fun fmt_dec001 () =
      let
        val case_dec_m1 as () = test StringCvt.DEC n1 "~1"
        val case_dec_m2 as () = test StringCvt.DEC n123 "~123"
        val case_dec_z as () = test StringCvt.DEC p0 "0"
        val case_dec_p1 as () = test StringCvt.DEC p1 "1"
        val case_dec_p2 as () = test StringCvt.DEC p123 "123"
      in () end

  fun fmt_hex001 () =
      let
        val case_hex_m1 as () = test StringCvt.HEX n1 "~1"
        val case_hex_m2 as () = test StringCvt.HEX n123 "~7B"
        val case_hex_z as () = test StringCvt.HEX p0 "0"
        val case_hex_p1 as () = test StringCvt.HEX p1 "1"
        val case_hex_p2 as () = test StringCvt.HEX p123 "7B"
      in () end

  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualString expected (I.toString arg)
  in
  fun toString001 () =
      let
        val case_m1 as () = test n1 "~1"
        val case_m2 as () = test n123 "~123"
        val case_z as () = test p0 "0"
        val case_p1 as () = test p1 "1"
        val case_p2 as () = test p123 "123"
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualIntOption expected (I.fromString arg)
  in
  fun fromString001 () =
      let
        val case_null as () = test "" NONE
        val case_nonum as () = test "abc123def" NONE
        val case_m1 as () = test "~1" (SOME n1)
        val case_m12 as () = test "~1abc" (SOME n1)
        val case_m13 as () = test " \t\v\f\n\r~1abc" (SOME n1)
        val case_m2 as () = test "~123" (SOME n123)
        val case_m22 as () = test "~123abc" (SOME n123)
        val case_z1 as () = test "0" (SOME p0)
        val case_z12 as () = test "00" (SOME p0)
        val case_z12 as () = test "00abc" (SOME p0)
        val case_p1 as () = test "1" (SOME p1)
        val case_p12 as () = test "1abc" (SOME p1)
        val case_p2 as () = test "123" (SOME p123)
        (* ignore trailer *)
        val case_p22 as () = test "123abc" (SOME p123)
        (* skip initial whitespaces *)
        val case_p23 as () = test " \t\v\f\n\r123abc" (SOME p123)
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
    fun testOverflow arg1 arg2 =
        (I.scan arg1 List.getItem (explode arg2); fail "scan:expect Overflow.")
        handle General.Overflow => ()
  in

  local val test = test StringCvt.BIN
  in
  fun scan_bin001 () =
      let
        val case_bin_null as () = test "" NONE
        val case_bin_0 as () = test "0" (SOME(p0, ""))
        val case_bin_01 as () = test "00" (SOME(p0, ""))
        val case_bin_p0 as () = test "+0" (SOME(p0, ""))
        val case_bin_t0 as () = test "~0" (SOME(p0, ""))
        val case_bin_m0 as () = test "-0" (SOME(p0, ""))
        val case_bin_t1 as () = test "~1" (SOME(n1, ""))
        val case_bin_t1b as () = test "~1abc" (SOME(n1, "abc"))
        val case_bin_t1c as () = test "~01" (SOME(n1, ""))
        val case_bin_m1 as () = test "-1" (SOME(n1, ""))
        val case_bin_m1b as () = test "-1abc" (SOME(n1, "abc"))
        val case_bin_m1c as () = test "-01" (SOME(n1, ""))
        val case_bin_p1 as () = test "+1" (SOME(p1, ""))
        val case_bin_p1b as () = test "+1abc" (SOME(p1, "abc"))
        val case_bin_p1c as () = test "+01" (SOME(p1, ""))
        val case_bin_1 as () = test "1" (SOME(p1, ""))
        val case_bin_1b as () = test "1abc" (SOME(p1, "abc"))
        val case_bin_1c as () = test "01" (SOME(p1, ""))
        val case_bin_maxInt as () =
            case I.precision
             of NONE => ()
              | SOME prec =>
                let val arg = CharVector.tabulate (prec - 1, fn _ => #"1")
                in test arg (SOME (maxInt, "")) end
        val case_bin_minInt as () =
            case I.precision
             of NONE => ()
              | SOME prec =>
                let
                  val arg = "~1" ^ CharVector.tabulate (prec - 1, fn _ => #"0")
                in test arg (SOME (minInt, "")) end
      in () end
  fun scan_bin101 () =
      let
        val case_bin_2 as () = test "2" NONE
        val case_bin_maxIntPlus1 as () =
            case I.precision
             of SOME prec =>
                testOverflow
                    StringCvt.BIN
                    ("1" ^ CharVector.tabulate (prec - 1, fn _ => #"0"))
              | NONE => ()
        val case_bin_minIntMinus1 as () =
            case I.precision
             of SOME prec =>
                testOverflow
                    StringCvt.BIN
                    ("~1" ^ CharVector.tabulate (prec - 1, fn _ => #"0") ^ "1")
              | NONE => ()
      in () end
  end (* inner local *)

  local val test = test StringCvt.OCT
  in
  fun scan_oct001 () =
      let
        val case_oct_null as () = test "" NONE
        val case_oct_0 as () = test "0" (SOME(p0, ""))
        val case_oct_01 as () = test "00" (SOME(p0, ""))
        val case_oct_p0 as () = test "+0" (SOME(p0, ""))
        val case_oct_t0 as () = test "~0" (SOME(p0, ""))
        val case_oct_m0 as () = test "-0" (SOME(p0, ""))
        val case_oct_t173 as () = test "~173" (SOME(n123, ""))
        val case_oct_t173b as () = test "~17389a" (SOME(n123, "89a"))
        val case_oct_t173c as () = test "~0173" (SOME(n123, ""))
        val case_oct_m173 as () = test "-173" (SOME(n123, ""))
        val case_oct_m173b as () = test "-17389a" (SOME(n123, "89a"))
        val case_oct_m173c as () = test "-0173" (SOME(n123, ""))
        val case_oct_p173 as () = test "+173" (SOME(p123, ""))
        val case_oct_p173b as () = test "+17389a" (SOME(p123, "89a"))
        val case_oct_p173c as () = test "+0173" (SOME(p123, ""))
        val case_oct_173 as () = test "173" (SOME(p123, ""))
        val case_oct_173b as () = test "17389a" (SOME(p123, "89a"))
        val case_oct_173c as () = test "0173" (SOME(p123, ""))
        val case_oct_maxInt as () =
            case I.precision
             of NONE => ()
              | SOME prec =>
                let
                  val arg = 
                      case prec
                       of 31 => "7777777777"
                        | 32 => "17777777777"
                        | 64 => "777777777777777777777"
                in test arg (SOME(maxInt, "")) end
        val case_oct_minInt as () =
            case I.precision
             of NONE => ()
              | SOME prec =>
                let
                  val arg = 
                      case prec
                       of 31 => "~10000000000"
                        | 32 => "~20000000000"
                        | 64 => "~1000000000000000000000"
                in test arg (SOME(minInt, "")) end                           
      in () end
  fun scan_oct101 () =
      let
        val case_oct_8 as () = test "8" NONE
        val case_oct_maxIntPlus1 as () =
            case I.precision
             of NONE => ()
              | SOME prec =>
                testOverflow
                    StringCvt.OCT
                    (case prec
                      of 31 => "10000000000"
                       | 32 => "20000000000"
                       | 64 => "1000000000000000000000")
        val case_oct_minIntMinus1 as () =
            case I.precision
             of NONE => ()
              | SOME prec =>
                testOverflow
                    StringCvt.OCT
                    (case prec
                      of 31 => "~10000000001"
                       | 32 => "~20000000001"
                       | 64 => "~1000000000000000000001")
      in () end
  end (* inner local *)

  local val test = test StringCvt.DEC
  in
  fun scan_dec001 () =
      let
        val case_dec_null as () = test "" NONE
        val case_dec_0 as () = test "0" (SOME(p0, ""))
        val case_dec_01 as () = test "00" (SOME(p0, ""))
        val case_dec_p0 as () = test "+0" (SOME(p0, ""))
        val case_dec_t0 as () = test "~0" (SOME(p0, ""))
        val case_dec_m0 as () = test "-0" (SOME(p0, ""))
        val case_dec_t123 as () = test "~123" (SOME(n123, ""))
        val case_dec_t123b as () = test "~123a" (SOME(n123, "a"))
        val case_dec_t123c as () = test "~0123" (SOME(n123, ""))
        val case_dec_m123 as () = test "-123" (SOME(n123, ""))
        val case_dec_m123b as () = test "-123a" (SOME(n123, "a"))
        val case_dec_m123c as () = test "-0123" (SOME(n123, ""))
        val case_dec_p123 as () = test "+123" (SOME(p123, ""))
        val case_dec_p123b as () = test "+123a" (SOME(p123, "a"))
        val case_dec_p123c as () = test "+0123" (SOME(p123, ""))
        val case_dec_123 as () = test "123" (SOME(p123, ""))
        val case_dec_123b as () = test "123a" (SOME(p123, "a"))
        val case_dec_123c as () = test "0123" (SOME(p123, ""))
        val case_oct_maxInt as () =
            case I.precision
             of NONE => ()
              | SOME prec =>
                let
                  val arg = 
                      case prec
                       of 31 => "1073741823"
                        | 32 => "2147483647"
                        | 64 => "9223372036854775807"
                in test arg (SOME(maxInt, "")) end
        val case_oct_minInt as () =
            case I.precision
             of NONE => ()
              | SOME prec =>
                let
                  val arg = 
                      case prec
                       of 31 => "~1073741824"
                        | 32 => "~2147483648"
                        | 64 => "~9223372036854775808"
                in test arg (SOME(minInt, "")) end                           
      in () end
  fun scan_dec101 () =
      let
        val case_dec_A as () = test "A" NONE
        val case_dec_maxIntPlus1 as () =
            case I.precision
             of NONE => ()
              | SOME prec =>
                testOverflow
                    StringCvt.DEC
                    (case prec
                      of 31 => "1073741824"
                       | 32 => "2147483648"
                       | 64 => "9223372036854775808")
        val case_dec_minIntMinus1 as () =
            case I.precision
             of NONE => ()
              | SOME prec =>
                testOverflow
                    StringCvt.DEC
                    (case prec
                      of 31 => "~1073741825"
                       | 32 => "~2147483649"
                       | 64 => "~9223372036854775809")
      in () end
  end (* inner local *)

  local val test = test StringCvt.HEX
  in
  fun scan_hex001 () =
      let
        val case_hex_null as () = test "" NONE
        val case_hex_head1 as () = test "0x " (SOME(p0, "x "))
        val case_hex_head2 as () = test "0X " (SOME(p0, "X "))
        val case_hex_0 as () = test "0" (SOME(p0, ""))
        val case_hex_01 as () = test "00" (SOME(p0, ""))
        val case_hex_0h1 as () = test "0x0" (SOME(p0, ""))
        val case_hex_0h2 as () = test "0X0" (SOME(p0, ""))
        val case_hex_p0 as () = test "+0" (SOME(p0, ""))
        val case_hex_p0h1 as () = test "+0x0" (SOME(p0, ""))
        val case_hex_p0h2 as () = test "+0X0" (SOME(p0, ""))
        val case_hex_t0 as () = test "~0" (SOME(p0, ""))
        val case_hex_m0 as () = test "-0" (SOME(p0, ""))
        (* 0x7B = 123 *)
        val case_hex_t7B as () = test "~7B" (SOME(n123, ""))
        val case_hex_t7Bb as () = test "~7BGg" (SOME(n123, "Gg"))
        val case_hex_t7Bb_h1 as () = test "~0x7BGg" (SOME(n123, "Gg"))
        val case_hex_t7Bb_h2 as () = test "~0X7BGg" (SOME(n123, "Gg"))
        val case_hex_t7Bc as () = test "~07B" (SOME(n123, ""))
        val case_hex_m7B as () = test "-7B" (SOME(n123, ""))
        val case_hex_m7Bb as () = test "-7BGg" (SOME(n123, "Gg"))
        val case_hex_m7Bb_h1 as () = test "-0x7BGg" (SOME(n123, "Gg"))
        val case_hex_m7Bb_h2 as () = test "-0X7BGg" (SOME(n123, "Gg"))
        val case_hex_m7Bc as () = test "-07B" (SOME(n123, ""))
        val case_hex_p7B as () = test "+7B" (SOME(p123, ""))
        val case_hex_p7Bb as () = test "+7BGg" (SOME(p123, "Gg"))
        val case_hex_p7Bb_h1 as () = test "+0x7BGg" (SOME(p123, "Gg"))
        val case_hex_p7Bb_h2 as () = test "+0X7BGg" (SOME(p123, "Gg"))
        val case_hex_p7Bc as () = test "+07B" (SOME(p123, ""))
        val case_hex_7B as () = test "7B" (SOME(p123, ""))
        val case_hex_7Bb as () = test "7BGg" (SOME(p123, "Gg"))
        val case_hex_7Bb_h1 as () = test "0x7BGg" (SOME(p123, "Gg"))
        val case_hex_7Bb_h2 as () = test "0X7BGg" (SOME(p123, "Gg"))
        val case_hex_7Bc as () = test "07B" (SOME(p123, ""))

        val case_hex_maxInt as () =
            case I.precision
             of NONE => ()
              | SOME prec =>
                let
                  val arg = 
                      case prec
                       of 31 => "3FFFFFFF"
                        | 32 => "7FFFFFFF"
                        | 64 => "7FFFFFFFFFFFFFFF"
                in test arg (SOME(maxInt, "")) end
        val case_hex_minInt as () =
            case I.precision
             of NONE => ()
              | SOME prec =>
                let
                  val arg = 
                      case prec
                       of 31 => "~40000000"
                        | 32 => "~80000000"
                        | 64 => "~8000000000000000"
                in test arg (SOME(minInt, "")) end                           
      in () end
  fun scan_hex101 () =
      let
        val case_hex_G as () = test "G" NONE
        val case_hex_maxIntPlus1 as () =
            case I.precision
             of NONE => ()
              | SOME prec =>
                testOverflow
                    StringCvt.HEX
                    (case prec
                      of 31 => "40000000"
                       | 32 => "80000000"
                       | 64 => "8000000000000000")
        val case_hex_minIntMinus1 as () =
            case I.precision
             of NONE => ()
              | SOME prec =>
                testOverflow
                    StringCvt.HEX
                    (case prec
                      of 31 => "~40000001"
                       | 32 => "~80000001"
                       | 64 => "~8000000000000001")
      in () end
  end (* inner local *)

  fun scan_skipWS001 () =
      let
        val case_skipWS1 as () = test StringCvt.DEC "  123" (SOME(p123, ""))
        val case_skipWS2 as () = test StringCvt.DEC "\t\n\v\f\r123" (SOME(p123, ""))
      in () end

  end (* outer local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("toLarge001", toLarge001),
        ("toLarge002", toLarge002),
        ("fromLargeInt001", fromLargeInt001),
        ("fromLargeInt002", fromLargeInt002),
        ("fromLargeInt101", fromLargeInt101),
        ("toInt001", toInt001),
        ("toInt002", toInt002),
        ("toInt101", toInt101),
        ("fromInt001", fromInt001),
        ("fromInt002", fromInt002),
        ("fromInt101", fromInt101),

        ("add001", add001),
        ("add101", add101),
        ("sub001", sub001),
        ("sub101", sub101),
        ("mul001", mul001),
        ("mul101", mul101),
        ("mul102", mul102),
        ("div001", div001),
        ("div101", div101),
        ("div102", div102),
        ("mod001", mod001),
        ("mod101", mod101),
        ("mod102", mod102),
        ("quot001", quot001),
        ("quot101", quot101),
        ("quot102", quot102),
        ("rem001", rem001),
        ("rem101", rem101),
        ("rem102", rem102),

        ("compare001", compare001),
        ("binComp001", binComp001),
        ("tilda001", tilda001),
        ("tilda101", tilda101),
        ("abs001", abs001),
        ("abs101", abs101),
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
        ("scan_bin101", scan_bin101),
        ("scan_oct001", scan_oct001),
        ("scan_oct101", scan_oct101),
        ("scan_dec001", scan_dec001),
        ("scan_dec101", scan_dec101),
        ("scan_hex001", scan_hex001),
        ("scan_hex101", scan_hex101),
        ("scan_skipWS001", scan_skipWS001)
      ]

  (************************************************************)

end
