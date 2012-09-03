(**
 * test cases for pretty-printing of terms.
 *
 * <table border=1>
 * <caption>Test cases matrix</caption>
 * <tr><th>case</th><th>description</th></tr>
 * <tr><td>Term0001</td><td>single term</td></tr>
 * <tr><td>Term0002</td><td>sequence of terms</td></tr>
 * <tr><td>Term0003</td><td>including spaces as terms</td></tr>
 * </table>
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure SMLFormatTest0001 =
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

  local
    val TESTTERM0001_COLUMNS = 10
    val TESTTERM0001_EXPRESSION = [FE.Term(6, "jugemu")]
    val TESTTERM0001_EXPECTED = "jugemu"
  in
  fun testTerm0001 () =
      (
        Assert.assertEqualString
        TESTTERM0001_EXPECTED
        (prettyPrint
             TESTTERM0001_COLUMNS
             TESTTERM0001_EXPRESSION);
        ()
      )
  end

  local
    val TESTTERM0002_COLUMNS = 10
    val TESTTERM0002_EXPRESSION = [FE.Term(6, "jugemu"), FE.Term(6, "jugemu")]
    val TESTTERM0002_EXPECTED = "jugemujugemu"
  in
  fun testTerm0002 () =
      (
        Assert.assertEqualString
        TESTTERM0002_EXPECTED
        (prettyPrint
             TESTTERM0002_COLUMNS
             TESTTERM0002_EXPRESSION);
        ()
      )
  end

  local
    val TESTTERM0003_COLUMNS = 10
    val TESTTERM0003_EXPRESSION =
        [FE.Term(6, "jugemu"), FE.Term(1, " "),
         FE.Term(6, "jugemu"), FE.Term(1, " "),
         FE.Term(15, "gokounosurikire")]
    val TESTTERM0003_EXPECTED = "jugemu jugemu gokounosurikire"
  in
  fun testTerm0003 () =
      (
        Assert.assertEqualString
        TESTTERM0003_EXPECTED
        (prettyPrint
             TESTTERM0003_COLUMNS
             TESTTERM0003_EXPRESSION);
        ()
      )
  end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testTerm0001", testTerm0001),
        ("testTerm0002", testTerm0002),
        ("testTerm0003", testTerm0003)
      ]

  (***************************************************************************)

end