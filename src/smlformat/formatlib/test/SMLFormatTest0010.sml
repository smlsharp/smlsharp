(**
 *  verify the inheritance of associativity when the expressions contains
 * three nested guards.
 * <p>
 *  These cases pretty-print expressions of the form as follows:
 * <pre>
 * <i>c</i>{ <i>d</i>{ <i>e</i>{ ... } } ... <i>d</i>{ <i>e</i>{ ... } } }
 * </pre>
 * <i>c, d, e</i> denotes assoc indicators.
 * </p>
 *
 * <p><b>
 *   variation of cut attribute of assoc indicator of the middle guard:
 * </b></p>
 * <ul>
 *   <li>without cut</li>
 *   <li>with cut</li>
 * </ul>
 *
 * <p><b>variation of strength of assoc indicators:</b></p>
 * <ul>
 *   <li>(1) <i>c</i> &lt; <i>d</i> &lt; <i>e</i></li>
 *   <li>(2) <i>c</i> &lt; <i>e</i> &lt; <i>d</i></li>
 *   <li>(3) <i>d</i> &lt; <i>c</i> &lt; <i>e</i></li>
 *   <li>(4) <i>d</i> &lt; <i>e</i> &lt; <i>c</i></li>
 *   <li>(5) <i>e</i> &lt; <i>c</i> &lt; <i>d</i></li>
 *   <li>(6) <i>e</i> &lt; <i>d</i> &lt; <i>c</i></li>
 *   <li>(7) <i>c</i> &lt; <i>e</i> (the middle guard has no assoc)</li>
 *   <li>(8) <i>e</i> &lt; <i>c</i> (the middle guard has no assoc)</li>
 * </ul>
 *
 * <table border=1>
 * <caption>Test cases matrix</caption>
 * <tr>
 *   <th>case</th>
 *   <th>cut attribute</th>
 *   <th>strength of assoc indicators</th>
 * </tr>
 * <tr><td>0001</td><td rowspan=8>without cut</td><td>1</td></tr>
 * <tr><td>0002</td><td>2</td></tr>
 * <tr><td>0003</td><td>3</td></tr>
 * <tr><td>0004</td><td>4</td></tr>
 * <tr><td>0005</td><td>5</td></tr>
 * <tr><td>0006</td><td>6</td></tr>
 * <tr><td>0007</td><td>7</td></tr>
 * <tr><td>0008</td><td>8</td></tr>
 *
 * <tr><td>0101</td><td rowspan=8>with cut</td><td>1</td></tr>
 * <tr><td>0102</td><td>2</td></tr>
 * <tr><td>0103</td><td>3</td></tr>
 * <tr><td>0104</td><td>4</td></tr>
 * <tr><td>0105</td><td>5</td></tr>
 * <tr><td>0106</td><td>6</td></tr>
 * <tr><td>0107</td><td>7</td></tr>
 * <tr><td>0108</td><td>8</td></tr>
 * </table>
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure SMLFormatTest0010 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure Testee = SMLFormat
  structure FE = Testee.FormatExpression
  structure PP = Testee.PrinterParameter

  (***************************************************************************)

  val TESTASSOC_COLUMNS = 10

  fun prettyPrint expressions =
      SMLFormat.prettyPrint
          [
            SMLFormat.Newline "\n",
            SMLFormat.Space " ",
            SMLFormat.Columns TESTASSOC_COLUMNS
          ]
          expressions

  fun makeExpression
          (outerStrength, middleCutStrengthOpt, innerStrength) =
      let
        val outerAssoc =
            {cut = false, strength = outerStrength, direction = FE.Neutral}
        val middleAssocOpt =
            case middleCutStrengthOpt of
              SOME (middleCut, middleStrength) =>
              SOME
              {
                cut = middleCut,
                strength = middleStrength,
                direction = FE.Neutral
              }
            | NONE => NONE
        val innerAssoc =
            {cut = false, strength = innerStrength, direction = FE.Neutral}
      in
        [FE.Guard
         (
           SOME outerAssoc,
           [
             FE.Guard
             (middleAssocOpt,
              [
                FE.Guard(SOME innerAssoc, [FE.Term(1, "1")]),
                FE.Guard(SOME innerAssoc, [FE.Term(1, "2")]),
                FE.Guard(SOME innerAssoc, [FE.Term(1, "3")])
              ]),
             FE.Guard
             (middleAssocOpt,
              [
                FE.Guard(SOME innerAssoc, [FE.Term(1, "4")]),
                FE.Guard(SOME innerAssoc, [FE.Term(1, "5")]),
                FE.Guard(SOME innerAssoc, [FE.Term(1, "6")])
              ]),
             FE.Guard
             (middleAssocOpt,
              [
                FE.Guard(SOME innerAssoc, [FE.Term(1, "7")]),
                FE.Guard(SOME innerAssoc, [FE.Term(1, "8")]),
                FE.Guard(SOME innerAssoc, [FE.Term(1, "9")])
              ])
           ]
         )]
      end

  fun assertAssoc expected expression =
      (Assert.assertEqualString expected (prettyPrint expression); ())

  (****************************************)

  local
    val TESTASSOC0001_EXPRESSION = makeExpression (0, SOME (false, 5), 10)
    val TESTASSOC0001_EXPECTED = "123456789"
  in
  fun testAssoc0001 () =
      assertAssoc TESTASSOC0001_EXPECTED TESTASSOC0001_EXPRESSION
  end

  local
    val TESTASSOC0002_EXPRESSION = makeExpression (0, SOME (false, 10), 5)
    val TESTASSOC0002_EXPECTED = "(1)(2)(3)(4)(5)(6)(7)(8)(9)"
  in
  fun testAssoc0002 () =
      assertAssoc TESTASSOC0002_EXPECTED TESTASSOC0002_EXPRESSION
  end

  local
    val TESTASSOC0003_EXPRESSION = makeExpression (5, SOME (false, 0), 10)
    val TESTASSOC0003_EXPECTED = "(123)(456)(789)"
  in
  fun testAssoc0003 () =
      assertAssoc TESTASSOC0003_EXPECTED TESTASSOC0003_EXPRESSION
  end

  local
    val TESTASSOC0004_EXPRESSION = makeExpression (10, SOME (false, 0), 5)
    val TESTASSOC0004_EXPECTED = "(123)(456)(789)"
  in
  fun testAssoc0004 () =
      assertAssoc TESTASSOC0004_EXPECTED TESTASSOC0004_EXPRESSION
  end

  local
    val TESTASSOC0005_EXPRESSION = makeExpression (5, SOME (false, 10), 0)
    val TESTASSOC0005_EXPECTED = "(1)(2)(3)(4)(5)(6)(7)(8)(9)"
  in
  fun testAssoc0005 () =
      assertAssoc TESTASSOC0005_EXPECTED TESTASSOC0005_EXPRESSION
  end

  local
    val TESTASSOC0006_EXPRESSION = makeExpression (10, SOME (false, 5), 0)
    val TESTASSOC0006_EXPECTED = "((1)(2)(3))((4)(5)(6))((7)(8)(9))"
  in
  fun testAssoc0006 () =
      assertAssoc TESTASSOC0006_EXPECTED TESTASSOC0006_EXPRESSION
  end

  local
    val TESTASSOC0007_EXPRESSION = makeExpression (0, NONE, 10)
    val TESTASSOC0007_EXPECTED = "123456789"
  in
  fun testAssoc0007 () =
      assertAssoc TESTASSOC0007_EXPECTED TESTASSOC0007_EXPRESSION
  end

  local
    val TESTASSOC0008_EXPRESSION = makeExpression (10, NONE, 0)
    val TESTASSOC0008_EXPECTED = "(1)(2)(3)(4)(5)(6)(7)(8)(9)"
  in
  fun testAssoc0008 () =
      assertAssoc TESTASSOC0008_EXPECTED TESTASSOC0008_EXPRESSION
  end

  (********************)

  local
    val TESTASSOC0101_EXPRESSION = makeExpression (0, SOME (true, 5), 10)
    val TESTASSOC0101_EXPECTED = "123456789"
  in
  fun testAssoc0101 () =
      assertAssoc TESTASSOC0101_EXPECTED TESTASSOC0101_EXPRESSION
  end

  local
    val TESTASSOC0102_EXPRESSION = makeExpression (0, SOME (true, 10), 5)
    val TESTASSOC0102_EXPECTED = "(1)(2)(3)(4)(5)(6)(7)(8)(9)"
  in
  fun testAssoc0102 () =
      assertAssoc TESTASSOC0102_EXPECTED TESTASSOC0102_EXPRESSION
  end

  local
    val TESTASSOC0103_EXPRESSION = makeExpression (5, SOME (true, 0), 10)
    val TESTASSOC0103_EXPECTED = "123456789"
  in
  fun testAssoc0103 () =
      assertAssoc TESTASSOC0103_EXPECTED TESTASSOC0103_EXPRESSION
  end

  local
    val TESTASSOC0104_EXPRESSION = makeExpression (10, SOME (true, 0), 5)
    val TESTASSOC0104_EXPECTED = "123456789"
  in
  fun testAssoc0104 () =
      assertAssoc TESTASSOC0104_EXPECTED TESTASSOC0104_EXPRESSION
  end

  local
    val TESTASSOC0105_EXPRESSION = makeExpression (5, SOME (true, 10), 0)
    val TESTASSOC0105_EXPECTED = "(1)(2)(3)(4)(5)(6)(7)(8)(9)"
  in
  fun testAssoc0105 () =
      assertAssoc TESTASSOC0105_EXPECTED TESTASSOC0105_EXPRESSION
  end

  local
    val TESTASSOC0106_EXPRESSION = makeExpression (10, SOME (true, 5), 0)
    val TESTASSOC0106_EXPECTED = "(1)(2)(3)(4)(5)(6)(7)(8)(9)"
  in
  fun testAssoc0106 () =
      assertAssoc TESTASSOC0106_EXPECTED TESTASSOC0106_EXPRESSION
  end

  local
    val TESTASSOC0107_EXPRESSION = makeExpression (0, NONE, 10)
    val TESTASSOC0107_EXPECTED = "123456789"
  in
  fun testAssoc0107 () =
      assertAssoc TESTASSOC0107_EXPECTED TESTASSOC0107_EXPRESSION
  end

  local
    val TESTASSOC0108_EXPRESSION = makeExpression (10, NONE, 0)
    val TESTASSOC0108_EXPECTED = "(1)(2)(3)(4)(5)(6)(7)(8)(9)"
  in
  fun testAssoc0108 () =
      assertAssoc TESTASSOC0108_EXPECTED TESTASSOC0108_EXPRESSION
  end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testAssoc0001", testAssoc0001),
        ("testAssoc0002", testAssoc0002),
        ("testAssoc0003", testAssoc0003),
        ("testAssoc0004", testAssoc0004),
        ("testAssoc0005", testAssoc0005),
        ("testAssoc0006", testAssoc0006),
        ("testAssoc0007", testAssoc0007),
        ("testAssoc0008", testAssoc0008),

        ("testAssoc0101", testAssoc0101),
        ("testAssoc0102", testAssoc0102),
        ("testAssoc0103", testAssoc0103),
        ("testAssoc0104", testAssoc0104),
        ("testAssoc0105", testAssoc0105),
        ("testAssoc0106", testAssoc0106),
        ("testAssoc0107", testAssoc0107),
        ("testAssoc0108", testAssoc0108)
      ]

  (***************************************************************************)

end