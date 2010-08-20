(**
 * test cases for pretty-printing of expressions included within guards.
 *
 * <table border=1>
 * <caption>Test cases matrix</caption>
 * <tr><th>case</th><th>description</th></tr>
 * <tr>
 *   <td>Guard0001</td>
 *   <td>including twe nested guards, the outer one contains a newline
 *     indicator whose priority is higher than a newline indicator in the
 *     inner one. Specifies the minimum number of columns which do not require
 *     to insert newline at indicator within the inner guard.</td>
 * </tr>
 * <tr>
 *   <td>Guard0002</td>
 *   <td>including two nested guards, the outer one contains a deferred newline
 *     indicator and the inner guard contains a preferred newline indicator.
 *     </td>
 * </tr>
 * <tr>
 *   <td>Guard0003</td>
 *   <td>including two nested guards whose ranges do not overlap</td>
 * </tr>
 * <tr>
 *   <td>Guard0004</td>
 *   <td>including a guard whose base column is higher than zero.</td>
 * </tr>
 * <tr>
 *   <td>Guard0005</td>
 *   <td>including a guard which is included within a indent region</td>
 * </tr>
 * </table>
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure SMLFormatTest0007 =
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

  val ind_s = FE.Indicator{space = true, newline = NONE}
  val ind_s1 =
      FE.Indicator{space = true, newline = SOME{priority = FE.Preferred 1}}
  val ind_s2 =
      FE.Indicator{space = true, newline = SOME{priority = FE.Preferred 2}}
  val ind_sd =
      FE.Indicator{space = true, newline = SOME{priority = FE.Deferred}}

  (****************************************)

  local
    val TESTGUARD0001_EXPRESSION = 
        [FE.Guard
         (
           NONE,
           [
             FE.Guard
             (NONE, [FE.Term(6, "jugemu"), ind_s1, FE.Term(6, "jugemu")]),
             ind_s1,
             FE.Term(15, "gokounosurikire"), ind_s2,
             FE.Term(15, "kaijarisuigyono")
           ]
         )]

    val TESTGUARD0001_COLUMNS = 6 + 1 + 6
    val TESTGUARD0001_EXPECTED =
        "jugemu jugemu\ngokounosurikire\nkaijarisuigyono"
  in
  fun testGuard0001 () =
      (
        Assert.assertEqualString
        TESTGUARD0001_EXPECTED
        (prettyPrint
             TESTGUARD0001_COLUMNS
             TESTGUARD0001_EXPRESSION);
        ()
      )
  end

  local
    val TESTGUARD0002_EXPRESSION = 
        [FE.Guard
         (
           NONE,
           [
             FE.Term(6, "jugemu"), ind_sd, FE.Term(6, "jugemu"), ind_s1,
             FE.Guard
             (NONE,
              [
                FE.Term(15, "gokounosurikire"), ind_s1,
                FE.Term(15, "kaijarisuigyono")
              ])
           ]
         )]

    val TESTGUARD0002_COLUMNS = 6 + 1 + 6
    val TESTGUARD0002_EXPECTED =
        "jugemu jugemu\ngokounosurikire\nkaijarisuigyono"
  in
  fun testGuard0002 () =
      (
        Assert.assertEqualString
        TESTGUARD0002_EXPECTED
        (prettyPrint
             TESTGUARD0002_COLUMNS
             TESTGUARD0002_EXPRESSION);
        ()
      )
  end

  local
    val TESTGUARD0003_EXPRESSION = 
        [FE.Guard
         (
           NONE,
           [
             FE.Guard
             (NONE, [FE.Term(6, "jugemu"), ind_s2, FE.Term(6, "jugemu")]),
             ind_s1,
             FE.Guard
             (NONE,
              [
                FE.Term(15, "gokounosurikire"), ind_s2,
                FE.Term(15, "kaijarisuigyono")
              ])
           ]
         )]

    val TESTGUARD0003_COLUMNS = 6 + 1 + 6
    val TESTGUARD0003_EXPECTED =
        "jugemu jugemu\ngokounosurikire\nkaijarisuigyono"
  in
  fun testGuard0003 () =
      (
        Assert.assertEqualString
        TESTGUARD0003_EXPECTED
        (prettyPrint
             TESTGUARD0003_COLUMNS
             TESTGUARD0003_EXPRESSION);
        ()
      )
  end

  local
    val TESTGUARD0004_EXPRESSION = 
        [FE.Guard
         (
           NONE,
           [
             FE.Term(6, "jugemu"), ind_s,
             FE.Guard
             (NONE,
              [
                FE.Term(6, "jugemu"),
                FE.StartOfIndent 5, ind_s1,
                FE.Term(15, "gokounosurikire"),
                FE.EndOfIndent,
                FE.StartOfIndent ~3, ind_s1,
                FE.Term(15, "kaijarisuigyono"),
                FE.EndOfIndent
              ])
           ]
         )]

    val TESTGUARD0004_COLUMNS = (6 + 1 + 6 + 1 + 15 + 1 + 15) - 1
    val TESTGUARD0004_EXPECTED =
        "jugemu jugemu\n            gokounosurikire\n    kaijarisuigyono"
  in
  fun testGuard0004 () =
      (
        Assert.assertEqualString
        TESTGUARD0004_EXPECTED
        (prettyPrint
             TESTGUARD0004_COLUMNS
             TESTGUARD0004_EXPRESSION);
        ()
      )
  end

  local
    val TESTGUARD0005_EXPRESSION = 
        [FE.Guard
         (
           NONE,
           [
             FE.Term(6, "jugemu"), FE.StartOfIndent 3, ind_s1,
             FE.Guard
             (NONE,
              [
                FE.Term(6, "jugemu"),
                FE.StartOfIndent 5, ind_s1,
                FE.Term(15, "gokounosurikire"),
                FE.EndOfIndent,
                FE.StartOfIndent ~3, ind_s1,
                FE.Term(15, "kaijarisuigyono"),
                FE.EndOfIndent
              ]),
             FE.EndOfIndent
           ]
         )]

    val TESTGUARD0005_COLUMNS = 3 + (6 + 1 + 15 + 1 + 15) - 1
    val TESTGUARD0005_EXPECTED =
        "jugemu\n   jugemu\n        gokounosurikire\nkaijarisuigyono"
  in
  fun testGuard0005 () =
      (
        Assert.assertEqualString
        TESTGUARD0005_EXPECTED
        (prettyPrint
             TESTGUARD0005_COLUMNS
             TESTGUARD0005_EXPRESSION);
        ()
      )
  end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testGuard0001", testGuard0001),
        ("testGuard0002", testGuard0002),
        ("testGuard0003", testGuard0003),
        ("testGuard0004", testGuard0004),
        ("testGuard0005", testGuard0005)
      ]

  (***************************************************************************)

end