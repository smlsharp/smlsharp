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
        val () = assertTrue minChar0
      in () end

  (********************)

  fun maxChar001 () =
      let
        val maxChar0 = Char.maxChar = (Char.chr Char.maxOrd)
        val () = assertTrue maxChar0
      in () end

  (********************)

  fun maxOrd001 () =
      let
        val maxOrd0 = Char.maxOrd = (Char.ord Char.maxChar)
        val () = assertTrue maxOrd0
      in () end

  (********************)

  fun ord001 () =
      let
        val ord0 = Char.ord #"\000"
        val () = assertEqualInt 0 ord0
        val ord1 = Char.ord #"\001"
        val () = assertEqualInt 1 ord1
      in () end

  (********************)

  fun chr001 () =
      let
        val chr064 = Char.chr 64
        val () = assertEqualChar #"@" chr064

        val chr_minus = (Char.chr ~1) handle General.Chr => #"a"
        val () = assertEqualChar #"a" chr_minus

        val chr_max = (Char.chr (Char.maxOrd + 1)) handle General.Chr => #"a"
        val () = assertEqualChar #"a" chr_max
      in () end

  (********************)

  fun succ001 () =
      let
        val succ_A = Char.succ #"A"
        val () = assertEqualChar #"B" succ_A

        val succ_min = Char.succ Char.minChar
        val () = assertEqualChar #"\001" succ_min

        val succ_max = (Char.succ Char.maxChar) handle General.Chr => #"a"
        val () = assertEqualChar #"a" succ_max
      in () end

  (********************)

  fun pred001 () =
      let
        val pred_A = Char.pred #"A"
        val () = assertEqualChar #"@" pred_A

        val pred_min = (Char.pred Char.minChar) handle General.Chr => #"a"
        val () = assertEqualChar #"a" pred_min

        val pred_max = Char.pred Char.maxChar
        val () = assertEqualChar (Char.chr (Char.maxOrd - 1)) pred_max
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
        val case_lt as () = test (#"a", #"b") TTFF
        val case_eq as () = test (#"a", #"a") FTTF
        val case_gt as () = test (#"b", #"a") FFTT
      in () end
  end (* local *)

  (********************)

  fun compare001 () =
      let
        val compare_lt = Char.compare (#"a", #"b")
        val () = assertEqualOrder LESS compare_lt

        val compare_eq = Char.compare (#"a", #"a")
        val () = assertEqualOrder EQUAL compare_eq

        val compare_gt = Char.compare (#"b", #"a")
        val () = assertEqualOrder GREATER compare_gt
      in () end

  (********************)

  local
    fun test arg1 arg2 expected =
        assertEqualBool expected (Char.contains arg1 arg2)
  in
  fun contains001 () =
      let
        val case_null as () = test "" #"a" false
        val case_f as () = test "x" #"a" false
        val case_t as () = test "a" #"a" true
        val case_ff as () = test "xy" #"a" false
        val case_ft as () = test "xa" #"a" true
        val case_tf as () = test "ax" #"a" true
        val case_ftf as () = test "xay" #"a" true
        val case_tft as () = test "axa" #"a" true
      in () end
  end (* local *)

  (********************)

  local
    fun test arg1 arg2 expected =
        assertEqualBool expected (Char.notContains arg1 arg2)
  in
  fun notContains001 () =
      let
        val case_null as () = test "" #"a" true
        val case_f as () = test "x" #"a" true
        val case_t as () = test "a" #"a" false
        val case_ff as () = test "xy" #"a" true
        val case_ft as () = test "xa" #"a" false
        val case_tf as () = test "ax" #"a" false
        val case_ftf as () = test "xay" #"a" false
        val case_tft as () = test "axa" #"a" false
      in () end
  end (* local *)

  (********************)

  local fun test arg expected = assertEqualBool expected (Char.isAscii arg)
  in
  fun isAscii001 () =
      let
        val case_Chr0 as () = test (Char.chr 0) true
        val case_Chr127 as () = test (Char.chr 127) true
        val case_Chr128 as () = test (Char.chr 128) false
        val case_Chr255 as () = test (Char.chr 255) false
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqual2Char expected (Char.toLower arg, Char.toUpper arg)
  in
  fun toLowerUpper001 () =
      let
        val case_A as () = test #"A" (#"a", #"A") (* 065 *)
        val case_Z as () = test #"Z" (#"z", #"Z") (* 090 *)
        val case_a as () = test #"a" (#"a", #"A") (* 097 *)
        val case_z as () = test #"z" (#"z", #"Z") (* 122 *)
        val case_AT as () = test #"@" (#"@", #"@") (* @ = 064 *)
        val case_LQ as () = test #"[" (#"[", #"[") (* [ = 091 *)
        val case_BQ as () = test #"`" (#"`", #"`") (* ` = 096 *)
        val case_LB as () = test #"{" (#"{", #"{") (* { = 123 *)
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
        val case_A as () = test #"A" TTFT (* 065 *)
        val case_Z as () = test #"Z" TTFF (* 090 *)
        val case_a as () = test #"a" TTFT (* 097 *)
        val case_z as () = test #"z" TTFF (* 122 *)
        val case_0 as () = test #"0" FTTT
        val case_9 as () = test #"9" FTTT
        val case_F as () = test #"F" TTFT
        val case_AT as () = test #"@" FFFF (* @ = 064 *)
        val case_LQ as () = test #"[" FFFF (* [ = 091 *)
        val case_BQ as () = test #"`" FFFF (* ` = 096 *)
        val case_LB as () = test #"{" FFFF (* { = 123 *)
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
        val case_ascii000 as () = test #"\000" TFFFF (* '^@' *)
        val case_ascii009 as () = test #"\009" TFFTF (* '\t' *)
        val case_ascii010 as () = test #"\010" TFFTF (* '\n' *)
        val case_ascii011 as () = test #"\011" TFFTF (* '\v' *)
        val case_ascii012 as () = test #"\012" TFFTF (* '\f' *)
        val case_ascii013 as () = test #"\013" TFFTF (* '\r' *)
        val case_ascii014 as () = test #"\014" TFFFF (* '^N' *)
        val case_ascii031 as () = test #"\031" TFFFF (* '^_' *)
        val case_ascii032 as () = test #"\032" FFTTF (* ' ' *)
        val case_ascii033 as () = test #"\033" FTTFT (* '!' *)
        val case_ascii047 as () = test #"\047" FTTFT (* '/' *)
        val case_ascii048 as () = test #"\048" FTTFF (* '0' *)
        val case_ascii057 as () = test #"\057" FTTFF (* '9' *)
        val case_ascii058 as () = test #"\058" FTTFT (* ':' *)
        val case_ascii064 as () = test #"\064" FTTFT (* '@' *)
        val case_ascii065 as () = test #"\065" FTTFF (* 'A' *)
        val case_ascii090 as () = test #"\090" FTTFF (* 'Z' *)
        val case_ascii091 as () = test #"\091" FTTFT (* '[' *)
        val case_ascii096 as () = test #"\096" FTTFT (* '`' *)
        val case_ascii097 as () = test #"\097" FTTFF (* 'a' *)
        val case_ascii122 as () = test #"\122" FTTFF (* 'z' *)
        val case_ascii123 as () = test #"\123" FTTFT (* '{' *)
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
        val case_A as () = test #"A" FT (* 065 *)
        val case_Z as () = test #"Z" FT (* 090 *)
        val case_a as () = test #"a" TF (* 097 *)
        val case_z as () = test #"z" TF (* 122 *)
        val case_0 as () = test #"0" FF (* 048 *)
        val case_9 as () = test #"9" FF (* 057 *)
        val case_AT as () = test #"@" FF (* @ = 064 *)
        val case_LQ as () = test #"[" FF (* [ = 091 *)
        val case_BQ as () = test #"`" FF (* ` = 096 *)
        val case_LB as () = test #"{" FF (* { = 123 *)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqualCharOption expected (Char.fromString arg)
  in

  fun fromString001 () =
      let
        val case_empty as () = test "" NONE
        val case_A as () = test "A" (SOME #"A") 
        val case_ABC as () = test "ABC" (SOME #"A") 
        val case_alert as () = test "\\a" (SOME #"\a") 
        val case_backspace as () = test "\\b" (SOME #"\b") 
        val case_tab as () = test "\\t" (SOME #"\t") 
        val case_linefeed as () = test "\\n" (SOME #"\n") 
        val case_vtab as () = test "\\v" (SOME #"\v") 
        val case_formfeed as () = test "\\f" (SOME #"\f") 
        val case_return as () = test "\\r" (SOME #"\r") 
        val case_backslash as () = test "\\\\" (SOME #"\\") 
        val case_dquote as () = test "\\\"" (SOME #"\"") 
        val case_ctrl064 as () = test "\\^@" (SOME #"\000") 
        val case_ctrl095 as () = test "\\^_" (SOME #"\031") 
        val case_dec000 as () = test "\\000" (SOME #"\000") 
        val case_dec255 as () = test "\\255" (SOME #"\255") 
        (*
        val case_hex0000 as () = test "\\u0000"
        val case_hex007e as () = test "\\u007e" (* ~ *)
        val case_hex007E as () = test "\\u007E"
         *)
        val case_multiBySpace as () = test "\\ \\def" (SOME #"d") 
        val case_multiByTab as () = test "\\\t\\def" (SOME #"d") 
        val case_multiByNewline as () = test "\\\n\\def" (SOME #"d") 
        val case_multiByFormfeed as () = test "\\\f\\def" (SOME #"d") 
        val case_invalidEscape as () = test "\\q" NONE
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
        val case_empty as () = test "" NONE 
        val case_A as () = test "A" (SOME(#"A", [])) 
        val case_ABC as () = test "ABC" (SOME(#"A", [#"B", #"C"])) 
        val case_alert as () = test "\\a" (SOME(#"\a", [])) 
        val case_backspace as () = test "\\b" (SOME(#"\b", [])) 
        val case_tab as () = test "\\t" (SOME(#"\t", [])) 
        val case_linefeed as () = test "\\n" (SOME(#"\n", [])) 
        val case_vtab as () = test "\\v" (SOME(#"\v", [])) 
        val case_formfeed as () = test "\\f" (SOME(#"\f", [])) 
        val case_return as () = test "\\r" (SOME(#"\r", [])) 
        val case_backslash as () = test "\\\\" (SOME(#"\\", [])) 
        val case_dquote as () = test "\\\"" (SOME(#"\"", [])) 
        val case_ctrl064 as () = test "\\^@" (SOME(#"\000", [])) 
        val case_ctrl095 as () = test "\\^_" (SOME(#"\031", [])) 
        val case_dec000 as () = test "\\000" (SOME(#"\000", [])) 
        val case_dec255 as () = test "\\255" (SOME(#"\255", [])) 
        (*
        val case_hex0000 as () = test "\\u0000"
        val case_hex007e as () = test "\\u007e" (* ~ *)
        val case_hex007E as () = test "\\u007E"
         *)
        val case_multiBySpace as () = test "\\ \\def" (SOME(#"d", [#"e", #"f"])) 
        val case_multiByTab as () = test "\\\t\\def" (SOME(#"d", [#"e", #"f"])) 
        val case_multiByNewline as () = test "\\\n\\def" (SOME(#"d", [#"e", #"f"])) 
        val case_multiByFormfeed as () = test "\\\f\\def" (SOME(#"d", [#"e", #"f"])) 
        val case_invalidEscape as () = test "\\q" NONE 
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualString expected (Char.toString arg)
  in
  fun toString001 () =
      let
        val case_A as () = test #"A" "A" 
        val case_alert as () = test #"\a" "\\a" 
        val case_backspace as () = test #"\b" "\\b" 
        val case_tab as () = test #"\t" "\\t" 
        val case_linefeed as () = test #"\n" "\\n" 
        val case_vtab as () = test #"\v" "\\v" 
        val case_formfeed as () = test #"\f" "\\f" 
        val case_return as () = test #"\r" "\\r" 
        val case_backslash as () = test #"\\" "\\\\" 
        val case_dquote as () = test #"\"" "\\\"" 
        val case_ctrl064 as () = test #"\^@" "\\^@" 
        val case_ctrl095 as () = test #"\^_" "\\^_" 
        val case_dec000 as () = test #"\000" "\\^@" 
        val case_dec255 as () = test #"\255" "\\255" 
        (* SML/NJ does not accept these literal.
        val case_hex0000 as () = test #"\u0000"
        val case_hex007e as () = test #"\u007e" (* ~ *)
        val case_hex007E as () = test #"\u007E"
         *)
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected = assertEqualString expected (Char.toCString arg)
  in
  fun toCString001 () =
      let
        val case_A as () = test #"A" "A" 
        val case_alert as () = test #"\a" "\\a" 
        val case_backspace as () = test #"\b" "\\b" 
        val case_tab as () = test #"\t" "\\t" 
        val case_linefeed as () = test #"\n" "\\n" 
        val case_vtab as () = test #"\v" "\\v" 
        val case_formfeed as () = test #"\f" "\\f" 
        val case_return as () = test #"\r" "\\r" 
        val case_backslash as () = test #"\\" "\\\\" 
        val case_dquote as () = test #"\"" "\\\"" 
        val case_squote as () = test #"'" "\\'" 
        val case_question as () = test #"?" "\\?" 
        val case_ctrl064 as () = test #"\^@" "\\000" 
        val case_ctrl095 as () = test #"\^_" "\\037" (* = 095 - 064 *)
        val case_dec000 as () = test #"\000" "\\000" 
        val case_dec255 as () = test #"\255" "\\377" 
      in () end
  end (* local *)

  (********************)

  local
    fun test arg expected =
        assertEqualCharOption expected (Char.fromCString arg)
  in
  fun fromCString001 () =
      let
        val case_empty as () = test "" NONE 
        val case_A as () = test "A" (SOME #"A") 
        val case_ABC as () = test "ABC" (SOME #"A") 
        val case_alert as () = test "\\a" (SOME #"\a") 
        val case_backspace as () = test "\\b" (SOME #"\b") 
        val case_tab as () = test "\\t" (SOME #"\t") 
        val case_linefeed as () = test "\\n" (SOME #"\n") 
        val case_vtab as () = test "\\v" (SOME #"\v") 
        val case_formfeed as () = test "\\f" (SOME #"\f") 
        val case_return as () = test "\\r" (SOME #"\r") 
        val case_backslash as () = test "\\\\" (SOME #"\\") 
        val case_dquote as () = test "\\\"" (SOME #"\"") 
        val case_squote as () = test "\\'" (SOME #"'") 
        val case_question as () = test "\\?" (SOME #"?") 
        val case_ctrl064 as () = test "\\^@" (SOME #"\000") 
        val case_ctrl095 as () = test "\\^_" (SOME #"\031") (* 95 - 64 *)
        val case_oct000 as () = test "\\000" (SOME #"\000") 
        val case_oct101 as () = test "\\101" (SOME #"\065") (* 0x41 = A *) 
        val case_hex00 as () = test "\\x00" (SOME #"\000") 
        val case_hex7e as () = test "\\x7e" (* ~ *) (SOME #"\126") 
        val case_hex7E as () = test "\\x7E" (SOME #"\126") 
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