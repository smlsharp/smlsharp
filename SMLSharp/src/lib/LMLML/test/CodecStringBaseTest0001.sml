(**
 * Test cases for multibyte string.
 * Test cases in this module are codec independent.
 * @author YAMATODANI Kiyoshi
 * @version $Id: CodecStringBaseTest0001.sml,v 1.1.2.1 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
functor CodecStringBaseTest0001(Codec : CODEC) =
struct

  (***************************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test

  structure MBS = Codec.String
  structure MBSS = Codec.Substring
  structure MBC = Codec.Char

  structure TestUtil = LMLMLTestUtil(Codec)
  open TestUtil.Assert
  open TestUtil

  (***************************************************************************)

  local
    val bytes1 = asciiStringToBytes ""
    val bytes2 = asciiStringToBytes "a"
    val bytes3 = asciiStringToBytes "ab"
  in
  fun testBytesToMBS0001 () =
      (
        assertEqualBytes bytes1 ((MBS.MBSToBytes o MBS.bytesToMBS) bytes1);
        assertEqualBytes bytes2 ((MBS.MBSToBytes o MBS.bytesToMBS) bytes2);
        assertEqualBytes bytes3 ((MBS.MBSToBytes o MBS.bytesToMBS) bytes3);
        ()
      )
  end

  local
    val slice1 = asciiStringToBytesSlice ""
    val slice2 = asciiStringToBytesSlice "a"
    val slice3 = asciiStringToBytesSlice "ab"
  in
  fun testBytesSliceToMBS0001 () =
      (
        assertEqualBytesSlice
            slice1 ((MBS.MBSToBytesSlice o MBS.bytesSliceToMBS) slice1);
        assertEqualBytesSlice
            slice2 ((MBS.MBSToBytesSlice o MBS.bytesSliceToMBS) slice2);
        assertEqualBytesSlice
            slice3 ((MBS.MBSToBytesSlice o MBS.bytesSliceToMBS) slice3);
        ()
      )
  end

  local
    val string1 = ""
    val string2 = "a"
    val string3 = "ab"
  in
  fun testStringToMBS0001 () =
      (
        assertEqualString
            string1 ((MBS.MBSToString o MBS.stringToMBS) string1);
        assertEqualString
            string2 ((MBS.MBSToString o MBS.stringToMBS) string2);
        assertEqualString
            string3 ((MBS.MBSToString o MBS.stringToMBS) string3);
        ()
      )
  end

  (* stringToMBS should not interpret escape sequences. *)
  local
    val string1 = "\\a"
    val string2 = "\a"
    val string3 = "\\255"
  in
  fun testStringToMBS0002 () =
      (
        assertEqualString
            string1 ((MBS.MBSToString o MBS.stringToMBS) string1);
        assertEqualString
            string2 ((MBS.MBSToString o MBS.stringToMBS) string2);
        assertEqualString
            string3 ((MBS.MBSToString o MBS.stringToMBS) string3);
        ()
      )
  end

(*
  fun testMaxSize0001() = ...
*)

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

  fun testConcatWith0001 () =
      (
        assertEqualMBS (S "") (MBS.concatWith (S "<>") []);
        assertEqualMBS (S "ab") (MBS.concatWith (S "<>") [S "ab"]);
        assertEqualMBS (S "ab<>a") (MBS.concatWith (S "<>") [S "ab", S "a"]);
        assertEqualMBS (S "ab<>ab") (MBS.concatWith (S "<>") [S "ab", S "ab"]);
        assertEqualMBS (S "<>ab") (MBS.concatWith (S "<>") [S "", S "ab"]);
        assertEqualMBS (S "ab<>") (MBS.concatWith (S "<>") [S "ab", S ""]);
        assertEqualMBS (S "ab<><>ab") (MBS.concatWith (S "<>") [S "ab", S "", S "ab"]);
        assertEqualMBS (S "ab<>a<>ab") (MBS.concatWith (S "<>") [S "ab", S "a", S "ab"]);
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

  fun testLT0001 () =
      (
        assertFalse (MBS.< (S "", S ""));
        assertTrue (MBS.< (S "", S "y"));
        assertFalse (MBS.< (S "b", S ""));
        assertTrue (MBS.< (S "b", S "y"));
        assertFalse (MBS.< (S "b", S "b"));
        assertFalse (MBS.< (S "y", S "b"));
        assertTrue (MBS.< (S "b", S "yz"));
        assertTrue (MBS.< (S "y", S "yc"));
        assertTrue (MBS.< (S "bc", S "y"));
        assertFalse (MBS.< (S "bz", S "b"));
        assertTrue (MBS.< (S "bc", S "yz"));
        assertFalse (MBS.< (S "bc", S "bc"));
        assertFalse (MBS.< (S "yz", S "bc"));
        ()
      )

  fun testGT0001 () =
      (
        assertFalse (MBS.> (S "", S ""));
        assertFalse (MBS.> (S "", S "y"));
        assertTrue (MBS.> (S "b", S ""));
        assertFalse (MBS.> (S "b", S "y"));
        assertFalse (MBS.> (S "b", S "b"));
        assertTrue (MBS.> (S "y", S "b"));
        assertFalse (MBS.> (S "b", S "yz"));
        assertFalse (MBS.> (S "y", S "yc"));
        assertFalse (MBS.> (S "bc", S "y"));
        assertTrue (MBS.> (S "bz", S "b"));
        assertFalse (MBS.> (S "bc", S "yz"));
        assertFalse (MBS.> (S "bc", S "bc"));
        assertTrue (MBS.> (S "yz", S "bc"));
        ()
      )

  fun testLE0001 () =
      (
        assertTrue (MBS.<= (S "", S ""));
        assertTrue (MBS.<= (S "", S "y"));
        assertFalse (MBS.<= (S "b", S ""));
        assertTrue (MBS.<= (S "b", S "y"));
        assertTrue (MBS.<= (S "b", S "b"));
        assertFalse (MBS.<= (S "y", S "b"));
        assertTrue (MBS.<= (S "b", S "yz"));
        assertTrue (MBS.<= (S "y", S "yc"));
        assertTrue (MBS.<= (S "bc", S "y"));
        assertFalse (MBS.<= (S "bz", S "b"));
        assertTrue (MBS.<= (S "bc", S "yz"));
        assertTrue (MBS.<= (S "bc", S "bc"));
        assertFalse (MBS.<= (S "yz", S "bc"));
        ()
      )

  fun testGE0001 () =
      (
        assertTrue (MBS.>= (S "", S ""));
        assertFalse (MBS.>= (S "", S "y"));
        assertTrue (MBS.>= (S "b", S ""));
        assertFalse (MBS.>= (S "b", S "y"));
        assertTrue (MBS.>= (S "b", S "b"));
        assertTrue (MBS.>= (S "y", S "b"));
        assertFalse (MBS.>= (S "b", S "yz"));
        assertFalse (MBS.>= (S "y", S "yc"));
        assertFalse (MBS.>= (S "bc", S "y"));
        assertTrue (MBS.>= (S "bz", S "b"));
        assertFalse (MBS.>= (S "bc", S "yz"));
        assertTrue (MBS.>= (S "bc", S "bc"));
        assertTrue (MBS.>= (S "yz", S "bc"));
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

  (********************)

  local
    val string1 = ""
    val string2 = "a"
    val string3 = "ab"
  in
  fun testFromAsciiString0001 () =
      (
        assertEqualString
            string1 ((MBS.toAsciiString o MBS.fromAsciiString) string1);
        assertEqualString
            string2 ((MBS.toAsciiString o MBS.fromAsciiString) string2);
        assertEqualString
            string3 ((MBS.toAsciiString o MBS.fromAsciiString) string3);
        ()
      )
  end

  (* fromAsciiString should not interpret escape sequences. *)
  local
    val string1 = "\\a"
    val string2 = "\a"
    val string3 = "\\255"
  in
  fun testFromAsciiString0002 () =
      (
        assertEqualString
            string1 ((MBS.toAsciiString o MBS.fromAsciiString) string1);
        assertEqualString
            string2 ((MBS.toAsciiString o MBS.fromAsciiString) string2);
        assertEqualString
            string3 ((MBS.toAsciiString o MBS.fromAsciiString) string3);
        ()
      )
  end

  (********************)

  (* decode an ASCII string to a MBS, and convert the MBS to a String.string
   * without encoding.
   *)
  val A = MBS.MBSToString o MBS.fromAsciiString

  fun testFromString0001 () =
      ( (* safe cases: normal strings *)
        assertEqualMBSOption (SOME(S "")) (MBS.fromString (A ""));
        assertEqualMBSOption (SOME(S "a")) (MBS.fromString (A "a"));
        assertEqualMBSOption (SOME(S "ab")) (MBS.fromString (A "ab"));
        assertEqualMBSOption (SOME(S "abc")) (MBS.fromString (A "abc"));
        ()
      )

  fun testFromString0002 () =
      ( (* safe cases: valid escape sequence *)
        assertEqualMBSOption (SOME(S "\a")) (MBS.fromString (A "\\a"));
        assertEqualMBSOption (SOME(S "\b")) (MBS.fromString (A "\\b"));
        assertEqualMBSOption (SOME(S "\t")) (MBS.fromString (A "\\t"));
        assertEqualMBSOption (SOME(S "\n")) (MBS.fromString (A "\\n"));
        assertEqualMBSOption (SOME(S "\v")) (MBS.fromString (A "\\v"));
        assertEqualMBSOption (SOME(S "\f")) (MBS.fromString (A "\\f"));
        assertEqualMBSOption (SOME(S "\r")) (MBS.fromString (A "\\r"));
        assertEqualMBSOption (SOME(S "\\")) (MBS.fromString (A "\\\\"));
        assertEqualMBSOption (SOME(S "\"")) (MBS.fromString (A "\\\""));
        assertEqualMBSOption (SOME(S "\000")) (MBS.fromString (A "\\^@"));
        assertEqualMBSOption (SOME(S "\031")) (MBS.fromString (A "\\^_"));
        assertEqualMBSOption (SOME(S "\000")) (MBS.fromString (A "\\000"));
        assertEqualMBSOption (SOME(S "\126")) (MBS.fromString (A "\\126"));
(*
        assertEqualMBSOption (SOME(S "\255")) (MBS.fromString (A "\\255"));
*)
        assertEqualMBSOption (SOME(S "\001")) (MBS.fromString (A "\\u0001"));
        assertEqualMBSOption (SOME(S "\126")) (MBS.fromString (A "\\u007E"));
(*
        assertEqualMBSOption (SOME(S "\255")) (MBS.fromString (A "\\u00FF"));
*)
        assertEqualMBSOption (SOME(S "")) (MBS.fromString (A "\\ \\"));
        assertEqualMBSOption (SOME(S "")) (MBS.fromString (A "\\\t\\"));
        assertEqualMBSOption (SOME(S "")) (MBS.fromString (A "\\\n\\"));
        assertEqualMBSOption (SOME(S "")) (MBS.fromString (A "\\\r\\"));
        assertEqualMBSOption (SOME(S "")) (MBS.fromString (A "\\ \t\n\r\\"));
        ()
      )

  fun testFromString0101 () =
      ( (* error cases: invalid escape sequence at the beginning of string. *)
        assertEqualMBSOption NONE (MBS.fromString (A "\\q"));
        assertEqualMBSOption NONE (MBS.fromString (A "\\qABC"));
        assertEqualMBSOption NONE (MBS.fromString (A "\\ \\"));
        assertEqualMBSOption NONE (MBS.fromString (A "\\ \\\^D"));
        assertEqualMBSOption NONE (MBS.fromString (A "\\ a"));
        assertEqualMBSOption NONE (MBS.fromString (A "\\c"));
        assertEqualMBSOption NONE (MBS.fromString (A "\\^$"));
        ()
      )

  fun testFromString0102 () =
      ( (* error cases: invalid escape sequence in the mid of string. *)
        assertEqualMBSOption (SOME(S"abc")) (MBS.fromString (A "abc\\q"));
        assertEqualMBSOption (SOME(S"abc")) (MBS.fromString (A "abc\\qdef"));
        ()
      )

  fun testFromString0103 () =
      ( (* error cases: sequences which fromCString considers as escape
         * sequences, but invalid for fromString. *)
        assertEqualMBSOption NONE (MBS.fromString (A "\\xFF"));
        assertEqualMBSOption NONE (MBS.fromString (A "\\?"));
        assertEqualMBSOption NONE (MBS.fromString (A "\\'"));
        ()
      )

  (********************)

  fun testFromCString0001 () =
      ( (* safe cases: normal strings *)
        assertEqualMBSOption (SOME(S "")) (MBS.fromCString (A ""));
        assertEqualMBSOption (SOME(S "a")) (MBS.fromCString (A "a"));
        assertEqualMBSOption (SOME(S "ab")) (MBS.fromCString (A "ab"));
        assertEqualMBSOption (SOME(S "abc")) (MBS.fromCString (A "abc"));
        ()
      )

  fun testFromCString0002 () =
      ( (* safe cases: valid escape sequence *)
        assertEqualMBSOption (SOME(S "\a")) (MBS.fromCString (A "\\a"));
        assertEqualMBSOption (SOME(S "\b")) (MBS.fromCString (A "\\b"));
        assertEqualMBSOption (SOME(S "\t")) (MBS.fromCString (A "\\t"));
        assertEqualMBSOption (SOME(S "\n")) (MBS.fromCString (A "\\n"));
        assertEqualMBSOption (SOME(S "\v")) (MBS.fromCString (A "\\v"));
        assertEqualMBSOption (SOME(S "\f")) (MBS.fromCString (A "\\f"));
        assertEqualMBSOption (SOME(S "\r")) (MBS.fromCString (A "\\r"));
        assertEqualMBSOption (SOME(S "?")) (MBS.fromCString (A "\\?"));
        assertEqualMBSOption (SOME(S "\\")) (MBS.fromCString (A "\\\\"));
        assertEqualMBSOption (SOME(S "\"")) (MBS.fromCString (A "\\\""));
        assertEqualMBSOption (SOME(S "'")) (MBS.fromCString (A "\\'"));
        assertEqualMBSOption (SOME(S "\000")) (MBS.fromCString (A "\\^@"));
        assertEqualMBSOption (SOME(S "\031")) (MBS.fromCString (A "\\^_"));
        assertEqualMBSOption (SOME(S "\001")) (MBS.fromCString (A "\\001"));
        assertEqualMBSOption (SOME(S "\255")) (MBS.fromCString (A "\\xFF"));
        ()
      )

  fun testFromCString0101 () =
      ( (* error cases: invalid escape sequence at the beginning of string. *)
        assertEqualMBSOption NONE (MBS.fromCString (A "\\q"));
        assertEqualMBSOption NONE (MBS.fromCString (A "\\qABC"));
        assertEqualMBSOption NONE (MBS.fromCString (A "\\ \\"));
        assertEqualMBSOption NONE (MBS.fromCString (A "\\ \\\^D"));
        assertEqualMBSOption NONE (MBS.fromCString (A "\\ a"));
        assertEqualMBSOption NONE (MBS.fromCString (A "\\c"));
        assertEqualMBSOption NONE (MBS.fromCString (A "\\^$"));
        ()
      )

  fun testFromCString0102 () =
      ( (* error cases: invalid escape sequence in the mid of string. *)
        assertEqualMBSOption (SOME(S"abc")) (MBS.fromCString (A "abc\\q"));
        assertEqualMBSOption (SOME(S"abc")) (MBS.fromCString (A "abc\\qdef"));
        ()
      )

  (***************************************************************************)

  fun suite () =
      T.labelTests
      [
(*
        ("testBytesToMBS0001", testBytesToMBS0001),
        ("testBytesSliceToMBS0001", testBytesSliceToMBS0001),
        ("testStringToMBS0001", testStringToMBS0001),
        ("testStringToMBS0002", testStringToMBS0002),
*)
(*
        ("testMaxSize0001", testMaxSize0001),
*)
        ("testSize0001", testSize0001),
        ("testSub0001", testSub0001),
        ("testExtract0001", testExtract0001),
        ("testSubstring0001", testSubstring0001),
        ("testConcat0001", testConcat0001),
        ("testConcat0002", testConcat0002),
        ("testConcatWith0001", testConcatWith0001),
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
        ("testLT0001", testLT0001),
        ("testGT0001", testGT0001),
        ("testLE0001", testLE0001),
        ("testGE0001", testGE0001),
        ("testCollate0001", testCollate0001),
        ("testFromAsciiString0001", testFromAsciiString0001),
        ("testFromAsciiString0002", testFromAsciiString0002),
        ("testFromString0001", testFromString0001),
        ("testFromString0002", testFromString0002),
        ("testFromString0101", testFromString0101),
        ("testFromString0102", testFromString0102),
        ("testFromString0103", testFromString0103),
        ("testFromCString0001", testFromCString0001),
        ("testFromCString0002", testFromCString0002),
        ("testFromCString0101", testFromCString0101),
        ("testFromCString0102", testFromCString0102)
      ]

  (***************************************************************************)

end