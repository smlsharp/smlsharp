(**
 * Test cases for multibyte string.
 * Test cases in this module are codec independent.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: CodecCharBaseTest0001.sml,v 1.1.2.1 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
functor CodecCharBaseTest0001(Codec : CODEC) =
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

  local
    fun assertSafe string =
        let
          val bytes = asciiStringToBytes string
          val expected = asciiCharToBytes (String.sub (string, 0))
          val result = MBC.bytesToMBC bytes
          val _ = assertSome result
          val _ =
              assertEqualBytes expected (MBC.MBCToBytes (Option.valOf result))
        in
          ()
        end
    fun assertFail string =
        let val bytes = asciiStringToBytes string
        in assertNone (MBC.bytesToMBC bytes)
        end
  in
  fun testBytesToMBC0001 () =
      (
        assertFail "";
        assertSafe "a";
        assertSafe "ab";
        ()
      )
  end

  local
    fun assertSafe string =
        let
          val slice = asciiStringToBytesSlice string
          val expected = asciiCharToBytesSlice (String.sub (string, 0))
          val result = MBC.bytesSliceToMBC slice
          val _ = assertSome result
          val _ =
              assertEqualBytesSlice
                  expected (MBC.MBCToBytesSlice (Option.valOf result))
        in
          ()
        end
    fun assertFail string =
        let val slice = asciiStringToBytesSlice string
        in assertNone (MBC.bytesSliceToMBC slice)
        end
  in
  fun testBytesSliceToMBC0001 () =
      (
        assertFail "";
        assertSafe "a";
        assertSafe "ab";
        ()
      )
  end

  local
    fun assertSafe string =
        let
          val result = MBC.stringToMBC string
          val expected = String.substring (string, 0, 1)
          val _ = assertSome result
          val _ =
              assertEqualString
                  expected (MBC.MBCToString (Option.valOf result))
        in
          ()
        end
    fun assertFail string =
        let
        in assertNone (MBC.stringToMBC string)
        end
  in
  fun testStringToMBC0001 () =
      (
        assertFail "";
        assertSafe "a";
        assertSafe "ab";
        ()
      )

  (* stringToMBC should not interpret escape sequences. *)
  fun testStringToMBC0002 () =
      (
        assertSafe "\\a";
        assertSafe "\a";
        assertSafe "\\255";
        ()
      )
  end

  local
    fun assertSafe char =
        let
          val result = (MBC.toAsciiChar o MBC.fromAsciiChar) char
          val _ = assertSome result
          val _ = assertEqualChar char (Option.valOf result)
        in
          ()
        end
    fun assertFail char =
        let
        in assertNone ((MBC.toAsciiChar o MBC.fromAsciiChar) char)
        end
  in
  fun testFromAsciiChar0001 () =
      (
        assertSafe #"a";
        ()
      )

  fun testFromAsciiChar0002 () =
      (
        assertSafe #"\a";
        ()
      )
  end

  (********************)

  fun testMinChar0001 () = (assertEqualMBC (C #"\000") (MBC.minChar ()); ())
  fun testMaxChar0001 () = (MBC.maxChar (); ())
  fun testMaxOrd0001 () = (MBC.maxOrd (); ())

  fun testMaxOrdw0001 () = (MBC.maxOrdw (); ())
  fun testMinOrdw0001 () = (assertEqualWord32 0w0 (MBC.minOrdw ()); ())

  fun testOrd0001() =
      (
        assertEqualInt (Char.ord #"a") (MBC.ord (C #"a"));
        assertEqualInt 0 (MBC.ord (MBC.minChar()));
        assertEqualInt (MBC.maxOrd()) (MBC.ord (MBC.maxChar()));
        ()
      )

  fun testOrdw0001() =
      (
        assertEqualWord32 (Word32.fromInt (Char.ord #"a")) (MBC.ordw (C #"a"));
        assertEqualWord32 0w0 (MBC.ordw (MBC.minChar()));
        assertEqualWord32 (MBC.maxOrdw()) (MBC.ordw (MBC.maxChar()));
        ()
      )

  fun testChr0001() =
      (
        assertEqualMBC (C #"a") (MBC.chr (Char.ord #"a"));
        assertEqualMBC (C #"\000") (MBC.chr 0);
        assertEqualMBC (MBC.maxChar()) (MBC.chr (MBC.maxOrd()));
        ()
      )

  fun testChr0002 () =
      (
        (MBC.chr (~1); fail "chr0002,1") handle MBC.Chr => ();
        (MBC.chr (MBC.maxOrd() + 1); fail "chr0002,2") handle MBC.Chr => ();
        ()
      )

  fun testChrw0001() =
      (
        assertEqualMBC (C #"a") (MBC.chrw (Word32.fromInt(Char.ord #"a")));
        assertEqualMBC (C #"\000") (MBC.chrw 0w0);
        assertEqualMBC (MBC.maxChar()) (MBC.chrw (MBC.maxOrdw()));
        ()
      )

  fun testChrw0002 () =
      (
        (MBC.chrw (MBC.maxOrdw() + 0w1); fail "chrw0002,1")
        handle MBC.Chr => ();
        ()
      )

  fun testSucc0001() =
      (
        assertEqualMBC (C #"b") (MBC.succ (C #"a"));
        assertEqualMBC (C #"\001") (MBC.succ (C #"\000"));
        assertEqualMBC
            (MBC.maxChar()) (MBC.succ (MBC.chrw (MBC.maxOrdw() - 0w1)));
        ()
      )

  fun testSucc0002() =
      (
        if
          IntInf.pow (2, Word32.wordSize)
          = (IntInf.fromLarge o Word32.toLargeInt) (MBC.maxOrdw ())
        then ()
        else
          (MBC.succ (MBC.chrw (MBC.maxOrdw())); fail "succ0002")
          handle MBC.Chr => ();
        ()
      )

  fun testPred0001() =
      (
        assertEqualMBC (C #"a") (MBC.pred (C #"b"));
        assertEqualMBC (C #"\000") (MBC.pred (C #"\001"));
        assertEqualMBC
            (MBC.chrw (MBC.maxOrdw() - 0w1)) (MBC.pred (MBC.maxChar()));
        ()
      )

  fun testPred0002() =
      (
        (MBC.pred (MBC.chrw (MBC.minOrdw())); fail "pred0002")
        handle MBC.Chr => ();
        ()
      )

  fun testCompare0001 () =
      (
        assertEqualOrder LESS (MBC.compare (C #"b", C #"y"));
        assertEqualOrder EQUAL (MBC.compare (C #"b", C #"b"));
        assertEqualOrder GREATER (MBC.compare (C #"y", C #"b"));
        ()
      )

  fun testLT0001 () =
      (
        assertTrue (MBC.< (C #"b", C #"y"));
        assertFalse (MBC.< (C #"b", C #"b"));
        assertFalse (MBC.< (C #"y", C #"b"));
        ()
      )

  fun testGT0001 () =
      (
        assertFalse (MBC.> (C #"b", C #"y"));
        assertFalse (MBC.> (C #"b", C #"b"));
        assertTrue (MBC.> (C #"y", C #"b"));
        ()
      )

  fun testLE0001 () =
      (
        assertTrue (MBC.<= (C #"b", C #"y"));
        assertTrue (MBC.<= (C #"b", C #"b"));
        assertFalse (MBC.<= (C #"y", C #"b"));
        ()
      )

  fun testGE0001 () =
      (
        assertFalse (MBC.>= (C #"b", C #"y"));
        assertTrue (MBC.>= (C #"b", C #"b"));
        assertTrue (MBC.>= (C #"y", C #"b"));
        ()
      )

  fun testContains0001 () =
      (
        assertFalse (MBC.contains (S "") (C #"a"));
        assertTrue (MBC.contains (S "a") (C #"a"));
        assertFalse (MBC.contains (S "b") (C #"a"));
        assertTrue (MBC.contains (S "ab") (C #"a"));
        assertTrue (MBC.contains (S "ba") (C #"a"));
        assertFalse (MBC.contains (S "bb") (C #"a"));
        assertTrue (MBC.contains (S "bab") (C #"a"));
        ()
      )

  fun testNotContains0001 () =
      (
        assertTrue (MBC.notContains (S "") (C #"a"));
        assertFalse (MBC.notContains (S "a") (C #"a"));
        assertTrue (MBC.notContains (S "b") (C #"a"));
        assertFalse (MBC.notContains (S "ab") (C #"a"));
        assertFalse (MBC.notContains (S "ba") (C #"a"));
        assertTrue (MBC.notContains (S "bb") (C #"a"));
        assertFalse (MBC.notContains (S "bab") (C #"a"));
        ()
      )


  (* NOTE:
   * The Basis specification says that isAscii(c) should be true for
   * an ASCII character, i.e., 0 <= (ord c) <= 127.
   * But, in some codecs, including EUCJP, GB2312 and ShiftJIS, 
   * 127 is an illegal character code.
   *)
  fun testIsAscii0001 () =
      (
        assertTrue (MBC.isAscii (C #"\000"));
        assertTrue (MBC.isAscii (C #"\126"));
(*
        assertFalse (MBC.isAscii (C #"\128"));
        assertFalse (MBC.isAscii (C #"\255"));
*)
        assertTrue (MBC.isAscii (C #" "));
        assertTrue (MBC.isAscii (C #"@"));
        assertTrue (MBC.isAscii (C #"A"));
        assertTrue (MBC.isAscii (C #"Z"));
        assertTrue (MBC.isAscii (C #"a"));
        assertTrue (MBC.isAscii (C #"z"));
        ()
      )

  fun testToLower0001 () =
      (
        assertEqualMBC (C #"\000") (MBC.toLower (C #"\000"));
        assertEqualMBC (C #"\126") (MBC.toLower (C #"\126"));
        assertEqualMBC (C #"@") (MBC.toLower (C #"@"));
        assertEqualMBC (C #"a") (MBC.toLower (C #"A"));
        assertEqualMBC (C #"z") (MBC.toLower (C #"Z"));
        assertEqualMBC (C #"[") (MBC.toLower (C #"["));
        assertEqualMBC (C #"`") (MBC.toLower (C #"`"));
        assertEqualMBC (C #"a") (MBC.toLower (C #"a"));
        assertEqualMBC (C #"z") (MBC.toLower (C #"z"));
        assertEqualMBC (C #"{") (MBC.toLower (C #"{"));
        ()
      )

  fun testToUpper0001 () =
      (
        assertEqualMBC (C #"\000") (MBC.toUpper (C #"\000"));
        assertEqualMBC (C #"\126") (MBC.toUpper (C #"\126"));
        assertEqualMBC (C #"@") (MBC.toUpper (C #"@"));
        assertEqualMBC (C #"A") (MBC.toUpper (C #"A"));
        assertEqualMBC (C #"Z") (MBC.toUpper (C #"Z"));
        assertEqualMBC (C #"[") (MBC.toUpper (C #"["));
        assertEqualMBC (C #"`") (MBC.toUpper (C #"`"));
        assertEqualMBC (C #"A") (MBC.toUpper (C #"a"));
        assertEqualMBC (C #"Z") (MBC.toUpper (C #"z"));
        assertEqualMBC (C #"{") (MBC.toUpper (C #"{"));
        ()
      )

  fun testIsSpace0001 () =
      (
        assertFalse (MBC.isSpace (C #"\000"));
        assertFalse (MBC.isSpace (C #"\126"));
        assertTrue (MBC.isSpace (C #" "));
        assertTrue (MBC.isSpace (C #"\n"));
        assertTrue (MBC.isSpace (C #"\t"));
        assertTrue (MBC.isSpace (C #"\r"));
        assertTrue (MBC.isSpace (C #"\v"));
        assertTrue (MBC.isSpace (C #"\f"));
        assertFalse (MBC.isSpace (C #"@"));
        assertFalse (MBC.isSpace (C #"{"));
        ()
      )

  fun testIsLower0001 () =
      (
        assertFalse (MBC.isLower (C #"\000"));
        assertFalse (MBC.isLower (C #"\126"));
        assertFalse (MBC.isLower (C #"@"));
        assertFalse (MBC.isLower (C #"A"));
        assertFalse (MBC.isLower (C #"Z"));
        assertFalse (MBC.isLower (C #"["));
        assertFalse (MBC.isLower (C #"`"));
        assertTrue (MBC.isLower (C #"a"));
        assertTrue (MBC.isLower (C #"z"));
        assertFalse (MBC.isLower (C #"{"));
        ()
      )

  fun testIsUpper0001 () =
      (
        assertFalse (MBC.isUpper (C #"\000"));
        assertFalse (MBC.isUpper (C #"\126"));
        assertFalse (MBC.isUpper (C #"@"));
        assertTrue (MBC.isUpper (C #"A"));
        assertTrue (MBC.isUpper (C #"Z"));
        assertFalse (MBC.isUpper (C #"["));
        assertFalse (MBC.isUpper (C #"`"));
        assertFalse (MBC.isUpper (C #"a"));
        assertFalse (MBC.isUpper (C #"z"));
        assertFalse (MBC.isUpper (C #"{"));
        ()
      )

  fun testIsDigit0001 () =
      (
        assertFalse (MBC.isDigit (C #"\000"));
        assertFalse (MBC.isDigit (C #"\126"));
        assertTrue (MBC.isDigit (C #"0"));
        assertTrue (MBC.isDigit (C #"9"));
        assertFalse (MBC.isDigit (C #"@"));
        assertFalse (MBC.isDigit (C #"A"));
        assertFalse (MBC.isDigit (C #"Z"));
        assertFalse (MBC.isDigit (C #"["));
        assertFalse (MBC.isDigit (C #"`"));
        assertFalse (MBC.isDigit (C #"a"));
        assertFalse (MBC.isDigit (C #"z"));
        assertFalse (MBC.isDigit (C #"{"));
        ()
      )

  fun testIsAlpha0001 () =
      (
        assertFalse (MBC.isAlpha (C #"\000"));
        assertFalse (MBC.isAlpha (C #"\126"));
        assertFalse (MBC.isAlpha (C #"0"));
        assertFalse (MBC.isAlpha (C #"9"));
        assertFalse (MBC.isAlpha (C #"@"));
        assertTrue (MBC.isAlpha (C #"A"));
        assertTrue (MBC.isAlpha (C #"Z"));
        assertFalse (MBC.isAlpha (C #"["));
        assertFalse (MBC.isAlpha (C #"`"));
        assertTrue (MBC.isAlpha (C #"a"));
        assertTrue (MBC.isAlpha (C #"z"));
        assertFalse (MBC.isAlpha (C #"{"));
        ()
      )

  fun testIsHexDigit0001 () = 
      (
        assertFalse (MBC.isHexDigit (C #"\000"));
        assertFalse (MBC.isHexDigit (C #"\126"));
        assertTrue (MBC.isHexDigit (C #"0"));
        assertTrue (MBC.isHexDigit (C #"9"));
        assertFalse (MBC.isHexDigit (C #"@"));
        assertTrue (MBC.isHexDigit (C #"A"));
        assertTrue (MBC.isHexDigit (C #"F"));
        assertFalse (MBC.isHexDigit (C #"G"));
        assertFalse (MBC.isHexDigit (C #"Z"));
        assertFalse (MBC.isHexDigit (C #"["));
        assertFalse (MBC.isHexDigit (C #"`"));
        assertTrue (MBC.isHexDigit (C #"a"));
        assertTrue (MBC.isHexDigit (C #"f"));
        assertFalse (MBC.isHexDigit (C #"g"));
        assertFalse (MBC.isHexDigit (C #"{"));
        ()
      )

  fun testIsAlphaNum0001 () =
      (
        assertFalse (MBC.isAlphaNum (C #"\000"));
        assertFalse (MBC.isAlphaNum (C #"\126"));
        assertTrue (MBC.isAlphaNum (C #"0"));
        assertTrue (MBC.isAlphaNum (C #"9"));
        assertFalse (MBC.isAlphaNum (C #"@"));
        assertTrue (MBC.isAlphaNum (C #"A"));
        assertTrue (MBC.isAlphaNum (C #"Z"));
        assertFalse (MBC.isAlphaNum (C #"["));
        assertFalse (MBC.isAlphaNum (C #"`"));
        assertTrue (MBC.isAlphaNum (C #"a"));
        assertTrue (MBC.isAlphaNum (C #"z"));
        assertFalse (MBC.isAlphaNum (C #"{"));
        ()
      )

  fun testIsPrint0001 () =
      (
        assertFalse (MBC.isPrint (C #"\000"));
        assertFalse (MBC.isPrint (C #"\031"));
        assertTrue (MBC.isPrint (C #"\032"));
        assertTrue (MBC.isPrint (C #"\126"));

        assertTrue (MBC.isPrint (C #" "));
        assertTrue (MBC.isPrint (C #"~"));
        ()
      )

  fun testIsPunct0001 () =
      (
        assertFalse (MBC.isPunct (C #"\032"));
        assertTrue (MBC.isPunct (C #"\033"));
        assertTrue (MBC.isPunct (C #"\047"));
        assertFalse (MBC.isPunct (C #"\048"));

        assertFalse (MBC.isPunct (C #"\057"));
        assertTrue (MBC.isPunct (C #"\058"));
        assertTrue (MBC.isPunct (C #"\064"));
        assertFalse (MBC.isPunct (C #"\065"));

        assertFalse (MBC.isPunct (C #"\090"));
        assertTrue (MBC.isPunct (C #"\091"));
        assertTrue (MBC.isPunct (C #"\096"));
        assertFalse (MBC.isPunct (C #"\097"));

        assertFalse (MBC.isPunct (C #"\122"));
        assertTrue (MBC.isPunct (C #"\123"));
        assertTrue (MBC.isPunct (C #"\126"));

        assertFalse (MBC.isPunct (C #"0"));
        assertFalse (MBC.isPunct (C #"9"));
        assertFalse (MBC.isPunct (C #"A"));
        assertFalse (MBC.isPunct (C #"Z"));
        assertFalse (MBC.isPunct (C #"a"));
        assertFalse (MBC.isPunct (C #"z"));
        ()
      )

  fun testIsGraph0001 () = 
      (
        assertFalse (MBC.isGraph (C #"\000"));
        assertFalse (MBC.isGraph (C #"\032"));
        assertTrue (MBC.isGraph (C #"\033"));
        assertTrue (MBC.isGraph (C #"\126"));

        assertFalse (MBC.isGraph (C #" ")); (* 032 *)
        assertFalse (MBC.isGraph (C #"\n")); (* 010 *)
        assertFalse (MBC.isGraph (C #"\t")); (* 009 *)
        assertFalse (MBC.isGraph (C #"\r")); (* 013 *)
        assertFalse (MBC.isGraph (C #"\v")); (* 011 *)
        assertFalse (MBC.isGraph (C #"\f")); (* 012 *)

        assertTrue (MBC.isGraph (C #"!"));
        assertTrue (MBC.isGraph (C #"~"));
        ()
      )

  fun testIsCntrl0001 () =
      (
        assertTrue (MBC.isCntrl (C #"\000"));
        assertTrue (MBC.isCntrl (C #"\031"));
        assertFalse (MBC.isCntrl (C #"\032"));
        assertFalse (MBC.isCntrl (C #" "));
        assertTrue (MBC.isCntrl (C #"\^@"));
        assertTrue (MBC.isCntrl (C #"\^_"));
        ()
      )

  (********************)

  (* decode an ASCII string to a MBS, and convert the MBS to a String.string
   * without encoding.
   *)
  val A = MBS.MBSToString o MBS.fromAsciiString

  fun testFromString0001 () =
      ( (* safe cases: normal strings *)
        assertEqualMBCOption NONE (MBC.fromString (A ""));
        assertEqualMBCOption (SOME(C #"a")) (MBC.fromString (A "a"));
        assertEqualMBCOption (SOME(C #"a")) (MBC.fromString (A "ab"));
        assertEqualMBCOption (SOME(C #"a")) (MBC.fromString (A "abc"));
        ()
      )

  fun testFromString0002 () =
      ( (* safe cases: valid escape sequence *)
        assertEqualMBCOption (SOME(C #"\a")) (MBC.fromString (A "\\a"));
        assertEqualMBCOption (SOME(C #"\b")) (MBC.fromString (A "\\b"));
        assertEqualMBCOption (SOME(C #"\t")) (MBC.fromString (A "\\t"));
        assertEqualMBCOption (SOME(C #"\n")) (MBC.fromString (A "\\n"));
        assertEqualMBCOption (SOME(C #"\v")) (MBC.fromString (A "\\v"));
        assertEqualMBCOption (SOME(C #"\f")) (MBC.fromString (A "\\f"));
        assertEqualMBCOption (SOME(C #"\r")) (MBC.fromString (A "\\r"));
        assertEqualMBCOption (SOME(C #"\\")) (MBC.fromString (A "\\\\"));
        assertEqualMBCOption (SOME(C #"\"")) (MBC.fromString (A "\\\""));
        assertEqualMBCOption (SOME(C #"\000")) (MBC.fromString (A "\\^@"));
        assertEqualMBCOption (SOME(C #"\031")) (MBC.fromString (A "\\^_"));
        assertEqualMBCOption (SOME(C #"\000")) (MBC.fromString (A "\\000"));
        assertEqualMBCOption (SOME(C #"\126")) (MBC.fromString (A "\\126"));
(*
        (* see a comment for testIsAscii0001. *)
        assertEqualMBCOption (SOME(C #"\255")) (MBC.fromString (A "\\255"));
*)
        assertEqualMBCOption (SOME(C #"\001")) (MBC.fromString (A "\\u0001"));
        assertEqualMBCOption (SOME(C #"\126")) (MBC.fromString (A "\\u007E"));
(*
        assertEqualMBCOption (SOME(C #"\255")) (MBC.fromString (A "\\u00FF"));
*)
        assertEqualMBCOption NONE (MBC.fromString (A "\\ \\"));
        assertEqualMBCOption NONE (MBC.fromString (A "\\\t\\"));
        assertEqualMBCOption NONE (MBC.fromString (A "\\\n\\"));
        assertEqualMBCOption NONE (MBC.fromString (A "\\\r\\"));
        assertEqualMBCOption NONE (MBC.fromString (A "\\ \t\n\r\\"));
        ()
      )

  fun testFromString0101 () =
      ( (* error cases: invalid escape sequence at the beginning of string. *)
        assertEqualMBCOption NONE (MBC.fromString (A "\\q"));
        assertEqualMBCOption NONE (MBC.fromString (A "\\qABC"));
        assertEqualMBCOption NONE (MBC.fromString (A "\\ \\"));
        assertEqualMBCOption NONE (MBC.fromString (A "\\ \\\^D"));
        assertEqualMBCOption NONE (MBC.fromString (A "\\ a"));
        assertEqualMBCOption NONE (MBC.fromString (A "\\c"));
        assertEqualMBCOption NONE (MBC.fromString (A "\\^$"));
        ()
      )

  fun testFromString0102 () =
      ( (* safe cases: invalid escape sequence in the mid of string. *)
        assertEqualMBCOption (SOME(C #"a")) (MBC.fromString (A "abc\\q"));
        assertEqualMBCOption (SOME(C #"a")) (MBC.fromString (A "abc\\qdef"));
        ()
      )

  fun testFromString0103 () =
      ( (* error cases: sequences which fromCString considers as escape
         * sequences, but invalid for fromString. *)
        assertEqualMBCOption NONE (MBC.fromString (A "\\xFF"));
        assertEqualMBCOption NONE (MBC.fromString (A "\\?"));
        assertEqualMBCOption NONE (MBC.fromString (A "\\'"));
        ()
      )

  (********************)

  fun testFromCString0001 () =
      ( (* safe cases: normal strings *)
        assertEqualMBCOption NONE (MBC.fromCString (A ""));
        assertEqualMBCOption (SOME(C #"a")) (MBC.fromCString (A "a"));
        assertEqualMBCOption (SOME(C #"a")) (MBC.fromCString (A "ab"));
        assertEqualMBCOption (SOME(C #"a")) (MBC.fromCString (A "abc"));
        ()
      )

  fun testFromCString0002 () =
      ( (* safe cases: valid escape sequence *)
        assertEqualMBCOption (SOME(C #"\a")) (MBC.fromCString (A "\\a"));
        assertEqualMBCOption (SOME(C #"\b")) (MBC.fromCString (A "\\b"));
        assertEqualMBCOption (SOME(C #"\t")) (MBC.fromCString (A "\\t"));
        assertEqualMBCOption (SOME(C #"\n")) (MBC.fromCString (A "\\n"));
        assertEqualMBCOption (SOME(C #"\v")) (MBC.fromCString (A "\\v"));
        assertEqualMBCOption (SOME(C #"\f")) (MBC.fromCString (A "\\f"));
        assertEqualMBCOption (SOME(C #"\r")) (MBC.fromCString (A "\\r"));
        assertEqualMBCOption (SOME(C #"?")) (MBC.fromCString (A "\\?"));
        assertEqualMBCOption (SOME(C #"\\")) (MBC.fromCString (A "\\\\"));
        assertEqualMBCOption (SOME(C #"\"")) (MBC.fromCString (A "\\\""));
        assertEqualMBCOption (SOME(C #"'")) (MBC.fromCString (A "\\'"));
        (* NOTE: SML/NJ 0.72 does not consider "\\^c" as a valid escape
         * sequence. The following two assertions will fail therefore. *)
        assertEqualMBCOption (SOME(C #"\000")) (MBC.fromCString (A "\\^@"));
        assertEqualMBCOption (SOME(C #"\031")) (MBC.fromCString (A "\\^_"));
        assertEqualMBCOption (SOME(C #"\001")) (MBC.fromCString (A "\\001"));
        assertEqualMBCOption (SOME(C #"\255")) (MBC.fromCString (A "\\xFF"));
        ()
      )

  fun testFromCString0101 () =
      ( (* error cases: invalid escape sequence at the beginning of string. *)
        assertEqualMBCOption NONE (MBC.fromCString (A "\\q"));
        assertEqualMBCOption NONE (MBC.fromCString (A "\\qABC"));
        assertEqualMBCOption NONE (MBC.fromCString (A "\\ \\"));
        assertEqualMBCOption NONE (MBC.fromCString (A "\\ \\\^D"));
        assertEqualMBCOption NONE (MBC.fromCString (A "\\ a"));
        assertEqualMBCOption NONE (MBC.fromCString (A "\\c"));
        assertEqualMBCOption NONE (MBC.fromCString (A "\\^$"));
        ()
      )

  fun testFromCString0102 () =
      ( (* safe cases: invalid escape sequence in the mid of string. *)
        assertEqualMBCOption (SOME(C #"a")) (MBC.fromCString (A "abc\\q"));
        assertEqualMBCOption (SOME(C #"a")) (MBC.fromCString (A "abc\\qdef"));
        ()
      )

  (***************************************************************************)

  fun suite () =
      T.labelTests
      [
(*
        ("testBytesToMBC0001", testBytesToMBC0001),
        ("testBytesSliceToMBC0001", testBytesSliceToMBC0001),
        ("testStringToMBC0001", testStringToMBC0001),
        ("testStringToMBC0002", testStringToMBC0002),
*)
        ("testFromAsciiChar0001", testFromAsciiChar0001),
        ("testFromAsciiChar0002", testFromAsciiChar0002),

        ("testMinChar0001", testMinChar0001),
        ("testMaxChar0001", testMaxChar0001),
        ("testMaxOrd0001", testMaxOrd0001),
        ("testMaxOrdw0001", testMaxOrdw0001),
        ("testMinOrdw0001", testMinOrdw0001),

(*
        ("testMaxSize0001", testMaxSize0001),
*)
        ("testOrd0001", testOrd0001),
        ("testOrdw0001", testOrdw0001),
        ("testChr0001", testChr0001),
        ("testChr0002", testChr0002),
        ("testChrw0001", testChrw0001),
        ("testChrw0002", testChrw0002),
        ("testSucc0001", testSucc0001),
        ("testSucc0002", testSucc0002),
        ("testPred0001", testPred0001),
        ("testPred0002", testPred0002),

        ("testCompare0001", testCompare0001),
        ("testLT0001", testLT0001),
        ("testGT0001", testGT0001),
        ("testLE0001", testLE0001),
        ("testGE0001", testGE0001),

        ("testContains0001", testContains0001),
        ("testNotContains0001", testNotContains0001),

        ("testIsAscii0001", testIsAscii0001),
        ("testToLower0001", testToLower0001),
        ("testToUpper0001", testToUpper0001),
        ("testIsSpace0001", testIsSpace0001),
        ("testIsLower0001", testIsLower0001),
        ("testIsUpper0001", testIsUpper0001),
        ("testIsDigit0001", testIsDigit0001),
        ("testIsAlpha0001", testIsAlpha0001),
        ("testIsHexDigit0001", testIsHexDigit0001),
        ("testIsAlphaNum0001", testIsAlphaNum0001),
        ("testIsPrint0001", testIsPrint0001),
        ("testIsPunct0001", testIsPunct0001),
        ("testIsGraph0001", testIsGraph0001),
        ("testIsCntrl0001", testIsCntrl0001),

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