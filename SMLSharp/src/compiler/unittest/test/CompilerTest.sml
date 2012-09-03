(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: CompilerTest.sml,v 1.6 2006/02/18 04:59:37 ohori Exp $
 *)
structure CompilerTest =
struct

  open SMLUnit.Test

  fun suite () =
      TestList
      [
        TestLabel("Assemble", AssembleTest.suite()),
        TestLabel("Session", SessionTest.suite ()),
        TestLabel("TypedFlatCalc", TypedFlatCalcTest.suite()),
        TestLabel("Types", TypesTest.suite()),
        TestLabel("Util", UtilTest.suite()),
        TestLabel("Instructions", InstructionsTest.suite())
      ]

end
