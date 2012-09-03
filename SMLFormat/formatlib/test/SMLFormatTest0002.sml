(**
 * test cases for pretty-printing of space indicators.
 *
 * <table border=1>
 * <caption>Test cases matrix</caption>
 * <tr><th>case</th><th>description</th></tr>
 * <tr><td>SpaceIndicator0001</td><td>including space indicator</td></tr>
 * </table>
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure SMLFormatTest0002 =
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
    val ind_s = FE.Indicator{space = true, newline = NONE}
    val TESTSPACEINDICATOR0001_COLUMNS = 10
    val TESTSPACEINDICATOR0001_EXPRESSION = 
        [FE.Term(6, "jugemu"), ind_s,
         FE.Term(6, "jugemu"), ind_s,
         FE.Term(15, "gokounosurikire")]
    val TESTSPACEINDICATOR0001_EXPECTED = "jugemu jugemu gokounosurikire"
  in
  fun testSpaceIndicator0001 () =
      (
        Assert.assertEqualString
        TESTSPACEINDICATOR0001_EXPECTED
        (prettyPrint
             TESTSPACEINDICATOR0001_COLUMNS
             TESTSPACEINDICATOR0001_EXPRESSION);
        ()
      )
  end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testSpaceIndicator0001", testSpaceIndicator0001)
      ]

  (***************************************************************************)

end