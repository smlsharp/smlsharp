(**
 * A test runner which makes report about result of test in plain text format.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: TextUITestRunner.sml,v 1.4 2005/04/09 14:44:32 kiyoshiy Exp $
 *)
structure TextUITestRunner : TESTRUNNER =
struct
  
  (***************************************************************************)

  (** NOTE : In future version, this might be changed so that the verbose level
   * of printing results can be specified. *)
  type parameter = {output : TextIO.outstream}

  type test = Test.test

  type testResult =
       {
         (** the number of test performed *)
         testCount : int, 
         (** tests aborted by assertion failure *)
         failures : (string * string) list, 
         (** tests aborted by any exception raised *)
         errors : (string * exn) list 
       }

  (***************************************************************************)

  val separator = "/"

  (***************************************************************************)

  fun printTo (parameter : parameter) string =
      TextIO.output(#output parameter, string)

  fun doTest parameter path test =
      let
        val print = printTo parameter
      in
        case test of
          (Test.TestCase test) =>
          ((
             test ();
             print ".";
             {testCount = 1, failures = [], errors = []}
           )
           handle Assert.Fail failure =>
                  let
                    val message = 
                        case failure of
                          Assert.GeneralFailure message => message
                        | Assert.NotEqualFailure (expected, actual) =>
                          "expected:<" ^ expected ^">, actual:<" ^ actual ^ ">"
                  in
                    print "F";
                    {testCount = 1, failures = [(path, message)], errors = []}
                  end
                | error => 
                  (
                    print "E";
                    {testCount = 1, failures = [], errors = [(path, error)]}
                  ))
        | (Test.TestLabel (label, test)) =>
          doTest parameter (path ^ separator ^ label) test
        | (Test.TestList tests) =>
          let 
            fun runOneTest (test, (index, {testCount, failures, errors})) =
                let
                  val result =
                      doTest
                          parameter
                          (path ^ separator ^ (Int.toString index)) test
                in
                  (
                    index + 1,
                    {
                      testCount = testCount + (#testCount result),
                      failures = failures @ (#failures result),
                      errors = errors @ (#errors result)
                    }
                  )
                end
          in
            #2
                (foldl
                     runOneTest
                     (1, {testCount = 0, failures = [], errors = []})
                     tests)
          end
      end

  fun printTestResult parameter ({testCount, failures, errors} : testResult) =
      let
        val print = printTo parameter
        val message =
            ("tests = " ^ (Int.toString testCount) ^ ", ") ^
            ("failures = " ^ (Int.toString (List.length failures)) ^ ", ") ^
            ("errors = " ^ (Int.toString (List.length errors)))
      in
        print ("\n" ^ message ^ "\n");
        print "Failures:\n";
        app
        (fn (path, message) =>
            (print path; print  ": "; print message; print "\n"))
        failures;
        print  "Errors:\n";
        app
        (fn (path, exn) =>
            (print
             (path ^ ": " ^ (exnName exn) ^ ": " ^ (exnMessage exn) ^ "\n")))
        errors
      end

  (***************************************************************************)

  fun runTest parameter test =
      printTestResult parameter (doTest parameter separator test)

  (***************************************************************************)

end
