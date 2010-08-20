(**
 * test cases for pretty-printing of newline indicators.
 * <p>
 * These cases pretty-print expressions which contain newline indicators.
 * </p>
 *
 * <table border=1>
 * <caption>Test cases matrix</caption>
 * <tr><th>case</th><th>description</th></tr>
 * <tr>
 *   <td>NewlineIndicator0001</td>
 *   <td>specifies the minimum number of columns which does not require to
 *     insert newline at any of indicators.</td>
 * </tr>
 * <tr>
 *   <td>NewlineIndicator0002</td>
 *   <td>specifies the maximum number of columns which requires to insert
 *     newline at the highest of indicators</td>
 * </tr>
 * <tr>
 *   <td>NewlineIndicator0003</td>
 *   <td>specifies the minimum number of columns which causes to insert newline
 *     at the highest of indicators</td>
 * </tr>
 * <tr>
 *   <td>NewlineIndicator0004</td>
 *   <td>specifies the maximum number of columns which causes to insert newline
 *     at all of indicators</td>
 * </tr>
 * </table>
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure SMLFormatTest0003 =
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

  val ind_1 =
      FE.Indicator{space = false, newline = SOME{priority = FE.Preferred 1}}
  val ind_2 =
      FE.Indicator{space = false, newline = SOME{priority = FE.Preferred 2}}

  (****************************************)

  val TESTNEWLINEINDICATOR_EXPRESSION = 
      [FE.Term(6, "jugemu"), ind_2,
       FE.Term(6, "jugemu"), ind_1,
       FE.Term(15, "gokounosurikire"), ind_2,
       FE.Term(15, "kaijarisuigyono")]

  local
    val TESTNEWLINEINDICATOR0001_COLUMNS = 6 + 6 + 15 + 15
    val TESTNEWLINEINDICATOR0001_EXPECTED =
        "jugemujugemugokounosurikirekaijarisuigyono"
  in
  fun testNewlineIndicator0001 () =
      (
        Assert.assertEqualString
        TESTNEWLINEINDICATOR0001_EXPECTED
        (prettyPrint
             TESTNEWLINEINDICATOR0001_COLUMNS
             TESTNEWLINEINDICATOR_EXPRESSION);
        ()
      )
  end

  local
    val TESTNEWLINEINDICATOR0002_COLUMNS = (6 + 6 + 15 + 15) - 1
    val TESTNEWLINEINDICATOR0002_EXPECTED =
        "jugemujugemu\ngokounosurikirekaijarisuigyono"
  in
  fun testNewlineIndicator0002 () =
      (
        Assert.assertEqualString
        TESTNEWLINEINDICATOR0002_EXPECTED
        (prettyPrint
             TESTNEWLINEINDICATOR0002_COLUMNS
             TESTNEWLINEINDICATOR_EXPRESSION);
        ()
      )
  end

  local
    val TESTNEWLINEINDICATOR0003_COLUMNS = 15 + 15
    val TESTNEWLINEINDICATOR0003_EXPECTED =
        "jugemujugemu\ngokounosurikirekaijarisuigyono"
  in
  fun testNewlineIndicator0003 () =
      (
        Assert.assertEqualString
        TESTNEWLINEINDICATOR0003_EXPECTED
        (prettyPrint
             TESTNEWLINEINDICATOR0003_COLUMNS
             TESTNEWLINEINDICATOR_EXPRESSION);
        ()
      )
  end

  local
    val TESTNEWLINEINDICATOR0004_COLUMNS = (15 + 15) - 1
    val TESTNEWLINEINDICATOR0004_EXPECTED =
        "jugemu\njugemu\ngokounosurikire\nkaijarisuigyono"
  in
  fun testNewlineIndicator0004 () =
      (
        Assert.assertEqualString
        TESTNEWLINEINDICATOR0004_EXPECTED
        (prettyPrint
             TESTNEWLINEINDICATOR0004_COLUMNS
             TESTNEWLINEINDICATOR_EXPRESSION);
        ()
      )
  end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testNewlineIndicator0001", testNewlineIndicator0001),
        ("testNewlineIndicator0002", testNewlineIndicator0002),
        ("testNewlineIndicator0003", testNewlineIndicator0003),
        ("testNewlineIndicator0004", testNewlineIndicator0004)
      ]

  (***************************************************************************)

end