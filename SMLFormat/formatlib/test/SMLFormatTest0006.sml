(**
 * test cases for pretty-printing of expressions with indent width indicators.
 *
 * <table border=1>
 * <caption>Test cases matrix</caption>
 * <tr><th>case</th><th>description</th></tr>
 * <tr>
 *   <td>Indent0001</td>
 *   <td>including single indent, but not required to insert newline</td>
 * </tr>
 * <tr>
 *   <td>Indent0002</td>
 *   <td>including single indent and required to insert newline at indicators
 *     within the indent region.</td>
 * </tr>
 * <tr>
 *   <td>Indent0003</td>
 *   <td>including multiple newline indicators within an indent region</td>
 * </tr>
 * <tr>
 *   <td>Indent0004</td><td>including nested indent indicator</td>
 * </tr>
 * <tr>
 *   <td>Indent0005</td>
 *   <td>including indent indicator whose indent width is negative integer</td>
 * </tr>
 * </table>
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure SMLFormatTest0006 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure Testee = SMLFormat
  structure FE = Testee.FormatExpression
  structure PP = Testee.PrinterParameter

  (***************************************************************************)

  fun prettyPrint columns expressions =
      SMLFormat.prettyPrint
          [
            SMLFormat.Newline "\n",
            SMLFormat.Space " ",
            SMLFormat.Columns columns
          ]
          expressions

  (****************************************)

  val ind_s1 =
      FE.Indicator{space = true, newline = SOME{priority = FE.Preferred 1}}
  val ind_s2 =
      FE.Indicator{space = true, newline = SOME{priority = FE.Preferred 2}}
  val ind_sd =
      FE.Indicator{space = true, newline = SOME{priority = FE.Deferred}}

  (****************************************)

  local
    val TESTINDENT_EXPRESSION = 
        [FE.Term(6, "jugemu"), ind_s2,
         FE.Term(6, "jugemu"), FE.StartOfIndent 5, ind_s1,
         FE.Term(15, "gokounosurikire"), FE.EndOfIndent, ind_s2,
         FE.Term(15, "kaijarisuigyono")]

  in
  local
    val TESTINDENT0001_COLUMNS = 6 + 1 + 6 + 1 + 15 + 1 + 15
    val TESTINDENT0001_EXPECTED =
        "jugemu jugemu gokounosurikire kaijarisuigyono"
  in
  fun testIndent0001 () =
      (
        Assert.assertEqualString
        TESTINDENT0001_EXPECTED
        (prettyPrint
             TESTINDENT0001_COLUMNS
             TESTINDENT_EXPRESSION);
        ()
      )
  end

  local
    val TESTINDENT0002_COLUMNS = (6 + 1 + 6 + 1 + 15 + 1 + 15) - 1
    val TESTINDENT0002_EXPECTED =
        "jugemu jugemu\n     gokounosurikire kaijarisuigyono"
  in
  fun testIndent0002 () =
      (
        Assert.assertEqualString
        TESTINDENT0002_EXPECTED
        (prettyPrint
             TESTINDENT0002_COLUMNS
             TESTINDENT_EXPRESSION);
        ()
      )
  end
  end

  local
    val TESTINDENT0003_EXPRESSION = 
        [FE.Term(6, "jugemu"), ind_s2,
         FE.Term(6, "jugemu"), FE.StartOfIndent 5, ind_s1,
         FE.Term(15, "gokounosurikire"), ind_s2,
         FE.Term(15, "kaijarisuigyono"), FE.EndOfIndent]

    val TESTINDENT0003_COLUMNS = (15 + 1 + 15) - 1
    val TESTINDENT0003_EXPECTED =
        "jugemu\njugemu\n     gokounosurikire\n     kaijarisuigyono"
  in
  fun testIndent0003 () =
      (
        Assert.assertEqualString
        TESTINDENT0003_EXPECTED
        (prettyPrint
             TESTINDENT0003_COLUMNS
             TESTINDENT0003_EXPRESSION);
        ()
      )
  end

  local
    val TESTINDENT0004_EXPRESSION = 
        [FE.Term(6, "jugemu"), ind_s2,
         FE.Term(6, "jugemu"), FE.StartOfIndent 5, ind_s1,
         FE.Term(15, "gokounosurikire"), FE.StartOfIndent 3, ind_s2,
         FE.Term(15, "kaijarisuigyono"), FE.EndOfIndent, FE.EndOfIndent]

    val TESTINDENT0004_COLUMNS = (15 + 1 + 15) - 1
    val TESTINDENT0004_EXPECTED =
        "jugemu\njugemu\n     gokounosurikire\n        kaijarisuigyono"
  in
  fun testIndent0004 () =
      (
        Assert.assertEqualString
        TESTINDENT0004_EXPECTED
        (prettyPrint
             TESTINDENT0004_COLUMNS
             TESTINDENT0004_EXPRESSION);
        ()
      )
  end

  local
    val TESTINDENT0005_EXPRESSION = 
        [FE.Term(6, "jugemu"), ind_s2,
         FE.Term(6, "jugemu"), FE.StartOfIndent 5, ind_s1,
         FE.Term(15, "gokounosurikire"), FE.StartOfIndent ~3, ind_s2,
         FE.Term(15, "kaijarisuigyono"), FE.EndOfIndent, FE.EndOfIndent]

    val TESTINDENT0005_COLUMNS = (15 + 1 + 15) - 1
    val TESTINDENT0005_EXPECTED =
        "jugemu\njugemu\n     gokounosurikire\n  kaijarisuigyono"
  in
  fun testIndent0005 () =
      (
        Assert.assertEqualString
        TESTINDENT0005_EXPECTED
        (prettyPrint
             TESTINDENT0005_COLUMNS
             TESTINDENT0005_EXPRESSION);
        ()
      )
  end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testIndent0001", testIndent0001),
        ("testIndent0002", testIndent0002),
        ("testIndent0003", testIndent0003),
        ("testIndent0004", testIndent0004),
        ("testIndent0005", testIndent0005)
      ]

  (***************************************************************************)

end