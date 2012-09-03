(**
 * test cases for pretty-printing of space-newline indicators.
 * <p>
 * These cases pretty-print expressions which contain indicators which indicate
 * both space and newline.
 * </p>
 *
 * <table border=1>
 * <caption>Test cases matrix</caption>
 * <tr><th>case</th><th>description</th></tr>
 * <tr>
 *   <td>SpaceNewlineIndicator0001</td>
 *   <td>specifies the minimum number of columns which does not require to
 *     insert newline at any of indicators.</td>
 * </tr>
 * <tr>
 *   <td>SpaceNewlineIndicator0002</td>
 *   <td>specifies the maximum number of columns which requires to insert
 *     newline at the highest of indicators</td>
 * </tr>
 * <tr>
 *   <td>SpaceNewlineIndicator0003</td>
 *   <td>specifies the minimum number of columns which causes to insert newline
 *     at the highest of indicators</td>
 * </tr>
 * <tr>
 *   <td>SpaceNewlineIndicator0004</td>
 *   <td>specifies the maximum number of columns which causes to insert newline
 *     at all of indicators</td>
 * </tr>
 * </table>
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure SMLFormatTest0004 =
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

  (****************************************)

  val TESTSPACENEWLINEINDICATOR_EXPRESSION = 
      [FE.Term(6, "jugemu"), ind_s2,
       FE.Term(6, "jugemu"), ind_s1,
       FE.Term(15, "gokounosurikire"), ind_s2,
       FE.Term(15, "kaijarisuigyono")]

  local
    val TESTSPACENEWLINEINDICATOR0001_COLUMNS = 6 + 1 + 6 + 1 + 15 + 1 + 15
    val TESTSPACENEWLINEINDICATOR0001_EXPECTED =
        "jugemu jugemu gokounosurikire kaijarisuigyono"
  in
  fun testSpaceNewlineIndicator0001 () =
      (
        Assert.assertEqualString
        TESTSPACENEWLINEINDICATOR0001_EXPECTED
        (prettyPrint
             TESTSPACENEWLINEINDICATOR0001_COLUMNS
             TESTSPACENEWLINEINDICATOR_EXPRESSION);
        ()
      )
  end

  local
    val TESTSPACENEWLINEINDICATOR0002_COLUMNS =
        (6 + 1 + 6 + 1 + 15 + 1 + 15) - 1
    val TESTSPACENEWLINEINDICATOR0002_EXPECTED =
        "jugemu jugemu\ngokounosurikire kaijarisuigyono"
  in
  fun testSpaceNewlineIndicator0002 () =
      (
        Assert.assertEqualString
        TESTSPACENEWLINEINDICATOR0002_EXPECTED
        (prettyPrint
             TESTSPACENEWLINEINDICATOR0002_COLUMNS
             TESTSPACENEWLINEINDICATOR_EXPRESSION);
        ()
      )
  end

  local
    val TESTSPACENEWLINEINDICATOR0003_COLUMNS = (15 + 1 + 15)
    val TESTSPACENEWLINEINDICATOR0003_EXPECTED =
        "jugemu jugemu\ngokounosurikire kaijarisuigyono"
  in
  fun testSpaceNewlineIndicator0003 () =
      (
        Assert.assertEqualString
        TESTSPACENEWLINEINDICATOR0003_EXPECTED
        (prettyPrint
             TESTSPACENEWLINEINDICATOR0003_COLUMNS
             TESTSPACENEWLINEINDICATOR_EXPRESSION);
        ()
      )
  end

  local
    val TESTSPACENEWLINEINDICATOR0004_COLUMNS = (15 + 1 + 15) - 1
    val TESTSPACENEWLINEINDICATOR0004_EXPECTED =
        "jugemu\njugemu\ngokounosurikire\nkaijarisuigyono"
  in
  fun testSpaceNewlineIndicator0004 () =
      (
        Assert.assertEqualString
        TESTSPACENEWLINEINDICATOR0004_EXPECTED
        (prettyPrint
             TESTSPACENEWLINEINDICATOR0004_COLUMNS
             TESTSPACENEWLINEINDICATOR_EXPRESSION);
        ()
      )
  end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testSpaceNewlineIndicator0001", testSpaceNewlineIndicator0001),
        ("testSpaceNewlineIndicator0002", testSpaceNewlineIndicator0002),
        ("testSpaceNewlineIndicator0003", testSpaceNewlineIndicator0003),
        ("testSpaceNewlineIndicator0004", testSpaceNewlineIndicator0004)
      ]

  (***************************************************************************)

end