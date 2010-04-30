use "./ExceptionTestee1.sml";
use "./ExceptionTestee1Exception.sml";

(**
 * TestCases for Java exception mechanism.
 *)
structure ExceptionTest1 =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test
  structure JA = AssertJavaValue

  structure T = ExceptionTestee1
  structure TExn = ExceptionTestee1Exception

  structure J = Java
  structure JV = Java.Value

  val $ = Java.call
  val $$ = Java.referenceOf

  (**********)

  fun testThrow () =
      let
        val obj = T.new ()
        val v = 123
        val _ = A.assertEqualInt v ($obj#doThrow(v, false))
        val _ =
            ($obj#doThrow(v, true); A.fail "exception should be raised.")
            handle J.JavaException exn => A.assertTrue (TExn.isInstance exn)
        (* check exception is cleared. *)
        val _ = A.assertEqualInt v ($obj#doThrow(v, false))
      in
        ()
      end
           
  (******************************************)

  fun init () =
      let
        val _ = T.static()
        val _ = TExn.static()
      in
        ()
      end

  fun suite () =
      Test.labelTests
      [
        ("testThrow", testThrow)
      ]

end;
