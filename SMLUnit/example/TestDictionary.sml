(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure TestDictionary =
struct

  (***************************************************************************
   inner structure declarations
   ***************************************************************************)

  open Dictionary
  structure Assert = SMLUnit.Assert
  structure Test = SMLUnit.Test

  (***************************************************************************
   value bindings
   ***************************************************************************)

  fun testCreate0001 () =
      (create (); ())

  fun testExists0001 () =
      let val emptyDictionary = create ()
      in Assert.assertFalse (exists emptyDictionary 1); () end

  fun testExists0002 () =
      let
        val key = "K1"
        val dictionary = update (create ()) key 1
      in
        Assert.assertTrue (exists dictionary key); ()
      end

  fun testLookup0001 () =
      let val emptyDictionary = create ()
      in
        (lookup emptyDictionary 1; Assert.fail "must fail")
        handle NotFound => ()
      end

  fun testIsEmpty0001 () =
      let
        val emptyDictionary = create ()
      in
        Assert.assertTrue (isEmpty emptyDictionary); ()
      end

  (******************************************)

  fun suite () =
      Test.labelTests
      [
        ("create0001", testCreate0001),
        ("exists0001", testExists0001),
        ("exists0002", testExists0002),
        ("lookup0001", testLookup0001),
        ("isEmpty0001", testIsEmpty0001)
      ]

end;

SMLUnit.TextUITestRunner.runTest
    {output = TextIO.stdOut}
    (TestDictionary.suite ());
(*
  Sample session:
    - TextUITestRunner.runTest () (TestDictionary.suite ());
    ....F
    tests = 5, failures = 1, errors = 0
    val it = () : unit
*)
