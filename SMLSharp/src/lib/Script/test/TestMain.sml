(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: TestMain.sml,v 1.1 2006/02/26 13:28:37 kiyoshiy Exp $
 *)
structure TestMain =
struct

  fun test () =
      let val tests = ScriptTest.suite ()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end
