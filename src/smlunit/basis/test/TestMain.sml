(**
 * entry point of the test suite of SML Basis library.
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 * @version $Id: TestMain.sml,v 1.1.28.1 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
structure TestMain =
struct

  local
    open SMLUnit.Test
  in
  fun test () =
      let
        val tests = TestList (TestRequiredModules.tests ())
(*
        val tests =
            TestList
                (TestRequiredModules.tests () @ TestOptionalModules.tests ())
*)
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end
  end

end
