(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: ScriptTest.sml,v 1.1 2006/02/26 13:28:37 kiyoshiy Exp $
 *)
structure ScriptTest =
struct

  open SMLUnit.Test

  fun suite () =
      TestList
      [
        TestLabel ("ScriptrTest0001", ScriptTest0001.suite ())
      ]

end