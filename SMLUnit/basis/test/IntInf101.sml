(**
 * test cases for IntInf structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure IntInf101 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  structure I = IntInf

  (************************************************************)

  val assertEqualInt =  assertEqualByCompare I.compare I.toString
  val assertEqual2Int = assertEqual2Tuple (assertEqualInt, assertEqualInt)
  val assertEqual3Int =
      assertEqual3Tuple (assertEqualInt, assertEqualInt, assertEqualInt)

  (****************************************)

  local
    fun test arg expected = assertEqual2Int expected (I.divMod arg)
    fun testDiv args =
        (I.divMod args; fail "expect Div.") handle General.Div => ()
  in
  fun divMod0001 () =
      let
        val case_mm as () = test (~8, ~3) (2, ~2)
        val case_mp as () = test (~8, 3) (~3, 1)
        val case_pm as () = test (8, ~3) (~3, ~1)
        val case_pp as () = test (8, 3) (2, 2)
        val case_zp as () = test (0, 3) (0, 0)
      in () end
  fun divMod1001 () =
      let
        val case_pz as () = testDiv (8, 0)
        val case_zz as () = testDiv (0, 0)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqual2Int expected (I.quotRem arg)
    fun testDiv args =
        (I.quotRem args; fail "expect Div.") handle General.Div => ()
  in
  fun quotRem0001 () =
      let
        val case_mm as () = test (~8, ~3) (2, ~2)
        val case_mp as () = test (~8, 3) (~2, ~2)
        val case_pm as () = test (8, ~3) (~2, 2)
        val case_pp as () = test (8, 3) (2, 2)
        val case_zp as () = test (0, 3) (0, 0)
      in () end
  fun quotRem1001 () =
      let
        val case_pz as () = testDiv (8, 0)
        val case_zz as () = testDiv (0, 0)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualInt expected (I.pow arg)
    fun testDiv args =
        (I.pow args; fail "expect Div.") handle General.Div => ()
  in
  fun pow0001 () =
      let
        val case_n3_n2 as () = test (~3, ~2) 0
        val case_n3_z as () = test (~3, 0) 1
        val case_n3_p2 as () = test (~3, 2) 9
        val case_n1_n2 as () = test (~1, ~2) 1 (* SML/NJ returns 0. *)
        val case_n1_z as () = test (~1, 0) 1
        val case_n1_p2 as () = test (~1, 2) 1
        val case_z_n2 as () = testDiv (0, ~2)
        val case_z_z as () = test (0, 0) 1
        val case_z_p2 as () = test (0, 2) 0
        val case_p1_n2 as () = test (1, ~2) 1
        val case_p1_z as () = test (1, 0) 1
        val case_p1_p2 as () = test (1, 2) 1
        val case_p3_n2 as () = test (3, ~2) 0
        val case_p3_z as () = test (3, 0) 1
        val case_p3_p2 as () = test (3, 2) 9
      in () end
  end (* local *)

  local
    fun test arg expected = A.assertEqualInt expected (I.log2 arg)
    fun testDomain args =
        (I.log2 args; fail "expect Domain.") handle General.Domain => ()
    fun testOverflow args =
        (I.log2 args; fail "expect Overflow.") handle General.Overflow => ()
  in
  fun log20001 () =
      let
        val case2_n2 as () = testDomain ~2
        val case2_z as () = testDomain 0
        val case2_p1 as () = test 1 0
        val case2_p2 as () = test 2 1
        val case2_p3 as () = test 3 1
        val case2_p4 as () = test 4 2
        val case2_p5 as () = test 5 2
      in () end
  fun log20002 () =
      let
        (* ToDo : we should test whether log2(i) raises Overflow if i is equal
         * or greater than pow(2, valOf(Int.maxInt) + 1).
         * For example, if Int.precision = SOME 32, log2 should raise Overflow
         * when 2^0x80000000 <= i.
         *)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqual3Int expected (I.andb arg, I.orb arg, I.xorb arg)
  in
  fun binBit0001 () =
      let
        val case_0_0 as () = test (0, 0) (0, 0, 0)
        val case_F0_0F as () = test (0xF0, 0x0F) (0, 0xFF, 0xFF)
        val case_0F_0F as () = test (0x0F, 0x0F) (0x0F, 0x0F, 0)
      in () end
  fun binBit0002 () =
      (* negative integers *)
      let
        val case_n1_n1 as () = test (~1, ~1) (~1, ~1, 0)
        val case_n1_z as () = test (~1, 0) (0, ~1, ~1)
        val case_n1_p1 as () = test (~1, 1) (1, ~1, ~2)
      in () end
  end (* local *)

  (********************)

  fun notb0001 () =
      let
        val case_0 as () = assertEqualInt ~1 (I.notb 0)
        val case_0F as () = assertEqualInt ~0x10 (I.notb 0x0F)
        val case_F0 as () = assertEqualInt ~0xF1 (I.notb 0xF0)
      in () end
  fun notb0002 () =
      case Int.precision
       of NONE => ()
        | SOME precision =>
          let
            val maxIntPlus1 =
                case precision
                 of 31 => 0x80000000
                  | 32 => 0x100000000
                  | 64 => 0x10000000000000000
            val notb_maxIntPlus1 =
                case precision
                 of 31 => ~0x80000001
                  | 32 => ~0x100000001
                  | 64 => ~0x10000000000000001
            val () = assertEqualInt notb_maxIntPlus1 (I.notb maxIntPlus1)
          in () end
  fun notb0003 () =
      case Int.precision
       of NONE => ()
        | SOME precision =>
          let
            val minInt =
                case precision
                 of 31 => ~0x80000000
                  | 32 => ~0x100000000
                  | 64 => ~0x10000000000000000
            val notb_minInt =
                case precision
                 of 31 => 0x7FFFFFFF
                  | 32 => 0xFFFFFFFF
                  | 64 => 0xFFFFFFFFFFFFFFFF
            val () = assertEqualInt notb_minInt (I.notb minInt)
          in () end

  (********************)

  local
    fun test arg expected = assertEqual2Int expected (I.<< arg, I.~>> arg)
  in
  fun shift0001 () =
      let
        val case_n1_0 as () = test (~1, 0w0) (~1, ~1)
        val case_n1_1 as () = test (~1, 0w1) (~2, ~1)
        val case_n1_2 as () = test (~1, 0w2) (~4, ~1)
        val case_0_0 as () = test (0, 0w0) (0, 0)
        val case_0_1 as () = test (0, 0w1) (0, 0)
        val case_p1_0 as () = test (1, 0w0) (1, 1)
        val case_p1_1 as () = test (1, 0w1) (2, 0)
        val case_p1_2 as () = test (1, 0w2) (4, 0)

        val case_p1F_1 as () = test (0x1F, 0w1) (0x3E, 0xF)
        val case_p1F_2 as () = test (0x1F, 0w2) (0x7C, 0x7)

        val case_n1F_1 as () = test (~0x1F, 0w1) (~0x3E, ~0x10)
        val case_n1F_2 as () = test (~0x1F, 0w2) (~0x7C, ~0x08)
      in () end
  fun shift0002 () =
      case Int.precision
       of NONE => ()
        | SOME precision =>
          let
            val maxInt = I.fromInt (valOf Int.maxInt)
            val maxIntMul2 =
                case precision
                 of 31 => 0x7FFFFFFE
                  | 32 => 0xFFFFFFFE
                  | 64 => 0xFFFFFFFFFFFFFFFE
            val maxIntDiv2 =
                case precision
                 of 31 => 0x1FFFFFFF
                  | 32 => 0x3FFFFFFF
                  | 64 => 0x3FFFFFFFFFFFFFFF
            val case_maxInt_0 as () = test (maxInt, 0w0) (maxInt, maxInt)
            val case_maxInt_1 as () = test (maxInt, 0w1) (maxIntMul2, maxIntDiv2)
          in () end
  fun shift0003 () =
      case Int.precision
       of NONE => ()
        | SOME precision =>
          let
            val minInt = I.fromInt (valOf Int.minInt)
            val minIntMul2 =
                case precision
                 of 31 => ~0x80000000
                  | 32 => ~0x100000000
                  | 64 => ~0x10000000000000000
            val minIntDiv2 =
                case precision
                 of 31 => ~0x20000000
                  | 32 => ~0x40000000
                  | 64 => ~0x4000000000000000
            val case_minInt_0 as () = test (minInt, 0w0) (minInt, minInt)
            val case_minInt_1 as () = test (minInt, 0w1) (minIntMul2, minIntDiv2)
          in () end
  end (* local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("divMod0001", divMod0001),
        ("divMod1001", divMod1001),
        ("quotRem0001", quotRem0001),
        ("quotRem1001", quotRem1001),
        ("pow0001", pow0001),
        ("log20001", log20001),
        ("log20002", log20002),
        ("binBit0001", binBit0001),
        ("binBit0002", binBit0002),
        ("notb0001", notb0001),
        ("notb0002", notb0002),
        ("notb0003", notb0003),
        ("shift0001", shift0001),
        ("shift0002", shift0002),
        ("shift0003", shift0003)
      ]

  (************************************************************)

end