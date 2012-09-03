(**
 * unit test of <code>structure EasyHTMLParser</code>
 *)
structure EasyHTMLParserTest0001 =
struct

  (***************************************************************************)

  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure Testee = EasyHTMLParser

  (***************************************************************************)

  local
    val TESTGETBODYOFHTML0001_BODY = "FOO"
    val TESTGETBODYOFHTML0001_TEXT =
        "<HTML><BODY>" ^ TESTGETBODYOFHTML0001_BODY ^ "</BODY></HTML>"
  in
  (**
   * test of getBodyOfHTML (normal case)
   * <ul>
   *   <li>BODY start tag: exists</li>
   *   <li>BODY end tag: exists</li>
   * </ul>
   *)
  fun testGetBodyOfHTML0001 () =
      (
        Assert.assertEqualString
        TESTGETBODYOFHTML0001_BODY
        (Testee.getBodyOfHTML (fn _ => ()) TESTGETBODYOFHTML0001_TEXT);
        ()
      )
  end

  (****************************************)

  local
    val TESTGETBODYOFHTML0002_BODY = "FOO"
    val TESTGETBODYOFHTML0002_TEXT =
        TESTGETBODYOFHTML0002_BODY ^ "</BODY></HTML>"
  in
  (**
   * test of getBodyOfHTML (normal case)
   * <ul>
   *   <li>BODY start tag: not exists</li>
   *   <li>BODY end tag: exists</li>
   * </ul>
   *)
  fun testGetBodyOfHTML0002 () =
      (
        Assert.assertEqualString
        TESTGETBODYOFHTML0002_BODY
        (Testee.getBodyOfHTML (fn _ => ()) TESTGETBODYOFHTML0002_TEXT);
        ()
      )
  end

  (****************************************)

  local
    val TESTGETBODYOFHTML0003_BODY = "FOO"
    val TESTGETBODYOFHTML0003_TEXT =
        "<HTML><BODY>" ^ TESTGETBODYOFHTML0003_BODY
  in
  (**
   * test of getBodyOfHTML (normal case)
   * <ul>
   *   <li>BODY start tag: exists</li>
   *   <li>BODY end tag: not exists</li>
   * </ul>
   *)
  fun testGetBodyOfHTML0003 () =
      (
        Assert.assertEqualString
        TESTGETBODYOFHTML0003_BODY
        (Testee.getBodyOfHTML (fn _ => ()) TESTGETBODYOFHTML0003_TEXT);
        ()
      )
  end

  (****************************************)

  local
    val TESTGETBODYOFHTML0004_BODY = "FOO"
    val TESTGETBODYOFHTML0004_TEXT = TESTGETBODYOFHTML0004_BODY
  in
  (**
   * test of getBodyOfHTML (normal case)
   * <ul>
   *   <li>BODY start tag: not exists</li>
   *   <li>BODY end tag: not exists</li>
   * </ul>
   *)
  fun testGetBodyOfHTML0004 () =
      (
        Assert.assertEqualString
        TESTGETBODYOFHTML0004_BODY
        (Testee.getBodyOfHTML (fn _ => ()) TESTGETBODYOFHTML0004_TEXT);
        ()
      )
  end

  (***************************************************************************)

  fun suite () =
      Test.labelTests
      [
        ("testGetBodyOfHTML0001", testGetBodyOfHTML0001),
        ("testGetBodyOfHTML0002", testGetBodyOfHTML0002),
        ("testGetBodyOfHTML0003", testGetBodyOfHTML0003),
        ("testGetBodyOfHTML0004", testGetBodyOfHTML0004)
      ]

  (***************************************************************************)

end