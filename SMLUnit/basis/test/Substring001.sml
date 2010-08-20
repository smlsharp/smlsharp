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
        val case_0_0 as () = testFail (abc_1_0, 0)
        val case_1_m1 as () = testFail (abc_1_1, ~1)
        val case_1_0 as () = test (abc_1_1, 0) #"b"
        val case_1_1 as () = testFail (abc_1_1, 1)
        val case_2_m1 as () = testFail (abcd_1_2, ~1)
        val case_2_0 as () = test (abcd_1_2, 0) #"b"
        val case_2_1 as () = test (abcd_1_2, 1) #"c"
        val case_2_2 as () = testFail (abcd_1_2, 2)
      in () end
  end (* local *)

  (********************)

  fun size0001 () =
      let
        val size_0 = SS.size abc_1_0
        val () = assertEqualInt 0 size_0
        val size_1 = SS.size abc_1_1
        val () = assertEqualInt 1 size_1
        val size_2 = SS.size abcd_1_2
        val () = assertEqualInt 2 size_2
      in () end

  (********************)

  local
    (* base o substring is an identify function. *)
    fun test arg = assertEqualBase arg (SS.base (SS.substring arg))
  in
  fun base0001 () =
      let
        val case_0_0_0 as () = test ("", 0, 0)
        val case_3_0_0 as () = test ("abc", 0, 0)
        val case_3_0_1 as () = test ("abc", 0, 1)
        val case_3_0_2 as () = test ("abc", 0, 2)
        val case_3_0_3 as () = test ("abc", 0, 3)
        val case_3_1_0 as () = test ("abc", 1, 0)
        val case_3_1_1 as () = test ("abc", 1, 1)
        val case_3_1_2 as () = test ("abc", 1, 2)
        val case_3_2_0 as () = test ("abc", 2, 0)
        val case_3_2_1 as () = test ("abc", 2, 1)
        val case_3_3_0 as () = test ("abc", 3, 0)
      in () end
  end (* local *)

  (********************)

  local
    fun test (arg as (s, i, j)) expected =
        let
          val argBase = (s, i, Option.getOpt(j, String.size s - i))
          val ss = SS.extract arg
          val base = SS.base ss
          val () = assertEqualString expected (SS.string ss)
          (* Basis spec requires that base o substring be the identity
           * function on valid arguments. *)
          val () = assertEqualBase argBase base
        in () end
  in
  fun extract0001 () =
      let
        (* safe cases *)
        val case_0_0_N as () = test ("", 0, NONE) ""
        val case_0_0_0 as () = test ("", 0, SOME 0) ""
        val case_1_0_N as () = test ("a", 0, NONE) "a"
        val case_1_0_0 as () = test ("a", 0, SOME 0) ""
        val case_1_0_1 as () = test ("a", 0, SOME 1) "a"
        val case_1_1_N as () = test ("a", 1, NONE) ""
        val case_1_1_0 as () = test ("a", 1, SOME 0) ""
        val case_2_0_N as () = test ("ab", 0, NONE) "ab"
        val case_2_0_0 as () = test ("ab", 0, SOME 0) ""
        val case_2_0_1 as () = test ("ab", 0, SOME 1) "a"
        val case_2_0_2 as () = test ("ab", 0, SOME 2) "ab"
        val case_2_1_N as () = test ("ab", 1, NONE) "b"
        val case_2_1_0 as () = test ("ab", 1, SOME 0) ""
        val case_2_1_1 as () = test ("ab", 1, SOME 1) "b"
        val case_2_2_N as () = test ("ab", 2, NONE) ""
        val case_2_2_0 as () = test ("ab", 2, SOME 0) ""
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
        val case_2_m1_N as () = test ("ab", ~1, NONE)
        val case_2_3_N as () = test ("ab", 3, NONE)
        val case_2_m1_0 as () = test ("ab", ~1, SOME 0)
        val case_2_0_m1 as () = test ("ab", ~1, SOME ~1)
        val case_2_1_2 as () = test ("ab", 1, SOME 2)
      in () end
  end (* local *)

  (********************)

  (* safe cases *)
  local
    fun test (arg as (s, i, j)) expected =
        let
          val ss = SS.substring arg
          val base = SS.base ss
          val () = assertEqualString expected (SS.string ss)
          (* Basis spec requires that base o substring be the identity
           * function on valid arguments. *)
          val () = assertEqualBase arg base
        in () end
  in
  fun substring0001 () =
      let
        val case_0_0_0 as () = test ("", 0, 0) ""
        val case_1_0_0 as () = test ("a", 0, 0) ""
        val case_1_0_1 as () = test ("a", 0, 1) "a"
        val case_1_1_0 as () = test ("a", 1, 0) ""
        val case_2_0_0 as () = test ("ab", 0, 0) ""
        val case_2_0_1 as () = test ("ab", 0, 1) "a"
        val case_2_0_2 as () = test ("ab", 0, 2) "ab"
        val case_2_1_0 as () = test ("ab", 1, 0) ""
        val case_2_1_1 as () = test ("ab", 1, 1) "b"
        val case_2_2_0 as () = test ("ab", 2, 0) ""
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
        val case_2_m1_0 as () = test ("ab", ~1, 0)
        val case_2_0_m1 as () = test ("ab", ~1, ~1)
        val case_2_1_2 as () = test ("ab", 1, 2)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        let
          val ss = SS.full arg
          val () = assertEqualString expected (SS.string ss)
          (* Basis spec says that 
           *   Substring.full s
           * is equivalent to the expression
           *   Substring.substring(s, 0, String.size s).
           *)
          val () = assertEqualSubstring
                      (SS.substring(arg, 0, String.size arg)) ss
        in () end
  in
  fun full0001 () =
      let
        val case_empty as () = test "" ""
        val case_1 as () = test "a" "a"
        val case_2 as () = test "ab" "ab"
        val case_10 as () = test "abcdefghij" "abcdefghij"
      in () end
  end (* local *)

  (********************)

  fun string0001 () =
      let
        val case_0 as () = assertEqualString "" (SS.string (SS.full ""))
        val case_1 as () = assertEqualString "a" (SS.string (SS.full "a"))
        val case_3_0 as () = assertEqualString "a" (SS.string abc_0_1)
        val case_3_1 as () = assertEqualString "b" (SS.string abc_1_1)
        val case_3_2 as () = assertEqualString "c" (SS.string abc_2_1)
      in () end
    
  (********************)

  fun isEmpty0001 () =
      let
        val isEmpty_0 = SS.isEmpty(SS.full "")
        val () = assertTrue isEmpty_0
        val isEmpty_1_0_N = SS.isEmpty(SS.extract("a", 0, NONE))
        val () = assertFalse isEmpty_1_0_N
        val isEmpty_1_0_0 = SS.isEmpty(SS.extract("a", 0, SOME 0))
        val () = assertTrue isEmpty_1_0_0
        val isEmpty_1_0_1 = SS.isEmpty(SS.extract("a", 0, SOME 1))
        val () = assertFalse isEmpty_1_0_1
        val isEmpty_1_1_N = SS.isEmpty(SS.extract("a", 1, NONE))
        val () = assertTrue isEmpty_1_1_N
      in () end

  (********************)

  local fun test arg expected = assertEqualCSSOption expected (SS.getc arg)
  in
  fun getc0001 () =
      let
        val case_0 as () = test (SS.full "") NONE
        val case_1_0_N as () = test (SS.extract("a", 0, NONE)) (SOME(#"a", SS.full ""))
        val case_1_0_0 as () = test (SS.extract("a", 0, SOME 0)) NONE
        val case_1_0_1 as () = test (SS.extract("a", 0, SOME 1)) (SOME(#"a", SS.full ""))
        val case_1_1_N as () = test (SS.extract("a", 1, NONE)) NONE
      in () end
  end (* local *)

  (********************)

  local fun test arg expected = assertEqualCharOption expected (SS.first arg)
  in
  fun first0001 () =
      let
        val case_0 as () = test (SS.full "") NONE
        val case_1_0_N as () = test (SS.extract("a", 0, NONE)) (SOME #"a")
        val case_1_0_0 as () = test (SS.extract("a", 0, SOME 0)) NONE
        val case_1_0_1 as () = test (SS.extract("a", 0, SOME 1)) (SOME #"a")
        val case_1_1_N as () = test (SS.extract("a", 1, NONE)) NONE
      in () end
  end (* local *)

  (********************)

  local
    fun test arg1 arg2 (expectedl, expectedr) =
        let
          val rl = SS.triml arg1 arg2
          val rr = SS.trimr arg1 arg2
          val () =
              assertEqual2Substring
                  (SS.full expectedl, SS.full expectedr) (rl, rr)
        in () end
  in
  fun trim0001 () =
      let
        val case_0_0 as () = test 0 (SS.full "") ("", "")
        val case_1_0 as () = test 1 (SS.full "") ("", "") (* safe *)
        val case_0_1 as () = test 0 abc_1_1 ("b", "b")
        val case_1_1 as () = test 1 abc_1_1 ("", "")
        val case_2_1 as () = test 2 abc_1_1 ("", "")
        val case_0_2 as () = test 0 abcd_1_2 ("bc", "bc")
        val case_1_2 as () = test 1 abcd_1_2 ("c", "b")
        val case_2_2 as () = test 2 abcd_1_2 ("", "")
        val case_3_2 as () = test 3 abcd_1_2 ("", "")
      in () end
  end (* local *)

  fun trim1001 () =
      (* error case *)
      let
        val case_m1 as () =
            (SOME(SS.triml ~1); fail "triml: expects Subscript")
            handle General.Subscript => ()
        val case_m1 as () =
            (SOME(SS.trimr ~1); fail "trimr: expects Subscript")
            handle General.Subscript => ()
      in () end

  (********************)

  local
    fun test arg expected =
        assertEqualSubstring (SS.full expected) (SS.slice arg)
  in
  (* safe cases *)
  fun slice0001 () =
      let
        val case_0_0_N as () = test (abc_1_0, 0, NONE) ""
        val case_0_0_0 as () = test (abc_1_0, 0, SOME 0)  ""
        val case_1_0_N as () = test (abc_1_1, 0, NONE) "b"
        val case_1_0_0 as () = test (abc_1_1, 0, SOME 0) ""
        val case_1_0_1 as () = test (abc_1_1, 0, SOME 1) "b"
        val case_1_1_N as () = test (abc_1_1, 1, NONE) ""
        val case_1_1_0 as () = test (abc_1_1, 1, SOME 0) ""
        val case_2_0_N as () = test (abcd_1_2, 0, NONE) "bc"
        val case_2_0_0 as () = test (abcd_1_2, 0, SOME 0) ""
        val case_2_0_1 as () = test (abcd_1_2, 0, SOME 1) "b"
        val case_2_0_2 as () = test (abcd_1_2, 0, SOME 2) "bc"
        val case_2_1_N as () = test (abcd_1_2, 1, NONE) "c"
        val case_2_1_0 as () = test (abcd_1_2, 1, SOME 0) ""
        val case_2_1_1 as () = test (abcd_1_2, 1, SOME 1) "c"
        val case_2_2_N as () = test (abcd_1_2, 2, NONE) ""
        val case_2_2_0 as () = test (abcd_1_2, 2, SOME 0) ""
      in () end
  end (* local *)

  (* error cases *)
  fun slice1001 () =
      let
        val case_2_m1_N as () =
            (SS.slice(abcd_1_2, ~1, NONE); fail "slice_2_m1_N:Subscript")
            handle General.Subscript => ()
        val case_2_3_N as () =
            (SS.slice(abcd_1_2, 3, NONE); fail "slice_2_3_N:Subscript")
            handle General.Subscript => ()
        val case_2_m1_0 as () =
            (SS.slice(abcd_1_2, ~1, SOME 0); fail "slice_2_m1_0:Subscript")
            handle General.Subscript => ()
        val case_2_0_m1 as () =
            (SS.slice(abcd_1_2, ~1, SOME ~1); fail "slice_2_0_m1:Subscript")
            handle General.Subscript => ()
        val case_2_1_2 as () =
            (SS.slice(abcd_1_2, 1, SOME 2); fail "slice_2_1_2:Subscript")
            handle General.Subscript => ()
      in () end

  (********************)

  local fun test arg expected = assertEqualString expected (SS.concat arg)
  in
  fun concat0001 () =
      let
        val case_0 as () = test [] ""
        val case_1 as () = test [abcd_1_2] "bc"
        val case_2_diff as () = test [abcd_1_2, abc_1_1] "bcb"
        val case_2_same as () = test [abcd_1_2, abcd_1_2] "bcbc"
        val case_2_02 as () = test [abc_1_0, abcd_1_2] "bc"
        val case_2_20 as () = test [abcd_1_2, abc_1_0] "bc"
        val case_3_202 as () = test [abcd_1_2, abc_1_0, abcd_1_2] "bcbc"
        val case_3_212 as () = test [abcd_1_2, abc_1_1, abcd_1_2] "bcbbc"
      in () end
  end (* local *)

  (********************)

  local
    fun test arg1 arg2 expected =
        assertEqualString expected (SS.concatWith arg1 arg2)
  in
  fun concatWith0001 () =
      let
        val case_0 as () = test "X" [] ""
        val case_1 as () = test "X" [abcd_1_2] "bc"
        val case_2_diff as () = test "X" [abcd_1_2, abc_1_1] "bcXb"
        val case_2_same as () = test "X" [abcd_1_2, abcd_1_2] "bcXbc"
        val case_2_02 as () = test "X" [abc_1_0, abcd_1_2] "Xbc"
        val case_2_20 as () = test "X" [abcd_1_2, abc_1_0] "bcX"
        val case_3_202 as () = test "X" [abcd_1_2, abc_1_0, abcd_1_2] "bcXXbc"
        val case_3_212 as () = test "X" [abcd_1_2, abc_1_1, abcd_1_2] "bcXbXbc"
      in () end
  end (* local *)

  (********************)

  local fun test arg expected = assertEqualCharList expected (SS.explode arg)
  in
  fun explode0001 () =
      let
        val case_0_0_0 as () = test (SS.substring("", 0, 0)) []
        val case_1_0_0 as () = test (SS.substring("a", 0, 0)) []
        val case_1_0_1 as () = test (SS.substring("a", 0, 1)) [#"a"]
        val case_1_1_0 as () = test (SS.substring("a", 1, 0)) []
        val case_2_0_0 as () = test (SS.substring("ab", 0, 0)) []
        val case_2_0_1 as () = test (SS.substring("ab", 0, 1)) [#"a"]
        val case_2_0_2 as () = test (SS.substring("ab", 0, 2)) [#"a", #"b"]
        val case_2_1_0 as () = test (SS.substring("ab", 1, 0)) []
        val case_2_1_1 as () = test (SS.substring("ab", 1, 1)) [#"b"]
        val case_2_2_0 as () = test (SS.substring("ab", 2, 0)) []
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
        val case_0_0 as () = test "" abc_1_0 TTT
        val case_1_0 as () = test "a" abc_1_0 FFF
        val case_0_1 as () = test "" abc_1_1 TTT
        val case_1_1t as () = test "b" abc_1_1 TTT
        val case_1_1f as () = test "a" abc_1_1 FFF
        val case_1_2a as () = test "a" abc_1_2 FFF
        val case_1_2b as () = test "b" abc_1_2 TTF
        val case_1_2c as () = test "c" abc_1_2 FTT
        val case_2_2bc as () = test "bc" abc_1_2 TTT
        val case_2_2bd as () = test "bd" abc_1_2 FFF
        val case_2_2dc as () = test "dc" abc_1_2 FFF
        val case_1_3c as () = test "c" abcde_1_3 FTF
        val case_1_3e as () = test "e" abcde_1_3 FFF
        val case_2_3bc as () = test "bc" abcde_1_3 TTF
        val case_2_3bd as () = test "bd" abcde_1_3 FFF
        val case_2_3bd as () = test "cd" abcde_1_3 FTT
        val case_3_3bcd as () = test "bcd" abcde_1_3 TTT
        val case_3_3ccd as () = test "ccd" abcde_1_3 FFF
        val case_3_3bcc as () = test "bcc" abcde_1_3 FFF
      in () end
  end (* local *)

  (********************)

  local fun test arg expected = assertEqualOrder expected (SS.compare arg)
  in
  fun compare0001 () =
      let
        val case_0_0 as () = test (abc_1_0, xyz_1_0) EQUAL
        val case_0_1 as () = test (abc_1_0, xyz_1_1) LESS
        val case_1_0 as () = test (abc_1_1, xyz_1_0) GREATER
        val case_1_1_lt as () = test (abc_1_1, xyz_1_1) LESS
        val case_1_1_eq as () = test (abc_1_1, xbz_1_1) EQUAL
        val case_1_1_gt as () = test (xyz_1_1, abc_1_1) GREATER
        val case_1_2_lt as () = test (abc_1_1, xyz_1_2) LESS
        val case_1_2_gt as () = test (xyz_1_1, abc_1_2) GREATER
        val case_2_1_lt as () = test (abc_1_2, xyz_1_1) LESS
        val case_2_1_gt as () = test (xyz_1_2, abc_1_1) GREATER
        val case_2_2_lt as () = test (abc_1_2, xyz_1_2) LESS
        val case_2_2_eq as () = test (abc_1_2, xbc_1_2) EQUAL
        val case_2_2_gt as () = test (xyz_1_2, abc_1_2) GREATER
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
        val case_0_0 as () = test (abc_1_0, xyz_1_0) EQUAL
        val case_0_1 as () = test (abc_1_0, xyz_1_1) LESS
        val case_1_0 as () = test (abc_1_1, xyz_1_0) GREATER
        val case_1_1_lt as () = test (abc_1_1, xyz_1_1) GREATER
        val case_1_1_eq as () = test (abc_1_1, xbz_1_1) EQUAL
        val case_1_1_gt as () = test (xyz_1_1, abc_1_1) LESS
        val case_1_2_lt as () = test (abc_1_1, xyz_1_2) GREATER
        val case_1_2_gt as () = test (xyz_1_1, abc_1_2) LESS
        val case_2_1_lt as () = test (abc_1_2, xyz_1_1) GREATER
        val case_2_1_gt as () = test (xyz_1_2, abc_1_1) LESS
        val case_2_2_lt as () = test (abc_1_2, xyz_1_2) GREATER
        val case_2_2_eq as () = test (abc_1_2, xbc_1_2) EQUAL
        val case_2_2_gt as () = test (xyz_1_2, abc_1_2) LESS
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
          val () =
              assertEqual2Substring (SS.full expectedll, SS.full expectedlr) l
          val () =
              assertEqual2Substring (SS.full expectedrl, SS.full expectedrr) r
        in () end
  in
  fun split0001 () =
      let
        val case_0 as () = test ("", 0, 0) (("", ""), ("", ""))
        val case_1_0 as () = test ("abc", 1, 1) (("", "b"), ("b", ""))
        val case_1_1 as () = test ("aAc", 1, 1) (("A", ""), ("", "A"))
        val case_2_00 as () = test ("abcd", 1, 2) (("", "bc"), ("bc", ""))
        val case_2_01 as () = test ("aaAd", 1, 2) (("", "aA"), ("a", "A"))
        val case_2_10 as () = test ("aAcd", 1, 2) (("A", "c"), ("Ac", ""))
        val case_2_11 as () = test ("aAAd", 1, 2) (("AA", ""), ("", "AA"))
        val case_3_000 as () = test ("abcde", 1, 3) (("", "bcd"), ("bcd", ""))
        val case_3_001 as () = test ("abcAe", 1, 3) (("", "bcA"), ("bc", "A"))
        val case_3_010 as () = test ("abAde", 1, 3) (("", "bAd"), ("bAd", ""))
        val case_3_011 as () = test ("abAAe", 1, 3) (("", "bAA"), ("b", "AA"))
        val case_3_100 as () = test ("aAcde", 1, 3) (("A", "cd"), ("Acd", ""))
        val case_3_101 as () = test ("aAcAe", 1, 3) (("A", "cA"), ("Ac", "A"))
        val case_3_110 as () = test ("aAAde", 1, 3) (("AA", "d"), ("AAd", ""))
        val case_3_111 as () = test ("aAAAe", 1, 3) (("AAA", ""), ("", "AAA"))
      in () end
  end (* local *)

  (********************)

  local
    fun test arg (expectedl, expectedr) =
        assertEqual2Substring
            (SS.full expectedl, SS.full expectedr) (SS.splitAt arg)
    fun testFail arg =
        (SS.splitAt arg; fail "splitAt: Subscript.")
        handle General.Subscript => ()
  in
  fun splitAt0001 () =
      let
        val case_0_0 as () = test (SS.full "", 0) ("", "")
        val case_0_m1 as () = testFail (SS.full "", ~1)
        val case_0_1 as () = testFail (SS.full "", 1)
        val case_1_0 as () = test (abc_1_1, 0) ("", "b")
        val case_1_1 as () = test (abc_1_1, 1) ("b", "")
        val case_1_2 as () = testFail (abc_1_1, 2)
        val case_1_m1 as () = testFail (abc_1_1, ~1)
        val case_2_0 as () = test (abcd_1_2, 0) ("", "bc")
        val case_2_1 as () = test (abcd_1_2, 1) ("b", "c")
        val case_2_2 as () = test (abcd_1_2, 2) ("bc", "")
        val case_2_3 as () = testFail (abcd_1_2, 3) 
        val case_2_m1 as () = testFail (abcd_1_2, ~1)
        val case_3_0 as () = test (abcde_1_3, 0) ("", "bcd")
        val case_3_1 as () = test (abcde_1_3, 1) ("b", "cd")
        val case_3_2 as () = test (abcde_1_3, 2) ("bc", "d")
        val case_3_3 as () = test (abcde_1_3, 3) ("bcd", "")
        val case_3_4 as () = testFail (abcde_1_3, 4)
        val case_3_m1 as () = testFail (abcde_1_3, ~1)
      in () end
  end (* local *)

(********************)

  local
    fun predicate char = char = #"A"
    fun test arg (dropl, dropr, takel, taker) =
        let
          val arg = SS.substring arg
          val () =
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
        val case_0_0 as () = test ("", 0, 0) ("", "", "", "")
        val case_1_0 as () = test ("abc", 1, 1) ("b", "b", "", "")
        val case_1_1 as () = test ("aAc", 1, 1) ("", "", "A", "A")
        val case_2_00 as () = test ("abcd", 1, 2) ("bc", "bc", "", "")
        val case_2_01 as () = test ("abAd", 1, 2) ("bA", "b", "", "A")
        val case_2_10 as () = test ("aAcd", 1, 2) ("c", "Ac", "A", "")
        val case_2_11 as () = test ("aAAd", 1, 2) ("", "", "AA", "AA")
        val case_3_000 as () = test ("abcde", 1, 3) ("bcd", "bcd", "", "")
        val case_3_001 as () = test ("abcAe", 1, 3) ("bcA", "bc", "", "A")
        val case_3_010 as () = test ("abAde", 1, 3) ("bAd", "bAd", "", "")
        val case_3_011 as () = test ("abAAe", 1, 3) ("bAA", "b", "", "AA")
        val case_3_101 as () = test ("aAcAe", 1, 3) ("cA", "Ac", "A", "A")
        val case_3_100 as () = test ("aAcde", 1, 3) ("cd", "Acd", "A", "")
        val case_3_110 as () = test ("aAAde", 1, 3) ("d", "AAd", "AA", "")
        val case_3_111 as () = test ("aAAAe", 1, 3) ("", "", "AAA", "AAA")
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
        val case_0_0 as () = test "" abc_1_0 ("", "")
        val case_0_1 as () = test "" abc_1_1 ("", "b")
        val case_1_1_m1 as () = test "a" abc_1_1 ("b", "")
        val case_1_1_1 as () = test "c" abc_1_1 ("b", "")
        val case_1_1_0t as () = test "b" abc_1_1 ("", "b")
        val case_1_2_m1 as () = test "a" abcd_1_2 ("bc", "")
        val case_1_2_0 as () = test "b" abcd_1_2 ("", "bc")
        val case_1_2_1 as () = test "c" abcd_1_2 ("b", "c")
        val case_1_2_2 as () = test "d" abcd_1_2 ("bc", "")
        val case_2_1_f1 as () = test "ab" abc_1_1 ("b", "")
        val case_2_1_f2 as () = test "bc" abc_1_1 ("b", "")
        val case_2_2_m1 as () = test "ab" abcd_1_2 ("bc", "")
        val case_2_2_0 as () = test "bc" abcd_1_2 ("", "bc")
        val case_2_2_1 as () = test "cd" abcd_1_2 ("bc", "")
        val case_2_2_2 as () = test "de" abcd_1_2 ("bc", "")
        val case_2_3_m1 as () = test "ab" abcdef_1_3 ("bcd", "")
        val case_2_3_0 as () = test "bc" abcdef_1_3 ("", "bcd")
        val case_2_3_1 as () = test "cd" abcdef_1_3 ("b", "cd")
        val case_2_3_2 as () = test "de" abcdef_1_3 ("bcd", "")
        val case_2_3_3 as () = test "ef" abcdef_1_3 ("bcd", "")
        (* the 'position' must search the longest suffix. *)
        val case_longest as () = test "bc" (SS.substring ("abcdbcf", 1, 5)) ("", "bcdbc")
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
        val case_0_0_A_A as () = test "abcde" (1, 0) (3, 0) (1, 2)

        val case_1_1_A_A as () = test "abcde" (1, 1) (3, 1) (1, 3)
        val case_1_1_A_B as () = test "abcde" (1, 1) (2, 1) (1, 2)
        val case_1_1_B_D as () = test "abcde" (1, 1) (1, 1) (1, 1)
        val case_1_1_D_E as () = test "abcde" (2, 1) (1, 1) (2, 0)
        val case_1_1_E_E as () = testFail "abcde" (3, 1) (1, 1)

        val case_1_2_A_A as () = test "abcde" (1, 1) (3, 2) (1, 4)
        val case_1_2_A_B as () = test "abcde" (1, 1) (2, 2) (1, 3)
        val case_1_2_B_C as () = test "abcde" (1, 1) (1, 2) (1, 2)
        val case_1_2_C_D as () = test "abcde" (2, 1) (1, 2) (2, 1)
        val case_1_2_D_E as () = test "abcde" (3, 1) (1, 2) (3, 0)
        val case_1_2_E_E as () = testFail "abcde" (3, 1) (0, 2)

        val case_2_1_A_A as () = test "abcde" (1, 2) (4, 1) (1, 4)
        val case_2_1_A_B as () = test "abcde" (1, 2) (3, 1) (1, 3)
        val case_2_1_A_D as () = test "abcde" (1, 2) (2, 1) (1, 2)
        val case_2_1_B_E as () = test "abcde" (1, 2) (1, 1) (1, 1)
        val case_2_1_D_E as () = test "abcde" (2, 2) (1, 1) (2, 0)
        val case_2_1_E_E as () = testFail "abcde" (2, 2) (0, 1)

        val case_2_2_A_A as () = test "abcdef" (1, 2) (4, 2) (1, 5)
        val case_2_2_A_B as () = test "abcdef" (1, 2) (3, 2) (1, 4)
        val case_2_2_A_C as () = test "abcdef" (1, 2) (2, 2) (1, 3)
        val case_2_2_B_D as () = test "abcdef" (1, 2) (1, 2) (1, 2)
        val case_2_2_C_E as () = test "abcdef" (2, 2) (1, 2) (2, 1)
        val case_2_2_D_E as () = test "abcdef" (3, 2) (1, 2) (3, 0)
        val case_2_2_E_E as () = testFail "abcdef" (3, 2) (0, 2)

        val case_3_1_A_A as () = test "abcdef" (1, 3) (5, 1) (1, 5)
        val case_3_1_A_B as () = test "abcdef" (1, 3) (4, 1) (1, 4)
        val case_3_1_A_C as () = test "abcdef" (1, 3) (3, 1) (1, 3)
        val case_3_1_A_E as () = test "abcdef" (1, 3) (2, 1) (1, 2)
        val case_3_1_B_E as () = test "abcdef" (1, 3) (1, 1) (1, 1)
        val case_3_1_D_E as () = test "abcdef" (2, 3) (1, 1) (2, 0)
        val case_3_1_E_E as () = testFail "abcdef" (2, 3) (0, 1)

        val case_3_2_A_A as () = test "abcdefg" (1, 3) (5, 2) (1, 6)
        val case_3_2_A_B as () = test "abcdefg" (1, 3) (4, 2) (1, 5)
        val case_3_2_A_C as () = test "abcdefg" (1, 3) (3, 2) (1, 4)
        val case_3_2_A_D as () = test "abcdefg" (1, 3) (2, 2) (1, 3)
        val case_3_2_B_E as () = test "abcdefg" (1, 3) (1, 2) (1, 2)
        val case_3_2_C_E as () = test "abcdefg" (2, 3) (1, 2) (2, 1)
        val case_3_2_D_E as () = test "abcdefg" (3, 3) (1, 2) (3, 0)
        val case_3_2_E_E as () = testFail "abcdefg" (3, 3) (0, 2)

        val case_3_3_A_A as () = test "abcdefgh" (1, 3) (5, 3) (1, 7)
        val case_3_3_A_B as () = test "abcdefgh" (1, 3) (4, 3) (1, 6)
        val case_3_3_A_Ca as () = test "abcdefgh" (1, 3) (3, 3) (1, 5)
        val case_3_3_A_Cb as () = test "abcdefgh" (1, 3) (2, 3) (1, 4)
        val case_3_3_B_D as () = test "abcdefgh" (1, 3) (1, 3) (1, 3)
        val case_3_3_C_Ea as () = test "abcdefgh" (2, 3) (1, 3) (2, 2)
        val case_3_3_C_Eb as () = test "abcdefgh" (3, 3) (1, 3) (3, 1)
        val case_3_3_D_E as () = test "abcdefgh" (4, 3) (1, 3) (4, 0)
        val case_3_3_E_E as () = testFail "abcdefgh" (4, 3) (0, 3)

        val case_2_3_A_A as () = test "abcdefg" (1, 2) (4, 3) (1, 6)
        val case_2_3_A_B as () = test "abcdefg" (1, 2) (3, 3) (1, 5)
        val case_2_3_A_C as () = test "abcdefg" (1, 2) (2, 3) (1, 4)
        val case_2_3_B_C as () = test "abcdefg" (1, 2) (1, 3) (1, 3)
        val case_2_3_C_D as () = test "abcdefg" (2, 2) (1, 3) (2, 2)
        val case_2_3_D_E as () = test "abcdefg" (3, 2) (1, 3) (3, 1)
        val case_2_3_E_E as () = testFail "abcdefg" (4, 2) (0, 3)
        (* le + 1 < rs *)
        val case_3_3_A_A_2 as () = test "abcdefghi" (1, 3) (5, 3) (1, 7)
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
          val () = assertEqualString expected r
          val () = assertEqualCharList visited (!s)
        in () end
  in
  fun translate0001 () =
      let
        val case0 as () = test abc_1_0 "" []
        val case1 as () = test abc_1_1 "bb" [#"b"]
        val case2 as () = test abcd_1_2 "bbcc" [#"b", #"c"]
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
          val () = assertEqualSubstringList (List.map SS.full expected) r
          val () = assertEqualCharList visited (!s)
        in () end
  in
  fun tokens0001 () =
      let
        val case_empty as () = test ("abc", 1, 0) [] []
        val case_00 as () = test ("a|b", 1, 1) [] [#"|"]
        val case_01 as () = test ("a|bc", 1, 2) ["b"] [#"|", #"b"]
        val case_10 as () = test ("ab|c", 1, 2) ["b"] [#"b", #"|"]
        val case_11 as () = test ("ab|cd", 1, 3) ["b", "c"] [#"b", #"|", #"c"]
        val case_000 as () = test ("a||b", 1, 2) [] [#"|", #"|"]
        val case_001 as () = test ("a||bc", 1, 3) ["b"] [#"|", #"|", #"b"]
        val case_010 as () = test ("a|b|c", 1, 3) ["b"] [#"|", #"b", #"|"]
        val case_011 as () = test ("a|b|cd", 1, 4) ["b", "c"] [#"|", #"b", #"|", #"c"]
        val case_100 as () = test ("ab||c", 1, 3) ["b"] [#"b", #"|", #"|"]
        val case_101 as () = test ("ab||cd", 1, 4) ["b", "c"] [#"b", #"|", #"|", #"c"]
        val case_110 as () = test ("ab|c|d", 1, 4) ["b", "c"] [#"b", #"|", #"c", #"|"]
        val case_111 as () = test ("ab|c|de", 1, 5) ["b", "c", "d"] [#"b", #"|", #"c", #"|", #"d"]
        val case_222 as () = test ("abc|de|fgh", 1, 8) ["bc", "de", "fg"] [#"b", #"c", #"|", #"d", #"e", #"|", #"f", #"g"]
      in () end
  end (* inner local *)

  (********************)

  local
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = SS.fields f (SS.substring arg)
          val () = assertEqualSubstringList (List.map SS.full expected) r
          val () = assertEqualCharList visited (!s)
        in () end
  in
  fun fields0001 () =
      let
        val case_empty as () = test ("abc", 1, 0) [""] []
        val case_00 as () = test ("a|b", 1, 1) ["", ""] [#"|"]
        val case_01 as () = test ("a|bc", 1, 2) ["", "b"] [#"|", #"b"]
        val case_10 as () = test ("ab|c", 1, 2) ["b", ""] [#"b", #"|"]
        val case_11 as () = test ("ab|cd", 1, 3) ["b", "c"] [#"b", #"|", #"c"]
        val case_000 as () = test ("a||b", 1, 2) ["", "", ""] [#"|", #"|"]
        val case_001 as () = test ("a||bc", 1, 3) ["", "", "b"] [#"|", #"|", #"b"]
        val case_010 as () = test ("a|b|c", 1, 3) ["", "b", ""] [#"|", #"b", #"|"]
        val case_011 as () = test ("a|b|cd", 1, 4) ["", "b", "c"] [#"|", #"b", #"|", #"c"]
        val case_100 as () = test ("ab||c", 1, 3) ["b", "", ""] [#"b", #"|", #"|"]
        val case_101 as () = test ("ab||cd", 1, 4) ["b", "", "c"] [#"b", #"|", #"|", #"c"]
        val case_110 as () = test ("ab|c|d", 1, 4) ["b", "c", ""] [#"b", #"|", #"c", #"|"]
        val case_111 as () = test ("ab|c|de", 1, 5) ["b", "c", "d"] [#"b", #"|", #"c", #"|", #"d"]
        val case_222 as () = test ("abc|de|fgh", 1, 8) ["bc", "de", "fg"] [#"b", #"c", #"|", #"d", #"e", #"|", #"f", #"g"]
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
          val () = assertEqualCharList visited (!r)
        in () end
  in
  fun app0001 () =
      let
        val case0 as () = test abc_1_0 []
        val case1 as () = test abc_1_1 [#"b"]
        val case2 as () = test abcd_1_2 [#"b", #"c"]
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
          val () = assertEqualCharList expected r
          val () = assertEqualCharList visited (!s)
        in () end
    val testl = test SS.foldl
    val testr = test SS.foldr
  in

  fun foldl0001 () =
      let
        val case_0 as () = testl [] abc_1_0 [] []
        val case_1 as () = testl [] abc_1_1 [#"b"] [#"b"]
        val case_2 as () = testl [] abcd_1_2 [#"c", #"b"] [#"b", #"c"]
        val case_3 as () = testl [] abcde_1_3 [#"d", #"c", #"b"] [#"b", #"c", #"d"]
      in () end

  (********************)

  fun foldr0001 () =
      let
        val case_0 as () = testr [] abc_1_0 [] []
        val case_1 as () = testr [] abc_1_1 [#"b"] [#"b"]
        val case_2 as () = testr [] abcd_1_2 [#"b", #"c"] [#"c", #"b"]
        val case_3 as () = testr [] abcde_1_3 [#"b", #"c", #"d"] [#"d", #"c", #"b"]
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