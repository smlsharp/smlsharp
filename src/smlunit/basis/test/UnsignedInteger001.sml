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
               end) : sig
  val suite : unit -> SMLUnit.Test.test
end =
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
        val case_0 as () = test w0 (0w0, 0w0)
        val case_123 as () = test w123 (0w123, 0w123)
        val case_maxWord as () = test maxWord (maxWordLarge, maxLargeWord)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualWord expected (W.fromLarge arg)
  in
  fun fromLarge0001 () =
      let
        val case_0 as () = test 0w0 w0
        val case_123 as () = test 0w123 w123
        val case_maxWord as () = test maxWordLarge maxWord
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
        val case_0 as () = test w0 (0, 0)
        val case_123 as () = test w123 (123, 123)
        val case_maxWord as () = test maxWord (maxWordLargeInt, ~1)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualWord expected (W.fromLargeInt arg)
  in
  fun fromLargeInt0001 () =
      let
        val case_0 as () = test 0 w0
        val case_123 as () = test 123 w123
        val case_FFFFFFFF as () = test ~1 maxWord
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
        val case_0 as () = test w0 (0, 0)
        val case_123 as () = test w123 (123, 123)
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
        val case_maxInt as () =
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
        val case_m1 as () =
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
        val case_m1 as () = assertEqualInt ~1 (W.toIntX arg)
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
        val case_minInt as () =
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
        val case_minInt as () =
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
        val case_0 as () = test 0 w0
        val case_123 as () = test 123 w123
        val case_7FFFFFFF as () =
            test
                (case Int.precision
                  of SOME 31 => I2i 0x3FFFFFFF
                   | SOME 32 => I2i 0x7FFFFFFF
                   | SOME 64 => I2i 0x7FFFFFFFFFFFFFFF)
                (case Int.precision
                  of SOME 31 => I2w 0x3FFFFFFF
                   | SOME 32 => I2w 0x7FFFFFFF
                   | SOME 64 => I2w 0x7FFFFFFFFFFFFFFF)
        val case_FFFFFFFF as () = test ~1 maxWord
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqual3Word expected (W.andb arg, W.orb arg, W.xorb arg)
  in
  fun binBit0001 () =
      let
        val case_0_0 as () = test (w0, w0) (w0, w0, w0)
        val case_F0_0F as () = test (I2w 0xF0, I2w 0x0F) (w0, I2w 0xFF, I2w 0xFF)
        val case_0F_0F as () = test (I2w 0x0F, I2w 0x0F) (I2w 0x0F, I2w 0x0F, w0)
      in () end
  end (* local *)

  (********************)

  fun notb0001 () =
      let
        val case_0 as () = assertEqualWord maxWord (W.notb w0)
        val case_F0 as () =
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
        val case_0_0 as () = test (w0, 0w0) (w0, w0, w0)
        val case_1_0 as () = test (w1, 0w0) (w1, w1, w1)
        val case_1_1 as () = test (w1, 0w1) (w2, w0, w0)
        val case_1_2 as () = test (w1, 0w2) (w4, w0, w0)
        val case_1_max_m1 as () =
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
        val case_1_max as () = test (w1, Word.fromInt W.wordSize) (w0, w0, w0)
        val case_1F_1 as () = test (wx1F, 0w1) (I2w 0x3E, I2w 0xF, I2w 0xF)
        val case_1F_2 as () = test (wx1F, 0w2) (I2w 0x7C, w7, w7)
        val case_1F_max_m1 as () =
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
        val case_1F_max as () =
            test (wx1F, Word.fromInt W.wordSize) (w0, w0, w0)

        val case_max_1 as () =
            test
                (maxWord, 0w1) (W.-(maxWord, w1), W.div (maxWord, w2), maxWord)
        val case_max_max_m1 as () =
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
        val case_max_max as () =
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
        val case_pp as () = test (w7, w3) w10
        val case_zp as () = test (w0, w3) w3
        val case_pz as () = test (w7, w0) w7
        val case_zz as () = test (w0, w0) w0

        val case_max_0 as () = test (maxWord, w0) maxWord
        val case_max_1 as () = test (maxWord, w1) w0
        val case_max_max as () =
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
        val case_pp_gt as () = test (w7, w3) w4
        val case_pp_eq as () = test (w7, w7) w0
        val case_pp_lt as () =
            test
                (w3, w7)
                (case W.wordSize
                  of 8 => I2w 0xFC
                   | 31 => I2w 0x7FFFFFFC
                   | 32 => I2w 0xFFFFFFFC
                   | 64 => I2w 0xFFFFFFFFFFFFFFFC)
        val case_zp as () =
            test
                (w0, w3)
                (case W.wordSize
                  of 8 => I2w 0xFD
                   | 31 => I2w 0x7FFFFFFD
                   | 32 => I2w 0xFFFFFFFD
                   | 64 => I2w 0xFFFFFFFFFFFFFFFD)
        val case_pz as () = test (w7, w0) w7
        val case_zz as () = test (w0, w0) w0
        val case_max_0 as () = test (maxWord, w0) maxWord
        val case_max_max as () = test (maxWord, maxWord) w0
      in () end
  end (* inner local *)

  local val test = test W.*
  in
  fun mul0001 () =
      let
        val case_pp as () = test (w7, w3) (I2w 21)
        val case_zp as () = test (w0, w3) w0
        val case_pz as () = test (w7, w0) w0
        val case_zz as () = test (w0, w0) w0
        val case_max_0 as () = test (maxWord, w0) w0
        val case_max_1 as () = test (maxWord, w1) maxWord
        val case_max_max as () = test (maxWord, maxWord) w1
      in () end
  end (* inner local *)

  local
    val test = test W.div
    val testFailDiv = testFailDiv W.div
  in
  fun div0001 () =
      let
        val case_pp as () = test (w7, w3) w2
        val case_zp as () = test (w0, w3) w0
        val case_pz as () = testFailDiv (w7, w0)
        val case_zz as () = testFailDiv (w0, w0)
        val case_max_0 as () = testFailDiv (maxWord, w0)
        val case_max_1 as () = test (maxWord, w1) maxWord
        val case_max_max as () = test (maxWord, maxWord) w1
      in () end
  end (* inner local *)

  local
    val test = test W.mod
    val testFailDiv = testFailDiv W.mod
  in
  fun mod0001 () =
      let
        val case_pp as () = test (w7, w3) w1
        val case_zp as () = test (w0, w3) w0
        val case_pz as () = testFailDiv (w7, w0)
        val case_zz as () = testFailDiv (w0, w0)
        val case_max_0 as () = testFailDiv (maxWord, w0)
        val case_max_1 as () = test (maxWord, w1) w0
        val case_max_max as () = test (maxWord, maxWord) w0
      in () end
  end (* inner local *)

  end (* outer local *)

  (********************)

  local fun test args expected = assertEqualOrder expected (W.compare args)
  in
  fun compare0001 () =
      let
        val case_ppL as () = test (w3, w7) LESS
        val case_ppE as () = test (w7, w7) EQUAL
        val case_ppG as () = test (w7, w3) GREATER
        val case_zp as () = test (w0, w3) LESS
        val case_pz as () = test (w7, w0) GREATER
        val case_zz as () = test (w0, w0) EQUAL

        val case_maxWord_0 as () = test (maxWord, w0) GREATER
        val case_maxWord_1 as () = test (maxWord, w1) GREATER
        val case_maxWord_maxWord as () = test (maxWord, maxWord) EQUAL
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
        val case_ppL as () = test (w3, w7) TTFF
        val case_ppE as () = test (w7, w7) FTTF
        val case_ppG as () = test (w7, w3) FFTT
        val case_zp as () = test (w0, w3) TTFF
        val case_pz as () = test (w7, w0) FFTT
        val case_zz as () = test (w0, w0) FTTF

        val case_maxWord_z as () = test (maxWord, w0) FFTT
        val case_maxWord_1 as () = test (maxWord, w1) FFTT
        val case_z_maxWord as () = test (w0, maxWord) TTFF
        val case_1_maxWord as () = test (w1, maxWord) TTFF
        val case_maxWord_maxWord as () = test (maxWord, maxWord) FTTF
      in () end

  end (* local *)

  (********************)

  fun tilda0001 () =
      let
        val case_0 as () = assertEqualWord w0 (W.~ w0)
        val case_1 as () = assertEqualWord maxWord (W.~ w1)
        val case_maxWord as () = assertEqualWord w1 (W.~ maxWord)
      in () end

  (********************)

  local
    fun test arg expected = assertEqual2Word expected (W.min arg, W.max arg)
  in
  fun minMax0001 () =
      let
        val case_ppL as () = test (w3, w7) (w3, w7)
        val case_ppE as () = test (w7, w7) (w7, w7)
        val case_ppG as () = test (w7, w3) (w3, w7)
        val case_zp as () = test (w0, w3) (w0, w3)
        val case_pz as () = test (w7, w0) (w0, w7)
        val case_zz as () = test (w0, w0) (w0, w0)

        val case_maxWord_z as () = test (maxWord, w0) (w0, maxWord)
        val case_z_maxWord as () = test (w0, maxWord) (w0, maxWord)
        val case_maxWord_1 as () = test (maxWord, w1) (w1, maxWord)
        val case_1_maxWord as () = test (w1, maxWord) (w1, maxWord)
        val case_maxWord_maxWord as () = test (maxWord, maxWord) (maxWord, maxWord)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg1 arg2 expected  = assertEqualString expected (W.fmt arg1 arg2)
  in
  fun fmt_bin0001 () =
      let
        val case_bin_z as () = test StringCvt.BIN w0 "0"
        val case_bin_p1 as () = test StringCvt.BIN w1 "1"
        val case_bin_p2 as () = test StringCvt.BIN w123 "1111011"
        val case_bin_maxWord as () =
            test
                StringCvt.BIN
                maxWord
                (String.implode (List.tabulate (W.wordSize, fn _ => #"1")))
      in () end
  fun fmt_oct0001 () =
      let
        val case_oct_z as () = test StringCvt.OCT w0 "0"
        val case_oct_p1 as () = test StringCvt.OCT w1 "1"
        val case_oct_p2 as () = test StringCvt.OCT w123 "173"
        val case_oct_maxWord as () =
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
        val case_dec_z as () = test StringCvt.DEC w0 "0"
        val case_dec_p1 as () = test StringCvt.DEC w1 "1"
        val case_dec_p2 as () = test StringCvt.DEC w123 "123"
        val case_dec_maxWord as () =
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
        val case_hex_z as () = test StringCvt.HEX w0 "0"
        val case_hex_p1 as () = test StringCvt.HEX w1 "1"
        val case_hex_p2 as () = test StringCvt.HEX w123 "7B"
        val case_hex_maxWord as () =
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
        val case_z as () = test w0 "0"
        val case_p1 as () = test w1 "1"
        val case_p2 as () = test w123 "7B"
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualWordOption expected (W.fromString arg)
  in
  fun fromString0001 () =
      let
        val case_null as () = test "" NONE
        val case_nonum as () = test "ghi123def" NONE
        val case_z1 as () = test "0" (SOME w0)
        val case_z2 as () = test "0w00" (SOME w0)
        val case_z12 as () = test "0ghi" (SOME w0)
        val case_p1 as () = test "1f" (SOME wx1F)
        val case_p12 as () = test "0wx1fghi" (SOME wx1F)

        val case_skipWS as () = test " \f\n\r\t\v1" (SOME w1)
        val case_trailer as () = test "0wx1Fghi" (SOME wx1F)
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

  local val test = test StringCvt.BIN
  in
  fun scan_bin0001 () =
      let
        val case_bin_null as () = test "" NONE
        val case_bin_0 as () = test "0" (SOME(w0, []))
        val case_bin_0w00 as () = test "0w00" (SOME(w0, []))
        val case_bin_1 as () = test "1" (SOME(w1, []))
        val case_bin_0w12 as () = test "0w12" (SOME(w1, [#"2"]))
        val case_bin_0w1a as () = test "0w1a" (SOME(w1, [#"a"]))
        val case_bin_01 as () = test "01" (SOME(w1, []))
        val case_bin_11 as () = test "11" (SOME(w3, []))
        val case_bin_maxWord as () =
            test
                (String.implode (List.tabulate (W.wordSize, fn _ => #"1")))
                (SOME(maxWord, []))
      in () end
  fun scan_bin1001 () =
      let
        val case_bin_2 as () = test "2" NONE
        val case_bin_maxWordPlus1 as () =
            testOverflow
                StringCvt.BIN
                (String.implode
                     (List.tabulate (W.wordSize + 1, fn _ => #"1")))
      in () end
  end (* inner local *)

  local val test = test StringCvt.OCT
  in
  fun scan_oct0001 () =
      let
        val case_oct_null as () = test "" NONE
        val case_oct_0 as () = test "0" (SOME(w0, []))
        val case_oct_0w00 as () = test "0w00" (SOME(w0, []))
        val case_oct_173 as () = test "173" (SOME(w123, []))
        val case_oct_0w1738 as () = test "0w1738" (SOME(w123, [#"8"]))
        val case_oct_0173 as () = test "0173" (SOME(w123, []))
        val case_oct_maxWord as () = 
            test
                (case W.wordSize
                  of 8 => "377"
                   | 31 => "17777777777"
                   | 32 => "37777777777"
                   | 64 => "1777777777777777777777")
                (SOME(maxWord, []))
      in () end
  fun scan_oct1001 () =
      let
        val case_oct_9 as () = test "9" NONE
        val case_oct_maxWordPlus1 as () =
            testOverflow
                StringCvt.OCT
                (case W.wordSize
                  of 8 => "400"
                   | 31 => "20000000000"
                   | 32 => "40000000000"
                   | 64 => "2000000000000000000000")
      in () end
  end (* inner local *)

  local val test = test StringCvt.DEC
  in
  fun scan_dec0001 () =
      let
        val case_dec_null as () = test "" NONE
        val case_dec_0 as () = test "0" (SOME(w0, []))
        val case_dec_0w00 as () = test "0w00" (SOME(w0, []))
        val case_dec_123 as () = test "123" (SOME(w123, []))
        val case_dec_0w123a as () = test "0w123a" (SOME(w123, [#"a"]))
        val case_dec_0123 as () = test "0123" (SOME(w123, []))
        val case_dec_maxWord as () =
            test
                (case W.wordSize
                  of 8 => "255"
                   | 31 => "2147483647"
                   | 32 => "4294967295"
                   | 64 => "18446744073709551615")
                (SOME(maxWord, []))
      in () end
  fun scan_dec1001 () =
      let
        val case_dec_a as () = test "a" NONE
        val case_dec_maxWordPlus1 as () =
            testOverflow
                StringCvt.DEC
                (case W.wordSize
                  of 8 => "256"
                   | 31 => "2147483648"
                   | 32 => "4294967296"
                   | 64 => "18446744073709551616")
      in () end
  end (* inner local *)

  local val test = test StringCvt.HEX
  in
  fun scan_hex0001 () =
      let
        val case_hex_null as () = test "" NONE
        val case_hex_0wx as () = test "0wx " (SOME(w0, [#"w", #"x", #" "]))
        val case_hex_0wX as () = test "0wX " (SOME(w0, [#"w", #"X", #" "]))
        val case_hex_0x as () = test "0x " (SOME(w0, [ #"x", #" "]))
        val case_hex_0X as () = test "0X " (SOME(w0, [ #"X", #" "]))
        val case_hex_0 as () = test "0" (SOME(w0, []))
        val case_hex_00 as () = test "00" (SOME(w0, []))
        val case_hex_0wx0 as () = test "0wx0" (SOME(w0, []))
        val case_hex_0wX0 as () = test "0wX0" (SOME(w0, []))
        val case_hex_0x0 as () = test "0x0" (SOME(w0, []))
        val case_hex_0X0 as () = test "0X0" (SOME(w0, []))
        val case_hex_7B as () = test "7B" (SOME(w123, []))
        val case_hex_1FGg as () = test "1FGg" (SOME(wx1F, [#"G", #"g"]))
        val case_hex_0wx1FGg as () = test "0wx1FGg" (SOME(wx1F, [#"G", #"g"]))
        val case_hex_0wX1FGg as () = test "0wX1FGg" (SOME(wx1F, [#"G", #"g"]))
        val case_hex_0x1FGg as () = test "0x1FGg" (SOME(wx1F, [#"G", #"g"]))
        val case_hex_0X1FGg as () = test "0X1FGg" (SOME(wx1F, [#"G", #"g"]))
        val case_hex_07B as () = test "07B" (SOME(w123, []))
        val case_hex_maxWord as () =
            test
                (case W.wordSize
                  of 8 => "FF"
                   | 31 => "7FFFFFFF"
                   | 32 => "FFFFFFFF"
                   | 64 => "FFFFFFFFFFFFFFFF")
                (SOME(maxWord, []))
      in () end
  fun scan_hex1001 () =
      let
        val case_hex_g as () = test "g" NONE
        val case_hex_maxWordPlus1 as () =
            testOverflow
                StringCvt.HEX
                (case W.wordSize
                  of 8 => "100"
                   | 31 => "80000000"
                   | 32 => "100000000"
                   | 64 => "10000000000000000")
      in () end
  end (* inner local *)

  fun scan_skipWS0001 () =
      let
        val case_skipWS1 as () = test StringCvt.DEC "  123" (SOME(w123, []))
        val case_skipWS2 as () = test StringCvt.DEC "\t\n\v\f\r123" (SOME(w123, []))
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
        ("scan_bin1001", scan_bin1001),
        ("scan_oct0001", scan_oct0001),
        ("scan_oct1001", scan_oct1001),
        ("scan_dec0001", scan_dec0001),
        ("scan_dec1001", scan_dec1001),
        ("scan_hex0001", scan_hex0001),
        ("scan_hex1001", scan_hex1001),
        ("scan_skipWS0001", scan_skipWS0001)
      ]

  (************************************************************)

end
