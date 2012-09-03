(**
 *  verify that the SMLFormat treats the <code>newlineString</code> field in
 * PrinterParameter.parameter properly.
 *
 * <table border=1>
 * <caption>Test cases matrix</caption>
 * <tr><th>case</th><th>newlineString</th></tr>
 * <tr><td>NewlineString0001</td><td>\n</td></tr>
 * <tr><td>NewlineString0002</td><td>&lt;BR&gt;</td></tr>
 * </table>
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure PrinterParameterTest0001 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure FE = SMLFormat.FormatExpression
  structure PP = SMLFormat.PrinterParameter

  (***************************************************************************)

  local
    val TESTNEWLINESTRING0001_COLUMNS = 9
    val TESTNEWLINESTRING0001_NEWLINESTRING = "\n"
    val TESTNEWLINESTRING0001_EXPRESSION =
        [
          FE.Term(5, "12345"),
          FE.Indicator
              {space = false, newline = SOME{priority = FE.Preferred 1}},
          FE.Term(5, "67890")
        ]
    val TESTNEWLINESTRING0001_EXPECTED = "12345\n67890"
  in
  fun testNewlineString0001 () =
      (
        Assert.assertEqualString
        TESTNEWLINESTRING0001_EXPECTED
        (SMLFormat.prettyPrint
             [
               SMLFormat.Newline TESTNEWLINESTRING0001_NEWLINESTRING,
               SMLFormat.Space " ",
               SMLFormat.Columns TESTNEWLINESTRING0001_COLUMNS
             ]
             TESTNEWLINESTRING0001_EXPRESSION);
        ()
      )
  end

  local
    val TESTNEWLINESTRING0002_COLUMNS = 9
    val TESTNEWLINESTRING0002_NEWLINESTRING = "<BR>"
    val TESTNEWLINESTRING0002_EXPRESSION =
        [
          FE.Term(5, "12345"),
          FE.Indicator
              {space = false, newline = SOME{priority = FE.Preferred 1}},
          FE.Term(5, "67890")
        ]
    val TESTNEWLINESTRING0002_EXPECTED = "12345<BR>67890"
  in
  fun testNewlineString0002 () =
      (
        Assert.assertEqualString
        TESTNEWLINESTRING0002_EXPECTED
        (SMLFormat.prettyPrint
             [
               SMLFormat.Newline TESTNEWLINESTRING0002_NEWLINESTRING,
               SMLFormat.Space " ",
               SMLFormat.Columns TESTNEWLINESTRING0002_COLUMNS
             ]
             TESTNEWLINESTRING0002_EXPRESSION);
        ()
      )
  end
  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testNewlineString0001", testNewlineString0001),
        ("testNewlineString0002", testNewlineString0002)
      ]

  (***************************************************************************)

end