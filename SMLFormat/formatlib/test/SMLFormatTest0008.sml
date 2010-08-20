(**
 *  test cases examining the relation between the associativity indicators
 * of two guards one of which is nested within the other.
 * <p>
 *  These cases pretty-print expressions of the form as follows:
 * <pre>
 * <i>cm</i>{ <i>dn</i>{ ... } ... <i>dn</i>{ ... } }
 * </pre>
 * <i>c, d</i> denotes assoc direction(<code>L, R, N</code>), and <i>m, n</i>
 * denotes assoc strength (integer value).
 * </p>
 * <table border=1>
 * <caption>Test cases matrix</caption>
 * <tr>
 *   <th>case</th>
 *   <th>direction(inner)</th>
 *   <th>direction(outer)</th>
 *   <th>relation R of strength(inner R outer)</th>
 * </tr>
 * <tr><td>0LL1</td><td rowspan=9>L</td><td rowspan=3>L</td><td>&lt;</td></tr>
 * <tr><td>0LL2</td><td>=</td></tr>
 * <tr><td>0LL3</td><td>&gt;</td></tr>
 *
 * <tr><td>0LN1</td><td rowspan=3>N</td><td>&lt;</td></tr>
 * <tr><td>0LN2</td><td>=</td></tr>
 * <tr><td>0LN3</td><td>&gt;</td></tr>
 *
 * <tr><td>0LR1</td><td rowspan=3>R</td><td>&lt;</td></tr>
 * <tr><td>0LR2</td><td>=</td></tr>
 * <tr><td>0LR3</td><td>&gt;</td></tr>
 *
 * </table>
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure SMLFormatTest0008 =
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
          (outerDirection, outerStrength) (innerDirection, innerStrength) =
      let
        val outerAssoc =
            {cut = false, strength = outerStrength, direction = outerDirection}
        val innerAssoc =
            {cut = false, strength = innerStrength, direction = innerDirection}
      in
        [FE.Guard
         (
           SOME outerAssoc,
           [
             FE.Guard(SOME innerAssoc, [FE.Term(1, "1")]),
             FE.Guard(SOME innerAssoc, [FE.Term(1, "2")]),
             FE.Guard(SOME innerAssoc, [FE.Term(1, "3")])
           ]
         )]
      end

  fun assertAssoc expected expression =
      (Assert.assertEqualString expected (prettyPrint expression); ())

  (****************************************)

  local
    val TESTASSOC0LL1_EXPRESSION = makeExpression (FE.Left, 5) (FE.Left, 10)
    val TESTASSOC0LL1_EXPECTED = "123"
  in
  fun testAssoc0LL1 () =
      assertAssoc TESTASSOC0LL1_EXPECTED TESTASSOC0LL1_EXPRESSION
  end

  local
    val TESTASSOC0LL2_EXPRESSION = makeExpression (FE.Left, 5) (FE.Left, 5)
    val TESTASSOC0LL2_EXPECTED = "1(2)(3)"
  in
  fun testAssoc0LL2 () =
      assertAssoc TESTASSOC0LL2_EXPECTED TESTASSOC0LL2_EXPRESSION
  end

  local
    val TESTASSOC0LL3_EXPRESSION = makeExpression (FE.Left, 10) (FE.Left, 5)
    val TESTASSOC0LL3_EXPECTED = "(1)(2)(3)"
  in
  fun testAssoc0LL3 () =
      assertAssoc TESTASSOC0LL3_EXPECTED TESTASSOC0LL3_EXPRESSION
  end

  (********************)

  local
    val TESTASSOC0LN1_EXPRESSION = makeExpression (FE.Left, 5) (FE.Neutral, 10)
    val TESTASSOC0LN1_EXPECTED = "123"
  in
  fun testAssoc0LN1 () =
      assertAssoc TESTASSOC0LN1_EXPECTED TESTASSOC0LN1_EXPRESSION
  end

  local
    val TESTASSOC0LN2_EXPRESSION = makeExpression (FE.Left, 5) (FE.Neutral, 5)
    val TESTASSOC0LN2_EXPECTED = "123"
  in
  fun testAssoc0LN2 () =
      assertAssoc TESTASSOC0LN2_EXPECTED TESTASSOC0LN2_EXPRESSION
  end

  local
    val TESTASSOC0LN3_EXPRESSION = makeExpression (FE.Left, 10) (FE.Neutral, 5)
    val TESTASSOC0LN3_EXPECTED = "(1)(2)(3)"
  in
  fun testAssoc0LN3 () =
      assertAssoc TESTASSOC0LN3_EXPECTED TESTASSOC0LN3_EXPRESSION
  end

  (********************)

  local
    val TESTASSOC0LR1_EXPRESSION = makeExpression (FE.Left, 5) (FE.Right, 10)
    val TESTASSOC0LR1_EXPECTED = "123"
  in
  fun testAssoc0LR1 () =
      assertAssoc TESTASSOC0LR1_EXPECTED TESTASSOC0LR1_EXPRESSION
  end

  local
    val TESTASSOC0LR2_EXPRESSION = makeExpression (FE.Left, 5) (FE.Right, 5)
    val TESTASSOC0LR2_EXPECTED = "(1)(2)(3)"
  in
  fun testAssoc0LR2 () =
      assertAssoc TESTASSOC0LR2_EXPECTED TESTASSOC0LR2_EXPRESSION
  end

  local
    val TESTASSOC0LR3_EXPRESSION = makeExpression (FE.Left, 10) (FE.Right, 5)
    val TESTASSOC0LR3_EXPECTED = "(1)(2)(3)"
  in
  fun testAssoc0LR3 () =
      assertAssoc TESTASSOC0LR3_EXPECTED TESTASSOC0LR3_EXPRESSION
  end

  (****************************************)

  local
    val TESTASSOC0NL1_EXPRESSION = makeExpression (FE.Neutral, 5) (FE.Left, 10)
    val TESTASSOC0NL1_EXPECTED = "123"
  in
  fun testAssoc0NL1 () =
      assertAssoc TESTASSOC0NL1_EXPECTED TESTASSOC0NL1_EXPRESSION
  end

  local
    val TESTASSOC0NL2_EXPRESSION = makeExpression (FE.Neutral, 5) (FE.Left, 5)
    val TESTASSOC0NL2_EXPECTED = "(1)(2)(3)"
  in
  fun testAssoc0NL2 () =
      assertAssoc TESTASSOC0NL2_EXPECTED TESTASSOC0NL2_EXPRESSION
  end

  local
    val TESTASSOC0NL3_EXPRESSION = makeExpression (FE.Neutral, 10) (FE.Left, 5)
    val TESTASSOC0NL3_EXPECTED = "(1)(2)(3)"
  in
  fun testAssoc0NL3 () =
      assertAssoc TESTASSOC0NL3_EXPECTED TESTASSOC0NL3_EXPRESSION
  end

  (********************)

  local
    val TESTASSOC0NN1_EXPRESSION =
        makeExpression (FE.Neutral, 5) (FE.Neutral, 10)
    val TESTASSOC0NN1_EXPECTED = "123"
  in
  fun testAssoc0NN1 () =
      assertAssoc TESTASSOC0NN1_EXPECTED TESTASSOC0NN1_EXPRESSION
  end

  local
    val TESTASSOC0NN2_EXPRESSION =
        makeExpression (FE.Neutral, 5) (FE.Neutral, 5)
    val TESTASSOC0NN2_EXPECTED = "123"
  in
  fun testAssoc0NN2 () =
      assertAssoc TESTASSOC0NN2_EXPECTED TESTASSOC0NN2_EXPRESSION
  end

  local
    val TESTASSOC0NN3_EXPRESSION =
        makeExpression (FE.Neutral, 10) (FE.Neutral, 5)
    val TESTASSOC0NN3_EXPECTED = "(1)(2)(3)"
  in
  fun testAssoc0NN3 () =
      assertAssoc TESTASSOC0NN3_EXPECTED TESTASSOC0NN3_EXPRESSION
  end

  (********************)

  local
    val TESTASSOC0NR1_EXPRESSION =
        makeExpression (FE.Neutral, 5) (FE.Right, 10)
    val TESTASSOC0NR1_EXPECTED = "123"
  in
  fun testAssoc0NR1 () =
      assertAssoc TESTASSOC0NR1_EXPECTED TESTASSOC0NR1_EXPRESSION
  end

  local
    val TESTASSOC0NR2_EXPRESSION = makeExpression (FE.Neutral, 5) (FE.Right, 5)
    val TESTASSOC0NR2_EXPECTED = "(1)(2)(3)"
  in
  fun testAssoc0NR2 () =
      assertAssoc TESTASSOC0NR2_EXPECTED TESTASSOC0NR2_EXPRESSION
  end

  local
    val TESTASSOC0NR3_EXPRESSION =
        makeExpression (FE.Neutral, 10) (FE.Right, 5)
    val TESTASSOC0NR3_EXPECTED = "(1)(2)(3)"
  in
  fun testAssoc0NR3 () =
      assertAssoc TESTASSOC0NR3_EXPECTED TESTASSOC0NR3_EXPRESSION
  end

  (****************************************)

  local
    val TESTASSOC0RL1_EXPRESSION = makeExpression (FE.Right, 5) (FE.Left, 10)
    val TESTASSOC0RL1_EXPECTED = "123"
  in
  fun testAssoc0RL1 () =
      assertAssoc TESTASSOC0RL1_EXPECTED TESTASSOC0RL1_EXPRESSION
  end

  local
    val TESTASSOC0RL2_EXPRESSION = makeExpression (FE.Right, 5) (FE.Left, 5)
    val TESTASSOC0RL2_EXPECTED = "(1)(2)(3)"
  in
  fun testAssoc0RL2 () =
      assertAssoc TESTASSOC0RL2_EXPECTED TESTASSOC0RL2_EXPRESSION
  end

  local
    val TESTASSOC0RL3_EXPRESSION = makeExpression (FE.Right, 10) (FE.Left, 5)
    val TESTASSOC0RL3_EXPECTED = "(1)(2)(3)"
  in
  fun testAssoc0RL3 () =
      assertAssoc TESTASSOC0RL3_EXPECTED TESTASSOC0RL3_EXPRESSION
  end

  (********************)

  local
    val TESTASSOC0RN1_EXPRESSION =
        makeExpression (FE.Right, 5) (FE.Neutral, 10)
    val TESTASSOC0RN1_EXPECTED = "123"
  in
  fun testAssoc0RN1 () =
      assertAssoc TESTASSOC0RN1_EXPECTED TESTASSOC0RN1_EXPRESSION
  end

  local
    val TESTASSOC0RN2_EXPRESSION =
        makeExpression (FE.Right, 5) (FE.Neutral, 5)
    val TESTASSOC0RN2_EXPECTED = "123"
  in
  fun testAssoc0RN2 () =
      assertAssoc TESTASSOC0RN2_EXPECTED TESTASSOC0RN2_EXPRESSION
  end

  local
    val TESTASSOC0RN3_EXPRESSION =
        makeExpression (FE.Right, 10) (FE.Neutral, 5)
    val TESTASSOC0RN3_EXPECTED = "(1)(2)(3)"
  in
  fun testAssoc0RN3 () =
      assertAssoc TESTASSOC0RN3_EXPECTED TESTASSOC0RN3_EXPRESSION
  end

  (********************)

  local
    val TESTASSOC0RR1_EXPRESSION = makeExpression (FE.Right, 5) (FE.Right, 10)
    val TESTASSOC0RR1_EXPECTED = "123"
  in
  fun testAssoc0RR1 () =
      assertAssoc TESTASSOC0RR1_EXPECTED TESTASSOC0RR1_EXPRESSION
  end

  local
    val TESTASSOC0RR2_EXPRESSION = makeExpression (FE.Right, 5) (FE.Right, 5)
    val TESTASSOC0RR2_EXPECTED = "(1)(2)3"
  in
  fun testAssoc0RR2 () =
      assertAssoc TESTASSOC0RR2_EXPECTED TESTASSOC0RR2_EXPRESSION
  end

  local
    val TESTASSOC0RR3_EXPRESSION = makeExpression (FE.Right, 10) (FE.Right, 5)
    val TESTASSOC0RR3_EXPECTED = "(1)(2)(3)"
  in
  fun testAssoc0RR3 () =
      assertAssoc TESTASSOC0RR3_EXPECTED TESTASSOC0RR3_EXPRESSION
  end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testAssoc0LL1", testAssoc0LL1),
        ("testAssoc0LL2", testAssoc0LL2),
        ("testAssoc0LL3", testAssoc0LL3),
        ("testAssoc0LN1", testAssoc0LN1),
        ("testAssoc0LN2", testAssoc0LN2),
        ("testAssoc0LN3", testAssoc0LN3),
        ("testAssoc0LR1", testAssoc0LR1),
        ("testAssoc0LR2", testAssoc0LR2),
        ("testAssoc0LR3", testAssoc0LR3),

        ("testAssoc0NL1", testAssoc0NL1),
        ("testAssoc0NL2", testAssoc0NL2),
        ("testAssoc0NL3", testAssoc0NL3),
        ("testAssoc0NN1", testAssoc0NN1),
        ("testAssoc0NN2", testAssoc0NN2),
        ("testAssoc0NN3", testAssoc0NN3),
        ("testAssoc0NR1", testAssoc0NR1),
        ("testAssoc0NR2", testAssoc0NR2),
        ("testAssoc0NR3", testAssoc0NR3),

        ("testAssoc0RL1", testAssoc0RL1),
        ("testAssoc0RL2", testAssoc0RL2),
        ("testAssoc0RL3", testAssoc0RL3),
        ("testAssoc0RN1", testAssoc0RN1),
        ("testAssoc0RN2", testAssoc0RN2),
        ("testAssoc0RN3", testAssoc0RN3),
        ("testAssoc0RR1", testAssoc0RR1),
        ("testAssoc0RR2", testAssoc0RR2),
        ("testAssoc0RR3", testAssoc0RR3)
      ]

  (***************************************************************************)

end