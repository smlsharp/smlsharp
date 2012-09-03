(**
 * test cases of formatters defined in <code>BasicFormatters</code>.
 *
 * <table border=1>
 * <caption>Test cases matrix</caption>
 * <tr><th>case</th><th>value to be formatted</th></tr>
 * <tr><td>FormatUnit0001</td><td>()</td></tr>
 * <tr><td>FormatInt0001</td><td>~123456</td></tr>
 * <tr><td>FormatInt0002</td><td>0</td></tr>
 * <tr><td>FormatInt0003</td><td>123456</td></tr>
 * <tr><td>FormatWord0001</td><td>0w0</td></tr>
 * <tr><td>FormatWord0002</td><td>0wx123456</td></tr>
 * <tr><td>FormatReal0001</td><td>~123.456</td></tr>
 * <tr><td>FormatReal0002</td><td>0.0</td></tr>
 * <tr><td>FormatReal0003</td><td>123.456</td></tr>
 * <tr><td>FormatChar0001</td><td>#"a"</td></tr>
 * <tr><td>FormatString0001</td><td>"abc"</td></tr>
 * <tr><td>FormatString0002</td><td>""</td></tr>
 * <tr><td>FormatString0003</td><td>"a"</td></tr>
 * <tr><td>FormatSubstring0001</td><td>"abc"</td></tr>
 * <tr><td>FormatSubstring0002</td><td>""</td></tr>
 * <tr><td>FormatSubstring0003</td><td>"a"</td></tr>
 * <tr><td>FormatExn0001</td><td>(omitted)</td></tr>
 * <tr><td>FormatArray0001</td><td>["a", "b", "c"]</td></tr>
 * <tr><td>FormatArray0002</td><td>[]</td></tr>
 * <tr><td>FormatArray0003</td><td>["a"]</td></tr>
 * <tr><td>FormatVector0001</td><td>["a", "b", "c"]</td></tr>
 * <tr><td>FormatVector0002</td><td>[]</td></tr>
 * <tr><td>FormatVector0003</td><td>["a"]</td></tr>
 * <tr><td>FormatRef0001</td><td>ref ()</td></tr>
 * <tr><td>FormatBool0001</td><td>true</td></tr>
 * <tr><td>FormatBool0002</td><td>false</td></tr>
 * <tr><td>FormatOption0001</td><td>SOME ()</td></tr>
 * <tr><td>FormatOption0002</td><td>NONE</td></tr>
 * <tr><td>FormatOrder0001</td><td>LESS</td></tr>
 * <tr><td>FormatOrder0002</td><td>EQUAL</td></tr>
 * <tr><td>FormatOrder0003</td><td>GREATER</td></tr>
 * <tr><td>FormatList0001</td><td>["a", "b", "c"]</td></tr>
 * <tr><td>FormatList0002</td><td>[]</td></tr>
 * <tr><td>FormatList0003</td><td>["a"]</td></tr>
 * </table>
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure BasicFormattersTest0001 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test
  structure U = SMLFormatTestUtil

  structure FE = SMLFormat.FormatExpression
  structure FE = SMLFormat.FormatExpression
  structure BF = SMLFormat.BasicFormatters

  (***************************************************************************)

  local
    val TESTFORMATUNIT0001_VALUE = ()
    val TESTFORMATUNIT0001_EXPECTED = [FE.Term(2, "()")]
  in
  fun testFormatUnit0001 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATUNIT0001_EXPECTED
        (BF.format_unit TESTFORMATUNIT0001_VALUE);
        ()
      )
  end

  (********************)

  local
    val TESTFORMATINT0001_VALUE = ~123456
    val TESTFORMATINT0001_EXPECTED = [FE.Term(7, "~123456")]
  in
  fun testFormatInt0001 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATINT0001_EXPECTED
        (BF.format_int TESTFORMATINT0001_VALUE);
        ()
      )
  end

  local
    val TESTFORMATINT0002_VALUE = 0
    val TESTFORMATINT0002_EXPECTED = [FE.Term(1, "0")]
  in
  fun testFormatInt0002 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATINT0002_EXPECTED
        (BF.format_int TESTFORMATINT0002_VALUE);
        ()
      )
  end

  local
    val TESTFORMATINT0003_VALUE = 123456
    val TESTFORMATINT0003_EXPECTED = [FE.Term(6, "123456")]
  in
  fun testFormatInt0003 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATINT0003_EXPECTED
        (BF.format_int TESTFORMATINT0003_VALUE);
        ()
      )
  end

  (********************)

  local
    val TESTFORMATWORD0001_VALUE = 0w0
    val TESTFORMATWORD0001_EXPECTED = [FE.Term(3, "0x0")]
  in
  fun testFormatWord0001 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATWORD0001_EXPECTED
        (BF.format_word TESTFORMATWORD0001_VALUE);
        ()
      )
  end

  local
    val TESTFORMATWORD0002_VALUE = 0wx123456
    val TESTFORMATWORD0002_EXPECTED = [FE.Term(8, "0x123456")]
  in
  fun testFormatWord0002 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATWORD0002_EXPECTED
        (BF.format_word TESTFORMATWORD0002_VALUE);
        ()
      )
  end

  (********************)

  local
    val TESTFORMATREAL0001_VALUE = ~123.456
    val TESTFORMATREAL0001_EXPECTED = [FE.Term(8, "~123.456")]
  in
  fun testFormatReal0001 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATREAL0001_EXPECTED
        (BF.format_real TESTFORMATREAL0001_VALUE);
        ()
      )
  end

  local
    val TESTFORMATREAL0002_VALUE = 0.0
    val TESTFORMATREAL0002_EXPECTED = [FE.Term(3, "0.0")]
  in
  fun testFormatReal0002 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATREAL0002_EXPECTED
        (BF.format_real TESTFORMATREAL0002_VALUE);
        ()
      )
  end

  local
    val TESTFORMATREAL0003_VALUE = 123.456
    val TESTFORMATREAL0003_EXPECTED = [FE.Term(7, "123.456")]
  in
  fun testFormatReal0003 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATREAL0003_EXPECTED
        (BF.format_real TESTFORMATREAL0003_VALUE);
        ()
      )
  end

  (********************)

  local
    val TESTFORMATCHAR0001_VALUE = #"a"
    val TESTFORMATCHAR0001_EXPECTED = [FE.Term(1, "a")]
  in
  fun testFormatChar0001 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATCHAR0001_EXPECTED
        (BF.format_char TESTFORMATCHAR0001_VALUE);
        ()
      )
  end

  (********************)

  local
    val TESTFORMATSTRING0001_VALUE = "abc"
    val TESTFORMATSTRING0001_EXPECTED = [FE.Term(3, "abc")]
  in
  fun testFormatString0001 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATSTRING0001_EXPECTED
        (BF.format_string TESTFORMATSTRING0001_VALUE);
        ()
      )
  end

  local
    val TESTFORMATSTRING0002_VALUE = ""
    val TESTFORMATSTRING0002_EXPECTED = [FE.Term(0, "")]
  in
  fun testFormatString0002 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATSTRING0002_EXPECTED
        (BF.format_string TESTFORMATSTRING0002_VALUE);
        ()
      )
  end

  local
    val TESTFORMATSTRING0003_VALUE = "a"
    val TESTFORMATSTRING0003_EXPECTED = [FE.Term(1, "a")]
  in
  fun testFormatString0003 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATSTRING0003_EXPECTED
        (BF.format_string TESTFORMATSTRING0003_VALUE);
        ()
      )
  end

  (********************)

  local
    val TESTFORMATSUBSTRING0001_VALUE = Substring.full "abc"
    val TESTFORMATSUBSTRING0001_EXPECTED = [FE.Term(3, "abc")]
  in
  fun testFormatSubstring0001 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATSUBSTRING0001_EXPECTED
        (BF.format_substring TESTFORMATSUBSTRING0001_VALUE);
        ()
      )
  end

  local
    val TESTFORMATSUBSTRING0002_VALUE = Substring.full ""
    val TESTFORMATSUBSTRING0002_EXPECTED = [FE.Term(0, "")]
  in
  fun testFormatSubstring0002 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATSUBSTRING0002_EXPECTED
        (BF.format_substring TESTFORMATSUBSTRING0002_VALUE);
        ()
      )
  end

  local
    val TESTFORMATSUBSTRING0003_VALUE = Substring.full "a"
    val TESTFORMATSUBSTRING0003_EXPECTED = [FE.Term(1, "a")]
  in
  fun testFormatSubstring0003 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATSUBSTRING0003_EXPECTED
        (BF.format_substring TESTFORMATSUBSTRING0003_VALUE);
        ()
      )
  end

  (********************)

  local
    val TESTFORMATARRAY0001_VALUE = Array.fromList ["a", "b", "c"]
    val TESTFORMATARRAY0001_EXPECTED =
        [
          FE.Term(1, "a"),
          FE.Term(1, ":"),
          FE.Term(1, "b"),
          FE.Term(1, ":"),
          FE.Term(1, "c")
        ]
  in
  fun testFormatArray0001 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATARRAY0001_EXPECTED
        (BF.format_array
             (BF.format_string, [FE.Term(1, ":")])
             TESTFORMATARRAY0001_VALUE);
        ()
      )
  end

  local
    val TESTFORMATARRAY0002_VALUE = Array.fromList []
    val TESTFORMATARRAY0002_EXPECTED = []
  in
  fun testFormatArray0002 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATARRAY0002_EXPECTED
        (BF.format_array
             (BF.format_string, [FE.Term(1, ":")])
             TESTFORMATARRAY0002_VALUE);
        ()
      )
  end

  local
    val TESTFORMATARRAY0003_VALUE = Array.fromList ["a"]
    val TESTFORMATARRAY0003_EXPECTED = [FE.Term(1, "a")]
  in
  fun testFormatArray0003 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATARRAY0003_EXPECTED
        (BF.format_array
             (BF.format_string, [FE.Term(1, ":")])
             TESTFORMATARRAY0003_VALUE);
        ()
      )
  end

  (********************)

  local
    val TESTFORMATVECTOR0001_VALUE = Vector.fromList ["a", "b", "c"]
    val TESTFORMATVECTOR0001_EXPECTED =
        [
          FE.Term(1, "a"),
          FE.Term(1, ":"),
          FE.Term(1, "b"),
          FE.Term(1, ":"),
          FE.Term(1, "c")
        ]
  in
  fun testFormatVector0001 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATVECTOR0001_EXPECTED
        (BF.format_vector
             (BF.format_string, [FE.Term(1, ":")])
             TESTFORMATVECTOR0001_VALUE);
        ()
      )
  end

  local
    val TESTFORMATVECTOR0002_VALUE = Vector.fromList []
    val TESTFORMATVECTOR0002_EXPECTED = []
  in
  fun testFormatVector0002 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATVECTOR0002_EXPECTED
        (BF.format_vector
             (BF.format_string, [FE.Term(1, ":")])
             TESTFORMATVECTOR0002_VALUE);
        ()
      )
  end

  local
    val TESTFORMATVECTOR0003_VALUE = Vector.fromList ["a"]
    val TESTFORMATVECTOR0003_EXPECTED = [FE.Term(1, "a")]
  in
  fun testFormatVector0003 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATVECTOR0003_EXPECTED
        (BF.format_vector
             (BF.format_string, [FE.Term(1, ":")])
             TESTFORMATVECTOR0003_VALUE);
        ()
      )
  end

  (********************)

  local
    val TESTFORMATREF0001_VALUE = ref ()
    val TESTFORMATREF0001_EXPECTED = [FE.Term(2, "()")]
  in
  fun testFormatRef0001 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATREF0001_EXPECTED
        (BF.format_ref BF.format_unit TESTFORMATREF0001_VALUE);
        ()
      )
  end

  (********************)

  local
    val TESTFORMATBOOL0001_VALUE = true
    val TESTFORMATBOOL0001_EXPECTED = [FE.Term(4, "true")]
  in
  fun testFormatBool0001 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATBOOL0001_EXPECTED
        (BF.format_bool TESTFORMATBOOL0001_VALUE);
        ()
      )
  end

  local
    val TESTFORMATBOOL0002_VALUE = false
    val TESTFORMATBOOL0002_EXPECTED = [FE.Term(5, "false")]
  in
  fun testFormatBool0002 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATBOOL0002_EXPECTED
        (BF.format_bool TESTFORMATBOOL0002_VALUE);
        ()
      )
  end

  (********************)

  local
    val TESTFORMATOPTION0001_VALUE = SOME ()
    val TESTFORMATOPTION0001_EXPECTED = [FE.Term(2, "()")]
  in
  fun testFormatOption0001 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATOPTION0001_EXPECTED
        (BF.format_option BF.format_unit TESTFORMATOPTION0001_VALUE);
        ()
      )
  end

  local
    val TESTFORMATOPTION0002_VALUE = NONE
    val TESTFORMATOPTION0002_EXPECTED = [FE.Term(0, "")]
  in
  fun testFormatOption0002 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATOPTION0002_EXPECTED
        (BF.format_option BF.format_unit TESTFORMATOPTION0002_VALUE);
        ()
      )
  end

  (********************)

  local
    val TESTFORMATORDER0001_VALUE = LESS
    val TESTFORMATORDER0001_EXPECTED = [FE.Term(4, "LESS")]
  in
  fun testFormatOrder0001 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATORDER0001_EXPECTED
        (BF.format_order TESTFORMATORDER0001_VALUE);
        ()
      )
  end

  local
    val TESTFORMATORDER0002_VALUE = EQUAL
    val TESTFORMATORDER0002_EXPECTED = [FE.Term(5, "EQUAL")]
  in
  fun testFormatOrder0002 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATORDER0002_EXPECTED
        (BF.format_order TESTFORMATORDER0002_VALUE);
        ()
      )
  end

  local
    val TESTFORMATORDER0003_VALUE = GREATER
    val TESTFORMATORDER0003_EXPECTED = [FE.Term(7, "GREATER")]
  in
  fun testFormatOrder0003 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATORDER0003_EXPECTED
        (BF.format_order TESTFORMATORDER0003_VALUE);
        ()
      )
  end

  (********************)

  local
    val TESTFORMATLIST0001_VALUE = ["a", "b", "c"]
    val TESTFORMATLIST0001_EXPECTED =
        [
          FE.Term(1, "a"),
          FE.Term(1, ":"),
          FE.Term(1, "b"),
          FE.Term(1, ":"),
          FE.Term(1, "c")
        ]
  in
  fun testFormatList0001 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATLIST0001_EXPECTED
        (BF.format_list
             (BF.format_string, [FE.Term(1, ":")])
             TESTFORMATLIST0001_VALUE);
        ()
      )
  end

  local
    val TESTFORMATLIST0002_VALUE = []
    val TESTFORMATLIST0002_EXPECTED = []
  in
  fun testFormatList0002 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATLIST0002_EXPECTED
        (BF.format_list
             (BF.format_string, [FE.Term(1, ":")])
             TESTFORMATLIST0002_VALUE);
        ()
      )
  end

  local
    val TESTFORMATLIST0003_VALUE = ["a"]
    val TESTFORMATLIST0003_EXPECTED = [FE.Term(1, "a")]
  in
  fun testFormatList0003 () =
      (
        U.assertEqualFormatExpressionList
        TESTFORMATLIST0003_EXPECTED
        (BF.format_list
             (BF.format_string, [FE.Term(1, ":")])
             TESTFORMATLIST0003_VALUE);
        ()
      )
  end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testFormatUnit0001", testFormatUnit0001),

        ("testFormatInt0001", testFormatInt0001),
        ("testFormatInt0002", testFormatInt0002),
        ("testFormatInt0003", testFormatInt0003),

        ("testFormatWord0001", testFormatWord0001),
        ("testFormatWord0002", testFormatWord0002),

        ("testFormatReal0001", testFormatReal0001),
        ("testFormatReal0002", testFormatReal0002),
        ("testFormatReal0003", testFormatReal0003),

        ("testFormatChar0001", testFormatChar0001),

        ("testFormatString0001", testFormatString0001),
        ("testFormatString0002", testFormatString0002),
        ("testFormatString0003", testFormatString0003),

        ("testFormatSubstring0001", testFormatSubstring0001),
        ("testFormatSubstring0002", testFormatSubstring0002),
        ("testFormatSubstring0003", testFormatSubstring0003),

        ("testFormatArray0001", testFormatArray0001),
        ("testFormatArray0002", testFormatArray0002),
        ("testFormatArray0003", testFormatArray0003),

        ("testFormatVector0001", testFormatVector0001),
        ("testFormatVector0002", testFormatVector0002),
        ("testFormatVector0003", testFormatVector0003),

        ("testFormatRef0001", testFormatRef0001),

        ("testFormatBool0001", testFormatBool0001),
        ("testFormatBool0002", testFormatBool0002),

        ("testFormatOption0001", testFormatOption0001),
        ("testFormatOption0002", testFormatOption0002),

        ("testFormatOrder0001", testFormatOrder0001),
        ("testFormatOrder0002", testFormatOrder0002),
        ("testFormatOrder0003", testFormatOrder0003),

        ("testFormatList0001", testFormatList0001),
        ("testFormatList0002", testFormatList0002),
        ("testFormatList0003", testFormatList0003)
      ]

  (***************************************************************************)

end