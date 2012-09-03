use "./abstype/RenameKeywordTestee2.sml";

(**
 * TestCases for renaming SML keywords used in Java package name.
 *)
structure RenameKeywordTest2 =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test
  structure JA = AssertJavaValue

  structure T = abstype'.RenameKeywordTestee2

  structure J = Java
  structure JV = Java.Value

  val $ = Java.call
  val $$ = Java.referenceOf

  (**********)

  fun test1 () =
      let
        val T = T.new()
      in
        ()
      end

  (******************************************)

  fun init () =
      let
        val _ = T.static()
      in
        ()
      end

  fun suite () =
      Test.labelTests
      [
        ("test1", test1)
      ]

end;
