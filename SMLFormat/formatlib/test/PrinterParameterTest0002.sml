(**
 *  verify that the SMLFormat treats the <code>spaceString</code> field in
 * PrinterParameter.parameter properly.
 *
 * <table border=1>
 * <caption>Test cases matrix</caption>
 * <tr><th>case</th><th>spaceString</th></tr>
 * <tr><td>SpaceString0001</td><td>&nbsp;</td></tr>
 * <tr><td>SpaceString0002</td><td>&amp;nbsp;</td></tr>
 * </table>
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure PrinterParameterTest0002 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure FE = SMLFormat.FormatExpression
  structure PP = SMLFormat.PrinterParameter

  (***************************************************************************)

  local
    val TESTSPACESTRING0001_COLUMNS = 10
    val TESTSPACESTRING0001_SPACESTRING = " "
    val TESTSPACESTRING0001_EXPRESSION =
        [
          FE.Term(5, "12345"),
          FE.Indicator{space = true, newline = NONE},
          FE.Term(5, "67890")
        ]
    val TESTSPACESTRING0001_EXPECTED = "12345 67890"
  in
  fun testSpaceString0001 () =
      (
        Assert.assertEqualString
        TESTSPACESTRING0001_EXPECTED
        (SMLFormat.prettyPrint
             [
               SMLFormat.Newline "\n",
               SMLFormat.Space TESTSPACESTRING0001_SPACESTRING,
               SMLFormat.Columns TESTSPACESTRING0001_COLUMNS
             ]
             TESTSPACESTRING0001_EXPRESSION);
        ()
      )
  end

  local
    val TESTSPACESTRING0002_COLUMNS = 11
    val TESTSPACESTRING0002_SPACESTRING = "&nbsp;"
    val TESTSPACESTRING0002_EXPRESSION =
        [
          FE.Term(5, "12345"),
          FE.Indicator{space = true, newline = NONE},
          FE.Term(5, "67890")
        ]
    val TESTSPACESTRING0002_EXPECTED = "12345&nbsp;67890"
  in
  fun testSpaceString0002 () =
      (
        Assert.assertEqualString
        TESTSPACESTRING0002_EXPECTED
        (SMLFormat.prettyPrint
             [
               SMLFormat.Newline "\n",
               SMLFormat.Space TESTSPACESTRING0002_SPACESTRING,
               SMLFormat.Columns TESTSPACESTRING0002_COLUMNS
             ]
             TESTSPACESTRING0002_EXPRESSION);
        ()
      )
  end
  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testSpaceString0001", testSpaceString0001),
        ("testSpaceString0002", testSpaceString0002)
      ]

  (***************************************************************************)

end