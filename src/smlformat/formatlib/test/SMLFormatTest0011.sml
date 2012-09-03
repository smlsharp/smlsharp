(**
 * test cases examining the relation between newline indicators across nested
 * guards.
 *
 * <p>
 * These test cases examine that an indicator has higher priority than
 * indicators which occur in inner guards, and that a newline is inserted
 * at outer indicators if a newline is inserted at inner indicators.
 * </p>
 * <p>
 * Following cases are examined with 3 columns specified.
 * <table border=1>
 * <tr><th>No.</th><th>format expression</th><th>expected output</th></tr>
 * <tr>
 *   <td>001</td>
 *   <td><pre>"a" 2 "b" 1 {"cd" 1 "e"}</pre></td>
 *   <td><pre>
 *ab
 *cde</pre></td>
 * </tr>
 * <tr>
 *   <td>002</td>
 *   <td><pre>"a" 2 "b" 1 {"cd" 1 "ef"}</pre></td>
 *   <td><pre>
 *a
 *b
 *cd
 *ef</pre></td>
 * </tr>
 * <tr>
 *   <td>003</td>
 *   <td><pre>"a" 2 "b" 1 {"cd" d "ef"}</pre></td>
 *   <td><pre>
 *a
 *b
 *cd
 *ef</pre></td>
 * </tr>
 * <tr>
 *   <td>004</td>
 *   <td><pre>"a" 2 "b" 1 {"cd" 1 "e" 2 "f"}</pre></td>
 *   <td><pre>
 *a
 *b
 *cd
 *ef</pre></td>
 * </tr>
 * <tr>
 *   <td>101</td>
 *   <td><pre>"a" 2 "b" 1 {"cd" 1 "e"} "f"</pre></td>
 *   <td><pre>
 *ab
 *cdef</pre></td>
 * </tr>
 * <tr>
 *   <td>102</td>
 *   <td><pre>"a" 2 "b" 1 {"cd" 1 "e"} 1 "f"</pre></td>
 *   <td><pre>
 *ab
 *cde
 *f</pre></td>
 * </tr>
 * <tr>
 *   <td>103</td>
 *   <td><pre>"a" 2 "b" 1 {"cd" 1 "e"} 2 "f"</pre></td>
 *   <td><pre>
 *a
 *b
 *cde
 *f</pre></td>
 * </tr>
 * <tr>
 *   <td>104</td>
 *   <td><pre>"a" 2 "b" 1 {"cd" 1 "e"} 3 "f"</pre></td>
 *   <td><pre>
 *a
 *b
 *cde
 *f</pre></td>
 * </tr>
 * <tr>
 *   <td>105</td>
 *   <td><pre>"a" 2 "b" 1 {"cd" 1 "e"} d "f"</pre></td>
 *   <td><pre>
 *a
 *b
 *cde
 *f</pre></td>
 * </tr>
 * </table>
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure SMLFormatTest0011 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure Testee = SMLFormat
  structure E = Testee.FormatExpression
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

  val ind_s = E.Indicator{space = true, newline = NONE}
  val ind_s1 =
      E.Indicator{space = true, newline = SOME{priority = E.Preferred 1}}
  val ind_s2 =
      E.Indicator{space = true, newline = SOME{priority = E.Preferred 2}}
  val ind_sd =
      E.Indicator{space = true, newline = SOME{priority = E.Deferred}}
  val ind_1 =
      E.Indicator{space = false, newline = SOME{priority = E.Preferred 1}}
  val ind_2 =
      E.Indicator{space = false, newline = SOME{priority = E.Preferred 2}}
  val ind_3 =
      E.Indicator{space = false, newline = SOME{priority = E.Preferred 3}}
  val ind_d =
      E.Indicator{space = false, newline = SOME{priority = E.Deferred}}

  (****************************************)

  local
    val TESTGUARD0001_EXPRESSION = 
        [E.Guard
         (
           NONE,
           [
             E.Term(1, "a"),
             ind_2,
             E.Term(1, "b"),
             ind_1,
             E.Guard
             (NONE, [E.Term(2, "cd"), ind_1, E.Term(1, "e")])
           ]
         )]

    val TESTGUARD0001_COLUMNS = 3
    val TESTGUARD0001_EXPECTED = "ab\ncde"
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
        [E.Guard
         (
           NONE,
           [
             E.Term(1, "a"),
             ind_2,
             E.Term(1, "b"),
             ind_1,
             E.Guard
             (NONE, [E.Term(2, "cd"), ind_1, E.Term(2, "ef")])
           ]
         )]

    val TESTGUARD0002_COLUMNS = 3
    val TESTGUARD0002_EXPECTED = "a\nb\ncd\nef"
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
        [E.Guard
         (
           NONE,
           [
             E.Term(1, "a"),
             ind_2,
             E.Term(1, "b"),
             ind_1,
             E.Guard
             (NONE, [E.Term(2, "cd"), ind_d, E.Term(2, "ef")])
           ]
         )]

    val TESTGUARD0003_COLUMNS = 3
    val TESTGUARD0003_EXPECTED = "a\nb\ncd\nef"
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
        [E.Guard
         (
           NONE,
           [
             E.Term(1, "a"),
             ind_2,
             E.Term(1, "b"),
             ind_1,
             E.Guard
             (NONE,
              [E.Term(2, "cd"), ind_1, E.Term(1, "e"), ind_2, E.Term(1, "f")])
           ]
         )]

    val TESTGUARD0004_COLUMNS = 3
    val TESTGUARD0004_EXPECTED = "a\nb\ncd\nef"
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
    val TESTGUARD0101_EXPRESSION = 
        [E.Guard
         (
           NONE,
           [
             E.Term(1, "a"),
             ind_2,
             E.Term(1, "b"),
             ind_1,
             E.Guard
             (NONE, [E.Term(2, "cd"), ind_1, E.Term(1, "e")]),
             E.Term(1, "f")
           ]
         )]

    val TESTGUARD0101_COLUMNS = 3
    val TESTGUARD0101_EXPECTED = "ab\ncdef"
  in
  fun testGuard0101 () =
      (
        Assert.assertEqualString
        TESTGUARD0101_EXPECTED
        (prettyPrint
             TESTGUARD0101_COLUMNS
             TESTGUARD0101_EXPRESSION);
        ()
      )
  end

  local
    val TESTGUARD0102_EXPRESSION = 
        [E.Guard
         (
           NONE,
           [
             E.Term(1, "a"),
             ind_2,
             E.Term(1, "b"),
             ind_1,
             E.Guard
             (NONE, [E.Term(2, "cd"), ind_1, E.Term(1, "e")]),
             ind_1,
             E.Term(1, "f")
           ]
         )]

    val TESTGUARD0102_COLUMNS = 3
    val TESTGUARD0102_EXPECTED = "ab\ncde\nf"
  in
  fun testGuard0102 () =
      (
        Assert.assertEqualString
        TESTGUARD0102_EXPECTED
        (prettyPrint
             TESTGUARD0102_COLUMNS
             TESTGUARD0102_EXPRESSION);
        ()
      )
  end

  local
    val TESTGUARD0103_EXPRESSION = 
        [E.Guard
         (
           NONE,
           [
             E.Term(1, "a"),
             ind_2,
             E.Term(1, "b"),
             ind_1,
             E.Guard
             (NONE, [E.Term(2, "cd"), ind_1, E.Term(1, "e")]),
             ind_2,
             E.Term(1, "f")
           ]
         )]

    val TESTGUARD0103_COLUMNS = 3
    val TESTGUARD0103_EXPECTED = "a\nb\ncde\nf"
  in
  fun testGuard0103 () =
      (
        Assert.assertEqualString
        TESTGUARD0103_EXPECTED
        (prettyPrint
             TESTGUARD0103_COLUMNS
             TESTGUARD0103_EXPRESSION);
        ()
      )
  end

  local
    val TESTGUARD0104_EXPRESSION = 
        [E.Guard
         (
           NONE,
           [
             E.Term(1, "a"),
             ind_2,
             E.Term(1, "b"),
             ind_1,
             E.Guard
             (NONE, [E.Term(2, "cd"), ind_1, E.Term(1, "e")]),
             ind_3,
             E.Term(1, "f")
           ]
         )]

    val TESTGUARD0104_COLUMNS = 3
    val TESTGUARD0104_EXPECTED = "a\nb\ncde\nf"
  in
  fun testGuard0104 () =
      (
        Assert.assertEqualString
        TESTGUARD0104_EXPECTED
        (prettyPrint
             TESTGUARD0104_COLUMNS
             TESTGUARD0104_EXPRESSION);
        ()
      )
  end

  local
    val TESTGUARD0105_EXPRESSION = 
        [E.Guard
         (
           NONE,
           [
             E.Term(1, "a"),
             ind_2,
             E.Term(1, "b"),
             ind_1,
             E.Guard
             (NONE, [E.Term(2, "cd"), ind_1, E.Term(1, "e")]),
             ind_d,
             E.Term(1, "f")
           ]
         )]

    val TESTGUARD0105_COLUMNS = 3
    val TESTGUARD0105_EXPECTED = "a\nb\ncde\nf"
  in
  fun testGuard0105 () =
      (
        Assert.assertEqualString
        TESTGUARD0105_EXPECTED
        (prettyPrint
             TESTGUARD0105_COLUMNS
             TESTGUARD0105_EXPRESSION);
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
        ("testGuard0101", testGuard0101),
        ("testGuard0102", testGuard0102),
        ("testGuard0103", testGuard0103),
        ("testGuard0104", testGuard0104),
        ("testGuard0105", testGuard0105)
      ]

  (***************************************************************************)

end