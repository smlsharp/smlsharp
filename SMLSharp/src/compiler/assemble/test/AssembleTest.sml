(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: AssembleTest.sml,v 1.2 2005/03/22 02:10:01 kiyoshiy Exp $
 *)
structure AssembleTest =
struct

  open SMLUnit.Test

  fun suite () =
      TestList
      [
        TestLabel ("AssemblerTest0001", AssemblerTest0001.suite ()),
        TestLabel ("AssemblerTest0002", AssemblerTest0002.suite ())
      ]

end