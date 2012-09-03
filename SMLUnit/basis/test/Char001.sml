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

  val assertEqual2Bool = assertEqual2Tuple (assertEqualBool, assertEqualBool)

  val assertEqual4Bool =
      assertEqual4Tuple
          (assertEqualBool, assertEqualBool, assertEqualBool, assertEqualBool)

  val assertEqual5Bool =
      assertEqual5Tuple
          (
            assertEqualBool,
            assertEqualBool,
            assertEqualBool,
            assertEqualBool,
            assertEqualBool
          )

  val assertEqual2Char = assertEqual2Tuple (assertEqualChar, assertEqualChar)

  val TTTT = (true, true, true, true)
  val TTFT = (true, true, false, true)
  val TTFF = (true, true, false, false)
  val TFTF = (true, false, true, false)
  val FTTT = (false, true, true, true)
  val FTTF = (false, true, true, false)
  val FTFF = (false, true, false, false)
  val FFTT = (false, false, true, true)
  val FFFF = (false, false, false, false)

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
        val lt_lt = test (#"a", #"b") TTFF
        val lt_eq = test (#"a", #"a") FTTF
        val lt_gt = test (#"b", #"a") FFTT
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

  local fun test arg expected = assertEqualBool expected (Char.isAscii arg)
  in
  fun isAscii001 () =
      let
        val isAscii_Chr0 = test (Char.chr 0) true
        val isAscii_Chr127 = test (Char.chr 127) true
        val isAscii_Chr128 = test (Char.chr 128) false
        val isAscii_Chr255 = test (Char.chr 255) false
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
    fun test arg expected =
        assertEqual4Bool
            expected
            (
              Char.isAlpha arg,
              Char.isAlphaNum arg,
              Char.isDigit arg,
              Char.isHexDigit arg
            )
  in
  (* classification of alphabet and digit characters.*)
  fun isAlphaDigit001 () =
      let
        val isAlphaDigit_A = test #"A" TTFT (* 065 *)
        val isAlphaDigit_Z = test #"Z" TTFF (* 090 *)
        val isAlphaDigit_a = test #"a" TTFT (* 097 *)
        val isAlphaDigit_z = test #"z" TTFF (* 122 *)
        val isAlphaDigit_0 = test #"0" FTTT
        val isAlphaDigit_9 = test #"9" FTTT
        val isAlphaDigit_F = test #"F" TTFT
        val isAlphaDigit_AT = test #"@" FFFF (* @ = 064 *)
        val isAlphaDigit_LQ = test #"[" FFFF (* [ = 091 *)
        val isAlphaDigit_BQ = test #"`" FFFF (* ` = 096 *)
        val isAlphaDigit_LB = test #"{" FFFF (* { = 123 *)
      in () end
  end (* local *)

  local
    val TFFFF = (true, false, false, false, false)
    val TFFTF = (true, false, false, true, false)
    val TFTTF = (true, false, true, true, false)
    val FFTTF = (false, false, true, true, false)
    val FTTFT = (false, true, true, false, true)
    val FTTFF = (false, true, true, false, false)
    fun test arg expected =
        assertEqual5Bool
            expected
            (
              Char.isCntrl arg,
              Char.isGraph arg, (* isPrint && not isSpace *)
              Char.isPrint arg, (* not isCntrl *)
              Char.isSpace arg,
              Char.isPunct arg  (* isGraph && not isAlphaNum *)
            )
  in
  (* classification of control and space characters.*)
  fun isCntrlSpace001 () =
      let
        val isCntrlSpace_ascii000 = test #"\000" TFFFF (* '^@' *)
        val isCntrlSpace_ascii009 = test #"\009" TFFTF (* '\t' *)
        val isCntrlSpace_ascii010 = test #"\010" TFFTF (* '\n' *)
        val isCntrlSpace_ascii011 = test #"\011" TFFTF (* '\v' *)
        val isCntrlSpace_ascii012 = test #"\012" TFFTF (* '\f' *)
        val isCntrlSpace_ascii013 = test #"\013" TFFTF (* '\r' *)
        val isCntrlSpace_ascii014 = test #"\014" TFFFF (* '^N' *)
        val isCntrlSpace_ascii031 = test #"\031" TFFFF (* '^_' *)
        val isCntrlSpace_ascii032 = test #"\032" FFTTF (* ' ' *)
        val isCntrlSpace_ascii033 = test #"\033" FTTFT (* '!' *)
        val isCntrlSpace_ascii047 = test #"\047" FTTFT (* '/' *)
        val isCntrlSpace_ascii048 = test #"\048" FTTFF (* '0' *)
        val isCntrlSpace_ascii057 = test #"\057" FTTFF (* '9' *)
        val isCntrlSpace_ascii058 = test #"\058" FTTFT (* ':' *)
        val isCntrlSpace_ascii064 = test #"\064" FTTFT (* '@' *)
        val isCntrlSpace_ascii065 = test #"\065" FTTFF (* 'A' *)
        val isCntrlSpace_ascii090 = test #"\090" FTTFF (* 'Z' *)
        val isCntrlSpace_ascii091 = test #"\091" FTTFT (* '[' *)
        val isCntrlSpace_ascii096 = test #"\096" FTTFT (* '`' *)
        val isCntrlSpace_ascii097 = test #"\097" FTTFF (* 'a' *)
        val isCntrlSpace_ascii122 = test #"\122" FTTFF (* 'z' *)
        val isCntrlSpace_ascii123 = test #"\123" FTTFT (* '{' *)
      in () end
  end (* local *)

  local
    val FF = (false, false)
    val FT = (false, true)
    val TF = (true, false)
    fun test arg expected =
        assertEqual2Bool expected (Char.isLower arg, Char.isUpper arg)
  in
  fun isLowerUpper001 () =
      let
        val isLowerUpper_A = test #"A" FT (* 065 *)
        val isLowerUpper_Z = test #"Z" FT (* 090 *)
        val isLowerUpper_a = test #"a" TF (* 097 *)
        val isLowerUpper_z = test #"z" TF (* 122 *)
        val isLowerUpper_0 = test #"0" FF (* 048 *)
        val isLowerUpper_9 = test #"9" FF (* 057 *)
        val isLowerUpper_AT = test #"@" FF (* @ = 064 *)
        val isLowerUpper_LQ = test #"[" FF (* [ = 091 *)
        val isLowerUpper_BQ = test #"`" FF (* ` = 096 *)
        val isLowerUpper_LB = test #"{" FF (* { = 123 *)
      in () end
  end (* local *)

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
        ("isAscii001", isAscii001),
        ("toLowerUpper001", toLowerUpper001),
        ("isAlphaDigit001", isAlphaDigit001),
        ("isCntrlSpace001", isCntrlSpace001),
        ("isLowerUpper001", isLowerUpper001),
        ("fromString001", fromString001),
        ("fromString002", fromString002),
        ("scan001", scan001),
        ("toString001", toString001),
        ("toCString001", toCString001),
        ("fromCString001", fromCString001)
      ]

  (************************************************************)

end