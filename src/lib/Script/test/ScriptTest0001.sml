structure ScriptTest0001 =
struct

  (***************************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test

  structure Testee = Script

  (***************************************************************************)

  (*
   * string argument does not include '\n' and '\r'.
   *)
  fun testChop0001 () =
      (
        A.assertEqualString "" (Testee.chop "");
        A.assertEqualString "" (Testee.chop "a");
        A.assertEqualString "a" (Testee.chop "ab");
        ()
      )

  (*
   * string argument includes '\n' or '\r'.
   *)
  fun testChop0002 () =
      (
        A.assertEqualString "" (Testee.chop "\n");
        A.assertEqualString "" (Testee.chop "\r");
        A.assertEqualString "\n" (Testee.chop "\n\r");
        A.assertEqualString "" (Testee.chop "\r\n");
        A.assertEqualString "a" (Testee.chop "a\n");
        A.assertEqualString "a" (Testee.chop "a\r");
        A.assertEqualString "a\n" (Testee.chop "a\n\r");
        A.assertEqualString "a" (Testee.chop "a\r\n");
        ()
      )

  fun testItoa0001 () =
      (
        A.assertEqualString "0" (Testee.itoa 0);
        A.assertEqualString "1" (Testee.itoa 1);
        A.assertEqualString "~1" (Testee.itoa ~1);
        A.assertEqualString "123" (Testee.itoa 123);
        A.assertEqualString "~123" (Testee.itoa ~123);
        ()
      )

  (*
   * valid numeral text, without trailer
   *)
  fun testAtoi0001 () =
      (
        A.assertEqualInt 0 (Testee.atoi "0");
        A.assertEqualInt 0 (Testee.atoi "000");
        A.assertEqualInt 1 (Testee.atoi "1");
        A.assertEqualInt 1 (Testee.atoi "01");
        A.assertEqualInt ~1 (Testee.atoi "~1");
        A.assertEqualInt ~1 (Testee.atoi "-1");
        A.assertEqualInt 123 (Testee.atoi "123");
        A.assertEqualInt 123 (Testee.atoi "0123");
        A.assertEqualInt ~123 (Testee.atoi "~123");
        A.assertEqualInt ~123 (Testee.atoi "-123");
        ()
      )

  (*
   * valid numeral text, with trailer
   *)
  fun testAtoi0002 () =
      (
        A.assertEqualInt 0 (Testee.atoi "0abc");
        A.assertEqualInt 1 (Testee.atoi "1abc");
        A.assertEqualInt 123 (Testee.atoi "123abc");
        A.assertEqualInt ~123 (Testee.atoi "~123abc");
        A.assertEqualInt ~123 (Testee.atoi "-123abc");
        ()
      )

  (*
   * invalid numeral text
   *)
  fun testAtoi0003 () =
      (
        A.assertEqualInt 0 (Testee.atoi "abc");
        ()
      )

  (*
   * pattern does not include meta character.
   *)
  fun testReEqual0001 () =
      (
        A.assertTrue (Testee.=~ ("a", "a"));
        A.assertTrue (Testee.=~ ("ab", "ab"));
        A.assertTrue (Testee.=~ ("abc", "ab"));
        A.assertTrue (Testee.=~ ("xabc", "ab"));

        A.assertFalse (Testee.=~ ("", "a"));
        A.assertFalse (Testee.=~ ("b", "a"));
        A.assertFalse (Testee.=~ ("a", "ab"));

        ()
      )

  (*
   * pattern include atomic pattern.
   * ^, $, .
   *)
  fun testReEqual0002 () =
      (
        A.assertTrue (Testee.=~ ("", "^"));
        A.assertTrue (Testee.=~ ("a", "^"));

        A.assertFalse (Testee.=~ ("", "^a"));
        A.assertTrue (Testee.=~ ("a", "^a"));
        A.assertTrue (Testee.=~ ("ab", "^a"));
        A.assertFalse (Testee.=~ ("ba", "^a"));

        A.assertTrue (Testee.=~ ("", "$"));
        A.assertTrue (Testee.=~ ("a", "$"));

        A.assertFalse (Testee.=~ ("", "a$"));
        A.assertTrue (Testee.=~ ("a", "a$"));
        A.assertTrue (Testee.=~ ("ba", "a$"));
        A.assertFalse (Testee.=~ ("ab", "a$"));

        A.assertTrue (Testee.=~ ("", "^$"));
        A.assertFalse (Testee.=~ ("a", "^$"));
        A.assertTrue (Testee.=~ ("a", "^a$"));
        A.assertFalse (Testee.=~ ("b", "^a$"));
        A.assertFalse (Testee.=~ ("ab", "^a$"));

        A.assertFalse (Testee.=~ ("", "."));
        A.assertTrue (Testee.=~ ("a", "."));
        A.assertTrue (Testee.=~ ("ab", "."));
        A.assertFalse (Testee.=~ ("a", ".."));
        A.assertTrue (Testee.=~ ("ab", ".."));

        ()
      )

  (*
   * pattern include '|'
   * 
   *)
  fun testReEqual0003 () =
      (
(*
        (* not implemented *)
        A.assertTrue (Testee.=~ ("", "|"));
        A.assertTrue (Testee.=~ ("a", "|"));
*)

        A.assertTrue (Testee.=~ ("", "|a"));
        A.assertTrue (Testee.=~ ("a", "|a"));
        A.assertTrue (Testee.=~ ("b", "|a"));
(*
        (* not implemented *)
        A.assertTrue (Testee.=~ ("", "a|"));
        A.assertTrue (Testee.=~ ("a", "a|"));
        A.assertTrue (Testee.=~ ("b", "a|"));
*)
        A.assertTrue (Testee.=~ ("a", "a|b"));
        A.assertTrue (Testee.=~ ("b", "a|b"));
        A.assertFalse (Testee.=~ ("c", "a|b"));

        A.assertTrue (Testee.=~ ("aa", "aa|bb"));
        A.assertTrue (Testee.=~ ("bb", "aa|bb"));
        A.assertFalse (Testee.=~ ("a", "aa|bb"));
        A.assertFalse (Testee.=~ ("b", "aa|bb"));

        ()
      )

  (*
   * pattern include '?'
   *)
  fun testReEqual0004 () =
      (
        A.assertTrue (Testee.=~ ("", "a?"));
        A.assertTrue (Testee.=~ ("a", "a?"));
        A.assertTrue (Testee.=~ ("b", "a?"));

        ()
      )

  (*
   * pattern include '*'
   *)
  fun testReEqual0005 () =
      (
        A.assertTrue (Testee.=~ ("", "a*"));
        A.assertTrue (Testee.=~ ("a", "a*"));
        A.assertTrue (Testee.=~ ("b", "a*"));
        A.assertTrue (Testee.=~ ("aa", "a*"));

        ()
      )

  (*
   * pattern include '+'
   *)
  fun testReEqual0006 () =
      (
        A.assertFalse (Testee.=~ ("", "a+"));
        A.assertTrue (Testee.=~ ("a", "a+"));
        A.assertFalse (Testee.=~ ("b", "a+"));
        A.assertTrue (Testee.=~ ("aa", "a+"));
        A.assertTrue (Testee.=~ ("bab", "a+"));

        ()
      )

  (*
   * pattern include '()'
   *)
  fun testReEqual0007 () =
      (
        A.assertTrue (Testee.=~ ("", "()"));
        A.assertTrue (Testee.=~ ("a", "(a)"));
        A.assertTrue (Testee.=~ ("ab", "(ab)"));

        (* combination with | *)
        (* | is inside of () *)
(*
        A.assertTrue (Testee.=~ ("", "(|)"));
*)
        A.assertTrue (Testee.=~ ("aab", "a(a|b)b"));
        A.assertTrue (Testee.=~ ("abb", "a(a|b)b"));
        A.assertFalse (Testee.=~ ("ab", "a(a|b)b"));
        (* | is outside of () *)
        A.assertTrue (Testee.=~ ("aabb", "a((ab)|(ba))b"));
        A.assertTrue (Testee.=~ ("abab", "a((ab)|(ba))b"));
        A.assertFalse (Testee.=~ ("aab", "a((ab)|(ba))b"));
        A.assertFalse (Testee.=~ ("aaab", "a((ab)|(ba))b"));

        (* combination with ? *)
        (* ? is inside of () *)
        A.assertTrue (Testee.=~ ("", "(a?)"));
        A.assertTrue (Testee.=~ ("a", "(a?)"));
        A.assertTrue (Testee.=~ ("a", "(ab?)"));
        A.assertTrue (Testee.=~ ("", "(a?b?)"));
        A.assertTrue (Testee.=~ ("b", "(a?b?)"));
        A.assertTrue (Testee.=~ ("ab", "(a?b?)"));
        (* ? is outside of () *)
        A.assertTrue (Testee.=~ ("", "(ab)?"));
        A.assertTrue (Testee.=~ ("a", "(ab)?"));
        A.assertTrue (Testee.=~ ("b", "(ab)?"));
        A.assertTrue (Testee.=~ ("a", "(ab)?"));
        A.assertTrue (Testee.=~ ("ab", "(ab)?"));
        A.assertTrue (Testee.=~ ("ab", "a(ab)?b"));
        A.assertTrue (Testee.=~ ("aab", "a(ab)?b"));
        A.assertTrue (Testee.=~ ("aabb", "a(ab)?b"));
        A.assertFalse (Testee.=~ ("aaa", "a(ab)?b"));

        (* combination with * *)
        (* * is outside of () *)
        A.assertTrue (Testee.=~ ("", "(ab)*"));
        A.assertTrue (Testee.=~ ("a", "(ab)*"));
        A.assertTrue (Testee.=~ ("b", "(ab)*"));
        A.assertTrue (Testee.=~ ("ab", "(ab)*"));
        A.assertTrue (Testee.=~ ("ba", "(ab)*"));
        A.assertTrue (Testee.=~ ("abab", "(ab)*"));
        (* * is inside of () *)
        A.assertTrue (Testee.=~ ("abab", "(ab*)"));

        (* combination with + *)
        (* + is outside of () *)
        A.assertFalse (Testee.=~ ("", "(ab)+"));
        A.assertFalse (Testee.=~ ("a", "(ab)+"));
        A.assertFalse (Testee.=~ ("b", "(ab)+"));
        A.assertTrue (Testee.=~ ("ab", "(ab)+"));
        A.assertFalse (Testee.=~ ("ba", "(ab)+"));
        A.assertTrue (Testee.=~ ("abab", "(ab)+"));
        (* + is inside of () *)
        A.assertTrue (Testee.=~ ("ab", "(ab+)"));
        A.assertTrue (Testee.=~ ("aba", "(ab+)"));
        A.assertTrue (Testee.=~ ("abab", "(ab+)"));

        ()
      )

  val assertEqualInt2TupleOption = 
      A.assertEqualOption
          (A.assertEqual2Tuple (A.assertEqualInt, A.assertEqualInt))

  fun testFind0001 () =
      (
        (* pattern length = 1 *)
        assertEqualInt2TupleOption NONE (Testee.find "a" "");
(*
        assertEqualInt2TupleOption (SOME(0, 0)) (Testee.find "" "a?");
*)
        assertEqualInt2TupleOption (SOME(0, 1)) (Testee.find "a" "a");
        assertEqualInt2TupleOption (SOME(0, 1)) (Testee.find "a" "aa");

        assertEqualInt2TupleOption (SOME(1, 1)) (Testee.find "a" "xax");
        assertEqualInt2TupleOption (SOME(1, 1)) (Testee.find "a" "xa");

        (* pattern length = 2 *)
        assertEqualInt2TupleOption NONE (Testee.find "aa" "xa");
        assertEqualInt2TupleOption (SOME(1, 2)) (Testee.find "aa" "xaa");
        assertEqualInt2TupleOption (SOME(1, 2)) (Testee.find "aa" "xaax");

        ()
      )

  val assertEqualInt2TupleList = 
      A.assertEqualList
          (A.assertEqual2Tuple (A.assertEqualInt, A.assertEqualInt))

  fun testGlobal_Find0001 () =
      (
        (* pattern length = 1 *)
        assertEqualInt2TupleList [] (Testee.global_find "a" "");
(*
        assertEqualInt2TupleList [(0, 0)] (Testee.global_find "" "a?");
*)
        assertEqualInt2TupleList [(0, 1)] (Testee.global_find "a" "a");
        assertEqualInt2TupleList
            [(0, 1), (1, 1)] (Testee.global_find "a" "aa");

        assertEqualInt2TupleList [(1, 1)] (Testee.global_find "a" "xax");
        assertEqualInt2TupleList [(1, 1)] (Testee.global_find "a" "xa");

        (* pattern length = 2 *)
        assertEqualInt2TupleList [] (Testee.global_find "aa" "xa");
        assertEqualInt2TupleList [(1, 2)] (Testee.global_find "aa" "xaa");
        assertEqualInt2TupleList [(0, 2)] (Testee.global_find "aa" "aaa");
        assertEqualInt2TupleList [(1, 2)] (Testee.global_find "aa" "xaax");
        assertEqualInt2TupleList
            [(0, 2), (2, 2)] (Testee.global_find "aa" "aaaa");

        ()
      )

  val assertEqualInt2TupleOptionListOption = 
      A.assertEqualOption
          (A.assertEqualList
               (A.assertEqualOption
                    (A.assertEqual2Tuple
                         (A.assertEqualInt, A.assertEqualInt))))

  local
    val assertResult = assertEqualInt2TupleOptionListOption
  in
  fun testFind_Group0001 () =
      (
        (* 0 group *)
        assertResult NONE (Testee.find_group "a" "");
        assertResult (SOME[SOME(0, 1)]) (Testee.find_group "a" "a");
        assertResult (SOME[SOME(0, 1)]) (Testee.find_group "a" "aa");

        (* 1 group *)
        assertResult
            (SOME[SOME(0, 1), SOME(0, 1)]) (Testee.find_group "(a)" "a");
        assertResult
            (SOME[SOME(0, 3), SOME(1, 1)]) (Testee.find_group "a(a)a" "aaaa");
        assertResult
            (SOME[SOME(0, 1), SOME(1, 0)]) (Testee.find_group "a(b?)" "aa");
        assertResult
            (SOME[SOME(0, 1)]) (Testee.find_group "a|(b)" "aa");

        (* 2 groups *)
        assertResult
            (SOME[SOME(0, 2), SOME(0, 1), SOME(1, 1)])
            (Testee.find_group "(a)(b)" "ab");
        assertResult
            (SOME[SOME(0, 2), SOME(1, 0), SOME(1, 0)])
            (Testee.find_group "x(a?)(b?)y" "xy");

        (* nested 2 groups *)
        assertResult
            (SOME[SOME(0, 2), SOME(0, 2), SOME(0, 2)])
            (Testee.find_group "((ab))" "ab");
        assertResult
            (SOME[SOME(1, 3), SOME(1, 3), SOME(2, 1)])
            (Testee.find_group "(a(b)c)" "xabcy");

        assertResult
            (SOME[SOME(1, 6), SOME(1, 3), SOME(2, 1), SOME(5, 1)])
            (Testee.find_group "(a(b)c)d(e)f" "xabcdefy");
        ()
      )
  end

  val assertEqualInt2TupleOptionListList = 
      A.assertEqualList
          (A.assertEqualList
               (A.assertEqualOption
                    (A.assertEqual2Tuple
                         (A.assertEqualInt, A.assertEqualInt))))

  local
    val assertResult = assertEqualInt2TupleOptionListList
  in
  fun testGlobal_Find_Group0001 () =
      (
        (* no match *)
        assertResult [] (Testee.global_find_group "a" "");
        assertResult [] (Testee.global_find_group "a" "xy");

        assertResult [[SOME(0, 1)]] (Testee.global_find_group "a" "ax");

        assertResult
            [[SOME(0, 1)], [SOME(2, 1)]] (Testee.global_find_group "a" "axa");

        assertResult
            [[SOME(0, 2), SOME(1, 1)], [SOME(3, 2), SOME(4, 1)]]
            (Testee.global_find_group "a(b)" "abxab");

        assertResult
            [[SOME(0, 5), SOME(1, 4)]]
            (Testee.global_find_group "a(ba)*" "ababa");

        ()
      )
  end

  fun testSubst0001 () =
      (
        A.assertEqualString "" (Testee.subst "a" "x" "");

        A.assertEqualString "x" (Testee.subst "a" "x" "a");
        A.assertEqualString "" (Testee.subst "a" "" "a");

        A.assertEqualString "xa" (Testee.subst "a" "x" "aa");
        A.assertEqualString "xb" (Testee.subst "a" "x" "ab");
        A.assertEqualString "bx" (Testee.subst "a" "x" "ba");
        A.assertEqualString "xba" (Testee.subst "a" "x" "aba");
        A.assertEqualString "ba" (Testee.subst "a" "" "aba");

        A.assertEqualString "x" (Testee.subst "aa" "x" "aa");
        A.assertEqualString "xa" (Testee.subst "aa" "x" "aaa");
        ()
      )

  fun testGlobal_Subst0001 () =
      (
        A.assertEqualString "" (Testee.global_subst "a" "x" "");

        A.assertEqualString "x" (Testee.global_subst "a" "x" "a");
        A.assertEqualString "" (Testee.global_subst "a" "" "a");

        A.assertEqualString "xx" (Testee.global_subst "a" "x" "aa");
        A.assertEqualString "xb" (Testee.global_subst "a" "x" "ab");
        A.assertEqualString "bx" (Testee.global_subst "a" "x" "ba");
        A.assertEqualString "xbx" (Testee.global_subst "a" "x" "aba");
        A.assertEqualString "b" (Testee.global_subst "a" "" "aba");

        A.assertEqualString "x" (Testee.global_subst "aa" "x" "aa");
        A.assertEqualString "xa" (Testee.global_subst "aa" "x" "aaa");
        ()
      )

  fun testFields0001 () =
      (
        (* separator is 1 character. *)
        A.assertEqualStringList [""] (Testee.fields "," "");
        A.assertEqualStringList ["a"] (Testee.fields "," "a");
        A.assertEqualStringList ["a", "b"] (Testee.fields "," "a,b");
        A.assertEqualStringList
            ["", "ab", "", "xy", ""] (Testee.fields "," ",ab,,xy,");

        (* separator is more than 1 character. *)
        A.assertEqualStringList
            ["a", "b", "c"] (Testee.fields "@@" "a@@b@@c");
        A.assertEqualStringList
            ["", "a", "@b", "", "c", ""] (Testee.fields "@@" "@@a@@@b@@@@c@@");
        ()
      )

  fun testTokens0001 () =
      (
        (* separator is 1 character. *)
        A.assertEqualStringList [] (Testee.tokens "," "");
        A.assertEqualStringList ["a"] (Testee.tokens "," "a");
        A.assertEqualStringList ["a", "b"] (Testee.tokens "," "a,b");
        A.assertEqualStringList
            ["ab", "xy"] (Testee.tokens "," ",ab,,xy,");

        (* separator is more than 1 character. *)
        A.assertEqualStringList
            ["a", "b", "c"] (Testee.tokens "@@" "a@@b@@c");
        A.assertEqualStringList
            ["a", "@b", "c"] (Testee.tokens "@@" "@@a@@@b@@@@c@@");
        ()
      )

  (***************************************************************************)

  fun suite () =
      T.labelTests
          [
            ("testChop0001", testChop0001),
            ("testChop0002", testChop0002),
            ("testItoa0001", testItoa0001),
            ("testAtoi0001", testAtoi0001),
            ("testAtoi0002", testAtoi0002),
            ("testAtoi0003", testAtoi0003),
            ("testReEqual0001", testReEqual0001),
            ("testReEqual0002", testReEqual0002),
            ("testReEqual0003", testReEqual0003),
            ("testReEqual0004", testReEqual0004),
            ("testReEqual0005", testReEqual0005),
            ("testReEqual0006", testReEqual0006),
            ("testReEqual0007", testReEqual0007),
            ("testFind0001", testFind0001),
            ("testGlobal_Find0001", testGlobal_Find0001),
            ("testFind_Group0001", testFind_Group0001),
            ("testGlobal_Find_Group0001", testGlobal_Find_Group0001),
            ("testSubst0001", testSubst0001),
            ("testGlobal_Subst0001", testGlobal_Subst0001),
            ("testFields0001", testFields0001),
            ("testTokens0001", testTokens0001)
          ]

  (***************************************************************************)

end