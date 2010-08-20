use "./Exception1Testee.sml";

(**
 * test cases for handling exception thrown from COM/.NET object.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Exception1Tester =
struct

  structure A = SMLUnit.Assert
  structure Test = SMLUnit.Test

  structure T = Exception1Testee

  open AssertOLEValue
  open AssertDotNETValue

  (**********)

  fun testThrow1 () =
      let
        val obj = T.newException1Testee ()
        val _ =
            (#method_throw obj (); A.fail "exception is expected.")
            handle OLE.OLEError(OLE.ComApplicationError _) => ()
      in
        ()
      end

  (******************************************)

  fun init () =
      let
      in
        ()
      end

  fun suite () =
      Test.labelTests
      [
        ("testThrow1", testThrow1)
      ]

end