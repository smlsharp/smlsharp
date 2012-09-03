(**
 * test cases for pretty-printing of deferred newline indicators.
 * <p>
 * These cases pretty-print expressions which contain deferred newline
 * indicators.
 * </p>
 *
 * <table border=1>
 * <caption>Test cases matrix</caption>
 * <tr><th>case</th><th>description</th></tr>
 * <tr>
 *   <td>DeferredIndicator0001</td>
 *   <td>specifies the minimum number of columns which do not require to insert
 *     newline at deferred indicators</td>
 * </tr>
 * <tr>
 *   <td>DeferredIndicator0002</td>
 *   <td>specifies the minimum number of columns which requires to insert
 *     newline at deferred indicators</td>
 * </tr>
 * <tr>
 *   <td>DeferredIndicator0003</td>
 *   <td>including deferred newline indicator and requiring to insert
 *     newline at it, which causes to insert newline at the preferred
 *     indicator where would be not required to insert newline if the
 *     deffered indicator is not included.</td>
 * </tr>
 * <tr>
 *   <td>DeferredIndicator0004</td>
 *   <td>including deferred multiple newline indicators and requiring to insert
 *     at one of them but not required at the other.</td>
 * </tr>
 * </table>
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure SMLFormatTest0005 =
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
    val TESTDEFERREDINDICATOR0001_EXPRESSION = 
        [FE.Term(6, "jugemu"), ind_sd,
         FE.Term(6, "jugemu"), ind_s1,
         FE.Term(15, "gokounosurikire"), ind_s2,
         FE.Term(15, "kaijarisuigyono")]

    val TESTDEFERREDINDICATOR0001_COLUMNS = 6 + 1 + 6
    val TESTDEFERREDINDICATOR0001_EXPECTED =
        "jugemu jugemu\ngokounosurikire\nkaijarisuigyono"
  in
  fun testDeferredIndicator0001 () =
      (
        Assert.assertEqualString
        TESTDEFERREDINDICATOR0001_EXPECTED
        (prettyPrint
             TESTDEFERREDINDICATOR0001_COLUMNS
             TESTDEFERREDINDICATOR0001_EXPRESSION);
        ()
      )
  end

  local
    val TESTDEFERREDINDICATOR0002_EXPRESSION = 
        [FE.Term(6, "jugemu"), ind_sd,
         FE.Term(6, "jugemu"), ind_s1,
         FE.Term(15, "gokounosurikire"), ind_s2,
         FE.Term(15, "kaijarisuigyono")]

    val TESTDEFERREDINDICATOR0002_COLUMNS = (6 + 1 + 6) - 1
    val TESTDEFERREDINDICATOR0002_EXPECTED =
        "jugemu\njugemu\ngokounosurikire\nkaijarisuigyono"
  in
  fun testDeferredIndicator0002 () =
      (
        Assert.assertEqualString
        TESTDEFERREDINDICATOR0002_EXPECTED
        (prettyPrint
             TESTDEFERREDINDICATOR0002_COLUMNS
             TESTDEFERREDINDICATOR0002_EXPRESSION);
        ()
      )
  end

  local
    val TESTDEFERREDINDICATOR0003_EXPRESSION = 
        [FE.Term(6, "jugemu"), ind_s2,
         FE.Term(6, "jugemu"), ind_s1,
         FE.Term(15, "gokounosurikire"), ind_sd,
         FE.Term(15, "kaijarisuigyono")]

    val TESTDEFERREDINDICATOR0003_COLUMNS = (15 + 1 + 15) - 1
    val TESTDEFERREDINDICATOR0003_EXPECTED =
        "jugemu\njugemu\ngokounosurikire\nkaijarisuigyono"
  in
  fun testDeferredIndicator0003 () =
      (
        Assert.assertEqualString
        TESTDEFERREDINDICATOR0003_EXPECTED
        (prettyPrint
             TESTDEFERREDINDICATOR0003_COLUMNS
             TESTDEFERREDINDICATOR0003_EXPRESSION);
        ()
      )
  end

  local
    val TESTDEFERREDINDICATOR0004_EXPRESSION = 
        [FE.Term(6, "jugemu"), ind_sd,
         FE.Term(6, "jugemu"), ind_s1,
         FE.Term(15, "gokounosurikire"), ind_sd,
         FE.Term(15, "kaijarisuigyono")]

    val TESTDEFERREDINDICATOR0004_COLUMNS = (15 + 1 + 15) - 1
    val TESTDEFERREDINDICATOR0004_EXPECTED =
        "jugemu jugemu\ngokounosurikire\nkaijarisuigyono"
  in
  fun testDeferredIndicator0004 () =
      (
        Assert.assertEqualString
        TESTDEFERREDINDICATOR0004_EXPECTED
        (prettyPrint
             TESTDEFERREDINDICATOR0004_COLUMNS
             TESTDEFERREDINDICATOR0004_EXPRESSION);
        ()
      )
  end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testDeferredIndicator0001", testDeferredIndicator0001),
        ("testDeferredIndicator0002", testDeferredIndicator0002),
        ("testDeferredIndicator0003", testDeferredIndicator0003),
        ("testDeferredIndicator0004", testDeferredIndicator0004)
      ]

  (***************************************************************************)

end