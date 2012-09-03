(**
 * test cases for Char structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Char001 =
struct

  (************************************************************)

  structure A = SMLUnit.Assert
  structure T = SMLUnit.Test
  open A

  (************************************************************)

  val assertEqualCCListOption =
      assertEqualOption
          (assertEqual2Tuple (assertEqualChar, assertEqualCharList))

  val assertEqual4Bool =
      assertEqual4Tuple
          (assertEqualBool, assertEqualBool, assertEqualBool, assertEqualBool)

  val assertEqual2Char = assertEqual2Tuple (assertEqualChar, assertEqualChar)

  (****************************************)

  fun minChar001 () =
      let
        val minChar0 = Char.minChar = (Char.chr 0)
        val _ = assertTrue minChar0
      in () end

  (********************)

  fun maxChar001 () =
      let
        val maxChar0 = Char.maxChar = (Char.chr Char.maxOrd)
        val _ = assertTrue maxChar0
      in () end

  (********************)

  fun maxOrd001 () =
      let
        val maxOrd0 = Char.maxOrd = (Char.ord Char.maxChar)
        val _ = assertTrue maxOrd0
      in () end

  (********************)

  fun ord001 () =
      let
        val ord0 = Char.ord #"\000"
        val _ = assertEqualInt 0 ord0
        val ord1 = Char.ord #"\001"
        val _ = assertEqualInt 1 ord1
      in () end

  (********************)

  fun chr001 () =
      let
        val chr064 = Char.chr 64
        val _ = assertEqualChar #"@" chr064

        val chr_minus = (Char.chr ~1) handle General.Chr => #"a"
        val _ = assertEqualChar #"a" chr_minus

        val chr_max = (Char.chr (Char.maxOrd + 1)) handle General.Chr => #"a"
        val _ = assertEqualChar #"a" chr_max
      in () end

  (********************)

  fun succ001 () =
      let
        val succ_A = Char.succ #"A"
        val _ = assertEqualChar #"B" succ_A

        val succ_min = Char.succ Char.minChar
        val _ = assertEqualChar #"\001" succ_min

        val succ_max = (Char.succ Char.maxChar) handle General.Chr => #"a"
        val _ = assertEqualChar #"a" succ_max
      in () end

  (********************)

  fun pred001 () =
      let
        val pred_A = Char.pred #"A"
        val _ = assertEqualChar #"@" pred_A

        val pred_min = (Char.pred Char.minChar) handle General.Chr => #"a"
        val _ = assertEqualChar #"a" pred_min

        val pred_max = Char.pred Char.maxChar
        val _ = assertEqualChar (Char.chr (Char.maxOrd - 1)) pred_max
      in () end

  (********************)

  local
    fun test arg expected =
        assertEqual4Bool
            expected
            (Char.< arg, Char.<= arg, Char.>= arg, Char.> arg)
  in
  fun binComp001 () =
      let
        val lt_lt = test (#"a", #"b") (true, true, false, false)
        val lt_eq = test (#"a", #"a") (false, true, true, false)
        val lt_gt = test (#"b", #"a") (false, false, true, true)
      in () end
  end (* local *)

  (********************)

  fun compare001 () =
      let
        val compare_lt = Char.compare (#"a", #"b")
        val _ = assertEqualOrder LESS compare_lt

        val compare_eq = Char.compare (#"a", #"a")
        val _ = assertEqualOrder EQUAL compare_eq

        val compare_gt = Char.compare (#"b", #"a")
        val _ = assertEqualOrder GREATER compare_gt
      in () end

  (********************)

  local
    fun test arg1 arg2 expected =
        assertEqualBool expected (Char.contains arg1 arg2)
  in
  fun contains001 () =
      let
        val contains_null = test "" #"a" false
        val contains_f = test "x" #"a" false
        val contains_t = test "a" #"a" true
        val contains_ff = test "xy" #"a" false
        val contains_ft = test "xa" #"a" true
        val contains_tf = test "ax" #"a" true
        val contains_ftf = test "xay" #"a" true
        val contains_tft = test "axa" #"a" true
      in () end
  end (* local *)

  (********************)

  local
    fun test arg1 arg2 expected =
        assertEqualBool expected (Char.notContains arg1 arg2)
  in
  fun notContains001 () =
      let
        val notContains_null = test "" #"a" true
        val notContains_f = test "x" #"a" true
        val notContains_t = test "a" #"a" false
        val notContains_ff = test "xy" #"a" true
        val notContains_ft = test "xa" #"a" false
        val notContains_tf = test "ax" #"a" false
        val notContains_ftf = test "xay" #"a" false
        val notContains_tft = test "axa" #"a" false
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqual2Char expected (Char.toLower arg, Char.toUpper arg)
  in
  fun toLowerUpper001 () =
      let
        val toLower_A = test #"A" (#"a", #"A") (* 065 *)
        val toLower_Z = test #"Z" (#"z", #"Z") (* 090 *)
        val toLower_a = test #"a" (#"a", #"A") (* 097 *)
        val toLower_z = test #"z" (#"z", #"Z") (* 122 *)
        val toLower_AT = test #"@" (#"@", #"@") (* @ = 064 *)
        val toLower_LQ = test #"[" (#"[", #"[") (* [ = 091 *)
        val toLower_BQ = test #"`" (#"`", #"`") (* ` = 096 *)
        val toLower_LB = test #"{" (#"{", #"{") (* { = 123 *)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualBool expected (Char.isAlpha arg)
  in
  fun isAlpha001 () =
      let
        val isAlpha_A = test #"A" true (* 065 *)
        val isAlpha_Z = test #"Z" true (* 090 *)
        val isAlpha_a = test #"a" true (* 097 *)
        val isAlpha_z = test #"z" true (* 122 *)
        val isAlpha_0 = test #"0" false 
        val isAlpha_9 = test #"9" false
        val isAlpha_F = test #"F" true
        val isAlpha_AT = test #"@" false (* @ = 064 *)
        val isAlpha_LQ = test #"[" false (* [ = 091 *)
        val isAlpha_BQ = test #"`" false (* ` = 096 *)
        val isAlpha_LB = test #"{" false (* { = 123 *)
      in () end
  end (* local *)

(* ToDo : test of other functions (isALphaNum, isAscii, ...) *)

  (********************)

  local
    fun test arg expected =
        assertEqualCharOption expected (Char.fromString arg)
  in

  fun fromString001 () =
      let
        val fromString_empty = test "" NONE
        val fromString_A = test "A" (SOME #"A") 
        val fromString_ABC = test "ABC" (SOME #"A") 
        val fromString_alert = test "\\a" (SOME #"\a") 
        val fromString_backspace = test "\\b" (SOME #"\b") 
        val fromString_tab = test "\\t" (SOME #"\t") 
        val fromString_linefeed = test "\\n" (SOME #"\n") 
        val fromString_vtab = test "\\v" (SOME #"\v") 
        val fromString_formfeed = test "\\f" (SOME #"\f") 
        val fromString_return = test "\\r" (SOME #"\r") 
        val fromString_backslash = test "\\\\" (SOME #"\\") 
        val fromString_dquote = test "\\\"" (SOME #"\"") 
        val fromString_ctrl064 = test "\\^@" (SOME #"\000") 
        val fromString_ctrl095 = test "\\^_" (SOME #"\031") 
        val fromString_dec000 = test "\\000" (SOME #"\000") 
        val fromString_dec255 = test "\\255" (SOME #"\255") 
        (*
        val fromString_hex0000 = test "\\u0000"
        val fromString_hex007e = test "\\u007e" (* ~ *)
        val fromString_hex007E = test "\\u007E"
         *)
        val fromString_multiBySpace = test "\\ \\def" (SOME #"d") 
        val fromString_multiByTab = test "\\\t\\def" (SOME #"d") 
        val fromString_multiByNewline = test "\\\n\\def" (SOME #"d") 
        val fromString_multiByFormfeed = test "\\\f\\def" (SOME #"d") 
        val fromString_invalidEscape = test "\\q" NONE
      in () end

  (**
   * test cases from examples in Basis document.
   *)
  fun fromString002 () =
      let
        val s1 = test "\\q" NONE
        val s2 = test "a\^D"   (SOME #"a")
        val s3 = test ("a\\ \\\\q") (SOME #"a")
        val s4 = test "\\ \\" NONE
        val s5 = test "" NONE
        val s6 = test "\\ \\\^D" NONE
        val s7 = test "\\ a"  NONE
      in () end

  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqualCCListOption expected (Char.scan List.getItem (explode arg))
  in
  fun scan001 () =
      let
        val scan_empty = test "" NONE 
        val scan_A = test "A" (SOME(#"A", [])) 
        val scan_ABC = test "ABC" (SOME(#"A", [#"B", #"C"])) 
        val scan_alert = test "\\a" (SOME(#"\a", [])) 
        val scan_backspace = test "\\b" (SOME(#"\b", [])) 
        val scan_tab = test "\\t" (SOME(#"\t", [])) 
        val scan_linefeed = test "\\n" (SOME(#"\n", [])) 
        val scan_vtab = test "\\v" (SOME(#"\v", [])) 
        val scan_formfeed = test "\\f" (SOME(#"\f", [])) 
        val scan_return = test "\\r" (SOME(#"\r", [])) 
        val scan_backslash = test "\\\\" (SOME(#"\\", [])) 
        val scan_dquote = test "\\\"" (SOME(#"\"", [])) 
        val scan_ctrl064 = test "\\^@" (SOME(#"\000", [])) 
        val scan_ctrl095 = test "\\^_" (SOME(#"\031", [])) 
        val scan_dec000 = test "\\000" (SOME(#"\000", [])) 
        val scan_dec255 = test "\\255" (SOME(#"\255", [])) 
        (*
        val scan_hex0000 = test "\\u0000"
        val scan_hex007e = test "\\u007e" (* ~ *)
        val scan_hex007E = test "\\u007E"
         *)
        val scan_multiBySpace = test "\\ \\def" (SOME(#"d", [#"e", #"f"])) 
        val scan_multiByTab = test "\\\t\\def" (SOME(#"d", [#"e", #"f"])) 
        val scan_multiByNewline = test "\\\n\\def" (SOME(#"d", [#"e", #"f"])) 
        val scan_multiByFormfeed = test "\\\f\\def" (SOME(#"d", [#"e", #"f"])) 
        val scan_invalidEscape = test "\\q" NONE 
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualString expected (Char.toString arg)
  in
  fun toString001 () =
      let
        val toString_A = test #"A" "A" 
        val toString_alert = test #"\a" "\\a" 
        val toString_backspace = test #"\b" "\\b" 
        val toString_tab = test #"\t" "\\t" 
        val toString_linefeed = test #"\n" "\\n" 
        val toString_vtab = test #"\v" "\\v" 
        val toString_formfeed = test #"\f" "\\f" 
        val toString_return = test #"\r" "\\r" 
        val toString_backslash = test #"\\" "\\\\" 
        val toString_dquote = test #"\"" "\\\"" 
        val toString_ctrl064 = test #"\^@" "\\^@" 
        val toString_ctrl095 = test #"\^_" "\\^_" 
        val toString_dec000 = test #"\000" "\\^@" 
        val toString_dec255 = test #"\255" "\\255" 
        (* SML/NJ does not accept these literal.
        val toString_hex0000 = test #"\u0000"
        val toString_hex007e = test #"\u007e" (* ~ *)
        val toString_hex007E = test #"\u007E"
         *)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualString expected (Char.toCString arg)
  in
  fun toCString001 () =
      let
        val toCString_A = test #"A" "A" 
        val toCString_alert = test #"\a" "\\a" 
        val toCString_backspace = test #"\b" "\\b" 
        val toCString_tab = test #"\t" "\\t" 
        val toCString_linefeed = test #"\n" "\\n" 
        val toCString_vtab = test #"\v" "\\v" 
        val toCString_formfeed = test #"\f" "\\f" 
        val toCString_return = test #"\r" "\\r" 
        val toCString_backslash = test #"\\" "\\\\" 
        val toCString_dquote = test #"\"" "\\\"" 
        val toCString_squote = test #"'" "\\'" 
        val toCString_question = test #"?" "\\?" 
        val toCString_ctrl064 = test #"\^@" "\\000" 
        val toCString_ctrl095 = test #"\^_" "\\037" (* = 095 - 064 *)
        val toCString_dec000 = test #"\000" "\\000" 
        val toCString_dec255 = test #"\255" "\\377" 
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqualCharOption expected (Char.fromCString arg)
  in
  fun fromCString001 () =
      let
        val fromCString_empty = test "" NONE 
        val fromCString_A = test "A" (SOME #"A") 
        val fromCString_ABC = test "ABC" (SOME #"A") 
        val fromCString_alert = test "\\a" (SOME #"\a") 
        val fromCString_backspace = test "\\b" (SOME #"\b") 
        val fromCString_tab = test "\\t" (SOME #"\t") 
        val fromCString_linefeed = test "\\n" (SOME #"\n") 
        val fromCString_vtab = test "\\v" (SOME #"\v") 
        val fromCString_formfeed = test "\\f" (SOME #"\f") 
        val fromCString_return = test "\\r" (SOME #"\r") 
        val fromCString_backslash = test "\\\\" (SOME #"\\") 
        val fromCString_dquote = test "\\\"" (SOME #"\"") 
        val fromCString_squote = test "\\'" (SOME #"'") 
        val fromCString_question = test "\\?" (SOME #"?") 
        val fromCString_ctrl064 = test "\\^@" (SOME #"\000") 
        val fromCString_ctrl095 = test "\\^_" (SOME #"\031") (* 95 - 64 *)
        val fromCString_oct000 = test "\\000" (SOME #"\000") 
        val fromCString_oct101 = test "\\101" (SOME #"\065") (* 0x41 = A *) 
        val fromCString_hex00 = test "\\x00" (SOME #"\000") 
        val fromCString_hex7e = test "\\x7e" (* ~ *) (SOME #"\126") 
        val fromCString_hex7E = test "\\x7E" (SOME #"\126") 
      in () end
  end (* local *)

  (****************************************)

  fun suite () =
      T.labelTests
      [
        ("minChar001", minChar001),
        ("maxChar001", maxChar001),
        ("maxOrd001", maxOrd001),
        ("ord001", ord001),
        ("chr001", chr001),
        ("succ001", succ001),
        ("pred001", pred001),
        ("binComp001", binComp001),
        ("compare001", compare001),
        ("contains001", contains001),
        ("notContains001", notContains001),
        ("toLowerUpper001", toLowerUpper001),
        ("isAplha001", isAlpha001),
        ("fromString001", fromString001),
        ("fromString002", fromString002),
        ("scan001", scan001),
        ("toString001", toString001),
        ("toCString001", toCString001),
        ("fromCString001", fromCString001)
      ]

  (************************************************************)

end