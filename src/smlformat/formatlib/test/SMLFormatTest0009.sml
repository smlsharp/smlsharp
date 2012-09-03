(**
 *  verify that the SMLFormat treats the left/right most element in guards properly
 * in inheriting associativity from the guards to their elements.
 * <p>
 *  These cases pretty-print expressions of the form as follows:
 * <pre>
 * <i>cm</i>{ eL Lm{ ... } ... Rm{ ... } eR }
 * </pre>
 * <i>c</i> denotes assoc direction(<code>L, N, R</code>), and <i>m</i>
 * denotes assoc strength (integer value).
 * </p>
 * <p>
 *  If <i>eL</i> or <i>eR</i> is not <code>Term</code> or <code>Guard</code>,
 * it should be ignored in the inheritance of associativity.
 * </p>
 *
 * <table border=1>
 * <caption>Test cases matrix</caption>
 * <tr>
 *   <th>case</th>
 *   <th>direction(<code>c</code>)</th>
 *   <th>left-most of inner(<code>eL</code>)</th>
 *   <th>right-most of inner(<code>eR</code>)</th>
 * </tr>
 * <tr><td>00L1</td><td rowspan=4>L</td><td>Term</td><td>Term</td></tr>
 * <tr><td>00L2</td><td>Guard</td><td>Guard</td></tr>
 * <tr><td>00L3</td><td>Indicator</td><td>Indicator</td></tr>
 * <tr><td>00L4</td><td>StartOfIndent</td><td>EndOfIndent</td></tr>
 *
 * <tr><td>00N1</td><td rowspan=4>N</td><td>Term</td><td>Term</td></tr>
 * <tr><td>00N2</td><td>Guard</td><td>Guard</td></tr>
 * <tr><td>00N3</td><td>Indicator</td><td>Indicator</td></tr>
 * <tr><td>00N4</td><td>StartOfIndent</td><td>EndOfIndent</td></tr>
 *
 * <tr><td>00R1</td><td rowspan=4>R</td><td>Term</td><td>Term</td></tr>
 * <tr><td>00R2</td><td>Guard</td><td>Guard</td></tr>
 * <tr><td>00R3</td><td>Indicator</td><td>Indicator</td></tr>
 * <tr><td>00R4</td><td>StartOfIndent</td><td>EndOfIndent</td></tr>
 *
 * </table>
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure SMLFormatTest0009 =
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

  val TESTASSOC_ASSOCSTRENGTH = 5

  fun makeExpression direction leftMost rightMost =
      let
        val outerAssoc =
            {
              cut = false,
              strength = TESTASSOC_ASSOCSTRENGTH,
              direction = direction
            }
        val leftAssoc =
            {
              cut = false,
              strength = TESTASSOC_ASSOCSTRENGTH,
              direction = FE.Left
            }
        val rightAssoc =
            {
              cut = false,
              strength = TESTASSOC_ASSOCSTRENGTH,
              direction = FE.Right
            }
      in
        [FE.Guard
         (
           SOME outerAssoc,
           [
             leftMost,
             FE.Guard(SOME leftAssoc, [FE.Term(1, "L")]),
             FE.Guard(SOME rightAssoc, [FE.Term(1, "R")]),
             rightMost
           ]
         )]
      end

  fun assertAssoc expected expression =
      (Assert.assertEqualString expected (prettyPrint expression); ())

  (****************************************)

  local
    val TESTASSOC00L1_EXPRESSION =
        makeExpression FE.Left (FE.Term(1, "1")) (FE.Term(1, "2"))
    val TESTASSOC00L1_EXPECTED = "1(L)(R)2"
  in
  fun testAssoc00L1 () =
      assertAssoc TESTASSOC00L1_EXPECTED TESTASSOC00L1_EXPRESSION
  end

  local
    val TESTASSOC00L2_EXPRESSION =
        makeExpression
        FE.Left
        (FE.Guard
         (SOME
          {
            cut = false,
            strength = TESTASSOC_ASSOCSTRENGTH,
            direction = FE.Left
          },
          [FE.Term(1, "1")]))
        (FE.Guard
         (SOME
          {
            cut = false,
            strength = TESTASSOC_ASSOCSTRENGTH,
            direction = FE.Right
          },
          [FE.Term(1, "2")]))
    val TESTASSOC00L2_EXPECTED = "1(L)(R)(2)"
  in
  fun testAssoc00L2 () =
      assertAssoc TESTASSOC00L2_EXPECTED TESTASSOC00L2_EXPRESSION
  end

  local
    val TESTASSOC00L3_EXPRESSION =
        makeExpression
        FE.Left
        (FE.Indicator{space = false, newline = SOME{priority = FE.Deferred}})
        (FE.Indicator{space = false, newline = SOME{priority = FE.Deferred}})
    val TESTASSOC00L3_EXPECTED = "L(R)"
  in
  fun testAssoc00L3 () =
      assertAssoc TESTASSOC00L3_EXPECTED TESTASSOC00L3_EXPRESSION
  end

  local
    val TESTASSOC00L4_EXPRESSION =
        makeExpression FE.Left (FE.StartOfIndent 1) FE.EndOfIndent
    val TESTASSOC00L4_EXPECTED = "L(R)"
  in
  fun testAssoc00L4 () =
      assertAssoc TESTASSOC00L4_EXPECTED TESTASSOC00L4_EXPRESSION
  end

  (****************************************)

  local
    val TESTASSOC00N1_EXPRESSION =
        makeExpression FE.Neutral (FE.Term(1, "1")) (FE.Term(1, "2"))
    val TESTASSOC00N1_EXPECTED = "1(L)(R)2"
  in
  fun testAssoc00N1 () =
      assertAssoc TESTASSOC00N1_EXPECTED TESTASSOC00N1_EXPRESSION
  end

  local
    val TESTASSOC00N2_EXPRESSION =
        makeExpression
        FE.Neutral
        (FE.Guard
         (SOME
          {
            cut = false,
            strength = TESTASSOC_ASSOCSTRENGTH,
            direction = FE.Left
          },
          [FE.Term(1, "1")]))
        (FE.Guard
         (SOME
          {
            cut = false,
            strength = TESTASSOC_ASSOCSTRENGTH,
            direction = FE.Right
          },
          [FE.Term(1, "2")]))
    val TESTASSOC00N2_EXPECTED = "(1)(L)(R)(2)"
  in
  fun testAssoc00N2 () =
      assertAssoc TESTASSOC00N2_EXPECTED TESTASSOC00N2_EXPRESSION
  end

  local
    val TESTASSOC00N3_EXPRESSION =
        makeExpression
        FE.Neutral
        (FE.Indicator{space = false, newline = SOME{priority = FE.Deferred}})
        (FE.Indicator{space = false, newline = SOME{priority = FE.Deferred}})
    val TESTASSOC00N3_EXPECTED = "(L)(R)"
  in
  fun testAssoc00N3 () =
      assertAssoc TESTASSOC00N3_EXPECTED TESTASSOC00N3_EXPRESSION
  end

  local
    val TESTASSOC00N4_EXPRESSION =
        makeExpression FE.Neutral (FE.StartOfIndent 1) FE.EndOfIndent
    val TESTASSOC00N4_EXPECTED = "(L)(R)"
  in
  fun testAssoc00N4 () =
      assertAssoc TESTASSOC00N4_EXPECTED TESTASSOC00N4_EXPRESSION
  end

  (****************************************)

  local
    val TESTASSOC00R1_EXPRESSION =
        makeExpression FE.Right (FE.Term(1, "1")) (FE.Term(1, "2"))
    val TESTASSOC00R1_EXPECTED = "1(L)(R)2"
  in
  fun testAssoc00R1 () =
      assertAssoc TESTASSOC00R1_EXPECTED TESTASSOC00R1_EXPRESSION
  end

  local
    val TESTASSOC00R2_EXPRESSION =
        makeExpression
        FE.Right
        (FE.Guard
         (SOME
          {
            cut = false,
            strength = TESTASSOC_ASSOCSTRENGTH,
            direction = FE.Left
          },
          [FE.Term(1, "1")]))
        (FE.Guard
         (SOME
          {
            cut = false,
            strength = TESTASSOC_ASSOCSTRENGTH,
            direction = FE.Right
          },
          [FE.Term(1, "2")]))
    val TESTASSOC00R2_EXPECTED = "(1)(L)(R)2"
  in
  fun testAssoc00R2 () =
      assertAssoc TESTASSOC00R2_EXPECTED TESTASSOC00R2_EXPRESSION
  end

  local
    val TESTASSOC00R3_EXPRESSION =
        makeExpression
        FE.Right
        (FE.Indicator{space = false, newline = SOME{priority = FE.Deferred}})
        (FE.Indicator{space = false, newline = SOME{priority = FE.Deferred}})
    val TESTASSOC00R3_EXPECTED = "(L)R"
  in
  fun testAssoc00R3 () =
      assertAssoc TESTASSOC00R3_EXPECTED TESTASSOC00R3_EXPRESSION
  end

  local
    val TESTASSOC00R4_EXPRESSION =
        makeExpression FE.Right (FE.StartOfIndent 1) FE.EndOfIndent
    val TESTASSOC00R4_EXPECTED = "(L)R"
  in
  fun testAssoc00R4 () =
      assertAssoc TESTASSOC00R4_EXPECTED TESTASSOC00R4_EXPRESSION
  end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testAssoc00L1", testAssoc00L1),
        ("testAssoc00L2", testAssoc00L2),
        ("testAssoc00L3", testAssoc00L3),
        ("testAssoc00L4", testAssoc00L4),

        ("testAssoc00N1", testAssoc00N1),
        ("testAssoc00N2", testAssoc00N2),
        ("testAssoc00N3", testAssoc00N3),
        ("testAssoc00N4", testAssoc00N4),

        ("testAssoc00R1", testAssoc00R1),
        ("testAssoc00R2", testAssoc00R2),
        ("testAssoc00R3", testAssoc00R3),
        ("testAssoc00R4", testAssoc00R4)
      ]

  (***************************************************************************)

end