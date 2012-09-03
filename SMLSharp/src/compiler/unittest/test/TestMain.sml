(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: TestMain.sml,v 1.4 2006/02/18 04:59:37 ohori Exp $
 *)
structure TestMain =
struct

  fun test () =
      let val tests = CompilerTest.suite ()
      in SMLUnit.TextUITestRunner.runTest {output = TextIO.stdOut} tests
      end

end
