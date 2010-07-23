(**
 * test cases for String structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure String001 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  structure S = String

  (************************************************************)

  val assertEqual3Bool =
      assertEqual3Tuple (assertEqualBool, assertEqualBool, assertEqualBool)

  val assertEqual4Bool =
      assertEqual4Tuple
          (assertEqualBool, assertEqualBool, assertEqualBool, assertEqualBool)

  val assertEqualChar2List =
      assertEqualList (assertEqual2Tuple (assertEqualChar, assertEqualChar))

  val assertEqualSCListOption =
      assertEqualOption
          (assertEqual2Tuple (assertEqualString, assertEqualCharList))

  (********************)

  fun size0001 () =
      let
        val size_0 = S.size ""
        val _ = assertEqualInt 0 size_0
        val size_1 = S.size "a"
        val _ = assertEqualInt 1 size_1
        val size_2 = S.size "ab"
        val _ = assertEqualInt 2 size_2
      in
        ()
      end

  (********************)

  fun sub0001 () =
      let
        val sub_0_0 = S.sub("", 0) handle Subscript => #"E"
        val _ = assertEqualChar #"E" sub_0_0
        val sub_1_m1 = S.sub("a", ~1) handle Subscript => #"E"
        val _ = assertEqualChar #"E" sub_1_m1
        val sub_1_0 = S.sub("a", 0)
        val _ = assertEqualChar #"a" sub_1_0
        val sub_1_1 = S.sub("a", 1) handle Subscript => #"E"
        val _ = assertEqualChar #"E" sub_1_1
        val sub_2_m1 = S.sub("ab", ~1) handle Subscript => #"E"
        val _ = assertEqualChar #"E" sub_2_m1
        val sub_2_0 = S.sub("ab", 0)
        val _ = assertEqualChar #"a" sub_2_0
        val sub_2_1 = S.sub("ab", 1)
        val _ = assertEqualChar #"b" sub_2_1
        val sub_2_2 = S.sub("ab", 2) handle Subscript => #"E"
        val _ = assertEqualChar #"E" sub_2_2
      in
        ()
      end

  (********************)

  (* safe cases *)
  local
    fun test arg expected = assertEqualString expected (S.extract arg)
  in
  fun extract0001 () =
      let
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
      in
        ()
      end
  end (* local *)

  (* error cases *)
  local
    fun test arg =
        (S.extract arg; fail "Subsctipt expected.")
        handle General.Subscript => ()
  in
  fun extract1001 () =
      let
        val extract_2_m1_N = test ("ab", ~1, NONE)
        val extract_2_3_N = test ("ab", 3, NONE)
        val extract_2_m1_0 = test ("ab", ~1, SOME 0)
        val extract_2_0_m1 = test ("ab", ~1, SOME ~1)
        val extract_2_1_2 = test ("ab", 1, SOME 2)
      in
        ()
      end
  end (* local *)

  (********************)

  (* safe cases *)
  local
    fun test arg expected = assertEqualString expected (S.substring arg)
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
      in
        ()
      end
  end (* local *)
  (* error cases *)
  local
    fun test arg =
        (S.substring arg; fail "Subscript expected.")
        handle General.Subscript => ()
  in
  fun substring1001 () =
      let
        val substring_2_m1_0 = test ("ab", ~1, 0)
        val substring_2_0_m1 = test ("ab", ~1, ~1)
        val substring_2_1_2 = test ("ab", 1, 2)
      in
        ()
      end
  end (* local *)

  (********************)
  local
    fun test arg expected = assertEqualString expected (S.^ arg)
  in
  fun concat2_0001 () =
      let
        val concat2_0_0 = test ("", "") ""
        val concat2_0_1 = test ("", "a") "a"
        val concat2_1_0 = test ("a", "") "a"
        val concat2_1_1 = test ("a", "b") "ab"
        val concat2_1_2 = test ("a", "bc") "abc"
        val concat2_2_2 = test ("ab", "bc") "abbc"
      in
        ()
      end
  end (* local *)

  (********************)
  local
    fun test arg expected = assertEqualString expected (S.concat arg)
  in
  fun concat0001 () =
      let
        val concat_0 = test [] ""
        val concat_1 = test ["ab"] "ab"
        val concat_2_diff = test ["ab", "a"] "aba"
        val concat_2_same = test ["ab", "ab"] "abab"
        val concat_2_02 = test ["", "ab"] "ab"
        val concat_2_20 = test ["ab", ""] "ab"
        val concat_3_202 = test ["ab", "", "ab"] "abab"
        val concat_3_212 = test ["ab", "a", "ab"] "abaab"
      in
        ()
      end
  end (* local *)

  (********************)
  local
    fun test arg1 arg2 expected =
        assertEqualString expected (S.concatWith arg1 arg2)
  in
  fun concatWith0001 () =
      let
        val concatWith_0 = test "X" [] ""
        val concatWith_1 = test "X" ["ab"] "ab"
        val concatWith_2_diff = test "X" ["ab", "a"] "abXa"
        val concatWith_2_same = test "X" ["ab", "ab"] "abXab"
        val concatWith_2_02 = test "X" ["", "ab"] "Xab"
        val concatWith_2_20 = test "X" ["ab", ""] "abX"
        val concatWith_3_202 = test "X" ["ab", "", "ab"] "abXXab"
        val concatWith_3_212 = test "X" ["ab", "a", "ab"] "abXaXab"
      in
        ()
      end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualString expected (S.str arg)
  in
  fun str0001 () =
      let
        val str_a = test #"a" "a"
        val str_null = test #"\000" "\000"
      in
        ()
      end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualString expected (S.implode arg)
  in
  fun implode0001 () =
      let
        val implode_0 = test [] ""
        val implode_1 = test [#"a"] "a"
        val implode_2 = test [#"a", #"b"] "ab"
        val implode_3 = test [#"a", #"b", #"c"] "abc"
      in
        ()
      end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualCharList expected (S.explode arg)
  in
  fun explode0001 () =
      let
        val explode_0 = test "" []
        val explode_1 = test "a" [#"a"]
        val explode_2 = test "ab" [#"a", #"b"]
        val explode_3 = test "abc" [#"a", #"b", #"c"]
      in
        ()
      end
  end (* local *)

  (********************)

  local
    fun makeState () =
        let
          val r = ref []
          fun f ch = (r := !r @ [ch]; Char.toUpper ch)
        in
          (r, f)
        end
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = S.map f arg
          val _ = assertEqualString expected r
          val _ = assertEqualCharList visited (!s)
        in
          ()
        end
  in
  fun map0001 () =
      let
        val map0 = test "" "" []
        val map1 = test "b" "B" [#"b"]
        val map2 = test "bc" "BC" [#"b", #"c"]
      in
        ()
      end
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
          val r = S.translate f arg
          val _ = assertEqualString expected r
          val _ = assertEqualCharList visited (!s)
        in
          ()
        end
  in
  fun translate0001 () =
      let
        val translate0 = test "" "" []
        val translate1 = test "b" "bb" [#"b"]
        val translate2 = test "bc" "bbcc" [#"b", #"c"]
      in
        ()
      end
  end (* local*)

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
          val r = S.tokens f arg
          val _ = assertEqualStringList expected r
          val _ = assertEqualCharList visited (!s)
        in
          ()
        end
  in
  fun tokens0001 () =
      let
        val tokens_empty = test "" [] []
        val tokens_00 = test "|" [] [#"|"]
        val tokens_01 = test "|b" ["b"] [#"|", #"b"]
        val tokens_10 = test "b|" ["b"] [#"b", #"|"]
        val tokens_11 = test "b|c" ["b", "c"] [#"b", #"|", #"c"]
        val tokens_000 = test "||" [] [#"|", #"|"]
        val tokens_001 = test "||b" ["b"] [#"|", #"|", #"b"]
        val tokens_010 = test "|b|" ["b"] [#"|", #"b", #"|"]
        val tokens_011 = test "|b|c" ["b", "c"] [#"|", #"b", #"|", #"c"]
        val tokens_100 = test "b||" ["b"] [#"b", #"|", #"|"]
        val tokens_101 = test "b||c" ["b", "c"] [#"b", #"|", #"|", #"c"]
        val tokens_110 = test "b|c|" ["b", "c"] [#"b", #"|", #"c", #"|"]
        val tokens_111 = test "b|c|d" ["b", "c", "d"] [#"b", #"|", #"c", #"|", #"d"]
        val tokens_222 = test "bc|de|fg" ["bc", "de", "fg"] [#"b", #"c", #"|", #"d", #"e", #"|", #"f", #"g"]
      in
        ()
      end
  end (* inner local *)

  (********************)

  local
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = S.fields f arg
          val _ = assertEqualStringList expected r
          val _ = assertEqualCharList visited (!s)
        in
          ()
        end
  in
  fun fields0001 () =
      let
        val tokens_empty = test "" [""] []
        val tokens_00 = test "|" ["", ""] [#"|"]
        val tokens_01 = test "|b" ["", "b"] [#"|", #"b"]
        val tokens_10 = test "b|" ["b", ""] [#"b", #"|"]
        val tokens_11 = test "b|c" ["b", "c"] [#"b", #"|", #"c"]
        val tokens_000 = test "||" ["", "", ""] [#"|", #"|"]
        val tokens_001 = test "||b" ["", "", "b"] [#"|", #"|", #"b"]
        val tokens_010 = test "|b|" ["", "b", ""] [#"|", #"b", #"|"]
        val tokens_011 = test "|b|c" ["", "b", "c"] [#"|", #"b", #"|", #"c"]
        val tokens_100 = test "b||" ["b", "", ""] [#"b", #"|", #"|"]
        val tokens_101 = test "b||c" ["b", "", "c"] [#"b", #"|", #"|", #"c"]
        val tokens_110 = test "b|c|" ["b", "c", ""] [#"b", #"|", #"c", #"|"]
        val tokens_111 = test "b|c|d" ["b", "c", "d"] [#"b", #"|", #"c", #"|", #"d"]
        val tokens_222 = test "bc|de|fg" ["bc", "de", "fg"] [#"b", #"c", #"|", #"d", #"e", #"|", #"f", #"g"]
      in
        ()
      end
  end (* inner local *)

  end (* outer local *)

  (********************)
  local
    fun test arg1 arg2 expected =
        let
          val r =
              (
                S.isPrefix arg1 arg2,
                S.isSuffix arg1 arg2,
                S.isSubstring arg1 arg2
              )
          val _ = assertEqual3Bool expected r
        in
          ()
        end
  in
  fun isContained0001 () =
      let
        val isContained_0_0 = test "" "" (true, true, true)
        val isContained_1_0 = test "a" "" (false, false, false)
        val isContained_0_1 = test "" "b" (true, true, true)
        val isContained_1_1t = test "b" "b" (true, true, true)
        val isContained_1_1f = test "a" "b" (false, false, false)
        val isContained_1_2t1 = test "c" "bc" (false, true, true)
        val isContained_1_2t2 = test "b" "bc" (true, false, true)
        val isContained_1_2f = test "a" "bc" (false, false, false)
        val isContained_2_2t = test "bc" "bc" (true, true, true)
        val isContained_2_2f = test "bd" "bc" (false, false, false)
        val isContained_2_3t1 = test "bc" "bcd" (true, false, true)
        val isContained_2_3t2 = test "cd" "bcd" (false, true, true)
        val isContained_2_3f = test "bd" "bcd" (false, false, false)
        val isContained_3_3t = test "bcd" "bcd" (true, true, true)
        val isContained_3_3f = test "ccd" "bcd" (false, false, false)
      in
        ()
      end
  end

  (********************)

  local
    fun test arg expected = assertEqualOrder expected (S.compare arg)
  in
  fun compare0001 () =
      let
        val compare_0_0 = test ("", "") EQUAL
        val compare_0_1 = test ("", "y") LESS
        val compare_1_0 = test ("b", "") GREATER
        val compare_1_1_lt = test ("b", "y") LESS
        val compare_1_1_eq = test ("b", "b") EQUAL
        val compare_1_1_gt = test ("y", "b") GREATER
        val compare_1_2_lt = test ("b", "yz") LESS
        val compare_1_2_gt = test ("y", "bc") GREATER
        val compare_2_1_lt = test ("bc", "y") LESS
        val compare_2_1_gt = test ("bz", "b") GREATER
        val compare_2_2_lt = test ("bc", "yz") LESS
        val compare_2_2_eq = test ("bc", "bc") EQUAL
        val compare_2_2_gt = test ("yz", "bc") GREATER
      in
        ()
      end
  end (* local *)

  (********************)

  local
    (* reverse of Char.collate *)
    fun collateFun (left, right : char) =
        if left < right
        then General.GREATER
        else if left = right then General.EQUAL else General.LESS
    fun makeState () =
        let
          val r = ref []
          fun f (ch1, ch2) = (r := !r @ [(ch1, ch2)]; collateFun (ch1, ch2))
        in
          (r, f)
        end
    fun test arg expected visited =
        let
          val (s, f) = makeState ()
          val r = S.collate f arg
          val _ = assertEqualOrder expected r
          val _ = assertEqualChar2List visited (!s)
        in
          ()
        end
  in
  fun collate0001 () =
      let
        (* NOTE: character comparison is revered. *)
        val collate_0_0 = test ("", "") EQUAL []
        val collate_0_1 = test ("", "y") LESS []
        val collate_1_0 = test ("b", "") GREATER []
        val collate_1_1_lt = test ("b", "y") GREATER [(#"b", #"y")]
        val collate_1_1_eq = test ("b", "b") EQUAL [(#"b", #"b")]
        val collate_1_1_gt = test ("y", "b") LESS [(#"y", #"b")]
        val collate_1_2_lt = test ("b", "yz") GREATER [(#"b", #"y")]
        val collate_1_2_gt = test ("y", "bc") LESS [(#"y", #"b")]
        val collate_2_1_lt = test ("bc", "y") GREATER [(#"b", #"y")]
        val collate_2_1_gt = test ("bz", "b") GREATER [(#"b", #"b")]
        val collate_2_2_lt = test ("bc", "yz") GREATER [(#"b", #"y")]
        val collate_2_2_eq = test ("bc", "bc") EQUAL [(#"b", #"b"), (#"c", #"c")]
        val collate_2_2_gt = test ("yz", "bc") LESS [(#"y", #"b")]
      in
        ()
      end
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
        assertEqual4Bool expected (S.< args, S.<= args, S.>= args, S.> args)
  in
  fun binComp0001 () =
      let
        val binComp_0_0 = test ("", "") FTTF
        val binComp_0_1 = test ("", "y") TTFF
        val binComp_1_0 = test ("b", "") FFTT
        val binComp_1_1_lt = test ("b", "y") TTFF
        val binComp_1_1_eq = test ("b", "b") FTTF
        val binComp_1_1_gt = test ("y", "b") FFTT
        val binComp_1_2_lt = test ("b", "yz") TTFF
        val binComp_1_2_gt = test ("y", "bc") FFTT
        val binComp_2_1_lt = test ("bc", "y") TTFF
        val binComp_2_1_gt = test ("bz", "b") FFTT
        val binComp_2_2_lt = test ("bc", "yz") TTFF
        val binComp_2_2_eq = test ("bc", "bc") FTTF
        val binComp_2_2_gt = test ("yz", "bc") FFTT
      in
        ()
      end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqualStringOption expected (String.fromString arg)
  in
  fun fromString001 () =
      let
        val fromString_empty = test "" (SOME "")
        val fromString_A = test "A" (SOME "A")
        val fromString_ABC = test "ABC" (SOME "ABC")
        val fromString_alert = test "\\a" (SOME "\a")
        val fromString_backspace = test "\\b" (SOME "\b")
        val fromString_tab = test "\\t" (SOME "\t")
        val fromString_linefeed = test "\\n" (SOME "\n")
        val fromString_vtab = test "\\v" (SOME "\v")
        val fromString_formfeed = test "\\f" (SOME "\f")
        val fromString_return = test "\\r" (SOME "\r")
        val fromString_backslash = test "\\\\" (SOME "\\")
        val fromString_dquote = test "\\\"" (SOME "\"")
        val fromString_ctrl064 = test "\\^@" (SOME "\000")
        val fromString_ctrl095 = test "\\^_" (SOME "\031")
        val fromString_dec000 = test "\\000" (SOME "\000")
        val fromString_dec255 = test "\\255" (SOME "\255")
        (*
        val fromString_hex0000 = test "\\u0000"
        val fromString_hex007e = test "\\u007e" (* ~ *)
        val fromString_hex007E = test "\\u007E"
         *)
        val fromString_multiBySpace = test "\\ \\def" (SOME "def")
        val fromString_multiByTab = test "\\\t\\def" (SOME "def")
        val fromString_multiByNewline = test "\\\n\\def" (SOME "def")
        val fromString_multiByFormfeed = test "\\\f\\def" (SOME "def")
        val fromString_invalidEscape = test "\\q" NONE
      in
        ()
      end

  (**
   * test cases from examples in Basis document.
   *)
  fun fromString002 () =
      let
        val s1 = test "\\q" NONE
        val s2 = test "a\^D" (SOME "a")
        val s3 = test "a\\ \\\\q" (SOME "a")
        val s4 = test "\\ \\" (SOME "")
        val s5 = test "" (SOME "")
        val s6 = test "\\ \\\^D" (SOME "")
        val s7 = test "\\ a"  NONE
      in
        ()
      end

  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqualSCListOption
            expected
            (String.scan List.getItem (explode arg))
  in
  fun scan001 () =
      let
        val scan_empty = test "" (SOME("", []))
        val scan_A = test "A" (SOME("A", []))
        val scan_ABC = test "ABC" (SOME("ABC", []))
        val scan_alert = test "\\a" (SOME("\a", []))
        val scan_backspace = test "\\b" (SOME("\b", []))
        val scan_tab = test "\\t" (SOME("\t", []))
        val scan_linefeed = test "\\n" (SOME("\n", []))
        val scan_vtab = test "\\v" (SOME("\v", []))
        val scan_formfeed = test "\\f" (SOME("\f", []))
        val scan_return = test "\\r" (SOME("\r", []))
        val scan_backslash = test "\\\\" (SOME("\\", []))
        val scan_dquote = test "\\\"" (SOME("\"", []))
        val scan_ctrl064 = test "\\^@" (SOME("\000", []))
        val scan_ctrl095 = test "\\^_" (SOME("\031", []))
        val scan_dec000 = test "\\000" (SOME("\000", []))
        val scan_dec255 = test "\\255" (SOME("\255", []))
        (*
        val scan_hex0000 = test "\\u0000"
        val scan_hex007e = test "\\u007e" (* ~ *)
        val scan_hex007E = test "\\u007E"
         *)
        val scan_multiBySpace = test "\\ \\def" (SOME("def", []))
        val scan_multiByTab = test "\\\t\\def" (SOME("def", []))
        val scan_multiByNewline = test "\\\n\\def" (SOME("def", []))
        val scan_multiByFormfeed = test "\\\f\\def" (SOME("def", []))
        val scan_invalidEscape = test "\\q" NONE
      in
        ()
      end
  end

  (********************)

  local
    fun test arg expected =
        assertEqualString expected (String.toString arg)
  in
  fun toString001 () =
      let
        val toString_A = test "A" "A"
        val toString_alert = test "\a" "\\a"
        val toString_backspace = test "\b" "\\b"
        val toString_tab = test "\t" "\\t"
        val toString_linefeed = test "\n" "\\n"
        val toString_vtab = test "\v" "\\v"
        val toString_formfeed = test "\f" "\\f"
        val toString_return = test "\r" "\\r"
        val toString_backslash = test "\\" "\\\\"
        val toString_dquote = test "\"" "\\\""
        val toString_ctrl064 = test "\^@" "\\^@"
        val toString_ctrl095 = test "\^_" "\\^_"
        val toString_dec000 = test "\000" "\\^@"
        val toString_dec255 = test "\255" "\\255"
        (* SML/NJ does not accept these literal.
        val toString_hex0000 = test "\u0000"
        val toString_hex007e = test "\u007e" (* ~ *)
        val toString_hex007E = test "\u007E"
         *)
      in
        ()
      end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqualString expected (String.toCString arg)
  in
  fun toCString001 () =
      let
        val toCString_A = test "A" "A"
        val toCString_alert = test "\a" "\\a"
        val toCString_backspace = test "\b" "\\b"
        val toCString_tab = test "\t" "\\t"
        val toCString_linefeed = test "\n" "\\n"
        val toCString_vtab = test "\v" "\\v"
        val toCString_formfeed = test "\f" "\\f"
        val toCString_return = test "\r" "\\r"
        val toCString_backslash = test "\\" "\\\\"
        val toCString_dquote = test "\"" "\\\""
        val toCString_squote = test "'" "\\'"
        val toCString_question = test "?" "\\?"
        val toCString_ctrl064 = test "\^@" "\\000"
        val toCString_ctrl095 = test "\^_" "\\037" (* = 095 - 064 *)
        val toCString_dec000 = test "\000" "\\000"
        val toCString_dec255 = test "\255" "\\377"
      in
        ()
      end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqualStringOption expected (String.fromCString arg)
  in
  fun fromCString001 () =
      let
        val fromCString_empty = test "" (SOME "")
        val fromCString_A = test "A" (SOME "A") 
        val fromCString_ABC = test "ABC" (SOME "ABC") 
        val fromCString_alert = test "\\a" (SOME "\a") 
        val fromCString_backspace = test "\\b" (SOME "\b") 
        val fromCString_tab = test "\\t" (SOME "\t") 
        val fromCString_linefeed = test "\\n" (SOME "\n") 
        val fromCString_vtab = test "\\v" (SOME "\v") 
        val fromCString_formfeed = test "\\f" (SOME "\f") 
        val fromCString_return = test "\\r" (SOME "\r") 
        val fromCString_backslash = test "\\\\" (SOME "\\") 
        val fromCString_dquote = test "\\\"" (SOME "\"") 
        val fromCString_squote = test "\\'" (SOME "'") 
        val fromCString_question = test "\\?" (SOME "?") 
        val fromCString_ctrl064 = test "\\^@" (SOME "\000") 
        val fromCString_ctrl095 = test "\\^_" (SOME "\031") (* 95 - 64 *)
        val fromCString_oct000 = test "\\000" (SOME "\000") 
        val fromCString_oct101 = test "\\101" (* 0x41 = A *) (SOME "\065") 
        val fromCString_hex00 = test "\\x00" (SOME "\000") 
        val fromCString_hex7e = test "\\x7e" (* ~ *) (SOME "\126") 
        val fromCString_hex7E = test "\\x7E" (SOME "\126") 
      in
        ()
      end
  end (* local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("size0001", size0001),
        ("sub0001", sub0001),
        ("extract0001", extract0001),
        ("extract1001", extract1001),
        ("substring0001", substring0001),
        ("substring1001", substring1001),
        ("concat2_0001", concat2_0001),
        ("concat0001", concat0001),
        ("concatWith0001", concatWith0001),
        ("str0001", str0001),
        ("implode0001", implode0001),
        ("explode0001", explode0001),
        ("map0001", map0001),
        ("translate0001", translate0001),
        ("tokens0001", tokens0001),
        ("fields0001", fields0001),
        ("isContained0001", isContained0001),
        ("compare0001", compare0001),
        ("collate0001", collate0001),
        ("binComp0001", binComp0001),
        ("fromString001", fromString001),
        ("scan001", scan001),
        ("toString001", toString001),
        ("toCString001", toCString001),
        ("fromCString001", fromCString001)
      ]

  (************************************************************)

end