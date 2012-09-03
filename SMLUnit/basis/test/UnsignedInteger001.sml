(**
 * test cases for WORD structures.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
functor UnsignedInteger001
            (W
             : sig
                 include WORD
                 val assertEqualWord : word SMLUnit.Assert.assertEqual
               end) =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  structure AL = SMLUnit.Assert.AssertLargeWord
  open A

  structure LW = LargeWord

  (************************************************************)

  val assertEqualWord = W.assertEqualWord
  val assertEqualWordOption = assertEqualOption assertEqualWord
  val assertEqualWSOption =
      assertEqualOption
          (assertEqual2Tuple (assertEqualWord, assertEqualString))
  val assertEqualWCListOption =
      assertEqualOption
          (assertEqual2Tuple (assertEqualWord, assertEqualCharList))

  val assertEqual4Bool =
      assertEqual4Tuple
          (assertEqualBool, assertEqualBool, assertEqualBool, assertEqualBool)

  val assertEqual2Int = assertEqual2Tuple (assertEqualInt, assertEqualInt)

  val assertEqual2Word = assertEqual2Tuple (assertEqualWord, assertEqualWord)

  val assertEqual3Word =
      assertEqual3Tuple (assertEqualWord, assertEqualWord, assertEqualWord)

  val assertEqual5Word =
      assertEqual5Tuple
          (
            assertEqualWord,
            assertEqualWord,
            assertEqualWord,
            assertEqualWord,
            assertEqualWord
          )

  val assertEqual2LargeWord = 
      assertEqual2Tuple (AL.assertEqualWord, AL.assertEqualWord)

  val assertEqualLargeInt = SMLUnit.Assert.AssertLargeInt.assertEqualInt
  val assertEqual2LargeInt =
      assertEqual2Tuple (assertEqualLargeInt, assertEqualLargeInt)

  val W2w = W.fromLarge
  val I2W = LW.fromLargeInt
  val I2w = W2w o I2W
  val I2i = Int.fromLarge
  val i2I = Int.toLarge
  val i2w = I2w o i2I

  (* We assume here that LargeInt.precision > 64. *)
  val (maxWordLargeInt : LargeInt.int, maxWordLarge : LW.word, maxWord) =
      case W.wordSize
       of 8 => (0xFF, I2W 0xFF, I2w 0xFF)
        | 31 => (0x7FFFFFFF, I2W 0x7FFFFFFF, I2w 0x7FFFFFFF)
        | 32 => (0xFFFFFFFF, I2W 0xFFFFFFFF, I2w 0xFFFFFFFF)
        | 64 =>
          (0xFFFFFFFFFFFFFFFF, I2W 0xFFFFFFFFFFFFFFFF, I2w 0xFFFFFFFFFFFFFFFF)
        | n => raise General.Fail ("W.wordSize = " ^ Int.toString n)
  val maxLargeWord =
      case LW.wordSize
       of 31 => I2W 0x7FFFFFFF
        | 32 => I2W 0xFFFFFFFF
        | 63 => I2W 0x7FFFFFFFFFFFFFFF
        | 64 => I2W 0xFFFFFFFFFFFFFFFF
        | n => raise General.Fail ("LW.wordSize = " ^ Int.toString n)

  val [w0, w1, w2, w3, w4, w5, w6, w7, w8, w9] = List.tabulate (10, I2w o i2I)
  val w10 = I2w 10
  val w123 = W2w 0w123
  val wx1F = W2w 0wx1F

  (********************)

  (* test for toLarge and toLargeX (and toLargeWord and toLargeWordX). *)
  local
    fun test arg expected =
        assertEqual2LargeWord expected (W.toLarge arg, W.toLargeX arg)
  in
  fun toLarge0001 () =
      let
        val toLarge_0 = test w0 (0w0, 0w0)
        val toLarge_123 = test w123 (0w123, 0w123)
        val toLarge_maxWord = test maxWord (maxWordLarge, maxLargeWord)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualWord expected (W.fromLarge arg)
  in
  fun fromLarge0001 () =
      let
        val fromLarge_0 = test 0w0 w0
        val fromLarge_123 = test 0w123 w123
        val fromLarge_maxWord = test maxWordLarge maxWord
      in () end
  end (* local *)

  (********************)

  (* test for toLargeInt and toLargeIntX *)
  local
    fun test arg expected =
        assertEqual2LargeInt expected (W.toLargeInt arg, W.toLargeIntX arg)
  in
  fun toLargeInt0001 () =
      let
        val toLargeInt_0 = test w0 (0, 0)
        val toLargeInt_123 = test w123 (123, 123)
        val toLargeInt_maxWord = test maxWord (maxWordLargeInt, ~1)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualWord expected (W.fromLargeInt arg)
  in
  fun fromLargeInt0001 () =
      let
        val fromLargeInt_0 = test 0 w0
        val fromLargeInt_123 = test 123 w123
        val fromLargeInt_FFFFFFFF = test ~1 maxWord
      in () end
  end (* local *)

  (********************)

  (* test for toInt and toIntX *)
  local
    fun test arg expected =
        (assertEqual2Int expected (W.toInt arg, W.toIntX arg); ())
    fun testFail arg =
        (W.toInt arg; fail "toInt: expect Overflow.")
        handle General.Overflow => ()
    fun testFailX arg =
        (W.toIntX arg; fail "toInt: expect Overflow.")
        handle General.Overflow => ()
  in
  fun toInt0001 () =
      let
        val toInt_0 = test w0 (0, 0)
        val toInt_123 = test w123 (123, 123)
      in () end
  (* all bits of the argument, except for the most significant bit, are 1.
   *)
  fun toInt0002 () =
      let
        val arg =
            case W.wordSize
             of 8 => I2w 0x7F
              | 31 => I2w 0x3FFFFFFF
              | 32 => I2w 0x7FFFFFFF
              | 64 => I2w 0x7FFFFFFFFFFFFFFF
        val toInt_maxInt =
            if W.wordSize <= Option.getOpt (Int.precision, W.wordSize)
            then
              test
                  arg
                  (case W.wordSize
                    of 8 => (I2i 0x7F, I2i 0x7F)
                     | 31 => (I2i 0x3FFFFFFF, I2i 0x3FFFFFFF)
                     | 32 => (I2i 0x7FFFFFFF, I2i 0x7FFFFFFF)
                     | 64 => (I2i 0x7FFFFFFFFFFFFFFF, I2i 0x7FFFFFFFFFFFFFFF))
            else testFail arg
      in () end
  (* test of toInt on arguments of which the most significant bit is set. *)
  fun toInt0003 () =
      let
        (* arg = -1 in 2's complement representaion. *)
        val arg =
            case W.wordSize
             of 8 => I2w 0xFF
              | 31 => I2w 0x7FFFFFFF
              | 32 => I2w 0xFFFFFFFF
              | 64 => I2w 0xFFFFFFFFFFFFFFFF
        val toInt_m1 =
            if W.wordSize < Option.getOpt (Int.precision, W.wordSize + 1)
            then
              (
                assertEqualInt
                    (case W.wordSize
                      of 8 => I2i 0xFF
                       | 31 => I2i 0x7FFFFFFF
                       | 32 => I2i 0xFFFFFFFF
                       | 64 => I2i 0xFFFFFFFFFFFFFFFF)
                    (W.toInt arg);
                ()
              )
            else
              ((W.toInt arg; fail "toInt: expect Overflow")
               handle General.Overflow => ())
        val toIntX_m1 = assertEqualInt ~1 (W.toIntX arg)
      in () end
  (* all bits of the argument, except for the most significant bit, are 0.
   *)
  fun toInt0004 () =
      let
        val arg =
            case W.wordSize
             of 8 => I2w 0x80
              | 31 => I2w 0x40000000
              | 32 => I2w 0x80000000
              | 64 => I2w 0x8000000000000000
        (* To toInt succeeds, int must be wider than word at least 1 bit. *)
        val toInt_minInt =
            if W.wordSize < Option.getOpt (Int.precision, W.wordSize + 1)
            then
              (
                assertEqualInt
                    (case W.wordSize
                      of 8 => I2i 0x80
                       | 31 => I2i 0x40000000
                       | 32 => I2i 0x80000000
                       | 64 => I2i 0x8000000000000000)
                    (W.toInt arg);
                ()
              )
            else
              ((W.toInt arg; fail "toInt: expect Overflow")
               handle General.Overflow => ())
        (* If word and int are same bit width, toIntX succeeds. *)
        val toIntX_minInt =
            if W.wordSize <= Option.getOpt (Int.precision, W.wordSize)
            then
              (
                assertEqualInt
                    (case W.wordSize
                      of 8 => I2i ~0x80
                       | 31 => I2i ~0x40000000
                       | 32 => I2i ~0x80000000
                       | 64 => I2i ~0x8000000000000000)
                    (W.toIntX arg);
                ()
              )
            else
              ((W.toIntX arg; fail "toIntX: expect Overflow")
               handle General.Overflow => ())
      in () end
  end (* local *)

  (********************)

  local fun test arg expected = assertEqualWord expected (W.fromInt arg)
  in
  fun fromInt0001 () =
      let
        val fromInt_0 = test 0 w0
        val fromInt_123 = test 123 w123
        val fromInt_7FFFFFFF =
            test
                (case Int.precision
                  of SOME 31 => I2i 0x3FFFFFFF
                   | SOME 32 => I2i 0x7FFFFFFF
                   | SOME 64 => I2i 0x7FFFFFFFFFFFFFFF)
                (case Int.precision
                  of SOME 31 => I2w 0x3FFFFFFF
                   | SOME 32 => I2w 0x7FFFFFFF
                   | SOME 64 => I2w 0x7FFFFFFFFFFFFFFF)
        val fromInt_FFFFFFFF = test ~1 maxWord
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqual3Word expected (W.andb arg, W.orb arg, W.xorb arg)
  in
  fun binBit0001 () =
      let
        val binBit_0_0 = test (w0, w0) (w0, w0, w0)
        val binBit_F0_0F = test (I2w 0xF0, I2w 0x0F) (w0, I2w 0xFF, I2w 0xFF)
        val binBit_0F_0F = test (I2w 0x0F, I2w 0x0F) (I2w 0x0F, I2w 0x0F, w0)
      in () end
  end (* local *)

  (********************)

  fun notb0001 () =
      let
        val notb_0 = assertEqualWord maxWord (W.notb w0)
        val notb_F0 =
            assertEqualWord
                (case W.wordSize
                  of 8 => I2w 0x0F
                   | 31 => I2w 0x7FFFFF0F
                   | 32 => I2w 0xFFFFFF0F
                   | 64 => I2w 0xFFFFFFFFFFFFFF0F)
                (W.notb (I2w 0xF0))
      in () end

  (********************)

  local
    fun test arg expected =
        assertEqual3Word expected (W.<< arg, W.>> arg, W.~>> arg)
  in
  fun shift0001 () =
      let
        val shift_0_0 = test (w0, 0w0) (w0, w0, w0)
        val shift_1_0 = test (w1, 0w0) (w1, w1, w1)
        val shift_1_1 = test (w1, 0w1) (w2, w0, w0)
        val shift_1_2 = test (w1, 0w2) (w4, w0, w0)
        val shift_1_max_m1 =
            test
                (w1, Word.fromInt(W.wordSize - 1))
                (
                  case W.wordSize
                   of 8 => I2w 0x80
                    | 31 => I2w 0x40000000
                    | 32 => I2w 0x80000000
                    | 64 => I2w 0x8000000000000000,
                  w0,
                  w0
                )
        val shift_1_max = test (w1, Word.fromInt W.wordSize) (w0, w0, w0)
        val shift_1F_1 = test (wx1F, 0w1) (I2w 0x3E, I2w 0xF, I2w 0xF)
        val shift_1F_2 = test (wx1F, 0w2) (I2w 0x7C, w7, w7)
        val shift_1F_max_m1 =
            test
                (wx1F, Word.fromInt(W.wordSize - 1))
                (
                  case W.wordSize
                  of 8 => I2w 0x80
                   | 31 => I2w 0x40000000
                   | 32 => I2w 0x80000000
                   | 64 => I2w 0x8000000000000000,
                  w0,
                  w0
                )
        val shift_1F_max =
            test (wx1F, Word.fromInt W.wordSize) (w0, w0, w0)

        val shift_max_1 =
            test
                (maxWord, 0w1) (W.-(maxWord, w1), W.div (maxWord, w2), maxWord)
        val shift_max_max_m1 =
            test
                (maxWord, Word.fromInt(W.wordSize - 1))
                (
                  case W.wordSize
                   of 8 => I2w 0x80
                    | 31 => I2w 0x40000000
                    | 32 => I2w 0x80000000
                    | 64 => I2w 0x8000000000000000,
                  w1,
                  maxWord
                )
        val shift_max_max =
            test (maxWord, Word.fromInt W.wordSize) (w0, w0, maxWord)
      in () end

  end (* local *)

  (********************)

  local
    fun test operator args expected = assertEqualWord expected (operator args)
    fun testFailDiv operator args =
        (operator args; fail "Div expected.") handle General.Div => ()
  in

  local val test = test W.+
  in
  fun add0001 () =
      let
        val add_pp = test (w7, w3) w10
        val add_zp = test (w0, w3) w3
        val add_pz = test (w7, w0) w7
        val add_zz = test (w0, w0) w0

        val add_max_0 = test (maxWord, w0) maxWord
        val add_max_1 = test (maxWord, w1) w0
        val sub_max_max =
            test
                (maxWord, maxWord)
                (case W.wordSize
                  of 8 => I2w 0xFE
                   | 31 => I2w 0x7FFFFFFE
                   | 32 => I2w 0xFFFFFFFE
                   | 64 => I2w 0xFFFFFFFFFFFFFFFE)
      in () end
  end (* inner local *)

  local val test = test W.-
  in
  fun sub0001 () =
      let
        val sub_pp_gt = test (w7, w3) w4
        val sub_pp_eq = test (w7, w7) w0
        val sub_pp_lt =
            test
                (w3, w7)
                (case W.wordSize
                  of 8 => I2w 0xFC
                   | 31 => I2w 0x7FFFFFFC
                   | 32 => I2w 0xFFFFFFFC
                   | 64 => I2w 0xFFFFFFFFFFFFFFFC)
        val sub_zp =
            test
                (w0, w3)
                (case W.wordSize
                  of 8 => I2w 0xFD
                   | 31 => I2w 0x7FFFFFFD
                   | 32 => I2w 0xFFFFFFFD
                   | 64 => I2w 0xFFFFFFFFFFFFFFFD)
        val sub_pz = test (w7, w0) w7
        val sub_zz = test (w0, w0) w0
        val sub_max_0 = test (maxWord, w0) maxWord
        val sub_max_max = test (maxWord, maxWord) w0
      in () end
  end (* inner local *)

  local val test = test W.*
  in
  fun mul0001 () =
      let
        val mul_pp = test (w7, w3) (I2w 21)
        val mul_zp = test (w0, w3) w0
        val mul_pz = test (w7, w0) w0
        val mul_zz = test (w0, w0) w0
        val mul_max_0 = test (maxWord, w0) w0
        val mul_max_1 = test (maxWord, w1) maxWord
        val mul_max_max = test (maxWord, maxWord) w1
      in () end
  end (* inner local *)

  local
    val test = test W.div
    val testFailDiv = testFailDiv W.div
  in
  fun div0001 () =
      let
        val div_pp = test (w7, w3) w2
        val div_zp = test (w0, w3) w0
        val div_pz = testFailDiv (w7, w0)
        val div_zz = testFailDiv (w0, w0)
        val div_max_0 = testFailDiv (maxWord, w0)
        val div_max_1 = test (maxWord, w1) maxWord
        val div_max_max = test (maxWord, maxWord) w1
      in () end
  end (* inner local *)

  local
    val test = test W.mod
    val testFailDiv = testFailDiv W.mod
  in
  fun mod0001 () =
      let
        val mod_pp = test (w7, w3) w1
        val mod_zp = test (w0, w3) w0
        val mod_pz = testFailDiv (w7, w0)
        val mod_zz = testFailDiv (w0, w0)
        val mod_max_0 = testFailDiv (maxWord, w0)
        val mod_max_1 = test (maxWord, w1) w0
        val mod_max_max = test (maxWord, maxWord) w0
      in () end
  end (* inner local *)

  end (* outer local *)

  (********************)

  local fun test args expected = assertEqualOrder expected (W.compare args)
  in
  fun compare0001 () =
      let
        val compare_ppL = test (w3, w7) LESS
        val compare_ppE = test (w7, w7) EQUAL
        val compare_ppG = test (w7, w3) GREATER
        val compare_zp = test (w0, w3) LESS
        val compare_pz = test (w7, w0) GREATER
        val compare_zz = test (w0, w0) EQUAL

        val compare_maxWord_0 = test (maxWord, w0) GREATER
        val compare_maxWord_1 = test (maxWord, w1) GREATER
        val compare_maxWord_maxWord = test (maxWord, maxWord) EQUAL
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
        assertEqual4Bool expected (W.< args, W.<= args, W.>= args, W.> args)
  in
  fun binComp0001 () =
      let
        val binComp_ppL = test (w3, w7) TTFF
        val binComp_ppE = test (w7, w7) FTTF
        val binComp_ppG = test (w7, w3) FFTT
        val binComp_zp = test (w0, w3) TTFF
        val binComp_pz = test (w7, w0) FFTT
        val binComp_zz = test (w0, w0) FTTF

        val binComp_maxWord_z = test (maxWord, w0) FFTT
        val binComp_maxWord_1 = test (maxWord, w1) FFTT
        val binComp_z_maxWord = test (w0, maxWord) TTFF
        val binComp_1_maxWord = test (w1, maxWord) TTFF
        val binComp_maxWord_maxWord = test (maxWord, maxWord) FTTF
      in () end

  end (* local *)

  (********************)

  fun tilda0001 () =
      let
        val tilda_0 = assertEqualWord w0 (W.~ w0)
        val tilda_1 = assertEqualWord maxWord (W.~ w1)
        val tilda_maxWord = assertEqualWord w1 (W.~ maxWord)
      in () end

  (********************)

  local
    fun test arg expected = assertEqual2Word expected (W.min arg, W.max arg)
  in
  fun minMax0001 () =
      let
        val minMax_ppL = test (w3, w7) (w3, w7)
        val minMax_ppE = test (w7, w7) (w7, w7)
        val minMax_ppG = test (w7, w3) (w3, w7)
        val minMax_zp = test (w0, w3) (w0, w3)
        val minMax_pz = test (w7, w0) (w0, w7)
        val minMax_zz = test (w0, w0) (w0, w0)

        val minMax_maxWord_z = test (maxWord, w0) (w0, maxWord)
        val minMax_z_maxWord = test (w0, maxWord) (w0, maxWord)
        val minMax_maxWord_1 = test (maxWord, w1) (w1, maxWord)
        val minMax_1_maxWord = test (w1, maxWord) (w1, maxWord)
        val minMax_maxWord_maxWord = test (maxWord, maxWord) (maxWord, maxWord)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg1 arg2 expected  = assertEqualString expected (W.fmt arg1 arg2)
  in
  fun fmt_bin0001 () =
      let
        val fmt_bin_z = test StringCvt.BIN w0 "0"
        val fmt_bin_p1 = test StringCvt.BIN w1 "1"
        val fmt_bin_p2 = test StringCvt.BIN w123 "1111011"
        val fmt_bin_maxWord =
            test
                StringCvt.BIN
                maxWord
                (String.implode (List.tabulate (W.wordSize, fn _ => #"1")))
      in () end
  fun fmt_oct0001 () =
      let
        val fmt_oct_z = test StringCvt.OCT w0 "0"
        val fmt_oct_p1 = test StringCvt.OCT w1 "1"
        val fmt_oct_p2 = test StringCvt.OCT w123 "173"
        val fmt_oct_maxWord =
            test
                StringCvt.OCT
                maxWord
                (case W.wordSize
                  of 8 => "377"
                   | 31 => "17777777777"
                   | 32 => "37777777777"
                   | 64 => "1777777777777777777777")
      in () end
  fun fmt_dec0001 () =
      let
        val fmt_dec_z = test StringCvt.DEC w0 "0"
        val fmt_dec_p1 = test StringCvt.DEC w1 "1"
        val fmt_dec_p2 = test StringCvt.DEC w123 "123"
        val fmt_dec_maxWord =
            test
                StringCvt.DEC
                maxWord
                (case W.wordSize
                  of 8 => "255"
                   | 31 => "2147483647"
                   | 32 => "4294967295"
                   | 64 => "18446744073709551615")
      in () end
  fun fmt_hex0001 () =
      let
        val fmt_hex_z = test StringCvt.HEX w0 "0"
        val fmt_hex_p1 = test StringCvt.HEX w1 "1"
        val fmt_hex_p2 = test StringCvt.HEX w123 "7B"
        val fmt_hex_maxWord =
            test
                StringCvt.HEX
                maxWord
                (case W.wordSize
                  of 8 => "FF"
                   | 31 => "7FFFFFFF"
                   | 32 => "FFFFFFFF"
                   | 64 => "FFFFFFFFFFFFFFFF")
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualString expected (W.toString arg)
  in
  fun toString0001 () =
      let
        val toString_z = test w0 "0"
        val toString_p1 = test w1 "1"
        val toString_p2 = test w123 "7B"
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualWordOption expected (W.fromString arg)
  in
  fun fromString0001 () =
      let
        val fromString_null = test "" NONE
        val fromString_nonum = test "ghi123def" NONE
        val fromString_z1 = test "0" (SOME w0)
        val fromString_z2 = test "0w00" (SOME w0)
        val fromString_z12 = test "0ghi" (SOME w0)
        val fromString_p1 = test "1f" (SOME wx1F)
        val fromString_p12 = test "0wx1fghi" (SOME wx1F)

        val fromString_skipWS = test " \f\n\r\t\v1" (SOME w1)
        val fromString_trailer = test "0wx1Fghi" (SOME wx1F)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg1 arg2 expected =
        assertEqualWCListOption
            expected (W.scan arg1 List.getItem (explode arg2))
    fun testOverflow arg1 arg2 =
        (W.scan arg1 List.getItem (explode arg2); fail "scan:expect Overflow.")
        handle General.Overflow => ()
  in
  fun scan_bin0001 () =
      let
        val test = test StringCvt.BIN
        val scan_bin_null = test "" NONE
        val scan_bin_0 = test "0" (SOME(w0, []))
        val scan_bin_0w00 = test "0w00" (SOME(w0, []))
        val scan_bin_1 = test "1" (SOME(w1, []))
        val scan_bin_0w12 = test "0w12" (SOME(w1, [#"2"]))
        val scan_bin_0w1a = test "0w1a" (SOME(w1, [#"a"]))
        val scan_bin_01 = test "01" (SOME(w1, []))
        val scan_bin_11 = test "11" (SOME(w3, []))
        val scan_bin_maxWord =
            test
                (String.implode (List.tabulate (W.wordSize, fn _ => #"1")))
                (SOME(maxWord, []))

        val scan_bin_2 = test "2" NONE

        val scan_bin_maxWordPlus1 =
            testOverflow
                StringCvt.BIN
                (String.implode
                     (List.tabulate (W.wordSize + 1, fn _ => #"1")))
      in () end
  fun scan_oct0001 () =
      let
        val test = test StringCvt.OCT
        val scan_oct_null = test "" NONE
        val scan_oct_0 = test "0" (SOME(w0, []))
        val scan_oct_0w00 = test "0w00" (SOME(w0, []))
        val scan_oct_173 = test "173" (SOME(w123, []))
        val scan_oct_0w1738 = test "0w1738" (SOME(w123, [#"8"]))
        val scan_oct_0173 = test "0173" (SOME(w123, []))
        val scan_oct_maxWord = 
            test
                (case W.wordSize
                  of 8 => "377"
                   | 31 => "17777777777"
                   | 32 => "37777777777"
                   | 64 => "1777777777777777777777")
                (SOME(maxWord, []))

        val scan_oct_9 = test "9" NONE
        val scan_oct_maxWordPlus1 =
            testOverflow
                StringCvt.OCT
                (case W.wordSize
                  of 8 => "400"
                   | 31 => "20000000000"
                   | 32 => "40000000000"
                   | 64 => "2000000000000000000000")
      in () end
  fun scan_dec0001 () =
      let
        val test = test StringCvt.DEC
        val scan_dec_null = test "" NONE
        val scan_dec_0 = test "0" (SOME(w0, []))
        val scan_dec_0w00 = test "0w00" (SOME(w0, []))
        val scan_dec_123 = test "123" (SOME(w123, []))
        val scan_dec_0w123a = test "0w123a" (SOME(w123, [#"a"]))
        val scan_dec_0123 = test "0123" (SOME(w123, []))
        val scan_dec_maxWord =
            test
                (case W.wordSize
                  of 8 => "255"
                   | 31 => "2147483647"
                   | 32 => "4294967295"
                   | 64 => "18446744073709551615")
                (SOME(maxWord, []))

        val scan_dec_a = test "a" NONE
        val scan_dec_maxWordPlus1 =
            testOverflow
                StringCvt.DEC
                (case W.wordSize
                  of 8 => "256"
                   | 31 => "2147483648"
                   | 32 => "4294967296"
                   | 64 => "18446744073709551616")
      in () end
  fun scan_hex0001 () =
      let
        val test = test StringCvt.HEX

        val scan_hex_null = test "" NONE
        val scan_hex_0wx = test "0wx " (SOME(w0, [#"w", #"x", #" "]))
        val scan_hex_0wX = test "0wX " (SOME(w0, [#"w", #"X", #" "]))
        val scan_hex_0x = test "0x " (SOME(w0, [ #"x", #" "]))
        val scan_hex_0X = test "0X " (SOME(w0, [ #"X", #" "]))
        val scan_hex_0 = test "0" (SOME(w0, []))
        val scan_hex_00 = test "00" (SOME(w0, []))
        val scan_hex_0wx0 = test "0wx0" (SOME(w0, []))
        val scan_hex_0wX0 = test "0wX0" (SOME(w0, []))
        val scan_hex_0x0 = test "0x0" (SOME(w0, []))
        val scan_hex_0X0 = test "0X0" (SOME(w0, []))
        val scan_hex_7B = test "7B" (SOME(w123, []))
        val scan_hex_1FGg = test "1FGg" (SOME(wx1F, [#"G", #"g"]))
        val scan_hex_0wx1FGg = test "0wx1FGg" (SOME(wx1F, [#"G", #"g"]))
        val scan_hex_0wX1FGg = test "0wX1FGg" (SOME(wx1F, [#"G", #"g"]))
        val scan_hex_0x1FGg = test "0x1FGg" (SOME(wx1F, [#"G", #"g"]))
        val scan_hex_0X1FGg = test "0X1FGg" (SOME(wx1F, [#"G", #"g"]))
        val scan_hex_07B = test "07B" (SOME(w123, []))
        val scan_hex_maxWord =
            test
                (case W.wordSize
                  of 8 => "FF"
                   | 31 => "7FFFFFFF"
                   | 32 => "FFFFFFFF"
                   | 64 => "FFFFFFFFFFFFFFFF")
                (SOME(maxWord, []))

        val scan_hex_g = test "g" NONE
        val scan_hex_maxWordPlus1 =
            testOverflow
                StringCvt.HEX
                (case W.wordSize
                  of 8 => "100"
                   | 31 => "80000000"
                   | 32 => "100000000"
                   | 64 => "10000000000000000")
      in () end
  fun scan_skipWS0001 () =
      let
        val scan_skipWS1 = test StringCvt.DEC "  123" (SOME(w123, []))
        val scan_skipWS2 = test StringCvt.DEC "\t\n\v\f\r123" (SOME(w123, []))
      in () end

  end (* local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("toLarge0001", toLarge0001),
(*
        ("toLargeX0001", toLargeX0001),
*)
        ("fromLarge0001", fromLarge0001),
        ("toLargeInt0001", toLargeInt0001),
(*
        ("toLargeIntX0001", toLargeIntX0001),
*)
        ("fromLargeInt0001", fromLargeInt0001),
        ("toInt0001", toInt0001),
        ("toInt0002", toInt0002),
        ("toInt0003", toInt0003),
        ("toInt0004", toInt0004),
        ("fromInt0001", fromInt0001),

        ("binBit0001", binBit0001),
        ("notb0001", notb0001),
        ("shift0001", shift0001),

        ("add0001", add0001),
        ("sub0001", sub0001),
        ("mul0001", mul0001),
        ("div0001", div0001),
        ("mod0001", mod0001),

        ("compare0001", compare0001),
        ("binComp0001", binComp0001),

        ("tilda0001", tilda0001),
        ("minMax0001", minMax0001),

        ("fmt_bin0001", fmt_bin0001),
        ("fmt_oct0001", fmt_oct0001),
        ("fmt_dec0001", fmt_dec0001),
        ("fmt_hex0001", fmt_hex0001),
        ("toString0001", toString0001),
        ("fromString0001", fromString0001),
        ("scan_bin0001", scan_bin0001),
        ("scan_oct0001", scan_oct0001),
        ("scan_dec0001", scan_dec0001),
        ("scan_hex0001", scan_hex0001),
        ("scan_skipWS0001", scan_skipWS0001)
      ]

  (************************************************************)

end
