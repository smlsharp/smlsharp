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
        val () = assertEqualInt 0 size_0
        val size_1 = S.size "a"
        val () = assertEqualInt 1 size_1
        val size_2 = S.size "ab"
        val () = assertEqualInt 2 size_2
      in
        ()
      end

  (********************)
  fun sub0001 () =
      let
        val sub_0_0 = S.sub("", 0) handle Subscript => #"E"
        val () =  assertEqualChar #"E" sub_0_0
        val sub_1_m1 = S.sub("a", ~1) handle Subscript => #"E"
        val () = assertEqualChar #"E" sub_1_m1
        val sub_1_0 = S.sub("a", 0)
        val () = assertEqualChar #"a" sub_1_0
        val sub_1_1 = S.sub("a", 1) handle Subscript => #"E"
        val () = assertEqualChar #"E" sub_1_1
        val sub_2_m1 = S.sub("ab", ~1) handle Subscript => #"E"
        val () = assertEqualChar #"E" sub_2_m1
        val sub_2_0 = S.sub("ab", 0)
        val () = assertEqualChar #"a" sub_2_0
        val sub_2_1 = S.sub("ab", 1)
        val () = assertEqualChar #"b" sub_2_1
        val sub_2_2 = S.sub("ab", 2) handle Subscript => #"E"
        val () = assertEqualChar #"E" sub_2_2
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
        val case_2_m1_N as () = test ("ab", ~1, NONE)
        val case_2_3_N as () = test ("ab", 3, NONE)
        val case_2_m1_0 as () = test ("ab", ~1, SOME 0)
        val case_2_0_m1 as () = test ("ab", ~1, SOME ~1)
        val case_2_1_2 as () = test ("ab", 1, SOME 2)
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
        val case_2_m1_0 as () = test ("ab", ~1, 0)
        val case_2_0_m1 as () = test ("ab", ~1, ~1)
        val case_2_1_2 as () = test ("ab", 1, 2)
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
        val case2_0_0 as () = test ("", "") ""
        val case2_0_1 as () = test ("", "a") "a"
        val case2_1_0 as () = test ("a", "") "a"
        val case2_1_1 as () = test ("a", "b") "ab"
        val case2_1_2 as () = test ("a", "bc") "abc"
        val case2_2_2 as () = test ("ab", "bc") "abbc"
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
        val case_0 as () = test [] ""
        val case_1 as () = test ["ab"] "ab"
        val case_2_diff as () = test ["ab", "a"] "aba"
        val case_2_same as () = test ["ab", "ab"] "abab"
        val case_2_02 as () = test ["", "ab"] "ab"
        val case_2_20 as () = test ["ab", ""] "ab"
        val case_3_202 as () = test ["ab", "", "ab"] "abab"
        val case_3_212 as () = test ["ab", "a", "ab"] "abaab"
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
        val case_0 as () = test "X" [] ""
        val case_1 as () = test "X" ["ab"] "ab"
        val case_2_diff as () = test "X" ["ab", "a"] "abXa"
        val case_2_same as () = test "X" ["ab", "ab"] "abXab"
        val case_2_02 as () = test "X" ["", "ab"] "Xab"
        val case_2_20 as () = test "X" ["ab", ""] "abX"
        val case_3_202 as () = test "X" ["ab", "", "ab"] "abXXab"
        val case_3_212 as () = test "X" ["ab", "a", "ab"] "abXaXab"
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
        val case_a as () = test #"a" "a"
        val case_null as () = test #"\000" "\000"
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
        val case_0 as () = test [] ""
        val case_1 as () = test [#"a"] "a"
        val case_2 as () = test [#"a", #"b"] "ab"
        val case_3 as () = test [#"a", #"b", #"c"] "abc"
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
        val case_0 as () = test "" []
        val case_1 as () = test "a" [#"a"]
        val case_2 as () = test "ab" [#"a", #"b"]
        val case_3 as () = test "abc" [#"a", #"b", #"c"]
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
          val () = assertEqualString expected r
          val () = assertEqualCharList visited (!s)
        in
          ()
        end
  in
  fun map0001 () =
      let
        val case0 as () = test "" "" []
        val case1 as () = test "b" "B" [#"b"]
        val case2 as () = test "bc" "BC" [#"b", #"c"]
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
          val () = assertEqualString expected r
          val () = assertEqualCharList visited (!s)
        in
          ()
        end
  in
  fun translate0001 () =
      let
        val case0 as () = test "" "" []
        val case1 as () = test "b" "bb" [#"b"]
        val case2 as () = test "bc" "bbcc" [#"b", #"c"]
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
          val () = assertEqualStringList expected r
          val () = assertEqualCharList visited (!s)
        in
          ()
        end
  in
  fun tokens0001 () =
      let
        val case_empty as () = test "" [] []
        val case_00 as () = test "|" [] [#"|"]
        val case_01 as () = test "|b" ["b"] [#"|", #"b"]
        val case_10 as () = test "b|" ["b"] [#"b", #"|"]
        val case_11 as () = test "b|c" ["b", "c"] [#"b", #"|", #"c"]
        val case_000 as () = test "||" [] [#"|", #"|"]
        val case_001 as () = test "||b" ["b"] [#"|", #"|", #"b"]
        val case_010 as () = test "|b|" ["b"] [#"|", #"b", #"|"]
        val case_011 as () = test "|b|c" ["b", "c"] [#"|", #"b", #"|", #"c"]
        val case_100 as () = test "b||" ["b"] [#"b", #"|", #"|"]
        val case_101 as () = test "b||c" ["b", "c"] [#"b", #"|", #"|", #"c"]
        val case_110 as () = test "b|c|" ["b", "c"] [#"b", #"|", #"c", #"|"]
        val case_111 as () = test "b|c|d" ["b", "c", "d"] [#"b", #"|", #"c", #"|", #"d"]
        val case_222 as () = test "bc|de|fg" ["bc", "de", "fg"] [#"b", #"c", #"|", #"d", #"e", #"|", #"f", #"g"]
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
          val () = assertEqualStringList expected r
          val () = assertEqualCharList visited (!s)
        in
          ()
        end
  in
  fun fields0001 () =
      let
        val case_empty as () = test "" [""] []
        val case_00 as () = test "|" ["", ""] [#"|"]
        val case_01 as () = test "|b" ["", "b"] [#"|", #"b"]
        val case_10 as () = test "b|" ["b", ""] [#"b", #"|"]
        val case_11 as () = test "b|c" ["b", "c"] [#"b", #"|", #"c"]
        val case_000 as () = test "||" ["", "", ""] [#"|", #"|"]
        val case_001 as () = test "||b" ["", "", "b"] [#"|", #"|", #"b"]
        val case_010 as () = test "|b|" ["", "b", ""] [#"|", #"b", #"|"]
        val case_011 as () = test "|b|c" ["", "b", "c"] [#"|", #"b", #"|", #"c"]
        val case_100 as () = test "b||" ["b", "", ""] [#"b", #"|", #"|"]
        val case_101 as () = test "b||c" ["b", "", "c"] [#"b", #"|", #"|", #"c"]
        val case_110 as () = test "b|c|" ["b", "c", ""] [#"b", #"|", #"c", #"|"]
        val case_111 as () = test "b|c|d" ["b", "c", "d"] [#"b", #"|", #"c", #"|", #"d"]
        val case_222 as () = test "bc|de|fg" ["bc", "de", "fg"] [#"b", #"c", #"|", #"d", #"e", #"|", #"f", #"g"]
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
          val () = assertEqual3Bool expected r
        in
          ()
        end
  in
  fun isContained0001 () =
      let
        val case_0_0 as () = test "" "" (true, true, true)
        val case_1_0 as () = test "a" "" (false, false, false)
        val case_0_1 as () = test "" "b" (true, true, true)
        val case_1_1t as () = test "b" "b" (true, true, true)
        val case_1_1f as () = test "a" "b" (false, false, false)
        val case_1_2t1 as () = test "c" "bc" (false, true, true)
        val case_1_2t2 as () = test "b" "bc" (true, false, true)
        val case_1_2f as () = test "a" "bc" (false, false, false)
        val case_2_2t as () = test "bc" "bc" (true, true, true)
        val case_2_2f as () = test "bd" "bc" (false, false, false)
        val case_2_3t1 as () = test "bc" "bcd" (true, false, true)
        val case_2_3t2 as () = test "cd" "bcd" (false, true, true)
        val case_2_3f as () = test "bd" "bcd" (false, false, false)
        val case_3_3t as () = test "bcd" "bcd" (true, true, true)
        val case_3_3f as () = test "ccd" "bcd" (false, false, false)
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
        val case_0_0 as () = test ("", "") EQUAL
        val case_0_1 as () = test ("", "y") LESS
        val case_1_0 as () = test ("b", "") GREATER
        val case_1_1_lt as () = test ("b", "y") LESS
        val case_1_1_eq as () = test ("b", "b") EQUAL
        val case_1_1_gt as () = test ("y", "b") GREATER
        val case_1_2_lt as () = test ("b", "yz") LESS
        val case_1_2_gt as () = test ("y", "bc") GREATER
        val case_2_1_lt as () = test ("bc", "y") LESS
        val case_2_1_gt as () = test ("bz", "b") GREATER
        val case_2_2_lt as () = test ("bc", "yz") LESS
        val case_2_2_eq as () = test ("bc", "bc") EQUAL
        val case_2_2_gt as () = test ("yz", "bc") GREATER
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
          val () = assertEqualOrder expected r
          val () = assertEqualChar2List visited (!s)
        in
          ()
        end
  in
  fun collate0001 () =
      let
        (* NOTE: character comparison is revered. *)
        val case_0_0 as () = test ("", "") EQUAL []
        val case_0_1 as () = test ("", "y") LESS []
        val case_1_0 as () = test ("b", "") GREATER []
        val case_1_1_lt as () = test ("b", "y") GREATER [(#"b", #"y")]
        val case_1_1_eq as () = test ("b", "b") EQUAL [(#"b", #"b")]
        val case_1_1_gt as () = test ("y", "b") LESS [(#"y", #"b")]
        val case_1_2_lt as () = test ("b", "yz") GREATER [(#"b", #"y")]
        val case_1_2_gt as () = test ("y", "bc") LESS [(#"y", #"b")]
        val case_2_1_lt as () = test ("bc", "y") GREATER [(#"b", #"y")]
        val case_2_1_gt as () = test ("bz", "b") GREATER [(#"b", #"b")]
        val case_2_2_lt as () = test ("bc", "yz") GREATER [(#"b", #"y")]
        val case_2_2_eq as () = test ("bc", "bc") EQUAL [(#"b", #"b"), (#"c", #"c")]
        val case_2_2_gt as () = test ("yz", "bc") LESS [(#"y", #"b")]
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
        val case_0_0 as () = test ("", "") FTTF
        val case_0_1 as () = test ("", "y") TTFF
        val case_1_0 as () = test ("b", "") FFTT
        val case_1_1_lt as () = test ("b", "y") TTFF
        val case_1_1_eq as () = test ("b", "b") FTTF
        val case_1_1_gt as () = test ("y", "b") FFTT
        val case_1_2_lt as () = test ("b", "yz") TTFF
        val case_1_2_gt as () = test ("y", "bc") FFTT
        val case_2_1_lt as () = test ("bc", "y") TTFF
        val case_2_1_gt as () = test ("bz", "b") FFTT
        val case_2_2_lt as () = test ("bc", "yz") TTFF
        val case_2_2_eq as () = test ("bc", "bc") FTTF
        val case_2_2_gt as () = test ("yz", "bc") FFTT
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
        val case_empty as () = test "" (SOME "")
        val case_A as () = test "A" (SOME "A")
        val case_ABC as () = test "ABC" (SOME "ABC")
        val case_alert as () = test "\\a" (SOME "\a")
        val case_backspace as () = test "\\b" (SOME "\b")
        val case_tab as () = test "\\t" (SOME "\t")
        val case_linefeed as () = test "\\n" (SOME "\n")
        val case_vtab as () = test "\\v" (SOME "\v")
        val case_formfeed as () = test "\\f" (SOME "\f")
        val case_return as () = test "\\r" (SOME "\r")
        val case_backslash as () = test "\\\\" (SOME "\\")
        val case_dquote as () = test "\\\"" (SOME "\"")
        val case_ctrl064 as () = test "\\^@" (SOME "\000")
        val case_ctrl095 as () = test "\\^_" (SOME "\031")
        val case_dec000 as () = test "\\000" (SOME "\000")
        val case_dec255 as () = test "\\255" (SOME "\255")
        (*
        val case_hex0000 as () = test "\\u0000"
        val case_hex007e as () = test "\\u007e" (* ~ *)
        val case_hex007E as () = test "\\u007E"
         *)
        val case_multiBySpace as () = test "\\ \\def" (SOME "def")
        val case_multiByTab as () = test "\\\t\\def" (SOME "def")
        val case_multiByNewline as () = test "\\\n\\def" (SOME "def")
        val case_multiByFormfeed as () = test "\\\f\\def" (SOME "def")
        val case_invalidEscape as () = test "\\q" NONE
      in
        ()
      end

  (**
   * test cases from examples in Basis document.
   *)
  fun fromString002 () =
      let
        val case1 as () = test "\\q" NONE
        val case2 as () = test "a\^D" (SOME "a")
        val case3 as () = test "a\\ \\\\q" (SOME "a")
        val case4 as () = test "\\ \\" (SOME "")
        val case5 as () = test "" (SOME "")
        val case6 as () = test "\\ \\\^D" (SOME "")
        val case7 as () = test "\\ a"  NONE
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
        val case_empty as () = test "" (SOME("", []))
        val case_A as () = test "A" (SOME("A", []))
        val case_ABC as () = test "ABC" (SOME("ABC", []))
        val case_alert as () = test "\\a" (SOME("\a", []))
        val case_backspace as () = test "\\b" (SOME("\b", []))
        val case_tab as () = test "\\t" (SOME("\t", []))
        val case_linefeed as () = test "\\n" (SOME("\n", []))
        val case_vtab as () = test "\\v" (SOME("\v", []))
        val case_formfeed as () = test "\\f" (SOME("\f", []))
        val case_return as () = test "\\r" (SOME("\r", []))
        val case_backslash as () = test "\\\\" (SOME("\\", []))
        val case_dquote as () = test "\\\"" (SOME("\"", []))
        val case_ctrl064 as () = test "\\^@" (SOME("\000", []))
        val case_ctrl095 as () = test "\\^_" (SOME("\031", []))
        val case_dec000 as () = test "\\000" (SOME("\000", []))
        val case_dec255 as () = test "\\255" (SOME("\255", []))
        (*
        val case_hex0000 as () = test "\\u0000"
        val case_hex007e as () = test "\\u007e" (* ~ *)
        val case_hex007E as () = test "\\u007E"
         *)
        val case_multiBySpace as () = test "\\ \\def" (SOME("def", []))
        val case_multiByTab as () = test "\\\t\\def" (SOME("def", []))
        val case_multiByNewline as () = test "\\\n\\def" (SOME("def", []))
        val case_multiByFormfeed as () = test "\\\f\\def" (SOME("def", []))
        val case_invalidEscape as () = test "\\q" NONE
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
        val case_A as () = test "A" "A"
        val case_alert as () = test "\a" "\\a"
        val case_backspace as () = test "\b" "\\b"
        val case_tab as () = test "\t" "\\t"
        val case_linefeed as () = test "\n" "\\n"
        val case_vtab as () = test "\v" "\\v"
        val case_formfeed as () = test "\f" "\\f"
        val case_return as () = test "\r" "\\r"
        val case_backslash as () = test "\\" "\\\\"
        val case_dquote as () = test "\"" "\\\""
        val case_ctrl064 as () = test "\^@" "\\^@"
        val case_ctrl095 as () = test "\^_" "\\^_"
        val case_dec000 as () = test "\000" "\\^@"
        val case_dec255 as () = test "\255" "\\255"
        (* SML/NJ does not accept these literal.
        val case_hex0000 as () = test "\u0000"
        val case_hex007e as () = test "\u007e" (* ~ *)
        val case_hex007E as () = test "\u007E"
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
        val case_A as () = test "A" "A"
        val case_alert as () = test "\a" "\\a"
        val case_backspace as () = test "\b" "\\b"
        val case_tab as () = test "\t" "\\t"
        val case_linefeed as () = test "\n" "\\n"
        val case_vtab as () = test "\v" "\\v"
        val case_formfeed as () = test "\f" "\\f"
        val case_return as () = test "\r" "\\r"
        val case_backslash as () = test "\\" "\\\\"
        val case_dquote as () = test "\"" "\\\""
        val case_squote as () = test "'" "\\'"
        val case_question as () = test "?" "\\?"
        val case_ctrl064 as () = test "\^@" "\\000"
        val case_ctrl095 as () = test "\^_" "\\037" (* = 095 - 064 *)
        val case_dec000 as () = test "\000" "\\000"
        val case_dec255 as () = test "\255" "\\377"
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
        val case_empty as () = test "" (SOME "")
        val case_A as () = test "A" (SOME "A") 
        val case_ABC as () = test "ABC" (SOME "ABC") 
        val case_alert as () = test "\\a" (SOME "\a") 
        val case_backspace as () = test "\\b" (SOME "\b") 
        val case_tab as () = test "\\t" (SOME "\t") 
        val case_linefeed as () = test "\\n" (SOME "\n") 
        val case_vtab as () = test "\\v" (SOME "\v") 
        val case_formfeed as () = test "\\f" (SOME "\f") 
        val case_return as () = test "\\r" (SOME "\r") 
        val case_backslash as () = test "\\\\" (SOME "\\") 
        val case_dquote as () = test "\\\"" (SOME "\"") 
        val case_squote as () = test "\\'" (SOME "'") 
        val case_question as () = test "\\?" (SOME "?") 
        val case_ctrl064 as () = test "\\^@" (SOME "\000") 
        val case_ctrl095 as () = test "\\^_" (SOME "\031") (* 95 - 64 *)
        val case_oct000 as () = test "\\000" (SOME "\000") 
        val case_oct101 as () = test "\\101" (* 0x41 = A *) (SOME "\065") 
        val case_hex00 as () = test "\\x00" (SOME "\000") 
        val case_hex7e as () = test "\\x7e" (* ~ *) (SOME "\126") 
        val case_hex7E as () = test "\\x7E" (SOME "\126") 
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
