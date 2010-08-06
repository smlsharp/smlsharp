(**
 * test cases for Substring structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Substring001 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  structure SS = Substring

  (************************************************************)

  val assertEqualBase =
      assertEqual3Tuple (assertEqualString, assertEqualInt, assertEqualInt)

  val assertEqualCSSOption =
      assertEqualOption
          (assertEqual2Tuple (assertEqualChar, assertEqualSubstring))

  val assertEqual3Bool =
      assertEqual3Tuple (assertEqualBool, assertEqualBool, assertEqualBool)

  val assertEqual2Substring =
      assertEqual2Tuple (assertEqualSubstring, assertEqualSubstring)

  val assertEqual4Substring =
      assertEqual4Tuple
          (
            assertEqualSubstring,
            assertEqualSubstring,
            assertEqualSubstring,
            assertEqualSubstring
          )

  val abc_0_1 = SS.substring ("abc", 0, 1)
  val abc_1_0 = SS.substring ("abc", 1, 0)
  val abc_1_1 = SS.substring ("abc", 1, 1)
  val abc_1_2 = SS.substring ("abc", 1, 2)
  val abc_2_1 = SS.substring ("abc", 2, 1)
  val abcd_1_2 = SS.substring ("abcd", 1, 2)
  val abcde_1_3 = SS.substring("abcde", 1, 3)
  val abcdef_1_3 = SS.substring ("abcdef", 1, 3)
  val xyz_1_0 = SS.substring ("xyz", 1, 0)
  val xyz_1_1 = SS.substring ("xyz", 1, 1)
  val xyz_1_2 = SS.substring ("xyz", 1, 2)
  val xbz_1_1 = SS.substring ("xbz", 1, 1)
  val xbz_1_2 = SS.substring ("xbz", 1, 2)
  val xbc_1_2 = SS.substring ("xbc", 1, 2)

  (********************)

  local
    fun test arg expected = assertEqualChar expected (SS.sub  arg)
    fun testFail arg =
        (SS.sub arg; fail "sub:Subscript") handle General.Subscript => ()
  in
  fun sub0001 () =
      let
        val sub_0_0 = testFail (abc_1_0, 0)
        val sub_1_m1 = testFail (abc_1_1, ~1)
        val sub_1_0 = test (abc_1_1, 0) #"b"
        val sub_1_1 = testFail (abc_1_1, 1)
        val sub_2_m1 = testFail (abcd_1_2, ~1)
        val sub_2_0 = test (abcd_1_2, 0) #"b"
        val sub_2_1 = test (abcd_1_2, 1) #"c"
        val sub_2_2 = testFail (abcd_1_2, 2)
      in () end
  end (* local *)

  (********************)

  fun size0001 () =
      let
        val size_0 = SS.size abc_1_0
        val _ = assertEqualInt 0 size_0
        val size_1 = SS.size abc_1_1
        val _ = assertEqualInt 1 size_1
        val size_2 = SS.size abcd_1_2
        val _ = assertEqualInt 2 size_2
      in () end

  (********************)

  local
    (* base o substring is an identify function. *)
    fun test arg = assertEqualBase arg (SS.base (SS.substring arg))
  in
  fun base0001 () =
      let
        val base_0_0_0 = test ("", 0, 0)
        val base_3_0_0 = test ("abc", 0, 0)
        val base_3_0_1 = test ("abc", 0, 1)
        val base_3_0_2 = test ("abc", 0, 2)
        val base_3_0_3 = test ("abc", 0, 3)
        val base_3_1_0 = test ("abc", 1, 0)
        val base_3_1_1 = test ("abc", 1, 1)
        val base_3_1_2 = test ("abc", 1, 2)
        val base_3_2_0 = test ("abc", 2, 0)
        val base_3_2_1 = test ("abc", 2, 1)
        val base_3_3_0 = test ("abc", 3, 0)
      in () end
  end (* local *)

  (********************)

  local
    fun test (arg as (s, i, j)) expected =
        let
          val argBase = (s, i, Option.getOpt(j, String.size s - i))
          val ss = SS.extract arg
          val base = SS.base ss
          val _ = assertEqualString expected (SS.string ss)
          (* Basis spec requires that base o substring be the identity
           * function on valid arguments. *)
          val _ = assertEqualBase argBase base
        in () end
  in
  fun extract0001 () =
      let
        (* safe cases *)
        val extract_0_0_N = test ("", 0, NONE) ""
        val extract_0_0_0 = test ("", 0, SOME 0) ""
        val extract_1_0_N = test ("a", 0, NONE) "a"
        val extract_1_0_0 = test ("a", 0, SOME 0) ""
        val extract_1_0_1 = test ("a", 0, SOME 1) "a"
        val extract_1_1_N = test ("a", 1, NONE) ""
        val extract_1_1_0 = test ("a", 1, SOME 0) ""
        val extract_2_0_N = test ("ab", 0, NONE) "ab"
        val extract_2_0_0 = test ("ab", 0, SOME 0) ""
        val extract_2_0_1 = test ("ab", 0, SOME 1) "a"
        val extract_2_0_2 = test ("ab", 0, SOME 2) "ab"
        val extract_2_1_N = test ("ab", 1, NONE) "b"
        val extract_2_1_0 = test ("ab", 1, SOME 0) ""
        val extract_2_1_1 = test ("ab", 1, SOME 1) "b"
        val extract_2_2_N = test ("ab", 2, NONE) ""
        val extract_2_2_0 = test ("ab", 2, SOME 0) ""
      in () end
  end (* local *)

  local
    fun test arg =
        (SS.extract arg; fail "Subscript expected.")
        handle General.Subscript => ()
  in
  fun extract1001 () =
      let
        (* error cases *)
        val extract_2_m1_N = test ("ab", ~1, NONE)
        val extract_2_3_N = test ("ab", 3, NONE)
        val extract_2_m1_0 = test ("ab", ~1, SOME 0)
        val extract_2_0_m1 = test ("ab", ~1, SOME ~1)
        val extract_2_1_2 = test ("ab", 1, SOME 2)
      in () end
  end (* local *)

  (********************)

  (* safe cases *)
  local
    fun test (arg as (s, i, j)) expected =
        let
          val ss = SS.substring arg
          val base = SS.base ss
          val _ = assertEqualString expected (SS.string ss)
          (* Basis spec requires that base o substring be the identity
           * function on valid arguments. *)
          val _ = assertEqualBase arg base
        in () end
  in
  fun substring0001 () =
      let
        val substring_0_0_0 = test ("", 0, 0) ""
        val substring_1_0_0 = test ("a", 0, 0) ""
        val substring_1_0_1 = test ("a", 0, 1) "a"
        val substring_1_1_0 = test ("a", 1, 0) ""
        val substring_2_0_0 = test ("ab", 0, 0) ""
        val substring_2_0_1 = test ("ab", 0, 1) "a"
        val substring_2_0_2 = test ("ab", 0, 2) "ab"
        val substring_2_1_0 = test ("ab", 1, 0) ""
        val substring_2_1_1 = test ("ab", 1, 1) "b"
        val substring_2_2_0 = test ("ab", 2, 0) ""
      in () end
  end (* local *)

  local
    fun test arg =
        (SS.substring arg; fail "Subscript expected.")
        handle General.Subscript => ()
  in
  fun substring1001 () =
      let
        (* error cases *)
        val substring_2_m1_0 = test ("ab", ~1, 0)
        val substring_2_0_m1 = test ("ab", ~1, ~1)
        val substring_2_1_2 = test ("ab", 1, 2)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        let
          val ss = SS.full arg
          val _ = assertEqualString expected (SS.string ss)
          (* Basis spec says that 
           *   Substring.full s
           * is equivalent to the expression
           *   Substring.substring(s, 0, String.size s).
           *)
          val _ = assertEqualSubstring
                      (SS.substring(arg, 0, String.size arg)) ss
        in () end
  in
  fun full0001 () =
      let
        val full_empty = test "" ""
        val full_1 = test "a" "a"
        val full_2 = test "ab" "ab"
        val full_10 = test "abcdefghij" "abcdefghij"
      in () end
  end (* local *)

  (********************)

  fun string0001 () =
      let
        val string_0 = assertEqualString "" (SS.string (SS.full ""))
        val string_1 = assertEqualString "a" (SS.string (SS.full "a"))
        val string_3_0 = assertEqualString "a" (SS.string abc_0_1)
        val string_3_1 = assertEqualString "b" (SS.string abc_1_1)
        val string_3_2 = assertEqualString "c" (SS.string abc_2_1)
      in () end
    
  (********************)

  fun isEmpty0001 () =
      let
        val isEmpty_0 = SS.isEmpty(SS.full "")
        val _ = assertTrue isEmpty_0
        val isEmpty_1_0_N = SS.isEmpty(SS.extract("a", 0, NONE))
        val _ = assertFalse isEmpty_1_0_N
        val isEmpty_1_0_0 = SS.isEmpty(SS.extract("a", 0, SOME 0))
        val _ = assertTrue isEmpty_1_0_0
        val isEmpty_1_0_1 = SS.isEmpty(SS.extract("a", 0, SOME 1))
        val _ = assertFalse isEmpty_1_0_1
        val isEmpty_1_1_N = SS.isEmpty(SS.extract("a", 1, NONE))
        val _ = assertTrue isEmpty_1_1_N
      in () end

  (********************)

  local fun test arg expected = assertEqualCSSOption expected (SS.getc arg)
  in
  fun getc0001 () =
      let
        val getc_0 = test (SS.full "") NONE
        val getc_1_0_N = test (SS.extract("a", 0, NONE))
        val getc_1_0_0 = test (SS.extract("a", 0, SOME 0)) NONE
        val getc_1_0_1 = test (SS.extract("a", 0, SOME 1)) (SOME(#"a", SS.full ""))
        val getc_1_1_N = test (SS.extract("a", 1, NONE)) NONE
      in () end
  end (* local *)

  (********************)

  local fun test arg expected = assertEqualCharOption expected (SS.first arg)
  in
  fun first0001 () =
      let
        val first_0 = test (SS.full "") NONE
        val first_1_0_N = test (SS.extract("a", 0, NONE)) (SOME #"a")
        val first_1_0_0 = test (SS.extract("a", 0, SOME 0)) NONE
        val first_1_0_1 = test (SS.extract("a", 0, SOME 1)) (SOME #"a")
        val first_1_1_N = test (SS.extract("a", 1, NONE)) NONE
      in () end
  end (* local *)

  (********************)

  local
    fun test arg1 arg2 (expectedl, expectedr) =
        let
          val rl = SS.triml arg1 arg2
          val rr = SS.trimr arg1 arg2
          val _ =
              assertEqual2Substring
                  (SS.full expectedl, SS.full expectedr) (rl, rr)
        in () end
  in
  fun trim0001 () =
      let
        val triml_0_0 = test 0 (SS.full "") ("", "")
        val triml_1_0 = test 1 (SS.full "") ("", "") (* safe *)
        val triml_0_1 = test 0 abc_1_1 ("b", "b")
        val triml_1_1 = test 1 abc_1_1 ("", "")
        val triml_2_1 = test 2 abc_1_1 ("", "")
        val triml_0_2 = test 0 abcd_1_2 ("bc", "bc")
        val triml_1_2 = test 1 abcd_1_2 ("c", "b")
        val triml_2_2 = test 2 abcd_1_2 ("", "")
        val triml_3_2 = test 3 abcd_1_2 ("", "")
      in () end
  end (* local *)

  fun trim1001 () =
      (* error case *)
      let
        val triml_m1 =
            (SOME(SS.triml ~1); fail "triml: expects Subscript")
            handle General.Subscript => NONE
        val trimr_m1 =
            (SOME(SS.trimr ~1); fail "trimr: expects Subscript")
            handle General.Subscript => NONE
      in () end

  (********************)

  local
    fun test arg expected =
        assertEqualSubstring (SS.full expected) (SS.slice arg)
  in
  (* safe cases *)
  fun slice0001 () =
      let
        val slice_0_0_N = test (abc_1_0, 0, NONE) ""
        val slice_0_0_0 = test (abc_1_0, 0, SOME 0)  ""
        val slice_1_0_N = test (abc_1_1, 0, NONE) "b"
        val slice_1_0_0 = test (abc_1_1, 0, SOME 0) ""
        val slice_1_0_1 = test (abc_1_1, 0, SOME 1) "b"
        val slice_1_1_N = test (abc_1_1, 1, NONE) ""
        val slice_1_1_0 = test (abc_1_1, 1, SOME 0) ""
        val slice_2_0_N = test (abcd_1_2, 0, NONE) "bc"
        val slice_2_0_0 = test (abcd_1_2, 0, SOME 0) ""
        val slice_2_0_1 = test (abcd_1_2, 0, SOME 1) "b"
        val slice_2_0_2 = test (abcd_1_2, 0, SOME 2) "bc"
        val slice_2_1_N = test (abcd_1_2, 1, NONE) "c"
        val slice_2_1_0 = test (abcd_1_2, 1, SOME 0) ""
        val slice_2_1_1 = test (abcd_1_2, 1, SOME 1) "c"
        val slice_2_2_N = test (abcd_1_2, 2, NONE) ""
        val slice_2_2_0 = test (abcd_1_2, 2, SOME 0) ""
      in () end
  end (* local *)

  (* error cases *)
  fun slice1001 () =
      let
        val slice_2_m1_N =
            (SS.slice(abcd_1_2, ~1, NONE); fail "slice_2_m1_N:Subscript")
            handle General.Subscript => NONE
        val slice_2_3_N =
            (SS.slice(abcd_1_2, 3, NONE); fail "slice_2_3_N:Subscript")
            handle General.Subscript => NONE
        val slice_2_m1_0 =
            (SS.slice(abcd_1_2, ~1, SOME 0); fail "slice_2_m1_0:Subscript")
            handle General.Subscript => NONE
        val slice_2_0_m1 =
            (SS.slice(abcd_1_2, ~1, SOME ~1); fail "slice_2_0_m1:Subscript")
            handle General.Subscript => NONE
        val slice_2_1_2 =
            (SS.slice(abcd_1_2, 1, SOME 2); fail "slice_2_1_2:Subscript")
            handle General.Subscript => NONE
      in () end

  (********************)

  local fun test arg expected = assertEqualString expected (SS.concat arg)
  in
  fun concat0001 () =
      let
        val concat_0 = test [] ""
        val concat_1 = test [abcd_1_2] "bc"
        val concat_2_diff = test [abcd_1_2, abc_1_1] "bcb"
        val concat_2_same = test [abcd_1_2, abcd_1_2] "bcbc"
        val concat_2_02 = test [abc_1_0, abcd_1_2] "bc"
        val concat_2_20 = test [abcd_1_2, abc_1_0] "bc"
        val concat_3_202 = test [abcd_1_2, abc_1_0, abcd_1_2] "bcbc"
        val concat_3_212 = test [abcd_1_2, abc_1_1, abcd_1_2] "bcbbc"
      in () end
  end (* local *)

  (********************)

  local
    fun test arg1 arg2 expected =
        assertEqualString expected (SS.concatWith arg1 arg2)
  in
  fun concatWith0001 () =
      let
        val concatWith_0 = test "X" [] ""
        val concatWith_1 = test "X" [abcd_1_2] "bc"
        val concatWith_2_diff = test "X" [abcd_1_2, abc_1_1] "bcXb"
        val concatWith_2_same = test "X" [abcd_1_2, abcd_1_2] "bcXbc"
        val concatWith_2_02 = test "X" [abc_1_0, abcd_1_2] "Xbc"
        val concatWith_2_20 = test "X" [abcd_1_2, abc_1_0] "bcX"
        val concatWith_3_202 = test "X" [abcd_1_2, abc_1_0, abcd_1_2] "bcXXbc"
        val concatWith_3_212 = test "X" [abcd_1_2, abc_1_1, abcd_1_2] "bcXbXbc"
      in () end
  end (* local *)

  (********************)

  local fun test arg expected = assertEqualCharList expected (SS.explode arg)
  in
  fun explode0001 () =
      let
        val explode_0_0_0 = test (SS.substring("", 0, 0)) []
        val explode_1_0_0 = test (SS.substring("a", 0, 0)) []
        val explode_1_0_1 = test (SS.substring("a", 0, 1)) [#"a"]
        val explode_1_1_0 = test (SS.substring("a", 1, 0)) []
        val explode_2_0_0 = test (SS.substring("ab", 0, 0)) []
        val explode_2_0_1 = test (SS.substring("ab", 0, 1)) [#"a"]
        val explode_2_0_2 = test (SS.substring("ab", 0, 2)) [#"a", #"b"]
        val explode_2_1_0 = test (SS.substring("ab", 1, 0)) []
        val explode_2_1_1 = test (SS.substring("ab", 1, 1)) [#"b"]
        val explode_2_2_0 = test (SS.substring("ab", 2, 0)) []
      in () end
  end (* local *)

  (********************)

  local
    fun test arg1 arg2 expected =
        assertEqual3Bool
            expected
            (
              SS.isPrefix arg1 arg2,
              SS.isSubstring arg1 arg2,
              SS.isSuffix arg1 arg2
            )
    val TTT = (true, true, true)
    val FFF = (false, false, false)
    val TTF = (true, true, false)
    val FTT = (false, true, true)
    val FTF = (false, true, false)
  in
  fun isContained0001 () =
      let
        val isContained_0_0 = test "" abc_1_0 TTT
        val isContained_1_0 = test "a" abc_1_0 FFF
        val isContained_0_1 = test "" abc_1_1 TTT
        val isContained_1_1t = test "b" abc_1_1 TTT
        val isContained_1_1f = test "a" abc_1_1 FFF
        val isContained_1_2a = test "a" abc_1_2 FFF
        val isContained_1_2b = test "b" abc_1_2 TTF
        val isContained_1_2c = test "c" abc_1_2 FTT
        val isContained_2_2bc = test "bc" abc_1_2 TTT
        val isContained_2_2bd = test "bd" abc_1_2 FFF
        val isContained_2_2dc = test "dc" abc_1_2 FFF
        val isContained_1_3c = test "c" abcde_1_3 FTF
        val isContained_1_3e = test "e" abcde_1_3 FFF
        val isContained_2_3bc = test "bc" abcde_1_3 TTF
        val isContained_2_3bd = test "bd" abcde_1_3 FFF
        val isContained_2_3bd = test "cd" abcde_1_3 FTT
        val isContained_3_3bcd = test "bcd" abcde_1_3 TTT
        val isContained_3_3ccd = test "ccd" abcde_1_3 FFF
        val isContained_3_3bcc = test "bcc" abcde_1_3 FFF
      in () end
  end (* local *)

  (********************)

  local fun test arg expected = assertEqualOrder expected (SS.compare arg)
  in
  fun compare0001 () =
      let
        val compare_0_0 = test (abc_1_0, xyz_1_0) EQUAL
        val compare_0_1 = test (abc_1_0, xyz_1_1) LESS
        val compare_1_0 = test (abc_1_1, xyz_1_0) GREATER
        val compare_1_1_lt = test (abc_1_1, xyz_1_1) LESS
        val compare_1_1_eq = test (abc_1_1, xbz_1_1) EQUAL
        val compare_1_1_gt = test (xyz_1_1, abc_1_1) GREATER
        val compare_1_2_lt = test (abc_1_1, xyz_1_2) LESS
        val compare_1_2_gt = test (xyz_1_1, abc_1_2) GREATER
        val compare_2_1_lt = test (abc_1_2, xyz_1_1) LESS
        val compare_2_1_gt = test (xyz_1_2, abc_1_1) GREATER
        val compare_2_2_lt = test (abc_1_2, xyz_1_2) LESS
        val compare_2_2_eq = test (abc_1_2, xbc_1_2) EQUAL
        val compare_2_2_gt = test (xyz_1_2, abc_1_2) GREATER
      in () end
  end (* local *)

  (********************)

  local
    (* reverse of Char.collate *)
    fun compare (left, right : char) =
        if left < right
        then General.GREATER
        else if left = right then General.EQUAL else General.LESS
    fun test arg expected = assertEqualOrder expected (SS.collate compare arg)
  in
  fun collate0001 () =
      let
        val collate_0_0 = test (abc_1_0, xyz_1_0) EQUAL
        val collate_0_1 = test (abc_1_0, xyz_1_1) LESS
        val collate_1_0 = test (abc_1_1, xyz_1_0) GREATER
        val collate_1_1_lt = test (abc_1_1, xyz_1_1) GREATER
        val collate_1_1_eq = test (abc_1_1, xbz_1_1) EQUAL
        val collate_1_1_gt = test (xyz_1_1, abc_1_1) LESS
        val collate_1_2_lt = test (abc_1_1, xyz_1_2) GREATER
        val collate_1_2_gt = test (xyz_1_1, abc_1_2) LESS
        val collate_2_1_lt = test (abc_1_2, xyz_1_1) GREATER
        val collate_2_1_gt = test (xyz_1_2, abc_1_1) LESS
        val collate_2_2_lt = test (abc_1_2, xyz_1_2) GREATER
        val collate_2_2_eq = test (abc_1_2, xbc_1_2) EQUAL
        val collate_2_2_gt = test (xyz_1_2, abc_1_2) LESS
      in () end
  end (* local *)

  (********************)

  local
    fun predicate char = char = #"A"
    fun test arg ((expectedll, expectedlr), (expectedrl, expectedrr)) =
        let
          val arg = SS.substring arg
          val l = SS.splitl predicate arg
          val r = SS.splitr predicate arg
          val _ =
              assertEqual2Substring (SS.full expectedll, SS.full expectedlr) l
          val _ =
              assertEqual2Substring (SS.full expectedrl, SS.full expectedrr) r
        in () end
  in
  fun split0001 () =
      let
        val split_0 = test ("", 0, 0) (("", ""), ("", ""))
        val split_1_0 = test ("abc", 1, 1) (("", "b"), ("b", ""))
        val split_1_1 = test ("aAc", 1, 1) (("A", ""), ("", "A"))
        val split_2_00 = test ("abcd", 1, 2) (("", "bc"), ("bc", ""))
        val split_2_01 = test ("aaAd", 1, 2) (("", "aA"), ("a", "A"))
        val split_2_10 = test ("aAcd", 1, 2) (("A", "c"), ("Ac", ""))
        val split_2_11 = test ("aAAd", 1, 2) (("AA", ""), ("", "AA"))
        val split_3_000 = test ("abcde", 1, 3) (("", "bcd"), ("bcd", ""))
        val split_3_001 = test ("abcAe", 1, 3) (("", "bcA"), ("bc", "A"))
        val split_3_010 = test ("abAde", 1, 3) (("", "bAd"), ("bAd", ""))
        val split_3_011 = test ("abAAe", 1, 3) (("", "bAA"), ("b", "AA"))
        val split_3_100 = test ("aAcde", 1, 3) (("A", "cd"), ("Acd", ""))
        val split_3_101 = test ("aAcAe", 1, 3) (("A", "cA"), ("Ac", "A"))
        val split_3_110 = test ("aAAde", 1, 3) (("AA", "d"), ("AAd", ""))
        val split_3_111 = test ("aAAAe", 1, 3) (("AAA", ""), ("", "AAA"))
      in () end
  end (* local *)

  (********************)

  local
    fun test arg (expectedl, expectedr) =
        assertEqual2Substring
            (SS.full expectedl, SS.full expectedr) (SS.splitAt arg)
    fun testFail arg =
        (SS.splitAt arg; fail "splitAt: Subscript.")
        handle General.Subscript => NONE
  in
  fun splitAt0001 () =
      let
        val splitAt_0_0 = test (SS.full "", 0) ("", "")
        val splitAt_0_m1 = testFail (SS.full "", ~1)
        val splitAt_0_1 = testFail (SS.full "", 1)
        val splitAt_1_0 = test (abc_1_1, 0) ("", "b")
        val splitAt_1_1 = test (abc_1_1, 1) ("b", "")
        val splitAt_1_2 = testFail (abc_1_1, 2)
        val splitAt_1_m1 = testFail (abc_1_1, ~1)
        val splitAt_2_0 = test (abcd_1_2, 0) ("", "bc")
        val splitAt_2_1 = test (abcd_1_2, 1) ("b", "c")
        val splitAt_2_2 = test (abcd_1_2, 2) ("bc", "")
        val splitAt_2_3 = testFail (abcd_1_2, 3) 
        val splitAt_2_m1 = testFail (abcd_1_2, ~1)
        val splitAt_3_0 = test (abcde_1_3, 0) ("", "bcd")
        val splitAt_3_1 = test (abcde_1_3, 1) ("b", "cd")
        val splitAt_3_2 = test (abcde_1_3, 2) ("bc", "d")
        val splitAt_3_3 = test (abcde_1_3, 3) ("bcd", "")
        val splitAt_3_4 = testFail (abcde_1_3, 4)
        val splitAt_3_m1 = testFail (abcde_1_3, ~1)
      in () end
  end (* local *)

(********************)

  local
    fun predicate char = char = #"A"
    fun test arg (dropl, dropr, takel, taker) =
        let
          val arg = SS.substring arg
          val _ =
              assertEqual4Substring
                  (SS.full dropl, SS.full dropr, SS.full takel, SS.full taker)
                  (
                    SS.dropl predicate arg,
                    SS.dropr predicate arg,
                    SS.takel predicate arg,
                    SS.taker predicate arg
                  )
        in () end
  in
  fun dropTake0001 () =
      let
        val dropl_0_0 = test ("", 0, 0) ("", "", "", "")
        val dropl_1_0 = test ("abc", 1, 1) ("b", "b", "", "")
        val dropl_1_1 = test ("aAc", 1, 1) ("", "", "A", "A")
        val dropl_2_00 = test ("abcd", 1, 2) ("bc", "bc", "", "")
        val dropl_2_01 = test ("abAd", 1, 2) ("bA", "b", "", "A")
        val dropl_2_10 = test ("aAcd", 1, 2) ("c", "Ac", "A", "")
        val dropl_2_11 = test ("aAAd", 1, 2) ("", "", "AA", "AA")
        val dropl_3_000 = test ("abcde", 1, 3) ("bcd", "bcd", "", "")
        val dropl_3_001 = test ("abcAe", 1, 3) ("bcA", "bc", "", "A")
        val dropl_3_010 = test ("abAde", 1, 3) ("bAd", "bAd", "", "")
        val dropl_3_011 = test ("abAAe", 1, 3) ("bAA", "b", "", "AA")
        val dropl_3_101 = test ("aAcAe", 1, 3) ("cA", "Ac", "A", "A")
        val dropl_3_100 = test ("aAcde", 1, 3) ("cd", "Acd", "A", "")
        val dropl_3_110 = test ("aAAde", 1, 3) ("d", "AAd", "AA", "")
        val dropl_3_111 = test ("aAAAe", 1, 3) ("", "", "AAA", "AAA")
      in () end
  end (* local *)

  (********************)

  local
    fun test arg1 arg2 (expectedl, expectedr) =
        assertEqual2Substring
            (SS.full expectedl, SS.full expectedr) (SS.position arg1 arg2)
  in
  fun position0001 () =
      let
        val position_0_0 = test "" abc_1_0 ("", "")
        val position_0_1 = test "" abc_1_1 ("", "b")
        val position_1_1_m1 = test "a" abc_1_1 ("b", "")
        val position_1_1_1 = test "c" abc_1_1 ("b", "")
        val position_1_1_0t = test "b" abc_1_1 ("", "b")
        val position_1_2_m1 = test "a" abcd_1_2 ("bc", "")
        val position_1_2_0 = test "b" abcd_1_2 ("", "bc")
        val position_1_2_1 = test "c" abcd_1_2 ("b", "c")
        val position_1_2_2 = test "d" abcd_1_2 ("bc", "")
        val position_2_1_f1 = test "ab" abc_1_1 ("b", "")
        val position_2_1_f2 = test "bc" abc_1_1 ("b", "")
        val position_2_2_m1 = test "ab" abcd_1_2 ("bc", "")
        val position_2_2_0 = test "bc" abcd_1_2 ("", "bc")
        val position_2_2_1 = test "cd" abcd_1_2 ("bc", "")
        val position_2_2_2 = test "de" abcd_1_2 ("bc", "")
        val position_2_3_m1 = test "ab" abcdef_1_3 ("bcd", "")
        val position_2_3_0 = test "bc" abcdef_1_3 ("", "bcd")
        val position_2_3_1 = test "cd" abcdef_1_3 ("b", "cd")
        val position_2_3_2 = test "de" abcdef_1_3 ("bcd", "")
        val position_2_3_3 = test "ef" abcdef_1_3 ("bcd", "")
        (* the 'position' must search the longest suffix. *)
        val position_longest = test "bc" (SS.substring ("abcdbcf", 1, 5)) ("", "bcdbc")
      in () end
  end (* local *)

(********************)

  local
    fun test string (left : int * int) (right : int * int) (expected : int * int) =
        let
          val left = SS.substring (string, #1 left, #2 left)
          val right = SS.substring (string, #1 right, #2 right)
          val r = SS.span (left, right)
        in
          assertEqualBase (string, #1 expected, #2 expected) (SS.base r)
        end
    fun testFail string (left : int * int) (right : int * int) =
        let
          val left = SS.substring (string, #1 left, #2 left)
          val right = SS.substring (string, #1 right, #2 right)
        in
          (SS.span (left, right); fail "span: Span expected.")
          handle General.Span => ()
        end
    (*
     * (ls, le): the start index and the end index of left substring.
     * (rs, re): the start index and the end index of right substring.
     * There are 6 cases in the relation between the ls and the right
     * substring.
     * (A) ls < rs, (B) ls = rs, (C) rs < ls < re, (D) ls = re, (E) re < ls
     * And, same relations between the le and the right substring.
     * (A) le < rs, (B) le = rs, (C) rs < le < re, (D) le = re, (E) re < le
     * Some combinations are not considered because they are impossible. 
     *)
  in
  fun span0001 () =
      let
        val span_0_0_A_A = test "abcde" (1, 0) (3, 0) (1, 2)

        val span_1_1_A_A = test "abcde" (1, 1) (3, 1) (1, 3)
        val span_1_1_A_B = test "abcde" (1, 1) (2, 1) (1, 2)
        val span_1_1_B_D = test "abcde" (1, 1) (1, 1) (1, 1)
        val span_1_1_D_E = test "abcde" (2, 1) (1, 1) (2, 0)
        val span_1_1_E_E = testFail "abcde" (3, 1) (1, 1)

        val span_1_2_A_A = test "abcde" (1, 1) (3, 2) (1, 4)
        val span_1_2_A_B = test "abcde" (1, 1) (2, 2) (1, 3)
        val span_1_2_B_C = test "abcde" (1, 1) (1, 2) (1, 2)
        val span_1_2_C_D = test "abcde" (2, 1) (1, 2) (2, 1)
        val span_1_2_D_E = test "abcde" (3, 1) (1, 2) (3, 0)
        val span_1_2_E_E = testFail "abcde" (3, 1) (0, 2)

        val span_2_1_A_A = test "abcde" (1, 2) (4, 1) (1, 4)
        val span_2_1_A_B = test "abcde" (1, 2) (3, 1) (1, 3)
        val span_2_1_A_D = test "abcde" (1, 2) (2, 1) (1, 2)
        val span_2_1_B_E = test "abcde" (1, 2) (1, 1) (1, 1)
        val span_2_1_D_E = test "abcde" (2, 2) (1, 1) (2, 0)
        val span_2_1_E_E = testFail "abcde" (2, 2) (0, 1)

        val span_2_2_A_A = test "abcdef" (1, 2) (4, 2) (1, 5)
        val span_2_2_A_B = test "abcdef" (1, 2) (3, 2) (1, 4)
        val span_2_2_A_C = test "abcdef" (1, 2) (2, 2) (1, 3)
        val span_2_2_B_D = test "abcdef" (1, 2) (1, 2) (1, 2)
        val span_2_2_C_E = test "abcdef" (2, 2) (1, 2) (2, 1)
        val span_2_2_D_E = test "abcdef" (3, 2) (1, 2) (3, 0)
        val span_2_2_E_E = testFail "abcdef" (3, 2) (0, 2)

        val span_3_1_A_A = test "abcdef" (1, 3) (5, 1) (1, 5)
        val span_3_1_A_B = test "abcdef" (1, 3) (4, 1) (1, 4)
        val span_3_1_A_C = test "abcdef" (1, 3) (3, 1) (1, 3)
        val span_3_1_A_E = test "abcdef" (1, 3) (2, 1) (1, 2)
        val span_3_1_B_E = test "abcdef" (1, 3) (1, 1) (1, 1)
        val span_3_1_D_E = test "abcdef" (2, 3) (1, 1) (2, 0)
        val span_3_1_E_E = testFail "abcdef" (2, 3) (0, 1)

        val span_3_2_A_A = test "abcdefg" (1, 3) (5, 2) (1, 6)
        val span_3_2_A_B = test "abcdefg" (1, 3) (4, 2) (1, 5)
        val span_3_2_A_C = test "abcdefg" (1, 3) (3, 2) (1, 4)
        val span_3_2_A_D = test "abcdefg" (1, 3) (2, 2) (1, 3)
        val span_3_2_B_E = test "abcdefg" (1, 3) (1, 2) (1, 2)
        val span_3_2_C_E = test "abcdefg" (2, 3) (1, 2) (2, 1)
        val span_3_2_D_E = test "abcdefg" (3, 3) (1, 2) (3, 0)
        val span_3_2_E_E = testFail "abcdefg" (3, 3) (0, 2)

        val span_3_3_A_A = test "abcdefgh" (1, 3) (5, 3) (1, 7)
        val span_3_3_A_B = test "abcdefgh" (1, 3) (4, 3) (1, 6)
        val span_3_3_A_Ca = test "abcdefgh" (1, 3) (3, 3) (1, 5)
        val span_3_3_A_Cb = test "abcdefgh" (1, 3) (2, 3) (1, 4)
        val span_3_3_B_D = test "abcdefgh" (1, 3) (1, 3) (1, 3)
        val span_3_3_C_Ea = test "abcdefgh" (2, 3) (1, 3) (2, 2)
        val span_3_3_C_Eb = test "abcdefgh" (3, 3) (1, 3) (3, 1)
        val span_3_3_D_E = test "abcdefgh" (4, 3) (1, 3) (4, 0)
        val span_3_3_E_E = testFail "abcdefgh" (4, 3) (0, 3)

        val span_2_3_A_A = test "abcdefg" (1, 2) (4, 3) (1, 6)
        val span_2_3_A_B = test "abcdefg" (1, 2) (3, 3) (1, 5)
        val span_2_3_A_C = test "abcdefg" (1, 2) (2, 3) (1, 4)
        val span_2_3_B_C = test "abcdefg" (1, 2) (1, 3) (1, 3)
        val span_2_3_C_D = test "abcdefg" (2, 2) (1, 3) (2, 2)
        val span_2_3_D_E = test "abcdefg" (3, 2) (1, 3) (3, 1)
        val span_2_3_E_E = testFail "abcdefg" (4, 2) (0, 3)
        (* le + 1 < rs *)
        val span_3_3_A_A_2 = test "abcdefghi" (1, 3) (5, 3) (1, 7)
      in () end
  end (* local *)
  (* another error case where base strings of substrings are not equal. *)
  fun span1001 () =
      let
        val ss1 = SS.substring ("abcd", 1, 0)
        val ss2 = SS.substring ("bcde", 2, 0)
      in
        (SS.span (ss1, ss2); fail "Span expected.")
        handle General.Span => ()
      end

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f ch = (r := !r @ [ch]; implode [ch, ch])
        in
          (r, f)
        end
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = SS.translate f arg
          val _ = assertEqualString expected r
          val _ = assertEqualCharList visited (!s)
        in () end
  in
  fun translate0001 () =
      let
        val translate0 = test abc_1_0 "" []
        val translate1 = test abc_1_1 "bb" [#"b"]
        val translate2 = test abcd_1_2 "bbcc" [#"b", #"c"]
      in () end
  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f ch = (r := !r @ [ch]; ch = #"|")
        in
          (r, f)
        end
  in

  local
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = SS.tokens f (SS.substring arg)
          val _ = assertEqualSubstringList (List.map SS.full expected) r
          val _ = assertEqualCharList visited (!s)
        in () end
  in
  fun tokens0001 () =
      let
        val tokens_empty = test ("abc", 1, 0) [] []
        val tokens_00 = test ("a|b", 1, 1) [] [#"|"]
        val tokens_01 = test ("a|bc", 1, 2) ["b"] [#"|", #"b"]
        val tokens_10 = test ("ab|c", 1, 2) ["b"] [#"b", #"|"]
        val tokens_11 = test ("ab|cd", 1, 3) ["b", "c"] [#"b", #"|", #"c"]
        val tokens_000 = test ("a||b", 1, 2) [] [#"|", #"|"]
        val tokens_001 = test ("a||bc", 1, 3) ["b"] [#"|", #"|", #"b"]
        val tokens_010 = test ("a|b|c", 1, 3) ["b"] [#"|", #"b", #"|"]
        val tokens_011 = test ("a|b|cd", 1, 4) ["b", "c"] [#"|", #"b", #"|", #"c"]
        val tokens_100 = test ("ab||c", 1, 3) ["b"] [#"b", #"|", #"|"]
        val tokens_101 = test ("ab||cd", 1, 4) ["b", "c"] [#"b", #"|", #"|", #"c"]
        val tokens_110 = test ("ab|c|d", 1, 4) ["b", "c"] [#"b", #"|", #"c", #"|"]
        val tokens_111 = test ("ab|c|de", 1, 5) ["b", "c", "d"] [#"b", #"|", #"c", #"|", #"d"]
        val tokens_222 = test ("abc|de|fgh", 1, 8) ["bc", "de", "fg"] [#"b", #"c", #"|", #"d", #"e", #"|", #"f", #"g"]
      in () end
  end (* inner local *)

  (********************)

  local
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = SS.fields f (SS.substring arg)
          val _ = assertEqualSubstringList (List.map SS.full expected) r
          val _ = assertEqualCharList visited (!s)
        in () end
  in
  fun fields0001 () =
      let
        val fields_empty = test ("abc", 1, 0) [""] []
        val fields_00 = test ("a|b", 1, 1) ["", ""] [#"|"]
        val fields_01 = test ("a|bc", 1, 2) ["", "b"] [#"|", #"b"]
        val fields_10 = test ("ab|c", 1, 2) ["b", ""] [#"b", #"|"]
        val fields_11 = test ("ab|cd", 1, 3) ["b", "c"] [#"b", #"|", #"c"]
        val fields_000 = test ("a||b", 1, 2) ["", "", ""] [#"|", #"|"]
        val fields_001 = test ("a||bc", 1, 3) ["", "", "b"] [#"|", #"|", #"b"]
        val fields_010 = test ("a|b|c", 1, 3) ["", "b", ""] [#"|", #"b", #"|"]
        val fields_011 = test ("a|b|cd", 1, 4) ["", "b", "c"] [#"|", #"b", #"|", #"c"]
        val fields_100 = test ("ab||c", 1, 3) ["b", "", ""] [#"b", #"|", #"|"]
        val fields_101 = test ("ab||cd", 1, 4) ["b", "", "c"] [#"b", #"|", #"|", #"c"]
        val fields_110 = test ("ab|c|d", 1, 4) ["b", "c", ""] [#"b", #"|", #"c", #"|"]
        val fields_111 = test ("ab|c|de", 1, 5) ["b", "c", "d"] [#"b", #"|", #"c", #"|", #"d"]
        val fields_222 = test ("abc|de|fgh", 1, 8) ["bc", "de", "fg"] [#"b", #"c", #"|", #"d", #"e", #"|", #"f", #"g"]
      in () end
  end (* inner local *)

  end (* outer local *)

(********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f n = r := !r @ [n]
        in
          (r, f)
        end
    fun test arg visited =
        let
          val (r, f) = makeState ()
          val () = SS.app f arg
          val _ = assertEqualCharList visited (!r)
        in () end
  in
  fun app0001 () =
      let
        val app0 = test abc_1_0 []
        val app1 = test abc_1_1 [#"b"]
        val app2 = test abcd_1_2 [#"b", #"c"]
      in () end
  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val r= ref []
          fun f (n, accum) = (r := !r @ [n]; n :: accum)
        in
          (r, f)
        end
    fun test fold arg1 arg2 expected visited =
        let
          val (s, f) = makeState ()
          val r = fold f arg1 arg2
          val _ = assertEqualCharList expected r
          val _ = assertEqualCharList visited (!s)
        in () end
    val testl = test SS.foldl
    val testr = test SS.foldr
  in

  fun foldl0001 () =
      let
        val foldl_0 = testl [] abc_1_0 []
        val foldl_1 = testl [] abc_1_1 [#"b"] [#"b"]
        val foldl_2 = testl [] abcd_1_2 [#"c", #"b"] [#"b", #"c"]
        val foldl_3 = testl [] abcde_1_3 [#"d", #"c", #"b"] [#"b", #"c", #"d"]
      in () end

  (********************)

  fun foldr0001 () =
      let
        val foldr_0 = testr [] abc_1_0 []
        val foldr_1 = testr [] abc_1_1 [#"b"] [#"b"]
        val foldr_2 = testr [] abcd_1_2 [#"b", #"c"] [#"c", #"b"]
        val foldr_3 = testr [] abcde_1_3 [#"b", #"c", #"d"] [#"d", #"c", #"b"]
      in () end

  end (* local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("sub0001", sub0001),
        ("size0001", size0001),
        ("base0001", base0001),
        ("extract0001", extract0001),
        ("extract1001", extract1001),
        ("substring0001", substring0001),
        ("substring1001", substring1001),
        ("full0001", full0001),
        ("string0001", string0001),
        ("isEmpty0001", isEmpty0001),
        ("getc0001", getc0001),
        ("first0001", first0001),
        ("trim0001", trim0001),
        ("trim1001", trim1001),
        ("slice0001", slice0001),
        ("slice1001", slice1001),
        ("concat0001", concat0001),
        ("concatWith0001", concatWith0001),
        ("explode0001", explode0001),
        ("isContained0001", isContained0001),
        ("compare0001", compare0001),
        ("collate0001", collate0001),
        ("split0001", split0001),
        ("splitAt0001", splitAt0001),
        ("dropTake0001", dropTake0001),
        ("position0001", position0001),
        ("span0001", span0001),
        ("span1001", span1001),
        ("translate0001", translate0001),
        ("tokens0001", tokens0001),
        ("fields0001", fields0001),
        ("app0001", app0001),
        ("foldl0001", foldl0001),
        ("foldr0001", foldr0001)
      ]

  (************************************************************)

end