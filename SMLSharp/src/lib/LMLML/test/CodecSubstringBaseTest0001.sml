(**
 * Test cases for multibyte substring.
 * Test cases in this module are codec independent.
 * @author YAMATODANI Kiyoshi
 * @version $Id: CodecSubstringBaseTest0001.sml,v 1.1.2.1 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
functor CodecSubstringBaseTest0001(Codec : CODEC) =
struct

  (***************************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test

  structure MBC = Codec.Char
  structure MBS = Codec.String
  structure MBSS = Codec.Substring

  structure TestUtil = LMLMLTestUtil(Codec)
  open TestUtil.Assert
  open TestUtil

  (***************************************************************************)

  fun testSub0001() =
      (
        (MBSS.sub (SS "", 0) ; A.fail "sub") handle Subscript => ();

        (MBSS.sub (SS "a", ~1); A.fail "sub") handle Subscript => ();
        assertEqualMBC (C #"a") (MBSS.sub (SS "a", 0));
        (MBSS.sub (SS "a", 1); A.fail "sub") handle Subscript => ();

        (MBSS.sub (SS "ab", ~1); A.fail "sub") handle Subscript => ();
        assertEqualMBC (C #"a") (MBSS.sub (SS "ab", 0));
        assertEqualMBC (C #"b") (MBSS.sub (SS "ab", 1));
        (MBSS.sub (SS "ab", 2); A.fail "sub") handle Subscript => ();

        ()
      )

  fun testSize0001() =
      (
        assertEqualInt 0 (MBSS.size (SS ""));
        assertEqualInt 1 (MBSS.size (SS "a"));
        assertEqualInt 2 (MBSS.size (SS "ab"));
        ()
      )

  local
    val assertEqualBase =
        assertEqual3Tuple (assertEqualMBS, assertEqualInt, assertEqualInt)
    fun assertBase base =
        assertEqualBase base (MBSS.base (MBSS.substring base))
  in
  fun testBase0001() =
      (
        assertBase (S "", 0, 0);
        assertBase (S "a", 0, 1);
        assertBase (S "abc", 0, 1);
        assertBase (S "abc", 1, 1);
        assertBase (S "abc", 2, 1);
        assertBase (S "abc", 0, 2);
        assertBase (S "abc", 1, 2);
        assertBase (S "abc", 0, 3);
        ()
      )
  end

  fun testExtract0001 () =
      (
        assertEqualMBSS (SS "") (MBSS.extract (S "", 0, NONE));
        assertEqualMBSS (SS "") (MBSS.extract (S "", 0, SOME 0));
        assertEqualMBSS (SS "a") (MBSS.extract (S "a", 0, NONE));
        assertEqualMBSS (SS "") (MBSS.extract (S "a", 0, SOME 0));
        assertEqualMBSS (SS "a") (MBSS.extract (S "a", 0, SOME 1));
        assertEqualMBSS (SS "") (MBSS.extract (S "a", 1, NONE));
        assertEqualMBSS (SS "") (MBSS.extract (S "a", 1, SOME 0));
        assertEqualMBSS (SS "ab") (MBSS.extract (S "ab", 0, NONE));
        assertEqualMBSS (SS "") (MBSS.extract (S "ab", 0, SOME 0));
        assertEqualMBSS (SS "a") (MBSS.extract (S "ab", 0, SOME 1));
        assertEqualMBSS (SS "ab") (MBSS.extract (S "ab", 0, SOME 2));
        assertEqualMBSS (SS "b") (MBSS.extract (S "ab", 1, NONE));
        assertEqualMBSS (SS "") (MBSS.extract (S "ab", 1, SOME 0));
        assertEqualMBSS (SS "b") (MBSS.extract (S "ab", 1, SOME 1));
        assertEqualMBSS (SS "") (MBSS.extract (S "ab", 2, NONE));
        assertEqualMBSS (SS "") (MBSS.extract (S "ab", 2, SOME 0));

        (* error cases *)
        (MBSS.extract(S "ab", ~1, NONE); fail "extract")
        handle Subscript => ();
        (MBSS.extract(S "ab", 3, NONE); fail "extract")
        handle Subscript => ();
        (MBSS.extract(S "ab", ~1, SOME 0); fail "extract")
        handle Subscript => ();
        (MBSS.extract(S "ab", ~1, SOME ~1); fail "extract")
        handle Subscript => ();
        (MBSS.extract(S "ab", 1, SOME 2); fail "extract")
        handle Subscript => ();

        ()
      )

  fun testSubstring0001 () =
      (
        assertEqualMBSS (SS "") (MBSS.substring(S "", 0, 0));
        assertEqualMBSS (SS "") (MBSS.substring(S "a", 0, 0));
        assertEqualMBSS (SS "a") (MBSS.substring(S "a", 0, 1));
        assertEqualMBSS (SS "") (MBSS.substring(S "a", 1, 0));
        assertEqualMBSS (SS "") (MBSS.substring(S "ab", 0, 0));
        assertEqualMBSS (SS "a") (MBSS.substring(S "ab", 0, 1));
        assertEqualMBSS (SS "ab") (MBSS.substring(S "ab", 0, 2));
        assertEqualMBSS (SS "") (MBSS.substring(S "ab", 1, 0));
        assertEqualMBSS (SS "b") (MBSS.substring(S "ab", 1, 1));
        assertEqualMBSS (SS "") (MBSS.substring(S "ab", 2, 0));

        (* error cases *)
        (MBSS.substring(S "ab", ~1, 0); fail "subtring")
        handle Subscript => ();
        (MBSS.substring(S "ab", ~1, ~1); fail "subtring")
        handle Subscript => ();
        (MBSS.substring(S "ab", 1, 2); fail "subtring")
        handle Subscript => ();

        ()
      )

  fun testFull0001 () =
      (
        assertEqualMBSS (SS "") (MBSS.full (S ""));
        assertEqualMBSS (SS "a") (MBSS.full (S "a"));
        assertEqualMBSS (SS "ab") (MBSS.full (S "ab"));
        ()
      )

  local
    fun assertString string =
        assertEqualMBS (S string) (MBSS.string (MBSS.full (S string)))
  in
  fun testString0001 () =
      (
        assertString "";
        assertString "a";
        assertString "abc";
        ()
      )
  end

  fun testIsEmpty0001 () =
      (
        assertTrue (MBSS.isEmpty (SS ""));
        assertFalse (MBSS.isEmpty (SS "a"));
        ()
      )

  local
    val assertGetc =
        assertEqualOption (assertEqual2Tuple (assertEqualMBC, assertEqualMBSS))
  in
  fun testGetc0001 () =
      (
         assertGetc NONE (MBSS.getc (SS ""));
         assertGetc (SOME (C #"a", SS "")) (MBSS.getc (SS "a"));
         assertGetc (SOME (C #"a", SS "b")) (MBSS.getc (SS "ab"));
        ()
      )
  end

  local
    val assertFirst = assertEqualOption assertEqualMBC
  in
  fun testFirst0001 () =
      (
         assertFirst NONE (MBSS.first (SS ""));
         assertFirst (SOME (C #"a")) (MBSS.first (SS "a"));
         assertFirst (SOME (C #"a")) (MBSS.first (SS "ab"));
        ()
      )
  end

  fun testTriml0001 () =
      (
        assertEqualMBSS (SS "") (MBSS.triml 0 (MBSS.full (S "")));
        assertEqualMBSS (SS "") (MBSS.triml 1 (MBSS.full (S "")));(* safe *)
        assertEqualMBSS
            (SS "b") (MBSS.triml 0 (MBSS.substring(S "abc", 1, 1)));
        assertEqualMBSS (SS "") (MBSS.triml 1 (MBSS.substring(S "abc", 1, 1)));
        assertEqualMBSS (SS "") (MBSS.triml 2 (MBSS.substring(S "abc", 1, 1)));
        assertEqualMBSS
            (SS "bc") (MBSS.triml 0 (MBSS.substring(S "abcd", 1, 2)));
        assertEqualMBSS
            (SS "c") (MBSS.triml 1 (MBSS.substring(S "abcd", 1, 2)));
        assertEqualMBSS
            (SS "") (MBSS.triml 2 (MBSS.substring(S "abcd", 1, 2)));
        assertEqualMBSS
            (SS "") (MBSS.triml 3 (MBSS.substring(S "abcd", 1, 2)));
        (* error case *)
        (MBSS.triml ~1; fail "triml") handle Subscript => ();
        ()
      )

  fun testTrimr0001 () =
      (
        assertEqualMBSS (SS "") (MBSS.trimr 0 (MBSS.full (S "")));
        assertEqualMBSS (SS "") (MBSS.trimr 1 (MBSS.full (S "")));(* safe *)
        assertEqualMBSS
            (SS "b") (MBSS.trimr 0 (MBSS.substring(S "abc", 1, 1)));
        assertEqualMBSS (SS "") (MBSS.trimr 1 (MBSS.substring(S "abc", 1, 1)));
        assertEqualMBSS (SS "") (MBSS.trimr 2 (MBSS.substring(S "abc", 1, 1)));
        assertEqualMBSS
            (SS "bc") (MBSS.trimr 0 (MBSS.substring(S "abcd", 1, 2)));
        assertEqualMBSS
            (SS "b") (MBSS.trimr 1 (MBSS.substring(S "abcd", 1, 2)));
        assertEqualMBSS
            (SS "") (MBSS.trimr 2 (MBSS.substring(S "abcd", 1, 2)));
        assertEqualMBSS
            (SS "") (MBSS.trimr 3 (MBSS.substring(S "abcd", 1, 2)));
        (* error case *)
        (MBSS.trimr ~1; fail "trimr") handle Subscript => ();
        ()
      )

  fun testSlice0001 () =
      (
        assertEqualMBSS (SS "") (MBSS.slice (SS "", 0, NONE));
        assertEqualMBSS (SS "") (MBSS.slice (SS "", 0, SOME 0));
        assertEqualMBSS (SS "a") (MBSS.slice (SS "a", 0, NONE));
        assertEqualMBSS (SS "") (MBSS.slice (SS "a", 0, SOME 0));
        assertEqualMBSS (SS "a") (MBSS.slice (SS "a", 0, SOME 1));
        assertEqualMBSS (SS "") (MBSS.slice (SS "a", 1, NONE));
        assertEqualMBSS (SS "") (MBSS.slice (SS "a", 1, SOME 0));
        assertEqualMBSS (SS "ab") (MBSS.slice (SS "ab", 0, NONE));
        assertEqualMBSS (SS "") (MBSS.slice (SS "ab", 0, SOME 0));
        assertEqualMBSS (SS "a") (MBSS.slice (SS "ab", 0, SOME 1));
        assertEqualMBSS (SS "ab") (MBSS.slice (SS "ab", 0, SOME 2));
        assertEqualMBSS (SS "b") (MBSS.slice (SS "ab", 1, NONE));
        assertEqualMBSS (SS "") (MBSS.slice (SS "ab", 1, SOME 0));
        assertEqualMBSS (SS "b") (MBSS.slice (SS "ab", 1, SOME 1));
        assertEqualMBSS (SS "") (MBSS.slice (SS "ab", 2, NONE));
        assertEqualMBSS (SS "") (MBSS.slice (SS "ab", 2, SOME 0));

        (* error cases *)
        (MBSS.slice(SS "ab", ~1, NONE); fail "slice")
        handle Subscript => ();
        (MBSS.slice(SS "ab", 3, NONE); fail "slice")
        handle Subscript => ();
        (MBSS.slice(SS "ab", ~1, SOME 0); fail "slice")
        handle Subscript => ();
        (MBSS.slice(SS "ab", ~1, SOME ~1); fail "slice")
        handle Subscript => ();
        (MBSS.slice(SS "ab", 1, SOME 2); fail "slice")
        handle Subscript => ();

        ()
      )

  local
    fun assert result strings =
        assertEqualMBS
            (S result)
            (MBSS.concat (List.map (MBSS.full o MBS.fromAsciiString) strings))
  in
  fun testConcat0001 () =
      (
        assert "" [];
        assert "a" ["a"];
        assert "ab" ["a", "b"];
        assert "abc" ["a", "b", "c"];
        ()
      )
  end

  local
    fun assert result separator strings =
        assertEqualMBS
            (S result)
            (MBSS.concatWith
                 (S separator)
                 (List.map (MBSS.full o MBS.fromAsciiString) strings))
  in
  fun testConcatWith0001 () =
      (
        assert "" "$" [];
        assert "a" "$" ["a"];
        assert "a$b" "$" ["a", "b"];
        assert "a$b$c" "$" ["a", "b", "c"];
        ()
      )
  end

  fun testExplode0001 () =
      (
        assertEqualMBCList [] (MBSS.explode(SS ""));
        assertEqualMBCList [C #"a"] (MBSS.explode(SS "a"));
        assertEqualMBCList [C #"a", C #"b"] (MBSS.explode(SS "ab"));
        assertEqualMBCList [C #"a", C #"b", C #"c"] (MBSS.explode(SS "abc"));
        ()
      )

  fun testIsPrefix0001 () =
      (
        assertTrue (MBSS.isPrefix (S "") (SS ""));
        assertFalse (MBSS.isPrefix (S "a") (SS ""));
        assertTrue (MBSS.isPrefix (S "") (SS "b"));
        assertTrue (MBSS.isPrefix (S "b") (SS "b"));
        assertFalse (MBSS.isPrefix (S "a") (SS "b"));
        assertTrue (MBSS.isPrefix (S "b") (SS "bc"));
        assertFalse (MBSS.isPrefix (S "a") (SS "bc"));
        assertTrue (MBSS.isPrefix (S "bc") (SS "bc"));
        assertFalse (MBSS.isPrefix (S "bd") (SS "bc"));
        assertTrue (MBSS.isPrefix (S "bc") (SS "bcd"));
        assertFalse (MBSS.isPrefix (S "bd") (SS "bcd"));
        assertTrue (MBSS.isPrefix (S "bcd") (SS "bcd"));
        assertFalse (MBSS.isPrefix (S "ccd") (SS "bcd"));
        ()
      )

  fun testIsSuffix0001 () =
      (
        assertTrue (MBSS.isSuffix (S "") (SS ""));
        assertFalse (MBSS.isSuffix (S "a") (SS ""));
        assertTrue (MBSS.isSuffix (S "") (SS "b"));
        assertTrue (MBSS.isSuffix (S "b") (SS "b"));
        assertFalse (MBSS.isSuffix (S "a") (SS "b"));
        assertTrue (MBSS.isSuffix (S "c") (SS "bc"));
        assertFalse (MBSS.isSuffix (S "a") (SS "bc"));
        assertTrue (MBSS.isSuffix (S "bc") (SS "bc"));
        assertFalse (MBSS.isSuffix (S "bd") (SS "bc"));
        assertTrue (MBSS.isSuffix (S "cd") (SS "bcd"));
        assertFalse (MBSS.isSuffix (S "bd") (SS "bcd"));
        assertTrue (MBSS.isSuffix (S "bcd") (SS "bcd"));
        assertFalse (MBSS.isSuffix (S "ccd") (SS "bcd"));
        ()
      )

  fun tessIsSubstring0001 () =
      (
        assertTrue (MBSS.isSubstring (S "") (SS ""));
        assertFalse (MBSS.isSubstring (S "a") (SS ""));
        assertTrue (MBSS.isSubstring (S "") (SS "b"));
        assertTrue (MBSS.isSubstring (S "b") (SS "b"));
        assertFalse (MBSS.isSubstring (S "a") (SS "b"));
        assertTrue (MBSS.isSubstring (S "c") (SS "bc"));
        assertTrue (MBSS.isSubstring (S "b") (SS "bc"));
        assertFalse (MBSS.isSubstring (S "a") (SS "bc"));
        assertTrue (MBSS.isSubstring (S "bc") (SS "bc"));
        assertFalse (MBSS.isSubstring (S "bd") (SS "bc"));
        assertTrue (MBSS.isSubstring (S "bc") (SS "bcd"));
        assertTrue (MBSS.isSubstring (S "cd") (SS "bcd"));
        assertFalse (MBSS.isSubstring (S "bd") (SS "bcd"));
        assertTrue (MBSS.isSubstring (S "bcd") (SS "bcd"));
        assertFalse (MBSS.isSubstring (S "ccd") (SS "bcd"));
        ()
      )

  fun testCompare0001 () =
      (
        assertEqualOrder EQUAL (MBSS.compare (SS "", SS ""));
        assertEqualOrder LESS (MBSS.compare (SS "", SS "y"));
        assertEqualOrder GREATER (MBSS.compare (SS "b", SS ""));
        assertEqualOrder LESS (MBSS.compare (SS "b", SS "y"));
        assertEqualOrder EQUAL (MBSS.compare (SS "b", SS "b"));
        assertEqualOrder GREATER (MBSS.compare (SS "y", SS "b"));
        assertEqualOrder LESS (MBSS.compare (SS "b", SS "yz"));
        assertEqualOrder LESS (MBSS.compare (SS "y", SS "yc"));
        assertEqualOrder LESS (MBSS.compare (SS "bc", SS "y"));
        assertEqualOrder GREATER (MBSS.compare (SS "bz", SS "b"));
        assertEqualOrder LESS (MBSS.compare (SS "bc", SS "yz"));
        assertEqualOrder EQUAL (MBSS.compare (SS "bc", SS "bc"));
        assertEqualOrder GREATER (MBSS.compare (SS "yz", SS "bc"));
        ()
      )

  fun collateFun (left, right) =
      case MBC.compare (left, right)
       of LESS => General.GREATER
        | EQUAL => General.EQUAL
        | _ =>  General.LESS;

  fun testCollate0001 () =
      (
        assertEqualOrder EQUAL (MBSS.collate collateFun (SS "", SS ""));
        assertEqualOrder LESS (MBSS.collate collateFun (SS "", SS "y"));
        assertEqualOrder GREATER (MBSS.collate collateFun (SS "b", SS ""));
        assertEqualOrder GREATER (MBSS.collate collateFun (SS "b", SS "y"));
        assertEqualOrder EQUAL (MBSS.collate collateFun (SS "b", SS "b"));
        assertEqualOrder LESS (MBSS.collate collateFun (SS "y", SS "b"));
        assertEqualOrder GREATER (MBSS.collate collateFun (SS "b", SS "yz"));
        assertEqualOrder LESS (MBSS.collate collateFun (SS "y", SS "yc"));
        assertEqualOrder GREATER (MBSS.collate collateFun (SS "bc", SS "y"));
        assertEqualOrder GREATER (MBSS.collate collateFun (SS "bz", SS "b"));
        assertEqualOrder GREATER (MBSS.collate collateFun (SS "bc", SS "yz"));
        assertEqualOrder EQUAL (MBSS.collate collateFun (SS "bc", SS "bc"));
        assertEqualOrder LESS (MBSS.collate collateFun (SS "yz", SS "bc"));
        ()
      )

  local
    val assertSplit = assertEqual2Tuple (assertEqualMBSS, assertEqualMBSS)
    fun pred char = EQUAL <> MBC.compare (char, (C #"A"))
  in
  fun testSplitl0001 () =
      (
        assertSplit
            (SS "", SS "") (MBSS.splitl pred (SS ""));
        assertSplit
            (SS "b", SS "")
            (MBSS.splitl pred (MBSS.substring (S "abc", 1, 1)));
        assertSplit
            (SS "", SS "A")
            (MBSS.splitl pred (MBSS.substring (S "aAc", 1, 1)));
        assertSplit
            (SS "bc", SS "")
            (MBSS.splitl pred (MBSS.substring (S "abcd", 1, 2)));
        assertSplit
            (SS "", SS "Ac")
            (MBSS.splitl pred (MBSS.substring (S "aAcd", 1, 2)));
        assertSplit
            (SS "a", SS "A")
            (MBSS.splitl pred (MBSS.substring (S "aaAd", 1, 2)));
        assertSplit
            (SS "bcd", SS "")
            (MBSS.splitl pred (MBSS.substring (S "abcde", 1, 3)));
        assertSplit
            (SS "", SS "AcA")
            (MBSS.splitl pred (MBSS.substring (S "aAcAe", 1, 3)));
        assertSplit
            (SS "b", SS "AA")
            (MBSS.splitl pred (MBSS.substring (S "abAAe", 1, 3)));
        assertSplit
            (SS "bc", SS "A")
            (MBSS.splitl pred (MBSS.substring (S "abcAe", 1, 3)));
        ()
      )

  fun testSplitr0001 () =
      (
        assertSplit (SS "", SS "") (MBSS.splitr pred (SS ""));
        assertSplit
            (SS "", SS "b")
            (MBSS.splitr pred (MBSS.substring (S "abc", 1, 1)));
        assertSplit
            (SS "A", SS "")
            (MBSS.splitr pred (MBSS.substring (S "aAc", 1, 1)));
        assertSplit
            (SS "", SS "bc")
            (MBSS.splitr pred (MBSS.substring (S "abcd", 1, 2)));
        assertSplit
            (SS "A", SS "c")
            (MBSS.splitr pred (MBSS.substring (S "aAcd", 1, 2)));
        assertSplit
            (SS "aA", SS "")
            (MBSS.splitr pred (MBSS.substring (S "aaAd", 1, 2)));
        assertSplit
            (SS "", SS "bcd")
            (MBSS.splitr pred (MBSS.substring (S "abcde", 1, 3)));
        assertSplit
            (SS "AcA", SS "")
            (MBSS.splitr pred (MBSS.substring (S "aAcAe", 1, 3)));
        assertSplit
            (SS "bAA", SS "")
            (MBSS.splitr pred (MBSS.substring (S "abAAe", 1, 3)));
        assertSplit
            (SS "bcA", SS "")
            (MBSS.splitr pred (MBSS.substring (S "abcAe", 1, 3)));
        ()
      )

  fun testSplitAt0001 () =
      (
        assertSplit (SS "", SS "") (MBSS.splitAt (MBSS.full (S ""), 0));
        (MBSS.splitAt(MBSS.full (S ""), ~1); fail "splitAt") 
        handle General.Subscript => ();
        (MBSS.splitAt(MBSS.full (S ""), 1); fail "splitAt")
        handle General.Subscript => ();
        assertSplit
            (SS "", SS "b") (MBSS.splitAt(MBSS.substring (S "abc", 1, 1), 0));
        assertSplit
            (SS "b", SS "") (MBSS.splitAt(MBSS.substring (S "abc", 1, 1), 1));
        (MBSS.splitAt(MBSS.substring (S "abc", 1, 1), 2); fail "splitAt")
        handle General.Subscript => ();
        (MBSS.splitAt(MBSS.substring (S "abc", 1, 1), ~1); fail "splitAt")
        handle General.Subscript => ();
        assertSplit
            (SS "", SS "bc")
            (MBSS.splitAt(MBSS.substring (S "abcd", 1, 2), 0));
        assertSplit
            (SS "b", SS "c")
            (MBSS.splitAt(MBSS.substring (S "abcd", 1, 2), 1));
        assertSplit
            (SS "bc", SS "")
            (MBSS.splitAt(MBSS.substring (S "abcd", 1, 2), 2));
        (MBSS.splitAt(MBSS.substring (S "abcd", 1, 2), 3); fail "splitAt")
        handle General.Subscript => ();
        (MBSS.splitAt(MBSS.substring (S "abcd", 1, 2), ~1); fail "splitAt")
        handle General.Subscript => ();
        assertSplit
            (SS "", SS "bcd")
            (MBSS.splitAt(MBSS.substring (S "abcde", 1, 3), 0));
        assertSplit
            (SS "b", SS "cd")
            (MBSS.splitAt(MBSS.substring (S "abcde", 1, 3), 1));
        assertSplit
            (SS "bc", SS "d")
            (MBSS.splitAt(MBSS.substring (S "abcde", 1, 3), 2));
        assertSplit
            (SS "bcd", SS "")
            (MBSS.splitAt(MBSS.substring (S "abcde", 1, 3), 3));
        (MBSS.splitAt(MBSS.substring (S "abcde", 1, 3), 4); fail "splitAt")
        handle General.Subscript => ();
        (MBSS.splitAt(MBSS.substring (S "abcde", 1, 3), ~1); fail "splitAt")
        handle General.Subscript => ();
        ()
      )

  fun testDropl0001 () =
      (
        assertEqualMBSS (SS "") (MBSS.dropl pred (SS ""));
        assertEqualMBSS
            (SS "") (MBSS.dropl pred (MBSS.substring (S "abc", 1, 1)));
        assertEqualMBSS
            (SS "A") (MBSS.dropl pred (MBSS.substring (S "aAc", 1, 1)));
        assertEqualMBSS
            (SS "") (MBSS.dropl pred (MBSS.substring (S "abcd", 1, 2)));
        assertEqualMBSS
            (SS "Ac") (MBSS.dropl pred (MBSS.substring (S "aAcd", 1, 2)));
        assertEqualMBSS
            (SS "A") (MBSS.dropl pred (MBSS.substring (S "aaAd", 1, 2)));
        assertEqualMBSS
            (SS "") (MBSS.dropl pred (MBSS.substring (S "abcde", 1, 3)));
        assertEqualMBSS
            (SS "AcA") (MBSS.dropl pred (MBSS.substring (S "aAcAe", 1, 3)));
        assertEqualMBSS
            (SS "AA") (MBSS.dropl pred (MBSS.substring (S "abAAe", 1, 3)));
        assertEqualMBSS
            (SS "A") (MBSS.dropl pred (MBSS.substring (S "abcAe", 1, 3)));
        ()
      )

  fun testDropr0001 () =
      (
        assertEqualMBSS (SS "") (MBSS.dropr pred (SS ""));
        assertEqualMBSS
            (SS "") (MBSS.dropr pred (MBSS.substring (S "abc", 1, 1)));
        assertEqualMBSS
            (SS "A") (MBSS.dropr pred (MBSS.substring (S "aAc", 1, 1)));
        assertEqualMBSS
            (SS "") (MBSS.dropr pred (MBSS.substring (S "abcd", 1, 2)));
        assertEqualMBSS
            (SS "A") (MBSS.dropr pred (MBSS.substring (S "aAcd", 1, 2)));
        assertEqualMBSS
            (SS "aA") (MBSS.dropr pred (MBSS.substring (S "aaAd", 1, 2)));
        assertEqualMBSS
            (SS "") (MBSS.dropr pred (MBSS.substring (S "abcde", 1, 3)));
        assertEqualMBSS
            (SS "AcA") (MBSS.dropr pred (MBSS.substring (S "aAcAe", 1, 3)));
        assertEqualMBSS
            (SS "bAA") (MBSS.dropr pred (MBSS.substring (S "abAAe", 1, 3)));
        assertEqualMBSS
            (SS "bcA") (MBSS.dropr pred (MBSS.substring (S "abcAe", 1, 3)));
        ()
      )

  fun testTakel0001 () =
      (
        assertEqualMBSS (SS "") (MBSS.takel pred (SS ""));
        assertEqualMBSS
            (SS "b") (MBSS.takel pred (MBSS.substring (S "abc", 1, 1)));
        assertEqualMBSS
            (SS "") (MBSS.takel pred (MBSS.substring (S "aAc", 1, 1)));
        assertEqualMBSS
            (SS "bc") (MBSS.takel pred (MBSS.substring (S "abcd", 1, 2)));
        assertEqualMBSS
            (SS "") (MBSS.takel pred (MBSS.substring (S "aAcd", 1, 2)));
        assertEqualMBSS
            (SS "a") (MBSS.takel pred (MBSS.substring (S "aaAd", 1, 2)));
        assertEqualMBSS
            (SS "bcd") (MBSS.takel pred (MBSS.substring (S "abcde", 1, 3)));
        assertEqualMBSS
            (SS "") (MBSS.takel pred (MBSS.substring (S "aAcAe", 1, 3)));
        assertEqualMBSS
            (SS "b") (MBSS.takel pred (MBSS.substring (S "abAAe", 1, 3)));
        assertEqualMBSS
            (SS "bc") (MBSS.takel pred (MBSS.substring (S "abcAe", 1, 3)));
        ()
      )

  fun testTaker0001 () =
      (
        assertEqualMBSS (SS "") (MBSS.taker pred (SS ""));
        assertEqualMBSS
            (SS "b") (MBSS.taker pred (MBSS.substring (S "abc", 1, 1)));
        assertEqualMBSS
            (SS "") (MBSS.taker pred (MBSS.substring (S "aAc", 1, 1)));
        assertEqualMBSS
            (SS "bc") (MBSS.taker pred (MBSS.substring (S "abcd", 1, 2)));
        assertEqualMBSS
            (SS "c") (MBSS.taker pred (MBSS.substring (S "aAcd", 1, 2)));
        assertEqualMBSS
            (SS "") (MBSS.taker pred (MBSS.substring (S "aaAd", 1, 2)));
        assertEqualMBSS
            (SS "bcd") (MBSS.taker pred (MBSS.substring (S "abcde", 1, 3)));
        assertEqualMBSS
            (SS "") (MBSS.taker pred (MBSS.substring (S "aAcAe", 1, 3)));
        assertEqualMBSS
            (SS "") (MBSS.taker pred (MBSS.substring (S "abAAe", 1, 3)));
        assertEqualMBSS
            (SS "") (MBSS.taker pred (MBSS.substring (S "abcAe", 1, 3)));
        ()
      )

  (********************)
  local
    val assertPosition = assertEqual2Tuple (assertEqualMBSS, assertEqualMBSS)
  in
  fun testPosition0001 () =
      (
        assertPosition
            (SS "", SS "") (MBSS.position (S "") (SS ""));
        assertPosition
            (SS "", SS "b")
            (MBSS.position (S "") (MBSS.substring (S "abc", 1, 1)));
        assertPosition
            (SS "b", SS "")
            (MBSS.position (S "a") (MBSS.substring (S "abc", 1, 1)));
        assertPosition
            (SS "b", SS "")
            (MBSS.position (S "c") (MBSS.substring (S "abc", 1, 1)));
        assertPosition
            (SS "", SS "b")
            (MBSS.position (S "b") (MBSS.substring (S "abc", 1, 1)));
        assertPosition
            (SS "bc", SS "")
            (MBSS.position (S "a") (MBSS.substring (S "abcd", 1, 2)));
        assertPosition
            (SS "", SS "bc")
            (MBSS.position (S "b") (MBSS.substring (S "abcd", 1, 2)));
        assertPosition
            (SS "b", SS "c")
            (MBSS.position (S "c") (MBSS.substring (S "abcd", 1, 2)));
        assertPosition
            (SS "bc", SS "")
            (MBSS.position (S "d") (MBSS.substring (S "abcd", 1, 2)));
        assertPosition
            (SS "b", SS "")
            (MBSS.position (S "ab") (MBSS.substring (S "abc", 1, 1)));
        assertPosition
            (SS "b", SS "")
            (MBSS.position (S "bc") (MBSS.substring (S "abc", 1, 1)));
        assertPosition
            (SS "bc", SS "")
            (MBSS.position (S "ab") (MBSS.substring (S "abcd", 1, 2)));
        assertPosition
            (SS "", SS "bc")
            (MBSS.position (S "bc") (MBSS.substring (S "abcd", 1, 2)));
        assertPosition
            (SS "bc", SS "")
            (MBSS.position (S "cd") (MBSS.substring (S "abcd", 1, 2)));
        assertPosition
            (SS "bc", SS "")
            (MBSS.position (S "de") (MBSS.substring (S "abcd", 1, 2)));
        assertPosition
            (SS "bcd", SS "")
            (MBSS.position (S "ab") (MBSS.substring (S "abcdef", 1, 3)));
        assertPosition
            (SS "", SS "bcd")
            (MBSS.position (S "bc") (MBSS.substring (S "abcdef", 1, 3)));
        assertPosition
            (SS "b", SS "cd")
            (MBSS.position (S "cd") (MBSS.substring (S "abcdef", 1, 3)));
        assertPosition
            (SS "bcd", SS "")
            (MBSS.position (S "de") (MBSS.substring (S "abcdef", 1, 3)));
        assertPosition
            (SS "bcd", SS "")
            (MBSS.position (S "ef") (MBSS.substring (S "abcdef", 1, 3)));
        (* the 'position' must search the longest suffix. *)
        assertPosition
            (SS "", SS "bcdbc")
            (MBSS.position (S "bc") (MBSS.substring (S "abcdbcf", 1, 5)));
        ()
      )
  end

  end

  local
    fun assertSpan
            expected string (leftStart, leftLength) (rightStart, rightLength) =
        let
          val mbs = S string
          val left = MBSS.substring (mbs, leftStart, leftLength)
          val right = MBSS.substring (mbs, rightStart, rightLength)
        in assertEqualMBSS (MBSS.full (S expected)) (MBSS.span (left, right))
        end
  in
  (*
   * (ls, le): the start index and the end index of left substring.
   * (rs, re): the start index and the end index of right substring.
   * There are 6 cases in the relation between the ls and the right substring.
   *  (A) ls < rs, (B) ls = rs, (C) rs < ls < re, (D) ls = re, (E) re < ls
   * And, same relations between the le and the right substring.
   * Some combinations are not considered because they are impossible. 
   *)
  fun testSpan0001 () =
      (

        assertSpan "bc"  "abcde" (1, 0) (3, 0);
        assertSpan "bcd"  "abcde" (1, 1) (3, 1);
        assertSpan "b"  "abcde" (1, 1) (1, 1);
        (assertSpan ""  "abcde" (3, 1) (1, 1); fail "span1")
        handle General.Span => ();

        assertSpan "bcde"  "abcde" (1, 1) (3, 2);
        assertSpan "bc"  "abcde" (1, 1) (1, 2);
        assertSpan "c"  "abcde" (2, 1) (1, 2);
        assertSpan ""  "abcde" (3, 1) (1, 2);

        assertSpan "bcd"  "abcde" (1, 2) (3, 1);
        assertSpan "bc"  "abcde" (1, 2) (2, 1);
        assertSpan "b"  "abcde" (1, 2) (1, 1);
        assertSpan ""  "abcde" (2, 2) (1, 1);

        assertSpan "bcde"  "abcdef" (1, 2) (3, 2);
        assertSpan "bcd"  "abcdef" (1, 2) (2, 2);
        assertSpan "bc"  "abcdef" (1, 2) (1, 2);
        assertSpan "c"  "abcdef" (2, 2) (1, 2);
        assertSpan ""  "abcdef" (3, 2) (1, 2);

        assertSpan "bcde"  "abcdef" (1, 3) (4, 1);
        assertSpan "bcd"  "abcdef" (1, 3) (3, 1);
        assertSpan "bc"  "abcdef" (1, 3) (2, 1);
        assertSpan "b"  "abcdef" (1, 3) (1, 1);
        assertSpan ""  "abcdef" (2, 3) (1, 1);

        assertSpan "bcdef"  "abcdefg" (1, 3) (4, 2);
        assertSpan "bcde"  "abcdefg" (1, 3) (3, 2);
        assertSpan "bcd"  "abcdefg" (1, 3) (2, 2);
        assertSpan "bc"  "abcdefg" (1, 3) (1, 2);
        assertSpan "c"  "abcdefg" (2, 3) (1, 2);
        assertSpan ""  "abcdefg" (3, 3) (1, 2);

        assertSpan "bcdefg"  "abcdefgh" (1, 3) (4, 3);
        assertSpan "bcdef"  "abcdefgh" (1, 3) (3, 3);
        assertSpan "bcde"  "abcdefgh" (1, 3) (2, 3);
        assertSpan "bcd"  "abcdefgh" (1, 3) (1, 3);
        assertSpan "cd"  "abcdefgh" (2, 3) (1, 3);
        assertSpan "d"  "abcdefgh" (3, 3) (1, 3);
        assertSpan ""  "abcdefgh" (4, 3) (1, 3);

        assertSpan "bcdef"  "abcdefg" (1, 2) (3, 3);
        assertSpan "bcde"  "abcdefg" (1, 2) (2, 3);
        assertSpan "bcd"  "abcdefg" (1, 2) (1, 3);
        assertSpan "cd"  "abcdefg" (2, 2) (1, 3);
        assertSpan "d"  "abcdefg" (3, 2) (1, 3);
        assertSpan ""  "abcdefg" (4, 2) (1, 3);

        (* le + 1 < rs *)
        assertSpan "bcdefgh"  "abcdefghi" (1, 3) (5, 3);
        ()
      )
  end

  local
    fun translateFun ch =
        let val string = MBS.implode [ch, ch] in string end
  in
  fun testTranslate0001 () =
      (
        assertEqualMBS
            (S "")
            (MBSS.translate translateFun (MBSS.substring (S "abc", 1, 0)));
        assertEqualMBS
            (S "bb")
            (MBSS.translate translateFun (MBSS.substring (S "abc", 1, 1)));
        assertEqualMBS
            (S "bbcc")
            (MBSS.translate translateFun (MBSS.substring (S "abcd", 1, 2)));
        ()
      )
  end

  fun tokensFun ch = EQUAL = MBC.compare (ch, C #"|");
  fun testTokens0001 () =
      (
        assertEqualMBSSList [] (MBSS.tokens tokensFun (SS ""));
        assertEqualMBSSList [] (MBSS.tokens tokensFun (SS "|"));
        assertEqualMBSSList [SS "b"] (MBSS.tokens tokensFun (SS "|b"));
        assertEqualMBSSList [SS "b"] (MBSS.tokens tokensFun (SS "b|"));
        assertEqualMBSSList [SS "b", SS "c"] (MBSS.tokens tokensFun (SS "b|c"));
        assertEqualMBSSList [] (MBSS.tokens tokensFun (SS "||"));
        assertEqualMBSSList [SS "b"] (MBSS.tokens tokensFun (SS "||b"));
        assertEqualMBSSList [SS "b"] (MBSS.tokens tokensFun (SS "|b|"));
        assertEqualMBSSList [SS "b", SS "c"] (MBSS.tokens tokensFun (SS "|b|c"));
        assertEqualMBSSList [SS "b"] (MBSS.tokens tokensFun (SS "b||"));
        assertEqualMBSSList [SS "b", SS "c"] (MBSS.tokens tokensFun (SS "b||c"));
        assertEqualMBSSList [SS "b", SS "c"] (MBSS.tokens tokensFun (SS "b|c|"));
        assertEqualMBSSList
            [SS "b", SS "c", SS "d"] (MBSS.tokens tokensFun (SS "b|c|d"));
        assertEqualMBSSList
            [SS "bc", SS "de", SS "fg"] (MBSS.tokens tokensFun (SS "bc|de|fg"));
        ()
      )

  fun fieldsFun ch = EQUAL = MBC.compare (ch, C #"|");
  fun testFields0001 () =
      (
        assertEqualMBSSList [SS ""] (MBSS.fields fieldsFun (SS ""));
        assertEqualMBSSList [SS "", SS ""] (MBSS.fields fieldsFun (SS "|"));
        assertEqualMBSSList [SS "", SS "b"] (MBSS.fields fieldsFun (SS "|b"));
        assertEqualMBSSList [SS "b", SS ""] (MBSS.fields fieldsFun (SS "b|"));
        assertEqualMBSSList [SS "b", SS "c"] (MBSS.fields fieldsFun (SS "b|c"));
        assertEqualMBSSList [SS "", SS "", SS ""] (MBSS.fields fieldsFun (SS "||"));
        assertEqualMBSSList
            [SS "", SS "", SS "b"] (MBSS.fields fieldsFun (SS "||b"));
        assertEqualMBSSList
            [SS "", SS "b", SS ""] (MBSS.fields fieldsFun (SS "|b|"));
        assertEqualMBSSList
            [SS "", SS "b", SS "c"] (MBSS.fields fieldsFun (SS "|b|c"));
        assertEqualMBSSList
            [SS "b", SS "", SS ""] (MBSS.fields fieldsFun (SS "b||"));
        assertEqualMBSSList
            [SS "b", SS "", SS "c"] (MBSS.fields fieldsFun (SS "b||c"));
        assertEqualMBSSList
            [SS "b", SS "c", SS ""] (MBSS.fields fieldsFun (SS "b|c|"));
        assertEqualMBSSList
            [SS "b", SS "c", SS "d"] (MBSS.fields fieldsFun (SS "b|c|d"));
        assertEqualMBSSList
            [SS "bc", SS "de", SS "fg"]
            (MBSS.fields fieldsFun (SS "bc|de|fg"));
        ()
      )

  local
    fun assert expected arg =
        let
          val r = ref []
          fun f c = r := c :: (!r)
        in
          MBSS.app f arg;
          assertEqualMBCList expected (!r)
        end
  in
  fun testApp0001 () =
      (
        assert [] (MBSS.substring (S "abc", 1, 0));
        assert [C #"b"] (MBSS.substring (S "abc", 1, 1));
        assert [C #"c", C #"b"] (MBSS.substring (S "abcd", 1, 2));
        ()
      )
  end

  local
    fun foldFun (ch, accum) = (ch :: accum)
    val assert = assertEqualMBCList
  in
  fun testFoldl0001 () =
      (
        assert
            []
            (MBSS.foldl foldFun [] (MBSS.substring(S "abc", 1, 0)));
        assert
            [C #"b"]
            (MBSS.foldl foldFun [] (MBSS.substring(S "abc", 1, 1)));
        assert
            [C #"c", C #"b"]
            (MBSS.foldl foldFun [] (MBSS.substring(S "abcd", 1, 2)));
        assert
            [C #"d", C #"c", C #"b"]
            (MBSS.foldl foldFun [] (MBSS.substring(S "abcde", 1, 3)));
        ()
      )

  fun testFoldr0001 () =
      (
        assert
            []
            (MBSS.foldr foldFun [] (MBSS.substring(S "abc", 1, 0)));
        assert
            [C #"b"]
            (MBSS.foldr foldFun [] (MBSS.substring(S "abc", 1, 1)));
        assert
            [C #"b", C #"c"]
            (MBSS.foldr foldFun [] (MBSS.substring(S "abcd", 1, 2)));
        assert
            [C #"b", C #"c", C #"d"]
            (MBSS.foldr foldFun [] (MBSS.substring(S "abcde", 1, 3)));
        ()
      )

  end

  (***************************************************************************)

  fun suite () =
      T.labelTests
      [
        ("testSub0001", testSub0001),
        ("testSize0001),", testSize0001),
        ("testBase0001", testBase0001),
        ("testExtract0001", testExtract0001),
        ("testSubstring0001", testSubstring0001),
        ("testFull0001", testFull0001),
        ("testString0001", testString0001),
        ("testIsEmpty0001", testIsEmpty0001),
        ("testGetc0001", testGetc0001),
        ("testFirst0001", testFirst0001),
        ("testTriml0001", testTriml0001),
        ("testTrimr0001", testTrimr0001),
        ("testSlice0001", testSlice0001),
        ("testConcat0001", testConcat0001),
        ("testConcatWith0001", testConcatWith0001),
        ("testExplode0001", testExplode0001),
        ("testIsPrefix0001", testIsPrefix0001),
        ("testIsSuffix0001", testIsSuffix0001),
        ("tessIsSubstring0001", tessIsSubstring0001),
        ("testCompare0001", testCompare0001),
        ("testCollate0001", testCollate0001),
        ("testSplitl0001", testSplitl0001),
        ("testSplitr0001", testSplitr0001),
        ("testSplitAt0001", testSplitAt0001),
        ("testDropl0001", testDropl0001),
        ("testDropr0001", testDropr0001),
        ("testTakel0001", testTakel0001),
        ("testTaker0001", testTaker0001),
        ("testPosition0001", testPosition0001),
        ("testSpan0001", testSpan0001),
        ("testTranslate0001", testTranslate0001),
        ("testTokens0001", testTokens0001),
        ("testFields0001", testFields0001),
        ("testApp0001", testApp0001),
        ("testFoldl0001", testFoldl0001),
        ("testFoldr0001", testFoldr0001)
      ]

  (***************************************************************************)

end