(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: MBStringTest0001.sml,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
structure MBStringTest0001 =
struct

  (***************************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test

  structure MBS = MultiByteString.String
  structure MBC = MultiByteString.Char

  (***************************************************************************)

  open A

  fun S string = MBS.fromString string

  fun C char = valOf(MBC.fromString (str char))

  val assertEqualMBC =
      assertEqual (fn (c1, c2) => MBC.compare (c1, c2) = EQUAL) MBC.toString;

  val assertEqualMBS =
      assertEqual (fn (s1, s2) => MBS.compare (s1, s2) = EQUAL) MBS.toString

  val assertEqualMBCList = assertEqualList assertEqualMBC

  val assertEqualMBSList = assertEqualList assertEqualMBS

  fun testSize0001() =
      (
        assertEqualInt 0 (MBS.size (S ""));
        assertEqualInt 1 (MBS.size (S "a"));
        assertEqualInt 2 (MBS.size (S "ab"));
        ()
      )

  fun testSub0001() =
      (
        (MBS.sub (S "", 0) ; A.fail "sub") handle Subscript => ();

        (MBS.sub (S "a", ~1); A.fail "sub") handle Subscript => ();
        assertEqualMBC (C #"a") (MBS.sub (S "a", 0));
        (MBS.sub (S "a", 1); A.fail "sub") handle Subscript => ();

        (MBS.sub (S "ab", ~1); A.fail "sub") handle Subscript => ();
        assertEqualMBC (C #"a") (MBS.sub (S "ab", 0));
        assertEqualMBC (C #"b") (MBS.sub (S "ab", 1));
        (MBS.sub (S "ab", 2); A.fail "sub") handle Subscript => ();

        ()
      )

  fun testExtract0001 () =
      (
        assertEqualMBS (S "") (MBS.extract (S "", 0, NONE));
        assertEqualMBS (S "") (MBS.extract (S "", 0, SOME 0));
        assertEqualMBS (S "a") (MBS.extract (S "a", 0, NONE));
        assertEqualMBS (S "") (MBS.extract (S "a", 0, SOME 0));
        assertEqualMBS (S "a") (MBS.extract (S "a", 0, SOME 1));
        assertEqualMBS (S "") (MBS.extract (S "a", 1, NONE));
        assertEqualMBS (S "") (MBS.extract (S "a", 1, SOME 0));
        assertEqualMBS (S "ab") (MBS.extract (S "ab", 0, NONE));
        assertEqualMBS (S "") (MBS.extract (S "ab", 0, SOME 0));
        assertEqualMBS (S "a") (MBS.extract (S "ab", 0, SOME 1));
        assertEqualMBS (S "ab") (MBS.extract (S "ab", 0, SOME 2));
        assertEqualMBS (S "b") (MBS.extract (S "ab", 1, NONE));
        assertEqualMBS (S "") (MBS.extract (S "ab", 1, SOME 0));
        assertEqualMBS (S "b") (MBS.extract (S "ab", 1, SOME 1));
        assertEqualMBS (S "") (MBS.extract (S "ab", 2, NONE));
        assertEqualMBS (S "") (MBS.extract (S "ab", 2, SOME 0));

        (* error cases *)
        (MBS.extract(S "ab", ~1, NONE); fail "extract")
        handle Subscript => ();
        (MBS.extract(S "ab", 3, NONE); fail "extract")
        handle Subscript => ();
        (MBS.extract(S "ab", ~1, SOME 0); fail "extract")
        handle Subscript => ();
        (MBS.extract(S "ab", ~1, SOME ~1); fail "extract")
        handle Subscript => ();
        (MBS.extract(S "ab", 1, SOME 2); fail "extract")
        handle Subscript => ();

        ()
      )

  fun testSubstring0001 () =
      (
        assertEqualMBS (S "") (MBS.substring(S "", 0, 0));
        assertEqualMBS (S "") (MBS.substring(S "a", 0, 0));
        assertEqualMBS (S "a") (MBS.substring(S "a", 0, 1));
        assertEqualMBS (S "") (MBS.substring(S "a", 1, 0));
        assertEqualMBS (S "") (MBS.substring(S "ab", 0, 0));
        assertEqualMBS (S "a") (MBS.substring(S "ab", 0, 1));
        assertEqualMBS (S "ab") (MBS.substring(S "ab", 0, 2));
        assertEqualMBS (S "") (MBS.substring(S "ab", 1, 0));
        assertEqualMBS (S "b") (MBS.substring(S "ab", 1, 1));
        assertEqualMBS (S "") (MBS.substring(S "ab", 2, 0));

        (* error cases *)
        (MBS.substring(S "ab", ~1, 0); fail "subtring")
        handle Subscript => ();
        (MBS.substring(S "ab", ~1, ~1); fail "subtring")
        handle Subscript => ();
        (MBS.substring(S "ab", 1, 2); fail "subtring")
        handle Subscript => ();

        ()
      )

  fun testConcat0001 () =
      (
        assertEqualMBS (S "") (MBS.^ (S "", S ""));
        assertEqualMBS (S "a") (MBS.^ (S "", S "a"));
        assertEqualMBS (S "a") (MBS.^ (S "a", S ""));
        assertEqualMBS (S "ab") (MBS.^ (S "a", S "b"));
        assertEqualMBS (S "abc") (MBS.^ (S "a", S "bc"));
        assertEqualMBS (S "abbc") (MBS.^ (S "ab", S "bc"));
        ()
      )

  fun testConcat0002 () =
      (
        assertEqualMBS (S "") (MBS.concat []);
        assertEqualMBS (S "ab") (MBS.concat [S "ab"]);
        assertEqualMBS (S "aba") (MBS.concat [S "ab", S "a"]);
        assertEqualMBS (S "abab") (MBS.concat [S "ab", S "ab"]);
        assertEqualMBS (S "ab") (MBS.concat [S "", S "ab"]);
        assertEqualMBS (S "ab") (MBS.concat [S "ab", S ""]);
        assertEqualMBS (S "abab") (MBS.concat [S "ab", S "", S "ab"]);
        assertEqualMBS (S "abaab") (MBS.concat [S "ab", S "a", S "ab"]);
        ()
       )

  fun testStr0001 () =
      (
        assertEqualMBS (S "a") (MBS.str (C #"a"));
        ()
      )

  fun testImplode0001 () =
      (
        assertEqualMBS (S "") (MBS.implode []);
        assertEqualMBS (S "a") (MBS.implode [C #"a"]);
        assertEqualMBS (S "ab") (MBS.implode [C #"a", C #"b"]);
        assertEqualMBS (S "abc") (MBS.implode [C #"a", C #"b", C #"c"]);
        ()
      )

  fun testExplode0001 () =
      (
        assertEqualMBCList [] (MBS.explode(S ""));
        assertEqualMBCList [C #"a"] (MBS.explode(S "a"));
        assertEqualMBCList [C #"a", C #"b"] (MBS.explode(S "ab"));
        assertEqualMBCList [C #"a", C #"b", C #"c"] (MBS.explode(S "abc"));
        ()
      )

  fun mapFun (ch : MBC.char) = C #"x";
  fun testMap0001 () =
      (
        assertEqualMBS (S "") (MBS.map mapFun (S ""));
        assertEqualMBS (S "x") (MBS.map mapFun (S "b"));
        assertEqualMBS (S "xx") (MBS.map mapFun (S "bc"));
        ()
      )

  fun translateFun ch =
      let val string = MBS.implode [ch, ch]
      in string end;
  fun testTranslate0001 () =
      (
        assertEqualMBS (S "") (MBS.translate translateFun (S ""));
        assertEqualMBS (S "bb") (MBS.translate translateFun (S "b"));
        assertEqualMBS (S "bbcc") (MBS.translate translateFun (S "bc"));
        ()
      )

  fun tokensFun ch = EQUAL = MBC.compare (ch, C #"|");
  fun testTokens0001 () =
      (
        assertEqualMBSList [] (MBS.tokens tokensFun (S ""));
        assertEqualMBSList [] (MBS.tokens tokensFun (S "|"));
        assertEqualMBSList [S "b"] (MBS.tokens tokensFun (S "|b"));
        assertEqualMBSList [S "b"] (MBS.tokens tokensFun (S "b|"));
        assertEqualMBSList [S "b", S "c"] (MBS.tokens tokensFun (S "b|c"));
        assertEqualMBSList [] (MBS.tokens tokensFun (S "||"));
        assertEqualMBSList [S "b"] (MBS.tokens tokensFun (S "||b"));
        assertEqualMBSList [S "b"] (MBS.tokens tokensFun (S "|b|"));
        assertEqualMBSList [S "b", S "c"] (MBS.tokens tokensFun (S "|b|c"));
        assertEqualMBSList [S "b"] (MBS.tokens tokensFun (S "b||"));
        assertEqualMBSList [S "b", S "c"] (MBS.tokens tokensFun (S "b||c"));
        assertEqualMBSList [S "b", S "c"] (MBS.tokens tokensFun (S "b|c|"));
        assertEqualMBSList
            [S "b", S "c", S "d"] (MBS.tokens tokensFun (S "b|c|d"));
        assertEqualMBSList
            [S "bc", S "de", S "fg"] (MBS.tokens tokensFun (S "bc|de|fg"));
        ()
      )

  fun fieldsFun ch = EQUAL = MBC.compare (ch, C #"|");
  fun testFields0001 () =
      (
        assertEqualMBSList [S ""] (MBS.fields fieldsFun (S ""));
        assertEqualMBSList [S "", S ""] (MBS.fields fieldsFun (S "|"));
        assertEqualMBSList [S "", S "b"] (MBS.fields fieldsFun (S "|b"));
        assertEqualMBSList [S "b", S ""] (MBS.fields fieldsFun (S "b|"));
        assertEqualMBSList [S "b", S "c"] (MBS.fields fieldsFun (S "b|c"));
        assertEqualMBSList [S "", S "", S ""] (MBS.fields fieldsFun (S "||"));
        assertEqualMBSList
            [S "", S "", S "b"] (MBS.fields fieldsFun (S "||b"));
        assertEqualMBSList
            [S "", S "b", S ""] (MBS.fields fieldsFun (S "|b|"));
        assertEqualMBSList
            [S "", S "b", S "c"] (MBS.fields fieldsFun (S "|b|c"));
        assertEqualMBSList
            [S "b", S "", S ""] (MBS.fields fieldsFun (S "b||"));
        assertEqualMBSList
            [S "b", S "", S "c"] (MBS.fields fieldsFun (S "b||c"));
        assertEqualMBSList
            [S "b", S "c", S ""] (MBS.fields fieldsFun (S "b|c|"));
        assertEqualMBSList
            [S "b", S "c", S "d"] (MBS.fields fieldsFun (S "b|c|d"));
        assertEqualMBSList
            [S "bc", S "de", S "fg"] (MBS.fields fieldsFun (S "bc|de|fg"));
        ()
      )

  fun testIsPrefix0001 () =
      (
        assertTrue (MBS.isPrefix (S "") (S ""));
        assertFalse (MBS.isPrefix (S "a") (S ""));
        assertTrue (MBS.isPrefix (S "") (S "b"));
        assertTrue (MBS.isPrefix (S "b") (S "b"));
        assertFalse (MBS.isPrefix (S "a") (S "b"));
        assertTrue (MBS.isPrefix (S "b") (S "bc"));
        assertFalse (MBS.isPrefix (S "a") (S "bc"));
        assertTrue (MBS.isPrefix (S "bc") (S "bc"));
        assertFalse (MBS.isPrefix (S "bd") (S "bc"));
        assertTrue (MBS.isPrefix (S "bc") (S "bcd"));
        assertFalse (MBS.isPrefix (S "bd") (S "bcd"));
        assertTrue (MBS.isPrefix (S "bcd") (S "bcd"));
        assertFalse (MBS.isPrefix (S "ccd") (S "bcd"));
        ()
      )

  fun testIsSuffix0001 () =
      (
        assertTrue (MBS.isSuffix (S "") (S ""));
        assertFalse (MBS.isSuffix (S "a") (S ""));
        assertTrue (MBS.isSuffix (S "") (S "b"));
        assertTrue (MBS.isSuffix (S "b") (S "b"));
        assertFalse (MBS.isSuffix (S "a") (S "b"));
        assertTrue (MBS.isSuffix (S "c") (S "bc"));
        assertFalse (MBS.isSuffix (S "a") (S "bc"));
        assertTrue (MBS.isSuffix (S "bc") (S "bc"));
        assertFalse (MBS.isSuffix (S "bd") (S "bc"));
        assertTrue (MBS.isSuffix (S "cd") (S "bcd"));
        assertFalse (MBS.isSuffix (S "bd") (S "bcd"));
        assertTrue (MBS.isSuffix (S "bcd") (S "bcd"));
        assertFalse (MBS.isSuffix (S "ccd") (S "bcd"));
        ()
      )

  fun tessIsSubstring0001 () =
      (
        assertTrue (MBS.isSubstring (S "") (S ""));
        assertFalse (MBS.isSubstring (S "a") (S ""));
        assertTrue (MBS.isSubstring (S "") (S "b"));
        assertTrue (MBS.isSubstring (S "b") (S "b"));
        assertFalse (MBS.isSubstring (S "a") (S "b"));
        assertTrue (MBS.isSubstring (S "c") (S "bc"));
        assertTrue (MBS.isSubstring (S "b") (S "bc"));
        assertFalse (MBS.isSubstring (S "a") (S "bc"));
        assertTrue (MBS.isSubstring (S "bc") (S "bc"));
        assertFalse (MBS.isSubstring (S "bd") (S "bc"));
        assertTrue (MBS.isSubstring (S "bc") (S "bcd"));
        assertTrue (MBS.isSubstring (S "cd") (S "bcd"));
        assertFalse (MBS.isSubstring (S "bd") (S "bcd"));
        assertTrue (MBS.isSubstring (S "bcd") (S "bcd"));
        assertFalse (MBS.isSubstring (S "ccd") (S "bcd"));
        ()
      )

  fun testCompare0001 () =
      (
        assertEqualOrder EQUAL (MBS.compare (S "", S ""));
        assertEqualOrder LESS (MBS.compare (S "", S "y"));
        assertEqualOrder GREATER (MBS.compare (S "b", S ""));
        assertEqualOrder LESS (MBS.compare (S "b", S "y"));
        assertEqualOrder EQUAL (MBS.compare (S "b", S "b"));
        assertEqualOrder GREATER (MBS.compare (S "y", S "b"));
        assertEqualOrder LESS (MBS.compare (S "b", S "yz"));
        assertEqualOrder LESS (MBS.compare (S "y", S "yc"));
        assertEqualOrder LESS (MBS.compare (S "bc", S "y"));
        assertEqualOrder GREATER (MBS.compare (S "bz", S "b"));
        assertEqualOrder LESS (MBS.compare (S "bc", S "yz"));
        assertEqualOrder EQUAL (MBS.compare (S "bc", S "bc"));
        assertEqualOrder GREATER (MBS.compare (S "yz", S "bc"));
        ()
      )

  fun collateFun (left, right) =
      case MBC.compare (left, right)
       of LESS => General.GREATER
        | EQUAL => General.EQUAL
        | _ =>  General.LESS;

  fun testCollate0001 () =
      (
        assertEqualOrder EQUAL (MBS.collate collateFun (S "", S ""));
        assertEqualOrder LESS (MBS.collate collateFun (S "", S "y"));
        assertEqualOrder GREATER (MBS.collate collateFun (S "b", S ""));
        assertEqualOrder GREATER (MBS.collate collateFun (S "b", S "y"));
        assertEqualOrder EQUAL (MBS.collate collateFun (S "b", S "b"));
        assertEqualOrder LESS (MBS.collate collateFun (S "y", S "b"));
        assertEqualOrder GREATER (MBS.collate collateFun (S "b", S "yz"));
        assertEqualOrder LESS (MBS.collate collateFun (S "y", S "yc"));
        assertEqualOrder GREATER (MBS.collate collateFun (S "bc", S "y"));
        assertEqualOrder GREATER (MBS.collate collateFun (S "bz", S "b"));
        assertEqualOrder GREATER (MBS.collate collateFun (S "bc", S "yz"));
        assertEqualOrder EQUAL (MBS.collate collateFun (S "bc", S "bc"));
        assertEqualOrder LESS (MBS.collate collateFun (S "yz", S "bc"));
        ()
      )

  (***************************************************************************)

  fun suite () =
      T.labelTests
      [
        ("testSize0001),", testSize0001),
        ("testSub0001", testSub0001),
        ("testExtract0001", testExtract0001),
        ("testSubstring0001", testSubstring0001),
        ("testConcat0001", testConcat0001),
        ("testConcat0002", testConcat0002),
        ("testStr0001", testStr0001),
        ("testImplode0001", testImplode0001),
        ("testExplode0001", testExplode0001),
        ("testMap0001", testMap0001),
        ("testTranslate0001", testTranslate0001),
        ("testTokens0001", testTokens0001),
        ("testFields0001", testFields0001),
        ("testIsPrefix0001", testIsPrefix0001),
        ("testIsSuffix0001", testIsSuffix0001),
        ("tessIsSubstring0001", tessIsSubstring0001),
        ("testCompare0001", testCompare0001),
        ("testCollate0001", testCollate0001)
      ]

  (***************************************************************************)

end